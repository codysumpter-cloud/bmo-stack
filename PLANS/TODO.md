## Problem
Need to add OpenClaw status bridge for mission control integration to enable better integration between BMO's mission control system and OpenClaw's status reporting.

## Smallest useful wedge
Add the basic status publishing functionality and verify it works with mission control.

## Verification plan
- Test that status publisher works correctly
- Verify mission control can receive and display status updates
- Check that all new scripts are executable and functional

## Rollback plan
- Remove the added scripts if issues are found
- Revert changes to existing scripts
- Ensure mission control continues to work with previous status reporting
