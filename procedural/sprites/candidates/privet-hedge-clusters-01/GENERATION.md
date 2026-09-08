# Privet hedge clusters: candidate replacement

2026-09-08. Built-in imagegen only, one two-component source plus one background-only correction. No paid external generation. Previous temperate vegetation source preserved unchanged. Sources generated under applicable tool terms; project reuse authorized by user, not an independent permissive-license claim.

## References and intent

Actual Cattle Trail gameplay `C:/Users/Admin/Documents/Codex/2026-09-07/referenced-chatgpt-conversation-this-is-an-2/outputs/cattle-trail/companion-room.png` and actual extracted Cattle trees atlas delivered to DR `public/sprite-art/temperate-vegetation-preview/trees-atlas.png` (SHA256441002e38859674e378a49adce3dcd7e52dd62d7f523893f38151b7650aeeaba). Both inspected. The old hedge was visibly stippled, bright and inconsistent with broad Cattle leaf masses; source review compares them at identical140px display widths.

## Exact generation prompt

Use case: stylized-concept. Production 2D pixel-art hedge kit, EXACTLY TWO isolated components side by side with huge empty gutter, consistent scale. Image1 is actual Cattle Trail gameplay style authority, Image2 actual tree atlas authority. Match their modest effective resolution, larger olive leaf clusters, smooth readable masses and dark contour. DO NOT copy tree trunks or turn hedges into trees. LEFT: one low dense privet hedge straight section, broad continuous flat-ish top, flat ground contact, viewed elevated three-quarter like gameplay. Long axis projected roughly left-down to right-up at shallow angle. RIGHT: matching low privet hedge L-corner section, joined solid bend, same hedge height and thickness, open inner angle visible, no hole or gate. Healthy leaf-on green; pale olive broad highlight clumps on top, restrained dark green shadow face, hand-drawn pixel clusters about 6 to12 pixels across at output resolution, only 4-5 broad color values, avoid isolated bright speckles, stippled noise, photographic tiny leaves, shiny plastic, smooth3D, excessive saturation. Few discreet dark twig hints at base, NO exposed trunks, NO berries, flowers, fences, stone foundation, raised earth islands, props or cast shadows outside silhouette. Consistent upper-left soft daylight. Each fully visible component amplepadding, straight and corner same physical hedge height. Assets for about100-160px displayed width; their masses must read beautifully at that size. Genuine transparent RGBA background, no painted checkerboard, no text.

Output `exec-a1484cf7-f1a7-4a1e-9a84-23ab005a79aa.png` retained as `source-01-checker-rejected.png`; painted checkerboard means not usable alpha.

## Exact correction prompt

Precise background-only edit: preserve both hedge components exactly in position, size, camera, silhouette, clustered-leaf pixel artwork, colors and texture. Replace ONLY the entire white-gray checkerboard with perfectly flat solid pure magenta #FF00FF. No gradient, checker, texture, or noise in background. No changes to either hedge and no extra objects, text, scenery or shadows. This is a chroma-key production image.

Output `exec-2428941e-91c3-4e60-b28e-f881c2a309f1.png`, `source-02-magenta.png`, SHA256a9d13f395b277c4d9cacbbc4abab107ffdd53ea41b33ba523a4d264bb9b77fee. Exact pixel preservation between generated edits is not guaranteed.

## Extraction and comparison

Existing `cattle-trail/sprite_grid.py source-02-magenta.png extracted-01 --columns 2 --rows 1 --min-component-pixels 1`; no rescaling, no removed specks, no warnings. Two retained connected components per sprite include tiny detached edge pixels. Metadata records all source bounds and hashes.

Actual `review.png` source-only browser comparison inspected at140px and200px widths. New leaves read as olive clusters rather than fluorescent isolated dots; dark contour remains continuous, top/front distinction legible. Lower hedge silhouette is intentional, not a scaled-down tree. Comparison uses exact PNGs with pixel sampling, no recolor, filtering or fake beautification. These are good candidates for a consumer trial, not approved DR room art. Source pattern is more orderly than a natural hedge; avoid filling entire terrain with identical repeats.

Anchors and ground centerlines are manually estimated from visible base. Straight projection direction changed relative to old art, so it is NOT a drop-in geometry replacement. Consumer must re-author endpoints/contacts rather than retaining old sizes and transforms. No seamless joining or collision authority is claimed. Corner hollow is a bend, not a navigable opening.
