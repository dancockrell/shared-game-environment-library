# Project 42 shared-asset-platform import — candidate only

This directory is a byte-preserving transfer of the generic resource-library
payload from Project 42's `codex/shared-asset-platform` branch at commit
`74bd481`. It was moved here because a cross-project source library belongs in
the shared environment library, not in a consuming game's repository.

## Status

`candidate_intake_only`. Nothing in this import is approved source material,
engine-ready content, or a consumer project's runtime asset. Do not reference
these files from a game scene or package them with an application.

The import deliberately retains its original `resource-packs/` hierarchy,
including its source-collection license captures, generated local index, and
curated geometry metadata. The files have not been renamed, transformed, or
reclassified as part of this move.

## Promotion gate

Promote a collection or derivative only after the shared-library intake
procedure records its exact upstream source, archive checksum, license
evidence, internal paths, and technical review. Promotion goes into the
appropriate library lane (`assets/approved_cc0/` or `resource_packs/`) with a
new manifest entry; it never happens by treating this whole import as approved.

## Provenance

See `catalog/candidate-imports/project42-shared-asset-platform.json` for the
source branch, immutable commit, transfer count, retained license claim, and
required review work.
