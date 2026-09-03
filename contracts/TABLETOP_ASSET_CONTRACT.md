# Tabletop Asset Contract

## Scope

This is the common technical language used by shared raw assets and by project-specific adapters. It is intentionally independent of DragonRealms and Project 42 lore.

## Coordinate and scale rules

- Godot convention: +Y up, -Z forward for authored mesh orientation.
- Static prop origin: floor contact point centered under its intended footprint.
- Character/miniature origin: floor contact between the feet; root motion never moves the mesh origin away from the controller.
- Units: 1 engine unit equals 1 meter. Scale must be declared, never inferred from viewport appearance.
- Thumbnail camera: three-quarter view, neutral light, fixed per asset family.
- Collider, navigation, selection ring, shadow proxy, and visual mesh are separate named layers.

## Shared environment grammar

Reusable asset families should favor composable pieces:

- ground planes, edges, curbs, stairs, bridges, doors, arches, walls, roof segments, piers;
- trees, hedges, flowers, roots, rocks, basalt, driftwood, reeds, water-edge dressing;
- benches, barrels, crates, tables, lanterns, market dressing, neutral shrine pieces, workshop and tavern dressing;
- neutral weapons, shields, tools, armour silhouettes, boats and ship fragments.

An asset that depends on a named town, race, faction, god, guild, or character belongs in a project adapter, not here.

## Material slots

Each model must use semantically named slots when applicable:

`base`, `trim_metal`, `wood`, `stone`, `cloth_primary`, `cloth_secondary`, `leather`, `foliage`, `water`, `emissive`, `skin`, `hair_or_fur`, `eye`.

Use only slots that physically apply. Names are an interface for palette normalization and tooling, not an instruction to create fake detail.

## Rig and attachment rules

The shared miniature system supports a bounded number of high-quality rig families rather than one rig per NPC:

- medium humanlike;
- short/stout humanlike;
- tall/broad humanlike;
- hulking humanoid;
- feline humanoid;
- reptilian humanoid;
- ordinary furry humanoid;
- alternate beast/digitigrade family;
- creature families by body plan, not humanoid reskins.

Compatible head assemblies use a declared neck-ring radius, socket transform, forward axis, eye line, and material zones. Hair, hats, helmets, hoods, masks, ears, horns, beards, crests, tails, weapons, shields, and tools attach through named sockets. A component may declare incompatibilities to prevent clipping and lore-breaking combinations in consuming games.

## Common event states

Every admitted compatible rig maps the subset it supports to:

`idle -> orient -> short_step -> ready -> attack -> hit | miss | block -> cast -> affected -> defeat`

The game’s authoritative logic selects events. The asset controller only renders confirmed state. Project-specific animations can extend the vocabulary without changing these meanings.

## Required metadata tags

Every asset manifest declares: `assetId`, `assetKind`, `domain`, `scaleMeters`, `forwardAxis`, `pivotPolicy`, `collisionPolicy`, `materialSlots`, `lodPolicy`, `thumbnailPolicy`, `selectionHook`, `statusHook`, `provenanceId`, `licenseStatus`, and `admissionStatus`.

## Visual standard

The shared library supplies readable, modifiable physical structure. It should support painted-resin, illustrated, or hand-painted scene direction without imposing photorealism. Literal correctness and a neutral fallback are preferred to a beautiful but wrong semantic asset.
