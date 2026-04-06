# OpenClaw Local Stack Builder

## Recommendation

Treat the public mobile product as a fixed local-first OpenClaw runtime that generates personalized agent systems from questionnaire answers, presets, and machine-readable policy templates.

Do not frame the product as arbitrary downloaded plugins or unrestricted code injection on iPhone. Frame it as a configurable runtime that stays stable while user stacks are compiled from safe, data-driven blueprints.

## Product goal

Give ordinary users a way to create a personalized OpenClaw stack on their phone in minutes.

Each user should be able to answer a short setup flow and receive:

- a primary assistant
- a small supporting agent team
- workflow presets
- a local memory layout
- model preferences
- tool permissions
- home-screen shortcuts

## Product promise

The product should feel like:

- private
- local-first
- tailored
- fast to set up
- powerful without requiring prompt engineering

A good one-line pitch is:

> Build your own private AI operating system on your iPhone in a few minutes.

## Ownership split

### Fixed runtime

The shipped app owns:

- the runtime engine
- the workflow engine
- the memory system
- local workspace storage
- model adapters
- permission and policy enforcement
- UI surfaces for chat, files, tasks, and review

### Config compiler

The setup system owns:

- onboarding questions
- preset selection
- agent generation
- workflow generation
- memory-scope generation
- tool permission defaults
- model preference defaults

### User stack

The generated user stack owns:

- stack name
- assistant tone
- agent roster
- workflow shortcuts
- memory scopes
- attached workspace folders
- local preference state

## Starter build phases

### v0.1

Build a useful local-first setup experience.

Must include:

- preset families
- questionnaire flow
- generated stack summary
- generated agent list
- generated workflow list
- generated permission profile
- local persistence of stack config

### v0.5

Add task-aware execution and review.

Must include:

- task templates
- per-stack environment selection
- patch review surfaces
- richer memory scopes
- export and import of stack configs

### v1.0

Turn the generated stack into a full OpenClaw mission-control product.

Must include:

- multi-agent routing
- local and remote environment profiles
- approval policies
- repo-aware workflows
- advanced workflow templates
- stack marketplace templates based on safe configs, not arbitrary executable plugins

## Setup flow

The first-run wizard should ask a short but high-value series of questions.

### 1. Primary goal

Examples:

- coding
- writing
- study
- research
- founder workflow
- personal organization
- creative work

### 2. User type

Examples:

- developer
- student
- founder
- creator
- researcher
- operations

### 3. Preferred team shape

Examples:

- one main assistant
- main assistant plus reviewer
- small specialist team

### 4. Autonomy level

Examples:

- explain only
- suggest edits
- edit with confirmation
- execute workflows with approval gates

### 5. Memory posture

Examples:

- session only
- remember project context
- remember long-term preferences

### 6. Tool posture

Examples:

- files only
- files and workspace notes
- files plus structured workflows
- advanced stack with review and automation

### 7. Optimization priority

Examples:

- privacy
- speed
- quality
- battery
- depth

## Generated outputs

The questionnaire should compile into the following structures:

- stack profile
- agent roster
- workflow pack
- permission profile
- memory profile
- model preference profile

## Suggested starter presets

Ship curated preset families instead of forcing users to start from a blank page.

Recommended starting presets:

- Coder
- Founder
- Student
- Creator
- Researcher
- Life OS

## Agent model

Each generated agent should define:

- `id`
- `name`
- `role`
- `goal`
- `tone`
- `allowedTools`
- `memoryScopes`
- `preferredModelProfile`
- `approvalMode`

## Workflow model

Each generated workflow should define:

- `id`
- `title`
- `intent`
- `requiredTools`
- `defaultAgent`
- `defaultEnvironment`
- `approvalMode`

## Safe runtime rules

- Keep the runtime fixed and versioned.
- Keep stack generation data-driven.
- Keep permissions explicit.
- Prefer local storage and local models by default.
- Treat marketplace expansion as safe template/config distribution, not arbitrary executable plugins.

## Monetization posture

The app should not explain pricing in terms of hidden setup complexity.

Prefer user-facing value tiers such as:

- free starter stack
- pro stack builder
- specialist preset packs
- studio-level advanced orchestration

## Verification

This work is successful when the app can generate a believable personalized stack from questionnaire answers and persist it locally without requiring the user to hand-author prompts, agents, or policies.
