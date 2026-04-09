import SwiftUI

struct StackPreviewView: View {
    @EnvironmentObject private var stackStore: StackStore
    @State private var showDashboard = false
    
    var body: some View {
        VStack(spacing: 20) {
            if let stack = stackStore.stack {
                VStack(alignment: .leading, spacing: 16) {
                    Text(stack.name)
                        .font(.title2)
                        .bold()
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Primary Assistant")
                            .font(.headline)
                        AgentCardView(agent: stack.primaryAssistant)
                        
                        if !stack.supportingAgents.isEmpty {
                            Text("Supporting Agents")
                                .font(.headline)
                            ForEach(stack.supportingAgents) { agent in
                                AgentCardView(agent: agent)
                                    .padding(.leading)
                            }
                        }
                        
                        if !stack.workflows.isEmpty {
                            Text("Workflows")
                                .font(.headline)
                            ForEach(stack.workflows) { workflow in
                                WorkflowCardView(workflow: workflow)
                                    .padding(.leading)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Memory Profile")
                                .font(.headline)
                            Label("Persistence: \(stack.memoryProfile.persistenceLevel.rawValue.capitalized)", systemImage: "dollarsign.circle")
                            Label("Retention: \(stack.memoryProfile.retentionPolicy.rawValue.capitalized)", systemImage: "clock")
                            Label("Storage: \(stack.memoryProfile.storageLocation.rawValue.capitalized)", systemImage: "externaldrive")
                            Label("Encryption: \(stack.memoryProfile.encryptionEnabled ? "Enabled" : "Disabled")", systemImage: "lock")
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Model Preferences")
                                .font(.headline)
                            Label("Backend: \(stack.modelPreferenceProfile.preferredBackend.rawValue.capitalized)", systemImage: "cpu")
                            Label("Quantization: \(stack.modelPreferenceProfile.quantizationPreference.rawValue.uppercased())", systemImage: "memorychip")
                            Label("Context Size: \(stack.modelPreferenceProfile.contextSizePreference.rawValue.capitalized)", systemImage: "textformat.size")
                            Label("Performance/Quality: \(stack.modelPreferenceProfile.performanceVsQuality.rawValue.capitalized)", systemImage: "gauge")
                        }
                    }
                    
                    Button("Start Using Stack") {
                        showDashboard = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                ProgressView("Generating your stack...")
            }
        }
        .padding()
        .fullScreenCover(isPresented: $showDashboard) {
            DashboardView()
                .environmentObject(stackStore)
        }
    }
}

struct AgentCardView: View {
    let agent: AgentProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(agent.name)
                .font(.headline)
            Text(agent.role)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(agent.description)
                .font(.footnote)
                .foregroundStyle(.secondary)
            
            if !agent.capabilities.isEmpty {
                Text("Capabilities")
                    .font(.caption)
                    .bold()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(agent.capabilities, id: \.self) { capability in
                            Text(capability)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.secondary.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            if !agent.personalityTraits.isEmpty {
                Text("Personality")
                    .font(.caption)
                    .bold()
                Text(agent.personalityTraits.joined(separator: ", "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

struct WorkflowCardView: View {
    let workflow: WorkflowProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(workflow.name)
                .font(.headline)
            Text(workflow.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if !workflow.steps.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Steps")
                        .font(.caption)
                        .bold()
                    ForEach(workflow.steps, id: \.self) { step in
                        Label(step, systemImage: "checkmark.circle")
                            .font(.caption2)
                    }
                }
            }
            
            if !workflow.triggers.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Triggers")
                        .font(.caption)
                        .bold()
                    Text(workflow.triggers.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}