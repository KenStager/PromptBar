import Foundation

actor AnalysisQueue {
    static let shared = AnalysisQueue()
    
    private let ollamaClient: OllamaClient
    private lazy var repository: PromptRepository = {
        do {
            return try DIContainer.shared.resolve(PromptRepository.self)
        } catch {
            fatalError("Failed to resolve PromptRepository: \(error)")
        }
    }()
    private var pendingTasks: [String: Task<Void, Never>] = [:]
    private let maxConcurrentTasks = 3
    private var activeTasks = 0
    
    private init() {
        self.ollamaClient = OllamaClient()
    }
    
    func enqueue(_ prompt: Prompt) {
        let promptId = prompt.id.uuidString
        print("🔄 QUEUE: enqueue called for prompt: \(prompt.title)")
        guard pendingTasks[promptId] == nil else {
            print("Analysis already queued for prompt: \(prompt.id)")
            return
        }
        
        let task = Task {
            await processPrompt(prompt)
        }
        
        pendingTasks[promptId] = task
        print("✅ QUEUE: Queued analysis for prompt: \(prompt.title)")
    }
    
    func cancel(_ promptId: String) {
        if let task = pendingTasks.removeValue(forKey: promptId) {
            task.cancel()
            print("Cancelled analysis for prompt: \(promptId)")
        }
    }
    
    func cancelAll() {
        for (_, task) in pendingTasks {
            task.cancel()
        }
        pendingTasks.removeAll()
        print("Cancelled all pending analyses")
    }
    
    func getQueueStatus() -> (pending: Int, active: Int) {
        return (pendingTasks.count, activeTasks)
    }
    
    private func processPrompt(_ prompt: Prompt) async {
        let promptId = prompt.id.uuidString
        print("🔄 QUEUE: processPrompt started for: \(prompt.title)")
        defer {
            pendingTasks.removeValue(forKey: promptId)
            activeTasks -= 1
            print("🔄 QUEUE: processPrompt finished for: \(prompt.title)")
        }
        
        await waitForAvailableSlot()
        activeTasks += 1
        
        await updatePromptStatus(promptId, status: .processing)
        
        print("🔄 QUEUE: Checking Ollama health...")
        let healthCheck = await ollamaClient.checkHealth()
        print("🔄 QUEUE: Ollama health check result: \(healthCheck)")
        if !healthCheck {
            print("❌ QUEUE: Ollama service unavailable, using fallback")
            await handleAnalysisFailure(prompt)
            return
        }
        
        let result = await ollamaClient.analyzePrompt(prompt)
        await saveAnalysisResult(promptId, result: result)
        
        print("✅ Analysis completed for: \(prompt.title)")
    }
    
    private func waitForAvailableSlot() async {
        while activeTasks >= maxConcurrentTasks {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
    }
    
    private func updatePromptStatus(_ promptId: String, status: AnalysisStatus) async {
        do {
            try await repository.updateAnalysisStatus(promptId, status: status)
        } catch {
            print("Failed to update prompt status: \(error)")
        }
    }
    
    private func saveAnalysisResult(_ promptId: String, result: AnalysisResult) async {
        do {
            try await repository.updateAnalysisResult(promptId, result: result)
            print("Saved analysis result for prompt: \(promptId)")
        } catch {
            print("Failed to save analysis result: \(error)")
        }
    }
    
    private func handleAnalysisFailure(_ prompt: Prompt) async {
        let fallbackResult = AnalysisResult.fallback(for: prompt)
        await saveAnalysisResult(prompt.id.uuidString, result: fallbackResult)
    }
}

extension AnalysisQueue {
    func processWithTimeout(_ prompt: Prompt, timeout: TimeInterval = 10.0) async {
        let task = Task {
            await processPrompt(prompt)
        }
        
        do {
            try await withTimeout(timeout) {
                await task.value
            }
        } catch {
            task.cancel()
            print("Analysis timed out for prompt: \(prompt.title)")
            await handleAnalysisFailure(prompt)
        }
    }
}

func withTimeout<T>(_ timeout: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            throw AnalysisTimeoutError()
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

struct AnalysisTimeoutError: Error {}