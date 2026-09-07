# Organic town first playable slice — review handoff

READY for integrator review, September 7, 2026. Not integrated or player-launched.

Worktree: `/Users/seanpurtill/.codex/worktrees/c2aa/tomorrow-and-tomorrow`
Branch: `codex/organic-town-integration`
Base: `1b9e121f481d1382eb1ecce9e7dde17b66b9e754`
Canonical Mac remains `/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow`.
The delivery commit is the commit containing this file.

## Behavior and ownership

- `scripts/organic_town_visual.gd`: deterministic, bounded frontage placement from
  saved plot polygons, IDs, seeds, material families, roof plans, land use, storeys,
  roof coverage and existing route geometry. Houses face lane sides or lane heads;
  residual household land can carry small kitchen-garden beds. Neither homes nor
  beds create residents, production, workers or new saved simulation records.
- `scripts/local_terrain.gd` (shared integration hotspot): integrates six reusable
  components as at most six MultiMeshes plus one garden mesh; caches the layout
  across camera rebuilds. Fitting plots retire their legacy roofs. No-fit plots
  explicitly retain legacy roof fabric. Historical camps, round/flat/stone roofs,
  taller buildings and other land uses retain their renderer. Existing selection
  and simulation ownership are unchanged.
- `assets/buildings/organic_town/`: four 24 m² houses and a 120 m² market hall from
  the accepted organic-town study, plus a 12 m² small house derived from the medium
  house for inherited small parcels. All source dimensions are metres; every
  runtime building instance uses uniform scale 0.001. One vertex-color material
  preserves modeled framing/roof courses. Source procedural noise is not baked.
- `tools/build_organic_small_house.py`: reproducible Blender background derivation
  of the smaller floor plan; horizontal dimensions shortened by sqrt(0.5), full
  height retained. It does not alter the game unit conversion.
- `tests/test_organic_town_visual.gd`: nine focused tests. No existing simulation
  test or authority was rewritten.

The complete early slice is primary settlements through 5,000 population and 128
recorded plots with at least one compatible permanent building. It removes the
legacy stage mass/density overlay in that range while retaining authoritative
completed/under-construction defenses and the computed settlement extent. Ground,
route, boundary and yard lifts in the slice are centimetres, not several metres
through a correctly scaled building.

At most the first 128 persistent plot IDs receive this kit, at most eight buildings
per plot and 512 total. Their geometry survives later population/plot-count growth;
newer districts use the existing bounded aggregate renderer. Population affects
settlement size through the existing plot model, not a new per-person object rule.
Actual current population does not set an individual house's position or style.

For the changed houses the same transforms and source meshes are used at every
camera distance. Identity-transform GLBs retain Godot's imported LOD/shadow meshes;
no settlement image tile, disk or unrelated distant building proxy is introduced.
Frustum culling remains on the bounded batches. Orthographic camera calibration is
unchanged; Camera3D.size is a view extent, not an altitude.

## Validation

Godot `4.7.2.stable.official.ed1daf0bf`, explicit worktree path, headless, Dummy audio.
Ignored local `override.cfg` isolated user data under
`TomorrowAndTomorrow_OrganicTown_Test`; do not copy it to canonical.

Final command:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless \
  --path /Users/seanpurtill/.codex/worktrees/c2aa/tomorrow-and-tomorrow \
  -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode \
  -a tests/test_organic_town_visual.gd \
  -a tests/test_settlement_visual_architecture.gd \
  -a tests/test_settlement_model.gd
```

**135 cases passed; zero errors, failures, skipped cases or orphans; exit 0.**
Final log: `/tmp/organic-final-regression.log`; local report `reports/report_15/`.
After a final eligibility guard restricted the early mode to inherited kit IDs,
the nine focused cases passed again (exit 0, `reports/report_16/`,
`/tmp/organic-last-focused.log`). Earlier intermediate
failures found road cap clearance, insufficient real-parcel fit, a headless
MultiMesh getter limitation, condition handling and a typed-variable parse error;
those intermediate runs are not claimed as successful validation.

Focused evidence:

- Imported all six GLBs and checked ground origin, height, COLOR_0, one mesh
  surface, uniform 0.001 CPU transforms supplied to MultiMesh, and bounded batches.
  Four original houses and the derived small house are 532 triangles each; hall 608.
- Determinism under input reordering, a one-resident-per-plot increase, condition
  changes, construction/ruin/reoccupation and current political-profile changes.
- Footprints contained in actual polygons, pairwise nonintersection, clearance of
  road envelopes including caps, rejection of water fixtures; garden containment
  and exclusion from roofs; market land use selects the hall.
- Real model founding fixture with recorded permanent timber completions: 19 plots,
  five accepted small homes, remaining no-fit plots retain legacy roofs. This is
  not a claim that the real founding camp is automatically upgraded to houses.
- Production `_create_plot_fabric` on actual terrain: identical supplied transforms
  at camera sizes 0.12, 1, 3, 16 and 100, plus populations 1001/5000/5001/1 billion.
- Tiny no-fit plot explicitly retains `PersistentRoofFabric`; early return retains
  the exact stage radius; authoritative defense surfaces still exist.
- 128-plot workload stays within 512 kit buildings; existing 83 architecture cases and
  43 settlement model cases pass, including aggregate growth/material/route behavior.
- `git diff --check` passed. No player save was loaded or written.

## Limits and next review

No in-engine graphical sign-off or FPS claim. The approved isolated graphical
launcher in this repository is Windows/private-desktop-only. No second graphical
player/test window was opened on the Mac and no live editor/game was interrupted.
Headless MultiMesh getters use a dummy backend; the scale/camera tests inspect the
CPU transforms actually submitted, not a rendered pixel result. The integrator
should visually review this slice before describing it as verified player visuals.

This is a partial, compatible-tradition replacement, not a complete restyle of all
existing plots. Old parcels are often too small or have crossing access routes;
no-fit fallback retains old visual limitations rather than hiding occupied plots.
The new component does not promise historically calibrated household occupancy.

The mature stage land-cover layer resumes outside the early slice; its transition,
continent-scale footprint, foreign settlements and later architectural kits remain
outside this delivery. Inherited kit houses retain identity across that boundary,
but no claim is made that the wider mature silhouette is derived from these houses.
Mesh LOD configuration is retained; GPU LOD quality/performance has not been measured.

Height uses the game's close-terrain sampler at the building origin. This slice
has no individually excavated foundations or slope terracing; steep/rough local
terrain needs a graphical inspection. Water clearance uses center/corner/mid-edge
samples plus the existing terrain/river predicate, not an exact water polygon union.

Recorded material, form and roof-plan history gates the kit. The plot records do
not contain a full per-building historical political-architecture snapshot, so the
renderer does not invent one or instantly restyle old houses from current politics.
Existing model-generated parcel/route variation is retained. Broader historical
architectural variations should be added through that authority in a later slice.

## Integration and save compatibility

Save schema and all simulation authorities are unchanged; no migration required.
The only shared-file conflict is `scripts/local_terrain.gd`, specifically stage
landscape early return, plot fabric, route/yard/boundary lifts and layout cache.
Other files are new. No merge, push, canonical launch or integration-status update
was performed. Unrelated generated UID/import sidecars remain uncommitted; the
local test override and reports must remain in this worktree.
