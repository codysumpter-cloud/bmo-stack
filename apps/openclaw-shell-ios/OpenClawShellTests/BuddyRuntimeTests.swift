import XCTest
@testable import BeMoreAgent

@MainActor
final class BuddyRuntimeTests: XCTestCase {
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

    func testBundledBuddyResourcesDecodeAndCouncilStarterPackMatchesCanonicalRoster() throws {
        let contracts = try BuddyContractLoader.loadCanonicalResources()

        for resource in BuddyBundledResource.allCases {
            if resource.resourceExtension == "json" {
                let data = try BuddyContractLoader.loadData(resource: resource)
                XCTAssertNoThrow(try JSONSerialization.jsonObject(with: data), resource.rawValue)
            } else {
                let text = try BuddyContractLoader.loadText(resource: resource)
                XCTAssertFalse(text.isEmpty, resource.rawValue)
            }
        }

        let expectedIDs = [
            "bmo",
            "prismo",
            "neptr",
            "princess-bubblegum",
            "finn",
            "jake",
            "marceline",
            "simon",
            "peppermint-butler",
            "lady-rainicorn",
            "lemongrab",
            "flame-princess"
        ]

        XCTAssertEqual(contracts.templates.count, 12)
        XCTAssertEqual(contracts.templates.map(\.id), expectedIDs)
    }

    func testInstallingStarterBuddyCreatesCleanDerivedCopyAndPersistsArtifacts() throws {
        let contracts = try BuddyContractLoader.loadCanonicalResources()
        let originalTemplate = try XCTUnwrap(contracts.template(id: "bmo"))
        let runtime = OpenClawWorkspaceRuntime()
        runtime.bootstrap(config: .default, preferences: .default, routeSummary: "Direct cloud model route")

        let engine = BuddyEventEngine(contracts: contracts)
        let bundle = try engine.install(
            templateID: "bmo",
            currentState: BuddyLibraryState(),
            currentEvents: BuddyRuntimeEventLog(),
            now: Date(timeIntervalSince1970: 1_744_314_400)
        )

        XCTAssertEqual(originalTemplate.name, "BMO")
        XCTAssertEqual(originalTemplate.moveSet.count, 4)
        XCTAssertEqual(bundle.libraryState.instances.count, 1)
        XCTAssertEqual(bundle.libraryState.activeBuddy?.templateId, "starter.bmo.v1")
        XCTAssertEqual(bundle.libraryState.activeBuddy?.displayName, "BMO")
        XCTAssertEqual(bundle.eventLog.events.first?.type, "buddy.template.installed")

        let receipt = runtime.persistBuddyBundle(bundle)

        XCTAssertEqual(receipt.status, .persisted)
        XCTAssertTrue(FileManager.default.fileExists(atPath: Paths.stateDirectory.appendingPathComponent("buddy-instances.json").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: Paths.openClawDirectory.appendingPathComponent("state/buddy-runtime-events.json").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: Paths.openClawDirectory.appendingPathComponent("buddy.md").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: Paths.openClawDirectory.appendingPathComponent("buddies.md").path))

        let persisted = try XCTUnwrap(BuddyInstanceStore().loadLibraryState())
        XCTAssertEqual(persisted.activeBuddy?.displayName, "BMO")
        XCTAssertEqual(persisted.instances.first?.provenance.derivedFromTemplate, true)
    }

    func testPersonalizeAppendsEventAndRegeneratesBuddyMarkdown() throws {
        let contracts = try BuddyContractLoader.loadCanonicalResources()
        let runtime = OpenClawWorkspaceRuntime()
        runtime.bootstrap(config: .default, preferences: .default, routeSummary: "Direct cloud model route")
        let engine = BuddyEventEngine(contracts: contracts)

        let installBundle = try engine.install(
            templateID: "bmo",
            currentState: BuddyLibraryState(),
            currentEvents: BuddyRuntimeEventLog(),
            now: Date(timeIntervalSince1970: 1_744_314_400)
        )
        _ = runtime.persistBuddyBundle(installBundle)

        let personalized = try engine.personalize(
            instanceID: try XCTUnwrap(installBundle.libraryState.activeBuddy?.instanceId),
            displayName: "BMO Prime",
            nickname: "Bee",
            currentFocus: "Morning planning and continuity",
            currentState: installBundle.libraryState,
            currentEvents: installBundle.eventLog,
            now: Date(timeIntervalSince1970: 1_744_318_000)
        )

        let receipt = runtime.persistBuddyBundle(personalized)
        XCTAssertEqual(receipt.status, .persisted)

        let eventLog = try XCTUnwrap(BuddyInstanceStore().loadEventLog())
        XCTAssertTrue(eventLog.events.contains(where: { $0.type == "buddy.personalized" }))
        XCTAssertTrue(eventLog.events.contains(where: { $0.type == "buddy.memory.promoted" }))

        let buddyMarkdown = try String(contentsOf: Paths.openClawDirectory.appendingPathComponent("buddy.md"), encoding: .utf8)
        XCTAssertTrue(buddyMarkdown.contains("BMO Prime"))
        XCTAssertTrue(buddyMarkdown.contains("## What changed recently"))
        XCTAssertTrue(buddyMarkdown.contains("Morning planning and continuity"))
    }

    func testLegacyBuddySystemMigratesIntoBuild18State() throws {
        let legacyJSON = """
        {
          "profileSignature": "legacy|operator",
          "activeBuddy": {
            "id": "6E3B5675-58CA-4FC9-9D4D-78D9A4E7F001",
            "seed": 42,
            "profileSignature": "legacy|operator",
            "name": "Old Pal",
            "archetype": "robot",
            "title": "Generated Helper",
            "originSummary": "Generated from legacy profile",
            "specialty": "Keeping things moving",
            "personalitySummary": "A legacy generated Buddy",
            "asciiArt": "[o_o]",
            "stats": {
              "bond": 42,
              "power": 55,
              "focus": 61,
              "curiosity": 48,
              "care": 50
            },
            "createdAt": "2026-04-08T12:00:00Z"
          },
          "collection": [],
          "tradeOffers": [],
          "battleHistory": []
        }
        """

        try legacyJSON.write(
            to: Paths.stateDirectory.appendingPathComponent("buddy-system.json"),
            atomically: true,
            encoding: .utf8
        )

        let contracts = try BuddyContractLoader.loadCanonicalResources()
        let migrated = try XCTUnwrap(BuddyInstanceStore().migrateLegacyState(contracts: contracts))

        XCTAssertEqual(migrated.instances.count, 1)
        XCTAssertEqual(migrated.activeBuddy?.displayName, "Old Pal")
        XCTAssertEqual(migrated.activeBuddy?.templateId, "legacy.generated.v1")
        XCTAssertEqual(migrated.activeBuddy?.provenance.installedFrom, "custom_creation")
        XCTAssertEqual(migrated.activeBuddy?.progression.badges, ["legacy_migrated"])
    }

    // Verifies migration succeeds when the legacy file used JSONEncoder defaults
    // (numeric timestamps — seconds since Apple reference date Jan 1 2001).
    func testLegacyBuddySystemMigratesWithNumericDateTimestamps() throws {
        // Date(timeIntervalSinceReferenceDate: 798_897_600) ≈ 2026-04-08T12:00:00Z
        let numericCreatedAt = 798_897_600.0
        let legacyJSON = """
        {
          "profileSignature": "legacy|operator",
          "activeBuddy": {
            "id": "A1B2C3D4-1234-5678-ABCD-000000000001",
            "seed": 7,
            "profileSignature": "legacy|operator",
            "name": "Numeric Pal",
            "archetype": "robot",
            "title": "Numeric Helper",
            "originSummary": "Generated from legacy numeric profile",
            "specialty": "Time handling",
            "personalitySummary": "A legacy Buddy with numeric dates",
            "asciiArt": "[~_~]",
            "stats": {
              "bond": 30,
              "power": 40,
              "focus": 50,
              "curiosity": 35,
              "care": 45
            },
            "createdAt": \(numericCreatedAt)
          },
          "collection": [],
          "tradeOffers": [],
          "battleHistory": []
        }
        """

        try legacyJSON.write(
            to: Paths.stateDirectory.appendingPathComponent("buddy-system.json"),
            atomically: true,
            encoding: .utf8
        )

        let contracts = try BuddyContractLoader.loadCanonicalResources()
        let migrated = try XCTUnwrap(BuddyInstanceStore().migrateLegacyState(contracts: contracts))

        XCTAssertEqual(migrated.instances.count, 1)
        XCTAssertEqual(migrated.activeBuddy?.displayName, "Numeric Pal")
        XCTAssertEqual(migrated.activeBuddy?.templateId, "legacy.generated.v1")
        XCTAssertEqual(migrated.activeBuddy?.provenance.installedFrom, "custom_creation")
        XCTAssertEqual(migrated.activeBuddy?.progression.badges, ["legacy_migrated"])
        // Installed date should decode to a valid non-nil Date (not epoch or distant-past)
        let installedAt = try XCTUnwrap(migrated.activeBuddy?.provenance.installedAt)
        XCTAssertGreaterThan(installedAt.timeIntervalSince1970, 0)
    }
}
