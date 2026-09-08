# Drowned shrine sprite

Target: existing site_archetype.cthulhu.drowned_shrine. Static 2D elevated
three-quarter building sprite, approximately 150 world pixels wide. Reference:
Project42 game/assets/island/watch_fort.png for camera and pixel treatment only.
Identity: ancient maritime cult architecture, integrated tentacled idol, dark
stone, restrained cyan ritual lights. No human NPC or monster silhouette.
One fixed rectangular footprint; explicit ground/door pivot required after output.
Status: source reviewed; development-only runtime placement. Not final art approval.
Tool: built-in image generation, no external paid API or model-generation call.
Alpha, source and intended-scale appearance require inspection before admission.

## Exact prompt

Use case: stylized-concept. Asset: one Cthulhu drowned-shrine building sprite for Pirate Island, fixed elevated three-quarter orthographic 2D pixel art. The attached fort is ONLY a camera angle, pixel-cluster scale, top-plane visibility and readable material reference. Entirely different architecture: a compact ancient dark sea-stone shrine, two uneven broken pylons framing one deep black open entrance, a carved tentacled idol integrated above its lintel, shallow stone entry stairs facing lower-right, encrusted salt and restrained green sea patina, two small cyan ritual lights. A squat roofless sanctum behind the entrance with one visible dark ritual basin. The silhouette must clearly read an uncanny drowned cult temple, not a castle, church, hut, monster body or giant face. Keep it architecturally usable as a people-spawning building. One connected compact rectangular ground footprint, clear doorway ground contact, all architectural overhangs stay above that footprint. No water patch or floating island; no terrain, foliage, people, text, skull piles or extra props outside the building. Balanced charcoal-blue stone, desaturated sea-green, small pale cyan accents; readable three-value grouping at 150 pixels wide. Crisp deliberately clustered pixel edges and restrained outline like reference, no photorealism, no smooth 3D render, no atmospheric bloom. Single object centered with generous empty margins. Genuine transparent background, no painted checkerboard or background shadow. Static building art, not poster, sheet or concept painting.
## Processing and review — 8 September 2026

One built-in image-generation call. Output exec-7d9c4f32-7ad0-4a32-8f85-298ab27bc640.png,
preserved as source.png: RGBA 1536x1024, SHA256
3636a015dccca0578ffc631f78ebc454d0c0b8f8e9a3d98b4114202f986d253b.
Actual transparent background; soft low-alpha surrounding glow was removed by
the existing shared cattle-trail/sprite_grid.py alpha threshold 128. Columns=1,
rows=1, min-component-pixels=1; no pixel resizing or component deletion.
Extracted 897x836 binary-alpha sprite SHA256
804377de550667198f2b995d9c729d9991d4460738bc0596760fe31f2001675b.
Full source and extraction visually inspected: entrance, basin and tentacled
carving remain distinct; no borrowed colonial identity or painted backdrop.
Read-only geography review compared source-art placements at 120px and 110px.
110px is cleaner near the western palm crown. Provisional stair approach pivot
[690,800], initial entrance [27,17] failed native connectivity because its real
foundation sealed the narrow row-17 corridor. Final developmental entrance
[27,16] shifts the whole building north by 32px, keeping both solid walls and
the route below the stairs. A second source-art geography review found this
cleaner, with no trunk bases in the foundation. Old [28,23] is inside palms.
No ground-mask expansion. review.html reproduces the static source composition,
not an engine capture; browser review attempt timed out. Final foreground
foliage sorting and rendered gameplay review are still outstanding.
No external paid API/model generator used. Built-in tool did not report a
per-call credit or monetary cost; no claim of a measured zero cost.
