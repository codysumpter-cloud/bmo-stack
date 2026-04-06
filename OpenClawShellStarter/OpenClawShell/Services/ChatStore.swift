import Foundation

@MainActor
final class ChatStore: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var selectedFileIDs: Set<UUID> = []
    @Published var isGenerating = false
    @Published var errorMessage: String?

    func load() {
        guard let data = try? Data(contentsOf: Paths.chatStateFile) else {
            messages = [ChatMessage(role: .system, content: "OpenClawShell is ready. Plug in a real local inference backend next.")]
            return
        }
        messages = (try? JSONDecoder().decode([ChatMessage].self, from: data)) ?? []
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
        messages = [ChatMessage(role: .system, content: "Conversation cleared.")]
        persist()
    }
}
