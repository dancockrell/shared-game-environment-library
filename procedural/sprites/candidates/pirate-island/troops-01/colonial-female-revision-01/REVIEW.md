# Colonial standing correction — revise, not admitted

2026-09-08. One built-in character edit and one background-only correction, then the existing shared extractor. No runtime edits or animation claim.

## What improved

The ordinary marine identity survives: black/gold tricorn, tied-back brown hair, blue waistcoat, cream sleeves, brown breeches, stockings, boots and long musket. Both hands visibly hold the weapon, both feet and full muzzle are present. The stance is more compact and the top of the hat establishes a somewhat higher camera than the original. The result is a single slim adult woman rather than a sheet or detached assembly.

## Hard comparison

The requested whole-body southeast rotation is **not fully achieved**. Head still looks principally right, torso is mostly toward the viewer, and feet do not establish one unambiguous southeast heading. This is not an acceptable directional turnaround. Do not label it a proven SE animation source just because the prompt requested that direction.

The 33-pixel-height nearest-neighbor comparison in scale-review.png shows both original and revision at actual target image height plus a four-times nearest enlargement. The revision's stance is a little more compact, but the large source detail does not produce a decisive readability gain at 33px. The tricorn, pale stocking breaks, dark waistcoat and diagonal musket remain visible; facial identity and fine clothing detail do not. This is a diagnostic image, not a native engine capture or user approval.

## Alpha and geometry evidence

- Keyed source 971x1620; trimmed cutout 695x1168, bounds [146,143,841,1311], right/bottom exclusive.
- Cutout SHA256 7e3a582227a8a32d5dac5efa7f8afa4e4bb1d1caca8311107a1b83bd5496de2b.
- Alpha is binary [0,255]. Two four-connected components, sizes 323356 and 32. Neither was silently discarded. No grid cut warnings.
- Reproducible diagnostic script review_scale.py only reads the original and extracted sprites and creates its own comparison; no source retouching.
- At height 33, rounded width 20. Candidate-only scale 33/1168; no runtime pivot admitted.

## Decision

Keep as a source-traceable revision candidate, **not a runtime replacement**. Budgeted generation stops here. The next justified experiment is an explicitly approved same-camera southeast body-pose reference, changing orientation while retaining this clothing identity; simply requesting more detail would not address the failure. Native rendered scale, grounding and animation remain open gates.
