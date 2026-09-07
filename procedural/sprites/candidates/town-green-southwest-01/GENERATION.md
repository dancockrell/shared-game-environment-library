# Town Green Southwest — room 1-23

Status: candidate; no runtime admission yet.

Consumer: existing DR Companion room backdrop, landscape 1536x1024,
contained in tactical room stage with independently rendered actors. Static
opaque PNG; no baked characters, UI or movement. Built-in image generation,
no paid external API. Generation date 2026-09-08.

Source: DR `public/roomtext/1.json` room `1-23`, compiled from canonical
`data/art/room-prompts-priority.json` through `room-place-map.json`:

> The hedgerow to the west meets the row of tall lunat trees that separates the Town Green from the commercial traffic on Lunat Shade Road due south. The growth is especially dense here, with no way to slip past either of the living fences. The small thorns on the hedges, to keep out stray livestock in search of prime pasture, look daunting in any case.

Style reference: admitted neighboring `town-green-south-01/source-02.png`,
runtime `town-green-south.png`, SHA256
`a2b74edc3770de5aff4869c205979443a2263febedef2676be8fc51ce4b3ab6a`.
Lunat foliage morphology and the exact visible corner geometry are artistic
interpretation. No cardinal screen mapping is asserted. The road is context
beyond the boundary; this plate must not invent a traversable hedge opening.

## Exact prompt

Use case: stylized-concept. Asset type: one detailed pixel-art fantasy RPG room background, landscape 1536x1024. Image 1 is a STYLE reference for palette, pixel texture, camera elevation, soft daylight and grass detail, NOT a geometry target. Build the neighboring Town Green Southwest: a dense thorny hedgerow meets a continuous row of tall mature lunat trees, forming an unmistakably CLOSED living-fence corner. Dense interlocking shrubs under the trees; small thorns visible on some foreground hedge twigs. Broad beautiful grass occupies the central playable ground with fine blades, subtle wear and soft dappled shadows. Keep the centre and the mid-right actor area open and legible. Show the two thick living boundaries meeting along two outer edges in this elevated three-quarter top-down view. No opening, gate, path through either boundary, or gap at the corner. Match the reference's polished detailed illustrated pixel-art language, restrained natural greens, rich foliage depth and consistent upper-left daylight. Lunat trees are a fantasy species: use the reference's mature broadleaf look as artistic continuity, not a new invented botanical claim. Beyond the living fence, Lunat Shade Road stays hidden; no new buildings or landmarks. No characters, animals, monsters, people, signs, text, UI, watermark, horizon, dramatic camera, blur, or photorealism. A single coherent scene, not a grid or sprite sheet.

## Admission gates

Verify dense closed corner, separate hedge/tree silhouettes, no false passage,
readable actor space, consistent camera/light/style, original file/hash retained,
and actual-client crop with correct room prose. Do not promote from source alone.

## Source review

Built-in output `exec-9bbe83c7-b64f-4b18-b340-991e9e0b35fa.png`, copied
unchanged to `source-01.png`. Full-size review: continuous thick lower/left
hedge meets densely undergrown mature tree row; no traversable boundary gap.
Fine foreground twigs suggest thorns without turning the scene into a barrier
diagram. Clear central/right grass is available to the radar actors. Lighting
and palette are consistent with the neighboring plate. Exact plant species
morphology is interpretation, not a botanical reconstruction. No baked actors,
text or buildings. Source accepted for mounted review, not final user approval.
