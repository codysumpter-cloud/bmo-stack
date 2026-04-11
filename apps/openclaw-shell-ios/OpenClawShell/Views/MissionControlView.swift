import SwiftUI

struct MissionControlView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedSurface: RepoSurface?
    @State private var lastReceipt: OpenClawReceipt?
    @State private var sandboxCommand = "ls"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BMOTheme.spacingMD) {
                    buddyHomeCard
                    primaryFlowCard
                    if let lastReceipt {
                        ActionReceiptCard(receipt: lastReceipt)
                    }
                    taskAndResultsCard
                    skillsCard
                    macPowerCard
                    routeCard
                    stackSurfacesCard
                }
                .padding(.horizontal, BMOTheme.spacingMD)
                .padding(.bottom, BMOTheme.spacingXL)
            }
            .background(BMOTheme.backgroundPrimary)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Buddy Home")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                }
            }
            .toolbarBackground(BMOTheme.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(item: $selectedSurface) { surface in
                RepoSurfaceDetailView(surface: surface)
            }
            .onAppear { appState.workspaceRuntime.refreshMetadata() }
        }
    }

    private var buddyHomeCard: some View {
        let status = appState.buddyRuntimeStatus
        return VStack(alignment: .leading, spacing: BMOTheme.spacingMD) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("BeMore")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(BMOTheme.textTertiary)
                    Text("Buddy keeps the work moving.")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(BMOTheme.textPrimary)
                    Text(appState.operatorSummary)
                        .font(.subheadline)
                        .foregroundColor(BMOTheme.textSecondary)
                }
                Spacer()
                StatusBadge(label: status.runtimeAvailable ? "Buddy ready" : "Needs setup", color: status.runtimeAvailable ? BMOTheme.success : BMOTheme.warning)
            }

            BuddyAsciiView(mood: buddyMood(for: status))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                dashboardMetric("Workspace", value: "\(appState.workspaceStore.files.count)", icon: "folder")
                dashboardMetric("Skills", value: "\(status.registeredSkillCount)", icon: "sparkles.rectangle.stack")
                dashboardMetric("Receipts", value: "\(status.recentChanges.count)", icon: "checklist.checked")
                dashboardMetric("Mac", value: appState.macRuntimeSnapshot == nil ? "pair" : "live", icon: "macbook.and.iphone")
            }
        }
        .bmoCard()
    }

    private var primaryFlowCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Start with Buddy")
                .font(.headline)
                .foregroundColor(BMOTheme.textPrimary)
            Text("Use the same mobile loop as the Mac shell: choose workspace context, run a skill or task, inspect the result, and keep the receipt.")
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)

            HStack(spacing: 8) {
                Button("Open Buddy") {
                    appState.selectedTab = .buddy
                }
                .buttonStyle(BMOButtonStyle())

                Button("Pair Mac") {
                    appState.selectedTab = .pairing
                }
                .buttonStyle(BMOButtonStyle(isPrimary: false))
            }

            HStack(spacing: 8) {
                Button("Workspace") {
                    appState.selectedTab = .files
                }
                .buttonStyle(BMOButtonStyle(isPrimary: false))

                Button("Skills") {
                    appState.selectedTab = .skills
                }
                .buttonStyle(BMOButtonStyle(isPrimary: false))
            }
        }
        .bmoCard()
    }

    private var taskAndResultsCard: some View {
        let status = appState.buddyRuntimeStatus
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tasks and results")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                    Text("Receipt-backed work is the proof surface on iPhone too.")
                        .font(.caption)
                        .foregroundColor(BMOTheme.textSecondary)
                }
                Spacer()
                StatusBadge(label: "\(status.failedActions.count) blocked", color: status.failedActions.isEmpty ? BMOTheme.success : BMOTheme.warning)
            }

            HStack(spacing: 8) {
                TextField("Sandbox command", text: $sandboxCommand)
                    .textFieldStyle(.plain)
                    .foregroundColor(BMOTheme.textPrimary)
                    .padding(10)
                    .background(BMOTheme.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusSmall, style: .continuous))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Run") {
                    lastReceipt = appState.runSandbox(command: sandboxCommand)
                }
                .buttonStyle(BMOButtonStyle())
            }

            if status.recentChanges.isEmpty {
                Text("Run a Buddy action, skill, or Mac inspection to create the next result.")
                    .font(.caption)
                    .foregroundColor(BMOTheme.textTertiary)
            } else {
                ForEach(Array(status.recentChanges.prefix(3)), id: \.id) { event in
                    detailRow(event.type, value: event.message)
                }
            }
        }
        .bmoCard()
    }

    private var skillsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Buddy skills")
                    .font(.headline)
                    .foregroundColor(BMOTheme.textPrimary)
                Spacer()
                StatusBadge(label: "\(appState.workspaceRuntime.skills.count) registered", color: BMOTheme.accent)
            }
            Text("Skills make Buddy more useful: they produce artifacts, receipts, and task context rather than decorative shortcuts.")
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)
            Button("Open Skills") {
                appState.selectedTab = .skills
            }
            .buttonStyle(BMOButtonStyle(isPrimary: false))
        }
        .bmoCard()
    }

    private var macPowerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mac power mode")
                    .font(.headline)
                    .foregroundColor(BMOTheme.textPrimary)
                Spacer()
                StatusBadge(label: appState.macRuntimeSnapshot == nil ? "Not paired" : "Paired", color: appState.macRuntimeSnapshot == nil ? BMOTheme.warning : BMOTheme.success)
            }
            Text(appState.macPowerModeSummary)
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)
            Button("Inspect Mac runtime") {
                Task { await appState.refreshMacRuntimeSnapshot() }
            }
            .buttonStyle(BMOButtonStyle(isPrimary: false))
        }
        .bmoCard()
    }

    private var routeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Runtime route")
                .font(.headline)
                .foregroundColor(BMOTheme.textPrimary)
            detailRow("Active route", value: appState.activeRouteTitle)
            detailRow("Target", value: appState.activeRouteDetail)
            detailRow("Health", value: appState.routeHealthSummary)
        }
        .bmoCard()
    }

    private var stackSurfacesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reference surfaces")
                .font(.headline)
                .foregroundColor(BMOTheme.textPrimary)
            Text("Repo briefs stay available as supporting context, but Buddy Home is now the product center.")
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
                    .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusSmall, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .bmoCard()
    }

    private func buddyMood(for status: BuddyRuntimeStatus) -> BuddyAnimationMood {
        if !status.failedActions.isEmpty { return .thinking }
        if appState.macRuntimeSnapshot?.processes.contains(where: { $0.status == "running" }) == true { return .working }
        if status.recentChanges.isEmpty && appState.workspaceStore.files.isEmpty { return .sleepy }
        if !status.recentChanges.isEmpty { return .happy }
        return status.runtimeAvailable ? .idle : .thinking
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

    private func dashboardMetric(_ label: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(BMOTheme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(BMOTheme.textTertiary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(BMOTheme.textPrimary)
            }
            Spacer()
        }
        .padding(10)
        .background(BMOTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusSmall, style: .continuous))
    }
}
