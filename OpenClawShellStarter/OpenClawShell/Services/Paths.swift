import Foundation

enum Paths {
    static let appFolderName = "OpenClaw"
    static let workspaceFolderName = "OpenClawWorkspace"

    static var fileManager: FileManager { .default }

    static var applicationSupportDirectory: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent(appFolderName, isDirectory: true)
        ensureDirectoryExists(folder)
        return folder
    }

    static var modelsDirectory: URL {
        let folder = applicationSupportDirectory.appendingPathComponent("Models", isDirectory: true)
        ensureDirectoryExists(folder)
        return folder
    }

    static var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var workspaceDirectory: URL {
        let folder = documentsDirectory.appendingPathComponent(workspaceFolderName, isDirectory: true)
        ensureDirectoryExists(folder)
        return folder
    }

    static var stateDirectory: URL {
        let folder = applicationSupportDirectory.appendingPathComponent("State", isDirectory: true)
        ensureDirectoryExists(folder)
        return folder
    }

    static var chatStateFile: URL {
        stateDirectory.appendingPathComponent("chat.json")
    }

    static var modelCatalogFile: URL {
        stateDirectory.appendingPathComponent("remote-models.json")
    }

    private static func ensureDirectoryExists(_ url: URL) {
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}
