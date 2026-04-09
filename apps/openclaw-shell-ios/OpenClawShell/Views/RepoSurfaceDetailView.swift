import SwiftUI

enum RepoSurface: String, CaseIterable, Identifiable {
    case missionControl
    case testFlightAdmin
    case pokemonChampions

    var id: String { rawValue }

    var title: String {
        switch self {
        case .missionControl:
            return "Mission Control"
        case .testFlightAdmin:
            return "TestFlight Admin"
        case .pokemonChampions:
            return "Pokemon Champions Team Builder"
        }
    }

    var summary: String {
        switch self {
        case .missionControl:
            return "Portable operator control-room contract for runs, tasks, approvals, schedules, memory, and usage."
        case .testFlightAdmin:
            return "The repo-managed build and TestFlight delivery path that now owns BeMoreAgent release proof."
        case .pokemonChampions:
            return "Merged backend spec from PR #206, wrapped here as a real repo scope brief instead of a toy in-app reimplementation."
        }
    }

    var sourcePath: String {
        switch self {
        case .missionControl:
            return "docs/MISSION_CONTROL.md"
        case .testFlightAdmin:
            return "apps/openclaw-shell-ios/ADMIN_TESTFLIGHT_RUNBOOK.md"
        case .pokemonChampions:
            return "docs/POKEMON_CHAMPIONS_TEAM_BUILDER_BACKEND.md"
        }
    }

    var statusLabel: String {
        switch self {
        case .missionControl:
            return "Wrapped"
        case .testFlightAdmin:
            return "Available"
        case .pokemonChampions:
            return "Bundled brief"
        }
    }

    var statusColor: Color {
        switch self {
        case .missionControl:
            return BMOTheme.accent
        case .testFlightAdmin:
            return BMOTheme.success
        case .pokemonChampions:
            return BMOTheme.warning
        }
    }

    fileprivate var resourceName: String {
        switch self {
        case .missionControl:
            return "MISSION_CONTROL"
        case .testFlightAdmin:
            return "ADMIN_TESTFLIGHT_RUNBOOK"
        case .pokemonChampions:
            return "POKEMON_CHAMPIONS_TEAM_BUILDER_BACKEND"
        }
    }

    fileprivate var preferredSections: [String] {
        switch self {
        case .missionControl:
            return ["Purpose", "MVP", "Hard rules"]
        case .testFlightAdmin:
            return ["Safe baseline", "How to ship the next build", "What counts as proof"]
        case .pokemonChampions:
            return ["Purpose", "Backend architecture at a glance", "API contract", "Suggested first shipping scope"]
        }
    }

    fileprivate var contextNote: String {
        switch self {
        case .missionControl:
            return "Wrapped as a mobile brief. The iOS shell exposes the operator intent and source-of-truth contract, not full desktop parity."
        case .testFlightAdmin:
            return "Available as an operational brief because this repo now ships BeMoreAgent to TestFlight through GitHub Actions rather than hand-waved local admin steps."
        case .pokemonChampions:
            return "Included because PR #206 already merged it into real repo scope. This iOS surface reuses the canonical spec and keeps it explicitly separate from the operator shell."
        }
    }
}

private enum RepoSurfaceDocumentStore {
    static func detailText(for surface: RepoSurface) -> String {
        let markdown = loadMarkdown(for: surface)
        let sections = surface.preferredSections.compactMap { extractSection(named: $0, in: markdown) }
        let body = sections.isEmpty ? fallbackExcerpt(from: markdown) : sections.joined(separator: "\n\n")

        return """
        \(surface.title)

        Source: \(surface.sourcePath)
        Status: \(surface.statusLabel)

        \(surface.contextNote)

        \(body)
        """
    }

    private static func loadMarkdown(for surface: RepoSurface) -> String {
        guard let url = Bundle.main.url(forResource: surface.resourceName, withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "Missing bundled source document for \(surface.sourcePath)."
        }
        return text
    }

    private static func extractSection(named heading: String, in markdown: String) -> String? {
        let lines = markdown.components(separatedBy: .newlines)
        let target = heading.lowercased()
        var currentLevel = 0
        var capturing = false
        var collected: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") {
                let level = trimmed.prefix { $0 == "#" }.count
                let title = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "# ")).lowercased()

                if capturing, level <= currentLevel {
                    break
                }

                if title == target {
                    capturing = true
                    currentLevel = level
                    collected.append(trimmed)
                    continue
                }
            }

            if capturing {
                collected.append(line)
            }
        }

        let result = collected.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? nil : result
    }

    private static func fallbackExcerpt(from markdown: String) -> String {
        markdown
            .components(separatedBy: .newlines)
            .prefix(36)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct RepoSurfaceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let surface: RepoSurface

    private var detailText: String {
        RepoSurfaceDocumentStore.detailText(for: surface)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(surface.title)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(BMOTheme.textPrimary)
                            Text(surface.summary)
                                .font(.subheadline)
                                .foregroundColor(BMOTheme.textSecondary)
                        }
                        Spacer()
                        StatusBadge(label: surface.statusLabel, color: surface.statusColor)
                    }

                    Text(surface.sourcePath)
                        .font(.caption)
                        .foregroundColor(BMOTheme.textTertiary)

                    Text(detailText)
                        .font(.caption)
                        .foregroundColor(BMOTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .padding(BMOTheme.spacingMD)
            }
            .background(BMOTheme.backgroundPrimary)
            .navigationTitle("Surface Brief")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(BMOTheme.accent)
                }
            }
        }
    }
}
