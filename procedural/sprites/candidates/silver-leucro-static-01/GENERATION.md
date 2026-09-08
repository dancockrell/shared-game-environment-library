# Silver leucro static

Source: exact cached DR bestiary and creature-prompts `Silver leucro`. Sleek and
lean wolfish creature; fur brown to dark grey, always tipped bright silver.
Qi'Reshalia/Ratha, Reshalia Trade Road93. NOT Crossing or giant black leucro.
No existing shared leucro candidate folder found before generation.

Contract: one fullbody neutral standing quadruped, four paws and tail visible,
fixed elevated down-right camera, illustrated Cattle Trail pixel clusters and
restrained upper-left light. Brown/dark-grey fur with bright silver tips, no
armor/glow/scenery/text, true transparent background. Static first, no animation.
Built-in imagegen only, no paid external API. Model/version and credit count not
exposed; generated pixel licensing follows tool terms, not asserted MIT/CC0.

## Generation and extraction

2026-09-08 source01, output exec-1ad8e3b8-a669-48f5-b382-251880a973e5,
rejected for diffuse exterior halo. Source02 output
exec-f75f292a-2520-41f7-b25e-634cc06e4c55,1536x1024, SHA256
53ab167b4987a5a8675e3d6c5021088b8152ffd16e81a9294a63bfb42e20cc7a.
One correction only: preserve exact body/camera/silver fur, replace entire
outside silhouette and all leg gaps with uniform #FF00FF, remove halo/shadow,
no magenta inside animal. No further generation.

Original prompt: ONE fullbody static SILVER LEUCRO, sleek lean adult wolfish
quadruped, brown-dark-grey undercoat always tipped bright silver, long muzzle,
triangular ears, lowered long tail, FOUR planted visible paws. Not white wolf,
black wolf or jackal, no glow/armor. Elevated down-right game camera, premium
Cattle Trail illustrated pixel clusters, dark outline, restrained upper-left
light, earthy brown/cool-silver shading. Read at80px; transparent alpha, no
matte/checkerboard/scene/shadow/text, one neutral pose not sheet or attack.

Existing Cattle Trail sprite_grid.py with --columns1 --rows1
--min-component-pixels1 extracted source02 into extracted-02. Metadata includes
source/helper/output digests. No rescale, one connected retained component,
zero removed pixels and zero cut warnings.1063x842RGBA. Native cutout inspected
for complete paws/tail and silver-tipped identity; gameplay review still separate.
