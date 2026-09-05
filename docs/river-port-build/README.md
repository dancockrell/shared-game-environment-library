# River-port construction study — 2026-09-05

These are actual Godot captures of constructed 3D geometry, not generated concept images or image backgrounds. The approved painted-miniature reference remains the quality target in `../visual-reference/`; this study does **not** replace it or satisfy final visual admission.

## Deliverables

- `river-port-main.png`: primary orthographic composition.
- `river-port-alternate.png`: opposite front quarter.
- `river-port-roundtrip.png`: independent process reloading the saved native scene.
- `river-port-rear.png`: rear-quarter inspection of that saved scene.
- `river-port-native.scn`: native editable hierarchy with embedded geometry, triplanar surfaces, lights, camera, and static water shader.
- `river-port-scene.glb`: geometry interchange proof, approximately 5.8 MB. Renderer-specific water and triplanar surfaces are **not** preserved. Use the native scene for visual evaluation.
- `build-report.json`: material input hashes, renderer, seed, and measured submission counts.

## Preserved direction

Build visual quality first. No polygon-reduction target has been imposed, and no automatic decimation was applied to the authored environment. Optimization requires measured evidence and a subsequent decision. Prominent raised gold nodes and gold connections remain part of the tabletop presentation. Inn and guild have complete rear/side walls and roof geometry for other camera angles; the merchant shop is an explicit open-front cutaway variant.

The scene includes individual beveled roof tiles, fitted irregular paving stones, staggered masonry, timber frames, dormer, shelves, awning, lanterns, tables, dock planks/piles/rope, bridge, shoreline rocks/reeds, and three neutral scale pawns. Nothing is animated. Pawns are **unrigged placeholders**, not delivered production actors. Actor rigs and full character sculpts remain separate unfinished work.

This is a neutral catalog study, not a DragonRealms map or client implementation. Gold connections here are composition fixtures, not authoritative exits. Client integration must derive rooms, connection types, movement, and state from the actual MUD graph; visual distance never creates an exit.

## Provenance and transformation

Environment geometry is authored by the included deterministic Godot construction code (`tools/river-port-kit.gd` and `tools/build-river-port.gd`). The approved image is a visual reference only; its pixels are not projected onto geometry. Source boat, barrel, and crate are the catalog's existing normalized model derivatives, retaining the provenance chains of their curated source packs. No new downloaded assets were introduced for this study.

Surfaces use the existing approved Poly Haven rock-boulder-dry, medieval-wood, and fabric-pattern-05 material seeds. Their six exact inputs, SHA-256 hashes, and CC0 source declarations are recorded in the report and checked before loading. Albedo is converted to a restrained monochrome luminance modulation at 512 pixels and multiplied by the painted palette; normal maps use reduced strength. Original source files remain unchanged. These are material transformations, not polygon simplification.

Do not infer a new blanket CC0 grant for the authored scene from the licenses of these upstream inputs. This study is not added to the approved runtime asset manifest; final admission, distribution terms, and consumer bindings remain outstanding.

## Rebuild and verify

Validated with Godot 4.7.2, Forward+, Vulkan, RTX 4070. From repository root, with `godot` pointing to that executable:

```text
godot --path tools --rendering-method forward_plus --script res://build-river-port.gd -- <absolute-repository-path>
godot --path tools --rendering-method forward_plus --script res://build-river-port.gd -- <absolute-repository-path> --inspect
```

Rebuild uses deterministic seed 5012026. Inspection reloads the native file in a separate process, verifies finite mesh transforms and nonempty bounds, captures front and rear, imports the GLB, and checks mesh-instance count parity. Both contain 4,741 mesh instances. This is not a manifold audit, collision test, rig validation, or game-integration test.

The build contains 4,737 authored pieces plus imported prop meshes. Reported 496,744 rendered primitives and 1,634 draw calls are renderer frame submissions, including passes; they are **not** unique mesh polygon counts or a frame-rate benchmark. Performance acceptance has not been established.

## Visual review and next work

Front, alternate, saved-scene roundtrip, and rear captures were inspected. Initial reversed surface winding and unwanted smooth-normal artifacts were corrected before this checkpoint. Complete roof/back geometry survives the alternate views.

The result is still materially below the approved illustration: architecture is too regular and generic; vegetation needs authored branch/canopy forms; shoreline transitions are too block-like; stone/wood weathering and ornamental detail are insufficient; figures are only scale stand-ins. Rear water highlights and contact-shadow stippling also need a lighting/material pass. Those are unresolved quality gaps, **not** a proposed simpler art direction. Preserve the approved richness while improving these aspects. Rear walls are structurally present but need designed facade detail before unrestricted camera presentation is considered finished.
