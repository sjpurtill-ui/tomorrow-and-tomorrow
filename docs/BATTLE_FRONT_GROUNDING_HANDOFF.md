# Battle-front grounding

Branch: `codex/battle-front-grounding`; base: `362ad9c`.

Front markers now use the existing zoom-aware military ground clearance instead
of a fixed 0.20 km elevation. This prevents local front markers floating far above
their map position. No visibility, battle rules, labels, menus, or save data change.

Validation: `tests/warfare_map_runtime_probe.tscn` PASS, including actual marker
height and visibility at camera sizes 8, 20, and 320 km. Existing shutdown resource
warnings remain. This is a numerical placement correction, not a visual redesign.

Limitations: ground-band fronts remain hidden. Enabling them requires a combined
layout with co-located army counters; simply enabling visibility would overlap them.

Shared file: `scripts/local_terrain.gd`, only the front position elevation expression.
