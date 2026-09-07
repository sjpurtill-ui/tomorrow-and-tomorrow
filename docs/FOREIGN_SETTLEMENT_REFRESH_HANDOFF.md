# Foreign settlement visual and report refresh

READY for integrator review; graphical sign-off remains pending.

Worktree: /Users/seanpurtill/Documents/Codex/tt-foreign-settlement-refresh
Branch: codex/foreign-settlement-refresh
Base: 1e57003ab6fcc34b571036cde6cf8ff78a50d81b

The screenshot used foreign_settlement_visual.gd, which was excluded from the
home settlement neighborhood deliveries. It still authored primitive houses,
rectangular yard mats and ladder paths independently of the shared house kit.
The city report hid estimates behind a toggle and put unscrollable forms in a
420px panel.

Foreign visuals now reuse the organic town house meshes at scale .001, with four
households facing shared courts and narrow feathered connecting paths. Geometry
is deterministic for the city and world seed, bounded to 128 representative
buildings, and uses only returned population estimates. No foreign construction
history is inferred from hidden simulation. Report UI explicitly identifies the
layout and architecture as representative, not surveyed. This is visual asset
parity, not a new foreign settlement construction simulation. Ground clearance
retains the existing height-only callback; slope/water-aware siting is not added.

The report opens first, with single-column estimate cards, compact header and
separate scrollable Report, Scouting and Military tabs. Existing operations and
quotes remain unchanged. Focus on map remains in the report. No new tactical or
cohort controls were added.

Validation (Godot 4.7.2, headless, explicit worktree path):
- tests/foreign_refresh_probe.tscn: PASS, zero failures. Checks repeated geometry,
  bounded counts, supplied physical transforms, no legacy roof/wall meshes,
  unchanged report records, report-first navigation, horizontal containment and
  scroll reachability at 1024x576, 1280x720 and 1000x820. Dummy renderer transforms
  are inspected through the shared renderer's source_transforms metadata.
- GdUnitCmdTool.gd -a res://tests/test_city_intelligence.gd
  -a res://tests/test_organic_town_visual.gd --ignoreHeadlessMode -c:
  22/23 pass, zero errors/skips/orphans. The sole failure is the pre-existing
  test_ai_cannot_target_unknown_home_or_read_changed_live_player_strength, line
  93 (expects one raid, receives zero). The unchanged base versions of both
  edited production scripts reproduced the same failure: 13/14 intelligence
  cases pass. All nine organic town cases pass on the final changes.
- git diff --check passes.
Logs: /tmp/foreign-refresh-probe-final.log, /tmp/foreign-refresh-tests-final.log,
/tmp/foreign-refresh-baseline.log.

No save format, simulation authority or migration changes. Test user data was
isolated with an override config, removed after validation. Canonical checkout,
player/editor sessions and saves were untouched. No graphical preview, player
launch, integration or push occurred. Appearance has not been signed off in the
engine. Review and integration belong to the designated integrator.

Owned production files: scripts/foreign_settlement_visual.gd and
scripts/city_intelligence_screen.gd. Other changes: the new probe and this handoff.
No listed simulation hotspot changed; conflicts are possible with concurrent
foreign-renderer or city-panel work. Integrate the commit, never copy folders.
