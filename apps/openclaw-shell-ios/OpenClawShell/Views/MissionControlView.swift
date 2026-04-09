import SwiftUI

struct MissionControlView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedSurface: RepoSurface?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BMOTheme.spacingMD) {
                    headerCard
                    stackContractCard
                    routeCard
                    metricsCard
                    providerCard
                    shellCard
                    stackSurfacesCard
                }
                .padding(.horizontal, BMOTheme.spacingMD)
                .padding(.bottom, BMOTheme.spacingXL)
            }
            .background(BMOTheme.backgroundPrimary)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Mission Control")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                }
            }
            .toolbarBackground(BMOTheme.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(item: $selectedSurface) { surface in
                RepoSurfaceDetailView(surface: surface)
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.operatorDisplayName)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(BMOTheme.textPrimary)
                    Text("OpenClaw mobile operator shell")
                        .font(.subheadline)
                        .foregroundColor(BMOTheme.textSecondary)
                }
                Spacer()
                StatusBadge(label: appState.activeRouteModeLabel, color: appState.selectedProviderAccount != nil ? BMOTheme.success : (appState.selectedInstalledModel != nil ? BMOTheme.accent : BMOTheme.warning))
            }

            Text(appState.operatorSummary)
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)
        }
        .bmoCard()
    }

    private var stackContractCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Stack contract")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(BMOTheme.textSecondary)

            detailRow("Mode", value: appState.stackConfig.deploymentMode.title)
            detailRow("Gateway", value: appState.stackConfig.gatewayURL)
            detailRow("Role", value: appState.stackConfig.role)
            detailRow("Goal", value: appState.stackConfig.goal)
            detailRow("Node on iPhone", value: appState.stackConfig.installNodeOnThisPhone ? "Expected" : "Not expected")
            detailRow("Desktop/server node", value: appState.stackConfig.installDesktopNode ? "Expected" : "Optional")
        }
        .bmoCard()
    }

    private var routeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Route control")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(BMOTheme.textSecondary)

            detailRow("Active route", value: appState.activeRouteTitle)
            detailRow("Target", value: appState.activeRouteDetail)
            detailRow("Health", value: appState.routeHealthSummary)
        }
        .bmoCard()
    }

    private var metricsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Live local state")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(BMOTheme.textSecondary)

            detailRow("Workspace", value: appState.workspaceStatusSummary)
            detailRow("Messages", value: "\(appState.chatStore.messages.count)")
            detailRow("Installed models", value: "\(appState.modelStore.installedModels.count)")
            detailRow("Persistence", value: appState.persistenceSummary)
        }
        .bmoCard()
    }

    private var providerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Providers")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(BMOTheme.textSecondary)

            ForEach(ProviderKind.allCases) { provider in
                let account = appState.providerStore.account(for: provider)
                detailRow(provider.displayName, value: account.isEnabled ? account.modelSlug : "Not linked")
            }
        }
        .bmoCard()
    }

    private var shellCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Shell tabs")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(BMOTheme.textSecondary)

            Text(appState.orderedVisibleTabs.map(\.title).joined(separator: " • "))
                .font(.subheadline)
                .foregroundColor(BMOTheme.textPrimary)
            Text("Manage tab order in Settings. Mission Control stays the stable landing surface for stack health and route truth.")
                .font(.caption)
                .foregroundColor(BMOTheme.textTertiary)
        }
        .bmoCard()
    }

    private var stackSurfacesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BMO Stack Surfaces")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(BMOTheme.textSecondary)

            Text("These briefs are bundled from real repo docs so the iOS shell can expose meaningful stack surfaces without pretending to reimplement the whole desktop operator stack.")
                .font(.caption)
                .foregroundColor(BMOTheme.textTertiary)

            ForEach(RepoSurface.allCases) { surface in
                Button {
                    selectedSurface = surface
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(surface.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(BMOTheme.textPrimary)
                            Text(surface.summary)
                                .font(.caption)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(BMOTheme.textSecondary)
                            Text(surface.sourcePath)
                                .font(.caption2)
                                .foregroundColor(BMOTheme.textTertiary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 8) {
                            StatusBadge(label: surface.statusLabel, color: surface.statusColor)
                            Text("Open brief")
                                .font(.caption2)
                                .foregroundColor(BMOTheme.accent)
                        }
                    }
                    .padding(12)
                    .background(BMOTheme.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusMedium, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .bmoCard()
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundColor(BMOTheme.textTertiary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundColor(BMOTheme.textPrimary)
        }
        .font(.caption)
    }
}
