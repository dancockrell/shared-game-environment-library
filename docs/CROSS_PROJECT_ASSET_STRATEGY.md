# Cross-project asset production strategy

Owner direction, 2026-09-06: DR Companion and Pirate Island take priority. Olympus / Board Game Cabinet is a low-priority consumer with no new paid-generation or purchase budget. Reuse assets creatively and coherently; childish clay-like primitive assemblies do not meet the visual goal. Free generation is allowed when guided toward a named, useful asset.

## One library, project-owned identity

Use the existing resource-pack ledger and tabletop contract. Do not create another shared library or universal character implementation. Source meshes, bodies, rigs, sockets, animations, neutral materials and props can be shared. Named characters, lore, gameplay and final visual approval remain with each app. Existing illustrated adventurer references are references, not bodies or rigs.

Before work, search `catalog/resource-pack-ledger.json`, approved source/material ledgers and the consuming projects' source inventories. Distinguish a downloaded source from an admitted runtime asset. Preserve originals; record exact source hashes and transformations when exporting.

## Cost boundary and verified Magnific route

Owner clarification,2026-09-06: **Do not use paid work at all for ordinary production.** Limited paid capacity is reserved for emergencies in finishing work. Only a specific future owner authorization can permit that expense; agents must not self-declare an emergency or use a paid fallback. Reuse and visibly verified browser-unlimited generation remain the normal routes.

Checked 2026-09-06: Magnific account reports unlimited mode, but the MCP connector reports `unlimitedAppliesHere: false`. Connector generations consume credits. Do not infer free operation from the account tier or from a model being called cheap/fast.

The authenticated browser Image Generator explicitly displays **Unlimited generations** when **Google Nano Banana 2 Lite** is selected. That verifies a browser image-generation route; it does not establish free image-to-3D, rigging, upscaling, video or every model/setting. Recheck the submission panel immediately before each job. If it shows credits, unknown cost, or an upgrade, do not submit under the zero-budget policy.

Do not use Auto for cost-sensitive work. Do not use the paid MCP call as a fallback for a browser failure. No jobs were submitted during this strategy audit.

## Guided generation contract

A free job still spends attention and cleanup time. Record these fields in the originating project's existing art manifest / experiment record before submission:

- Concrete gap, intended consumers, and existing asset search result.
- Exact parent/reference IDs and hashes; distinguish identity from style references.
- Output role: modeling reference, base-color candidate, ornament, illustration, or other precise use. Never label an image a rig or PBR set.
- Fixed proportions, palette, physical material, view, margins and background; explicit properties allowed to change.
- Model, count 1 initially, dimensions, selected cost mode and visible free-cost evidence.
- Acceptance check at actual use size; stop after one candidate and at most one targeted correction per gap before reconsidering the approach.
- Output ID, preserved bytes, decision and actual cost evidence. Account balance changes alone are not reliable attribution when other agents are using the account.

Use a shared reference when one fits. Do not spend a free generation on a material already available in the approved PBR seeds. Do not batch a roster while body, rig and material choices are unresolved.

## Bodies and animation

Share a bounded set of compatible body/rig families as described in the tabletop contract. A skeleton with no clips is not a completed animation system. A character mesh with fused weapon/shield is not automatically a modular base. Inspect skin weights, joint names, clips, equipment separation, proportions, feet and shoulders before choosing a foundation.

Shared authored forward is **-Z**. Olympus currently expects character presentation **+Z**. Apply a declared project wrapper rotation once; never silently mutate the shared source or reverse core game coordinates. Preserve real source scale; miniature scale is a consuming-project transform. Reuse existing clips through an explicit mapping to shared event names; do not rename original clips destructively.

Priority order: existing suitable mesh/rig -> existing mesh as intentional static miniature -> existing modular parts -> coherent relief/token/standee family -> defer the unit. Do not force an expensive monster body merely because it appeared in an early roster.

## Olympus visual use

Test a restrained classical tabletop treatment: cast bronze, painted wood, stone and engraved metal with clean silhouettes and intentional edges. A bronze shader does not repair poor anatomy. Prefer one coherent family to a mixture of realistic heroes, toy bodies and unrelated portraits. The real-camera comparison decides whether a low-poly source is acceptable; asset availability alone is not quality approval.

For an initial proof use one reusable human, separate spear/shield and existing animations if suitable. Architecture should reuse compatible source components and materials, not require a new purchase. No demand from Olympus should force DR Companion or Pirate Island to change character identity or art direction.

## Already purchased Olympus work — find before regenerating

The existing private [model-source package](https://github.com/dancockrell/board-game-cabinet/releases/tag/olympus-model-sources-2026-09-06) contains original GLBs, reference images, four-angle Godot reviews, a staged temple board capture, structural inventory and hashes. Agents with repository access can retrieve it. Keep the package in its existing source location; these records do not grant CC0 status or public redistribution of its binaries.

| Source | Reuse status | Important limitations |
| --- | --- | --- |
| Hoplite, Magnific DofKSycpcl | Cleanup/modeling candidate | 17,246 triangles; 38-joint skin; zero clips; fused outfit/equipment; uneven arms and weak grip; color texture only |
| Temple, Magnific WDIQxUScXe | Static architecture cleanup candidate | 24,627 triangles; no rig; color texture only; softened edges; game-specific footprint requires review |

Hoplite SHA-256: `aa5443f30fd1c87268d92a0e7f2257458b85eaf7098d63b7f5335b1e7652bbe9`.
Temple SHA-256: `4dc2d5ddf05ecd236ab322e62262832b2024dee794899a5dad88728a10a9c268`.

They consumed 2,085 reported credits including references before the zero-budget strategy. No additional spending is authorized by keeping these records. They are not shared body standards. The source package remains the authority for their detailed production history.

## Inspected reuse inventory, 2026-09-06

This is an audit snapshot, not another approval ledger. Source collections remain authoritative. Local checkouts inspected: `dancockrell/dr-companion` at `8299fe860c8ba50428d98bb3c97a292fa36c0584`; Pirate Island asset-work checkout at `07d255ac3e9255ab43874927509c2f1277aeb254`; Pirate Island gameplay checkout at `3eccfc2e9816faa9a8e65c9f91778d20ddafb22a`. Recheck before integration.

In the Pirate Island asset-work checkout, `content/art/shared_source_collections.json` catalogs 33 source collections with provenance. These are available sources, not 33 approved production packs.

| Source path (relative to its owning repository) | Finding | Decision |
| --- | --- | --- |
| Pirate asset-work: `resource-packs/source/cc0/kenney/mini-dungeon/character-human.glb` | 465 triangles, 2 skins, 32 clips. Native four-angle review shows huge cube head and very short body; referenced `Textures/colormap.png` absent in extracted bundle. Adjacent `LICENSE-CC0.txt` present. | Reject as Olympus visual body. Rig/clip research only; repair dependency before palette review. Retargeting unproven. |
| Same collection: `weapon-spear.glb`, `shield-round.glb`, `weapon-sword.glb` | Separate equipment sources; spear/shield each have one mesh/material. | Inspect sockets, scale and silhouette before reuse; no body regeneration required. |
| Pirate asset-work: `resource-packs/source/cc0/kenney/animated-characters-protagonists/characterMedium.fbx` | Body plus separate idle/run/jump FBXs and CC0 license file exist. | Native FBX review rejected for adult-body use: approximately3.3heads tall, oversized head and childlike torso. One mesh/58bones; clips not tested after silhouette failed. |
| Shared: `assets/approved_cc0/PolyHaven/medieval-wood-1k/source_files/` | Existing map set with ledger/provenance. | First material candidate for board and equipment backs. |
| Shared: `assets/approved_cc0/PolyHaven/metal-plate-02-1k/source_files/` | Existing map set with ledger/provenance. | Surface source; do not call it cast bronze without material review. |
| Shared: `assets/approved_cc0/PolyHaven/rock-boulder-dry-1k/source_files/` | Existing map set with ledger/provenance. | Arena geology candidate; no new texture generation needed. |
| Shared: `resource_packs/fortifications/castle-core/` | Wall, tower base, stone stairs and gate GLBs. | Reuse literal components only; a castle is not a Greek temple. |
| Shared: `resource_packs/maritime/pirate-prop-core/` | Crate, barrel, rowboat and cannon GLBs. | Generic props reusable where setting fits; cannon excluded from classical Olympus. |
| Pirate asset-work: `game/assets/candidates/betty_3d/betty_candidate_v1.glb` | One mesh, no skin, no clips. Existing Betty contract marks static candidate. | No shared animated body claim; inspect existing source before commissioning another. |
| Pirate gameplay: `work/art/characters/cthulhu/cthulhu.glb` | Eight meshes, one skin, six clips; manifest records procedural prototype ancestry. | Rig/pipeline evidence only, not a neutral body or visually approved model. |

No production-ready adult body family was established by this bounded audit. That is a real gap, not permission to spend or adopt the rejected chibi model.

## Next three bounded production tasks

1. **Material proof:** import one existing wood or rock set with exact hashes; correct color spaces and ARM channels; compare in native Godot at arena scale. No new geometry or generation. Validate material response under two light angles and record cost zero.
2. **Body compatibility proof:** inspect the existing alternative body source and existing paid candidates before generating. Verify adult silhouette first, then rig and clip mapping. Stop if neither provides a defensible foundation; use intentional static pieces rather than force an unsuitable body.
3. **Guided free image only for a demonstrated gap:** nominate one reusable reference/component with two intended consumers, use verified browser unlimited setting, one output then review. No automatic 3D conversion, upscaling or batch expansion. Save lineage in the originating manifest and contribute through the existing library intake.


Olympus consumed the existing dry-rock maps in its runtime stage on2026-09-06:18outcrops, byte-identical source maps and a project-owned material Resource.113stage/material and45native-app checks pass. This is a material reuse example, not new shared geometry or a completed art-quality claim. Detailed runtime ancestry stays in the Olympus art manifest.
