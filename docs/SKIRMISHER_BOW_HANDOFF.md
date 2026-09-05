# Skirmisher bow glyph

Branch `codex/skirmisher-bow-glyph`, base `1ed9500`.

Skirmishers now show a curved bow, string, shaft and real arrowhead, matching the
current military catalog's bow equipment. Existing four glyph slots are reused.
The curved arc is a fixed eight-segment/48-vertex mesh, not a per-unit object.

Runtime probe PASS, including arc budget/upward normals, arrowhead presence and
existing full military bounds/offset tests. Hidden self-quitting production glyph
capture inspected: `artifacts/military-all-unit-silhouettes.png`. The QA probe now
reads all eleven archetypes from the real catalog rather than omitting skirmishers,
machine guns and modern artillery. Its viewport adjusts to the row count.

No gameplay, equipment gate, save, troop count, menu or selection changes.
Existing shutdown resource warnings remain. Shared local_terrain.gd changes are
the bow mesh helper and skirmisher branch only. Physical close army figures are
unchanged; this is the strategic counter symbol.
