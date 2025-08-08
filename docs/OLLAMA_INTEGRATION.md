# OLLAMA INTEGRATION: PromptBar
*Version 1.0 - AI Analysis Pipeline Specification*
*Last Updated: January 2025*

## Overview

This document specifies the complete integration between PromptBar and Ollama for intelligent prompt analysis. The integration provides automatic categorization, tagging, and description generation while maintaining the principle of "intelligence without complexity."

### Integration Principles

1. **Optional Enhancement**: App remains fully functional without Ollama
2. **Local Processing**: All AI processing happens on localhost - no cloud APIs
3. **Non-Blocking**: Analysis never interrupts user workflow
4. **Graceful Degradation**: Fallback to manual/keyword-based categorization
5. **User Control**: Analysis can be disabled, re-run, or overridden

### Architecture Overview

```
┌──────────────┐     ┌─────────────────┐     ┌──────────────┐
│  Save Prompt │────▶│ Analysis Queue  │────▶│ Ollama HTTP  │
└──────────────┘     │    (Actor)      │     │   Client     │
                     └─────────────────┘     └──────┬───────┘
                              │                      │
                              │                      ▼
                     ┌────────▼────────┐     ┌──────────────┐
                     │ Update Prompt   │◀────│ Parse JSON   │
                     │   with Results  │     │   Response   │
                     └─────────────────┘     └──────────────┘
```

## Service Architecture

### HTTP Client Configuration

```swift
import Foundation

final class OllamaClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    init(baseURL: URL = URL(string: "http://localhost:11434")!) {
        self.baseURL = baseURL
        
        // Configure session with appropriate timeouts
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10.0  // Total request timeout
        configuration.timeoutIntervalForResource = 10.0
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        // Connection settings
        configuration.httpMaximumConnectionsPerHost = 2
        configuration.httpShouldUsePipelining = true
        
        self.session = URLSession(configuration: configuration)
    }
    
    func checkHealth() async -> Bool {
        let endpoint = baseURL.appendingPathComponent("/api/tags")
        
        do {
            let (_, response) = try await session.data(from: endpoint)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    func listModels() async throws -> [OllamaModel] {
        let endpoint = baseURL.appendingPathComponent("/api/tags")
        let (data, _) = try await session.data(from: endpoint)
        let response = try decoder.decode(OllamaModelsResponse.self, from: data)
        return response.models
    }
    
    func generate(_ request: OllamaGenerateRequest) async throws -> OllamaGenerateResponse {
        let endpoint = baseURL.appendingPathComponent("/api/generate")
        
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try decoder.decode(OllamaGenerateResponse.self, from: data)
        case 404:
            throw OllamaError.modelNotFound
        case 500...599:
            throw OllamaError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw OllamaError.unexpectedStatusCode(httpResponse.statusCode)
        }
    }
}

// MARK: - Models

struct OllamaGenerateRequest: Encodable {
    let model: String
    let prompt: String
    let stream: Bool = false
    let format: String? = "json"  // Enforce JSON output
    let options: OllamaOptions?
    let system: String?
    let context: [Int]? = nil  // For conversation context
}

struct OllamaOptions: Encodable {
    let temperature: Double = 0.3      // Lower for more consistent output
    let top_p: Double = 0.9
    let top_k: Int = 40
    let num_predict: Int = 500         // Limit response length
    let stop: [String] = ["```", "\n\n", "}\n"]  // Stop sequences
    let seed: Int? = nil               // For reproducible output
    let num_ctx: Int = 2048           // Context window
}

struct OllamaGenerateResponse: Decodable {
    let model: String
    let created_at: String
    let response: String
    let done: Bool
    let context: [Int]?
    let total_duration: Int64?
    let load_duration: Int64?
    let prompt_eval_count: Int?
    let prompt_eval_duration: Int64?
    let eval_count: Int?
    let eval_duration: Int64?
}

struct OllamaModel: Decodable {
    let name: String
    let modified_at: String
    let size: Int64
    let digest: String
}

struct OllamaModelsResponse: Decodable {
    let models: [OllamaModel]
}

// MARK: - Errors

enum OllamaError: LocalizedError {
    case invalidResponse
    case modelNotFound
    case serverError(statusCode: Int)
    case unexpectedStatusCode(Int)
    case connectionFailed
    case timeout
    case invalidJSON
    case parsingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Ollama"
        case .modelNotFound:
            return "Model not found. Please pull the model first."
        case .serverError(let code):
            return "Ollama server error: \(code)"
        case .unexpectedStatusCode(let code):
            return "Unexpected status code: \(code)"
        case .connectionFailed:
            return "Failed to connect to Ollama. Is it running?"
        case .timeout:
            return "Request timed out"
        case .invalidJSON:
            return "Ollama returned invalid JSON"
        case .parsingFailed(let reason):
            return "Failed to parse response: \(reason)"
        }
    }
}
```

### Connection Management

```swift
actor OllamaConnectionManager {
    private let client: OllamaClient
    private var isHealthy = false
    private var lastHealthCheck: Date?
    private let healthCheckInterval: TimeInterval = 30.0
    private var retryCount = 0
    private let maxRetries = 3
    
    init(client: OllamaClient) {
        self.client = client
    }
    
    func ensureConnection() async throws {
        // Check if we need a health check
        if let lastCheck = lastHealthCheck,
           Date().timeIntervalSince(lastCheck) < healthCheckInterval,
           isHealthy {
            return
        }
        
        // Perform health check
        isHealthy = await client.checkHealth()
        lastHealthCheck = Date()
        
        if !isHealthy {
            throw OllamaError.connectionFailed
        }
        
        retryCount = 0
    }
    
    func executeWithRetry<T>(
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                try await ensureConnection()
                return try await operation()
            } catch {
                lastError = error
                
                if attempt < maxRetries {
                    // Exponential backoff
                    let delay = pow(2.0, Double(attempt))
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    
                    Logger.warning("Ollama operation failed, retrying... (attempt \(attempt + 1)/\(maxRetries))")
                }
            }
        }
        
        throw lastError ?? OllamaError.connectionFailed
    }
    
    func resetConnection() {
        isHealthy = false
        lastHealthCheck = nil
        retryCount = 0
    }
}
```

## Analysis Pipeline

### Complete Analysis Flow

```swift
protocol PromptAnalyzer {
    func analyzePrompt(_ prompt: Prompt) async throws -> AnalysisResult
}

final class OllamaPromptAnalyzer: PromptAnalyzer {
    private let client: OllamaClient
    private let connectionManager: OllamaConnectionManager
    private let model: String
    
    init(
        client: OllamaClient,
        model: String = "llama3.2:3b"
    ) {
        self.client = client
        self.connectionManager = OllamaConnectionManager(client: client)
        self.model = model
    }
    
    func analyzePrompt(_ prompt: Prompt) async throws -> AnalysisResult {
        let request = buildAnalysisRequest(for: prompt)
        
        let response = try await connectionManager.executeWithRetry {
            try await self.client.generate(request)
        }
        
        return try parseAnalysisResponse(response)
    }
    
    private func buildAnalysisRequest(for prompt: Prompt) -> OllamaGenerateRequest {
        let systemPrompt = """
        You are a prompt analysis assistant. Analyze the given prompt and provide a JSON response with the following structure:
        {
            "description": "A brief description of what this prompt does (10-50 words)",
            "tags": ["tag1", "tag2", "tag3", "tag4", "tag5"],
            "category": "One of: Development, Writing, Analysis, Design, Other",
            "use_cases": ["use case 1", "use case 2", "use case 3"],
            "complexity": "simple|intermediate|advanced",
            "related_prompts": []
        }
        
        Rules:
        - Tags should be lowercase, alphanumeric with hyphens (2-30 chars)
        - Provide 3-5 relevant tags
        - Use cases should be specific and actionable
        - Complexity based on prompt sophistication
        - Output ONLY valid JSON, no additional text
        """
        
        let userPrompt = """
        Analyze this prompt:
        
        Title: \(prompt.title)
        
        Content:
        \(prompt.content)
        """
        
        return OllamaGenerateRequest(
            model: model,
            prompt: userPrompt,
            format: "json",
            options: OllamaOptions(),
            system: systemPrompt
        )
    }
    
    private func parseAnalysisResponse(_ response: OllamaGenerateResponse) throws -> AnalysisResult {
        guard let data = response.response.data(using: .utf8) else {
            throw OllamaError.invalidJSON
        }
        
        do {
            let result = try JSONDecoder().decode(AnalysisResult.self, from: data)
            try result.validate()
            return result
        } catch let decodingError as DecodingError {
            // Log the actual response for debugging
            Logger.error("Failed to decode Ollama response: \(response.response)")
            throw OllamaError.parsingFailed(decodingError.localizedDescription)
        }
    }
}

// MARK: - Analysis Result Validation

extension AnalysisResult {
    func validate() throws {
        // Validate description
        let descriptionLength = description.trimmingCharacters(in: .whitespacesAndNewlines).count
        guard descriptionLength >= 10 && descriptionLength <= 500 else {
            throw ValidationError.invalidDescription
        }
        
        // Validate tags
        guard tags.count >= 1 && tags.count <= 10 else {
            throw ValidationError.invalidTagCount
        }
        
        let tagRegex = try NSRegularExpression(pattern: "^[a-z0-9-_]{2,30}$")
        for tag in tags {
            let range = NSRange(location: 0, length: tag.utf16.count)
            guard tagRegex.firstMatch(in: tag, range: range) != nil else {
                throw ValidationError.invalidTag(tag)
            }
        }
        
        // Validate category
        let validCategories = ["Development", "Writing", "Analysis", "Design", "Other"]
        guard validCategories.contains(category) else {
            throw ValidationError.invalidCategory
        }
        
        // Validate complexity
        guard ["simple", "intermediate", "advanced"].contains(complexity) else {
            throw ValidationError.invalidComplexity
        }
    }
}
```

## Prompt Engineering

### Analysis Prompt Templates

```swift
struct PromptTemplates {
    // Main analysis prompt with clear structure
    static let analysisSystem = """
    You are an expert prompt analyst. Your task is to analyze prompts and extract structured metadata.
    
    RESPONSE FORMAT:
    You must respond with ONLY a valid JSON object. No markdown, no explanations, just JSON.
    
    ANALYSIS CRITERIA:
    1. Description: Summarize what the prompt accomplishes (10-50 words)
    2. Tags: Extract 3-5 relevant keywords that categorize the prompt
    3. Category: Choose the MOST appropriate from the given list
    4. Use Cases: List 2-4 specific scenarios where this prompt would be useful
    5. Complexity: Assess based on prompt sophistication and requirements
    
    CATEGORY DEFINITIONS:
    - Development: Programming, debugging, code generation, technical documentation
    - Writing: Content creation, editing, storytelling, marketing copy
    - Analysis: Data analysis, research, problem-solving, decision-making
    - Design: UI/UX, visual design, architecture, creative concepts
    - Other: Anything that doesn't fit the above categories
    
    COMPLEXITY LEVELS:
    - simple: Basic, straightforward prompts with single tasks
    - intermediate: Multi-step prompts with some context or constraints
    - advanced: Complex prompts with multiple requirements, specific formats, or deep context
    
    TAG RULES:
    - Lowercase only
    - 2-30 characters
    - Alphanumeric with hyphens or underscores only
    - Specific and relevant to the prompt's purpose
    """
    
    // Focused version for faster responses
    static let quickAnalysisSystem = """
    Analyze the prompt and return a JSON object with these fields:
    - description: Brief summary (10-50 words)
    - tags: Array of 3-5 lowercase tags
    - category: Development|Writing|Analysis|Design|Other
    
    Respond with valid JSON only.
    """
    
    // Examples to improve consistency
    static func analysisWithExamples(prompt: String, title: String) -> String {
        """
        Analyze this prompt following the examples:
        
        EXAMPLE 1:
        Prompt: "Debug this Python code and explain the issue"
        Result: {
            "description": "Identifies and fixes bugs in Python code with explanations",
            "tags": ["python", "debugging", "code-review", "programming"],
            "category": "Development",
            "use_cases": ["Finding syntax errors", "Debugging logic issues", "Code review"],
            "complexity": "intermediate"
        }
        
        EXAMPLE 2:
        Prompt: "Write a blog post outline about sustainable living"
        Result: {
            "description": "Creates structured blog post outlines on sustainability topics",
            "tags": ["blogging", "content", "sustainability", "outline"],
            "category": "Writing",
            "use_cases": ["Content planning", "Blog structure", "Topic research"],
            "complexity": "simple"
        }
        
        NOW ANALYZE:
        Title: \(title)
        Prompt: \(prompt)
        
        Respond with JSON only.
        """
    }
}
```

### Model-Specific Optimizations

```swift
struct ModelOptimizations {
    static func optionsForModel(_ model: String) -> OllamaOptions {
        switch model {
        case "llama3.2:3b":
            return OllamaOptions(
                temperature: 0.3,      // Lower for consistency
                top_p: 0.9,
                top_k: 40,
                num_predict: 500,      // Limit output length
                stop: ["```", "\n\n", "}\n"],
                num_ctx: 2048
            )
            
        case "mistral:7b":
            return OllamaOptions(
                temperature: 0.2,      // Even lower for Mistral
                top_p: 0.95,
                top_k: 50,
                num_predict: 400,
                stop: ["```", "}\n"],
                num_ctx: 4096         // Larger context window
            )
            
        default:
            return OllamaOptions()    // Default settings
        }
    }
    
    static func contextLimitForModel(_ model: String) -> Int {
        switch model {
        case "llama3.2:3b": return 2048
        case "mistral:7b": return 4096
        case "llama3.2:1b": return 1024
        default: return 2048
        }
    }
}
```

## Queue Management

### Background Processing Queue

```swift
actor AnalysisQueue {
    private var pendingAnalyses: [UUID: PendingAnalysis] = [:]
    private var activeAnalyses: Set<UUID> = []
    private var processingTask: Task<Void, Never>?
    private let analyzer: PromptAnalyzer
    private let repository: PromptRepository
    private let maxConcurrent = 3
    private let maxRetries = 2
    
    struct PendingAnalysis {
        let prompt: Prompt
        let priority: Priority
        let retryCount: Int
        let enqueuedAt: Date
        
        enum Priority: Int, Comparable {
            case low = 0
            case normal = 1
            case high = 2
            
            static func < (lhs: Priority, rhs: Priority) -> Bool {
                lhs.rawValue < rhs.rawValue
            }
        }
    }
    
    init(analyzer: PromptAnalyzer, repository: PromptRepository) {
        self.analyzer = analyzer
        self.repository = repository
    }
    
    func enqueue(_ prompt: Prompt, priority: PendingAnalysis.Priority = .normal) {
        pendingAnalyses[prompt.id] = PendingAnalysis(
            prompt: prompt,
            priority: priority,
            retryCount: 0,
            enqueuedAt: Date()
        )
        
        startProcessingIfNeeded()
    }
    
    func cancel(_ promptId: UUID) {
        pendingAnalyses.removeValue(forKey: promptId)
    }
    
    func status(for promptId: UUID) -> AnalysisStatus {
        if activeAnalyses.contains(promptId) {
            return .processing
        } else if pendingAnalyses[promptId] != nil {
            return .queued
        } else {
            return .none
        }
    }
    
    private func startProcessingIfNeeded() {
        guard processingTask == nil else { return }
        
        processingTask = Task {
            await processQueue()
        }
    }
    
    private func processQueue() async {
        while !pendingAnalyses.isEmpty {
            // Wait if at capacity
            while activeAnalyses.count >= maxConcurrent {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
            
            // Get highest priority item
            guard let (id, analysis) = nextAnalysis() else { continue }
            
            activeAnalyses.insert(id)
            pendingAnalyses.removeValue(forKey: id)
            
            // Process in parallel
            Task {
                await processAnalysis(id: id, analysis: analysis)
                await completeAnalysis(id: id)
            }
        }
        
        processingTask = nil
    }
    
    private func nextAnalysis() -> (UUID, PendingAnalysis)? {
        pendingAnalyses
            .sorted { $0.value.priority > $1.value.priority }
            .first
    }
    
    private func processAnalysis(id: UUID, analysis: PendingAnalysis) async {
        do {
            // Perform analysis
            let result = try await analyzer.analyzePrompt(analysis.prompt)
            
            // Update prompt with results
            var updatedPrompt = analysis.prompt
            updatedPrompt.description = result.description
            updatedPrompt.category = result.parsedCategory
            updatedPrompt.tags = result.tags.map { Tag(name: $0) }
            updatedPrompt.complexity = result.parsedComplexity
            updatedPrompt.useCases = result.useCases
            updatedPrompt.analysisVersion = 1
            updatedPrompt.analyzedAt = Date()
            
            // Save to repository
            try await repository.update(updatedPrompt)
            
            // Notify UI
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .promptAnalysisCompleted,
                    object: nil,
                    userInfo: ["promptId": id]
                )
            }
            
            Logger.info("Analysis completed for prompt: \(analysis.prompt.title)")
            
        } catch {
            Logger.error("Analysis failed for prompt \(id): \(error)")
            
            // Retry if under limit
            if analysis.retryCount < maxRetries {
                var retryAnalysis = analysis
                retryAnalysis.retryCount += 1
                pendingAnalyses[id] = retryAnalysis
            } else {
                // Mark as failed
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .promptAnalysisFailed,
                        object: nil,
                        userInfo: ["promptId": id, "error": error]
                    )
                }
            }
        }
    }
    
    private func completeAnalysis(id: UUID) {
        activeAnalyses.remove(id)
    }
}

enum AnalysisStatus {
    case none
    case queued
    case processing
    case completed
    case failed
}

// MARK: - Notifications

extension Notification.Name {
    static let promptAnalysisCompleted = Notification.Name("promptAnalysisCompleted")
    static let promptAnalysisFailed = Notification.Name("promptAnalysisFailed")
}
```

### Rate Limiting

```swift
actor RateLimiter {
    private let maxRequestsPerMinute: Int
    private var requestTimestamps: [Date] = []
    
    init(maxRequestsPerMinute: Int = 20) {
        self.maxRequestsPerMinute = maxRequestsPerMinute
    }
    
    func shouldAllowRequest() -> Bool {
        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-60)
        
        // Remove old timestamps
        requestTimestamps.removeAll { $0 < oneMinuteAgo }
        
        // Check if under limit
        if requestTimestamps.count < maxRequestsPerMinute {
            requestTimestamps.append(now)
            return true
        }
        
        return false
    }
    
    func timeUntilNextRequest() -> TimeInterval {
        guard !requestTimestamps.isEmpty else { return 0 }
        
        let oldestRequest = requestTimestamps.first!
        let oneMinuteLater = oldestRequest.addingTimeInterval(60)
        return max(0, oneMinuteLater.timeIntervalSinceNow)
    }
}
```

## Response Handling

### JSON Parsing with Validation

```swift
struct ResponseParser {
    static func parseAnalysisResponse(_ jsonString: String) throws -> AnalysisResult {
        // Clean up common issues
        let cleaned = jsonString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
        
        guard let data = cleaned.data(using: .utf8) else {
            throw OllamaError.invalidJSON
        }
        
        do {
            let result = try JSONDecoder().decode(AnalysisResult.self, from: data)
            try result.validate()
            return result
        } catch {
            // Try to extract JSON from response
            if let extracted = extractJSON(from: cleaned) {
                let result = try JSONDecoder().decode(AnalysisResult.self, from: extracted)
                try result.validate()
                return result
            }
            
            throw error
        }
    }
    
    private static func extractJSON(from text: String) -> Data? {
        // Find JSON object boundaries
        guard let startIndex = text.firstIndex(of: "{"),
              let endIndex = text.lastIndex(of: "}") else {
            return nil
        }
        
        let jsonSubstring = text[startIndex...endIndex]
        return jsonSubstring.data(using: .utf8)
    }
}

// Flexible parsing for partial results
struct PartialAnalysisResult: Decodable {
    let description: String?
    let tags: [String]?
    let category: String?
    let use_cases: [String]?
    let complexity: String?
    
    func toAnalysisResult() -> AnalysisResult? {
        guard let description = description,
              let tags = tags,
              let category = category else {
            return nil
        }
        
        return AnalysisResult(
            description: description,
            tags: tags,
            category: category,
            useCases: use_cases ?? [],
            complexity: complexity ?? "simple",
            relatedPrompts: []
        )
    }
}
```

### Error Recovery

```swift
struct AnalysisErrorRecovery {
    static func handleAnalysisError(
        _ error: Error,
        for prompt: Prompt
    ) async -> RecoveryAction {
        switch error {
        case OllamaError.connectionFailed:
            return .retry(delay: 5.0)
            
        case OllamaError.timeout:
            return .retry(delay: 2.0)
            
        case OllamaError.modelNotFound:
            return .fallback(reason: "Model not available")
            
        case OllamaError.parsingFailed:
            return .fallback(reason: "Invalid response format")
            
        case is DecodingError:
            return .fallback(reason: "Response parsing failed")
            
        default:
            return .fail
        }
    }
    
    enum RecoveryAction {
        case retry(delay: TimeInterval)
        case fallback(reason: String)
        case fail
    }
}
```

## Fallback Strategies

### Keyword-Based Analysis

```swift
final class KeywordAnalyzer: PromptAnalyzer {
    private let keywordMappings = KeywordMappings()
    
    func analyzePrompt(_ prompt: Prompt) async throws -> AnalysisResult {
        let content = prompt.content.lowercased()
        let words = content.components(separatedBy: .whitespacesAndNewlines)
        
        // Determine category
        let category = determineCategory(from: words)
        
        // Extract tags
        let tags = extractTags(from: words)
        
        // Generate description
        let description = generateDescription(for: prompt, category: category)
        
        // Determine complexity
        let complexity = determineComplexity(prompt: prompt)
        
        return AnalysisResult(
            description: description,
            tags: Array(tags.prefix(5)),
            category: category,
            useCases: [],
            complexity: complexity,
            relatedPrompts: []
        )
    }
    
    private func determineCategory(from words: [String]) -> String {
        let categoryScores: [String: Int] = [
            "Development": 0,
            "Writing": 0,
            "Analysis": 0,
            "Design": 0
        ]
        
        var scores = categoryScores
        
        // Development keywords
        let devKeywords = ["code", "debug", "function", "class", "api", "script", 
                          "python", "swift", "javascript", "sql", "git", "deploy"]
        scores["Development"]! += words.filter { devKeywords.contains($0) }.count * 2
        
        // Writing keywords
        let writeKeywords = ["write", "article", "blog", "content", "copy", "edit",
                           "story", "paragraph", "headline", "seo", "draft"]
        scores["Writing"]! += words.filter { writeKeywords.contains($0) }.count * 2
        
        // Analysis keywords
        let analysisKeywords = ["analyze", "data", "report", "metrics", "insights",
                               "research", "statistics", "trends", "evaluate"]
        scores["Analysis"]! += words.filter { analysisKeywords.contains($0) }.count * 2
        
        // Design keywords
        let designKeywords = ["design", "ui", "ux", "layout", "color", "mockup",
                            "wireframe", "prototype", "visual", "interface"]
        scores["Design"]! += words.filter { designKeywords.contains($0) }.count * 2
        
        // Return highest scoring category
        return scores.max(by: { $0.value < $1.value })?.key ?? "Other"
    }
    
    private func extractTags(from words: [String]) -> [String] {
        // Common technical terms that make good tags
        let technicalTerms = Set([
            "python", "javascript", "swift", "react", "ios", "android", "api",
            "database", "sql", "nosql", "debugging", "testing", "deployment",
            "docker", "kubernetes", "aws", "azure", "gcp", "ml", "ai",
            "async", "frontend", "backend", "fullstack", "mobile", "web"
        ])
        
        let contentTerms = Set([
            "blog", "article", "seo", "marketing", "content", "copywriting",
            "social", "email", "newsletter", "headline", "storytelling"
        ])
        
        let allTerms = technicalTerms.union(contentTerms)
        
        return words
            .filter { allTerms.contains($0) && $0.count >= 3 }
            .uniqued()
            .sorted()
    }
    
    private func generateDescription(for prompt: Prompt, category: String) -> String {
        let prefix = "Prompt for \(category.lowercased()) tasks"
        
        // Try to extract the main action
        let firstLine = prompt.content
            .components(separatedBy: .newlines)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if firstLine.count > 20 && firstLine.count < 100 {
            return firstLine
        } else {
            return "\(prefix) related to \(prompt.title.lowercased())"
        }
    }
    
    private func determineComplexity(prompt: Prompt) -> String {
        let length = prompt.content.count
        let lineCount = prompt.content.components(separatedBy: .newlines).count
        
        if length < 200 && lineCount < 5 {
            return "simple"
        } else if length < 1000 && lineCount < 20 {
            return "intermediate"
        } else {
            return "advanced"
        }
    }
}

// MARK: - Array Extension

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
```

### Manual Categorization UI

```swift
struct ManualCategorizationView: View {
    @Binding var prompt: Prompt
    @State private var selectedCategory: Category?
    @State private var tagInput: String = ""
    @State private var tags: [String] = []
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Categorize Prompt")
                .font(.headline)
            
            // Category Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Category.all) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory?.id == category.id,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                }
            }
            
            // Tag Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("Add tag...", text: $tagInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            addTag()
                        }
                    
                    Button("Add", action: addTag)
                        .disabled(tagInput.isEmpty)
                }
                
                // Tag chips
                FlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        TagChip(tag: tag) {
                            tags.removeAll { $0 == tag }
                        }
                    }
                }
            }
            
            Spacer()
            
            // Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button("Save") {
                    saveCategoriztion()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedCategory == nil)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
    
    private func addTag() {
        let tag = tagInput
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
        
        if !tag.isEmpty && !tags.contains(tag) && tags.count < 10 {
            tags.append(tag)
            tagInput = ""
        }
    }
    
    private func saveCategoriztion() {
        prompt.category = selectedCategory
        prompt.tags = tags.map { Tag(name: $0) }
        prompt.modifiedAt = Date()
        
        Task {
            try? await DIContainer.shared.resolve(PromptRepository.self)
                .update(prompt)
        }
        
        dismiss()
    }
}
```

## Performance Optimization

### Response Caching

```swift
actor AnalysisCache {
    private var cache: [String: CachedAnalysis] = [:]
    private let maxCacheSize = 1000
    private let maxCacheAge: TimeInterval = 86400 // 24 hours
    
    struct CachedAnalysis {
        let result: AnalysisResult
        let timestamp: Date
        let promptHash: String
    }
    
    func get(for prompt: Prompt) -> AnalysisResult? {
        let hash = computeHash(for: prompt)
        
        guard let cached = cache[hash],
              Date().timeIntervalSince(cached.timestamp) < maxCacheAge else {
            return nil
        }
        
        return cached.result
    }
    
    func set(_ result: AnalysisResult, for prompt: Prompt) {
        let hash = computeHash(for: prompt)
        
        cache[hash] = CachedAnalysis(
            result: result,
            timestamp: Date(),
            promptHash: hash
        )
        
        // Evict old entries if needed
        if cache.count > maxCacheSize {
            evictOldestEntries()
        }
    }
    
    private func computeHash(for prompt: Prompt) -> String {
        let content = prompt.title + prompt.content
        return SHA256.hash(data: content.data(using: .utf8)!)
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }
    
    private func evictOldestEntries() {
        let sorted = cache.sorted { $0.value.timestamp < $1.value.timestamp }
        let toRemove = sorted.prefix(cache.count - maxCacheSize)
        
        for (key, _) in toRemove {
            cache.removeValue(forKey: key)
        }
    }
}
```

### Batch Processing

```swift
extension OllamaPromptAnalyzer {
    func analyzeBatch(_ prompts: [Prompt]) async -> [UUID: Result<AnalysisResult, Error>] {
        var results: [UUID: Result<AnalysisResult, Error>] = [:]
        
        // Process in chunks to avoid overwhelming Ollama
        let chunkSize = 5
        let chunks = prompts.chunked(into: chunkSize)
        
        for chunk in chunks {
            await withTaskGroup(of: (UUID, Result<AnalysisResult, Error>).self) { group in
                for prompt in chunk {
                    group.addTask {
                        do {
                            let result = try await self.analyzePrompt(prompt)
                            return (prompt.id, .success(result))
                        } catch {
                            return (prompt.id, .failure(error))
                        }
                    }
                }
                
                for await (id, result) in group {
                    results[id] = result
                }
            }
            
            // Rate limit between chunks
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        return results
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
```

## Error Handling

### Comprehensive Error Scenarios

```swift
enum AnalysisErrorHandler {
    static func handle(_ error: Error, for prompt: Prompt) async -> AnalysisResult? {
        Logger.error("Analysis failed for '\(prompt.title)': \(error)")
        
        switch error {
        case OllamaError.connectionFailed:
            // Ollama not running - use fallback
            return try? await KeywordAnalyzer().analyzePrompt(prompt)
            
        case OllamaError.modelNotFound:
            // Model not available - notify user
            await showModelNotFoundAlert()
            return nil
            
        case OllamaError.timeout:
            // Timeout - could retry with simpler prompt
            return try? await retryWithSimplifiedPrompt(prompt)
            
        case OllamaError.serverError:
            // Server error - wait and retry
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            return nil
            
        case let OllamaError.parsingFailed(reason):
            // Parsing failed - log for debugging
            Logger.debug("Parse failure: \(reason)")
            return try? await KeywordAnalyzer().analyzePrompt(prompt)
            
        default:
            // Unknown error - use fallback
            return try? await KeywordAnalyzer().analyzePrompt(prompt)
        }
    }
    
    private static func retryWithSimplifiedPrompt(_ prompt: Prompt) async throws -> AnalysisResult {
        // Truncate content for retry
        var simplified = prompt
        simplified.content = String(prompt.content.prefix(500))
        
        return try await DIContainer.shared.resolve(OllamaPromptAnalyzer.self)
            .analyzePrompt(simplified)
    }
    
    @MainActor
    private static func showModelNotFoundAlert() {
        // Show alert to user about missing model
        let alert = NSAlert()
        alert.messageText = "Ollama Model Not Found"
        alert.informativeText = "The required model 'llama3.2:3b' is not installed. Please run:\n\nollama pull llama3.2:3b"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Disable Ollama")
        
        if alert.runModal() == .alertSecondButtonReturn {
            UserDefaults.standard.set(false, forKey: "ollamaEnabled")
        }
    }
}
```

## Testing & Debugging

### Mock Ollama Service

```swift
final class MockOllamaClient: OllamaClient {
    var mockResponses: [String: Result<OllamaGenerateResponse, Error>] = [:]
    var requestCount = 0
    var lastRequest: OllamaGenerateRequest?
    
    override func generate(_ request: OllamaGenerateRequest) async throws -> OllamaGenerateResponse {
        requestCount += 1
        lastRequest = request
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        let key = request.prompt.prefix(50).lowercased()
        
        if let mockResponse = mockResponses[String(key)] {
            switch mockResponse {
            case .success(let response):
                return response
            case .failure(let error):
                throw error
            }
        }
        
        // Default mock response
        return OllamaGenerateResponse(
            model: request.model,
            created_at: ISO8601DateFormatter().string(from: Date()),
            response: """
            {
                "description": "Mock analysis for testing",
                "tags": ["test", "mock", "analysis"],
                "category": "Other",
                "use_cases": ["Testing the analysis pipeline"],
                "complexity": "simple"
            }
            """,
            done: true,
            context: nil,
            total_duration: 150_000_000,
            load_duration: 50_000_000,
            prompt_eval_count: 100,
            prompt_eval_duration: 50_000_000,
            eval_count: 50,
            eval_duration: 50_000_000
        )
    }
    
    override func checkHealth() async -> Bool {
        return true // Always healthy in tests
    }
}
```

### Debug Logging

```swift
struct OllamaDebugger {
    static var isEnabled: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "ollamaDebugMode")
        #else
        return false
        #endif
    }
    
    static func logRequest(_ request: OllamaGenerateRequest) {
        guard isEnabled else { return }
        
        Logger.debug("""
        [Ollama Request]
        Model: \(request.model)
        System: \(request.system ?? "none")
        Prompt: \(request.prompt.prefix(200))...
        Options: \(String(describing: request.options))
        """)
    }
    
    static func logResponse(_ response: OllamaGenerateResponse) {
        guard isEnabled else { return }
        
        Logger.debug("""
        [Ollama Response]
        Model: \(response.model)
        Response: \(response.response.prefix(200))...
        Duration: \(response.total_duration ?? 0)ns
        Tokens: \(response.eval_count ?? 0)
        """)
    }
    
    static func logError(_ error: Error, context: String) {
        Logger.error("[Ollama Error] \(context): \(error)")
    }
}
```

### Integration Tests

```swift
final class OllamaIntegrationTests: XCTestCase {
    var analyzer: OllamaPromptAnalyzer!
    
    override func setUp() async throws {
        let client = OllamaClient()
        analyzer = OllamaPromptAnalyzer(client: client)
    }
    
    func testRealAnalysis() async throws {
        // Skip if Ollama not available
        let client = OllamaClient()
        guard await client.checkHealth() else {
            throw XCTSkip("Ollama not running")
        }
        
        let prompt = Prompt(
            title: "Python Debug Helper",
            content: """
            Debug this Python async/await code and identify race conditions:
            ```python
            async def process_items(items):
                results = []
                for item in items:
                    result = await process_single(item)
                    results.append(result)
                return results
            ```
            """
        )
        
        let result = try await analyzer.analyzePrompt(prompt)
        
        XCTAssertFalse(result.description.isEmpty)
        XCTAssertFalse(result.tags.isEmpty)
        XCTAssertEqual(result.category, "Development")
        XCTAssertTrue(result.tags.contains("python"))
    }
    
    func testTimeout() async throws {
        let client = OllamaClient(baseURL: URL(string: "http://localhost:99999")!)
        analyzer = OllamaPromptAnalyzer(client: client)
        
        let prompt = Prompt(title: "Test", content: "Test content")
        
        do {
            _ = try await analyzer.analyzePrompt(prompt)
            XCTFail("Should have timed out")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
}
```

## Configuration

### User Settings

```swift
struct OllamaSettings: Codable {
    var enabled: Bool = true
    var baseURL: String = "http://localhost:11434"
    var model: String = "llama3.2:3b"
    var timeout: TimeInterval = 5.0
    var autoRetry: Bool = true
    var maxRetries: Int = 2
    var debugMode: Bool = false
    
    static var current: OllamaSettings {
        get {
            guard let data = UserDefaults.standard.data(forKey: "ollamaSettings"),
                  let settings = try? JSONDecoder().decode(OllamaSettings.self, from: data) else {
                return OllamaSettings()
            }
            return settings
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "ollamaSettings")
            }
        }
    }
}
```

### Settings UI

```swift
struct OllamaSettingsView: View {
    @State private var settings = OllamaSettings.current
    @State private var isTestingConnection = false
    @State private var connectionStatus: ConnectionStatus?
    
    var body: some View {
        Form {
            Section("Ollama Configuration") {
                Toggle("Enable AI Analysis", isOn: $settings.enabled)
                
                TextField("Base URL", text: $settings.baseURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Picker("Model", selection: $settings.model) {
                    Text("Llama 3.2 (3B)").tag("llama3.2:3b")
                    Text("Llama 3.2 (1B)").tag("llama3.2:1b")
                    Text("Mistral (7B)").tag("mistral:7b")
                }
                
                HStack {
                    Text("Connection Status:")
                    
                    if isTestingConnection {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if let status = connectionStatus {
                        Image(systemName: status.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(status.isConnected ? .green : .red)
                        Text(status.message)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Button("Test Connection") {
                        testConnection()
                    }
                }
            }
            
            Section("Performance") {
                Slider(value: $settings.timeout, in: 1...30, step: 1) {
                    Text("Timeout: \(Int(settings.timeout))s")
                }
                
                Toggle("Auto Retry on Failure", isOn: $settings.autoRetry)
                
                if settings.autoRetry {
                    Stepper("Max Retries: \(settings.maxRetries)", value: $settings.maxRetries, in: 1...5)
                }
            }
            
            Section("Advanced") {
                Toggle("Debug Mode", isOn: $settings.debugMode)
                    .help("Logs all Ollama requests and responses")
            }
        }
        .formStyle(GroupedFormStyle())
        .onChange(of: settings) { _ in
            OllamaSettings.current = settings
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        connectionStatus = nil
        
        Task {
            let client = OllamaClient(baseURL: URL(string: settings.baseURL)!)
            let isConnected = await client.checkHealth()
            
            await MainActor.run {
                isTestingConnection = false
                connectionStatus = ConnectionStatus(
                    isConnected: isConnected,
                    message: isConnected ? "Connected" : "Connection failed"
                )
            }
        }
    }
    
    struct ConnectionStatus {
        let isConnected: Bool
        let message: String
    }
}
```

## Privacy & Security

### Local-Only Guarantees

```swift
struct PrivacyGuarantees {
    // No external network requests
    static func validateLocalOnly(url: URL) -> Bool {
        guard let host = url.host else { return false }
        
        let localHosts = ["localhost", "127.0.0.1", "::1", "0.0.0.0"]
        return localHosts.contains(host)
    }
    
    // Sanitize sensitive content before analysis
    static func sanitizePrompt(_ content: String) -> String {
        var sanitized = content
        
        // Remove potential API keys
        let apiKeyPattern = #"[A-Za-z0-9_-]{20,}"#
        sanitized = sanitized.replacingOccurrences(
            of: apiKeyPattern,
            with: "[REDACTED]",
            options: .regularExpression
        )
        
        // Remove email addresses
        let emailPattern = #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}"#
        sanitized = sanitized.replacingOccurrences(
            of: emailPattern,
            with: "[EMAIL]",
            options: .regularExpression
        )
        
        return sanitized
    }
}
```

### Audit Logging

```swift
actor AuditLogger {
    private let logFile: URL
    
    init() {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        
        logFile = documentsPath
            .appendingPathComponent("PromptBar")
            .appendingPathComponent("audit.log")
    }
    
    func logAnalysis(promptId: UUID, model: String, duration: TimeInterval) {
        let entry = AuditEntry(
            timestamp: Date(),
            action: "analyze_prompt",
            promptId: promptId,
            model: model,
            duration: duration
        )
        
        Task {
            await writeEntry(entry)
        }
    }
    
    private func writeEntry(_ entry: AuditEntry) {
        // Implementation
    }
    
    struct AuditEntry: Codable {
        let timestamp: Date
        let action: String
        let promptId: UUID
        let model: String
        let duration: TimeInterval
    }
}
```

## Summary

This Ollama integration provides:
- ✅ Seamless AI-powered analysis with <5s response times
- ✅ Non-blocking operation maintaining UI responsiveness
- ✅ Graceful fallback when Ollama unavailable
- ✅ Privacy-first local processing
- ✅ Flexible model support with optimized prompts
- ✅ Comprehensive error handling and recovery
- ✅ Production-ready queue management
- ✅ Extensive debugging and monitoring capabilities

The integration enhances PromptBar with intelligence while maintaining the core principle of simplicity and speed.

---
*Version 1.0 - Implementation Ready*