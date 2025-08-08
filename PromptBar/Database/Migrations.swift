import Foundation

struct DatabaseMigrator {
    let database: SQLiteDatabase
    
    func migrate() throws {
        print("DatabaseMigrator: Starting database migrations...")
        
        try createSchemaVersionTable()
        print("DatabaseMigrator: Schema version table created/verified")
        
        let currentVersion = try getCurrentVersion()
        print("DatabaseMigrator: Current database version: \(currentVersion)")
        
        // Add debug to see if migrations array is populated
        print("DatabaseMigrator: Available migrations: \(migrations.count)")
        
        for migration in migrations where migration.version > currentVersion {
            print("DatabaseMigrator: Running migration \(migration.version): \(migration.description)")
            do {
                try migration.up(database)
                try setVersion(migration.version)
                print("DatabaseMigrator: Migration \(migration.version) completed successfully")
            } catch {
                print("DatabaseMigrator: Migration \(migration.version) failed: \(error)")
                throw error
            }
        }
        
        print("DatabaseMigrator: All migrations completed")
        
        // Verify tables were created
        do {
            let tables = try database.query("SELECT name FROM sqlite_master WHERE type='table'")
            print("DatabaseMigrator: Tables in database: \(tables.map { $0["name"] ?? "unknown" })")
        } catch {
            print("DatabaseMigrator: Failed to list tables: \(error)")
        }
    }
    
    private func createSchemaVersionTable() throws {
        try database.execute("""
            CREATE TABLE IF NOT EXISTS schema_version (
                version INTEGER PRIMARY KEY,
                applied_at REAL NOT NULL
            )
        """)
    }
    
    private func getCurrentVersion() throws -> Int {
        do {
            let results = try database.query("SELECT MAX(version) as max_version FROM schema_version")
            if let row = results.first, let version = row["max_version"] as? Int64 {
                return Int(version)
            }
            return 0
        } catch {
            // If the table doesn't exist, return 0
            print("DatabaseMigrator: Schema version table doesn't exist yet, returning version 0")
            return 0
        }
    }
    
    private func setVersion(_ version: Int) throws {
        try database.execute("""
            INSERT OR REPLACE INTO schema_version (version, applied_at)
            VALUES (?, ?)
        """, parameters: [version, Date().timeIntervalSince1970])
    }
    
    private let migrations = [
        Migration(
            version: 1,
            description: "Initial schema with analysis fields",
            up: { db in
                print("Migration 1: Creating prompts table...")
                
                // Create prompts table with all fields
                try db.execute("""
                    CREATE TABLE IF NOT EXISTS prompts (
                        id TEXT PRIMARY KEY,
                        title TEXT NOT NULL,
                        content TEXT NOT NULL,
                        description TEXT,
                        is_favorite INTEGER DEFAULT 0,
                        created_at REAL NOT NULL,
                        modified_at REAL NOT NULL,
                        used_count INTEGER DEFAULT 0,
                        last_used_at REAL,
                        category TEXT,
                        analysis_status TEXT DEFAULT 'pending',
                        analysis_confidence REAL,
                        analysis_description TEXT
                    )
                """)
                print("Migration 1: ✓ Created prompts table")
                
                // Create indexes
                try db.execute("CREATE INDEX IF NOT EXISTS idx_prompts_created ON prompts(created_at DESC)")
                try db.execute("CREATE INDEX IF NOT EXISTS idx_prompts_favorite ON prompts(is_favorite)")
                try db.execute("CREATE INDEX IF NOT EXISTS idx_prompts_category ON prompts(category)")
                try db.execute("CREATE INDEX IF NOT EXISTS idx_prompts_analysis_status ON prompts(analysis_status)")
                print("Migration 1: ✓ Created indexes")
                
                // Create FTS5 table
                do {
                    // First, check if the FTS table already exists
                    let ftsExists = try db.query("SELECT name FROM sqlite_master WHERE type='table' AND name='prompts_fts'")
                    
                    if ftsExists.isEmpty {
                        try db.execute("""
                            CREATE VIRTUAL TABLE prompts_fts USING fts5(
                                id UNINDEXED,
                                title,
                                content,
                                description,
                                tags,
                                tokenize='porter unicode61'
                            )
                        """)
                        print("Migration 1: ✓ Created FTS5 virtual table")
                    } else {
                        print("Migration 1: ✓ FTS5 table already exists")
                    }
                } catch {
                    print("Migration 1: ✗ Failed to create FTS5 table: \(error)")
                    print("Migration 1:   Note: FTS5 support might not be compiled into SQLite")
                    
                    // Try a simpler FTS5 table without tokenizer options
                    do {
                        try db.execute("""
                            CREATE VIRTUAL TABLE IF NOT EXISTS prompts_fts USING fts5(
                                id UNINDEXED,
                                title,
                                content,
                                description,
                                tags
                            )
                        """)
                        print("Migration 1: ✓ Created FTS5 virtual table (without custom tokenizer)")
                    } catch {
                        print("Migration 1: ✗ FTS5 creation failed completely: \(error)")
                        throw error
                    }
                }
                
                // Create triggers for FTS
                do {
                    // Drop existing triggers if they exist
                    try? db.execute("DROP TRIGGER IF EXISTS prompts_ai")
                    try? db.execute("DROP TRIGGER IF EXISTS prompts_au")
                    try? db.execute("DROP TRIGGER IF EXISTS prompts_ad")
                    
                    try db.execute("""
                        CREATE TRIGGER prompts_ai AFTER INSERT ON prompts BEGIN
                            INSERT OR IGNORE INTO prompts_fts(id, title, content, description, tags)
                            VALUES (new.id, new.title, new.content, COALESCE(new.description, ''), COALESCE(new.category, ''));
                        END
                    """)
                    print("Migration 1: ✓ Created INSERT trigger")
                    
                    try db.execute("""
                        CREATE TRIGGER prompts_au AFTER UPDATE ON prompts BEGIN
                            UPDATE prompts_fts SET 
                                title = new.title,
                                content = new.content,
                                description = COALESCE(new.description, ''),
                                tags = COALESCE(new.category, '')
                            WHERE id = new.id;
                        END
                    """)
                    print("Migration 1: ✓ Created UPDATE trigger")
                    
                    try db.execute("""
                        CREATE TRIGGER prompts_ad AFTER DELETE ON prompts BEGIN
                            DELETE FROM prompts_fts WHERE id = old.id;
                        END
                    """)
                    print("Migration 1: ✓ Created DELETE trigger")
                } catch {
                    print("Migration 1: ✗ Failed to create FTS triggers: \(error)")
                    // This is a critical error - without triggers, FTS won't stay in sync
                    throw error
                }
                
                print("Migration 1: Completed successfully")
            }
        )
    ]
}

struct Migration {
    let version: Int
    let description: String
    let up: (SQLiteDatabase) throws -> Void
}