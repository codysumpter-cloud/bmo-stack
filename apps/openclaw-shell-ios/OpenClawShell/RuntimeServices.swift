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
    static var providersFile: URL { stateDirectory.appendingPathComponent("providers.json") }
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
        var request = try makeRequest(account: account, messages: messages, temperature: temperature, maxOutputTokens: maxOutputTokens)
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        let preview = String(data: data.prefix(6000), encoding: .utf8) ?? ""

        guard (200...299).contains(statusCode) else {
            throw CloudExecutionServiceError.upstreamFailure(preview.isEmpty ? "Request failed with status \(statusCode)." : preview)
        }

        return try parse(provider: account.provider, data: data)
    }

    private func makeRequest(account: ProviderAccount, messages: [CloudExecutionMessage], temperature: Double?, maxOutputTokens: Int?) throws -> URLRequest {
        let normalizedBase = ProviderTransport.normalizeBaseURL(for: account.provider, rawValue: account.baseURL)
        guard let url = requestURL(provider: account.provider, baseURL: normalizedBase, model: account.modelSlug) else {
            throw CloudExecutionServiceError.invalidBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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

        request.httpBody = try requestBody(provider: account.provider, model: account.modelSlug, messages: messages, temperature: temperature, maxOutputTokens: maxOutputTokens)
        return request
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

// MARK: - App state

@MainActor
final class AppState: ObservableObject {
    @Published var modelStore = ModelCatalogStore()
    @Published var workspaceStore = WorkspaceStore()
    @Published var chatStore = ChatStore()
    @Published var providerStore = ProviderStore()
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

    var selectedProviderAccount: ProviderAccount? {
        guard let provider = runtimePreferences.selection.selectedProvider else { return nil }
        let account = providerStore.account(for: provider)
        return account.isEnabled ? account : nil
    }

    var operatorSummary: String {
        if let account = selectedProviderAccount {
            return "Cloud chat ready via \(account.provider.displayName) using \(account.modelSlug)."
        }
        if let model = selectedInstalledModel {
            return "On-device runtime selected: \(model.modelID.isEmpty ? model.localFilename : model.modelID)."
        }
        if usesStubRuntime {
            return "Link a cloud provider or install a local model to enable real chat."
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
    private let cloudExecutionService = CloudExecutionService()

    init(engine: LocalLLMEngine) {
        self.engine = engine
    }

    var backendDisplayName: String { engine.backendDisplayName }

    func bootstrap() async {
        loadStackConfig()
        modelStore.load()
        workspaceStore.load()
        chatStore.load()
        providerStore.load()
        runtimePreferences.load()
        refreshGemmaState()
        refreshRuntimeSummary()
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

    // MARK: - Chat

    func send(prompt: String) async {
        let cleaned = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        if selectedProviderAccount == nil && engine.requiresModelSelection && selectedInstalledModel == nil {
            chatStore.errorMessage = "Link a provider in Settings or select an installed model in Models before sending."
            runtimeStatus = "Model or provider required"
            return
        }

        chatStore.messages.append(ChatMessage(role: .user, content: cleaned))
        chatStore.persist()
        chatStore.isGenerating = true

        let attachedFiles = workspaceStore.files.filter { chatStore.selectedFileIDs.contains($0.id) }

        do {
            let reply: String
            if let account = selectedProviderAccount {
                runtimeStatus = "Cloud: \(account.provider.displayName)"
                reply = try await cloudExecutionService.send(
                    account: account,
                    messages: buildCloudMessages(prompt: cleaned, attachedFiles: attachedFiles)
                )
            } else {
                if usesStubRuntime { runtimeStatus = "Stub preview" }
                reply = try await engine.generate(prompt: cleaned, fileContexts: attachedFiles, chatHistory: chatStore.messages)
            }
            chatStore.messages.append(ChatMessage(role: .assistant, content: reply))
            chatStore.persist()
        } catch CloudExecutionServiceError.upstreamFailure(let message) {
            chatStore.errorMessage = message
        } catch {
            chatStore.errorMessage = error.localizedDescription
        }

        refreshRuntimeSummary()

        chatStore.isGenerating = false
    }

    // MARK: - Private

    func refreshRuntimeSummary() {
        if let account = selectedProviderAccount {
            runtimeStatus = "Cloud: \(account.provider.displayName) • \(account.modelSlug)"
        } else if let model = selectedInstalledModel {
            runtimeStatus = model.modelID.isEmpty ? "Selected: \(model.localFilename)" : "Selected: \(model.modelID)"
        } else if usesStubRuntime {
            runtimeStatus = "Link provider or select model"
        } else {
            runtimeStatus = "No model selected"
        }
    }

    private func buildCloudMessages(prompt: String, attachedFiles: [WorkspaceFile]) -> [CloudExecutionMessage] {
        var messages: [CloudExecutionMessage] = [
            CloudExecutionMessage(role: .system, content: "You are BeMoreAgent, a practical assistant inside the iOS app. Be concise, helpful, and use any attached file context when relevant.")
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

        messages.append(CloudExecutionMessage(role: .user, content: prompt))
        return messages
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
        runtimeStatus = installed.modelID.isEmpty ? "Selected: \(installed.localFilename)" : "Selected: \(installed.modelID)"
    }
}
