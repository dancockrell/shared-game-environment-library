# Flat ground path overlay candidates

## Current source: corrected genuine alpha, 2026-09-08

`source-02-alpha-correction.png`, built-in `exec-06195077-4346-4098-86eb-5a9ce11fc9db.png`, SHA256 `ecff27407c6c3921878f2fab66640c3c6d7d2577b734ab7ab8da9afff92e6004`, is actual RGBA with alpha range 0–255. One bounded background-extraction edit used original source-01 as explicit input. Four subject identities/positions broadly preserved, but generative edit changed fringe and grass coloring, so not pixel-exact preservation. Existing sprite_grid produces `extracted-03` with binary alpha threshold 128 and zero cut warnings; source retains original soft alpha. `kit.json` now points only to corrected source/extraction.

Exact correction prompt:

Background extraction edit only. Make this exact four-sprite ground overlay sheet genuinely transparent RGBA with transparent empty pixels, NOT a picture of a checkerboard. Remove ALL bright magenta background and the pink/red color contamination on the ragged earth/grass edges. Restore those contaminated edge pixels to their natural warm earth brown or olive grass color, with clean alpha outside. Keep exact four sprite identities, stone arrangement, grass direction, shapes, positions, scale, cropping and camera unchanged. No new background, no grey/white checker pattern, no extra objects, no shadows, no geometry changes. Real alpha transparency is the deliverable.

`alpha-correction-review.png` inspected at 200px wide on both dark and light backgrounds. Earlier conspicuous pink outline is no longer visible at this size; source review passes as a candidate. Grass looks more yellow/olive than Town Green and still requires palette compatibility review. No gameplay or runtime admission. Old review.png and extracted-01/02 remain historical rejected evidence, not current recommendations. No second extraction implementation or green-key extension was added.

Built-in imagegen, 2026-09-08, no paid API. Actual Cattle Trail gameplay reference viewed and explicitly supplied: `C:/Users/Admin/Documents/Codex/2026-09-07/referenced-chatgpt-conversation-this-is-an-2/outputs/cattle-trail/companion-room.png`, SHA256 `e28c787bf1ef8758edc1a99bb2433f53a0b4ddfd1eb637222535ade658539c79`.

## Description evidence

Read actual lore entries in DR `data/art/room-prompts-priority.json`, not its legacy art prompts. Room 1-14 explicitly describes a small path of bent grass leading to a narrow stretch of cobblestones between grass and privet hedge before Milgrym. Room 1-16 describes a gap in lunat trees and grass with dense hedges but no explicit cobblestone path. Room 1-17 describes soft spongy well-manicured grass and ancient oak, not a worn path or cobbles. Consequently this kit is compatible material evidence for 1-14 only, not automatic assignment to all three rooms. Exact road geometry remains unspecified.

Existing source families inspected first: ground-plank-approach is wood, masonry contains raised wall/stair props, vegetation has no cobble or bent-grass overlay; Cattle Trail overview contains scattered rock/grass props rather than these bounded continuous strips. New bounded component sheet justified; no full room generation.

## Exact prompt

Use case stylized-concept. Four reusable FLAT GROUND OVERLAY SPRITES in a 2x2 sheet, isolated on pure solid magenta RGB255,0,255 for chromakey extraction. STYLE ONLY from supplied actual Cattle Trail gameplay screenshot: modest pixel density, broad readable clustered pixels, warm muted ground colors, crisp hand-drawn pixel edges. NO 3D. Elevated three-quarter gameplay camera, all surfaces lie FLUSH on ground plane, zero thickness, NO vertical side faces or raised slabs. Top left narrow straight band of small irregular grey cobblestones, diagonally left-bottom to right-top, around five stones wide and twelve long, naturally uneven feathered edge, no curb. Top right narrow gently bending cobblestone band, same stone size and material, ends readable. Bottom left narrow straight strip of worn/bent meadow grass, flattened muted olive blades in broad clusters, mostly green grass not bare dirt, slightly scattered feathered edge, same diagonal flow as cobbles. Bottom right gently curving strip of bent/worn olive grass, same texture and width. Each independent segment occupies its own equal grid cell with wide solid magenta gutters and is fully visible, no subjects crossing cell boundaries. No checkerboard, no labels, no text, no scenery or trees, no ground islands, no diamond tiles, no shadows outside ground surface, no tall grass tufts, no rim. These are overlays laid on existing grass, not full scenes, no seamless promise.

## Provenance and extraction

Source `source-01-magenta.png`, built-in `exec-23bf2cd2-8cd3-42bc-8af4-60ab1f1a73ab.png`; SHA256 `19b871e8273f7c63773cf32a0db989b5ea10bd7169bd7fbbe3c6a68d6b146c3e`. Existing Cattle Trail `sprite_grid.py --columns 2 --rows 2 --min-component-pixels 1` produced four RGBA crops with no cut warnings. No resize, all retained components preserved. Exact hashes and source rectangles in extracted metadata. One generation, no corrective regeneration.

## Production review

One bounded cleanup experiment uses existing extractor `--key-difference 5` into `extracted-02`; it reduces some fringe but still leaves reddish contamination in the source dirt fringe. Its first cobble crop was visually inspected and is NOT admitted. Keep canonical candidate metadata pointing to extracted-01; extracted-02 is a documented cleanup experiment, not a parallel runtime pipeline. A clean edge source is the next production need.

Source sheet inspected: cobbles are flush small stones without raised slab sides, grass strips are flattened and ragged rather than tall tufts. No scene or supports. Native-size contact review at 200 px wide is source-only, not gameplay. IMPORTANT: review.png exposes pink/magenta contamination around ragged edges that the binary key does not remove; these crops are NOT ready for runtime and require edge cleanup or a clean regeneration. This is a failed alpha-admission gate despite structurally valid extraction. Grass is olive/dry, requiring palette review against greener Town Green grounds. All strips taper and have distinctive ends; no seamless tiling or connector guarantee. Centerlines and anchors are estimates only. No game state or collision inferred. No DR edits or tests, no server launched. Generated source is candidate under applicable built-in tool terms; runtime admission separate.
