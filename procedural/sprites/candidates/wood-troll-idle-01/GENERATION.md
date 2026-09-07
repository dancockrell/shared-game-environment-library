# Wood troll — restrained idle sprite pack

## Source and identity

DragonRealms cached data/elanthipedia/bestiary.json, Wood troll (1): Crossing, Vineyards map7a and Lake of Dreams map3. Description: "The wood troll stands between seven and eight feet in height. Its skin is a tough, bark-like texture, covered haphazardly with patches of a mossy grey fur. It looks at you with beady black eyes, staring down a long nose that protrudes from his face like a twisted root."

Variants Wood troll (2)/(3) share this appearance but different habitats/levels. Runtime exact name wood troll; do not map generic troll, rock troll, cave troll or other species. This art does not establish any particular room spawn.

Visual interpretation: brown bark skin, grey mossy fur patches, long root-like nose, large biped silhouette, plain ragged waistcloth. Eyes retain small highlight rims rather than a perfectly black iris. Small bark protrusions and cloth are artistic—not lore equipment assertions. Empty hands are neutral unarmed presentation; do not imply mob cannot use weapons. No attack, damage, death or walking clips supplied.

## Production contract

2026-09-08 built-in imagegen only, no paid external API. Model version unavailable. Reference ../adventurer-standing-01/source-01.png SHA25637fac227a96874268c487a62bf11aef5a0f1e9281af0f71a3c8c52c9162310b6 supplies rendering/camera style, not identity. Original raw sheets preserved; no external third-party image downloaded. Generated under user-directed project workflow, not claimed human-authored.

source-01.png SHA256 afa073c77fbae84ac9dec5df93b444d79a8bbfaa3ada4fa4285b9b191918de0d: first six-pose sheet. Superseded for visible magenta reflection on far hand. Its extracted/ directory remains experiment evidence only, not runtime selection.

source-02.png SHA256 31fc090eced1093e3b0ed230f2b28ccb09d3a2717deb10c92b2b65d904233389: targeted hand-color correction. Selected extracted-02 frames have true RGBA and no gutter warnings. All6 preserved at original size; no components removed, no rescaling. Existing Cattle Trail sprite_grid.py reused read-only, SHA256 d6aa76d7ba4f74209b3022ead3b4a8fbc0704a03a4f34b04059b215ce4f0ac4d. No duplicated extraction implementation.

Command: python procedural/sprites/candidates/cattle-trail/sprite_grid.py procedural/sprites/candidates/wood-troll-idle-01/source-02.png procedural/sprites/candidates/wood-troll-idle-01/extracted-02 --columns 3 --rows 2 --min-component-pixels 1

## Clip

One southeast/down-right direction. Neutral hold2200ms, breathing200ms, slight head tilt200ms, blink120ms, open eyes200ms, neutral return600ms. 3520ms nominal cycle. Manual foot-midpoint anchors171,432; head-tilt frame171,430 accounts for its2px shorter top trim. No independent resize. At0.34 source scale approximately153px tall. Motion and anatomy reviewed in offline player, client integration remains parent-owned. Static fallback is cell_00_00.png. Reduced motion should use static fallback. Do not call this walking or combat animation.

## Exact initial prompt

Use case: stylized-concept. Asset: 2D fantasy game sprite sheet, 1536x1024 landscape, exactly 3 columns and 2 rows of equal 512x512 cells. Image 1 is pixel rendering and high-three-quarter camera STYLE reference only; create a DIFFERENT NONHUMAN creature. Six poses of ONE identical DragonRealms WOOD TROLL, always facing diagonally DOWN-RIGHT/southeast. Canonical appearance: seven to eight feet tall, tough bark-like skin, haphazard patches of mossy GREY FUR (fur tufts, NOT leaf foliage), beady black eyes, long crooked nose protruding like twisted root. Large strong bipedal humanoid, weathered root-brown grey-olive skin, long arms, heavy feet, expressive grim face; richly shaded crisp earthy pixel art matching reference. Simple ragged brown waistcloth for neutral presentation, no armor, weapon, magic, leaves growing from head, horns or invented faction insignia. Full body, entire head and feet inside every cell with at least 40px gutters. Tall subject roughly 380px in every 512 cell. SAME scale, same camera, feet at exact same local coordinates, same silhouette and palette across frames. Sequence left-right top-bottom: 1 neutral alert idle; 2 subtle upper chest breathing lift with feet planted; 3 slight head tilt while feet planted; 4 blink eyes closed and head back neutral; 5 eyes open neutral; 6 exact neutral return matching frame1. Restrained idle, NOT walking, lunging or attacking. Do not move the feet or resize body. Flat solid saturated magenta background RGB255,0,255 #FF00FF outside all six subjects, NO transparency request, no checkerboard, gradient, ground shadows, glow, labels, gridlines, UI, scenery or other objects. Magenta chroma-key source for clean deterministic sprite extraction. No magenta pixels within subject, no antialiased magenta haze.

## Exact correction prompt

Use case: precise-object-edit. Image 1 is the edit target: six wood troll idle sprites on magenta key. Change ONLY the purple/magenta discoloration on the far/right-side hand and fingers of EACH troll to the SAME natural dark root-brown bark skin color as its other hand, preserving all finger outlines and anatomy. Also keep eyes dark near-black rather than amber glints. Do not move or redraw the creatures, do not change posture, dimensions, fur, outlines, noses, body proportions, cell grid, canvas size or foot positions. Preserve distinct closed eyelids of bottom-left blink. Keep the entire flat background vivid uniform #FF00FF magenta for chroma key; ONLY the skin pixels of hands must stop being magenta/purple. No magenta spill on subject. Output same 1536x1024 image.

