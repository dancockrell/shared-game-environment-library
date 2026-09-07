# Shared sprite production

Current game production uses detailed illustrated pixel art. Sources under `candidates/` are not automatically shipped or approved. Preserve each source and generation record; keep individual projects' art authority separate.

## Room placement review

The first grounded room package is `candidates/barana-drydock-01/`. Open its `review.html` directly in a browser; no server, account, engine or network is needed.

The review consumes `room.json`, validates its source image hash and dimensions, and embeds the metadata for offline use. It shows explicit layout probes, supports floor-bounded placement and exports edited candidate JSON. Export does not modify the source file or admit the asset. To apply a reviewed export, replace the intended manifest after inspecting the diff, then regenerate.

```sh
node tools/sprite-room-review.mjs procedural/sprites/candidates/barana-drydock-01/room.json
node tools/sprite-room-review-test.mjs
```

One canonical placement function serves validation and the browser. Coordinates are normalized image coordinates, not meters or MUD topology. Floor and approach anchors are artist estimates. The graph-backed south exit remains explicitly off-camera; no invented exit socket or command dispatch is supplied. The 2D room plate remains flattened, so this is not yet a layered sprite scene.

Before runtime admission: correct alpha and frame extraction for actors; stable ground pivots; sprite scale and lighting review; real occlusion masks; reviewed entrance placement; actual client integration and confirmed-state behavior. The current sheet's checkerboard and weak gait continuity are unresolved, so gold probes are deliberately used instead of misrepresenting it as a usable actor.

The optional second test argument is a path to an existing Playwright module, enabling a headless interaction/screenshot check. It downloads no dependencies and starts no world server.
