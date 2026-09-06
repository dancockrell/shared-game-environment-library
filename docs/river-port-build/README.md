# River-port construction study — 2026-09-05

## Consumer-owned assembly recipes

The existing `--assemble-catalog` path accepts an optional absolute recipe JSON and output directory after the flag. A recipe supplies `sceneName`, `scope`, `buildings` and `props`. Each placement is `[catalog-id-suffix, x, z]` in metres. Shared quay staging and dock connections remain common; this is not a general terrain editor. Omitting recipe arguments preserves the original layout.

`--inspect-catalog <absolute-assembly-directory>` verifies a consumer scene against its saved catalog: source hash, bounds, sockets, GLB hashes and native reload. New recipes being authored in the kit do not invalidate a saved consumer catalog. Normal catalog-only inspection still checks the current recipe count. Consumer lore and topology stay outside this builder.

## Current direction — coherent authored scene (2026-09-06)

The user has ended the exact-reference reconstruction objective. The illustration now supplies art direction, not a camera-calibration or pixel-matching acceptance target. Historical fitting notes and the overlay remain diagnostic history; do not spend further production passes minimizing reference pixel residuals. Preserve rich miniature detail and judge the actual scene for consistent scale, supported architecture, accessible entrances, attached shorelines, clear vegetation, and readable gold connections.

This pass replaces detached sand ellipses with sloped banks derived from the quay boundary, leaving the central bridge channel open. Tree placement searches for ground-supported positions with conservative canopy clearance from building wall bounds. This is not full scene collision validation: roof overhangs, props and tree-to-tree clearance still require visual review.

These are actual Godot captures of constructed 3D geometry, not generated concept images or image backgrounds. The approved painted-miniature reference remains the quality target in `../visual-reference/`; this study does **not** replace it or satisfy final visual admission.

## Deliverables

### Reusable supply batch — 6 September 2026

The existing kit now builds **76 independent model candidates**, not one
monolithic scene. This is a first Crossing supply batch, not the complete
Crossing and not a set of canonically placed landmarks. The user accepted
the first batch's building treatment as "good enough buildings" on 6 September;
continue at this standard. That visual approval is separate from runtime admission.
No paid generation, subscription, API or Magnific credits were consumed.

- [Front review sheet](catalog/contact-sheet.png) and [rear review sheet](catalog/contact-sheet-rear.png): actual Godot geometry captures; thumbnails fit each asset individually and therefore are not a common scale chart.
- [Editable native catalog](catalog/catalog-native.scn): shared textured material resources, complete model hierarchies and named sockets. Each top-level child is a separate model at its own bottom-centered origin, hidden by default to prevent overlap. Instantiate the desired child and enable its visibility. Model paths are recorded in the report.
- [Build report and asset index](catalog/build-report.json): stable IDs, per-model GLB filename/hash, native child path, measured bounds, mesh/triangle counts, sockets, materials and review status. This is a candidate build report, **not** an approved runtime manifest.
- One standalone GLB and two PNGs per recipe under `catalog/`. GLBs preserve geometry and material colors, **not** the native triplanar texture treatment. Do not present them as visually equivalent final exports.

The architecture batch includes bakery, smithy, warehouse, townhouse,
meeting hall, watchtower, gatehouse and stable. The remaining sixteen models
cover produce/fish stalls, coopered barrel, braced cargo, open handcart,
roofed well, fountain, bench, street lantern, signpost, hedge, vine bower,
quay wall, pier, landing stairs and mooring post. Produce/fish stalls share
their frame but have different stock; these are not two architecture families.
All are neutral reuse ingredients. Consumer room descriptions must authorize
their selection before they are called part of an actual Crossing location.

The second batch adds sixteen models: tollhouse with side service porch,
wide-door boathouse with slip apron, ventilated granary, bell hall with open
belfry, courtyard wall, timber gate, roofed notice board, trestle table, stool,
stacked firewood, water trough, cargo crane, rope coil, timber footbridge,
reed bank and rock shelf. See the [expansion front sheet](catalog/expansion-sheet.png)
and [expansion rear sheet](catalog/expansion-sheet-rear.png). These use the same
recipe registry, exporter, surfaces and metadata, not another asset pipeline.

The older polish notes below describe future improvement opportunities, not
a blocker to further production at the now-accepted building level. New models
have been inspected against that working standard; named-place selection,
collision and runtime performance remain consumer review tasks.

The third batch adds twenty assembly ingredients: cobbled plaza and street,
dirt path, grass verge, straight curb, curb corner, quay corner, dock ramp,
workbench, anvil, tool rack, forge hearth, bucket, sack stack, fishing rack,
mooring cleat, driftwood, basalt outcrop, beach slope and stone culvert.
See the [assembly-pieces sheet](catalog/assembly-pieces.png) and
[reverse views](catalog/assembly-pieces-rear.png). Tile connectors describe
physical presentation alignment, not legal exits. Terrain pieces use a 4 m
assembly module here; this is not a new universal room size.

### Saved-model assembly proof

The [workshop/quay composition](catalog/assembly-workshop-quay.png) places
77 instances loaded from the saved catalog, including three complete buildings,
modular paving, workshop/market props and a connected pier-ramp-landing chain.
This is **not a map of The Crossing** and creates no authoritative MUD routes.
The scene is an assembly/scale test, not a finished district or performance gate.

The same builder now supports:

```text
godot --path tools --rendering-method forward_plus --script res://build-river-port.gd -- <absolute-repository-path> --assemble-catalog
```

It resolves stable asset IDs through the existing report, duplicates saved
native model subtrees without regenerating their geometry, and aligns named
connection points. Orientation is explicit in the assembly; socket alignment
only translates the already oriented instance. This does not infer rotations,
compatibility, collision freedom or game connectivity. Unknown IDs/sockets fail.

The [editable assembly](catalog/assembly-workshop-quay.scn) includes its camera,
lighting, foundation and water. The [assembly check](catalog/assembly-check.json)
records placements, source-catalog hash, connection errors and mesh count.
`--inspect-catalog` independently reloads it, verifies the dependency hash,
instance/mesh counts and camera/environment, and rejects a stale assembly after
the source catalog changes. Rebuild the assembly after rebuilding the catalog.

Third-batch checks: 60 GLB mesh/bounds roundtrips and native socket/hash checks
passed; all prior 40 GLBs remained unchanged. Gate, footbridge and culvert
clearance checks passed. Assembly connection residuals were below 0.1 mm and
the three building envelopes did not intersect. All eight source resource packs
passed. Front/rear model sheets and the assembled capture were visually reviewed.
The sack, driftwood, path treatment and water glare were revised during review.
No credits were used. General prop collision, dense-city performance and actual
Crossing room integration remain untested; the simple terrain is modular base
geometry rather than a finished natural shoreline.

The fourth batch adds fishmonger, chandlery, stone cottage and guard barracks;
oak, willow and cypress trees; flower planter; hitching post, capstan, dock
ladder, hand pump, rain barrel, grindstone, log bench and canvas shelter.
See [landscape and trade additions](catalog/landscape-and-trade.png) and their
[reverse views](catalog/landscape-and-trade-rear.png). The fishmonger and cottage
reuse existing stock/planter recipes, not copied implementations. Trees extend
the existing scene tree builder with tapered branches and a drooping willow
form. These are reusable species-style candidates, not verified named flora.

The saved workshop/quay assembly now uses 94 catalog instances. Its planted
back strip, four trees, planters, grindstone and capstan demonstrate the new
pieces at shared scale. Tree visual envelopes are checked against building
envelopes; this is conservative canopy clearance, not full prop collision or
navigation validation. The pump handle received a connected neck/pivot after
visual review. Review-light shadow bias was reduced to make ground contact
easier to inspect; that changes preview images, not the first 60 model exports.

Foliage retains full authored geometry and is relatively expensive. The report
records triangle/mesh counts; do not infer dense-world performance approval
from successful generation or from one scene capture. No animation, creature
rigs, runtime admission or canonical room placement is delivered by this batch.

Rebuild and independently inspect using the existing builder:

```text
godot --path tools --rendering-method forward_plus --script res://build-river-port.gd -- <absolute-repository-path> --catalog
godot --headless --path tools --script res://build-river-port.gd -- <absolute-repository-path> --inspect-catalog
```

Each recipe has its own deterministic seed derived from its stable name.
The exporter normalizes measured visual bounds to bottom-center and wraps
the scene's older +Z-facing construction in a -Z-facing catalog root.
Door, vendor, seat, connector and label sockets follow that same transform.
Visual bounds include decorative overhangs; they are not colliders or legal
route envelopes. No MUD exits, interactions, animation or NPCs are invented.

Construction review corrected separated circular masonry courses, the closed
cart body, undersized hedge height, and the stable rail blocking its door.
The gatehouse has a conservative mesh-bound check for a 2 m wide, 2.35 m high
central passage. This does not establish complete scene navigation safety.

Remaining polish: architecture still needs richer function-specific silhouettes
and detailing; bakery/smithy/warehouse/stable are visibly related shells, not
finished bespoke landmarks. Fish/produce need more recognizable sculpted
stock. Vegetation is dense procedural geometry, not production-optimized:
refer to measured counts, especially hedge and bower, before city instancing.
No decimation was applied and no dense-city performance acceptance is claimed.
The simple bench and signage need a decorative finish pass. Native texture
interchange, collision authoring, consumer admission and actual room placement
remain outstanding. This checkpoint broadens the library; it does not lower
the approved finish standard or retire the remaining city work.

Verification at this checkpoint: all 24 standalone GLBs passed export/import
mesh-count and bounds checks; independent native reload checked every model's
bounds and socket positions against the saved report, and verified GLB hashes.
All 24 GLB hashes were identical on an unchanged-recipe rebuild. Front and rear
contact sheets were visually inspected, with the unresolved finish issues above
retained as revisions, not approved quality. All eight existing resource packs
passed their validator. No runtime client tests, Godot 4.3 compatibility tests,
full manifold audit or city performance benchmark were run for this batch.

Second-batch verification: all 40 models passed export/reimport mesh-count
and bounds checks, independent native bounds/socket/hash checks, and the
existing eight resource-pack validations. The footbridge also has a conservative
2 m wide railing-clearance check above its deck. The original 24 GLB hashes
remain unchanged. New front/rear sheets were visually inspected. All generation
was local and consumed zero service credits; runtime placement remains pending.

### Connected-scene study

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

The half-open merchant demo has been replaced in place by an enclosed exterior. Its exposed counter, shelving, partial canopy and low front wall are no longer generated. Existing kit components supply the full building; a blue-and-gold vial sign and herb boxes communicate the shop's role. No new external assets were introduced. This does not implement a playable interior or roof-hiding interaction. Native reload checks require the enclosed shop, roof frame, aligned entrance approach and absence of the former cutaway node.

Build visual quality first. No polygon-reduction target has been imposed, and no automatic decimation was applied to the authored environment. Optimization requires measured evidence and a subsequent decision. Prominent raised gold nodes and gold connections remain part of the tabletop presentation. Inn and guild have complete rear/side walls and roof geometry for other camera angles; the merchant shop is an enclosed apothecary with a complete slate roof, centered entry, windows, shutters, herb boxes and a vial trade sign. The cutaway demo is superseded.

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

The first constrained fit leaves approximately 41 and 23 source pixels of rear-anchor disagreement respectively. It fixes the entrance-side error but does not establish exact roof proportions or building placement. The HTML audit draws model footprint, wall-top, ridge and door edges over both images so those errors can be inspected directly. The enclosed shop now uses the complete roof frame and ridge reporting. Occupied bounds include descendant mesh extents; they are not collision shapes. Quay bounds describe the base at 0.8 (paving reaches 0.88); bridge bounds describe landing width rather than its curved profile; dock bounds exclude piles, ropes and crane.

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
