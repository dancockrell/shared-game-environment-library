# Delivery quality experiment — 2026-09-08

Root requested higher sprite quality without new generation. Approved source is untouched. `quality-comparison.png` shows six static composites on actual island terrain, not engine captures. Each panel shows native raster pixels enlarged exactly 3× nearest-neighbor. Michael uses the actual southeast frame, cropped to alpha bounds and normalized to the labeled visible height; these 33/48 px comparisons are controlled proposals, not claims about his present runtime frame padding/scale.

Top row: original 999 px dog source sampled directly with nearest filtering. Bottom row: area averaging (Pillow BOX) to a 96 px logical-width sprite, alpha coverage thresholded at 128, then nearest to the labeled delivery width. Candidate is `quality-logical96-candidate.png`; it is QA-only, not approved or installed. Both rows use identical terrain and character positions. No geometry, gameplay scale or camera was changed.

## Findings

- At 27 px, direct sampling makes individual brass highlights sparkle into disconnected bright specks. The 96 px intermediate mildly unifies some brass/iron areas but cannot restore a muzzle, feet or tiny joints that have too few final pixels. This is not a meaningful standalone quality fix.
- At 36 px next to a 48 px Michael, the muzzle, black ears and front-leg separation become substantially clearer. This is the useful candidate balance: dog is visibly canine machinery, while the human remains the taller body. The 96 px intermediate slightly reduces harsh highlight noise; it also reduces contrast in very fine vents.
- At 42 px next to the same 48 px Michael, muzzle and paws are clearer again, but the dog becomes visually oversized. Tail height exceeds Michael and the machine commands disproportionate attention. This is not a neutral quality upgrade.
- At all sizes, the island grass and shrub detail competes with dark outlines. The review intentionally uses real textured ground, not a flattering solid background. Readability must also be evaluated in engine over multiple ground colors, including contact shadow/selection treatment.

## Recommendation

Test a consistent closer gameplay viewing scale (roughly 36 px dog and 48 px human on screen), not just inflate the dog in world coordinates. A camera zoom can increase on-screen pixel allocation while retaining faction unit proportions and collision. Keep 27 px for distant overview if needed; do not promise full character detail there. A deliberate logical-source grid is useful for predictable pixel density, but 96 px preprocessing alone is not higher-quality art. Final improvement still needs authored cluster cleanup and coherent movement frames; no resizing operation creates them.

This experiment is static evidence for root's display/pipeline decision. No generation, runtime edits or source replacement.

## Authored image revision (subsequently authorized)

Root authorized one built-in image revision after the sampling experiment. `quality-revision-source.png` is a newly generated art revision, not the 96 px processing experiment. `quality-revision-extracted/cell_00_00.png` is its unscaled keyed cutout. One generation, zero corrections; original art unchanged. Provider output `exec-4484a3ad-4d5b-4b49-ac3b-e0cff8eb8f3e.png` in generation task `01a0801a-e0ff-7fa1-b06f-883e9a9d15fd`. Built-in model/version/cost not exposed. No paid external API.

1022×1132 RGBA; PNG SHA256 `02824c80f25292ed1d77f461938e92b8ac901a553e9e94571fad751511a85e23`. Suggested center-of-contacts pivot `[520,925]`; world width27 scale `0.02641878669`. One connected component and no extractor warnings. Same identity, four articulated paws, integrated boiler, pointed ears, segmented tail and southeast pose.

Root visually reviewed the full revision and identical-size 38/54 px comparison and admitted this revision as the current development-standing runtime source on 2026-09-08. Cleaner planes, legs and muzzle are a small but real gain. The original remains preserved as prior admitted source, superseded for latest runtime selection only; the 96 px resampling candidate remains QA-only. Root separately updates the existing game asset path, SHA, pivot and scale. No animation or final-art approval is implied.

`quality-revision-comparison.png` compares ORIGINAL and REVISED art at identical 38 px and 54 px screen widths, nearest sampling, same actual terrain patch, displayed 3×. It does not inflate the replacement relative to the original. At 38 px the revised flank and muzzle use more connected color planes and less broken sparkle; at 54 px the chest vent and rear iron leg separate more clearly. Improvement is visible but incremental, not a dramatic quality leap. Thin tail/leg highlights still alias, and the source remains more detailed than its final pixel budget. The generated source also did not obey a strict 96-logical-pixel construction grid. Admission is development-standing only.

Exact prompt (first input original dog cutout, second input Michael four-view source for style):

Refine image1's mechanical dog as one professional game-ready PIXEL ART standing sprite. Image1 is identity and pose authority; image2 is only the human game's rich pixel-art world/style reference, do NOT include a human or sheet. Keep exact southeast elevated three-quarter dog, four articulated legs with paws, pointed ears, square muzzle, upright segmented tail and compact boiler integrated into ribcage. Improve pixel craftsmanship materially: deliberate clean chunky pixel clusters, calmer contiguous dark iron and antique-brass planes, fewer isolated yellow sparkle pixels, clear negative-space separation of all four legs, strong clean canine silhouette. Choose about 96 logical pixels across dog body image, upscale those crisp pixels, not blurry or anti-aliased illustration. Preserve mature working dog proportions, small normal eyes and head, no chibi, no huge eyes, no fur. Victorian 1870s machinery not modern robot. Art should read compellingly at 38 screen pixels wide and retain elegant crafted details at 54 pixels wide. No smooth gradients or 3D rendering. ONE frame only, no action, no extra props. Use solid flat pure magenta #FF00FF background for keying, no checkerboard, no shadow, generous margin. Never change dog identity into another creature.
