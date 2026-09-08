# Crossing interiors sheet

One4column3row sheet,12 static props requested. Candidate usable count must
follow actual extraction and gameplay-size review; not promised12 on generation.
Existing river-dock and smithy-garden kits inspected as neighboring families;
this batch fills enclosed interior furniture rather than duplicate outdoor cargo.
Generic furniture, no room-specific landmark or live state claim.

Row1 rectangular wood table, round table, chair, stool.
Row2 bench, bed, closed wardrobe, empty bookshelf.
Row3 counter, empty wall rack, washbasin stand, unlit stone hearth.
Fixed elevated three-quarter camera, earthy detailed Cattle Trail pixel clusters,
restrained upper-left light, cohesive worn warm oak/stone palette, full silhouettes
with margins, flatmagenta key. No labels, characters, scene or glossy3D.
Existing Cattle Trail extractor, no new raster pipeline. Built-in imagegen only,
one sheet plus at most one correction. Tool version/credit count unavailable;
generated pixels follow tool terms, not asserted MIT/CC0.

## Results —12 usable reviewed candidates,0 rejected extracted cells

2026-09-08 source01 output exec-7d00f609-e306-4852-9426-4a191af5ea91.
Good designs, but uneven row spacing and unwanted alpha edge flecks; not selected.
One correction only, source02 output exec-6486fb13-80fe-48df-95d9-1a624f5fc530.
Actual1448x1086, sourceSHA256
21924a305f7f0e92c2cd6a8db398f3a06ee316284d42b002f76fc0d9bf4b0271.

Original prompt follows the12 ordered subjects above, exact4column3row equal
cells, full silhouettes/generous gutters, coherent warm worn oak/grey stone/
cream linen, elevated lower-right facing camera, Cattle Trail crisp pixel
clusters and upper-left light. No text/grid/characters/scene/cast shadows/3D.
Correction preserved designs and order, requested equal384pxcells on1536x1152,
minimum32px padding and max320px object bounds, flat#FF00FF through all gaps.
Actual output resolution differs; existing extractor uses actual pixels, never
assumes requested size. Corrected layout fits cleanly despite resolution change.

Extraction: existing cattle-trail/sprite_grid.py source-02.png extracted-02
--columns4 --rows3 --min-component-pixels1.12RGBA PNGs, no rescale, no cutting
warnings. Source rectangles, trims, helper hash, per-cell PNG/RGBA hashes and
component counts preserved in extracted-02/metadata.json. All12 dimensions and
PNG hashes independently checked. kit.json records exact ids/files/sizes/manual
anchors/mounts/semanticTags/status per consumer contract. Rack uses wall anchor;
all other anchors estimate projected ground center, not a collision polygon.

Offline review.html displays the actual alpha cutouts at96–160px, not mockups.
review.png inspected: all12 requested objects recognizable, coherent light/
palette, empty shelves/rack clear, no visible magenta halo, full bases/legs intact.
First screenshot viewport cut off bottom labels; recaptured taller to verify
whole sheet, then browser closed. No server or DR runtime testing.12 candidates
are usable for placement review, not automatically admitted to every game room.
Wardrobe closure, empty shelves and unlit hearth are depicted states, not inferred
live MUD state. No world scale/seam/physics claims; source01 remains unselected.
