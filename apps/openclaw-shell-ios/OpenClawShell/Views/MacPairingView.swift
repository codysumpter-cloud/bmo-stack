import SwiftUI

struct MacPairingView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BMOTheme.spacingMD) {
                    headerCard
                    snapshotCard
                    tasksCard
                    processesCard
                    reviewCard
                    artifactsAndReceiptsCard
                }
                .padding(.horizontal, BMOTheme.spacingMD)
                .padding(.bottom, BMOTheme.spacingXL)
            }
            .background(BMOTheme.backgroundPrimary)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Mac Pairing")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                }
            }
            .toolbarBackground(BMOTheme.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("BeMore Mac power mode")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                    Text(appState.macRuntimeStatus)
                        .font(.caption)
                        .foregroundColor(BMOTheme.textSecondary)
                }
                Spacer()
                StatusBadge(label: appState.macRuntimeSnapshot == nil ? "Not paired" : "Paired", color: appState.macRuntimeSnapshot == nil ? BMOTheme.warning : BMOTheme.success)
            }

            Text(appState.macPowerModeSummary)
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)

            Text("Endpoint: \(appState.macPairingEndpoint)")
                .font(.caption)
                .foregroundColor(BMOTheme.textTertiary)

            Button("Inspect Mac runtime") {
                Task { await appState.refreshMacRuntimeSnapshot() }
            }
            .buttonStyle(BMOButtonStyle())
        }
        .bmoCard()
    }

    private var snapshotCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Runtime state")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(BMOTheme.textSecondary)

            if let snapshot = appState.macRuntimeSnapshot {
                detailRow("Host", value: snapshot.pairing.hostName)
                detailRow("Status", value: snapshot.pairing.status)
                detailRow("Workspace", value: snapshot.workspaceRoot ?? "No workspace selected")
                detailRow("Buddy", value: snapshot.buddy.activeFocus)
                if let code = snapshot.pairing.pairingCode {
                    detailRow("Pair code", value: code)
                }
            } else {
                Text("No Mac snapshot yet. Start BeMore Mac, expose the runtime endpoint intentionally, then inspect it here.")
                    .font(.caption)
                    .foregroundColor(BMOTheme.textSecondary)
            }
        }
        .bmoCard()
    }

    private var tasksCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tasks")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(BMOTheme.textSecondary)

            ForEach(appState.macRuntimeSnapshot?.tasks ?? []) { task in
                VStack(alignment: .leading, spacing: 4) {
                    detailRow(task.title, value: task.status)
                    if let command = task.command {
                        Text(command)
                            .font(.caption)
                            .foregroundColor(BMOTheme.textTertiary)
                    }
                }
            }

            if appState.macRuntimeSnapshot?.tasks.isEmpty ?? true {
                Text("No Mac tasks yet. Create or run a Buddy task on the Mac to mirror it here.")
                    .font(.caption)
                    .foregroundColor(BMOTheme.textTertiary)
            }
        }
        .bmoCard()
    }

    private var processesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Command output")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(BMOTheme.textSecondary)

            ForEach(appState.macRuntimeSnapshot?.processes ?? []) { process in
                VStack(alignment: .leading, spacing: 6) {
                    detailRow(process.command, value: process.status)
                    if let stdout = process.stdout, !stdout.isEmpty {
                        Text(stdout)
                            .font(.caption)
                            .foregroundColor(BMOTheme.textSecondary)
                    }
                    if let stderr = process.stderr, !stderr.isEmpty {
                        Text(stderr)
                            .font(.caption)
                            .foregroundColor(BMOTheme.error)
                    }
                }
            }

            if appState.macRuntimeSnapshot?.processes.isEmpty ?? true {
                Text("No Mac command output yet. Run a task on the Mac to inspect it here.")
                    .font(.caption)
                    .foregroundColor(BMOTheme.textTertiary)
            }
        }
        .bmoCard()
    }

    private var reviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Review and diffs")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(BMOTheme.textSecondary)

            ForEach(appState.macRuntimeSnapshot?.diff.files ?? []) { file in
                detailRow(file.path, value: file.status)
            }

            if let diff = appState.macRuntimeSnapshot?.diff.unifiedDiff, !diff.isEmpty {
                Text(diff.prefix(1200))
                    .font(.caption2.monospaced())
                    .foregroundColor(BMOTheme.textSecondary)
            } else {
                Text("No Mac diff yet.")
                    .font(.caption)
                    .foregroundColor(BMOTheme.textTertiary)
            }
        }
        .bmoCard()
    }

    private var artifactsAndReceiptsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Artifacts and receipts")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(BMOTheme.textSecondary)

            ForEach(appState.macRuntimeSnapshot?.artifacts ?? []) { artifact in
                detailRow(artifact.relativePath, value: artifact.kind)
            }

            ForEach(Array(appState.macRuntimeSnapshot?.receipts.prefix(6) ?? [])) { receipt in
                detailRow(receipt.action, value: "\(receipt.status): \(receipt.summary)")
            }

            if (appState.macRuntimeSnapshot?.artifacts.isEmpty ?? true) && (appState.macRuntimeSnapshot?.receipts.isEmpty ?? true) {
                Text("No Mac artifacts or receipts yet.")
                    .font(.caption)
                    .foregroundColor(BMOTheme.textTertiary)
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
