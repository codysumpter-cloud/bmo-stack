import SwiftUI

@main
struct OpenClawShellApp: App {
    @StateObject private var appState = AppState(engine: MLCBridgeEngine())
    @StateObject private var stackStore = StackStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(stackStore)
                .task {
                    await appState.bootstrap()
                }
        }
    }
}
