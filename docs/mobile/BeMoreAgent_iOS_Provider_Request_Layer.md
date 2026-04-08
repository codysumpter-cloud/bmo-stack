# BeMoreAgent iOS provider request layer

This document explains the request-building layer added for the platform iOS subtree.

## Scope of the added layer

The repo-side provider layer now covers:

- base URL normalization
- provider-specific request URL construction
- provider-specific request body construction
- provider-specific response parsing

The source lives in:

- `apps/bemoreagent-platform-ios/BeMoreAgentPlatform/ProviderTransport.swift`
- `apps/bemoreagent-platform-ios/BeMoreAgentPlatform/CloudExecutionService.swift`

## Provider shapes currently handled

### OpenRouter
- normalized as an OpenAI-style chat-completions provider
- request path ends in `/chat/completions`
- request body uses `model`, `messages`, `stream`
- response parser expects `choices[0].message.content`

### NVIDIA
- treated as OpenAI-compatible chat completions
- request path ends in `/chat/completions`
- request body uses `model`, `messages`, `stream`
- response parser expects `choices[0].message.content`

### Hugging Face
- normalized toward the router-based OpenAI-compatible chat-completions path
- request path ends in `/chat/completions`
- request body uses `model`, `messages`, `stream`
- response parser expects `choices[0].message.content`

### Google
- uses the Gemini `generateContent` request style
- request URL includes `/v1beta/models/{model}:generateContent`
- request body uses `contents` and `generationConfig`
- response parser expects `candidates[].content.parts[].text`

### Ollama
- uses `/api/chat`
- request body uses `model`, `messages`, `stream`
- response parser expects `message.content`

## What this does not prove yet

This request layer does **not** prove that provider execution is production-complete.

It still needs:

- Xcode compile validation
- simulator/device request validation
- provider-by-provider auth testing
- secure credential handling review
- retry/error-state UX review

## Why this still matters

Before this pass, the platform subtree had provider accounts and model defaults but no real request-building layer.

After this pass, the repo now contains a concrete starting point for:
- provider probing
- cloud model execution
- provider-specific parsing improvements
- later migration into a unified BeMoreAgent app target
