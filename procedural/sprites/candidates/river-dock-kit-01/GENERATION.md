# River dock component kit 01

Status: generated candidate, not runtime admitted. Built-in imagegen, no paid API used. Source-only production; no room assignment or topology inferred.

## Exact initial prompt

Use case: stylized-concept. Asset type: reusable 2D pixel-art dock component sprite sheet. Both supplied images are STYLE-ONLY references: match the Cattle Trail camp chest, rope coil, fence timber, wagon wood and actual gameplay pixel scale. Do not copy their UI, people, cattle or geography. Create ONE coherent sheet with exactly six isolated objects in a spacious 3 columns by 2 rows grid, each fully contained with clear transparent gutters: top row straight weathered plank dock segment; L-shaped dock corner; shallow wooden access ramp. Bottom row pair of timber pilings connected by a hanging rope; single short wooden mooring bollard; compact coiled rope resting beside a wooden cleat as one combined prop. True transparent background, not checkerboard painted into image; no water, shore, ground patches or cast ground shadows. Fixed high three-quarter top-down gameplay camera, same perspective for every piece, consistent upper-left daylight. Hand-authored-looking crisp pixel clusters, strong dark brown contours, broad readable warm ochre wood planes, short selective grain marks, restrained 5-7 shade timber ramp. Comparable to the supplied game's camp/fence sprites, not realistic 3D renders, not vector, not smooth painterly textures, not fine stippling. Straight segment and corner share plank width, deck thickness and construction. Deck segments without railings so actors can use them, visible short support structure; no decorative extra objects. Compact sprite design readable around 80-180 gameplay pixels wide. No text, labels, borders, symbols, logos, boats or characters.

## Inputs

Style-only: existing Cattle Trail `overview.png` and actual `companion-room.png` gameplay screenshot. Both were inspected before generation, including camp rope/chest and fence wood forms. Generated output `exec-6bd1d920-23a7-470a-be62-7c74b523129f.png`.

## Background correction exact prompt

Change ONLY the background of this sprite sheet: replace every white and grey checkerboard pixel outside objects and in object openings with perfectly flat solid magenta #FF00FF, no checkerboard and no gradient. Preserve all six wooden subjects, their exact positions, pixel-art style, sizes, silhouettes, grain, outlines, ropes and lighting unchanged. No added text or objects. Magenta production extraction matte only.

Correction output `exec-0dfead2a-cac8-4da6-ae12-aeb9b9f109ef.png`, saved as `source-02-magenta.png`. Initial source SHA256 `e686418e36e4f6c5cc29ae500a549ed3cba252f21c3adf710b2303ffe8dc0ac7`. Overview reference SHA256 `7af7b4d9b8fe9c98503eb516f3d4684b2d65df46e09882c9d35872324757e03c`; gameplay reference SHA256 `e28c787bf1ef8758edc1a99bb2433f53a0b4ddfd1eb637222535ade658539c79`.

## Extraction and review

Reused `cattle-trail/sprite_grid.py source-02-magenta.png extracted-01 --columns 3 --rows 2 --min-component-pixels 1`. Six RGBA cutouts, zero cut warnings, zero removed small pixels; exact source/extractor/output hashes and dimensions in extraction metadata. No resizing. Corrected full sheet inspected: silhouette and layout retained, some wood grain repainted by edit (not pixel-identical); no water or cast-ground layer. Extracted rope/cleat inspected: opening keyed cleanly. Compact/native-size review remains consumer work, not claimed from these checks. Source references remain owned by their respective Cattle Trail pipeline, used as style references only. Built-in tool model version was not exposed; no paid API call or third-party download.

## Initial review

## Estimated connector assembly follow-up

`kit.json` now contains estimated top-surface polygons and named socket edge endpoints for straight, corner and ramp. Screen coordinates come from inspecting the extracted PNGs. They are not collision, walkability, world coordinates, or MUD exit authority. `build-assembly-review.mjs` embeds the canonical shared `alignSpriteEdge` implementation into an offline HTML preview; run it from this directory or repository root with Node. Open `assembly-review.html` directly, with adjacent PNGs retained. The overlay checkbox shows estimated deck polygons and both edge positions.

Visual inspection of `assembly-review.png` confirms an L end plus two straight sections can form a coherent long deck without rotating/mirroring or redrawing the sprites. Measured endpoint residuals are 1.517 and 5.858 source-review pixels under an explicit 6-pixel inspection allowance. The second seam remains visibly offset; plank grain and skirt/piling positions do not become continuous merely because connectors approximately meet. This is a candidate assembly, not seamless admission. Ramp excluded due to unknown elevation matching. The corner branch has the opposite projected slope and requires another directional component. No runtime test performed. Local component HTML capture only; browser closed afterward.

Six requested subjects present, coherent ochre timber palette, dark silhouette contours, no water or characters. L-corner and straight deck share construction but mating-edge alignment is not established. Ramp is steeper than requested; treat as sloped access candidate, not an authored navigation incline. Output is RGB with baked checkerboard despite transparency request. Preserve original; request background-only magenta correction for existing extractor.
