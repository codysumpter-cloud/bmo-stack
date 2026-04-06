import Foundation

final class StubLLMEngine: LocalLLMEngine {
    func bootstrap() async throws {}

    func installedModelIDs() async -> [String] { [] }

    func loadModel(at localURL: URL) async throws {}

    func generate(prompt: String, fileContexts: [WorkspaceFile], chatHistory: [ChatMessage]) async throws -> String {
        let filenames = fileContexts.map(\.filename).joined(separator: ", ")
        let historyCount = chatHistory.count
        return "Stub engine reply.\n\nPrompt: \(prompt)\n\nAttached files: \(filenames.isEmpty ? \"none\" : filenames)\nHistory messages: \(historyCount)\n\nReplace StubLLMEngine with your MLC or llama.cpp bridge to get real local inference."
    }
}
