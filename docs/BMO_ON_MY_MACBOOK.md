# BMO on My MacBook

## Goal

Run one coherent BMO setup on a MacBook without pretending the old donor repos are still the live runtime.

## What is live

- `bmo-stack` is the only live runtime and operator control plane.
- BMO is the only front-facing agent.
- Council members are internal subagents.

## What is archived or donor-only

- `PrismBot` is archived source material.
- `omni-bmo` is a donor repo for embodied local runtime features.

## Recommended layout

```text
~/code/
  bmo-stack/
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

If BMO is unhealthy:

```bash
make recover-bmo
```

## Integration rules

- Keep new runtime logic BMO-first.
- Use PrismBot docs/scripts as migration references only.
- Use `omni-bmo` helpers only through BMO bridge scripts unless there is a good reason not to.

## Related

- `docs/BMO_CONSOLIDATION.md`
- `docs/OMNI_BMO_INTEGRATION.md`
- `RESEARCH_CITATION_MODE.md`
