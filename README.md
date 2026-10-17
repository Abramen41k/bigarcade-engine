# BigArcade Engine 0.2.0-dev — Godot Foundation

This repository contains **only the Godot-based BigArcade Engine 0.2.0-dev**.
The previous TypeScript/PixiJS web project is **not included**.

**Status:** development checkpoint, **not** a finished 0.2.0 stable release. The Godot 4.7.2-based Linux editor was compiled and headless-tested in the original development environment. Windows compilation and actual GPU/desktop rendering have **not** been validated. 60/120 FPS are performance targets, not demonstrated graphics FPS.

## What's included

- `foundation/modules/bigarcade/` — BigArcade native C++20 module and tests.
- `foundation/projects/lab/` — 2D, isometric 2.5D and 3D demo scenes; editor add-on (`addons/bigarcade_studio`); profiler/streaming prototype.
- `foundation/tools/` — reproducible Godot fork bootstrap, build, tests, project creation and verification.
- `foundation/branding/` — editor identity / splash resources.
- `foundation/docs/`, `foundation/reports/` — technical documentation, known issues and historical test reports.
- `.github/workflows/godot-foundation.yml` — Linux/Windows build/test workflows; CI results on GitHub are not yet known.

## Getting the Godot source

Two alternative archives were produced:

**iPhone / GitHub archive:** contains BigArcade's Godot module, tools, demos and dependencies lock **without vendored upstream Godot files**. This is the preferred one to commit from a phone. Running bootstrap clones the pinned upstream Godot source and applies the overlay.

**Complete source archive:** also includes `foundation/engine/godot/`, the full modified Godot source snapshot (but no nested `.git` database, compiled editor or binary exports). It can be used to compile without re-downloading the upstream source. It is significantly larger and contains thousands of files.

### Build (Linux)

Requires Python 3.12, Git, C++ compiler, SCons, pkg-config and dependencies expected by Godot.
From the repository root:

```bash
python -m pip install -r foundation/requirements-build.txt
python foundation/tools/bootstrap.py
python foundation/tools/build.py --platform linuxbsd --profile release --jobs 4
python foundation/tools/verify.py --binary foundation/engine/godot/bin/bigarcade.linuxbsd.editor.x86_64
```

On Windows x64, use a **Visual Studio 2022 x64 Developer Command Prompt** with C++ tools, Windows SDK, Git and Python:

```bat
python -m pip install -r foundation/requirements-build.txt
python foundation/tools/bootstrap.py
python foundation/tools/build.py --platform windows --profile release --jobs 4
```

Windows compilation is unverified. Run the appropriate editor executable and open `foundation/projects/lab/project.godot` (or use `--editor --path foundation/projects/lab`). The tools preserve build logs in `foundation/reports/`.

## Important

The promotional BigArcade Studio screenshots shown in announcements were **visual mockups**, not captures of this build. Current Studio modifications are a branded splash, a small dock and three launchable technical templates; the full custom editor is still planned.

Only Godot's existing lighting pipeline is used in this checkpoint; a distinct BigArcade Lighting renderer and a PlayCanvas runtime **have not been implemented**. See `foundation/DEVELOPMENT_REPORT.md` and `foundation/docs/KNOWN_ISSUES.md`.

Original Godot is distributed under MIT and retains third-party licenses/copyright. BigArcade's own module uses MIT; see `foundation/LICENSE.txt`, `foundation/LICENSE-GODOT.txt`, `foundation/COPYRIGHT-GODOT.txt` and the Godot source licenses in the full package.

Version: `0.2.0-dev` — Source provenance: `foundation/UPSTREAM.lock.json`.
