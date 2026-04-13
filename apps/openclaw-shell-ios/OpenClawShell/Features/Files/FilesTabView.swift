import SwiftUI
import UniformTypeIdentifiers

struct FilesTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isImporterPresented = false

    var body: some View {
        NavigationStack {
            mainList
                .navigationTitle(\"Files\")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isImporterPresented = true
                        } label: {
                            Label(\"Import\", systemImage: \"plus\")
                        }
                    }
                }
                .fileImporter(
                    isPresented: $isImporterPresented,
                    allowedContentTypes: [.data, .plainText, .json, .sourceCode, .xml, .commaSeparatedText, .text],
                    allowsMultipleSelection: true
                ) { result in
                    handleImport(result)
                }
                .safeAreaInset(edge: .bottom) {
                    bottomPreview
                }
                .alert(\"Files error\", isPresented: Binding(get: {
                    appState.workspaceStore.errorMessage != nil
                }, set: { _ in
                    appState.workspaceStore.errorMessage = nil
                })) {
                    Button(\"OK\", role: .cancel) {}
                } message: {
                    Text(appState.workspaceStore.errorMessage ?? \"Unknown error\")
                }
        }
    }

    private var mainList: some View {
        List {
            if let stack = appState.activeStack {
                Section(\"Stack Workspace\") {
                    Text(stack.workspaceGuidance)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if appState.workspaceStore.files.isEmpty {
                ContentUnavailableView(
                    \"No files yet\",
                    systemImage: \"folder\",
                    description: Text(appState.activeStack?.workspaceGuidance ?? \"Import files you want your local assistant to keep around.\")
                )
            }

            ForEach(appState.workspaceStore.files) { file in
                fileRow(for: file)
            }
        }
    }

    private func fileRow(for file: WorkspaceFile) -> some View {
        Button {
            appState.workspaceStore.selectedFile = file
            if let stack = appState.activeStack, stack.enabledSurfaces.contains(.editor) {
                appState.route(to: .editor)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(file.filename)
                    Text(file.localURL.lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if appState.workspaceStore.selectedFile?.id == file.id {
                    Image(systemName: \"checkmark.circle.fill\")
                }
            }
        }
        .swipeActions {
            Button(role: .destructive) {
                appState.workspaceStore.delete(file)
            } label: {
                Label(\"Delete\", systemImage: \"trash\")
            }
        }
    }

    private var bottomPreview: some View {
        Group {
            if let selected = appState.workspaceStore.selectedFile {
                TextFilePreview(file: selected)
                    .environmentObject(appState)
                    .frame(maxHeight: 280)
                    .background(.thinMaterial)
            }
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            appState.workspaceStore.importFiles(from: urls)
        case .failure(let error):
            appState.workspaceStore.errorMessage = error.localizedDescription
        }
    }
}

private struct TextFilePreview: View {
    @EnvironmentObject private var appState: AppState
    let file: WorkspaceFile

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(file.filename)
                    .font(.headline)
                Spacer()
                Text(file.ext.uppercased())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            if file.isTextLike {
                ScrollView {
                    Text(appState.workspaceStore.readText(for: file))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .font(.system(.footnote, design: .monospaced))
                        .padding(.bottom, 12)
                }
            } else {
                Text("Preview unavailable for this file type.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
