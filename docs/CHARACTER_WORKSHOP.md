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

The editor is not yet integrated into either game's menus. Modular attachment/rig compatibility, body-region masking, material variants, constrained population generation, production humanoid bases and creature families remain to implement. No arbitrary external clothing is attached until its skeleton, bind pose and body compatibility are established.

## Verification

```text
godot --path tools --script res://test-character-workshop.gd -- <absolute-test.glb> <absolute-review-output-stem>
```

The test imports a real model, applies visibility/height changes, rejects mismatched source hashes and malformed data atomically, saves/reloads JSON, verifies failed imports preserve the model and captures the editor. A failure produces nonzero exit status. The current integration fixture has no blend shapes; blend-shape deformation still needs a suitable independently licensed test asset. Animation controls are exposed but deformation quality is not certified by preset tests.

Next priority: select reusable licensed humanoid and creature foundations with DR Companion, then add compatible equipment assemblies and material controls to this same editor. Source quality is a separate gate; no procedural anatomy fallback is implied.
