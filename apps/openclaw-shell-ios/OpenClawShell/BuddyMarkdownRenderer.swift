import Foundation

enum BuddyMarkdownRenderer {
    static func renderActiveBuddy(
        instance: BuddyInstance,
        template: CouncilStarterBuddyTemplate?,
        contracts: BuddyCanonicalResources,
        events: [BuddyRuntimeEvent],
        now: Date = .now
    ) -> String {
        let bondLabel = bondLabel(for: instance.progression.bond, contracts: contracts)
        let nextLevel = nextLevelProgress(for: instance, contracts: contracts)
        let roleProfile = template.flatMap { contracts.progression.roleProfiles[$0.id] }
        let recent = recentEvents(for: instance, events: events, limit: 4)
        let topProficiencies = topProficiencyLabels(for: instance)

        return """
        # buddy.md

        - Active buddy: \(instance.displayName)
        - Template: \(template?.name ?? "Legacy Buddy")
        - Role: \(instance.identity.class) / \(instance.identity.role)
        - Level: \(instance.progression.level)
        - XP: \(instance.progression.xp)
        - Bond: \(instance.progression.bond)/\(contracts.progression.maxBond) (\(bondLabel))
        - Evolution tier: \(instance.progression.evolutionTier)
        - Mood: \(instance.state.mood.capitalized)
        - Activity mode: \(instance.state.activityMode.capitalized)
        - Current focus: \(instance.state.currentFocus ?? "No active focus")
        - Last active: \(iso8601(instance.state.lastActiveAt))

        ## What changed recently
        \(bulletList(recent.isEmpty ? ["No Buddy events recorded yet."] : recent))

        ## What matters now
        \(bulletList(matterNowLines(instance: instance, roleProfile: roleProfile, nextLevel: nextLevel, topProficiencies: topProficiencies)))

        ## What is stale
        \(bulletList(staleLines(for: instance, now: now)))

        ## Equipped moves
        \(bulletList(instance.equippedMoves.sorted(by: { $0.slot < $1.slot }).map { "Slot \($0.slot): \($0.name) (\($0.category), mastery \($0.mastery))" }))
        """
    }

    static func renderRoster(
        instances: [BuddyInstance],
        activeBuddyInstanceId: String?,
        contracts: BuddyCanonicalResources,
        events: [BuddyRuntimeEvent],
        now: Date = .now
    ) -> String {
        let sections = instances.map { instance -> String in
            let template = contracts.templateForInstance(instance)
            let recent = recentEvents(for: instance, events: events, limit: 2)
            let status = instance.instanceId == activeBuddyInstanceId ? "Active" : (isStale(instance, now: now) ? "Needs attention" : "Installed")
            let bond = bondLabel(for: instance.progression.bond, contracts: contracts)

            return """
            ## \(instance.displayName)

            - Status: \(status)
            - Template: \(template?.name ?? "Legacy Buddy")
            - Role: \(instance.identity.role)
            - Level: \(instance.progression.level)
            - Bond: \(instance.progression.bond)/\(contracts.progression.maxBond) (\(bond))
            - Mood: \(instance.state.mood.capitalized)
            - Focus: \(instance.state.currentFocus ?? "No active focus")
            - Last active: \(iso8601(instance.state.lastActiveAt))
            \(recent.isEmpty ? "- Recent note: No Buddy events recorded yet." : recent.map { "- Recent note: \($0)" }.joined(separator: "\n"))
            """
        }

        return """
        # buddies.md

        - Installed buddies: \(instances.count)
        - Active buddy ID: \(activeBuddyInstanceId ?? "None")
        - Updated: \(iso8601(now))

        \(sections.joined(separator: "\n\n"))
        """
    }

    static func bondLabel(for bond: Int, contracts: BuddyCanonicalResources) -> String {
        let labels = contracts.progression.bondLabels
        let safeIndex = max(0, min(bond, labels.count - 1))
        return labels[safeIndex]
    }

    static func iso8601(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private static func recentEvents(for instance: BuddyInstance, events: [BuddyRuntimeEvent], limit: Int) -> [String] {
        events
            .filter { $0.buddyInstanceId == instance.instanceId }
            .sorted { $0.occurredAt > $1.occurredAt }
            .prefix(limit)
            .map { "\(iso8601($0.occurredAt)): \($0.summary)" }
    }

    private static func matterNowLines(
        instance: BuddyInstance,
        roleProfile: BuddyRoleProfile?,
        nextLevel: (level: Int?, remainingXP: Int?),
        topProficiencies: [String]
    ) -> [String] {
        var lines: [String] = []
        if let level = nextLevel.level, let remainingXP = nextLevel.remainingXP {
            lines.append("Next level: \(level) in \(remainingXP) XP.")
        } else {
            lines.append("Level cap reached for the current BeMore companion wedge.")
        }

        if let challenge = roleProfile?.dailyChallengeHook {
            lines.append("Recommended daily challenge: \(challenge.name) — \(challenge.description)")
        }

        if topProficiencies.isEmpty {
            lines.append("Training profile is still fresh. One guided training session will establish a specialty.")
        } else {
            lines.append("Current strongest proficiencies: \(topProficiencies.joined(separator: ", ")).")
        }

        return lines
    }

    private static func staleLines(for instance: BuddyInstance, now: Date) -> [String] {
        guard isStale(instance, now: now) else {
            return ["No stale Buddy warnings right now."]
        }

        let days = max(1, Calendar.current.dateComponents([.day], from: instance.state.lastActiveAt, to: now).day ?? 1)
        return [
            "Buddy has not been active for \(days) day\(days == 1 ? "" : "s").",
            "Run a check-in or training session before trusting this Buddy as your current primary."
        ]
    }

    private static func isStale(_ instance: BuddyInstance, now: Date) -> Bool {
        let days = Calendar.current.dateComponents([.day], from: instance.state.lastActiveAt, to: now).day ?? 0
        return days >= 3
    }

    private static func nextLevelProgress(
        for instance: BuddyInstance,
        contracts: BuddyCanonicalResources
    ) -> (level: Int?, remainingXP: Int?) {
        let thresholds = contracts.progression.xpThresholds.sorted { $0.level < $1.level }
        guard let next = thresholds.first(where: { $0.level > instance.progression.level }) else {
            return (nil, nil)
        }
        return (next.level, max(0, next.xpRequired - instance.progression.xp))
    }

    private static func topProficiencyLabels(for instance: BuddyInstance) -> [String] {
        let values: [(String, Int)] = [
            ("Planning", instance.proficiencies.planning),
            ("Building", instance.proficiencies.building),
            ("Research", instance.proficiencies.research),
            ("Writing", instance.proficiencies.writing),
            ("Memory", instance.proficiencies.memory),
            ("Organization", instance.proficiencies.organization),
            ("Safety", instance.proficiencies.safety),
            ("Verification", instance.proficiencies.verification),
            ("Optimization", instance.proficiencies.optimization),
            ("Creativity", instance.proficiencies.creativity),
            ("Coordination", instance.proficiencies.coordination),
            ("Emotional Support", instance.proficiencies.emotionalSupport)
        ]

        return values
            .filter { $0.1 > 0 }
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 {
                    return lhs.0 < rhs.0
                }
                return lhs.1 > rhs.1
            }
            .prefix(3)
            .map { "\($0.0) \($0.1)/5" }
    }

    private static func bulletList(_ items: [String]) -> String {
        items.map { "- \($0)" }.joined(separator: "\n")
    }
}
