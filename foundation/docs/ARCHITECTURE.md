# Foundation architecture

## Boundaries

Godot owns its rendering backends, scene tree, resource import, physics, audio,
platform abstraction and editor. BigArcade adds a small native module and project
tools. There is no replacement renderer, incompatible physics loop or duplicate
ECS hidden under the editor.

`namespace bigarcade` contains portable deterministic region generation and a
bounded frame-history ring. `BigArcadeRuntime` is a registered RefCounted adapter;
public ClassDB identifiers use the BigArcade prefix. Engine registration occurs
at scene initialization. Native source is compiled as C++20; portable core tests
also compile as C++17 to guard avoidable coupling to the new language standard.

GDScript orchestrates scene creation, player input, profile selection, persistence
and editor tools. Core C++ remains free of platform I/O and scene ownership.
C# projects will require a separate `module_mono_enabled=yes` build and matching
.NET SDK/export templates. No such build is included. Rust needs an isolated
measured use case before adding ABI and toolchain costs. TypeScript is reserved
for browser tools and a future separate runtime.

## Performance

The ring records wall-clock intervals between process callbacks, Godot CPU process
and physics monitors, optional viewport GPU measurements and static allocated
memory. These channels are not additive: CPU/GPU overlap, sample timing and
monitor scopes differ. Wall intervals include sleep/VSync/pacing. GPU timing is
null when unavailable, including dummy rendering. Static memory is not total RSS
or VRAM. Exported raw samples allow recalculation of nearest-rank percentiles.

Budgets apply to the full frame: 1000/60 = 16.6667 ms and 1000/120 = 8.3333 ms.
The limiter is independent of `Engine.physics_ticks_per_second=60`; physics moves
characters in `_physics_process`, with engine interpolation enabled. Test-generated
teleports reset interpolation. Loading hitches and pacing jitter can exceed the
budget even when average simulation time is small.

Low/medium/high quality controls scaling, antialiasing and shadows. High enables
SDFGI/volumetric fog only with Forward+. Optional automatic selection only steps
down after sustained p95 excess; it is disabled by default and is a prototype.
It is not a hardware classifier. A production selector needs hardware cohorts,
thermal/power states, hysteresis, stable warmup and user overrides.

Existing Godot mechanisms are used instead of rewritten: Canvas batching for 2D,
MultiMesh per region for repeated 3D blocks, frustum culling and unloaded distant
regions. MultiMesh is culled as a group, hence region-sized batches. Imported mesh
LOD, visibility ranges and occlusion culling are candidates for measured 0.4 work;
they are not advertised as implemented optimizations here.

## World

Regions are 16×16 cells indexed by floor(world position / side), including negative
coordinates. A versioned unsigned integer hash makes seed/coordinate generation
deterministic. Corridors connect through region centers. This produces a small
test world; it is not a dungeon connectivity solver, cave mesher or terrain system.

WorkerThreadPool tasks produce data only. The main thread creates SceneTree nodes
at at most one region per process frame. A 3×3 neighborhood bounds active regions.
Unload removes geometry; separate state keyed by stable `ba:seed:x:z` region IDs
and object IDs survives unload. Beacon activation proves save/restore semantics.
Shutdown joins pending work before releasing the streamer. Generated geometry is
reconstructed, while gameplay state is persisted as JSON, schema/generator 1.

Future NPC, quest and interaction services should refer to stable object IDs and
consume region lifecycle signals. No live Object instance or executable resource
is deserialized from saves. Future work includes migration, atomic saves/backups,
streaming priority, collision readiness, memory budgets and time-based instantiation
slices. The prototype does not guarantee smooth travel or infinite worlds.

## Studio

Engine name, version marker and splash identify BigArcade Studio. The project dock
creates working demo scene copies and selects target FPS. CLI templates create a
new project without overwriting an existing destination. The inherited scene tree,
inspector, import and material tools remain available. Existing EditorPlugin APIs
are the extension mechanism. A dedicated project-manager template picker and
full material/performance inspector are future Studio work.
