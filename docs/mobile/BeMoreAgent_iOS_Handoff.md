# BeMoreAgent iOS Mac-side handoff

This document is the shared finish-line checklist for the remaining work that cannot be completed from a repo-only environment.

## Current repo state

The repository now contains:

- `apps/openclaw-shell-ios` for the local-first BeMoreAgent shell
- `apps/bemoreagent-platform-ios` for platform operations and provider-connected cloud workflows
- XcodeGen project definitions for both subtrees
- CI workflows for simulator generation/build validation
- Xcode Cloud prep scripts/docs for both iOS subtrees
- a provider transport and cloud execution service in the platform subtree

## What still requires a Mac / Xcode / real device

### Shell app

- generate and open the Xcode project
- verify the onboarding flow and tab shell render correctly
- validate imports/files/models flows on simulator and device
- replace the stub runtime with the real on-device runtime bridge
- archive and upload to TestFlight

### Platform app

- generate and open the Xcode project
- verify all tabs render correctly
- validate provider connection persistence
- validate real provider network calls provider-by-provider
- validate secure credential handling strategy
- archive and upload to TestFlight if this target stays separate

## Provider-specific validation checklist

### OpenRouter
- verify `/api/v1/chat/completions` request path
- verify bearer-token auth
- verify OpenAI-style response parsing

### NVIDIA
- verify `https://integrate.api.nvidia.com/v1/chat/completions`
- verify bearer-token auth
- verify chosen model IDs exist for the account

### Hugging Face
- verify OpenAI-compatible router path
- verify token scope is sufficient for inference
- verify response parsing against current router output

### Google
- verify `generateContent` requests with `x-goog-api-key`
- verify model names and quotas on the account
- verify response parsing from `candidates[].content.parts[]`

### Ollama
- verify local-host path `http://localhost:11434/api/chat`
- verify remote/cloud behavior if using `https://ollama.com/api`
- verify model naming against the actual host

## Immediate recommended execution order

1. run both CI workflows and fix anything obviously failing
2. open the shell app in Xcode first
3. validate/simplify the shell app until it is the clearest TestFlight candidate
4. open the platform app in Xcode second
5. validate provider requests one provider at a time
6. decide whether to ship two targets or converge toward one combined app

## Practical decision gate

Before broad convergence work, answer this on the Mac side:

- Is the shell app stable enough to be the first TestFlight app?
- Does the platform app need to ship as a second target, or can it remain a source/reference subtree while features move into the main app?

## Honest rule

Do not claim:
- real on-device runtime is complete
- provider execution is complete
- TestFlight readiness is complete

until those have been proven in Xcode and on a real device.
