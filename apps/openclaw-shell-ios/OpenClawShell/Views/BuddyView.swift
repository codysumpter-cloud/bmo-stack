import Foundation
import SwiftUI

private struct BuddyPersonalizationDraft {
    var displayName: String = ""
    var nickname: String = ""
    var currentFocus: String = ""
}

struct BuddyView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var store: BuddyProfileStore
    @State private var checkInNote = ""
    @State private var trainingNote = ""
    @State private var personalizationDraft = BuddyPersonalizationDraft()
    @State private var isShowingPersonalizationSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BMOTheme.spacingMD) {
                    if let activeBuddy = store.activeBuddy {
                        myBuddyHeader(for: activeBuddy)
                        activeBuddyCard(for: activeBuddy)
                        actionCard(for: activeBuddy)
                        recentEventsCard(for: activeBuddy)
                    } else {
                        emptyStateCard
                    }

                    rosterCard
                    marketplaceCard

                    trainingAndManagementCard

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
        }
        .sheet(isPresented: $isShowingPersonalizationSheet) {
            personalizationSheet
        }
    }

    private func myBuddyHeader(for buddy: BuddyInstance) -> some View {
        let status = appState.buddyRuntimeStatus
        let template = store.contracts?.templateForInstance(buddy)
        return VStack(alignment: .leading, spacing: BMOTheme.spacingMD) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Buddy")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(BMOTheme.textTertiary)
                    Text(buddy.displayName)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(BMOTheme.textPrimary)
                    Text(template?.onboardingCopy ?? "\(buddy.displayName) is the active companion for chat, skills, tasks, receipts, and results.")
                        .font(.subheadline)
                        .foregroundColor(BMOTheme.textSecondary)
                }
                Spacer()
                StatusBadge(
                    label: status.runtimeAvailable ? "Connected" : "Phone-first",
                    color: status.runtimeAvailable ? BMOTheme.success : BMOTheme.warning
                )
            }

            BuddyAsciiView(buddy: buddy, template: template, mood: buddyMood(for: buddy), compact: true)

            HStack(spacing: BMOTheme.spacingSM) {
                metricPill(title: "Owned", value: "\(status.installedBuddyCount)")
                metricPill(title: "Skills", value: "\(status.registeredSkillCount)")
                metricPill(title: "Level", value: "\(buddy.progression.level)")
                metricPill(title: "Bond", value: "\(buddy.progression.bond)")
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

            BuddyAsciiView(buddy: buddy, template: template, mood: buddyMood(for: buddy))

            Text(template?.onboardingCopy ?? "Buddy profile is ready for the BeMore runtime.")
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

    private var marketplaceCard: some View {
        let installedTemplateIDs = Set(store.installedBuddies.map(\.templateId))

        return VStack(alignment: .leading, spacing: BMOTheme.spacingMD) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Discover Buddies")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                    Text("A curated Buddy marketplace beta. Install starter Buddies now; premium creator Buddies can live here when billing is ready.")
                        .font(.subheadline)
                        .foregroundColor(BMOTheme.textSecondary)
                }
                Spacer()
                StatusBadge(label: "Marketplace beta", color: BMOTheme.accent)
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
                            StatusBadge(label: store.activeBuddy?.templateId == template.templateID ? "Active" : "Owned", color: BMOTheme.success)
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
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Buddy Roster")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                    Text("Owned Buddies stay separate from marketplace templates. Equip one active Buddy at a time.")
                        .font(.caption)
                        .foregroundColor(BMOTheme.textSecondary)
                }
                Spacer()
                StatusBadge(label: "\(store.installedBuddies.count) owned", color: BMOTheme.accent)
            }

            if store.installedBuddies.isEmpty {
                Text("Install your first Buddy from Discover to start a roster.")
                    .font(.subheadline)
                    .foregroundColor(BMOTheme.textSecondary)
            } else {
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
                                Button("Equip") {
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
        }
        .bmoCard()
    }

    private var trainingAndManagementCard: some View {
        VStack(alignment: .leading, spacing: BMOTheme.spacingMD) {
            Text("Training and Plans")
                .font(.headline)
                .foregroundColor(BMOTheme.textPrimary)
            Text("Training grows your active Buddy. Pricing controls future Buddy slots, premium marketplace access, and higher runtime capacity.")
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)
            HStack {
                Button("Open Pricing") {
                    appState.selectedTab = .pricing
                }
                .buttonStyle(BMOButtonStyle(isPrimary: false))
                Button("Open Chat") {
                    appState.openChat(from: .buddy)
                }
                .buttonStyle(BMOButtonStyle())
            }
        }
        .bmoCard()
    }

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: BMOTheme.spacingMD) {
            Text("No Buddy Installed Yet")
                .font(.headline)
                .foregroundColor(BMOTheme.textPrimary)
            Text("Install a starter Buddy to create a local companion, start the Buddy event stream, and keep receipt-backed continuity.")
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

    private func buddyMood(for buddy: BuddyInstance) -> BuddyAnimationMood {
        switch buddy.state.mood.lowercased() {
        case "happy", "excited":
            return .happy
        case "working":
            return .working
        case "thinking":
            return .thinking
        case "sleepy", "tired":
            return .sleepy
        case "needsattention", "needs attention", "stressed":
            return .needsAttention
        default:
            return .idle
        }
    }
}
