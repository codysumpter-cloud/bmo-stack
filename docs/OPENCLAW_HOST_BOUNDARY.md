# OpenClaw Host Boundary

This repo tracks the desired operator contract for Cody's MacBook OpenClaw setup. The iOS app is a separate sandboxed client.

## Boundary

- Mac OpenClaw runtime state lives under `~/.openclaw`.
- The iOS app workspace lives inside the app container at `Documents/OpenClawWorkspace/.openclaw`.
- `bmo-stack` source files are the durable policy and automation source of truth.
- The app must not read or write the Mac's `~/.openclaw` files directly.
- The Mac runtime and app may interact only through an explicitly configured gateway, pairing, or manual export/import flow.

## Current Host Delivery Policy

Telegram should prefer one coherent answer. It should not stream lots of small paragraph-sized messages just because the model emits paragraphs.

Host policy:

- collect up to 20 inbound user messages into one agent turn before summarizing overflow
- keep Telegram reply threading on the first delivered chunk only
- use length-based outbound chunking
- coalesce block-streamed replies into near-Telegram-limit chunks

Apply it with:

```sh
make openclaw-host-policy
```

Verify the host/app boundary with:

```sh
make openclaw-boundary-doctor
```

## Expected Good State

- gateway config is local/loopback
- gateway listens on `127.0.0.1:18789`
- Telegram is bound to the host-facing `main` agent
- iOS source contains no direct `~/.openclaw` references
- the iOS app uses its own app-container `.openclaw` workspace

## Important Caveat

The OpenClaw CLI is the live owner for runtime delivery behavior. If a repo-side check passes but Telegram delivery still behaves incorrectly, continue in the live `openclaw` owner path and treat this repo as the policy/automation source, not proof that the live channel changed.
