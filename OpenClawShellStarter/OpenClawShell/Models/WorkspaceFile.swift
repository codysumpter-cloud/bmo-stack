import Foundation

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
