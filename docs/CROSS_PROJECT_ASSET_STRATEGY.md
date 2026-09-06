# Cross-project asset production strategy

Owner direction, 2026-09-06: DR Companion and Pirate Island take priority. Olympus / Board Game Cabinet is a low-priority consumer with no new paid-generation or purchase budget. Reuse assets creatively and coherently; childish clay-like primitive assemblies do not meet the visual goal. Free generation is allowed when guided toward a named, useful asset.

## One library, project-owned identity

Use the existing resource-pack ledger and tabletop contract. Do not create another shared library or universal character implementation. Source meshes, bodies, rigs, sockets, animations, neutral materials and props can be shared. Named characters, lore, gameplay and final visual approval remain with each app. Existing illustrated adventurer references are references, not bodies or rigs.

Before work, search `catalog/resource-pack-ledger.json`, approved source/material ledgers and the consuming projects' source inventories. Distinguish a downloaded source from an admitted runtime asset. Preserve originals; record exact source hashes and transformations when exporting.

## Cost boundary and verified Magnific route

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
