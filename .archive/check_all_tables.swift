import Foundation
import SQLite3

// Check database tables
let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, 
                                              in: .userDomainMask).first!
let appDirectory = appSupportURL.appendingPathComponent("PromptBar")
let dbPath = appDirectory.appendingPathComponent("promptbar.db").path

print("Checking database at: \(dbPath)")

var db: OpaquePointer?
if sqlite3_open(dbPath, &db) == SQLITE_OK {
    print("✅ Database opened")
    
    // List ALL tables including system tables
    let checkSQL = "SELECT type, name, tbl_name, sql FROM sqlite_master ORDER BY type, name;"
    var statement: OpaquePointer?
    
    if sqlite3_prepare_v2(db, checkSQL, -1, &statement, nil) == SQLITE_OK {
        print("\nDatabase objects:")
        while sqlite3_step(statement) == SQLITE_ROW {
            let type = String(cString: sqlite3_column_text(statement, 0))
            let name = String(cString: sqlite3_column_text(statement, 1))
            let tblName = String(cString: sqlite3_column_text(statement, 2))
            print("  \(type): \(name) (table: \(tblName))")
        }
    }
    sqlite3_finalize(statement)
    sqlite3_close(db)
} else {
    print("❌ Failed to open database")
}
