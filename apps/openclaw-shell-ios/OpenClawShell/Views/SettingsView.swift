import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

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

                Section("Runtime") {
                    settingsRow(title: "Backend", value: appState.backendDisplayName)
                    settingsRow(title: "Status", value: appState.runtimeStatus)
                    settingsRow(title: "Mode", value: appState.usesStubRuntime ? "Stub mode" : "Ready")
                }

                Section("Scope") {
                    Text("This shell is local-first. Cloud providers and remote-model workflows live in the BeMoreAgent Platform target.")
                        .font(.caption)
                        .foregroundColor(BMOTheme.textSecondary)
                        .listRowBackground(BMOTheme.backgroundCard)
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
        }
        .preferredColorScheme(.dark)
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
