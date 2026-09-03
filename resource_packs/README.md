# Resource packs

Resource packs are the working unit of this library. They are organized by **physical type** and **authoring lineage**, never by a consuming game.

```text
resource_packs/
  geology/
  flora/
  structures/
  props/
  weapons/
  armour/
  materials/
  rig_parts/
  vfx/
```

Every pack owns a `pack.json` containing stable IDs, literal subject tags, style tags, authoring status, upstream source links, derivative ancestry, technical status, and review status. A derivative pack keeps its original extracted source members beside the newly authored output so it can be rebuilt or recalled by lineage.

`source_origin` means a copied upstream file that has only been placed and catalogued. `derivative` means this library has changed geometry, material assignment, topology, composition, or another concrete asset property. `reference_only` is never engine eligible.
