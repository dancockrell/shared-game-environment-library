# Eastern Fox People female spear skirmisher — candidate

2026-09-08. One ordinary adult female fighter, not a named hero, porter or vendor. Suggested consumer definition agreed with npc_inspection: `actor_def.eastern_fox_people.spear_skirmisher`. Generic agile spear fighter; fast positioning and reach are proposed role cues, not implemented new abilities. Persistent personal name comes from the consumer's generated identity system.

## Source and process

Built-in imagegen only: one initial generation and one parent-authorized background-only correction. No external paid API/CLI calls. Tool accounting unavailable; no zero-cost claim. Exact prompts in PROMPT.txt and ALPHA-PROMPT.txt. Input style/camera reference was viewed and supplied explicitly: ../troops-01/pirate-female-revision-01/extracted/cell_00_00.png, SHA256 52326f77901ee1d4643359d32fea47e25915bfd9146fd3e667b8e66b0c5afc19.

- source.png: original built-in exec-b6d76ca1-4100-48f1-9d78-995af7e83f6b.png; 974x1614 RGB; SHA256 b004ab75cef1c11ca85c5ffab49a92b3e9d4667d9a5218901325aed9b2842ad2. Painted checkerboard, rejected as runtime delivery.
- keyed-source.png: built-in exec-294e94c2-e6ab-4c4b-bcd4-2c09b708eb43.png; 975x1614; SHA256 483cc2296f10c72e4071311ce496d05e52fe232258836538bce1ef99030a78af. Magenta background correction. Identity preserved visually, not pixel-identical: width changed by one pixel, so exact foreground preservation is not claimed.
- extracted/cell_00_00.png: 781x1456 RGBA; SHA256 72614967d92697725b14731ff0cd49c6caffa81d98a8447fe3a3568ac1aeb672. Canonical ../.. /cattle-trail/sprite_grid.py used with columns1 rows1 min-component-pixels1 (actual script path and hash in extraction metadata). Five connected components retained, zero discarded foreground pixels, no cut warnings. Binary alpha spans0..255; magenta keyed without redrawing.

Generated-output provenance under applicable built-in tool terms; no CC0 or external licensed-character claim. Parent owns final admission.

## Placement proposal

Use trimmed-image estimated ground pivot [500,1300], between the two boot contact points, not the bottom of the spear. Suggested uniform scale0.0261 gives approximately36px body height and38px total spear height. Source body crown-to-low-boot extent is approximately1380px. No collision dimensions inferred from tail or spear. Direction SE, single standing pose only, no mirroring of baked light and no animation claim.

## Actual visual review

Viewed full raw source, extracted PNG and nearest-neighbor diagnostic at approximately36px body height on light sand and dark green. review-cutout-36px.png contains native-size samples plus enlargements of those exact reduced samples, not independently detailed redraws. Earlier review-40px-10x.png preserves the rejected checkered source diagnosis.

Jade cross-collar wrap, ivory sash, russet tail, two ears and long broad-headed spear make the fighter distinct from pirate and colonial units. Tail and spear remain recognizable at gameplay size. Adult face and capable slender silhouette fit the intended ordinary recruit. Head/crown and shoulders imply elevated camera; face is three-quarter, although lower body remains somewhat frontal rather than a strict whole-body SE turn. At36px, face detail vanishes and near shin/spear can visually align; this is a candidate weakness, not proof of animation readiness. Detailed source texture reduces to broad clusters, consistent with the current pirate source family but not a pixel-perfect palette match.

Accept as a useful static candidate for parent in-engine review, NOT final shipped art. No runtime edits, Godot windows, commits or pushes from this task.
