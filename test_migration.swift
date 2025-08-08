import Foundation
import SQLite3

// Test database setup and migrations
let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, 
                                              in: .userDomainMask).first!
let appDirectory = appSupportURL.appendingPathComponent("PromptBar")
let dbPath = appDirectory.appendingPathComponent("promptbar.db").path

print("Testing database migrations...")
print("Database path: \(dbPath)")

// Open database
var db: OpaquePointer?
if sqlite3_open(dbPath, &db) == SQLITE_OK {
    print("✅ Database opened")
    
    // Check what tables exist
    let checkSQL = "SELECT name FROM sqlite_master WHERE type='table';"
    var statement: OpaquePointer?
    
    if sqlite3_prepare_v2(db, checkSQL, -1, &statement, nil) == SQLITE_OK {
        print("\nExisting tables:")
        while sqlite3_step(statement) == SQLITE_ROW {
            if let namePointer = sqlite3_column_text(statement, 0) {
                let name = String(cString: namePointer)
                print("  - \(name)")
            }
        }
    }
    sqlite3_finalize(statement)
    
    // Try to query prompts table
    let testSQL = "SELECT COUNT(*) FROM prompts"
    if sqlite3_prepare_v2(db, testSQL, -1, &statement, nil) == SQLITE_OK {
        print("\n✅ prompts table exists")
        sqlite3_finalize(statement)
    } else {
        print("\n❌ prompts table does not exist")
        print("Error: \(String(cString: sqlite3_errmsg(db)))")
    }
    
    sqlite3_close(db)
} else {
    print("❌ Failed to open database")
}
