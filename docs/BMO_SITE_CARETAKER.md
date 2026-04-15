# BMO Site Caretaker

## Purpose

Inventory the legacy `prismtek-site` donor and the `prismtek-site-replica` React/Vite candidate, then emit a controlled migration plan artifact.

## Commands

Basic run:

```bash
node scripts/bmo-site-caretaker.mjs
```

Explicit paths:

```bash
node scripts/bmo-site-caretaker.mjs \
  --site-dir ~/prismtek-site \
  --replica-dir ~/prismtek-site-replica
```

If the default paths do not exist, the helper searches under the discovery root and reports candidate paths:

```bash
node scripts/bmo-site-caretaker.mjs --discovery-root ~
```

You can also set:

- `BMO_SITE_DIR`
- `BMO_SITE_REPLICA_DIR`
- `BMO_SITE_DISCOVERY_ROOT`

## Output

Writes `workflows/bmo-site-caretaker.json` containing:

- site inventory
- replica inventory
- discovery candidates when paths are missing
- route-level migration plan
- chat/API candidate files in the site and replica repos
