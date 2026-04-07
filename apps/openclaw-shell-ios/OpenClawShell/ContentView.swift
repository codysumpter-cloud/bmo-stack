import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeTabView()
                .tabItem { Label("Home", systemImage: "house") }
                .tag(OpenClawShellTab.home)

            ChatTabView()
                .tabItem { Label("Chat", systemImage: "message") }
                .tag(OpenClawShellTab.chat)

            FilesTabView()
                .tabItem { Label("Files", systemImage: "folder") }
                .tag(OpenClawShellTab.files)

            ModelsTabView()
                .tabItem { Label("Models", systemImage: "square.and.arrow.down") }
                .tag(OpenClawShellTab.models)

            EditorTabView()
                .tabItem { Label("Editor", systemImage: "chevron.left.forwardslash.chevron.right") }
                .tag(OpenClawShellTab.editor)
        }
    }
}
