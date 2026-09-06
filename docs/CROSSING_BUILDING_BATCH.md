# Description-led Crossing building batch

## Alchemy furnishing batch

Five new candidates extend the catalog to 105 models: stoppered-jar,
glass-carboy, ceramic-amphora, liquid-vat and long-worktable. Vessels use
one radius/height profile constructor with outward normals and 48 radial
segments; the long table extends the existing trestle-table construction.
The table retains its measured surface socket, and the vat has a liquid
surface socket. The vat contains a neutral visual liquid, not a claim about
contents, quantity, safety or live inventory.

First-pass horizontal shading bands and square-section amphora handles
were rejected and revised. Current front views were inspected after the
normal/handle correction. Materials remain candidates: dark opaque glass
is not yet convincing transparent glass; vessels still need wear, surface
variation and closer rim/stopper refinement. The ceramic amphora must not
stand in for Chizili's explicitly glass specimen containers.

Chizili's documented mixed vessels and vats, and the separate workroom's
long table, establish the consumer needs. Exact shapes, sizes and colors
are art-direction inferences. No specimens, active shop inventory or NPC
are built into these props. No paid generation or credits were used.

## Static great bellows

The 100th candidate, forge-bellows, extends the existing native kit with
timber leaves, a folded leather body, iron nozzle, trestle frame and pull
lever. Air outlet, lever pivot and operator handle have measured sockets.
UpperLeaf is a separate node for later rigging; no animation, operator,
active fire or game state is baked into the scenery. Geometry is authored
locally, with the existing licensed wood inputs and a plain leather material.
No paid tools or generation credits were used.

Front/rear renders were inspected. Leather folds, nozzle opening and pivot
hardware still need polish; this is a consumer-review candidate, not final
mechanical or historical reconstruction. Crossing's bellows-room description
provides the use case; exact dimensions and mechanism are art-direction
inferences. Character work remains separate.

## Focused review, not a growing slideshow

Catalog rebuilds now support `--catalog --render-only clinker-rowboat` (a
comma-separated list is accepted). Geometry and native/GLB integrity checks
still run for every model; existing front/rear images are reused for unselected
models, and missing images are rendered. This is an explicitly selected render
scope, **not automatic change detection**. Include every visually changed model;
use a full render after shared material, camera, lighting or common-generator
changes. Do not treat reused images as evidence for newly changed geometry.

The original river-port rowboat construction now lives in `river-port-kit.gd`
and is called by both the original scene and catalog. `clinker-rowboat` is a
roughly 4.3 m plank-built boat with ribs, thwarts, oar and a mooring attachment.
It supplies a reusable hull for the quay batch; dilapidation, mooring placement,
waterline and exact named-room admission still require scene review. It is not
a barge, gondola or flood raft substitute. No animation or paid generation.
The 99-model build passed native bounds/socket/hash inspection, retained all
98 existing GLB hashes, and reloaded the 94-instance assembly. Front and rear
rowboat renders were inspected; they retain the earlier scene's segmented wood
treatment, which still needs close-range polish. An invalid render-selection ID
was tested and correctly exited with an error before rebuilding the catalog.

Use the existing builder's `--review-catalog <comma-separated-ids>` mode to
inspect a small named batch from the saved native catalog. For example:
`godot --path tools --rendering-method forward_plus --script res://build-river-port.gd -- <absolute-repo> --review-catalog pine-shop-counter,wooden-display-bin,shield-hook-board`.
This captures front/rear views without regenerating any geometry. Unknown or
duplicate IDs fail instead of silently reviewing something else. Output lives
in `docs/river-port-build/catalog/review-batch/`; `review.json` names the current
batch and pins its source catalog hash. Older image files can remain there;
only the receipt's IDs belong to the current review. Captures are not approval.

Routine visual review should cover changed pieces and their composed room,
including joins, scale, access and sightlines. A full `--catalog` build still
rebuilds, checks and renders every model; it is not an incremental build cache.
Reserve that full visual sweep for broad material/geometry changes or an
intentional catalog audit. Automated catalog-wide validation remains separate
from asking the user to watch every model. Character production is owned by
Pirate Island; this workflow owns reusable environments and scene composition.

## Building candidates

### Interior and furnishing batch (98-model catalog checkpoint)

Nine additional candidate models extend the same kit: plaster and stone wall
sections, a timber doorway section, a mullioned window section, pine shop
counter, wooden display bin, shield-hook board, wooden park bench and gingham
picnic table. Wall modules have a nominal 3 m span and 3 m height, with named
end joins. Doorway clear width is approximately 1.32 m; consumers must account
for the raised threshold. Windows have real openings but no glass. Counter,
bin and table expose support surfaces; hook board exposes four hanging points.
Catalog bounds and sockets are the exported measurement authority.

The shop fittings answer Milgrym showroom and Tembeg salesroom description
requirements; this does not assign those identities to the neutral models.
The bench and table are candidates for Town Green Pond furnishings, subject to
season/state confirmation. Front views of doorway, window, bench and table
were inspected. The table's flat checkerboard treatment was rejected for room
admission: cloth drape and fabric material remain to be built. It stays a
catalog candidate, not an approved runtime furnishing. All other new pieces
still require composed-room review, not automatic admission from this ledger.

Validation: all 98 saved models passed independent bounds, sockets and GLB
hash checks; all 89 previously published GLB hashes stayed unchanged. The
94-instance existing assembly was rebuilt and independently reloaded against
the new catalog hash. No service credits consumed. These checks establish
reusable geometry integrity, not completion of Crossing's interiors.

Nine new shared candidates, built locally with the existing river-port kit.
No paid services, no decimation, no generated live population. Complete shells
have measured bounds, bottom-centered pivots, front/rear captures and entrance
sockets. Game identity belongs to DR Companion's hashed room recipes, not these
neutral shared asset IDs.

| Shared asset | Description constraint read in DR source ledger | Interpretation / remaining work |
|---|---|---|
| unpainted-armorer-shop | Town Green Northwest (1-225): unpainted wooden structure, exterior samples on hooks, no sign; hedge breach and plank approach | Size and wooden roof inferred; shield samples only, broader armor display unfinished |
| plain-weaponsmith | Town Green North (1-14): Milgrym's stands beyond privet and narrow cobbles; showroom plain/practical | Masonry shell and roof inferred, not specified by description |
| trellised-herbalist | Flamethorn Way (1-7): wicker/cane facade trellises and dense climbing plants | Trellis and climbing foliage built; botanical species distinctions unfinished |
| low-brick-bathhouse | Water Street (1-95): low, long reddish-brown structure on north side | Brick treatment, roof and chimneys interpreted; damp weathering unfinished |
| old-stone-residence | Manciple Cobble (1-22): old stone residences lining court-like cobbled walkway | Shared complete house repeated on opposite sides; count and roof shape inferred |
| cruck-cottage | Swithen's Court (1-100): thatched cruck-frame house on small former rural plot | Continuous thatch with bundled straw; weathering and curved structural crucks need refinement |
| barn-stable | Goodwhate Pike (1-112): long barn-like structure, very high/wide double door, outer town wall north | Two door leaves and ring handles built; wall is a separate missing district element |
| mud-court | Supply Stand (1-371) and Mongers' Bazaar (1-379): trampled/muddy ground | Solid earth, irregular clods and shallow glossy puddles; not a fluid simulation |
| tattered-shelter | Mongers' Bazaar (1-379): ramshackle stalls and tattered tents | Broken cloth strips and uneven edges; natural drape and repair patches unfinished |

Source: the existing DR Companion data/art/room-prompts-priority.json lore fields
resolved through room-place-map.json, checked against full cell titles and IDs.
Old raster prompt boilerplate is not a building specification. No directional
exit or named building is inferred from a model filename. Missing MUD fields
remain explicit rather than being silently filled as canon.

The first cruck roof (straw lines over exposed shingles) was rejected in visual
review and replaced. All candidates remain subject to gameplay-distance review;
model construction is not the same as complete city composition.
