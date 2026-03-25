# Title

docs: define BMO product boundary and non-goals

# Labels

docs, architecture, bmo, priority:P0

## Summary

Create a clear product boundary document for `bmo-stack` so future changes stay aligned with its intended role as a local-first personal/family agent stack.

## Problem

The repo already has strong building blocks, but the product boundary is still implicit. Without an explicit boundary, it will be easy to accidentally mix in enterprise concerns, risky defaults, or features that belong in `automindlab-stack`.

## Goal

Define what BMO is, what it owns, and what it explicitly does not own.

## Scope

Add and wire up:
- `docs/BMO_PRODUCT_BOUNDARY.md`
- README reference to the boundary doc
- `SYSTEMMAP.md` reference to the boundary doc

## Required content

The boundary doc should state:

### BMO is
- local-first
- host-first
- single-user / family-oriented
- safe by default
- able to use an optional disposable worker
- designed to keep canonical context outside disposable workers

### BMO owns
- local runtime ergonomics
- context and memory hygiene
- personal workflow skills
- safe profile defaults
- optional sandbox use for risky work

### BMO does not own
- tenant isolation
- enterprise approval workflows
- business records and reporting
- customer-facing service contracts
- multi-tenant policy control planes

## Non-goals
- no new runtime behavior
- no service refactors
- no worker implementation changes in this issue

## Tasks
- [ ] Create `docs/BMO_PRODUCT_BOUNDARY.md`
- [ ] Add a short "Product boundary" section to `README.md`
- [ ] Add a pointer from `SYSTEMMAP.md`
- [ ] Include a short "belongs in AutoMindLab, not BMO" section
- [ ] Keep the document short enough to be read in under 5 minutes

## Acceptance criteria
- [ ] The repo has a single canonical BMO boundary doc
- [ ] README links to it
- [ ] The document clearly defines ownership and non-goals
- [ ] A contributor can tell whether a proposed feature belongs in BMO or not

## Notes
Use plain language. This is a control document, not marketing copy.
