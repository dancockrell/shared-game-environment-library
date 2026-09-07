# Pirate Island — shelved art and 3D builder

User-directed preservation, 7 September 2026. Pirate Island now ships toward the approved elevated three-quarter **2D pixel-sprite** style. Older painted/3D styles and the character/creature/garment builder are shelved for possible future work, roughly six months out, **not automatically scheduled to restart**. Resume only on a new explicit decision.

## Preserved artwork

- `character-design-session/`: 89 files from the character-design session: original portraits, provisional variants, original manifests, prompts and six supporting design/review documents. Financial/donation-product documents are deliberately excluded.
- `early-game-art/`: 22 files from the earlier game art folder, preserving battle/roster/world references and available model-input provenance.
- `additional-model-art/`: two additional manifest revisions found in the model-art checkout. Other files in that checkout's art folder were hash-identical to already preserved sources and were not copied again.

Each folder contains `snapshot.json` with exact source-relative paths, bytes and SHA-256 hashes. All copied files were checked against the originals. The first two snapshots contain 208,838,772 source bytes; use receipts for exact per-file sizes. The snapshot command's summary printed a null byte total, so that summary is not size evidence. Source files remain in place to avoid breaking historical project references; **nothing was deleted**. This archive is not a runtime asset directory or a second editable asset source.

Preserve each original's authorship, license and approval record. This is mixed project-reference material, not a CC0 source pack. Old image approvals describe those historical variants, not automatic approval for the new sprite style. Do not randomly select these pictures into new runtime pools.

## The 3D builder is already here — do not duplicate it

The shared repository is the existing implementation owner. Code and its history remain at:

- `tools/character-workshop.gd`, `tools/character-outfit.gd`, `tools/prepare-character-model.gd`: assembly/editor, wardrobe and body compiler.
- `tools/build-period-pattern.py`, `tools/fit-period-pattern.py`, their tests and `tools/benchmark-character-physics.ps1`: period-pattern construction, experimental draping, review and bounded execution.
- `tools/addons/shared_character_builder/` and `integrations/unity/`: existing engine adapters, with verification limits below.
- `catalog/characters/`, `assets/character-sources/`, `assets/character-prototypes/`: identity/reference records, source meshes and constructed prototypes.
- `docs/CHARACTER_WORKSHOP.md`, `docs/CHARACTER_PRODUCTION.md`: methods, research, acceptance boundaries and detailed run history.
- `artifacts/character-iterations/`: local research papers, solver runs, receipts, rejected renders and diagnostics. Most of this is local research storage, not a remotely backed-up payload; do not erase it when cleaning caches.

Relevant retained history: `7d4acde` adds the IPC surface-crossing audit; `b452766` adds the bounded author-retargeter Windows preflight; `cb6f91f` records a later skeleton-weight/open-topology audit; `8935bc8` shelves Pirate Island's 3D consumer direction. Consult current history before resuming because another shared-product task may have added complementary work.

## Restart checklist, not current work

1. Read the workshop's current decision and research records. Recheck live sources and licenses; do not reinstall from an assumed stale environment.
2. Preserve the approved 2D game. A future 3D experiment is not permission to undo its shipped presentation.
3. Reproduce source/body/wardrobe tests under the existing low-resource watchdog before attempting new geometry.
4. Retain the key failure evidence: poor period cut/shape, garment/body intersections, cuff/seam failures and incomplete general retargeting. Numerical success was never final art approval.
5. Recheck the author retargeter prerequisite/build state; do not infer that downloaded code means a completed or integrated solver. Unity execution and production animation were not certified by the original work.
6. Use source hashes and actual multi-view renders/pose tests. No paid generation or high-memory run without renewed, scoped authority.

The user asked to finish games now. Current production priority is coherent 2D sprite kits, exact atlas metadata, one visually accepted playable island scene and the existing faction/companion simulation—not more 3D investigation.
