# Foothold placement review — actual source, 8 September 2026

This is an offline source-art composite on the actual Pirate Island terrain, not an engine capture. Updated after the actual workshop arrived: the former provisional rectangle and symmetric footprint are superseded. The game-art pipeline's intended-size review gate governs these conclusions. The parent delegated runtime PNG/manifest admission; final native/engine integration remains the parent's responsibility.

## Salvage cache

- Source: `procedural/sprites/candidates/mercantile-cart-props-01/extracted-01/cell_00_02.png`, shared catalog.
- SHA256: `8911b0430334effaa432f3460353414a8d4d3ac4c589b9bed457a6e2a1b6125c`.
- Source size: 505 × 336 RGBA, alpha extrema 0 and 255.
- Requested pivot: `[252,304]`; width 30; uniform scale `30/505 = 0.0594059405940594`.
- Nearest-neighbor review raster: 30 × 20 pixels at rounded origin `[641,606]`, anchored at `[656,624]`, cell `[20,19]`.
- Visually a compact tan tied bale, not a machine, chest or corpse. Rope cross and raised bundle remain readable at intended size. No apparent pale matte at this size.
- Placement is on a clear dirt gap just south of Michael's start. Palms are near the left and lower sides but do not visibly intersect the bale's front or main silhouette. No water intersection. Runtime selection/collision remains independent of the sprite.

## Actual workshop placement

- Entrance cell `[19,17]`, world `[624,560]`.
- Actual source `extracted/cell_00_00.png`, 1287 × 1004 RGBA; SHA256 `d1380c98922aaaa953242b921dfcdae05f1527cb268b721c0ae5574fba1f5718`.
- Source stairs-ground pivot `[405,910]`, on the bottom/front step rather than the platform center. Width 120 means scale `120/1287 = 0.09324009324009325`; nearest review raster 120 × 94, rounded origin `[586,475]`.
- Actual asymmetric foundation blocked offsets: `[[0,-1],[1,-1],[2,-1],[1,0]]`, absolute cells `[19,16]`, `[20,16]`, `[21,16]`, `[20,17]`. This covers the central work floor, right boiler platform and front support. The left projecting crane/roof is not an additional ground obstacle.
- The source reads as a canvas-topped timber steam workshop: exposed boiler/chimney and restoration cradle remain distinguishable at 120 pixels. Stairs lead toward the unblocked entrance. Some individual tools become texture, which is acceptable for this map scale. No obvious alpha matte or terrain intersection at this placement.
- These cells sit outside the listed static blocked rectangles. The entrance stays clear, with open east and south travel space. Michael starts two Manhattan cells away at `[20,18]`; the cache stays separately reachable below him. The small platform crosses part of the dirt fork but leaves passage around it.
- Runtime manifest and exact PNG copy added under parent delegation: `game/assets/island/buildings.json`, `game/assets/island/field_workshop.png`. `reviewed_entrance` records the tested spot without imposing a fixed `placement_entrance`; native legal-footprint checks govern arbitrary player construction. PNG copy SHA256 verified equal to source.

## Native code compatibility review

Read-only snapshot of in-progress `build_foothold` on 8 September:

- Building placement stages a clone, rejects nontraversable or actor-occupied foundation cells, then verifies Michael can reach the entrance, every live actor, all building entrances and a remaining cache. Only after validation are resources deducted into the committed state. This guards presently relevant endpoints against trapping; it is not a proof of preserving every empty path cell.
- Current siege resolution specifically avoids eliminating Michael's faction when its last building is destroyed while Michael remains alive. This avoids deleting Michael simply because his workshop falls.
- Restoration requires an owned, living undead adult woman and both her and Michael within reach of an operational workshop. It does not newly acquire the target or remove her identity.
- No engine or Cargo tests were run by this reviewer. Native tests and actual engine placement belong to the integrating parent/native agent.

## Evidence

`placement-review.png` is the full terrain with the actual 30-pixel cache and actual 120-pixel workshop. `placement-detail.png` is a 3× nearest-neighbor review crop with a grid, actual foundation, and labeled anchors. `placement_review.py` reproduces both. Sources and extracted sprites were not altered. Runtime `git diff --check` passed; engine/Cargo were not run by this reviewer.
