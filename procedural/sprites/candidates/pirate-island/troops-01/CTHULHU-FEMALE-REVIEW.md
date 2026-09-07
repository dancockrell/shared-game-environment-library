# Cthulhu ordinary female cultist — character and sprite review

Reviewed 2026-09-07 UTC. **Candidate, single standing pose only. Not an approved animation or an admitted runtime asset.** This note reviews an existing design; it neither creates a new hero nor adds a permanent canonical name. Runtime and recruitment implementation belong to the parent game task.

## Character contract

**Display role:** living cultist. Give each spawned individual a persistent generated personal name through the shared NPC system, not through this sprite filename.

**Concept:** a slight, composed young adult woman whose quiet certainty is more unsettling than frenzy. She has surrendered her judgement to the sea-green cult and carries its ritual staff as an ordinary soldier carries a weapon. The robe, hood and small cold light identify her allegiance before her face is readable. She is a person serving a faction, not a generic undead monster and not automatically a major romance character.

Her useful battlefield distinction is short-range ritual fire from behind the front rank. It is **not** a new hero power package. The existing drowned-cultist definition can serve male and female instances with different identity and appearance metadata. Sex must not be inferred from the selected PNG at runtime.

Keep the current ordinary-unit kit as the first integration baseline:

| System | Existing baseline | Meaning |
|---|---|---|
| Unit definition | `actor_def.cthulhu.drowned_cultist` | Reuse the current ordinary cultist, not a duplicated female class. |
| Health | 9 | Fragile compared with a colonial marine. |
| Attack | 2 damage, range 3 cells, cooldown 4 ticks | One ritual strike using the existing combat simulation. |
| Production | Drowned shrine; 3 ticks; 2 ritual control + 1 dream; population 1 | Current prototype economics, not final balance. |
| AI role | Faction-directed soldier | Existing range holding, target selection, movement and siege rules. |

These values were read from `godot-rust/src/world.rs` and `content/production/drowned_shrine_cultists.json` in Project 42. They are not new promises about completed recruitment or spell animation. Do not give this ordinary woman a personal madness aura, faction-wide resurrection or a hero ultimate merely to make the character sheet longer. Madness and midnight resurrection remain faction/campaign systems.

## Recruitment encounter proposal — not implemented

**Situation:** Michael encounters this living cultist away from a dense hostile group. She initially speaks in the cult's borrowed phrases, but remembers a personal detail from her generated history. That detail provides the short encounter's human thread.

**Actionable structure:** identify a concrete source of her present binding; complete its authored counter-condition; return and make a recruitment offer. For an ordinary generated encounter, the counter-condition can be recovery of her personal keepsake from an accessible site. A stronger binding can instead require an appropriate artifact. The condition must exist as persistent quest state and a reachable objective, not a vague charisma judgement or an invisible permission check.

**Resolution:** when the conditions and relationship state allow acceptance, transfer this same NPC instance to Michael. Preserve name, history, equipment and identity; cancel hostile queued commands and faction assignment. Offer an active companion slot separately. Joining the faction does not automatically replace one of Michael's four companions.

The premise is recovery of an individual connection, not “hurt her until she joins.” Low HP is not a recruitment trigger. These proposed conditions are encounter variation, not blanket female protection: all female NPCs remain potentially recruitable under the right conditions. Males/non-females are outside Michael's recruitment mechanic. This source depicts a **living adult**; it supplies no proof of an undead variant. If she later dies and returns under Cthulhu, preserve her identity and attachment to Michael so reacquisition can use that history. Do not treat death as voluntary defection or erase her bond.

No universal quest requirement is established here. The eventual recruitment system must support simpler and harder circumstances, rather than imposing a keepsake task on every ordinary woman. Diplomacy consequences belong to the encounter/faction outcome, not the bitmap.

## Exact source and extraction audit

Candidate file: `extracted/cell_01_02.png` beside this note.

- PNG SHA-256: `2929cb62163b3450b7f4b586f954a909a7f4ffcf86de9fca016c45cb400783a8`.
- Decoded image: 224 × 360, RGBA.
- Decoded RGBA SHA-256 recorded by extraction: `e4fd9da6887524ea7a818e1bb1ebde12e19507d97370fbf8655d3afe12ae2bca`.
- Source cell: row 1, column 2 of `keyed-source.png`, cell rectangle `[800,612,1254,1254]`.
- Trim rectangle in source coordinates: `[905,687,1129,1047]`; right and bottom exclusive.
- Keyed-source PNG SHA-256: `adddcb1310be7d960d0e689c272491b9fda2c47e30e7475abcf97dd5242c1696`.
- Original generated source PNG SHA-256, before background edit: `1a1fedb8f8fdc90307278ff39256461ba26c9cffb5bc72410896efc5d4db1632`.
- Live pixel check: 41,254 opaque pixels; 39,386 transparent pixels; alpha values only 0 and 255; one four-connected opaque component.
- Live check found zero visible pixels matching the extraction's magenta-difference rule. This proves no surviving key-color pixels under that rule, not perfect edge quality.
- No image was generated, edited, rescaled, re-keyed or exported in this review. No credits spent.

Generation prompt, background correction and tool provenance remain in the existing `GENERATION.md`; extraction settings remain in `extracted/metadata.json`. Those files are authoritative rather than duplicated instructions here. Generated art is not automatically CC0.

## Visual judgement

Inspected the actual transparent female PNG and corresponding male cultist PNG at source size.

**Works:** compact sea-green silhouette, pale face, black hair at the face opening, hood top visible, small turquoise staff focal point, complete boots and weapon. The down-right face and visible shoulder/hood tops support the elevated three-quarter view. She is visibly slimmer than the male source. The quieter stance makes a useful contrast with the cutlass pirate and musket marine. No photographic or 3D rendering claim is needed.

**Limits:** she is more front-facing through the torso than a strict directional turntable would require. Hood height exaggerates perceived body height. Gold shoulder discs read as decorated metal rather than obvious barnacles. The full-length layered overskirt conceals most of the requested fitted trousers; it is not proof that a separate trousers garment exists. At distant game scale, face, gold trim and robe pleats will collapse together. This is not a high-detail romance portrait. One idle frame provides no gait, casting, death, eight-facing continuity or animation timing evidence.

**Decision:** retain this source as a usable ordinary-unit identity candidate. Do not generate an ornamental redesign just to make the prose true. If the faction later needs stronger marine-corruption shapes, compare one controlled costume revision against this identity instead of replacing the character arbitrarily.

## Placement proposal and scale limits

Use the **ground midpoint between the two boot contacts**, not the staff tip or texture bounding-box centre. Proposed authored pivot in the trimmed PNG: **`[84,340]`**. This is an explicit visual estimate from the rear boot around `[26,323]` and front boot around `[142,357]`; it is not automatically measured skeletal data. Equivalent source-image pivot: `[989,1027]`.

Start with a common female actor scale of **0.090** against the current male troop scale of 0.105. This source then occupies about **20.16 × 32.40 map pixels**; the 267 × 373 male cultist occupies about 28.04 × 39.17. Female hood-to-ground apparent extent is about 83% of the male full silhouette extent. This is a visual sizing proposal, **not** a measured real-world height conversion. The design height constraint remains adult women 4 ft 10 in–5 ft 3 in; men 5 ft 9 in–6 ft 4 in. Check body crown rather than hood ornament and compare shared ground anchors before assigning an individual stature.

The existing male render pivot is not used as anatomical proof. An inconsistent bottom-of-texture pivot could place the pair on different apparent ground planes. The parent should review both actors against a marked tile before choosing the common anchoring convention.

## Admission gates still open

1. Place candidate beside Michael, male cultist and the other ordinary female candidates at actual map zoom with common ground marks; inspect stature, silhouette and edge readability.
2. Verify the proposed pivot against the actual rendered ground plane, not a source-sheet grid.
3. Review on bright sand and dark jungle/corruption; binary alpha alone does not ensure dark-edge readability.
4. Verify the same adult NPC instance survives recruitment, party assignment, save/load, death and reacquisition with attachment intact once those systems exist.
5. Keep movement explicitly standing-only until authored directional sequences and planted-foot review exist. Do not borrow Cattle Trail release timing or label a still image a walk cycle.
6. No visible Godot session was opened. No in-engine screenshot, animation or final-art approval was obtained in this audit.
