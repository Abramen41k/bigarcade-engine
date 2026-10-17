# Decision: a separate browser runtime, shared assets

Status: research/design only for 0.7. No PlayCanvas runtime, SDK or exporter is
claimed implemented or tested in 0.2.

Godot and PlayCanvas own different rendering, entity/scene, input, physics, resource
and scripting systems. Linking their renderers into one frame loop would create
duplicated ownership and large maintenance costs. Keep native Godot and browser
PlayCanvas as independent runtimes. Treat a browser target as a separate product
capability with explicit feature support, not a transparent Godot replacement.

| Data/subsystem | Shared boundary | Limitations |
| --- | --- | --- |
| Meshes, hierarchy, skins, animations | glTF 2.0 / GLB assets | Validate extensions, coordinates, units, root motion and animation semantics |
| PBR textures/materials | glTF metallic-roughness baseline | Godot ShaderMaterial graphs, screen-space effects and custom shaders need independent implementations |
| Images/audio | Reviewed standard formats plus hashes | Import settings, texture compression and platform codecs differ |
| Scene description | Versioned neutral JSON: IDs, transform, GLB URI, selected component data | Requires validation and explicit unsupported-feature errors; not raw `.tscn` translation |
| World persistence | Seed, generator version, region/object IDs, JSON state | JavaScript hash arithmetic must reproduce uint32 semantics; physics determinism is not implied |
| Game behavior | Domain/event contracts, test vectors | GDScript, C# and C++ do not automatically run in PlayCanvas; behavior needs TypeScript implementations |
| Physics, rendering, navigation, editor | Remain runtime-owned | No shared live Godot Node/PlayCanvas Entity object model |

Godot can export 3D scenes with GLTFDocument, but not all Godot scene features survive
export (notably custom shaders, 2D content and particles). PlayCanvas supports GLB
model containers including materials and animations. Therefore asset interoperability
is plausible; semantic project compatibility is not established by the file format.

A future TypeScript SDK should validate a versioned manifest, resolve assets by
content hash, build a supported component subset, expose interaction/save contracts,
and report dropped or unsupported fields. Keep native/web golden test vectors for
the seed algorithm and scene transforms. Begin with one static GLB, one skinned
animation, one interaction and one saved beacon state before expanding scope.

The initial interchange convention should be meters, Y-up, explicit coordinate
conversion at adapters, local TRS and stable string IDs. For each material publish
the supported alpha mode, texture color spaces, normal convention and extension
allowlist. Do not infer engine-specific normal-map orientation or camera forward
axes merely from both engines accepting glTF.

## Licenses

Godot and the open-source PlayCanvas **engine** use MIT; their copyright/license
notices can coexist in a distribution. Third-party codecs/libraries, imported assets
and extensions require their own notice review. PlayCanvas hosted Editor, storage,
collaboration and other services have separate service terms; the engine's MIT
license does not grant those services. No service account, subscription or hosted
workflow is required or created by this foundation.

## Primary sources, reviewed 2026-10-16

- https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/exporting_3d_scenes.html
- https://docs.godotengine.org/en/stable/classes/class_gltfdocument.html
- https://developer.playcanvas.com/user-manual/assets/models/exporting/
- https://developer.playcanvas.com/user-manual/assets/supported-formats/
- https://github.com/playcanvas/engine/blob/main/LICENSE
- Godot `LICENSE.txt` and `COPYRIGHT.txt` at the pinned upstream commit.

Before 0.7 implementation, pin a tested PlayCanvas engine version and record the
license/extension set. No unpinned current version is added to the build now.
