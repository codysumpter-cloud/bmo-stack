import SwiftUI

struct BillingView: View {
    @EnvironmentObject private var appState: PlatformAppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    infoCard(title: "Plan", value: appState.billing.planName)
                    infoCard(title: "Usage", value: "\(Int(appState.billing.currentUsageUSD)) of \(Int(appState.billing.softLimitUSD))")
                    infoCard(title: "Capacity", value: "\(appState.billing.activeSandboxes) of \(appState.billing.maxSandboxes) sandboxes")
                }
                .padding(16)
            }
            .background(PlatformTheme.background)
            .navigationTitle("Billing")
        }
    }

    private func infoCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(PlatformTheme.textSecondary)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(PlatformTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .platformCard()
    }
}
