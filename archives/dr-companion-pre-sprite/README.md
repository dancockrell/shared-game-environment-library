# DR Companion pre-sprite preservation

Preserved 2026-09-07 at the user's request. New game production uses detailed illustrated pixel-art sprites; earlier 3D-first, resin-diorama and incompatible scene styles are historical, not new production targets.

## Preserved artwork

The local snapshot contains **5,105 files / 258,976,716 bytes**, copied from DR Companion's complete `public`, `data/art` and `docs` trees. This deliberately retains supporting manifests, descriptions and documentation as well as artwork; not every file is an obsolete image. Every copied file was SHA-256 checked. See `snapshot.json` for exact paths, sizes and hashes.

No original was deleted. Existing runtime references remain intact until sprite replacements are admitted. Archiving does not grant new rights or change upstream asset licenses.

The receipt and these notes are tracked; the bulk snapshot payload is local-only and ignored by Git. This is **not an off-machine backup**. Preserve this directory when moving machines. Shared library assets and 3D studies already here remain at their canonical locations rather than being duplicated.

## Deferred 3D model builder

The builder already lives in this shared repository:

- `procedural/`: Rust generator, fixtures, Godot and Unity adapters.
- `procedural/blender/`: Blender study tooling.
- `tools/character-workshop.gd`, `tools/iterate-character-build.ps1` and `tools/benchmark-character-physics.ps1`: workshop and guarded iteration tools.
- `tools/retarget-dependencies/`: pinned prerequisite configuration.
- `docs/PROCEDURAL_SCENE_BUILDER.md` and `docs/CHARACTER_WORKSHOP.md`: architecture, limitations and prior evidence.
- Local ignored `procedural/generated/`: generated studies, including teapot, food and character experiments. These are not necessarily in Git.
- `artifacts/character-iterations/`: iteration receipts where present.

Status: **deferred research, not completed or production-approved**. The user suggested revisiting in roughly six months; no timer or automatic restart is authorized. Preserve current code/history, recipes, rejected studies and receipts. Do not resume expensive solver, render or engine loops as part of sprite production.

Restart by inspecting current repository state and recorded limitations, checking dependencies and resource limits, then running one bounded prototype and visually reviewing it. The last prerequisite success does not establish solver execution, photorealism, Unity validation, or completed character export.
