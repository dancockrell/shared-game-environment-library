# River-port construction study — 2026-09-05

These are actual Godot captures of constructed 3D geometry, not generated concept images or image backgrounds. The approved painted-miniature reference remains the quality target in `../visual-reference/`; this study does **not** replace it or satisfy final visual admission.

## Deliverables

- `river-port-main.png`: primary orthographic composition.
- `river-port-ground.png`: same camera and geometry with buildings hidden, exposing the traced quay, bridge landings, and dock footprint.
- `river-port-alternate.png`: opposite front quarter.
- `river-port-roundtrip.png`: independent process reloading the saved native scene.
- `river-port-rear.png`: rear-quarter inspection of that saved scene.
- `river-port-native.scn`: native editable hierarchy with embedded geometry, triplanar surfaces, lights, camera, and static water shader.
- `river-port-scene.glb`: geometry interchange proof. Renderer-specific water and triplanar surfaces are **not** preserved. Use the native scene for visual evaluation.
- `build-report.json`: material input hashes, renderer, seed, and measured submission counts.

## Preserved direction

Build visual quality first. No polygon-reduction target has been imposed, and no automatic decimation was applied to the authored environment. Optimization requires measured evidence and a subsequent decision. Prominent raised gold nodes and gold connections remain part of the tabletop presentation. Inn and guild have complete rear/side walls and roof geometry for other camera angles; the merchant shop is an explicit open-front cutaway variant.

The scene includes individual overlapping roof tiles, fitted irregular paving stones, staggered masonry, timber frames, dormers, shelves, curved awning, lanterns, tables, dock planks/piles/rope, bridge, shoreline rocks/reeds, and a constructed clinker rowboat with ribs and benches. Nothing is animated. Three articulated figure studies now have 15-bone rigid-piece rigs; these replace the unrigged cylinders. They are **not production character sculpts**, do not have deformable skin/cloth, and are not final asset admissions. Two robed figures still fail to reproduce the reference's distinct mage and ranger identities.

## Reference reconstruction correction

The user rejected the initial rectangular platforms, sideways bridge, independent generic architecture, and coarse/cartoon-like construction. Increasing piece count did not address those defects. The approved image remains authoritative, including its finer forms, shadow complexity, and conspicuous gold points.

The builder now converts manually traced source pixels from the 1536 by 1024 reference into 3D points by intersecting camera rays with stated ground heights. `reference_quay()` owns the continuous perimeter. Dock geometry uses four independently traced corners: back-left (675,717), back-right (853,773), front-left (419,898), front-right (537,973). The bridge uses its own rear and front landing centers (855,551) and (723,744), at heights 0.8 and 0.3. The dock is therefore not an extension of the bridge axis. Its planks run lengthwise, with real thickness, joints, piles, and rope.

These measurements are manual approximations of visible boundaries, not automatic image segmentation or a claim of exact matching. Rear contours occluded by roofs/cliffs are inferred at foundation level, not traced around roof silhouettes. No reference pixels are pasted into the render. Elevated markers, figure bases, table positions, vegetation anchors, and the rowboat position also use source-pixel anchors where visible. The layout is only a reconstruction study, never authoritative game topology.

Building corrections include a narrower main inn volume and perpendicular right wing, a larger cutaway shop with its front side walls lowered, and a rotated guild with a taller stone pediment, finials, banners, and larger entrance. Thin eight-pane joinery, reduced bevels, finer roof layers, and full-resolution input material maps address part of the chunky form language. Roof planes now rotate about their actual centers, and tile offsets are measured along the roof normal so thinner tiles do not disappear inside the deck.

This is a neutral catalog study, not a DragonRealms map or client implementation. Gold connections here are composition fixtures, not authoritative exits. Client integration must derive rooms, connection types, movement, and state from the actual MUD graph; visual distance never creates an exit.

## Provenance and transformation

Environment geometry is authored by the included deterministic Godot construction code (`tools/river-port-kit.gd` and `tools/build-river-port.gd`). The approved image is a visual reference only; its pixels are not projected onto geometry. The crate uses the existing normalized catalog derivative and its curated source-pack provenance. The earlier imported boat has been replaced in this scene by the authored curved hull; the original source pack remains unchanged. No new downloaded assets were introduced for this study.

Surfaces use the existing approved Poly Haven rock-boulder-dry, medieval-wood, and fabric-pattern-05 material seeds. Their six exact inputs, SHA-256 hashes, and CC0 source declarations are recorded in the report and checked before loading. Albedo retains the full 1K source resolution, is converted to monochrome luminance modulation, and is multiplied by the painted palette; normal strength is 0.8. Original source files remain unchanged. These are material transformations, not polygon simplification.

Do not infer a new blanket CC0 grant for the authored scene from the licenses of these upstream inputs. This study is not added to the approved runtime asset manifest; final admission, distribution terms, and consumer bindings remain outstanding.

## Rebuild and verify

Validated with Godot 4.7.2, Forward+, Vulkan, RTX 4070. From repository root, with `godot` pointing to that executable:

```text
godot --path tools --rendering-method forward_plus --script res://build-river-port.gd -- <absolute-repository-path>
godot --path tools --rendering-method forward_plus --script res://build-river-port.gd -- <absolute-repository-path> --inspect
```

Rebuild uses deterministic seed 5012026. Inspection reloads the native file in a separate process, verifies finite mesh transforms and nonempty bounds, captures front and rear, imports the GLB, and checks mesh-instance count parity against the current build report. It also checks three native skeletons, each with 15 bones and an elevated head pose. This is a rest-pose hierarchy check, not deformation/animation validation, a manifold audit, a collision test, or a game-integration test.

Current authored-piece, mesh-instance, rendered-primitive, and draw-call counts are in `build-report.json`. Renderer submissions include passes; they are **not** unique mesh polygon counts or a frame-rate benchmark. Performance acceptance has not been established. Forward+ review now uses temporal antialiasing alongside MSAA and an 8192-pixel directional shadow atlas; captures allow temporal accumulation. This is a visual review configuration, not a proposed minimum runtime requirement.

## Visual review and next work

Front, alternate, saved-scene roundtrip, and rear captures were inspected. Initial reversed surface winding and unwanted smooth-normal artifacts were corrected before this checkpoint. Complete roof/back geometry survives the alternate views.

The result remains below the approved illustration. Exact architectural profiles, roof junctions, carved ornaments, richly stocked shop contents, individual character sculpting, and fine weathering are not reproduced. Vegetation and beach transitions remain too procedural, and the inferred rear ground should not be mistaken for evidence of the reference's unseen layout. Those are unresolved quality gaps, **not** a proposed simpler art direction. Preserve the approved richness while improving these aspects. Rear walls are structurally present but need designed facade detail before unrestricted camera presentation is considered finished. No numerical visual-similarity score or claim of exact recreation is made.
