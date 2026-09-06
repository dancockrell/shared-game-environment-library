# Shared character workshop

Owner: Pirate Island work. DR Companion continues environment-asset production. The character editor and preset format are shared; neither game's lore or faction logic belongs here. No paid generation and no character models redistributed in this increment.

## Working first increment

`tools/character-workshop.tscn` is an embeddable Godot Control with its own 3D viewport. Launch it in the existing tools project:

```text
godot --path tools res://character-workshop.tscn -- <absolute-source.glb>
```

Or omit the final argument and use Open source GLB. The editor exposes actual imported mesh visibility, supported blend shapes, measured overall height, turntable and existing animation clips. It retains source materials and skeletons. Height uses uniform scaling, not anatomical reshaping. A model without blend shapes has no shape sliders. A material-batched model does not magically become a modular clothing library.

Appearance JSON stores schema version, name, source filename/hash, height, exact mesh paths and supported shape weights. Loading requires the matching model already open, validates all fields before changing live state, and never writes to the source asset. Absolute machine paths are not saved in presets. Animation and turntable are preview controls, not persistent identity. Save dialogue uses normal overwrite confirmation.

## Asset boundary

Approved illustrations in the shared character-support pack are identity references, not rigged body meshes. The first test uses Pirate Island's rejected procedural Cthulhu GLB strictly to exercise import, rig preservation and preset handling. It is not a renewed art proposal or an admitted base body. The source GLB stays in its owning repository.

The editor is not yet integrated into either game's menus. Clothing slots, named body-region hiding, linked morphs and material dyes now work for a prepared source GLB. Separate garment import/rig remapping, constrained population generation, production humanoid bases and creature families remain to implement. No arbitrary external clothing is attached until its skeleton, bind pose and body compatibility are established.

## Prepared body and wardrobe

Open the source GLB, then **Open clothing/body profile**. The profile is an asset-authored JSON document, not a player preset. Body, garments and equipment must already be exported together on the compatible rig; this increment never guesses or transfers skin weights. Body-region hiding operates on separate named mesh parts, not individual polygons. The profile supplies human-readable clothing choices, morph labels and dye channels. These replace raw mesh/shape controls while the profile is active.

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

Asset download is currently blocked in this environment. Direct HTTPS failed; in-app download produced no verified local archive; Chrome displayed ERR_BLOCKED_BY_CLIENT for the official system pack. No browser security setting was bypassed. The archive is not admitted or included. Existing Downloads GLBs are single-mesh, unrigged Tripo exports, not a usable modular body foundation.

Completion requires obtaining the source assets, preparing a dressed humanoid with linked morphs and rig, authoring its profile, verifying visible clothing fit across body extremes and poses, and connecting the shared builder into the game. This remains unfinished. Do not describe synthetic fixture passes as finished body construction or approved character art.

## Verification

```text
godot --path tools --script res://test-character-workshop.gd -- <absolute-test.glb> <absolute-review-output-stem>
```

The test imports a real model, applies visibility/height changes, rejects mismatched source hashes and malformed data atomically, saves/reloads JSON, verifies failed imports preserve the model and captures the editor. A failure produces nonzero exit status. The current integration fixture has no blend shapes; blend-shape deformation still needs a suitable independently licensed test asset. Animation controls are exposed but deformation quality is not certified by preset tests.

Run `godot --headless --path tools --script res://test-character-outfit.gd` for synthetic mechanical tests of clothing selection, overlapping region masks, linked shape weights, source-material isolation, dyes, atomic rejection and JSON roundtrip. The real-GLB editor test also checks profile integration and whole-appearance atomic rejection. Neither test currently certifies humanoid garment fit. Source quality is a separate gate; no procedural anatomy fallback is implied.
