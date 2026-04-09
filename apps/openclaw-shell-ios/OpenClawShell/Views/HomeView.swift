import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isSettingsPresented = false
    @State private var isHomeFileImporterPresented = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BMOTheme.spacingMD) {
                    headerSection
                    primaryAgentCard
                    statusCardsRow
                    quickActionsSection
                    runtimeStatusCard
                }
                .padding(.horizontal, BMOTheme.spacingMD)
                .padding(.bottom, BMOTheme.spacingXL)
            }
            .background(BMOTheme.backgroundPrimary)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("BeMoreAgent")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isSettingsPresented = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(BMOTheme.textSecondary)
                    }
                }
            }
            .toolbarBackground(BMOTheme.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .fileImporter(
                isPresented: $isHomeFileImporterPresented,
                allowedContentTypes: [.data, .plainText, .json, .sourceCode, .xml, .commaSeparatedText, .text],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    appState.workspaceStore.importFiles(from: urls)
                case .failure(let error):
                    appState.workspaceStore.errorMessage = error.localizedDescription
                }
            }
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView()
                    .environmentObject(appState)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.stackConfig.stackName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(BMOTheme.textPrimary)
                    StatusBadge(
                        label: appState.gemmaDownloadState == .installed ? "Active" : "Setup Required",
                        color: appState.gemmaDownloadState == .installed ? BMOTheme.success : BMOTheme.warning
                    )
                }
                Spacer()
            }
        }
        .padding(.top, BMOTheme.spacingSM)
    }

    private var primaryAgentCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(BMOTheme.accent.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: "cpu")
                        .font(.title2)
                        .foregroundColor(BMOTheme.accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("BMO Agent")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                    Text("Primary Agent")
                        .font(.caption)
                        .foregroundColor(BMOTheme.textTertiary)
                }

                Spacer()

                StatusBadge(
                    label: agentStatus,
                    color: agentStatusColor
                )
            }

            HStack(spacing: BMOTheme.spacingSM) {
                infoChip(icon: "brain", label: appState.stackConfig.memoryEnabled ? "Memory on" : "Memory off")
                infoChip(icon: "gauge.open.with.lines.needle.33percent", label: "Autonomy \(appState.stackConfig.autonomyLevel)/5")
                infoChip(icon: "dial.low", label: appState.stackConfig.optimizationMode.capitalized)
            }

            if appState.gemmaDownloadState != .installed {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(BMOTheme.warning)
                    Text("Model not installed. Go to Models to set up.")
                        .font(.caption)
                        .foregroundColor(BMOTheme.warning)
                }
            }
        }
        .bmoCard()
    }

    private var statusCardsRow: some View {
        HStack(spacing: 12) {
            statusCard(icon: "message", count: "\(appState.chatStore.messages.count)", label: "Messages")
            statusCard(icon: "folder", count: "\(appState.workspaceStore.files.count)", label: "Files")
            statusCard(icon: "square.and.arrow.down", count: "\(appState.modelStore.installedModels.count)", label: "Models")
        }
    }

    private func statusCard(icon: String, count: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(BMOTheme.accent)
            Text(count)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(BMOTheme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundColor(BMOTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .bmoCard()
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(BMOTheme.textSecondary)

            HStack(spacing: 12) {
                quickAction(icon: "message", label: "New Chat") {
                    appState.chatStore.clear()
                }
                quickAction(icon: "folder.badge.plus", label: "Import File") {
                    isHomeFileImporterPresented = true
                }
                quickAction(icon: "arrow.clockwise", label: "Refresh") {
                    appState.modelStore.refreshInstalledModels()
                    appState.workspaceStore.load()
                    appState.refreshGemmaState()
                }
            }
        }
    }

    private func quickAction(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(BMOTheme.accent)
                Text(label)
                    .font(.caption)
                    .foregroundColor(BMOTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(BMOTheme.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusMedium, style: .continuous))
        }
    }

    private var runtimeStatusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Runtime")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(BMOTheme.textSecondary)
                Spacer()
                Text(appState.backendDisplayName)
                    .font(.caption)
                    .foregroundColor(BMOTheme.textTertiary)
            }

            HStack(spacing: 8) {
                Circle()
                    .fill(runtimeStatusColor)
                    .frame(width: 8, height: 8)
                Text(appState.runtimeStatus)
                    .font(.subheadline)
                    .foregroundColor(BMOTheme.textPrimary)
            }

            if appState.usesStubRuntime {
                Text("This build is still using the stub local runtime. Use Models to link a cloud route for real chat today, or install a local model in preparation for the real on-device bridge.")
                    .font(.caption)
                    .foregroundColor(BMOTheme.textTertiary)
            }

            Text("Cloud providers can be linked in Settings and switched day-to-day in Models. Settings handles credentials; Models is the live route control surface.")
                .font(.caption)
                .foregroundColor(BMOTheme.textTertiary)
        }
        .bmoCard()
    }

    private var agentStatus: String {
        if appState.gemmaDownloadState == .installed && !appState.usesStubRuntime {
            return "Running"
        } else if appState.gemmaDownloadState == .installed {
            return "Model Ready"
        } else {
            return "Setup Needed"
        }
    }

    private var agentStatusColor: Color {
        if appState.gemmaDownloadState == .installed && !appState.usesStubRuntime {
            return BMOTheme.success
        } else if appState.gemmaDownloadState == .installed {
            return BMOTheme.accent
        } else {
            return BMOTheme.warning
        }
    }

    private var runtimeStatusColor: Color {
        switch appState.runtimeStatus {
        case _ where appState.runtimeStatus.localizedCaseInsensitiveContains("error"):
            return BMOTheme.error
        case _ where appState.runtimeStatus.localizedCaseInsensitiveContains("selected"):
            return BMOTheme.success
        default:
            return BMOTheme.warning
        }
    }

    private func infoChip(icon: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(label)
                .font(.system(size: 11))
        }
        .foregroundColor(BMOTheme.textTertiary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(BMOTheme.backgroundSecondary)
        .clipShape(Capsule())
    }
}
