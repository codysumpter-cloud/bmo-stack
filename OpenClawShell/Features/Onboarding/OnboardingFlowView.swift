import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var stackStore: StackStore
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var currentStep = 0
    
    private let totalSteps = 7
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            ProgressView(value: Double(currentStep), total: Double(totalSteps))
                .progressViewStyle(.linear)
                .padding()
            
            TabView(selection: $currentStep) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    OnboardingStepView(step: step, answerSet: $viewModel.answerSet)
                        .tag(step)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Navigation buttons
            HStack {
                Button("Back") {
                    if currentStep > 0 {
                        currentStep -= 1
                    }
                }
                .disabled(currentStep == 0)
                
                Spacer()
                
                Button(currentStep < totalSteps - 1 ? "Next" : "Generate Stack") {
                    if currentStep < totalSteps - 1 {
                        currentStep += 1
                    } else {
                        generateStack()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.isValidForStep(currentStep))
            }
            .padding()
        }
        .padding(.top, 8)
    }
    
    private func generateStack() {
        Task {
            let stack = StackCompiler.generateStack(from: viewModel.answerSet)
            stackStore.saveStack(stack)
            stackStore.completeOnboarding()
        }
    }
}

final class OnboardingViewModel: ObservableObject {
    @Published var answerSet = QuestionnaireAnswerSet()
    
    func isValidForStep(_ step: Int) -> Bool {
        switch step {
        case 0: return !answerSet.primaryGoal.isEmpty
        case 1: return !answerSet.userType.isEmpty
        case 2: return !answerSet.teamShape.isEmpty
        case 3: return !answerSet.autonomyLevel.isEmpty
        case 4: return !answerSet.memoryPosture.isEmpty
        case 5: return !answerSet.toolPosture.isEmpty
        case 6: return !answerSet.optimizationPriority.isEmpty
        default: return true
        }
    }
}

struct OnboardingStepView: View {
    let step: Int
    @Binding var answerSet: QuestionnaireAnswerSet
    
    private let questions = [
        "What's your primary goal for using OpenClaw?",
        "How would you describe your user type?",
        "What's your team shape or collaboration style?",
        "What autonomy level do you prefer for your agents?",
        "How do you want to handle memory and persistence?",
        "What's your preferred tool access posture?",
        "What's your optimization priority?"
    ]
    
    private let placeholders = [
        "e.g., personal productivity, team collaboration, automation",
        "e.g., individual developer, team lead, researcher, executive",
        "e.g., solo, small team (2-5), medium team (5-20), large team",
        "e.g., fully autonomous, supervised, collaborative, manual approval",
        "e.g., transient, session-based, persistent, permanent storage",
        "e.g., restrictive, balanced, permissive, external integrations",
        "e.g., response quality, speed, cost-effectiveness, versatility"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text(questions[step])
                .font(.title3)
                .multilineTextAlignment(.center)
            
            TextField(placeholders[step], text: binding(for: step))
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    private func binding(for step: Int) -> Binding<String> {
        switch step {
        case 0: return $answerSet.primaryGoal
        case 1: return $answerSet.userType
        case 2: return $answerSet.teamShape
        case 3: return $answerSet.autonomyLevel
        case 4: return $answerSet.memoryPosture
        case 5: return $answerSet.toolPosture
        case 6: return $answerSet.optimizationPriority
        default: return .constant("")
        }
    }
}