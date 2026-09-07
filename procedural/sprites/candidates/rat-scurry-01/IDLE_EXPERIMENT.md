# Restrained idle experiment

2026-09-08. Hypothesis: reducing motion to ears, eyelids and whiskers can preserve
the body and ground contacts better than the rejected scurry sequence. Reference:
source-01.png upper-right gathered pose, already used statically in DR Companion.
No other pose is an identity reference. Built-in image generation only; no paid
external generation. Preserve original source and scurry rejection.

Contract: four equal 2x2 cells on transparent RGBA, fixed down-right camera, one
animal identity, fixed body and foot contacts. Neutral -> ear/whisker twitch ->
blink -> neutral. This is an idle, never evidence of attacking or walking.
Admission requires alpha, anatomy, fixed-scale alignment and continuous motion
review at gameplay size. Candidate only until those are checked.

## Direct-alpha attempts: rejected for runtime

- idle-02.png: RGB 1254x1254, SHA256 4b45d91d71821c11695cd34a781f1dfe0edff09fa5c846d2c9739996b6fe02c0.
- idle-03.png: background-only cleanup attempt, also RGB 1254x1254, SHA256 e7f5fe11bfa8666564e68c0251f852bd253d7f3eb248784af67dab6b7a83069c.

Both paint the checkerboard into the pixels. Neither has an alpha channel.
Visible pose consistency is better than the scurry source, including a blink,
but no continuous-motion acceptance was performed after the alpha gate failed.
Stop this generation/cleanup sequence rather than repeating the same request.
The existing DR static source and original scurry experiment are unchanged.

The reusable reviewer now rejects non-8-bit-RGBA PNG sources before building and
checks for both fully transparent background pixels and visible pixels after
browser decode. Presence of alpha still does not certify clean edges or motion.
Its HTML embeds the verified bytes so local-file origin restrictions cannot
prevent pixel inspection and later source replacement cannot change the review.

## Chroma-key follow-up: extracted candidate, admission pending

The Cattle Trail handoff's METHOD.md and sprite_grid.py provide a reproducible
solid-magenta workflow. Reused that helper read-only, without a DR-specific fork.
Built-in image generation changed the background of idle-02.png to a magenta key
in idle-magenta-04.png (SHA256 decfd883afaa3b5e69b8e9add7ec9294fdd79655f2d3a6d032880a365876bafe).

Extraction command from shared repository root:

```powershell
python procedural/sprites/candidates/cattle-trail/sprite_grid.py procedural/sprites/candidates/rat-scurry-01/idle-magenta-04.png procedural/sprites/candidates/rat-scurry-01/idle-extracted-04 --columns 2 --rows 2 --min-component-pixels 1
```

The helper refuses to overwrite populated outputs. Use a new empty destination
for a reproducibility check. System Python 3.13 has Pillow/numpy/scipy; the bundled
Codex Python lacks scipy and was not modified. Extractor SHA256:
d6aa76d7ba4f74209b3022ead3b4a8fbc0704a03a4f34b04059b215ce4f0ac4d.
The Cattle Trail handoff remains owner-maintained; keep that dependency with its
source ZIP or verified helper, rather than copying a second implementation.

Four RGBA cells produced, no gutter warnings and no small-component pixels
removed. Metadata records all original crop/trim rectangles and output hashes.
Raw generation, cleaned candidates and runtime admission remain separate.
Inspect whiskers and pink tail for key spill; a magenta key is inappropriate for
subjects that themselves contain magenta. No claim of lossless background edit.

The reviewer now accepts either one atlas or multiple frame sources and explicit
per-frame durationMs. This clip uses 2400/140/100/200ms at fixed 0.12 source scale;
all anchors are the same manual body-ground estimate [280,330] after trimming.
No frame is independently resized to force its silhouette to match. Browser
decode, four frames, two timed loops and Pause passed. Observed first-loop
transitions were approximately 2430/2583/2688/2870ms. Nineteen tool tests passed.
The screenshot confirms the small sprite reads against moss; timing telemetry
alone does not establish native gameplay animation acceptance. Inspect actual
in-client motion, light/dark edges and reduced-motion fallback before admission.

Regenerate the review with `node tools/sprite-animation-review.mjs procedural/sprites/candidates/rat-scurry-01/idle-extracted-04/animation.json`.

### Exact magenta edit prompt

Use case: precise-object-edit. Image 1 is the edit target, a four-frame pixel-art rat idle sheet. Change ONLY its grey-white checkerboard background to perfectly flat solid vivid magenta RGB(255,0,255), #FF00FF. This is a chroma-key production source, NOT a transparency request. Keep all four rats at exactly the same coordinates and size, and preserve the original square canvas, 2x2 cell layout, fur patterns, outline, paws, tail, eyes and lower-left closed-eye blink. Do not redraw or move rats. Preserve fine whiskers, no magenta fringe. No checkerboard, no gradients, no lighting changes, no shadows, no labels. Solid #FF00FF everywhere outside the rats.

## Exact initial prompt

Use case: stylized-concept. Asset type: game sprite animation source, genuinely transparent RGBA PNG, square canvas, exactly 2 columns and 2 rows of equal square cells. Input image 1 is the identity and style reference. Use ONLY its UPPER-RIGHT gathered, crouching brown rat as the base; do not use the stretched running poses. Draw four sequential restrained IDLE frames of that exact same rat facing diagonally down-right under the same fixed high three-quarter gameplay camera. Frame 1 neutral with eyes open; frame 2 ears twitch a little and whiskers lift; frame 3 eyes briefly blink and ears return; frame 4 same eyes-open neutral as frame 1. Keep the torso, head position and size, body silhouette, fur clusters, tail shape, four paw ground contacts, scale, lighting and exact placement within each cell unchanged. This is NOT running or walking: no lunging, no body stretching, no moving feet. Only tiny ear, eyelid and whisker changes. Same pixel density, richly shaded crisp earthy pixel-art style as the reference, no smooth glossy 3D. Full rat and entire tail comfortably inside every cell, matching generous transparent gutters. No grids, checkerboards, text, labels, objects, shadows or background. Four frames of ONE consistent animal, not four different rat designs.

## Exact cleanup prompt

Use case: background-extraction. Image 1 is the edit target: a four-frame pixel rat sprite sheet. Remove ONLY the painted grey-and-white checkerboard background and replace it with actual transparent alpha (RGBA PNG). Keep all four rats at exactly their current coordinates, preserve every rat's shape, fur pixels, tail, paws, whiskers, colors, shading and the closed-eye blink in the lower-left frame. Do not redraw, resize, reposition or change the creatures. No replacement solid color, no checkerboard pattern, no ground or shadow. Preserve semitransparent edge details on whiskers without a white halo. Deliver the same square 2x2 sheet with genuine transparent background, not an illustration of transparency.
