import SwiftUI

struct TextFilePreview: View {
    @EnvironmentObject private var appState: AppState
    let file: WorkspaceFile

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(file.filename)
                .font(.headline)
            if file.isTextLike {
                ScrollView {
                    Text(appState.workspaceStore.loadText(for: file))
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text("Preview unavailable for this file type.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
