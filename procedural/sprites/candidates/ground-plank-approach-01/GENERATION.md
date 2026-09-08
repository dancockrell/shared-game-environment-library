# Flat plank approach candidate

Built-in imagegen, 2026-09-08, no paid external service. Single reusable ground component, not a room. Cattle Trail camp/fence/rocks atlases inspected; no suitable plain loose board walkway. River dock/ramp rejected for this use because supports/incline imply elevation.

References: Cattle Trail `outputs/cattle-trail/companion-room.png` (actual native gameplay style) and DR `data/art/out/sprite-kit-northwest-1440.png` (workshop camera/material/doorway). User-authorized shared-game artwork; generated output under applicable tool terms, not a claim of independent MIT licensing.

## Exact initial prompt

Use case: stylized-concept. Create ONE isolated reusable 2D pixel-art component, not a scene. Image1 is the exact Cattle Trail gameplay pixel-style reference. Image2 is ONLY camera/material/doorway reference for a plain timber workshop. Subject: three plain weathered unpainted wooden planks laid side by side FLAT directly on ground, making a short humble walkway. No supports, posts, legs, risers, raised platform, bridge, dock, railings, water, grass, building, people, nails decoration or text. Fixed elevated three-quarter camera matching references: long axis projects from bottom-left foreground toward upper-right background; boards have only a thin dark edge, one board thickness, NO slope or incline. All three boards parallel along walking direction, slight uneven ends, quiet restrained wood grain, warm desaturated brown with upper-left daylight and restrained highlights. Crisp pixel clusters like Cattle Trail, not photorealistic, not glossy, not a 3D render. Generous empty padding around the single whole component, fully visible silhouette. Genuine transparent RGBA background; do not draw a checkerboard. No cast shadow outside the boards. This will appear around120px wide in gameplay, so readability matters more than dense micro-detail.

Output `exec-4a22b67a-d686-40dd-a874-86aba3781d6a.png`, retained `source-01-checker-rejected.png`: painted checkerboard, rejected for extraction.

## Exact background-only correction

Precise object edit. Keep the three flat wooden planks exactly unchanged in shape, camera, pixel style, dimensions, position and material. Change ONLY the white/gray checkerboard background to one perfectly solid flat pure magenta #FF00FF color. No gradient, no checkerboard, no noise in magenta. Preserve every wood pixel and thin dark board edge. No added objects or shadows. This is a chroma-key production source.

Output `exec-bf2eb3ed-b0e7-410f-90b3-179a22d71674.png`, retained `source-02-magenta.png`, SHA256 `0d4425699b7c236a6a26178db5b76d51f63591c50e4a988179d6e9e21a8bbfe9`.

Existing `cattle-trail/sprite_grid.py source-02-magenta.png extracted-01 --columns 1 --rows 1 --min-component-pixels 1` produced one1135x625 RGBA cutout, no warnings, one retained connected component, no deleted specks/rescaling. Metadata records exact bounds and hashes. Full output inspected: three flat boards, no supports or railings; plausible modest approach. Contact pivot and consumer alignment remain authored estimates, not collision authority. No mirroring or pixel rotation to invent other orientations.
