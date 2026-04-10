import SwiftUI

struct ArtifactsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedArtifact: OpenClawArtifactMetadata?
    @State private var lastReceipt: OpenClawReceipt?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BMOTheme.spacingMD) {
                    header
                    if let lastReceipt {
                        ActionReceiptCard(receipt: lastReceipt)
                    }
                    ForEach(appState.workspaceRuntime.artifacts) { artifact in
                        Button {
                            selectedArtifact = artifact
                        } label: {
                            artifactRow(artifact)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, BMOTheme.spacingMD)
                .padding(.bottom, BMOTheme.spacingXL)
            }
            .background(BMOTheme.backgroundPrimary)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Artifacts")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        lastReceipt = appState.regenerateArtifacts(target: "all")
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(BMOTheme.accent)
                    }
                }
            }
            .toolbarBackground(BMOTheme.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear { appState.workspaceRuntime.refreshMetadata() }
            .navigationDestination(item: $selectedArtifact) { artifact in
                ArtifactPreviewView(artifact: artifact)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(".openclaw")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(BMOTheme.textPrimary)
                Spacer()
                StatusBadge(label: "\(appState.workspaceRuntime.artifacts.count) files", color: BMOTheme.accent)
            }
            Text("Canonical files, state stores, action receipts, event logs, registry data, and saved skill outputs live here.")
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)
        }
        .bmoCard()
    }

    private func artifactRow(_ artifact: OpenClawArtifactMetadata) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: artifact.kind == "markdown" ? "doc.text.fill" : "curlybraces.square.fill")
                .foregroundColor(BMOTheme.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 5) {
                Text(artifact.path)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(BMOTheme.textPrimary)
                Text("\(artifact.kind) • \(artifact.size) bytes")
                    .font(.caption)
                    .foregroundColor(BMOTheme.textTertiary)
                if let updatedAt = artifact.updatedAt {
                    Text(updatedAt, style: .relative)
                        .font(.caption2)
                        .foregroundColor(BMOTheme.textTertiary)
                }
            }

            Spacer()
            StatusBadge(label: artifact.freshness.rawValue.capitalized, color: artifact.freshness == .missing ? BMOTheme.error : BMOTheme.success)
        }
        .bmoCard()
    }
}

struct ArtifactPreviewView: View {
    @EnvironmentObject private var appState: AppState
    let artifact: OpenClawArtifactMetadata
    @State private var content = ""
    @State private var error: String?
    @State private var receipt: OpenClawReceipt?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BMOTheme.spacingMD) {
                header
                if let receipt {
                    ActionReceiptCard(receipt: receipt)
                }
                if let error {
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(BMOTheme.error)
                        .bmoCard()
                } else {
                    Text(content.isEmpty ? "Empty artifact." : content)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(BMOTheme.textPrimary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .bmoCard()
                }
            }
            .padding(.horizontal, BMOTheme.spacingMD)
            .padding(.bottom, BMOTheme.spacingXL)
        }
        .background(BMOTheme.backgroundPrimary)
        .navigationTitle(artifact.path)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if ["soul.md", "user.md", "memory.md", "session.md", "skills.md"].contains(artifact.path) {
                    Button("Regenerate") {
                        receipt = appState.regenerateArtifacts(target: artifact.path)
                        load()
                    }
                    .foregroundColor(BMOTheme.accent)
                }
            }
        }
        .onAppear(perform: load)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(artifact.path)
                .font(.headline)
                .foregroundColor(BMOTheme.textPrimary)
            Text("Preview is read from the persisted `.openclaw` artifact.")
                .font(.caption)
                .foregroundColor(BMOTheme.textTertiary)
        }
        .bmoCard()
    }

    private func load() {
        do {
            content = try appState.workspaceRuntime.readFile(artifact.path)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}
