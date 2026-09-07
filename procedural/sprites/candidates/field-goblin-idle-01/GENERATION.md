# Field goblin idle source

Status: extracted idle candidate; no runtime admission yet.

Built-in generation 2026-09-08 returned 1254x1254 RGB source, SHA256 `3e4a6feb04e5c47313c135ca21b2c281b968be3ab7fb8893424d4762043577d7`. Exact prompt below. No paid/API fallback. Source preserved as `source-01.png`.

Extraction: `python procedural/sprites/candidates/cattle-trail/sprite_grid.py procedural/sprites/candidates/field-goblin-idle-01/source-01.png procedural/sprites/candidates/field-goblin-idle-01/extracted-01 --columns 2 --rows 2 --min-component-pixels 1`. Reuses the shared helper read-only, hash `d6aa76d7ba4f74209b3022ead3b4a8fbc0704a03a4f34b04059b215ce4f0ac4d`. All four frames are 296x556 RGBA, no gutter warnings or discarded small pixels. `metadata.json` preserves source trim rectangles and every output hash.

Source visual review: consistent short adult silhouette and cloth design, four planted-foot poses, visible half-close and closed-eye blink; no weapons or invented action. Exact trim dimensions match. Slight detailed texture variation is not proof of perfectly unchanged pixels. Fixed manual shoe-ground anchor [166,533], source scale0.2 in existing reviewer. Cadence 2600/100/140/220ms. Needs actual client view and motion acceptance; shared status remains candidate until parent integrates the exact name through existing creature curation.

Source authority: DR Companion `data/elanthipedia/bestiary.json`, entry `Field goblin (1)`: Zoluren, Tiger Clan, maps 3 and 4; little biped humanoid, melee, uses weapons, nonmagical. Description: standing on two legs, somewhat small like a Dwarf, passive but wary. This is not a claim of spawning in Town Green South. Olive skin, pointed ears, brown tunic and empty hands are artistic presentation choices, not additional lore facts. Equipment cannot be treated as live inventory.

Contract: richly shaded crisp illustrated pixel art matching current sprite-first DR presentation; fixed high three-quarter view facing down-right; short adult humanoid, no chibi proportions; neutral/blink idle only; no movement or combat outcomes. Four equal cells, 2x2 square source, matching scale, planted feet, consistent palette and light. Solid magenta source for the existing Cattle Trail extractor; ordinary RGBA frame files for review. No paid API route.

Exact built-in image-generation prompt:

Use case: stylized-concept. Asset type: premium 2D fantasy game sprite idle source sheet. Square canvas divided invisibly into exactly 2 columns and 2 rows of equal square cells; solid perfectly flat vivid magenta #FF00FF background for chroma key, NOT a transparency checkerboard. Four sequential frames of ONE identical field goblin. Full body short adult humanoid, dwarf-sized proportions, olive leathery skin, pointed ears, long angular nose, dark wary eyes, short dark hair, patched earth-brown linen tunic with covered torso, worn charcoal trousers, simple leather belt and soft brown shoes. Empty relaxed hands. Passive but alert, not snarling, not cute or chibi. Fixed high three-quarter top-down gameplay camera, facing diagonally down-right. Rich detailed crisp pixel-art clusters, beautiful warm directional highlights from upper left, deep coherent earthy shadows, restrained outline, no smooth glossy 3D. Frame 1 neutral eyes open. Frame 2 eyelids half-close. Frame 3 blink eyes closed. Frame 4 same eyes-open neutral as frame 1. Only eyelids move; lock every foot, knee, arm, hand, head, ear, clothing fold, silhouette and location at exactly matching local coordinates in every cell. No body bounce, no walking, no size or lighting changes. Every figure fully inside its cell with wide identical magenta gutters, visible shoes and head, no cropping. No shadows outside the character, no ground, no weapons, no text, no labels, no grid lines, no other objects. Four frames of the SAME goblin, not four different designs. Magenta must not appear inside the goblin.

## Prone status candidate

`prone-source-01.png`:1254x1254 RGB, SHA256 `f874cb26079ed37d4fdaf3e769a0b280a1949df414f6b3be55445ab121be7af5`.
Same shared extractor command with `--columns 1 --rows 1 --min-component-pixels 1`
to `prone-extracted-01` produced974x504 RGBA, no warnings/no removed pixels.
Source and alpha cutout visually inspected: same face/costume identity, open
alert eyes and limbs readable on ground, not a corpse. `pose.json` records
manual belly-ground anchor and tentative0.7 source-scale calibration because
the new single-subject source has more pixels per head than the standing sheet.
This requires client calibration; never independently fit this horizontal pose
to the standing pose's width. No production-state mapping added by this asset.

Parent verified bridge combatant statuses include `prone`; there is no identified
per-hit animation event. Therefore this is a single static status pose, not an
attack, death, damage outcome or fall animation. Not admitted until runtime
explicitly consumes authoritative prone status.

Exact built-in prompt, using source-01.png as identity/style reference:

Use case: identity-preserve. Asset type: ONE full-body field goblin prone status sprite, NOT a sprite sheet. Input image is identity and pixel-art style reference: use its upper-left eyes-open goblin only. Render that exact same short adult olive-skinned goblin, same angular long-nosed face and pointed ears, dark short hair, patched brown tunic with covered torso, charcoal trousers, brown shoes, belt, empty hands, under exactly the same high three-quarter gameplay camera and upper-left light. Change only pose: he is alive and lying prone on his stomach along a diagonal, head toward lower-right and feet toward upper-left. Elbows bent, hands on the ground beside his shoulders, head slightly raised with alert eyes; both legs extended behind with visible shoes. A grounded readable silhouette, no tucked sitting pose, no flying, no standing. Preserve body proportions and costume identity; same richly shaded crisp earthy pixel-art clusters, no smooth 3D. ONE goblin centered on a perfectly flat solid #FF00FF magenta background for chroma key. Whole body comfortably inside frame with generous margins. No ground illustration, no external cast shadow, no weapons, no blood, no wound, no death symbolism, no text, no grid, no checkerboard. This is a recoverable prone posture, not a corpse. Landscape composition within a square image.
