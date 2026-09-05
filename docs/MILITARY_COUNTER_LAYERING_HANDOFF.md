# Military counter layering

Base: c57b71d. Scope: formation-counter rendering and regression tests only.

Counter geometry now shares the alpha rendering pass in a reserved priority band
(17–26), above settlement roof drapes. Internal border/plate/glyph/indicator order
is retained; labels render at priority 32. Opaque glyphs previously rendered before
transparent roofs despite ignoring depth, allowing roofs to overwrite their pixels.
Route/front materials are unchanged.

Validation: 26 warfare presentation tests pass; warfare runtime probe passes,
including owned/foreign material pass and relative ordering assertions after updates.
Existing headless shutdown RID/ObjectDB warnings remain. Actual terrain captures:
artifacts/army-counter-layered.png and army-counter-layered-rotated.png, compared
against army-counter-clarity.png and army-counter-rotated.png. Captures are isolated
self-quitting QA, not the player game.

No simulation, save schema, UI layout, troop counts, geometry budget, or asset changes.
Shared-file conflict surface: the end of _create_warfare_formation_marker in
scripts/local_terrain.gd. No canonical checkout edits or player launch.
