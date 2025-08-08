import Foundation
import SQLite3

protocol PromptRepository {
    func save(_ prompt: Prompt) async throws
    func update(_ prompt: Prompt) async throws
    func delete(id: UUID) async throws
    func fetch(id: UUID) async throws -> Prompt?
    func search(query: String) async throws -> [Prompt]
    func fetchRecent(limit: Int) async throws -> [Prompt]
    func fetchAll() async throws -> [Prompt]
    func updateAnalysisStatus(_ promptId: String, status: AnalysisStatus) async throws
    func updateAnalysisResult(_ promptId: String, result: AnalysisResult) async throws
}

final class SQLitePromptRepository: PromptRepository {
    private let database: SQLiteDatabase
    
    init(database: SQLiteDatabase) {
        self.database = database
    }
    
    func save(_ prompt: Prompt) async throws {
        // Write to debug log file immediately
        let debugEntry = """
        === REPOSITORY SAVE START ===
        PromptRepository.save() called at \(Date())
        prompt.id = \(prompt.id)
        prompt.title = '\(prompt.title)' (length: \(prompt.title.count))
        prompt.content = '\(prompt.content.prefix(100))...' (length: \(prompt.content.count))
        prompt.description = '\(prompt.description ?? "nil")'
        
        """
        await writeToDebugLog(debugEntry)
        
        print("🔥 REPO: save called for prompt id: \(prompt.id)")
        print("🔥 REPO: title: '\(prompt.title)' (length: \(prompt.title.count))")
        print("🔥 REPO: content: '\(prompt.content.prefix(50))...' (length: \(prompt.content.count))")
        
        // CRITICAL: Validate data before database save
        if prompt.title.isEmpty || prompt.content.isEmpty {
            print("🔥 REPO: CRITICAL ERROR - Empty data in repository save!")
            print("🔥 REPO: title.isEmpty: \(prompt.title.isEmpty)")
            print("🔥 REPO: content.isEmpty: \(prompt.content.isEmpty)")
            await writeToDebugLog("REPO ERROR: Empty data detected - title: '\(prompt.title)', content length: \(prompt.content.count)\n")
        } else {
            await writeToDebugLog("REPO: Data validation passed - title and content are not empty\n")
        }
        
        let sql = """
            INSERT OR REPLACE INTO prompts (id, title, content, description, is_favorite, 
                               created_at, modified_at, used_count, last_used_at,
                               category, analysis_status, analysis_confidence, analysis_description)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        print("PromptRepository: Executing SQL insert...")
        await writeToDebugLog("REPO: About to execute SQL insert\n")
        await writeToDebugLog("REPO: SQL = \(sql)\n")
        await writeToDebugLog("REPO: Parameters - id: \(prompt.id.uuidString), title: '\(prompt.title)', content length: \(prompt.content.count)\n")
        
        do {
            try database.execute(sql, parameters: [
                prompt.id.uuidString,
                prompt.title,
                prompt.content,
                prompt.description ?? NSNull(),
                prompt.isFavorite ? 1 : 0,
                prompt.createdAt.timeIntervalSince1970,
                prompt.modifiedAt.timeIntervalSince1970,
                prompt.usedCount,
                prompt.lastUsedAt?.timeIntervalSince1970 ?? NSNull(),
                prompt.category ?? NSNull(),
                prompt.analysisStatus.rawValue,
                prompt.analysisConfidence ?? NSNull(),
                prompt.analysisDescription ?? NSNull()
            ])
            print("PromptRepository: Save successful!")
            await writeToDebugLog("REPO SUCCESS: database.execute() completed successfully\n")
        } catch {
            print("PromptRepository: Save failed with error: \(error)")
            await writeToDebugLog("REPO ERROR: database.execute() failed - \(error)\n")
            throw error
        }
        
        await writeToDebugLog("=== REPOSITORY SAVE END ===\n\n")
    }
    
    func update(_ prompt: Prompt) async throws {
        let sql = """
            UPDATE prompts SET title = ?, content = ?, description = ?, 
                              is_favorite = ?, modified_at = ?, used_count = ?, last_used_at = ?,
                              category = ?, analysis_status = ?, analysis_confidence = ?, analysis_description = ?
            WHERE id = ?
        """
        
        try database.execute(sql, parameters: [
            prompt.title,
            prompt.content,
            prompt.description ?? NSNull(),
            prompt.isFavorite ? 1 : 0,
            Date().timeIntervalSince1970,
            prompt.usedCount,
            prompt.lastUsedAt?.timeIntervalSince1970 ?? NSNull(),
            prompt.category ?? NSNull(),
            prompt.analysisStatus.rawValue,
            prompt.analysisConfidence ?? NSNull(),
            prompt.analysisDescription ?? NSNull(),
            prompt.id.uuidString
        ])
    }
    
    func delete(id: UUID) async throws {
        try database.execute("DELETE FROM prompts WHERE id = ?", parameters: [id.uuidString])
    }
    
    func fetch(id: UUID) async throws -> Prompt? {
        let sql = "SELECT * FROM prompts WHERE id = ? LIMIT 1"
        let results = try database.query(sql, parameters: [id.uuidString])
        
        guard let row = results.first else { return nil }
        return try mapRowToPrompt(row)
    }
    
    func search(query: String) async throws -> [Prompt] {
        guard !query.isEmpty else { return [] }
        
        let sql = """
            SELECT p.* FROM prompts p
            JOIN prompts_fts fts ON p.id = fts.id
            WHERE prompts_fts MATCH ?
            ORDER BY rank
            LIMIT 50
        """
        
        let results = try database.query(sql, parameters: [query])
        return try results.map { row in
            try mapRowToPrompt(row)
        }
    }
    
    func fetchRecent(limit: Int) async throws -> [Prompt] {
        print("SQLitePromptRepository: fetchRecent called with limit: \(limit)")
        let sql = "SELECT * FROM prompts ORDER BY created_at DESC LIMIT ?"
        
        do {
            let results = try database.query(sql, parameters: [limit])
            print("SQLitePromptRepository: Query returned \(results.count) results")
            
            if results.isEmpty {
                print("SQLitePromptRepository: No prompts found, returning empty array")
                return []
            }
            
            return try results.map { row in
                print("SQLitePromptRepository: Mapping row: \(row)")
                return try mapRowToPrompt(row)
            }
        } catch {
            print("SQLitePromptRepository: fetchRecent failed with error: \(error)")
            throw error
        }
    }
    
    func fetchAll() async throws -> [Prompt] {
        print("PromptRepository: fetchAll called")
        let sql = "SELECT * FROM prompts ORDER BY created_at DESC"
        let results = try database.query(sql)
        print("PromptRepository: Query returned \(results.count) rows")
        let prompts = results.compactMap { row in
            do {
                return try mapRowToPrompt(row)
            } catch {
                print("PromptRepository: Skipping invalid row: \(error)")
                return nil
            }
        }
        print("PromptRepository: Mapped \(prompts.count) prompts")
        return prompts
    }
    
    func updateAnalysisStatus(_ promptId: String, status: AnalysisStatus) async throws {
        let sql = "UPDATE prompts SET analysis_status = ? WHERE id = ?"
        try database.execute(sql, parameters: [status.rawValue, promptId])
    }
    
    func updateAnalysisResult(_ promptId: String, result: AnalysisResult) async throws {
        let sql = """
            UPDATE prompts SET 
                category = ?, 
                analysis_status = ?, 
                analysis_confidence = ?, 
                analysis_description = ?,
                modified_at = ?
            WHERE id = ?
        """
        
        try database.execute(sql, parameters: [
            result.category,
            result.status.rawValue,
            result.confidence,
            result.description,
            Date().timeIntervalSince1970,
            promptId
        ])
    }
    
    private func mapRowToPrompt(_ row: [String: Any]) throws -> Prompt {
        print("SQLitePromptRepository: mapRowToPrompt called with row: \(row)")
        
        guard let idString = row["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = row["title"] as? String,
              let content = row["content"] as? String else {
            print("SQLitePromptRepository: Missing required fields in row")
            print("  id: \(row["id"] ?? "nil")")
            print("  title: \(row["title"] ?? "nil")")
            print("  content: \(row["content"] ?? "nil")")
            throw ValidationError.invalidInput
        }
        
        let description = row["description"] as? String
        let isFavorite = (row["is_favorite"] as? Int64) == 1
        let category = row["category"] as? String
        let analysisStatusString = row["analysis_status"] as? String ?? "pending"
        let analysisStatus = AnalysisStatus(rawValue: analysisStatusString) ?? .pending
        let analysisConfidence = row["analysis_confidence"] as? Double
        let analysisDescription = row["analysis_description"] as? String

        // Map timestamp fields
        let createdAtTime = (row["created_at"] as? Double) ?? (row["created_at"] as? Int64).map(Double.init) ?? Date().timeIntervalSince1970
        let modifiedAtTime = (row["modified_at"] as? Double) ?? (row["modified_at"] as? Int64).map(Double.init) ?? createdAtTime
        let lastUsedTime = (row["last_used_at"] as? Double) ?? (row["last_used_at"] as? Int64).map(Double.init)

        let prompt = Prompt(
            id: id,
            title: title,
            content: content,
            description: description,
            tags: [], // TODO: Load tags separately
            isFavorite: isFavorite,
            createdAt: Date(timeIntervalSince1970: createdAtTime),
            modifiedAt: Date(timeIntervalSince1970: modifiedAtTime),
            usedCount: Int((row["used_count"] as? Int64) ?? 0),
            lastUsedAt: lastUsedTime.map { Date(timeIntervalSince1970: $0) },
            category: category,
            analysisStatus: analysisStatus,
            analysisConfidence: analysisConfidence,
            analysisDescription: analysisDescription
        )

        return prompt
    }
    
    private func writeToDebugLog(_ message: String) async {
        let documentsPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appPath = documentsPath.appendingPathComponent("PromptBar")
        let logPath = appPath.appendingPathComponent("debug.log")
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: appPath, withIntermediateDirectories: true)
        
        // Append to log file
        let logEntry = "\(message)"
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

enum ValidationError: LocalizedError {
    case invalidInput
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Invalid input provided"
        }
    }
}