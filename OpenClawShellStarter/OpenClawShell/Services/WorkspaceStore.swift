import Foundation

@MainActor
final class WorkspaceStore: ObservableObject {
    @Published private(set) var files: [WorkspaceFile] = []
    @Published var selectedFile: WorkspaceFile?
    @Published var errorMessage: String?

    private let fileManager = FileManager.default

    func load() {
        refresh()
    }

    func refresh() {
        let urls = (try? fileManager.contentsOfDirectory(at: Paths.workspaceDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        files = urls
            .map { WorkspaceFile(filename: $0.lastPathComponent, localURL: $0) }
            .sorted { $0.filename.localizedCaseInsensitiveCompare($1.filename) == .orderedAscending }
        if let selectedFile, !files.contains(selectedFile) {
            self.selectedFile = nil
        }
    }

    func importFiles(from urls: [URL]) {
        for source in urls {
            let didAccess = source.startAccessingSecurityScopedResource()
            defer {
                if didAccess { source.stopAccessingSecurityScopedResource() }
            }

            let destination = Paths.workspaceDirectory.appendingPathComponent(source.lastPathComponent)
            do {
                if fileManager.fileExists(atPath: destination.path) {
                    try fileManager.removeItem(at: destination)
                }
                try fileManager.copyItem(at: source, to: destination)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        refresh()
    }

    func loadText(for file: WorkspaceFile) -> String {
        (try? String(contentsOf: file.localURL, encoding: .utf8)) ?? ""
    }

    func saveText(_ text: String, to file: WorkspaceFile) {
        do {
            try text.write(to: file.localURL, atomically: true, encoding: .utf8)
            refresh()
            selectedFile = files.first(where: { $0.localURL == file.localURL })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ file: WorkspaceFile) {
        do {
            try fileManager.removeItem(at: file.localURL)
            refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
