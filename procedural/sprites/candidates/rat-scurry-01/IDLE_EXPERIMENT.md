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

## Result: rejected for runtime

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

## Exact initial prompt

Use case: stylized-concept. Asset type: game sprite animation source, genuinely transparent RGBA PNG, square canvas, exactly 2 columns and 2 rows of equal square cells. Input image 1 is the identity and style reference. Use ONLY its UPPER-RIGHT gathered, crouching brown rat as the base; do not use the stretched running poses. Draw four sequential restrained IDLE frames of that exact same rat facing diagonally down-right under the same fixed high three-quarter gameplay camera. Frame 1 neutral with eyes open; frame 2 ears twitch a little and whiskers lift; frame 3 eyes briefly blink and ears return; frame 4 same eyes-open neutral as frame 1. Keep the torso, head position and size, body silhouette, fur clusters, tail shape, four paw ground contacts, scale, lighting and exact placement within each cell unchanged. This is NOT running or walking: no lunging, no body stretching, no moving feet. Only tiny ear, eyelid and whisker changes. Same pixel density, richly shaded crisp earthy pixel-art style as the reference, no smooth glossy 3D. Full rat and entire tail comfortably inside every cell, matching generous transparent gutters. No grids, checkerboards, text, labels, objects, shadows or background. Four frames of ONE consistent animal, not four different rat designs.

## Exact cleanup prompt

Use case: background-extraction. Image 1 is the edit target: a four-frame pixel rat sprite sheet. Remove ONLY the painted grey-and-white checkerboard background and replace it with actual transparent alpha (RGBA PNG). Keep all four rats at exactly their current coordinates, preserve every rat's shape, fur pixels, tail, paws, whiskers, colors, shading and the closed-eye blink in the lower-left frame. Do not redraw, resize, reposition or change the creatures. No replacement solid color, no checkerboard pattern, no ground or shadow. Preserve semitransparent edge details on whiskers without a white halo. Deliver the same square 2x2 sheet with genuine transparent background, not an illustration of transparency.
