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
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView(selection: Binding(
            get: { appState.selectedTab },
            set: { appState.selectedTab = $0 }
        )) {
            ForEach(appState.orderedVisibleTabs) { tab in
                destination(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                    .tag(tab)
            }
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

    @ViewBuilder
    private func destination(for tab: AppTab) -> some View {
        switch tab {
        case .missionControl:
            MissionControlView()
        case .models:
            ModelsView()
        case .chat:
            ChatView()
        case .skills:
            SkillsView()
        case .artifacts:
            ArtifactsView()
        case .buddy:
            BuddyView()
        case .files:
            FilesView()
        case .pairing:
            MacPairingView()
        case .settings:
            SettingsView()
        }
    }
}
