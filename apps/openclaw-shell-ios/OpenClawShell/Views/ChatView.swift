import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var appState: AppState
    @State private var prompt = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(appState.chatStore.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            if appState.chatStore.isGenerating {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .tint(BMOTheme.accent)
                                    Text("Thinking...")
                                        .font(.subheadline)
                                        .foregroundColor(BMOTheme.textTertiary)
                                    Spacer()
                                }
                                .padding(.horizontal, BMOTheme.spacingMD)
                                .padding(.vertical, BMOTheme.spacingSM)
                            }
                        }
                        .padding(.horizontal, BMOTheme.spacingMD)
                        .padding(.top, BMOTheme.spacingSM)
                        .padding(.bottom, BMOTheme.spacingMD)
                    }
                    .onChange(of: appState.chatStore.messages.count) { _, _ in
                        if let last = appState.chatStore.messages.last {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()
                    .overlay(BMOTheme.divider)

                // File context chips
                if !appState.workspaceStore.files.isEmpty {
                    fileChipsBar
                }

                // Input bar
                inputBar
            }
            .background(BMOTheme.backgroundPrimary)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Chat")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        appState.chatStore.clear()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(BMOTheme.textSecondary)
                    }
                }
            }
            .toolbarBackground(BMOTheme.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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

    // MARK: - File chips

    private var fileChipsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(appState.workspaceStore.files) { file in
                    let isSelected = appState.chatStore.selectedFileIDs.contains(file.id)
                    Button {
                        if isSelected {
                            appState.chatStore.selectedFileIDs.remove(file.id)
                        } else {
                            appState.chatStore.selectedFileIDs.insert(file.id)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "doc")
                                .font(.system(size: 12))
                            Text(file.filename)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundColor(isSelected ? BMOTheme.accent : BMOTheme.textTertiary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isSelected ? BMOTheme.accent.opacity(0.12) : BMOTheme.backgroundCard)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, BMOTheme.spacingMD)
            .padding(.vertical, BMOTheme.spacingSM)
        }
    }

    // MARK: - Input

    private var inputBar: some View {
        VStack(spacing: 8) {
            if appState.usesStubRuntime || appState.selectedInstalledModel == nil {
                HStack(spacing: 6) {
                    Image(systemName: appState.usesStubRuntime ? "info.circle" : "exclamationmark.triangle")
                        .font(.caption)
                    Text(appState.usesStubRuntime
                        ? "Stub runtime — responses are simulated"
                        : "No model selected")
                        .font(.caption)
                }
                .foregroundColor(BMOTheme.warning)
                .padding(.horizontal, BMOTheme.spacingMD)
            }

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Message your agent...", text: $prompt, axis: .vertical)
                    .focused($isInputFocused)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .foregroundColor(BMOTheme.textPrimary)
                    .lineLimit(1...5)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(BMOTheme.backgroundCard)
                    .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusMedium, style: .continuous))

                Button {
                    let value = prompt
                    prompt = ""
                    isInputFocused = false
                    Task { await appState.send(prompt: value) }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(canSend ? BMOTheme.accent : BMOTheme.textTertiary)
                }
                .disabled(!canSend)
            }
            .padding(.horizontal, BMOTheme.spacingMD)
            .padding(.vertical, BMOTheme.spacingSM)
        }
        .background(BMOTheme.backgroundSecondary)
    }

    private var canSend: Bool {
        !appState.chatStore.isGenerating &&
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (appState.usesStubRuntime || appState.selectedInstalledModel != nil)
    }
}

// MARK: - Message bubble

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 48) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if message.role == .system {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.caption2)
                        Text(message.content)
                            .font(.caption)
                    }
                    .foregroundColor(BMOTheme.textTertiary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(BMOTheme.divider)
                    .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusSmall, style: .continuous))
                } else {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(message.role == .user ? BMOTheme.backgroundPrimary : BMOTheme.textPrimary)
                        .textSelection(.enabled)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            message.role == .user
                                ? BMOTheme.accent
                                : BMOTheme.backgroundCard
                        )
                        .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusMedium, style: .continuous))
                }

                Text(message.createdAt, style: .time)
                    .font(.system(size: 10))
                    .foregroundColor(BMOTheme.textTertiary)
            }

            if message.role != .user { Spacer(minLength: 48) }
        }
    }
}
