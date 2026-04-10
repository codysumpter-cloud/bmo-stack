import Foundation
import SwiftUI

// MARK: - Action receipts

enum OpenClawActionStatus: String, Codable, CaseIterable, Hashable {
    case planned
    case queued
    case running
    case completed
    case failed
    case persisted

    var label: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .planned, .queued: return BMOTheme.warning
        case .running: return BMOTheme.accent
        case .completed, .persisted: return BMOTheme.success
        case .failed: return BMOTheme.error
        }
    }
}

enum OpenClawActionKind: String, Codable, CaseIterable, Hashable {
    case skillRun = "skill.run"
    case artifactRegenerate = "artifact.regenerate"
    case memoryRefresh = "memory.refresh"
    case sandboxRun = "sandbox.run"
    case workspaceWrite = "workspace.write"
    case workspaceRead = "workspace.read"
}

struct OpenClawActionRecord: Identifiable, Codable, Hashable {
    var id: UUID
    var kind: OpenClawActionKind
    var source: String
    var title: String
    var status: OpenClawActionStatus
    var createdAt: Date
    var updatedAt: Date
    var input: [String: String]
    var output: [String: String]
    var error: String?
    var artifacts: [String]
    var logs: [String]
}

struct OpenClawReceipt: Identifiable, Codable, Hashable {
    var id: UUID { actionId }
    var actionId: UUID
    var status: OpenClawActionStatus
    var title: String
    var summary: String
    var output: [String: String]
    var artifacts: [String]
    var logs: [String]
    var error: String?
}

enum ReceiptFormatter {
    static func confirmedSummary(for receipt: OpenClawReceipt) -> String {
        switch receipt.status {
        case .persisted:
            let artifacts = receipt.artifacts.isEmpty ? "" : " Artifacts: \(receipt.artifacts.joined(separator: ", "))."
            return "Persisted: \(receipt.summary).\(artifacts)"
        case .completed:
            return "Completed: \(receipt.summary)."
        case .failed:
            return "Failed: \(receipt.error ?? receipt.summary)."
        case .planned:
            return "Planned: \(receipt.summary)."
        case .queued:
            return "Queued: \(receipt.summary)."
        case .running:
            return "Running: \(receipt.summary)."
        }
    }
}

// MARK: - Artifacts

struct OpenClawArtifactMetadata: Identifiable, Codable, Hashable {
    enum Freshness: String, Codable, Hashable {
        case fresh
        case stale
        case missing
    }

    var id: String { path }
    var path: String
    var kind: String
    var updatedAt: Date?
    var size: Int
    var freshness: Freshness
}

struct OpenClawEventRecord: Codable, Hashable {
    var id: UUID = UUID()
    var type: String
    var message: String
    var createdAt: Date = .now
    var metadata: [String: String] = [:]
}

// MARK: - Skills

struct SkillManifest: Identifiable, Codable, Hashable {
    struct UIMetadata: Codable, Hashable {
        var route: String
        var systemImage: String
        var accent: String
    }

    var id: String
    var name: String
    var description: String
    var version: String
    var category: String
    var tags: [String]
    var permissions: [String]
    var inputSchema: [String: String]
    var outputSchema: [String: String]
    var ui: UIMetadata
    var entrypoint: String
    var enabled: Bool
}

struct PokemonTeamMember: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var role: String
    var notes: String
}

struct PokemonTeamOutput: Codable, Hashable {
    var teamMembers: [PokemonTeamMember]
    var roleBreakdown: [String]
    var summary: String
    var weaknesses: [String]
    var suggestions: [String]
    var artifactPath: String?
}

enum BuiltInSkillRegistry {
    static let pokemonTeamBuilderID = "pokemon-team-builder"
    static let artifactRebuilderID = "artifact-rebuilder"
    static let memoryInspectorID = "memory-inspector"

    static var manifests: [SkillManifest] {
        [
            SkillManifest(
                id: pokemonTeamBuilderID,
                name: "Pokemon Team Builder",
                description: "Draft, analyze, save, and export structured Pokemon teams as OpenClaw artifacts.",
                version: "1.0.0",
                category: "Games",
                tags: ["pokemon", "team-builder", "strategy"],
                permissions: ["workspace.write", "workspace.read", "actions.write"],
                inputSchema: [
                    "format": "string",
                    "strategy": "string",
                    "mustInclude": "comma-separated string",
                    "avoid": "comma-separated string"
                ],
                outputSchema: [
                    "teamMembers": "array",
                    "summary": "string",
                    "artifactPath": "string"
                ],
                ui: .init(route: "/skills/pokemon-team-builder", systemImage: "gamecontroller.fill", accent: "accent"),
                entrypoint: "builtin.pokemonTeamBuilder",
                enabled: true
            ),
            SkillManifest(
                id: artifactRebuilderID,
                name: "Artifact Rebuilder",
                description: "Regenerate canonical soul, user, memory, session, and skills artifacts from current OpenClaw state.",
                version: "1.0.0",
                category: "System",
                tags: ["artifacts", "memory", "workspace"],
                permissions: ["workspace.write", "state.read", "actions.write"],
                inputSchema: ["target": "all or artifact path"],
                outputSchema: ["paths": "array"],
                ui: .init(route: "/skills/artifact-rebuilder", systemImage: "arrow.triangle.2.circlepath", accent: "accent"),
                entrypoint: "builtin.artifactRebuilder",
                enabled: true
            ),
            SkillManifest(
                id: memoryInspectorID,
                name: "Memory Inspector",
                description: "Read current facts, preferences, session state, and recent memory-derived changes.",
                version: "1.0.0",
                category: "System",
                tags: ["memory", "facts", "session"],
                permissions: ["state.read", "workspace.read"],
                inputSchema: [:],
                outputSchema: ["summary": "string"],
                ui: .init(route: "/skills/memory-inspector", systemImage: "brain.head.profile", accent: "accent"),
                entrypoint: "builtin.memoryInspector",
                enabled: true
            )
        ]
    }
}

// MARK: - Workspace Runtime

@MainActor
final class OpenClawWorkspaceRuntime: ObservableObject {
    @Published private(set) var skills: [SkillManifest] = []
    @Published private(set) var artifacts: [OpenClawArtifactMetadata] = []
    @Published private(set) var recentActions: [OpenClawActionRecord] = []
    @Published private(set) var recentEvents: [OpenClawEventRecord] = []
    @Published var lastError: String?

    private let fileManager = FileManager.default
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

    var rootURL: URL { Paths.openClawDirectory }
    var isBootstrapped: Bool { fileManager.fileExists(atPath: rootURL.appendingPathComponent("soul.md").path) }

    func bootstrap(config: StackConfig, preferences: UserPreferences, routeSummary: String) {
        ensureWorkspaceTree()
        skills = BuiltInSkillRegistry.manifests
        writeJSON(skills, to: rootURL.appendingPathComponent("registry/skills.json"))
        ensureStateStores(config: config, preferences: preferences, routeSummary: routeSummary)
        regenerateCanonicalArtifactsIfMissing(config: config, preferences: preferences, routeSummary: routeSummary)
        refreshMetadata()
        appendEvent(type: "workspace.bootstrapped", message: "OpenClaw workspace runtime bootstrapped.")
    }

    func readFile(_ path: String) throws -> String {
        let url = try resolve(path)
        return try String(contentsOf: url, encoding: .utf8)
    }

    func writeFile(_ path: String, content: String, source: String = "runtime") throws -> OpenClawReceipt {
        let action = begin(kind: .workspaceWrite, source: source, title: "Write \(path)", input: ["path": path])
        do {
            let url = try resolve(path)
            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try content.write(to: url, atomically: true, encoding: .utf8)
            appendEvent(type: "artifact.written", message: "Wrote \(path).", metadata: ["path": path])
            return finish(action, status: .persisted, summary: "Wrote \(path)", output: ["path": path], artifacts: [path])
        } catch {
            return finish(action, status: .failed, summary: "Could not write \(path)", error: error.localizedDescription)
        }
    }

    func listFiles(_ path: String = "") -> [String] {
        let start = (try? resolve(path)) ?? rootURL
        guard let enumerator = fileManager.enumerator(at: start, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else {
            return []
        }
        return enumerator.compactMap { item in
            guard let url = item as? URL else { return nil }
            let values = try? url.resourceValues(forKeys: [.isRegularFileKey])
            guard values?.isRegularFile == true else { return nil }
            return relativePath(for: url)
        }.sorted()
    }

    func regenerateArtifacts(target: String = "all", config: StackConfig, preferences: UserPreferences, routeSummary: String, source: String = "runtime") -> OpenClawReceipt {
        let action = begin(kind: .artifactRegenerate, source: source, title: "Regenerate artifacts", input: ["target": target])
        let targets = target == "all" ? canonicalArtifactPaths : [target]
        do {
            let generated = artifactContents(config: config, preferences: preferences, routeSummary: routeSummary)
            var written: [String] = []
            for path in targets {
                guard let content = generated[path] else { continue }
                let url = try resolve(path)
                try content.write(to: url, atomically: true, encoding: .utf8)
                written.append(path)
                appendEvent(type: "artifact.written", message: "Regenerated \(path).", metadata: ["path": path])
            }
            refreshMetadata()
            let status: OpenClawActionStatus = written.isEmpty ? .failed : .persisted
            let summary = written.isEmpty ? "No matching canonical artifacts were regenerated" : "Regenerated \(written.count) canonical artifact\(written.count == 1 ? "" : "s")"
            return finish(action, status: status, summary: summary, output: ["paths": written.joined(separator: ", ")], artifacts: written, error: written.isEmpty ? "Unknown artifact target: \(target)" : nil)
        } catch {
            return finish(action, status: .failed, summary: "Artifact regeneration failed", error: error.localizedDescription)
        }
    }

    func refreshMemory(config: StackConfig, preferences: UserPreferences, routeSummary: String, source: String = "runtime") -> OpenClawReceipt {
        let action = begin(kind: .memoryRefresh, source: source, title: "Refresh memory", input: [:])
        ensureStateStores(config: config, preferences: preferences, routeSummary: routeSummary)
        let receipt = regenerateArtifacts(target: "memory.md", config: config, preferences: preferences, routeSummary: routeSummary, source: source)
        appendEvent(type: "memory.refreshed", message: "Memory stores refreshed.", metadata: ["artifact": "memory.md"])
        return finish(action, status: receipt.status, summary: "Memory stores refreshed", output: receipt.output, artifacts: receipt.artifacts, error: receipt.error)
    }

    func runSkill(id: String, input: [String: String], config: StackConfig, preferences: UserPreferences, routeSummary: String) -> OpenClawReceipt {
        guard let manifest = skills.first(where: { $0.id == id }), manifest.enabled else {
            let action = begin(kind: .skillRun, source: "skills", title: "Run skill", input: ["skillId": id])
            return finish(action, status: .failed, summary: "Skill is not registered or enabled", error: "Unknown skill: \(id)")
        }

        appendEvent(type: "skill.invoked", message: "Invoked \(manifest.name).", metadata: ["skillId": id])
        switch id {
        case BuiltInSkillRegistry.pokemonTeamBuilderID:
            return runPokemonTeamBuilder(input: input, manifest: manifest)
        case BuiltInSkillRegistry.artifactRebuilderID:
            return regenerateArtifacts(target: input["target"]?.nilIfBlank ?? "all", config: config, preferences: preferences, routeSummary: routeSummary, source: "skill.\(id)")
        case BuiltInSkillRegistry.memoryInspectorID:
            return runMemoryInspector(manifest: manifest)
        default:
            let action = begin(kind: .skillRun, source: "skills", title: manifest.name, input: input)
            return finish(action, status: .failed, summary: "Entrypoint is not implemented", error: "Missing entrypoint: \(manifest.entrypoint)")
        }
    }

    func runSandbox(command: String, config: StackConfig, preferences: UserPreferences, routeSummary: String) -> OpenClawReceipt {
        let cleaned = command.trimmingCharacters(in: .whitespacesAndNewlines)
        let action = begin(kind: .sandboxRun, source: "sandbox", title: "Run sandbox command", input: ["command": cleaned])
        let parts = cleaned.split(separator: " ").map(String.init)
        guard let op = parts.first else {
            return finish(action, status: .failed, summary: "No command supplied", error: "Empty sandbox command")
        }

        appendEvent(type: "sandbox.command.executed", message: "Sandbox command requested: \(cleaned)", metadata: ["command": cleaned])

        switch op {
        case "pwd":
            return finish(action, status: .completed, summary: "Printed workspace root", output: ["stdout": "/.openclaw", "exitCode": "0"])
        case "ls":
            let target = parts.dropFirst().first ?? ""
            return finish(action, status: .completed, summary: "Listed \(target.isEmpty ? "/.openclaw" : target)", output: ["stdout": listFiles(target).joined(separator: "\n"), "exitCode": "0"])
        case "cat":
            guard let target = parts.dropFirst().first else {
                return finish(action, status: .failed, summary: "cat requires a file path", error: "Usage: cat soul.md")
            }
            do {
                return finish(action, status: .completed, summary: "Read \(target)", output: ["stdout": try readFile(target), "exitCode": "0"], artifacts: [target])
            } catch {
                return finish(action, status: .failed, summary: "Could not read \(target)", error: error.localizedDescription)
            }
        case "regenerate":
            return regenerateArtifacts(target: parts.dropFirst().first ?? "all", config: config, preferences: preferences, routeSummary: routeSummary, source: "sandbox")
        case "skills":
            return finish(action, status: .completed, summary: "Listed registered skills", output: ["stdout": skills.map { "\($0.id) - \($0.name)" }.joined(separator: "\n"), "exitCode": "0"])
        case "help":
            return finish(action, status: .completed, summary: "Printed sandbox help", output: ["stdout": "Supported commands: pwd, ls [path], cat <path>, regenerate [all|artifact], skills, help", "exitCode": "0"])
        default:
            return finish(
                action,
                status: .failed,
                summary: "Arbitrary shell execution is unavailable in the iOS sandbox",
                output: ["exitCode": "127"],
                error: "Unsupported command '\(op)'. Build 17 exposes a controlled OpenClaw command surface; TODO: connect a hardened process runner where platform policy allows it."
            )
        }
    }

    func refreshMetadata() {
        artifacts = listArtifactMetadata()
        recentActions = loadRecentActions()
        recentEvents = loadRecentEvents()
    }

    func buddyStatus(activeModelAdapter: String, brainConnected: Bool, runtimeAvailable: Bool) -> BuddyRuntimeStatus {
        refreshMetadata()
        let canonical = artifacts.filter { canonicalArtifactPaths.contains($0.path) }
        let failed = recentActions.filter { $0.status == .failed }
        let missing = canonical.filter { $0.freshness == .missing }.map(\.path)
        var suggestions: [String] = []
        if missing.isEmpty {
            suggestions.append("Open Skills and run Pokemon Team Builder to create a saved team artifact.")
        } else {
            suggestions.append("Regenerate missing artifacts: \(missing.joined(separator: ", ")).")
        }
        if failed.isEmpty == false {
            suggestions.append("Review failed action receipts before trusting generated summaries.")
        }
        if skills.isEmpty {
            suggestions.append("Rebuild the skills registry.")
        }

        return BuddyRuntimeStatus(
            activeModelAdapter: activeModelAdapter,
            brainConnected: brainConnected,
            runtimeAvailable: runtimeAvailable,
            memoryHealthy: missing.isEmpty && fileManager.fileExists(atPath: rootURL.appendingPathComponent("state/facts.json").path),
            artifacts: canonical,
            registeredSkillCount: skills.count,
            recentChanges: Array(recentEvents.prefix(5)),
            failedActions: Array(failed.prefix(5)),
            suggestedNextActions: suggestions
        )
    }

    // MARK: Private workspace

    private var canonicalArtifactPaths: [String] {
        ["soul.md", "user.md", "memory.md", "session.md", "skills.md"]
    }

    private func ensureWorkspaceTree() {
        [
            rootURL,
            rootURL.appendingPathComponent("registry", isDirectory: true),
            rootURL.appendingPathComponent("state", isDirectory: true),
            rootURL.appendingPathComponent("skills/pokemon-team-builder/teams", isDirectory: true),
            rootURL.appendingPathComponent("skills/pokemon-team-builder/presets", isDirectory: true),
            rootURL.appendingPathComponent("logs", isDirectory: true)
        ].forEach { try? fileManager.createDirectory(at: $0, withIntermediateDirectories: true) }

        let cacheURL = rootURL.appendingPathComponent("skills/pokemon-team-builder/cache.json")
        if !fileManager.fileExists(atPath: cacheURL.path) {
            writeJSON(["lastRun": "never"], to: cacheURL)
        }
        let latestLog = rootURL.appendingPathComponent("logs/latest-actions.log")
        if !fileManager.fileExists(atPath: latestLog.path) {
            try? "OpenClaw action log initialized.\n".write(to: latestLog, atomically: true, encoding: .utf8)
        }
    }

    private func ensureStateStores(config: StackConfig, preferences: UserPreferences, routeSummary: String) {
        writeJSON([
            "identity": [preferences.preferredName.nilIfBlank ?? config.operatorName.nilIfBlank ?? "operator"],
            "project": [config.stackName],
            "workflow": [config.goal.nilIfBlank ?? "Build and operate an OpenClaw workspace"],
            "tooling": ["OpenClaw iOS workspace runtime", routeSummary],
            "game": ["Pokemon Team Builder is a registered skill"]
        ], to: rootURL.appendingPathComponent("state/facts.json"))

        writeJSON([
            "preferredName": preferences.preferredName,
            "theme": preferences.theme.rawValue,
            "optimizationMode": config.optimizationMode,
            "memoryEnabled": String(config.memoryEnabled),
            "toolsEnabled": String(config.toolsEnabled)
        ], to: rootURL.appendingPathComponent("state/preferences.json"))

        writeJSON([
            "openTasks": [
                "Ship a real on-device inference runtime or hardened host process runner when available."
            ],
            "completedTasks": [
                "Created .openclaw workspace runtime structure.",
                "Registered Pokemon Team Builder as a skill."
            ]
        ], to: rootURL.appendingPathComponent("state/tasks.json"))

        writeJSON([
            "stackName": config.stackName,
            "role": config.role,
            "goal": config.goal,
            "route": routeSummary,
            "updatedAt": ISO8601DateFormatter().string(from: .now)
        ], to: rootURL.appendingPathComponent("state/session.json"))
    }

    private func regenerateCanonicalArtifactsIfMissing(config: StackConfig, preferences: UserPreferences, routeSummary: String) {
        let generated = artifactContents(config: config, preferences: preferences, routeSummary: routeSummary)
        for path in canonicalArtifactPaths {
            let url = rootURL.appendingPathComponent(path)
            if !fileManager.fileExists(atPath: url.path), let content = generated[path] {
                try? content.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    private func artifactContents(config: StackConfig, preferences: UserPreferences, routeSummary: String) -> [String: String] {
        [
            "soul.md": """
            # soul.md

            OpenClaw is one agent, one workspace, one sandbox, and one capability surface.

            ## Operating posture
            - Prefer confirmed runtime receipts over fluent claims.
            - Treat local and cloud model adapters as callers of the same Workspace Runtime.
            - Save durable work into inspectable artifacts.
            - Say planned, unavailable, or failed when no receipt confirms completion.

            ## Stack
            - Name: \(config.stackName)
            - Role: \(config.role.nilIfBlank ?? "operator")
            - Goal: \(config.goal.nilIfBlank ?? "not set")
            - Active route: \(routeSummary)
            """,
            "user.md": """
            # user.md

            ## Operator
            - Preferred name: \(preferences.preferredName.nilIfBlank ?? config.operatorName.nilIfBlank ?? "not set")
            - Role: \(config.role.nilIfBlank ?? "not set")
            - Goal: \(config.goal.nilIfBlank ?? "not set")

            ## Preferences
            - Theme: \(preferences.theme.rawValue)
            - Optimization: \(config.optimizationMode)
            - Memory enabled: \(config.memoryEnabled ? "yes" : "no")
            - Tools enabled: \(config.toolsEnabled ? "yes" : "no")
            """,
            "memory.md": """
            # memory.md

            ## Durable facts
            - OpenClaw should feel like a real agent workspace, not a chat-only shell.
            - Canonical artifacts live under `.openclaw/`.
            - Pokemon Team Builder is a first-class skill and saves artifacts.
            - Completion language must be receipt-aware.

            ## Current project
            - Stack: \(config.stackName)
            - Runtime route: \(routeSummary)
            """,
            "session.md": """
            # session.md

            ## Current state
            - Updated: \(ISO8601DateFormatter().string(from: .now))
            - Active route: \(routeSummary)
            - Registered skills: \(skills.count)
            - Recent actions: \(recentActions.count)

            ## Next useful moves
            - Run Pokemon Team Builder from Skills and save a team artifact.
            - Review Artifacts to inspect generated workspace files.
            - Use the controlled sandbox commands for workspace reads/regeneration.
            """,
            "skills.md": """
            # skills.md

            \(skills.map { "- **\($0.name)** (`\($0.id)`): \($0.description)" }.joined(separator: "\n"))
            """
        ]
    }

    private func runPokemonTeamBuilder(input: [String: String], manifest: SkillManifest) -> OpenClawReceipt {
        let action = begin(kind: .skillRun, source: "skill.\(manifest.id)", title: manifest.name, input: input)
        let format = input["format"].nilIfBlank ?? "Singles"
        let strategy = input["strategy"].nilIfBlank ?? "balanced offense"
        let mustInclude = splitList(input["mustInclude"])
        let avoid = Set(splitList(input["avoid"]).map { $0.lowercased() })
        let candidates = ["Pikachu", "Charizard", "Venusaur", "Blastoise", "Gengar", "Dragonite", "Lucario", "Garchomp", "Rotom-Wash", "Corviknight", "Togekiss", "Snorlax"]
        let roles = ["Lead / speed control", "Physical breaker", "Special attacker", "Defensive pivot", "Utility support", "Late-game cleaner"]
        var selected: [String] = []
        for name in mustInclude where !avoid.contains(name.lowercased()) {
            if !selected.contains(name) { selected.append(name) }
        }
        for candidate in candidates where selected.count < 6 {
            guard !avoid.contains(candidate.lowercased()), !selected.contains(candidate) else { continue }
            selected.append(candidate)
        }
        let team = selected.prefix(6).enumerated().map { index, name in
            PokemonTeamMember(name: name, role: roles[index % roles.count], notes: "\(format) pick for \(strategy).")
        }
        let weaknesses = [
            "Validate exact legality, moves, items, and EVs against the target format before competitive use.",
            "This MVP uses curated role coverage rather than a full damage calculator or matchup database."
        ]
        let suggestions = [
            "Add exact movesets after choosing the battle format.",
            "Run a future simulator-backed pass for type chart and usage data."
        ]
        let output = PokemonTeamOutput(
            teamMembers: Array(team),
            roleBreakdown: team.map { "\($0.name): \($0.role)" },
            summary: "Drafted a \(format) team around \(strategy).",
            weaknesses: weaknesses,
            suggestions: suggestions,
            artifactPath: nil
        )

        do {
            let slug = safeSlug([format, strategy, String(Int(Date().timeIntervalSince1970))].joined(separator: "-"))
            let jsonPath = "skills/pokemon-team-builder/teams/\(slug).json"
            let mdPath = "skills/pokemon-team-builder/teams/\(slug).md"
            var saved = output
            saved.artifactPath = mdPath
            let jsonData = try encoder.encode(saved)
            try jsonData.write(to: resolve(jsonPath), options: [.atomic])
            try pokemonMarkdown(output: saved, format: format, strategy: strategy).write(to: resolve(mdPath), atomically: true, encoding: .utf8)
            appendEvent(type: "skill.completed", message: "Pokemon Team Builder saved \(mdPath).", metadata: ["skillId": manifest.id, "artifact": mdPath])
            refreshMetadata()
            return finish(
                action,
                status: .persisted,
                summary: "Pokemon team drafted and saved",
                output: ["summary": saved.summary, "members": saved.teamMembers.map(\.name).joined(separator: ", ")],
                artifacts: [jsonPath, mdPath]
            )
        } catch {
            return finish(action, status: .failed, summary: "Pokemon team draft failed to save", error: error.localizedDescription)
        }
    }

    private func runMemoryInspector(manifest: SkillManifest) -> OpenClawReceipt {
        let action = begin(kind: .skillRun, source: "skill.\(manifest.id)", title: manifest.name, input: [:])
        let paths = ["state/facts.json", "state/preferences.json", "state/session.json"]
        let body = paths.compactMap { path -> String? in
            guard let value = try? readFile(path) else { return nil }
            return "## \(path)\n\(value)"
        }.joined(separator: "\n\n")
        return finish(action, status: .completed, summary: "Read memory stores", output: ["summary": body], artifacts: paths)
    }

    private func pokemonMarkdown(output: PokemonTeamOutput, format: String, strategy: String) -> String {
        """
        # Pokemon Team

        - Format: \(format)
        - Strategy: \(strategy)
        - Receipt-backed: yes

        ## Team
        \(output.teamMembers.map { "- **\($0.name)** - \($0.role): \($0.notes)" }.joined(separator: "\n"))

        ## Summary
        \(output.summary)

        ## Weaknesses
        \(output.weaknesses.map { "- \($0)" }.joined(separator: "\n"))

        ## Suggestions
        \(output.suggestions.map { "- \($0)" }.joined(separator: "\n"))
        """
    }

    private func begin(kind: OpenClawActionKind, source: String, title: String, input: [String: String]) -> OpenClawActionRecord {
        let action = OpenClawActionRecord(id: UUID(), kind: kind, source: source, title: title, status: .queued, createdAt: .now, updatedAt: .now, input: input, output: [:], error: nil, artifacts: [], logs: [])
        persistAction(action)
        var running = action
        running.status = .running
        running.updatedAt = .now
        upsertRecent(running)
        persistAction(running)
        return running
    }

    private func finish(_ action: OpenClawActionRecord, status: OpenClawActionStatus, summary: String, output: [String: String] = [:], artifacts: [String] = [], logs: [String] = [], error: String? = nil) -> OpenClawReceipt {
        var finished = action
        finished.status = status
        finished.updatedAt = .now
        finished.output = output.merging(["summary": summary]) { current, _ in current }
        finished.artifacts = artifacts
        finished.logs = logs
        finished.error = error
        upsertRecent(finished)
        persistAction(finished)
        if let error {
            appendEvent(type: "action.failed", message: error, metadata: ["actionId": action.id.uuidString])
        } else {
            appendEvent(type: "action.\(status.rawValue)", message: summary, metadata: ["actionId": action.id.uuidString])
        }
        refreshMetadata()
        return OpenClawReceipt(actionId: action.id, status: status, title: action.title, summary: summary, output: output, artifacts: artifacts, logs: logs, error: error)
    }

    private func upsertRecent(_ action: OpenClawActionRecord) {
        recentActions.removeAll { $0.id == action.id }
        recentActions.insert(action, at: 0)
        recentActions = Array(recentActions.prefix(30))
    }

    private func persistAction(_ action: OpenClawActionRecord) {
        appendJSONLine(action, to: rootURL.appendingPathComponent("actions.jsonl"))
        let line = "[\(action.status.rawValue)] \(action.title) \(action.error ?? action.output["summary"] ?? "")\n"
        appendText(line, to: rootURL.appendingPathComponent("logs/latest-actions.log"))
    }

    private func appendEvent(type: String, message: String, metadata: [String: String] = [:]) {
        let event = OpenClawEventRecord(type: type, message: message, metadata: metadata)
        recentEvents.insert(event, at: 0)
        recentEvents = Array(recentEvents.prefix(30))
        appendJSONLine(event, to: rootURL.appendingPathComponent("events.jsonl"))
    }

    private func appendJSONLine<T: Encodable>(_ value: T, to url: URL) {
        guard let data = try? encoder.encode(value), let line = String(data: data, encoding: .utf8)?.replacingOccurrences(of: "\n", with: "") else { return }
        appendText(line + "\n", to: url)
    }

    private func appendText(_ value: String, to url: URL) {
        if !fileManager.fileExists(atPath: url.path) {
            fileManager.createFile(atPath: url.path, contents: nil)
        }
        guard let handle = try? FileHandle(forWritingTo: url) else { return }
        defer { try? handle.close() }
        try? handle.seekToEnd()
        if let data = value.data(using: .utf8) {
            handle.write(data)
        }
    }

    private func writeJSON<T: Encodable>(_ value: T, to url: URL) {
        try? fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if let data = try? encoder.encode(value) {
            try? data.write(to: url, options: [.atomic])
        }
    }

    private func resolve(_ path: String) throws -> URL {
        let cleaned = path.replacingOccurrences(of: "\\", with: "/").trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !cleaned.isEmpty else { return rootURL }
        let components = cleaned.split(separator: "/").map(String.init)
        guard components.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else {
            throw NSError(domain: "OpenClawWorkspaceRuntime", code: 400, userInfo: [NSLocalizedDescriptionKey: "Unsafe workspace path: \(path)"])
        }
        let url = components.reduce(rootURL) { $0.appendingPathComponent($1) }
        let standardizedRoot = rootURL.standardizedFileURL.path
        let standardizedPath = url.standardizedFileURL.path
        guard standardizedPath == standardizedRoot || standardizedPath.hasPrefix(standardizedRoot + "/") else {
            throw NSError(domain: "OpenClawWorkspaceRuntime", code: 401, userInfo: [NSLocalizedDescriptionKey: "Path escapes .openclaw workspace: \(path)"])
        }
        return url
    }

    private func relativePath(for url: URL) -> String {
        let root = rootURL.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        return path.hasPrefix(root + "/") ? String(path.dropFirst(root.count + 1)) : url.lastPathComponent
    }

    private func listArtifactMetadata() -> [OpenClawArtifactMetadata] {
        let allPaths = Set(canonicalArtifactPaths + listFiles())
        return allPaths.sorted().map { path in
            let url = rootURL.appendingPathComponent(path)
            let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
            let exists = fileManager.fileExists(atPath: url.path)
            return OpenClawArtifactMetadata(
                path: path,
                kind: path.pathExtensionKind,
                updatedAt: values?.contentModificationDate,
                size: values?.fileSize ?? 0,
                freshness: exists ? .fresh : .missing
            )
        }
    }

    private func loadRecentActions() -> [OpenClawActionRecord] {
        let url = rootURL.appendingPathComponent("actions.jsonl")
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return recentActions }
        var latest: [UUID: OpenClawActionRecord] = [:]
        for line in text.split(separator: "\n").suffix(120) {
            if let data = String(line).data(using: .utf8), let action = try? decoder.decode(OpenClawActionRecord.self, from: data) {
                latest[action.id] = action
            }
        }
        return latest.values.sorted { $0.updatedAt > $1.updatedAt }.prefix(30).map { $0 }
    }

    private func loadRecentEvents() -> [OpenClawEventRecord] {
        let url = rootURL.appendingPathComponent("events.jsonl")
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return recentEvents }
        return text.split(separator: "\n").suffix(30).compactMap { line in
            guard let data = String(line).data(using: .utf8) else { return nil }
            return try? decoder.decode(OpenClawEventRecord.self, from: data)
        }.sorted { $0.createdAt > $1.createdAt }
    }

    private func splitList(_ value: String?) -> [String] {
        (value ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func safeSlug(_ value: String) -> String {
        value.lowercased().map { character in
            character.isLetter || character.isNumber ? character : "-"
        }.reduce("") { partial, character in
            if character == "-", partial.last == "-" { return partial }
            return partial + String(character)
        }.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}

struct BuddyRuntimeStatus {
    var activeModelAdapter: String
    var brainConnected: Bool
    var runtimeAvailable: Bool
    var memoryHealthy: Bool
    var artifacts: [OpenClawArtifactMetadata]
    var registeredSkillCount: Int
    var recentChanges: [OpenClawEventRecord]
    var failedActions: [OpenClawActionRecord]
    var suggestedNextActions: [String]
}

private extension String? {
    var nilIfBlank: String? {
        guard let value = self?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value
    }
}

private extension String {
    var nilIfBlank: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var pathExtensionKind: String {
        let ext = URL(fileURLWithPath: self).pathExtension.lowercased()
        if ext == "md" { return "markdown" }
        if ext == "json" { return "json" }
        if ext == "jsonl" { return "log" }
        return ext.isEmpty ? "file" : ext
    }
}
