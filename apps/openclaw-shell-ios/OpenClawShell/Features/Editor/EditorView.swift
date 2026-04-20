import SwiftUI

struct EditorTabView: View {
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
                    ContentUnavailableView(
                        "No file selected",
                        systemImage: "chevron.left.forwardslash.chevron.right",
                        description: Text(appState.activeStack == nil ? "Choose a file in Files, then edit it here." : "Choose a stack workspace file in Files, then edit it here.")
                    )
                }
            }
            .navigationTitle("Editor")
        }
    }
}
