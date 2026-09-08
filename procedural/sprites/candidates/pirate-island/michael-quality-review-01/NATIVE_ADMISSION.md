# Michael standing revision: native-resolution admission

The parent reviewed the revised face, collar, vest, and brass separation as an improvement, with coherent four-view equipment placement. This is development standing art, not finished animation.

The user's subsequent direction supersedes normalized source preparation: **no artificial source downsampling or palette reduction**. `revision-runtime-candidate.png`, `revision-frames.json`, and the sampling/normalization scripts are preserved historical comparison evidence only. Do not ship those normalized files.

Use `revision-native-atlas.png` with `revision-native-frames.json`. `pack_native.py` packs all four extracted RGBA images byte-for-byte with no resampling, color reduction, or alpha compositing. Four-pixel transparent margins separate cells. Each packed rectangle is checked byte-for-byte against its extracted source.

`worldScale` is a rendering transform, not source processing: it preserves the prior physical body height (592, 600, 586, 597 source pixels respectively, times the existing 0.065 world scale). The original full-resolution source remains available to the renderer. Foot pivots are stance center and last image row. The engine should use per-frame worldScale rather than a second normalization export.

Generation and background correction provenance, limitations, and preserved original comparison references remain in REVISION_REVIEW.md. Two built-in generation calls were used; no further generation is authorized for this revision. Cost is not asserted to be zero.
