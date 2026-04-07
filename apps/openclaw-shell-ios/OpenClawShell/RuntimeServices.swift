import Foundation
import SwiftUI

#if canImport(MLCSwift)
import MLCSwift
#endif

// MARK: - Paths

enum Paths {
    static let appFolderName = "BeMoreAgent"
    static let workspaceFolderName = "BeMoreAgentWorkspace"

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
        documentsDirectory.appendingPathComponent("OpenClawWorkspace", isDirectory: true)
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
    static var stackConfigFile: URL { stateDirectory.appendingPathComponent("stack-config.json") }

    private static func ensureDirectoryExists(_ url: URL) {
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}

// MARK: - Download center

final class DownloadCenter {
    enum DownloadState: Equatable {
        case idle(modelName: String)
        case progress(modelName: String, fraction: Double)
    }

    func download(from sourceURL: URL, to destinationURL: URL, onProgress: @escaping @Sendable (DownloadState) -> Void) async throws {
        let modelName = destinationURL.deletingPathExtension().lastPathComponent

        let (asyncBytes, response) = try await URLSession.shared.bytes(from: sourceURL)

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw NSError(domain: "DownloadCenter", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])
        }

        let expectedLength = response.expectedContentLength
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        FileManager.default.createFile(atPath: tempURL.path, contents: nil)
        let fileHandle = try FileHandle(forWritingTo: tempURL)
        defer { try? fileHandle.close() }

        var bytesReceived: Int64 = 0
        var buffer = Data()
        let chunkSize = 256 * 1024

        for try await byte in asyncBytes {
            buffer.append(byte)
            if buffer.count >= chunkSize {
                fileHandle.write(buffer)
                bytesReceived += Int64(buffer.count)
                buffer.removeAll(keepingCapacity: true)
                if expectedLength > 0 {
                    let fraction = min(Double(bytesReceived) / Double(expectedLength), 1.0)
                    onProgress(.progress(modelName: modelName, fraction: fraction))
                }
            }
        }

        if !buffer.isEmpty {
            fileHandle.write(buffer)
            bytesReceived += Int64(buffer.count)
        }

        try? fileHandle.close()
        onProgress(.progress(modelName: modelName, fraction: 1.0))

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.moveItem(at: tempURL, to: destinationURL)
    }
}

// MARK: - LLM Engine protocol

protocol LocalLLMEngine {
    var backendDisplayName: String { get }
    var isRuntimeReady: Bool { get }
    var requiresModelSelection: Bool { get }

    func bootstrap() async throws
    func configureRuntime(_ config: EngineRuntimeConfig?) async throws
    func generate(prompt: String, fileContexts: [WorkspaceFile], chatHistory: [ChatMessage]) async throws -> String
}

// MARK: - MLC / Stub engine

final class MLCBridgeEngine: LocalLLMEngine {
    private var runtimeConfig: EngineRuntimeConfig?

    var backendDisplayName: String {
        #if canImport(MLCSwift)
        return "MLC Swift"
        #else
        return "Stub runtime (LiteRT-LM pending)"
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
            throw NSError(domain: "BeMoreAgent", code: 1001, userInfo: [NSLocalizedDescriptionKey: "The selected model is missing modelLib. Add the packaged model library name in Models."])
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
            throw NSError(domain: "BeMoreAgent", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Select a downloaded model first."])
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
        return """
        [BMO Agent — Stub Response]

        Your prompt: \(prompt)
        Selected model: \(selected)
        Attached files: \(attachedFiles)
        History: \(chatHistory.count) messages

        This is a simulated response. The LiteRT-LM Swift SDK is in development. \
        Once available, this will run real on-device inference with your installed model.
        """
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

// MARK: - Model catalog store

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

    func downloadToPath(from sourceURL: URL, to destination: URL, displayName: String, modelID: String, modelLib: String, onProgress: @escaping (Double) -> Void) async throws {
        try await downloadCenter.download(from: sourceURL, to: destination) { state in
            if case .progress(_, let fraction) = state {
                onProgress(fraction)
            }
        }
        installedMetadata[destination.lastPathComponent] = InstalledModelDescriptor(
            filename: destination.lastPathComponent,
            displayName: displayName,
            modelID: modelID,
            modelLib: modelLib
        )
        persistInstalledMetadata()
        refreshInstalledModels()
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

// MARK: - Workspace store

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
                errorMessage = "Failed to migrate existing workspace files: \(error.localizedDescription)"
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

// MARK: - Chat store

@MainActor
final class ChatStore: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var selectedFileIDs: Set<UUID> = []
    @Published var isGenerating = false
    @Published var errorMessage: String?

    func load() {
        guard let data = try? Data(contentsOf: Paths.chatStateFile) else {
            messages = [ChatMessage(role: .system, content: "BMO Agent is ready. Install a model to start on-device inference.")]
            return
        }
        messages = (try? JSONDecoder().decode([ChatMessage].self, from: data)) ?? []
        if messages.isEmpty {
            messages = [ChatMessage(role: .system, content: "BMO Agent is ready.")]
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
        messages = [ChatMessage(role: .system, content: "Conversation cleared. Ready for a new chat.")]
        persist()
    }
}

// MARK: - Runtime preferences

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
        } catch {}
    }
}

// MARK: - App state

@MainActor
final class AppState: ObservableObject {
    @Published var modelStore = ModelCatalogStore()
    @Published var workspaceStore = WorkspaceStore()
    @Published var chatStore = ChatStore()
    @Published var runtimePreferences = RuntimePreferencesStore()
    @Published var runtimeStatus = "Not configured"
    @Published var stackConfig = StackConfig.default
    @Published var gemmaDownloadState: ModelDownloadState = .notInstalled

    var selectedInstalledModel: InstalledModel? {
        guard let filename = runtimePreferences.selection.selectedInstalledFilename else { return nil }
        return modelStore.installedModels.first(where: { $0.localFilename == filename })
    }

    var usesStubRuntime: Bool {
        backendDisplayName.contains("Stub")
    }

    var operatorSummary: String {
        if usesStubRuntime {
            return "UI, storage, and model management are real. On-device inference activates when LiteRT-LM Swift SDK ships."
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
        var parts = ["Files, chat history, and model metadata stay inside the app container."]
        if modelStore.remoteModels.isEmpty {
            parts.append("No remote model sources configured.")
        } else {
            parts.append("Remote model URLs are configured for convenience.")
        }
        return parts.joined(separator: " ")
    }

    var workspaceStatusSummary: String {
        let fileCount = workspaceStore.files.count
        let selectedCount = chatStore.selectedFileIDs.count
        let messageCount = chatStore.messages.count
        return "\(fileCount) file\(fileCount == 1 ? "" : "s"), \(selectedCount) attached, \(messageCount) message\(messageCount == 1 ? "" : "s")."
    }

    private let engine: LocalLLMEngine

    init(engine: LocalLLMEngine) {
        self.engine = engine
    }

    var backendDisplayName: String { engine.backendDisplayName }

    func bootstrap() async {
        loadStackConfig()
        modelStore.load()
        workspaceStore.load()
        chatStore.load()
        runtimePreferences.load()
        refreshGemmaState()
        do {
            try await engine.bootstrap()
            try await applySelectedModelIfPossible()
        } catch {
            chatStore.errorMessage = error.localizedDescription
            runtimeStatus = "Runtime error"
        }
    }

    // MARK: - Onboarding

    func completeOnboarding(_ config: StackConfig) {
        stackConfig = config
        persistStackConfig()
    }

    func loadStackConfig() {
        guard let data = try? Data(contentsOf: Paths.stackConfigFile) else { return }
        stackConfig = (try? JSONDecoder().decode(StackConfig.self, from: data)) ?? StackConfig.default
    }

    func persistStackConfig() {
        do {
            let data = try JSONEncoder().encode(stackConfig)
            try data.write(to: Paths.stackConfigFile, options: [.atomic])
        } catch {}
    }

    // MARK: - Gemma download

    func refreshGemmaState() {
        let gemmaInstalled = modelStore.installedModels.contains(where: { $0.modelID == "gemma4-e2b-it" })
        if gemmaInstalled {
            gemmaDownloadState = .installed
        } else if case .downloading = gemmaDownloadState {
            // keep current download state
        } else {
            gemmaDownloadState = .notInstalled
        }
    }

    func downloadGemma() {
        // Use the Kaggle/HuggingFace direct download path for the LiteRT-compatible Gemma model
        // This is a real URL pattern - the actual URL will need to be configured per distribution channel
        let gemmaSourceURL = "https://huggingface.co/google/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it.Q4_K_M.gguf"

        guard let sourceURL = URL(string: gemmaSourceURL) else {
            gemmaDownloadState = .failed(message: "Invalid download URL")
            return
        }

        let destination = Paths.modelsDirectory.appendingPathComponent("gemma4-e2b-it.gguf")
        gemmaDownloadState = .downloading(progress: 0)

        Task {
            do {
                try await modelStore.downloadToPath(
                    from: sourceURL,
                    to: destination,
                    displayName: "Gemma 4 E2B-IT",
                    modelID: "gemma4-e2b-it",
                    modelLib: "gemma-2-2b-it-q4_k_m"
                ) { [weak self] progress in
                    Task { @MainActor in
                        self?.gemmaDownloadState = .downloading(progress: progress)
                    }
                }
                gemmaDownloadState = .installed
            } catch {
                gemmaDownloadState = .failed(message: error.localizedDescription)
            }
        }
    }

    // MARK: - Model selection

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

    // MARK: - Chat

    func send(prompt: String) async {
        let cleaned = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        if engine.requiresModelSelection, selectedInstalledModel == nil {
            chatStore.errorMessage = "Select an installed model in Models before sending."
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

    // MARK: - Private

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
        runtimeStatus = installed.modelID.isEmpty ? "Selected: \(installed.localFilename)" : "Selected: \(installed.modelID)"
    }
}
