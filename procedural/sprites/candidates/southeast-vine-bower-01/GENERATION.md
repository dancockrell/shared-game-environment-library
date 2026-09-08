# Southeast Green vine bower candidate

Built-in imagegen,2026-09-08. One referenced image plus one background-only correction; no paid external service. User-authorized cross-game style references; generated output under applicable tool terms, not a claim that botanical interpretation is canon.

## Authoritative description

DR `public/roomtext/1.json`, exact1-15: "This tranquil corner of the Green has a small bower of entwined modwyn vines, laden with tempting, grape-like clusters. A limestone bench and some sawed-off sections of trees that serve as rustic stools make up an open-air performance space, where bards, musicians and poets can demonstrate their talents."

Only entwined vines, bower and grape-like clusters constrain this component. Exact leaf shape, fruit color, woody support and arch geometry are not specified. Olive lobed leaves, dusky-purple fruit and braided woody stems are declared artistic interpretation. Decorative glass modwyn berries or gold glass color are NOT botanical evidence. No outside source is claimed to establish living fruit color. The result contains no bench, stools, actors, sign, stage or building.

## References

Actual Cattle Trail gameplay `C:/Users/Admin/Documents/Codex/2026-09-07/referenced-chatgpt-conversation-this-is-an-2/outputs/cattle-trail/companion-room.png` and existing shared `southeast-green-props-01/scale-review.png`. Both inspected. The furniture plate supplies compatible pixel style and comparison scale, not furniture to bake into the bower.

## Exact generation prompt

Use case: stylized-concept. Create one reusable 2D pixel-art VINE BOWER component, completely isolated, NO furniture or people. Reference1 is actual Cattle Trail gameplay style authority; reference2 furniture review gives compatible pixel density and pale warm materials only: do NOT copy the benches or stools. DragonRealms room source describes a small bower of entwined modwyn vines laden with tempting grape-like clusters, open-air performance space. Depict a modest broad vine arch supported by just two irregular woody vine stems, lightly interwoven branches across top, NO conventional building. Open center large enough to frame bench and two performers later. Make a shallow open-backed arch, not a tunnel or enclosed gazebo. Vines braid up left and right margins, canopy across top, visibly dangling small grape-like dusky-purple fruit clusters. Olive-green broad leaf clusters, consistent dark outline, restrained muted sunlight upper-left. Leaf shape, purple fruit and woody support are artistic interpretation, not botanical canon. Match detailed yet readable Cattle pixel art: coherent medium pixel clusters, not tiny stippled leaves, no smooth3D or photorealism. Fixed elevated high-three-quarter camera as references, generous padding. Entire component including two ground contacts fully visible. Transparent RGBA everywhere outside vine silhouette AND through the big central opening. No checkerboard, backdrop, soil island, diamond base, stone, flowers, hanging signs, fences, roof tiles, furniture, lamp, stage, people, text or detached cast shadow. Intended display height about230px. Bottom and middle center must remain completely empty for actors and separate bench.

Initial `exec-178160c0-b08d-4dd8-b12a-97f51d32c1c9.png` retained as `source-01-checker-rejected.png`; fake checkerboard rejected for alpha delivery.

## Exact background correction

Precise background-only edit. Keep this vine arch exactly unchanged: all twisted woody vines, grape-like fruit clusters, leaves, full silhouette, pixel style, colors, positions, size and camera. Replace ONLY all white and gray checkerboard everywhere outside the vines and throughout the large center opening and little leaf gaps with perfectly flat solid pure magenta #FF00FF. No background gradient, texture, shadow or extra objects. This is a chroma-key production source.

Corrected `exec-100aef10-9803-4c61-a450-4c8a68937300.png` retained as `source-02-magenta.png`, SHA256e399608e6beaedcc5369d4aa06699a2c998026702c13b6b8db09ce76b4e732f1.

## Extraction and source review

Existing `cattle-trail/sprite_grid.py source-02-magenta.png extracted-01 --columns 1 --rows 1 --min-component-pixels 1 --key-difference 100`. Higher chroma difference preserves muted purple fruit while removing saturated magenta background. One1099x1014RGBA cutout, two retained connected components, no warnings or removed small pixels. Metadata contains bounds/hash. Center rectangle[300,430,850,930] has max alpha0; zero retained pixels meet the saturated-magenta rejection criterion.

`review.png` inspected at230px bower height alongside separate120px bench. The open center accommodates that bench without baked furniture; fruit clusters and braided stems remain legible. View is near-front elevated arch, not an alternate rotated view; no mirroring/rotation implied. Leaf scale and purple fruit are interpretive. Source-only review is not DR runtime admission; actor occlusion, native placement and collision remain consumer decisions.
