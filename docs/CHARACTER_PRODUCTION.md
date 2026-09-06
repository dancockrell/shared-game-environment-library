# Shared character production coverage

This extends the [character workshop](CHARACTER_WORKSHOP.md). It is the requirements inventory and consumer-admission layer, not a second character renderer or gameplay simulation.

## Current coverage authority

`catalog/characters/dragonrealms-requirements.json` is generated from DR Companion's local Elanthipedia cache. It combines creature names from the creature catalogue and combat bestiary, preserving numbered page variants. Named NPCs and playable race records remain separate kinds. Every imported requirement starts **unassessed**, with no approved asset assigned. A matching noun, generic humanoid body or source garment is not coverage.

The inventory contains source filenames, SHA-256 fingerprints and record counts. It intentionally does not reproduce cached lore prose or local filesystem paths. It describes this cache snapshot, not every creature ever created in the live game. Refresh the existing DR Companion cache through its own maintained scraper, then regenerate here; do not create a second scraper.

Run from the shared repository:

```powershell
node tools/character-production.mjs ../dr-companion/data/elanthipedia catalog/characters/dragonrealms-requirements.json
node tools/test-character-production.mjs
```

Race, guild and male/female humanoid presentation are independent axes. Commoner is the unguilded case. The guild list is grounded in https://elanthipedia.play.net/Category:Guilds. Creature anatomy and sex must be assessed from its actual source; unknown, sexless, skeletal and nonhuman bodies must not silently become male or female humans. Historical case differences in source body labels are preserved as evidence, not taken as separate modeled families.

## Admission rules

`tools/character-production.mjs` owns the consumer rules. DragonRealms admits ancient through early-modern styling, with firearms forbidden regardless of date. Pirate Island additionally admits its industrial-1870s and fantasy-steampunk direction. Neither automatically admits modern clothing.

```powershell
node tools/character-production.mjs --admit path/to/asset-record.json dragonrealms
```

The command returns JSON and exits nonzero for ineligible metadata. Records require `status: approved`, explicit `consumers`, `era`, `tags`, `sourceSha256`, `license`, `fitReview` and `visualReview`. This validates declared metadata; it does not inspect images, authenticate an approval, resolve review paths or certify physical fit. Actual source/derivative hash and rendered fit checks remain mandatory in the workshop workflow. This gate is currently an offline production command, **not yet a runtime export interlock**.

The existing MakeHuman casual/formal suits and fedora are source-fitting prototypes. They do not become DragonRealms or Pirate Island wardrobe merely because they render correctly. New period cuts must be constructed, fitted, checked against body variations and visibly reviewed before admission.

## Production order

1. Historical shared garments: fitted base layers, tunics, shirts, breeches, hose, skirts, robes, belts, boots, cloaks and appropriate headwear. Separate torso/leg/outer layers; derive explicit body masks and exclusion rules, not arbitrary overlapping outfits.
2. Distinct humanoid anatomy: actual head/face, stature, limb proportions and species features for the sourced races. Pointed human ears alone do not complete an elf or other race.
3. Creature families from assessed records: quadrupeds, avians, reptiles, arthropods, serpentine bodies, constructs and noncorporeal forms, with separate topology/rig requirements. Do not substitute primitive blobs for finished monsters.
4. Consumer-specific cuts and equipment, then notable-character identity and low-cost population variation. Romance presentation applies only to adult characters; ordinary NPC inventory membership is not a romance classification.

The goal includes actual assets and game integration. This inventory is a measurable starting backlog, not completion of that goal. No paid generation is authorized by this workflow.
