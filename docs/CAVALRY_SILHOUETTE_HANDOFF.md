# Cavalry and spear silhouettes

Branch `codex/cavalry-silhouette`, base `8b9f790`.

Cavalry/mobile glyphs now use a recognizable horse-head silhouette instead of
three overlapping shapes resembling a person beside a pole. One visible glyph
part replaces three; the aggregate counter and soldier count remain unchanged.
Line infantry uses the existing real triangular spearhead helper instead of a
CylinderMesh requesting three sides (Godot clamps that to four).

Validation: 26 warfare presentation tests PASS; warfare runtime probe PASS,
including horse top-face orientation, 144-vertex fixed budget, obsolete parts
hidden, spearhead 24-vertex prism, and existing offset/update/node-budget checks.
Hidden self-quitting capture inspected: `artifacts/military-glyph-audit-current.png`
before and `artifacts/military-horse-silhouette.png` after. Both use production
counter constructors. Horse head remains a map symbol, not a physical mounted unit.

No simulation, save, unit classification, menu or interaction changes. Existing
shutdown resource warnings remain. Shared local_terrain.gd edits are the horse
mesh helper and two role-glyph branches; do not overwrite pending wall-material
or other integrated terrain work.
