# Engraved folio HUD — October 4, 2026

User direction: beautify the circled left navigation and top status bar; create
unique Shakespearean icons. The user approved the generated engraved folio style.

Worktree: `C:/Users/sjpur/.codex/worktrees/court-face-richness/TomorrowandTomorrow`
Branch: `codex/hud-chrome`; base: `48c7c60051f2b216d081b277adeaf348c818fa96`.
The icon worker's pushed source `bcfc976ac3dc22cc60eac68ebca6d85055c855e1`
was cherry-picked as `bf379840`; its vectors are now missing-art fallbacks.

## Delivered behavior

- Twenty distinct transparent folio emblems for Court, navigation, ledgers,
  resource readings and Menu. Source PNGs are unchanged built-in image generation
  outputs; asset README and provenance retain generation briefs and hashes.
- The parchment rail uses larger artwork, a framed Court entry, recessed ledger
  rows, clear selected and keyboard focus states, and readable labels. It scrolls
  at short heights; the Menu remains outside that scrolling area.
- Time and pace occupy two rows. Framed status cards retain stable widths,
  live readings, semantic warning rules, hover details and existing routing.
  Neutral engraving colors reverse in night mode, preserving original gold.
- Shared rail width and header/content-top tokens keep docks, notices, military
  panels and the military travel line outside the enlarged chrome.

No simulation, adjudication, population, civic authority or save schema changes.
Existing saves are compatible. No player/editor process is stopped or restarted.

## Validation and reproduction

Godot 4.7.2 headless import and 52 cases across `test_command_rail_stability`,
`test_kpi_detail_panels`, `test_era_words`, `test_button_contrast`, and
`test_notification_stack` pass. These are state/layout checks; GdUnit is run with
`--ignoreHeadlessMode` and does not certify native pointer input in headless mode.
The adjacent `test_war_screen` and `test_home_docks_plain` suites pass all28
cases, bringing this checkpoint to80 passing cases across seven suites.

`tests/hud_chrome_capture.tscn` renders actual HUD widgets in an isolated fixture,
at 1920×1080, 1280×720 and 1138×640, in light and dark modes. It checks viewport
bounds, clock overlap, complete status text height, ledger text extents, stable
warning widths and absence of a closed drawer frame. Both palette runs pass.
`world` additionally renders the real terrain and HUD in a disposable paused
new world, without loading or saving a player campaign. All graphical checks
use `tools/run_isolated_gpu_probe.ps1` on a private desktop with Dummy audio;
the processes exit after captures. Reports remain local in `reports/hud_chrome`.

Both atlas source hashes and all twenty crop bounds were independently reviewed.
Mipmapped sampling was visually checked; it removes fine-line aliasing at small
sizes. Dark mode preserves alpha instead of multiplying it twice.

## Scope and integration

Owned runtime files: `command_rail_hud.gd`, `hud_chrome_icon.gd`,
`hud_folio_art.gd`, `hud_tokens.gd`, the two atlas PNGs/import settings and mapping.
Related layout-only edits: `notification_stack.gd`, `war_board.gd`,
`command_hierarchy_panel.gd`, `military_roster_screen.gd`, `war_map_mode.gd`.
Shared hotspot `scripts/local_terrain.gd` changes only the military travel-line Y
offset to the shared content-top token. Preserve concurrent terrain and map work.

Only intentional source, artwork, import settings, capture fixture and docs are
staged. Existing generated import churn, private overrides, reports, captures,
saved games and authoring setup remain local and excluded. Final remote and
canonical verification is recorded in the delivery message and integration log.

Limits: detailed engraving naturally simplifies at status-caption size; no
high-DPI performance benchmark is claimed. Narrow screens keep the existing
priority rules that hide less urgent status cards. A running game retains its
loaded UI until a normal restart.
