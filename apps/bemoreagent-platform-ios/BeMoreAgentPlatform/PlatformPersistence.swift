import Foundation

enum PlatformPaths {
    static var fileManager: FileManager { .default }

    static var appSupport: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("BeMoreAgentPlatform", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static var providersFile: URL { appSupport.appendingPathComponent("provider-accounts.json") }
    static var workspacesFile: URL { appSupport.appendingPathComponent("workspaces.json") }
    static var jobsFile: URL { appSupport.appendingPathComponent("factory-jobs.json") }
    static var sessionsFile: URL { appSupport.appendingPathComponent("sandbox-sessions.json") }
}

enum PlatformPersistence {
    static func save<T: Encodable>(_ value: T, to url: URL) throws {
        let data = try JSONEncoder().encode(value)
        try data.write(to: url, options: [.atomic])
    }

    static func load<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
