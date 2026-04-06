import SwiftUI
import UniformTypeIdentifiers

struct FilesView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isImporterPresented = false

    var body: some View {
        NavigationStack {
            List {
                if appState.workspaceStore.files.isEmpty {
                    ContentUnavailableView("No files yet", systemImage: "folder", description: Text("Import files you want your local assistant to keep around."))
                }

                ForEach(appState.workspaceStore.files) { file in
                    Button {
                        appState.workspaceStore.selectedFile = file
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
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            appState.workspaceStore.delete(file)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Files")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isImporterPresented = true
                    } label: {
                        Label("Import", systemImage: "plus")
                    }
                }
            }
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
            .safeAreaInset(edge: .bottom) {
                if let selected = appState.workspaceStore.selectedFile {
                    TextFilePreview(file: selected)
                        .environmentObject(appState)
                        .frame(maxHeight: 280)
                        .background(.thinMaterial)
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
}
