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
                Text("Results")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(BMOTheme.textPrimary)
                Spacer()
                StatusBadge(label: "\(appState.workspaceRuntime.artifacts.count) files", color: BMOTheme.accent)
            }
            Text("Canonical state, receipts, event logs, registry data, and saved Buddy skill outputs live here.")
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
    @Environment(\.dismiss) private var dismiss
    let artifact: OpenClawArtifactMetadata
    @State private var content = ""
    @State private var error: String?
    @State private var receipt: OpenClawReceipt?
    @State private var isEditing = false

    var body: some View {
        Group {
            if isEditing {
                VStack(spacing: 0) {
                    TextEditor(text: $content)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(BMOTheme.textPrimary)
                        .scrollContentBackground(.hidden)
                        .background(BMOTheme.backgroundPrimary)
                        .padding(BMOTheme.spacingMD)
                }
            } else {
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
                            actionBar
                            preview
                        }
                    }
                    .padding(.horizontal, BMOTheme.spacingMD)
                    .padding(.bottom, BMOTheme.spacingXL)
                }
            }
        }
        .background(BMOTheme.backgroundPrimary)
        .navigationTitle(artifact.path)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if let url = try? appState.workspaceRuntime.fileURL(for: artifact.path) {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if isEditing {
                    Button("Save") {
                        receipt = appState.writeWorkspaceArtifact(path: artifact.path, content: content)
                        isEditing = false
                        load()
                    }
                    .foregroundColor(BMOTheme.accent)
                } else {
                    Button("Edit") {
                        isEditing = true
                    }
                    .foregroundColor(BMOTheme.accent)
                }
            }
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    if ["soul.md", "user.md", "memory.md", "session.md", "skills.md"].contains(artifact.path) {
                        Button("Regenerate") {
                            receipt = appState.regenerateArtifacts(target: artifact.path)
                            load()
                        }
                        .foregroundColor(BMOTheme.accent)
                    }

                    Spacer()

                    Button(role: .destructive) {
                        receipt = appState.deleteWorkspaceArtifact(path: artifact.path)
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .onAppear(perform: load)
    }

    private var preview: some View {
        Text(content.isEmpty ? "Empty artifact." : content)
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(BMOTheme.textPrimary)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .bmoCard()
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            Button {
                isEditing = true
            } label: {
                Label("Edit", systemImage: "pencil")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(BMOButtonStyle(isPrimary: false))

            if let url = try? appState.workspaceRuntime.fileURL(for: artifact.path) {
                ShareLink(item: url) {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BMOButtonStyle(isPrimary: false))
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(artifact.path)
                .font(.headline)
                .foregroundColor(BMOTheme.textPrimary)
            Text("Read, edit, export, or delete this persisted `Results` artifact. Canonical markdown can also be regenerated.")
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
