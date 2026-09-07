# Controlled revision result

Reviewed 2026-09-07 UTC. **Preserve as experimental evidence; do not replace the previous candidate or admit this to runtime.**

## Result against the hypothesis

The edit retained the adult living cultist's sea-green hood, pale face, black hair, gold ornament, robe and lit staff. It did not achieve the requested whole-body southeast correction: the head points right, but the shoulder line and central bodice remain strongly frontal. Both boots are visible and planted in this still; that is not animation evidence.

It also did not produce simpler coherent native-scale clusters. The output is a 1,000-pixel-scale imitation of pixel art with abundant cloth/hood detail. At a 33-pixel height, nearest sampling throws much of that detail away. The staff's turquoise focal point is largely lost in the sampled result, and shoulder highlights become isolated bright spots. The previous source keeps at least as clear a staff/face separation. A larger attractive source image is therefore **not evidence of an improved game sprite**.

The transparent-background request failed: `source.png` is RGB with a baked checkerboard. The single authorized background correction supplied magenta for the existing extractor. It changed image dimensions by one pixel in each direction, so it must not be called byte-identical foreground preservation.

## Files and hashes

| File | Size | PNG SHA256 |
|---|---|---|
| `source.png` | 1017 × 1546 RGB | `4bff83f349b48da8e3c0473876c4a4b78a437e882fb2d1a03cf8b4af5c45e1ac` |
| `keyed-source.png` | 1016 × 1547 RGB | `239ab5c744c0d2eb66cffc6193b8a1605a79963d5b2b9436b42c639d1bf7b5a3` |
| `extracted/cell_00_00.png` | 770 × 1090 RGBA | `aa968428325824355c64d368423f9a0759785dd48ab99e904381e2250786a6fe` |

Raw built-in outputs are preserved as source/keyed-source; their original tool files were `exec-0659e357-8ac0-4ac5-aa9c-e3240a979d3d.png` and `exec-314464fa-4525-4308-80c6-d709e4e6f976.png` in generated-images session `01a07d0b-62ba-7533-90cc-ec40465167b8`.

Extraction reused `../../../cattle-trail/sprite_grid.py` through the shared catalog's existing tool, with `--columns 1 --rows 1 --min-component-pixels 1`. No independent keying implementation was created. The extractor hash, exact trim `[157,219,927,1309]`, settings and decoded RGBA hash are in `extracted/metadata.json`. Alpha check: 409,239 opaque pixels, 430,061 transparent pixels, only 0 and 255; one retained component, no speck deletion. Transparent source pixels were not invented as finished animation masks.

## Exact permitted background-only prompt

Use case: background-extraction. Change ONLY the baked white/gray checkerboard background of this one female cultist sprite to completely flat saturated MAGENTA #FF00FF for deterministic chroma-key extraction. Also change checkerboard visible in the spaces between arms, staff, robe and boots. Preserve the figure EXACTLY: same pixel clusters, dimensions, placement, pose, face, robe, hood, gold trim, staff and boots. Do not change facing or improve the character. No checkerboard, gradients, shadows, text or added objects. One unchanged sprite on flat magenta.

## Reproducible nearest-size review

`review_nearest.py` produces `nearest-review.png`, comparing original and revision at 33 pixels high on the same sand and dark green backgrounds. Top of each panel is the actual-size sample; below it is that **same sampled bitmap** enlarged sixfold with nearest filtering. This script is a static QA plate, not a new production extractor or an engine screenshot. Original samples to 21 × 33; revision to 23 × 33. The raw extracted source is never modified.

For a future placement-only investigation, a provisional boot-ground midpoint in the revised trim would be approximately `[340,1035]`; visual estimate only. It is not an admitted runtime pivot and should not replace the old source's anchor. At 33/1090 scale this corresponds to approximately `[10.29,31.33]` output pixels before integer placement.

## Stop and next useful experiment

The authorized edit budget is exhausted; no further generation in this task. A repeat of this same high-resolution edit prompt is not justified. The next useful test should establish the actor's actual pixel canvas and camera agreement with the approved reference before adding costume detail. Separate pose correctness and cluster readability as measurable acceptance gates. Parent decides the next bounded method; this task does not authorize a new tool, paid generation or a runtime replacement.

No Godot session, in-engine capture, multi-direction animation or final user art approval occurred. The ordinary-unit/recruitment contract in the prior review is unchanged.
