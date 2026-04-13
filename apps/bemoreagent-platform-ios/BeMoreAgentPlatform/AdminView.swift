import SwiftUI

struct AdminView: View {
    @EnvironmentObject private var appState: PlatformAppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    statCard("Total users", value: "\(appState.admin.totalUsers)")
                    statCard("Active sessions", value: "\(appState.admin.activeSessions)")
                    statCard("Generation jobs", value: "\(appState.admin.generationJobs)")
                    statCard("System health", value: appState.admin.systemHealth)
                }
                .padding(16)
            }
            .background(PlatformTheme.background)
            .navigationTitle("Admin")
        }
    }

    private func statCard(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(PlatformTheme.textSecondary)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(PlatformTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .platformCard()
    }
}
