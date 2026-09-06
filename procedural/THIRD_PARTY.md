# Software dependency review

Cargo.lock is the exact version/checksum authority. This first build resolved:

| Package | Version | Declared license |
|---|---|---|
| serde | 1.0.229 | MIT OR Apache-2.0 |
| serde_core | 1.0.229 | MIT OR Apache-2.0 |
| serde_derive | 1.0.229 | MIT OR Apache-2.0 |
| serde_json | 1.0.151 | MIT OR Apache-2.0 |
| proc-macro2 | 1.0.107 | MIT OR Apache-2.0 |
| quote | 1.0.47 | MIT OR Apache-2.0 |
| syn | 3.0.5 | MIT OR Apache-2.0 |
| itoa | 1.0.18 | MIT OR Apache-2.0 |
| memchr | 2.8.3 | Unlicense OR MIT |
| unicode-ident | 1.0.24 | (MIT OR Apache-2.0) AND Unicode-3.0 |
| zmij | 1.0.23 | MIT |

These declarations were read from Cargo metadata for the resolved packages.
They are permissive; unicode-ident additionally requires the Unicode notice.
No GPL, LGPL, MPL, model weights, online service SDK or engine bindings are
included. Original geometry algorithms here were written from first principles.

Binary distribution must include the upstream copyright/license notices from
each resolved crate, not just this summary. No binary release package is being
published at this checkpoint. Builds and generated review images remain local.
Unity and Godot executables are not redistributed by this repository.
