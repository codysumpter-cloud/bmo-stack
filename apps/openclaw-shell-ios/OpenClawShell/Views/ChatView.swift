import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var store: BuddyProfileStore
    @State private var prompt = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                buddyChatHeader

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(appState.chatStore.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            ForEach(chatScopedActions) { action in
                                ActionRecordCard(action: action)
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

                if !appState.workspaceStore.files.isEmpty {
                    fileChipsBar
                }

                inputBar
            }
            .background(BMOTheme.backgroundPrimary)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(store.activeBuddy?.displayName ?? "Buddy Chat")
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
            .onAppear {
                appState.workspaceRuntime.refreshMetadata()
                store.load(for: appState.stackConfig)
            }
        }
    }

    private var buddyChatHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            BuddyAsciiView(buddy: store.activeBuddy, template: store.activeBuddy.flatMap { store.contracts?.templateForInstance($0) }, mood: buddyMood, compact: true)
                .frame(width: 126)
            VStack(alignment: .leading, spacing: 4) {
                Text("Chatting with \(store.activeBuddy?.displayName ?? "your Buddy")")
                    .font(.headline)
                    .foregroundColor(BMOTheme.textPrimary)
                Text(buddyChatSubtitle)
                    .font(.caption)
                    .foregroundColor(BMOTheme.textSecondary)
                    .lineLimit(2)
            }
            Spacer()
            Button("Switch") {
                appState.selectedTab = .buddy
            }
            .buttonStyle(BMOButtonStyle(isPrimary: false))
        }
        .padding(BMOTheme.spacingMD)
        .background(BMOTheme.backgroundSecondary)
    }

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

    private var inputBar: some View {
        VStack(spacing: 8) {
            if appState.selectedProviderAccount != nil || appState.selectedInstalledModel != nil || appState.usesStubRuntime {
                HStack(spacing: 6) {
                    Image(systemName: appState.selectedProviderAccount != nil ? "link.circle.fill" : appState.usesStubRuntime ? "exclamationmark.triangle.fill" : "cpu")
                        .font(.caption)
                    Text(statusLine)
                        .font(.caption)
                }
                .foregroundColor(appState.selectedProviderAccount != nil || appState.selectedInstalledModel != nil ? BMOTheme.textSecondary : BMOTheme.warning)
                .padding(.horizontal, BMOTheme.spacingMD)
            }

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Message \(store.activeBuddy?.displayName ?? "your Buddy")...", text: $prompt, axis: .vertical)
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
        (appState.selectedProviderAccount != nil || (appState.selectedInstalledModel != nil && !appState.usesStubRuntime))
    }

    private var chatScopedActions: [OpenClawActionRecord] {
        appState.workspaceRuntime.recentActions
            .filter { $0.source == "chat" || $0.source == "assistant" }
            .prefix(3)
            .map { $0 }
    }

    private var statusLine: String {
        if let account = appState.selectedProviderAccount {
            return "\(store.activeBuddy?.displayName ?? "Buddy") via \(account.provider.displayName) • \(account.modelSlug)"
        }
        if let model = appState.selectedInstalledModel {
            return appState.usesStubRuntime ? "Local model selected, runtime not included in this build" : "\(store.activeBuddy?.displayName ?? "Buddy") on-device • \(model.displayName)"
        }
        return "Route not configured. Link a cloud provider to chat in this build."
    }

    private var buddyChatSubtitle: String {
        guard let buddy = store.activeBuddy else {
            return "Create a Buddy so chat has a real companion identity."
        }
        return "\(buddy.identity.role) • \(buddy.state.currentFocus ?? "ready for the next useful step")"
    }

    private var buddyMood: BuddyAnimationMood {
        guard let buddy = store.activeBuddy else { return .thinking }
        switch buddy.state.mood.lowercased() {
        case "happy", "excited":
            return .happy
        case "working":
            return .working
        case "thinking":
            return .thinking
        case "sleepy", "tired":
            return .sleepy
        case "needsattention", "needs attention", "stressed":
            return .needsAttention
        default:
            return appState.chatStore.isGenerating ? .thinking : .idle
        }
    }
}

private struct ActionRecordCard: View {
    let action: OpenClawActionRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(action.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(BMOTheme.textPrimary)
                    Spacer()
                    StatusBadge(label: action.status.label, color: action.status.color)
                }
                Text(action.output["summary"] ?? action.error ?? action.kind.rawValue)
                    .font(.caption)
                    .foregroundColor(BMOTheme.textSecondary)
                if !action.artifacts.isEmpty {
                    Text(action.artifacts.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(BMOTheme.accent)
                }
            }
            Spacer(minLength: 32)
        }
        .bmoCard()
    }
}

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
