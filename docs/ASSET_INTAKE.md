# Asset Intake Procedure

## Purpose

This procedure turns a useful-looking download into a traceable shared source, or leaves it outside the library. It applies to models, textures, HDRIs, VFX plates, rig templates, and reusable props.

## Intake sequence

1. **Classify the candidate.** Choose a literal domain first: terrain, flora, geology, water, architecture, prop, weapon, armour, material, rig infrastructure, character, or VFX reference. Add project affinity and subject scope as separate tags when applicable; do not replace literal classification with lore labels.
2. **Capture source evidence.** Record the source page, publisher, creator where known, license page, archive name, and retrieval date before conversion or extraction.
3. **Verify rights.** Confirm that the exact file is CC0 1.0. Record commercial-use and redistribution evidence. Quarantine any ambiguity.
4. **Archive unchanged source.** Preserve the original archive or source file, then calculate SHA-256. Never overwrite raw source with an engine-converted file.
5. **Review semantics.** Confirm what the asset literally depicts. A “generic shrine” cannot be admitted as “East-Asian shrine” merely because it seems close; use neutral tags or leave it project-specific.
6. **Review technical fit.** Check scale, forward axis, origin/pivot, collision intent, material slots, texture size, animation/rig state, and expected Godot import path.
7. **Write the catalog entry.** Validate it against `catalog/asset-manifest.schema.json`.
8. **Approve or quarantine.** Only an `approved` CC0 entry may be put under `assets/approved_cc0/`. Every other result remains in a non-runtime lane.
9. **Make consuming-project entries.** A game copies or derives the approved source into its own manifest and records its visual review. Library-authored or project-specific packs may remain here when their rights and affinity are recorded. This shared repository never declares an asset shipped.

## Required review questions

- Is this exact source legally redistributable in the shared repository?
- Does it communicate the intended physical object without project lore?
- Does it preserve a useful silhouette at tabletop camera distance?
- Does it have a stable origin and scale?
- Can it be reused in at least two neutral contexts?
- If it is a rig component, does it obey the shared socket and animation contract?
- Is its visual style broad enough to be recolored, repainted, or used as a scene anchor without dictating a game’s final look?
- If it is a game-specific or character asset, are its project affinity, author/rights, adult-only status where relevant, body/style profile, and adoption rules explicit?

## Quarantine is a successful outcome

Quarantine prevents a plausible asset from becoming invisible technical, licensing, or art debt. A quarantined asset can still be used as a visual reference, never as an approved shared runtime source.

## No bulk approval

Collection pages and marketplace searches are leads, not approval. Review each downloaded archive and admitted source path independently.
