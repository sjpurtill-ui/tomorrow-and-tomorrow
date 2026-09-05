# Military counter clarity

Base ba7c25707d249444afa7a004aa137eaeca9c04be; branch codex/military-counter-clarity.

- Center existing weapon/vehicle silhouette; remove redundant command spine; move supply/echelon decoration to badge edges.
- Compact troop count sits below the badge in screen-down direction, including camera rotations. Full detailed labels and their HUD-clearance fallback remain.
- Owned counts are exact; foreign compact counts preserve estimate ranges or unknown status instead of displaying the upper bound as exact.
- No menus, selection, unit rules, saves, or extra render nodes. One mesh removed per counter.

26 map presentation tests pass; runtime probe passes including three camera rotations, existing HUD-obscured/clear transitions, glyph offsets, selection and budgets. Inspected perspective counter-clarity-before.png and counter-clarity-final.png (probe caption typography was also corrected), actual terrain army-counter-clarity.png versus prior army-label-clearance.png, and army-counter-rotated.png. Existing shutdown resource warnings remain.

Remaining independent issue: roof drapes can overdraw low-priority counter parts when an army overlaps a settlement. Reported to integrator; not changed here.

Shared files: counter creation/application in local_terrain.gd; counter_strength formatter in warfare_map_presentation.gd; existing runtime/unit tests and military_glyph_probe. No player launch.
