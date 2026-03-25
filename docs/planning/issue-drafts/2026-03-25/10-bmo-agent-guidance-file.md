# Title

docs: add BMO agents.md style guidance for council roles and runtime behavior

# Labels

docs, council, bmo, priority:P2

## Summary
Add an editor-facing agent guidance file for BMO so council roles, delegation rules, and runtime behavior are easier to extend safely.

## Problem
BMO currently relies on context and council files, but there is no concise editor-side guidance file equivalent to an `agents.md` style rule set.

## Goal
Make extension safer and reduce drift when adding or modifying council roles and specialist behaviors.

## Scope
Add a concise rule file covering:
- role boundaries
- host vs worker execution rules
- verification expectations
- skill packaging expectations
- naming and documentation conventions

## Proposed files
- `.cursor/rules/agents.md` or repo-equivalent editor rule file
- `docs/AGENT_EXTENSION_GUIDE.md`

## Tasks
- [ ] Add an editor-facing agent guidance file
- [ ] Document council role boundaries and delegation limits
- [ ] Document verification-before-completion rules
- [ ] Document how new specialists should be added
- [ ] Link the guide from the README or docs index

## Acceptance criteria
- [ ] BMO has a concise extension guide for agents and specialists
- [ ] Role boundaries and verification expectations are explicit
- [ ] New contributors can add an agent without guessing format or behavior
