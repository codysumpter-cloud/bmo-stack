# BeMore Codex Implementation Prompt

Use this prompt to drive repo work from the current iOS shell owner path:
- `apps/openclaw-shell-ios`

Ground implementation planning in the latest known delivery lane when relevant:
- `fix/openclaw-build17-workspace-runtime`

Do not pretend the app has already been renamed or reorganized if the repo still uses older path names.

## Ask mode pre-prompt

```text
Read the repo and produce a concrete implementation plan for the prompt that follows.

Be specific about:
- existing subsystems to reuse
- files likely to change
- the shortest path to the flagship flow
- which parts should ship in this pass vs later phases
- highest-risk wiring points
- data model choices for Buddy Templates, installs, sanitation, and Buddy memory

Do not implement yet.
Do not give a vague product roadmap.
Return a repo-specific build plan with a recommended implementation order.
```

## Code mode prompt

```text
You are modifying this repo in one primary implementation pass.

Your mission is to build the first strong vertical slice of BeMore's new identity from the current owner path in this repo.

Current owner path:
- apps/openclaw-shell-ios

Current delivery lane to treat as highly relevant when present:
- fix/openclaw-build17-workspace-runtime

Do not stop at analysis.
Do not return a design memo instead of code.
Implement the strongest coherent vertical slice you can, then run validation, fix the most important breakages, and report exact remaining blockers.

# Product direction

This app is not just a thin assistant client.
It is becoming a standalone personal agent system app.

It should feel like:
- one agent
- one workspace
- one runtime
- one evolving memory layer
- one Buddy that matters
- one future-facing ecosystem for Buddy Templates

The app has four integrated surfaces:
1. daily-life assistant
2. agent workspace
3. living memory system
4. Buddy ecosystem / Buddy Workshop

# Core goal for this pass

Build the runtime and app surfaces that make the in-app agent materially more capable, while also making Buddy important through evolving markdown state and making Buddy templates installable in a safe structured way.

This pass must establish 7 things:
1. a real Workspace Runtime
2. a real Agent Workspace surface
3. evolving markdown memory files
4. Buddy as steward of those files
5. real receipts and results for actions
6. canonical Council Starter Pack data and templates
7. first Buddy Workshop template and install foundations

# Highest-priority product truth

The app already has intelligence.
It now needs embodiment, continuity, and portable identity.

Embodiment:
- browse files
- open, edit, and save files
- run commands
- inspect output
- review diffs
- run subtasks

Continuity:
- markdown files evolve through use
- Buddy tracks what changed
- memory feels curated and operational, not theatrical

Portable identity:
- Buddies can be represented as structured templates
- installs create clean derived copies
- private state does not bleed across users

# Absolute priorities

## Priority 1 — Workspace Runtime

Create or formalize one app-facing runtime contract.

It must cover directly or via adapters:
- workspace.listFiles(path?)
- workspace.readFile(path)
- workspace.writeFile(path, content)
- workspace.searchFiles(query)
- runtime.runCommand(command, options?)
- runtime.listProcesses()
- runtime.pollProcess(id)
- runtime.killProcess(id)
- review.listChangedFiles()
- review.getDiff(path)
- tasks.list()
- tasks.create(input)
- tasks.runSubtask(input)
- artifacts.list()
- artifacts.read(path)
- receipts.list()

Reuse existing repo primitives where possible.
Do not rewrite major subsystems if adapters can unify them.

## Priority 2 — Agent Workspace shell

Create one coherent workspace surface.

Minimum sections:
- Files
- Editor
- Terminal
- Tasks
- Review
- Results
- Buddy / Memory
- Buddies / Library

## Priority 3 — File/editor flow

Minimum:
- browse workspace tree
- open a file
- edit it
- save it
- switch between open or recent files
- support markdown and code reasonably well

## Priority 4 — Command/process flow

Minimum:
- run command
- see running, completed, and failed state
- view stdout and stderr
- rerun command
- stop command
- inspect recent runs

## Priority 5 — Diff/review flow

Minimum:
- changed files list
- diff view
- changed and untracked indicators
- links from runs, tasks, and results to affected files where possible

## Priority 6 — Task/subtask flow

Minimum:
- task list
- current task
- create task
- run subtask
- show task status
- show result summary
- connect tasks to files, runs, and results

## Priority 7 — Evolving markdown memory

Implement or formalize these canonical files as real app artifacts:
- .openclaw/soul.md
- .openclaw/user.md
- .openclaw/memory.md
- .openclaw/session.md
- .openclaw/skills.md

Required behavior:
- session.md updates frequently
- memory.md updates from durable extracted facts
- user.md updates conservatively from repeated preferences or patterns
- skills.md reflects actual capabilities
- soul.md changes rarely and remains stable

Use a real pipeline:
- event -> extract -> merge -> regenerate markdown -> Buddy surfaces change

Important:
- do not append forever
- use stable sections
- preserve or separate user-authored vs generated content
- avoid recap sludge
- generated state should feel curated and operational

## Priority 8 — Buddy as continuity steward

Buddy should:
- explain what changed in markdown state
- surface stale files
- suggest promotions from conversation to durable memory
- show current focus and active tasks
- show recent artifact or memory changes
- act as steward of continuity, not just another chat tab

Minimum Buddy outputs:
- what changed
- what matters now
- what is stale
- what should be remembered

## Priority 9 — Council Starter Pack foundations

Add canonical starter Buddy template data for the 12-member public council.

For V1 these should be:
- starter Buddy templates
- locked initial stats
- locked initial move sets
- locked initial class identity
- editable name
- editable nickname
- later-evolving appearance and growth stage

The 12 canonical starter Buddies are:
- BMO
- Prismo
- NEPTR
- Princess Bubblegum
- Finn
- Jake
- Marceline
- Simon
- Peppermint Butler
- Lady Rainicorn
- Lemongrab
- Flame Princess

Each starter template should include:
- buddy name
- short description
- role or class
- personality profile
- voice style
- visual archetype
- starter stats
- starter moves
- growth metadata
- tags
- recommended user type

Use structured data, not giant prompt blobs.

## Priority 10 — Buddy Workshop template model

Implement the first structured Buddy Template schema and supporting install flow.

At minimum create a typed model equivalent to:

```ts
type BuddyTemplate = {
  templateId: string;
  creatorId: string;
  version: string;
  compatibilityVersion: string;

  listing: {
    title: string;
    description: string;
    category: string;
    tags: string[];
    priceCents: number;
    visibility: "private" | "unlisted" | "public_free" | "public_paid";
    contentRating: "general" | "teen" | "restricted";
  };

  buddy: {
    defaultName: string;
    class: string;
    role: string;
    personalityPrimary: string;
    personalitySecondary?: string;
    voicePrimary: string;
    voiceSecondary?: string;
    archetype: string;
    bodyStyle: string;
    palette: string;
    evolutionStage: number;
  };

  gameplay: {
    stats: Record<string, number>;
    moves: string[];
    passive?: string;
    growthPath?: string[];
  };

  utility: {
    starterSkills: string[];
    taskBiases: string[];
    recommendedUseCases: string[];
    suggestedRoutines?: string[];
  };

  assets: {
    asciiVariantId?: string;
    pixelVariantId?: string;
    coverImage?: string;
    gallery?: string[];
  };

  provenance: {
    derivedFromTemplateId?: string;
    sanitizedAt: string;
    benchmarkSummary?: Record<string, number>;
  };
};
```

## Priority 11 — Install flow

On install the app should:
- create a new local Buddy copy
- mark it as derived from the installed template
- let the user rename it
- let the user personalize it
- start with the buyer's own clean private memory

That means:
- the buyer owns their version
- the creator's source Buddy stays separate
- private state does not bleed across users

## Priority 12 — Sanitation and publishing foundations

Do not build full payouts in this pass.
Do implement the foundations for safe packaging.

Create a publish/package pipeline that can convert a Buddy into a sanitized Buddy Template draft.

Always strip:
- private conversation history
- raw chat logs
- user-specific memory
- linked accounts
- uploaded documents
- email, text, and calendar contents
- creator notes
- secret prompts containing private information
- API keys / tokens / credentials
- hidden task history tied to the creator
- private markdown memory state
- personal identifiers unless explicitly public

Safe to keep:
- personality structure
- role or class
- skill loadout
- visual identity
- generic public starter memories
- public routines
- public sample tasks
- benchmark summaries
- performance badges
- public descriptions

At minimum:
- implement data-level sanitation hooks
- add validation for metadata completeness and broken references
- create placeholders for banned content, restricted term checks, and unsupported dependency checks

## Priority 13 — Buddy Library / Workshop UI foundations

Create a simple but real Buddy Library / Workshop surface.

Minimum:
- list official starter templates
- view template detail
- inspect included items
- inspect stats, move highlights, and use cases
- install template
- see whether a Buddy is installed / derived from template

## Priority 14 — Real execution semantics

No fake success.

The app or agent must not claim:
- created
- saved
- updated
- generated
- published
- installed
- persisted

unless confirmed by real execution, results, receipts, or state transitions.

# Flagship user flow

After your changes, this flow should work as far as the repo allows:
1. open Agent Workspace
2. browse workspace files
3. open and edit a file
4. save changes
5. run a command
6. inspect stdout, stderr, and status
7. review changed files and diffs
8. run a subtask using repo-native foundations where possible
9. inspect results, receipts, and artifacts
10. open Buddy Library
11. inspect a Council Starter Pack Buddy template
12. install it into a clean local Buddy copy
13. rename or personalize the installed Buddy
14. see Buddy report what changed in markdown memory and state

If this flow is not real, the task is not done.

# Non-goals for this pass

Do not spend this pass on:
- pixel-perfect UI polish
- full creator payouts
- wallets or balances
- marketplace currency
- raw live-Buddy resale
- unrelated docs-only output
- claiming every BeMore surface is fully implemented inside this repo

# Acceptance criteria

This work is successful only if all are true:
1. There is a real Agent Workspace surface.
2. Files can be browsed, opened, edited, and saved.
3. Commands can be run and their output/state is visible.
4. Changed files and diffs can be reviewed.
5. Tasks and subtasks can be created or run using repo-native foundations where possible.
6. The canonical markdown files exist and evolve through use.
7. Buddy visibly reports and interprets markdown and memory changes.
8. The app does not fake completion claims.
9. Canonical starter Buddy templates exist in structured form.
10. A user can inspect and install a starter Buddy template.
11. Installed Buddies are clean derived copies, not shared live state.
12. The flagship flow works as far as the repo allows.

# Validation

At the end:
- run the most relevant builds and tests available
- fix the most important failures
- do not widen scope after the main slice works
- report exact remaining blockers

# Output format when finished

Return:
1. concise summary
2. major files changed
3. commands and tests run
4. known limitations and TODOs
5. whether the flagship flow works end to end
6. whether evolving markdown + Buddy stewardship are working
7. whether starter Buddy template install flow works
8. whether sanitation and publishing foundations exist
```

## Strong sequencing guidance

If implementation effort must be staged, use this order:
1. workspace runtime and honest receipts
2. evolving markdown memory and Buddy stewardship
3. official starter Buddy templates
4. Buddy Library and install flow
5. sanitation and free sharing foundations
6. paid creator marketplace later
