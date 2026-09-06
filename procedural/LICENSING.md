# Scene Forge licensing

User-authorized policy change, 6 September 2026:

- Current original generator software and Blender tooling in this directory
  are GPL-3.0-or-later. LICENSE contains the GPL version 3 text.
- Prior MIT grants are not revoked. LICENSE.MIT preserves the original
  copyright and permission notice and applies to the previously MIT-covered
  portions incorporated into the current work.
- The original Unity adapter under unity/ remains MIT under unity/LICENSE.
  This is a licensing exception for those files, not permission to distribute
  a GPL native library linked into a proprietary engine. That distribution
  architecture remains unapproved; a file-based authoring/export boundary
  must not be confused with the existing native-link development adapter.
- Third-party software keeps its own notices and terms; see THIRD_PARTY.md
  and Cargo.lock. No Blender implementation code has been copied into Rust.
- Blender is installed separately. Do not redistribute its binary without
  satisfying its license and source-distribution obligations.
- Catalog assets keep their individual provenance and licenses. Merely using
  Blender or this generator does not make artistic output GPL, but embedded
  third-party assets may impose their own terms.

Do not label the combined generator MIT-only. Do not relabel third-party art,
erase copyright notices, or infer Unity distribution clearance from local tests.
