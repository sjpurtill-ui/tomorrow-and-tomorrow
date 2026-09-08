# Founding water and neighbor guidance

READY for integrator review; source commit is the commit containing this handoff.
Base: bd1992c7e63ade7d0e901cbc8a1721c08dd42fc9.
Worktree: /Users/seanpurtill/Documents/Codex/tt-founding-water-guidance.
Branch: codex/founding-water-guidance. Integrator: root.

## Behavior

Review Founding Site opens a compact card on the real terrain before first commitment. It shows a known fresh-water source, distance/bearing, household drinking coverage, and water-hauling warnings. It marks up to three suitable nearby sites plus the selected water source; numbered choices focus the agreed 50,000-foot view and can send the founding convoy through its existing route/provision checks. Map clicks and Escape dismiss the initial review without ordering movement.

First and later founding commands reject sites without a confirmed source within the existing 6 km collection limit. Final commitment rechecks the exact location rather than using the 25 m display cache. Water within 1 km earns a recommendation; longer carries remain an explicit strategy choice. The existing household collection curve supplies the coverage estimate. Dry terrain validation remains independent for military recovery.

The review and later convoy quote also show border provocation from returned city reports. Relations lose up to 70 points using 0.70 * (1 - distance/30 km)^2 inside 30 km; closer settlements cause larger penalties. Each affected civilization receives one grievance per player city, based on its closest owned city. Additional player cities can add grievances. Border tension rises by the same amount. Cities within the existing 12 km sight radius observe a new settlement locally; farther neighbors react when ordinary reports reach them. Hidden foreign cities are not exposed by the preview. Repeated reports/days/load do not re-charge the same grievance; diplomacy can subsequently repair relations.

Recommendations require charted dry land, nearby known water, no known foreign city within 30 km, and a charted route that passes existing convoy terrain validation. Search is bounded to 128 candidates within 12 km and runs on request, with a 256-entry display cache keyed by world and fog revision. No-candidate results explicitly describe that limited search.

## Files and conflicts

New: scripts/founding_site_advice.gd, scripts/hud/founding_site_guide.gd, scripts/settlement_siting_relations.gd, tests/test_founding_water_guidance.gd, tests/test_settlement_siting_relations.gd.
Changed: scripts/local_terrain.gd (shared integration hotspot), scripts/hud/command_rail_hud.gd, scripts/civilization_system.gd, scripts/settlement_model.gd; tests/test_map_onboarding_ui.gd now explicitly initializes charted founding knowledge.
No concurrent workers or shared-file conflicts. No project settings, terrain data, population authority, government labor authority or military combat changes.

## Validation

107 tests pass across test_founding_water_guidance, test_settlement_siting_relations, test_map_onboarding_ui, test_map_panel_dismissal, test_settlement_model, test_secondary_city_design, and test_city_intelligence. Zero errors, failures, skips or orphans. Log: /tmp/tt-founding-water-tests.log. The last marker-label/duplicate-hover-query cleanup then passed the 23 focused water/relations tests: /tmp/tt-founding-water-final-ui.log.

Cases include exact collection-limit rejection, hidden water, dry banks, real seeded hydrology, read-only previews, real first-site commitment, secondary founding boundaries, visible quote actions at 1024x640, monotonic opinion penalties, delayed observations, repeat-report deduplication, multiple cities, controlled-city ownership, and serialized grievance preservation.

Fresh-worktree import initially exited with signal 11 at asset import; retry completed successfully, /tmp/tt-founding-water-import-retry.log. A later malformed test override signature was corrected before the passing runs. All tests used the isolated TomorrowFoundingWaterTests user directory; the owned override.cfg was removed. No player/editor process was stopped and no actual campaign save was modified. Native visual verification remains for integrated main.

## Compatibility and limitations

Existing saves load without a new required field. Grievances are optional dictionaries inside already-persisted civilization relations. Previously observed nearby player cities can acquire their first grievance after this update; the deduplication then persists. No map pins or review caches are saved.

Water guidance uses current authored rivers, tributaries and surface drainage and the existing collection model; it does not add wells, aqueducts, seasonal hydrology or a complete water-hauling simulation. Suitability describes these known checks, not guaranteed food/security or a global best-site search. The map's existing convoy route rules still decide crossings and endurance. The 30 km diplomatic radius is an initial tuning choice, not historical fact or a war declaration rule. Existing diplomacy, treaties and military/intelligence gates continue to determine actual hostile action.
