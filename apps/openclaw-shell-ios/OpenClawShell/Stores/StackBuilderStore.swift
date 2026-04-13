import Foundation

struct StackCompiler {
    func compile(from draft: StackOnboardingDraft, existingID: UUID? = nil, existingCreatedAt: Date? = nil) -> CompiledStack {
        let cleanOperator = draft.operatorName.trimmingCharacters(in: .whitespacesAndNewlines)
        let operatorName = cleanOperator.isEmpty ? "Operator" : cleanOperator

        let cleanStackName = draft.stackName.trimmingCharacters(in: .whitespacesAndNewlines)
        let stackName = cleanStackName.isEmpty ? "\(operatorName)'s OpenClaw" : cleanStackName

        let cleanOutcome = draft.primaryOutcome.trimmingCharacters(in: .whitespacesAndNewlines)
        let outcome = cleanOutcome.isEmpty ? defaultOutcome(for: draft.focus) : cleanOutcome

        let summary = "\(stackName) is tuned for \(draft.focus.title.lowercased()) work. \(localFirstPhrase(for: draft)) Primary goal: \(outcome)."

        let recommendedModelStrategy = modelStrategy(for: draft)
        let workspaceGuidance = workspaceStrategy(for: draft)
        let chatSystemPrompt = "You are assisting inside \(stackName), a local-first OpenClaw operating system for \(operatorName). Focus area: \(draft.focus.title). Primary outcome: \(outcome). Favor concrete next steps, preserve local context, and treat the iPhone shell as the source of truth."
        let chatInputPlaceholder = placeholder(for: draft)
        let starterPrompts = prompts(for: draft, stackName: stackName, operatorName: operatorName, outcome: outcome)
        let quickActions = quickActions(for: draft)
        let enabledSurfaces = enabledSurfaces(for: draft)
        let dashboardCards = cards(for: draft, outcome: outcome)
        let previewSections = previewSections(for: draft, stackName: stackName, outcome: outcome, recommendedModelStrategy: recommendedModelStrategy, workspaceGuidance: workspaceGuidance)

        return CompiledStack(
            id: existingID ?? UUID(),
            name: stackName,
            operatorName: operatorName,
            focus: draft.focus,
            experience: draft.experience,
            primaryOutcome: outcome,
            tagline: draft.focus.tagline,
            summary: summary,
            recommendedModelStrategy: recommendedModelStrategy,
            workspaceGuidance: workspaceGuidance,
            chatSystemPrompt: chatSystemPrompt,
            chatInputPlaceholder: chatInputPlaceholder,
            starterPrompts: starterPrompts,
            quickActions: quickActions,
            enabledSurfaces: enabledSurfaces,
            dashboardCards: dashboardCards,
            previewSections: previewSections,
            createdAt: existingCreatedAt ?? .now,
            updatedAt: .now
        )
    }

    private func enabledSurfaces(for draft: StackOnboardingDraft) -> [StackSurface] {
        var surfaces: [StackSurface] = [.home, .chat, .preview]
        if draft.wantsFileWorkspace { surfaces.append(.files) }
        if draft.wantsLocalModels { surfaces.append(.models) }
        surfaces.append(.editor)
        return surfaces
    }

    private func cards(for draft: StackOnboardingDraft, outcome: String) -> [StackDashboardCard] {
        var cards: [StackDashboardCard] = [
            StackDashboardCard(
                title: "Stack Preview",
                detail: "Review the compiled local-first plan for \(outcome).",
                symbol: "square.stack.3d.up",
                destination: .preview
            ),
            StackDashboardCard(
                title: "Stack Chat",
                detail: "Use chat with system context shaped for \(draft.focus.title.lowercased()) work.",
                symbol: "message",
                destination: .chat
            )
        ]

        if draft.wantsFileWorkspace {
            cards.append(
                StackDashboardCard(
                    title: "Workspace Files",
                    detail: "Keep imported files attached to the current stack instead of a generic file bucket.",
                    symbol: "folder",
                    destination: .files
                )
            )
        }

        if draft.wantsLocalModels {
            cards.append(
                StackDashboardCard(
                    title: "Model Posture",
                    detail: "Track model imports and runtime readiness for this stack.",
                    symbol: "cpu",
                    destination: .models
                )
            )
        }

        cards.append(
            StackDashboardCard(
                title: "Editor",
                detail: "Open the current workspace file in the bundled editor shell.",
                symbol: "chevron.left.forwardslash.chevron.right",
                destination: .editor
            )
        )

        return cards
    }

    private func previewSections(
        for draft: StackOnboardingDraft,
        stackName: String,
        outcome: String,
        recommendedModelStrategy: String,
        workspaceGuidance: String
    ) -> [StackPreviewSection] {
        [
            StackPreviewSection(
                title: "Identity",
                bullets: [
                    "Stack name: \(stackName)",
                    "Focus: \(draft.focus.title)",
                    "Experience mode: \(draft.experience.title)",
                    "Primary outcome: \(outcome)"
                ]
            ),
            StackPreviewSection(
                title: "Local-First Foundations",
                bullets: [
                    localFirstPhrase(for: draft),
                    recommendedModelStrategy,
                    workspaceGuidance
                ]
            ),
            StackPreviewSection(
                title: "Enabled Surfaces",
                bullets: enabledSurfaces(for: draft).map(\.title)
            ),
            StackPreviewSection(
                title: "Operator Notes",
                bullets: draft.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? ["No custom notes saved yet."]
                    : draft.notes
                        .split(separator: "\n")
                        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
            )
        ]
    }

    private func prompts(for draft: StackOnboardingDraft, stackName: String, operatorName: String, outcome: String) -> [String] {
        switch draft.focus {
        case .personalOperator:
            return [
                "Turn \(stackName) into a daily cockpit for \(operatorName) and map the first three routines.",
                "Summarize the local-first policies I should follow before I automate anything sensitive.",
                "Use my current files and draft a next-actions checklist for \(outcome)."
            ]
        case .codeWorkbench:
            return [
                "Compile a stack-builder plan for \(outcome) and keep the iPhone shell as the source of truth.",
                "Review my attached files and tell me what foundation pieces are missing from this stack.",
                "Draft the next implementation milestone with local persistence, preview, and dashboard updates."
            ]
        case .modelLab:
            return [
                "Create a local model readiness checklist for this phone-first stack.",
                "Compare my imported models and tell me which one best fits \(outcome).",
                "Draft a compact validation plan for runtime readiness, memory pressure, and fallback behavior."
            ]
        case .creatorStudio:
            return [
                "Use the current workspace to sketch a creation pipeline for \(outcome).",
                "Help me structure prompts, files, and edits so the stack stays reusable.",
                "Turn this phone shell into a repeatable studio dashboard with clear next actions."
            ]
        }
    }

    private func quickActions(for draft: StackOnboardingDraft) -> [String] {
        var actions = ["Review compiled stack preview", "Open stack chat"]
        if draft.wantsFileWorkspace {
            actions.append("Import workspace files")
        }
        if draft.wantsLocalModels {
            actions.append("Set local model posture")
        }
        actions.append("Open editor with selected file")
        return actions
    }

    private func modelStrategy(for draft: StackOnboardingDraft) -> String {
        if draft.wantsLocalModels {
            switch draft.experience {
            case .gettingStarted:
                return "Start with one prepared local model import, prove the runtime path, and avoid juggling multiple weights on day one."
            case .comfortable:
                return "Keep one known-good local model selected for daily use and treat remote sources as optional staging paths."
            case .advanced:
                return "Maintain a small local model bench, but keep one default runtime selected so the iPhone flow stays boring and reliable."
            }
        }

        return "Model management is optional for this stack. Keep the shell buildable first, then decide whether local inference belongs in the daily loop."
    }

    private func workspaceStrategy(for draft: StackOnboardingDraft) -> String {
        if draft.wantsFileWorkspace {
            return "Persist imported files in the app container, attach them deliberately in chat, and keep one actively edited file selected for the editor."
        }
        return "This stack can stay light on file imports; use the workspace only when a file materially changes the outcome."
    }

    private func placeholder(for draft: StackOnboardingDraft) -> String {
        switch draft.focus {
        case .personalOperator:
            return "Ask your stack for the next operator move"
        case .codeWorkbench:
            return "Ask your stack builder what to compile next"
        case .modelLab:
            return "Ask your model lab what to validate next"
        case .creatorStudio:
            return "Ask your studio stack what to build or revise"
        }
    }

    private func defaultOutcome(for focus: StackBuilderFocus) -> String {
        switch focus {
        case .personalOperator:
            return "a dependable personal operating system"
        case .codeWorkbench:
            return "a local-first stack builder foundation"
        case .modelLab:
            return "a practical on-device model workflow"
        case .creatorStudio:
            return "a reusable creative production loop"
        }
    }

    private func localFirstPhrase(for draft: StackOnboardingDraft) -> String {
        var parts = ["The stack persists its state, files, and preview locally on the iPhone."]
        if draft.wantsLocalModels {
            parts.append("Prepared local model imports are the preferred runtime path.")
        } else {
            parts.append("Runtime model work is deferred until the rest of the stack foundation is stable.")
        }
        return parts.joined(separator: " ")
    }
}

@MainActor
final class StackBuilderStore: ObservableObject {
    @Published var draft: StackOnboardingDraft = .empty {
        didSet { persistIfLoaded() }
    }
    @Published private(set) var compiledStack: CompiledStack? {
        didSet { persistIfLoaded() }
    }
    @Published var errorMessage: String?

    private let compiler = StackCompiler()
    private var hasLoaded = false

    func load() {
        defer { hasLoaded = true }

        guard let data = try? Data(contentsOf: Paths.stackBuilderStateFile) else {
            draft = .empty
            compiledStack = nil
            return
        }

        guard let state = try? JSONDecoder().decode(StackBuilderState.self, from: data) else {
            draft = .empty
            compiledStack = nil
            return
        }

        draft = state.draft
        compiledStack = state.compiledStack
    }

    var hasCompletedOnboarding: Bool {
        compiledStack != nil
    }

    func compileCurrentStack() -> CompiledStack {
        let stack = compiler.compile(
            from: draft,
            existingID: compiledStack?.id,
            existingCreatedAt: compiledStack?.createdAt
        )
        compiledStack = stack
        return stack
    }

    func reopenOnboarding() {
        compiledStack = nil
    }

    func reset() {
        draft = .empty
        compiledStack = nil
    }

    private func persistIfLoaded() {
        guard hasLoaded else { return }
        persist()
    }

    private func persist() {
        do {
            let state = StackBuilderState(draft: draft, compiledStack: compiledStack)
            let data = try JSONEncoder().encode(state)
            try data.write(to: Paths.stackBuilderStateFile, options: [.atomic])
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
