import SwiftUI

struct SandboxView: View {
    @EnvironmentObject private var appState: PlatformAppState
    @State private var workspaceName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 10) {
                        TextField("Workspace name", text: $workspaceName)
                            .textFieldStyle(.roundedBorder)
                        Button("Launch Session") {
                            appState.launchSandbox(for: workspaceName)
                            workspaceName = ""
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .platformCard()

                    ForEach(appState.sessions) { session in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(session.workspaceName)
                                    .font(.headline)
                                    .foregroundColor(PlatformTheme.textPrimary)
                                Spacer()
                                PillBadge(text: session.status.capitalized, color: PlatformTheme.success)
                            }
                            Text(session.connectURL)
                                .font(.caption)
                                .foregroundColor(PlatformTheme.textSecondary)
                            Text(session.expiresAt.formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                                .foregroundColor(PlatformTheme.textTertiary)
                            Button("End Session") {
                                appState.terminateSandbox(session)
                            }
                            .buttonStyle(.bordered)
                        }
                        .platformCard()
                    }
                }
                .padding(16)
            }
            .background(PlatformTheme.background)
            .navigationTitle("Sandbox")
        }
    }
}
