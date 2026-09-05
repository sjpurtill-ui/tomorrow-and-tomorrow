# Inhabited ground continuity

Base: f0b4b2b. Design-critique review identified close town roofs disconnected from
the existing shared-ground representation: density patches were excluded for all
LOD0, including ordinary village altitude. Permit them with the same384-patch
budget as LOD1. Their shader fades from zero to full with a0.12–0.60metre pixel
footprint, retaining close-yard detail rather than creating an opaque city decal.

Existing plot positions, irregular feathered patches, palettes, and exclusions are
retained. Farms/water/temporary camps/reclaimed land do not acquire urban cover.
No simulated buildings, population changes, new textures or save changes. This adds
one existing batched density draw atLOD0, bounded to384 eligible plots.

Validation:81 architecture/material tests PASS, including fixedbudget/exclusions.
Captures town-current-audit.png versus town-ground-connected.png, plus
village-ground-connected.png at0.25km. Difference is restrained ground consolidation,
not a replacement settlement art style. No claim of full visual redesign.

Shared terrain scope:_settlement_plot_has_aggregate_density and kind4 shaderalpha.
No canonical edits or launch.
