# iBuddy Runtime Prototype Boundary

## Status: Prototype
This directory contains the prototype transport and bootstrap layer for the iBuddy runtime. 

## Current Dependency: Hermes Reference Runtime
This prototype is currently a **thin-slice wrapper** around the reference implementation located in the `hermes-agent` repository. It does not yet contain its own native runtime logic.

### Dependency Model
The `runtime_bootstrap.py` module acts as the explicit boundary. It resolves the path to the reference runtime, validates the environment, and provides the `BuddyAdapter` instance to the API server.

### Exit Plan
To move toward true ownership by `BeMore-stack`, the following steps are planned:
1. **Native Implementation**: Develop a native `iBuddy` runtime implementation within `BeMore-stack/runtime/native/`.
2. **Bootstrap Pivot**: Update `runtime_bootstrap.py` to instantiate the native implementation instead of the reference adapter.
3. **De-coupling**: Remove the reference-runtime bootstrap logic and the dependency on the `hermes-agent` repository entirely.
