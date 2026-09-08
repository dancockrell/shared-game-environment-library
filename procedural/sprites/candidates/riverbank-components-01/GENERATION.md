# Riverbank components 01

Generated candidate kit, not runtime admitted. Built-in imagegen; no paid API. Six bounded overlays, not seamless room tiles or graph edges.

## Exact prompt

Use case: stylized-concept. Asset type: SIX separate reusable 2D riverbank overlay sprites, one spacious 3-column 2-row sheet. Supplied images are STYLE-ONLY references to actual Cattle Trail gameplay and sprite catalog. Match their broad legible pixel clusters, dark brown contours, restrained detail and small gameplay scale; no 3D rendering, no fine stippled noise. Top row left: low earth bank strip with grassy top and exposed soil front, running upper-left to lower-right, front facing lower-right/SE. Top row middle: matching low earth and grass bank running lower-left to upper-right, front facing lower-left/SW, independently drawn under SAME upper-left lighting, NOT a mirrored copy. Top row right: low weathered stone quay edge strip facing SE, few chunky grey-brown rectangular stones, narrow paved top. Bottom row left: corresponding stone quay edge facing SW, independently drawn upper-left lighting. Bottom row middle: isolated small reed clump with green/tan blades and three brown seedheads. Bottom row right: flat shallow muddy-gravel oval patch with sparse stones, no puddle. Each item fully contained, broad blank gutters and generous outer margins, no overlap. Transparent background requested; if alpha unavailable use perfectly flat solid magenta #FF00FF extraction background, NEVER checkerboard. No water background, no grass rectangle beneath objects, no surrounding scenery, no people, boats, signs, letters, labels, grids or UI. Fixed elevated three-quarter gameplay view, crisp pixel edges, warm muted daylight, earthy ochre dirt and olive grass with grey-brown stone. These are bounded bank strips and patches, not full room scenes. Use compact chunky readable shapes like the Cattle Trail fence, rocks and grass examples.

## Inputs

Style-only actual Cattle Trail `overview.png` (SHA256 7af7b4d9b8fe9c98503eb516f3d4684b2d65df46e09882c9d35872324757e03c) and `companion-room.png` (SHA256 e28c787bf1ef8758edc1a99bb2433f53a0b4ddfd1eb637222535ade658539c79). Both inspected before generation; overview camp/fence/rock forms and gameplay scale informed the brief, not DragonRealms geography.

Output: `exec-51f1bf33-802f-4c13-a1f4-42ede0e488b6.png`. Model version not exposed by built-in tool. No third-party download or paid API.

## Extraction and brief visual review

Source is genuine RGBA 1536x1024 with alpha range 0..254 and 467120 partial-alpha pixels. The viewer shows a soft colored halo in the source; it is not an opaque backdrop. Existing `cattle-trail/sprite_grid.py` used `--columns 3 --rows 2 --min-component-pixels 1`: six trimmed binary-alpha PNGs, no grid-cut warnings and no discarded small components. Its existing alpha-128 threshold removes the faint halo; source remains preserved unchanged. This threshold also loses faint edge pixels and is not lossless alpha preservation. Full source plus extracted bank and quay inspected: complete silhouettes, readable grass/soil and chunky stone forms, no water or actors. Both bank directions and both stone directions are present; their exact shape is not mirrored or geometrically identical. Stone direction ordering differed from the verbal requested order, so metadata describes actual screen-axis orientation instead of claiming compass direction. Style source review passed as a candidate, not final native-scale approval.

Extraction metadata records exact source/extractor/output hashes, source rectangles, dimensions and processing. Estimated anchors in kit.json are placement pivots only; not footprints or joints. No DR runtime edit or game test performed.
