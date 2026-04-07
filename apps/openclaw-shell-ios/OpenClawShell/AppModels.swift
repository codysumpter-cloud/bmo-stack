import Foundation

// MARK: - Chat

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

// MARK: - Workspace

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

// MARK: - Models

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

// MARK: - Onboarding / Stack

struct StackConfig: Codable {
    var stackName: String
    var goal: String
    var role: String
    var autonomyLevel: Int // 1-5
    var memoryEnabled: Bool
    var toolsEnabled: Bool
    var optimizationMode: String // "speed", "quality", "balanced"
    var isOnboardingComplete: Bool

    static let `default` = StackConfig(
        stackName: "Life Command",
        goal: "",
        role: "",
        autonomyLevel: 3,
        memoryEnabled: true,
        toolsEnabled: true,
        optimizationMode: "balanced",
        isOnboardingComplete: false
    )
}

// MARK: - Model download state

enum ModelDownloadState: Equatable {
    case notInstalled
    case downloading(progress: Double)
    case installed
    case failed(message: String)

    static func == (lhs: ModelDownloadState, rhs: ModelDownloadState) -> Bool {
        switch (lhs, rhs) {
        case (.notInstalled, .notInstalled): return true
        case (.installed, .installed): return true
        case let (.downloading(a), .downloading(b)): return a == b
        case let (.failed(a), .failed(b)): return a == b
        default: return false
        }
    }
}

// MARK: - Known model catalog

struct KnownModel: Identifiable {
    let id = UUID()
    let name: String
    let modelID: String
    let family: String
    let parameterCount: String
    let description: String
    let downloadSizeGB: Double
    let requiresDownload: Bool
    let runtimeBackend: String

    static let gemma4E2B = KnownModel(
        name: "Gemma 4 E2B-IT",
        modelID: "gemma4-e2b-it",
        family: "Gemma",
        parameterCount: "2B",
        description: "Google's efficient 2B instruction-tuned model. Optimized for on-device use with LiteRT.",
        downloadSizeGB: 1.4,
        requiresDownload: true,
        runtimeBackend: "LiteRT-LM"
    )

    static let catalog: [KnownModel] = [gemma4E2B]
}
