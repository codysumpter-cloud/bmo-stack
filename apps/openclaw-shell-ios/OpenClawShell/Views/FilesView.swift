import SwiftUI
import UniformTypeIdentifiers

struct FilesView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isImporterPresented = false
    @State private var isCreatePresented = false
    @State private var newFilename = "notes.md"
    @State private var selectedFile: WorkspaceFile?

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
                        isCreatePresented = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(BMOTheme.accent)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isImporterPresented = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(BMOTheme.textSecondary)
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
            .sheet(isPresented: $isCreatePresented) {
                NavigationStack {
                    Form {
                        Section("New workspace file") {
                            TextField("Filename", text: $newFilename)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            Text("Creates a real file in the Files workspace. Markdown, text, JSON, and source files can be edited after creation.")
                                .font(.caption)
                                .foregroundColor(BMOTheme.textTertiary)
                        }
                    }
                    .navigationTitle("Create File")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { isCreatePresented = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Create") {
                                appState.workspaceStore.createFile(named: newFilename, content: "# \(newFilename)\n\n")
                                isCreatePresented = false
                            }
                        }
                    }
                }
            }
            .navigationDestination(item: $selectedFile) { file in
                WorkspaceFileEditorView(file: file)
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

            HStack {
                Button("Create File") {
                    isCreatePresented = true
                }
                .buttonStyle(BMOButtonStyle())

                Button("Import") {
                    isImporterPresented = true
                }
                .buttonStyle(BMOButtonStyle(isPrimary: false))
            }
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
                Button {
                    selectedFile = file
                } label: {
                    Text(file.filename)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(BMOTheme.textPrimary)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
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

            ShareLink(item: file.localURL) {
                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline)
                    .foregroundColor(BMOTheme.textTertiary)
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

struct WorkspaceFileEditorView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let file: WorkspaceFile
    @State private var text = ""
    @State private var isLoaded = false

    var body: some View {
        VStack(spacing: 0) {
            if file.isTextLike {
                TextEditor(text: $text)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(BMOTheme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(BMOTheme.backgroundPrimary)
                    .padding(BMOTheme.spacingMD)
            } else {
                VStack(spacing: BMOTheme.spacingMD) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 44))
                        .foregroundColor(BMOTheme.textTertiary)
                    Text("This file is not editable as text.")
                        .foregroundColor(BMOTheme.textSecondary)
                    ShareLink(item: file.localURL) {
                        Label("Export File", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(BMOButtonStyle())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(BMOTheme.backgroundPrimary)
            }
        }
        .navigationTitle(file.filename)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                ShareLink(item: file.localURL) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if file.isTextLike {
                    Button("Save") {
                        appState.workspaceStore.saveText(text, for: file)
                    }
                    .foregroundColor(BMOTheme.accent)
                }
            }
            ToolbarItem(placement: .bottomBar) {
                Button(role: .destructive) {
                    appState.workspaceStore.delete(file)
                    dismiss()
                } label: {
                    Label("Delete File", systemImage: "trash")
                }
            }
        }
        .onAppear {
            guard !isLoaded else { return }
            text = appState.workspaceStore.readText(for: file)
            isLoaded = true
        }
    }
}
