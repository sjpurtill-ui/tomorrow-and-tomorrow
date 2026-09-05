# Close army map scale

Base: fe5ceef6e126c7f4162d41691364e6a4744fc0cd. Branch: codex/army-close-scale.

- Counter ground clearance now scales with camera size (minimum half a metre, regional cap 180m). Previously owned counters hovered 180m above their troops at every zoom, foreign counters 150m.
- Close stack, label, and opposing-contact proximity thresholds scale with the visible map. Distinct nearby armies no longer become an artificial aggregate spanning the close view. Truly co-located troops retain separate counter slots and an aggregate label.
- Changes are presentation-only. No troop, movement, reporting, selection, save, or simulation changes.

Tests: 24 map presentation cases pass; warfare_map_runtime_probe passes including close counter clearance and the prior reported-state regression. Inspected artifacts/army-grounded.png against army-labels-clean.png. Existing resource-leak warnings remain at test shutdown.

Limitations: army labels near viewport boundaries can still run under the HUD. This pass does not redesign the counter art. No player launch.

Coordinated scope: two counter placement lines in scripts/local_terrain.gd, zoom thresholds/helper in scripts/warfare_map_presentation.gd, two existing test files. No other files owned.
