import SwiftUI

struct ModelsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var modelName = ""
    @State private var modelURL = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Add remote model") {
                    TextField("Display name", text: $modelName)
                    TextField("Direct download URL", text: $modelURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)

                    Button("Save model source") {
                        appState.modelStore.addRemoteModel(displayName: modelName, sourceURL: modelURL)
                        modelName = ""
                        modelURL = ""
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
                        Text("Add one or more direct model URLs here. Good first target: a small quantized model file you know your runtime can load later.")
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

                            HStack {
                                ShareLink(item: model.localURL) {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(.bordered)

                                Button("Delete", role: .destructive) {
                                    appState.modelStore.deleteInstalledModel(model)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Models")
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
