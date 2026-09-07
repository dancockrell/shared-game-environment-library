# Town Green Northwest — 1-225

Status: source candidate. Built-in image generation, no paid external API,
2026-09-08. Opaque1536x1024 static room background for the existing tactical
scene; actors rendered independently. Pair with Southwest source; distinct
geometry grounded in each room's prose, not arbitrary reusable filler.

Source: DR `public/roomtext/1.json`, compiled through the room/place map:

> The entrance to Tembeg's Armory is through a hacked-out breach in the thick hedges that border the Green here. Tembeg, being a humble sort, has laid down a few planks leading into his establishment to serve as a walkway. Samples of his work are hung on hooks on the exterior of the unpainted wood structure but no sign or other eye-catching gimmicks are noticeable.

Style reference: neighboring Town Green North runtime PNG, hash
`f55470f3f63d6eb3b6365a8f7a35804a691255075c2b583949ebc3543f763e29`.
Building roof shape and individual armor sample types are artistic interpretation.
Entrance and planks are specifically established; no sign is allowed.

## Exact prompt

Use case: stylized-concept. Asset type: a single polished detailed pixel-art fantasy RPG room backdrop, landscape 1536x1024. Image1 is ONLY the neighboring room's visual style reference: match foliage, grass, palette, fine pixel texture, soft upper-left daylight and high three-quarter top-down camera. New room is Town Green Northwest. Show a humble UNPAINTED timber armory exterior along the upper edge, a small ordinary roof, and its entrance reached through a visibly hacked-out breach in a THICK hedge. A FEW plain rough wooden planks form the short walkway through the hedge breach into the door. Practical armor samples hang individually on exterior wall hooks: modest worn breastplate, helmet, shield as artistic interpretation of samples, not a market stall. No painted facade, no sign, no banners, no writing or eye-catching gimmicks. The modest enclosed building is a production exterior, not a half-open dollhouse. Most of the composition is beautiful open green grass in the central and lower ground for independently rendered player and enemy sprites; keep centre and mid-right clear. Hedges frame the armory entry without spreading props into the playable lawn. No people, animals, creatures, UI, labels, watermark, horizon, dramatic blur, photorealism or 3D render look. One continuous room illustration, not a sheet. Keep the plain planks and rough hedge breach clearly distinguishable from a cobblestone path.

## Gates

Check humble enclosed unpainted timber building, real hedge breach, plain plank
entry, wall-hook work samples, no sign/text; clear playable lawn; consistent
style/camera/light. Source preservation and native room/prose checks required.

## Targeted material correction

First output `exec-61b44229-f314-4fa0-a411-d1208f3abfa4.png` retained unchanged
as `source-01-rejected.png`. Rejected: stone/plaster wall panels contradict
the explicitly unpainted wood structure. Do not admit this source.

Exact correction prompt:

Use case: precise-object-edit. Edit only the armory building's WALL MATERIALS in this room illustration. Replace ALL stone and plaster wall panels, including front facade under the hanging armor and visible side facade, with plain weathered UNPAINTED WOODEN BOARDS in natural brown. The whole humble structure must read as a wooden shed/armory, not a stone or plaster building. Keep the existing wood framing, small roof, entrance, hanging armor hooks/samples, hedge breach, rough plank walkway, grass, camera, lighting and composition exactly unchanged. No signs, text, paint, extra objects or new structures. Preserve detailed pixel-art texture. This is a material correction only.

Corrected output `exec-617f4d81-9ed1-4c34-a7df-e86a494cdaf7.png` preserved as
`source-02.png`, SHA256 `37218ec2dde2539beb305b771139a3e986f5d519f16588f195c75dbf6aab04f2`.
Visual review confirms wooden front and side walls, closed production exterior,
hedge breach and plain plank approach. No sign or text; empty lawn remains clear.
Source accepted for consumer review; native room and actor-scale verification pending.
