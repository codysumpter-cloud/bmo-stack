import Foundation
import SwiftUI

#if canImport(MLCSwift)
import MLCSwift
#endif

enum Paths {
    static let appFolderName = "OpenClaw"
    static let workspaceFolderName = "OpenClawWorkspace"

    static var fileManager: FileManager { .default }

    static var applicationSupportDirectory: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent(appFolderName, isDirectory: true)
        ensureDirectoryExists(folder)
        return folder
    }

    static var modelsDirectory: URL {
        let folder = applicationSupportDirectory.appendingPathComponent("Models", isDirectory: true)
        ensureDirectoryExists(folder)
        return folder
    }

    static var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var legacyWorkspaceDirectory: URL {
        documentsDirectory.appendingPathComponent(workspaceFolderName, isDirectory: true)
    }

    static var workspaceDirectory: URL {
        let folder = applicationSupportDirectory.appendingPathComponent(workspaceFolderName, isDirectory: true)
        ensureDirectoryExists(folder)
        return folder
    }

    static var stateDirectory: URL {
        let folder = applicationSupportDirectory.appendingPathComponent("State", isDirectory: true)
        ensureDirectoryExists(folder)
        return folder
    }

    static var modelCatalogFile: URL { stateDirectory.appendingPathComponent("remote-models.json") }
    static var installedModelMetadataFile: URL { stateDirectory.appendingPathComponent("installed-model-metadata.json") }
    static var chatStateFile: URL { stateDirectory.appendingPathComponent("chat.json") }
    static var runtimeSelectionFile: URL { stateDirectory.appendingPathComponent("runtime-selection.json") }

    private static func ensureDirectoryExists(_ url: URL) {
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}

final class DownloadCenter {
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

protocol LocalLLMEngine {
    var backendDisplayName: String { get }
    var isRuntimeReady: Bool { get }
    var requiresModelSelection: Bool { get }

    func bootstrap() async throws
    func configureRuntime(_ config: EngineRuntimeConfig?) async throws
    func generate(prompt: String, fileContexts: [WorkspaceFile], chatHistory: [ChatMessage]) async throws -> String
}

final class MLCBridgeEngine: LocalLLMEngine {
    private var runtimeConfig: EngineRuntimeConfig?

    var backendDisplayName: String {
        #if canImport(MLCSwift)
        return "MLC Swift"
        #else
        return "Stub runtime"
        #endif
    }

    var isRuntimeReady: Bool { runtimeConfig != nil }

    var requiresModelSelection: Bool {
        #if canImport(MLCSwift)
        true
        #else
        false
        #endif
    }

    func bootstrap() async throws {}

    func configureRuntime(_ config: EngineRuntimeConfig?) async throws {
        runtimeConfig = config

        #if canImport(MLCSwift)
        guard let config else { return }
        guard !config.modelLib.isEmpty else {
            throw NSError(domain: "OpenClawShell", code: 1001, userInfo: [NSLocalizedDescriptionKey: "The selected model is missing modelLib. Add the packaged model library name in Models."])
        }
        let engine = MLCEngine.shared
        await engine.reload(modelPath: config.modelURL.path, modelLib: config.modelLib)
        #endif
    }

    func generate(prompt: String, fileContexts: [WorkspaceFile], chatHistory: [ChatMessage]) async throws -> String {
        let contextPrefix = buildContextPrefix(fileContexts: fileContexts, chatHistory: chatHistory)
        let finalPrompt = contextPrefix + prompt

        #if canImport(MLCSwift)
        guard runtimeConfig != nil else {
            throw NSError(domain: "OpenClawShell", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Select a downloaded model first."])
        }

        let engine = MLCEngine.shared
        var output = ""
        let stream = await engine.chat.completions.create(
            messages: [ChatCompletionMessage(role: .user, content: finalPrompt)]
        )

        for await response in stream {
            if let text = response.choices.first?.delta.content?.asText() {
                output += text
            }
        }

        return output.trimmingCharacters(in: .whitespacesAndNewlines)
        #else
        let filenames = fileContexts.map(\.filename).joined(separator: ", ")
        let selected = runtimeConfig?.modelID ?? "none"
        let attachedFiles = filenames.isEmpty ? "none" : filenames
        return "Stub engine reply.\n\nSelected model: \(selected)\nBackend: \(backendDisplayName)\nPrompt: \(prompt)\n\nAttached files: \(attachedFiles)\nHistory messages: \(chatHistory.count)\n\nAdd MLCSwift locally in Xcode and package your model libraries with MLC to get real on-device inference."
        #endif
    }

    private func buildContextPrefix(fileContexts: [WorkspaceFile], chatHistory: [ChatMessage]) -> String {
        var parts: [String] = []

        if !fileContexts.isEmpty {
            let rendered = fileContexts.map { file -> String in
                let text = (try? String(contentsOf: file.localURL, encoding: .utf8)) ?? "[binary or unreadable file]"
                return "FILE: \(file.filename)\n\(text.prefix(8000))"
            }
            parts.append(rendered.joined(separator: "\n\n"))
        }

        if !chatHistory.isEmpty {
            let clipped = chatHistory.suffix(8).map { "\($0.role.rawValue.uppercased()): \($0.content)" }.joined(separator: "\n")
            parts.append("RECENT CHAT:\n\(clipped)")
        }

        guard !parts.isEmpty else { return "" }
        return parts.joined(separator: "\n\n") + "\n\nUSER REQUEST:\n"
    }
}

#if canImport(MLCSwift)
extension MLCEngine {
    static let shared = MLCEngine()
}
#endif

@MainActor
final class ModelCatalogStore: ObservableObject {
    @Published private(set) var remoteModels: [RemoteModel] = []
    @Published private(set) var installedModels: [InstalledModel] = []
    @Published var activeDownload: DownloadCenter.DownloadState?
    @Published var errorMessage: String?

    private let downloadCenter = DownloadCenter()
    private let fileManager = FileManager.default
    private var installedMetadata: [String: InstalledModelDescriptor] = [:]

    func load() {
        guard let data = try? Data(contentsOf: Paths.modelCatalogFile) else {
            remoteModels = []
            loadInstalledMetadata()
            refreshInstalledModels()
            return
        }
        remoteModels = (try? JSONDecoder().decode([RemoteModel].self, from: data)) ?? []
        loadInstalledMetadata()
        refreshInstalledModels()
    }

    func addRemoteModel(displayName: String, sourceURL: String, modelID: String, modelLib: String) {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = sourceURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedURL.isEmpty else {
            errorMessage = "Enter both a display name and a model URL."
            return
        }
        guard let parsedURL = URL(string: trimmedURL), let scheme = parsedURL.scheme?.lowercased(), ["https", "http"].contains(scheme) else {
            errorMessage = "Model source URLs must be valid http or https links."
            return
        }

        remoteModels.insert(
            RemoteModel(
                displayName: trimmedName,
                sourceURL: trimmedURL,
                modelID: modelID.trimmingCharacters(in: .whitespacesAndNewlines),
                modelLib: modelLib.trimmingCharacters(in: .whitespacesAndNewlines)
            ),
            at: 0
        )
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
            let metadata = installedMetadata[url.lastPathComponent]
            return InstalledModel(
                displayName: metadata?.displayName ?? url.deletingPathExtension().lastPathComponent,
                localFilename: url.lastPathComponent,
                localURL: url,
                fileSizeBytes: Int64(values.fileSize ?? 0),
                modelID: metadata?.modelID ?? "",
                modelLib: metadata?.modelLib ?? ""
            )
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
                    Task { @MainActor in self?.activeDownload = state }
                }
                await MainActor.run {
                    self.installedMetadata[destination.lastPathComponent] = InstalledModelDescriptor(
                        filename: destination.lastPathComponent,
                        displayName: model.displayName,
                        modelID: model.modelID,
                        modelLib: model.modelLib
                    )
                    self.persistInstalledMetadata()
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

    func importPreparedModelItems(from urls: [URL]) {
        for url in urls {
            let didStart = url.startAccessingSecurityScopedResource()
            defer { if didStart { url.stopAccessingSecurityScopedResource() } }

            let destination = Paths.modelsDirectory.appendingPathComponent(url.lastPathComponent)
            do {
                if fileManager.fileExists(atPath: destination.path) {
                    try fileManager.removeItem(at: destination)
                }
                try fileManager.copyItem(at: url, to: destination)
                installedMetadata[destination.lastPathComponent] = InstalledModelDescriptor(
                    filename: destination.lastPathComponent,
                    displayName: destination.deletingPathExtension().lastPathComponent,
                    modelID: "",
                    modelLib: ""
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        persistInstalledMetadata()
        refreshInstalledModels()
    }

    func deleteInstalledModel(_ model: InstalledModel) {
        do {
            try fileManager.removeItem(at: model.localURL)
            installedMetadata.removeValue(forKey: model.localFilename)
            persistInstalledMetadata()
            refreshInstalledModels()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func persistRemoteModels() {
        do {
            let data = try JSONEncoder().encode(remoteModels)
            try data.write(to: Paths.modelCatalogFile, options: [.atomic])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadInstalledMetadata() {
        guard let data = try? Data(contentsOf: Paths.installedModelMetadataFile) else {
            installedMetadata = [:]
            return
        }
        installedMetadata = (try? JSONDecoder().decode([String: InstalledModelDescriptor].self, from: data)) ?? [:]
    }

    private func persistInstalledMetadata() {
        do {
            let data = try JSONEncoder().encode(installedMetadata)
            try data.write(to: Paths.installedModelMetadataFile, options: [.atomic])
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
final class WorkspaceStore: ObservableObject {
    @Published private(set) var files: [WorkspaceFile] = []
    @Published var selectedFile: WorkspaceFile?
    @Published var errorMessage: String?

    func load() {
        migrateLegacyWorkspaceIfNeeded()

        let urls = (try? FileManager.default.contentsOfDirectory(at: Paths.workspaceDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        files = urls.map { WorkspaceFile(filename: $0.lastPathComponent, localURL: $0) }
            .sorted { $0.filename.localizedCaseInsensitiveCompare($1.filename) == .orderedAscending }
        if let selected = selectedFile {
            selectedFile = files.first(where: { $0.localURL == selected.localURL })
        }
    }

    private func migrateLegacyWorkspaceIfNeeded() {
        let fileManager = FileManager.default
        let legacyDirectory = Paths.legacyWorkspaceDirectory
        let targetDirectory = Paths.workspaceDirectory

        guard legacyDirectory != targetDirectory else { return }

        var legacyIsDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: legacyDirectory.path, isDirectory: &legacyIsDirectory), legacyIsDirectory.boolValue else {
            return
        }

        let legacyURLs = (try? fileManager.contentsOfDirectory(at: legacyDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        guard !legacyURLs.isEmpty else { return }

        let targetURLs = (try? fileManager.contentsOfDirectory(at: targetDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        guard targetURLs.isEmpty else { return }

        for sourceURL in legacyURLs {
            let destinationURL = targetDirectory.appendingPathComponent(sourceURL.lastPathComponent)
            do {
                if fileManager.fileExists(atPath: destinationURL.path) {
                    continue
                }
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
            } catch {
                errorMessage = "Failed to migrate existing workspace files into app storage: \(error.localizedDescription)"
                return
            }
        }
    }

    func importFiles(from urls: [URL]) {
        let fileManager = FileManager.default
        for url in urls {
            let didStart = url.startAccessingSecurityScopedResource()
            defer { if didStart { url.stopAccessingSecurityScopedResource() } }
            let destination = Paths.workspaceDirectory.appendingPathComponent(url.lastPathComponent)
            do {
                if fileManager.fileExists(atPath: destination.path) {
                    try fileManager.removeItem(at: destination)
                }
                try fileManager.copyItem(at: url, to: destination)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        load()
    }

    func delete(_ file: WorkspaceFile) {
        do {
            try FileManager.default.removeItem(at: file.localURL)
            if selectedFile?.id == file.id { selectedFile = nil }
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func readText(for file: WorkspaceFile) -> String {
        (try? String(contentsOf: file.localURL, encoding: .utf8)) ?? ""
    }

    func saveText(_ text: String, for file: WorkspaceFile) {
        do {
            try text.write(to: file.localURL, atomically: true, encoding: .utf8)
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
final class ChatStore: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var selectedFileIDs: Set<UUID> = []
    @Published var isGenerating = false
    @Published var errorMessage: String?

    func load() {
        guard let data = try? Data(contentsOf: Paths.chatStateFile) else {
            messages = [ChatMessage(role: .system, content: "OpenClawShell is ready. Add a packaged MLC runtime or use the stub path until then.")]
            return
        }
        messages = (try? JSONDecoder().decode([ChatMessage].self, from: data)) ?? []
        if messages.isEmpty {
            messages = [ChatMessage(role: .system, content: "OpenClawShell is ready.")]
        }
    }

    func persist() {
        do {
            let data = try JSONEncoder().encode(messages)
            try data.write(to: Paths.chatStateFile, options: [.atomic])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clear() {
        messages = [ChatMessage(role: .system, content: "Conversation cleared.")]
        persist()
    }
}

@MainActor
final class RuntimePreferencesStore: ObservableObject {
    @Published var selection = RuntimeSelection(selectedInstalledFilename: nil)

    func load() {
        guard let data = try? Data(contentsOf: Paths.runtimeSelectionFile) else { return }
        selection = (try? JSONDecoder().decode(RuntimeSelection.self, from: data)) ?? RuntimeSelection(selectedInstalledFilename: nil)
    }

    func persist() {
        do {
            let data = try JSONEncoder().encode(selection)
            try data.write(to: Paths.runtimeSelectionFile, options: [.atomic])
        } catch {
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var modelStore = ModelCatalogStore()
    @Published var workspaceStore = WorkspaceStore()
    @Published var chatStore = ChatStore()
    @Published var runtimePreferences = RuntimePreferencesStore()
    @Published var runtimeStatus = "Not configured"

    var selectedInstalledModel: InstalledModel? {
        guard let filename = runtimePreferences.selection.selectedInstalledFilename else { return nil }
        return modelStore.installedModels.first(where: { $0.localFilename == filename })
    }

    var usesStubRuntime: Bool {
        backendDisplayName == "Stub runtime"
    }

    var operatorSummary: String {
        if usesStubRuntime {
            return "Demo-safe shell: UI, storage, and editing are real, but model inference is still stubbed until MLCSwift is wired in."
        }
        if let model = selectedInstalledModel {
            return "On-device runtime selected: \(model.modelID.isEmpty ? model.localFilename : model.modelID)."
        }
        if engine.requiresModelSelection {
            return "On-device runtime is available, but no packaged model is selected yet."
        }
        return "Runtime ready."
    }

    var localFirstSummary: String {
        var parts = ["Files, chat history, and model metadata stay inside the app container by default."]
        if modelStore.remoteModels.isEmpty {
            parts.append("No remote model sources are configured.")
        } else {
            parts.append("Remote model URLs are configured for convenience, but prepared local imports remain the safer path.")
        }
        return parts.joined(separator: " ")
    }

    var workspaceStatusSummary: String {
        let fileCount = workspaceStore.files.count
        let selectedCount = chatStore.selectedFileIDs.count
        let messageCount = chatStore.messages.count
        return "\(fileCount) workspace file\(fileCount == 1 ? \"\" : \"s\"), \(selectedCount) attached to chat, \(messageCount) chat message\(messageCount == 1 ? \"\" : \"s\")."
    }

    private let engine: LocalLLMEngine

    init(engine: LocalLLMEngine) {
        self.engine = engine
    }

    var backendDisplayName: String { engine.backendDisplayName }

    func bootstrap() async {
        modelStore.load()
        workspaceStore.load()
        chatStore.load()
        runtimePreferences.load()
        do {
            try await engine.bootstrap()
            try await applySelectedModelIfPossible()
        } catch {
            chatStore.errorMessage = error.localizedDescription
            runtimeStatus = "Runtime error"
        }
    }

    func setSelectedInstalledModel(filename: String?) async {
        runtimePreferences.selection.selectedInstalledFilename = filename
        runtimePreferences.persist()
        do {
            try await applySelectedModelIfPossible()
        } catch {
            chatStore.errorMessage = error.localizedDescription
            runtimeStatus = "Runtime error"
        }
    }

    func send(prompt: String) async {
        let cleaned = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        if engine.requiresModelSelection, selectedInstalledModel == nil {
            chatStore.errorMessage = "Select an installed model in Models before sending chat prompts."
            runtimeStatus = "Model required"
            return
        }

        chatStore.messages.append(ChatMessage(role: .user, content: cleaned))
        chatStore.persist()
        chatStore.isGenerating = true

        let attachedFiles = workspaceStore.files.filter { chatStore.selectedFileIDs.contains($0.id) }

        do {
            let reply = try await engine.generate(prompt: cleaned, fileContexts: attachedFiles, chatHistory: chatStore.messages)
            chatStore.messages.append(ChatMessage(role: .assistant, content: reply))
            chatStore.persist()
        } catch {
            chatStore.errorMessage = error.localizedDescription
        }

        chatStore.isGenerating = false
    }

    private func applySelectedModelIfPossible() async throws {
        guard let filename = runtimePreferences.selection.selectedInstalledFilename else {
            try await engine.configureRuntime(nil)
            runtimeStatus = "No model selected"
            return
        }

        guard let installed = modelStore.installedModels.first(where: { $0.localFilename == filename }) else {
            try await engine.configureRuntime(nil)
            runtimeStatus = "Selected model missing"
            return
        }

        try await engine.configureRuntime(
            EngineRuntimeConfig(modelURL: installed.localURL, modelID: installed.modelID, modelLib: installed.modelLib)
        )
        runtimeStatus = installed.modelID.isEmpty ? "Selected file: \(installed.localFilename)" : "Selected model: \(installed.modelID)"
    }
}
