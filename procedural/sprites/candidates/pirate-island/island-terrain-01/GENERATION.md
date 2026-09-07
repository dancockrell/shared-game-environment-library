# Island terrain plate — 2026-09-07

Built-in image generation, not external paid API. User's Cattle Trail style board
used for visual reference only. No CC0 declaration. Original bytes preserved.
SHA256: 5b5af8b60df58e402ec69f9d6788ee788c60238ebc68fd38d60654e7583cf976.
Dimensions: 1536 x 1024. Status: first terrain candidate, not final island design.

## Exact prompt

Use case: stylized-concept. Asset type: continuous 2D pixel-art tropical island RTS game terrain plate, wide landscape. The provided reference is STYLE ONLY: use its gameplay panels' detailed crisp pixel clusters, natural greens, warm soil, readable elevated three-quarter gameplay camera. Not its poster layout, western towns, text or UI. Draw ONE expansive tropical island, whole coastline inside canvas with a modest border of turquoise sea. Fixed elevated orthographic three-quarter view, no horizon or perspective vanishing point. Broad irregular island with coves and promontories, gently sloping pale sandy beaches, large connected areas of low grassy land and weathered warm dirt, branching dirt paths with loops and multiple open junctions. Scattered small clusters of coconut palms and broad-leaf foliage around edges, low volcanic rocks in only a few places; keep most central ground clearly walkable and empty, roomy flat buildable clearings. Geography for a living pirate faction RTS, NOT a tiny decorative diorama. No buildings, people, ships, flags, animals, UI, text or symbols baked into terrain; those will be separate simulation-controlled sprites. No mountains hiding navigable ground, no deep inland water, no bridges, no giant hero objects, no 3D render, no smooth airbrushed painting. A beautiful continuous high quality pixel-art game map, saturated but tasteful teal water, warm sand and lush grass, consistent daylight from upper left. Entire island visible from above at gameplay perspective, uniform scale and crisp square pixel language.

## Visual inspection and integration

Continuous tropical land, sea, paths and open clearings are present.
No units or faction structures are baked in. Small foliage and rock clusters
are baked in at this stage; this is not a dynamic harvestable vegetation layer.
Some northern rocks are larger than requested. Future production needs a much
larger island, modular geography, separable occluders and deeper faction topology.

Project 42 copies these exact bytes to game/assets/island/terrain.png and has
an authored conservative land polygon/obstacle mask in navigation.json.
The mask deliberately excludes uncertain shores. It is not inferred from colors.
Actual Godot scene integration passes headless travel and pause tests; no rendered
scene or animation approval is claimed.
