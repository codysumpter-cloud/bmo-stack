import SwiftUI

struct SkillsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var lastReceipt: OpenClawReceipt?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BMOTheme.spacingMD) {
                    headerCard

                    if let lastReceipt {
                        ActionReceiptCard(receipt: lastReceipt)
                    }

                    clawHubCard

                    ForEach(appState.workspaceRuntime.skills) { skill in
                        skillCard(skill)
                    }
                }
                .padding(.horizontal, BMOTheme.spacingMD)
                .padding(.bottom, BMOTheme.spacingXL)
            }
            .background(BMOTheme.backgroundPrimary)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Skills")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                }
            }
            .toolbarBackground(BMOTheme.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear { appState.workspaceRuntime.refreshMetadata() }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("BeMore Skills")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(BMOTheme.textPrimary)
                Spacer()
                StatusBadge(label: "\(appState.workspaceRuntime.skills.count) registered", color: BMOTheme.accent)
            }
            Text("Skills are practical abilities Buddy can learn, equip, and use for planning, review, building, and deeper operator work when you ask for it.")
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)
        }
        .bmoCard()
    }

    private func skillCard(_ skill: SkillManifest) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: skill.ui.systemImage)
                    .font(.title3)
                    .foregroundColor(BMOTheme.accent)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(skill.name)
                            .font(.headline)
                            .foregroundColor(BMOTheme.textPrimary)
                        Spacer()
                        StatusBadge(label: skill.enabled ? "Enabled" : "Disabled", color: skill.enabled ? BMOTheme.success : BMOTheme.warning)
                    }
                    Text(skill.description)
                        .font(.subheadline)
                        .foregroundColor(BMOTheme.textSecondary)
                    Text("\(skill.category) • \(skill.tags.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(BMOTheme.textTertiary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(skill.permissions, id: \.self) { permission in
                        Text(permission)
                            .font(.caption2)
                            .foregroundColor(BMOTheme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(BMOTheme.accent.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }

            if skill.id == BuiltInSkillRegistry.pokemonTeamBuilderID {
                NavigationLink {
                    PokemonTeamBuilderView()
                } label: {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Launch Team Builder")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(BMOButtonStyle())
            } else {
                Button {
                    let input = skill.id == BuiltInSkillRegistry.artifactRebuilderID ? ["target": "all"] : ["request": "Run \(skill.name) from Skills."]
                    lastReceipt = appState.runSkill(id: skill.id, input: input)
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Run Skill")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(BMOButtonStyle(isPrimary: false))
            }
        }
        .bmoCard()
    }

    private var clawHubCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Buddy Skill Hub")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                    Text("Install starter skills into the BeMore workspace registry with real README, manifest, artifact, and receipt output.")
                        .font(.caption)
                        .foregroundColor(BMOTheme.textSecondary)
                }
                Spacer()
                StatusBadge(label: "Local", color: BMOTheme.success)
            }

            ForEach(ClawHubCatalog.templates) { template in
                let installed = appState.workspaceRuntime.skills.contains(where: { $0.id == template.id })
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: template.systemImage)
                        .foregroundColor(BMOTheme.accent)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(BMOTheme.textPrimary)
                        Text(template.description)
                            .font(.caption)
                            .foregroundColor(BMOTheme.textSecondary)
                    }
                    Spacer()
                    Button(installed ? "Installed" : "Install") {
                        lastReceipt = appState.installClawHubSkill(template)
                    }
                    .disabled(installed)
                    .buttonStyle(.bordered)
                }
            }
        }
        .bmoCard()
    }
}

struct PokemonTeamBuilderView: View {
    @EnvironmentObject private var appState: AppState
    @State private var format = "Singles"
    @State private var strategy = "balanced offense"
    @State private var mustInclude = "Pikachu"
    @State private var avoid = ""
    @State private var receipt: OpenClawReceipt?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BMOTheme.spacingMD) {
                header
                formCard
                if let receipt {
                    ActionReceiptCard(receipt: receipt)
                    if let members = receipt.output["members"] {
                        analysisCard(members: members)
                    }
                }
            }
            .padding(.horizontal, BMOTheme.spacingMD)
            .padding(.bottom, BMOTheme.spacingXL)
        }
        .background(BMOTheme.backgroundPrimary)
        .navigationTitle("Pokemon Team Builder")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Flagship Skill")
                .font(.caption)
                .foregroundColor(BMOTheme.textTertiary)
            Text("Draft a team, save artifacts, get a receipt.")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(BMOTheme.textPrimary)
            Text("This MVP uses curated role coverage. Exact legality, moves, EVs, and simulator-backed matchup data are still TODOs.")
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)
        }
        .bmoCard()
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Format", selection: $format) {
                Text("Singles").tag("Singles")
                Text("Doubles").tag("Doubles")
                Text("Story Run").tag("Story Run")
                Text("Draft League").tag("Draft League")
            }
            .pickerStyle(.segmented)

            labeledField("Strategy / theme", text: $strategy, placeholder: "rain balance, cute chaos, bulky offense")
            labeledField("Must include", text: $mustInclude, placeholder: "Pikachu, Gengar")
            labeledField("Avoid", text: $avoid, placeholder: "Legendaries, Charizard")

            Button {
                receipt = appState.runSkill(
                    id: BuiltInSkillRegistry.pokemonTeamBuilderID,
                    input: [
                        "format": format,
                        "strategy": strategy,
                        "mustInclude": mustInclude,
                        "avoid": avoid
                    ]
                )
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text("Generate and Save Team")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(BMOButtonStyle())
        }
        .bmoCard()
    }

    private func analysisCard(members: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Saved roster")
                .font(.headline)
                .foregroundColor(BMOTheme.textPrimary)
            Text(members)
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)
            Text("Open Artifacts to inspect the saved JSON and Markdown team files.")
                .font(.caption)
                .foregroundColor(BMOTheme.textTertiary)
            if let strategy = receipt?.output["strategy"] {
                Divider().overlay(BMOTheme.divider)
                Text("Battle strategy")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(BMOTheme.textPrimary)
                Text(strategy)
                    .font(.caption)
                    .foregroundColor(BMOTheme.textSecondary)
            }
            if let rationale = receipt?.output["rationale"] {
                Divider().overlay(BMOTheme.divider)
                Text("Why these picks")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(BMOTheme.textPrimary)
                Text(rationale)
                    .font(.caption)
                    .foregroundColor(BMOTheme.textSecondary)
            }
        }
        .bmoCard()
    }

    private func labeledField(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(BMOTheme.textTertiary)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .foregroundColor(BMOTheme.textPrimary)
                .padding(12)
                .background(BMOTheme.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusSmall, style: .continuous))
        }
    }
}

struct ActionReceiptCard: View {
    let receipt: OpenClawReceipt

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(receipt.title)
                    .font(.headline)
                    .foregroundColor(BMOTheme.textPrimary)
                Spacer()
                StatusBadge(label: receipt.status.label, color: receipt.status.color)
            }

            Text(ReceiptFormatter.confirmedSummary(for: receipt))
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)

            if !receipt.artifacts.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Artifacts")
                        .font(.caption)
                        .foregroundColor(BMOTheme.textTertiary)
                    ForEach(receipt.artifacts, id: \.self) { artifact in
                        Text(artifact)
                            .font(.caption)
                            .foregroundColor(BMOTheme.accent)
                    }
                }
            }
        }
        .bmoCard()
    }
}
