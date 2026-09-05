# Army label clearance

Base a0d123167e407635c55fa2f1843839fa8e199bdf; branch codex/army-label-occlusion.

Detailed army labels now check their estimated screen bounds against the viewport and actual visible HUD panels. When obstructed, the existing compact soldier count remains visible on the counter. Full detail returns when clear. No HUD layout, menu, selection, simulation, or save changes.

Font measurement is cached by text/font/size; viewport projection and visible panel bounds remain live. No extra scene nodes or draw calls.

Verification: 25 map presentation tests pass. Runtime probe checks obstructed-to-clear transitions and compact-count fallback alongside prior army tests. Inspected artifacts/army-label-clearance.png against army-grounded.png. Existing shutdown RID/resource leak warnings remain; bounds are deliberately conservative, not exact glyph masks.

Shared scope: _apply_warfare_formation_view and new helper in local_terrain.gd; pure rectangle predicate in warfare_map_presentation.gd; existing test suites. Coordinated with integrator. No player launch.
