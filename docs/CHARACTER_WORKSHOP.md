# Shared character workshop

Reusable production instructions live in `.agents/skills/character-art-production/SKILL.md`. They preserve faction-specific art direction while using this shared implementation.

## Outerwear construction checkpoint — 6 September 2026

The compiler now constructs short and long open-front cloak prototypes for both prepared bodies. The same wardrobe profile exposes a mutually exclusive Outerwear slot, a shared cloak dye and all eight linked fit targets. This is actual generated cloth geometry with UVs, normals and skinning, not a reference image. Both rendered workshop runs completed with zero assertion failures, including front/back captures and removing outerwear.

Visual review: the initial long cut stretched its yoke below the shoulders; separating shoulder drop from hem length and moving the collar anchor improved that defect. The current shoulder attachment still looks too square and lacks a convincing closure, hem treatment, material detail and secondary movement. It is a **construction prototype, not approved faction art**. The surrounding modern suits remain source-fitting fixtures. Cloaks follow the upper torso rigidly; eight fit targets and a valid rig do not prove combat-motion clearance or cloth simulation. Runtime admission remains pending.

The next revision expands the front opening around the collar and constructs an independently dyeable border as a second mesh surface. Both cuts retain all linked fit shapes. The front now reads as a cloak, but the arm/body intersections remain visible: add proper arm openings or revise the drape before admission. This revision supersedes the initial untrimmed review images, not their historical evidence in Git. The long-cut export is reloaded to check that its selected clothing and both surfaces survive bundling.

Current refinement: both cuts now have authored side vents with bordered edges, removing the obvious upper-arm intersections in the reviewed rest views without deleting skin. The cloth and border derive normals from the same fitted grid. An initial normal-direction error was caught in the render and corrected for Godot's clockwise winding; tests now check both seam continuity and normal agreement with triangles after GLB import. Both rendered body suites pass. These remain stiff construction samples with oversized angular trim and no fastening or secondary-motion solution; this is not combat-pose or final-art approval.

The original authored pattern is in `add_cloak` inside the existing compiler, fitted against the pinned CC0 source proxy. Preserve the compiled receipt and the `*-short-front`, `*-short-back`, `*-long-front`, `*-long-back` review images when refining it. No paid generation was used.

The [MakeHuman suits02 source pack](https://static.makehumancommunity.org/assets/assetpacks/suits02.html), checked 6 September 2026, lists RehmanPolanski's Viking tunic, pants and boots and Donitz's monk robe and hood variants as CC0. These are acquisition candidates, **not downloaded or admitted assets**. The pack also contains unrelated sci-fi/franchise designs; do not import it wholesale into either game's runtime or treat its CC0 label as approval of those character identities. Inspect individual mesh, fitting and material files before adding the historical subset to the existing compiler.

Acquisition attempt: the source page loaded in Chrome, but its mirror1 ZIP link returned `ERR_BLOCKED_BY_CLIENT`. No archive was acquired and no browser protection was bypassed. Local construction remains available; this download failure does not establish a blocker for the entire character-production goal.

Owner: Pirate Island work. DR Companion continues environment-asset production. The character editor and preset format are shared; neither game's lore or faction logic belongs here. No paid generation. The inspected CC0 MakeHuman source subset and fitted workshop derivatives are now included, separately from approved game art.

## Working first increment

### Facial construction expansion

Four additional controls use seven original CC0 MakeHuman target files: paired cheekbone definition, paired cheek fullness, paired eye size, and jaw width. Their Git blob IDs, SHA-256 values and exact lengths are in the existing core source manifest. Both assemblies now expose twelve linked morphology controls, and the stature envelope is rebuilt against all of them.

The tests check actual source-mesh displacement and render each new control in isolation alongside the unchanged base face. Full-strength cheekbone and cheek-volume targets produce overly strong facial forms in the inspected source heads; these are authoring extremes, not approved NPC appearances. Prepared profiles therefore provide `variationCaps` for automatic generation. The wardrobe validates those caps, and seeded appearance generation observes them and avoids simultaneously choosing narrow-chin and broad-jaw controls. Existing profiles without caps retain their prior default.

This is expanded construction capability, not approved character identity. Hair cards, eyebrows/lashes, skin presentation, faction styling and nonhuman topology remain unfinished. Do not interpret twelve controls as twelve completed races or characters.

### Rest-body stature

Prepared profiles now include a `measurement` envelope derived from the **unclothed fitted body proxy**, not the assembly bounds. It stores vertical base coordinates and per-morph deltas for every vertex that could determine the minimum or maximum height across independent 0..1 controls. The compiler checks the reduced envelope against the full source for the base and each individual target. Current builds retain 47 female and 44 male measurement vertices, rather than every vertex of the source body.

The wardrobe owner evaluates this envelope whenever appearance changes. The editor updates body scale and grounding while preserving the requested rest-body height. Hats, shoes, hair and cloaks do not redefine stature. The same scale and origin go into exported actors and generated batches. The UI labels this as **Rest body height (metres)**; it is not the height of a crouching animation or the top of headwear. Unprofiled models still use the explicitly labelled source-unit/assembly assumption.

Profiles with missing measurement data remain compatible. Malformed controls, non-finite samples and envelopes that cannot guarantee positive height are rejected before mutation. This does not establish race-specific limb proportions, face identity or approved anatomy; those remain separate production work.

`tools/character-workshop.tscn` is an embeddable Godot Control with its own 3D viewport. Launch it in the existing tools project:

```text
godot --path tools res://character-workshop.tscn -- <absolute-source.glb>
```

Or omit the final argument and use Open source GLB. The editor exposes actual imported mesh visibility, supported blend shapes, measured overall height, turntable and existing animation clips. It retains source materials and skeletons. Height uses uniform scaling, not anatomical reshaping. A model without blend shapes has no shape sliders. A material-batched model does not magically become a modular clothing library.

When the prepared MakeHuman assets are present, **Female body** and **Male body** load the matching model and wardrobe together. Embedding applications can set `prepared_asset_directory`; the standalone tools project discovers the adjacent prepared assets by default. Custom GLB/profile loading remains available.

## Export a configured character

Choose clothes, body shape, colors and height, then **Export Godot character** to a `.scn` file. This is a self-contained binary Godot `PackedScene`: geometry, textures, wardrobe visibility, blend-shape values, skins and skeleton are bundled. Drop the scene into a Godot world or instantiate it with `load(path).instantiate()`. No workshop script, external GLB or wardrobe JSON is required to load it.

The export has one `Character` root at the selected scale, retains the normalized ground placement, and excludes the editor UI, lights, camera and turntable rotation. Original node transforms and skeleton rest poses are restored in the copy; animation autoplay is cleared. Appearance metadata records the source hash, wardrobe hash and saved choices. The exported root is marked `workshop-export-requires-consumer-approval`; export is not art admission or a gameplay identity assignment.

`build_character()` returns the same packed actor for an embedding host; successful file exports emit `character_built(character, appearance)`. Materials are copied so later editor dyes cannot alter an already built actor. Instances of a packed scene use Godot's normal shared-resource behavior: consumers that recolor individual instances must duplicate that instance's material. Exports now remove hidden mesh, skin and material resources while retaining transform nodes and attachments. The original editor assembly and full source/appearance recipe remain intact. Outfit changes must be rebuilt from that source; an export is a selected appearance, not a wardrobe library. Selected meshes still retain their editable blend shapes and full rig, so this is not a crowd/LOD solution. A complete menu, game save binding and actor controller are still consumer integration work.

The exported `export_geometry` metadata records source/retained mesh counts and surface vertex counts (including seam duplicates, not unique spatial points). In the 2026-09-06 Casual 02 export fixtures, the female assembly reduced from 22 meshes / 79,350 vertices to 8 / 23,731; male reduced from 22 / 84,455 to 8 / 20,388. Other selections have different budgets. This is resource-retention evidence, not frame-rate, GPU-memory or draw-call certification. Skinned animation retargeting remains unapproved, and animation tracks must not expect removed outfit geometry to reappear.

The regression suite exports a dressed, recolored, lean character at 1.53 metres, reloads its scene and checks zero external resource dependencies. A separate process can exercise only the exported artifact:

```text
godot --path tools --script res://test-character-workshop.gd -- <absolute-character.scn> <absolute-render-output-stem>
```

Test-generated `*-review.scn` files are rebuildable local fixtures and are not committed as duplicate source assemblies. Their reviewed standalone screenshots are retained as evidence, not approved art.

Export checkpoint, 2026-09-06: female and male workshop runs each passed 46 checks with rendering; each fresh-process exported-scene review passed 10 checks, and the synthetic wardrobe suite passed 15. Both standalone renders were inspected. The temporary local-to-scene material duplication path produced engine errors during teardown and was removed; ordinary isolated export materials passed the rerun. Existing environment log/certificate/tablet/shader-cache warnings remain distinct from these checks. The main game checkout was inspected but not modified in this checkpoint; no in-game menu or gameplay-controller integration is claimed.

Appearance JSON stores schema version, name, source filename/hash, height, exact mesh paths and supported shape weights. Loading requires the matching model already open, validates all fields before changing live state, and never writes to the source asset. Absolute machine paths are not saved in presets. Animation and turntable are preview controls, not persistent identity. Save dialogue uses normal overwrite confirmation.

## Asset boundary

Approved illustrations in the shared character-support pack are identity references, not rigged body meshes. The earlier rejected procedural Cthulhu import fixture is superseded for humanoid testing by the real MakeHuman assemblies below. It remains rejected art.

The editor is not yet integrated into either game's menus. Clothing slots, named body-region hiding, linked morphs and material dyes now work for a prepared source GLB. Separate garment import/rig remapping, constrained population generation, production humanoid bases and creature families remain to implement. No arbitrary external clothing is attached until its skeleton, bind pose and body compatibility are established.

## Prepared body and wardrobe

The expanded source wardrobe has three complete outfits per body. **Formal separates** uses the source blouse/skirt or jacket/trousers as two disconnected mesh components, each with its own dye channel. The compiler verifies that those components partition the source mesh without dropping or duplicating vertices. They remain a paired outfit choice with one correctly masked body; arbitrary top/bottom mixing is not yet admitted. The **Headwear** slot equips a fitted felt hat and hides the incompatible hair mesh; removing it restores hair. This all-hair exclusion avoids intersections but is not final under-hat hairstyling.

These are additional CC0 construction/test garments, not final colonial, pirate, fox, elf or steampunk outfits. The source textures retain modern tailoring details. Do not label this source inventory as finished faction costumes. The staged system subset now contains 105 files. Re-extraction permits additions only when every previous source record is retained with identical bytes and hashes.

## NPC batch production

With a prepared body loaded, enter a seed, choose a count from 1 to 64, and use **Export NPC batch**. The output is one self-contained `CharacterBatch` scene, containing independently configured actors named `NPC_000`, `NPC_001`, etc. Each actor retains a stable `variation_id` formed from the seed and index, complete appearance metadata and its rig. These are authoring identifiers, not authored character names or simulation-person IDs. Batch appearance names are deliberately blank, so a named hero in the editor is never cloned into the NPC roster. Geometry and textures are shared where possible rather than exporting separate copies of the source library for every NPC.

The batch reuses `create_variation()` and `build_character()`; it has no second fitting, randomization or export implementation. It restores the edited appearance and camera after building. Counts outside 1–64 are rejected. Each batch uses the currently loaded body, explicit species trait, height and retained settings. Generate male and female batches separately. Named heroes should use reference-authored appearances rather than this randomization.

Batch actors are stored at the origin for consumer spawning. The test's six-person grid is a review arrangement only, not an island placement system. The consumer must associate actors with persistent people, choose legal positions and admit final art. There are no faction workers or encounters spawned by this authoring feature alone. Load a `*-batch.scn` with the existing standalone export test to review it in a fresh process. Test-generated binary batch files are ignored and reproducible; reviewed PNGs are retained.

Wardrobe/batch checkpoint, 2026-09-06: female and male rendered workshop suites each passed 85 checks. Each six-actor batch passed 69 fresh-process load/material/render checks. Formal outfits, headwear and both batch grids were visually inspected. These remain unapproved source-body tests; modern garments and rough hair/hat presentation need art work. The larger crowd budget, costume construction and game integration remain unfinished.

Open the source GLB, then **Open clothing/body profile**. The profile is an asset-authored JSON document, not a player preset. Body, garments and equipment must already be exported together on the compatible rig. The offline MakeHuman compiler transfers source weights through the original fitting tables; the runtime editor does not guess weights for arbitrary garments. Runtime body-region hiding operates on separate named mesh parts. The compiler additionally bakes garment-specific polygon masks into the two alternate body meshes. The profile supplies human-readable clothing choices, morph labels and dye channels. These replace raw mesh/shape controls while the profile is active.

Profile schema:

```json
{
  "schemaVersion": 1,
  "sourceSha256": "<exact GLB SHA-256>",
  "slots": {
    "Coat": {
      "Canvas coat": {"meshes": ["Skeleton3D/Coat"], "hides": ["Skeleton3D/Torso"]},
      "None": {"meshes": [], "hides": []}
    }
  },
  "morphs": {
    "Build": ["Skeleton3D/Torso::build", "Skeleton3D/Coat::build"]
  },
  "dyes": {
    "Coat fabric": [{"mesh": "Skeleton3D/Coat", "surface": 0}]
  }
}
```

Paths above illustrate the contract, not shipped asset names. Every referenced mesh, shape and material surface must exist. Each slot initially selects its first choice. One clothing mesh cannot belong to multiple slots; hiding a region is the union of all equipped items' masks. Removing one item therefore cannot expose a region still covered by another. Reopen the source to replace a profile.

Each morph lists the actual corresponding body and garment blend shapes. All listed weights update together, including unequipped garments, so switching outfits retains the current build. Missing bindings reject the profile. This guarantees coordinated weights, **not** collision-free artistic deformation: every admitted garment still needs minimum/maximum body-shape and pose review.

Dyes multiply a copied standard material's original albedo color and retain its textures. White means unchanged; source material resources are never edited. Profile selection, linked morph weights and dyes are stored in the existing appearance recipe with a profile hash. Both source and profile must match on load. Validation finishes before live appearance changes. JSON saves use full numeric precision.

## Free source acquisition and completion gate

### Selectable fitted hair — 2026-09-06 checkpoint

The **Hairstyle** slot adds Braid, Long loose, Bob and Afro source meshes to both bodies, alongside their original Source default hair and a Bald option. These are four newly staged CC0 source styles, not newly approved character identities. The system subset now contains 145 original files. Every hair mesh shares the twelve fitting controls, transferred skin weights and Hair dye channel. The source files remain unchanged.

Equipment choices may now declare optional `excludes` mesh lists. Unlike `hides` (body-region masks), exclusions explicitly target equipment owned by another slot. The felt-hat choice excludes all five hair meshes without changing the remembered hairstyle. Removing it restores only the selected style, including a genuinely bald selection. Unknown targets, same-slot targets and malformed lists reject atomically. Appearance recipes canonicalize numeric morph weights to floating-point values, so an integer-authored zero does not cause a false save/load mismatch.

Front/back source fitting reviews use `*-review-hair-<style>-<view>.png`. The bob heavily obscures the face, the Afro has noisy alpha/shadow edges, and the male braid shows a small scalp gap. These are recorded art defects, not acceptable finished variants. Braid/long hair also require head-turn, shoulder and clothing collision checks plus secondary-motion work; source skinning is not a complete hair animation system. All styles remain authoring candidates and must not be treated as approved runtime pools.

### Fitted brows and lashes — 2026-09-06 checkpoint

Period overgarment construction now also includes **Open-sided tabard** in the existing Outerwear slot. It uses the same constructor as the travelling cloaks, not a separate fitting/export pipeline. Its cut closes the front, connects the shoulders around a neck opening, and leaves both sides open to the hem. Cloth and edging have independent dye surfaces. Torso-depth samples provide chest/hip ease; twelve fitted shape targets and the shared skeleton remain attached. Source body polygons are not hidden by this overgarment.

This is an original construction prototype, not a finished faction costume. Initial review rejected flat shoulders, oversized edging and chest intersections; shoulder drop, finer border sampling and body-derived depth were revised. Front, side and back review captures are named `*-review-tabard-*.png`. The underlayers in these fixtures are still modern source clothes, not proposed period ensembles. The tabard is rigidly weighted to the torso: it needs fastening, fabric treatment, movement/leg clearance, body-extreme testing and faction-specific detailing before runtime art admission. Its presence does not complete a historical wardrobe.

The revised female front no longer shows the observed chest poke-through. The male formal jacket still intersects the tabard's back shoulder edges: that combination fails visual admission. Both rendered workshop suites pass the mechanical selection, linked-shape, seam-normal, triangle-winding and selected-garment export checks; those tests do not certify layer collision or animation quality.

Both prepared body profiles now expose **Eyebrows** (Brow 01, Brow 05, none) and **Eyelashes** (Lashes 01, Lashes 04, none), with separate dye channels. The four source parts use their original fitting tables, transferred skin weights and all twelve linked morphology controls. The ZIP subset now contains 125 original files; the separate core manifest contains 25. This supersedes the smaller extraction counts in the historical checkpoints below.

Profiles can provide `variationChoices` to restrict automatic appearance generation to an explicit nonempty subset of each slot's choices. Manual choices remain available: ordinary seeded humanoids get brows and lashes, but an artist can remove either. Invalid, duplicate or unknown choices reject atomically.

The converter preserves source `castShadows False` through profile `shadowlessMeshes`, because GLB alone does not reliably retain that engine setting. Transparent source hair cards use alpha blending with a depth prepass rather than a hard alpha cutout. Close-up review showed that hard cutouts broke fine strands into dotted edges; blending improved them. Hair-card edge cleanup and lash density still need art work. These parts and the modern source outfits remain construction fixtures, not approved faction costumes or character likenesses.

Verification: both twelve-control body builds completed; both rendered workshop suites and both fresh standalone scene loads reported zero failures. Thirty synthetic wardrobe checks passed, including invalid generation choices and malformed shadow overrides. All 125 system and 25 core source hashes, compiled output hashes and compiler receipt hash matched. Review images `*-review-brows-lashes-01.png` and `*-review-brows-lashes-04.png` show the actual assemblies. Environmental log and certificate access warnings remain. No paid generation was used.

Researched 2026-09-06: MakeHuman explicitly permits reuse of its CC0 base mesh, targets and core system assets in another character generator: https://static.makehumancommunity.org/mpfb/faq/build_other_chargen.html . Its system pack includes clothing, hair, skins and body parts with per-item CC0 declarations: https://static.makehumancommunity.org/assets/assetpacks/makehuman_system_assets.html . Third-party packs may use different licenses. Runtime code licenses are separate from asset licenses; no MakeHuman/MPFB application code has been copied.

The user supplied the completed system ZIP on 2026-09-06. `prepare-character-assets.ps1` verifies its pinned SHA-256, extracts 87 selected original files, refuses changed-source overwrites, and writes a per-file hash manifest. Core base geometry, six adult targets, skeleton and weights were fetched through the GitHub connector by immutable blob ID. Their separate source manifest records those IDs, hashes and license evidence. The full ZIP is not duplicated in the repository. No browser security setting was bypassed.

### Rebuild and open the fitted prototypes

```powershell
./tools/prepare-character-assets.ps1 -Archive 'C:/Users/Admin/Downloads/makehuman_system_assets_cc0.zip'
godot --headless --path tools --script res://prepare-character-model.gd -- '<repo>/assets/character-sources/makehuman-system' '<repo>/assets/character-prototypes/makehuman'
godot --path tools res://character-workshop.tscn -- '<repo>/assets/character-prototypes/makehuman/female-source.glb' '<repo>/assets/character-prototypes/makehuman/female-profile.json'
```

Replace `<repo>` with the absolute shared checkout path; use `male` for the other assembly. Both core and system source directories are included. The extraction step is only needed to independently reproduce or verify the staged ZIP subset. Open the corresponding profile with the model: the raw GLB contains alternate overlapping bodies and outfits and is not intended to be instantiated unconfigured.

`prepare-character-model.gd` fits each proxy/garment through its original barycentric table and scaling anchors, applies source body targets to every part, transfers the strongest four normalized skin influences, and preserves the source hierarchy with 163 bones. It exports two clothes choices per body, shoes, eyes, hair, linked Lean/Muscular controls and clothing/hair dyes. Shared indexing preserves correspondence across targets. Derivative textures are capped at 1024 pixels; original textures are untouched. Full target normals avoid the observed distortion caused by packing relative normal deltas.

**Limits:** these are CC0 workshop test assets, not approved hero art. Modern sample clothes are not the period wardrobe. Skeleton rest frames currently use global-axis orientations at source joint centers; source rotation-plane/bone-roll conventions are not reproduced, so external animation retargeting is not certified. The controls do not yet provide arbitrary limb proportions or complete creature construction. A one-arm pose test is not full animation QA. Bones do not move their rest centers with body targets. No arbitrary garment fitting, full costume construction, RTS LODs, faction population spawning or game-menu integration is claimed. The expanded GLBs are approximately 18 MB each, not final crowd budgets.

### Face construction and repeatable NPC variations

The same compiler now includes six linked controls in addition to Lean and Muscular: Oval face, Square face, Narrow chin, Broad nose, Full lips, and Pointed ears. Eight original CC0 target files supply these controls; upper/lower lips and left/right ears are paired in one control each. Source paths, immutable Git blob IDs and file hashes are recorded in the existing core manifest. Every target refits body, eyes, hair and wardrobe through the original fitting tables; no primitive anatomy substitutes are added. Face view and Full body buttons support close-up review.

Enter a seed and choose **Create variation** to generate repeatable body/face weights, wardrobe selection and hair tint. The algorithm hashes the seed plus each field key independently with SHA-256, sorts wardrobe choices, limits generated morph weights to below 0.65 and quantizes them to 1/1024 steps for exact save/load stability. It avoids combining Oval and Square face weights. Identity/name, height, clothing tint and the explicitly selected pointed-ear amount are retained, not rerolled. `variationSeed` records the originating seed; the full saved appearance remains authoritative after manual edits. Reproduction requires the same source/profile and retained explicit settings. This is appearance variation, not faction membership, NPC naming, romance content or population simulation.

These controls are source-backed construction tools, not approved finished likenesses. Named heroes still require reference-led fitting, faction wardrobes remain unfinished, and unrestricted combinations still need wider visual review. Rebuilding the GLBs changes their source hashes intentionally: older appearance files reject rather than silently applying to a different source.

Face/variation checkpoint, 2026-09-06: both rendered workshop suites passed 62 checks, both standalone export suites passed 10, and the wardrobe suite passed 15. All new source hashes verified. Two seeded face variants and pointed-ear renders were reviewed for each body. Arbitrary double-precision generated weights initially failed exact JSON roundtrip; quantized dyadic weights fixed the failure without relaxing the test. Head controls preserve adult source geometry but are not an approved facial style or named-character likeness. Male hair-card edges remain visibly rough in close-up and require art cleanup.

The acquisition, fitted dressed bodies and authored profiles are complete as a development checkpoint. Completion of the requested builder still requires expanded construction controls, appropriate wardrobe, monster families, broad fit/pose coverage and in-game integration. Do not describe this checkpoint as a finished character builder or approved character art.

## Verification

```text
godot --path tools --script res://test-character-workshop.gd -- <absolute-test.glb> <absolute-review-output-stem>
```

The test imports a real model, applies visibility/height changes, rejects mismatched source hashes and malformed data atomically, saves/reloads JSON, verifies failed imports preserve the model and captures the editor. A failure produces nonzero exit status. Add the absolute corresponding `female-profile.json` or `male-profile.json` as a third argument for the real fitted-asset checks: actual body/garment targets, 163 skin binds, linked target weights, masked-body outfit switching, and fitted-recipe roundtrip. Rendered runs also bend the left upper arm and assert that baked garment vertices move, then capture the lean posed result. Refreshing controls keeps the screenshot labels consistent with the model.

Run `godot --headless --path tools --script res://test-character-outfit.gd` for synthetic mechanical tests of clothing selection, overlapping region masks, linked shape weights, source-material isolation, dyes, atomic rejection and JSON roundtrip. Source quality remains a separate gate. On 2026-09-06 the female and male rendered suites each passed 29 checks; the two lean arm-pose renders were inspected. The initial raw assembly and incorrect extreme-shape shading were rejected and corrected. Godot also emitted environment errors for inaccessible user logs, tablet settings, certificate store and shader cache; these are not clean-environment release-test results.
