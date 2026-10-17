# Reproductions and fixes

## BA-WORLD-001: malformed nested save accepted

Reproduction: save a valid beacon, then restore JSON with a valid schema/generator/
seed but `states[region_id]["beacon"]` set to a string. Expected: ERR_INVALID_DATA
and the existing world state preserved. Actual before fix: restore returned OK and
replaced live state with data the scene's `.get()` calls could not consume.

Root cause: only the top-level `states` dictionary was checked. Fix: validate every
region dictionary and object-state dictionary before assigning any live state.
The integration test checks both rejection and preservation, then restores a valid
save and continues running scenes.

## BA-WORLD-002: unbounded pending generation during teleports

Reproduction: issue sixteen widely separated position updates before the next
process frame. Expected: at most nine tasks for the default 3×3 region window.
Actual before fix: every new position enqueued another neighborhood before stale
results could be consumed.

Root cause: active-region bounds did not bound work in flight. Fix: schedule only
up to the neighborhood task limit, prioritize nearer regions and refill after
completed/stale results are consumed. Refill also works when the player stops
moving. Existing shutdown joins are retained. Regression checks the pending bound,
then confirms unload/streaming behavior and physics in the actual scenes.

Evidence: `reports/scene-integration-before-fix.log` has three failed assertions
covering these two defects. `reports/scene-integration.log` and
`reports/integration-results.json` show 21/21 passing checks after the fix.

## BA-CONFIG-001: interpolation camera warning

Godot reported that Camera2D idle processing was overridden because physics
interpolation was enabled. The scene now explicitly selects physics processing.
The final integration and benchmark logs contain no such warning. This was a
project configuration correction, not an engine defect.

## Build-state recovery

Compilation initially reached the linker but failed with missing symbols. The
workspace contained zero-byte object files and static archives with zero-byte
members. The source was preserved. Empty objects were regenerated, affected static
archives were recreated, and the final link succeeded. The successful executable
then passed actual native tests, editor startup and scene integration.

`empty-objects.json`, `recovery-20261017.json`, `empty-archive-members.json` and the
archived failed-build logs record the observations. The reason those temporary
outputs became empty was not established; this is not attributed to a Godot code
bug. Recovery removed only reproducible build intermediates. The current build
script preserves previous build logs before another run.

## Source-history packaging

A shallow Godot `git bundle --all` passed `git bundle verify` but failed an actual
clone because upstream parent commits were omitted. The source packager therefore
preserves the fork's real shallow Git database and boundary alongside its complete
working source snapshot. The parent BigArcade repository is not shallow and is
preserved as a regular bundle. Do not describe the Godot fork as a full upstream
history mirror.
