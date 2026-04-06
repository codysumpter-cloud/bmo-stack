import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ModelsView()
                .tabItem {
                    Label("Models", systemImage: "square.and.arrow.down")
                }

            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message")
                }

            FilesView()
                .tabItem {
                    Label("Files", systemImage: "folder")
                }

            EditorView()
                .tabItem {
                    Label("Editor", systemImage: "chevron.left.forwardslash.chevron.right")
                }
        }
    }
}
