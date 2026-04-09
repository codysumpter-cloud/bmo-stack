import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var editingProvider: ProviderKind?

    var body: some View {
        NavigationStack {
            List {
                Section("Agent Setup") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(appState.stackConfig.stackName)
                            .font(.headline)
                            .foregroundColor(BMOTheme.textPrimary)
                        Text(appState.stackConfig.goal.isEmpty ? "No goal configured yet" : appState.stackConfig.goal)
                            .font(.caption)
                            .foregroundColor(BMOTheme.textSecondary)
                    }
                    .listRowBackground(BMOTheme.backgroundCard)

                    Button("Reconfigure Agent") {
                        appState.resetOnboardingAndReturnToSetup()
                        dismiss()
                    }
                    .foregroundColor(BMOTheme.accent)
                    .listRowBackground(BMOTheme.backgroundCard)
                }

                Section("Chat Runtime") {
                    settingsRow(title: "Backend", value: appState.backendDisplayName)
                    settingsRow(title: "Status", value: appState.runtimeStatus)
                    settingsRow(title: "Active route", value: activeRouteLabel)
                }

                Section("Linked Accounts") {
                    Text("Link your own NVIDIA, Google AI Studio, OpenAI, Hugging Face, or Ollama endpoint, then pick which one chat should use.")
                        .font(.caption)
                        .foregroundColor(BMOTheme.textSecondary)
                        .listRowBackground(BMOTheme.backgroundCard)

                    ForEach(ProviderKind.allCases) { provider in
                        providerRow(provider)
                    }
                }

                Section("Storage") {
                    settingsRow(title: "Files", value: "\(appState.workspaceStore.files.count)")
                    settingsRow(title: "Messages", value: "\(appState.chatStore.messages.count)")
                    settingsRow(title: "Installed models", value: "\(appState.modelStore.installedModels.count)")
                }
            }
            .scrollContentBackground(.hidden)
            .background(BMOTheme.backgroundPrimary)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(BMOTheme.accent)
                }
            }
            .sheet(item: $editingProvider) { provider in
                ProviderEditorSheet(provider: provider)
                    .environmentObject(appState)
            }
            .alert("Provider error", isPresented: Binding(get: {
                appState.providerStore.lastError != nil
            }, set: { _ in
                appState.providerStore.lastError = nil
            })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(appState.providerStore.lastError ?? "Unknown error")
            }
        }
        .preferredColorScheme(.dark)
    }

    private var activeRouteLabel: String {
        if let account = appState.selectedProviderAccount {
            return "\(account.provider.displayName) • \(account.modelSlug)"
        }
        if let model = appState.selectedInstalledModel {
            return model.displayName
        }
        return "None"
    }

    private func providerRow(_ provider: ProviderKind) -> some View {
        let account = appState.providerStore.account(for: provider)
        let isActive = appState.runtimePreferences.selection.selectedProvider == provider
        let models = appState.availableModels(for: provider)
        let isLoadingModels = appState.providerModelLoading.contains(provider)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(provider.displayName)
                        .foregroundColor(BMOTheme.textPrimary)
                    Text(account.isEnabled ? account.modelSlug : provider.accountHint)
                        .font(.caption)
                        .foregroundColor(BMOTheme.textSecondary)
                }
                Spacer()
                Text(account.isEnabled ? (isActive ? "Active" : "Connected") : "Not linked")
                    .font(.caption)
                    .foregroundColor(account.isEnabled ? BMOTheme.accent : BMOTheme.warning)
            }

            if account.isEnabled {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Model")
                            .foregroundColor(BMOTheme.textSecondary)
                        Spacer()
                        if isLoadingModels {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Button {
                            Task { await appState.refreshProviderModels(for: provider, force: true) }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.borderless)
                    }

                    Picker("Model", selection: Binding(
                        get: { appState.providerStore.account(for: provider).modelSlug },
                        set: { appState.updateProviderModel(provider, modelSlug: $0) }
                    )) {
                        ForEach(models) { model in
                            Text(model.displayName).tag(model.slug)
                        }
                    }
                    .pickerStyle(.menu)

                    if let error = appState.providerModelErrors[provider], !error.isEmpty {
                        Text("Using fallback list, live fetch failed.")
                            .font(.caption2)
                            .foregroundColor(BMOTheme.warning)
                    }
                }
            }

            HStack {
                Button("Edit") { editingProvider = provider }
                    .buttonStyle(.bordered)
                if account.isEnabled {
                    Button("Test") {
                        Task { await appState.verifyProviderConnection(provider) }
                    }
                    .buttonStyle(.bordered)

                    Button(isActive ? "Using now" : "Use for chat") {
                        appState.setSelectedProvider(provider)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isActive)
                }
            }
        }
        .listRowBackground(BMOTheme.backgroundCard)
        .task(id: account.isEnabled) {
            guard account.isEnabled else { return }
            await appState.refreshProviderModels(for: provider)
        }
    }

    private func settingsRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(BMOTheme.textSecondary)
            Spacer()
            Text(value)
                .foregroundColor(BMOTheme.textPrimary)
        }
        .listRowBackground(BMOTheme.backgroundCard)
    }
}

private struct ProviderEditorSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let provider: ProviderKind
    @State private var account: ProviderAccount

    init(provider: ProviderKind) {
        self.provider = provider
        _account = State(initialValue: .blank(for: provider))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Connection") {
                    TextField("Label", text: $account.label)
                    if provider != .ollama {
                        SecureField(provider.accountHint, text: $account.apiKey)
                    } else {
                        SecureField("Bearer token, optional", text: $account.apiKey)
                    }
                    TextField("Base URL", text: $account.baseURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Model", text: $account.modelSlug)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                if account.isEnabled || !appState.availableModels(for: provider).isEmpty {
                    Section("Available models") {
                        if appState.providerModelLoading.contains(provider) {
                            ProgressView("Loading models…")
                        }

                        Picker("Available models", selection: $account.modelSlug) {
                            ForEach(appState.availableModels(for: provider)) { model in
                                Text(model.displayName).tag(model.slug)
                            }
                        }

                        Button("Refresh model list") {
                            Task { await appState.refreshProviderModels(for: provider, force: true) }
                        }
                    }
                }

                if provider == .openAI {
                    Section("Note") {
                        Text("This build supports OpenAI API-key chat now. Full ChatGPT OAuth needs a proper OAuth client flow and callback handling, so that part is not wired yet.")
                            .font(.caption)
                            .foregroundColor(BMOTheme.textSecondary)
                    }
                }
            }
            .onAppear {
                account = appState.providerStore.account(for: provider)
                if account.isEnabled {
                    Task { await appState.refreshProviderModels(for: provider) }
                }
            }
            .navigationTitle(provider.displayName)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        appState.providerStore.upsert(account)
                        appState.providerStore.validate(provider)
                        if appState.providerStore.account(for: provider).isEnabled {
                            appState.setSelectedProvider(provider)
                            Task { await appState.refreshProviderModels(for: provider, force: true) }
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}
