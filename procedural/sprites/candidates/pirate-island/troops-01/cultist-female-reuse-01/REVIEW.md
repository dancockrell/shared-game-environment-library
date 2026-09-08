# Living female cultist — reuse audit

8 September 2026. This folder contains review evidence only; it does not duplicate source art. No new image generation, background correction, re-extraction or runtime/native edit was performed.

## Contract and decision

Ordinary living adult human woman, age20 under the original generation contract; slim, pale face, black hair, sea-green hood and layered robe, small turquoise ritual focus on a staff. Reuse `actor_def.cthulhu.drowned_cultist`; no new hero, scythe, corpse design, permanent personal name or separate combat class.

**Root viewed the original cutout and scale comparison and admitted it for development-standing use only**, at33px with pivot84,340. It matches the current male's robe/hood/focus language, has a slightly quieter and narrower silhouette than the rejected later revision, and is already alpha-clean. This is not a solved southeast turnaround or animation asset. Repeated generation is not warranted merely because a prior stricter directional brief remained unsatisfied.

At33px, the hood top, pale face, layered sea-green silhouette, two boot ends and detached-from-body focus shape read together. A tiny cyan highlight survives particularly on dark green; its wooden shaft is less distinct than the overall focus silhouette. The overskirt and gold trim become texture; face detail is not a portrait at this distance. Dark boots and robe edges lose some separation on dark vegetation, but no pale matte or baked checkerboard appears. The torso remains front-biased. Do not claim a stable casting pose, walking gait or final facing set.

## Exact source and placement

- Source: `../extracted/cell_01_02.png` (original troop sheet bottom row, third column).
- PNG SHA256: `2929cb62163b3450b7f4b586f954a909a7f4ffcf86de9fca016c45cb400783a8`.
- Size224×360 RGBA; binary alpha0/255, one four-connected component41254 pixels. Source untouched.
- Ground pivot `[84,340]`, between the projected boot contacts, not weapon-inclusive bounds center.
- Recommended scale `33/360 = 0.09166666666666666`; review21×33. Earlier0.090 proposal gave32.4px; this small adjustment uses the current common33px female target. Male0.105×373=39.165px is shown rounded39px in comparison.
- Source crop `[905,687,1129,1047]` from1254×1254 keyed sheet, right/bottom exclusive. Decoded RGBA SHA256 `e4fd9da6887524ea7a818e1bb1ebde12e19507d97370fbf8655d3afe12ae2bca`.

## Provider and provenance

Original provider: OpenAI built-in image generation, recorded7 September2026 in `../GENERATION.md`. User's cowboy sheet served only as approved pixel-style/elevated-camera reference. The exact original generation and background correction prompts remain there; no new prompt was executed by this audit.

- Original `../source.png` SHA256 `1a1fedb8f8fdc90307278ff39256461ba26c9cffb5bc72410896efc5d4db1632`.
- `../keyed-source.png` SHA256 `adddcb1310be7d960d0e689c272491b9fda2c47e30e7475abcf97dd5242c1696`.
- Original extraction metadata: `../extracted/metadata.json`,3columns×2rows, magenta difference25, alpha threshold128, minimum component1, no source rescaling.
- Generated art is not newly designated CC0. This audit made zero generation calls; that does not assert the original source incurred zero credits.

## Rejection preserved

`../cthulhu-female-revision-01/extracted/cell_00_00.png`, SHA256 `aa968428325824355c64d368423f9a0759785dd48ab99e904381e2250786a6fe`, remains rejected as a replacement. Its more elaborate shoulders and frontal torso do not improve the original's33px job. That rejection was a quality finding, not a moderation refusal; no blocked request was retried.

## Evidence

`scale-review.png` shows actual39px male and33px original/rejected female, plus4× nearest enlargements, on sand and dark green. `review_scale.py` reproduces this offline review without altering sources. This is not an engine capture. Root owns any admission, runtime copy, real-terrain grounding and commit.
