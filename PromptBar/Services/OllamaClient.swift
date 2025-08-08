import Foundation

struct OllamaClient {
    private let baseURL: URL
    private let session: URLSession
    private let timeout: TimeInterval = 10.0
    
    init(baseURL: String = "http://localhost:11434") {
        self.baseURL = URL(string: baseURL)!
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: config)
    }
    
    func analyzePrompt(_ prompt: Prompt) async -> AnalysisResult {
        do {
            let analysisPrompt = buildAnalysisPrompt(for: prompt)
            let request = try buildRequest(prompt: analysisPrompt)
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw OllamaError.invalidResponse
            }
            
            let ollamaResponse = try parseStreamingResponse(data)
            let analysis = parseAnalysisResponse(ollamaResponse)
            
            return AnalysisResult(
                category: analysis.category,
                tags: analysis.tags,
                description: analysis.description,
                confidence: analysis.confidence,
                status: .completed
            )
            
        } catch {
            print("Ollama analysis failed: \(error)")
            return AnalysisResult.fallback(for: prompt)
        }
    }
    
    func checkHealth() async -> Bool {
        do {
            let url = baseURL.appendingPathComponent("api/tags")
            let request = URLRequest(url: url)
            let (_, response) = try await session.data(for: request)
            
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    private func buildAnalysisPrompt(for prompt: Prompt) -> String {
        return """
        Analyze this prompt and provide meaningful categorization. Focus on what the prompt is trying to accomplish, not just summarizing its content.
        
        Title: \(prompt.title)
        Content: \(prompt.content)
        
        For the description field, explain the PURPOSE or GOAL, not just repeat the content. Examples:
        - "Helps create authentication system for web applications"
        - "Guides writing persuasive marketing copy"
        - "Assists with code review and debugging processes"
        
        Return as JSON with the specified schema.
        """
    }
    
    private func buildRequest(prompt: String) throws -> URLRequest {
        let url = baseURL.appendingPathComponent("api/chat")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = OllamaChatRequest(
            model: "llama3.2:latest",
            messages: [ChatMessage(role: "user", content: prompt)],
            stream: false,
            format: AnalysisSchema.jsonSchema(),
            options: OllamaOptions(temperature: 0.0)
        )
        
        request.httpBody = try JSONEncoder().encode(payload)
        return request
    }
    
    private func parseStreamingResponse(_ data: Data) throws -> String {
        guard let response = try? JSONDecoder().decode(OllamaChatResponse.self, from: data) else {
            throw OllamaError.decodingFailed
        }
        return response.message.content
    }
    
    private func parseAnalysisResponse(_ response: String) -> ParsedAnalysis {
        do {
            let cleanResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let jsonData = extractJSON(from: cleanResponse) {
                let analysis = try JSONDecoder().decode(ParsedAnalysis.self, from: jsonData)
                return analysis
            }
            
            return ParsedAnalysis.fallback()
        } catch {
            print("JSON parsing failed: \(error)")
            return ParsedAnalysis.fallback()
        }
    }
    
    private func extractJSON(from text: String) -> Data? {
        if text.hasPrefix("{") && text.hasSuffix("}") {
            return text.data(using: .utf8)
        }
        
        let pattern = #"\{[^{}]*\}"#
        if let range = text.range(of: pattern, options: .regularExpression) {
            return String(text[range]).data(using: .utf8)
        }
        
        return nil
    }
}

struct OllamaRequest: Codable {
    let model: String
    let prompt: String
    let stream: Bool
    let options: OllamaOptions
}

struct OllamaOptions: Codable {
    let temperature: Double
}

struct OllamaResponse: Codable {
    let response: String
    let done: Bool
}

struct ParsedAnalysis: Codable {
    let category: String
    let tags: [String]
    let description: String
    let confidence: Double
    
    static func fallback() -> ParsedAnalysis {
        return ParsedAnalysis(
            category: "other",
            tags: ["untagged"],
            description: "Auto-generated prompt",
            confidence: 0.5
        )
    }
}

struct AnalysisResult {
    let category: String
    let tags: [String]
    let description: String
    let confidence: Double
    let status: AnalysisStatus
    
    static func fallback(for prompt: Prompt) -> AnalysisResult {
        let category = inferCategoryFromContent(prompt.content)
        let tags = extractTagsFromContent(prompt.content)
        
        return AnalysisResult(
            category: category,
            tags: tags,
            description: "Generated from content analysis",
            confidence: 0.3,
            status: .fallback
        )
    }
    
    private static func inferCategoryFromContent(_ content: String) -> String {
        let lowercased = content.lowercased()
        
        if lowercased.contains("code") || lowercased.contains("function") || lowercased.contains("class") {
            return "coding"
        } else if lowercased.contains("write") || lowercased.contains("essay") || lowercased.contains("article") {
            return "writing"
        } else if lowercased.contains("business") || lowercased.contains("meeting") || lowercased.contains("proposal") {
            return "business"
        } else if lowercased.contains("creative") || lowercased.contains("story") || lowercased.contains("poem") {
            return "creative"
        } else {
            return "other"
        }
    }
    
    private static func extractTagsFromContent(_ content: String) -> [String] {
        let words = content.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let commonWords = Set(["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by"])
        
        let significantWords = words.filter { word in
            word.count > 3 && !commonWords.contains(word)
        }
        
        return Array(Set(significantWords.prefix(3)))
    }
}

enum AnalysisStatus: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case fallback = "fallback"
}

enum OllamaError: LocalizedError {
    case networkError
    case invalidResponse
    case decodingFailed
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection failed"
        case .invalidResponse:
            return "Invalid response from Ollama"
        case .decodingFailed:
            return "Failed to decode response"
        case .timeout:
            return "Request timed out"
        }
    }
}

// MARK: - New Structured Output Types

struct OllamaChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let stream: Bool
    let format: JSONSchema
    let options: OllamaOptions
}

struct JSONSchema: Codable {
    let type: String
    let properties: [String: PropertySchema]
    let required: [String]
    let additionalProperties: Bool
}

struct PropertySchema: Codable {
    let type: String
    let enumValues: [String]?
    let items: ItemsSchema?
    let maxItems: Int?
    let minItems: Int?
    let minLength: Int?
    let maxLength: Int?
    let minimum: Double?
    let maximum: Double?
    
    enum CodingKeys: String, CodingKey {
        case type, items, maxItems, minItems, minLength, maxLength, minimum, maximum
        case enumValues = "enum"
    }
}

struct ItemsSchema: Codable {
    let type: String
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct OllamaChatResponse: Codable {
    let message: ChatMessage
    let done: Bool
}

struct AnalysisSchema {
    static func jsonSchema() -> JSONSchema {
        return JSONSchema(
            type: "object",
            properties: [
                "category": PropertySchema(
                    type: "string",
                    enumValues: ["coding", "writing", "business", "creative", "personal", "other"],
                    items: nil,
                    maxItems: nil,
                    minItems: nil,
                    minLength: nil,
                    maxLength: nil,
                    minimum: nil,
                    maximum: nil
                ),
                "tags": PropertySchema(
                    type: "array",
                    enumValues: nil,
                    items: ItemsSchema(type: "string"),
                    maxItems: 5,
                    minItems: 1,
                    minLength: nil,
                    maxLength: nil,
                    minimum: nil,
                    maximum: nil
                ),
                "description": PropertySchema(
                    type: "string",
                    enumValues: nil,
                    items: nil,
                    maxItems: nil,
                    minItems: nil,
                    minLength: 10,
                    maxLength: 200,
                    minimum: nil,
                    maximum: nil
                ),
                "confidence": PropertySchema(
                    type: "number",
                    enumValues: nil,
                    items: nil,
                    maxItems: nil,
                    minItems: nil,
                    minLength: nil,
                    maxLength: nil,
                    minimum: 0.0,
                    maximum: 1.0
                )
            ],
            required: ["category", "tags", "description", "confidence"],
            additionalProperties: false
        )
    }
}