import SwiftUI

@main
struct BeMoreAgentApp: App {
    @StateObject private var appState = AppState(engine: LiteRTLMEngine())

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .task {
                    await appState.bootstrap()
                }
        }
    }
}
