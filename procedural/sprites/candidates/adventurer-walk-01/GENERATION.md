# Adventurer walking sprite candidate

Status: raw generated candidate, not runtime admitted. Built-in image generation;
not a Blender render or executed animation. User cowboy sprite sheet is a style
reference, not a source of DragonRealms guns or lore. Original PNGs preserved.

## Original generation prompt

Use case: stylized-concept. Asset type: high-quality fantasy game directional walking sprite sheet, raw animation candidate for DR Companion. Input Image 1 is STYLE REFERENCE ONLY: retain its detailed illustrated pixel-art rendering, crisp dark contours, carefully clustered warm shading, expressive readable anatomy and high three-quarter top-down gameplay perspective. Replace cowboy and horse with ONE consistent original adult fantasy woman adventurer on foot, chestnut braid, teal short traveling cloak, fitted practical brown leather jerkin over cream sleeves, dark trousers, sturdy boots, small belt pouch and sheathed sword. No guns or western hats. Create exactly 24 full-body sprites in a strict uniform 6-column by 4-row grid, ample transparent gutters, equal scale and aligned ground anchors. Each cell contains exactly one isolated adventurer, never two figures. Row 1 six consecutive walk-cycle phases facing screen down-right. Row 2 same six phases facing down-left. Row 3 same six phases facing up-right showing back. Row 4 same six phases facing up-left showing back. Each row: left heel contact, weight down, passing, right heel contact, weight down, passing; anatomically coherent opposing arm swing and controlled cloak sway, not repeated identical poses. Keep exact character identity, costume details and equipment attachments constant. Fixed high three-quarter camera elevation and fixed soft upper-left lighting throughout; no lighting changes by frame, no dramatic cast shadows. Beautiful polished detailed pixel art, not smooth vector art or 3D render, not chibi, no blurry edges. Truly transparent background with alpha, NO checkerboard drawn into the art, no scenery, no ground, no text, no labels, no dividers, no logos. Rectangular landscape sheet, consistent crisp pixel scale. This is meant for frame extraction, so prioritize individual silhouettes, clean spacing and consistent framing.

## Correction

Second built-in call used source-01 as reference and requested only row four
face upper-left from behind, preserving the other rows and character design;
requested true alpha again. The generated result is source-02.png.

## Inspection

Source-02: 1536 by 1024, RGB (no alpha). Checkerboard is baked in; do not
describe this as transparent or ship it as a sprite atlas. Six columns and
four rows visible. Opposite rear directions corrected. Strides remain too
similar in places; equipment-side consistency, pixel grid, pivots and playback
need inspection and correction. No tested animation cadence or seamless loop.
Keep actual MUD traversal authoritative; these visual poses cannot issue moves.

Next: isolate one character anchor, resolve genuine background removal, then
build and visually inspect one directional cycle before expanding the library.
For video generation use one isolated character, not this entire sheet as
the starting frame. Preserve selected frame bounds, foot anchors, durations,
direction, action, source hashes and review status in the existing pipeline.
