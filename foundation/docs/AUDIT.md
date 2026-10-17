# Audit of the existing project — 2026-10-16

The local repository was found and inspected, including source, package metadata,
test output, continuation notes and Git history. This is not a reconstruction from
assumed contents. Prior work was retained.

| Evidence | Actual state |
| --- | --- |
| Old branch | `engine/development` at `eb9a732d402e4dd9e17eb8423a398b357828c057` |
| Preservation | `archive/pixi-0.1.0` points to that exact commit |
| Active branch | `foundation/godot-0.2.0` |
| 0.1 technology | TypeScript, PixiJS 8, browser canvas, two playable technical demos |
| Prior checks | 32 Vitest tests, type checking and project/library builds passed in prior work |
| Prior rendering caveat | Software Pixi render was checked; no browser/GPU certification |
| Previous fixes | `af6398e` corrected cave start/size behavior; `eb9a732` finalized release documentation |
| GitHub | Connected login `Abramen41k`; repository listing returned an empty array |
| GitHub write access | Cannot establish repository-level rights without an accessible repository; no push attempted |
| Existing hosted project | Existing private 0.1 Site retained; it is not replaced with native Godot source |

New Godot work occupies `foundation/` and a separate CI workflow. The previous
engine, assets, tests and build pipeline remain available. Prior tasks such as
browser/GPU verification and broader gameplay tooling remain unfinished; this
phase does not retroactively mark them complete.

## Reuse decisions

| Existing item | Decision |
| --- | --- |
| RPG atlas PNG/JSON | Reused byte-for-byte by 2D and isometric Sprite3D demos |
| Icon SVG | Reused as the laboratory project icon |
| Atlas source and extraction scripts | Retained in 0.1; no need to regenerate completed assets |
| Procedural world concepts, fixed-step intent | Reimplemented against Godot physics/SceneTree; TS code is not linked into C++ |
| TS ECS, Pixi filters and Web Audio | Preserved in 0.1; not suitable for direct native integration |
| Vitest tests | Remain tests of 0.1; do not count as native Godot coverage |
| Browser services/library packaging | Preserved as possible future web tooling; not claimed as PlayCanvas support |

The copied `rpg.png` SHA-256 is
`7724b9f30451562dc734ea39ae542d2059309a940132fa5069875b6e95563363`.
See the parent `docs/ASSETS.md` for original ImageGen provenance. No external game
art, music or proprietary engine content was introduced.

When a GitHub repository becomes accessible, add it as a remote after checking its
contents, push the preserved and development branches without force, and run the
configured CI. Do not overwrite an unrelated remote history.
