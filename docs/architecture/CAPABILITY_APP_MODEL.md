# Capability/App Model

This document locks the ownership split for Buddy-operated skills and apps.

## Concise Architecture Summary

BeMore-stack owns capability and intelligence. prismtek-apps owns product surfaces and release. Hermes remains donor/reference only. The current GitHub slug may still be `codysumpter-cloud/bmo-stack` until the repo can be safely renamed, but contracts should use `BeMore-stack` as the canonical product/runtime identity.

Skills define bounded capability. Apps compose one or more skills into product UX. Buddy Bindings attach a Buddy persona, permissions scope, and resume behavior to a skill or app. The Runtime Registry is the only place the Buddy Runtime discovers executable capability. iBeMore reads app/skill metadata and invokes runtime methods; it does not fork per-app brains or embed hidden runtimes.

The first proof is Pokemon Team Builder. Its brain-owned runtime logic belongs in BeMore-stack; its iBeMore launch, editor, artifact viewer, and supervision UX belong in prismtek-apps.

## Capability Model

### Skill Package

A Skill Package is a bounded capability unit. It answers: what can the Buddy Runtime do, what inputs are valid, what permissions are needed, what events/artifacts are emitted, and which handler executes it.

A skill package must include:

- `id`, `name`, `description`, `version`, `ownerRepo`, `ownerTeam`, and `stability`.
- Permissions required to run, such as `workspace.read`, `workspace.write`, `artifact.write`, `network.read`, or `approval.request`.
- Required tools and runtime capabilities, such as deterministic scoring, artifact persistence, Buddy reasoning, or type-chart lookup.
- Input and output schema references.
- Artifact types and event types it can emit.
- Install/configure schema and defaults.
- Validation hooks that run before install, before execution, and after execution.
- UI surface hooks for discovery and launch, without embedding app-specific intelligence.
- Runtime binding rules naming the handler and allowed Buddy binding modes.

A skill is not a separate runtime. It can call runtime services, tools, and data providers only through the registry-approved handler context.

### App Package

An App Package is a larger user-facing package built around one or more skills. It answers: how does iBeMore present the capability, what screens exist, how does installation/configuration work, and how are artifacts supervised?

An app package must include:

- `id`, `name`, `description`, `version`, `ownerRepo`, `displayName`, `category`, and `requiredSkills`.
- Routes/screens, launch/install/config schema, and default route.
- Artifact presentation model for cards, previews, export actions, and save/resume.
- Persistence model naming runtime-owned state and app-owned local UI state.
- Approval/supervision hooks for tool requests, generated artifacts, and destructive changes.
- Packaging rules that forbid bundling a private runtime, hidden daemon, or donor-only code.

Apps do not own solver logic, policy, permissions, or Buddy reasoning. Apps request runtime actions and render receipts, events, and artifacts.

### Buddy Binding

A Buddy Binding attaches a Buddy to a skill or app. It answers: which Buddy is operating this capability, what role are they taking, what permissions are in scope, and how does the session resume?

A binding must include:

- Binding metadata: `bindingId`, `buddyId`, `targetKind`, `targetId`, `version`, `createdAt`, and `status`.
- Persona/role, for example `team_coach`, `rules_auditor`, or `workbench_supervisor`.
- Permissions scope narrowed from both Buddy permissions and package permissions.
- Event emission rules for status, request, approval, receipt, artifact, and handoff events.
- Artifact ownership rules: artifacts are owned by the runtime session and attributed to Buddy plus skill/app.
- Handoff/resume behavior: current inputs, current artifact IDs, last event sequence, and open approvals.
- Constraint that the binding cannot create a new LLM loop, provider account, daemon, or hidden service.

A Buddy creates or adopts a skill/app through runtime registry install and binding creation. The Buddy can propose an app from a user goal, but installation requires registry validation and user approval when new permissions are requested.

### Runtime Registry

The Runtime Registry is the source of truth for discoverable and executable capability. It registers:

- Skill packages and versions.
- App packages and versions.
- Buddy bindings.
- Permission grants and install status.
- UI hooks for iBeMore discovery.
- Runtime handlers and validation hooks.
- Compatibility between app versions, skill versions, and runtime capabilities.

The registry lives in BeMore-stack. iBeMore may cache registry snapshots, but must treat BeMore-stack/runtime responses as authoritative.

## Ownership

BeMore-stack owns:

- Skill/app contracts.
- Buddy and iBuddy runtime-side execution rules.
- Runtime registry.
- Permissions model.
- Event and artifact schemas.
- Buddy binding rules.
- Skill/app manifests.
- Runtime-side Pokemon Team Builder skill logic.

prismtek-apps owns:

- iBeMore and BeMore app surfaces.
- App launcher/install/configure flows.
- Skill/app discovery UI.
- Pokemon Team Builder UI.
- Workbench/supervision views.
- App runtime client bindings.
- TestFlight and release ownership.

Hermes owns nothing in the destination product. Hermes can be read as donor/reference only, and any borrowed idea needs explicit provenance plus an exit plan into BeMore-stack or prismtek-apps.

## Pokemon Team Builder MVP Definition

The smallest believable MVP is fully functional if it can create, edit, analyze, explain, iterate, save, resume, and export one Pokemon team without hidden services or donor-only code.

### User Flow

1. User installs Pokemon Team Builder from iBeMore app discovery.
2. User chooses Singles or Doubles, optional format snapshot, goal, locked Pokemon, avoided Pokemon, and style.
3. User launches the app and sees a six-slot team workbench.
4. User can manually edit each slot.
5. User runs analysis and sees type coverage, role coverage, weaknesses/resistances, recommendations, and rationale.
6. User exports JSON, Markdown, and share text artifacts.

### Buddy Flow

1. Active Buddy adopts the `pokemon-team-builder` binding.
2. Buddy interprets natural-language goals into structured skill inputs.
3. Buddy asks for approval when a requested change overwrites saved team state.
4. Buddy iterates through runtime calls, not a separate app brain.
5. Buddy can resume from saved team artifacts and previous event sequence.

### Runtime Flow

1. Runtime validates install/config/schema.
2. Runtime loads a versioned local type chart and curated MVP dataset.
3. Runtime generates or edits a team deterministically.
4. Runtime computes type and role coverage.
5. Runtime emits `skill.run.started`, `pokemon.team.generated`, `pokemon.team.analyzed`, `artifact.created`, and `skill.run.completed`.
6. Runtime returns a receipt with artifact refs.

### Artifact Flow

The MVP emits:

- `pokemon.team.v1+json`: canonical team, slots, constraints, analysis, snapshot, and provenance.
- `pokemon.team.report.v1+markdown`: user-readable rationale and warnings.
- `pokemon.team.export.v1+text`: compact share/export text.

### Supervision Flow

iBeMore shows:

- Current Buddy, skill/app binding, and permission scope.
- Event timeline.
- Pending approvals.
- Artifact previews.
- Last receipt and errors.

### Save/Resume Flow

Runtime owns persisted team state and artifacts. iBeMore owns selected screen, draft form state, and local UI filters. Resume uses `runtime.resume_session` or `registry.get_install_status` plus latest artifact refs.

## Repo-By-Repo Implementation Plan

### BeMore-stack

Add or change:

- `contracts/capabilities/skill-package.schema.json`
- `contracts/capabilities/app-package.schema.json`
- `contracts/capabilities/buddy-binding.schema.json`
- `contracts/capabilities/runtime-registry.schema.json`
- `docs/architecture/CAPABILITY_APP_MODEL.md`
- `runtime/skills/pokemon-team-builder/README.md`
- `runtime/skills/pokemon-team-builder/skill.package.json`
- `runtime/skills/pokemon-team-builder/schemas/*.json`
- `runtime/skills/pokemon-team-builder/data/type-chart.v1.json`
- `runtime/skills/pokemon-team-builder/data/mvp-pokemon.v1.json`
- `runtime/skills/pokemon-team-builder/handler.*`
- `runtime/registry/capabilities.registry.json`
- Runtime tests for install, validation, generation, edit, analysis, artifact emission, and resume.

Move now:

- Treat the old Pokemon logic in `apps/openclaw-shell-ios/OpenClawShell/OpenClawWorkspaceRuntime.swift` as donor/reference.
- Re-express the real skill as a BeMore-stack runtime package and handler.
- Keep the existing backend spec at `docs/POKEMON_CHAMPIONS_TEAM_BUILDER_BACKEND.md` as a longer-term solver reference.

Do not implement yet:

- Live web scraping.
- Full damage calculator.
- Competitive meta ingestion.
- Background daemon.
- Per-app model/provider settings.
- Hermes-owned destination code.

### prismtek-apps

Add or change:

- `apps/bemore-ios-native/OpenClawShell/RuntimeClient/*`
- `apps/bemore-ios-native/OpenClawShell/Capabilities/*`
- `apps/bemore-ios-native/OpenClawShell/Views/AppDiscoveryView.swift`
- `apps/bemore-ios-native/OpenClawShell/Views/PokemonTeamBuilderView.swift`
- `apps/bemore-ios-native/OpenClawShell/Views/PokemonTeamWorkbenchView.swift`
- `apps/bemore-ios-native/OpenClawShell/Views/SupervisionTimelineView.swift`
- `apps/bemore-ios-native/OpenClawShell/Views/ArtifactPreviewView.swift`
- `apps/bemore-ios-native/OpenClawShell/AppModels.swift` for registry DTOs only.
- iOS tests for registry decode, launch/config forms, team editing, artifact display, and runtime client request construction.

Move now:

- Remove product claims that app-side Pokemon logic is the canonical skill brain.
- Replace local Pokemon generation with runtime-client calls once BeMore-stack handler exists.
- Keep TestFlight and release workflows in prismtek-apps.

Reference-only temporarily:

- Existing Swift Pokemon UI/runtime code can be used to mine DTOs and user flow, but not as the destination runtime.
- Hermes can be inspected for patterns only; no product/system ownership lands there.

Do not implement yet:

- Another iOS-only runtime registry.
- A separate Pokemon provider/model picker.
- A hidden local server.
- Broad OpenClaw/BeMore rename pass.

## End-To-End Proof Path

1. Register `pokemon-team-builder` in the BeMore-stack Runtime Registry as an enabled skill package with a tested handler.
2. Register `pokemon-team-builder-app` as an app package that requires that skill.
3. iBeMore fetches or bundles the registry snapshot and shows Pokemon Team Builder in discovery.
4. User installs it; runtime validates permissions and config.
5. Active Buddy creates a Buddy Binding for the app and emits a binding event.
6. User enters goal: `Build a balanced Singles team around Dragonite and make it less weak to Electric`.
7. Runtime returns generated team, coverage analysis, rationale, and artifact refs.
8. iBeMore displays event timeline, team workbench, recommendations, receipt, and artifact previews.
9. User asks: `replace this slot with a bulky pivot`.
10. Buddy calls the same skill handler with existing team artifact ref plus edit request.
11. Runtime emits a new versioned artifact and preserves previous artifact provenance.
12. User exports Markdown or share text cleanly.

## Top 3 Risks

1. Daemon/server sprawl. The failure mode is adding a Pokemon backend server, app-only runtime, or Hermes worker before the runtime registry exists. Mitigation: one BeMore-stack runtime handler first; no hidden services in MVP.

2. Ownership confusion. The failure mode is prismtek-apps keeping canonical skill logic because it currently ships the UI, or Hermes becoming the destination repo because it has reference code. Mitigation: contracts and runtime handlers live in BeMore-stack; app surfaces and release live in prismtek-apps; Hermes stays donor-only.

3. Per-app mini-brain duplication. The failure mode is Pokemon Team Builder getting its own model settings, chat loop, memory, and permissions. Mitigation: Buddy Binding supplies persona and scope; Buddy Runtime supplies reasoning; the skill supplies deterministic capability and artifacts.

## Smallest Safe Next Implementation Step

Implement the BeMore-stack Pokemon Team Builder runtime package behind the registry, using a small bundled dataset and deterministic analyzer. Do not touch iBeMore UI until the runtime handler can pass tests for generate, edit, analyze, save, resume, and export.
