# Army route scale and grounding

Branch `codex/army-route-scale`, base `11d6fd5`.

Army route widths and march arrow sizes no longer impose their old 0.45/0.50 km
scale floors over the smaller local-view presentation scale. Ribbons, arrows and
objective markers use zoom-aware ground clearance and the same terrain sampler.
The route cache includes an 8% logarithmic zoom bucket so within-band geometry
updates while unchanged views reuse their existing path.

Headless and hidden graphical warfare runtime probes PASS. Actual army refresh
tested at 8, 20, 40 and 320 km for route scale, objective ground clearance,
changed-zoom rebuild and unchanged-zoom reuse. Actual MultiMesh arrow scales and
cardinal directions checked with the graphical renderer. Existing marker/layer
tests also pass. This is a numerical placement/scale correction, not a new design.

No route orders, reported positions, army simulation, saves or menus changed.
Ground-band path visibility remains unchanged. Scale steps remain bounded by the
8% cache bucket; existing shutdown resource warnings remain.

Base precedes pending scout scale commit `968b134`. Preserve its scout-only edits
when integrating; this commit touches army path refresh/constructor and tests only.
