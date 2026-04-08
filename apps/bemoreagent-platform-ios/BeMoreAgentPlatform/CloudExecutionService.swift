import Foundation

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

struct CloudExecutionResult: Hashable {
    var text: String
    var rawPreview: String
    var statusCode: Int
}

enum CloudExecutionServiceError: Error {
    case invalidBaseURL
    case invalidResponse
}

actor CloudExecutionService {
    func send(account: ProviderAccount, messages: [CloudExecutionMessage], temperature: Double? = nil, maxOutputTokens: Int? = nil) async throws -> CloudExecutionResult {
        var request = try makeRequest(account: account, messages: messages, temperature: temperature, maxOutputTokens: maxOutputTokens)
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        let preview = String(data: data.prefix(6000), encoding: .utf8) ?? ""
        return try parse(provider: account.provider, data: data, statusCode: statusCode, preview: preview)
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
            if !account.apiKey.isEmpty {
                request.setValue(account.apiKey, forHTTPHeaderField: "x-goog-api-key")
            }
        case .ollama:
            if normalizedBase.contains("ollama.com"), !account.apiKey.isEmpty {
                request.setValue("Bearer \(account.apiKey)", forHTTPHeaderField: "Authorization")
            }
        default:
            if !account.apiKey.isEmpty {
                request.setValue("Bearer \(account.apiKey)", forHTTPHeaderField: "Authorization")
            }
        }

        request.httpBody = try requestBody(provider: account.provider, model: account.modelSlug, messages: messages, temperature: temperature, maxOutputTokens: maxOutputTokens)
        return request
    }

    private func requestURL(provider: ProviderKind, baseURL: String, model: String) -> URL? {
        let root = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        switch provider {
        case .openRouter:
            return URL(string: root + "/chat/completions")
        case .nvidia:
            return URL(string: root + "/chat/completions")
        case .huggingFace:
            return URL(string: root + "/chat/completions")
        case .ollama:
            if root.hasSuffix("/api") {
                return URL(string: root + "/chat")
            }
            return URL(string: root + "/api/chat")
        case .google:
            return URL(string: root + "/v1beta/models/\(model):generateContent")
        }
    }

    private func requestBody(provider: ProviderKind, model: String, messages: [CloudExecutionMessage], temperature: Double?, maxOutputTokens: Int?) throws -> Data {
        let json: Any
        switch provider {
        case .google:
            let contents = messages.map { message in
                [
                    "role": message.role == .assistant ? "model" : message.role.rawValue,
                    "parts": [["text": message.content]]
                ]
            }
            var body: [String: Any] = [
                "contents": contents
            ]
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

    private func parse(provider: ProviderKind, data: Data, statusCode: Int, preview: String) throws -> CloudExecutionResult {
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

        guard let text, !text.isEmpty else {
            throw CloudExecutionServiceError.invalidResponse
        }

        return CloudExecutionResult(text: text, rawPreview: preview, statusCode: statusCode)
    }
}
