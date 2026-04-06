import Foundation

@MainActor
final class ModelStore: ObservableObject {
    @Published private(set) var remoteModels: [RemoteModel] = []
    @Published private(set) var installedModels: [InstalledModel] = []
    @Published var activeDownload: DownloadCenter.DownloadState?
    @Published var errorMessage: String?

    private let downloadCenter = DownloadCenter()
    private let fileManager = FileManager.default

    func load() {
        loadRemoteModels()
        refreshInstalledModels()
    }

    func addRemoteModel(displayName: String, sourceURL: String) {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = sourceURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedURL.isEmpty else { return }

        let model = RemoteModel(displayName: trimmedName, sourceURL: trimmedURL)
        remoteModels.insert(model, at: 0)
        persistRemoteModels()
    }

    func removeRemoteModel(_ model: RemoteModel) {
        remoteModels.removeAll { $0.id == model.id }
        persistRemoteModels()
    }

    func refreshInstalledModels() {
        let urls = (try? fileManager.contentsOfDirectory(at: Paths.modelsDirectory, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles])) ?? []
        installedModels = urls.compactMap { url in
            guard let values = try? url.resourceValues(forKeys: [.fileSizeKey]) else { return nil }
            return InstalledModel(displayName: url.deletingPathExtension().lastPathComponent,
                                  localFilename: url.lastPathComponent,
                                  localURL: url,
                                  fileSizeBytes: Int64(values.fileSize ?? 0))
        }
        .sorted { $0.addedAt > $1.addedAt }
    }

    func download(_ model: RemoteModel) {
        guard let sourceURL = URL(string: model.sourceURL) else {
            errorMessage = "Invalid model URL."
            return
        }

        let destination = Paths.modelsDirectory.appendingPathComponent(model.localFilename)
        activeDownload = .idle(modelName: model.displayName)

        Task {
            do {
                try await downloadCenter.download(from: sourceURL, to: destination) { [weak self] state in
                    Task { @MainActor in
                        self?.activeDownload = state
                    }
                }
                await MainActor.run {
                    self.activeDownload = nil
                    self.refreshInstalledModels()
                }
            } catch {
                await MainActor.run {
                    self.activeDownload = nil
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func deleteInstalledModel(_ model: InstalledModel) {
        do {
            try fileManager.removeItem(at: model.localURL)
            refreshInstalledModels()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadRemoteModels() {
        guard let data = try? Data(contentsOf: Paths.modelCatalogFile) else {
            remoteModels = []
            return
        }
        remoteModels = (try? JSONDecoder().decode([RemoteModel].self, from: data)) ?? []
    }

    private func persistRemoteModels() {
        do {
            let data = try JSONEncoder().encode(remoteModels)
            try data.write(to: Paths.modelCatalogFile, options: [.atomic])
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
