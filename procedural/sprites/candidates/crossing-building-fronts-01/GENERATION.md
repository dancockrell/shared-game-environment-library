# Whole enclosed building prefab candidates

Production date 2026-09-08. Built-in imagegen only, no paid API. Generic fantasy building styles, not named Crossing landmarks. Candidate outputs, no runtime admission.

## Actual references

Both were viewed and passed explicitly as referenced_image_paths, style-only:

- `../cattle-trail/overview.png`, SHA256 `7af7b4d9b8fe9c98503eb516f3d4684b2d65df46e09882c9d35872324757e03c`.
- `C:/Users/Admin/Documents/Codex/2026-09-07/referenced-chatgpt-conversation-this-is-an-2/outputs/cattle-trail/companion-room.png`, SHA256 `e28c787bf1ef8758edc1a99bb2433f53a0b4ddfd1eb637222535ade658539c79`.

## Exact initial prompt

Use case: stylized-concept. Deliver a production sprite sheet with exactly FOUR original fantasy whole buildings in a two-column two-row grid. Each full building isolated with generous empty gutters. Genuine transparent background, no painted checkerboard. Image 1 and 2 are actual Cattle Trail sprites and gameplay: STYLE references only. Match their broad readable pixel clusters, strong dark contours, compact gameplay proportions, modest effective pixel density, warm restrained colors. Deliberately hand-drawn pixel-art feel, crisp shapes not smooth 3D rendering or fine-grained stippling. Consistent elevated high-three-quarter fixed camera, top and front/right side visible, same upper-left soft daylight and relative human door scale across all buildings. Top left modest one-and-half storey enclosed timber-and-cream-plaster cottage, reddish clay gable roof, tiny chimney, wooden CLOSED door and two shuttered windows. Top right plain single-storey enclosed timber workshop/shop, dark wooden boards, blue-grey shingled gable roof, broad CLOSED plank door, small window; NO sign or text. Bottom left small solid grey-stone civic/guildhall building, intact slate gable roof, simple stone arch CLOSED oak door, two narrow windows, restrained architecture without emblems. Bottom right humble enclosed rural cottage, full warm thatched hipped roof, pale earth-plaster walls, CLOSED dark wooden door, modest shutter window. Every roof and all building walls fully intact and visible, no cutaway, no open house, no missing front walls, no interior, no roof transparency, no crops. Whole buildings NOT loose doors or facade fragments. No people, trees, grass clumps, signs, text, scenery, ground islands, diamond bases or cast shadows outside the silhouette. Original generic fantasy architecture, not named locations, no wildwest branding. All four finished and attractive at small game scale.

## Exact corrective edit prompt

Background-only production edit: preserve these exact FOUR intact fantasy buildings and their layouts, camera, materials, sizes and pixel-art identity. Replace all white/grey checkerboard background with perfectly flat solid magenta RGB255,0,255. Include every gap and outside silhouette. No checker, no new shadows, no new objects, no text. Do not alter buildings or open any doors or walls.

## Source ledger

- `source-01-checker-rejected.png`, built-in `exec-2e6aaedf-d48f-4441-84d7-3c1e02bf48ee.png`, SHA256 `906c700ee694939a07c9ce7efce53ae2c6e59f809bb0e9d209afd6caead7f3ea`. Fake checker RGB despite transparent request; retained rejected as extraction source.
- `source-02-magenta.png`, built-in `exec-85583ae3-e1bd-4cc6-b952-4cbe70fdefcb.png`, SHA256 `d79283a0d21993eaf00d4a24ab7b30b023da5a83904c6dc990b373975afbb95c`. Background-only requested edit; exact source pixel preservation is not guaranteed by generation.
- Existing Cattle Trail `sprite_grid.py` with `--columns 2 --rows 2 --min-component-pixels 1`: four RGBA crops, no cut warnings, zero removed pixels, single connected component each. Source crop bounds, file and pixel hashes in `extracted-01/metadata.json`. No new extraction implementation.

## Quick production review

Full sheet and source-only browser `review.png` inspected. Four buildings remain intact, with roofs, all visible walls, closed doors and legible different material families. No half-open demo house, no characters, signs or baked scene. At roughly 190–215 px high the silhouettes, roofs and doors read cleanly on a neutral ground. There is still detailed texture; this is a candidate visual calibration, not proof of matching shipped Cattle Trail pixels exactly. Cottage roof junction is more elaborate than other prefabs. Door scale is estimated individually in metadata rather than pretending equal sheet cell size means equal world scale. Workshop door is visibly closed and side window shutter is artistic detail. Stone hall has narrow arched windows but is not assigned to any actual guild or civic landmark.

`review.html` uses exact extracted PNGs without effects, mirroring, or rotation. One source-only capture completed and browser closed. No DR gameplay tests, no runtime import. Metadata restricts room matching, inferred exits, lighting mirroring and collision authority. These generated assets remain candidate outputs under applicable built-in tool terms; consumer admission/provenance acceptance is separate.
