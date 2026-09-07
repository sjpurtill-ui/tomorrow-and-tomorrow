# Foreign city labels and map intelligence — September 7, 2026

Worker: /Users/seanpurtill/Documents/Codex/tt-foreign-city-labels
Branch: codex/foreign-city-labels. Base: 1d8b178b5eb78a7b2a82815c966b419caa6ecd81.

Reported foreign city names remain visible at every camera distance. They use
owned-city type size, outline, color, render priority and screen-up offset, with
population estimates from returned reports. The old camera.size <= 2 label cutoff
is removed. The 64-city geometry budget no longer discards names. Existing
known-city limits and geographic culling remain; unknown cities are not revealed.
New reports refresh label estimates even when the cached settlement mesh is stable.

Clicking the city name, pin or physical geometry opens an immediate summary in the
existing map-side dock. It includes population, garrison, defenses, supplies,
damage, production/logistics, age and source. Unknown fields remain unknown.
Full report and actions are optional from that summary; no automatic full-screen
city report. Labels/pins support screen-space hit testing at all distances.

Owned changes: scripts/local_terrain.gd (shared hotspot: foreign marker rendering,
city picking and inspection), scripts/hud/content/dock_detail_foreign_city.gd,
tests/test_foreign_city_map_labels.gd. No simulation/save schema changes.

Clean headless import passes. Two targeted cases pass: known-city labels and
clicks at all four calibrated distances; map summary reads frozen reported
estimates without opening the full report. Combined with existing intelligence
suite: 7/8 pass. The pre-existing test_ai_cannot_target_unknown_home_or_read_changed_live_player_strength
fails at line 93 (expects one target, gets zero), reproduced unchanged in the
speed-dropdown worktree at 45b24d1. Logs /tmp/foreign-label-tests.log and
/tmp/foreign-label-base-intel.log. No new failures or script errors after fixture
parse correction. Tests use isolated application data and Dummy audio.

User explicitly requests relaunch and then adds immediate map intelligence.
Player is already closed; current quicksave metadata records Seanston, 147 people,
day 2374.288, seed 1792946605. Resume this save through canonical editor Run Project
with --resume-saved; do not create or advance a new campaign as verification.
Integration and live verification are recorded separately.
