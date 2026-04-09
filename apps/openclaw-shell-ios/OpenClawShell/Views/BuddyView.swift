import SwiftUI
import Foundation

enum BuddyArchetype: String, CaseIterable, Codable, Hashable {
    case tengu
    case robot
    case cat
    case slime
    case capybara

    var displayName: String {
        switch self {
        case .tengu: return "Tengu"
        case .robot: return "Robot"
        case .cat: return "Cat"
        case .slime: return "Slime"
        case .capybara: return "Capybara"
        }
    }

    var badge: String {
        switch self {
        case .tengu: return "Watcher"
        case .robot: return "Builder"
        case .cat: return "Shadow"
        case .slime: return "Spark"
        case .capybara: return "Anchor"
        }
    }

    var asciiArt: String {
        switch self {
        case .tengu:
            return """
             /\\_/\\
            ( o.o )
             > ^ <
            """
        case .robot:
            return """
            [o_o]
            /|_|\\
             / \\
            """
        case .cat:
            return "/\\_/\\\n( =.= )\n (___)"
        case .slime:
            return """
             .-.
            (o o)
            | O \\
             \\   \\
              `~~~'
            """
        case .capybara:
            return " ____\n/ __ \\\n/ /  \\_\\\n\\_\\____/"
        }
    }
}

struct BuddyStats: Codable, Hashable {
    var bond: Int
    var power: Int
    var focus: Int
    var curiosity: Int
    var care: Int
}

struct GeneratedBuddy: Identifiable, Codable, Hashable {
    var id: UUID
    var seed: Int
    var profileSignature: String
    var name: String
    var archetype: BuddyArchetype
    var title: String
    var originSummary: String
    var specialty: String
    var personalitySummary: String
    var asciiArt: String
    var stats: BuddyStats
    var createdAt: Date
}

struct BuddyBattleRecord: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var summary: String
    var isVictory: Bool
    var createdAt: Date
}

struct BuddySystemState: Codable {
    var profileSignature: String
    var activeBuddy: GeneratedBuddy
    var collection: [GeneratedBuddy]
    var tradeOffers: [GeneratedBuddy]
    var battleHistory: [BuddyBattleRecord]
}

enum BuddyGenerator {
    private static let titles = [
        "of the Neon Vale",
        "of Prism Harbor",
        "the Quiet Wildcard",
        "the Soft Thunder",
        "of Kairos Drift",
        "the Pocket Vanguard",
        "the Signal Keeper"
    ]

    private static let suffixes = [
        "Glint", "Nova", "Patch", "Orbit", "Tinker", "Rune", "Mochi", "Pixel", "Comet", "Bloop"
    ]

    static func profileSignature(for config: StackConfig) -> String {
        [
            config.stackName,
            config.goal,
            config.role,
            String(config.autonomyLevel),
            config.memoryEnabled ? "memory-on" : "memory-off",
            config.toolsEnabled ? "tools-on" : "tools-off",
            config.optimizationMode
        ].joined(separator: "|")
    }

    static func makeBuddy(from config: StackConfig, seed: Int) -> GeneratedBuddy {
        var generator = SeededGenerator(seed: UInt64(abs(seed) + 1))
        let archetype = pickArchetype(for: config, using: &generator)
        let sourceName = config.stackName.trimmingCharacters(in: .whitespacesAndNewlines)
        let stem = (sourceName.isEmpty ? config.role : sourceName)
            .split(separator: " ")
            .first
            .map(String.init)?
            .capitalized ?? "BMO"
        let title = titles[generator.nextInt(upperBound: titles.count)]
        let suffix = suffixes[generator.nextInt(upperBound: suffixes.count)]

        let autonomyBonus = config.autonomyLevel * 3
        let toolBonus = config.toolsEnabled ? 8 : 0
        let memoryBonus = config.memoryEnabled ? 8 : 0
        let qualityBonus = config.optimizationMode == "quality" ? 8 : config.optimizationMode == "speed" ? 2 : 5

        let stats = BuddyStats(
            bond: min(100, 48 + memoryBonus + generator.nextInt(upperBound: 18)),
            power: min(100, 42 + autonomyBonus + generator.nextInt(upperBound: 18)),
            focus: min(100, 44 + qualityBonus + generator.nextInt(upperBound: 18)),
            curiosity: min(100, 40 + toolBonus + generator.nextInt(upperBound: 20)),
            care: min(100, 45 + memoryBonus + generator.nextInt(upperBound: 18))
        )

        return GeneratedBuddy(
            id: UUID(),
            seed: seed,
            profileSignature: profileSignature(for: config),
            name: "\(stem) \(suffix)",
            archetype: archetype,
            title: title,
            originSummary: "Generated from \(config.role.isEmpty ? "your current setup" : config.role) with a \(config.optimizationMode) posture and autonomy \(config.autonomyLevel)/5.",
            specialty: specialtySummary(for: config, archetype: archetype),
            personalitySummary: personalitySummary(for: config, archetype: archetype),
            asciiArt: archetype.asciiArt,
            stats: stats,
            createdAt: .now
        )
    }

    private static func pickArchetype(for config: StackConfig, using generator: inout SeededGenerator) -> BuddyArchetype {
        let role = config.role.lowercased()
        let goal = config.goal.lowercased()

        if role.contains("engineer") || config.toolsEnabled { return .robot }
        if role.contains("designer") || role.contains("creator") { return .cat }
        if role.contains("founder") || goal.contains("launch") || config.autonomyLevel >= 4 { return .tengu }
        if role.contains("student") || goal.contains("learn") || goal.contains("research") { return .slime }
        if role.contains("manager") || goal.contains("team") { return .capybara }
        return BuddyArchetype.allCases[generator.nextInt(upperBound: BuddyArchetype.allCases.count)]
    }

    private static func personalitySummary(for config: StackConfig, archetype: BuddyArchetype) -> String {
        let role = config.role.isEmpty ? "operator" : config.role
        switch archetype {
        case .tengu:
            return "A daring scout shaped by your \(role) profile. It thrives when you want momentum, initiative, and a little healthy chaos."
        case .robot:
            return "A dependable systems buddy generated from your \(role) setup. It prefers checklists, structure, and tools that actually ship."
        case .cat:
            return "A taste-driven companion tuned to your \(role) instincts. It notices details, protects quality, and keeps sharp edges where they matter."
        case .slime:
            return "A playful learner grown from your \(role) profile. It absorbs new context quickly and turns uncertainty into curiosity."
        case .capybara:
            return "A steady social anchor generated from your \(role) setup. It smooths noisy systems and keeps the party together under pressure."
        }
    }

    private static func specialtySummary(for config: StackConfig, archetype: BuddyArchetype) -> String {
        let goal = config.goal.isEmpty ? "whatever comes next" : config.goal.lowercased()
        switch archetype {
        case .tengu:
            return "Best at bold pushes toward \(goal)."
        case .robot:
            return "Best at reliable execution for \(goal)."
        case .cat:
            return "Best at craft, polish, and protecting signal while you chase \(goal)."
        case .slime:
            return "Best at experiments, learning loops, and leveling up around \(goal)."
        case .capybara:
            return "Best at collaboration, calm pacing, and sustainable progress toward \(goal)."
        }
    }
}

enum KairosMiniEvent: String, CaseIterable, Identifiable {
    case none
    case eclipse
    case harvest
    case storm

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "No Event"
        case .eclipse: return "Eclipse"
        case .harvest: return "Harvest"
        case .storm: return "Storm"
        }
    }

    var summary: String {
        switch self {
        case .none: return "Normal world state with no global modifier."
        case .eclipse: return "High-drama event windows and spicy rival encounters."
        case .harvest: return "Growth-heavy encounters with easier wins and better rewards."
        case .storm: return "Riskier battles with sharper swings and stronger opponents."
        }
    }

    var attackBonus: Int {
        switch self {
        case .none: return 0
        case .eclipse: return 6
        case .harvest: return 4
        case .storm: return 8
        }
    }

    var challengeBonus: Int {
        switch self {
        case .none: return 0
        case .eclipse: return 5
        case .harvest: return -4
        case .storm: return 10
        }
    }
}

@MainActor
final class BuddyProfileStore: ObservableObject {
    @Published private(set) var state: BuddySystemState?
    @Published var selectedEvent: KairosMiniEvent = .none

    var activeBuddy: GeneratedBuddy? { state?.activeBuddy }
    var collection: [GeneratedBuddy] { state?.collection ?? [] }
    var tradeOffers: [GeneratedBuddy] { state?.tradeOffers ?? [] }
    var battleHistory: [BuddyBattleRecord] { state?.battleHistory ?? [] }

    private let fileURL = Paths.stateDirectory.appendingPathComponent("buddy-system.json")

    func load(for config: StackConfig) {
        let signature = BuddyGenerator.profileSignature(for: config)

        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode(BuddySystemState.self, from: data) {
            if decoded.profileSignature == signature {
                state = decoded
                return
            }

            var migrated = decoded
            let newBuddy = BuddyGenerator.makeBuddy(from: config, seed: Int.random(in: 1...999_999))
            migrated.profileSignature = signature
            migrated.activeBuddy = newBuddy
            migrated.collection = dedupe([newBuddy] + migrated.collection + [decoded.activeBuddy])
            migrated.tradeOffers = makeTradeOffers(from: config, excluding: migrated.collection + [newBuddy])
            state = migrated
            persist()
            return
        }

        let starter = BuddyGenerator.makeBuddy(from: config, seed: Int.random(in: 1...999_999))
        state = BuddySystemState(
            profileSignature: signature,
            activeBuddy: starter,
            collection: [starter],
            tradeOffers: makeTradeOffers(from: config, excluding: [starter]),
            battleHistory: []
        )
        persist()
    }

    func regenerateBuddy(from config: StackConfig) {
        guard var state else { return }
        let buddy = BuddyGenerator.makeBuddy(from: config, seed: Int.random(in: 1...999_999))
        state.profileSignature = BuddyGenerator.profileSignature(for: config)
        state.activeBuddy = buddy
        state.collection = dedupe([buddy] + state.collection)
        state.tradeOffers = makeTradeOffers(from: config, excluding: state.collection + [buddy])
        self.state = state
        persist()
    }

    func trainActiveBuddy() {
        mutateActiveBuddy { buddy in
            buddy.stats.power = min(100, buddy.stats.power + 5)
            buddy.stats.focus = min(100, buddy.stats.focus + 3)
            buddy.stats.bond = min(100, buddy.stats.bond + 2)
        }
    }

    func feedActiveBuddy() {
        mutateActiveBuddy { buddy in
            buddy.stats.care = min(100, buddy.stats.care + 6)
            buddy.stats.bond = min(100, buddy.stats.bond + 4)
            buddy.stats.curiosity = min(100, buddy.stats.curiosity + 2)
        }
    }

    func startBattle() {
        guard var state else { return }
        var buddy = state.activeBuddy
        let event = selectedEvent
        var generator = SeededGenerator(seed: UInt64(abs(buddy.seed) + battleHistory.count + 7))
        let rivals = ["Echo Warden", "Sky Coil", "Dust Sprite", "Bit Fang", "Harbor Moth", "Rift Cub"]
        let rival = rivals[generator.nextInt(upperBound: rivals.count)]
        let allyScore = buddy.stats.power + buddy.stats.focus + event.attackBonus + Int.random(in: 4...18)
        let rivalScore = 80 + event.challengeBonus + Int.random(in: 0...30)
        let victory = allyScore >= rivalScore

        if victory {
            buddy.stats.power = min(100, buddy.stats.power + 4)
            buddy.stats.bond = min(100, buddy.stats.bond + 3)
        } else {
            buddy.stats.focus = min(100, buddy.stats.focus + 2)
            buddy.stats.care = min(100, buddy.stats.care + 2)
        }

        let summary = victory
            ? "\(buddy.name) won a \(event.displayName.lowercased()) duel against \(rival) and brought home fresh XP."
            : "\(buddy.name) lost a scrappy \(event.displayName.lowercased()) duel to \(rival), but learned enough to come back sharper."

        let record = BuddyBattleRecord(
            id: UUID(),
            title: victory ? "Victory in \(event.displayName)" : "Setback in \(event.displayName)",
            summary: summary,
            isVictory: victory,
            createdAt: .now
        )

        state.activeBuddy = buddy
        state.collection = dedupe([buddy] + state.collection)
        state.battleHistory = [record] + Array(state.battleHistory.prefix(7))
        self.state = state
        persist()
    }

    func acceptTrade(_ offer: GeneratedBuddy, from config: StackConfig) {
        guard var state else { return }
        let previous = state.activeBuddy
        state.activeBuddy = offer
        state.collection = dedupe([offer, previous] + state.collection)
        state.tradeOffers = makeTradeOffers(from: config, excluding: state.collection + [offer])
        self.state = state
        persist()
    }

    private func mutateActiveBuddy(_ mutation: (inout GeneratedBuddy) -> Void) {
        guard var state else { return }
        var buddy = state.activeBuddy
        mutation(&buddy)
        state.activeBuddy = buddy
        state.collection = dedupe([buddy] + state.collection)
        self.state = state
        persist()
    }

    private func makeTradeOffers(from config: StackConfig, excluding buddies: [GeneratedBuddy]) -> [GeneratedBuddy] {
        let existingNames = Set(buddies.map { $0.name })
        var offers: [GeneratedBuddy] = []
        var attempts = 0

        while offers.count < 3 && attempts < 20 {
            attempts += 1
            let candidate = BuddyGenerator.makeBuddy(from: config, seed: Int.random(in: 1...999_999))
            if existingNames.contains(candidate.name) || offers.contains(where: { $0.name == candidate.name }) {
                continue
            }
            offers.append(candidate)
        }

        return offers
    }

    private func dedupe(_ buddies: [GeneratedBuddy]) -> [GeneratedBuddy] {
        var seen = Set<String>()
        var unique: [GeneratedBuddy] = []

        for buddy in buddies {
            let key = "\(buddy.name)|\(buddy.archetype.rawValue)|\(buddy.seed)"
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            unique.append(buddy)
        }

        return unique
    }

    private func persist() {
        guard let state else { return }
        if let data = try? JSONEncoder().encode(state) {
            try? data.write(to: fileURL, options: [.atomic])
        }
    }
}

struct BuddyView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var store = BuddyProfileStore()

    private var profileID: String {
        BuddyGenerator.profileSignature(for: appState.stackConfig)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BMOTheme.spacingMD) {
                    if let buddy = store.activeBuddy {
                        header(for: buddy)
                        sourceProfileCard(for: buddy)
                        careLoopCard
                        battleCard
                        tradeBazaarCard
                        collectionCard
                    } else {
                        ProgressView()
                            .tint(BMOTheme.accent)
                            .padding(.top, BMOTheme.spacingXL)
                    }
                }
                .padding(.horizontal, BMOTheme.spacingMD)
                .padding(.bottom, BMOTheme.spacingXL)
            }
            .background(BMOTheme.backgroundPrimary)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Buddy")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                }
            }
            .toolbarBackground(BMOTheme.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task(id: profileID) {
                store.load(for: appState.stackConfig)
            }
        }
    }

    private func header(for buddy: GeneratedBuddy) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Generated Buddy")
                        .font(.caption)
                        .foregroundColor(BMOTheme.textTertiary)
                    Text(buddy.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(BMOTheme.textPrimary)
                    Text("\(buddy.archetype.displayName) \(buddy.title)")
                        .font(.subheadline)
                        .foregroundColor(BMOTheme.textSecondary)
                    StatusBadge(label: buddy.archetype.badge, color: BMOTheme.accent)
                }

                Spacer()

                Text(buddy.asciiArt)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(BMOTheme.accent)
                    .padding(12)
                    .background(BMOTheme.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusMedium, style: .continuous))
            }

            Text(buddy.personalitySummary)
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)

            HStack(spacing: 8) {
                statPill("Bond", value: buddy.stats.bond)
                statPill("Power", value: buddy.stats.power)
                statPill("Focus", value: buddy.stats.focus)
                statPill("Care", value: buddy.stats.care)
            }
        }
        .bmoCard()
    }

    private func sourceProfileCard(for buddy: GeneratedBuddy) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why this creature exists")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(BMOTheme.textSecondary)

            profileRow(label: "Stack", value: appState.stackConfig.stackName)
            profileRow(label: "Goal", value: appState.stackConfig.goal)
            profileRow(label: "Role", value: appState.stackConfig.role)
            profileRow(label: "Optimization", value: appState.stackConfig.optimizationMode.capitalized)
            profileRow(label: "Specialty", value: buddy.specialty)

            Text(buddy.originSummary)
                .font(.caption)
                .foregroundColor(BMOTheme.textTertiary)
        }
        .bmoCard()
    }

    private var careLoopCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Care loop")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(BMOTheme.textSecondary)

            Text("This buddy is generated from your agent profile, not selected from a fixed roster. Regenerating preserves your collection and creates a fresh companion from the latest profile.")
                .font(.caption)
                .foregroundColor(BMOTheme.textTertiary)

            HStack(spacing: 10) {
                buttonChip(label: "Feed", icon: "carrot.fill") {
                    store.feedActiveBuddy()
                }
                buttonChip(label: "Train", icon: "figure.run") {
                    store.trainActiveBuddy()
                }
            }

            Button {
                store.regenerateBuddy(from: appState.stackConfig)
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Generate new buddy from profile")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(BMOButtonStyle())
        }
        .bmoCard()
    }

    private var battleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Prismo's World")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(BMOTheme.textSecondary)
                Spacer()
                StatusBadge(label: store.selectedEvent.displayName, color: BMOTheme.warning)
            }

            Picker("Kairos Event", selection: $store.selectedEvent) {
                ForEach(KairosMiniEvent.allCases) { event in
                    Text(event.displayName).tag(event)
                }
            }
            .pickerStyle(.segmented)

            Text(store.selectedEvent.summary)
                .font(.caption)
                .foregroundColor(BMOTheme.textTertiary)

            Button {
                store.startBattle()
            } label: {
                HStack {
                    Image(systemName: "bolt.shield.fill")
                    Text("Start battle")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(BMOButtonStyle(isPrimary: false))

            if let latest = store.battleHistory.first {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(latest.title)
                            .font(.subheadline)
                            .foregroundColor(BMOTheme.textPrimary)
                        Spacer()
                        StatusBadge(label: latest.isVictory ? "Victory" : "Setback", color: latest.isVictory ? BMOTheme.success : BMOTheme.warning)
                    }
                    Text(latest.summary)
                        .font(.caption)
                        .foregroundColor(BMOTheme.textSecondary)
                }
            }
        }
        .bmoCard()
    }

    private var tradeBazaarCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trade bazaar")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(BMOTheme.textSecondary)

            Text("Local trading scaffold for the iOS app. Accepting an offer rotates your active buddy and archives the previous one in your collection.")
                .font(.caption)
                .foregroundColor(BMOTheme.textTertiary)

            ForEach(store.tradeOffers) { offer in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(offer.name) • \(offer.archetype.displayName)")
                                .font(.headline)
                                .foregroundColor(BMOTheme.textPrimary)
                            Text(offer.specialty)
                                .font(.caption)
                                .foregroundColor(BMOTheme.textSecondary)
                        }
                        Spacer()
                        Text(offer.asciiArt)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(BMOTheme.accent)
                    }

                    HStack(spacing: 8) {
                        statPill("Bond", value: offer.stats.bond)
                        statPill("Power", value: offer.stats.power)
                        statPill("Focus", value: offer.stats.focus)
                    }

                    Button {
                        store.acceptTrade(offer, from: appState.stackConfig)
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.swap")
                            Text("Accept trade")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(BMOButtonStyle(isPrimary: false))
                }
                .padding(12)
                .background(BMOTheme.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusMedium, style: .continuous))
            }
        }
        .bmoCard()
    }

    private var collectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Collection")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(BMOTheme.textSecondary)
                Spacer()
                Text("\(store.collection.count) buddies")
                    .font(.caption)
                    .foregroundColor(BMOTheme.textTertiary)
            }

            LazyVStack(spacing: 10) {
                ForEach(store.collection) { buddy in
                    HStack(alignment: .top, spacing: 12) {
                        Text(buddy.asciiArt)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(BMOTheme.accent)
                            .padding(8)
                            .background(BMOTheme.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusSmall, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(buddy.name)
                                .font(.subheadline)
                                .foregroundColor(BMOTheme.textPrimary)
                            Text("\(buddy.archetype.displayName) • \(buddy.title)")
                                .font(.caption)
                                .foregroundColor(BMOTheme.textSecondary)
                            Text(buddy.specialty)
                                .font(.caption2)
                                .foregroundColor(BMOTheme.textTertiary)
                        }

                        Spacer()
                    }
                }
            }
        }
        .bmoCard()
    }

    private func statPill(_ label: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(BMOTheme.textTertiary)
            Text("\(value)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(BMOTheme.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(BMOTheme.backgroundSecondary)
        .clipShape(Capsule())
    }

    private func profileRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(BMOTheme.textTertiary)
            Spacer()
            Text(value.isEmpty ? "—" : value)
                .foregroundColor(BMOTheme.textPrimary)
        }
        .font(.caption)
    }

    private func buttonChip(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(label)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(BMOButtonStyle(isPrimary: false))
    }
}

private struct SeededGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0xCAFEF00D : seed
    }

    mutating func next() -> UInt64 {
        state = 6364136223846793005 &* state &+ 1
        return state
    }

    mutating func nextInt(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        return Int(next() % UInt64(upperBound))
    }
}
