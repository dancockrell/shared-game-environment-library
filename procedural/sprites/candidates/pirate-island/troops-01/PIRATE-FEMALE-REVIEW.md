# Pirate female deckhand — individual character review

Reviewed 2026-09-08 local time. **Candidate, not admitted art.** This is one ordinary adult unit appearance, not another named hero. No new image generation, source modification, paid service, or engine window was used. This note extends this candidate's GENERATION.md and extracted/REVIEW.md; those remain the source and extraction records.

## Identity and playable concept

**Display identity:** the persistent generated NPC's own name; role label **Deckhand**. Do not assign one canonical name to every copy. An adult woman, approximately 20, short and slim, sun-browned, chestnut braid, red headcloth, cream period blouse/bodice, red sash, dark knee breeches, brown boots, cutlass. Keep her a working pirate, not an officer, glamorous unique heroine, or Michael recruit wearing pirate camouflage. Her faction can change without rewriting her identity or erasing her former crew.

**Trope:** the share-conscious boarding hand. She works the quay and takes the dangerous first few steps onto someone else's deck; a captain who pockets the shares has to sleep sometime. Competence and irreverence make her memorable without requiring a bespoke epic. Her visual point is practical agility: cutlass away from her body, rolled sleeves, firm boots, sash that breaks the cream/dark silhouette.

**Existing unit contract, not new powers:** `actor_def.pirates.deckhand`, produced by the tide quay for 1 provisions + 1 coin in 2 production ticks, population use 1, `worker` actor kind. The current preview combat profile is 10 health, 2 damage, range 1, cooldown 2 ticks. Sex/appearance must not silently grant different statistics or an extra hero ability bar. This gives an inexpensive close-range body that loses time and health approaching ranged opposition. These are current prototype values, not final balance approval.

**Later faction action, proposed and not implemented:** the same boarding hand can participate in the pirates' existing design for capturing vessels and machinery. Use an explicit boarding target, access/reach test, crew control/resistance resolution, and ownership transfer. A cutlass hit must not itself flip a healthy steam machine. Ordinary melee, work assignment, and a contextual boarding order are enough; do not invent a separate repair wagon, mechanist hero, or magical recruitment aura for her. Equipment capture is a pirate faction mechanic, not a female-only power.

## Recruitment encounter hook

One short generated encounter: **a disputed share after a boarding action**. She has a persistent reason to distrust her captain, not a special recruitability flag unavailable to other women. A factual event record supplies the missing share, crew/captain identities, and her reaction; dialogue draws from those facts. Michael can help settle the dispute and build personal attachment, or meet her later through another route. Helping is an opportunity for interaction, not payment for ownership of a person.

Recruitment must be a voluntary decision associated with relationship and circumstance, never `health < threshold`, a combat damage reward, or a forced result of buying her share. A loyal woman is still potentially recruitable under appropriate later conditions; this particular encounter is not a universal prerequisite. Joining changes this same actor's faction and removes her old assignment; it does not spawn a replacement companion while leaving her original pirate instance behind. Pirate population/work/combat contribution falls accordingly. Former-faction diplomacy can improve after an agreed settlement or worsen after a bitter departure, using the recorded circumstances rather than an unconditional penalty.

Michael faction membership and the four active companion slots are separate. She may join his broader faction without entering the active party. Once attached to Michael she does not become a normal dissatisfaction defector. Her personal identity and attachment must persist through death and the game's Cthulhu resurrection rules. Those systems are not implemented by this review.

## Direct visual inspection

Inspected `extracted/cell_01_01.png` at source size and in a temporary, in-memory nearest-neighbor preview: 24 × 36 pixels (source scale approximately 0.105), shown at 1× and enlarged 4× on dark neutral gray. No preview asset was added to the library. This is an isolated sampling review, **not a rendered terrain or Godot review**.

- The red headcloth and sash, cream shirt, dark breeches, brown boots and long curved cutlass survive at small size. Her faction reads distinctly from the colonial blue uniform and sea-green cultist.
- Full-size adult face, braid, garment layers, sleeves and cutlass are legible and coherent. At 24 × 36, face and braid stop carrying identity; headcloth/sash/body silhouette must do the work. Do not claim portrait-level facial expression survives this scale.
- The pose is near-frontal, with face turned right. It is **not a verified southeast body facing** matching the requested elevated three-quarter camera. A filename/direction label cannot correct that geometry. Correct facing before producing directional motion from it.
- The blade becomes a narrow broken-looking diagonal at 0.105 nearest sampling; it loses the continuous bright edge visible in the source. Readable weapon reach needs a native-scale pixel cleanup pass, not a larger glossy source image.
- The body silhouette is usable, but rendering all 342 source rows into 36 rows crushes the trouser/boot boundaries and blurs the distinction between hand and hilt into a few pixels. Do not add more decorative detail; simplify those clusters at target size.
- The source female height is 342 rows versus the male pirate's 362. At identical scale this is only about 5.5% shorter. That does not establish the requested female/male height contrast. A trial female scale around 0.096 would produce roughly 33 rows versus the male's 38 at 0.105, but this is only a **sampling experiment**, not a canonical height or approved runtime scale. Author common ground/body references and review the pair together before choosing it.
- Both boots are complete. The bounding box includes her extended sword, so its center is not a reliable ground pivot. Author the support point between boot contacts, not the weapon-inclusive midpoint. No final pivot is claimed from this review.
- One isolated three-pixel opaque component sits at x=186, y=68..70 of the trimmed image. It is retained by the original extraction as designed. Verify against the source before deliberate cleanup; do not silently alter the source or pretend a component count of two means a second character.

## Provenance and structural checks

The source was built-in image generation on 2026-09-07 followed by a magenta-background edit; no CC0 claim. Exact prompts, source hashes and failure of the original transparency request are recorded in GENERATION.md. The existing Cattle Trail extractor made these cutouts without resizing, with binary alpha and all components retained. This female is bottom row, middle column, not an animation frame for the male above her.

Direct current-file checks:

- PNG: 229 × 342, RGBA.
- SHA-256: `3b1a0c19893854792923fcfab042d7e2d8a387241bff378bc83fdb9c5fc1ceaa` — matches extracted/metadata.json.
- Alpha: 45,796 fully transparent pixels; 32,522 fully opaque; no partial-alpha pixels.
- Four-connected foreground components: 32,519 pixels plus the three-pixel component noted above.
- Zero opaque pixels pass the extractor's magenta test (`red - green > 25` and `blue - green > 25`). This is not a universal proof of halo-free edges against every terrain.
- Existing unit profile and production rule inspected directly in Project 42 `godot-rust/src/world.rs` and `content/production/tide_quay_deckhands.json`.

## Decision and next gate

**Keep as the female deckhand identity candidate. Not final sprite admission and not animation approval.** No extra hero or canonical personal name is created.

Next art pass should correct this one body's southeast camera/facing while preserving costume and silhouette, then make a small target-resolution cleanup of blade/hand/boot clusters. Review beside the male at calibrated body height and on the actual island at gameplay zoom. Only after that identity anchor passes should clean directional idle and walk actions be produced. Each walk needs actual planted-foot phases and motion review; repeating this idle while translating remains standing-only movement. Attack needs an actual cutlass stroke and matching hit timing. No paid generation is authorized by this note.
