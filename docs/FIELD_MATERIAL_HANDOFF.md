# Cultivated ground material readability

Base e54f1bcf6bbb76ffe39c3da7a6019ba5b24518e3; branch codex/field-material-readability.

Field-only shader branch keeps the simulated crop/phase vertex palette and uses source-photo luminance for surface texture, instead of replacing nearly all field color with source photography. Growing-phase crops receive a greener canopy tint; the existing mature family palettes remain. Alpha, geometry, crop timing, food yield, and saves are unchanged.

75 texture/settlement tests pass, including crop color relationships and unchanged field opacity. Inspected the six-phase probe (artifacts/fields-before.png and fields-final.png) and full village (village-fields-materials.png versus village-roof-filtered.png). Differences intentionally remain subtle at the existing .18 field alpha. Existing capture shutdown resource warnings persist.

New self-terminating tools/field_material_probe.gd renders actual production field material; optional --output selects an artifact filename. It does not run or save a player game.

Shared scope: growing tint in _settlement_plot_color; field-only branch in _settlement_fabric_material; test_map_texture_filtering.gd; probe. Coordinated with integrator. No player launch.
