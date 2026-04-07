import SwiftUI
import UniformTypeIdentifiers

struct FilesView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isImporterPresented = false

    var body: some View {
        NavigationStack {
            ZStack {
                BMOTheme.backgroundPrimary.ignoresSafeArea()

                if appState.workspaceStore.files.isEmpty {
                    emptyState
                } else {
                    filesList
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Files")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isImporterPresented = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(BMOTheme.accent)
                    }
                }
            }
            .toolbarBackground(BMOTheme.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .fileImporter(
                isPresented: $isImporterPresented,
                allowedContentTypes: [.data, .plainText, .json, .sourceCode, .xml, .commaSeparatedText, .text],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    appState.workspaceStore.importFiles(from: urls)
                case .failure(let error):
                    appState.workspaceStore.errorMessage = error.localizedDescription
                }
            }
            .alert("Files error", isPresented: Binding(get: {
                appState.workspaceStore.errorMessage != nil
            }, set: { _ in
                appState.workspaceStore.errorMessage = nil
            })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(appState.workspaceStore.errorMessage ?? "Unknown error")
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: BMOTheme.spacingMD) {
            Image(systemName: "folder")
                .font(.system(size: 48))
                .foregroundColor(BMOTheme.textTertiary)
            Text("No files yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(BMOTheme.textPrimary)
            Text("Import files your agent can reference\nduring conversations.")
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button("Import Files") {
                isImporterPresented = true
            }
            .buttonStyle(BMOButtonStyle())
            .padding(.top, BMOTheme.spacingSM)
        }
    }

    // MARK: - Files list

    private var filesList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(appState.workspaceStore.files) { file in
                    fileRow(file)
                }
            }
            .padding(.horizontal, BMOTheme.spacingMD)
            .padding(.vertical, BMOTheme.spacingSM)
        }
    }

    private func fileRow(_ file: WorkspaceFile) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: BMOTheme.radiusSmall, style: .continuous)
                    .fill(BMOTheme.accent.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: iconForExtension(file.ext))
                    .foregroundColor(BMOTheme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(file.filename)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(BMOTheme.textPrimary)
                    .lineLimit(1)
                Text(file.ext.uppercased())
                    .font(.caption2)
                    .foregroundColor(BMOTheme.textTertiary)
            }

            Spacer()

            let isAttached = appState.chatStore.selectedFileIDs.contains(file.id)
            Button {
                if isAttached {
                    appState.chatStore.selectedFileIDs.remove(file.id)
                } else {
                    appState.chatStore.selectedFileIDs.insert(file.id)
                }
            } label: {
                Image(systemName: isAttached ? "link.circle.fill" : "link.circle")
                    .font(.title3)
                    .foregroundColor(isAttached ? BMOTheme.accent : BMOTheme.textTertiary)
            }

            Button(role: .destructive) {
                appState.workspaceStore.delete(file)
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .foregroundColor(BMOTheme.error.opacity(0.6))
            }
        }
        .bmoCard()
    }

    private func iconForExtension(_ ext: String) -> String {
        switch ext {
        case "swift", "py", "js", "ts", "go", "rs", "java", "c", "cpp", "h":
            return "chevron.left.forwardslash.chevron.right"
        case "json", "yaml", "yml", "toml", "xml":
            return "doc.text"
        case "md", "txt":
            return "doc.plaintext"
        case "csv":
            return "tablecells"
        default:
            return "doc"
        }
    }
}
