import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var stackStore: StackStore
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Dashboard header
            VStack(spacing: 12) {
                if let stack = stackStore.stack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(stack.name)
                                .font(.title2)
                                .bold()
                            Text("Active Stack")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: resetStack) {
                            Label("Reset Stack", systemImage: "arrow.counterclockwise")
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    
                    Divider()
                    
                    // Stack summary cards
                    HStack(spacing: 16) {
                        VStack {
                            Label("Primary Agent", systemImage: "person.fill")
                                .font(.caption2)
                            Text(stackStore.stack?.primaryAssistant.name ?? "-")
                                .font(.headline)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack {
                            Label("Supporting Agents", systemImage: "person.2.fill")
                                .font(.caption2)
                            Text("\(stackStore.stack?.supportingAgents.count ?? 0)")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack {
                            Label("Workflows", systemImage: "repeat")
                                .font(.caption2)
                            Text("\(stackStore.stack?.workflows.count ?? 0)")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                }
            }
            
            Divider()
            
            // Quick actions
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Actions")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    QuickActionButton(label: "New Chat", icon: "message.fill", action: {})
                    QuickActionButton(label: "Browse Files", icon: "folder.fill", action: {})
                    QuickActionButton(label: "Models", icon: "square.and.arrow.down.fill", action: {})
                    QuickActionButton(label: "Editor", icon: "chevron.left.forwardslash.chevron.right", action: {})
                }
                .padding(.horizontal)
            }
            
            Divider()
            
            // Recent files
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Files")
                    .font(.headline)
                    .padding(.horizontal)
                
                if let files = stackStore.stack.flatMap({ $0 }) { // Placeholder - would connect to workspace store
                    // For now, show a placeholder
                    Text("No recent files yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                } else {
                    Text("No recent files yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
            
            Spacer()
            
            // Tab bar
            HStack {
                TabBarButton(icon: "square.and.arrow.down", label: "Models", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                TabBarButton(icon: "message", label: "Chat", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                TabBarButton(icon: "folder", label: "Files", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
                TabBarButton(icon: "chevron.left.forwardslash.chevron.right", label: "Editor", isSelected: selectedTab == 3) {
                    selectedTab = 3
                }
            }
            .padding(.vertical, 8)
            .background(.thinMaterial)
        }
        .background(.ultraThinMaterial)
        .ignoresSafeArea(edges: .bottom)
    }
    
    private func resetStack() {
        stackStore.resetStack()
    }
}

struct QuickActionButton: View {
    let label: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.secondary.opacity(0.1))
        .cornerRadius(8)
        .onTapGesture(perform: action)
    }
}

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(isSelected ? .title2 : .title3)
                .foregroundColor(isSelected ? .primary : .secondary)
            Text(label)
                .font(.caption2)
                .foregroundColor(isSelected ? .primary : .secondary)
                .fontWeight(isSelected ? .semibold : .regular)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(isSelected ? .primary.opacity(0.1) : .clear)
        .cornerRadius(4)
        .onTapGesture(perform: action)
    }
}