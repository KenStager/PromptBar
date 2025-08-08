import Foundation
import SQLite3

// Simulate the app's database setup
class SQLiteDatabase {
    private let dbPath: String
    private var db: OpaquePointer?
    
    init(path: String = "promptbar.db") {
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, 
                                                      in: .userDomainMask).first!
        let appDirectory = appSupportURL.appendingPathComponent("PromptBar")
        
        do {
            try FileManager.default.createDirectory(at: appDirectory, 
                                                   withIntermediateDirectories: true, 
                                                   attributes: nil)
        } catch {
            print("Failed to create app directory: \(error)")
        }
        
        self.dbPath = appDirectory.appendingPathComponent(path).path
        print("Database path: \(dbPath)")
    }
    
    func open() throws {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            print("SQLite Error opening database: \(errorMsg)")
            throw NSError(domain: "DB", code: 1)
        }
        
        print("Database opened successfully at: \(dbPath)")
        
        // Enable foreign keys
        try execute("PRAGMA foreign_keys = ON")
        
        // Performance optimizations
        try execute("PRAGMA journal_mode = WAL")
        try execute("PRAGMA synchronous = NORMAL")
        
        print("Database pragmas set successfully")
    }
    
    func execute(_ sql: String) throws {
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            print("Failed to prepare: \(sql)")
            print("Error: \(errorMsg)")
            throw NSError(domain: "DB", code: 2)
        }
        
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            print("SQLite Error executing: \(sql)")
            print("Error message: \(errorMsg)")
            throw NSError(domain: "DB", code: 3)
        }
    }
}

// Test the setup
let db = SQLiteDatabase()
do {
    try db.open()
    print("✅ Database opened and configured successfully!")
    
    // Try creating the prompts table
    try db.execute("""
        CREATE TABLE prompts (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            description TEXT,
            is_favorite INTEGER DEFAULT 0,
            created_at REAL NOT NULL,
            modified_at REAL NOT NULL,
            used_count INTEGER DEFAULT 0,
            last_used_at REAL
        )
    """)
    print("✅ Created prompts table")
    
} catch {
    print("❌ Error: \(error)")
}
