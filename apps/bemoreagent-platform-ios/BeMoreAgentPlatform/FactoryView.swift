import SwiftUI

struct FactoryView: View {
    @EnvironmentObject private var appState: PlatformAppState
    @State private var description = ""
    @State private var templateName = "agent-workspace"
    @State private var target = "Cloud Run"
    @State private var modelSlug = "gemini-2.5-flash"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Describe what you want to generate", text: $description, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...8)
                        TextField("Template", text: $templateName)
                            .textFieldStyle(.roundedBorder)
                        TextField("Target", text: $target)
                            .textFieldStyle(.roundedBorder)
                        TextField("Preferred model", text: $modelSlug)
                            .textFieldStyle(.roundedBorder)
                        Button("Queue Generation") {
                            appState.enqueueGeneration(description: description, templateName: templateName, target: target, modelSlug: modelSlug)
                            description = ""
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .platformCard()

                    ForEach(appState.jobs) { job in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(job.templateName)
                                    .font(.headline)
                                    .foregroundColor(PlatformTheme.textPrimary)
                                Spacer()
                                PillBadge(text: job.status.rawValue.capitalized, color: job.status == .completed ? PlatformTheme.success : PlatformTheme.warning)
                            }
                            Text(job.description)
                                .font(.subheadline)
                                .foregroundColor(PlatformTheme.textSecondary)
                            ProgressView(value: job.progress)
                                .tint(PlatformTheme.accent)
                            Text(job.target)
                                .font(.caption)
                                .foregroundColor(PlatformTheme.textTertiary)
                        }
                        .platformCard()
                    }
                }
                .padding(16)
            }
            .background(PlatformTheme.background)
            .navigationTitle("App Factory")
        }
    }
}
