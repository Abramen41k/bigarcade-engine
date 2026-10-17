# BigArcade Engine — Godot Foundation 0.2.0-dev

Native Godot fork, C++ module, editor plugin and three executable technical scenes.
This is a development checkpoint, not a stable release or a claim of production readiness.
The former browser/PixiJS project is not included in this engine-only repository.
The engine-only source package represents the `0.2.0-dev` checkpoint.

## Build

Pinned base: Godot **4.7.2-stable**, commit
`ed1daf0bf001b61586d9930840f2f1394092c079`. See `UPSTREAM.lock.json`.
Python 3.12 and SCons 4.11.1 are used here. Upstream and bundled dependencies keep
C++17; `modules/bigarcade/SCsub` selects C++20 only for the BigArcade module.

Run these commands from the repository root:

```sh
python -m pip install -r foundation/requirements-build.txt
python foundation/tools/bootstrap.py
python foundation/tools/build.py --platform linuxbsd --profile development --jobs 4
```

Linux needs GCC/G++, binutils and pkg-config; Wayland is disabled in this initial
profile. The build retains both OpenGL Compatibility and Vulkan renderers.
`development` uses `optimize=none`, no LTO and no debug symbols to reduce resource
requirements. Use `--profile release` for `optimize=speed` performance work.
Neither profile changes simulation frequency. Build command, duration, exit code
and logs are recorded under `reports/`. Byte-identical builds are not promised:
compiler, host libraries, commit metadata and toolchain also affect binaries.

On Windows x64, use an x64 Visual Studio 2022 Developer Command Prompt with the
Desktop C++ workload, Windows SDK, Python and Git:

```bat
python -m pip install -r foundation/requirements-build.txt
python foundation/tools/bootstrap.py
python foundation/tools/build.py --platform windows --profile release --jobs 4
```

Upstream produces `godot.*` executables. The build tool also creates `bigarcade.*`
copies with the same bytes; the Windows console wrapper and main executable must
remain together. Windows CI is configured but was not run in this Linux workspace.

## Run and test

```sh
foundation/engine/godot/bin/bigarcade.linuxbsd.editor.x86_64 --editor --path foundation/projects/lab
foundation/engine/godot/bin/bigarcade.linuxbsd.editor.x86_64 --path foundation/projects/lab
python foundation/tools/test_native.py
python foundation/tools/verify.py --binary foundation/engine/godot/bin/bigarcade.linuxbsd.editor.x86_64
```

The verification tool runs native Godot tests, editor asset import, scene/physics/
streaming integration and six paced CPU smoke benchmarks. Its default is headless:
the dummy renderer provides **no evidence of graphical correctness or GPU speed**.
On a real desktop use `--display desktop`. Review the actual reports; a successful
shell exit alone is insufficient because Godot may log a script error and exit 0.

In the laboratory, choose 2D / 2.5D / 3D in the header. WASD or arrows move; Space
jumps in 3D; hold right mouse to rotate the 3D camera; E activates a nearby beacon;
F6 changes 60/120 FPS, F7 changes quality, F8 exports `user://performance.json`.
Physics remains at 60 Hz with Godot interpolation enabled.

```sh
python foundation/tools/create_project.py /absolute/path/MyGame --mode 3d --name MyGame
```

The Studio dock creates editable scene copies in `res://created_scenes/`. Godot's
project manager, scene tree, inspector, importers, material tools and plugin system
remain the editor foundation. Full BigArcade project-manager redesign is deferred.

## Layout

| Path | Purpose |
| --- | --- |
| `modules/bigarcade/` | Native registration, frame history, seeded region data, Godot tests |
| `projects/lab/` | Three scenes, player physics, streamed regions, telemetry, Studio dock |
| `branding/` | Editable SVG and editor splash PNG |
| `tools/` | Bootstrap, build, project creation, verification, upstream review |
| `tests/` | Standalone C++17/C++20 regression and microbenchmark |
| `docs/` | Audit, architecture, Lighting plan, PlayCanvas decision, limitations |
| `reports/` | Real commands, test logs, machine-readable measurements |
| `engine/godot/` | Godot fork checkout (created by bootstrap in the compact package;
  provided without nested Git database in the full-source package) |

Use the full source archive for offline source inspection; it includes the Godot
source snapshot and the parent repository history. A fresh online reconstruction
uses the pinned upstream commit and the versioned overlay instead of vendoring the
whole upstream tree into every parent commit. See `docs/UPSTREAM.md`.

## Licensing and status

New Foundation code uses MIT (`LICENSE.txt`). Godot and third-party notices are
preserved in `LICENSE-GODOT.txt`, `COPYRIGHT-GODOT.txt` and the full source tree.
Existing 0.1 assets keep their provenance; this does not relicense the old project.
No PlayCanvas engine code or service is embedded. C#/.NET, Rust, mobile, macOS and
Web builds are architectural options, not tested deliverables.

`DEVELOPMENT_REPORT.md` and `docs/KNOWN_ISSUES.md` state the verified status and exact
next continuation point. Do not promote this checkpoint to stable 0.2.0 until the
remaining release gates are actually passed.
