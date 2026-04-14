import SwiftUI

struct ChatTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var prompt = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let stack = appState.activeStack {
                    stackBanner(stack)
                }

                if !appState.workspaceStore.files.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(appState.workspaceStore.files) { file in
                                let isSelected = appState.chatStore.selectedFileIDs.contains(file.id)
                                Button {
                                    if isSelected {
                                        appState.chatStore.selectedFileIDs.remove(file.id)
                                    } else {
                                        appState.chatStore.selectedFileIDs.insert(file.id)
                                    }
                                } label: {
                                    Label(file.filename, systemImage: isSelected ? "checkmark.circle.fill" : "doc")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                }

                List(appState.chatStore.messages) { message in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(message.role.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(message.content)
                            .textSelection(.enabled)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)

                composer
            }
            .navigationTitle("Chat")
            .onAppear {
                if let queued = appState.consumePendingPrompt() {
                    prompt = queued
                }
            }
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

    private var composer: some View {
        VStack(spacing: 12) {
            if appState.usesStubRuntime || appState.selectedInstalledModel == nil {
                ContentUnavailableView(
                    "Runtime needs attention",
                    systemImage: appState.usesStubRuntime ? "cpu" : "exclamationmark.triangle",
                    description: Text(appState.operatorSummary)
                )
                .frame(maxWidth: .infinity)
            }

            HStack {
                TextField(appState.activeStack?.chatInputPlaceholder ?? fallbackPlaceholder, text: $prompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)

                Button {
                    let value = prompt
                    prompt = ""
                    Task { await appState.send(prompt: value) }
                } label: {
                    if appState.chatStore.isGenerating {
                        ProgressView()
                    } else {
                        Text("Send")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(appState.chatStore.isGenerating || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (!appState.usesStubRuntime && appState.selectedInstalledModel == nil))
            }

            HStack {
                Text(appState.runtimeStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !appState.chatStore.selectedFileIDs.isEmpty {
                    Text("• \(appState.chatStore.selectedFileIDs.count) file context")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Clear") {
                    appState.clearConversation()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    private func stackBanner(_ stack: CompiledStack) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(stack.name)
                .font(.headline)
            Text(stack.primaryOutcome)
                .font(.subheadline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(stack.starterPrompts.prefix(3), id: \.self) { starter in
                        Button(starter) {
                            prompt = starter
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
    }

    private var fallbackPlaceholder: String {
        appState.usesStubRuntime ? "Try the shell UI (stub runtime active)" : "Ask your local model"
    }
}
