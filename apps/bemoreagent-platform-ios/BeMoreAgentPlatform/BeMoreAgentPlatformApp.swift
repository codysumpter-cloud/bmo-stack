import SwiftUI

@main
struct BeMoreAgentPlatformApp: App {
    @StateObject private var appState = PlatformAppState()

    var body: some Scene {
        WindowGroup {
            PlatformRootView()
                .environmentObject(appState)
                .task { appState.bootstrap() }
        }
    }
}
