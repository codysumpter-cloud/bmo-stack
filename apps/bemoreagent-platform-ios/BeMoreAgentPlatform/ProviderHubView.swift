import SwiftUI

struct ProviderHubView: View {
    @EnvironmentObject private var appState: PlatformAppState
    @State private var editingProvider: ProviderKind?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(ProviderKind.allCases) { provider in
                        let account = appState.providerStore.account(for: provider)
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(provider.displayName)
                                    .font(.headline)
                                    .foregroundColor(PlatformTheme.textPrimary)
                                Spacer()
                                PillBadge(text: account.isEnabled ? "Connected" : "Not Connected", color: account.isEnabled ? PlatformTheme.success : PlatformTheme.warning)
                            }
                            Text(account.baseURL)
                                .font(.caption)
                                .foregroundColor(PlatformTheme.textSecondary)
                            if !account.modelSlug.isEmpty {
                                Text("Default model: \(account.modelSlug)")
                                    .font(.caption)
                                    .foregroundColor(PlatformTheme.textTertiary)
                            }
                            HStack {
                                Button("Edit") { editingProvider = provider }
                                    .buttonStyle(.borderedProminent)
                                if account.isEnabled {
                                    Button("Use Model") {
                                        appState.useCloudModel(from: provider, modelSlug: account.modelSlug)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                        .platformCard()
                    }
                }
                .padding(16)
            }
            .background(PlatformTheme.background)
            .navigationTitle("Providers")
            .sheet(item: $editingProvider) { provider in
                ProviderEditorView(provider: provider)
                    .environmentObject(appState)
            }
        }
    }
}

private struct ProviderEditorView: View {
    @EnvironmentObject private var appState: PlatformAppState
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
                    TextField("Credential", text: $account.apiKey)
                    TextField("Base URL", text: $account.baseURL)
                    TextField("Default model", text: $account.modelSlug)
                }

                Section("Suggested models") {
                    ForEach(CloudModelCatalog.models(for: provider)) { model in
                        Button(model.displayName) {
                            account.modelSlug = model.slug
                        }
                    }
                }
            }
            .onAppear {
                account = appState.providerStore.account(for: provider)
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
                        appState.refreshRuntimeSummary()
                        dismiss()
                    }
                }
            }
        }
    }
}
