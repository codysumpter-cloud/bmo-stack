import Foundation

enum BuddyBundledResource: String, CaseIterable {
    case creationOptions = "config/buddy/buddy-creation-options.v1.json"
    case progression = "config/buddy/buddy-progression.v1.json"
    case runtimeEvents = "config/buddy/buddy-runtime-events.v1.json"
    case stateMachine = "config/buddy/buddy-state-machine.v1.json"
    case councilStarterPack = "config/buddy/council-starter-pack.v1.json"
    case creationOptionsSchema = "schemas/buddy-creation-options.schema.json"
    case instanceSchema = "schemas/buddy-instance.schema.json"
    case runtimeEventsSchema = "schemas/buddy-runtime-events.schema.json"
    case stateMachineSchema = "schemas/buddy-state-machine.schema.json"
    case buddySystemSchema = "schemas/buddy-system.schema.json"
    case templatePackageSchema = "schemas/buddy-template-package.schema.json"
    case instanceExample = "examples/buddy/buddy-instance.example.v1.json"
    case runtimeEventsExample = "examples/buddy/buddy-runtime-events.example.v1.json"
    case stateMachineExample = "examples/buddy/buddy-state-machine.example.v1.json"
    case templatePackageExample = "examples/buddy/buddy-template-package.example.v1.json"
    case buddySystemDoc = "docs/BUDDY_SYSTEM.md"
    case councilStarterDoc = "docs/COUNCIL_STARTER_PACK.md"

    var filename: String {
        URL(fileURLWithPath: rawValue).lastPathComponent
    }

    var resourceName: String {
        filename.replacingOccurrences(of: ".\(resourceExtension)", with: "")
    }

    var resourceExtension: String {
        URL(fileURLWithPath: rawValue).pathExtension
    }
}

struct BuddyCanonicalResources {
    var creationOptions: BuddyCreationOptions
    var progression: BuddyProgressionConfig
    var runtimeEvents: BuddyRuntimeEventCatalog
    var stateMachine: BuddyStateMachine
    var councilStarterPack: CouncilStarterPack

    var templates: [CouncilStarterBuddyTemplate] {
        councilStarterPack.councilStarterPack
    }

    var templatesByID: [String: CouncilStarterBuddyTemplate] {
        Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })
    }

    func template(id: String) -> CouncilStarterBuddyTemplate? {
        templatesByID[id]
    }

    func templateForInstance(_ instance: BuddyInstance) -> CouncilStarterBuddyTemplate? {
        if let exact = templates.first(where: { $0.templateID == instance.templateId }) {
            return exact
        }
        return templates.first(where: { instance.templateId.contains($0.id) })
    }
}

enum BuddyContractLoaderError: LocalizedError {
    case missingResource(String)
    case invalidText(String)
    case decodeFailed(String, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .missingResource(let path):
            return "Missing bundled Buddy resource: \(path)"
        case .invalidText(let path):
            return "Could not decode bundled Buddy text resource: \(path)"
        case .decodeFailed(let path, let underlying):
            return "Could not decode \(path): \(underlying.localizedDescription)"
        }
    }
}

private final class BuddyBundleToken {}

enum BuddyContractLoader {
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    static func loadCanonicalResources(bundle: Bundle? = nil) throws -> BuddyCanonicalResources {
        BuddyCanonicalResources(
            creationOptions: try decode(BuddyCreationOptions.self, resource: .creationOptions, bundle: bundle),
            progression: try decode(BuddyProgressionConfig.self, resource: .progression, bundle: bundle),
            runtimeEvents: try decode(BuddyRuntimeEventCatalog.self, resource: .runtimeEvents, bundle: bundle),
            stateMachine: try decode(BuddyStateMachine.self, resource: .stateMachine, bundle: bundle),
            councilStarterPack: try decode(CouncilStarterPack.self, resource: .councilStarterPack, bundle: bundle)
        )
    }

    static func decode<T: Decodable>(_ type: T.Type, resource: BuddyBundledResource, bundle: Bundle? = nil) throws -> T {
        let data = try loadData(resource: resource, bundle: bundle)
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw BuddyContractLoaderError.decodeFailed(resource.rawValue, underlying: error)
        }
    }

    static func loadData(resource: BuddyBundledResource, bundle: Bundle? = nil) throws -> Data {
        guard let url = url(for: resource, bundle: bundle) else {
            throw BuddyContractLoaderError.missingResource(resource.rawValue)
        }
        return try Data(contentsOf: url)
    }

    static func loadText(resource: BuddyBundledResource, bundle: Bundle? = nil) throws -> String {
        let data = try loadData(resource: resource, bundle: bundle)
        guard let text = String(data: data, encoding: .utf8) else {
            throw BuddyContractLoaderError.invalidText(resource.rawValue)
        }
        return text
    }

    static func url(for resource: BuddyBundledResource, bundle: Bundle? = nil) -> URL? {
        for candidate in candidateBundles(preferred: bundle) {
            if let direct = directURL(for: resource, in: candidate) {
                return direct
            }
            if let flat = candidate.url(forResource: resource.resourceName, withExtension: resource.resourceExtension) {
                return flat
            }
            if let discovered = recursiveLookup(for: resource.filename, in: candidate) {
                return discovered
            }
        }
        return nil
    }

    private static func candidateBundles(preferred: Bundle?) -> [Bundle] {
        let bundles = ([preferred].compactMap { $0 } + [Bundle.main, Bundle(for: BuddyBundleToken.self)] + Bundle.allBundles + Bundle.allFrameworks)
        var seen: Set<URL> = []
        return bundles.filter { bundle in
            let url = bundle.bundleURL.standardizedFileURL
            if seen.contains(url) {
                return false
            }
            seen.insert(url)
            return true
        }
    }

    private static func directURL(for resource: BuddyBundledResource, in bundle: Bundle) -> URL? {
        guard let root = bundle.resourceURL else { return nil }
        let url = root.appendingPathComponent(resource.rawValue)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private static func recursiveLookup(for filename: String, in bundle: Bundle) -> URL? {
        guard let root = bundle.resourceURL,
              let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else {
            return nil
        }

        for case let url as URL in enumerator where url.lastPathComponent == filename {
            return url
        }
        return nil
    }
}
