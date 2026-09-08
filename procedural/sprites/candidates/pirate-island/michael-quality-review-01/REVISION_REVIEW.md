# Michael readability revision — development standing admission

**Preparation superseded:** the user rejected artificial resolution reduction. The normalized atlas described below is historical evidence only, not production. Use the losslessly packed full-resolution extracted frames identified in `NATIVE_ADMISSION.md` and `revision-native-frames.json`. No source resizing or palette reduction is part of the admitted pipeline.

Root reviewed the actual scale-comparison and four-direction board and admitted this revision for development standing use on 8 September 2026. This is an incremental face/collar/waistcoat/brass readability improvement, not final native-pixel art or animation approval. Earlier 96-body quantized experiments remain rejected as a quality improvement and are preserved separately in this folder.

## Generation and preserved sources

Two built-in image-generation calls, no external API or paid external provider. Credit cost is unavailable; no zero-credit claim. First source reference was the original game Michael four-view sheet, SHA256 `9439551d5c9bd11eb5865748da07b79e8fdd4c83f5b83ec122b9e53222cc4ad7`; it remains in the existing shared Michael source collection. The approved mounted-cowboy sheet was a perspective/pixel-cluster style reference only.

1. `revision-source.png`: initial revision. Exact prompt in `REVISION_PROMPT.txt`. Built-in original output `exec-14a2b812-aafc-4eb0-bb04-e16e74aeba56.png`. The model supplied an opaque checkerboard, not genuine alpha.
2. `revision-keyed.png`: one authorized background correction. Built-in original output `exec-e90133fc-d6e8-419a-90ae-34010d8b1818.png`. Prompt: change only the checkerboard to uniform RGB255,0,255, preserve character pixels, silhouette, poses, sizes, faces, costume, equipment, layout and margins; no redraw, shadows or text. The correction slightly softened fine rendering despite that constraint; comparison evaluates the actual delivered result.

Both built-in originals were saved beneath `C:/Users/Admin/.codex/generated_images/01a0801a-8ae7-7b12-ae22-6ca1daf704fb/` and copied here. No further generation is authorized by this experiment.

## Extraction and normalization

Canonical `cattle-trail/sprite_grid.py` extracted four cells with magenta difference25, alpha threshold128, 2×2 layout and minimum component size1. All extraction metadata is retained in `revision-extracted/`.

`revision_review.py` places those true-alpha cells into the exact existing 1214×1295 atlas, preserving all four existing rectangles and foot pivots. Each direction is normalized to the original alpha-threshold128 body height, not the original faint stray-alpha bounding box. Nearest-neighbor fitting is deterministic. Pivots are the center of the planted-foot stance on the baseline, not arbitrary cell centers. The normalization record is retained in `revision-normalization.json`.

Runtime candidate: `revision-runtime-candidate.png`, SHA256 `bcb3c5c2ed31921cd8ffec3110b6d8e04acee969a2199a4fc1099f167b5b1b3b`. Metadata: `revision-frames.json`. Existing scale0.065 requires no adjustment.

## Visual findings

- At56/80-pixel body heights, face, open collar, navy waistcoat, red sash and brass apparatus separate more clearly than the prior source. At39 pixels, substantial detail still disappears; this does not resolve tiny overview rendering.
- Young adult identity, dark hat/hair, slim build, long brown coat and integrated machinery remain recognizable.
- Anatomical left-arm mechanism remains consistent in front and rear views. Northeast shows rear/rightward head turn; northwest shows rear/leftward head turn. These are not equipment-side mirror swaps.
- The improved source is still detailed pixel-styled raster artwork, not a hand-cleaned56-pixel native sprite. Broad highlight regions improve readability, but pixel-level finish remains future work.
- Actual terrain comparisons are deterministic composites, not engine screenshots. Animation, foot sliding and movement cadence are not tested or approved by these four idle views.

Root owns runtime installation, engine verification and publication of the game consumer. This shared package does not claim game deployment by itself.
