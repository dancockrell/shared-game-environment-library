# Mechanical dog — standing candidate

2026-09-08. Michael's 1870s mechanical canine, not a living recruit. Built-in image generation: one source and one background-only correction. No paid external API, model generator, or 3D work. Model/version and monetary cost are not exposed by the built-in tool; no zero-cost claim.

## Contract and review

Single southeast elevated-three-quarter standing sprite, brass boiler ribcage, iron canine legs, muzzle, ears and segmented tail. Reference: Project 42 `game/assets/island/troops/colonial.png`, style and camera only. Target width 27 px alongside 33 px human. Exactly one standing frame; no animation/directional approval.

Original `raw.png` has a baked checkerboard and is not usable alpha. `keyed.png` is the single background correction; canonical `cattle-trail/sprite_grid.py` removed magenta without rescaling. Chroma result is one connected subject, RGBA alpha 0–255, no review warnings.

Visually inspected extracted full-size sprite and 25/27/30 px comparisons (display enlarged nearest-neighbor 3×). Canine muzzle, erect ears, four paws and segmented tail remain legible at 27 px. Brass and iron distinguish it from furry wildlife. Integrated boiler reads as a large ribcage assembly rather than dangling equipment. Upper tail is tall and near the head-height of a human at this scale; body is substantially shorter. The far hind paw is naturally partly overlapped by the torso. Fine vent/rivet details merge at native scale. Slight outline/edge antialiasing in the source remains, so this is a development-standing candidate, not final hand-cleaned pixel animation.

Suggested floor pivot `[500,930]` is the approximate center of the four ground contacts, not the bottommost front toe. Canvas 999×1143. Width 27 implies uniform scale `0.027027027027`. PNG SHA256 `48b1867de2f0a09ef7c5e6cf11bb2fddb80f7a062cc34d61a1bd0ed4242e7253`.

Root reviewed the full cutout and actual-scale comparison and admitted the 27 px sprite as development-standing on 2026-09-08. Integrated machinery and small-scale canine silhouette passed; tall tail and merged vent details are accepted development limitations. This is not animation or final art approval. Root owns separate game integration and engine testing. No runtime or shared index changed here. Sources and extraction metadata preserved.

## Exact generation prompt

Use case: stylized-concept. Produce ONE isolated game sprite, a compact mechanical dog for an 1870s steampunk island RPG/RTS. Input image is ONLY a pixel-art style and elevated three-quarter camera reference, NOT a human or costume to reproduce. True transparent background. One complete dog standing on four jointed mechanical legs, facing southeast (head toward lower-right of picture), camera looks down slightly, back visible. Clear canine muzzle, two pointed metal ears, short upright segmented tail, doglike hock joints and four broad little metal paws. Compact brass boiler integrated into ribcage, dark iron spine and limbs, a few chunky copper joints; recognizable as a DOG first, not a box robot, not a vehicle. No rider, no saddle, no guns, no text. Detailed crisp old-school pixel sprite with coherent dark outline, controlled warm brass highlights and cool iron shadows, matching the reference's rich pixel clustering. Design for silhouette readability when reduced to only 27 pixels wide next to a 33-pixel-tall human. Exaggerate clear head, legs and tail; avoid tiny gears/noise, smoke clouds, loose dangling wires, glossy 3D surfaces and modern robotic styling. Entire subject safely inside frame with empty transparent padding. Neutral alert standing pose; no scenic ground or cast shadow.

## Exact correction prompt

Background extraction correction only. Keep this exact mechanical dog, all pixels of the dog, pose, proportions, four legs, colors and framing unchanged. Remove the baked gray and white checkerboard completely. Replace ALL background including holes between legs with perfectly flat solid pure magenta RGB255,0,255 / #FF00FF, no pattern, no shadow, no gradients. The dog must remain identical; do not repaint or redesign it. This is a chroma extraction source, not a transparency display.

Original provider output: `exec-0f6aee56-0b28-4cd4-97fe-fbc45c6fdb87.png`; correction: `exec-c5a99500-bb66-4818-912d-82b71792e255.png`, generation task `01a0801a-e0ff-7fa1-b06f-883e9a9d15fd`. Generation terms are provider terms; this record does not assert CC0 ownership.
