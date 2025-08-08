import Foundation

struct SavePromptUseCase {
    let repository: PromptRepository
    
    func execute(title: String, content: String, description: String? = nil) async throws -> Prompt {
        // Add to debug log immediately
        let debugEntry = """
        === USECASE DEBUG START ===
        SavePromptUseCase.execute called at \(Date())
        title = '\(title)' (length: \(title.count))
        content = '\(content.prefix(100))...' (length: \(content.count))
        description = '\(description ?? "nil")'
        
        """
        await writeToDebugLog(debugEntry)
        
        print("SavePromptUseCase: execute called")
        print("SavePromptUseCase: title: '\(title)'")
        print("SavePromptUseCase: content: '\(content.prefix(50))...'")
        print("SavePromptUseCase: description: '\(description ?? "nil")'")
        
        // Validate input
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("SavePromptUseCase: Validation failed - empty title or content")
            await writeToDebugLog("USECASE ERROR: Validation failed - empty title or content\n")
            throw ValidationError.invalidInput
        }
        
        // Create prompt
        let prompt = Prompt(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        print("SavePromptUseCase: Created prompt with id: \(prompt.id)")
        await writeToDebugLog("USECASE: Created prompt - id: \(prompt.id), title: '\(prompt.title)', content length: \(prompt.content.count)\n")
        
        // Save to repository
        await writeToDebugLog("USECASE: About to call repository.save()\n")
        try await repository.save(prompt)
        await writeToDebugLog("USECASE: repository.save() completed successfully\n")
        
        print("SavePromptUseCase: Prompt saved successfully")
        await writeToDebugLog("USECASE SUCCESS: Prompt saved successfully\n=== USECASE DEBUG END ===\n\n")
        
        return prompt
    }
    
    func executeFromClipboard(title: String, description: String? = nil) async throws -> Prompt? {
        guard let clipboardContent = ClipboardManager.shared.currentText,
              !clipboardContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        
        return try await execute(
            title: title,
            content: clipboardContent,
            description: description
        )
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