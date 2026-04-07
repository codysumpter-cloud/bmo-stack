import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    var body: some View {
        TabView {
            ControlTabView()
                .tabItem { Label("Control", systemImage: "switch.2") }

            ModelsTabView()
                .tabItem { Label("Models", systemImage: "square.and.arrow.down") }

            ChatTabView()
                .tabItem { Label("Chat", systemImage: "message") }

            FilesTabView()
                .tabItem { Label("Files", systemImage: "folder") }

            EditorTabView()
                .tabItem { Label("Editor", systemImage: "chevron.left.forwardslash.chevron.right") }
        }
    }
}

private struct ControlTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                Section("Runtime posture") {
                    LabeledContent("Backend", value: appState.backendDisplayName)
                    LabeledContent("Status", value: appState.runtimeStatus)
                    if let selectedModel = appState.selectedInstalledModel {
                        LabeledContent("Selected model", value: selectedModel.modelID.isEmpty ? selectedModel.localFilename : selectedModel.modelID)
                    } else {
                        LabeledContent("Selected model", value: "None")
                    }
                    Text(appState.operatorSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Local-first defaults") {
                    Text(appState.localFirstSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Prepared local model imports are preferred. Direct model downloads are a deliberate networked path.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Workspace") {
                    Text(appState.workspaceStatusSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    LabeledContent("Stored files", value: "\(appState.workspaceStore.files.count)")
                    LabeledContent("Installed models", value: "\(appState.modelStore.installedModels.count)")
                    LabeledContent("Saved model sources", value: "\(appState.modelStore.remoteModels.count)")
                }

                Section("Operator actions") {
                    Button("Clear conversation", role: .destructive) {
                        appState.chatStore.clear()
                    }
                    Button("Deselect active model") {
                        Task { await appState.setSelectedInstalledModel(filename: nil) }
                    }
                    .disabled(appState.selectedInstalledModel == nil)
                    Button("Clear selected file attachments") {
                        appState.chatStore.selectedFileIDs.removeAll()
                    }
                    .disabled(appState.chatStore.selectedFileIDs.isEmpty)
                }
            }
            .navigationTitle("Control")
        }
    }
}

private struct ModelsTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var modelName = ""
    @State private var modelURL = ""
    @State private var modelID = ""
    @State private var modelLib = ""
    @State private var isModelImporterPresented = false

    var body: some View {
        NavigationStack {
            List {
                Section("Runtime") {
                    LabeledContent("Backend", value: appState.backendDisplayName)
                    LabeledContent("Status", value: appState.runtimeStatus)
                }

                Section("Prepared model import") {
                    Text("Import a prepared model folder or artifact from Files when you already packaged it on your Mac. This is the preferred local-first path.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if appState.usesStubRuntime {
                        Text("The current build is still using the stub runtime, so imports mainly prepare storage and selection metadata until MLCSwift is wired in.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button("Import prepared model") {
                        isModelImporterPresented = true
                    }
                    .buttonStyle(.bordered)
                }

                Section("Add model source") {
                    Text("A saved model source is a convenience for later downloads. It is a networked path, not the default local-first path.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    TextField("Display name", text: $modelName)
                    TextField("Direct download URL", text: $modelURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    TextField("Model ID (for runtime)", text: $modelID)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("modelLib (packaged MLC lib name)", text: $modelLib)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button("Save model source") {
                        appState.modelStore.addRemoteModel(displayName: modelName, sourceURL: modelURL, modelID: modelID, modelLib: modelLib)
                        modelName = ""
                        modelURL = ""
                        modelID = ""
                        modelLib = ""
                    }
                    .buttonStyle(.borderedProminent)
                }

                if let activeDownload = appState.modelStore.activeDownload {
                    Section("Download") {
                        switch activeDownload {
                        case .idle(let modelName):
                            Label("Preparing \(modelName)", systemImage: "arrow.down.circle")
                        case .progress(let modelName, let fraction):
                            VStack(alignment: .leading, spacing: 8) {
                                Text(modelName)
                                ProgressView(value: fraction)
                            }
                        }
                    }
                }

                Section("Saved model sources") {
                    if appState.modelStore.remoteModels.isEmpty {
                        Text("No model sources yet.")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(appState.modelStore.remoteModels) { model in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(model.displayName)
                                .font(.headline)
                            Text(model.sourceURL)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                            if !model.modelID.isEmpty {
                                Text("modelID: \(model.modelID)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            if !model.modelLib.isEmpty {
                                Text("modelLib: \(model.modelLib)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            HStack {
                                Button("Download") {
                                    appState.modelStore.download(model)
                                }
                                .buttonStyle(.borderedProminent)

                                Button("Remove", role: .destructive) {
                                    appState.modelStore.removeRemoteModel(model)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Installed model files") {
                    if appState.modelStore.installedModels.isEmpty {
                        Text("No downloaded model files yet.")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(appState.modelStore.installedModels) { model in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(model.localFilename)
                                .font(.headline)
                            Text(ByteCountFormatter.string(fromByteCount: model.fileSizeBytes, countStyle: .file))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !model.modelID.isEmpty {
                                Text("modelID: \(model.modelID)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            if !model.modelLib.isEmpty {
                                Text("modelLib: \(model.modelLib)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            HStack {
                                Button(appState.runtimePreferences.selection.selectedInstalledFilename == model.localFilename ? "Selected" : "Use") {
                                    Task { await appState.setSelectedInstalledModel(filename: model.localFilename) }
                                }
                                .buttonStyle(.borderedProminent)

                                ShareLink(item: model.localURL) {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(.bordered)

                                Button("Delete", role: .destructive) {
                                    appState.modelStore.deleteInstalledModel(model)
                                    if appState.runtimePreferences.selection.selectedInstalledFilename == model.localFilename {
                                        Task { await appState.setSelectedInstalledModel(filename: nil) }
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Models")
            .fileImporter(
                isPresented: $isModelImporterPresented,
                allowedContentTypes: [.folder, .data],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    appState.modelStore.importPreparedModelItems(from: urls)
                case .failure(let error):
                    appState.modelStore.errorMessage = error.localizedDescription
                }
            }
            .alert("Model error", isPresented: Binding(get: {
                appState.modelStore.errorMessage != nil
            }, set: { _ in
                appState.modelStore.errorMessage = nil
            })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(appState.modelStore.errorMessage ?? "Unknown error")
            }
        }
    }
}

private struct ChatTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var prompt = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !appState.workspaceStore.files.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(appState.workspaceStore.files) { file in
                                let isSelected = appState.chatStore.selectedFileIDs.contains(file.id)
                                Button {
                                    if isSelected {
                                        appState.chatStore.selectedFileIDs.remove(file.id)
                                    } else {
                                        appState.chatStore.selectedFileIDs.insert(file.id)
                                    }
                                } label: {
                                    Label(file.filename, systemImage: isSelected ? "checkmark.circle.fill" : "doc")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                }

                List(appState.chatStore.messages) { message in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(message.role.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(message.content)
                            .textSelection(.enabled)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)

                VStack(spacing: 12) {
                    if appState.usesStubRuntime || appState.selectedInstalledModel == nil {
                        ContentUnavailableView(
                            "Runtime needs attention",
                            systemImage: appState.usesStubRuntime ? "cpu" : "exclamationmark.triangle",
                            description: Text(appState.operatorSummary)
                        )
                        .frame(maxWidth: .infinity)
                    }

                    HStack {
                        TextField(appState.usesStubRuntime ? "Try the shell UI (stub runtime active)" : "Ask your local model", text: $prompt, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(1...5)

                        Button {
                            let value = prompt
                            prompt = ""
                            Task { await appState.send(prompt: value) }
                        } label: {
                            if appState.chatStore.isGenerating {
                                ProgressView()
                            } else {
                                Text("Send")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(appState.chatStore.isGenerating || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (!appState.usesStubRuntime && appState.selectedInstalledModel == nil))
                    }

                    HStack {
                        Text(appState.runtimeStatus)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if !appState.chatStore.selectedFileIDs.isEmpty {
                            Text("• \(appState.chatStore.selectedFileIDs.count) file context")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Clear") {
                            appState.chatStore.clear()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .navigationTitle("Chat")
            .alert("Chat error", isPresented: Binding(get: {
                appState.chatStore.errorMessage != nil
            }, set: { _ in
                appState.chatStore.errorMessage = nil
            })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(appState.chatStore.errorMessage ?? "Unknown error")
            }
        }
    }
}

private struct FilesTabView: View {
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

private struct EditorTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            Group {
                if let file = appState.workspaceStore.selectedFile {
                    if file.isTextLike {
                        EditorWebView(file: file)
                            .environmentObject(appState)
                    } else {
                        ContentUnavailableView("Not a text file", systemImage: "doc", description: Text("Pick a text-like file from Files to edit it here."))
                    }
                } else {
                    ContentUnavailableView("No file selected", systemImage: "chevron.left.forwardslash.chevron.right", description: Text("Choose a file in Files, then edit it here."))
                }
            }
            .navigationTitle("Editor")
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
