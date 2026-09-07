# Pirate female correction 01

Status: controlled correction completed; **candidate retained for review, not runtime-admitted**.

## Contract and hypothesis

One controlled built-in edit of ../extracted/cell_01_01.png, SHA256 3b1a0c19893854792923fcfab042d7e2d8a387241bff378bc83fdb9c5fc1ceaa. Preserve the ordinary adult deckhand identity and clothes. Correct full-body SE orientation from an elevated three-quarter camera and cutlass edge continuity at approximately 36-pixel body height. One subject, one standing pose, PNG, real transparency requested; no animation claim. Check source, downsample, alpha, continuity, and provenance. No paid API fallback; at most one alpha-only follow-up.

## Exact edit prompt

Use case: identity-preserve. Input image 1 is the edit target, the existing Pirate Island adult female deckhand sprite. Change ONLY the whole-body camera/facing and the cutlass edge readability. Preserve this same approximately 20-year-old adult woman, her slim short build, chestnut braid, red headcloth, cream rolled-sleeve period blouse and fitted bodice, red waist sash, dark knee breeches, brown boots and single cutlass. One complete standing figure only, no sheet. Rotate the entire body, shoulders, hips and planted boots to face screen down-right (southeast), with head aligned with that direction, in a clearly elevated three-quarter orthographic RPG camera, enough above to show headcloth top, shoulder tops and boot tops. Do not merely turn her head while leaving her body frontal. Keep a relaxed ready stance and the same sword-bearing hand. The cutlass must remain a continuous clear broad curved steel blade, with a simple unbroken pale edge and dark outer contour, held clear of the body; design the blade and hand/hilt shapes to read when the full figure is only about 36 pixels tall. Keep the existing rich compact pixel-art style and restrained colors, dark outlines, crisp pixel clusters; not a painting, smooth illustration, 3D render or photorealism. All hands, legs, boots, braid and sword intact, fully within frame with a modest transparent margin. Output genuine RGBA transparency, not a drawn checkerboard or colored backdrop. No background, ground tile, shadow puddle, words, labels, extra props, extra weapons, detached pixels or duplicated limbs. PG13 fully clothed adult.

## Exact alpha follow-up prompt

Use case: background-extraction. Change ONLY the white/gray checkerboard background into uniform flat saturated magenta #FF00FF for deterministic chroma-key extraction. Preserve this single existing adult pirate woman's exact face, clothing, whole-body pose, elevated camera, scale, complete cutlass, hands, hair, boots, all foreground pixel colors and crisp edges unchanged. Replace background also in gaps around the sword, between limbs, and around the braid. No checkerboard, no transparency illustration, no shadows, no gradient, no extra objects, no new pose or style.

## Outputs and processing

Built-in image_gen was used twice: one identity correction, one alpha-specific correction. No CLI, external paid API, Magnific operation, or further generation. Cost/credits were not reported by the built-in tool; do not label this a verified zero-cost service. Model/version was not explicitly selected through the callable tool. Generated 2026-09-07 UTC / 2026-09-08 local Bangkok time.

- First output copied byte-for-byte from `.codex/generated_images/01a07d08-6e7d-7213-98c4-8ed69b11d0a9/exec-c0b704da-93a4-4af3-bddd-4e94c15256a2.png` into `source.png`: RGB 1034 × 1520, SHA256 `4614d9a0b902efa1c4531ecc95ceb1b233468584df22754045d1946f327223f3`. Real transparency failed; background is baked checkerboard.
- Alpha follow-up copied from same output directory `exec-402c2f39-d635-44c6-bb67-21230d63316c.png` into `keyed-source.png`: RGB 1034 × 1521, SHA256 `3b5124d7278150d81e571372b068f8f7638d3994879159bde6e08ade8f4e760f`. Canvas differs by one row; foreground invariance is visually assessed, not byte-identical.
- Existing shared Cattle Trail `sprite_grid.py`, SHA256 `d6aa76d7ba4f74209b3022ead3b4a8fbc0704a03a4f34b04059b215ce4f0ac4d`, run with `--columns 1 --rows 1 --min-component-pixels 1`, default key difference 25. No custom extraction implementation.
- `extracted/cell_00_00.png`: RGBA 568 × 1190, SHA256 `52326f77901ee1d4643359d32fea47e25915bfd9146fd3e667b8e66b0c5afc19`. Source crop [279,123,847,1313], exclusive right/bottom. Full parameters and hashes are in extracted/metadata.json.
- Alpha is binary: 306,585 transparent and 369,335 opaque pixels. Two four-connected components: main 369,334 pixels and one isolated pixel at trimmed (91,392). All retained deliberately; no implicit speck deletion. No gutter warnings.
- Previous source and review remain intact. No license such as CC0 is newly asserted; generated-source provenance is preserved, separate from admission.

## Visual evaluation

Viewed both generated sources and the transparent extraction at source scale. Also viewed a temporary in-memory nearest-neighbor sample **17 × 36**, plus its 4× enlargement on dark neutral gray. No engine or game screenshot was captured.

The principal correction works: shoulders, torso, hips and boots now share a substantially more coherent elevated three-quarter right-facing orientation than the near-frontal input. The cutlass is broad and continuous; its pale edge remains visibly joined at the 36-row sample. This is an improvement, not confirmation of exact camera agreement with the entire world.

The adult deckhand identity remains recognizable through headcloth, braid, cream fitted period top, rolled sleeves, red sash, dark breeches and brown boots. The pose still reads as a ready standing character, not a walking phase. The right-hand cutlass is physically held; limbs and boots are intact. The new face is cleaner and more stylized, and the braid and headcloth tails have become more prominent. Those are observable identity drift, not a claim of pixel-exact preservation.

Remaining issues: fine dithering in cloth and steel is excessive for a 36-pixel figure; facial detail disappears at that size. The sprite becomes narrow at 17 pixels because the sword now runs close to the body silhouette, although its light edge remains readable. The high source resolution is not itself useful shipped detail. The foot-support point needs an authored pivot; do not use the weapon-inclusive bounding-box center. Camera direction, male/female height calibration, sword silhouette on actual terrain, and static appearance alongside other faction troops still need a common-scale in-game comparison. No walking, attack timing, companion movement, or final visual acceptance is claimed.

## Next bounded action

Retain this as the better camera/weapon identity anchor for parent review. Do not generate again in this experiment. If approved to progress, do the common-height terrain comparison and target-resolution cluster cleanup before investing in directional action sequences. Keep raw sources unchanged and treat any derived cleanup as a traceable processing step. No runtime references added here.
