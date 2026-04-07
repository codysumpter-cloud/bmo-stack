import SwiftUI
import UniformTypeIdentifiers

struct ModelsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isModelImporterPresented = false
    @State private var showAddSource = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BMOTheme.spacingMD) {
                    recommendedModelCard
                    runtimeInfoCard
                    installedModelsSection
                    savedSourcesSection
                }
                .padding(.horizontal, BMOTheme.spacingMD)
                .padding(.bottom, BMOTheme.spacingXL)
            }
            .background(BMOTheme.backgroundPrimary)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Models")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            isModelImporterPresented = true
                        } label: {
                            Label("Import prepared model", systemImage: "folder")
                        }
                        Button {
                            showAddSource = true
                        } label: {
                            Label("Add model source URL", systemImage: "link")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(BMOTheme.accent)
                    }
                }
            }
            .toolbarBackground(BMOTheme.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
            .sheet(isPresented: $showAddSource) {
                AddModelSourceSheet()
                    .environmentObject(appState)
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

    // MARK: - Recommended model

    private var recommendedModelCard: some View {
        let model = KnownModel.gemma4E2B

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Recommended")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(BMOTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(BMOTheme.accent.opacity(0.12))
                    .clipShape(Capsule())
                Spacer()
            }

            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: BMOTheme.radiusSmall, style: .continuous)
                        .fill(BMOTheme.accent.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: "cpu")
                        .font(.title2)
                        .foregroundColor(BMOTheme.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(model.name)
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                    Text("\(model.parameterCount) parameters • \(model.family)")
                        .font(.caption)
                        .foregroundColor(BMOTheme.textSecondary)
                    Text(model.description)
                        .font(.caption)
                        .foregroundColor(BMOTheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // State-dependent action
            gemmaActionArea

            HStack(spacing: BMOTheme.spacingSM) {
                infoTag("LiteRT-LM")
                infoTag("~\(String(format: "%.1f", model.downloadSizeGB)) GB")
                infoTag("On-device")
            }
        }
        .bmoCard()
    }

    @ViewBuilder
    private var gemmaActionArea: some View {
        switch appState.gemmaDownloadState {
        case .notInstalled:
            Button {
                appState.downloadGemma()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("Install gemma4-e2b-it")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(BMOTheme.backgroundPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(BMOTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusSmall, style: .continuous))
            }

        case .downloading(let progress):
            VStack(spacing: 8) {
                ProgressView(value: progress)
                    .tint(BMOTheme.accent)
                HStack {
                    Text("Downloading...")
                        .font(.caption)
                        .foregroundColor(BMOTheme.textSecondary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(BMOTheme.accent)
                }
            }

        case .installed:
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(BMOTheme.success)
                Text("Installed & Ready")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(BMOTheme.success)
                Spacer()

                if appState.runtimePreferences.selection.selectedInstalledFilename != nil {
                    StatusBadge(label: "Active", color: BMOTheme.accent)
                } else {
                    Button("Activate") {
                        if let model = appState.modelStore.installedModels.first(where: { $0.modelID == "gemma4-e2b-it" }) {
                            Task { await appState.setSelectedInstalledModel(filename: model.localFilename) }
                        }
                    }
                    .buttonStyle(BMOButtonStyle(isPrimary: false))
                }
            }

        case .failed(let message):
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(BMOTheme.error)
                    Text("Download failed")
                        .font(.subheadline)
                        .foregroundColor(BMOTheme.error)
                }
                Text(message)
                    .font(.caption)
                    .foregroundColor(BMOTheme.textTertiary)

                Button("Retry") {
                    appState.downloadGemma()
                }
                .buttonStyle(BMOButtonStyle())
            }
        }
    }

    // MARK: - Runtime info

    private var runtimeInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(BMOTheme.accent)
                Text("Runtime")
                    .font(.headline)
                    .foregroundColor(BMOTheme.textPrimary)
            }

            HStack {
                Text("Backend")
                    .foregroundColor(BMOTheme.textSecondary)
                Spacer()
                Text(appState.backendDisplayName)
                    .fontWeight(.medium)
                    .foregroundColor(BMOTheme.textPrimary)
            }
            .font(.subheadline)

            HStack {
                Text("Status")
                    .foregroundColor(BMOTheme.textSecondary)
                Spacer()
                Text(appState.runtimeStatus)
                    .fontWeight(.medium)
                    .foregroundColor(BMOTheme.textPrimary)
            }
            .font(.subheadline)

            if appState.usesStubRuntime {
                VStack(alignment: .leading, spacing: 6) {
                    Text("LiteRT-LM Integration")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(BMOTheme.warning)
                    Text("The LiteRT-LM Swift SDK is in active development by Google. Model downloads and storage are fully functional now. On-device inference will activate automatically when the SDK is available.")
                        .font(.caption)
                        .foregroundColor(BMOTheme.textTertiary)
                }
                .padding(.top, 4)
            }
        }
        .bmoCard()
    }

    // MARK: - Installed models

    private var installedModelsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Installed Models")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(BMOTheme.textSecondary)

            if appState.modelStore.installedModels.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundColor(BMOTheme.textTertiary)
                    Text("No models installed yet")
                        .font(.subheadline)
                        .foregroundColor(BMOTheme.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .bmoCard()
            } else {
                ForEach(appState.modelStore.installedModels) { model in
                    installedModelRow(model)
                }
            }
        }
    }

    private func installedModelRow(_ model: InstalledModel) -> some View {
        let isSelected = appState.runtimePreferences.selection.selectedInstalledFilename == model.localFilename

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(model.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(BMOTheme.textPrimary)
                HStack(spacing: 8) {
                    Text(ByteCountFormatter.string(fromByteCount: model.fileSizeBytes, countStyle: .file))
                        .font(.caption)
                        .foregroundColor(BMOTheme.textTertiary)
                    if !model.modelID.isEmpty {
                        Text(model.modelID)
                            .font(.caption)
                            .foregroundColor(BMOTheme.textTertiary)
                    }
                }
            }

            Spacer()

            if isSelected {
                StatusBadge(label: "Active", color: BMOTheme.accent)
            } else {
                Button("Use") {
                    Task { await appState.setSelectedInstalledModel(filename: model.localFilename) }
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(BMOTheme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(BMOTheme.accent.opacity(0.12))
                .clipShape(Capsule())
            }

            Button {
                appState.modelStore.deleteInstalledModel(model)
                if isSelected {
                    Task { await appState.setSelectedInstalledModel(filename: nil) }
                }
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(BMOTheme.error.opacity(0.6))
            }
        }
        .bmoCard()
    }

    // MARK: - Saved sources

    private var savedSourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Model Sources")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(BMOTheme.textSecondary)
                Spacer()
                Button {
                    showAddSource = true
                } label: {
                    Image(systemName: "plus")
                        .font(.caption)
                        .foregroundColor(BMOTheme.accent)
                }
            }

            if appState.modelStore.remoteModels.isEmpty {
                VStack(spacing: 8) {
                    Text("No saved model sources")
                        .font(.subheadline)
                        .foregroundColor(BMOTheme.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .bmoCard()
            } else {
                ForEach(appState.modelStore.remoteModels) { model in
                    sourceRow(model)
                }
            }
        }
    }

    private func sourceRow(_ model: RemoteModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(BMOTheme.textPrimary)
            Text(model.sourceURL)
                .font(.caption)
                .foregroundColor(BMOTheme.textTertiary)
                .lineLimit(1)

            HStack(spacing: 10) {
                Button("Download") {
                    appState.modelStore.download(model)
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(BMOTheme.backgroundPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(BMOTheme.accent)
                .clipShape(Capsule())

                Button("Remove") {
                    appState.modelStore.removeRemoteModel(model)
                }
                .font(.caption)
                .foregroundColor(BMOTheme.error.opacity(0.7))
            }
        }
        .bmoCard()
    }

    // MARK: - Helpers

    private func infoTag(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundColor(BMOTheme.textTertiary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(BMOTheme.backgroundSecondary)
            .clipShape(Capsule())
    }
}

// MARK: - Add model source sheet

struct AddModelSourceSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var modelName = ""
    @State private var modelURL = ""
    @State private var modelID = ""
    @State private var modelLib = ""

    var body: some View {
        NavigationStack {
            ZStack {
                BMOTheme.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: BMOTheme.spacingMD) {
                        fieldGroup("Display Name", text: $modelName, placeholder: "My Model")
                        fieldGroup("Download URL", text: $modelURL, placeholder: "https://...", keyboard: .URL)
                        fieldGroup("Model ID (runtime)", text: $modelID, placeholder: "model-id")
                        fieldGroup("Model Lib (MLC)", text: $modelLib, placeholder: "model_lib_name")

                        Button("Save Source") {
                            appState.modelStore.addRemoteModel(
                                displayName: modelName,
                                sourceURL: modelURL,
                                modelID: modelID,
                                modelLib: modelLib
                            )
                            dismiss()
                        }
                        .buttonStyle(BMOButtonStyle())
                        .disabled(modelName.isEmpty || modelURL.isEmpty)
                        .opacity(modelName.isEmpty || modelURL.isEmpty ? 0.4 : 1.0)
                        .padding(.top, BMOTheme.spacingSM)
                    }
                    .padding(BMOTheme.spacingLG)
                }
            }
            .navigationTitle("Add Model Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(BMOTheme.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func fieldGroup(_ label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(BMOTheme.textSecondary)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundColor(BMOTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(BMOTheme.backgroundCard)
                .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusSmall, style: .continuous))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(keyboard)
        }
    }
}
