# Known limitations — 0.2.0-dev, 2026-10-17

## Release blockers

| ID | Status and next action |
| --- | --- |
| QA-01 | Desktop editor and scene pixels are not verified. Xvfb failed to create permitted listening sockets in this environment. Run the delivered build on a real Linux desktop, inspect all three scenes, Studio dock, splash, input and shadows. |
| QA-02 | Windows x64 has build instructions and CI only. No Windows compiler/runtime was available here; build and execute on Windows before making Windows support claims. |
| QA-03 | GPU timings, Forward+ rendering, SDFGI, volumetric fog, reflections and real GPU memory are unverified. Headless data cannot establish rendering performance. |
| QA-04 | No connected GitHub repository was returned. CI has not run remotely and native source has not been pushed to GitHub. Source/history are delivered as an archive. |

The version remains **0.2.0-dev**. Successful headless startup and scene execution
do not close the graphical verification gate.

## Technical debt

- The delivered Linux editor is an unoptimized development build (`optimize=none`,
  tests enabled, no LTO). Build `release` and remeasure on actual target hardware.
- Tested host uses glibc 2.39. Older Linux distributions and driver combinations
  are untested. `ldd` lists direct dependencies only; display/audio/GPU libraries
  loaded at runtime are also needed for desktop use.
- Accessibility build warning: optional AccessKit dependencies were unavailable.
  Screen-reader integration is not validated. Wayland is disabled; X11 is compiled.
- World saves validate schema, seed and nested object dictionaries, but lack atomic
  replacement, backups, size limits and migration. Arbitrary external save files
  are not a supported interchange format.
- Region generation is bounded, but SceneTree creation is budgeted by region count,
  not elapsed milliseconds. Fast travel, loading screens, collision readiness,
  long soak tests and persistent-state size limits remain future work.
- The generator produces grid regions with center corridors. It does not implement
  complete terrain, dungeon or cave generation, NPCs, quests or navigation streaming.
- Profiling reports wall intervals, selected CPU monitors and static allocated
  memory. It does not measure end-to-end input latency, total process RSS, total VRAM
  or every render pass. CPU and GPU channels must not be added together.
- Automatic quality degradation is an opt-in script prototype, not calibrated
  hardware detection. Frame p95 exceeded the strict pacing budget in the recorded
  smoke tests; stable 60/120 FPS with graphics is not demonstrated.
- Isometric character shadows use an approximate capsule proxy; custom height maps,
  sprite normal/emission authoring, full material tools and screenshot regressions
  are planned for Lighting 0.3.
- The Studio dock and scene templates are minimal. Project-manager branding and
  template UX, dedicated lighting/performance panels and a stable plugin API policy
  remain future work. Existing Godot tools provide the working baseline.
- C#/.NET, Rust modules, export templates, packaged games, macOS, Android, iOS and Web
  are not built or tested. PlayCanvas remains a documented design decision.
- Only the BigArcade native test subset and project integration tests ran; the full
  Godot test suite, sanitizers and long-running stress tests were not executed.

## Resolved and recorded issues

See `REGRESSIONS.md` for the reproduced malformed-save and task-queue defects,
their fixes and before/after evidence. No upstream Godot rendering/physics defect
is claimed fixed by this checkpoint.
