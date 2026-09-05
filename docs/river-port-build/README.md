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
- `geometry-bounds.json`: four building footprint/occupied bounds, named entrance positions, roof direction, fitting inputs/residuals, and quay/bridge/dock envelopes.
- `geometry-audit.html`: side-by-side reference and actual render with identical projected model edges. Open locally in a browser; no external service is required. Its embedded-browser visual check was blocked by local-URL policy, so interactive presentation is not marked verified.

## Preserved direction

Build visual quality first. No polygon-reduction target has been imposed, and no automatic decimation was applied to the authored environment. Optimization requires measured evidence and a subsequent decision. Prominent raised gold nodes and gold connections remain part of the tabletop presentation. Inn and guild have complete rear/side walls and roof geometry for other camera angles; the merchant shop is an explicit open-front cutaway variant.

The scene includes individual overlapping roof tiles, fitted irregular paving stones, staggered masonry, timber frames, dormers, shelves, curved awning, lanterns, tables, dock planks/piles/rope, bridge, shoreline rocks/reeds, and a constructed clinker rowboat with ribs and benches. Nothing is animated. Three articulated figure studies now have 15-bone rigid-piece rigs; these replace the unrigged cylinders. They are **not production character sculpts**, do not have deformable skin/cloth, and are not final asset admissions. Two robed figures still fail to reproduce the reference's distinct mage and ranger identities.

## Reference reconstruction correction

The user rejected the initial rectangular platforms, sideways bridge, independent generic architecture, and coarse/cartoon-like construction. Increasing piece count did not address those defects. The approved image remains authoritative, including its finer forms, shadow complexity, and conspicuous gold points.

The builder now converts manually traced source pixels from the 1536 by 1024 reference into 3D points by intersecting camera rays with stated ground heights. `reference_quay()` owns the continuous perimeter. Dock geometry uses four independently traced corners: back-left (675,717), back-right (853,773), front-left (419,898), front-right (537,973). The bridge uses its own rear and front landing centers (855,551) and (723,744), at heights 0.8 and 0.3. The dock is therefore not an extension of the bridge axis. Its planks run lengthwise, with real thickness, joints, piles, and rope.

These measurements are manual approximations of visible boundaries, not automatic image segmentation or a claim of exact matching. Rear contours occluded by roofs/cliffs are inferred at foundation level, not traced around roof silhouettes. No reference pixels are pasted into the render. Elevated markers, figure bases, table positions, vegetation anchors, and the rowboat position also use source-pixel anchors where visible. The layout is only a reconstruction study, never authoritative game topology.

The earlier whole-house rotation of the inn wing is superseded: it put the entrance on the wrong side. Roof direction now has an independent coordinate frame; the wing's front door remains on its declared plaza-facing wall. Main and wing placement now derive from measured front-wall endpoints and an inferred depth anchor, constrained to orthogonal footprints. Shop and guild have recorded bounds but are NOT yet fitted by this procedure. Thin eight-pane joinery, reduced bevels, finer roof layers, and full-resolution input material maps address only part of the chunky form language. Roof planes rotate about their actual centers, and tile offsets are measured along the roof normal.

## Bounded reconstruction contract — 2026-09-06

Each house records width, depth, wall height, roof rise, roof direction, cutaway status and door dimensions. Local +Z is the front/entrance side. `EntranceSocket` is on that face at the floor-top elevation; roof rotation must never rotate that socket. The inn stairs derive from the socket and end at plaza height 0.88. Their foundations span the transformed footprints down to bed datum -0.45. This is a constructed support volume, not an independently placed decorative slab; its stone detail remains unfinished.

`fit_building` intersects front-corner reference pixels with the declared base plane, derives the wall's X direction, constructs its perpendicular depth direction, and projects an inferred rear anchor onto that direction. It does not shear the building to force three inconsistent points to agree. The audit records the resulting rear-anchor residual. Near-zero error at the first two anchors is expected by construction and MUST NOT be reported as independent visual accuracy.

Current inn anchors, in approved 1536x1024 source pixels:

- Main: front-left (803,286), front-right (928,340), inferred rear-right (1070,214).
- Entrance wing: front-left (995,309), front-right (1153,365), inferred rear-right (1235,280).
- Both use base height 1.15 and vertical scale 0.85. These heights and hidden depths remain reconstruction assumptions, not measurements recovered uniquely from the illustration.

The first constrained fit leaves approximately 41 and 23 source pixels of rear-anchor disagreement respectively. It fixes the entrance-side error but does not establish exact roof proportions or building placement. The HTML audit draws model footprint, wall-top, ridge and door edges over both images so those errors can be inspected directly. The cutaway shop's special canopy is not represented by the generic ridge outline. Occupied bounds include descendant mesh extents; they are not collision shapes. Quay bounds describe the base at 0.8 (paving reaches 0.88); bridge bounds describe landing width rather than its curved profile; dock bounds exclude piles, ropes and crane.

Independent native reload checks four building footprints against the exported report, the three surface-record count, and both fitted buildings' entrance/stair alignment, independent roof direction, and foundation bed contact. These checks do not establish manifold geometry, obstacle clearance, full-width bridge/dock contact, or complete reference similarity. No asset is runtime-admitted by this pass.

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

### Continuous bridge construction pass

The bridge now uses fitted extruded sections rather than horizontal boxes sampled at each segment midpoint. Its deck follows the same measured landing centers; its underside has a continuous closed arch barrel, with individual facing stones, filled masonry above the arch, and fitted parapets/coping. The geometry builder rejects inverted section heights and checks the two declared deck endpoint heights. These are construction checks, not reference-similarity or walkability certification. The dock retains its separately traced footprint and sits 0.15 units below the front deck endpoint; the exact full-width landing fit still needs an independent check. This pass does not claim to reproduce the reference's stepped parapet profile or irregular stone carving.

The shop-side quay trace is also narrowed to turn along the foundation instead of preserving an unsupported broad paved apron. Main and building-hidden captures expose this correction. The narrower masonry makes the unfinished shoreline treatment more apparent: the sand shelves remain overly flat and detached in places, and need a continuous rock/soil/shallow-water transition. Do not treat those shelves as approved terrain assets. Procedural details share one deterministic random stream, so changing paving geometry also changes downstream material choices and scattered props; matching the seed alone does not isolate a before/after visual comparison.

Front, alternate, saved-scene roundtrip, and rear captures were inspected. Initial reversed surface winding and unwanted smooth-normal artifacts were corrected before this checkpoint. Complete roof/back geometry survives the alternate views.

The result remains below the approved illustration. Exact architectural profiles, roof junctions, carved ornaments, richly stocked shop contents, individual character sculpting, and fine weathering are not reproduced. Vegetation and beach transitions remain too procedural, and the inferred rear ground should not be mistaken for evidence of the reference's unseen layout. Those are unresolved quality gaps, **not** a proposed simpler art direction. Preserve the approved richness while improving these aspects. Rear walls are structurally present but need designed facade detail before unrestricted camera presentation is considered finished. No numerical visual-similarity score or claim of exact recreation is made.
