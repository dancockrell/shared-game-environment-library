# Musk hog sprite source

Target: ordinary exact-name `musk hog`, not the distinct `large musk hog`.
Existing DR bestiary classifies it as small quadruped, non-spellcasting melee
creature, present around Crossing/Tiger Clan on Woodland Path (map 4).
Local evidence: `dr-companion/data/elanthipedia/bestiary.json` entry `Musk hog`;
runtime facts: `dr-companion/src/data/bestiary.json` byName `musk hog`.
Live cross-check: https://elanthipedia.play.net/Musk_hog and
https://elanthipedia.play.net/Zoluren_Hunting_Guide read 2026-09-08.

Description-bound identity: dirty scruffy squat brown-gray hog with a broad,
flat twitching snout. Small bugs in coat may be subpixel at runtime; no invented
green gas effect, magical aura, weapons, oversized boar tusks or equipment.
Ear shape, coarse fur clusters and hoof geometry are artistic interpretation.
This asset does not claim a hog spawns in Town Green South.

Contract: detailed earthy pixel-art, fixed elevated three-quarter view facing
down-right. Four sequential restrained idle poses on a square 2x2 source sheet;
only snout twitch/blink, feet and body proportions remain planted. Flat magenta
production key, no cast shadow, no text. Extract using existing Cattle Trail
sprite_grid.py into RGBA PNGs, preserve source and hashes, equal source scale,
explicit per-frame anchors and duration. Review matte, silhouette and motion in
existing reviewer and actual DR client before any runtime admission.

Generated with built-in image_gen; no external paid service/API. Candidate only.

## Exact prompt and provenance

Style/layout input: `rat-scurry-01/idle-magenta-04.png`, SHA256
`decfd883afaa3b5e69b8e9add7ec9294fdd79655f2d3a6d032880a365876bafe`.

Use case: stylized-concept. Image 1 is ONLY a pixel-art rendering style and sheet-layout reference, not the subject. Generate a NEW DragonRealms MUSK HOG four-frame restrained idle animation sheet, square canvas divided into exactly 2x2 equal cells. One identical small squat scruffy dirty brownish-gray wild hog in each cell, broad flat snout, little eyes, short coarse bristles, four compact legs and cloven hooves, small ears, short tail. No oversized tusks, no rat anatomy, no accessories. Fixed elevated three-quarter gameplay camera facing diagonally down-right. Match the reference's earthy richly shaded crisp pixel-art and dark defined outline, not smooth 3D or vector. Frame1 neutral alert; frame2 snout twitches very slightly upward; frame3 brief eye blink with snout relaxed; frame4 neutral alert again. Exactly same size, camera, brown-gray palette, torso silhouette, short tail shape, and planted hoof coordinates relative to cell in all four frames; only tiny snout and eyelid change, no walking or breathing scale deformation. Full body comfortably inside every cell with generous clear equal gutters. Flat solid bright magenta #FF00FF background everywhere outside animal, no checkerboard, no ground shadows, no text, no labels, no grid lines. This is a chroma-key production source, not a transparency request. No magenta in subject, no gas clouds or extra insects detached in gutters.

Output `idle-magenta-01.png`: 1254x1254 RGB, SHA256
`cc4a106e040d7dc75505c48348307f7721435624b1865e4d233622d0e090ec85`.
Generated 2026-09-08; tool reports no explicit model version or credit amount.
Raw output retained unchanged. Generated assets follow project/user tool terms;
do not describe model output as third-party CC0 or MIT art.

Extraction: existing Cattle Trail `sprite_grid.py` with `--columns 2 --rows 2
--min-component-pixels 1`, Python3.13. No code fork and no discarded tiny pixels.
Four RGBA frames, no cut warnings. `idle-extracted-01/metadata.json` records all
source bounds, component counts, hashes and extractor version digest.

Initial visual review: squat scruffy brown-gray silhouette consistent across
sheet, broad flat snout, visible closed-eye pose at frame3. Small ivory tusks
are an artistic hog interpretation, not a described large-boar feature. No
equipment or special effects. Top/bottom frames differ one source pixel in
height; anchors compensate one pixel at same fixed scale, no per-frame resize.
Body-ground anchor is a manual estimate [205,312] (top), [205,313] (bottom)
relative to trimmed image, not an inferred MUD coordinate.
Full game motion and on-background edge acceptance remain required.

Browser review: all four RGBA frames decoded and passed alpha checks; Play
advanced through frames1/2/3/4 across the declared unequal timings. All19
shared animation-review tests passed. `idle-extracted-01/review.png` shows the
actual rendered stage and aligned filmstrip at0.16 source scale. Snout remains
readable, no visible magenta halo against moss, ground silhouette stays stable;
closed-eye pose is restrained. This is a source review, not runtime admission.
Browser closed after capture; no running server/Godot or Actions.
