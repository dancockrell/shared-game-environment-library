# Workshop generation record — 8 September 2026

Built-in image generation, not an external paid API. Model/version and actual cost were not exposed. Two calls: source and one background-only correction. The source was not transparent and is preserved rather than admitted directly.

Source SHA256: `ad2688820434516116f2b13d17c9337a105365d686b7a9adeecebe8cafff19b6`.
Magenta correction SHA256: `efff665cf19748a3e824d8221b5590fce2be1cbd903fe282c4330898a28cd348`.
Extracted/runtime SHA256: `d1380c98922aaaa953242b921dfcdae05f1527cb268b721c0ae5574fba1f5718`.

## Source prompt

Use case: stylized-concept. One isolated 2D pixel-art RTS field workshop building sprite. Image1 is CAMERA/PIXEL STYLE reference only, not architecture: same fixed elevated three-quarter orthographic view, rich crisp pixel clusters and upper-left warm daylight. Michael's fantastic1870s American frontier steampunk workshop built from his wrecked steam tea-cutter. Compact raised salvaged-timber platform, rough wooden posts with a partly rolled back weathered cream sailcloth canopy, visible sturdy workbench with vice and period handtools; a small copper riveted boiler, carefully connected brass pipes and gauges beside a clearly visible empty brass-and-leather reclining restoration cradle. Coherent practical invention, not random floating gears. One open lower-front approach; all equipment stays within the rectangular platform. This is an attractive scrappy first settlement building, not a hospital, not a castle, not a factory complex. Entire structure visible, generouspadding, nopeople, nosignage, noletters, noelectronic screens, no neon, no modern devices. Genuine transparent PNG background, no painted checkerboard, no surrounding terrain tile or landscape. Readable at120pxworldwidth beside36pxcharacters; no photorealism or smooth3D.

Reference: runtime `game/assets/island/watch_fort.png`, camera and pixel-style reference only.

## Background correction prompt

Use case: background-extraction. Keep this exact workshop, camera, pixel detail, wood, canvas, pipes, machinery, platform and stairs unchanged. Replace ONLY all background outside the building silhouette with completely flat solid pure magenta #ff00ff, including gaps beyond its exterior. Remove the brown atmospheric glow and external shadow entirely. No gradients, no checkerboard, no new objects. Preserve the whole building and generous clear margins.

Input: `source.png`. Result: `source-magenta.png`. Canonical `cattle-trail/sprite_grid.py`, one row, one column, min-component-pixels 1, default magenta key, produces `extracted/cell_00_00.png`. No animation claim. Placement review is a static composite, not an engine-render approval.
