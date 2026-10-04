# Settlement growth and inherited architecture

Worker: `codex/settlement-growth`, based on `bdacd023ee3af689039ca07d1f95e649edafece5`.
Worktree: `C:/Users/sjpur/.codex/worktrees/settlement-growth/TomorrowandTomorrow`.
This worker delivery requires integrator review; it is not a player-build claim.

New household, functional and connected-quarter drawings receive the lesser of
the city's achieved construction era and its currently supported age, workforce
and adopted architectural capability. Recorded material/roof recipes remain the
source of their fabric. New homes use the same storey and representative-capacity
progression as inherited homes. This adds no housing, workforce, material charge
or population authority; the existing aggregate systems retain that ownership.
Existing plots and routes are not reseeded, rescaled, migrated or upgraded by
new development. Existing quarterly renovation remains unchanged.

Connected quarters grow from existing built edges instead of an origin-centred
ring clamped at 1.05 km. Fields and remote resource sites do not create false city
edges. A short approach joins an existing frontage or parcel entrance. Its actual
bent geometry is checked against terrain at intervals of at most 10 m, and exact
segment/polygon intersections protect inherited occupied parcels. A complete
eight-plot/eight-route batch and nucleus slot must fit before any state changes.
Side paths exclude their own new plot when choosing a connection.

Validation: Godot 4.7.2, headless, Dummy audio, isolated ignored user-data override.
Clean second import (the initial fresh asset import required fonts to finish).
53/53 cases pass across `test_settlement_model.gd` (47) and
`test_settlement_architecture_kit.gd` (6), with zero errors, failures, skipped
cases or orphans. Log: `artifacts/growth-final-delivery-tests.log`; report 5.
The model tests cover all 13 supported generations, actual founding organic
construction, year 3000, city-work/adoption/workforce gates, unchanged inherited
geometry and route records, expansion beyond 1 km, exact narrow/large parcel
avoidance, water/steep/blocked approaches, and full batch bounds. A previous
fixed lower roof-count assertion now checks real growth and the original upper
bound: contemporary homes can represent more residents than founding shelters.

Exact test invocation (from this worktree):

```powershell
& 'C:/Users/sjpur/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:/Users/sjpur/.codex/worktrees/settlement-growth/TomorrowandTomorrow' --audio-driver Dummy -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a res://tests/test_settlement_model.gd -a res://tests/test_settlement_architecture_kit.gd -c
```

Save compatibility: existing dictionary schema and optional fabric fields; no
migration or saved geometry changes. New construction takes the new rules after
integration. The year-3000 case uses the existing maximum generation 12; this does
not add speculative future architectural assets.

Limits: this is a bounded first expansion slice, not a district hierarchy for
unlimited detailed geography. The 2,048-plot/1,024-route caps and six mature-quarter
target remain. No bridge/pathfinding planner or new field-growth system is added.
No graphical probe or player session was launched by this worker. Generated
imports, isolated override, test reports and logs are excluded from the commit.
Integration conflicts are limited to `scripts/settlement_model.gd` and its test
suite; renderer and ground files were not edited.
