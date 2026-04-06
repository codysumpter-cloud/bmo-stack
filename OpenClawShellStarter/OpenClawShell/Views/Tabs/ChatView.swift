import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var appState: AppState
    @State private var prompt = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !appState.workspaceStore.files.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(appState.workspaceStore.files) { file in
                                let selected = appState.chatStore.selectedFileIDs.contains(file.id)
                                Button {
                                    if selected {
                                        appState.chatStore.selectedFileIDs.remove(file.id)
                                    } else {
                                        appState.chatStore.selectedFileIDs.insert(file.id)
                                    }
                                } label: {
                                    Label(file.filename, systemImage: selected ? "checkmark.circle.fill" : "doc")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }

                ScrollViewReader { proxy in
                    List(appState.chatStore.messages) { message in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(message.role.rawValue.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(message.content)
                                .textSelection(.enabled)
                        }
                        .padding(.vertical, 4)
                        .id(message.id)
                    }
                    .listStyle(.plain)
                    .onChange(of: appState.chatStore.messages.count) { _, _ in
                        if let last = appState.chatStore.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }

                Divider()

                VStack(spacing: 12) {
                    TextField("Ask your local assistant…", text: $prompt, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...6)

                    HStack {
                        Button("Clear") {
                            appState.chatStore.clear()
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Button(appState.chatStore.isGenerating ? "Working…" : "Send") {
                            let value = prompt
                            prompt = ""
                            Task {
                                await appState.send(prompt: value)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(appState.chatStore.isGenerating || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding()
            }
            .navigationTitle("Chat")
            .alert("Chat error", isPresented: Binding(get: {
                appState.chatStore.errorMessage != nil
            }, set: { _ in
                appState.chatStore.errorMessage = nil
            })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(appState.chatStore.errorMessage ?? "Unknown error")
            }
        }
    }
}
