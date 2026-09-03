# Character Resource Pack Contract

This contract applies to reusable character bases, paper dolls, rigged models,
clothing modules, expression sets, portrait inputs, and animation test packs.
It makes authored character work findable without treating every body style as
the same asset or hiding a game-specific presentation behind neutral labels.

## Required pack identity

Every character pack declares:

- `packId`, author, rights holder, creation method, source-control revision,
  and redistribution terms;
- `contentScope`: `shared`, `project_specific`, or `reference_only`;
- `projectAffinity`: zero or more consuming-game identifiers;
- `subjectScope`: `character` or `named_character`;
- `adultPresentation`: `adult_only` for adult character presentation;
- literal role: base body, rig, clothing, hair, face, expression, portrait,
  animation, or prop interaction; and
- technical review and consumer-engine review state.

## Adult character body-style facets

For adult character packs, use descriptive facets rather than value judgments.
The pack may use any applicable tags, including `slender`, `small_bust`,
`variable_hips`, `lifted_glutes`, `cute_face`, `athletic`, `muscular`,
`plus_size`, `tall`, `short`, or another precise studio-approved descriptor.
Do not infer age from body shape, facial style, height, or clothing. The
`ageClass` must explicitly be `adult` whenever `adultPresentation` is
`adult_only`.

Different body and face styles are desirable library coverage, not competing
defaults. Each pack is one clearly described option that a consuming project
can adopt, recolor, dress, or ignore.

## Rig and modularity

State the rig profile, coordinate convention, rest pose, root motion policy,
material slots, mesh sections, and all modular attachment slots. For a doll
base, list each replaceable section separately—head, hair, torso, arms, hands,
legs, feet, tops, bottoms, jackets, belts, footwear, jewelry, weapons, and
expression layers—as applicable. A pack must identify which modules are
compatible; compatibility is never assumed from visual similarity.

## Consumer adoption

The shared repository preserves the source pack and its evidence. Each game
records a separate adoption entry covering visual fit, camera scale,
performance, content rating, animation retargeting, and final presentation.
Project affinity tells teams where the pack originated; it does not grant a
game permission to use it without that adoption record.
