# BMO on My MacBook

## Goal

Run one coherent BMO setup on a MacBook without pretending the old donor repos are still the live runtime.

## Runtime ownership today

- `bmo-stack` is the operator control plane, context source, and workspace-sync source.
- `openclaw` is the live host runtime source that owns Telegram delivery behavior.
- `/usr/local/lib/node_modules/openclaw` should resolve to the checked-out `~/code/openclaw` repo.
- `~/.openclaw/workspace/bmo-stack` is a mirrored workspace for context and repo files. It is not the same thing as the live Telegram runtime code.
- BMO is the only front-facing agent.
- Council members are internal subagents.

## What is archived or donor-only

- `PrismBot` is archived source material.
- `omni-bmo` is a donor repo for embodied local runtime features.

## Recommended layout

```text
~/code/
  bmo-stack/
  openclaw/
  omni-bmo/        # optional donor/runtime bridge target
  PrismBot/        # optional archived reference copy
```

## Daily operator flow

From `bmo-stack`:

```bash
make doctor-plus
make health-check
make omni-doctor
```

If you need to refresh all local repos:

```bash
make update-all
```

If you want the MacBook workspace mirror to stay current automatically:

```bash
make launchd-install
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/cloud.codysumpter.bmo-workspace-sync.plist
launchctl kickstart -k gui/$(id -u)/cloud.codysumpter.bmo-workspace-sync
```

That LaunchAgent runs `scripts/bmo-workspace-sync.py` at login and every 5 minutes by default, keeping `~/.openclaw/workspace/bmo-stack` aligned with the repo and syncing repo context into `~/bmo-context`.

From `openclaw`, update the live runtime code:

```bash
cd ~/code/openclaw
git fetch origin
git checkout main
git pull --ff-only origin main
node --test ./extensions/telegram/src/delivery-regressions.test.js
launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway
```

If BMO is unhealthy:

```bash
make recover-bmo
```

## Integration rules

- Keep new operator logic BMO-first in `bmo-stack`.
- Keep concrete Telegram/runtime delivery fixes in `openclaw`, then pull them onto the MacBook and restart the gateway.
- Use PrismBot docs/scripts as migration references only.
- Use `omni-bmo` helpers only through BMO bridge scripts unless there is a good reason not to.

## Verify the live runtime path

Run these on the MacBook before claiming a Telegram/runtime fix is live:

```bash
realpath /usr/local/lib/node_modules/openclaw
realpath "$(which openclaw)"
launchctl list | grep ai.openclaw.gateway
```

## Related

- `docs/BMO_CONSOLIDATION.md`
- `docs/OMNI_BMO_INTEGRATION.md`
- `RESEARCH_CITATION_MODE.md`
