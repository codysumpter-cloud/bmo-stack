import Foundation

protocol LocalLLMEngine {
    func bootstrap() async throws
    func installedModelIDs() async -> [String]
    func loadModel(at localURL: URL) async throws
    func generate(prompt: String, fileContexts: [WorkspaceFile], chatHistory: [ChatMessage]) async throws -> String
}
