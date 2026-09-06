# Scene Forge: shared procedural scene builder

## Current authority and scope

User direction, 6 September 2026: a Rust procedural generator, usable as Godot
and Unity plugins, for item parts, items, rooms, buildings, landscape and towns.
No neural network dependency, permanent server, paid services or unlicensed
code. The corrected hardware target is **8 GB VRAM**, not installed disk size.
The existing shared repository and catalog remain canonical. Character tooling
has a separate owner; this work does not replace it or its asset/provenance data.

`procedural/` is the common engine-neutral compiler and adapter package. It
extends this library's procedural production workflow, not another world server.
Original software in that directory is MIT licensed. Existing CC0-only art
admission is unchanged; permissively licensed software dependencies are not art.

## Implemented first slice

- Rust library, command-line executable and C ABI dynamic library.
- Reusable named mesh definitions; nested groups and repeated assemblies.
- Boxes, solid gable roofs, lathed profiles and convex polygon extrusions.
- Measured rectangular room shells with real door/window apertures on explicitly
  selected walls; identical room definitions share one mesh across instances.
- CCW, right-handed, Y-up, metre-based portable mesh/instance output.
- Deterministic output, shared meshes, explicit geometry/instance budgets,
  pre-expansion count checks, finite-coordinate and geometry validation.
- Godot editor add-on calls the local compiler on a worker thread and imports
  shared MultiMeshes, with an undoable scene insertion. No network listener.
- Unity editor package calls the same core through its C ABI and creates
  shared-mesh objects. Unity execution remains unverified until tested in Unity.
- A four-workshop construction fixture with complete walls, doorway openings,
  roofs, shelves and repeated lathed vessels. This is a geometry/adapter test,
  not art matching the approved Crossing reference.

Not implemented yet: a general room/city constraint solver, arbitrary concave
booleans, spline sweeps, terrain erosion, road networks, procedural PBR materials,
automatic LOD/streaming, catalog asset imports, MUD graph adapter, SQLite cache,
editor node graph, or production packaging. These are required later capabilities,
not hidden behind placeholder APIs in the current build.

## Architecture to extend, not fork

1. **Evidence and recipes:** translate researched construction patterns and
   room descriptions into typed, inspectable constraints. Every inferred feature
   carries its origin and uncertainty. No scraping result becomes executable code.
2. **Construction operators:** profiles, sweeps, extrusion, surface subdivision,
   controlled deformation, cuts and junctions. Compose details and structural
   members with reusable definitions; bound expansion rather than promising
   literally unlimited complexity on finite hardware.
3. **Assemblies:** sockets, support surfaces, joints, clearance volumes and
   material slots. Prefer catalog instances to rebuilding unchanged geometry.
4. **Spatial constraints:** rooms/buildings and landscape parcels use explicit
   bounds, openings, circulation, drainage and adjacency. MUD topology is an input
   constraint; ordinary worlds may use generated roads and parcels. Neither mode
   silently changes the other mode's topology.
5. **Compilation:** stable recipe/operator/source hashes, dependency graph,
   deterministic seeds, incremental build, cancellation, per-job resource limits.
6. **Local catalog/cache:** SQLite indexes the existing catalog, assets, hashes,
   dependencies, compile receipts, quality reviews and local artifact paths.
   The existing catalog remains provenance authority; SQLite is rebuildable.
7. **Engine adapters:** convert coordinates, material slots and mesh/instance
   buffers only. They do not implement a second geometry generator.

## 8 GB VRAM contract

Generation is CPU-side. The present compiler estimates vertex, index and
instance buffer payload, defaulting to a 512 MiB geometry limit; this is NOT
measured total VRAM. A hard safety ceiling prevents asking this prototype for
more than 6 GiB of geometry, but users should not allocate that whole amount.

The eventual residency controller must measure engine/device memory, account for
textures, render targets, shadows, duplicates and driver overhead, and maintain
headroom. Target a configurable 5–6 GB working set on an 8 GB card, with hysteresis
for eviction and quality reduction. Never infer available VRAM from file sizes.
Use mesh instancing, texture arrays/atlases where appropriate, hierarchical LOD,
chunked terrain and distance/visibility-based unloading. Disk/cache size and CPU
RAM have separate limits. No GPU performance or 8 GB compatibility claim is
established by the small fixture.

## Licensing and research

Current core geometry is original first-principles code. serde/serde_json and
their locked transitive dependencies require a distribution notice audit.
Cargo.lock pins exact downloads. Do not copy code from a paper or repository
merely because it is publicly readable. Record upstream revision, license,
attribution and modifications for each adopted implementation.

Current high-level godot-rust bindings use MPL; they have not been included.
The Godot editor add-on uses the documented GDScript plugin interface instead.
Unity uses its documented native-plugin C ABI. Future in-process Godot bindings
must pass the same permissive-license review, not bypass it.

References:
- https://docs.godotengine.org/en/stable/tutorials/plugins/editor/making_plugins.html
- https://docs.unity3d.com/6000.0/Documentation/Manual/plug-ins-native.html
- https://github.com/godot-rust/gdext
- https://github.com/rusqlite/rusqlite

## Build and inspect

Run `cargo test --manifest-path procedural/Cargo.toml`, then
`cargo build --release --manifest-path procedural/Cargo.toml`.
The Windows outputs are `scene-forge-cli.exe` and `scene_forge.dll` in
`procedural/target/release/`.

Compile `procedural/examples/workshop.json` into a **new** output filename:
`scene-forge-cli.exe <recipe.json> <new-scene.json>`. Existing files are protected
against overwrite. The CLI creates no server and requires no account.

Godot: copy `procedural/godot/addons/scene_forge` into the target project's
`addons/`, enable Scene Forge, choose the compiler path, open a scene, and choose
the recipe with the dock button. The bundled Godot project is an adapter test.

Unity: add the local `procedural/unity` package, place the release library in
the project's `Assets/Plugins/x86_64/` with the appropriate editor platform
settings, and open **Tools > Scene Forge**. Only the Windows native library is
built on this machine so far; no cross-platform or Unity runtime pass is claimed.
The discovered Unity 6000.0.5f1 folder contains installation data but no Unity.exe;
the editor smoke test therefore could not launch. No installation repair or
license activation was attempted.

First local evidence: seven Rust unit tests passed; the release compiler emitted
the four-workshop fixture (52 instances sharing eight meshes); Godot loaded it,
packed/reinstantiated it and rendered it through the same adapter used by the
editor plugin. The Godot plugin script also parsed during that test. This does
not prove the interactive dock workflow, Unity import, or 8 GB GPU capacity.

## Next acceptance targets

- Property tests for winding, manifoldness, profile seam normals and UVs;
  concave/self-intersecting input rejection; operator-specific allocation bounds.
- Run the same compiled scene through both engine adapters and compare world
  bounds, normals, instance transforms, sockets and captured views.
- Add constrained room construction with exact MUD openings and native-kit
  references, then buildings/streets/terrain; batch Crossing without hand recipes.
- Measure resident memory and frame time on an 8 GB GPU at dense-city scale.
- Package reproducible releases with complete permissive-dependency notices.

## Rectangular room operator

`procedural/examples/rooms.json` is the executable schema example. A `room`
shape takes clear interior width/depth/height in metres, wall and floor thickness,
and up to 64 rectangular openings. Finished floor is Y=0, centred on X/Z; north
is -Z, east +X, south +Z, west -X. Walls extend outward from the interior bounds;
the floor extends below Y=0. North/south opening offsets increase along X,
east/west offsets along Z, regardless of the direction an observer faces.

Each opening has centre offset, width, height and optional sill height (zero
means a floor-level door). Openings are geometric constraints, not evidence of
MUD exits. A caller must choose their wall from actual layout/graph data. This
operator neither creates graph links nor infers them from nearby rooms.

The compiler subdivides wall spans into jamb, sill and lintel boxes and lowers
them through the existing box mesher. It does not paint a black rectangle over
a solid wall. Interior clearance remains empty. East/west walls own corner
columns to avoid overlapping solid volumes. The result is a multi-solid mesh,
not a welded boolean union; coincident internal faces remain at segment joins.
Openings with overlapping horizontal spans are rejected, including vertically
stacked openings: that more general cut arrangement is not supported yet.
Out-of-bounds cuts and invalid dimensions fail rather than being silently moved.

Room geometry respects the existing vertex allocation budget. Repeated rooms
reuse their definition mesh. The 17,000-instance test demonstrates reuse and
budget enforcement only, not 17,000 distinct room designs, city rendering speed,
or measured VRAM. Roofs, material differentiation, trim, collision,
MUD adapter integration and final art admission remain subsequent work.

Validation for this operator: eleven Rust tests passed, including aperture-side
occupancy, window sill/lintel solids, four-sided full-height cuts, invalid cuts,
17,000 shared instances, deterministic output and vertex-budget rejection.
Clippy with warnings denied and the release build passed. The four-room fixture
imported, packed/reinstantiated and rendered in Godot 4.7.2 through the existing
adapter; its openings were visually inspected. These plain shells are construction
fixtures, not admitted Crossing art. Unity was not executed for this change.

### Aperture metadata and placement contract

Each compiled mesh now carries `apertures`: input opening index, definition-space
wall, bottom-centre position on the wall centre plane, outward normal, width and
height. Non-room meshes carry an empty array. These descriptors are emitted only
after room validation. They are geometric affordances, not traversal permission,
MUD commands or graph destinations. Opening indices refer to the supplied recipe
order; they are not persistent IDs across edits that reorder openings.

The Godot adapter stores these descriptors once on each shared MultiMesh display.
`aperture_world(display, instance_index, opening_index)` resolves a descriptor
through both the instance transform and its scene-parent transform on demand.
The returned position and normal are world-space; `definition_wall` deliberately
retains the original label. Width and height include transform scaling; singular
transforms and unknown indices return no result. No extra node is allocated per
opening. Metadata survives PackedScene packing/reinstantiation. Rust coordinate
checks and Godot translation, rotation, scale, missing-index and reload checks
passed. Unity currently ignores these additive descriptors; equivalent Unity
metadata consumption and engine execution are still outstanding.

Saved MultiMeshes explicitly persist the union of transformed mesh bounds in
`custom_aabb`. Crossing's off-screen capture exposed empty automatically derived
rendering bounds after native package reload even though mesh vertices and
instance transforms survived. Checking source mesh bounds alone missed this.

Further diagnosis found the actual missing data: Godot's dummy headless backend
saved instance counts but no instance buffer. Geometry-only tests were therefore
insufficient. Native package export now requires a graphics-backed process,
refuses missing buffers, and reloads the saved package to compare buffers and
bounds exactly. Run export off-screen with no focus and a low frame limit. Most
other validation remains headless. A valid AABB alone is not rendering proof.

## Research-to-implementation ledger (reviewed 6 September 2026)

This is a targeted current literature review, not an exhaustive claim of newest
or best results. Paper claims below are not our measured performance. No upstream
implementation has been copied or added by this review; any code adoption needs
its own revision, dependency and MIT-or-more-permissive license audit.

| Work | Relevant method | Decision for this builder |
| --- | --- | --- |
| [Infinigen Indoors, CVPR 2024](https://arxiv.org/abs/2406.11824) | Procedural assets plus a constraint language and arrangement solver | Adopt the separation of construction operators, relationships and placement objectives. Current rectangular shells and greedy placement are only a foundation; no equivalent general solver is implemented. |
| [Design for Descent, SIGGRAPH Asia 2025](https://www.computationaldesign.group/assets/papers/SIGA-2025-D4Descent.pdf) | Structural grammar rewrites interleaved with continuous parameter optimization | Candidate: make bays, roof spans and facade subdivisions explicit, then optimize dimensions without discarding structure. Not implemented. The paper is CC BY-NC; reading its ideas is not permission to copy its code or assets into our permissive distribution. |
| [Procedural Scene Programs, October 2025](https://arxiv.org/abs/2510.16147) | Dependent object-placement programs with search-based error repair | Candidate: place structure, then supports, then supported props; repair overlap and circulation failures while preserving description constraints. The paper uses an LLM for initial programs; its repair method does not require an LLM call at every correction. Our runtime must not depend on paid inference. |
| [Sceniris, December 2025](https://arxiv.org/abs/2512.16896) | Batch sampling, cached representations and accelerated collision checks | High priority: batch candidate evaluation and cache invariant geometry rather than re-running individual object workflows. Its reported 234x improvement uses its own baseline and GPU collision system; it is not our speedup and does not establish an 8 GB fit. |
| [Procedural Content Metageneration, August 18 2026](https://arxiv.org/abs/2608.17947) | Search over generators; reusable abstractions extracted from strong programs | Candidate: promote repeatedly successful construction rules into tested shared operators. This is evidence from game-level generation, not proof of detailed 3D fantasy architecture; do not import its inference costs or claim its method is already running here. |
| [4DSynth, August 27 2026 preprint](https://arxiv.org/abs/2608.26947) | Multiple inputs converge on one editable geometry-grounded scene representation | Architectural reference: source prose, graph bindings and authored constraints should converge on the same recipe representation. Its actor animation and simulation work is outside our current static scenery milestone. |
| [Infinigen-Sim, May 2025](https://arxiv.org/abs/2505.10755) | Procedural articulated assets with joint annotations | Later scenery work: hinges, shutters, gates, cranes and ferries need explicit pivots and parts even before animation. Not a replacement for Pirate Island's character workflow. |

### What is actually implemented

Deterministic CPU-side parametric mesh construction; reusable named geometry;
groups/repetition; exact rectangular aperture subdivision; strict geometry and
allocation limits; portable mesh/instance representation; native engine adapters;
Crossing evidence rules; greedy bounded furnishing placement with reserved
circulation; content-hashed rebuilds. This is not full shape-grammar search,
wave-function collapse, learned generation, a city constraint solver, PBR synthesis,
or automatic art-quality certification.

### Iteration contract

The next solver must maintain separate hard violations and soft quality scores.
Never let a weighted visual improvement buy permission to break a MUD edge.
Use deterministic seeds and a fixed candidate budget, not time-dependent output.

```text
for each changed cohort, in stable identifier order:
    evidence = bind_room_specific_prose_and_authoritative_exits()
    required = lock_graph_edges_and_authored_overrides(evidence)
    proposal = instantiate_shared_construction_rules(required)
    candidates = batch_local_rewrites(proposal, seed, fixed_budget)
    reject candidates with missing exits, overlap, blocked approaches,
           unsupported elevation, out_of_bounds geometry, or excess resources
    rank remaining candidates by material evidence, proportion,
         support plausibility, visibility, and deviation from authored intent
    if no valid candidate: retain an explicit diagnostic, never mark complete
    compile best valid candidate through the one Rust geometry implementation
    export; reload; verify actual buffers, bounds, pivots and aperture bindings
    render changed representatives and every newly flagged exception
    compare against previous receipts; record regressions and resource costs
    admit only after visual review; otherwise revise the shared rule and repeat
```

This is the implementation target for search/repair, not a claim that the loop
above is already automated. The current real loop is build, regression tests,
native reload, background capture, inspection and corrective edits. The missing
instance-buffer defect demonstrates why successful code execution alone is not
a valid scene-quality metric.

Crossing integration must bind actual exits to these descriptors explicitly.
The uncommitted earlier JavaScript shell experiment is not the production
authority: its neighbor-position fallback is insufficient evidence for a door's
wall. Do not silently treat proximity as an exit anchor. That experiment still
requires replacement when the shared compiler is connected to the MUD adapter.
