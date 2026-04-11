import Foundation

struct BuddyStatLine: Codable, Hashable {
    var focus: Int
    var creativity: Int
    var memory: Int
    var speed: Int
    var logic: Int
    var empathy: Int
    var discipline: Int
    var charm: Int

    var total: Int {
        focus + creativity + memory + speed + logic + empathy + discipline + charm
    }
}

struct BuddyMoveTemplate: Identifiable, Codable, Hashable {
    var id: String { name }
    var name: String
    var category: String
    var kind: String
    var effect: String
}

struct BuddyPassiveTemplate: Codable, Hashable {
    var name: String
    var tier2: String
    var tier3Upgrade: String
}

struct BuddyGrowthPathTemplate: Codable, Hashable {
    var tier1: String
    var tier2: String
    var tier3: String

    var stages: [String] { [tier1, tier2, tier3] }
}

struct BuddyASCIITemplate: Codable, Hashable {
    var baseSilhouette: String
    var expressions: [String: String]
    var idleFrames: [String]
    var sharedStates: [String]
    var accents: [String]
    var evolutionVisibleChanges: [String]
}

struct CouncilStarterBuddyTemplate: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var canonicalRole: String
    var starterRole: String
    var onboardingTitle: String
    var onboardingCopy: String
    var stats: BuddyStatLine
    var total: Int
    var moveSet: [BuddyMoveTemplate]
    var passive: BuddyPassiveTemplate
    var growthPath: BuddyGrowthPathTemplate
    var ascii: BuddyASCIITemplate
    var recommendedFor: [String]

    var templateID: String { "starter.\(id).v1" }

    var starterClass: String {
        starterRole
            .split(separator: "/")
            .first
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) } ?? starterRole
    }

    var starterRoleName: String {
        let parts = starterRole
            .split(separator: "/")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        guard parts.count > 1 else { return canonicalRole }
        return parts[1]
    }
}

struct BuddyImplementationGuidance: Codable, Hashable {
    var templates: String
    var initialStats: String
    var moveSets: String
    var classIdentity: String
    var editableName: Bool
    var editableNickname: Bool
    var evolvingAppearance: Bool
    var growthStageProgression: Bool
}

struct BuddyBalanceAdjustment: Codable, Hashable {
    var buddy: String
    var originalTotal: Int
    var adjustedTotal: Int
    var note: String
}

struct BuddyBalanceValidation: Codable, Hashable {
    var id: String
    var total: Int
    var valid: Bool
}

struct BuddyBalanceNotes: Codable, Hashable {
    var targetAverage: Int
    var normalizedAdjustment: BuddyBalanceAdjustment
    var validation: [BuddyBalanceValidation]
}

struct CouncilStarterPack: Codable, Hashable {
    var councilStarterPack: [CouncilStarterBuddyTemplate]
    var starterRecommendations: [String: [String]]
    var helpMeChoose: [String: String]
    var v1ImplementationGuidance: BuddyImplementationGuidance
    var balanceNotes: BuddyBalanceNotes
}

struct BuddyChoiceOption: Codable, Hashable {
    var id: String
    var label: String
    var description: String?
}

struct BuddyPaletteOption: Codable, Hashable {
    var id: String
    var label: String
    var colors: [String]
}

struct BuddyArchetypeOption: Codable, Hashable {
    var id: String
    var label: String
    var family: String
}

struct BuddyJobClassOption: Codable, Hashable {
    var id: String
    var label: String
    var primaryTraining: String
    var secondaryTraining: String
}

struct BuddyActivityModeOption: Codable, Hashable {
    var id: String
    var label: String
    var suggestionFrequency: String
}

struct BuddyPixelCanvasPreset: Codable, Hashable {
    var id: String
    var size: String
}

struct BuddyPixelGenerationOptions: Codable, Hashable {
    var canvasPresets: [BuddyPixelCanvasPreset]
    var defaultCanvas: String
    var transparentBackground: Bool
    var style: String
    var hardRules: [String]
}

struct BuddyCreationDefaults: Codable, Hashable {
    var purpose: String
    var personalityPrimary: String
    var voicePrimary: String
    var archetype: String
    var bodyStyle: String
    var palette: String
    var jobClass: String
    var activityMode: String
    var evolutionStage: Int
    var asciiVariant: String
    var pixelVariant: String?
}

struct BuddyFreeformFieldRule: Codable, Hashable {
    var enabled: Bool
    var required: Bool
    var minLength: Int?
    var maxLength: Int?
    var pattern: String?
}

struct BuddyCreationOptionsCatalog: Codable, Hashable {
    var purposes: [BuddyChoiceOption]
    var personalities: [BuddyChoiceOption]
    var voices: [BuddyChoiceOption]
    var archetypes: [BuddyArchetypeOption]
    var bodyStyles: [BuddyChoiceOption]
    var palettes: [BuddyPaletteOption]
    var jobClasses: [BuddyJobClassOption]
    var activityModes: [BuddyActivityModeOption]
    var moods: [BuddyChoiceOption]
    var pixelGeneration: BuddyPixelGenerationOptions
}

struct BuddyCompatibilityRule: Codable, Hashable {
    var `if`: [String: String]
    var preferredBodyStyles: [String]?
    var suggestedPalettes: [String]?
}

struct BuddyStartingMoveComposition: Codable, Hashable {
    var signature: Int
    var utility: Int
    var universal: Int
}

struct BuddyStarterLoadoutRules: Codable, Hashable {
    var statsStrategy: String
    var startingMoveCount: Int
    var moveComposition: BuddyStartingMoveComposition
    var startingBond: Int
    var startingLevel: Int
    var startingEvolutionStage: Int
}

struct BuddyQuizAnswer: Codable, Hashable {
    var id: String
    var label: String
}

struct BuddyQuizPrompt: Codable, Hashable {
    var id: String
    var question: String
    var answers: [BuddyQuizAnswer]
}

struct BuddyRecommendationQuiz: Codable, Hashable {
    var promptSet: [BuddyQuizPrompt]
}

struct BuddySelectionRules: Codable, Hashable {
    var personalityPrimaryCount: Int
    var personalitySecondaryCount: Int
    var voicePrimaryCount: Int
    var voiceSecondaryCount: Int
    var allowDuplicatePrimarySecondary: Bool
    var freeformOnlyFor: [String]
    var defaultPresetCount: Int
    var useGuidedSelectionsFirst: Bool
}

struct BuddyCreationOptions: Codable, Hashable {
    var version: String
    var description: String
    var defaults: BuddyCreationDefaults
    var freeformFields: [String: BuddyFreeformFieldRule]
    var options: BuddyCreationOptionsCatalog
    var selectionRules: BuddySelectionRules
    var compatibilityRules: [BuddyCompatibilityRule]
    var starterLoadoutRules: BuddyStarterLoadoutRules
    var recommendationQuiz: BuddyRecommendationQuiz
}

struct BuddyXPThreshold: Codable, Hashable {
    var level: Int
    var xpRequired: Int
}

struct BuddyEvolutionRequirementSet: Codable, Hashable {
    var minLevel: Int?
    var minBond: Int?
    var minRoleTrainingSessions: Int?
    var minDailyChallengesCompleted: Int?
    var minRealTasksCompleted: Int?
    var requiresAdvancedRoleChallenge: Bool?
    var minPrimarySkillProficiency: Int?
    var requiredActiveStreakDays: Int?
}

struct BuddyEvolutionRule: Codable, Hashable {
    var targetTier: Int
    var requirements: BuddyEvolutionRequirementSet
}

struct BuddyAntiGrindConfig: Codable, Hashable {
    var dailySoftCapXp: Int
    var repetitionPenaltyCurve: [Double]
    var diversityBonusEnabled: Bool
}

struct BuddyXPRewardBuckets: Codable, Hashable {
    var small: Int?
    var medium: Int?
    var large: Int?
    var basic: Int?
    var advanced: Int?
    var completion: Int?
    var highScore: Int?
}

struct BuddyXPRewardConfig: Codable, Hashable {
    var realTask: BuddyXPRewardBuckets
    var training: BuddyXPRewardBuckets
    var dailyChallenge: BuddyXPRewardBuckets
}

struct BuddyDailyChallengeHook: Codable, Hashable {
    var name: String
    var description: String
    var bonusCondition: String
}

struct BuddyRoleProfile: Codable, Hashable {
    var primaryTrainingCategory: String
    var secondaryTrainingCategory: String
    var growthBonus: String
    var dailyChallengeHook: BuddyDailyChallengeHook
}

struct BuddyUnlockCadence: Codable, Hashable {
    var adoption: [String]
    var level3: [String]
    var tier2: [String]
    var level7: [String]
    var tier3: [String]
}

struct BuddyProgressionConfig: Codable, Hashable {
    var schemaVersion: String
    var starterPackSource: String
    var maxLevel: Int
    var maxBond: Int
    var maxSkillProficiency: Int
    var xpThresholds: [BuddyXPThreshold]
    var trainingCategories: [String]
    var bondLabels: [String]
    var xpRewards: BuddyXPRewardConfig
    var evolutionRules: [BuddyEvolutionRule]
    var antiGrind: BuddyAntiGrindConfig
    var starterRecommendations: [String: [String]]
    var helpMeChoose: [String: String]
    var roleProfiles: [String: BuddyRoleProfile]
    var v1UnlockCadence: BuddyUnlockCadence
}

struct BuddyRuntimeEventType: Codable, Hashable {
    var type: String
    var description: String
    var actor: String
    var payloadSchemaRef: String
    var allowedEffects: [String]
}

struct BuddyRuntimeEventProcessingRules: Codable, Hashable {
    var idempotencyKeyRequiredForExternalSources: Bool
    var receiptRequiredForClaimedPersistence: Bool
    var stateTransitionsMustValidateAgainstStateMachine: Bool
    var xpAndBondMustRespectDailySoftCaps: Bool
    var memoryPromotionRequiresEvidence: Bool
    var templateInstallMustCreateCleanDerivedCopy: Bool
}

struct BuddyRuntimeEventCatalog: Codable, Hashable {
    var version: String
    var kind: String
    var description: String
    var eventTypes: [BuddyRuntimeEventType]
    var commonEffectFields: [String: String]
    var processingRules: BuddyRuntimeEventProcessingRules
}

struct BuddyStateMachineState: Codable, Hashable {
    var description: String?
    var allowedTransitions: [String]
}

struct BuddyNamedStateDomain: Codable, Hashable {
    var initial: String
    var states: [String: BuddyStateMachineState]
    var guards: [String: [String]]?
    var triggers: [String: String]?
    var guarantees: [String]?
    var alwaysStrip: [String]?
}

struct BuddyTierDefinition: Codable, Hashable {
    var name: String
    var label: String
    var unlockConditions: [String]
    var effects: [String]?
}

struct BuddyLevelUpRules: Codable, Hashable {
    var primaryStatGrowth: String
    var secondaryStatGrowth: String
    var trainingFlexGrowth: String
}

struct BuddyStateMachineProgressionDomain: Codable, Hashable {
    var levelCap: Int
    var xpThresholds: [String: Int]
    var tiers: [String: BuddyTierDefinition]
    var levelUpRules: BuddyLevelUpRules
}

struct BuddyBondRules: Codable, Hashable {
    var spamProtection: Bool
    var dailySoftCap: Int
    var requiresMeaningfulVariety: Bool
}

struct BuddyStateMachineBondDomain: Codable, Hashable {
    var min: Int
    var max: Int
    var labels: [String: String]
    var sources: [String: Int]
    var rules: BuddyBondRules
}

struct BuddyTrainingAntiGrind: Codable, Hashable {
    var dailyLowValueXpSoftCap: Int
    var repetitionDecay: [Double]
    var diversityBonusEnabled: Bool
}

struct BuddyTrainingDomain: Codable, Hashable {
    var categories: [String]
    var sessionStates: [String: [String]]
    var xpRewards: [String: Int]
    var antiGrind: BuddyTrainingAntiGrind
}

struct BuddyUnlockRules: Codable, Hashable {
    var moveUpgradeAtLevel: Int
    var roleMoveVariantAtLevel: Int
    var passiveUnlockTier: Int
    var signatureUpgradeTier: Int
}

struct BuddyForbiddenTransition: Codable, Hashable {
    var from: String
    var to: String
    var reason: String
}

struct BuddyStateMachineDomains: Codable, Hashable {
    var lifecycle: BuddyNamedStateDomain
    var mood: BuddyNamedStateDomain
    var activityMode: BuddyNamedStateDomain
    var progression: BuddyStateMachineProgressionDomain
    var bond: BuddyStateMachineBondDomain
    var installFlow: BuddyNamedStateDomain
    var publishFlow: BuddyNamedStateDomain
    var training: BuddyTrainingDomain
    var unlocks: BuddyUnlockRules
    var forbiddenTransitions: [BuddyForbiddenTransition]
}

struct BuddyStateMachine: Codable, Hashable {
    var schema: String?
    var version: String
    var id: String
    var description: String
    var domains: BuddyStateMachineDomains

    enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case version
        case id
        case description
        case domains
    }
}

struct BuddyIdentity: Codable, Hashable {
    var `class`: String
    var role: String
    var personalityPrimary: String
    var personalitySecondary: String?
    var voicePrimary: String
    var voiceSecondary: String?
    var archetype: String
    var bodyStyle: String
    var palette: String
}

struct BuddyProgressionState: Codable, Hashable {
    var level: Int
    var xp: Int
    var bond: Int
    var evolutionTier: Int
    var growthStageLabel: String
    var badges: [String]
    var streakDays: Int
    var passiveUnlocked: Bool
    var signatureUpgradeUnlocked: Bool
}

struct BuddyStateSnapshot: Codable, Hashable {
    var mood: String
    var energy: Int
    var activityMode: String
    var lastActiveAt: Date
    var currentFocus: String?
    var favoriteTasks: [String]
}

struct BuddyEquippedMove: Identifiable, Codable, Hashable {
    var id: String { "\(slot)-\(name)" }
    var name: String
    var category: String
    var kind: String
    var slot: Int
    var mastery: Int
}

struct BuddyProficiencies: Codable, Hashable {
    var planning: Int
    var building: Int
    var research: Int
    var writing: Int
    var memory: Int
    var organization: Int
    var safety: Int
    var verification: Int
    var optimization: Int
    var creativity: Int
    var coordination: Int
    var emotionalSupport: Int

    static let zero = BuddyProficiencies(
        planning: 0,
        building: 0,
        research: 0,
        writing: 0,
        memory: 0,
        organization: 0,
        safety: 0,
        verification: 0,
        optimization: 0,
        creativity: 0,
        coordination: 0,
        emotionalSupport: 0
    )

    func value(for category: String) -> Int {
        switch Self.normalized(category) {
        case "planning": return planning
        case "building": return building
        case "research": return research
        case "writing": return writing
        case "memory": return memory
        case "organization": return organization
        case "safety": return safety
        case "verification": return verification
        case "optimization": return optimization
        case "creativity": return creativity
        case "coordination": return coordination
        case "emotionalsupport": return emotionalSupport
        default: return 0
        }
    }

    mutating func increment(category: String, by delta: Int = 1, cap: Int) {
        switch Self.normalized(category) {
        case "planning": planning = min(cap, planning + delta)
        case "building": building = min(cap, building + delta)
        case "research": research = min(cap, research + delta)
        case "writing": writing = min(cap, writing + delta)
        case "memory": memory = min(cap, memory + delta)
        case "organization": organization = min(cap, organization + delta)
        case "safety": safety = min(cap, safety + delta)
        case "verification": verification = min(cap, verification + delta)
        case "optimization": optimization = min(cap, optimization + delta)
        case "creativity": creativity = min(cap, creativity + delta)
        case "coordination": coordination = min(cap, coordination + delta)
        case "emotionalsupport": emotionalSupport = min(cap, emotionalSupport + delta)
        default: break
        }
    }

    private static func normalized(_ category: String) -> String {
        category
            .lowercased()
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
}

struct BuddyProvenance: Codable, Hashable {
    var installedFrom: String
    var derivedFromTemplate: Bool
    var sanitizedSource: Bool
    var creatorId: String?
    var installedAt: Date
}

struct BuddyMemoryBindings: Codable, Hashable {
    var buddyFile: String
    var userFile: String
    var memoryFile: String
    var sessionFile: String
    var skillsFile: String?
    var lastStateSyncAt: Date?
}

struct BuddyVisualState: Codable, Hashable {
    var asciiVariantId: String?
    var pixelVariantId: String?
    var currentAnimationState: String?
    var evolutionCosmetics: [String]
}

struct BuddyTrainingRecord: Identifiable, Codable, Hashable {
    var id: String
    var category: String
    var xpAwarded: Int
    var bondDelta: Int
    var completedAt: Date
    var source: String
}

struct BuddyInstance: Identifiable, Codable, Hashable {
    var id: String { instanceId }
    var instanceId: String
    var templateId: String
    var displayName: String
    var nickname: String?
    var identity: BuddyIdentity
    var progression: BuddyProgressionState
    var state: BuddyStateSnapshot
    var equippedMoves: [BuddyEquippedMove]
    var proficiencies: BuddyProficiencies
    var provenance: BuddyProvenance
    var memory: BuddyMemoryBindings
    var visual: BuddyVisualState?
    var trainingHistory: [BuddyTrainingRecord]
}

struct BuddyLibraryState: Codable, Hashable {
    var version: String = "1.0.0"
    var activeBuddyInstanceId: String?
    var instances: [BuddyInstance] = []
    var lastUpdatedAt: Date = .now

    var activeBuddy: BuddyInstance? {
        guard let activeBuddyInstanceId else { return nil }
        return instances.first(where: { $0.instanceId == activeBuddyInstanceId })
    }
}

struct BuddyRuntimeEventEffects: Codable, Hashable {
    var xpDelta: Int?
    var bondDelta: Int?
    var proficiencyDeltas: [String: Int]?
    var moodTarget: String?
    var stateTransition: String?
    var memoryPromotion: String?
    var badgeGrant: String?
    var passiveUnlock: String?
    var signatureUpgrade: String?
    var receiptRef: String?
    var sanitationReport: String?
}

struct BuddyRuntimeEvent: Identifiable, Codable, Hashable {
    var id: String
    var type: String
    var buddyInstanceId: String
    var buddyDisplayName: String
    var actor: String
    var occurredAt: Date
    var summary: String
    var payload: [String: String]
    var effects: BuddyRuntimeEventEffects
}

struct BuddyRuntimeEventLog: Codable, Hashable {
    var version: String = "1.0.0"
    var events: [BuddyRuntimeEvent] = []
}

struct BuddyIdentityPreset {
    var personalityPrimary: String
    var personalitySecondary: String?
    var voicePrimary: String
    var voiceSecondary: String?
    var archetype: String
    var bodyStyle: String
    var palette: String
}

enum CouncilBuddyIdentityCatalog {
    private static let presets: [String: BuddyIdentityPreset] = [
        "bmo": .init(personalityPrimary: "Cheerful", personalitySecondary: "Loyal", voicePrimary: "Friendly", voiceSecondary: "Cozy", archetype: "robot", bodyStyle: "compact", palette: "mint_cream"),
        "prismo": .init(personalityPrimary: "Wise", personalitySecondary: "Focused", voicePrimary: "Confident", voiceSecondary: "Direct", archetype: "companion_orb", bodyStyle: "floaty", palette: "sky_navy"),
        "neptr": .init(personalityPrimary: "Focused", personalitySecondary: "Protective", voicePrimary: "Professional", voiceSecondary: "Direct", archetype: "robot", bodyStyle: "mechanical", palette: "black_neon"),
        "princess-bubblegum": .init(personalityPrimary: "Wise", personalitySecondary: "Focused", voicePrimary: "Professional", voiceSecondary: "Smart", archetype: "companion_orb", bodyStyle: "tall", palette: "rose_white"),
        "finn": .init(personalityPrimary: "Energetic", personalitySecondary: "Loyal", voicePrimary: "Uplifting", voiceSecondary: "Direct", archetype: "dino", bodyStyle: "compact", palette: "yellow_cocoa"),
        "jake": .init(personalityPrimary: "Playful", personalitySecondary: "Calm", voicePrimary: "Friendly", voiceSecondary: "Cozy", archetype: "slime", bodyStyle: "round", palette: "peach_brown"),
        "marceline": .init(personalityPrimary: "Curious", personalitySecondary: "Playful", voicePrimary: "Confident", voiceSecondary: "Mischievous", archetype: "spirit", bodyStyle: "tall", palette: "black_neon"),
        "simon": .init(personalityPrimary: "Wise", personalitySecondary: "Gentle", voicePrimary: "Soft", voiceSecondary: "Smart", archetype: "mini_wizard", bodyStyle: "tall", palette: "sky_navy"),
        "peppermint-butler": .init(personalityPrimary: "Protective", personalitySecondary: "Focused", voicePrimary: "Professional", voiceSecondary: "Mischievous", archetype: "tiny_monster", bodyStyle: "angular", palette: "black_neon"),
        "lady-rainicorn": .init(personalityPrimary: "Calm", personalitySecondary: "Loyal", voicePrimary: "Soft", voiceSecondary: "Uplifting", archetype: "spirit", bodyStyle: "floaty", palette: "aqua_teal"),
        "lemongrab": .init(personalityPrimary: "Focused", personalitySecondary: "Protective", voicePrimary: "Direct", voiceSecondary: "Professional", archetype: "tiny_monster", bodyStyle: "angular", palette: "yellow_cocoa"),
        "flame-princess": .init(personalityPrimary: "Energetic", personalitySecondary: "Focused", voicePrimary: "Confident", voiceSecondary: "Direct", archetype: "spirit", bodyStyle: "angular", palette: "red_charcoal")
    ]

    static func identity(for template: CouncilStarterBuddyTemplate) -> BuddyIdentity {
        let preset = presets[template.id] ?? BuddyIdentityPreset(
            personalityPrimary: "Cheerful",
            personalitySecondary: nil,
            voicePrimary: "Friendly",
            voiceSecondary: nil,
            archetype: "console_pet",
            bodyStyle: "compact",
            palette: "mint_cream"
        )

        return BuddyIdentity(
            class: template.starterClass,
            role: template.starterRoleName,
            personalityPrimary: preset.personalityPrimary,
            personalitySecondary: preset.personalitySecondary,
            voicePrimary: preset.voicePrimary,
            voiceSecondary: preset.voiceSecondary,
            archetype: preset.archetype,
            bodyStyle: preset.bodyStyle,
            palette: preset.palette
        )
    }
}
