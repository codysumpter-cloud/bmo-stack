import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appState: PlatformAppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BeMoreAgent Platform")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(PlatformTheme.textPrimary)
                        Text("Workspace sync, factory jobs, sandbox control, provider accounts, and platform operations in one native iPhone client.")
                            .font(.subheadline)
                            .foregroundColor(PlatformTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 12) {
                        metricCard("Workspaces", value: "\(appState.workspaces.count)")
                        metricCard("Jobs", value: "\(appState.jobs.count)")
                        metricCard("Sessions", value: "\(appState.sessions.count)")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Runtime")
                                .font(.headline)
                                .foregroundColor(PlatformTheme.textPrimary)
                            Spacer()
                            PillBadge(text: appState.runtime.mode, color: appState.runtime.mode == "Cloud" ? PlatformTheme.accent : PlatformTheme.warning)
                        }
                        detailRow("Provider", value: appState.runtime.activeProvider)
                        detailRow("Model", value: appState.runtime.activeModel)
                        Text(appState.runtime.notes)
                            .font(.caption)
                            .foregroundColor(PlatformTheme.textTertiary)
                    }
                    .platformCard()

                    if let error = appState.providerStore.lastError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(PlatformTheme.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .platformCard()
                    }
                }
                .padding(16)
            }
            .background(PlatformTheme.background)
            .navigationTitle("Dashboard")
        }
    }

    private func metricCard(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(PlatformTheme.textSecondary)
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(PlatformTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .platformCard()
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(PlatformTheme.textSecondary)
            Spacer()
            Text(value)
                .foregroundColor(PlatformTheme.textPrimary)
        }
        .font(.subheadline)
    }
}
