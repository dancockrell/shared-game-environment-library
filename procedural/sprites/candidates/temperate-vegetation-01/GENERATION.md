# Temperate vegetation component kit

2026-09-08. Built-in image generation, no paid external API. Candidate only, not runtime admitted. Generated source retained unchanged. No CC0 or MIT art license claim.

## Exact prompt

Use case: stylized-concept. Asset type: reusable 2D pixel-art temperate vegetation sprite kit for an elevated three-quarter RPG, detailed Cattle Trail-like crisp pixel clusters, not 3D. One square sheet with exactly SIX separate sprites in a regular 3 columns by 2 rows grid, each wholly inside its cell with generous empty gutters, no overlap. Top row: a mature leafy oak with visible branching trunk; a slimmer tall leafy deciduous tree; one compact rounded hawthorn shrub. Bottom row: a straight dense privet hedge section oriented horizontally; a dense hedge corner forming an L with visible thickness; a small irregular bramble shrub with subtle thorns. All isolated on genuinely transparent background, no checkerboard drawn. Consistent upper-left daylight, rich natural olive greens with deep shaded leaves and small golden-green highlights, brown textured trunks, finely drawn readable dark contours, detailed illustrated pixel art, no smooth airbrush, no plastic or low-poly appearance. Fixed high three-quarter gameplay view with roots grounded at the lower center of each sprite. No ground tiles or turf islands, no cast shadows extending outside the silhouette, no people, buildings, roads, labels, UI or text. Each component must be easily extracted and reused independently; this is a component sheet, not a landscape.

## Initial visual review

Source SHA256: `0b6745748800b40b5a7cfb9ab89d7c52bae22f5eff9d2a188885c07ee47a7f53`.

## Extraction checkpoint

## Independent native-scale review

Read-only reviewer checked trees at 180px width and shrubs/hedges at 130px width. Six hashes match extraction metadata. Minimum cell margin is 9px; no silhouette clipping. All cutouts have genuine binary alpha. Bramble retains six strongly magenta pixels, negligible at tested size but still a final-cleanup concern. Five other cutouts have none.

Do not use a uniform width: slender tree would become 368px tall against oak 209px. Calibrate by target height per species. Hedge and bramble pivots lie on transparent ground and are valid only as estimated placement pivots, not collision footprints. No shadows or reviewed occlusion masks are supplied. Candidate approved only for a first composition experiment, not broad room population.

Reused the Cattle Trail `sprite_grid.py` adaptive-gutter extractor with `--columns 3 --rows 2 --min-component-pixels 1 --key-difference 255`. Per-row adaptive cuts found six separate components with zero cut warnings; no fixed equal-cell slicing was used. No RGB color was keyed away. The extractor thresholds source alpha at 128 and keeps every detached component; original alpha remains in source-01.png. No scaling applied. Metadata records all bounds and hashes. `kit.json` supplies names, estimated ground anchors and semantic restrictions. These are not seamless tiles and are not admitted to the client yet.

Six discrete subjects, coherent palette and detailed sprite shading. The requested regular grid was not followed: the oak spans beyond a one-third column and the top row is taller. Do not slice using equal grid cells. Use reviewed per-object bounds. Flowering shrub and berries imply season and must not be placed universally. Hedge corner is a visual component, not a graph exit or proof of traversability. Alpha channel, native-scale legibility, extraction and actual client composition remain to be verified. No rooms receive coverage credit from this source sheet.
