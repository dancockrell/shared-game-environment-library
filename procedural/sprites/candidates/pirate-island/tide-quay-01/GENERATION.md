# Pirate tide quay candidate

Target: site_archetype.pirates.tide_quay, existing deckhand producer paid in
provisions and coin. Single static building cutout; no animation implied.
Camera/pixel-scale reference: Project 42 game/assets/island/watch_fort.png.
Output intended for shared candidate curation before runtime admission.
Transparency, doorway pivot, shoreline placement and footprint need verification.
Tool: built-in image generation; no external paid API fallback.

## Exact prompt

Use case: stylized-concept. Asset: ONE Pirate Island pirate tide-quay producer building sprite, fixed elevated three-quarter orthographic 2D pixel art. Attached fort is CAMERA, PIXEL EDGE and MATERIAL SCALE reference only. Do NOT repeat its architecture. Make a pirate dockside hiring office and cargo quay: a low irregular weathered timber office, broad patched tan sailcloth awning, a dark open doorway, a couple of stacked cargo crates and rope coils, and a short heavy timber landing on pilings with a hand-cranked loading davit. The silhouettes must say maritime salvage and opportunistic commerce, not military stone fort. No people, no text, no skull flag, no modern equipment. Period sail-age construction. One compact connected building assembly within a rectangular footprint, entire silhouette visible with ample margins. Show clear roof and top planes, light from upper left. Warm brown timber, muted rust-red cloth accents, desaturated blue-grey salvaged boards. Crisp pixel clusters, restrained palette, strong outline; readable at 150px wide, do not add intricate noisy detail. Actual transparent background, no baked checkerboard, no scenery or water patch, no grass base, no painted shadows outside the footprint. No photorealism, no 3D rendering, no poster or sheet layout.
## Processing and review

Original source.png: RGB 1402x1122, baked checkerboard; rejected for direct use.
Background edit magenta-source.png: RGB 1403x1121. The generator changed canvas
dimensions slightly, so crop/pivot measurements must come from the edited image,
not be copied from the original.

Exact edit prompt: Background correction only. Keep this exact pirate timber
quay building, ropes, davit, board construction and all pixels of the subject
visually unchanged. Replace ALL checkerboard outside and through gaps in the
structure with flat uniform RGB(255,0,255) magenta. No gradient, shadow or checker
pattern in the background. Same framing and dimensions, no subject redesign.

Extraction: shared cattle-trail/sprite_grid.py, columns=1, rows=1,
min-component-pixels=1. One connected component retained, no resizing, no gutter
warnings. Output 1166x975; metadata.json records bounds and cryptographic hashes.
PNG SHA256: f9bc0ea135cc5a03959c7478a51103b3e6901830cec482e830088536b14be2d7.

Source-size inspection: distinct pirate timber silhouette, open doorway, stair,
cargo and davit; camera reasonably consistent with fort reference. Quay is on
piles and needs coastline-aware placement. Runtime not admitted: current pirate
spawn location is a simulation fixture, not an approved shoreline anchor.
Do not silently place it inland or claim automatic placement is solved.
Next: review at intended map scale, author landing/entrance and shoreline
footprint, then integrate through existing buildings.json and native producer.
No final visual approval, animation, engine capture, or paid API use claimed.
