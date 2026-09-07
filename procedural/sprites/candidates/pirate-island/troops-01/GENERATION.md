# Ordinary faction troop candidates

Generated 2026-09-07 with built-in image generation. No external paid API.
User-supplied cowboy sheet is style/camera reference only. No CC0 declaration.
Six unnamed adult ordinary units, not six newly authored heroes.
Original and edited source bytes preserved separately.
Source SHA256: 1a1fedb8f8fdc90307278ff39256461ba26c9cffb5bc72410896efc5d4db1632.
Magenta image SHA256: adddcb1310be7d960d0e689c272491b9fda2c47e30e7475abcf97dd5242c1696.

## Exact generation prompt

Use case: stylized-concept. Asset type: Pirate Island ordinary troop sprite identity sheet, six isolated full-body adult units in a strict 3-column 2-row grid. Provided image is rendering STYLE and elevated three-quarter GAME CAMERA reference only, not western costume content. Match its compact readable detailed pixel-art clusters and dark contours, not realistic portraits. All six stand in neutral combat-ready idle facing screen down-right, viewed from clearly ABOVE: show hat/hood tops, tops of shoulders, torso foreshortening and planted feet. Same camera elevation and pixel scale across all. Top row adult males: column1 colonial line marine, dark blue period coat, cream cross-belts, tricorn, brown knee breeches and boots, long flintlock musket; column2 pirate deckhand, sun-browned weathered face with short beard, red headcloth, open cream shirt, striped waist sash, dark loose breeches, sturdy boots and cutlass; column3 living Cthulhu cultist, angular attractive adult face, dark sea-green hooded layered robes, barnacle-encrusted shoulder mantle and short ritual staff with subdued turquoise light. Bottom row corresponding adult female units, visibly shorter and slimmer than males (all clearly adults 20 years old): column1 colonial female marine with cute determined face, dark tied-up hair under tricorn, blue fitted period waistcoat over cream sleeveless bodice, fitted knee breeches, stockings and boots, same long musket; column2 pirate female deckhand with chestnut braid and red headcloth, fitted cream period bodice, red waist sash, dark breeches and boots, cutlass; column3 living female Cthulhu cultist with beautiful pale face, black hair framing face beneath sea-green hood, fitted layered sea-green ritual tunic, side-split overskirt over fitted trousers, dark boots, ritual staff. Women small-breasted and slim, PG13 fully clothed, no nudity, no childlike proportions. All are ordinary recruitable faction units rather than glamorous hero portraits. Distinguish soldiers' disciplined upright stance, pirates' loose agile stance, cultists' unsettling quiet stance. No names or text, no numbering, no scene, no ground tile, no cast-shadow puddle, no banners, no borders, no watermarks. Genuine fully transparent alpha background, DO NOT DRAW checkerboard. Equal cells and generous separation, complete weapons and feet inside cells. High quality crisp pixel game sprites, not painterly, no smooth gradients, no 3D, no modern equipment, no floating props. Each unit one unique design, no duplicates.

## Background correction prompt

Change ONLY the checkerboard background to completely uniform flat saturated MAGENTA #FF00FF. Keep these six full-body pixel-art soldiers exactly in place, same face/costume, same scale, same camera and all weapon silhouettes. Remove white/gray checker pattern also in spaces between arms, legs and weapons. This is a solid chroma-key source for deterministic extraction; do NOT draw transparency checkerboard and do NOT add gradients, shadows or text. Keep foreground art unchanged.

## Inspection

source.png is 1254 x 1254 RGB: transparency request failed; baked checkerboard.
keyed-source.png has visually uniform magenta background suitable for testing
the established Cattle Trail chroma-key method. It is not an alpha atlas yet.
Six separate silhouettes present; top row male colonial, pirate, living cultist;
bottom row their female counterparts. Women visibly shorter/slimmer.
Elevated view reads better than Michael's first standing sheet. Pirate male
and female lean closer to frontal than colonial/cultist; facing requires correction.
Female marine's requested sleeveless silhouette was not retained.
All poses are idle only, not walking. Costumes remain candidates, not final approval.

## Extraction plan

Actual layout is 3 columns by 2 rows. No assumed 4-by-4 animation grid.
Do not run Cattle Trail's current hard-coded 4-by-4 script unchanged.
Use shared binary magenta key (red-green >25 and blue-green >25), trim actual
silhouettes, common scale per body class, authored ground pivots, nearest sampling,
and inspect edges at game scale before accepting any output.
Do not count this keyed edit as six additional designs.
