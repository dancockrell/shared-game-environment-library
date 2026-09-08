# Wild boar — shared source reuse candidate

**Root review: approved at 34px wide as a development standing candidate for a large feral boar.** This is not ordinary domestic-pig scale, runtime encounter admission or final animation approval. Preserve the canonical frame reference below; do not generate or duplicate the source.

**Decision: reuse the existing ordinary musk hog standing source as a static wild-boar candidate. No generation was necessary.** DragonRealms lore, exact species semantics and mechanics do not transfer. No new hero, faction or equipment.

Canonical source: ../../musk-hog-01/idle-extracted-01/cell_00_00.png (relative to this folder). Size382x337 RGBA, actual alpha0..255; PNG SHA256 f30db2b55dfdcf77be7d5cf726564a1672f07f909343b716a2167a0f88831e11. Source remains in its original shared location rather than duplicating raw production files. Original source, exact generation prompt and extractor metadata remain in ../../musk-hog-01/GENERATION.md and idle-extracted-01/metadata.json. Raw1254x1254 magenta sheet SHA256 cc4a106e040d7dc75505c48348307f7721435624b1865e4d233622d0e090ec85. Built-in generation on2026-09-08; no exposed model/credit count, not CC0 or MIT art. Existing canonical sprite_grid.py extraction preserved all components. No extraction rerun or source edit in this task.

## Consumer proposal

Use only frame0 standing, elevated three-quarter down-right. Suggested width34px, uniform scale34/382=0.0890052356, resulting image height30px. Existing estimated ground pivot[205,312] gives local ground near[18.25,27.77] at this scale. Pivot remains a visual support estimate, not collision geometry. No animation or final runtime admission; the source's four idle candidates are not automatically approved for Pirate Island.

## Actual review

Viewed close source, current Pirate Island terrain and the actual runtime pirate female cutout. scale-review.png compares30,34,38px boar widths beside the same woman at33px image height. Top row is native size on a crop of current terrain; bottom row enlarges exactly those pixels3x with nearest sampling. This is an offline scale comparison, not engine playback or encounter placement.

Brown/tan coarse fur, darker raised back ridge, squat natural quadruped stance, short tail, snout and small ivory tusks fit a wild hog without extra gear or invented powers. The down-right camera exposes top and side planes and is compatible with current actors.34px is the strongest compromise: substantial enough for a tough animal while not towering over the human.30px keeps the body readable but loses more face/tusk detail;38px reads heavier and less ordinary. Eyes are stylized and round, giving more cartoon appeal than a ferocious natural-history boar. At tiny scale the tusks are only highlights, not a separate readable weapon silhouette. These are honest limitations, not reasons to spend a new generation for this static candidate.

Root should still review native terrain placement, ground anchor and encounter behavior before admission. No runtime changes, generation, new faction, combat statistics or engine work performed. No independent commit.
