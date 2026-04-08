import SwiftUI

struct WorkspacesView: View {
    @EnvironmentObject private var appState: PlatformAppState
    @State private var draftName = ""
    @State private var draftRepo = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 10) {
                        TextField("Workspace name", text: $draftName)
                            .textFieldStyle(.roundedBorder)
                        TextField("Linked repo (optional)", text: $draftRepo)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button("Add Workspace") {
                            appState.addWorkspace(name: draftName, repoURL: draftRepo)
                            draftName = ""
                            draftRepo = ""
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .platformCard()

                    ForEach(appState.workspaces) { workspace in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(workspace.name)
                                    .font(.headline)
                                    .foregroundColor(PlatformTheme.textPrimary)
                                Spacer()
                                PillBadge(text: workspace.syncStatus.capitalized, color: workspace.repoURL.isEmpty ? PlatformTheme.warning : PlatformTheme.accent)
                            }
                            Text(workspace.repoURL.isEmpty ? "Local workspace" : workspace.repoURL)
                                .font(.caption)
                                .foregroundColor(PlatformTheme.textSecondary)
                            HStack {
                                Button("Sync") { appState.syncWorkspace(workspace) }
                                    .buttonStyle(.bordered)
                                Button("Remove") { appState.deleteWorkspace(workspace) }
                                    .buttonStyle(.bordered)
                            }
                        }
                        .platformCard()
                    }
                }
                .padding(16)
            }
            .background(PlatformTheme.background)
            .navigationTitle("Workspaces")
        }
    }
}
