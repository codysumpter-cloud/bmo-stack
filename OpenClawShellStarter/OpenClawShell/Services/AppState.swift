import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var modelStore = ModelStore()
    @Published var workspaceStore = WorkspaceStore()
    @Published var chatStore = ChatStore()

    private let engine: LocalLLMEngine

    init(engine: LocalLLMEngine) {
        self.engine = engine
    }

    func bootstrap() async {
        modelStore.load()
        workspaceStore.load()
        chatStore.load()
        do {
            try await engine.bootstrap()
        } catch {
            chatStore.errorMessage = error.localizedDescription
        }
    }

    func send(prompt: String) async {
        let cleaned = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        chatStore.messages.append(ChatMessage(role: .user, content: cleaned))
        chatStore.persist()
        chatStore.isGenerating = true

        let attachedFiles = workspaceStore.files.filter { chatStore.selectedFileIDs.contains($0.id) }

        do {
            let reply = try await engine.generate(prompt: cleaned, fileContexts: attachedFiles, chatHistory: chatStore.messages)
            chatStore.messages.append(ChatMessage(role: .assistant, content: reply))
            chatStore.persist()
        } catch {
            chatStore.errorMessage = error.localizedDescription
        }

        chatStore.isGenerating = false
    }
}
