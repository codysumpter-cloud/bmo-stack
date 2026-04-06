import Foundation

struct RemoteModel: Identifiable, Codable, Hashable {
    let id: UUID
    var displayName: String
    var sourceURL: String
    var localFilename: String
    var createdAt: Date

    init(id: UUID = UUID(), displayName: String, sourceURL: String, localFilename: String? = nil, createdAt: Date = .now) {
        self.id = id
        self.displayName = displayName
        self.sourceURL = sourceURL
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
