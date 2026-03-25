# Title

skills: add first-party BMO skill packs for daily local workflows

# Labels

skills, product, bmo, priority:P1

## Summary
Create first-party skill packs that make `bmo-stack` immediately useful for personal and family workflows without requiring risky third-party ecosystem installs.

## Goal
Improve day-to-day usefulness while keeping the trusted surface small.

## Skill packs to add
- `skills/personal/session-wrap-up/`
- `skills/personal/changelog-draft/`
- `skills/personal/file-triage/`
- `skills/personal/project-bootstrap/`
- `skills/personal/vscode/`
- `skills/personal/obsidian/`
- `skills/personal/macos/`

## Requirements
Each skill should include:
- purpose
- inputs
- outputs
- side effects
- runtime scope
- rollback note
- example invocation

## Tasks
- [ ] Create the first-party skill pack structure
- [ ] Add at least 5 high-confidence daily workflow skills
- [ ] Document host vs worker execution for each skill
- [ ] Add simple smoke checks for skill packaging
- [ ] Link approved skills from `skills/README.md`

## Acceptance criteria
- [ ] BMO has a useful first-party workflow pack with no external dependencies
- [ ] Each skill is documented and reviewable
- [ ] Risky or network-heavy skills are not part of the default pack
- [ ] The safe-default profile can use the pack directly
