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
        id: UUID,
        title: String,
        content: String,
        description: String?,
        tags: [Tag],
        isFavorite: Bool,
        createdAt: Date,
        modifiedAt: Date,
        usedCount: Int,
        lastUsedAt: Date?,
        category: String?,
        analysisStatus: AnalysisStatus,
        analysisConfidence: Double?,
        analysisDescription: String?
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.description = description
        self.tags = tags
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.usedCount = usedCount
        self.lastUsedAt = lastUsedAt
        self.category = category
        self.analysisStatus = analysisStatus
        self.analysisConfidence = analysisConfidence
        self.analysisDescription = analysisDescription
    }

    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        description: String? = nil,
        tags: [Tag] = [],
        isFavorite: Bool = false
    ) {
        self.init(
            id: id,
            title: title,
            content: content,
            description: description,
            tags: tags,
            isFavorite: isFavorite,
            createdAt: Date(),
            modifiedAt: Date(),
            usedCount: 0,
            lastUsedAt: nil,
            category: nil,
            analysisStatus: .pending,
            analysisConfidence: nil,
            analysisDescription: nil
        )
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