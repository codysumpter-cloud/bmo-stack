import Foundation

final class DownloadCenter: NSObject {
    enum DownloadState: Equatable {
        case idle(modelName: String)
        case progress(modelName: String, fraction: Double)
    }

    func download(from sourceURL: URL, to destinationURL: URL, onProgress: @escaping @Sendable (DownloadState) -> Void) async throws {
        let request = URLRequest(url: sourceURL)
        let (tempURL, response) = try await URLSession.shared.download(for: request)

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw NSError(domain: "DownloadCenter", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])
        }

        let modelName = destinationURL.deletingPathExtension().lastPathComponent
        onProgress(.progress(modelName: modelName, fraction: 1.0))

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.moveItem(at: tempURL, to: destinationURL)
    }
}
