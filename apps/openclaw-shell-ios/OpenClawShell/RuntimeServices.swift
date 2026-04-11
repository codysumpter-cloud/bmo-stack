import Foundation
import SwiftUI

#if canImport(MLCSwift)
import MLCSwift
#endif

// MARK: - Paths

enum Paths {
    static let appFolderName = "BeMoreAgent"
    static let workspaceFolderName = "BeMoreAgentWorkspace"
    static var applicationSupportOverride: URL?
    static var documentsOverride: URL?

    static var fileManager: FileManager { .default }

    static var applicationSupportDirectory: URL {
        let base = applicationSupportOverride ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
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
        documentsOverride ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var legacyWorkspaceDirectory: URL {
        documentsDirectory.appendingPathComponent("OpenClawWorkspace", isDirectory: true)
    }

    static var workspaceDirectory: URL {
        let folder = applicationSupportDirectory.appendingPathComponent(workspaceFolderName, isDirectory: true)
        ensureDirectoryExists(folder)
        return folder
    }

    static var openClawDirectory: URL {
        let folder = workspaceDirectory.appendingPathComponent(".openclaw", isDirectory: true)
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
    static var providersFile: URL { stateDirectory.appendingPathComponent("providers.json") }
    static var runtimeSelectionFile: URL { stateDirectory.appendingPathComponent("runtime-selection.json") }
    static var stackConfigFile: URL { stateDirectory.appendingPathComponent("stack-config.json") }
    static var tabPreferencesFile: URL { stateDirectory.appendingPathComponent("tab-preferences.json") }
    static var userPreferencesFile: URL { stateDirectory.appendingPathComponent("user-preferences.json") }
    static var userProfileFile: URL { stateDirectory.appendingPathComponent("user-profile.md") }
    static var soulProfileFile: URL { stateDirectory.appendingPathComponent("soul-profile.md") }

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
            throw NSError(
                domain: "DownloadCenter",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: ModelSourceValidator.userFacingHTTPMessage(statusCode: http.statusCode, sourceURL: sourceURL)]
            )
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

// MARK: - Source validation / messaging

enum ModelSourceValidator {
    private static let supportedFileExtensions: Set<String> = ["gguf", "task", "bin", "mlmodelc", "zip"]

    static func validateDirectDownloadURL(_ url: URL) -> String? {
        let ext = url.pathExtension.lowercased()

        if url.host?.contains("huggingface.co") == true, !url.path.contains("/resolve/") {
            return "Use a direct file link from Hugging Face that points to a downloadable artifact (for example a /resolve/main/...gguf URL), or import a prepared model."
        }

        if ext.isEmpty || !supportedFileExtensions.contains(ext) {
            return "This source is not a supported direct-download artifact yet. Add a direct model file URL or import a prepared model."
        }

        return nil
    }

    static func userFacingHTTPMessage(statusCode: Int, sourceURL: URL) -> String {
        switch statusCode {
        case 401:
            return "This source requires authentication before it can be downloaded. Add an authenticated source or import a prepared model."
        case 403:
            return "This source is forbidden or gated. Use a public direct-download artifact, an authenticated source, or import a prepared model."
        case 404:
            return "The model file could not be found at this URL. Update the source URL or import a prepared model."
        default:
            return "Download failed with HTTP \(statusCode). Verify the source URL and try again."
        }
    }

    static func userFacingDownloadMessage(for error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == "DownloadCenter" {
            return nsError.localizedDescription
        }
        return error.localizedDescription
    }
}

enum ModelMetadataInference {
    static func displayName(from filename: String) -> String {
        let stem = filename
            .replacingOccurrences(of: ".gguf", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ".bin", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ".task", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ".zip", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !stem.isEmpty else { return filename }
        return stem
            .split(separator: " ")
            .map { token in
                let value = String(token)
                if value.uppercased() == value {
                    return value
                }
                return value.prefix(1).uppercased() + value.dropFirst()
            }
            .joined(separator: " ")
    }

    static func modelID(from filename: String) -> String {
        filename
            .replacingOccurrences(of: ".gguf", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ".bin", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ".task", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ".zip", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()
    }

    static func modelLib(from filename: String) -> String {
        modelID(from: filename).replacingOccurrences(of: "-", with: "_")
    }
}

// MARK: - LLM Engine protocol

protocol LocalLLMEngine {
    var backendDisplayName: String { get }
    var isRuntimeReady: Bool { get }
    var supportsLocalModels: Bool { get }
    var requiresModelSelection: Bool { get }
    var runtimeRequirementMessage: String? { get }

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

    var supportsLocalModels: Bool {
        #if canImport(MLCSwift)
        return true
        #else
        return false
        #endif
    }

    var requiresModelSelection: Bool {
        #if canImport(MLCSwift)
        true
        #else
        false
        #endif
    }

    var runtimeRequirementMessage: String? {
        supportsLocalModels ? nil : "This build does not include the on-device runtime package yet. Link a cloud provider for live chat."
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

        let inferredFilename = RemoteModel.suggestedFilename(from: trimmedURL, fallback: trimmedName)
        let finalModelID = modelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? ModelMetadataInference.modelID(from: inferredFilename)
            : modelID.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalModelLib = modelLib.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? ModelMetadataInference.modelLib(from: inferredFilename)
            : modelLib.trimmingCharacters(in: .whitespacesAndNewlines)

        remoteModels.insert(
            RemoteModel(
                displayName: trimmedName,
                sourceURL: trimmedURL,
                modelID: finalModelID,
                modelLib: finalModelLib
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
            let fallbackFilename = url.lastPathComponent
            return InstalledModel(
                displayName: metadata?.displayName ?? ModelMetadataInference.displayName(from: fallbackFilename),
                localFilename: fallbackFilename,
                localURL: url,
                fileSizeBytes: Int64(values.fileSize ?? 0),
                modelID: metadata?.modelID.isEmpty == false ? metadata!.modelID : ModelMetadataInference.modelID(from: fallbackFilename),
                modelLib: metadata?.modelLib.isEmpty == false ? metadata!.modelLib : ModelMetadataInference.modelLib(from: fallbackFilename)
            )
        }
        .sorted { $0.addedAt > $1.addedAt }
    }

    func download(_ model: RemoteModel) {
        guard let sourceURL = URL(string: model.sourceURL) else {
            errorMessage = "Invalid model URL."
            return
        }

        if let validationMessage = ModelSourceValidator.validateDirectDownloadURL(sourceURL) {
            errorMessage = validationMessage
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
                        modelID: model.modelID.isEmpty ? ModelMetadataInference.modelID(from: destination.lastPathComponent) : model.modelID,
                        modelLib: model.modelLib.isEmpty ? ModelMetadataInference.modelLib(from: destination.lastPathComponent) : model.modelLib
                    )
                    self.persistInstalledMetadata()
                    self.activeDownload = nil
                    self.refreshInstalledModels()
                }
            } catch {
                await MainActor.run {
                    self.activeDownload = nil
                    self.errorMessage = ModelSourceValidator.userFacingDownloadMessage(for: error)
                }
            }
        }
    }

    func downloadToPath(from sourceURL: URL, to destination: URL, displayName: String, modelID: String, modelLib: String, onProgress: @escaping (Double) -> Void) async throws {
        if let validationMessage = ModelSourceValidator.validateDirectDownloadURL(sourceURL) {
            throw NSError(domain: "DownloadCenter", code: 1000, userInfo: [NSLocalizedDescriptionKey: validationMessage])
        }

        try await downloadCenter.download(from: sourceURL, to: destination) { state in
            if case .progress(_, let fraction) = state {
                onProgress(fraction)
            }
        }
        installedMetadata[destination.lastPathComponent] = InstalledModelDescriptor(
            filename: destination.lastPathComponent,
            displayName: displayName.isEmpty ? ModelMetadataInference.displayName(from: destination.lastPathComponent) : displayName,
            modelID: modelID.isEmpty ? ModelMetadataInference.modelID(from: destination.lastPathComponent) : modelID,
            modelLib: modelLib.isEmpty ? ModelMetadataInference.modelLib(from: destination.lastPathComponent) : modelLib
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
                    displayName: ModelMetadataInference.displayName(from: destination.lastPathComponent),
                    modelID: ModelMetadataInference.modelID(from: destination.lastPathComponent),
                    modelLib: ModelMetadataInference.modelLib(from: destination.lastPathComponent)
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

    func createFile(named filename: String, content: String = "") {
        let cleaned = filename
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
        guard !cleaned.isEmpty else {
            errorMessage = "Enter a filename first."
            return
        }

        let destination = Paths.workspaceDirectory.appendingPathComponent(cleaned)
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                errorMessage = "\(cleaned) already exists."
                return
            }
            try content.write(to: destination, atomically: true, encoding: .utf8)
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
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
            messages = [ChatMessage(role: .system, content: "Route not configured. Link a cloud provider for live chat, or select a local model only after the on-device runtime is available.")]
            return
        }
        messages = (try? JSONDecoder().decode([ChatMessage].self, from: data)) ?? []
        if messages.isEmpty {
            messages = [ChatMessage(role: .system, content: "Route not configured. Choose a live route in Models before chatting.")]
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
        messages = [ChatMessage(role: .system, content: "Conversation cleared. Route must still be configured before live chat.")]
        persist()
    }
}

// MARK: - Provider accounts

@MainActor
final class ProviderStore: ObservableObject {
    @Published var accounts: [ProviderAccount] = []
    @Published var lastError: String?

    func load() {
        accounts = (try? JSONDecoder().decode([ProviderAccount].self, from: Data(contentsOf: Paths.providersFile))) ?? []
    }

    func account(for provider: ProviderKind) -> ProviderAccount {
        accounts.first(where: { $0.provider == provider }) ?? .blank(for: provider)
    }

    func upsert(_ account: ProviderAccount) {
        if let index = accounts.firstIndex(where: { $0.provider == account.provider }) {
            accounts[index] = account
        } else {
            accounts.append(account)
        }
        persist()
    }

    func validate(_ provider: ProviderKind) {
        var current = account(for: provider)
        switch provider {
        case .ollama:
            guard !current.baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                lastError = "Add an Ollama server URL first."
                return
            }
        default:
            guard !current.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                lastError = "Add credentials for \(provider.displayName) first."
                return
            }
        }
        current.isEnabled = true
        current.lastValidatedAt = .now
        upsert(current)
    }

    func remove(_ provider: ProviderKind) {
        accounts.removeAll { $0.provider == provider }
        persist()
    }

    func enabledProviders() -> [ProviderAccount] {
        accounts.filter(\.isEnabled)
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(accounts)
            try data.write(to: Paths.providersFile, options: [.atomic])
        } catch {
            lastError = error.localizedDescription
        }
    }
}

struct CloudExecutionMessage: Hashable {
    enum Role: String {
        case system
        case user
        case assistant
        case model
    }

    var role: Role
    var content: String
}

enum CloudPromptBuilder {
    static func systemPrompt(config: StackConfig, operatorName: String, routeLabel: String) -> String {
        let name = operatorName.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = name.isEmpty ? "the operator" : name
        let toolPosture = config.toolsEnabled
            ? "The operator intends to use tool-capable OpenClaw routes through the built-in Workspace Runtime as capabilities become available."
            : "The operator has not enabled tool-capable behavior for this stack profile."

        return """
        You are BeMoreAgent, the BMO-style operator agent for \(displayName)'s OpenClaw stack.

        You are not confined to the iOS app. Do not frame yourself as app-only. Help with the full OpenClaw/operator context: planning, repo work, runtime diagnosis, provider setup, deployment reasoning, and stack operations.

        Current route: \(routeLabel).
        Stack name: \(config.stackName).
        Runtime endpoint: \(config.gatewayURL).
        Admin/public domain: \(config.adminDomain).
        \(toolPosture)

        Be honest about capabilities. This direct cloud chat route can reason and use attached file context. Real filesystem, memory, skill, and sandbox changes must go through OpenClaw Workspace Runtime receipts. If a capability is unavailable in this iOS runtime, say unavailable or failed instead of claiming completion.

        Reply with the answer only. Do not reveal hidden reasoning, chain-of-thought, scratchpad notes, analysis sections, or internal deliberation unless the operator explicitly asks for an explanation. If asked to explain, give a concise rationale, not private step-by-step thoughts.
        """
    }
}

enum AgentReplySanitizer {
    static func userVisibleAnswer(from raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        text = removeDelimited("<think>", "</think>", from: text)
        text = removeDelimited("<thinking>", "</thinking>", from: text)
        text = removeDelimited("```thought", "```", from: text)
        text = removeDelimited("```thinking", "```", from: text)

        let dropPrefixes = [
            "Thought process:",
            "Thinking:",
            "Reasoning:",
            "Analysis:",
            "Chain of thought:",
            "Scratchpad:"
        ]
        var lines = text.components(separatedBy: .newlines)
        while let first = lines.first {
            let trimmed = first.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || dropPrefixes.contains(where: { trimmed.range(of: $0, options: [.caseInsensitive, .anchored]) != nil }) {
                lines.removeFirst()
            } else {
                break
            }
        }

        text = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? "I do not have a user-visible answer from that route." : text
    }

    private static func removeDelimited(_ start: String, _ end: String, from value: String) -> String {
        var result = value
        while let startRange = result.range(of: start, options: [.caseInsensitive]) {
            guard let endRange = result.range(of: end, options: [.caseInsensitive], range: startRange.upperBound..<result.endIndex) else {
                result.removeSubrange(startRange.lowerBound..<result.endIndex)
                break
            }
            result.removeSubrange(startRange.lowerBound..<endRange.upperBound)
        }
        return result
    }
}

enum CloudExecutionServiceError: Error {
    case invalidBaseURL
    case invalidResponse
    case upstreamFailure(String)
}

struct ProviderTransport {
    static func normalizeBaseURL(for provider: ProviderKind, rawValue: String) -> String {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return provider.defaultBaseURL }
        if provider == .huggingFace, trimmed.contains("api-inference.huggingface.co") {
            return "https://router.huggingface.co/v1"
        }
        return trimmed
    }
}

actor CloudExecutionService {
    func send(account: ProviderAccount, messages: [CloudExecutionMessage], temperature: Double? = nil, maxOutputTokens: Int? = nil) async throws -> String {
        let request = try makeRequest(account: account, messages: messages, temperature: temperature, maxOutputTokens: maxOutputTokens)
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        let preview = String(data: data.prefix(6000), encoding: .utf8) ?? ""

        guard (200...299).contains(statusCode) else {
            throw CloudExecutionServiceError.upstreamFailure(preview.isEmpty ? "Request failed with status \(statusCode)." : preview)
        }

        return try parse(provider: account.provider, data: data)
    }

    func availableModels(account: ProviderAccount) async throws -> [CloudModel] {
        let request = try makeModelsRequest(account: account)
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        let preview = String(data: data.prefix(6000), encoding: .utf8) ?? ""

        guard (200...299).contains(statusCode) else {
            throw CloudExecutionServiceError.upstreamFailure(preview.isEmpty ? "Model list failed with status \(statusCode)." : preview)
        }

        return try parseAvailableModels(provider: account.provider, data: data)
    }

    private func makeRequest(account: ProviderAccount, messages: [CloudExecutionMessage], temperature: Double?, maxOutputTokens: Int?) throws -> URLRequest {
        let normalizedBase = ProviderTransport.normalizeBaseURL(for: account.provider, rawValue: account.baseURL)
        guard let url = requestURL(provider: account.provider, baseURL: normalizedBase, model: account.modelSlug) else {
            throw CloudExecutionServiceError.invalidBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyAuthHeaders(to: &request, account: account, normalizedBase: normalizedBase)
        request.httpBody = try requestBody(provider: account.provider, model: account.modelSlug, messages: messages, temperature: temperature, maxOutputTokens: maxOutputTokens)
        return request
    }

    private func makeModelsRequest(account: ProviderAccount) throws -> URLRequest {
        let normalizedBase = ProviderTransport.normalizeBaseURL(for: account.provider, rawValue: account.baseURL)
        guard let url = modelsURL(provider: account.provider, baseURL: normalizedBase) else {
            throw CloudExecutionServiceError.invalidBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        applyAuthHeaders(to: &request, account: account, normalizedBase: normalizedBase)
        return request
    }

    private func applyAuthHeaders(to request: inout URLRequest, account: ProviderAccount, normalizedBase: String) {
        switch account.provider {
        case .google:
            if !account.apiKey.isEmpty { request.setValue(account.apiKey, forHTTPHeaderField: "x-goog-api-key") }
        case .ollama:
            if normalizedBase.contains("ollama.com"), !account.apiKey.isEmpty {
                request.setValue("Bearer \(account.apiKey)", forHTTPHeaderField: "Authorization")
            }
        default:
            if !account.apiKey.isEmpty { request.setValue("Bearer \(account.apiKey)", forHTTPHeaderField: "Authorization") }
        }
    }

    private func requestURL(provider: ProviderKind, baseURL: String, model: String) -> URL? {
        let root = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        switch provider {
        case .nvidia, .openAI, .huggingFace:
            return URL(string: root + "/chat/completions")
        case .ollama:
            return URL(string: (root.hasSuffix("/api") ? root : root + "/api") + "/chat")
        case .google:
            return URL(string: root + "/v1beta/models/\(model):generateContent")
        }
    }

    private func modelsURL(provider: ProviderKind, baseURL: String) -> URL? {
        let root = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        switch provider {
        case .nvidia, .openAI, .huggingFace:
            return URL(string: root + "/models")
        case .ollama:
            return URL(string: (root.hasSuffix("/api") ? root : root + "/api") + "/tags")
        case .google:
            return URL(string: root + "/v1beta/models")
        }
    }

    private func requestBody(provider: ProviderKind, model: String, messages: [CloudExecutionMessage], temperature: Double?, maxOutputTokens: Int?) throws -> Data {
        let json: Any
        switch provider {
        case .google:
            let contents = messages.map { message in
                ["role": message.role == .assistant ? "model" : message.role.rawValue, "parts": [["text": message.content]]] as [String : Any]
            }
            var body: [String: Any] = ["contents": contents]
            var config: [String: Any] = [:]
            if let temperature { config["temperature"] = temperature }
            if let maxOutputTokens { config["maxOutputTokens"] = maxOutputTokens }
            if !config.isEmpty { body["generationConfig"] = config }
            json = body
        case .ollama:
            var body: [String: Any] = [
                "model": model,
                "messages": messages.map { ["role": $0.role == .model ? "assistant" : $0.role.rawValue, "content": $0.content] },
                "stream": false
            ]
            if let temperature { body["options"] = ["temperature": temperature] }
            json = body
        default:
            var body: [String: Any] = [
                "model": model,
                "messages": messages.map { ["role": $0.role == .model ? "assistant" : $0.role.rawValue, "content": $0.content] },
                "stream": false
            ]
            if let temperature { body["temperature"] = temperature }
            if let maxOutputTokens { body["max_tokens"] = maxOutputTokens }
            json = body
        }
        return try JSONSerialization.data(withJSONObject: json)
    }

    private func parseAvailableModels(provider: ProviderKind, data: Data) throws -> [CloudModel] {
        let object = try JSONSerialization.jsonObject(with: data)

        switch provider {
        case .nvidia, .openAI, .huggingFace:
            guard let root = object as? [String: Any], let entries = root["data"] as? [[String: Any]] else {
                throw CloudExecutionServiceError.invalidResponse
            }
            return entries.compactMap { entry in
                guard let slug = entry["id"] as? String, !slug.isEmpty else { return nil }
                let displayName = (entry["name"] as? String) ?? slug
                return CloudModel(provider: provider, slug: slug, displayName: displayName, notes: "Discovered from linked account")
            }
        case .google:
            guard let root = object as? [String: Any], let entries = root["models"] as? [[String: Any]] else {
                throw CloudExecutionServiceError.invalidResponse
            }
            return entries.compactMap { entry in
                let methods = entry["supportedGenerationMethods"] as? [String] ?? []
                guard methods.contains("generateContent") else { return nil }
                guard let name = entry["name"] as? String, !name.isEmpty else { return nil }
                let slug = name.replacingOccurrences(of: "models/", with: "")
                let displayName = (entry["displayName"] as? String) ?? slug
                return CloudModel(provider: provider, slug: slug, displayName: displayName, notes: "Discovered from linked account")
            }
        case .ollama:
            guard let root = object as? [String: Any], let entries = root["models"] as? [[String: Any]] else {
                throw CloudExecutionServiceError.invalidResponse
            }
            return entries.compactMap { entry in
                guard let slug = entry["name"] as? String, !slug.isEmpty else { return nil }
                let displayName = (entry["model"] as? String) ?? slug
                return CloudModel(provider: provider, slug: slug, displayName: displayName, notes: "Discovered from linked account")
            }
        }
    }

    private func parse(provider: ProviderKind, data: Data) throws -> String {
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CloudExecutionServiceError.invalidResponse
        }

        let text: String?
        switch provider {
        case .google:
            if let candidates = object["candidates"] as? [[String: Any]],
               let first = candidates.first,
               let content = first["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]] {
                text = parts.compactMap { $0["text"] as? String }.joined(separator: "\n")
            } else {
                text = nil
            }
        case .ollama:
            if let message = object["message"] as? [String: Any],
               let content = message["content"] as? String {
                text = content
            } else {
                text = nil
            }
        default:
            if let choices = object["choices"] as? [[String: Any]],
               let first = choices.first,
               let message = first["message"] as? [String: Any],
               let content = message["content"] as? String {
                text = content
            } else {
                text = nil
            }
        }

        guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CloudExecutionServiceError.invalidResponse
        }
        return text
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

@MainActor
final class TabPreferencesStore: ObservableObject {
    @Published var preferences = ShellPreferences.default

    func load() {
        guard let data = try? Data(contentsOf: Paths.tabPreferencesFile) else { return }
        preferences = ((try? JSONDecoder().decode(ShellPreferences.self, from: data)) ?? .default).normalized()
    }

    func persist() {
        let normalized = preferences.normalized()
        preferences = normalized
        do {
            let data = try JSONEncoder().encode(normalized)
            try data.write(to: Paths.tabPreferencesFile, options: [.atomic])
        } catch {}
    }
}

@MainActor
final class UserPreferencesStore: ObservableObject {
    @Published var preferences = UserPreferences.default

    func load() {
        if let data = try? Data(contentsOf: Paths.userPreferencesFile),
           let decoded = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            preferences = decoded
        }
        if let value = try? String(contentsOf: Paths.userProfileFile, encoding: .utf8) {
            preferences.userProfileMarkdown = value
        }
        if let value = try? String(contentsOf: Paths.soulProfileFile, encoding: .utf8) {
            preferences.soulProfileMarkdown = value
        }
    }

    func updatePreferredName(_ value: String) {
        preferences.preferredName = value.trimmingCharacters(in: .whitespacesAndNewlines)
        persist()
    }

    func updateTheme(_ theme: AppColorTheme) {
        preferences.theme = theme
        persist()
    }

    func updateUserProfileMarkdown(_ value: String) {
        preferences.userProfileMarkdown = value
        persist()
    }

    func updateSoulProfileMarkdown(_ value: String) {
        preferences.soulProfileMarkdown = value
        persist()
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(preferences)
            try data.write(to: Paths.userPreferencesFile, options: [.atomic])
            try preferences.userProfileMarkdown.write(to: Paths.userProfileFile, atomically: true, encoding: .utf8)
            try preferences.soulProfileMarkdown.write(to: Paths.soulProfileFile, atomically: true, encoding: .utf8)
        } catch {}
    }
}

// MARK: - App state

@MainActor
final class AppState: ObservableObject {
    // MARK: Stored properties – declared before the initializer so they are in scope
    @Published var modelStore = ModelCatalogStore()
    @Published var workspaceStore = WorkspaceStore()
    @Published var chatStore = ChatStore()
    @Published var providerStore = ProviderStore()
    @Published var runtimePreferences = RuntimePreferencesStore()
    @Published var tabPreferencesStore = TabPreferencesStore()
    @Published var userPreferencesStore = UserPreferencesStore()
    @Published var runtimeStatus = "Not configured"
    @Published var stackConfig = StackConfig.default
    @Published var gemmaDownloadState: ModelDownloadState = .notInstalled
    @Published var providerModels: [ProviderKind: [CloudModel]] = [:]
    @Published var providerModelLoading = Set<ProviderKind>()
    @Published var providerModelErrors: [ProviderKind: String] = [:]
    @Published var workspaceRuntime = OpenClawWorkspaceRuntime()
    @Published var macRuntimeSnapshot: MacRuntimeSnapshot?
    @Published var macRuntimeStatus = "Mac not inspected"

    // MARK: Initializer – now placed after property declarations
    init(engine: LocalLLMEngine) {
        self.engine = engine
    }

    var orderedVisibleTabs: [AppTab] {
        tabPreferencesStore.preferences.visibleTabs
    }

    var selectedTab: AppTab {
        get { tabPreferencesStore.preferences.selectedTab }
        set {
            tabPreferencesStore.preferences.selectedTab = newValue
            tabPreferencesStore.persist()
        }
    }

    var selectedInstalledModel: InstalledModel? {
        guard let filename = runtimePreferences.selection.selectedInstalledFilename else { return nil }
        return modelStore.installedModels.first(where: { $0.localFilename == filename })
    }

    var usesStubRuntime: Bool {
        !engine.supportsLocalModels
    }

    var canUseSelectedLocalModel: Bool {
        selectedInstalledModel != nil && !usesStubRuntime
    }

    var selectedProviderAccount: ProviderAccount? {
        guard let provider = runtimePreferences.selection.selectedProvider else { return nil }
        let account = providerStore.account(for: provider)
        return account.isEnabled ? account : nil
    }

    var operatorDisplayName: String {
        let preferred = userPreferencesStore.preferences.preferredName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !preferred.isEmpty { return preferred }
        let configured = stackConfig.operatorName.trimmingCharacters(in: .whitespacesAndNewlines)
        return configured.isEmpty ? stackConfig.stackName : configured
    }

    var activeRouteModeLabel: String {
        if selectedProviderAccount != nil { return "Direct cloud model route" }
        if selectedInstalledModel != nil { return usesStubRuntime ? "Local runtime unavailable" : "On-device route" }
        return "Route not configured"
    }

    var operatorSummary: String {
        if let account = selectedProviderAccount {
            return "Chat is routed through \(account.provider.displayName) using \(account.modelSlug). Workspace actions use the built-in OpenClaw runtime and receipts."
        } else if let model = selectedInstalledModel {
            if usesStubRuntime {
                return "\(model.displayName) is selected, but local inference is unavailable in this build."
            }
            return "Selected runtime target: \(model.modelID.isEmpty ? model.localFilename : model.modelID)."
        } else if usesStubRuntime {
            return stackConfig.deploymentMode == .bootstrapSelfHosted
                ? "Stack profile is configured, but real chat still depends on a linked provider or a working on-device inference runtime."
                : "Link a provider or local runtime before claiming the shell is ready."
        } else if engine.requiresModelSelection {
            return "Runtime bridge is present, but no packaged model is selected yet."
        } else {
            return "Runtime ready."
        }
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

    var activeRouteTitle: String {
        if let account = selectedProviderAccount {
            return "\(account.provider.displayName) route"
        }
        if let model = selectedInstalledModel {
            return model.displayName
        }
        return "Route not configured"
    }

    var activeRouteDetail: String {
        if let account = selectedProviderAccount {
            return "\(account.modelSlug) via \(account.baseURL)"
        }
        if let model = selectedInstalledModel {
            let target = model.modelID.isEmpty ? model.localFilename : model.modelID
            return usesStubRuntime ? "\(target) selected, but local inference is not live in this build." : target
        }
        return "Runtime endpoint: \(stackConfig.gatewayURL). Select a live route in Models before using chat as if the stack is online."
    }

    var routeHealthSummary: String {
        if selectedProviderAccount != nil {
            return "Cloud chat is ready. Workspace actions require BeMore runtime receipts."
        }
        if let model = selectedInstalledModel {
            return usesStubRuntime
                ? "\(model.displayName) is selected, but local inference is still unavailable in this build."
                : "On-device route ready."
        }
        return usesStubRuntime
            ? "Stack profile saved, but no live chat route is ready yet."
            : "No route selected yet."
    }

    var persistenceSummary: String {
        "Files, chat history, provider metadata, buddy state, onboarding stack profile, and tab preferences persist locally inside the app container."
    }

    var macPairingEndpoint: String {
        stackConfig.gatewayURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var macPowerModeSummary: String {
        guard let snapshot = macRuntimeSnapshot else {
            return "Pair with BeMore Mac to inspect workspace state, tasks, command output, artifacts, receipts, and diffs from the phone."
        }
        let workspace = snapshot.workspaceRoot ?? "no workspace"
        return "\(snapshot.pairing.hostName) is \(snapshot.pairing.status); \(workspace); \(snapshot.tasks.count) task\(snapshot.tasks.count == 1 ? "" : "s"), \(snapshot.processes.count) process\(snapshot.processes.count == 1 ? "" : "es"), \(snapshot.receipts.count) receipt\(snapshot.receipts.count == 1 ? "" : "s")."
    }

    weak var buddyProfileStore: BuddyProfileStore?

    private let engine: LocalLLMEngine
    private let cloudExecutionService = CloudExecutionService()



    var backendDisplayName: String {
        if let account = selectedProviderAccount {
            return "Cloud routing via \(account.provider.displayName)"
        }
        return engine.backendDisplayName
    }

    func bootstrap() async {
        loadStackConfig()
        modelStore.load()
        workspaceStore.load()
        chatStore.load()
        providerStore.load()
        runtimePreferences.load()
        tabPreferencesStore.load()
        userPreferencesStore.load()
        workspaceRuntime.bootstrap(config: stackConfig, preferences: userPreferencesStore.preferences, routeSummary: activeRouteModeLabel)
        refreshGemmaState()
        refreshRuntimeSummary()
        for account in providerStore.enabledProviders() {
            Task { await refreshProviderModels(for: account.provider) }
        }
        do {
            try await engine.bootstrap()
            try await applySelectedModelIfPossible()
            refreshRuntimeSummary()
        } catch {
            chatStore.errorMessage = error.localizedDescription
            runtimeStatus = "Runtime error"
        }
    }

    // MARK: - Onboarding

    func completeOnboarding(_ config: StackConfig) {
        stackConfig = config
        if !config.operatorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           userPreferencesStore.preferences.preferredName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            userPreferencesStore.updatePreferredName(config.operatorName)
        }
        persistStackConfig()
        workspaceRuntime.bootstrap(config: stackConfig, preferences: userPreferencesStore.preferences, routeSummary: activeRouteModeLabel)
        buddyProfileStore?.load(for: config)
        refreshRuntimeSummary()
    }

    func loadStackConfig() {
        guard let data = try? Data(contentsOf: Paths.stackConfigFile) else { return }
        stackConfig = (try? JSONDecoder().decode(StackConfig.self, from: data)) ?? StackConfig.default
        if stackConfig.setupChecklist.isEmpty && stackConfig.isOnboardingComplete {
            stackConfig.setupChecklist = generatedSetupChecklist(for: stackConfig)
        }
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
        let gemmaSourceURL = "https://huggingface.co/unsloth/gemma-2-it-GGUF/resolve/main/gemma-2-2b-it.q4_k_m.gguf"

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
                    modelLib: "gemma_2_2b_it_q4_k_m"
                ) { [weak self] progress in
                    Task { @MainActor in
                        self?.gemmaDownloadState = .downloading(progress: progress)
                    }
                }
                gemmaDownloadState = .installed
            } catch {
                gemmaDownloadState = .failed(message: ModelSourceValidator.userFacingDownloadMessage(for: error))
            }
        }
    }

    // MARK: - Model selection

    func setSelectedInstalledModel(filename: String?) async {
        runtimePreferences.selection.selectedInstalledFilename = filename
        if filename != nil {
            runtimePreferences.selection.selectedProvider = nil
        }
        runtimePreferences.persist()
        do {
            try await applySelectedModelIfPossible()
        } catch {
            chatStore.errorMessage = error.localizedDescription
            runtimeStatus = "Runtime error"
        }
        refreshRuntimeSummary()
    }

    func setSelectedProvider(_ provider: ProviderKind?) {
        runtimePreferences.selection.selectedProvider = provider
        if provider != nil {
            runtimePreferences.selection.selectedInstalledFilename = nil
        }
        runtimePreferences.persist()
        refreshRuntimeSummary()
    }

    func updatePreferredOperatorName(_ value: String) {
        userPreferencesStore.updatePreferredName(value)
        workspaceRuntime.bootstrap(config: stackConfig, preferences: userPreferencesStore.preferences, routeSummary: activeRouteModeLabel)
    }

    func updateTheme(_ theme: AppColorTheme) {
        userPreferencesStore.updateTheme(theme)
        workspaceRuntime.bootstrap(config: stackConfig, preferences: userPreferencesStore.preferences, routeSummary: activeRouteModeLabel)
    }

    func setTabVisibility(_ tab: AppTab, isVisible: Bool) {
        guard tab.allowsHiding else { return }
        if isVisible {
            tabPreferencesStore.preferences.hiddenTabs.remove(tab)
        } else {
            tabPreferencesStore.preferences.hiddenTabs.insert(tab)
        }
        tabPreferencesStore.persist()
        if !orderedVisibleTabs.contains(selectedTab) {
            selectedTab = orderedVisibleTabs.first ?? .missionControl
        }
    }

    func moveTabs(fromOffsets: IndexSet, toOffset: Int) {
        var visibleTabs = orderedVisibleTabs
        visibleTabs.move(fromOffsets: fromOffsets, toOffset: toOffset)
        let hiddenTabs = tabPreferencesStore.preferences.orderedTabs.filter { tabPreferencesStore.preferences.hiddenTabs.contains($0) }
        tabPreferencesStore.preferences.orderedTabs = visibleTabs + hiddenTabs
        tabPreferencesStore.persist()
    }

    func removeProvider(_ provider: ProviderKind) {
        providerStore.remove(provider)
        providerModels[provider] = nil
        providerModelErrors[provider] = nil
        if runtimePreferences.selection.selectedProvider == provider {
            runtimePreferences.selection.selectedProvider = nil
            runtimePreferences.persist()
            refreshRuntimeSummary()
        }
    }

    func updateProviderModel(_ provider: ProviderKind, modelSlug: String) {
        var account = providerStore.account(for: provider)
        account.modelSlug = modelSlug.trimmingCharacters(in: .whitespacesAndNewlines)
        providerStore.upsert(account)
        if runtimePreferences.selection.selectedProvider == provider {
            refreshRuntimeSummary()
        }
    }

    func availableModels(for provider: ProviderKind) -> [CloudModel] {
        let account = providerStore.account(for: provider)
        var models = providerModels[provider] ?? CloudModelCatalog.models(for: provider)
        if !account.modelSlug.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !models.contains(where: { $0.slug == account.modelSlug }) {
            models.insert(CloudModel(provider: provider, slug: account.modelSlug, displayName: account.modelSlug, notes: "Current selection"), at: 0)
        }
        return models
    }

    func refreshProviderModels(for provider: ProviderKind, force: Bool = false) async {
        let account = providerStore.account(for: provider)
        guard account.isEnabled else {
            providerModels[provider] = CloudModelCatalog.models(for: provider)
            providerModelErrors[provider] = nil
            return
        }
        if providerModelLoading.contains(provider) { return }
        if !force, providerModels[provider] != nil { return }

        providerModelLoading.insert(provider)
        providerModelErrors[provider] = nil
        defer { providerModelLoading.remove(provider) }

        do {
            let discovered = try await cloudExecutionService.availableModels(account: account)
            let sorted = discovered.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
            providerModels[provider] = sorted.isEmpty ? CloudModelCatalog.models(for: provider) : sorted
        } catch CloudExecutionServiceError.upstreamFailure(let message) {
            providerModels[provider] = CloudModelCatalog.models(for: provider)
            providerModelErrors[provider] = message
        } catch {
            providerModels[provider] = CloudModelCatalog.models(for: provider)
            providerModelErrors[provider] = error.localizedDescription
        }
    }

    func verifyProviderConnection(_ provider: ProviderKind) async {
        let account = providerStore.account(for: provider)

        guard account.isEnabled else {
            chatStore.errorMessage = "Link and save \(provider.displayName) before testing the route."
            return
        }

        do {
            runtimeStatus = "Testing \(provider.displayName)..."
            let reply = try await cloudExecutionService.send(
                account: account,
                messages: [
                    CloudExecutionMessage(role: .system, content: "You are verifying BeMoreAgent's direct cloud chat route for an OpenClaw operator stack. Reply with exactly: ROUTE_OK"),
                    CloudExecutionMessage(role: .user, content: "Return ROUTE_OK")
                ],
                temperature: 0,
                maxOutputTokens: 12
            )
            let cleaned = reply.trimmingCharacters(in: .whitespacesAndNewlines)
            chatStore.messages.append(ChatMessage(role: .system, content: "\(provider.displayName) route check: \(cleaned)"))
            chatStore.persist()
            await refreshProviderModels(for: provider, force: true)
            refreshRuntimeSummary()
        } catch CloudExecutionServiceError.upstreamFailure(let message) {
            chatStore.errorMessage = message
            runtimeStatus = "\(provider.displayName) check failed"
        } catch {
            chatStore.errorMessage = error.localizedDescription
            runtimeStatus = "\(provider.displayName) check failed"
        }
    }

    // MARK: - BeMore Mac pairing

    func refreshMacRuntimeSnapshot() async {
        let endpoint = macPairingEndpoint
        guard var components = URLComponents(string: endpoint), !endpoint.isEmpty else {
            macRuntimeStatus = "Add a BeMore Mac endpoint in onboarding or settings."
            return
        }

        if components.scheme == nil {
            components.scheme = "https"
        }

        let normalizedPath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        components.path = normalizedPath.hasSuffix("api/snapshot") ? components.path : "/api/snapshot"

        guard let url = components.url else {
            macRuntimeStatus = "Mac endpoint is not a valid URL."
            return
        }

        do {
            macRuntimeStatus = "Inspecting BeMore Mac..."
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                macRuntimeStatus = "Mac runtime returned HTTP \(http.statusCode)."
                return
            }
            macRuntimeSnapshot = try JSONDecoder().decode(MacRuntimeSnapshot.self, from: data)
            macRuntimeStatus = "Paired power mode ready"
        } catch {
            macRuntimeStatus = "Mac unavailable: \(error.localizedDescription)"
        }
    }

    // MARK: - Chat

    func send(prompt: String) async {
        let cleaned = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        if selectedProviderAccount == nil && engine.requiresModelSelection && selectedInstalledModel == nil {
            chatStore.errorMessage = "Link a provider in Settings or select an installed model in Models before sending."
            runtimeStatus = "Model or provider required"
            return
        }

        if selectedProviderAccount == nil && usesStubRuntime {
            chatStore.errorMessage = "This build does not include the on-device runtime yet. Link a cloud provider for real chat."
            runtimeStatus = "Local runtime unavailable"
            return
        }

        chatStore.messages.append(ChatMessage(role: .user, content: cleaned))
        workspaceRuntime.refreshMetadata()
        chatStore.persist()
        chatStore.isGenerating = true

        let attachedFiles = workspaceStore.files.filter { chatStore.selectedFileIDs.contains($0.id) }

        do {
            let reply: String
            if let account = selectedProviderAccount {
                runtimeStatus = "Cloud: \(account.provider.displayName)"
                reply = AgentReplySanitizer.userVisibleAnswer(from: try await cloudExecutionService.send(
                    account: account,
                    messages: buildCloudMessages(attachedFiles: attachedFiles)
                ))
            } else {
                if usesStubRuntime { runtimeStatus = "Stub preview" }
                reply = AgentReplySanitizer.userVisibleAnswer(from: try await engine.generate(prompt: cleaned, fileContexts: attachedFiles, chatHistory: chatStore.messages))
            }
            chatStore.messages.append(ChatMessage(role: .assistant, content: reply))
            workspaceRuntime.refreshMetadata()
            chatStore.persist()
        } catch CloudExecutionServiceError.upstreamFailure(let message) {
            chatStore.errorMessage = message
        } catch {
            chatStore.errorMessage = error.localizedDescription
        }

        refreshRuntimeSummary()

        chatStore.isGenerating = false
    }

    func runSkill(id: String, input: [String: String] = [:]) -> OpenClawReceipt {
        let receipt = workspaceRuntime.runSkill(id: id, input: input, config: stackConfig, preferences: userPreferencesStore.preferences, routeSummary: activeRouteModeLabel)
        chatStore.messages.append(ChatMessage(role: .system, content: ReceiptFormatter.confirmedSummary(for: receipt)))
        chatStore.persist()
        return receipt
    }

    func regenerateArtifacts(target: String = "all") -> OpenClawReceipt {
        let receipt = workspaceRuntime.regenerateArtifacts(target: target, config: stackConfig, preferences: userPreferencesStore.preferences, routeSummary: activeRouteModeLabel)
        chatStore.messages.append(ChatMessage(role: .system, content: ReceiptFormatter.confirmedSummary(for: receipt)))
        chatStore.persist()
        return receipt
    }

    func runSandbox(command: String) -> OpenClawReceipt {
        let receipt = workspaceRuntime.runSandbox(command: command, config: stackConfig, preferences: userPreferencesStore.preferences, routeSummary: activeRouteModeLabel)
        chatStore.messages.append(ChatMessage(role: .system, content: ReceiptFormatter.confirmedSummary(for: receipt)))
        chatStore.persist()
        return receipt
    }

    func writeWorkspaceArtifact(path: String, content: String) -> OpenClawReceipt {
        let receipt: OpenClawReceipt
        do {
            receipt = try workspaceRuntime.writeFile(path, content: content, source: "user")
        } catch {
            receipt = OpenClawReceipt(actionId: UUID(), status: .failed, title: "Write \(path)", summary: "Could not write \(path)", output: [:], artifacts: [], logs: [], error: error.localizedDescription)
        }
        chatStore.messages.append(ChatMessage(role: .system, content: ReceiptFormatter.confirmedSummary(for: receipt)))
        chatStore.persist()
        return receipt
    }

    func deleteWorkspaceArtifact(path: String) -> OpenClawReceipt {
        let receipt = workspaceRuntime.deleteFile(path, source: "user")
        chatStore.messages.append(ChatMessage(role: .system, content: ReceiptFormatter.confirmedSummary(for: receipt)))
        chatStore.persist()
        return receipt
    }

    func installClawHubSkill(_ template: ClawHubSkillTemplate) -> OpenClawReceipt {
        let receipt = workspaceRuntime.installClawHubSkill(template)
        _ = regenerateArtifacts(target: "skills.md")
        chatStore.messages.append(ChatMessage(role: .system, content: ReceiptFormatter.confirmedSummary(for: receipt)))
        chatStore.persist()
        return receipt
    }

    var buddyRuntimeStatus: BuddyRuntimeStatus {
        workspaceRuntime.buddyStatus(
            activeModelAdapter: backendDisplayName,
            brainConnected: selectedProviderAccount != nil || canUseSelectedLocalModel,
            runtimeAvailable: workspaceRuntime.isBootstrapped,
        )
    }

    // MARK: - Private

    func refreshRuntimeSummary() {
        if let account = selectedProviderAccount {
            runtimeStatus = "Cloud: \(account.provider.displayName) • \(account.modelSlug)"
        } else if let model = selectedInstalledModel {
            if usesStubRuntime {
                runtimeStatus = "Local model selected, runtime unavailable"
            } else {
                runtimeStatus = model.modelID.isEmpty ? "On-device: \(model.localFilename)" : "On-device: \(model.modelID)"
            }
        } else if usesStubRuntime {
            runtimeStatus = stackConfig.isOnboardingComplete ? "Route not configured" : "Onboarding required"
        } else {
            runtimeStatus = "Route not configured"
        }
    }

    private func buildCloudMessages(attachedFiles: [WorkspaceFile]) -> [CloudExecutionMessage] {
        let routeLabel = selectedProviderAccount.map { "\($0.provider.displayName) using \($0.modelSlug)" } ?? "No selected cloud provider"
        var messages: [CloudExecutionMessage] = [
            CloudExecutionMessage(
                role: .system,
                content: CloudPromptBuilder.systemPrompt(
                    config: stackConfig,
                    operatorName: operatorDisplayName,
                    routeLabel: routeLabel
                ) + "\n\nWorkspace Runtime: Available inside BeMore. Ask for actions through the runtime contract; do not claim files, memory, skills, or sandbox commands changed unless a BeMore receipt confirms it. Registered skills: \(workspaceRuntime.skills.map(\.name).joined(separator: ", ")). Canonical artifacts: soul.md, user.md, memory.md, session.md, skills.md.\n\nMac Power Mode: \(macPowerModeSummary)"
            )
        ]

        if !attachedFiles.isEmpty {
            let rendered = attachedFiles.map { file -> String in
                let text = (try? String(contentsOf: file.localURL, encoding: .utf8)) ?? "[binary or unreadable file]"
                return "FILE: \(file.filename)\n\(text.prefix(8000))"
            }.joined(separator: "\n\n")
            messages.append(CloudExecutionMessage(role: .system, content: rendered))
        }

        for message in chatStore.messages.suffix(12) {
            let role: CloudExecutionMessage.Role = switch message.role {
            case .user: .user
            case .assistant: .assistant
            case .system: .system
            }
            messages.append(CloudExecutionMessage(role: role, content: message.content))
        }

        return messages
    }

    private func generatedSetupChecklist(for config: StackConfig) -> [String] {
        var items: [String] = []
        if config.deploymentMode == .bootstrapSelfHosted {
            items.append("Provision or verify the BeMore Mac runtime endpoint at \(config.gatewayURL).")
            items.append("Set runtime and pairing/public URL values to match \(config.adminDomain).")
        } else {
            items.append("Pair this app to the existing BeMore Mac runtime endpoint at \(config.gatewayURL).")
        }
        if config.installNodeOnThisPhone {
            items.append("Treat this iPhone as a node surface and grant notification or device permissions as needed.")
        }
        if config.installDesktopNode {
            items.append("Keep a desktop or server node online so the shell has a real self-hosted stack to connect to.")
        }
        if config.toolsEnabled {
            items.append("Enable only the tools the operator actually wants exposed through the stack.")
        }
        items.append("Verify local runtime readiness honestly before presenting the stack as fully operational.")
        return items
    }

    private func applySelectedModelIfPossible() async throws {
        guard let filename = runtimePreferences.selection.selectedInstalledFilename else {
            try await engine.configureRuntime(nil)
            runtimeStatus = "Route not configured"
            return
        }

        guard let installed = modelStore.installedModels.first(where: { $0.localFilename == filename }) else {
            try await engine.configureRuntime(nil)
            runtimeStatus = "Selected model missing"
            return
        }

        guard engine.supportsLocalModels else {
            try await engine.configureRuntime(nil)
            runtimeStatus = "Local model selected, runtime unavailable"
            return
        }

        try await engine.configureRuntime(
            EngineRuntimeConfig(modelURL: installed.localURL, modelID: installed.modelID, modelLib: installed.modelLib)
        )
        runtimeStatus = installed.modelID.isEmpty ? "On-device: \(installed.localFilename)" : "On-device: \(installed.modelID)"
    }
}
