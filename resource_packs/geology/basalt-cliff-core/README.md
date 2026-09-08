# Current policy: 2D only

Owner direction, 8 September 2026: all projects use 2D artwork only. Do not acquire, generate, admit, restore or reuse 3D models, rigs, model builders, volumetric scenery or model-only material packs. The owner requested permanent deletion, including shared packs and archived copies.

Any model pack described below is rejected and pending deletion. Historical details do not authorize reuse.

# Basalt Cliff Core

This is the first shared derivative resource pack. It takes three legally cleared Kenney Nature Kit cliff modules and builds a new, compact basalt cliff pass: a cave-facing rock base, a side shoulder, and a raised cap. The derivative changes the composition, placement, orientation, and material assignment. It is deliberately a neutral geological asset, suitable for coastlines, volcanic approaches, jungle escarpments, cave mouths, or mountain roads after a consuming project applies its own palette and scene dressing.

The pack is a source-and-derivative bundle, not an engine-shipping promise. The generated OBJ is valid static geometry and has stable metadata; collision, LOD, thumbnail, and Godot import review remain explicitly pending.

Build with:

```powershell
./tools/build-basalt-cliff-pack.ps1
```

The script is deterministic. It extracts the exact upstream OBJ inputs from the retained archive, builds the derivative OBJ/MTL pair, and writes a stable build report with source and output hashes.
