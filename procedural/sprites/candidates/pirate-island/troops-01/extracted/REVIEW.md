# Troop extraction review

Six candidate cutouts extracted from the preserved magenta source using Cattle
Trail's existing sprite_grid.py with columns=3, rows=2, min-component-pixels=1.
No resizing; binary alpha; no components dropped; no gutter warnings.
metadata.json records exact extraction parameters, crop bounds and hashes.

Source-size visual inspection of the three male cutouts confirmed intact
silhouettes and weapons. They are consumed as provisional idle appearances by
Pirate Island's island scene. The pirate is more frontal than the other two.
The three female cutouts remain candidates awaiting individual visual review.
No walk or attack animation and no final game-scale art approval is implied.

Runtime copies map row 0 columns 0/1/2 to colonial/pirate/cultist respectively.
The authored full-source ground pivots (255,540), (578,540), (1023,540)
become trimmed pivots (116,366), (143,363), (127,374). This preserves existing
placement rather than centering the weapon-inclusive bounding box.

Validation: actual Godot island scene loads all three binary-alpha textures
without shader materials; travel, pause, save/backup recovery, skirmishes,
casualty removal and restored survivor projection pass. All 52 Rust tests pass.
Headless validation does not substitute for rendered scene review.
