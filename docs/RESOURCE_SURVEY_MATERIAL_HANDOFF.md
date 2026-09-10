# Map surveys, dryland appearance and available construction materials

Task worktree `/Users/seanpurtill/Documents/Codex/tt-military-visual-roster`, branch `codex/military-visual-roster`, base `6d127d8f9b3e6c00d25a8cfe2fa458f3d8213735`. Sole integrator. Extends the approved military presentation delivery with the user's corrected survey scope and subsequent terrain/material requests.

## Behavior

- Revealed ground inspection uses a bounded 420px graphical survey: surface conditions, native vector material icons, distance, qualitative quality/abundance meters, access and the first blocker. Details expand existing explanations. Unknown/contact/settlement-plot inspection retains its existing information. Disclosed lens entries remain the authority; no hidden deposit quantities or production rates are invented. Long lists scroll; close and map dismissal remain available.
- Dryland color comes from the existing climate classification. Terrain photographs supply light/dark texture while biome color supplies hue. Meadow and lush-patch additions now respect the climate color. Resource placement, rainfall, fertility, woodland density, water and geography are unchanged.
- Starter works have feasible clay/stone/fiber alternatives. Household and functional recipes compete by the fraction of delivered city stores consumed, preserving explicit feasible stone policy. Earthen households still require clay-shaping knowledge. Timber-free earthen workshop/court variants use additional clay and plant fiber; industrial processing retains real fuel requirements. No material, worker or knowledge is granted.
- Completed starter shelter/storage/workshop records propagate their paid material family into subsequent plot conversion; earthen shelters use the existing earthen building kit. Recipe material mixes no longer claim ingredients absent from their bill. Older completed buildings retain recorded forms. No connection between the communal social classification and a timber preference was found; the actual bias was timber-only starter recipes and first-affordable timber recipes.

## Validation and limits

23 focused tests pass with zero errors/failures/skips/orphans across local-material choices, survey cards, secondary city design and architecture. 88 existing regression cases pass across settlement model, landscape resources, landscape resource visuals, early settlement visual and city resources. Tests cover paid construction, no double charging, city-isolated choice, knowledge/material gating, functional variants, existing fabric, narrow scroll layout and unknown survey values. Logs `/tmp/tt-survey-material-tests.log`, `/tmp/tt-material-regressions.log`.

Native capture-only `tests/survey_terrain_visual_probe.tscn` uses the actual terrain shader and map-lens widgets with disclosed sample data. It exits itself and passes; dry ground's mean red/green ratio is 1.137–1.142 and grassland's is 0.903–0.956 at 2/10/200/2000km test extents. Images were inspected in `artifacts/resource-survey`; log `/tmp/tt-survey-terrain-capture.log`. This is isolated visual validation, not a player launch or live map performance claim.

Save schema unchanged; existing stockpiles/knowledge feed new choices. Existing advanced upgrade/fuel recipes still require their actual structural/fuel inputs. This is not universal substitution of clay for every use of timber. Shared integration files: `scripts/local_terrain.gd`, `scripts/settlement_model.gd`; `scripts/settlement_construction.gd` plus new shared selection helper. No concurrent shared-file conflict. No player/editor stopped.
