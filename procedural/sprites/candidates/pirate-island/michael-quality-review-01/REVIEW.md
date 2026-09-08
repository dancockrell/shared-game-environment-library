# Michael sampling and scale review

Status: comparison only, not runtime admission or final-art approval. No image generation, repainting, game changes or paid tools. Reviewed under the shared game-art pipeline quality gates: original, native-scale presentation, alpha, identity and provenance remain distinct.

## Inputs and method

Current game source `game/assets/sprites/michael/source.png`, with its four existing atlas rectangles and foot pivots from `frames.json`. The actual source hash and derived frame sizes are in `review.json`. All four source directions were inspected together; the terrain comparison uses the same southeast pose throughout.

SE alpha silhouette height is 592 pixels. The current 0.065 scale displays that body at 38.48 world pixels. The comparison tests direct nearest-neighbor sampling at that scale and at 48/56 world-pixel body heights. It separately tests a deterministic 96-body export: BOX area sampling, 64 RGB colors, no dithering, alpha threshold 128, then nearest-neighbor presentation.

The terrain is the actual game's terrain.png. Every panel uses the same crop, ground pivot and pose. Top row is 1x world rendering enlarged 2x for inspection. Bottom row simulates actual 2x camera sampling directly, not an enlarged copy of the top row. These are static composites, not engine captures.

## Findings

- The original identity and outfit are considerably richer than the current 38.5-pixel body can express. Slouch hat, coat split, red sash and brass apparatus survive; eye, collar, belt and small metal details become sampling noise at the current size.
- Going to 48 or 56 world pixels yields a more readable character without altering anatomy, camera, pose or identity. The 56-pixel direct sample is visibly stronger than the current scale at 2x camera, particularly face, collar and brass highlights.
- The 96-body quantized derivative is calmer and more coherent at a glance, but BOX averaging and palette reduction lose local contrast. The full-source comparison makes the muddy face and muted machinery conspicuous. This specific conversion is **not** approved as a final-quality improvement.
- Sampling a 96-body grid into 48 world pixels has a clean 2:1 relationship and is pixel-exact at 2x camera. Sampling it into 56 world pixels is fractional and does not confer that benefit. A renderer should not advertise a consistent pixel grid while repeatedly sampling it at arbitrary fractional scales.
- The art is already a detailed pixel-styled raster, not a native 39-pixel sprite. No resampler can supply missing deliberate small-scale facial features. Rendering scale, camera presentation and eventual native-size pixel cleanup remain separate decisions.

## Recommendation

Test 48 and 56 world-pixel character scale in the actual scene before replacing source assets. Preserve the approved source. Do not adopt these 64-color exports automatically. If a native atlas is needed, compare a less destructive 112/128-body export with preserved colors and deliberate pixel-grid presentation, then judge actual movement and equipment continuity. This review does not authorize new images or claim that larger sprites alone finish the art.

## Outputs

- `sampling-comparison.png`: current/direct/grid variants on actual terrain.
- `source-and-export.png`: original SE identity next to the 96-body derivative.
- `michael-{se,sw,ne,nw}-96.png`: non-admitted experimental exports.
- `review.py`: reproducible comparison only; not a parallel production exporter.
- `review.json`: dimensions, pivots, input hash and processing parameters.
