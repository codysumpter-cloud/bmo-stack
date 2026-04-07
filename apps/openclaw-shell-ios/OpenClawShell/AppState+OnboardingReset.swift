import Foundation

@MainActor
extension AppState {
    func resetOnboardingAndReturnToSetup() {
        stackConfig = StackConfig.default
        persistStackConfig()

        chatStore.selectedFileIDs.removeAll()
        chatStore.clear()

        runtimePreferences.selection.selectedInstalledFilename = nil
        runtimePreferences.persist()
        runtimeStatus = "Not configured"
    }
}
