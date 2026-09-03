# Shared Game Environment Library

A public, provenance-first source library for reusable game environment, prop, material, and tabletop-miniature infrastructure.

This repository contains:

- technical contracts for scale, pivots, collision, materials, LODs, thumbnails, selection hooks, and animation states;
- a strict CC0-only approved-source lane;
- explicit quarantine lanes for candidates, generated references, and paid-source records;
- machine-readable asset metadata and a documented intake procedure;
- licensed upstream source archives and material-map seeds, each with checksums and provenance reports;
- small, literal-use source-origin packs for roads, maritime props, fortifications, and modular sci-fi interiors;
- derivative resource packs only when their source members and deterministic build output are recorded.

It deliberately does not contain project lore, character identities, proprietary art, paid-store source files, or unreviewed generated files.

## Use the right layer

`assets/approved_cc0/` preserves original vetted inputs. It is not a runtime folder.

`resource_packs/` holds small packs selected by literal use. A pack can be source-origin or derivative, yet still be waiting for a consuming engine to review scale, pivots, materials, collision, LODs, and visual fit.

The catalogs provide the blind-machine-readable view:

- [library taxonomy](catalog/library-taxonomy.json) defines stable cross-project vocabulary;
- [approved source ledger](catalog/approved-source-ledger.json) records archive-level CC0 sources;
- [approved material ledger](catalog/approved-material-ledger.json) records PBR map source sets and expected color spaces;
- [resource-pack ledger](catalog/resource-pack-ledger.json) indexes the literal-use packs and their individual output hashes.

See [the intake procedure](docs/ASSET_INTAKE.md), [the license policy](docs/ASSET_LICENSE_POLICY.md), [the tabletop asset contract](contracts/TABLETOP_ASSET_CONTRACT.md), and [the starter source catalog](catalog/source-catalog.json).
