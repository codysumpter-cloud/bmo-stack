import SwiftUI

struct PlatformRootView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            WorkspacesView()
                .tabItem { Label("Workspaces", systemImage: "shippingbox.fill") }
                .tag(1)

            FactoryView()
                .tabItem { Label("Factory", systemImage: "wand.and.stars") }
                .tag(2)

            SandboxView()
                .tabItem { Label("Sandbox", systemImage: "terminal.fill") }
                .tag(3)

            ProviderHubView()
                .tabItem { Label("Providers", systemImage: "network") }
                .tag(4)

            BillingView()
                .tabItem { Label("Billing", systemImage: "creditcard.fill") }
                .tag(5)

            AdminView()
                .tabItem { Label("Admin", systemImage: "shield.fill") }
                .tag(6)
        }
        .tint(PlatformTheme.accent)
        .preferredColorScheme(.dark)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(PlatformTheme.surface)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
