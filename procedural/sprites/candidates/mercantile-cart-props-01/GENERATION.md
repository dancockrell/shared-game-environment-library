# Mercantile Street cart and bales

## Review checkpoint

Existing Cattle Trail sprite_grid.py extraction with columns3/rows1/min-component-pixels1 produced three RGBA cutouts, zero cut warnings and no removed small-component pixels. Source and extracted sizes/hashes are recorded in extracted-01/metadata.json. Generated cart visibly rests on its side with tilted bed and differently oriented wheels; no rotated upright picture was used. Source geometry remains an artistic cart design, not an engineering reconstruction. Proposed gameplay-width screenshot scale-review.png inspected: cart150px, tall bale55px, flat bale64px. Dark contours, shafts, wheels and wrapped bale forms remain readable; fine fabric detail compresses into material tone. Ground contact and relative scale remain consumer estimates, not runtime admission. No DR edit or game test; component-only browser capture, then browser closed.

Built-in imagegen, no paid external generation. Candidate only, no runtime admission. Shared production for DR room 1-75.

## Actual source

The road here is partially blocked by an overturned oxcart. Large, burlap-wrapped bales are scattered over the cobbles and the sidewalk, making you detour around them. Other wagons and barrows wait rather impatiently for the harried driver to right his cart, rehitch his team and clear the way.

Exact corpus: DR data/art/room-descriptions-exact.json rooms[1-75], descriptionSha256 9b88c605607943f839c262de5f3e30aebb87a086a5527727a0e6701ef3d2d7fe. Read in full. No ox or driver generated; other waiting vehicles remain separate missing components. Upright Cattle Trail wagon views do not supply overturn geometry, so none were rotated into a false depiction.

## Exact generation prompt

Use case: stylized-concept. Reusable 2D pixel sprite sheet, THREE isolated props in one spacious horizontal row: LEFT an empty wooden two-wheel oxcart genuinely overturned onto its side, showing tilted empty cargo bed, underside axle and one wheel pointing obliquely upward while side rail rests on ground, long shafts resting askew; CENTER a large rectangular bale fully wrapped in rough tan burlap tied with two hemp ropes; RIGHT another burlap-wrapped bale on a different broad side, slightly squatter, tied with crossed rope, visibly closed wrapping. No loose grain or exposed hay. Source DragonRealms room75 says an overturned oxcart and large burlap-wrapped bales scattered across cobbles/sidewalk; no ox or driver sprite in this sheet. Actual Cattle Trail sprite overview is STYLE reference: warm timber broad clusters, crisp dark outlines, restrained wood grain, readable at cart150px/bales55px; existing DR Mercantile screenshot gives target camera and scale ONLY, do not copy UI, actors or scenery. Fixed high-three-quarter gameplay view, consistent upper-left light. Must draw real overturned geometry, not rotate an upright cart picture. Genuine transparent background; if unavailable flat #FF00FF magenta, never painted checkerboard. Each complete isolated subject, big gutters, no overlap, no attached ground, no shadows on background, no water, no people, no oxen, no labels, no panels, no sign. Detailed but compact hand-authored pixel-art visual language, not 3D, smooth rendering or fine noisy stippling.

References: actual Cattle Trail overview.png, style only (hash7af7b4d9b8fe9c98503eb516f3d4684b2d65df46e09882c9d35872324757e03c); current DR sprite-kit-street-1440.png, camera/scale only. Output exec-76e56f91-e17e-448b-a155-3cf549f20d4c.png, model version not exposed. Source figures and UI are not part of output.
