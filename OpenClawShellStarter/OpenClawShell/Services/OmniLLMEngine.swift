import Foundation

final class OmniLLMEngine: LocalLLMEngine {
    private let baseURL: URL
    private let authToken: String?
    private let useLocal: Bool
    
    init(baseURL: String = "https://app.prismtek.dev", authToken: String? = nil, useLocal: Bool = false) {
        // Remove trailing slash if present
        let cleanBase = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.baseURL = URL(string: "\(cleanBase)/api/omni")!
        self.authToken = authToken
        self.useLocal = useLocal
    }
    
    func bootstrap() async throws {
        // Health check to ensure API is reachable
        let healthURL = baseURL.appendingPathComponent("health")
        var request = URLRequest(url: healthURL)
        request.httpMethod = "GET"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "OmniLLMEngine", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "OmniAPI health check failed"])
        }
    }
    
    func installedModelIDs() async -> [String> {
        // Return available models from OmniAPI
        let modelsURL = baseURL.appendingPathComponent("models")
        var request = URLRequest(url: modelsURL)
        request.httpMethod = "GET"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return ["unknown"]
            }
            
            // Parse response to extract model IDs
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]] {
                return models.compactMap { $0["id"] as? String }
            }
            
            return ["default"]
        } catch {
            return ["error"]
        }
    }
    
    func loadModel(at localURL: URL) async throws {
        // For OmniAPI, model loading is handled by the backend
        // This is a no-op for the API-based engine
    }
    
    func generate(prompt: String, fileContexts: [WorkspaceFile], chatHistory: [ChatMessage]) async throws -> String {
        let completionsURL = baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: completionsURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Prepare messages array
        var messages: [[String: Any]] = []
        
        // Add chat history
        for message in chatHistory {
            messages.append([
                "role": message.role.rawValue,
                "content": message.content
            ])
        }
        
        // Add current prompt
        messages.append([
            "role": "user",
            "content": prompt
        ])
        
        // Prepare request body
        let body: [String: Any] = [
            "messages": messages,
            "stream": false
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "OmniLLMEngine", code: -2,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid response from OmniAPI"])
        }
        
        if httpResponse.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "OmniLLMEngine", code: httpResponse.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: "OmniAPI error: \(errorMsg)"])
        }
        
        // Parse response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let dataField = json["data"] as? [String: Any],
           let content = dataField["content"] as? String {
            return content
        } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = json["content"] as? String {
            return content
        } else {
            // Fallback: return raw JSON as string for debugging
            return String(data: data, encoding: .utf8) ?? "Empty response from OmniAPI"
        }
    }
}