# Shared character workshop

Owner: Pirate Island work. DR Companion continues environment-asset production. The character editor and preset format are shared; neither game's lore or faction logic belongs here. No paid generation. The inspected CC0 MakeHuman source subset and fitted workshop derivatives are now included, separately from approved game art.

## Working first increment

`tools/character-workshop.tscn` is an embeddable Godot Control with its own 3D viewport. Launch it in the existing tools project:

```text
godot --path tools res://character-workshop.tscn -- <absolute-source.glb>
```

Or omit the final argument and use Open source GLB. The editor exposes actual imported mesh visibility, supported blend shapes, measured overall height, turntable and existing animation clips. It retains source materials and skeletons. Height uses uniform scaling, not anatomical reshaping. A model without blend shapes has no shape sliders. A material-batched model does not magically become a modular clothing library.

When the prepared MakeHuman assets are present, **Female body** and **Male body** load the matching model and wardrobe together. Embedding applications can set `prepared_asset_directory`; the standalone tools project discovers the adjacent prepared assets by default. Custom GLB/profile loading remains available.

## Export a configured character

Choose clothes, body shape, colors and height, then **Export Godot character** to a `.scn` file. This is a self-contained binary Godot `PackedScene`: geometry, textures, wardrobe visibility, blend-shape values, skins and skeleton are bundled. Drop the scene into a Godot world or instantiate it with `load(path).instantiate()`. No workshop script, external GLB or wardrobe JSON is required to load it.

The export has one `Character` root at the selected scale, retains the normalized ground placement, and excludes the editor UI, lights, camera and turntable rotation. Original node transforms and skeleton rest poses are restored in the copy; animation autoplay is cleared. Appearance metadata records the source hash, wardrobe hash and saved choices. The exported root is marked `workshop-export-requires-consumer-approval`; export is not art admission or a gameplay identity assignment.

`build_character()` returns the same packed actor for an embedding host; successful file exports emit `character_built(character, appearance)`. Materials are copied so later editor dyes cannot alter an already built actor. Instances of a packed scene use Godot's normal shared-resource behavior: consumers that recolor individual instances must duplicate that instance's material. The exporter retains hidden wardrobe alternatives and editable blend shapes, so this is not yet a compact crowd/LOD export. A complete menu, game save binding and actor controller are still consumer integration work.

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

**Limits:** these are CC0 workshop test assets, not approved hero art. Modern sample clothes are not the period wardrobe. Skeleton rest frames currently use global-axis orientations at source joint centers; source rotation-plane/bone-roll conventions are not reproduced, so external animation retargeting is not certified. The two build targets do not provide face sculpting, arbitrary limb proportions or monster construction. A one-arm pose test is not full animation QA. Bones do not move their rest centers with body targets. No arbitrary garment fitting, full costume construction, RTS LODs, population generator or game-menu integration is claimed. The GLBs are approximately 11 MB each, not final crowd budgets.

The acquisition, fitted dressed bodies and authored profiles are complete as a development checkpoint. Completion of the requested builder still requires expanded construction controls, appropriate wardrobe, monster families, broad fit/pose coverage and in-game integration. Do not describe this checkpoint as a finished character builder or approved character art.

## Verification

```text
godot --path tools --script res://test-character-workshop.gd -- <absolute-test.glb> <absolute-review-output-stem>
```

The test imports a real model, applies visibility/height changes, rejects mismatched source hashes and malformed data atomically, saves/reloads JSON, verifies failed imports preserve the model and captures the editor. A failure produces nonzero exit status. Add the absolute corresponding `female-profile.json` or `male-profile.json` as a third argument for the real fitted-asset checks: actual body/garment targets, 163 skin binds, linked target weights, masked-body outfit switching, and fitted-recipe roundtrip. Rendered runs also bend the left upper arm and assert that baked garment vertices move, then capture the lean posed result. Refreshing controls keeps the screenshot labels consistent with the model.

Run `godot --headless --path tools --script res://test-character-outfit.gd` for synthetic mechanical tests of clothing selection, overlapping region masks, linked shape weights, source-material isolation, dyes, atomic rejection and JSON roundtrip. Source quality remains a separate gate. On 2026-09-06 the female and male rendered suites each passed 29 checks; the two lean arm-pose renders were inspected. The initial raw assembly and incorrect extreme-shape shading were rejected and corrected. Godot also emitted environment errors for inaccessible user logs, tablet settings, certificate store and shader cache; these are not clean-environment release-test results.
