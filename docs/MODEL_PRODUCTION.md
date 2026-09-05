# Shared model production

Decision date: 5 September 2026. This repository is the reusable catalog.
DR Companion and Pirate Island are consumers. The older Project 42
`resource-packs` catalog is evidence for migration, not another canonical home
for new shared work. Do not move or delete its assets until references and
provenance have been reconciled. Stable IDs, archive hashes and source-member
paths are the migration keys; directory similarity is not identity.

## Approved visual reference - controlling art target

![Approved painted miniature river-port reference](visual-reference/painted-miniature-river-port-approved.png)

On 5 September 2026, Dan approved this exact image: "yes. this is the
reference. this is what I want exactly." Preserve the image without edits.
Its provenance is in the adjacent JSON sidecar. This image controls the
painted tabletop fantasy art direction wherever earlier shorthand such as
"flat color", "chunky low-poly", or "simple block-built" would lower the
visible finish. Source packs and the foundation contact sheet are ingredients
and technical proofs; they are not approved substitutes for this finish.

The approval includes the image as shown. The assistant's preceding proposals
to simplify masonry/roof detail, brighten actors, or flatten the gold markers
were not separately approved and must not be applied by assumption.

### Features that must survive into the build

- Elevated fixed isometric presentation with a coherent, continuous place,
  clear approaches, and visible tabletop character pieces on discreet bases.
- Substantial stonework, layered roof tiles, dark structural timber, useful
  bevels, readable trim and ornamental metal. Keep the richness visible in
  this reference; avoid reducing the result to plain colored blocks.
- Warm stone and timber, slate and restrained terracotta roofs, muted teal
  water, natural greens, blue cloth and restrained gold accents. The cyan
  ground/peach rock source palette fails this target.
- Painterly material variation and believable light response: wood grain,
  stone joints, roof variation, restrained wear, contact shadows, warm lights
  in interiors, and softly shaded water with readable shallow shore details.
- Distinct rooflines and entrances; a cutaway shop with shelving and counter;
  believable relationship between buildings, paved public space and bridge.
- Timber quay/dock construction, mooring details, rowboat, stone banks,
  sandy transitions, rocks and grouped reeds. Water and land meet deliberately.
- Adult adventurer proportions, visible species and equipment identity,
  restrained heroic emphasis, and static poses that already communicate role.
- The gold node/connection treatment shown is part of the approved visual
  reference. Its runtime placement follows actual graph data; a decorative
  mark in this concept image never creates an exit or physical barrier.

The image approves visual language and finish, not a named canonical town or
a replacement graph. Translate its style across the established fantasy
families without asserting that every culture uses this western architecture.
Preserve the common finish while changing construction, forms and identity
from each game's evidence. Static now and rig-ready actors remain the scope.

### Acceptance and implementation consequences

For each assembled scene, capture the actual engine output at comparable
framing and place it beside this reference. Review silhouette, surface finish,
palette, lighting, material separation, density, actor readability, cutaway
readability and shoreline quality. Record pass/revise per dimension. Structural
checks, source licenses and low polygon counts cannot substitute for visual
acceptance. Unfinished geometry remains explicitly labeled as base art.

The budgets below predate this approval and remain provisional engineering
targets. First try shared materials, modular reuse, baked detail, spatial
culling and appropriate distant representations while preserving the approved
appearance at the reference framing. If a budget conflicts with the image,
measure and report the conflict; do not silently lower quality or claim both
targets passed. The reference does not by itself prove performance feasibility.

Next visual milestone: build an engine scene with a stone quay, timber dock,
bridge approach, roofed facade, cutaway shop and properly scaled actor pieces,
then assess it directly against this image. Favor a convincing connected
scene over a larger collection of isolated pieces that misses this standard.

## Review of the incoming DR Companion handoff

The supplied `3dcontenthandoffforchatgpt.md` correctly prioritizes geometry,
reuse, fixed-camera readability and MUD topology authority. Its dated counts
are demand estimates, not catalog counts. The generated Crossing manifest was
not present in the fresh current-main checkout inspected this session, so its
1,060 cells and 2,389 routes have not been independently reproduced here.
The older selection registry contains two selections covering three GLB paths.
Neither count measures the much larger reusable source library.

Corrections to carry into implementation:

- A fixed view can justify culling hidden faces in a consumer derivative.
  Shared sources retain closed geometry because other games, shadow passes,
  cutaways and framing heights can expose it. Interior floor and cutaway kits
  explicitly need interiors; the handoff's absolute ban contradicts that need.
- Body type and size identify rig candidates, not creature identity. A wolf,
  horse and tiger cannot share one finished quadruped mesh merely because their
  database sizes match. The claimed seventy-percent coverage needs a stated
  denominator and normalization table before it is accepted.
- Flat materials are a direction, not proof that normals, lighting or AO are
  unnecessary. Preserve valid source normals. Bake detail only after a camera
  comparison establishes value. Do not bake screen-facing shadows into a
  shared model.
- Repeated GLBs do not automatically share GPU materials. Instancing reduces
  submission cost but does not eliminate vertices, overdraw or shadows. Use
  spatial instance groups; one city-wide group can defeat useful culling.
- The stated installer size is an unverified snapshot. Measure compressed
  download, unpacked files, imported textures and resident GPU use separately.

## Work executed

Extended the existing curated-member manifest and builder with coast and
river/cliff packs. These retain the licensed source geometry. The builder now
extracts each GLB's external images and buffers from the exact source archive,
preserving paths and hashes. Previously a GLB could be extracted without its
palette. Models that then imported as white geometry were not a visual result.

The reusable review script imports the actual extracted GLBs, measures bounds,
triangle and surface counts, and builds 15 GLB derivatives in
`resource_packs/terrain/tabletop-foundation`. It uniformly fits them to a
maximum 4.4 m horizontal extent and 5 m height, centers the pivot at ground
contact, and replaces metallic response with matte roughness while retaining
source colors, textures and material names. This is a miniature profile, not
a claim that a barrel and a bridge share realistic scale. Original sources
remain unchanged. Every derivative is reimported before its image is captured.

The Godot 4.7.2 OpenGL review on an RTX 4070 found readable dock, boat, barrel,
crate, bridge and palm silhouettes. The cave opening is visible from the
selected angle. Source nature materials were fully metallic, making their
unlit sides black; the matte derivatives correct that response. Bright cyan
ground and peach rocks remain source-palette artifacts needing art direction.
The waterfall is a flat modular wall piece, not a finished waterfall scene.
No creature rigs or finished terrain compositions are delivered by this pass.
Godot 4.3 compatibility and dense-world performance are not yet tested.

Reproduce from the repository root, using PowerShell and a Godot executable:

```powershell
./tools/build-curated-member-packs.ps1
godot --path tools --script res://review-model-packs.gd -- (Get-Location).Path
./tools/validate-resource-packs.ps1
./tools/build-resource-pack-ledger.ps1
```

The contact sheet and measured source geometry are under `docs/model-review`.
The derivative pack's build report records transforms, source IDs, hashes and
the engine version. Its eligibility remains candidate until the consuming
game reviews scale, palette, camera occlusion and semantic fit.

## Production order and exit criteria

| Stage | Deliverable | What it unlocks | Exit criterion |
| --- | --- | --- | --- |
| 1 | Complete licensed dependencies; coast, dock, river, cliff and cave sources | Reusable physical building blocks | Hash validation and visible textured import |
| 2 | 4.4 m ground/floor plates, edge strips, cutaway walls, water ribbons | Ordinary outdoor and indoor cells | 5 m grid test; 0.6 m gutter; no overlap; all three framings |
| 3 | Hall, tower, gatehouse, colonnade, pitched/hipped/flat roofs | Named-place composition candidates | Recipes grounded in room evidence; recognition review |
| 4 | Reeds, mud islands, tidal banks, beaches, quay walls, piers, ferry landings | Wetlands and maritime transitions | Waterline, shore continuity, approach and silhouette review |
| 5 | Basalt slopes, crater segments, lava channels, ash and snow overlays | Volcanoes and uplands | Constructed geological silhouette; not merely red recoloring |
| 6 | Rig families and portrait/token vocabulary | Players and creatures | Skinning, sockets and identity review; neutral fallback remains |

The first two high-demand ground/edge kinds serve the same 767 outdoor cells;
their counts must not be added as if they were different rooms. Generic massing
is useful for authored compositions but cannot automatically fill 416 named
landmarks. Provision 18 bespoke composition slots initially: ten guild halls
as proposed by the handoff, four major gates, two bridges, a market and one
dominant civic landmark. These are planning slots, not claims those exact
locations have been verified. Replace the shortlist from actual navigation
and room evidence before commissioning bespoke work.

## Geometry and metadata contract

Extend `contracts/TABLETOP_ASSET_CONTRACT.md`; never invent a second coordinate
system. Authored assets use metres, +Y up, -Z forward, bottom-center origin.
The 4.4 m square is a DR presentation profile, not a shared-library size law.
For source-origin assets, unknown scale/front/pivot stays explicitly unknown.

| Family | DR profile dimensions | Suggested triangle ceiling | Materials/sockets |
| --- | --- | --- | --- |
| Ground/floor | 4.4 x 4.4 m, top at 0 | 128 / 64 | base; center/spawn hints in recipe |
| Boundary strip | <=4.4 x 0.25 m | 256 | stone or soil; corner anchors |
| Water ribbon | <=4.4 x 4.4 m | 64 | water; waterline datum |
| Cutaway wall | <=4.4 m run, 0.2 m thick, 0.8 m high | 256 | stone/wood; door-left/right anchors |
| Dock/bridge | <=4.4 m span, 1.2-2 m deck | 800 | wood/trim_metal; deck/approach anchors |
| Hall/gate/tower | <=4.4 m footprint; height reviewed for occlusion | 1,500; world proxy 80-200 | base/roof/trim; entrance/sign/banner |
| Canopy/threshold | <=3.6 m footprint | 600 | wood/cloth/stone; service/approach |
| Tree/rock/reed | footprint per measured species/form | 500 / 200 / 120 | foliage/wood/stone |
| Common miniature | measured body footprint, not room size | 3,000 | <=4 surfaces; rig sockets below |
| Hero miniature | default 1.7-1.9 m human scale | 8,000 | <=6 surfaces; identity review |

These are initial budgets, not results already achieved. Exceptions need
measured visual benefit and dense-scene evidence. A large ship is a multi-cell
visual or distant silhouette; do not crush it into 4.4 m and call it true scale.

Actor rigs require `root`, a stated pelvis/spine hierarchy and body-plan limbs;
zero animation clips are required now. Declare `socket_hand_l`,
`socket_hand_r`, `socket_back`, `socket_head`, `socket_nameplate`, and
`socket_effect_origin` only where anatomically applicable. Record bind pose,
joint count, normalized weights, maximum four influences per vertex, bounds,
facing, footprint, neck attachment and equipment exclusions. A skeleton node
without skin weights is not a rigged asset.

Prefer neutral tokens for unresolved creatures and world-distance actors;
use reviewed miniatures at route/room framing. A portrait carries dialogue
identity, while a stable glyph communicates combat state. Player defaults may
reuse approved Pirate Island rigs; named identities remain in each game.

## Palette, art families and performance

Build broad western fantasy, bronze-age mythic and eastern/wushu fantasy
families through silhouette and construction. Historical source packs are
ingredients, not mandatory reconstructions. Elven, treefolk, faction and cult
overlays carry explicit compatibility and provenance. Game-specific symbols
are consumer assets, never neutral source labels.

Start with eight shared opaque material definitions (earth, stone, wood,
roof, foliage, cloth, metal, bone/plaster), one opaque water material and one
optional emissive material. Palette variants should use instance/vertex colors
where the chosen renderer supports them. Do not silently flatten a model's
material zones or textured identity. Preserve originals and compare derivatives.

Provisional first-city art budget: <=15 MiB compressed additional art,
<=40 MiB unpacked, <=64 MiB resident texture data, <=250,000 visible triangles
and <=250 draw submissions at world framing. Target <=8 ms GPU and <=4 ms CPU
presentation time on a declared test machine at 1080p. These are benchmark
targets, not portable guarantees. Measure 100, 500 and 1,060 cells with shadows
on/off and worst visible overlap, report p50/p95 frame time and memory. Use
room/route detail plus one world proxy tier only when measurement warrants it.

## Deterministic execution contract

```text
for selection in existing_curated_manifest:
  source = approved_ledger.lookup(selection.upstreamSourceId)
  require source.license == CC0 and hash(archive) == source.archiveHash
  for member in selection.members:
    read exact archive member
    parse GLB dependency URIs
    reject remote, absolute and parent traversal paths
    extract dependencies from same archive with relative layout preserved
    record member and dependency hashes
  validate missing files, hashes, GLB structure and dependency closure
  import actual outputs in engine
  measure bounds, surfaces, triangles, textures, skinning if present
  render world / route / room references
  record visual decisions per member; do not infer admission from exit code
  rebuild existing resource-pack ledger

consumer selects stable asset ID + source hash + presentation transform
consumer validates lore and footprint for this usage
consumer owns topology, selection, physics and game events
```

## Limits and next decisions

Downloaded low-poly models can supply coherent base silhouettes but cannot
prove lore, final scale, good rigging or premium character identity. Palms are
not substitutes for temperate marsh trees; a lily is wetland dressing, not a
complete marsh. The cliff cave is appearance only and creates no exit. The
existing basalt pack is a useful volcano ingredient, not a complete volcano.

The shared repository accepts source and derivative readiness independently.
This work does not bind any new asset to a game, change DR Companion's
submodule, or proclaim a city complete. The next model-authoring gate is a
reviewed neutral terrain/cutaway kit, followed by evidence-led landmark recipes.
