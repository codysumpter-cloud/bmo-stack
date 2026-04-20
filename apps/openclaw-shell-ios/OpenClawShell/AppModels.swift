import Foundation
import SwiftUI

// MARK: - Chat

struct ChatMessage: Identifiable, Codable, Hashable {
    enum Role: String, Codable {
        case user
        case assistant
        case system
    }

    let id: UUID
    let role: Role
    let content: String
    let createdAt: Date

    init(id: UUID = UUID(), role: Role, content: String, createdAt: Date = .now) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}

// MARK: - Workspace

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

// MARK: - Models

struct RemoteModel: Identifiable, Codable, Hashable {
    let id: UUID
    var displayName: String
    var sourceURL: String
    var localFilename: String
    var modelID: String
    var modelLib: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        displayName: String,
        sourceURL: String,
        modelID: String = "",
        modelLib: String = "",
        localFilename: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        self.sourceURL = sourceURL
        self.modelID = modelID
        self.modelLib = modelLib
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

struct InstalledModel: Identifiable, Codable, Hashable {
    let id: UUID
    let displayName: String
    let localFilename: String
    let localURL: URL
    let fileSizeBytes: Int64
    let addedAt: Date
    let modelID: String
    let modelLib: String

    init(
        id: UUID = UUID(),
        displayName: String,
        localFilename: String,
        localURL: URL,
        fileSizeBytes: Int64,
        addedAt: Date = .now,
        modelID: String = "",
        modelLib: String = ""
    ) {
        self.id = id
        self.displayName = displayName
        self.localFilename = localFilename
        self.localURL = localURL
        self.fileSizeBytes = fileSizeBytes
        self.addedAt = addedAt
        self.modelID = modelID
        self.modelLib = modelLib
    }
}

struct InstalledModelDescriptor: Codable, Hashable {
    var filename: String
    var displayName: String
    var modelID: String
    var modelLib: String
}

enum ProviderKind: String, Codable, CaseIterable, Identifiable {
    case nvidia
    case google
    case openAI = "openai"
    case huggingFace = "huggingface"
    case ollama

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nvidia: return "NVIDIA"
        case .google: return "Google AI Studio"
        case .openAI: return "OpenAI"
        case .huggingFace: return "Hugging Face"
        case .ollama: return "Ollama"
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .nvidia: return "https://integrate.api.nvidia.com/v1"
        case .google: return "https://generativelanguage.googleapis.com"
        case .openAI: return "https://api.openai.com/v1"
        case .huggingFace: return "https://router.huggingface.co/v1"
        case .ollama: return "http://localhost:11434"
        }
    }

    var accountHint: String {
        switch self {
        case .nvidia: return "Paste a build.nvidia.com API key"
        case .google: return "Paste a Google AI Studio API key"
        case .openAI: return "Paste an OpenAI API key. ChatGPT OAuth can be added later with a real OAuth client flow."
        case .huggingFace: return "Paste a Hugging Face token"
        case .ollama: return "Set your Ollama server URL, optionally with a bearer token"
        }
    }
}

struct ProviderAccount: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var provider: ProviderKind
    var label: String
    var apiKey: String
    var baseURL: String
    var modelSlug: String
    var isEnabled: Bool
    var lastValidatedAt: Date?

    static func blank(for provider: ProviderKind) -> ProviderAccount {
        ProviderAccount(
            provider: provider,
            label: provider.displayName,
            apiKey: "",
            baseURL: provider.defaultBaseURL,
            modelSlug: CloudModelCatalog.suggestedDefaultModel(for: provider),
            isEnabled: false,
            lastValidatedAt: nil
        )
    }
}

struct CloudModel: Identifiable, Hashable {
    var id: String { "\(provider.rawValue):\(slug)" }
    let provider: ProviderKind
    let slug: String
    let displayName: String
    let notes: String
}

enum CloudModelCatalog {
    static func models(for provider: ProviderKind) -> [CloudModel] {
        switch provider {
        case .nvidia:
            return [
                CloudModel(provider: .nvidia, slug: "meta/llama-3.3-70b-instruct", displayName: "Llama 3.3 70B Instruct", notes: "Good default on build.nvidia.com"),
                CloudModel(provider: .nvidia, slug: "deepseek-ai/deepseek-r1", displayName: "DeepSeek R1", notes: "Reasoning-heavy option")
            ]
        case .google:
            return [
                CloudModel(provider: .google, slug: "gemini-2.5-pro", displayName: "Gemini 2.5 Pro", notes: "Best quality"),
                CloudModel(provider: .google, slug: "gemini-2.5-flash", displayName: "Gemini 2.5 Flash", notes: "Fast and cheaper")
            ]
        case .openAI:
            return [
                CloudModel(provider: .openAI, slug: "gpt-4.1-mini", displayName: "GPT-4.1 mini", notes: "Fast default"),
                CloudModel(provider: .openAI, slug: "gpt-4.1", displayName: "GPT-4.1", notes: "Higher quality")
            ]
        case .huggingFace:
            return [
                CloudModel(provider: .huggingFace, slug: "Qwen/Qwen2.5-Coder-32B-Instruct", displayName: "Qwen 2.5 Coder 32B", notes: "Strong coding model"),
                CloudModel(provider: .huggingFace, slug: "meta-llama/Llama-3.1-8B-Instruct", displayName: "Llama 3.1 8B", notes: "General purpose")
            ]
        case .ollama:
            return [
                CloudModel(provider: .ollama, slug: "llama3.1:8b", displayName: "Llama 3.1 8B", notes: "Good local default"),
                CloudModel(provider: .ollama, slug: "qwen2.5-coder:7b", displayName: "Qwen 2.5 Coder 7B", notes: "Coding-focused")
            ]
        }
    }

    static func suggestedDefaultModel(for provider: ProviderKind) -> String {
        models(for: provider).first?.slug ?? ""
    }
}

struct RuntimeSelection: Codable, Hashable {
    var selectedInstalledFilename: String?
    var selectedProvider: ProviderKind?
}

struct EngineRuntimeConfig: Sendable {
    let modelURL: URL
    let modelID: String
    let modelLib: String
}

// MARK: - BeMore Mac pairing

struct MacRuntimeTask: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let status: String
    let detail: String?
    let command: String?
}

struct MacRuntimeProcess: Codable, Hashable, Identifiable {
    let id: String
    let command: String
    let status: String
    let stdout: String?
    let stderr: String?
    let exitCode: Int?
}

struct MacRuntimeDiffFile: Codable, Hashable, Identifiable {
    var id: String { path }
    let path: String
    let status: String
    let summary: String
}

struct MacRuntimeDiff: Codable, Hashable {
    let files: [MacRuntimeDiffFile]
    let unifiedDiff: String?
}

struct MacRuntimeArtifact: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let relativePath: String
    let kind: String
}

struct MacRuntimeReceipt: Codable, Hashable, Identifiable {
    let id: String
    let action: String
    let status: String
    let summary: String
}

struct MacRuntimeBuddy: Codable, Hashable {
    let mode: String
    let activeFocus: String
    let guidance: [String]
}

struct MacRuntimePairing: Codable, Hashable {
    let hostName: String
    let status: String
    let pairingCode: String?
}

struct MacRuntimeSnapshot: Codable, Hashable {
    let workspaceRoot: String?
    let tasks: [MacRuntimeTask]
    let processes: [MacRuntimeProcess]
    let artifacts: [MacRuntimeArtifact]
    let receipts: [MacRuntimeReceipt]
    let diff: MacRuntimeDiff
    let buddy: MacRuntimeBuddy
    let pairing: MacRuntimePairing
}

// MARK: - Onboarding / Stack

enum StackDeploymentMode: String, Codable, CaseIterable, Hashable, Identifiable {
    case pairToExistingGateway
    case bootstrapSelfHosted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pairToExistingGateway: return "Pair to an existing runtime"
        case .bootstrapSelfHosted: return "Set up a self-hosted BeMore stack"
        }
    }

    var subtitle: String {
        switch self {
        case .pairToExistingGateway:
            return "Connect this iPhone to a BeMore Mac runtime endpoint you already run."
        case .bootstrapSelfHosted:
            return "Use onboarding answers to generate the exact stack profile, runtime target, and next setup steps for a self-hosted deployment."
        }
    }
}

enum BuddyPowerMode: String, Codable, CaseIterable, Hashable, Identifiable {
    case gentle
    case balanced
    case turbo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gentle: return "Easy Start"
        case .balanced: return "Balanced"
        case .turbo: return "Power Mode"
        }
    }

    var subtitle: String {
        switch self {
        case .gentle:
            return "Keep the experience calm: planning, reminders, notes, and teaching Buddy what helps."
        case .balanced:
            return "Keep Buddy, chat, skills, and results visible without making setup feel heavy."
        case .turbo:
            return "Keep deeper operator tools close for repo, runtime, debugging, and skill work."
        }
    }

    var optimizationMode: String {
        switch self {
        case .gentle: return "balanced"
        case .balanced: return "balanced"
        case .turbo: return "quality"
        }
    }
}

struct StackConfig: Codable {
    var stackName: String
    var goal: String
    var role: String
    var onboardingBuddyName: String?
    var onboardingBuddyTemplateID: String?
    var onboardingBuddyFocus: String?
    var onboardingPowerMode: BuddyPowerMode?
    var autonomyLevel: Int // 1-5
    var memoryEnabled: Bool
    var toolsEnabled: Bool
    var optimizationMode: String // "speed", "quality", "balanced"
    var deploymentMode: StackDeploymentMode
    var operatorName: String
    var gatewayURL: String
    var adminDomain: String
    var installNodeOnThisPhone: Bool
    var installDesktopNode: Bool
    var enableNotifications: Bool
    var setupChecklist: [String]
    var isOnboardingComplete: Bool

    static let `default` = StackConfig(
        stackName: "BeMoreAgent",
        goal: "",
        role: "",
        onboardingBuddyName: nil,
        onboardingBuddyTemplateID: nil,
        onboardingBuddyFocus: nil,
        onboardingPowerMode: nil,
        autonomyLevel: 3,
        memoryEnabled: true,
        toolsEnabled: true,
        optimizationMode: "balanced",
        deploymentMode: .bootstrapSelfHosted,
        operatorName: "",
        gatewayURL: "https://prismtek.dev",
        adminDomain: "prismtek.dev",
        installNodeOnThisPhone: true,
        installDesktopNode: true,
        enableNotifications: true,
        setupChecklist: [],
        isOnboardingComplete: false
    )
}

// MARK: - Model download state

enum ModelDownloadState: Equatable {
    case notInstalled
    case downloading(progress: Double)
    case installed
    case failed(message: String)

    static func == (lhs: ModelDownloadState, rhs: ModelDownloadState) -> Bool {
        switch (lhs, rhs) {
        case (.notInstalled, .notInstalled): return true
        case (.installed, .installed): return true
        case let (.downloading(a), .downloading(b)): return a == b
        case let (.failed(a), .failed(b)): return a == b
        default: return false
        }
    }
}

// MARK: - Known model catalog

struct KnownModel: Identifiable {
    let id = UUID()
    let name: String
    let modelID: String
    let family: String
    let parameterCount: String
    let description: String
    let downloadSizeGB: Double
    let requiresDownload: Bool
    let runtimeBackend: String

    static let gemma4E2B = KnownModel(
        name: "Gemma 4 E2B-IT",
        modelID: "gemma4-e2b-it",
        family: "Gemma",
        parameterCount: "2B",
        description: "Curated small GGUF install for the BeMoreAgent shell. Direct downloads should use a public artifact or explain auth requirements clearly.",
        downloadSizeGB: 1.7,
        requiresDownload: true,
        runtimeBackend: "MLC"
    )

    static let catalog: [KnownModel] = [gemma4E2B]
}

enum AppTab: String, Codable, CaseIterable, Hashable, Identifiable {
    case missionControl
    case editor
    case buddy
    case files
    case skills
    case artifacts
    case pairing
    case models
    case chat
    case pricing
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .missionControl: return "Home"
        case .editor: return "Editor"
        case .buddy: return "Buddy"
        case .files: return "Workspace"
        case .skills: return "Skills"
        case .artifacts: return "Results"
        case .pairing: return "Mac"
        case .models: return "Models"
        case .chat: return "Chat"
        case .pricing: return "Pricing"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .missionControl: return "heart.text.square.fill"
        case .editor: return "doc.text.fill"
        case .buddy: return "person.crop.circle.badge.checkmark"
        case .files: return "folder.fill"
        case .skills: return "sparkles.rectangle.stack.fill"
        case .artifacts: return "checklist.checked"
        case .pairing: return "macbook.and.iphone"
        case .models: return "cpu"
        case .chat: return "message.fill"
        case .pricing: return "creditcard.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var allowsHiding: Bool {
        self != .missionControl
    }
}

struct ShellPreferences: Codable, Hashable {
    var orderedTabs: [AppTab]
    var hiddenTabs: Set<AppTab>
    var selectedTab: AppTab

    static let `default` = ShellPreferences(
        orderedTabs: [.missionControl, .buddy, .chat, .skills, .artifacts, .files, .pairing, .pricing, .models, .settings],
        hiddenTabs: [.pairing, .pricing, .models],
        selectedTab: .missionControl
    )

    func normalized() -> ShellPreferences {
        var order = orderedTabs
        for tab in AppTab.allCases where !order.contains(tab) {
            order.append(tab)
        }
        order = order.filter { AppTab.allCases.contains($0) }

        var hidden = hiddenTabs.filter { $0.allowsHiding && AppTab.allCases.contains($0) }
        if order.filter({ !hidden.contains($0) }).isEmpty {
            hidden.removeAll()
        }

        let selected = hidden.contains(selectedTab) ? order.first(where: { !hidden.contains($0) }) ?? .missionControl : selectedTab
        return ShellPreferences(orderedTabs: order, hiddenTabs: hidden, selectedTab: selected)
    }

    var visibleTabs: [AppTab] {
        let normalized = normalized()
        return normalized.orderedTabs.filter { !normalized.hiddenTabs.contains($0) }
    }
}

enum AppColorTheme: String, Codable, Hashable, CaseIterable, Identifiable {
    case system
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .dark: return "Dark"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        }
    }
}

struct UserPreferences: Codable, Hashable {
    var preferredName: String
    var theme: AppColorTheme
    var userProfileMarkdown: String
    var soulProfileMarkdown: String

    static let `default` = UserPreferences(
        preferredName: "",
        theme: .dark,
        userProfileMarkdown: "",
        soulProfileMarkdown: ""
    )
}
