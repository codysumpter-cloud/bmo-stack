import SwiftUI

struct PricingView: View {
    private let plans: [PricingPlan] = [
        PricingPlan(
            name: "BeMore Free",
            price: "$0",
            subtitle: "Start with one active Buddy and the phone-first workflow.",
            features: ["1 active Buddy", "Starter Buddy marketplace", "Local receipts and results", "Manual Mac pairing"]
        ),
        PricingPlan(
            name: "BeMore Plus",
            price: "$12/mo preview",
            subtitle: "More Buddy capacity and stronger runtime usage when billing is enabled.",
            features: ["More Buddy slots", "Higher runtime/task capacity", "More saved skills", "Priority model routing options"]
        ),
        PricingPlan(
            name: "Buddy Council",
            price: "$29/mo preview",
            subtitle: "For teams of Buddies, councils, premium marketplace access, and power users.",
            features: ["Council/team Buddy rosters", "Premium and creator Buddies", "Advanced Mac power mode", "Expanded receipts and artifact history"]
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BMOTheme.spacingMD) {
                    headerCard
                    ForEach(plans) { plan in
                        planCard(plan)
                    }
                    billingStatusCard
                }
                .padding(.horizontal, BMOTheme.spacingMD)
                .padding(.bottom, BMOTheme.spacingXL)
            }
            .background(BMOTheme.backgroundPrimary)
            .navigationTitle("Pricing")
            .toolbarBackground(BMOTheme.backgroundPrimary, for: .navigationBar)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Plans grow with your Buddy")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(BMOTheme.textPrimary)
            Text("Billing is not connected in this build yet, but the product model is now explicit: free Buddy ownership, Plus runtime power, and Council/marketplace expansion.")
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)
            StatusBadge(label: "Billing preview", color: BMOTheme.accent)
        }
        .bmoCard()
    }

    private func planCard(_ plan: PricingPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.name)
                        .font(.title3.bold())
                        .foregroundColor(BMOTheme.textPrimary)
                    Text(plan.subtitle)
                        .font(.subheadline)
                        .foregroundColor(BMOTheme.textSecondary)
                }
                Spacer()
                Text(plan.price)
                    .font(.headline)
                    .foregroundColor(BMOTheme.accent)
            }

            ForEach(plan.features, id: \.self) { feature in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(BMOTheme.success)
                    Text(feature)
                        .font(.subheadline)
                        .foregroundColor(BMOTheme.textSecondary)
                }
            }
        }
        .bmoCard()
    }

    private var billingStatusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Upgrade path")
                .font(.headline)
                .foregroundColor(BMOTheme.textPrimary)
            Text("Upgrade buttons stay disabled until StoreKit or server billing is wired. The app now has a real pricing surface without pretending checkout is live.")
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)
            Button("Checkout not enabled yet") {}
                .buttonStyle(BMOButtonStyle(isPrimary: false))
                .disabled(true)
                .opacity(0.55)
        }
        .bmoCard()
    }
}

private struct PricingPlan: Identifiable {
    var id: String { name }
    let name: String
    let price: String
    let subtitle: String
    let features: [String]
}
