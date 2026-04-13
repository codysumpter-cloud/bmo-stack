import Foundation
import SwiftUI

@MainActor
final class PlatformAppState: ObservableObject {
    @Published var providerStore = ProviderStore()
    @Published var workspaces: [WorkspaceRecord] = []
    @Published var jobs: [GenerationJob] = []
    @Published var sessions: [SandboxSessionRecord] = []
    @Published var billing = BillingSnapshot.demo
    @Published var admin = AdminSnapshot.demo
    @Published var runtime = RuntimeSummary.stub

    func bootstrap() {
        providerStore.load()
        workspaces = PlatformPersistence.load([WorkspaceRecord].self, from: PlatformPaths.workspacesFile) ?? []
        jobs = PlatformPersistence.load([GenerationJob].self, from: PlatformPaths.jobsFile) ?? []
        sessions = PlatformPersistence.load([SandboxSessionRecord].self, from: PlatformPaths.sessionsFile) ?? []

        if workspaces.isEmpty {
            workspaces = [
                WorkspaceRecord(name: "BeMoreAgent iOS", repoURL: "codysumpter-cloud/bmo-stack", syncStatus: "linked", lastSyncedAt: .now),
                WorkspaceRecord(name: "prismtek.dev mega-app", repoURL: "codysumpter-cloud/prismtek.dev_mega-app", syncStatus: "linked", lastSyncedAt: nil)
            ]
            persistWorkspaces()
        }
        refreshRuntimeSummary()
    }

    func refreshRuntimeSummary() {
        if let connected = providerStore.accounts.first(where: { $0.isEnabled }) {
            runtime = RuntimeSummary(mode: "Hybrid-ready", activeProvider: connected.provider.displayName, activeModel: connected.modelSlug, notes: "Provider connection saved locally. Real network execution still needs request validation on device.")
        } else {
            runtime = .stub
        }
    }

    func addWorkspace(name: String, repoURL: String) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        workspaces.insert(WorkspaceRecord(name: name, repoURL: repoURL, syncStatus: repoURL.isEmpty ? "local" : "linked", lastSyncedAt: nil), at: 0)
        persistWorkspaces()
    }

    func syncWorkspace(_ workspace: WorkspaceRecord) {
        guard let index = workspaces.firstIndex(where: { $0.id == workspace.id }) else { return }
        workspaces[index].syncStatus = workspaces[index].repoURL.isEmpty ? "local" : "syncing"
        workspaces[index].lastSyncedAt = .now
        persistWorkspaces()
    }

    func deleteWorkspace(_ workspace: WorkspaceRecord) {
        workspaces.removeAll { $0.id == workspace.id }
        persistWorkspaces()
    }

    func enqueueGeneration(description: String, templateName: String, target: String, modelSlug: String) {
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let job = GenerationJob(description: description, templateName: templateName, target: target, modelSlug: modelSlug, status: .completed, progress: 1.0)
        jobs.insert(job, at: 0)
        persistJobs()
    }

    func launchSandbox(for workspaceName: String) {
        guard !workspaceName.isEmpty else { return }
        sessions.insert(SandboxSessionRecord(workspaceName: workspaceName, status: "running", connectURL: "sandbox-session", expiresAt: Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now), at: 0)
        persistSessions()
    }

    func terminateSandbox(_ session: SandboxSessionRecord) {
        sessions.removeAll { $0.id == session.id }
        persistSessions()
    }

    func useCloudModel(from provider: ProviderKind, modelSlug: String) {
        let account = providerStore.account(for: provider)
        guard account.isEnabled else {
            providerStore.lastError = "Connect \(provider.displayName) before using cloud models."
            return
        }
        runtime = RuntimeSummary(mode: "Cloud", activeProvider: provider.displayName, activeModel: modelSlug, notes: "Cloud model selected. Real request execution still needs provider-specific validation on-device.")
    }

    private func persistWorkspaces() {
        try? PlatformPersistence.save(workspaces, to: PlatformPaths.workspacesFile)
    }

    private func persistJobs() {
        try? PlatformPersistence.save(jobs, to: PlatformPaths.jobsFile)
    }

    private func persistSessions() {
        try? PlatformPersistence.save(sessions, to: PlatformPaths.sessionsFile)
    }
}
