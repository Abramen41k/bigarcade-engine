# Changelog

## 0.2.0-dev — Godot Foundation, 2026-10-17

- Preserve the TypeScript/PixiJS 0.1.0 project and `archive/pixi-0.1.0` branch.
- Pin Godot 4.7.2-stable and create `bigarcade/godot-foundation` with a small,
  reproducible overlay and retained upstream licenses.
- Add the C++20 BigArcadeRuntime module; retain upstream C++17 and independently
  test the portable core under both language standards.
- Add bounded frame history, percentile/budget reporting and deterministic seeded
  region generation with explicit negative-coordinate behavior.
- Brand BigArcade Studio with a name/version marker/splash and add a minimal dock,
  three scene templates, a new-project CLI and retained inherited editor tools.
- Add 2D dynamic-light/normal-map scene, isometric Sprite3D scene and 3D PBR/physics
  scene, sharing fixed-step movement and interpolated presentation.
- Add headless-safe telemetry, 60/120 FPS caps, quality profiles, JSON export,
  worker-thread region generation and beacon state persistence.
- Reject malformed nested saves without replacing live state; bound generation
  tasks during rapid teleports. Add reproduced before/after regression evidence.
- Build and launch the Linux x64 editor; pass native, editor-import, Studio-startup,
  scene and template checks. Record six CPU-only paced smoke measurements.
- Add Windows/Linux CI, build/update/packaging tools, audit, architecture, Lighting
  0.3 plan, PlayCanvas decision, known issues and continuation instructions.

Not a stable release: desktop visual/GPU verification and Windows build execution
remain outstanding. No upstream renderer or physics fix is claimed.
