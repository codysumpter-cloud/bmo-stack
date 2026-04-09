import Foundation

final class StackStore: ObservableObject {
    @Published private(set) var stack: UserStack?
    @Published private(set) var isOnboardingComplete: Bool = false
    
    private let stackKey = "userStack"
    private let onboardingKey = "onboardingComplete"
    
    init() {
        loadStack()
        checkOnboardingStatus()
    }
    
    private func loadStack() {
        guard let data = UserDefaults.standard.data(forKey: stackKey),
              let decoded = try? JSONDecoder().decode(UserStack.self, from: data) else {
            return
        }
        stack = decoded
    }
    
    private func checkOnboardingStatus() {
        isOnboardingComplete = UserDefaults.standard.bool(forKey: onboardingKey)
    }
    
    func saveStack(_ stack: UserStack) {
        self.stack = stack
        if let encoded = try? JSONEncoder().encode(stack) {
            UserDefaults.standard.set(encoded, forKey: stackKey)
        }
    }
    
    func completeOnboarding() {
        isOnboardingComplete = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }
    
    func resetStack() {
        stack = nil
        isOnboardingComplete = false
        UserDefaults.standard.removeObject(forKey: stackKey)
        UserDefaults.standard.set(false, forKey: onboardingKey)
    }
    
    func hasValidStack() -> Bool {
        return stack != nil && isOnboardingComplete
    }
}