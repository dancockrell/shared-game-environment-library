# Crossing jackal idle source

Candidate only; no runtime admission. Sole species owner: silver_leucro agent.
Local evidence: DR `data/elanthipedia/bestiary.json`, `Jackal (creature)`:
City Crossing,Shard; MapList Siergelde Cliffs (3). Description identifies a lean,
short-furred predatory canine, wolfish, scavenging carrion or hunting weaker prey.
Silver leucro was rejected for this batch: its entry is Ratha/Qi'Reshalia.
This does not claim jackals inhabit Town Green or every Crossing room.

Contract: four restrained down-right idle frames, fixed elevated three-quarter
camera, earthy detailed pixel clusters, planted paws, same lighting and identity.
Tawny saddle palette, amber eyes and ear details are artistic interpretation.
Magenta production key; existing Cattle Trail extractor creates transparent PNGs.
No walking, attack, wounds, equipment, backgrounds or generated shadows.
Intended width about 80-100 display pixels; review at fixed source scale first.

Built-in image_gen only, no paid external API. Tool does not expose explicit
model version or credit count. Generated output follows user/project tool terms;
not asserted CC0 or third-party MIT artwork.
Style/layout reference: ../musk-hog-01/idle-magenta-01.png, SHA256
cc4a106e040d7dc75505c48348307f7721435624b1865e4d233622d0e090ec85.

## Exact prompt

Use case: stylized-concept. Image 1 is ONLY a rendering style and 2x2 layout reference, NOT subject anatomy. Generate a NEW DragonRealms JACKAL four-frame restrained idle sprite sheet. Exactly 2x2 equal cells, one identical lean adult short-furred canine in each. A wolfish jackal, narrow chest and waist, slender strong legs, long tapered muzzle, upright triangular ears, moderately bushy lowered tail. Tawny brown short fur with dark gray-brown saddle and cream lower muzzle; natural wary amber eyes. Detailed earthy crisp pixel art with rich cluster shading and dark defined outline matching reference quality, not smooth 3D or cute cartoon. Fixed elevated three-quarter gameplay camera facing diagonally down-right. Frame1 alert neutral, frame2 tiny ear twitch, frame3 brief eyelid blink, frame4 return alert neutral. Keep body proportions, silhouette, tail and planted paw coordinates identical relative to each cell, same scale and soft upper-left light. No walking, no stretching, no attack, no pose rotation, no equipment. Entire body comfortably inside cells with equal generous gutters. Flat solid vivid magenta #FF00FF everywhere outside jackal, no magenta in animal, no ground or cast shadows, no checkerboard, no text, grid lines, labels, extra objects. This is a chromakey production source. Species lore: lean short-furred predatory canine, wolfish, scavenges carrion or hunts weaker prey; not a silver leucro or domestic dog.

## Extraction and review

Generated 2026-09-08, raw RGB source 1254x1254 `idle-magenta-01.png`:
SHA256 `87e20ad20d668c33e7cc10220593ab303bef5282c60f802fcf47444cd1da8b9b`.
Original tool output ID `exec-08d3f60e-e121-467b-9b02-690253c288b4.png`.
Extraction uses existing `../cattle-trail/sprite_grid.py`, not a copied helper:
`--columns 2 --rows 2 --min-component-pixels 1`. Four RGBA PNGs, no cut warnings,
no removed small components and no resizing. Metadata preserves source rectangles,
raw and PNG hashes, extractor digest and processing parameters.

At fixed 0.20 source scale, about 90 pixels wide, the lean canine reads clearly,
with consistent saddle coloring, eye blink and a restrained rather than dramatic
ear twitch. Four paws remain planted; manual anchors compensate one-pixel trim
differences, not game coordinates. No visible magenta halo on moss background.
Existing reviewer decoded all four alpha images and genuine playback observed
frames 2,3,4,1 over 3400ms. `review.png` is the actual browser stage and aligned
filmstrip, not a game-client screenshot. All 19 animation-review tests passed.
Browser closed after review. First browser attempt used its default `main`
selector and timed out on the standalone reviewer; corrected to `#stage`.

Source package is ready for integration proposal, NOT runtime admission. Client
foot anchoring, relative player scale, exact-name matching, fallback and live
status behavior remain required. Suggested initial width 90px; do not infer any
spawn location from the asset or map a silver leucro to this jackal.
