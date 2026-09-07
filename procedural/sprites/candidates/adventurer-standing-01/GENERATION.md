# Fantasy adventurer standing master

Generated 2026-09-07 using built-in image generation, not a paid API fallback.
Identity/style reference: ../adventurer-walk-01/source-02.png.
One adult adventurer, chestnut braid, teal cloak, cream sleeves, leather jerkin,
dark trousers and boots. Standing down-right; no claimed animation.

## Contract and inspection

Target: a reusable isolated actor source for DR Companion, eventually displayed
around 100 pixels tall. PNG with real alpha; entire body and equipment retained.
The result is RGBA 1254x1254, SHA256
37fac227a96874268c487a62bf11aef5a0f1e9281af0f71a3c8c52c9162310b6.
1,252,669 pixels are fully transparent. Alpha spans 0 to 255.

Visual inspection: recognizable identity, readable cloak/boots/pouch and a
complete standing silhouette. This is more finely shaded than the small source
sheet; actual gameplay-size palette and silhouette review remain required.
It must not automatically replace every player's own appearance.

Raw nonzero-alpha bounds are [24,31,1200,1254], but at alpha >=16 the visible
bounds are [354,78,880,1148]. Faint exterior noise contaminates automatic trim.
Do not use raw alpha bounds to infer a ground pivot or declare this runtime-ready.
No destructive cleanup applied. Alpha cleanup, scale review and neighboring
direction/animation continuity remain outstanding.

Status: candidate, not runtime-admitted. Keep source intact. Proposed foot pivot
[681,1147] is artist-estimated in source pixels and requires placement review.
This is a single standing frame, not a walk loop.

## Exact prompt

Use case: stylized-concept. Game asset: ONE isolated full-body fantasy adventurer standing sprite, not a sheet. Reference image is identity/style reference: reproduce the adult woman with chestnut braid, short dark teal cloak, cream sleeves, brown leather jerkin and belt pouch, charcoal trousers, brown boots and sheathed sword. Detailed illustrated pixel art with crisp clustered shading and dark contours, elegant proportions, matching the reference rather than a glossy 3D model. Fixed elevated three-quarter gameplay camera, facing down-right, relaxed ready stance with both boots planted, entire body and equipment visible. Large clean square canvas with generous empty margin around one centrally placed character. Genuinely transparent RGBA background: no checkerboard pixels, no white or colored background, no ground plane, no cast shadow, no scenery, no text, no extra poses. Keep torso, head and boots readable when scaled to 100 pixels tall. This is a standing identity master for a DragonRealms sprite pipeline, not a portrait or animation.
