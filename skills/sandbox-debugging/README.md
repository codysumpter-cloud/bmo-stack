# Sandbox Debugging

## Purpose

Diagnose and fix issues where the OpenClaw sandbox worker (`bmo-tron`) is misconfigured or behaving incorrectly.

## When to use

- main agent appears sandboxed
- worker cannot access expected capabilities
- Docker containers exist but behavior is wrong
- commands fail differently between main and worker

## Expected state

- `main` → sandbox mode OFF
- `bmo-tron` → sandbox mode ALL
- worker has network access when intended
- worker is isolated from host-critical operations

## Common failure modes

- main agent accidentally sandboxed
- worker network misconfigured
- sandbox recreated but routing not reapplied
- Docker running but sandbox containers missing

## Debug approach

1. inspect current sandbox config
2. confirm which agent is handling the request
3. verify Docker containers exist and are running
4. recreate sandbox if state is unclear
5. reapply agent configuration if needed

## Related

- scripts/configure-openclaw-agents.sh
- openclaw sandbox explain
- openclaw sandbox recreate --all --force
