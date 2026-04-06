import Foundation

struct InstalledModel: Identifiable, Codable, Hashable {
    let id: UUID
    let displayName: String
    let localFilename: String
    let localURL: URL
    let fileSizeBytes: Int64
    let addedAt: Date

    init(id: UUID = UUID(), displayName: String, localFilename: String, localURL: URL, fileSizeBytes: Int64, addedAt: Date = .now) {
        self.id = id
        self.displayName = displayName
        self.localFilename = localFilename
        self.localURL = localURL
        self.fileSizeBytes = fileSizeBytes
        self.addedAt = addedAt
    }
}
