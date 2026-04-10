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
                    stackProfileCard
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
                        label: shellStatusLabel,
                        color: shellStatusColor
                    )
                }
                Spacer()
            }
        }
        .padding(.top, BMOTheme.spacingSM)
    }

    private var stackProfileCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(BMOTheme.accent.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: "server.rack")
                        .font(.title2)
                        .foregroundColor(BMOTheme.accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(appState.stackConfig.deploymentMode == .bootstrapSelfHosted ? "Self-hosted OpenClaw stack" : "Runtime pairing shell")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                    Text(appState.operatorDisplayName)
                        .font(.caption)
                        .foregroundColor(BMOTheme.textTertiary)
                }

                Spacer()

                StatusBadge(
                    label: appState.activeRouteModeLabel,
                    color: appState.selectedProviderAccount != nil ? BMOTheme.success : (appState.selectedInstalledModel != nil ? BMOTheme.accent : BMOTheme.warning)
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                infoLine(title: "Runtime", value: appState.stackConfig.gatewayURL)
                infoLine(title: "Goal", value: appState.stackConfig.goal)
                infoLine(title: "Role", value: appState.stackConfig.role)
            }

            HStack(spacing: BMOTheme.spacingSM) {
                infoChip(icon: "brain", label: appState.stackConfig.memoryEnabled ? "Memory on" : "Memory off")
                infoChip(icon: "app.badge", label: appState.stackConfig.enableNotifications ? "Notifications on" : "Notifications off")
                infoChip(icon: "dial.low", label: appState.stackConfig.optimizationMode.capitalized)
            }
        }
        .bmoCard()
    }

    private var statusCardsRow: some View {
        HStack(spacing: 12) {
            statusCard(icon: "message", count: "\(appState.chatStore.messages.count)", label: "Messages")
            statusCard(icon: "folder", count: "\(appState.workspaceStore.files.count)", label: "Files")
            statusCard(icon: "checklist", count: "\(appState.stackConfig.setupChecklist.count)", label: "Checklist")
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
                    appState.refreshRuntimeSummary()
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
                Text("Shell readiness")
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

            Text(appState.operatorSummary)
                .font(.caption)
                .foregroundColor(BMOTheme.textSecondary)

            if appState.usesStubRuntime {
                Text("This build is still using the stub local runtime. The shell now says that plainly. Use Models to link a cloud route for real chat today, or install a local model in preparation for the real on-device bridge.")
                    .font(.caption)
                    .foregroundColor(BMOTheme.warning)
            }

            Text("Cloud providers can be linked in Settings and switched day-to-day in Models. Settings handles credentials; Models is the live route control surface.")
                .font(.caption)
                .foregroundColor(BMOTheme.textTertiary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Setup checklist")
                    .font(.caption)
                    .foregroundColor(BMOTheme.textTertiary)
                ForEach(appState.stackConfig.setupChecklist.prefix(3), id: \.self) { item in
                    Text("• \(item)")
                        .font(.caption)
                        .foregroundColor(BMOTheme.textSecondary)
                }
            }
        }
        .bmoCard()
    }

    private var shellStatusLabel: String {
        if appState.selectedProviderAccount != nil || appState.canUseSelectedLocalModel {
            return "Live Route"
        }
        return appState.stackConfig.isOnboardingComplete ? "Profile Ready" : "Setup Required"
    }

    private var shellStatusColor: Color {
        if appState.selectedProviderAccount != nil || appState.canUseSelectedLocalModel {
            return BMOTheme.success
        }
        return appState.stackConfig.isOnboardingComplete ? BMOTheme.accent : BMOTheme.warning
    }

    private var runtimeStatusColor: Color {
        switch appState.runtimeStatus {
        case _ where appState.runtimeStatus.localizedCaseInsensitiveContains("error"):
            return BMOTheme.error
        case _ where appState.runtimeStatus.localizedCaseInsensitiveContains("cloud") || appState.runtimeStatus.localizedCaseInsensitiveContains("selected"):
            return BMOTheme.success
        case _ where appState.runtimeStatus.localizedCaseInsensitiveContains("profiled"):
            return BMOTheme.accent
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

    private func infoLine(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.caption)
                .foregroundColor(BMOTheme.textTertiary)
            Spacer()
            Text(value)
                .font(.caption)
                .multilineTextAlignment(.trailing)
                .foregroundColor(BMOTheme.textPrimary)
        }
    }
}
