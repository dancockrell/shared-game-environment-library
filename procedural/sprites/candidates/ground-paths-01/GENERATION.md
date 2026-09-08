# Flat ground path overlay candidates

Built-in imagegen, 2026-09-08, no paid API. Actual Cattle Trail gameplay reference viewed and explicitly supplied: `C:/Users/Admin/Documents/Codex/2026-09-07/referenced-chatgpt-conversation-this-is-an-2/outputs/cattle-trail/companion-room.png`, SHA256 `e28c787bf1ef8758edc1a99bb2433f53a0b4ddfd1eb637222535ade658539c79`.

## Description evidence

Read actual lore entries in DR `data/art/room-prompts-priority.json`, not its legacy art prompts. Room 1-14 explicitly describes a small path of bent grass leading to a narrow stretch of cobblestones between grass and privet hedge before Milgrym. Room 1-16 describes a gap in lunat trees and grass with dense hedges but no explicit cobblestone path. Room 1-17 describes soft spongy well-manicured grass and ancient oak, not a worn path or cobbles. Consequently this kit is compatible material evidence for 1-14 only, not automatic assignment to all three rooms. Exact road geometry remains unspecified.

Existing source families inspected first: ground-plank-approach is wood, masonry contains raised wall/stair props, vegetation has no cobble or bent-grass overlay; Cattle Trail overview contains scattered rock/grass props rather than these bounded continuous strips. New bounded component sheet justified; no full room generation.

## Exact prompt

Use case stylized-concept. Four reusable FLAT GROUND OVERLAY SPRITES in a 2x2 sheet, isolated on pure solid magenta RGB255,0,255 for chromakey extraction. STYLE ONLY from supplied actual Cattle Trail gameplay screenshot: modest pixel density, broad readable clustered pixels, warm muted ground colors, crisp hand-drawn pixel edges. NO 3D. Elevated three-quarter gameplay camera, all surfaces lie FLUSH on ground plane, zero thickness, NO vertical side faces or raised slabs. Top left narrow straight band of small irregular grey cobblestones, diagonally left-bottom to right-top, around five stones wide and twelve long, naturally uneven feathered edge, no curb. Top right narrow gently bending cobblestone band, same stone size and material, ends readable. Bottom left narrow straight strip of worn/bent meadow grass, flattened muted olive blades in broad clusters, mostly green grass not bare dirt, slightly scattered feathered edge, same diagonal flow as cobbles. Bottom right gently curving strip of bent/worn olive grass, same texture and width. Each independent segment occupies its own equal grid cell with wide solid magenta gutters and is fully visible, no subjects crossing cell boundaries. No checkerboard, no labels, no text, no scenery or trees, no ground islands, no diamond tiles, no shadows outside ground surface, no tall grass tufts, no rim. These are overlays laid on existing grass, not full scenes, no seamless promise.

## Provenance and extraction

Source `source-01-magenta.png`, built-in `exec-23bf2cd2-8cd3-42bc-8af4-60ab1f1a73ab.png`; SHA256 `19b871e8273f7c63773cf32a0db989b5ea10bd7169bd7fbbe3c6a68d6b146c3e`. Existing Cattle Trail `sprite_grid.py --columns 2 --rows 2 --min-component-pixels 1` produced four RGBA crops with no cut warnings. No resize, all retained components preserved. Exact hashes and source rectangles in extracted metadata. One generation, no corrective regeneration.

## Production review

Source sheet inspected: cobbles are flush small stones without raised slab sides, grass strips are flattened and ragged rather than tall tufts. No scene or supports. Native-size contact review at 200 px wide is source-only, not gameplay. Grass is olive/dry, requiring palette review against greener Town Green grounds. All strips taper and have distinctive ends; no seamless tiling or connector guarantee. Centerlines and anchors are estimates only. No game state or collision inferred. No DR edits or tests, no server launched. Generated source is candidate under applicable built-in tool terms; runtime admission separate.
