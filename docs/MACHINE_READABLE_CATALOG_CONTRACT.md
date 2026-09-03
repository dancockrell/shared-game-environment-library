# Machine-Readable Catalog Contract

This repository is a queryable resource system. Markdown explains the policy;
JSON manifests and generated ledgers are the operational interface.

## Stable query surfaces

| Surface | Question it answers |
| --- | --- |
| `catalog/library-taxonomy.json` | Which stable values and facets exist? |
| `catalog/asset-manifest.schema.json` | What evidence is required for a source-asset record? |
| `resource_packs/**/pack.json` | What is this literal pack, who may use it, where did it come from, and what is its readiness? |
| `catalog/resource-pack-ledger.json` | Which packs and outputs match a cross-pack query? |
| `catalog/candidate-imports/*.json` | What has been preserved but is not yet admitted? |

## Required resource-pack facets

Every `pack.json` must contain these constrained fields:

```text
metadataVersion
packId
packType
provenance.class
provenance.rightsStatus
provenance.rightsRecord
scope.contentScope
scope.projectAffinity
scope.subjectScope
scope.adultPresentation
style.renderLanguage
style.physicalSubject
style.sceneRoles
sourceLineage
outputs[]
review
engineEligibility
searchTags
```

`provenance.class` is one of `borrowed_library`, `our_build`, or
`restricted_external`. `scope` answers where and how a pack is intended to be
used; it never substitutes for provenance.

## Query discipline

Use a conjunction of explicit fields, not filename guesses or prose searches.
For example:

```text
provenance.class=our_build
AND scope.contentScope=project_specific
AND scope.projectAffinity contains project-42-pirate-island-rpg
AND scope.subjectScope=character
AND scope.adultPresentation=adult_only
AND style.renderLanguage contains stylized_3d
AND engineEligibility=engine_reviewed_runtime_asset
```

No current pack is implicitly eligible because it appears in the repository.
A query result remains a candidate for a consuming project until that project
records its own adoption and runtime review.
