# Colonial watch fort candidate

Contract: site_archetype.colonial.watch_fort, existing marine producer.
One elevated three-quarter orthographic pixel-art building, transparent PNG,
compact footprint, entrance pivot, intended display width approximately 150px.
No automatic final admission; inspect alpha, silhouette, camera and game scale.
Tool: built-in image generation; no external paid API fallback authorized.
Reference: Project 42 docs/images/pixel-style/style-board.png (style only).

## Exact prompt

Use case: stylized-concept. Asset type: one runtime 2D pixel-art building sprite for Pirate Island. Reference image is STYLE ONLY: match the elevated three-quarter top-down game camera, crisp outlined pixel clusters, warm natural material colors and legible game-scale silhouettes of the gameplay portions; do not reproduce the board, text, cowboys, or layout. Subject: ONE colonial tropical-island watch fort that trains flintlock marines, compact pale weathered stone defensive walls around a tiny terracotta-roof barracks, a short square lookout, wooden open entrance at the front southeast edge. Period colonial military architecture, not a medieval castle or modern army base. No people, no lettering, no flags, no ocean, no grass base or surrounding scenery. All masonry and overhangs fit a compact square footprint viewed as a diamond. Show roof tops clearly with consistent orthographic elevated three-quarter perspective, no perspective convergence. Whole building visible, centered, generous empty margins. Actual transparent alpha background, no checkerboard baked in, no white matte. Restrained small palette and clean pixel edges, no 3D render, no photorealism, no painterly blur, no noisy microtexture. Target a sprite that reads at roughly 150 pixels wide; make architectural forms broad and readable. Light from upper left.
## Background correction and extraction

The first output was RGB with a baked checkerboard: rejected for direct runtime
use, retained as source.png. A built-in edit preserved the architecture while
replacing the background; retained as magenta-source.png.

Exact edit prompt: Edit only the background of this exact colonial watch fort
sprite. Replace every checkerboard background pixel with absolutely uniform flat
RGB(255,0,255) magenta. Preserve the fort, architectural shapes, pixel edges,
courtyard and open entrance unchanged. Outside the entire fort silhouette only
magenta, no shadow or checker pattern. Keep the same framing and dimensions.
No redesign.

Extraction reused Cattle Trail tools/sprite_grid.py with columns=1, rows=1,
min-component-pixels=1; no resizing or discarded components, zero gutter warnings.
extracted/metadata.json records original bounds, source and extractor hashes.
The transparent result is 1125x928 with binary alpha. Source-size review found
an intact fort, legible entrance, walls and lookout. It remains provisional:
game-scale readability, footprint collision and pixel-density consistency are
not yet visually approved. Runtime copy is game/assets/island/watch_fort.png,
using entrance pivot (775,825), approximate width 150 map pixels.
No paid API fallback or external credit spend was initiated.
