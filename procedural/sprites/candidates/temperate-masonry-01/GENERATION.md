# Temperate masonry component kit — candidate

Generated 2026-09-08 with the built-in imagegen tool, no paid API invocation. Original fantasy masonry, actual Cattle Trail reference inputs used for style only. Not runtime admitted and not assigned to any DragonRealms room.

## Reference evidence

- `../cattle-trail/overview.png`, SHA256 `7af7b4d9b8fe9c98503eb516f3d4684b2d65df46e09882c9d35872324757e03c`.
- `C:/Users/Admin/Documents/Codex/2026-09-07/referenced-chatgpt-conversation-this-is-an-2/outputs/cattle-trail/companion-room.png`, SHA256 `e28c787bf1ef8758edc1a99bb2433f53a0b4ddfd1eb637222535ade658539c79`.
- Both were viewed before generation and passed as explicit referenced_image_paths. Subject matter was not borrowed.

## Exact generation prompt

Use case: stylized-concept. Asset type: reusable 2D fantasy RPG masonry sprite sheet, SIX isolated independent components, 3 columns by 2 rows, generously separated, genuinely transparent background. Input image 1 and image 2 are STYLE REFERENCES ONLY: match the actual Cattle Trail sprite language, broad readable pixel clusters, strong dark brown contours, restrained compact palette, modest pixel density, crisp deliberate pixels and compact gameplay proportions. Do not copy text, UI, cowboys or scenery. NOT fine stippled illustration, NOT photorealism, NOT 3D render. Camera consistent elevated three-quarter gameplay view, seeing top and front and right sides; soft light from upper left. Original temperate fantasy assets: top left a straight waist-high coursed grey limestone wall section; top middle matching L-shaped limestone wall corner; top right CLOSED plain oak plank door with iron hinges within a compact enclosed timber-frame wall section, no cutaway interior. Bottom left simple plain stone arch doorway with dark recessed wooden CLOSED door, no ornate sculpture; bottom middle short broad flight of four worn limestone steps; bottom right matching low stone parapet with broad capstones, no battlements. Each object fully visible with generous transparent padding, no overlaps, no shared platform or ground island, no trees or grass, no cast shadow outside silhouette, no labels, no lettering, no checkerboard painted into image. Prioritize coherent reusable shapes with clear stone courses and a few readable chips rather than excessive tiny cracks. All six have matching material palette and lighting, game prop sheet not architectural concept poster.

## Corrective edit prompt

Precise background-only edit of this masonry sprite sheet. Preserve all six objects, their exact positions, shapes, sizes, pixel texture, colors and lighting unchanged. Replace ONLY the entire white and grey checkerboard background with perfectly solid flat vivid magenta RGB(255,0,255), including every gap between objects. No checker pattern anywhere. No new shadows, no new objects. This is a chroma-key production source.

## Sources and processing

- `source-01-checker-rejected.png`: built-in `exec-ca75adb1-8292-4c12-b147-7c134ba8280b.png`, SHA256 `90643418551534b9ec943622bd0ba075e75fb42605656fcdaa09f472956beba0`. RGB, fake checkerboard instead of alpha; rejected as delivery source, retained as generation evidence.
- `source-02-magenta.png`: built-in `exec-f592d247-9bca-4e8a-94f6-30dcdeeccb7d.png`, SHA256 `03b562aea7bbe18b4ea47deb453b1375536a8de23d46a826e7a1bc594b8fe5d9`. Same six component identities, chroma-key background correction. Exact pixel preservation was requested but is not guaranteed by generative editing.
- Existing `../cattle-trail/sprite_grid.py` run with `--columns 3 --rows 2 --min-component-pixels 1`. Six RGBA crops, zero cut warnings, zero removed foreground pixels, one connected subject each. Full provenance, source rectangles, pixel and file hashes in `extracted-01/metadata.json`. No new extraction implementation.

## Review and limitations

Full sheet and extracted timber doorway inspected. Clear dark silhouettes, broad stone courses and wood beams, coherent warm-grey stone palette. More compact and legible than fine stippled vegetation. Native-game-scale fidelity is NOT yet approved. Doorway generated stone infill beneath timber framing, not an all-wood facade; only use where compatible with description. It includes a flat top slab and is a frontage fragment, not a complete house. Both doors are visibly closed; artwork does not imply game lock/open state. Four stairs are illustrative and cannot determine graph elevation. Walls have closed ends and are not seamless tiles. Generic limestone appearance is not authority for named DR materials.

No runtime integration or in-game tests were performed by this production task. Collision footprints, attachment seams, scale against actors, and occlusion need consumer review. Do not mirror due to baked lighting. No licence claim is inferred from style reference ownership: generated output is retained as a candidate under applicable built-in tool terms; repository admission remains separate.
