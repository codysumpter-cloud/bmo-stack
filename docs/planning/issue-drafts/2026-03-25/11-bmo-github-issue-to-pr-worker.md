# Title

github: add issue-to-PR worker pipeline for BMO upgrades

# Labels

github, automation, workers, bmo, priority:P1

## Summary
Create a GitHub-driven worker pipeline that can turn approved issues into scoped implementation branches and draft pull requests for `bmo-stack`.

## Problem
Current GitHub automation covers repository maintenance reporting, but it does not yet implement an autonomous issue-to-change loop.

## Goal
Make GitHub the main operator control plane for BMO upgrades.

## Desired flow
1. issue is labeled `autonomy:ready`
2. planner worker converts the issue into a scoped implementation plan
3. executor worker creates a branch and applies bounded changes
4. verifier worker runs checks and posts a structured report
5. PR is opened with change summary, risks, and rollback notes

## Proposed files
- `.github/workflows/issue-to-pr.yml`
- `scripts/github-issue-planner.sh`
- `scripts/github-change-executor.sh`
- `docs/GITHUB_AUTONOMY.md`

## Tasks
- [ ] Define issue eligibility rules
- [ ] Define branch naming and PR naming rules
- [ ] Add planner and executor worker entrypoints
- [ ] Require structured verifier output before PR open
- [ ] Document failure, retry, and human-escalation paths

## Acceptance criteria
- [ ] A labeled issue can produce a draft PR without manual local work
- [ ] The pipeline is bounded and auditable
- [ ] Failures post structured status back to GitHub
- [ ] Unsafe or ambiguous issues do not auto-execute
