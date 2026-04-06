import SwiftUI

@main
struct OpenClawShellApp: App {
    // Use OmniLLMEngine for real API integration, or StubLLMEngine for testing
    @StateObject private var appState = AppState(engine: OmniLLMEngine(
        baseURL: "https://app.prismtek.dev",
        authToken: nil,  // Add your token here if needed
        useLocal: false
    ))

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
