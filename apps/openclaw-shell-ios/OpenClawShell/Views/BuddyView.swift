import Foundation
import SwiftUI

private struct BuddyPersonalizationDraft {
    var displayName: String = ""
    var nickname: String = ""
    var currentFocus: String = ""
}

struct BuddyView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var store = BuddyProfileStore()
    @State private var checkInNote = ""
    @State private var trainingNote = ""
    @State private var personalizationDraft = BuddyPersonalizationDraft()
    @State private var isShowingPersonalizationSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BMOTheme.spacingMD) {
                    runtimeCard

                    if let activeBuddy = store.activeBuddy {
                        activeBuddyCard(for: activeBuddy)
                        actionCard(for: activeBuddy)
                        recentEventsCard(for: activeBuddy)
                    } else {
                        emptyStateCard
                    }

                    libraryCard

                    if store.installedBuddies.isEmpty == false {
                        rosterCard
                    }

                    if let receipt = store.lastReceipt {
                        receiptCard(receipt)
                    }

                    if let loadError = store.loadError {
                        errorCard(loadError)
                    }
                }
                .padding(.horizontal, BMOTheme.spacingMD)
                .padding(.bottom, BMOTheme.spacingXL)
            }
            .background(BMOTheme.backgroundPrimary)
            .navigationTitle("Buddy")
            .toolbarBackground(BMOTheme.backgroundPrimary, for: .navigationBar)
        }
        .task {
            store.load(for: appState.stackConfig)
            appState.buddyProfileStore = store
        }
        .onDisappear {
            if appState.buddyProfileStore === store {
                appState.buddyProfileStore = nil
            }
        }
        .sheet(isPresented: $isShowingPersonalizationSheet) {
            personalizationSheet
        }
    }

    private var runtimeCard: some View {
        let status = appState.buddyRuntimeStatus
        return VStack(alignment: .leading, spacing: BMOTheme.spacingMD) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Build 18 Buddy Runtime")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                    Text("Structured Buddy templates, installable local instances, readable continuity files, and receipt-backed updates.")
                        .font(.subheadline)
                        .foregroundColor(BMOTheme.textSecondary)
                }
                Spacer()
                StatusBadge(
                    label: status.runtimeAvailable ? "Runtime Ready" : "Runtime Missing",
                    color: status.runtimeAvailable ? BMOTheme.success : BMOTheme.warning
                )
            }

            HStack(spacing: BMOTheme.spacingSM) {
                metricPill(title: "Installed", value: "\(status.installedBuddyCount)")
                metricPill(title: "Active", value: status.hasActiveBuddy ? "Yes" : "No")
                metricPill(title: "Skills", value: "\(status.registeredSkillCount)")
                metricPill(title: "Failures", value: "\(status.failedActions.count)")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Suggested next actions")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(BMOTheme.textPrimary)
                ForEach(status.suggestedNextActions, id: \.self) { suggestion in
                    Text("• \(suggestion)")
                        .font(.caption)
                        .foregroundColor(BMOTheme.textSecondary)
                }
            }
        }
        .bmoCard()
    }

    private func activeBuddyCard(for buddy: BuddyInstance) -> some View {
        let template = store.contracts?.templateForInstance(buddy)
        let bondLabel = store.contracts.map { BuddyMarkdownRenderer.bondLabel(for: buddy.progression.bond, contracts: $0) } ?? "Bond"

        return VStack(alignment: .leading, spacing: BMOTheme.spacingMD) {
            HStack(alignment: .top, spacing: BMOTheme.spacingMD) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Buddy")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(BMOTheme.textTertiary)
                    Text(buddy.displayName)
                        .font(.title2.bold())
                        .foregroundColor(BMOTheme.textPrimary)
                    Text("\(buddy.identity.class) • \(buddy.identity.role)")
                        .font(.subheadline)
                        .foregroundColor(BMOTheme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    StatusBadge(label: bondLabel, color: BMOTheme.accent)
                    StatusBadge(label: buddy.state.mood.capitalized, color: moodColor(buddy.state.mood))
                }
            }

            Text(asciiArt(for: buddy, template: template))
                .font(.system(.body, design: .monospaced))
                .foregroundColor(BMOTheme.accent)
                .padding(BMOTheme.spacingMD)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(BMOTheme.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusMedium, style: .continuous))

            Text(template?.onboardingCopy ?? "Legacy Buddy migrated into the Build 18 runtime.")
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)

            HStack(spacing: BMOTheme.spacingSM) {
                metricPill(title: "Level", value: "\(buddy.progression.level)")
                metricPill(title: "XP", value: "\(buddy.progression.xp)")
                metricPill(title: "Bond", value: "\(buddy.progression.bond)")
                metricPill(title: "Tier", value: "\(buddy.progression.evolutionTier)")
            }

            VStack(alignment: .leading, spacing: 6) {
                profileRow(label: "Template", value: template?.name ?? "Legacy Buddy")
                profileRow(label: "Focus", value: buddy.state.currentFocus ?? "No active focus")
                profileRow(label: "Last active", value: BuddyMarkdownRenderer.iso8601(buddy.state.lastActiveAt))
                profileRow(label: "Top move", value: buddy.equippedMoves.sorted(by: { $0.slot < $1.slot }).first?.name ?? "None")
            }

            Button("Personalize Buddy") {
                personalizationDraft = BuddyPersonalizationDraft(
                    displayName: buddy.displayName,
                    nickname: buddy.nickname ?? "",
                    currentFocus: buddy.state.currentFocus ?? ""
                )
                isShowingPersonalizationSheet = true
            }
            .buttonStyle(BMOButtonStyle(isPrimary: false))
        }
        .bmoCard()
    }

    private func actionCard(for buddy: BuddyInstance) -> some View {
        VStack(alignment: .leading, spacing: BMOTheme.spacingMD) {
            Text("Buddy Actions")
                .font(.headline)
                .foregroundColor(BMOTheme.textPrimary)

            VStack(alignment: .leading, spacing: 10) {
                Text("Check-in")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(BMOTheme.textPrimary)
                TextField("What changed or what matters now?", text: $checkInNote, axis: .vertical)
                    .textFieldStyle(.plain)
                    .foregroundColor(BMOTheme.textPrimary)
                    .padding(BMOTheme.spacingMD)
                    .background(BMOTheme.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusMedium, style: .continuous))

                Button("Record Check-in") {
                    store.recordCheckIn(note: checkInNote, using: appState)
                    checkInNote = ""
                }
                .buttonStyle(BMOButtonStyle())
            }

            Divider().overlay(BMOTheme.divider)

            VStack(alignment: .leading, spacing: 10) {
                Text("Training")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(BMOTheme.textPrimary)

                Picker("Training category", selection: $store.selectedTrainingCategory) {
                    ForEach(store.contracts?.progression.trainingCategories ?? [], id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(.menu)
                .tint(BMOTheme.accent)

                TextField("What did you train or improve?", text: $trainingNote, axis: .vertical)
                    .textFieldStyle(.plain)
                    .foregroundColor(BMOTheme.textPrimary)
                    .padding(BMOTheme.spacingMD)
                    .background(BMOTheme.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusMedium, style: .continuous))

                Button("Record Training for \(buddy.displayName)") {
                    store.recordTraining(note: trainingNote, using: appState)
                    trainingNote = ""
                }
                .buttonStyle(BMOButtonStyle())
            }
        }
        .bmoCard()
    }

    private func recentEventsCard(for buddy: BuddyInstance) -> some View {
        let events = store.recentEvents(for: buddy)
        return VStack(alignment: .leading, spacing: BMOTheme.spacingMD) {
            Text("Recent Buddy Events")
                .font(.headline)
                .foregroundColor(BMOTheme.textPrimary)

            if events.isEmpty {
                Text("No runtime events recorded yet. Install, personalize, check in, or train to start the event stream.")
                    .font(.subheadline)
                    .foregroundColor(BMOTheme.textSecondary)
            } else {
                ForEach(events) { event in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(event.type)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(BMOTheme.accent)
                            Spacer()
                            Text(BuddyMarkdownRenderer.iso8601(event.occurredAt))
                                .font(.caption)
                                .foregroundColor(BMOTheme.textTertiary)
                        }
                        Text(event.summary)
                            .font(.subheadline)
                            .foregroundColor(BMOTheme.textPrimary)
                    }
                    .padding(BMOTheme.spacingMD)
                    .background(BMOTheme.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusMedium, style: .continuous))
                }
            }
        }
        .bmoCard()
    }

    private var libraryCard: some View {
        let installedTemplateIDs = Set(store.installedBuddies.map(\.templateId))

        return VStack(alignment: .leading, spacing: BMOTheme.spacingMD) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Council Starter Pack")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                    Text("Official Build 18 Buddy templates bundled into the app from canonical PR #231 contracts.")
                        .font(.subheadline)
                        .foregroundColor(BMOTheme.textSecondary)
                }
                Spacer()
                StatusBadge(label: "\(store.templates.count) templates", color: BMOTheme.accent)
            }

            ForEach(store.templates) { template in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name)
                                .font(.headline)
                                .foregroundColor(BMOTheme.textPrimary)
                            Text(template.starterRole)
                                .font(.subheadline)
                                .foregroundColor(BMOTheme.textSecondary)
                        }
                        Spacer()
                        if installedTemplateIDs.contains(template.templateID) {
                            StatusBadge(label: "Installed", color: BMOTheme.success)
                        } else {
                            Button("Install") {
                                store.install(template: template, using: appState)
                            }
                            .buttonStyle(BMOButtonStyle(isPrimary: false))
                        }
                    }

                    Text(template.onboardingCopy)
                        .font(.subheadline)
                        .foregroundColor(BMOTheme.textSecondary)

                    HStack(spacing: BMOTheme.spacingSM) {
                        metricPill(title: "Power", value: "\(template.total)")
                        metricPill(title: "Signature", value: template.moveSet.first?.name ?? "None")
                    }

                    Text(template.ascii.baseSilhouette)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(BMOTheme.accent)

                    Text("Moves: \(template.moveSet.map(\.name).joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(BMOTheme.textTertiary)
                }
                .padding(BMOTheme.spacingMD)
                .background(BMOTheme.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusMedium, style: .continuous))
            }
        }
        .bmoCard()
    }

    private var rosterCard: some View {
        VStack(alignment: .leading, spacing: BMOTheme.spacingMD) {
            Text("Installed Buddy Roster")
                .font(.headline)
                .foregroundColor(BMOTheme.textPrimary)

            ForEach(store.installedBuddies) { buddy in
                let isActive = store.activeBuddy?.instanceId == buddy.instanceId
                let template = store.contracts?.templateForInstance(buddy)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(buddy.displayName)
                                .font(.headline)
                                .foregroundColor(BMOTheme.textPrimary)
                            Text(template?.name ?? buddy.identity.role)
                                .font(.subheadline)
                                .foregroundColor(BMOTheme.textSecondary)
                        }
                        Spacer()
                        if isActive {
                            StatusBadge(label: "Active", color: BMOTheme.accent)
                        } else {
                            Button("Make Active") {
                                store.makeActive(buddy, using: appState)
                            }
                            .buttonStyle(BMOButtonStyle(isPrimary: false))
                        }
                    }

                    Text("Focus: \(buddy.state.currentFocus ?? "No active focus")")
                        .font(.subheadline)
                        .foregroundColor(BMOTheme.textSecondary)

                    HStack(spacing: BMOTheme.spacingSM) {
                        metricPill(title: "Level", value: "\(buddy.progression.level)")
                        metricPill(title: "Bond", value: "\(buddy.progression.bond)")
                        metricPill(title: "Mood", value: buddy.state.mood.capitalized)
                    }
                }
                .padding(BMOTheme.spacingMD)
                .background(BMOTheme.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusMedium, style: .continuous))
            }
        }
        .bmoCard()
    }

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: BMOTheme.spacingMD) {
            Text("No Buddy Installed Yet")
                .font(.headline)
                .foregroundColor(BMOTheme.textPrimary)
            Text("Install one Council starter Buddy below to create a clean local instance, start the Buddy event stream, and generate `.openclaw/buddy.md` plus `.openclaw/buddies.md`.")
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)
        }
        .bmoCard()
    }

    private func receiptCard(_ receipt: OpenClawReceipt) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Latest Buddy Receipt")
                    .font(.headline)
                    .foregroundColor(BMOTheme.textPrimary)
                Spacer()
                StatusBadge(label: receipt.status.label, color: receipt.status.color)
            }

            Text(receipt.summary)
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)

            if receipt.artifacts.isEmpty == false {
                Text("Artifacts: \(receipt.artifacts.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(BMOTheme.textTertiary)
            }
        }
        .bmoCard()
    }

    private func errorCard(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Buddy Load Error")
                .font(.headline)
                .foregroundColor(BMOTheme.error)
            Text(message)
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)
        }
        .bmoCard()
    }

    private var personalizationSheet: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Display name", text: $personalizationDraft.displayName)
                    TextField("Nickname", text: $personalizationDraft.nickname)
                }

                Section("Current Focus") {
                    TextField("Focus", text: $personalizationDraft.currentFocus, axis: .vertical)
                }
            }
            .navigationTitle("Personalize Buddy")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isShowingPersonalizationSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.personalizeActive(
                            displayName: personalizationDraft.displayName,
                            nickname: personalizationDraft.nickname,
                            currentFocus: personalizationDraft.currentFocus,
                            using: appState
                        )
                        isShowingPersonalizationSheet = false
                    }
                }
            }
        }
    }

    private func asciiArt(for buddy: BuddyInstance, template: CouncilStarterBuddyTemplate?) -> String {
        guard let template else {
            return buddy.visual?.currentAnimationState ?? buddy.displayName
        }
        let state = buddy.visual?.currentAnimationState ?? buddy.state.mood
        return template.ascii.expressions[state] ?? template.ascii.baseSilhouette
    }

    private func metricPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(BMOTheme.textTertiary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(BMOTheme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(BMOTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusSmall, style: .continuous))
    }

    private func profileRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(BMOTheme.textTertiary)
                .frame(width: 84, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)
            Spacer(minLength: 0)
        }
    }

    private func moodColor(_ mood: String) -> Color {
        switch mood.lowercased() {
        case "happy", "excited":
            return BMOTheme.success
        case "working", "thinking":
            return BMOTheme.accent
        case "stressed":
            return BMOTheme.warning
        default:
            return BMOTheme.textSecondary
        }
    }
}
