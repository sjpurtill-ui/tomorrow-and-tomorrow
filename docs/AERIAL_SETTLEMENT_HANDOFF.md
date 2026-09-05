# Aerial settlement fabric

Worktree: C:/Users/sjpur/tt-settlement-aerial-fabric
Branch: codex/settlement-aerial-fabric
Base: 8a629a322f3b958ffcc90ce0470aaf1abeb75a2e

## Scope

Only the strategic urban fabric shader in scripts/local_terrain.gd and an
isolated rendered probe. No menu, simulation, save, terrain geography, river,
woodland, or authoritative settlement-boundary changes.

The old mature-city capture showed a dark street grid surrounding a small
inhabited core. The shader now resolves roof coverage within the existing
bounded urban surface: 48 deterministic layout combinations, local street
bends, varied roof sizes/positions, courts, open ground, roof-plane shading,
and small contact shadows. Cultures with strong axiality retain straighter
streets. Material tint still comes from the simulated settlement palette.

No photographic district clipmap is restored. No building objects or population
records are added. Detail integrates into the existing coarser land-cover field
as projected pixel size grows. The eight condition states retain the existing
survival rules: poor is occupied; physical damage removes roof sectors.

## Verification

- 72 existing settlement-architecture/material-filtering tests passed after
  the final shader edits.
- Compatibility-renderer captures inspected at 50,000 population, development
  tier 8, synthetic year 800. Iterations: city-occupied.png, city-varied.png,
  city-roof-presence.png in artifacts (local, not committed).
- tools/aerial_neighborhood_probe.gd renders all eight conditions and exits.
  Inspected artifacts/neighborhood-conditions.png. Its patches occupy different
  world coordinates, so this is an appearance check, not an exact same-layout
  quantitative comparison.
- Inspected city-zoom-2.39.png and city-zoom-2.41.png: the new neighborhood field
  retains its positions across the LOD boundary. Existing label/claim overlays
  still change there; a separate claim-opacity transition pass is planned.

## Limitations

## Follow-up: live ownership fade

The claim wash previously jumped to 30% of its strategic opacity immediately
above 2.4 km. It now enters smoothly over 2.4–4.4 km. Base claim alpha remains in
the vertices and a live material multiplier follows the camera, independent of
quantized network geometry rebuilds. Ownership geometry and values are unchanged.
72 architecture tests passed including the new monotonic, near-threshold and
same-material regression. Inspected city-claim-smooth.png at 2.41 km. Label offset
and plot LOD changes at that boundary remain separate from this tint fix.

## Remaining limitations

This remains abstract aerial geometry, not individually modeled city buildings.
Static captures do not establish moving-camera performance or shimmer freedom.
Existing full-scene capture teardown texture/RID warnings remain. Godot may
update tracked texture import compression during editor import; those generated
changes are outside this pass and must not be included blindly.

Shared integration hotspot: local_terrain.gd urban shader only. Integrator owns
main and launch. Preserve any concurrent renderer work when cherry-picking.
