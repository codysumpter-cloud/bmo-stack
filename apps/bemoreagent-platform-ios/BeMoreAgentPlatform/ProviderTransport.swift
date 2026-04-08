import Foundation

struct ProviderTransport {
    static func normalizeBaseURL(for provider: ProviderKind, rawValue: String) -> String {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            switch provider {
            case .openRouter:
                return "https://openrouter.ai/api/v1"
            case .google:
                return "https://generativelanguage.googleapis.com"
            case .nvidia:
                return "https://integrate.api.nvidia.com/v1"
            case .huggingFace:
                return "https://router.huggingface.co/v1"
            case .ollama:
                return "http://localhost:11434"
            }
        }

        if provider == .huggingFace, trimmed.contains("api-inference.huggingface.co") {
            return "https://router.huggingface.co/v1"
        }

        return trimmed
    }
}
