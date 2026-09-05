# Asset Intake Procedure

## Purpose

This procedure turns a useful-looking download into a traceable shared source, or leaves it outside the library. It applies to models, textures, HDRIs, VFX plates, rig templates, and reusable props.

## Intake sequence

1. **Classify the candidate.** Choose one domain: terrain, flora, geology, water, architecture, neutral prop, weapon, armour, material, rig infrastructure, or VFX reference. Do not use a lore-specific classification in this repository.
2. **Capture source evidence.** Record the source page, publisher, creator where known, license page, archive name, and retrieval date before conversion or extraction.
3. **Verify rights.** Confirm that the exact file is CC0 1.0. Record commercial-use and redistribution evidence. Quarantine any ambiguity.
4. **Archive unchanged source.** Preserve the original archive or source file, then calculate SHA-256. Never overwrite raw source with an engine-converted file.
5. **Review semantics.** Confirm what the asset literally depicts. A “generic shrine” cannot be admitted as “East-Asian shrine” merely because it seems close; use neutral tags or leave it project-specific.
6. **Review technical fit.** Check scale, forward axis, origin/pivot, collision intent, material slots, texture size, animation/rig state, and expected Godot import path.
7. **Write the catalog entry.** Validate it against `catalog/asset-manifest.schema.json`.
8. **Approve or quarantine.** Only an `approved` CC0 entry may be put under `assets/approved_cc0/`. Every other result remains in a non-runtime lane.
9. **Make consuming-project entries.** A game copies or derives the approved source into its own manifest and records its visual review. This shared repository never declares an asset shipped.

## Required review questions

- Is this exact source legally redistributable in the shared repository?
- Does it communicate the intended physical object without project lore?
- Does it preserve a useful silhouette at tabletop camera distance?
- Does it have a stable origin and scale?
- Can it be reused in at least two neutral contexts?
- If it is a rig component, does it obey the shared socket and animation contract?
- Is its visual style broad enough to be recolored, repainted, or used as a scene anchor without dictating a game’s final look?

## Quarantine is a successful outcome

Quarantine prevents a plausible asset from becoming invisible technical, licensing, or art debt. A quarantined asset can still be used as a visual reference, never as an approved shared runtime source.

## No bulk approval

Collection pages and marketplace searches are leads, not approval. Review each downloaded archive and admitted source path independently.

## Contributing generated character references

Use the same resource-pack catalog, not an independent approval ledger. The consuming project's character manifest owns identity and user selections; a shared reference pack is a reproducible export with a source-manifest hash. Its availability in the library is not runtime approval.

For the current artwork, run `node tools/import-character-references.mjs /absolute/path/to/character-art-manifest.json`, then `./tools/build-resource-pack-ledger.ps1` and `./tools/validate-resource-packs.ps1`. Run the importer again with `--check` to verify the exported bytes, prompts and metadata without writes. The importer refuses changed or missing retained variants. It currently accepts the recorded style-only generation workflow; a new combination workflow must explicitly represent every parent before import support is extended.

Search the library for suitable models, props, materials and references first. Keep a game's adaptations linked to exact shared asset IDs and hashes. Contribute useful new art and modified or combined outputs back with their transformations recorded, preserving the inputs. Keep game lore, character statistics and party selection in the game project.

The owner's clarified publication instruction on 5 September 2026 is: test, integrate into the existing repository, push and verify the remote result. Do not leave completed contributions on unpublished local branches or create forks. A further publication approval is not required for this work. Asset review status remains truthful: publishing a reference does not make it an approved game asset. Verify both Git commits and LFS objects; a pushed pointer without its image is not a successful art contribution. If transport or authentication prevents publication, record that exact blocker rather than inventing a new approval gate.
