import Foundation

struct ChatMessage: Identifiable, Codable, Hashable {
    enum Role: String, Codable {
        case user
        case assistant
        case system
    }

    let id: UUID
    let role: Role
    let content: String
    let createdAt: Date

    init(id: UUID = UUID(), role: Role, content: String, createdAt: Date = .now) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}

struct WorkspaceFile: Identifiable, Codable, Hashable {
    let id: UUID
    let filename: String
    let localURL: URL
    let addedAt: Date

    init(id: UUID = UUID(), filename: String, localURL: URL, addedAt: Date = .now) {
        self.id = id
        self.filename = filename
        self.localURL = localURL
        self.addedAt = addedAt
    }

    var ext: String {
        localURL.pathExtension.lowercased()
    }

    var isTextLike: Bool {
        let known = ["txt", "md", "json", "yaml", "yml", "swift", "js", "ts", "tsx", "jsx", "html", "css", "py", "rb", "go", "rs", "java", "c", "cpp", "h", "hpp", "xml", "toml", "ini", "csv"]
        return known.contains(ext)
    }
}

struct RemoteModel: Identifiable, Codable, Hashable {
    let id: UUID
    var displayName: String
    var sourceURL: String
    var localFilename: String
    var modelID: String
    var modelLib: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        displayName: String,
        sourceURL: String,
        modelID: String = "",
        modelLib: String = "",
        localFilename: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        self.sourceURL = sourceURL
        self.modelID = modelID
        self.modelLib = modelLib
        self.localFilename = localFilename ?? Self.suggestedFilename(from: sourceURL, fallback: displayName)
        self.createdAt = createdAt
    }

    static func suggestedFilename(from sourceURL: String, fallback: String) -> String {
        if let url = URL(string: sourceURL) {
            let candidate = url.lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines)
            if !candidate.isEmpty { return candidate }
        }
        return fallback.replacingOccurrences(of: " ", with: "-").lowercased()
    }
}

struct InstalledModel: Identifiable, Codable, Hashable {
    let id: UUID
    let displayName: String
    let localFilename: String
    let localURL: URL
    let fileSizeBytes: Int64
    let addedAt: Date
    let modelID: String
    let modelLib: String

    init(
        id: UUID = UUID(),
        displayName: String,
        localFilename: String,
        localURL: URL,
        fileSizeBytes: Int64,
        addedAt: Date = .now,
        modelID: String = "",
        modelLib: String = ""
    ) {
        self.id = id
        self.displayName = displayName
        self.localFilename = localFilename
        self.localURL = localURL
        self.fileSizeBytes = fileSizeBytes
        self.addedAt = addedAt
        self.modelID = modelID
        self.modelLib = modelLib
    }
}

struct InstalledModelDescriptor: Codable, Hashable {
    var filename: String
    var displayName: String
    var modelID: String
    var modelLib: String
}

struct RuntimeSelection: Codable, Hashable {
    var selectedInstalledFilename: String?
}

struct EngineRuntimeConfig: Sendable {
    let modelURL: URL
    let modelID: String
    let modelLib: String
}
