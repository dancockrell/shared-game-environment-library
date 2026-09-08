# Crossing yellowish wet-mud material candidate

Status: source candidate only; runtime admission false. One generation plus one targeted correction. No image resizing, paint-over, extraction, or postprocessing. Original generated files retained.

## Source contract

Exact corpus: `dr-companion/data/art/room-descriptions-exact.json`, SHA256 `2de2335dd829f870c8a9c478090192050671a41cb469fd2d4fe51e975068f5ea`.

- 1-641: "crates half-submerged in yellowish mud". This asset represents the mud only, not warehouse, pilings, crates, flies or southern brush.
- 1-645: "thorny weeds and yellowish mud conquer a narrow path and bring it to an end". Ground alone does not express the blocked path, river, crate or weeds.
- Not automatically appropriate to all 641–648: 643 requires lime-green algae/green-on-grey and separately authored trodden path; 648 starts with firm earth. 647 describes roof-sealing mud, not authority for a wet ground field. 642 does not specify surface color. 644/646 require independent assessment and missing props.

## Actual style references

- `../cattle-trail/overview.png`, SHA256 `7af7b4d9b8fe9c98503eb516f3d4684b2d65df46e09882c9d35872324757e03c`.
- `C:/Users/Admin/Documents/Codex/2026-09-07/referenced-chatgpt-conversation-this-is-an-2/outputs/cattle-trail/companion-room.png`, SHA256 `e28c787bf1ef8758edc1a99bb2433f53a0b4ddfd1eb637222535ade658539c79`.

Both inspected before generation, supplied as style references to built-in imagegen. No paid external CLI. Correction used source-01 plus actual gameplay screenshot.

## Exact initial prompt

Create ONE opaque 1536x1024 landscape reusable 2D game ground material, filling every edge of the frame. Use the attached Cattle Trail actual gameplay screenshot and sprite overview ONLY as visual style references: detailed illustrated pixel art with readable broad pixel clusters, crisp small stepped edges, restrained palette, handmade game art, not photorealism, not 3D rendering, not fine noisy stippling. Subject: damp yellowish mud of a neglected fantasy riverbank, muted ochre/clay yellow-brown mixed with grey-brown wet silt, darker shallow waterlogged depressions and very restrained dull wet glints. Rich but controlled material variation, gentle compressed horizontal surface forms seen from a fixed elevated three-quarter gameplay camera. This is a floor field viewed at normal character-gameplay scale, NOT a literal overhead macro texture and NOT a perspective landscape. Entire frame is mud ground, no horizon, sky, distant scenery, bank cliff, coastline, large pool, island, diamond, border or vignette. Keep the middle 60 percent quiet enough for actors and HUD overlays without making an obvious empty oval. Wetness should be readable but not plastic, molten gold, glossy varnish, or reflective lake. No algae blanket, plants, reeds, grass, stones, boards, crates, buildings, actors, creatures, footprints, trail, roads, props, text, UI or directional route. Source authority is exact DragonRealms Crossing room 641 crates half-submerged in yellowish mud and room 645 yellowish mud conquering a narrow path. Render only the reusable mud substrate, NOT those crates or path. Do not claim or imply knee-deep water. No tiling/seamless requirement. Preserve actual Cattle Trail visual vocabulary while changing biome from dry trail to saturated muted ochre mud.

## Exact correction prompt

Correct this ground material in place, keeping exact1536x1024 framing, floor-only composition and quiet center. It currently reads as dry golden gravel. Make it unmistakably saturated wet clay MUD, muted yellowish grey-brown ochre, substantially darker and less orange/gold. Replace gritty pebbly-looking ridges and speckle with larger smooth squashed pixel clusters of soft muddy silt, broad low contrast irregular dark-grey-brown damp depressions, a few narrow pale grey subdued water sheen highlights. Restrained wetness, not varnish or glowing gold; no large lake or mirror. Pixel-art visual style from supplied Cattle Trail reference, fixed elevated gameplay view, not macro photorealism. No props, stones, paths, plants, algae, border, horizon, depth claims or new structures. Opaque ground fills every edge; retain calmer actor-readable center without obvious oval.

## Source review

source-01 rejected for integration: overly golden/dry, gravel-like high-frequency ridges. Retained as production evidence.

source-02 selected as a candidate: darker muted ochre, grey wet depressions, restrained pale glints, calmer central surface. Full-frame opaque floor without baked navigation or props. Actual image inspected. Residual granular/mottled relief remains, especially around margins; needs mounted gameplay-scale review with separately placed source-grounded props. Not claimed seamless, depth-correct, final-approved, or sufficient room illustration. No navigation/collision information can be inferred from glints or ridges. Ground-only imagery does not prove sinking/knee-depth.

## Delivery

1536×1024 native images, no extraction required. Source-02 is the recommended candidate; source-01 is rejected history. Metadata bounds are image extent only, not walkable space. Runtime integration intentionally left to parent after inspection.

