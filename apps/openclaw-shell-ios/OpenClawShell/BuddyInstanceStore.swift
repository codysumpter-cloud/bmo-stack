import Foundation

struct BuddyInstanceStore {
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // Tolerant decoder for legacy JSON that may use either ISO 8601 strings or
    // numeric timestamps (seconds since Apple reference date, the JSONEncoder default).
    private let legacyDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let str = try? container.decode(String.self) {
                let iso = ISO8601DateFormatter()
                if let date = iso.date(from: str) { return date }
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot parse date string: \(str)"
                )
            }
            // JSONEncoder default: Double seconds since Jan 1 2001 (Apple reference date)
            let seconds = try container.decode(Double.self)
            return Date(timeIntervalSinceReferenceDate: seconds)
        }
        return decoder
    }()

    var libraryStateURL: URL {
        Paths.stateDirectory.appendingPathComponent("buddy-instances.json")
    }

    var eventLogURL: URL {
        Paths.openClawDirectory.appendingPathComponent("state/buddy-runtime-events.json")
    }

    private var legacyStateURL: URL {
        Paths.stateDirectory.appendingPathComponent("buddy-system.json")
    }

    func loadLibraryState() -> BuddyLibraryState? {
        guard let data = try? Data(contentsOf: libraryStateURL) else { return nil }
        return try? decoder.decode(BuddyLibraryState.self, from: data)
    }

    func loadEventLog() -> BuddyRuntimeEventLog? {
        guard let data = try? Data(contentsOf: eventLogURL) else { return nil }
        return try? decoder.decode(BuddyRuntimeEventLog.self, from: data)
    }

    func persistLibraryState(_ state: BuddyLibraryState) throws {
        let data = try encoder.encode(state)
        try FileManager.default.createDirectory(at: libraryStateURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: libraryStateURL, options: [.atomic])
    }

    func migrateLegacyState(contracts: BuddyCanonicalResources) -> BuddyLibraryState? {
        guard let data = try? Data(contentsOf: legacyStateURL),
              let legacy = try? legacyDecoder.decode(LegacyBuddySystemState.self, from: data) else {
            return nil
        }

        var instances: [BuddyInstance] = []
        instances.append(migrateLegacyBuddy(legacy.activeBuddy, contracts: contracts))

        for buddy in legacy.collection {
            let migrated = migrateLegacyBuddy(buddy, contracts: contracts)
            if instances.contains(where: { $0.displayName == migrated.displayName }) == false {
                instances.append(migrated)
            }
        }

        let activeID = instances.first?.instanceId
        return BuddyLibraryState(
            version: "1.0.0",
            activeBuddyInstanceId: activeID,
            instances: instances.sorted { $0.provenance.installedAt > $1.provenance.installedAt },
            lastUpdatedAt: instances.map { $0.provenance.installedAt }.max() ?? .now
        )
    }

    private func migrateLegacyBuddy(_ legacy: LegacyGeneratedBuddy, contracts: BuddyCanonicalResources) -> BuddyInstance {
        let fallbackTemplate = contracts.templates.first(where: { $0.id == "bmo" }) ?? contracts.templates.first
        let identity = fallbackTemplate.map { CouncilBuddyIdentityCatalog.identity(for: $0) } ?? BuddyIdentity(
            class: "Legacy",
            role: legacy.title,
            personalityPrimary: "Cheerful",
            personalitySecondary: nil,
            voicePrimary: "Friendly",
            voiceSecondary: nil,
            archetype: "console_pet",
            bodyStyle: "compact",
            palette: "mint_cream"
        )
        let installedAt = legacy.createdAt
        let bond = max(1, min(contracts.progression.maxBond, legacy.stats.bond / 10))

        return BuddyInstance(
            instanceId: "legacy_\(legacy.id.uuidString.lowercased())",
            templateId: "legacy.generated.v1",
            displayName: legacy.name,
            nickname: nil,
            identity: BuddyIdentity(
                class: identity.class,
                role: legacy.title,
                personalityPrimary: identity.personalityPrimary,
                personalitySecondary: identity.personalitySecondary,
                voicePrimary: identity.voicePrimary,
                voiceSecondary: identity.voiceSecondary,
                archetype: legacy.archetype,
                bodyStyle: identity.bodyStyle,
                palette: identity.palette
            ),
            progression: BuddyProgressionState(
                level: 1,
                xp: 0,
                bond: bond,
                evolutionTier: 1,
                growthStageLabel: "Legacy",
                badges: ["legacy_migrated"],
                streakDays: 0,
                passiveUnlocked: false,
                signatureUpgradeUnlocked: false
            ),
            state: BuddyStateSnapshot(
                mood: "neutral",
                energy: 75,
                activityMode: "balanced",
                lastActiveAt: installedAt,
                currentFocus: legacy.specialty,
                favoriteTasks: []
            ),
            equippedMoves: [
                BuddyEquippedMove(name: "Carry Forward", category: "Recovery", kind: "signature", slot: 1, mastery: 1),
                BuddyEquippedMove(name: "Fresh Start", category: "Support", kind: "utility", slot: 2, mastery: 0),
                BuddyEquippedMove(name: "Keep Signal", category: "Utility", kind: "utility", slot: 3, mastery: 0),
                BuddyEquippedMove(name: "Open Claw", category: "Attack", kind: "universal", slot: 4, mastery: 0)
            ],
            proficiencies: .zero,
            provenance: BuddyProvenance(
                installedFrom: "custom_creation",
                derivedFromTemplate: false,
                sanitizedSource: true,
                creatorId: nil,
                installedAt: installedAt
            ),
            memory: BuddyMemoryBindings(
                buddyFile: ".openclaw/buddy.md",
                userFile: ".openclaw/user.md",
                memoryFile: ".openclaw/memory.md",
                sessionFile: ".openclaw/session.md",
                skillsFile: ".openclaw/skills.md",
                lastStateSyncAt: installedAt
            ),
            visual: BuddyVisualState(
                asciiVariantId: nil,
                pixelVariantId: nil,
                currentAnimationState: "neutral",
                evolutionCosmetics: []
            ),
            trainingHistory: []
        )
    }
}

@MainActor
final class BuddyProfileStore: ObservableObject {
    @Published private(set) var contracts: BuddyCanonicalResources?
    @Published private(set) var libraryState = BuddyLibraryState()
    @Published private(set) var eventLog = BuddyRuntimeEventLog()
    @Published private(set) var lastReceipt: OpenClawReceipt?
    @Published private(set) var loadError: String?
    @Published var selectedTrainingCategory: String = "Planning"

    private let store = BuddyInstanceStore()

    var templates: [CouncilStarterBuddyTemplate] {
        contracts?.templates ?? []
    }

    var activeBuddy: BuddyInstance? {
        libraryState.activeBuddy
    }

    var installedBuddies: [BuddyInstance] {
        libraryState.instances
    }

    func recentEvents(for instance: BuddyInstance?, limit: Int = 6) -> [BuddyRuntimeEvent] {
        guard let instance else { return [] }
        return eventLog.events
            .filter { $0.buddyInstanceId == instance.instanceId }
            .sorted { $0.occurredAt > $1.occurredAt }
            .prefix(limit)
            .map { $0 }
    }

    func load(for _: StackConfig) {
        do {
            let contracts = try BuddyContractLoader.loadCanonicalResources()
            self.contracts = contracts
            if let existing = store.loadLibraryState() {
                libraryState = existing
            } else if let migrated = store.migrateLegacyState(contracts: contracts) {
                libraryState = migrated
                // Persist immediately so migration doesn't re-run on every launch.
                try store.persistLibraryState(migrated)
            } else {
                libraryState = BuddyLibraryState()
            }
            eventLog = store.loadEventLog() ?? BuddyRuntimeEventLog()
            if libraryState.activeBuddyInstanceId == nil {
                libraryState.activeBuddyInstanceId = libraryState.instances.first?.instanceId
            }
            selectedTrainingCategory = contracts.progression.trainingCategories.first ?? "Planning"
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    func install(template: CouncilStarterBuddyTemplate, using appState: AppState) {
        mutate(using: appState) { contracts in
            try BuddyEventEngine(contracts: contracts).install(
                templateID: template.id,
                currentState: libraryState,
                currentEvents: eventLog
            )
        }
    }

    func personalizeActive(displayName: String, nickname: String?, currentFocus: String?, using appState: AppState) {
        guard let activeBuddy else { return }
        mutate(using: appState) { contracts in
            try BuddyEventEngine(contracts: contracts).personalize(
                instanceID: activeBuddy.instanceId,
                displayName: displayName,
                nickname: nickname,
                currentFocus: currentFocus,
                currentState: libraryState,
                currentEvents: eventLog
            )
        }
    }

    func makeActive(_ instance: BuddyInstance, using appState: AppState) {
        mutate(using: appState) { contracts in
            try BuddyEventEngine(contracts: contracts).makeActive(
                instanceID: instance.instanceId,
                currentState: libraryState,
                currentEvents: eventLog
            )
        }
    }

    func recordCheckIn(note: String?, using appState: AppState) {
        guard let activeBuddy else { return }
        mutate(using: appState) { contracts in
            try BuddyEventEngine(contracts: contracts).recordCheckIn(
                instanceID: activeBuddy.instanceId,
                note: note,
                currentState: libraryState,
                currentEvents: eventLog
            )
        }
    }

    func recordTraining(note: String?, using appState: AppState) {
        guard let activeBuddy else { return }
        mutate(using: appState) { contracts in
            try BuddyEventEngine(contracts: contracts).recordTraining(
                instanceID: activeBuddy.instanceId,
                category: selectedTrainingCategory,
                note: note,
                currentState: libraryState,
                currentEvents: eventLog
            )
        }
    }

    private func mutate(using appState: AppState, operation: (BuddyCanonicalResources) throws -> BuddyPersistenceBundle) {
        guard let contracts else {
            loadError = "Buddy contracts are not loaded yet."
            return
        }

        do {
            let bundle = try operation(contracts)
            let receipt = appState.persistBuddyBundle(bundle)
            lastReceipt = receipt
            if receipt.status == .persisted {
                libraryState = bundle.libraryState
                eventLog = bundle.eventLog
                loadError = nil
            } else {
                loadError = receipt.error ?? receipt.summary
            }
        } catch {
            loadError = error.localizedDescription
        }
    }
}

private struct LegacyBuddyStats: Codable {
    var bond: Int
    var power: Int
    var focus: Int
    var curiosity: Int
    var care: Int
}

private struct LegacyGeneratedBuddy: Codable {
    var id: UUID
    var seed: Int
    var profileSignature: String
    var name: String
    var archetype: String
    var title: String
    var originSummary: String
    var specialty: String
    var personalitySummary: String
    var asciiArt: String
    var stats: LegacyBuddyStats
    var createdAt: Date
}

private struct LegacyBuddyBattleRecord: Codable {
    var id: UUID
    var title: String
    var summary: String
    var isVictory: Bool
    var createdAt: Date
}

private struct LegacyBuddySystemState: Codable {
    var profileSignature: String
    var activeBuddy: LegacyGeneratedBuddy
    var collection: [LegacyGeneratedBuddy]
    var tradeOffers: [LegacyGeneratedBuddy]
    var battleHistory: [LegacyBuddyBattleRecord]
}
