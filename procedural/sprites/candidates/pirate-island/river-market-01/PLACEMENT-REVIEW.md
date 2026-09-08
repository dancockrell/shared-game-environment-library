# River market — offline placement review

**Static source-art composite, not an engine capture or final placement approval.** Root owns the consuming manifest and native path validation. No source/extracted image pixels were modified.

## Exact placement

- Source: `extracted/cell_00_00.png`, 1128 × 1053 RGBA; SHA256 `883e48fa10f6702bfd8258d95f68da20d0d2cc4c398da931386898b750ff1c36`.
- Actual game terrain: Project 42 `game/assets/island/terrain.png`, 1536 × 1024; SHA256 `5b5af8b60df58e402ec69f9d6788ee788c60238ebc68fd38d60654e7583cf976`.
- Requested width 140px; scale `140/1128 = 0.12411347517730496`.
- Requested source pivot `[630,1020]` maps to world `[1072,304]`, centre of cell `[33,9]`.
- Ideal top-left approximately `[993.81,177.40]`; offline plate rounds to `[994,177]` and samples to 140 × 131 with nearest-neighbor filtering. Fractional engine sampling can differ by roughly one pixel.

`placement_review.py` reproduces the review from the unchanged source files. `placement-review.png` shows the entire map; `placement-detail.png` is a nearest-enlarged threefold detail with grid, proposed blocked cells in coral and entrance in cyan.

## Visual findings

The stone base rests wholly on dry grass/dirt clearing. No water or shoreline intersects its base. The lower/front gate meets the north–south dirt route, giving an understandable arrival direction from the south. The market occupies part of the path junction; the footprint should prevent walking through walls while keeping the entrance and nearby eastern bypass open.

The building is a compact landmark at this width, not an oversized settlement. Its green roofs, red uprights and stone walls remain distinct at full-map scale. Small cargo detail becomes decorative texture rather than individually recognizable inventory; no gameplay assertion should depend on counting those baskets.

Baked palm crowns behind the roof create some texture overlap, but the visible lower entrance/foundation is not interrupted by a foreground trunk. This composite cannot test actor depth sorting against the sprite or reveal foliage layers that the terrain image does not contain.

## Proposed blocked offsets

Relative to `[33,9]`, use this conservative five-cell starting footprint:

```json
[[-2,-1],[-1,-1],[0,-1],[1,-1],[0,-2]]
```

Absolute cells: `[31,8]`, `[32,8]`, `[33,8]`, `[34,8]`, `[33,7]`.

This is a coarse navigation footprint for the wall/foundation and rear centre, **not an alpha-mask collision outline**. Do not block the tall roof's complete drawn rectangle. Leave entrance offset `[0,0]` open. Do not add front-left `[−1,0]` simply to fill a rectangle: its cell extends substantially outside the foundation and would unnecessarily consume the arrival apron.

From the current authored obstacle rectangles grown by 10px, the immediate south cell `[33,10]` and east cell `[34,9]` are outside the nearby forest obstacle. The southwest `[32,10]` is inside that obstacle, so an arrival route should not assume a diagonal shortcut through it. This was checked against the recorded rectangle bounds, not a native pathfinding run. Parent still needs to verify the actual entrance, production spawn and an escape route using the native navigation owner after applying the footprint.

## Artifact hashes and acceptance boundary

- `placement-review.png`: `9bd11f6e77499c111d1699c2436ca4bbe19c36bf971eb8ea81fd327693896014`.
- `placement-detail.png`: `781ef615988e2a7346bc0d26d424eae9c9730345ac30ee6f8fa53856c60dd548`.

Full-map and enlarged detail inspected. No Godot, graphics editor, art generation or runtime mutation. This evidence supports a development placement trial at the requested location; it does not prove final visual acceptance, collision correctness, construction animation or faction gameplay balance.
