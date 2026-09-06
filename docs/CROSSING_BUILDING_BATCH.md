# Description-led Crossing building batch

## Focused review, not a growing slideshow

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
