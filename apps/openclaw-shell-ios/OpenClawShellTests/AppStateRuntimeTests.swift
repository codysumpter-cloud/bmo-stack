import XCTest
@testable import BeMoreAgent

@MainActor
final class AppStateRuntimeTests: XCTestCase {
    override func setUp() {
        super.setUp()
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let appSupport = root.appendingPathComponent("ApplicationSupport", isDirectory: true)
        let documents = root.appendingPathComponent("Documents", isDirectory: true)
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
        Paths.applicationSupportOverride = appSupport
        Paths.documentsOverride = documents
    }

    override func tearDown() {
        if let appSupport = Paths.applicationSupportOverride {
            try? FileManager.default.removeItem(at: appSupport.deletingLastPathComponent())
        }
        Paths.applicationSupportOverride = nil
        Paths.documentsOverride = nil
        super.tearDown()
    }

    func testUserPreferencesPersistLocally() throws {
        let store = UserPreferencesStore()
        store.load()

        store.updatePreferredName("Cody")
        store.updateTheme(.system)
        store.updateUserProfileMarkdown("# USER.md\n\nLocal only user profile")
        store.updateSoulProfileMarkdown("# SOUL.md\n\nLocal only soul profile")

        let reloaded = UserPreferencesStore()
        reloaded.load()

        XCTAssertEqual(reloaded.preferences.preferredName, "Cody")
        XCTAssertEqual(reloaded.preferences.theme, .system)
        XCTAssertEqual(reloaded.preferences.userProfileMarkdown, "# USER.md\n\nLocal only user profile")
        XCTAssertEqual(reloaded.preferences.soulProfileMarkdown, "# SOUL.md\n\nLocal only soul profile")
        XCTAssertTrue(FileManager.default.fileExists(atPath: Paths.userPreferencesFile.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: Paths.userProfileFile.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: Paths.soulProfileFile.path))
    }

    func testBootstrapConfiguresSelectedLocalModel() async throws {
        let fakeEngine = FakeLocalLLMEngine()
        let modelURL = Paths.modelsDirectory.appendingPathComponent("gemma4-e2b-it.gguf")
        try Data("model".utf8).write(to: modelURL)

        let selection = RuntimeSelection(selectedInstalledFilename: modelURL.lastPathComponent, selectedProvider: nil)
        let selectionData = try JSONEncoder().encode(selection)
        try selectionData.write(to: Paths.runtimeSelectionFile, options: [.atomic])

        let appState = AppState(engine: fakeEngine)
        await appState.bootstrap()

        XCTAssertEqual(fakeEngine.configureCalls.count, 1)
        XCTAssertEqual(fakeEngine.configureCalls.first??.modelID, "gemma4-e2b-it")
        XCTAssertEqual(appState.selectedInstalledModel?.localFilename, modelURL.lastPathComponent)
        XCTAssertTrue(appState.canUseSelectedLocalModel)
        XCTAssertEqual(appState.runtimeStatus, "On-device: gemma4-e2b-it")
    }

    func testBootstrapFallsBackToCloudWhenLocalRuntimeUnavailable() async throws {
        let fakeEngine = FakeLocalLLMEngine(supportsLocalModels: false, runtimeRequirementMessage: "Local runtime missing")
        let modelURL = Paths.modelsDirectory.appendingPathComponent("gemma4-e2b-it.gguf")
        try Data("model".utf8).write(to: modelURL)

        let selection = RuntimeSelection(selectedInstalledFilename: modelURL.lastPathComponent, selectedProvider: nil)
        let selectionData = try JSONEncoder().encode(selection)
        try selectionData.write(to: Paths.runtimeSelectionFile, options: [.atomic])

        let appState = AppState(engine: fakeEngine)
        await appState.bootstrap()

        XCTAssertEqual(fakeEngine.configureCalls.count, 1)
        XCTAssertNil(fakeEngine.configureCalls.first!)
        XCTAssertFalse(appState.canUseSelectedLocalModel)
        XCTAssertEqual(appState.runtimeStatus, "Local model selected, runtime unavailable")
        XCTAssertEqual(appState.operatorSummary, "Gemma4 E2b It is selected, but local inference is unavailable in this build.")
    }

    func testSelectedProviderIsLabeledAsDirectCloudRoute() async throws {
        let fakeEngine = FakeLocalLLMEngine(supportsLocalModels: false)
        let appState = AppState(engine: fakeEngine)
        await appState.bootstrap()

        var account = ProviderAccount.blank(for: .openAI)
        account.apiKey = "test-key"
        account.modelSlug = "gpt-4.1"
        account.isEnabled = true
        appState.providerStore.upsert(account)
        appState.setSelectedProvider(.openAI)

        XCTAssertEqual(appState.activeRouteModeLabel, "Direct cloud model route")
        XCTAssertTrue(appState.operatorSummary.contains("routed through OpenAI"))
        XCTAssertTrue(appState.operatorSummary.contains("Workspace actions use the built-in BeMore runtime"))
        XCTAssertTrue(appState.routeHealthSummary.contains("Cloud chat is ready"))
    }

    func testCloudSystemPromptDoesNotConfineAgentToAppOnly() {
        var config = StackConfig.default
        config.stackName = "BeMoreAgent"
        config.gatewayURL = "https://gateway.example.test"
        config.adminDomain = "example.test"
        config.toolsEnabled = true

        let prompt = CloudPromptBuilder.systemPrompt(
            config: config,
            operatorName: "Cody",
            routeLabel: "OpenAI using gpt-4.1"
        )

        XCTAssertTrue(prompt.contains("not confined to the iOS app"))
        XCTAssertTrue(prompt.contains("full BeMore operator context"))
        XCTAssertTrue(prompt.contains("Workspace Runtime receipts"))
        XCTAssertTrue(prompt.contains("Do not reveal hidden reasoning"))
        XCTAssertFalse(prompt.contains("only perform functions inside the app"))
    }

    func testAgentReplySanitizerRemovesThoughtBlocks() {
        let raw = """
        <think>
        private chain of thought
        </think>

        Here is the actual answer.
        """

        let cleaned = AgentReplySanitizer.userVisibleAnswer(from: raw)

        XCTAssertEqual(cleaned, "Here is the actual answer.")
        XCTAssertFalse(cleaned.localizedCaseInsensitiveContains("private chain"))
    }

    func testWorkspaceBootstrapCreatesCanonicalOpenClawArtifacts() throws {
        let runtime = OpenClawWorkspaceRuntime()
        var config = StackConfig.default
        config.stackName = "BeMore"
        config.role = "operator"
        config.goal = "build a real workspace"

        runtime.bootstrap(config: config, preferences: .default, routeSummary: "Route not configured")

        for path in ["soul.md", "user.md", "memory.md", "session.md", "skills.md", "registry/skills.json", "state/facts.json", "state/preferences.json", "state/tasks.json", "state/session.json"] {
            XCTAssertTrue(FileManager.default.fileExists(atPath: Paths.openClawDirectory.appendingPathComponent(path).path), path)
        }

        let soul = try runtime.readFile("soul.md")
        XCTAssertTrue(soul.contains("one agent, one workspace"))
        let skillsMarkdown = try runtime.readFile("skills.md")
        XCTAssertTrue(skillsMarkdown.contains("## Installed skills"))
        XCTAssertTrue(skillsMarkdown.contains("## ClawHub starters"))
        XCTAssertTrue(skillsMarkdown.contains("File Crafter"))
        XCTAssertTrue(skillsMarkdown.contains("Chat should not treat old skill artifacts as active context"))
        XCTAssertTrue(runtime.skills.contains(where: { $0.id == BuiltInSkillRegistry.pokemonTeamBuilderID }))
    }

    func testPokemonTeamBuilderPersistsArtifactsThroughGenericRunner() throws {
        let runtime = OpenClawWorkspaceRuntime()
        runtime.bootstrap(config: .default, preferences: .default, routeSummary: "Direct cloud model route")

        let receipt = runtime.runSkill(
            id: BuiltInSkillRegistry.pokemonTeamBuilderID,
            input: [
                "format": "Singles",
                "strategy": "electric balance",
                "mustInclude": "Pikachu, Gengar",
                "avoid": "Charizard"
            ],
            config: .default,
            preferences: .default,
            routeSummary: "Direct cloud model route"
        )

        XCTAssertEqual(receipt.status, .persisted)
        XCTAssertEqual(receipt.artifacts.count, 2)
        XCTAssertTrue(receipt.output["members"]?.contains("Pikachu") == true)
        XCTAssertTrue(receipt.output["strategy"]?.contains("Open with") == true)
        XCTAssertTrue(receipt.output["rationale"]?.contains("Pikachu") == true)
        XCTAssertTrue(receipt.artifacts.allSatisfy { FileManager.default.fileExists(atPath: Paths.openClawDirectory.appendingPathComponent($0).path) })
        XCTAssertTrue(ReceiptFormatter.confirmedSummary(for: receipt).hasPrefix("Persisted:"))
    }

    func testWorkspaceArtifactsCanBeEditedAndDeletedWithReceipts() throws {
        let runtime = OpenClawWorkspaceRuntime()
        runtime.bootstrap(config: .default, preferences: .default, routeSummary: "Route not configured")

        let writeReceipt = try runtime.writeFile("notes/test.md", content: "# Test\n")
        XCTAssertEqual(writeReceipt.status, .persisted)
        XCTAssertEqual(try runtime.readFile("notes/test.md"), "# Test\n")

        let deleteReceipt = runtime.deleteFile("notes/test.md")
        XCTAssertEqual(deleteReceipt.status, .persisted)
        XCTAssertThrowsError(try runtime.readFile("notes/test.md"))
    }

    func testClawHubInstallsRegistryBackedSkill() throws {
        let runtime = OpenClawWorkspaceRuntime()
        runtime.bootstrap(config: .default, preferences: .default, routeSummary: "Route not configured")

        let template = try XCTUnwrap(ClawHubCatalog.templates.first)
        XCTAssertGreaterThanOrEqual(ClawHubCatalog.templates.count, 8)
        let receipt = runtime.installClawHubSkill(template)

        XCTAssertEqual(receipt.status, .persisted)
        XCTAssertTrue(runtime.skills.contains(where: { $0.id == template.id }))
        XCTAssertTrue(FileManager.default.fileExists(atPath: Paths.openClawDirectory.appendingPathComponent("skills/\(template.id)/README.md").path))

        let runReceipt = runtime.runSkill(id: template.id, input: ["request": "coach me"], config: .default, preferences: .default, routeSummary: "Route not configured")
        XCTAssertEqual(runReceipt.status, .persisted)
        XCTAssertFalse(runReceipt.artifacts.isEmpty)
    }

    func testSandboxRejectsUnsupportedShellWithoutFakeCompletion() {
        let runtime = OpenClawWorkspaceRuntime()
        runtime.bootstrap(config: .default, preferences: .default, routeSummary: "Route not configured")

        let receipt = runtime.runSandbox(command: "rm -rf /", config: .default, preferences: .default, routeSummary: "Route not configured")

        XCTAssertEqual(receipt.status, .failed)
        XCTAssertTrue(receipt.error?.contains("Unsupported command") == true)
        XCTAssertTrue(ReceiptFormatter.confirmedSummary(for: receipt).hasPrefix("Failed:"))
    }
}

private final class FakeLocalLLMEngine: LocalLLMEngine {
    let backendDisplayName: String
    let supportsLocalModels: Bool
    let runtimeRequirementMessage: String?
    var configureCalls: [EngineRuntimeConfig?] = []
    private(set) var isRuntimeReady = false
    let requiresModelSelection = true

    init(
        backendDisplayName: String = "Fake Local Engine",
        supportsLocalModels: Bool = true,
        runtimeRequirementMessage: String? = nil
    ) {
        self.backendDisplayName = backendDisplayName
        self.supportsLocalModels = supportsLocalModels
        self.runtimeRequirementMessage = runtimeRequirementMessage
    }

    func bootstrap() async throws {}

    func configureRuntime(_ config: EngineRuntimeConfig?) async throws {
        configureCalls.append(config)
        isRuntimeReady = config != nil && supportsLocalModels
    }

    func generate(prompt: String, fileContexts: [WorkspaceFile], chatHistory: [ChatMessage]) async throws -> String {
        "ok"
    }
}
