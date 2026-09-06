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
Current generator software is GPL-3.0-or-later following the user's explicit
approval of GPL and Blender. Prior MIT grants remain valid and their notice
is retained in procedural/LICENSE.MIT. Third-party notices remain applicable.
The Unity adapter remains MIT as a separately licensed file-import boundary;
shipping a GPL-linked native Unity plugin is not an admitted distribution.
Existing CC0-only catalog art admission is unchanged; software licenses are
not automatically licenses on generated artistic output.

## Visual target: high-end stylized, not blocky

User clarification, 6 September 2026: aim for contemporary high-end studio
cartoon/stylized 3D, not photorealism, voxel forms, or intentionally crude
low-poly art. This refines the presentation target without authorizing room
expansion. Existing boxes and bare shells are construction/test geometry, not
finished assets or proof that the target has been reached.

The tool must support an explicit separation between structural geometry and
finished appearance. Preserve measured footprints, sockets and apertures while
adding expressive silhouettes, curved profiles, shaped rooflines, layered trim,
controlled bevels and authored asymmetry. Detail has three scales: readable
overall massing, construction-level parts, and restrained surface detail. Random
noise or polygon count alone is not a quality measure. Do not randomly distort
contact surfaces, opening clearance or architectural joins.

Materials should give wood, stone, metal, plaster, cloth and water distinct
responses without requiring photographic textures. Lighting must retain depth,
contact shadows and readable silhouettes. Validate at gameplay distance and
closer camera views; an orthographic thumbnail alone cannot certify quality.
The approved reference remains a quality anchor, not an exact reconstruction
claim. This target requires additional geometry/material operators and visual
iteration; those capabilities are not implemented merely by documenting them.

The 8 GB VRAM target is a residency constraint, not a reason to flatten every
shape. Prefer shared meshes/materials, local detail budgets, culling and future
LOD/streaming. Measure actual engine residency and frame time before claiming
the budget is met. No paid generation or neural inference dependency is added.

## Implemented tool checkpoint

### Solid-input diagnostics before joining parts

`procedural/audit-solids.mjs` reads a compiled scene without modifying it. It
constructs a diagnostic graph from exactly equal numeric positions (signed zero
is unified), independently of UV and shading splits. There is no tolerance weld.
It reports collapsed triangles, boundary edges, more-than-two-face edge incidence,
same-direction paired edges, connected components, and vertex links that are not
one closed cycle. The last check detects two shells touching only at a point,
which an edge-pairing test alone misses. A signed-volume estimate is reported
only when these closed/oriented graph checks pass; it is not a volume guarantee.

This graph is **not recovered authoritative topology** and is not a Boolean
input repair. Coincident surfaces can intentionally have separate connectivity.
Self-intersections, overlaps between parts, shell nesting and correct outward
orientation of every component are not certified. `solid_validity` is always
`not_certified`, and `self_intersections` is always `not_checked`. These diagnostics
must not be interpreted as permission to Boolean arbitrary rendered scenes.

The CPU runner now uses Node for five audit regressions and one read-only audit
per fixture, under the same per-process timeout/RAM guards. Optional `-Node`
selects its executable; the Rust generator itself remains Node-independent.
Audit findings are retained in each `*-connectivity.log`; a successful runner
means the diagnostics executed, not that every mesh is a valid solid.

Initial audit receipt (room-shell defects subsequently corrected below):
`procedural/generated/reviews/20260906-121846-a0ce66980da34535bd4e39e2a4588a47/report.json`:
44 Rust tests, five audit tests, format, strict clippy, release, nine deterministic
fixtures and nine connectivity audits passed (32 stages). Of 40 mesh definitions
audited, 38 have closed oriented exact-position graphs. All seven teapot parts
pass those checks independently, but this does not join their overlaps or open
the body beneath the spout. The `rooms` shell reports 21 excess-incidence edges,
19 failed closed vertex fans and six components; the transformed fixture's shell
reports 20, 16 and three respectively. Those composite rendering shells must not
be admitted as single clean solids. No geometry was repaired or changed.

#### Solid-construction research and license screen, 6 September 2026

- Read the author's [Manifold technical note](https://github.com/elalish/manifold/wiki/Manifold-Library),
  including manifoldness, symbolic perturbation, overlaps, triangulation,
  degeneracy removal and vertex properties. It distinguishes exact connectivity
  from rounded positions and explains why property-split render vertices cannot
  generally reconstruct original topology. Decision: retain rendering seams;
  use the new audit diagnostically, and require explicit construction topology
  plus intersection/property handling before accepting a solid join. This note
  is an author technical write-up, not a peer-reviewed paper. No code was copied.
- [Manifold-rust 0.13.1](https://docs.rs/crate/manifold-rust/latest) is a CPU Rust
  candidate with Apache-2.0 licensing and cancellation support documented by its
  author. It has not been benchmarked or admitted; the former MIT-only policy
  is superseded by GPL-compatible licensing. Advertised correctness and
  performance are not our measurements.
- [Boolmesh](https://github.com/komietty/boolmesh) currently declares MPL-2.0 and
  requires manifold, nonoverlapping input. No dependency was added.
- [Trueform's July 2026 paper abstract](https://arxiv.org/abs/2607.15905) discusses
  exact topology surviving floating-point output; full-paper fetching failed,
  so it is screened, not claimed fully read. Its current
  [published package](https://pypi.org/project/trueform/) declares PolyForm
  Noncommercial licensing. Do not adopt its implementation for this project.
- Full-text fetches for *Interactive and Robust Mesh Booleans* also failed in
  this pass. No implementation decision is attributed to unread methods.

Next solid work must preserve the authored outer shell and bore separately:
joining two hollow-looking pieces is not equivalent to subtracting a connected
interior passage from a joined exterior. Boolean intersection triangulation,
cut-surface shading/UVs and final rounded-output validation remain unimplemented.

### Recoverable construction recipes in engine imports

Compiled scenes carry `recipe_json`: a single canonical serialized recipe,
including definitions, material/paint controls, assembly/repetition structure,
limits and unused authored definitions. It is source data, not mesh inference.
Serialization normalizes formatting and fills defaults; it does not preserve
the original file's byte layout. A bounded writer refuses a canonical snapshot
larger than 16 MiB. The snapshot is CPU/editor metadata and is not charged as
GPU geometry. It is stored once at the scene root, not duplicated per instance.

Godot stores `scene_forge_recipe_json` on that root. Its dock's **Export selected
source recipe** action walks from one selected part to the imported root and
saves the source through a file dialog. Unity adds one runtime-serializable
`SceneForgeSource` root component and exposes the equivalent export action in
the existing Scene Forge editor window. Runtime placement keeps the component
outside the editor-only assembly so scene serialization can retain it.

The export is the **original construction snapshot**: later hand-edited engine
transforms, materials or meshes are NOT reconciled into it. Recompile an edited
export through the existing import action; that imports a new scene rather than
silently replacing an edited one. The UI explicitly states this limitation.
Older scenes lacking a snapshot remain importable but cannot export a recovered
recipe. Source snapshots can contain author-entered names and unused designs;
review before sharing them. No network publishing is performed by these actions.

CPU tests restore and recompile all nine fixture recipes and compare complete
scene serialization. They also verify unused definitions survive, exact-limit
acceptance and over-limit refusal. Engine tests now assert Godot in-memory/disk
metadata retention and Unity component serialization/recompilation, but those
engine tests and export dialogs have **not been executed** under the current
CPU-only workflow. Unity scene/prefab disk persistence and manual-edit merging
remain unverified/unimplemented respectively. No engine or VRAM claim follows.

CPU receipt: `procedural/generated/reviews/20260906-120629-d28b31e71e9949039a42e9ca5e65732c/report.json`:
42 tests, format, strict clippy, release and nine deterministic fixtures passed.
Independent saved-output comparison verified all prior scene fields unchanged.
The current teapot's canonical source is 5,106 UTF-8 bytes. Source hashing now
covers the Unity runtime component as well as the editor adapter; hashing is
provenance, not an executed C# compilation check.

### Exact vertex reuse without shape simplification

The compiler now indexes each named mesh by the complete bitwise position,
normal and UV tuple. First occurrence determines stable output order; triangle
order stays unchanged. Different normals, UV seams and signed zeros remain
distinct. This is not decimation, remeshing, topology repair or cross-part welding.
Materials, paint pixels, bounds, apertures and assembly instances are unchanged.

Each mesh exports `source_vertex_count` separately from its stored vertex count.
The existing `max_vertices` construction cap continues to charge the original
count, including across definitions: compression must not authorize larger
temporary construction workloads. Residency estimates use the indexed buffers.
The indexing map and temporary arrays consume CPU memory not represented by that
residency estimate. Godot's inspector exposes `source_vertices` with a legacy
fallback; this adapter addition has not yet been engine-executed.

Measured painted-teapot comparison, before/after indexing:

| Quantity | Before | After |
| --- | ---: | ---: |
| Stored vertices | 337,104 | 59,061 |
| Triangles | 112,368 | 112,368 |
| Estimated geometry, instances and texture mip bytes | 13,534,292 | 4,636,916 |
| Serialized scene JSON bytes | 35,131,362 | 10,313,845 |

An independent comparison of nine saved fixtures verified 427,584 triangle
corners: identical position/normal/UV values, in the same order, with unchanged
instances and mesh metadata. The Rust regression additionally compares float
bits and tests indexing idempotence. These are exact payload savings, not
measured VRAM, rendering speed or artistic improvement. No new Godot process
was launched; the displayed teapot remains the earlier graphics-backed render.
Final CPU receipt: `procedural/generated/reviews/20260906-115257-1a4408baae2e49db94f5dbaf20449ad7/report.json`
(37 tests, format, strict clippy, release build and nine deterministic fixtures
passed, including the explicit cross-definition construction-budget regression).

### Procedural painted underlayer

Materials can include `"paint":{"color":[0.45,0.6,0.42],"strength":0.35,"seed":42}`.
The existing definition color is the base palette entry. An original CPU routine
lays 32 soft, elongated brush-shaped marks onto an RGBA8 tile (64x64 by default),
mixing toward the second color with bounded strength. A deterministic integer
generator controls mark positions and orientation. No inference, external asset,
paid service, noise library or shader fork is required. This is deliberately a
small underpainting layer, not an automatic finished-material or art-style system.

The same paint owner now accepts optional `size` (64, 128, 256 or 512) and
`strokes`: up to 64 ordered, editable cubic UV brush marks. Each mark contains
four `points`, four cubic `widths` controls, RGB `color`, `opacity`, and
`repeat_u` (1..16). Widths are full widths in whole-texture UV units, independent
of repeat count. Repetition compresses a mark's horizontal coordinates into
each repeated cell; vertical coordinates remain unchanged. Horizontal brush
coverage wraps at the texture seam, while vertical coverage is clipped.

```json
{"points":[[0.4,0.2],[0.3,0.22],[0.2,0.24],[0.15,0.26]],
 "widths":[0,0.012,0.009,0],"color":[0.8,0.75,0.5],
 "opacity":0.95,"repeat_u":8}
```

This is original bounded CPU vector-brush rasterization, not a neural texture
generator or an image-generation-service output. Marks use 128 line segments
with unioned coverage and approximate one-pixel edge antialiasing. Work is
capped at 16 million stroke pixel visits per texture; excess work fails with
a diagnostic. The fixed sampling is not a certified curve-error tolerance.
Paint resolution changes do not change the editable mark coordinates. Stroke
parameters survive Godot live inspection and native package reload with the
existing paint metadata. Unity uploads the baked texture but does not yet
expose this complete editing metadata.

The compiler emits pixels and retains the palette, strength and seed in material
metadata. Both engine adapters have texture-upload code; Godot's path is executed
and Unity's remains unverified. Godot generates mipmaps, keeps the texture shared
with its mesh definition and returns paint settings through live inspection. The
saved-package gate compares texture bytes including mipmaps and retained paint
metadata. Missing paint is represented as absent data, not an engine metadata error.

Each painted mesh is charged its full uncompressed RGBA8 mip chain, derived
from texture dimensions (21,844 bytes at 64x64; 1,398,100 at 512x512).
For compatibility the existing `estimated_geometry_bytes` field now includes
these generated textures as well as geometry and instances; it still excludes
driver alignment, materials, framebuffers, CPU JSON and other engine overhead.
Identical textures across different definitions are not yet deduplicated. Alpha
remains opaque. Painting uses the shape's current UVs: lathe wrapping works, but
triangle-local mappings on unfinished operators can repeat marks unnaturally.

The actual painted-surface fixture shows controlled variation. Higher strength
looks blotchy and must not be called finished painterly art. Further work needs
surface-aware stroke direction, deliberate edge treatment, better UVs, material
families and composition-level palette control. Tests cover deterministic pixels,
seed changes, valid opaque output, zero-strength behavior, input rejection and
shared texture residency accounting. Pixel-preserving Godot roundtrip is tested;
cross-engine color matching is not certified.

![Unpainted, subtle and stronger procedural underpainting in Godot](verification/scene-forge-painted-surfaces.png)

### Elliptical arch bands

`{"kind":"arch","width":4,"rise":2,"thickness":0.35,"depth":0.8,"segments":32}`
creates a closed structural band around a half-elliptical opening. Width is the
inner spring-line span; rise is the inner apex above the y=0 spring line. Depth
is centered on Z. Thickness adds to the ellipse's horizontal and vertical radii;
it is **not a constant normal-distance offset** for noncircular ellipses. The
outer envelope is width+2*thickness by rise+thickness by depth. Even subdivision
counts 4..512 preserve an explicit apex sample. Tessellation approximates the
inner curve with chords; dimensions do not certify arbitrary character clearance.

The operator uses smooth analytic normals on inner and outer curved faces and
sharp front, rear and foot caps. Vertex allocation is checked before construction:
`24*segments+12`. Tests cover bounds, unit normals, outward winding, closed seams,
unfilled central opening vertices, invalid dimensions/subdivisions and budget
rejection. Extremely small unrepresentable bands fail rather than disappear.
UVs now follow normalized sampled arc length along the band's centerline, with
cross-band/depth coordinates on each surface. Adjacent segments share coordinates,
so paint no longer restarts on every triangle. Front, back, inner and outer bands
are separate overlapping UV islands, not a unique atlas; their edge seams remain
an artistic consideration. Foot caps each receive a complete quad mapping.

`procedural/examples/arches.json` composes circular, shallow and tall arch bands
on shared rounded columns with measured spring-line placement. It is a reusable
geometry/integration fixture, not masonry engineering, a game doorway binding,
or final painterly art. No new MUD exit is inferred from an opening.

![Circular, shallow and tall procedural arches in Godot](verification/scene-forge-arches.png)

The updated arch fixture adds a subtle underpainting layer to exercise this
mapping. Tests verify UV ranges, adjacency continuity and nonuniform U increments
on ellipses. Godot's general roundtrip test now compares imported UVs as well as
positions/normals/indices, allowing storage quantization.

Review framing now derives an orthographic camera from projected instance bounds
at a fixed isometric orientation, instead of assuming the original workshop's
size and location. This makes small/new fixtures legible without hand-editing a
camera. It is a diagnostic framing rule, not production scene composition.

The actual render confirms open centers and distinct curved silhouettes. Column
transitions and uniform finishes remain construction quality. The complete runner
passed 33 stages across seven fixtures, including 25 Rust tests; this is not
artistic admission of the arches or a generated environment.

### Shared-machine validation: current CPU-only entry point

Run `procedural/check-scene-forge.ps1 -Cargo <cargo>` on Windows. Following the
user's crash warning, this command launches **no Godot or Unity process**.
The old `-Godot` invocation is explicitly rejected before execution. It runs
locked Rust tests, formatting, strict clippy, release compilation, byte-for-byte
determinism for every example. Cargo uses one job and tests use one thread.
Each owned native process runs hidden and BelowNormal, with a 90-second default
timeout, a sampled 1 GiB root-process working-set ceiling and a 6 GiB
whole-machine free-RAM floor. These are sampled safeguards, not an OS reservation
or a bound on total child-process memory. The runner can terminate only its
owned process tree. It refuses heavy work if headroom is insufficient.

Each run creates a fresh `procedural/generated/reviews/<time-and-id>/` directory
containing compiled JSON, logs and a structured `report.json`. The report records
source/compiler hashes, times, errors, sampled root working set and available
RAM, output hashes and sizes. Unsampled measurements are null, never zero claims.
It does not inflate the full scene JSON into PowerShell objects. Changed source
hashes during a run invalidate the result. Logs, failure reports and unfinished
artifacts are retained for diagnosis. `engine_checks` and `visual_review` are
explicitly `not_run`; there are no new renders or native packages from this mode.

The existing Godot importer, spatial tests and native-package verifier are
retained, but their former repeated-launch orchestration is retired. A reusable
owned background session with resource monitoring must replace that workflow
before unattended engine checks resume. Headless dummy rendering cannot certify
real MultiMesh transforms, rendered appearance or graphics-backed package data.
Do not attach to or stop another thread's process. No persistent review worker
has been implemented or started at this checkpoint.

Every render starts with `visual_review: pending`, even when technical checks pass.
The initial render inspection confirms the fixtures are visible but remain crude
construction/operator tests, not attractive generated environments. The runner is
not an aesthetic grader, a Unity test, a VRAM measurement or a world-completion
certificate. Its purpose is to supply repeatable evidence for the next iteration.

The retained [initial verification report](verification/scene-forge-check-report.json)
records 29 passing technical stages across six fixtures. Its absolute artifact
paths identify the local run; those generated binaries and images are not bundled
with the report. This is historical graphics-backed evidence; the current
CPU-only command does not reproduce those engine checks. Latest CPU receipt
`20260906-114229-6bd0f3a215334b1d8459e079585c3b33` passed 22 stages across nine
fixtures; explicit legacy-launch and low-headroom refusal tests also passed.

### Bounds and live machine-readable inspection

Compiled meshes now include local `bounds.min`/`bounds.max`. Every instance
includes the axis-aligned envelope of that mesh box under its final transform.
Local bounds are computed once per mesh; placed bounds require eight transformed
corners, not scanning the mesh for every repeated object. These are conservative
geometric envelopes, not exact silhouettes, collision shapes, navigation clearance,
or proof of non-overlap. Composed bounds must stay within the coordinate ceiling;
a legal origin no longer permits the object's extents to exceed it.

Godot's `describe_instance(display,index)` returns JSON-friendly source addresses,
mesh identity, live world position/basis, world bounds, vertex/index counts,
material settings and aperture count. It follows live parent transforms rather
than assuming the recipe is still the editor's current pose. Individual aperture
positions remain available through the existing on-demand aperture query.

The independent Rust/Godot bounds comparison exposed that headless dummy rendering
can return default MultiMesh transforms despite apparent in-memory import success.
The inspector therefore returns an explicit error when the real instance buffer
is absent. Do not use headless success as spatial evidence. Graphics-backed tests
compare the compiler bounds to Godot's transformed mesh AABB (f32 tolerance), while
headless tests require honest unavailable-data reporting. Unity live inspection is
still pending. Geometry byte estimates exclude CPU metadata and engine overhead.

### Editable assembly transforms and instance provenance

`{"kind":"transform","position":[2,0,1],"yaw":0.35,"scale":0.8,"child":...}`
transforms an entire assembly in local coordinates. Translation defaults to zero,
yaw to zero radians and positive uniform scale to one. Nested transforms compose
parent-first; repetition steps rotate and scale with their enclosing assembly.
Full 3D orientation is now available through a wrapper:
`{"kind":"rotate","axis":[1,0,0],"angle":1.5707963,"child":...}`.
`angle` is right-handed radians and `axis` is a nonzero direction in the parent's
local coordinates, normalized by the compiler. This rotates the child about the
wrapper's origin. Use nested translation/rotation wrappers to choose a pivot.
Outer transforms multiply inner transforms; changing their order changes the
result. Existing yaw inputs remain valid. Only positive uniform scale is allowed,
so these operations do not introduce shear or mirrored winding. Limits apply to
composed transforms and nesting, not merely individual inputs. Meshes stay shared.

**Compiled scene format is now version 2.** Input recipes remain version 1 with
the additional strict `rotate` node. Every compiled instance carries `position`
and `basis`: nine values, three consecutive XYZ basis columns including scale.
The compiler no longer emits a misleading single `yaw`/`scale` pair for a fully
oriented instance. World points are `position + basis * local_point`. Bounds
transform all eight local AABB corners through that same transform owner.

Both adapters accept historical version-1 yaw/scale files and new version-2
bases; old adapters reject the version bump rather than silently dropping tilt.
Godot uses the columns directly. Unity mirrors the mesh through Z and transforms
its basis as `S * basis * S`, `S = diag(1,1,-1)`, then recovers its rotation and
positive scale. CPU tests cover ordered/inverse rotations, axis normalization,
invalid inputs, local-space repeats, source paths and tilted bounds. Engine
basis/reflection assertions have been added but are not executed in the current
CPU-only workflow. Version-2 saved-engine output and visual rendering therefore
remain unverified; retained screenshots and package receipts predate this format.

CPU receipt: `procedural/generated/reviews/20260906-121210-9c418e5575164c4bb8269341460c97b0/report.json`:
44 tests, format, strict clippy, release and nine deterministic fixtures passed.
All nine mesh sets are unchanged. Independent comparison of the eight unchanged
placement fixtures verified 99 instances against their earlier yaw/scale
transforms and bounds, with zero observed numerical difference. The remaining
composition fixture intentionally tilts its repeated vessels; this is a transform
integration case, not a visually approved arrangement or physical-support claim.

Every emitted instance now carries `source.recipe_path` (a JSON Pointer to its
authoring part) and `source.repeat_indices` (outer-to-inner repetition indices).
Together they distinguish generated copies and let an inspector find the original
rule without guessing from the mesh name or geometry. Tests resolve each pointer
against the original recipe and check unique identities across nested repeats.
Godot retains this data as shared-node metadata, exposes a defensive-copy
`instance_source` query and verifies it after saved-package reload. Legacy output
without source data returns an empty descriptor, not fabricated provenance.

These addresses are deterministic for an unchanged recipe, not permanent IDs
across array reorderings. Persistent authored IDs, revision-aware edits, semantic
part roles, full constraint explanations and Unity
source-metadata persistence remain to be built. Do not present a pointer to a
shared part as permission to change just one repeated copy: that requires an
explicit override or a recipe edit with known scope.

User requirement: generated content must feed rich structured data back to the
editing agent and tools. Mesh-only output is insufficient. Keep construction
parameters, provenance, geometry bounds, sockets/apertures, materials, constraints,
resource costs and diagnostics accessible without image-based inference. The
provenance fields are an implemented first step, not completion of that contract.

`procedural/examples/transformed-assemblies.json` exercises nested transforms,
rotated repetition, shared parts and scaled room apertures. It is an integration
fixture, not an authored game room or an artistic-quality acceptance scene.

### Profile shading and texture coordinates

Lathe recipes accept optional `"smooth":true` (default false). Analytic normals
smooth the circumference, with profile-normal blending controlled by
`"crease_angle":45` (default degrees, valid range 0..180). Gentle profile changes
blend; changes exceeding the threshold remain sharp. Zero retains every profile
crease while smoothing radially. This supports turned stock, finials, columns
and vessel-like forms without requiring dense radial tessellation just to hide
lighting facets. A first render revealed horizontal banding with radial-only
smoothing; the crease-angle control was added in response. It does not smooth a coarse silhouette or interpolate a curved
profile: authors still control profile samples and radial segment count.

The closing ring now reuses angle zero exactly, eliminating the tiny geometric
gap caused by floating-point `sin(TAU)`. Lathe UVs now wrap once around the
circumference and use normalized profile arc length vertically, replacing the
old repeated triangle-local mapping. Coincident seam positions intentionally
carry U=0 and U=1. This changes regenerated lathe UVs even with smooth disabled;
existing flat-color recipes are unaffected visually by that UV correction.

`procedural/examples/lathe-shading.json` compares flat/smooth shading at 16 and
48 radial segments with the same profile. It is a closed geometry diagnostic,
not a hollow usable pottery asset or finished scene. Tests check unchanged
geometry between shading modes, unit/radial normals, sharp caps, seam UVs and
valid coordinate ranges. The same engine-neutral output and Godot normal
roundtrip checks are used; no second mesher or custom engine shader is added.

![16-segment flat and smooth, then 48-segment flat and smooth, actual Godot render](verification/scene-forge-lathe-shading.png)

The second actual render confirms the gentle-profile banding is removed by
normal blending. The low-segment silhouette is still polygonal on close inspection;
shading is not geometry subdivision. This is rejected as a final-art presentation
and retained as operator verification only.

### Portable material response

Mesh definitions may now include `"material":{"roughness":0.2,"metallic":1}`.
Both values must be finite and in 0..1; misspelled properties are rejected.
Missing settings default to roughness 0.85 and metallic 0, preserving the previous
Godot appearance. The compiler emits both resolved values, including defaults.
Godot's legacy compiled-JSON fallback uses these same defaults. Unity's legacy
fallback now explicitly matches them rather than depending on shader defaults.

Godot maps these to StandardMaterial3D roughness and metallic. Unity maps metallic
directly and smoothness to `1 - roughness`, using URP Lit `_Smoothness` or Standard
`_Glossiness`; URP metallic workflow is selected explicitly. Property references:
[Godot BaseMaterial3D](https://docs.godotengine.org/en/stable/classes/class_basematerial3d.html)
and [Unity URP Lit source](https://github.com/Unity-Technologies/Graphics/blob/master/Packages/com.unity.render-pipelines.universal/Shaders/Lit.shader).
This is a portable scalar convention, not a claim of pixel-identical rendering.

`procedural/examples/materials.json` holds geometry and color constant while
comparing matte nonmetal, polished nonmetal, rough metal and polished metal.
The Godot diagnostic now provides a procedural sky for reflections; the actual
render shows changing highlight width and metallic response. The polished metal
is dark in this lighting, so this is a parameter diagnostic, not an approved
bronze/gold recipe or finished art. No external texture or paid asset is used.

![Material response comparison in Godot](verification/scene-forge-materials.png)

Rust tests cover defaults, partial settings, range errors, NaN/infinity and
serialized f32 roundtrips. Godot checks settings after pack/reinstantiate;
the graphics-backed exporter also compares color, roughness and metallic after
disk reload. Unity's smoke test now accepts any compiler fixture and checks
shared materials and smoothness conversion, but **has not executed locally**.
Texture generation, surface-specific detail, material slots within a mesh,
transparency/refraction, emission, clearcoat and cross-engine color calibration
remain unsupported or unverified. Alpha is retained as existing color data,
not an implemented transparency mode. Geometry residency estimates do not include
engine material, sky or framebuffer allocations.

### Rounded stock operator

`rounded_box` adds controlled edge curvature to reusable stock without changing
its declared outer footprint. Example shape:

```json
{"kind":"rounded_box","size":[6,3,4],"radius":0.35,"segments":6}
```

Dimensions are full extents in metres, centered at the origin as with `box`.
Radius must be positive and strictly less than half every dimension. Segments
range from 1 to 32; they subdivide each rounded strip, not the flat middle span.
The implementation projects a boundary-aligned six-face grid onto a rectangular
core dilated by a sphere, with analytic smooth normals and face-local UVs.
It is original CPU code with no additional dependency. Shared named definitions
and both engines' existing mesh format remain the only output path.

The emitted vertex count is `36 * (2 * segments + 1)^2`, checked against the
remaining budget before allocation. These are unshared vertices; geometric seams
are closed, but this is not an indexed-vertex optimization or welded physics mesh.
Tests check exact extents, radius surface distance, outward winding, unit normals,
two incident triangles at every geometric edge, bad inputs, budget refusal,
deterministic JSON and repeated mesh reuse. Precision-collapsed surfaces fail.

`procedural/examples/rounded-stock.json` compares a sharp box with 0.08, 0.35 and
0.9 metre rounding, plus repeated beams and plinths. The actual Godot render was
inspected: narrow rounding preserves a crisp silhouette and broader rounding
produces a smooth transition. The broad sample is intentionally exaggerated for
diagnosis, not an instruction to make architecture pillow-like. This is a tool
fixture, not approved environment art. That checkpoint used flat-color, uniformly
rough materials; portable scalar response is now supported as described above,
but bespoke textures and surface detail are still missing.

![Sharp to broad rounding, actual Godot diagnostic render](verification/scene-forge-rounded-stock.png)

The Godot import test additionally compares positions, smooth normals (allowing
0.001 storage quantization) and reversed triangle winding after packing and
reinstantiating. Graphics-backed disk package verification remains necessary
because a headless import cannot certify saved GPU instance buffers.

Latest priority: build and harden the shared tool, not additional Crossing room
content. Tool validation is a separate gate from room/art admission.

### Numerical and workload regression checkpoint

The triangle builder now computes cross products and normalization in f64 before
emitting f32 normals. A reproduced regression previously emitted only 12 of 36
box vertices for dimensions `[1e-20, 1, 1]`: its absolute area cutoff silently
discarded four faces. Tests now retain every box face at thin, tiny and large
scales and require finite unit normals. Exact zero-area lathe pole triangles
remain intentionally omitted. Box dimensions that underflow when halved are
rejected rather than accepted as a collapsed slab. This is numerical correctness,
not a claim that engines can visually resolve microscopic geometry.

Empty repeated subtrees are pruned before expansion. Otherwise nested repeats
could pass the zero-instance budget and still perform billions of empty steps.
The regression uses two nested `u32::MAX` repeats over an empty group and requires
an empty, zero-byte scene. No new dependency or GPU allocation is introduced.

These checks do not certify arbitrary mesh topology, Unity behavior, GPU memory,
or final art quality. Engine-render and saved-package checks remain independent.

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

### Realism research update, 7 September 2026

**Current decision:** improve construction and material response, not resolution
alone. The cake/pie remains rejected for final art. Package persistence is useful
infrastructure, not evidence that the generator makes convincing objects.
Preserve the painterly fantasy direction: believable thickness, deformation,
contact and light response underneath deliberate stylization.

This is a researched implementation plan, not newly implemented capability.
Extend the existing Rust compiler, porous extractor, material profiles and
Blender baker; do not create another generator or renderer alongside them.

#### Reading and technology screen

1. **Procedural Bread Making (2015).** The earlier inaccessible-paper status
   below is superseded for this paper only: the [institutional full text](https://ri.conicet.gov.ar/bitstream/handle/11336/15202/CONICET_Digital_Nro.18585.pdf?isAllowed=y&sequence=1)
   is now accessible. Read sections 3.1-3.2 and the baking/crust excerpts.
   Its bubble populations vary with radius; boundary distance protects crust,
   and subsequent deformation avoids retaining perfectly spherical voids.
   **Our adaptation:** preserve an uncut host boundary, create a crust exclusion
   region, deform the internal cavity field, and only then intersect the cut.
   A cut face must not acquire a newly baked crust. Full thermal simulation is
   not the first implementation. The separate 2016 porous-materials paper is
   still a located source, not a completed methods reading.

2. **Procedural Multiscale Geometry Modeling using Implicit Functions (2025).**
   Expanded the [previous reading](https://arxiv.org/html/2504.09553v1) to
   sections 3.2-3.4, 4-6 and limitations. Clustering, anisotropy and spatial
   variation offer more than our current spherical coupon. The paper identifies
   triangle extraction and local editing as challenges; its OptiX/RTX 4090
   results do not establish our budgets. **Our adaptation:** bounded field
   operations and baked surface detail, not a new runtime volume renderer.
   Any domain warp invalidates the old neighborhood proof unless the displacement
   and feature reach are included in that bound. Do not label a warped implicit
   field an exact signed distance function.

3. **OpenPBR: Novel Features and Implementation Details (2025).** Read the
   [coat section, equations 70-89 and implementation discussion](https://arxiv.org/html/2512.23696v1).
   Coating requires base/coat interface treatment, absorption, internal-reflection
   darkening and roughening; another shiny lobe alone is inadequate. The model
   explicitly does not cover liquid penetrating a porous base. **Our adaptation:**
   distinguish surface-film coverage from absorbed wetness. Extend our material
   contract and test the actual Blender response before applying compensation;
   do not double-darken a renderer that already accounts for the effect.

4. **Adobe OpenPBR BSDF implementation.** Inspected the official
   [repository](https://github.com/adobe/openpbr-bsdf) and its
   [Apache-2.0 license](https://github.com/adobe/openpbr-bsdf/blob/main/LICENSE).
   It is a concrete reference implementation to study/test rather than inventing
   all shading terms. No code downloaded, pinned, compiled or integrated here.
   Adoption must pin a revision and audit included notices/dependencies. This
   is not a ready-made Godot/Unity plugin or proof of exporter feature parity.

5. **Regularized Kelvinlets (SIGGRAPH 2017).** Read the
   [author abstract](https://graphics.stanford.edu/~djames/publication/kelvinlets/):
   localized elastic grab, scale, twist and pinch fields can supply controlled
   organic deformation. The linked Pixar PDF redirects; full equations remain
   unread. **Candidate, not implementation-ready:** obtain/read the full paper
   before coding a purported Kelvinlet. Intended uses include fruit dimples,
   compressed pastry and uneven handmade vessels; not character-workflow ownership.

6. **Blender displacement/instancing technology.** The official
   [Blender 5.0 Cycles notes](https://developer.blender.org/docs/release_notes/5.0/cycles/)
   describe object-space adaptive subdivision for shared instanced geometry.
   This is a useful candidate, but our installed 4.5.9 does not gain it by
   documentation lookup. No upgrade performed. Keep explicit mesh/texture caps;
   camera-dependent subdivision must not silently multiply shared geometry.

#### Next experiments, in implementation order

| Test | Missing capability | Required evidence |
| --- | --- | --- |
| Cut cake wedge | Crust boundary distinct from cut boundary; uneven connected crumb cavities | Exterior stays intact; cut exposes real pores; low-angle shadows and silhouette survive neutral lighting |
| Fruit in filling | Fruit is embedded in a continuous supporting filling, not buttons arranged on a plate | Side section shows contact and depth; macro-shape survives a clay-material view |
| Wet/dry material pair | Film coverage, interior color and dry substrate treated separately | Same geometry/camera/lights; clear highlights remain distinct from fruit color; no unearned metallic response |
| Pressed pastry strip | Smooth bounded compression and restrained asymmetry | Contact is seated; thickness stays positive; no flipped triangles or broken seams |
| Small reusable prop family | Geometric variation without resource explosion | Source edits propagate; bounded unique variants; export/reload preserves fields and actual meshes |

#### Proposed operator contract and algorithm

These names describe responsibilities, not a new schema already accepted by
the compiler. Add fields only alongside a real caller, validation and tests.
Keep metre units, stable IDs/seeds, operator order, undeformed bounds and support
anchors. Return region labels (crust, cut crumb, fruit, gel, film), not anonymous
triangles whose material assignment must later be guessed.

```text
compile_food(recipe, budgets):
    validate finite dimensions, seeds, region IDs and resource ceilings
    host = existing_parametric_shape(recipe.outer_shape)
    boundary = preserve_original_host_surface(host)  # before slicing
    cavities = existing_porous_field(recipe.pore_controls)
    reject candidate cavities violating authored crust clearance(boundary)
    apply validated bounded deformation to host and cavities consistently
    solid = host minus cavities
    if cut is authored:
        solid = intersect(solid, cut_halfspace)
        mark newly exposed surface as cut_interior, never crust
    mesh = existing_extractor(solid, bounded_sampling_plan)
    audit closure, orientation, tiny components, thickness and triangle budget
    on failure: emit diagnostic; do not silently fill cavities or admit asset
    assign material regions from construction provenance
    bake fine detail through existing profile/budget/export pipeline
    reload exported asset and compare geometry, regions and source parameters
    render fixed front, grazing-angle and cut views under fixed light rigs
    retain candidate until visual comparison passes; technical pass is separate
```

The current box-only field cannot accept arbitrary hosts or robust region-aware
cuts yet. Implement those extensions in place, with analytic primitive fixtures
before food complexity. For deformed fields, compare local queries to exhaustive
small-domain evaluation; test maximal reach, negative coordinates, seam samples
and minimum allowed feature size. Thickness checks must be independent of just
closed topology: a closed mesh can still contain unusably thin walls.

#### Cost and truthfulness gates

- Split silhouette-scale geometry from fine normal/roughness detail according
  to the authored closest view. Do not mesh every pore throughout every room.
- Preserve current extraction caps initially. Stream/bound work by component;
  stop before allocations exceed the budget, not after a render exhausts memory.
- Full transport effects such as subsurface scattering cannot be encoded faithfully
  into a fixed base-color texture. Record export losses and compare native
  engine appearance; a matching texture hash cannot certify material parity.
- Controlled comparisons lock exposure, camera, light size and backdrop. Review
  both clay geometry and finished materials to isolate causes. Do not tune light
  merely to hide defects. Keep prior failed renders out of admitted asset pools.
- No new engine processes, paid services, dependencies, runtime shader changes
  or GitHub Actions were needed for this research checkpoint. No measured 8 GB
  VRAM claim or new visual quality pass is made.

### Porous food: evidence and next implementation boundary, 6 September 2026

Read sections 3.1–3.2 and the results/discussion excerpt of
[Venu, Bosak and Padron-Griffe, Procedural Multiscale Geometry Modeling using Implicit Functions (2025)](https://arxiv.org/html/2504.09553v1).
The method generates particles from seeded grid cells, bounds neighbor searches
using particle radius, and supports spatially varying structures. Its performance
depends on representation; mesh extraction remains an acknowledged limitation.
Do not claim its renderer timings as Scene Forge results. No implementation was
downloaded or licensed into this repository. The older Procedural Bread Making
and Realistic Modeling of Porous Materials PDFs were located but their full-text
fetches failed; their methods are not recorded as read.

The selected experiment was a bounded cavity field intersecting a host
surface, compiled to the existing portable mesh format. Start with a small crumb
coupon, not a city-scale volume. Define pore spacing and radii in metres; preserve
seed, bounds and source parameters. Validate neighboring-cell coverage against
brute force, then closed extracted boundaries, outward normals, budgets and native
close-up appearance. Reject invisible painted-dot substitutes and claims of
porosity from color alone. Keep the existing lathe/sweep path for smooth pastry.
The first implementation and its limitations are recorded below; neither the
paper nor this selection establishes a final-art gate.

#### First implementation of the bounded coupon

The above proposed experiment now has an original Rust implementation in
`procedural/src/porous.rs`, reached by the existing compiler through
`porous_box`. `porous-materials.json` is its current caller/fixture. The cake
still uses its prior lathe; the coupon is not automatically admitted as cake art.
Parameters are host `size`, pore `spacing`, minimum/maximum `radii`, sampling
`step` (all metres) and integer `seed`. A deterministic cell hash places spherical
cavities; subtracting their local field from the host creates actual voids.
The 27-cell search is compared against a larger brute-force neighborhood.

This implementation uses a **truncated local field**, not an unlimited exact
distance function. The maximum radius is 0.45 spacing, and queried distances
are capped at half the spacing, making omitted cells irrelevant to that field.
Minimum radius is two requested grid steps. This does not guarantee every thin
wall or pore intersection is resolved. The padded grid is capped at 262,144
samples before allocation; emitted vertices obey the compiler budget. Extraction
uses six consistently tiled tetrahedra per cell and shared edge intersections.
Exact zero endpoints reuse their grid coordinate. Triangle orientation uses
inside/outside tetrahedron classification; shading normals use field differences.

Initial extraction failed the independent connectivity audit. The general suite
had not required closure for this new shape, so `porous_box` is now a required
closed shape alongside `room`; a fixture failure stops the checker. This change
is tested with a deliberately open mesh. Do not infer success from the initial
green runner or call open geometry a finished porous solid. Surface extraction
is an approximation and may produce separate closed cavities or fragments.
UVs are diagnostic planar coordinates, not production-ready porous texturing.

An explicit optional `surface_offset` shifts the level set in metres; magnitude
is limited to one tenth of the sampling step. Positive values expand material
and shrink cavities. The coupon declares +0.000001 m (one micrometre) rather than
silently welding away the point-contact ambiguity found with zero offset. This
is an authored geometric change, not a proof that arbitrary offsets guarantee
manifold extraction. No generic topology repair is claimed; new recipes must
pass the independent closure gate. The zero-offset failed receipt remains in
`procedural/generated/reviews/20260906-133154-6b2c3d5551e342c8a81d7001f4452b8d/`.

The explicit-offset coupon passed the strict audit: 85,240 triangles, 42,598
exact-position vertices, five components and zero reported connectivity defects.
Do not describe five components as a single connected solid or assume which are
cavity shells without containment analysis. Native import checks and capture
passed in the existing PID 30828; the reviewed image is
`procedural/generated/reviews/20260906-125338-e44dd4bf0e854f28a090f9293035b812/porous-coupon.png`.
Visible cavities confirm geometric structure, but coarse/polygonal cavity edges,
low pore density and uniform material make it unsuitable as cake crumb. The
recipe is an extraction coupon, not approved food art. No topology-cleanup,
final LOD, Unity execution, or measured 8 GB VRAM qualification is implied.

Final CPU receipt for this checkpoint:
`procedural/generated/reviews/20260906-133547-7c455e1648fb43559419bde6155da01f/report.json`.
53 Rust tests, six Node audit tests, strict clippy, formatting, release compilation
and deterministic fixture/audit workflow passed. New tests explicitly exercise
grid and vertex-budget rejection and excessive surface offsets, in addition to
neighbor lookup and seed checks. Native evidence above is for the same geometry;
no additional Godot process was required.

#### Denser cavity population: technical pass, visual rejection

The same operator now accepts `pores_per_cell` in 1..8 (default 1).
Particle index zero preserves the previous seed field; additional indices add
cavities without moving existing ones. Neighborhood lookup remains 27 cells,
with at most 216 particles considered per sample. Tests compare populations
1, 3 and 8 against a larger neighborhood, verify monotonic cavity union,
legacy JSON defaulting, and reject zero or excessive population.

The current coupon is 24 x 16 x 12 mm, spacing 4.5 mm, cavity radii
1.2..2 mm, sampling step 0.4 mm and three pores per cell. The unchanged
grid/vertex caps remain enforced. It produces 210,736 triangles, 105,164
exact-position vertices and nine components, with zero boundary edges,
winding conflicts, excess edge incidence or failed closed vertex fans.
This is not a self-intersection or connected-solid certification.

CPU receipt:
`procedural/generated/reviews/20260906-134334-6bce43cd9d2847e4b07682b1c0d1a8eb/report.json`.
All 54 Rust tests, six Node audit tests and the 38-stage workflow passed.
Native import and spatial checks passed in the existing PID 30828;
`procedural/generated/reviews/20260906-125338-e44dd4bf0e854f28a090f9293035b812/porous-dense.png`
was visually inspected. No new Godot process was launched.

**Reject as cake art:** the render reads as cut foam, with sharp cavity rims,
uniform flat color, thin fragments and unnaturally planar outside faces.
Increasing pore population did not establish edible material. Its triangle
cost is also unsuitable for indiscriminate room-scale replication. Keep this
as a bounded extraction fixture, not an approved food asset or cake replacement.
Next material experiments should separate sparse silhouette-scale cavities
from fine normal/roughness detail, establish a browned exterior versus fresh
cut interior, and validate those cues in the complete cake rather than treating
a denser diagnostic block as visual success. These next steps are not yet
implemented; existing cake and pie remain unapproved.

#### Fine pigment granulation in the existing paint path

Optional `material.paint.granulation` adds seeded, periodic soft pigment
deposits after the existing editable strokes. Contract:
`{"cells":[128,16],"strength":0.5,"color":[0.25,0.14,0.065]}`.
Each axis must contain 4..texture_size/4 cells; strength and RGB must be finite
and in 0..1. Independent U/V density accounts for differing surface lengths.
These are authored UV-space frequencies, not automatically inferred metric
texel density. A hash of the wrapped cell address and existing paint seed
determines the deposit center and elliptical radius. Only nine neighboring
cells are inspected per pixel; maximum radius is below one cell. Coverage is
bounded, periodic, and blended without baked directional illumination.

This is original CPU code within `paint.rs`, not a new renderer or a copied
paper implementation. No extra geometry, shader, adapter path or network
dependency is introduced. The existing texture and recipe metadata carry the
result to both adapters. At fixed resolution it adds no resident texture
bytes. The cake experiment increases its one shared sponge texture from
256 to 512 pixels: RGBA8 plus all mip levels grows by 1,048,576 bytes.
This is an estimate, not measured VRAM certification.

The first full-scene render used equal U/V counts and strong contrast; it
produced elongated dark spots, not believable crumb. It was rejected:
`procedural/generated/reviews/20260906-125338-e44dd4bf0e854f28a090f9293035b812/pastry-granulated.png`.
The corrected experiment uses the anisotropic counts above with lower contrast.
Neither variant provides normal maps, roughness variation, physical cavities,
subsurface scattering or a fresh-cut cake interior. Do not describe pigment
marks as geometric porosity or regard this alone as final food-art admission.

Corrected full-scene capture:
`procedural/generated/reviews/20260906-125338-e44dd4bf0e854f28a090f9293035b812/pastry-fine-grain.png`.
Visually reviewed: conspicuous horizontal spots are reduced to quieter, finer
surface variation, but the sponge still lacks depth and the icing/crust remain
too uniform. Keep as a material-development fixture, not final art.
Native Godot import and spatial checks passed for 80 instances and 17 shared
meshes in PID 30828, sequence `pastry-granulation-002`; no engine restart.
The CPU receipt at
`procedural/generated/reviews/20260906-134959-e8c9387c753741169e8ec28f1f9b2b33/report.json`
passed all 55 Rust tests, six Node audit tests and 38 stages. Granulation tests
cover periodicity, coverage range, deterministic output, zero-strength
equivalence, unchanged texture byte size at fixed resolution and density
rejection. Unity runtime and fresh on-disk engine reload were not exercised
at this checkpoint; existing adapters consume the unchanged RGBA output.

#### Surface-normal extension: CPU verified, native review pending

`paint.granulation.relief_texels` is optional, defaults to zero, and accepts
finite values in 0..4. It controls shading-only cavity depth in texture pixels,
not metres and not displacement. The same periodic grain coverage supplies
negative height; centered wrapped finite differences produce
`normalize([-dH/dU_pixel, -dH/dV_pixel, 1])`. The compiler emits optional
`paint_texture.normal_rgba`: linear +X/+Y/+Z tangent-space RGB8, alpha 255,
including the full mip chain in largest-to-smallest order through 1x1.
Zero relief omits that payload and leaves the existing albedo unchanged.
Changing texture resolution changes the physical apparent relief unless the
author retunes this explicitly texel-based control.

The canonical Godot adapter enables the normal texture, uploads the
compiler-provided normalized mip chain and generates mesh tangents.
This follows the documented requirements
for [normal textures](https://docs.godotengine.org/en/4.7/classes/class_basematerial3d.html#class-basematerial3d-property-normal-texture),
[ArrayMesh tangent generation](https://docs.godotengine.org/en/4.7/classes/class_arraymesh.html#class-arraymesh-method-regen-normal-maps)
and [normal mipmaps](https://docs.godotengine.org/en/4.7/classes/class_image.html#class-image-method-generate-mipmaps).
The Unity adapter uses a linear texture, the normal-map shader keyword and
[RecalculateTangents](https://docs.unity3d.com/ScriptReference/Mesh.RecalculateTangents.html).
Unity uploads the same full normal mip chain without automatic regeneration.
The earlier adapter-specific normal filtering is superseded: all normal
mip filtering is now owned by the Rust generator. Rendered orientation and
native upload equality still require engine verification.

Residency estimates include the additional full normal-map mip chain and
16 tangent bytes per indexed vertex. The pastry experiment uses 1.5 texels of
relief on the one shared sponge mesh. Against the preceding pigment-only
fixture, positions, normals, UVs and triangle indices are byte-equivalent
as JSON values. The new estimate is 1,486,532 bytes larger: 1,398,100 bytes
for the 512-square RGBA normal mip chain plus 88,432 tangent bytes for 5,527
vertices. No extra triangles. This remains an estimate, not measured GPU use.

CPU receipt:
`procedural/generated/reviews/20260906-135603-3260c0f9348b41f182f9fcd647c57048/report.json`.
56 Rust tests, six Node audit tests and all 38 stages passed. Tests cover
flat normals, known slope sign, wrap behavior, quantized unit-length tolerance,
positive Z, deterministic bytes, unchanged albedo, omitted zero-relief map,
invalid relief rejection, and normal/tangent budget accounting.
An initial strict-lint failure in test chunk iteration was fixed without
disabling the lint; its failed receipt is retained.

**Native gate remains open:** adapter changes and new native assertions are
prepared but have not run. The existing PID 30828 still has the earlier importer
preloaded and still displays the pigment-only scene; it cannot prove these
changes. Replacement of only that viewer was requested, not performed.
No new normal-mapped render, native parse pass, saved-scene reload, Unity run,
or final material-art approval is claimed at this checkpoint.

#### Canonical normal mip filtering and Unity upload correction

Each next normal mip level averages the four decoded RGB direction vectors,
renormalizes the sum, and re-encodes to RGBA8. The base level remains unchanged.
All supported sizes (64, 128, 256 and 512) produce a complete chain ending in
1x1. A zero-sum fallback uses the neutral +Z normal; generated cavity normals
already have positive Z. Tests exercise opposing slopes whose filtered result
must be flat, preservation of base bytes, neutral-map invariance, chain length,
and normalization throughout the generated chain. Filtering remains a simple
normalized box filter: no normal-variance-to-roughness compensation or proven
shimmer elimination is claimed.

Both adapters consume the same contiguous payload. Godot creates an Image with
mipmaps already present; Unity loads all raw levels and calls Apply without
regenerating them. The Unity smoke test now compares every uploaded normal
mip byte with the compiler payload. These assertions are prepared, not run.
Previously generated base-only normal payloads must be regenerated with the
current compiler; the normal extension has not been admitted to runtime use.

The same review found an existing Unity albedo upload contract mismatch:
a mipmapped Texture2D received only base-level bytes through LoadRawTextureData.
That API requires the whole texture, including mip levels
([Unity documentation](https://docs.unity3d.com/ja/current/ScriptReference/Texture2D.LoadRawTextureData.html)).
The canonical albedo path now uses SetPixelData at mip zero followed by
Apply with mip generation. This is a documentation-grounded source repair;
Unity compilation and runtime verification remain unavailable.

Compiler-generated normal mip bytes replace adapter-generated bytes rather
than increasing the prior residency estimate. Serialized output grows by the
lower-level data. The 512-square normal chain is 1,398,100 bytes in total.
This work leaves the current Godot process and its pigment-only preview
untouched; no new normal-mapped image is available yet.

Final CPU receipt for this change:
`procedural/generated/reviews/20260906-140105-0ac4966ebd1248d9bccf9fc44bf6956b/report.json`.
57 Rust tests, six Node mesh-audit tests and all 38 stages passed. The prior
run `20260906-135952-ca2e36dc07204b7d80414b59caa1461e` also passed before
the Unity albedo repair and additional native byte-comparison assertion.
No native engine pass is inferred from either CPU receipt.

#### User-directed wet cherry finish

The user clarified that cherry glaze is wet: reducing plastic appearance must
not flatten every material to matte. The existing fruit material now uses
roughness 0.16 instead of 0.7, richer red albedo and a subtle seeded dark-red
64-square painted underlayer. This is a single-surface glossy approximation,
not a separate transparent glaze layer or subsurface fruit simulation.
Cream, sponge, crust, camera, placement and fruit geometry remain unchanged.

For this review the pastry caller explicitly sets sponge relief_texels to zero.
The pending normal-map engine experiment is not silently shown through the old
importer; its compiler and adapter implementation remain available for later
validation. This supersedes the fixture's earlier enabled 1.5-texel setting,
not the retained historical CPU evidence.

Actual render:
`procedural/generated/reviews/20260906-125338-e44dd4bf0e854f28a090f9293035b812/pastry-wet-cherries.png`.
Reviewed bright localized cherry highlights and richer red against the matte
cake; overall pastry art still needs work. Existing PID 30828 passed native
import and spatial checks for 80 instances and 17 shared meshes, sequence
`pastry-wet-cherries-001`. No engine restart and no normal-map validation claim.
CPU receipt:
`procedural/generated/reviews/20260906-140940-773dbec951164aca8b56551780666515/report.json`;
all 38 stages, 57 Rust tests and six mesh-audit tests passed.
This art checkpoint is committed locally without a push or Actions dispatch,
respecting the user's request to limit GitHub Actions usage.

#### Filling close-up: resolution alone is not the defect

The next recipe experiment darkens and glosses the cake jam and pie compote,
softens the cake cream's upper outer profile, and adds twelve partly submerged
fruit pieces using one shared fluted-lathe definition. Their centers are in
lattice openings; this is deliberate placement, not random scattering.
No general fruit/lattice intersection certification is claimed.

CPU receipt `20260906-141327-7c49ff98068b4b1fb1465b7d51668c30` passed all
38 stages, 57 Rust tests and six mesh-audit tests.
Native whole-scene capture passed 92 instances/18 meshes:
`procedural/generated/reviews/20260906-125338-e44dd4bf0e854f28a090f9293035b812/pastry-fruit-filling.png`.
A pie-only review recipe keeps the same pie geometry/materials and frames it
larger at elevation 38 degrees:
`procedural/generated/reviews/20260906-125338-e44dd4bf0e854f28a090f9293035b812/pie-filling-close.png`.
Native import/spatial checks passed 61 instances/11 meshes in the unchanged
PID 30828. This is a native close-up, not an AI-enhanced image.

**Visual rejection remains:** enlarged filling still reads as a smooth slab;
fruit tops resemble separate buttons. More pixels do not solve this material
and geometric-transition problem. Cream is fuller but remains overly regular.
Retain this as an unapproved development fixture, not evidence of convincing
wet fruit or final food art. The user specifically questioned missing wet-surface
math. Distinguish the existing Godot PBR renderer from our limited exported
controls: roughness/metallic/color are exposed; layered glaze, transmission and
roughness texture controls are not. Normal-map integration remains unverified.

Godot already provides a separate clearcoat lobe and roughness control
([official material documentation](https://docs.godotengine.org/en/4.7/classes/class_basematerial3d.html)).
A next material step should expose that existing capability and evaluate
reflections in a close-up with useful lighting contrast, rather than inventing
a replacement BRDF or claiming that a dark glossy albedo is syrup.
No clearcoat implementation, new lighting rig or engine restart occurred here.
Checkpoint remains local; no Actions dispatch or remote push.

#### Blender reference renderer and GPL adoption

The user approved Blender and GPL. procedural/LICENSING.md is the current
licensing authority: GPL-3.0-or-later generator, preserved historical MIT notice,
unchanged third-party and asset notices, separate MIT Unity-adapter exception
without clearance to distribute a GPL-linked proprietary-engine plugin.
No Blender implementation code was copied into Rust.

procedural/blender/render_reference.py consumes the existing compiled meshes,
UVs, normals and instance transforms; it does not generate replacement geometry.
It preserves shared meshes, packs painted textures, and stores the source recipe
in the editable .blend. An explicit food-reference treatment adds Principled
coat, modest subsurface scattering, noise bump/roughness, area lights and AgX.
Those material nodes are Blender-only reference work, not exported game parity.
The first render exposed pale color handling; the corrected version explicitly
converts authored sRGB colors/bytes to linear values without double conversion.
Godot color parity is not yet measured.

Official portable Blender 4.5.9 LTS Windows x64 ZIP was checksum verified:
41da973b9bf95bb312cbeff4d1982feb13259b43c821686b9bafea4dfe5477cf.
It is installed outside the repository in Documents/Codex/tools/blender-4.5.9.
No paid generation, model weights, cloud rendering or GPU rendering was used.

Corrected image and editable scene reside in
procedural/generated/reviews/20260906-125338-e44dd4bf0e854f28a090f9293035b812/blender-glaze-002/
as reference.png and reference.blend. Input SHA256:
b254b72269fc7045f776ad269316db3dc61fc34fb489c2a6d16c132c4c3ec65e.
Observed render/save time 30.14 seconds, sampled process RAM peak
1,147,883,520 bytes, two CPU threads, 32-sample maximum and 60-second render cap.
The launch watchdog enforced 3 GiB process RAM and 150 seconds total.
These are not VRAM or game-performance measurements.

Fresh background --verify-only reload passed 61 instances, 11 shared meshes,
original positions, triangle counts, packed textures, recipe metadata and coat
settings. Future renders also perform that reload check. Rust's separate CPU
receipt 20260906-142640-f3a49c9c7fbc4fbcb2e795e58cd0ac95 passed 38 stages,
57 Rust tests and six mesh-audit tests; it does not verify Blender.

Visual finding: wet fruit highlights and contact shadows are more legible,
but the crust is too pale/regular and fruit tops still resemble placed pieces.
This is a material reference, not final food art. Earlier rejected reference
blender-glaze-001 is retained. No Godot process was changed; no remote push
or Actions dispatch occurred.

#### Editable Blender surface profiles

The former hard-coded food-name treatment now has one data owner:
procedural/blender/reference_materials.json, validated by material_profiles.py.
Named profiles expose bounded Principled inputs, noise scale/detail,
bump strength/distance, roughness ranges and an optional three-color palette.
Assignments use explicit name patterns; overlapping matches fail rather than
silently choosing an order. Unassigned surfaces retain the source material.
Limits: 64 KiB profile file, 32 profiles, 64 assignments, whitelisted shader
inputs and finite bounded numeric controls. Blender-reference scope remains
explicit; these profiles are not a game-engine material export contract.

The renderer saves the full profile document on the scene and the selected
profile on each material. Fresh reload checks compare those exact documents
and authored Principled input values, in addition to geometry and packed images.
Seven Python unit tests cover assignments/fallback, ambiguity, finite ranges,
palette shape, roughness ordering, unsupported inputs/coordinates, missing
profiles and malformed document structures. Python compilation also passed.
Rust sources and game adapters did not change and their suites were not rerun.

First baked-pastry profile used Generated coordinates; thin strip bounds
stretched the texture into strong streaks. Retained rejected render:
procedural/generated/reviews/20260906-125338-e44dd4bf0e854f28a090f9293035b812/blender-baked-001/.
The corrected baked profile uses Object coordinates, lower bump and coat
strength, and a darker palette. It overrides the reference pastry albedo with
procedural pigment; original painted images remain packed for editing.
Object coordinates are local mesh units, not scale-invariant world-space
texturing; changing instance scale still changes apparent grain size.

Current render and editable scene:
procedural/generated/reviews/20260906-125338-e44dd4bf0e854f28a090f9293035b812/blender-baked-002/
(reference.png, reference.blend, receipt.json).
Native rendering and saved-file reload passed for 61 instances/11 meshes.
Observed render/save 29.11 seconds, sampled process peak 1,146,454,016 bytes;
CPU two threads, 32 samples, same 3 GiB/150-second launch bounds as before.
Geometry, lighting and wet-fruit treatment are unchanged from the input study.
Visual review finds smaller-scale mottling instead of stretched streaks,
but pastry is still too pink and regular; this remains unapproved reference art.
No Godot process change, paid service, remote push or Actions run occurred.

#### Portable Blender bake checkpoint

`procedural/blender/bake_asset.py` now consumes the existing saved Blender
reference, one shared-mesh name (or `--all` for the assembly), and a fresh output directory. This is an
export stage of the canonical generator, not a second geometry generator.
It makes a separate bake UV layer, explicitly preserves original albedo UV
sampling, and uses Blender Smart UV Project rather than baking over potentially
overlapping original caps. Geometry positions and triangle count are unchanged.
UV packing is not formally overlap-certified.

The bounded exporter accepts a 128 MiB authoring file, one opaque Principled
material per mesh, at most 100,000 vertices per mesh, 500,000 unique vertices
per assembly, 32 unique meshes and 1,000 instances. It bakes budget-planned
128/256/512-square base color,
roughness and tangent-space normal textures on CPU/two threads. Emission
rerouting extracts unlit color/roughness; normal baking retains the authored
bump response. Transparent/transmissive inputs are rejected. It exports embedded
GLB textures, original recipe and material-profile metadata. Clearcoat strength
and roughness are checked in KHR_materials_clearcoat. Subsurface scattering and
independent coat IOR are explicitly recorded as export losses; no lighting is baked.
See the [official glTF exporter material documentation](https://docs.blender.org/manual/en/4.0/addons/import_export/scene_gltf2.html).

Usage (inside a bounded hidden Blender process):

```text
blender --background --factory-startup --threads 2 --python-exit-code 1 --python procedural/blender/bake_asset.py -- reference.blend pie.crust NEW_OUTPUT_DIRECTORY
```

Every successful run inspects GLB structure/embedded textures/metadata, then
reimports the actual GLB with Blender, checks triangle count and world bounds
within one micrometre, and renders that imported asset. This is not a Godot or
Unity parity test. The initial bounds/count-only gate is now strengthened by
the independent binary audit described below.

Evidence under the existing review root
`procedural/generated/reviews/20260906-125338-e44dd4bf0e854f28a090f9293035b812/`:

- `baked-crust-002`: 19,392 triangles, 1,236,876-byte GLB; successful bake,
  reload and render in 12.17 seconds; sampled peak process RAM 568,545,280 bytes.
  First and second crust exports have identical GLB SHA-256. Visible grain
  survives, but the regular bowl shape and pinkish finish are not approved art.
- `baked-fruit-002`: 4,320 triangles, 804,024-byte GLB; successful bake,
  reload, clearcoat check and render in 8.09 seconds; sampled peak process RAM
  549,158,912 bytes. Wet highlight survives the portable material. Fruit shape
  remains a small lathed lump, not a convincing finished filling treatment.
- `baked-fruit-001` inspection image was blank because the default camera near
  plane clipped the tiny asset. Camera clipping now scales with measured bounds;
  corrected actual render inspected. Earlier image is rejected evidence.

Runs used hidden BelowNormal processes with a 3 GiB sampled working-set and
150-second wall-time watchdog, terminating only their own process on excess.
Those watchdogs are launch controls, not a built-in hard reservation or VRAM
measurement. Seven material-profile tests and Python syntax checks passed.
Rust is unchanged; its full suite was not rerun for this Python-only checkpoint.
Whole-assembly export is implemented in the checkpoint below; automatic texture-resolution/LOD budgets, engine
import checks, and higher-quality pastry/fruit construction remain unfinished.
No Godot process replacement, paid generation, remote push or Actions run.

#### Independent portable geometry audit

`procedural/blender/glb_geometry.py` is the single GLB decoding/audit owner used
by the bake exporter. It bounds files to 64 MiB and accessors to one million
entries, reads embedded binary buffer views (including interleaved positions),
and rejects unsupported sparse/normalized/compressed geometry, truncated
chunks, out-of-view reads, invalid indices and non-finite coordinates.
It is deliberately not a general-purpose glTF importer.

Before export, the baker records source triangle corners in glTF local axes.
After export, the audit decodes the actual indexed positions and compares
oriented triangle multisets on a one-micrometre coordinate grid. Cyclic corner
rotations and vertex splitting/reordering are allowed; reversed winding,
changed surfaces, missing triangles and duplicate triangles are not.
This comparison is quantized, not exact floating-point identity, and does not
certify normal/tangent/UV attributes, node matrices individually, manifoldness
or self-intersection. The independent native reload/bounds/render gate remains.

Seven audit tests passed, including an adversarial same-bounds/same-count but
different triangle, reversed facing, duplicate counts, interleaved positions,
non-finite data, bad indices, truncated data and external buffers. Seven
existing material-profile tests also passed. Syntax checks passed.
Actual `baked-crust-audited-001` export under the same review root passed all
19,392 source triangles plus native import and actual visual inspection.
Sampled process RAM peak 585,330,688 bytes; wall time 14.14 seconds, hidden
BelowNormal CPU/two threads under the existing 3 GiB/150-second launch guard.
The render remains unapproved food art; this checkpoint changes export
assurance, not artistic quality. No Godot restart, remote Actions or paid work.

#### Shared-mesh assembly bake

The same `bake_asset.py` path now accepts `--all` in place of a mesh name.
It unwraps and bakes each unique mesh once, then exports every selected
placement together. No repeated external Blender launch is needed per mesh.
Source geometry is unchanged; per-mesh texture directories are generated with
numeric names so authored mesh names cannot escape the output directory.
The original reference file hash is checked again at completion.

The complete authoring recipe is stored once on an explicit
`SceneForgeAssembly` root. Export placement hierarchy is flattened under this
root while retaining each world transform; original recipe hierarchy remains
recoverable from the metadata. Each object retains source-mesh identity and a
batch export ID. Original source-instance metadata also remains on objects.

Binary checks now cover every unique mesh, the full mesh-name set, all instance
IDs and their mesh references, embedded textures and per-mesh material profiles.
Native reimport checks every placement matrix and bound within 1e-6, triangle
counts, shared mesh resource count and source-recipe preservation. This is still
not Godot/Unity validation or certification of untested Blender source graphs.

Actual evidence: `baked-assembly-003` under the existing review root exported,
reimported and rendered the complete pie/plate: 61 instances sharing 11 meshes,
71,376 unique triangles, 5,377,360-byte GLB. All oriented triangle audits passed.
The final background run took 18.16 seconds with sampled process RAM peak
683,245,568 bytes, CPU/two threads, same 3 GiB/150-second watchdog. Earlier
pre-root assembly runs 001 and 002 produced byte-identical GLBs. The new root
intentionally changes the final file; that final rooted output is not yet
repeat-determinism certified.

Fixed 512-square maps currently imply 46,137,300 bytes for three uncompressed
RGBA8 maps per unique mesh including complete mip chains. This estimate excludes
mesh data, engine allocation overhead, render targets and driver memory; it is
not measured VRAM. Uniform resolution and the dense source tessellation still
need adaptive budgeting before broad runtime admission.
Eight binary-audit tests and seven material-profile tests pass; Python syntax
checks pass. Actual reimported assembly render inspected: layout, pastry grain
and wet highlights survive, but pastry remains too pink/regular and the filling
still reads as an arrangement of small lumps. No final-art approval, paid work,
Godot process replacement, remote push or Actions run.

#### Independent pigment and surface-grain controls

Reference noise profiles now optionally accept `pigment_scale` (finite 1..512)
and `pigment_contrast` (finite 1..4), both requiring a color palette. Omission
preserves the prior shared-frequency/default-contrast behavior. Color is driven
by a separate noise field when requested; normal perturbation and roughness
retain the original field. Contrast remaps around 0.5 before the bounded color
ramp. These are reusable artistic controls, not a thermal baking simulation.

The pastry study uses pigment scale 60 versus grain scale 180 and contrast 2.5.
Its palette is darker and subsurface weight is zero, avoiding a reference-only
scattering dependency for the crust. Fruit, lighting and geometry are unchanged.
The first low-contrast/paler trial (`blender-browning-001`) looked like raw dough
and is rejected. `blender-browning-002` adds visible broader brown patches but
still has a pinkish cast and overly smooth regular strips. It is not approved
food art. More noise is not the solution to the remaining defect: browning
needs authored shape/exposure masks and the construction needs better pastry
and filling detail.

Both reference images and saved scenes live under the existing review root.
Final native reference render and saved-source reload passed for 61 instances,
11 meshes in 24.15 seconds, sampled process RAM 1,146,593,280 bytes. The entire
updated assembly then baked to `baked-browning-001` and passed all 71,376 unique
triangle comparisons, placement/reuse/material checks, native reimport and
actual render inspection in 18.14 seconds, sampled RAM 693,002,240 bytes.
Both used hidden CPU/two-thread BelowNormal runs with the existing watchdog;
these are not VRAM measurements. Nine profile tests, eight binary-geometry
tests and Python syntax checks passed. No Rust changes or full Rust rerun;
no Godot restart, paid service, remote push or Actions run.

#### Directional surface tint

Profiles now support an optional `directional_tint` with axis, sRGB color,
strength (0..1) and sharpness (0.1..8). The finite nonzero axis is normalized;
the renderer transforms shading normals from world to object space, normalizes,
then uses `strength * max(dot(normal, axis), 0)^sharpness` to mix the tint over
existing pigment. The axis uses Blender local Z-up coordinates, not source
recipe Y-up. This object-relative baked coloration follows later placements,
not a global weather direction. No camera or scene light enters the mask.
Implementation follows Blender's documented
[normal-space conversion](https://docs.blender.org/manual/en/4.2/render/shader_nodes/vector/transform.html).

This is a slope/direction mask only: it does NOT detect occluded recesses,
curvature, thin edges, heat transfer or actual exposure. Broader weathering and
convincing browning still require those missing controls. Current pastry uses
local +Z, strength 0.65 and sharpness 2; unchanged geometry/fruit/noise provide
the comparison. Actual render shows only a modest change, not the substantial
artistic improvement still required. No final-art approval.

Evidence under the existing review root: `blender-directional-001` reference
render and saved-scene check passed in 24.20 s with sampled RAM 1,149,054,976
bytes. `baked-directional-001` complete export/reimport/render passed in 18.14 s
with sampled RAM 699,596,800 bytes; 61 instances, 11 unique meshes, all 71,376
unique triangles unchanged. Profile metadata and embedded textures survive.
Actual exported render inspected. Ten profile tests and eight geometry-audit
tests pass; Python syntax check passes. These checks do not certify arbitrary
nonuniform/negative-scale source graphs, quantitative image parity or engine
appearance. Hidden CPU/two-thread runs use the existing resource watchdog;
no VRAM certification, Godot restart, paid generation, push or Actions run.

#### Surface-area texture budget (supersedes uniform 512 allocation)

`texture_budget.py` is the deterministic allocation owner used by the existing
baker. It selects 128/256/512-square textures from the maximum transformed
triangle surface area of each shared mesh's placements. Repeated instances
do not multiply texture allocation. World triangle area is measured directly,
without assuming uniform scale. The planner defaults to 1024 texels/metre and
a heuristic 2x area allowance for UV packing; actual occupancy is not measured.

The default 32 MiB assembly budget counts three uncompressed RGBA8 maps per
mesh with full mip chains. If needed, the planner halves the most overprovided
current density first, using stable name tie-breaking. It rejects budgets
that cannot fit minimum sizes, invalid areas, non-finite values and oversized
requests. Function-level budget/density parameters are available; there is no
new UI/CLI override yet. This is not a whole-scene VRAM cap: geometry, render
targets, driver/engine allocations and source-side Blender images are excluded.
Meshes hitting 512 are density-capped; camera coverage and hero-asset needs
are not inferred. Source triangle tessellation is unchanged.

On the exact preceding directional-tint reference, `baked-budget-001` and
`baked-budget-002` produced byte-identical GLBs (SHA-256
`3db33fb8809fa2035f42e1ce36ef32d76aa096bb4091159af39bfb94f230f6c9`).
Crust/filling/plate retain 512 maps, six lattice meshes receive 256, and
fruit/crimp receive 128. Estimated texture residency drops from 46,137,300
to 19,398,612 bytes; GLB size from 5,282,872 to 4,044,380 bytes. Reimported
image dimensions are checked against the plan, alongside existing complete
geometry, placements, material/profile and mesh reuse checks.
Final run: 12.12 seconds, sampled process RAM 647,487,488 bytes, hidden
BelowNormal CPU/two threads with existing watchdog. Not a controlled speed
benchmark or measured VRAM result.

Five planner tests, ten profile tests, eight binary geometry tests and syntax
checks passed. Reimported 640x512 assembly image inspected with unchanged
camera/materials/lighting: no obvious degradation at that framing, but extreme
close-up parity and smaller-mip seam behavior are not certified. Food art is
still unapproved. The game-art pipeline comparison kept allocation as the only
visual variable. No paid generation, Godot restart, remote push or Actions run.

#### Portable provenance and admission record

The exported assembly root now also carries `scene_forge_asset_manifest`, a
versioned JSON string containing SHA-256 of the input Blender file, canonical
recipe string, saved reference-profile string and exporter/auditor/planner
sources. It records Blender version, mesh/instance counts, the full texture
allocation plan and known export losses. Local filesystem paths are omitted.
The input and tool hashes are rechecked at completion to detect changes during
the run. Hashes provide traceability, not signatures or publisher identity.

Admission is explicitly `review-candidate`; engine validation is `not_run`.
Asset license is not inferred from the GPL generator. Memory scope explicitly
excludes geometry and engine overhead. The same record is preserved in the
external receipt, but travels inside the GLB so consumers need not locate that
receipt. It does not claim art approval, verified VRAM, external asset rights,
or a successful engine import. No consumer-specific integration is claimed.

The existing binary reader extracts exactly one record from a scene-root node,
bounds its encoded size to 64 KiB and validates version, current admission state
and the three source hash fields. Other fields are compared against the full
expected manifest during our export; this reader is not a complete general
schema validator for arbitrary third-party texture plans. Native Blender
reimport must retain the exact manifest string on exactly one object.

`baked-manifest-001` under the existing review root passed the full 61-instance,
11-mesh export/reimport/geometry/material/texture checks in 12.10 seconds,
sampled process RAM 640,790,528 bytes; hidden CPU/two threads with existing
watchdog. The manifest adds 2,168 bytes to the previous GLB. Nine binary-audit
tests (including root/duplicate/admission cases), five planner tests, ten profile
tests and syntax checks pass. No Godot restart, paid generation, push or Actions.

#### Error-bounded circular tessellation

Rust `lathe_spline` now optionally accepts `radial_tolerance` in local metres.
Without it, `segments` retains its exact legacy meaning. With it, `segments`
is a hard cap and the compiler chooses the smallest integer n from 3..cap
satisfying `2*r*sin(pi/(2*n))^2 <= radial_tolerance`. Maximum radius among the
Bezier control points bounds the meridian's radius. The stable sagitta form
avoids subtracting nearly equal cosine values. Cap/invalid-budget failures are
errors, not silent quality reduction. Fluted profiles reject this option:
circular sagitta does not bound their additional radial oscillations.

This bounds circular-ring chord error only, separately from existing meridian
profile tolerance. It does not certify total triangulated surface, normal,
screen-space or world-space error after instance scaling. It does not simplify
an already exported mesh or discard the editable spline. Artist opt-in and
render review remain required; this is not a blanket polygon-reduction policy.

The canonical patisserie fixture opts in for only plate/crust/filling at
0.0003 m. Triangle counts: plate 14,016 -> 7,738; crust 19,392 -> 9,696;
filling 9,984 -> 4,680. These reduce the corresponding 11-mesh pie set from
71,376 to 50,098 unique triangles (about 29.8%); other parts retain their
authored tessellation. New authoring field survives canonical recipe storage.

CPU receipt `20260906-152000-0d5661e97d564e389bd9fa2333de4802` passed 59 Rust
tests, strict clippy, formatting, release build, deterministic fixtures and
independent connectivity checks across all 38 stages. New tests check minimal
segment choice and reject impossible/non-finite budgets. The same receipt's
`blender-radial-001` rendered the complete 92-instance/18-mesh cake-and-pie
fixture and reloaded its source successfully: 22.20 seconds, sampled process
RAM 1,215,307,776 bytes, hidden CPU/two threads under the existing watchdog.
Actual image inspected: silhouettes remain smooth at that framing, but no
matched-camera pixel-error certification or final food-art approval. This
geometry checkpoint has not yet been rebaked/revalidated in Godot or Unity.
No paid generation, Godot restart, push or Actions run.

#### Full patisserie portable-export verification

The reduced-radial geometry has now passed the complete Blender bake/GLB
path, not just the source reference renderer. Evidence is `baked-full-001`
inside `20260906-152000-0d5661e97d564e389bd9fa2333de4802`.
This is the full 92-instance cake/board/pie assembly, not the earlier pie-only
61-instance subset. All 18 unique meshes and 109,822 unique triangles passed
independent oriented-surface comparison. Native import retained all placements,
shared resources, planned texture dimensions, recipe and asset manifest.
GLB size is 5,748,796 bytes, SHA-256
`cdd0e08dec5e3e58bb675a8f795e3055dc7dfa88552a79adc919c8a24ce0a271`.

This batch exercised actual budget reductions: six lattice textures dropped
from requested 256 to 128, and pie filling from 512 to 256. Final estimated
texture mip allocation is 33,030,072 bytes, within the 33,554,432-byte budget.
No triangle decimation or source material changes occurred during export.
The actual native-reimport render was inspected: overall composition is intact;
the darker portable lighting and omitted scattering are not reference parity.
Fine texture/close-up equivalence and Godot/Unity behavior remain unverified.
The cake and pastry still do not meet final-art quality.

Hidden BelowNormal CPU/two-thread export/reimport/render took 18.14 seconds,
sampled process RAM 718,684,160 bytes, under the existing watchdog. No measured
VRAM claim. Added an actual-definition regression test proving the opt-in
reduces the emitted mesh, omitted options serialize as absent for legacy
recipes, and fluted definitions reject the unsupported bound. CPU receipt
`20260906-152535-9fbb1cac6b7243378a6f9c9b44987fe4` passes all 38 stages with
60 Rust tests; all 24 Python tests also pass. No Godot restart, paid generation,
push or Actions run.

#### Godot portable metadata integration

The existing Godot adapter now has `build_portable(path)` alongside compiled
JSON construction. It delegates GLB parsing to GLTFDocument, copies only
Scene Forge metadata fields, promotes source/manifest onto its returned root,
and rejects missing/ambiguous source records. The editor plugin exposes an
explicit review-asset GLB import button using the shared undoable attachment
path and existing source-export interaction. Editor interaction itself has not
been exercised; importing arbitrary untrusted GLB dependencies is not certified
as sandboxed. The file-size gate is 64 MiB, not a total decode-memory bound.

Native Godot 4.7.2 diagnostics exposed invalidated mesh-node mappings after
generation. Cache engine-assigned names before generation; use its node lookup
when valid and otherwise require exactly one matching assigned name. Never
infer identity from position or mesh proximity. A generic generated root is
wrapped when needed. Missing mappings fail rather than dropping metadata.
The failed diagnostics are retained in the preceding CPU review directory;
one failed mapping experiment exited with leaked dummy-renderer resources,
which did not persist after its process exited. The final diagnostic exits
cleanly with no stderr findings.

`godot/test_portable.gd` is a headless scene-tree/source diagnostic, NOT a
rendering, GPU mesh-buffer, saved PackedScene or appearance certification.
On `baked-full-001/asset.glb`, final `godot-map-cached.log` reports
`SCENE_FORGE_PORTABLE_METADATA_PASS instances=92 graphics=not_run` with exit 0.
It checks unique source IDs across all 92 mesh placements and recipe SHA-256.
Tests run in short hidden headless processes; no preview replacement occurred.
Existing preview processes 30828 and 612 remained responsive after diagnostics.
Godot rendered appearance/package persistence, UI interaction, Unity and 8 GB
VRAM certification remain pending. No paid generation, push or Actions run.

#### Embedded-only Godot portable preflight

The portable adapter now validates the bytes before invoking GLTFDocument.
It requires a v2 GLB with exact file/chunk lengths, one JSON chunk (at most
24 MiB), one embedded binary chunk, one buffer with consistent declared size,
and no `uri` key anywhere in the parsed JSON. Recursive checking rejects nesting
beyond 64. Declared extension lists are limited to the material/texture
extensions emitted by this exporter. Native parsing consumes the same validated
buffer with an empty base path; it no longer reopens the input file afterward.
This avoids a file-replacement race and refuses external buffer/image references.

This is a conservative format preflight, NOT a complete glTF validator, decoder
sandbox, decompressed-image memory limit or arbitrary third-party asset safety
certificate. The existing file-size bound does not bound decoder allocations.
The intended input remains our reviewed embedded Scene Forge output; even
otherwise harmless URI metadata is rejected by this narrow contract.

Headless `test_portable.gd` now checks valid input, malformed/truncated GLB,
wrong format version and an injected external-buffer URI before running the
92-placement/source-hash test. It also compiles the editor plugin script without
opening the editor. `godot-preflight-final.log` in the preceding review directory
reports the metadata pass and exit 0 with empty stderr. No graphical scene,
saved-package, GUI interaction or Unity validation claim. Existing preview
processes were not replaced; no paid generation, push or Actions run.

#### Godot package persistence and stable node mapping

`test_portable.gd` now accepts an optional fresh `.scn` output path. It refuses
overwrite, requires available nonempty mesh arrays, assigns scene ownership,
saves a PackedScene, reloads with cache bypass and compares all 92 placements.
Snapshots include full mesh surface arrays, accumulated transforms, source IDs,
recipe/manifest strings, unique mesh count, selected material properties
(albedo, roughness, metallic, clearcoat and normal settings), and texture
dimensions/format/mipmap state/SHA-256 for albedo, normal, roughness and metallic
images. This is exact stored-data comparison, not visual rendering equivalence
or complete coverage of every possible material property.

A repeat run exposed stale-but-non-null Godot node references. The previous
conditional fallback strategy is superseded: never read post-conversion
`get_scene_node` pointers. All mapping now uses cached engine-assigned names
and requires exactly one match. The earlier metadata pass alone was not enough
to establish repeat reliability. This fixes the observed intermittent missing
source IDs rather than tolerating missing metadata.

Final `godot-package-final.log` in the `20260906-152000-...` review directory
reports metadata PASS, package PASS with material pixels checked, and two
additional same-process imports PASS. Output `portable-godot-004.scn` retains
18 shared meshes for all 92 placements. Exit 0, empty stderr; sampled process
RAM 131,141,632 bytes under the 1 GiB/30-second hidden BelowNormal diagnostic
guard. No graphics backend was exercised. This portable ArrayMesh path retained
its CPU buffers headlessly; it does not overturn the historical dummy-backend
MultiMesh buffer gate in the separate compiled-JSON path.

Fresh-process package loading is now verified by the same script's third
argument `--verify-package`: load the trusted saved package before importing
the source GLB, reject declared external dependencies, then compare its complete
snapshot against a fresh source import. `godot-cold-final.log` reports cold
PASS for `portable-godot-004.scn` and the full 92-instance source; stderr is empty.
The deliberately mismatched pie-only source versus full package reports cold
FAIL and exits 1 (`godot-cold-mismatch.log`). This is a regression diagnostic
for our generated packages, not a sandbox for untrusted native scenes.

Rendered Godot appearance, UI interaction, Unity and measured VRAM remain
unverified. Existing previews were not replaced;
no paid generation, push or Actions run.

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

The compiler subdivides wall spans into jamb, sill and lintel volumes using
shared min/max coordinates. It builds a bounded rectilinear occupancy grid on
all construction boundaries and emits only faces between occupied and empty
cells. Shared internal faces disappear, and every neighboring surface uses
the same face subdivisions. This **supersedes the disconnected box-mesh
concatenation** that left coincident faces and invalid shared-edge connectivity.
It is an exact axis-aligned room-boundary construction, not a general triangle
Boolean or tolerance-based weld. There is no voxel-resolution approximation:
grid lines occur at authored boundaries. Interior clearance remains empty.
Wall construction partitions horizontal slabs at aperture endpoints and removes
their sorted vertical aperture intervals. Vertically stacked openings, including
unequal widths and offset transoms, are supported. This supersedes the old
horizontal-span-only rejection. True rectangular-area overlaps are rejected;
shared edges merge geometrically while retaining separate authored descriptors.
Corner-only aperture contact is rejected because it makes a non-manifold material
edge. Out-of-bounds cuts, precision-collapsed openings and invalid dimensions fail
rather than being silently moved. The existing common boundary mesher remains
the only triangulation path; there is no second wall implementation.

Stacked-opening verification: local receipt
`procedural/generated/reviews/20260906-124403-6b748b11c49f4b6c9d19c45c527064c5/report.json`
passed 48 Rust tests and the CPU fixture/audit workflow. Tests cover material
volume, all four wall orientations, descriptor positions, shared edges, actual
overlaps and rejected corner-only contact. The five-opening example includes two
offset/stacked transoms; its 992 triangles form one closed oriented position graph
with zero reported connectivity defects. This new room variant has not received
a native visual or saved-engine reload review; the live teapot was left running.

Room geometry respects the existing vertex allocation budget. Repeated rooms
reuse their definition mesh. The 17,000-instance test demonstrates reuse and
budget enforcement only, not 17,000 distinct room designs, city rendering speed,
or measured VRAM. Roofs, material differentiation, trim, collision,
MUD adapter integration and final art admission remain subsequent work.

The occupancy grid is capped at 262,144 cells before allocation; boundary faces
are counted against the vertex budget before triangle allocation. Construction
cells collapsed by output precision are refused. Dense valid opening layouts
can exceed this grid cap and receive a diagnostic rather than unbounded work.
The conforming subdivisions can increase triangle counts; they are not mesh
decimation. Room UVs now use continuous planar coordinates with one UV unit per
definition-space metre, instead of restarting the texture on every triangle.
Wall V follows height; north/south U follows signed X and east/west U follows
signed Z so the exterior-facing mapping is consistently oriented. Horizontal
faces use X/Z. This preserves texture scale and continuity across coplanar
construction subdivisions. It does not unwrap continuously around corners;
UVs intentionally exceed 0..1 and require repeating material textures. Instance
scaling also scales the pattern: this is not world-space triplanar texturing.
These coordinates are a material foundation, not finished room art.
General self-intersection validation and new engine renders remain
outstanding.

The connectivity audit now enforces closed oriented graphs for source-declared
`room` shapes. It fails the CPU run on a regression while retaining the report.
This shape-specific gate does not promote other meshes to certified solids.

Corrected-boundary receipt:
`procedural/generated/reviews/20260906-122748-617c1f275457457eb45294ebbaaed12c/report.json`:
45 Rust tests, six audit tests and the 32-stage CPU pipeline passed. All 40
fixture mesh definitions now pass the closed oriented exact-position graph
check. Both room meshes have one component and zero boundary/excess-incidence
edges, winding conflicts or failed closed vertex fans. Their opening descriptors
are unchanged. Material-volume and excessive-grid/precision-collapse tests pass.
The new gate rejects the retained pre-fix `rooms.json` with exit 1, identifying
`room_shell`, so the original defect is a verified failing case.
The revised room fixture has 520 triangles and 944 render vertices; the simpler
transformed shell has 192 triangles and 366 render vertices. Neither has been
rendered or engine-reloaded in this pass. Teapot Boolean joins are still absent.

Continuous-UV follow-up receipt:
`procedural/generated/reviews/20260906-123121-c3bd93acdf3147719a9f3238033bbe30/report.json`:
46 Rust tests, six audit tests and all 32 CPU stages passed. Tests compare
geometric and UV edge lengths, upright wall mapping and shared-vertex UV values.
Independent comparison of all nine fixtures confirms unchanged triangle-corner
positions/normals, placements and apertures. Consistent UVs let exact indexing
reduce the room fixture from 944 to 440 render vertices (still 520 triangles)
and the transformed shell from 366 to 186 (still 192 triangles). GPU memory,
engine texture appearance and final material quality were not measured/reviewed.

Historical initial box-concatenation validation: eleven Rust tests passed, including aperture-side
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
its own revision, dependency and GPL-compatibility license audit.

| Work | Relevant method | Decision for this builder |
| --- | --- | --- |
| [Infinigen Indoors, CVPR 2024](https://arxiv.org/abs/2406.11824) | Procedural assets plus a constraint language and arrangement solver | Adopt the separation of construction operators, relationships and placement objectives. Current rectangular shells and greedy placement are only a foundation; no equivalent general solver is implemented. |
| [Design for Descent, SIGGRAPH Asia 2025](https://www.computationaldesign.group/assets/papers/SIGA-2025-D4Descent.pdf) | Structural grammar rewrites interleaved with continuous parameter optimization | Candidate: make bays, roof spans and facade subdivisions explicit, then optimize dimensions without discarding structure. Not implemented. The paper is CC BY-NC; reading its ideas is not permission to copy its code or assets into our permissive distribution. |
| [Procedural Scene Programs, October 2025](https://arxiv.org/abs/2510.16147) | Dependent object-placement programs with search-based error repair | Candidate: place structure, then supports, then supported props; repair overlap and circulation failures while preserving description constraints. The paper uses an LLM for initial programs; its repair method does not require an LLM call at every correction. Our runtime must not depend on paid inference. |
| [Sceniris, December 2025](https://arxiv.org/abs/2512.16896) | Batch sampling, cached representations and accelerated collision checks | High priority: batch candidate evaluation and cache invariant geometry rather than re-running individual object workflows. Its reported 234x improvement uses its own baseline and GPU collision system; it is not our speedup and does not establish an 8 GB fit. |
| [Procedural Content Metageneration, August 18 2026](https://arxiv.org/abs/2608.17947) | Search over generators; reusable abstractions extracted from strong programs | Candidate: promote repeatedly successful construction rules into tested shared operators. This is evidence from game-level generation, not proof of detailed 3D fantasy architecture; do not import its inference costs or claim its method is already running here. |
| [4DSynth, August 27 2026 preprint](https://arxiv.org/abs/2608.26947) | Multiple inputs converge on one editable geometry-grounded scene representation | Architectural reference: source prose, graph bindings and authored constraints should converge on the same recipe representation. Its actor animation and simulation work is outside our current static scenery milestone. |
| [Infinigen-Sim, May 2025](https://arxiv.org/abs/2505.10755) | Procedural articulated assets with joint annotations | Later scenery work: hinges, shutters, gates, cranes and ferries need explicit pivots and parts even before animation. Not a replacement for Pirate Island's character workflow. |

### Hero-asset research and acceptance sequence (2026-09-06)

Current user direction: read the actual methods before further construction.
Make a gorgeous teapot first, then pass cake **and** pie tests, then a ballerina
test. These are generator capability gates, not permission to hand-author a
separate one-off runtime for each object. None has passed. Existing primitive
fixtures and painted vessels remain technical diagnostics, not the quality bar.

#### Reading that changes the implementation plan

- [Wang et al., Computation of Rotation Minimizing Frames](https://www.cs.hku.hk/data/techreps/document/TR-2007-07.pdf): read the authors' technical-report version, especially sections 4.1, 4.3, 4.4 and Table 1. Double reflection transports the cross-section frame along a curve without arbitrary tangent-axis spin. The report explicitly identifies coincident samples and degenerate second reflections. **Decision:** use this as the basis for a general 3D sweep, with bounded resampling and explicit failure diagnostics; not a planar-only teapot tube. No source code copied; implementation pending.
- [Niessner et al., Feature Adaptive GPU Rendering of Catmull-Clark Subdivision Surfaces](https://www.niessnerlab.org/papers/2012/3feature/niessner2012feature.pdf): read subdivision rules, semi-sharp feature handling and the adaptive-patching architecture in sections 1 and 3. Crease tags preserve designed edges while local refinement avoids indiscriminate subdivision. **Decision:** retain editable surface structure and crease intent; evaluate CPU-baked meshes/LODs first for both engines. This is not a claim to have implemented their GPU evaluator, watertight patch scheme, or reported performance. Remaining detailed evaluator work must be read before implementing it.
- [Applying Painterly Concepts in a CG Film — Bolt](https://media.disneyanimation.com/uploads/production/publication_asset/64/asset/painterlyCgConcepts.pdf): read the production note's massing, painting-LOD, raypainting and painterly-normal discussion. **Decision:** preserve readable broad values and controlled edges before adding texture marks; separate broad color, ornament and fine finish layers. Random color noise alone does not satisfy the painterly target. This note describes production concepts, not a turnkey open-source shader.
- [ProcFunc, April 2026](https://arxiv.org/html/2604.26943v1): read sections 3 and 4, including the actual benchmark setting and limitations. Explicit function inputs/outputs, separate deterministic generators and samplers, and traceable composition directly inform our editable recipe contract. **Decision:** make construction, material masks and decoration independently composable; expose parameters and intermediate results. Its CPU scene-construction measurements are not game frame rates, and its RAM figures do not certify our 8 GB VRAM target. Blender dependency and code licenses require inspection before any reuse; no dependency has been adopted.

These supplement the scene-layout research above. They do not substitute for
art direction. New publications are useful where they solve our problem;
older established surface mathematics is still appropriate where it does.
No paper, figure, research asset, weights or third-party implementation has
been redistributed by this checkpoint.

#### Teapot: precision and designed curvature

Proposed first art direction: a graceful fantasy ceramic service piece, deep
blue-green glaze, warm ivory accents and restrained aged-gold ornament. This
palette is a proposal, not a new user-approved reference. Shape must remain
beautiful in clay shading without ornament. Start at plausible tabletop scale,
approximately 0.30 m overall width; store units and all dimensions explicitly.

Required capabilities and inspections:

1. A continuous, intentionally shaped belly/shoulder/neck profile, not a stack
   of obvious straight conical bands disguised by interpolated normals.
2. A fitted removable lid with seating lip, visible clearance, designed knob
   and underside. A hollow vessel and a genuinely open spout with wall thickness.
3. A tapered rising spout and graceful handle with comfortable negative space,
   deliberate attachment regions and finished transitions. Intersecting tubes
   are not automatically accepted as joined ceramic. A visible inner blockage
   fails the functional geometry review.
4. Deliberate foot, rim and decorative hierarchy. No uniform edge softening,
   random dents, arbitrary excessive ornament, or noise covering weak shape.
5. Distinct ceramic, glaze and metal response. Assess highlights under neutral
   light before flattering light; a wet-plastic appearance fails material review.

Reusable implementation order: smooth editable curves and derivatives; stable
sweep frames and variable sections; thickness/rim/attachment construction;
controlled surface refinement; layered materials and ornament masks. Preserve
the current mesh/export owner and extend it; do not build a separate teapot mesh
engine. A sweep alone cannot solve blended surface junctions.

Numerical acceptance must include finite derivatives, nonzero tangents,
right-handed orthonormal frames, seam continuity, outward normals, meaningful
wall thickness and measured clearance. Test straight paths, inflections, strong
curvature, repeated samples and reversed traversal. Reject unresolved
self-intersections rather than silently emitting a corrupt surface. Surface
sampling must have explicit error limits and allocation/depth caps; reaching a
cap is a diagnostic, not permission to misreport tolerance compliance.

#### Cake and pie: soft construction and material differentiation

Both must pass after the teapot; recoloring the teapot operator is not the test.
The cake should show a cut slice: sponge, filling and icing must remain distinct,
with controlled pores, rounded piping, believable layer contact and a designed
decoration pattern. The pie should show a crimped crust, a filled cut section and
an interwoven lattice with actual over/under relationships, plus restrained
browning variation. Avoid stone-like cake, plastic frosting and rope-like pastry.

Build these from reusable sectioning, sweep/profile, pattern, contact and material
operators. Keep cut surfaces intentional and bounded, not random mesh damage.
The food should look appealing as a complete composition and remain readable
at game distance; pore count alone is not a quality measure.

#### Ballerina: anatomy, cloth and graceful pose

Later coordinated integration test with the existing Pirate Island/shared
character workshop, not a competing anatomy, rigging or garment system. Start
with an adult stylized dancer in a static, anatomically credible ballet pose.
Assess line of action, balance/support, hands and feet, joint shapes, face,
costume construction, layered skirt silhouette and intersections from front,
side and rear. Rig readiness is required; an animation suite is a later gate,
not implicitly certified by a still image. Read the relevant anatomy/deformation
and cloth methods with that workflow before implementing this stage.

#### Common evidence contract

Every candidate must expose stable semantic part identifiers (body, lid, spout,
handle, etc.), source recipe location, parameters/ranges/units, evaluated bounds,
surface and attachment frames, material assignments, seeds, dependency hashes,
resource counts and actionable constraint failures. Existing recipe pointers
are useful but are not stable IDs across structural edits. Do not claim the
full contract is implemented merely because the JSON contains a mesh name.

Review a fixed camera set: front, side, rear, three-quarter, silhouette/clay,
material close-up, and intended gameplay scale. Include a lid-off/cutaway view
where needed to expose construction rather than conceal it. Record exact recipe,
lighting, camera, build hash and images. Compare revisions under identical light.
Use a small deterministic variation batch to expose brittle special cases only
after one authored design meets the visual target.

Track four separate states: numerical correctness, visual acceptance, native
engine roundtrip, and performance measurement. No average score can compensate
for a failed state. Profile actual GPU memory, frame time and loading behavior;
estimated mesh bytes are not VRAM usage. User-visible review must show the real
engine render, not a generated concept image standing in for implemented work.

### What is actually implemented

#### Curved construction checkpoint: teapot candidate, not admitted art

The Rust core now implements cubic `sweep` and `lathe_spline` shapes. Both use
one adaptive cubic sampler; the spline lathe delegates tessellation to the
existing lathe implementation. This is not Catmull-Clark subdivision. Sweeps use
double-reflection frames, variable circular radii, corrected taper normals,
continuous longitudinal UVs and optional inner walls with annular end faces.
All generation is CPU-side and dependency-free beyond the existing Rust stack.

Sweep authoring format:

```json
{"kind":"sweep","sweep":{
  "spans":[[[0,0,0,0.01],[0,0.03,0,0.01],[0.02,0.06,0,0.008],[0.04,0.07,0,0.006]]],
  "sides":48,"tolerance":0.00005,"wall_thickness":0.001
}}
```

Each control point is `[x,y,z,radius]` in metres. Connected spans must match
position/radius and tangent/radius slope. `lathe_spline` takes a `profile` array
of cubic spans with `[radius,height]` controls, plus `segments` and `tolerance`.
Ordinary lathe meridians may now return downward to construct inner walls;
crossings and nonadjacent contacts are rejected. Ordered profiles determine
winding. Existing ascending profiles remain compatible.

Sweeps also accept `section_scale: [a,b]` (each 0.125..8, default `[1,1]`)
and `section_roll` (degrees -360..360, default zero). These provide an elliptical
cross-section in the transported normal/binormal plane and a constant initial
orientation. Roll does not add progressive twisting. Optional `section_normal`
provides a definition-local author-controlled direction: normalize it, project
it perpendicular to the initial tangent, normalize the projection, then apply
`section_roll`. Direction magnitude is not a width control. A zero/nonfinite
direction or projection with squared length below `1e-12` fails explicitly;
the tool does not silently replace an invalid authored direction.

When `section_normal` is absent, the legacy initial frame projects world X
perpendicular to the initial tangent, except when `abs(tangent.x) >= 0.8`, where
world Y is used. This automatic choice can reverse the frame as an edit crosses
that threshold. Authored directions remove this particular discontinuity as
long as they remain sufficiently nonparallel to the tangent. They do not solve
closed-loop frame holonomy or define an absolute orientation everywhere in a
changing 3D curve. An explicit `[1,0,0]` on the current teapot handle preserves
its existing geometry while stabilizing that editing choice.

Authored-frame CPU receipt:
`procedural/generated/reviews/20260906-120046-a986ec3bf5744f92a054000cc1fd7940/report.json`:
41 tests, format, strict clippy, release and nine deterministic fixtures passed.
The regression reproduces the automatic-frame reversal across the 0.8 threshold
and verifies continuous authored frames, perpendicular/unit axes, projected
direction plus roll, invalid-direction refusal and recipe roundtrip. All nine
emitted fixture files remain byte-identical to the elliptical-section checkpoint.
This is an authoring-control improvement, not a new visual render or art admission.

Construction uses the existing [Wang et al. double-reflection frame transport](https://www.cs.hku.hk/data/techreps/document/TR-2007-07.pdf),
not a second sweep implementation. The ellipse and shading extension is original
analytic geometry, not a claim from that paper. In the following, `r` is the
current outer radius or `radius - wall_thickness` for the bore, `r_prime` is its
arc-length derivative, and `k` is the sampled tangent derivative:

```text
radial = a*cos(theta)*frame_normal + b*sin(theta)*frame_binormal
gradient = cos(theta)/a*frame_normal + sin(theta)/b*frame_binormal
position = spine_position + r*radial
normal = normalize((1 - r*dot(k, radial))*gradient - r_prime*tangent)
if inner_surface: normal = -normal
```

This is the cross-product normal for an ideal rotation-minimizing frame with
fixed semiaxis multipliers; implementation curvature remains sampled. A radial
normal would be incorrect for the ellipse. Hollow sections apply wall thickness
**before affine scaling**: axis thicknesses are `a*wall_thickness` and
`b*wall_thickness`, not a constant surface-normal thickness around the ellipse.
Both annular ends and caps follow the same scaled rings. UV U remains normalized
section angle, not ellipse arc length. Wider sections tighten the spine sampler
tolerance and use the maximum semiaxis in the conservative local folding guard.
These measures still do not certify global self-intersection or shading error.

The current teapot handle uses `[1.45,0.65]` to make a flattened oval metal band
instead of circular wire. This is an unrendered construction candidate under
the CPU-only shared-machine workflow. The saved PNG below predates this change;
do not use it as visual approval of the new handle. No extra triangles are
required per ring; adaptive refinement may increase ring count.

CPU receipt: `procedural/generated/reviews/20260906-115635-879c15bf77c74af2b3e86e290fdfeb05/report.json`.
39 tests, format, strict clippy, release and nine deterministic fixtures passed.
Tests cover closed solid/hollow ellipse meshes, outward unit normals, tapered
normals against the independent implicit-surface gradient, 0/90-degree extents,
invalid controls and omitted-field compatibility. Independent previous-output
comparison found eight fixtures and six teapot parts unchanged; the handle's
placement/source stayed fixed while its bounds updated. Handle output remains
3,237 indexed vertices and 6,000 triangles. Godot/Unity execution, a new render
and VRAM measurement are not run for this checkpoint.

The tolerance bounds control-hull deviation from each accepted 4D chord
(position plus radius), not complete mesh, shading, or screen-space error.
Angular checks and a positive derivative-projection test reject hidden cusps.
Sampling is capped at 12 subdivision levels, 64 spans, 8192 sweep samples or
512 lathe samples, additionally constrained by the vertex budget. Caps fail
explicitly. A local curvature/radius check rejects sampled folding; **global
sweep self-intersection, complete solid validity and exact junction booleans
are not certified**. Rim UVs remain simple diagnostic islands.

`procedural/examples/teapot.json` is the first authored construction candidate:
seven named parts, hollow body, fitted lid, finial, swept handle and hollow
spout, foot and lid trim. It is not a separate mesh generator. Current remaining
defects include the uncut body beneath the spout, unblended attachments and
unfinished rim treatment. The next paint checkpoint introduces authored
botanical marks, borders and a quieter glaze; this does not remedy solid
construction or establish final artistic quality. No
functional-pouring or high-end-art claim is made. This checkpoint does not pass
the engineering teapot gate; cake/pie and ballerina work had not started at that
checkpoint.

**Live review update, 6 September 2026:** the user described the current native
teapot preview as "fantastic teapot". Preserve its silhouette, teal glaze, gold
accents and botanical decoration as the accepted visual direction for subsequent
cake/pie studies. This positive visual response supersedes the earlier lack of a
user-endorsed aesthetic anchor; it does not certify the uncut body/spout junction,
attachment blending, watertight assembly, Unity parity or final production status.
The live version-2 import passed seven-part mesh, transform and bounds checks.
Its retained local capture is
`procedural/generated/reviews/20260906-123121-c3bd93acdf3147719a9f3238033bbe30/live-teapot.png`.
The existing Godot test/review entry point accepts `--keep-open` after its input,
output and two camera-angle arguments for explicitly requested live inspection;
it caps the retained preview at 12 FPS. Normal checks still exit. The CPU runner
still never launches Godot. Do not restart or touch another task's engine session.

For sequential review in that same process, the existing entry point now accepts
`--watch-request=<absolute mailbox.json path>` together with `--keep-open` and
the existing positional input, output and camera-angle arguments. The mailbox
is a local JSON file, not a socket, service or world server. Place it in the
generated review directory containing the study inputs. A request has this form:

```json
{"sequence":"pastry-front-001","input":"C:/review/patisserie.json","output":"C:/review/pastry-front-001.png","azimuth":45,"elevation":25}
```

Paths above are illustrative, not repository paths. Both input and output must
resolve lexically beneath the mailbox directory; output must be a new PNG.
Use a different capture name for every review. The one-second poll ignores
unchanged mailbox bytes and never queues concurrent imports. Limits: 4 KiB
request, 32 MiB compiled JSON, 128 mesh definitions, 1,000 instances and a 64 MiB
compiler payload estimate. These caps are review admission limits, not a hard
OS RAM/VRAM quota or an untrusted-file security sandbox. Feed it compiler outputs,
not arbitrary external JSON; deep mesh validity remains the compiler's contract.

On an admitted request, the tool frees only its previous study nodes, retains
the process and polling timer, then uses the existing full import-check and
capture path. No second renderer or adapter is introduced. Invalid request
headers leave the current study in place; an import assertion is a failed review,
never evidence of success. Wait for the log's `Review ready` JSON containing the
matching sequence, input, capture and unchanged process ID, then inspect the PNG.
The old running preview cannot acquire this code without one replacement; that
replacement was requested from the user, not assumed from an automatic goal turn.
Headless `--check-only` passed for the modified script. Sequential graphics-backed
switching was initially unexecuted. After explicit user approval, native startup
exposed a Timer started before tree entry. It now uses autostart. One corrective
restart was needed; subsequent material revisions loaded in the same PID 30828.
Matching `Review ready` log entries and actual captures verify sequential scene
switching. This supersedes the pending-switch status, but does not certify
long-run memory stability or a hard VRAM limit.

The same script has a headless `--test-review-requests` mode. It executes the
actual request/header admission functions without constructing a scene or
starting the mailbox timer. Native execution passed 37 rejected-request cases,
nine invalid payload estimates, oversized mesh/instance cases and valid/default
admission. Checks reject arrays, objects, nulls and booleans in numeric fields,
non-finite or negative payload estimates, path traversal and sibling-directory
prefix collisions before numeric conversions or imports. Input/output/sequence
are required nonempty strings. Accepted imports consume the parsed snapshot,
not a second file read after admission. Captures check for an existing output
again after rendering; this is not an atomic filesystem reservation against
another writer. The tests establish request admission behavior only, not live
graphics switching, safe arbitrary third-party meshes or an OS memory quota.
Local native-test log: `procedural/generated/reviews/20260906-125338-e44dd4bf0e854f28a090f9293035b812/request-tests.log`.

The actual native render below is retained as a construction baseline. The
reviewer found its smooth silhouette useful but finish and attachment quality
insufficient. The Godot diagnostic camera now frames sub-metre objects and
accepts optional azimuth/elevation degrees after the output PNG argument for
repeatable multi-angle inspection using the same import/validation path.

Validation receipt: `procedural/generated/reviews/20260906-111412-397cea53ad9e4cdeb2fad4cb32590e0b/report.json`
(local generated evidence): 34 Rust tests, strict clippy, release build and 41
stages across nine fixtures passed, including deterministic output and native
Godot package reload. Additional 0/180-degree views passed the same import
checks and were visually inspected. Tightened depth range reduced some opening
artifacts but did not establish final shading quality. Unity execution and
actual GPU memory measurements remain outstanding.

![Rust-generated teapot construction baseline in Godot; not finished art](verification/scene-forge-teapot.png)

### Cake and pie construction studies — not art-admitted

`procedural/examples/patisserie.json` is the first editable paired study following
the user's positive teapot response. The material direction is warm sponge and
cream, dark berry filling and teal serving ceramics. All geometry is generated
from the existing spline lathe and framed sweep operators. Fourteen shared mesh
definitions compose 42 instances: two cake sponge layers, filling, rounded icing,
cream dollops and berries around the rim, plus a separate open-crust berry pie
with ten swept pastry ribbons. Both dishes share the same plate definition.

To author circular decoration without manually listing every instance, the
**existing** `repeat` now accepts optional `yaw_step` (radians per copy, default
zero). Copy `i` has local translation `i * step` and Y rotation `i * yaw_step`;
the child's offset is rotated first, then the repeat translation is added, then
the enclosing transform is applied. Example: count 12, zero translation step,
yaw step PI/6 and a child at `[0.105, 0.138, 0]` make a ring. A nonzero vertical
step makes a helical array. Negative angles reverse direction. This does not
deform or duplicate the shared mesh, infer topology, or guarantee collision-free
placement. Definition sharing, bounds and source repeat indices follow the one
existing assembly traversal. Legacy recipes default to zero angular step.

CPU receipt:
`procedural/generated/reviews/20260906-124814-31cb3724d7ec461cb21de8413ecaf1a6/report.json`.
49 Rust tests and the full deterministic fixture workflow passed. The angular
repeat test checks translated/scaled parent composition, quarter-turn positions,
vertical steps, shared geometry, repeat identities and non-finite rejection.
All eleven pastry mesh definitions have closed oriented exact-position graphs;
this does not certify their assembled intersections. The generated definitions
contain 90,404 triangles before instance reuse and the compiler estimates
3,302,264 resident geometry/texture bytes, not measured engine RAM or VRAM.

The original flat-strip lattice is now **superseded by alternating swept ribbons**.
Six reusable definitions cover three lengths and two over/under phases; ten
instances span five rows in each direction. Cubic centre lines have horizontal
tangents at crossings and smooth elevation changes between them. Their authored
upward section frame and `[0.4, 1]` section scales make an elliptical pastry ribbon
6.4 mm thick and 16 mm wide, rather than circular tubing. The current centre-line
heights alternate between 50 and 60 mm. Ends descend to the crust at 52 mm. These
are fully editable sweep controls, not baked model imports or a second mesher.

The new crossing test clips the **actual transformed triangle polygons** of both
ribbons to each overlapping X/Z footprint and computes their vertical envelopes.
All 25 crossings must have the correct alternating over/under ordering and more
than 0.1 mm separating clearance. This is stronger than checking centre lines;
it establishes separation at these fixture crossings, not general self-collision
freedom for arbitrary user-edited sweeps or joins with the filling/crust.

Woven-lattice receipt:
`procedural/generated/reviews/20260906-125338-e44dd4bf0e854f28a090f9293035b812/report.json`.
50 Rust tests, strict clippy, deterministic output and the CPU fixture workflow
passed. All 14 mesh definitions passed the closed-position-graph audit. The
current fixture has 109,472 definition triangles, 42 instances and a compiler
geometry/texture estimate of 3,859,080 bytes; these supersede the preceding
flat-strip counts, not the distinction between estimates and engine measurement.

Outstanding: actual rendered inspection, native saved-output review, fluted
crust, richer piping, cake crumb detail and controlled natural variation. The
ribbons and rotational dollops remain construction studies, not finished pastry.
No artistic gate is passed from CPU checks. The first native pastry review has
now been executed after the user's explicit approval to replace the teapot
preview. It revealed washed-out cream, excessively orange pastry and plastic-like
highlights. Palette values were adjusted first under unchanged camera/lighting.
On the user's subsequent "make it less plastic" request, food roughness was raised
to 0.96 (cream/pastry) and 0.70 (fruit/filling), leaving the ceramic plate unchanged.
Seeded, editable paint marks add restrained baked variation to sponge and crust.
These are albedo marks, not geometric crumb, normal mapping or displacement.
256-pixel textures keep the compiled review input within its 32 MiB cap; a
512-pixel candidate exceeded that cap and was rejected by the running viewer.

Native reviewed capture:
`procedural/generated/reviews/20260906-125338-e44dd4bf0e854f28a090f9293035b812/pastry-matte2.png`.
The same PID 30828 loaded both palette and matte revisions with all 42-instance,
14-mesh native import checks passing. Lighting/camera were held fixed. The finish
is less glossy; perfectly smooth frosting, regular dollops and unfluted crust
still limit its food quality. No production-art approval or native disk package
reload is claimed for this revision.

**Food-shape follow-up:** after the user rejected the matte pass as insufficiently
convincing, a tapered helical sweep was rendered as cream and rejected: its open
coil read as a corkscrew. It is not retained in the recipe. The next construction
study uses seven shared lathe instances per rosette (central body plus six smaller
lobes), a cream layer with a thin jam seam, and 36 shared curved sweep crimps on
the pie rim. An excessively tight crimp was refused by the existing local
curvature guard; its curve was widened before rendering, not admitted with the
guard bypassed. Current local capture:
`procedural/generated/reviews/20260906-125338-e44dd4bf0e854f28a090f9293035b812/pastry-shaped.png`.
This capture was inspected in the same live process. Rosette intersection seams,
uniform frosting, regular rim repetition and insufficient porous sponge detail
remain visible. These are construction findings, not an assertion of convincing
real food or production-art admission. The component rosettes are not Boolean
unions and must not be described as seamless or watertight assemblies.

**Continuous fluting supersedes the intersecting cream lobes.** Both existing
`lathe` and `lathe_spline` shapes accept optional `fluting: {count, depth}`.
For meridian radius r and angle theta, the constructed radius is
`r * (1 + depth * cos(count * theta))`. Count is 2..64, depth is 0..0.4,
and angular sampling must provide at least eight segments per lobe. The positive
radial scale preserves the meridian ordering. This extends the one existing
lathe mesher; spline sampling still feeds that same path. Omission preserves
the original circular section and source format. Bounds are measured from the
resulting geometry, and normal directions account analytically for the angular
derivative, not just the meridian slope. No vertex displacement after shading,
overlapping lobe assembly or new engine shader is required.

The pastry recipe uses six flutes at depth 0.22 and 96 angular segments. Each
cream rosette is now one instance instead of seven intersecting lathe instances.
The exact-position audit reports one component, 11,136 triangles and no collapsed
faces, boundary edges, excess edge incidence, winding conflicts or invalid
vertex fans for `piping.dollop`. This is connectivity evidence, not a general
self-intersection certificate for arbitrary profiles. The conservative sampling
still needs gameplay-distance optimization; do not mistake it for final LOD.

Validation: 51 Rust tests and full CPU fixture workflow passed in
`procedural/generated/reviews/20260906-131937-d0b28adec08b44aca5ecb52127e59d3a/report.json`.
Added tests cover angular tangent/normal orthogonality, unit normals, pole caps,
closing UV seam, radial bounds and rejected parameter/sampling ranges. Actual
native capture `procedural/generated/reviews/20260906-125338-e44dd4bf0e854f28a090f9293035b812/pastry-fluted.png`
was reviewed after same-process reload in PID 30828. It removes the prior visible
rosette joins and reads more like piped cream. Porous sponge, surface irregularity,
crust/filling contacts and less uniform baking remain outstanding; this is not
final food-art admission. Unity execution remains unverified.

Ground-contact review adds one rounded matte supporting board to the same
pastry recipe (0.84 x 0.018 x 0.44 metres, centre Y=-0.009). Its top is Y=0,
matching both plate bases; food geometry is unchanged. Lower-angle native review
(azimuth 20, elevation 22 degrees) in the existing PID 30828 produced
`procedural/generated/reviews/20260906-125338-e44dd4bf0e854f28a090f9293035b812/pastry-contact.png`.
The capture confirms visible support and cast shadows. It also exposes uniform
sponge and repeated rim shapes; the presentation change does not establish food
material realism. The board is a review/serving prop, not an invented MUD room
or a general collision/contact solver. Previous isolated renders remain useful
for material comparison because this camera and framing differ.

Deterministic CPU-side parametric mesh construction; reusable named geometry;
groups/repetition; exact rectangular aperture subdivision; strict geometry and
allocation limits; portable mesh/instance representation; native engine adapters;
Crossing evidence rules; bounded discrete furnishing repair with reserved
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

Crossing compiler v7.1 now implements the first limited search/repair component:
deterministic depth-first selection over hard-filtered furniture candidates,
seeded by the previous greedy result, with a 4,000-state/attempt budget per room.
It prioritizes fitted requirement count, then placement score, and can revisit
earlier choices. This supersedes the greedy-only status above, but not the wider
research roadmap. Its regression fixture resolves a greedy dead end; the current
real Crossing batch evaluates 676 states and retains its existing sparse layouts.
No visual improvement, city-level solving or optimality claim follows from that.

Crossing integration must bind actual exits to these descriptors explicitly.
The uncommitted earlier JavaScript shell experiment is not the production
authority: its neighbor-position fallback is insufficient evidence for a door's
wall. Do not silently treat proximity as an exit anchor. That experiment still
requires replacement when the shared compiler is connected to the MUD adapter.
