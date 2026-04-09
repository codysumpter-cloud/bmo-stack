import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var stackStore: StackStore
    
    var body: some View {
        Group {
            if !stackStore.isOnboardingComplete {
                // Show onboarding flow
                OnboardingFlowView()
                    .environmentObject(stackStore)
            } else if stackStore.stack == nil {
                // Show preview while stack is being generated (should be brief)
                StackPreviewView()
                    .environmentObject(stackStore)
            } else {
                // Show dashboard once stack is ready
                DashboardView()
                    .environmentObject(stackStore)
            }
        }
    }
}