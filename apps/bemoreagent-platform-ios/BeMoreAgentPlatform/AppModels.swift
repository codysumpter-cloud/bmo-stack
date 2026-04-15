import Foundation

enum ProviderKind: String, Codable, CaseIterable, Identifiable {
    case nvidia
    case ollama
    case huggingFace = "huggingface"
    case google
    case xai
    case openRouter = "openrouter"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nvidia: return "NVIDIA"
        case .ollama: return "Ollama"
        case .huggingFace: return "Hugging Face"
        case .google: return "Google"
        case .xai: return "xAI (Grok)"
        case .openRouter: return "OpenRouter"
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .nvidia: return "https://integrate.api.nvidia.com/v1"
        case .ollama: return "http://localhost:11434"
        case .huggingFace: return "https://api-inference.huggingface.co"
        case .google: return "https://generativelanguage.googleapis.com"
        case .xai: return "https://api.x.ai/v1"
        case .openRouter: return "https://openrouter.ai/api/v1"
        }
    }

    var accountHint: String {
        switch self {
        case .nvidia: return "Paste an NVIDIA API key"
        case .ollama: return "Set the Ollama server URL"
        case .huggingFace: return "Paste a Hugging Face token"
        case .google: return "Paste a Google AI Studio / Gemini API key"
        case .xai: return "Paste an xAI API key"
        case .openRouter: return "Paste an OpenRouter API key"
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
    let id = UUID()
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
                CloudModel(provider: .nvidia, slug: "meta/llama-3.1-70b-instruct", displayName: "Llama 3.1 70B Instruct", notes: "NVIDIA hosted inference"),
                CloudModel(provider: .nvidia, slug: "mistralai/mixtral-8x7b-instruct-v0.1", displayName: "Mixtral 8x7B", notes: "High quality routed inference")
            ]
        case .ollama:
            return [
                CloudModel(provider: .ollama, slug: "llama3.1:8b", displayName: "Llama 3.1 8B", notes: "Runs from your Ollama server"),
                CloudModel(provider: .ollama, slug: "qwen2.5-coder:7b", displayName: "Qwen 2.5 Coder 7B", notes: "Great coding default")
            ]
        case .huggingFace:
            return [
                CloudModel(provider: .huggingFace, slug: "Qwen/Qwen2.5-Coder-32B-Instruct", displayName: "Qwen 2.5 Coder 32B", notes: "Inference API model"),
                CloudModel(provider: .huggingFace, slug: "meta-llama/Llama-3.1-8B-Instruct", displayName: "Llama 3.1 8B", notes: "Good general purpose default")
            ]
        case .google:
            return [
                CloudModel(provider: .google, slug: "gemini-2.5-pro", displayName: "Gemini 2.5 Pro", notes: "Strong reasoning model"),
                CloudModel(provider: .google, slug: "gemini-2.5-flash", displayName: "Gemini 2.5 Flash", notes: "Fast lower-cost model")
            ]
        case .xai:
            return [
                CloudModel(provider: .xai, slug: "grok-beta", displayName: "Grok Beta", notes: "Latest xAI experimental model"),
                CloudModel(provider: .xai, slug: "grok-2", displayName: "Grok 2", notes: "High-performance xAI model")
            ]
        case .openRouter:
            return [
                CloudModel(provider: .openRouter, slug: "openai/gpt-4.1-mini", displayName: "GPT-4.1 mini", notes: "OpenRouter routed model"),
                CloudModel(provider: .openRouter, slug: "anthropic/claude-3.7-sonnet", displayName: "Claude 3.7 Sonnet", notes: "Premium routed model")
            ]
        }
    }

    static func suggestedDefaultModel(for provider: ProviderKind) -> String {
        models(for: provider).first?.slug ?? ""
    }
}

struct WorkspaceRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var repoURL: String
    var syncStatus: String
    var lastSyncedAt: Date?
}

struct GenerationJob: Identifiable, Codable, Hashable {
    enum Status: String, Codable, CaseIterable {
        case queued
        case processing
        case completed
        case failed
    }

    var id: UUID = UUID()
    var description: String
    var templateName: String
    var target: String
    var modelSlug: String
    var status: Status
    var progress: Double
    var createdAt: Date = .now
}

struct SandboxSessionRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var workspaceName: String
    var status: String
    var connectURL: String
    var expiresAt: Date
}

struct BillingSnapshot: Codable, Hashable {
    var currentUsageUSD: Double
    var softLimitUSD: Double
    var activeSandboxes: Int
    var maxSandboxes: Int
    var planName: String

    static let demo = BillingSnapshot(currentUsageUSD: 42.5, softLimitUSD: 100, activeSandboxes: 3, maxSandboxes: 10, planName: "Pro")
}

struct AdminSnapshot: Codable, Hashable {
    var totalUsers: Int
    var activeSessions: Int
    var generationJobs: Int
    var systemHealth: String

    static let demo = AdminSnapshot(totalUsers: 1284, activeSessions: 84, generationJobs: 3492, systemHealth: "Healthy")
}

struct RuntimeSummary: Codable, Hashable {
    var mode: String
    var activeProvider: String
    var activeModel: String
    var notes: String

    static let stub = RuntimeSummary(
        mode: "Stub runtime",
        activeProvider: "None",
        activeModel: "None",
        notes: "Real on-device runtime still requires Mac/Xcode-side integration."
    )
}
