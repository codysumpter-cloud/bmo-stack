import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.stackConfig.isOnboardingComplete {
                MainTabView()
            } else {
                OnboardingFlow()
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
                .tag(1)

            BuddyView()
                .tabItem {
                    Label("Buddy", systemImage: "person.2.fill")
                }
                .tag(2)

            FilesView()
                .tabItem {
                    Label("Files", systemImage: "folder.fill")
                }
                .tag(3)

            ModelsView()
                .tabItem {
                    Label("Models", systemImage: "cpu")
                }
                .tag(4)
        }
        .tint(BMOTheme.accent)
        .onAppear {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor(BMOTheme.backgroundSecondary)
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}
