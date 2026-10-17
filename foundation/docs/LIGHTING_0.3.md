# BigArcade Lighting 0.3 — measured extension plan

## What 0.2 uses

| Scene | Existing Godot mechanisms | Verification boundary |
| --- | --- | --- |
| 2D | PointLight2D, PCF13 shadows, LightOccluder2D, CanvasModulate, procedural CanvasTexture normal map, animated atlas sprite | Scene/physics can be checked headlessly; pixels require desktop review |
| 2.5D | Orthographic Camera3D, shaded alpha-cut Sprite3D, shadow-only capsule proxy, PBR environment blocks, elevated point lights | Sprite is geometry in a real 3D light field; no invented 2D height-light solver |
| 3D | StandardMaterial3D PBR, directional/omni lighting, shadows, fog, slowly rotating sun | SDFGI and volumetric fog are gated to Forward+ high profile and remain GPU-unverified |

Compatibility is the conservative default. SDFGI, VoxelGI, screen-space reflections
and volumetric fog require other renderer support; ordinary fog is separate from
volumetric fog. Emissive materials are visible surfaces, not automatically general
dynamic GI light sources. A shadow proxy for the isometric character is deliberately
an approximation, not a claimed silhouette-accurate solution.

## Real constraints to investigate

These are documented engine limits or design tradeoffs, not newly proven upstream
bugs: SDFGI does not treat arbitrary dynamic occluders like a full dynamic path
tracer; transparent sprites can require sorting/alpha-cut tradeoffs; renderer
feature parity is incomplete; many shadowed lights and GI updates have significant
GPU cost. No upstream lighting bug is marked fixed without a reproduction.

## 0.3 sequence and acceptance

1. Establish Windows/real-GPU reference images on Compatibility and Forward+ with
   identical camera, exposure, time and seeds. Record GPU/driver/resolution.
2. Add sprite normal/emission authoring and a height metadata resource. Compare
   normal orientation under mirrored/animated sprites against known references.
3. Design shadow-proxy authoring for 2.5D, contact grounding and alpha-cut edges;
   measure camera-angle limitations before touching Godot render code.
4. Add a LightingProfile resource with backend capability checks, environment,
   exposure, shadow ranges and time-of-day curves. Persist artist overrides.
5. Benchmark localized GI/shadow update schedules during region loading. Compare
   SDFGI, baked lightmaps and probes on representative scenes before optimization.
6. For any engine defect: minimal project, expected image, actual image, hardware,
   root cause, smallest upstream-friendly patch, automated regression where feasible.

Acceptance requires reference-image review, measured frame/GPU memory cost, stable
fallback behavior and tests on at least two real hardware profiles. This roadmap
does not promise ray tracing or stable 120 FPS on all hardware.

## Primary sources, reviewed 2026-10-16

- https://docs.godotengine.org/en/4.7/engine_details/architecture/internal_rendering_architecture.html
- https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html
- https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/using_sdfgi.html
- https://docs.godotengine.org/en/4.7/tutorials/3d/3d_rendering_limitations.html

Stable documentation can change; the fork source and lock file define the actual
implementation baseline. No GPU measurements are inferred from these documents.
