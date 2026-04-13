import SwiftUI

struct HomeTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isPreviewPresented = false

    var body: some View {
        NavigationStack {
            Group {
                if let stack = appState.activeStack {
                    StackDashboardView(stack: stack, isPreviewPresented: $isPreviewPresented)
                } else {
                    StackOnboardingView()
                }
            }
            .navigationTitle(appState.activeStack == nil ? "Build Your Stack" : "Home")
            .toolbar {
                if appState.activeStack != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Preview") {
                            isPreviewPresented = true
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Edit Stack") {
                            appState.reopenStackOnboarding()
                        }
                    }
                }
            }
            .sheet(isPresented: $isPreviewPresented) {
                if let stack = appState.activeStack {
                    NavigationStack {
                        StackPreviewView(stack: stack)
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button("Done") {
                                        isPreviewPresented = false
                                    }
                                }
                            }
                    }
                }
            }
            .alert("Stack error", isPresented: Binding(get: {
                appState.stackStore.errorMessage != nil
            }, set: { _ in
                appState.stackStore.errorMessage = nil
            })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(appState.stackStore.errorMessage ?? "Unknown error")
            }
        }
    }
}

private struct StackOnboardingView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("Operator") {
                TextField("Your name", text: binding(\.operatorName))
                TextField("Stack name", text: binding(\.stackName))
            }

            Section("Target") {
                Picker("Focus", selection: binding(\.focus)) {
                    ForEach(StackBuilderFocus.allCases) { focus in
                        Text(focus.title).tag(focus)
                    }
                }

                Picker("Experience", selection: binding(\.experience)) {
                    ForEach(StackBuilderExperience.allCases) { experience in
                        Text(experience.title).tag(experience)
                    }
                }

                TextField("Primary outcome", text: binding(\.primaryOutcome), axis: .vertical)
                    .lineLimit(2...4)
            }

            Section("Foundation") {
                Toggle("Local model posture", isOn: binding(\.wantsLocalModels))
                Toggle("Persistent file workspace", isOn: binding(\.wantsFileWorkspace))
                Toggle("Operator dashboard emphasis", isOn: binding(\.wantsDashboard))
            }

            Section("Notes") {
                TextField("Constraints, rituals, or other stack notes", text: binding(\.notes), axis: .vertical)
                    .lineLimit(3...6)
            }

            Section {
                Button("Compile Stack") {
                    appState.compileStack()
                }
                .buttonStyle(.borderedProminent)

                Text("This creates a local-first stack definition, persists it on-device, and turns the native iPhone app into the source of truth for chat, files, and model posture.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<StackOnboardingDraft, Value>) -> Binding<Value> {
        Binding(
            get: { appState.stackStore.draft[keyPath: keyPath] },
            set: { appState.stackStore.draft[keyPath: keyPath] = $0 }
        )
    }
}

private struct StackDashboardView: View {
    @EnvironmentObject private var appState: AppState
    let stack: CompiledStack
    @Binding var isPreviewPresented: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                status
                cards
                prompts
                footer
            }
            .padding()
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(stack.name)
                .font(.largeTitle.bold())
            Text(stack.tagline)
                .font(.headline)
            Text(stack.summary)
                .foregroundStyle(.secondary)

            HStack {
                Label(stack.focus.title, systemImage: "square.stack")
                Label(stack.experience.title, systemImage: "dial.low")
                Label("\(stack.enabledSurfaces.count) surfaces", systemImage: "apps.iphone")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var status: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Foundation Status")
                .font(.title3.bold())

            LabeledContent("Runtime", value: appState.runtimeStatus)
            LabeledContent("Files", value: "\(appState.workspaceStore.files.count)")
            LabeledContent("Attached in chat", value: "\(appState.chatStore.selectedFileIDs.count)")
            LabeledContent("Installed models", value: "\(appState.modelStore.installedModels.count)")
            LabeledContent("Quick actions", value: "\(stack.quickActions.count)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var cards: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stack Surfaces")
                .font(.title3.bold())

            ForEach(stack.dashboardCards) { card in
                Button {
                    if card.destination == .preview {
                        isPreviewPresented = true
                    } else {
                        appState.route(to: mappedTab(for: card.destination))
                    }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: card.symbol)
                            .font(.title3)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(card.title)
                                .font(.headline)
                            Text(card.detail)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var prompts: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Starter Prompts")
                .font(.title3.bold())

            ForEach(stack.starterPrompts, id: \.self) { prompt in
                Button {
                    appState.openChat(with: prompt)
                } label: {
                    Text(prompt)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview")
                .font(.title3.bold())
            Text("Review the compiled stack plan before you expand the runtime integration. The phone app remains the source of truth for onboarding, preview, and local persistence.")
                .foregroundStyle(.secondary)

            HStack {
                Button("Open Preview") {
                    isPreviewPresented = true
                }
                .buttonStyle(.borderedProminent)

                Button("Reset Stack", role: .destructive) {
                    appState.resetStackBuilder()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func mappedTab(for surface: StackSurface) -> AppTab {
        switch surface {
        case .home:
            return .missionControl
        case .chat:
            return .chat
        case .files:
            return .files
        case .models:
            return .models
        case .editor:
            return .editor
        case .preview:
            return .missionControl
        }
    }
}

private struct StackPreviewView: View {
    let stack: CompiledStack

    var body: some View {
        List {
            Section("Compiled Stack") {
                Text(stack.summary)
                LabeledContent("Operator", value: stack.operatorName)
                LabeledContent("Updated", value: stack.updatedAt.formatted(date: .abbreviated, time: .shortened))
            }

            ForEach(stack.previewSections) { section in
                Section(section.title) {
                    ForEach(section.bullets, id: \.self) { bullet in
                        Text(bullet)
                    }
                }
            }
        }
        .navigationTitle("Stack Preview")
    }
}
