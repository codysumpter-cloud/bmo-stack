import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    private var isRunningOnMac: Bool {
        ProcessInfo.processInfo.isiOSAppOnMac
    }

    var body: some View {
        Group {
            if appState.stackConfig.isOnboardingComplete {
                if isRunningOnMac {
                    DesktopShellView()
                } else {
                    MainTabView()
                }
            } else {
                OnboardingFlow()
            }
        }
        .preferredColorScheme(appState.userPreferencesStore.preferences.theme.preferredColorScheme)
    }
}

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView(selection: Binding(
            get: { appState.selectedTab },
            set: { appState.selectedTab = $0 }
        )) {
            ForEach(appState.compactTabOrder) { tab in
                shellDestination(for: tab, appState: appState)
                    .tabItem {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                    .tag(tab)
            }
        }
        .tint(BMOTheme.accent)
        .onAppear {
            if !appState.compactTabOrder.contains(appState.selectedTab) {
                appState.selectedTab = appState.stableHomeTab
            }
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor(BMOTheme.backgroundSecondary)
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }

}

struct DesktopShellView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationSplitView {
            List(selection: Binding(
                get: { appState.selectedTab },
                set: { appState.selectedTab = $0 ?? appState.stableHomeTab }
            )) {
                Section("Start Here") {
                    shellRow(.missionControl, subtitle: "Buddy-first home and next steps")
                    shellRow(.buddy, subtitle: "Your active Buddy, roster, and training")
                    shellRow(.chat, subtitle: "Talk to your Buddy with a safe way back home")
                }

                Section("Work") {
                    shellRow(.files, subtitle: "Workspace files and source materials")
                    shellRow(.skills, subtitle: "Skills you can run through the runtime")
                    shellRow(.artifacts, subtitle: "Results, receipts, and generated artifacts")
                }

                Section("Control") {
                    shellRow(.settings, subtitle: "Onboarding, routes, tabs, and maintenance")
                }
            }
            .navigationTitle("BeMore")
            .scrollContentBackground(.hidden)
            .background(BMOTheme.backgroundPrimary)
        } detail: {
            shellDestination(for: appState.selectedTab, appState: appState)
        }
        .tint(BMOTheme.accent)
        .onAppear {
            if !appState.desktopTabOrder.contains(appState.selectedTab) {
                appState.selectedTab = appState.stableHomeTab
            }
        }
    }

    private func shellRow(_ tab: AppTab, subtitle: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(tab.title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(BMOTheme.textTertiary)
            }
        } icon: {
            Image(systemName: tab.systemImage)
        }
        .tag(tab)
        .foregroundColor(BMOTheme.textPrimary)
        .listRowBackground(BMOTheme.backgroundCard)
    }
}

@MainActor
@ViewBuilder
private func shellDestination(for tab: AppTab, appState: AppState) -> some View {
    switch tab {
    case .missionControl:
        MissionControlView(store: appState.buddyStore)
    case .editor:
        EditorView()
    case .models:
        ModelsView()
    case .chat:
        ChatView(store: appState.buddyStore)
    case .skills:
        SkillsView()
    case .artifacts:
        ArtifactsView()
    case .buddy:
        BuddyView(store: appState.buddyStore)
    case .files:
        FilesView()
    case .pairing:
        MacPairingView()
    case .pricing:
        PricingView()
    case .settings:
        SettingsView()
    }
}
