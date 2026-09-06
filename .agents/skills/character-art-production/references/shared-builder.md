# Existing shared builder: locate and verify before editing

These paths are relative to `dancockrell/shared-game-environment-library`. Locate its existing checkout rather than cloning an alternate implementation. Inspect current claims and Git status; DR Companion scenery work can share this repository. Do not assume historical test counts or asset counts are current.

## Implementation owners

- `tools/prepare-character-assets.ps1`: verified extraction of the user's MakeHuman system-assets archive. Preserve manifest-listed source bytes.
- `assets/character-sources/makehuman-system/`: original source body proxies, clothing, hair, textures and fitting tables, with source manifest.
- `assets/character-sources/makehuman-core/`: original core mesh, body/face targets, rig and weights, with source manifest. Source license evidence lives here; do not infer rights for unrelated community downloads.
- `tools/prepare-character-model.gd`: one offline compiler for fitted assembly, linked morphs and prepared GLB/profile/receipt output.
- `tools/character-outfit.gd`: one owner of wardrobe choices, explicit masks, exclusions, morphology bindings and material dyes.
- `tools/character-workshop.gd` and `.tscn`: existing editor, seeded appearance variation, recipe validation, standalone actor and batch export.
- `tools/test-character-workshop.gd`: actual import, recipe, deformation, export and rendered checks. It also reloads exported `.scn` files without loading the original GLB.
- `tools/test-character-outfit.gd`: focused profile and wardrobe tests.
- `tools/character-production.mjs`: cache-backed requirements inventory and consumer metadata admission. The admission command checks declarations, not image quality or review-path existence; do not call it a runtime interlock unless one has actually been implemented.
- `docs/CHARACTER_WORKSHOP.md` and `docs/CHARACTER_PRODUCTION.md`: current operating instructions and unresolved scope.

Use those entry points for changes. Do not copy their code or asset registry into this skill. Read compiler and test arguments before running; resolve an available Godot executable rather than relying on a dated absolute path.

## Fitting and rendering pitfalls already demonstrated

MakeHuman `.proxy`/`.mhclo` rows can fit to multiple core vertices with weights, scale anchors and offsets. Source units are converted together; individually centering meshes destroys the fit. Some material/OBJ filenames differ from the fitting-table basename.

Body masks are based on the actual garment's authored covered vertices. Disconnected mesh components can become separates only after validating the component partition. That alone does not prove every combination with other garments is safe.

The compiler uses matching vertex correspondence for every shape. Normalized blend shapes contain full target positions and full target normals. Tiny relative normal deltas were corrupted by normal packing; do not reintroduce that representation without testing the rendered result.

Source skeleton hierarchy and skin weights are present, but global-axis rest frames are not the original bone-roll convention. Correctly skinned geometry does not prove animation retargeting. Rest-pose export must not bake the editor's test pose or turntable.

Prepared GLBs contain hidden alternative bodies/outfits. Apply the matching profile; a raw viewer may show overlapping alternatives. Actor export is self-contained, but retained alternatives and morph targets do not constitute a crowd-optimized LOD. Inspect actual triangle, texture and retained-resource budgets.

Default sample casual/formal suits and hats are fitting fixtures, not approved period clothes or hero identities. Procedural cloak cuts are construction prototypes until fit, fastening, surface treatment and motion have been reviewed. Current whole-assembly height measurement must not be presented as naked-body anatomical height without verifying the implementation.

## Evidence and budgets

Run both relevant body builds, wardrobe tests, meaningful variant/pose renders and fresh standalone export loads after changing shared geometry. Inspect the images yourself. Record environmental log/cache permission warnings separately from assertion failures.

Keep generation costs explicit and default to no paid calls for this user's workflow. Network failure to publish is not evidence that a commit was pushed; local construction can continue when publication is unavailable.
