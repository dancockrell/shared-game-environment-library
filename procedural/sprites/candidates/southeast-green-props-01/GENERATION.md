# Southeast Green furniture candidates

Built-in imagegen, no paid API. Source-only, runtime admission false. Four furniture components; no modwyn botanical depiction commissioned.

## Room source

DR `data/art/room-composition-generated.json`, room 1-15: "This tranquil corner of the Green has a small bower of entwined modwyn vines, laden with tempting, grape-like clusters. A limestone bench and some sawed-off sections of trees that serve as rustic stools make up an open-air performance space, where bards, musicians and poets can demonstrate their talents."

The actual map 1 room 15 has exits north17, west16, northwest14, go grass path371, go amphitheater gate377. Furniture positions do not establish these exits. Bench construction, stool bark and end-grain are artistic interpretation; unspecified modwyn anatomy stays unresolved rather than invented.

## Exact prompt

Use case: stylized-concept. FOUR isolated furniture sprites in a 2x2 grid. Style references: supplied actual Cattle Trail gameplay screenshot and sprite overview, style only. Match its crisp dark outlines, broad warm shaded pixel clusters, compact legible camp prop silhouettes, NOT smooth 3D or detailed speckled textures. Fixed elevated three-quarter gameplay view, consistent upper-left daylight. Top-left: simple pale warm-grey limestone bench, thick rectangular seat slab resting on two short block legs, no back, no carving; long axis lower-left to upper-right. Top-right: same humble limestone bench seen on opposite diagonal, upper-left to lower-right, independently drawn with SAME upper-left lighting, not a mirror. Bottom-left: one rustic stool made from a short thick sawed-off section of tree trunk, bark sides and flat round end-grain seat with clear growth rings, no added legs or branches. Bottom-right: a slightly narrower sawed-off tree trunk stool with subtly different bark and end grain, same seat height relative to bench. Four complete objects centered separately, generous clear margins, large gutters. Genuine transparent background, if unavailable perfectly flat #FF00FF magenta instead, never checkerboard. No ground patches, no shadows on background, no people, vines, flowers, tools, signs, text, panels or UI. Bench readable around120 pixels wide, stool around40 pixels wide; chunky light/dark planes and intentional clean pixels. DragonRealms source says limestone bench and sawed-off tree sections used as stools in an open-air performance space. Do not invent a named location, botanical species or ornate features.

## References and output

Actual Cattle Trail companion-room.png gameplay and overview.png were inspected and passed as style-only reference paths. Reference SHA256 respectively e28c787bf1ef8758edc1a99bb2433f53a0b4ddfd1eb637222535ade658539c79 and 7af7b4d9b8fe9c98503eb516f3d4684b2d65df46e09882c9d35872324757e03c. Output exec-d4d25262-96d9-4037-b546-6569ca43ca15.png. Built-in model version not exposed. No third-party download.
