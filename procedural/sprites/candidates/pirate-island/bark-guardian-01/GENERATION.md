# Elven bark guardian standing candidate

One bounded built-in image generation attempted; **FAILED, NO ASSET RETURNED**. Existing gameplay ID `actor_def.elven.bark_guardian`; monster, not person. Production metadata is `spawn_rule.heart_grove.guardians`, 5 ticks, population 2, heart grove. This asset does not author new combat powers.

References: game `game/assets/island/troops/colonial.png` for current runtime sprite treatment and `docs/images/pixel-style/character-sheet.png` for approved style/camera. Both viewed before generation. Reference identities are not reused. Scope: 40–50px high standing monster; source, chroma extraction, authored pivot and scale review only. No animation or runtime approval implied. No external paid/API tool.

## Exact prompt

Use case: stylized-concept.
Asset: ONE standing Elven bark guardian monster sprite for Pirate Island, designed to be read around 45 pixels high beside the ordinary colonial unit. Image1 (colonial soldier) and image2 (cowboy sheet) are STYLE AND CAMERA references only: do not copy any person, costume, firearm, horse, or sheet layout.
Subject: a compact, hardy living-wood defender grown by an elven heart grove. Broad trunk chest, two sturdy articulated bark arms with chunky wooden hands, two separate thick root legs with plainly planted root feet, a small stern wooden face under a low crown of three short branch stubs and a few emerald leaf clusters. Adult ancient creature, neither human nor female nor a child, not a tree with no legs. Recognizable bark plates wrapping real shoulder/elbow/knee joints, warm umber and honey-brown wood, deep green moss only in restrained patches. No axe, shield, weapon or armor; its body is its protection. Memorable solid sentinel silhouette, not spindly, not grotesque.
Pose/camera: one quiet defensive standing pose, whole body facing southeast/down-right viewed from a clearly elevated fixed three-quarter game camera. See crown and shoulder tops. Shoulders, chest, pelvis, wooden face and feet agree on southeast facing; far arm partly occluded, near arm offset from torso with a clear dark gap, two root feet clearly separated. No frontal portrait, no action leap, no T pose.
Pixel treatment: match reference rich crisp sprite art but prioritize clear large clusters at 40–50px gameplay height: three-value bark planes, strong dark contour, minimal fine bark lines, readable face and hands. No smooth airbrush, tiny texture noise, photorealism, 3D render or generic clay shapes.
Composition: exactly ONE isolated full body on completely uniform saturated MAGENTA #FF00FF background for deterministic chroma extraction; preserve gaps between limbs as magenta. Complete crown, hands and feet within generous padding. No ground tile, cast shadow, floor, checkerboard, labels, watermark, scenery or extra poses.

## Attempt result

Built-in `image_gen` returned HTTP 400 `moderation_blocked`, output-stage category `other`, request ID `b65007be-33a0-4a52-ae44-822465a31d71`. No image, output path or generation provenance beyond the rejected request was returned. The reported category does not explain a specific cause; do not invent one.

One authorized generation call was used. No retry, alternate tool, API/CLI, external paid generation or image substitute. No source hash, alpha, pivot, scale or 40–50px review can be supplied because no asset exists. The intended 45px target is not an accepted scale. No game changes or commit.
