# Colonial female marine — ordinary-unit candidate review

Reviewed 2026-09-08. **Source-size candidate suitable for a provisional standing appearance; not final runtime or animation approval.** No new generation, retouching, runtime change, or credit expenditure in this review.

## Identity and battlefield purpose

An adult colonial line marine: disciplined, practical, impatient with officers who waste soldiers. She carries a long musket as a practiced tool rather than a decorative accessory. Her fitted blue waistcoat, pale rolled-sleeve shirt, tricorn, brown knee breeches, pale stockings, and boots make her recognizable as a colonial soldier without giving her a hero's costume. She belongs to the ordinary named population; generate her personal name and history through the same system as other ordinary NPCs. Do not invent a unique permanent hero identity for this sprite.

Her useful contrast with Michael is composure: while his machinery and daring make the spectacle, she establishes a firing position and works through the reload. Romance characterization can emerge from trust, humor, and disagreements about orders, rather than making her recruitment a new combat class. This is a proposed small character-content seed, not additional faction doctrine.

## Small, implementable kit

- **Musket shot:** use the existing colonial marine combat profile unchanged: 12 health, 3 damage, range 4 map cells, cooldown 6 simulation ticks. These are current prototype tuning, not final balance or lore measurements. The female ordinary unit should not be weaker just because her presentation is smaller.
- **Stand and reload:** existing combat holding behavior stops movement while a hostile target is in range and line of sight; cooldown owns the reload interval. No second buff, stance resource, or duplicate timing system.
- **Movement / assigned position:** use the existing navigation and order system. She resumes her assigned travel when no valid firing target holds her. Party follow and party command are future callers of this existing movement system, not properties proven by this art.

No ultimate, strategic passive, party passive, magical recruitment aura, or invented hero ability. Ordinary troops do not need a hero's seven-part kit. Do not claim a firing animation: this asset depicts a musket held across the body, not an aimed shot.

## Recruitable encounter hook — proposed, not implemented

**An officer orders her post abandoned while wounded comrades remain.** She will not leave them merely because Michael is charming. Michael can help secure an evacuation route and resolve the situation with her. Her decision is a short authored conversation using the same recruit eligibility and faction-transfer machinery as other female NPCs; it need not require a combat encounter to end in a massacre.

The encounter has two independent facts: whether the endangered comrades were helped, and whether the departure was sanctioned or a desertion. A sanctioned transfer can improve relations; desertion can anger the colonial faction. Neither route makes every colonial woman follow the same quest or creates an immunity to Michael outside this encounter. Other circumstances can recruit other women. Males are not eligible for Michael's attraction-based transfer.

On recruitment, preserve this woman's persistent identity, origin, current health, and memories. Change faction membership and clear obsolete hostile orders; do not spawn a duplicate. Joining Michael's faction does not automatically occupy one of the four active companion slots. Once joined she does not voluntarily defect. Death and subsequent Cthulhu allegiance must preserve her identity and attachment, not turn her into a newly rolled stranger. These are the user's shared recruitment rules, not functionality added by this candidate note.

Acceptance for future implementation: recruitment produces one identity before and after transfer; original faction loses the unit; active party limit stays four women; outside-party recruits remain faction members; stale attacks cannot shoot a newly allied member; saved state preserves the transfer. Encounter-specific relationship deltas remain tunable and are not specified here.

## Source and exact candidate mapping

- Existing source: `source.png`, SHA256 `1a1fedb8f8fdc90307278ff39256461ba26c9cffb5bc72410896efc5d4db1632`.
- Keyed source: `keyed-source.png`, SHA256 `adddcb1310be7d960d0e689c272491b9fda2c47e30e7475abcf97dd5242c1696`.
- Cutout: **`extracted/cell_01_00.png`**, SHA256 `21fec70f5a4d0ba2564b055f3d36ec120b26f0ab117a911f77d5fc04acdde7b5`.
- Original source crop: `[155,687,372,1043]`, right/bottom exclusive; cutout 217 by 356 pixels. No further crop is needed.
- Proposed ground pivot: **`[85,356]`** in trimmed pixels, equivalent to `[240,1043]` in the keyed source. This is an authored initial placement choice beneath her body, not the center of the weapon-inclusive bounds; grounding still requires rendered review.
- Proposed common-scale comparison: current male colonial scale 0.105 produces 37.905 pixels of source-image height. The same female scale produces 37.38 pixels, barely different. Prefer initial female scale **0.092**, producing 19.964 by 32.752 pixels; this is approximately 86.4% of the male image height. It is a provisional silhouette-scale correction, not a claim of exact physical stature.
- Keep nearest filtering, no smoothing shader, and the existing binary alpha. Do not resize the preserved source merely to change runtime scale.

## Hard visual audit

**What works at source size:** full musket and both feet remain inside the crop. The tricorn, blue waistcoat, cream sleeves, brown breeches, and stocking breaks distinguish a soldier immediately. The compact stance reads as a person bearing the weapon rather than an unconnected prop. A slight elevated view and diagonal musket agree broadly with the faction sheet's camera. Slim adult proportions are suitable for the intended ordinary female pool. Clothes are covered and period-inspired; the requested sleeveless design was not retained, but this is a coherent rolled-sleeve soldier silhouette.

**What is weaker:** face and torso face largely right rather than strongly down-right, and the stance is broad. It must not masquerade as a directional turnaround. The face, embroidery, fingers, and musket fittings are much finer than a 33-pixel sprite can preserve. Source richness therefore cannot establish game-scale facial identity. The large diagonal musket makes bounding-box centering wrong for foot placement. There is no firing, walking, reload, hit, or death sequence.

**Alpha / provenance checks:** decoded RGBA has 44,981 transparent pixels and 32,271 opaque pixels, with no intermediate alpha values. Four-connected analysis finds one 32,268-pixel body component and a three-pixel detached detail at trimmed x118–119, y80–81, adjacent to the upper-torso detail; preserve it rather than silently deleting source content. Both components were retained by the original extractor. No checkerboard is baked into this cutout. Existing GENERATION.md records the exact generation and keying prompts and identifies the built-in generation route without declaring the asset CC0. This audit adds no new license claim.

**Open admission gate:** no native rendered game-scale comparison was performed. Inspect the proposed 0.092 scale against the male, Michael, terrain, and UI at the actual camera zoom before admitting the presentation as final. Check feet alignment, musket visibility, dark-edge contrast on foliage, and whether she remains clearly distinct from the male at play distance. Existing shared animation reviewer requires multiple frames; duplicating this idle into fake frames solely to satisfy it would be misleading, so it was not used. No motion claim is made.
