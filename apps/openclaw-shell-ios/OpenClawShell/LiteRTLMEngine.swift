import Foundation
import LiteRTLM
import SwiftUI // for buildContextPrefix helper (already in project)

// MARK: – LiteRT‑LM engine -------------------------------------------------
/// Wrapper that conforms to the `LocalLLMEngine` protocol used by the app.
final class LiteRTLMEngine: LocalLLMEngine {
    // The model is loaded once and kept for the app lifetime.
    private var model: LLMModel?

    var backendDisplayName: String { "LiteRT‑LM (Gemma 4)" }
    // No external model selection needed – we load the bundled model.
    var requiresModelSelection: Bool { false }

    func bootstrap() async throws {
        // Nothing to do – the model will be loaded lazily in configureRuntime.
    }

    func configureRuntime(_ config: EngineRuntimeConfig?) async throws {
        // If a config is supplied we ignore it and just load the bundled model.
        // The bundled model lives in the app bundle under Resources/Models.
        guard let url = Bundle.main.url(forResource: "gemma-2b", withExtension: "tflite") else {
            throw NSError(domain: "LiteRTLMEngine", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Bundled Gemma model not found in bundle."])
        }
        // Options can be tuned – we use reasonable defaults.
        let options = LLMModel.Options(maxTokens: 1024, temperature: 0.8, topK: 40, topP: 0.9)
        model = try LLMModel(modelURL: url, options: options)
    }

    func generate(prompt: String, fileContexts: [WorkspaceFile], chatHistory: [ChatMessage]) async throws -> String {
        // Build the same context prefix the app normally uses.
        let context = buildContextPrefix(fileContexts: fileContexts, chatHistory: chatHistory)
        let fullPrompt = context + prompt
        guard let model = model else {
            throw NSError(domain: "LiteRTLMEngine", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Model not configured – call configureRuntime first."])
        }
        // LiteRT‑LM's generate API is async and returns the generated text.
        return try await model.generate(text: fullPrompt)
    }
}
