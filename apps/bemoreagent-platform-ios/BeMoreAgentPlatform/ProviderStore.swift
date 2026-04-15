import Foundation
import SwiftUI

@MainActor
final class ProviderStore: ObservableObject {
    @Published var accounts: [ProviderAccount] = []
    @Published var lastError: String?

    func load() {
        accounts = PlatformPersistence.load([ProviderAccount].self, from: PlatformPaths.providersFile) ?? []
    }

    func account(for provider: ProviderKind) -> ProviderAccount {
        accounts.first(where: { $0.provider == provider }) ?? .blank(for: provider)
    }

    func upsert(_ account: ProviderAccount) {
        if let index = accounts.firstIndex(where: { $0.provider == account.provider }) {
            accounts[index] = account
        } else {
            accounts.append(account)
        }
        persist()
    }

    func validate(_ provider: ProviderKind) {
        var current = account(for: provider)
        guard !current.apiKey.isEmpty || provider == .ollama else {
            lastError = "Add credentials for \(provider.displayName) first."
            return
        }
        current.isEnabled = true
        current.lastValidatedAt = .now
        upsert(current)
    }

    func remove(_ provider: ProviderKind) {
        accounts.removeAll { $0.provider == provider }
        persist()
    }

    private func persist() {
        do {
            try PlatformPersistence.save(accounts, to: PlatformPaths.providersFile)
        } catch {
            lastError = error.localizedDescription
        }
    }
}
