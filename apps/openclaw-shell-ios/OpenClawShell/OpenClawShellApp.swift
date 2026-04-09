import SwiftUI

@main
struct BeMoreAgentApp: App {
    @StateObject private var appState = AppState(engine: MLCBridgeEngine())
    @StateObject private var stackStore = StackStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(stackStore)
                .task {
                    await appState.bootstrap()
                    // Auto‑generate a demo stack if onboarding hasn’t been completed yet
                    if !stackStore.isOnboardingComplete {
                        let demoAnswers = QuestionnaireAnswerSet(
                            primaryGoal: "Productivity",
                            userType: "Developer",
                            teamShape: "Solo",
                            autonomyLevel: "Autonomous",
                            memoryPosture: "Persistent",
                            toolPosture: "Permissive",
                            optimizationPriority: "Performance"
                        )
                        let demoStack = StackCompiler.generateStack(from: demoAnswers)
                        stackStore.saveStack(demoStack)
                        stackStore.completeOnboarding()
                    }
                }
        }
    }
}
