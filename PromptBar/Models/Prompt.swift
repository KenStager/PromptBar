import Foundation

struct Prompt: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var content: String
    var description: String?
    var tags: [Tag]
    var isFavorite: Bool
    let createdAt: Date
    var modifiedAt: Date
    var usedCount: Int
    var lastUsedAt: Date?
    
    // Analysis fields
    var category: String?
    var analysisStatus: AnalysisStatus
    var analysisConfidence: Double?
    var analysisDescription: String?
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        description: String? = nil,
        tags: [Tag] = [],
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.description = description
        self.tags = tags
        self.isFavorite = isFavorite
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.usedCount = 0
        self.lastUsedAt = nil
        
        // Initialize analysis fields
        self.category = nil
        self.analysisStatus = .pending
        self.analysisConfidence = nil
        self.analysisDescription = nil
    }
}

struct Tag: Identifiable, Equatable, Codable, Hashable {
    let id: Int?
    let name: String
    
    init(id: Int? = nil, name: String) {
        self.id = id
        self.name = name.lowercased()
    }
}