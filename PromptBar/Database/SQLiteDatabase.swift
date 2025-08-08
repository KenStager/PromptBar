import Foundation
import SQLite3

final class SQLiteDatabase {
    private let dbPath: String
    private var db: OpaquePointer?
    
    init(path: String = "promptbar.db") {
        // Non-sandboxed app: use Application Support directory
        let containerURL: URL
        if let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, 
                                                        in: .userDomainMask).first {
            // Create PromptBar subdirectory
            containerURL = appSupportURL.appendingPathComponent("PromptBar")
        } else {
            // Fallback to temp directory if Application Support is not available
            containerURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("PromptBar")
        }
        
        // Create directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(at: containerURL, 
                                                   withIntermediateDirectories: true, 
                                                   attributes: nil)
            print("Created/verified directory: \(containerURL.path)")
        } catch {
            print("Failed to create app directory: \(error)")
        }
        
        self.dbPath = containerURL.appendingPathComponent(path).path
        print("SQLiteDatabase: Database path set to: \(dbPath)")
    }
    
    func open() throws {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            print("SQLite Error opening database: \(errorMsg)")
            throw DatabaseError.cannotOpen
        }
        
        print("Database opened successfully at: \(dbPath)")
        
        // Set pragmas using simple exec for better compatibility
        var errorMsg: UnsafeMutablePointer<CChar>?
        
        // Enable foreign keys
        if sqlite3_exec(db, "PRAGMA foreign_keys = ON", nil, nil, &errorMsg) != SQLITE_OK {
            if let error = errorMsg {
                print("Warning: Failed to enable foreign keys: \(String(cString: error))")
                sqlite3_free(errorMsg)
            }
        }
        
        // Performance optimizations
        if sqlite3_exec(db, "PRAGMA journal_mode = WAL", nil, nil, &errorMsg) != SQLITE_OK {
            if let error = errorMsg {
                print("Warning: Failed to set WAL mode: \(String(cString: error))")
                sqlite3_free(errorMsg)
            }
        }
        
        if sqlite3_exec(db, "PRAGMA synchronous = NORMAL", nil, nil, &errorMsg) != SQLITE_OK {
            if let error = errorMsg {
                print("Warning: Failed to set synchronous mode: \(String(cString: error))")
                sqlite3_free(errorMsg)
            }
        }
        
        print("Database pragmas set")
    }
    
    func execute(_ sql: String, parameters: [Any] = []) throws {
        // CRITICAL DEBUG: Log parameters received by SQLiteDatabase
        if sql.contains("INSERT OR REPLACE INTO prompts") {
            writeToDebugLogSync("=== SQLITE DATABASE EXECUTE DEBUG ===")
            writeToDebugLogSync("SQL: \(sql)")
            writeToDebugLogSync("Parameters count: \(parameters.count)")
            for (index, param) in parameters.enumerated() {
                if let stringParam = param as? String {
                    writeToDebugLogSync("  [\(index)]: String = '\(stringParam)' (length: \(stringParam.count))")
                } else {
                    writeToDebugLogSync("  [\(index)]: \(type(of: param)) = \(param)")
                }
            }
        }
        
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            print("SQLite Error preparing statement: \(sql)")
            print("Error message: \(errorMsg)")
            throw DatabaseError.prepareFailed(sql)
        }
        
        defer { sqlite3_finalize(statement) }
        
        // Bind parameters
        for (index, parameter) in parameters.enumerated() {
            let idx = Int32(index + 1)
            
            switch parameter {
            case let value as String:
                sqlite3_bind_text(statement, idx, value, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            case let value as Int:
                sqlite3_bind_int64(statement, idx, Int64(value))
            case let value as Double:
                sqlite3_bind_double(statement, idx, value)
            case let value as Data:
                sqlite3_bind_blob(statement, idx, [UInt8](value), Int32(value.count), unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            case is NSNull:
                sqlite3_bind_null(statement, idx)
            default:
                throw DatabaseError.invalidParameter
            }
        }
        
        // Execute the statement
        var result = sqlite3_step(statement)
        
        // For some statements like PRAGMA, we might get SQLITE_ROW
        // Keep stepping until we're done
        while result == SQLITE_ROW {
            result = sqlite3_step(statement)
        }
        
        guard result == SQLITE_DONE else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            print("SQLite Error executing: \(sql)")
            print("Error message: \(errorMsg)")
            print("Error code: \(result)")
            if sql.contains("INSERT OR REPLACE INTO prompts") {
                writeToDebugLogSync("SQLITE ERROR: \(errorMsg), code: \(result)")
            }
            throw DatabaseError.executionFailed(errorMsg)
        }
        
        // CRITICAL DEBUG: After INSERT, verify what was actually saved
        if sql.contains("INSERT OR REPLACE INTO prompts") {
            writeToDebugLogSync("SQLITE SUCCESS: INSERT completed, verifying saved data...")
            
            // Extract the id parameter (first parameter) for verification
            if let idParam = parameters.first as? String {
                let verificationSQL = "SELECT id, title, content FROM prompts WHERE id = ? LIMIT 1"
                
                var verifyStatement: OpaquePointer?
                if sqlite3_prepare_v2(db, verificationSQL, -1, &verifyStatement, nil) == SQLITE_OK {
                    sqlite3_bind_text(verifyStatement, 1, idParam, -1, nil)
                    
                    if sqlite3_step(verifyStatement) == SQLITE_ROW {
                        let savedId = String(cString: sqlite3_column_text(verifyStatement, 0))
                        let savedTitle = String(cString: sqlite3_column_text(verifyStatement, 1))
                        let savedContent = String(cString: sqlite3_column_text(verifyStatement, 2))
                        
                        writeToDebugLogSync("SQLITE VERIFICATION:")
                        writeToDebugLogSync("  Saved ID: \(savedId)")
                        writeToDebugLogSync("  Saved Title: '\(savedTitle)' (length: \(savedTitle.count))")
                        writeToDebugLogSync("  Saved Content: '\(savedContent.prefix(50))...' (length: \(savedContent.count))")
                    } else {
                        writeToDebugLogSync("SQLITE VERIFICATION: No row found with id \(idParam)")
                    }
                    sqlite3_finalize(verifyStatement)
                }
            }
            writeToDebugLogSync("=== SQLITE DATABASE EXECUTE END ===")
        }
    }
    
    func query(_ sql: String, parameters: [Any] = []) throws -> [[String: Any]] {
        var statement: OpaquePointer?
        var results: [[String: Any]] = []
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            print("SQLite Error preparing query: \(sql)")
            print("Error message: \(errorMsg)")
            throw DatabaseError.prepareFailed(sql)
        }
        
        defer { sqlite3_finalize(statement) }
        
        // Bind parameters
        for (index, parameter) in parameters.enumerated() {
            let idx = Int32(index + 1)
            
            switch parameter {
            case let value as String:
                sqlite3_bind_text(statement, idx, value, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            case let value as Int:
                sqlite3_bind_int64(statement, idx, Int64(value))
            case let value as Double:
                sqlite3_bind_double(statement, idx, value)
            case let value as Data:
                sqlite3_bind_blob(statement, idx, [UInt8](value), Int32(value.count), unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            case is NSNull:
                sqlite3_bind_null(statement, idx)
            default:
                throw DatabaseError.invalidParameter
            }
        }
        
        let columnCount = sqlite3_column_count(statement)
        
        while sqlite3_step(statement) == SQLITE_ROW {
            var row: [String: Any] = [:]
            
            for i in 0..<columnCount {
                let columnName = String(cString: sqlite3_column_name(statement, i))
                let columnType = sqlite3_column_type(statement, i)
                
                switch columnType {
                case SQLITE_INTEGER:
                    row[columnName] = sqlite3_column_int64(statement, i)
                case SQLITE_FLOAT:
                    row[columnName] = sqlite3_column_double(statement, i)
                case SQLITE_TEXT:
                    row[columnName] = String(cString: sqlite3_column_text(statement, i))
                case SQLITE_BLOB:
                    let data = sqlite3_column_blob(statement, i)
                    let size = sqlite3_column_bytes(statement, i)
                    row[columnName] = Data(bytes: data!, count: Int(size))
                case SQLITE_NULL:
                    row[columnName] = NSNull()
                default:
                    row[columnName] = NSNull()
                }
            }
            
            results.append(row)
        }
        
        return results
    }
    
    private func writeToDebugLogSync(_ message: String) {
        let documentsPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appPath = documentsPath.appendingPathComponent("PromptBar")
        let logPath = appPath.appendingPathComponent("debug.log")
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: appPath, withIntermediateDirectories: true)
        
        // Append to log file
        let logEntry = "\(message)\n"
        if let data = logEntry.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logPath.path) {
                let fileHandle = try? FileHandle(forWritingTo: logPath)
                fileHandle?.seekToEndOfFile()
                fileHandle?.write(data)
                fileHandle?.closeFile()
            } else {
                try? data.write(to: logPath)
            }
        }
    }
}

enum DatabaseError: LocalizedError {
    case cannotOpen
    case prepareFailed(String)
    case executionFailed(String)
    case invalidParameter
    
    var errorDescription: String? {
        switch self {
        case .cannotOpen:
            return "Cannot open database. Please ensure PromptBar has permission to access Application Support."
        case .prepareFailed(let sql):
            return "Failed to prepare SQL statement: \(sql)"
        case .executionFailed(let error):
            return "Failed to execute database operation: \(error)"
        case .invalidParameter:
            return "Invalid parameter provided to database"
        }
    }
}
