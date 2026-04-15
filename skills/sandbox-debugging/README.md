# Sandbox Debugging

## Purpose

Diagnose and fix issues where the OpenClaw sandbox worker (`bmo-tron`) is misconfigured or behaving incorrectly.

## Owner path

- `openclaw` owns live sandbox policy and routing behavior
- `openshell` owns sandbox inventory and lifecycle truth
- `BeMore-stack` owns the worker-status helper and recovery scripts

## When to use

- `main` appears sandboxed
- the worker cannot access expected capabilities
- Docker containers exist but behavior is wrong
- commands fail differently between `main` and the worker

## Expected state

- `main` -> sandbox mode off
- `bmo-tron` -> sandbox mode all
- worker has network access when intended
- worker is isolated from host-critical operations

## Common failure modes

- `main` accidentally sandboxed
- worker network misconfigured
- sandbox recreated but routing not reapplied
- Docker running but sandbox containers missing

## Fast path

```bash
scripts/bmo-worker-status
openclaw sandbox explain
openshell sandbox list
```

If the split has drifted badly, reapply it:

```bash
bash scripts/configure-openclaw-agents.sh
```

## Debug approach

1. inspect current sandbox config
2. confirm which agent is handling the request
3. verify Docker containers exist and are running
4. recreate sandbox if state is unclear
5. reapply agent configuration if needed

## Validation

- `scripts/bmo-worker-status` reports the expected checkpoint and sandbox presence
- `openclaw sandbox explain` shows `main` off and `bmo-tron` all
- `openshell sandbox list` confirms whether `bmo-tron` actually exists before claiming recreation worked

## Related

- `scripts/configure-openclaw-agents.sh`
- `scripts/bmo-worker-status`
- `openclaw sandbox explain`
- `openclaw sandbox recreate --all --force`
