import Foundation

enum OpenClawShellTab: Hashable {
    case home
    case chat
    case files
    case models
    case editor
}

enum StackBuilderFocus: String, Codable, CaseIterable, Identifiable {
    case personalOperator
    case codeWorkbench
    case modelLab
    case creatorStudio

    var id: String { rawValue }

    var title: String {
        switch self {
        case .personalOperator:
            return "Personal Operator"
        case .codeWorkbench:
            return "Code Workbench"
        case .modelLab:
            return "Model Lab"
        case .creatorStudio:
            return "Creator Studio"
        }
    }

    var tagline: String {
        switch self {
        case .personalOperator:
            return "Run a local-first operating system for your day."
        case .codeWorkbench:
            return "Turn OpenClaw into a pocket builder for software stacks."
        case .modelLab:
            return "Keep model experiments, packaging, and validation close at hand."
        case .creatorStudio:
            return "Organize files, prompts, and outputs around a creative workflow."
        }
    }
}

enum StackBuilderExperience: String, Codable, CaseIterable, Identifiable {
    case gettingStarted
    case comfortable
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gettingStarted:
            return "Getting Started"
        case .comfortable:
            return "Comfortable"
        case .advanced:
            return "Advanced"
        }
    }
}

enum StackSurface: String, Codable, CaseIterable, Identifiable {
    case home
    case chat
    case files
    case models
    case editor
    case preview

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home:
            return "Dashboard"
        case .chat:
            return "Chat"
        case .files:
            return "Files"
        case .models:
            return "Models"
        case .editor:
            return "Editor"
        case .preview:
            return "Preview"
        }
    }
}

struct StackOnboardingDraft: Codable, Hashable {
    var operatorName: String
    var stackName: String
    var focus: StackBuilderFocus
    var experience: StackBuilderExperience
    var primaryOutcome: String
    var wantsLocalModels: Bool
    var wantsFileWorkspace: Bool
    var wantsDashboard: Bool
    var notes: String

    static let empty = StackOnboardingDraft(
        operatorName: "",
        stackName: "",
        focus: .codeWorkbench,
        experience: .comfortable,
        primaryOutcome: "",
        wantsLocalModels: true,
        wantsFileWorkspace: true,
        wantsDashboard: true,
        notes: ""
    )
}

struct StackDashboardCard: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let detail: String
    let symbol: String
    let destination: StackSurface

    init(id: UUID = UUID(), title: String, detail: String, symbol: String, destination: StackSurface) {
        self.id = id
        self.title = title
        self.detail = detail
        self.symbol = symbol
        self.destination = destination
    }
}

struct StackPreviewSection: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let bullets: [String]

    init(id: UUID = UUID(), title: String, bullets: [String]) {
        self.id = id
        self.title = title
        self.bullets = bullets
    }
}

struct CompiledStack: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let operatorName: String
    let focus: StackBuilderFocus
    let experience: StackBuilderExperience
    let primaryOutcome: String
    let tagline: String
    let summary: String
    let recommendedModelStrategy: String
    let workspaceGuidance: String
    let chatSystemPrompt: String
    let chatInputPlaceholder: String
    let starterPrompts: [String]
    let quickActions: [String]
    let enabledSurfaces: [StackSurface]
    let dashboardCards: [StackDashboardCard]
    let previewSections: [StackPreviewSection]
    let createdAt: Date
    let updatedAt: Date
}

struct StackBuilderState: Codable, Hashable {
    var draft: StackOnboardingDraft
    var compiledStack: CompiledStack?
}
