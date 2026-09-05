# Battle HUD redesign — isolated review build

Integration update: selected for canonical release 2026.09.05.5. The text below
records the original isolated delivery; current status is in docs/INTEGRATION_STATUS.md.

This work lives on `codex/city-defense-aftermath` in `C:/Users/sjpur/tt-city-defense-aftermath`. The normal game remains canonical release 2026.09.05.4 in `C:/Users/sjpur/TomorrowandTomorrow`. Do not copy this test project's custom user-data configuration into the canonical game.

## What changed

The supplied Claude Design battle resolve/orders reference is implemented as native Godot controls around the existing BattleDiorama. Unit meshes, terrain, generals, animation, gore, and camera mechanics are retained. Army inspection keeps its existing controls in ArmyInspectionScreen.

The replacement includes round/phase status, Fighting/Out/morale with a loss-breakdown tooltip, calculated strength shares with animated needle/previous-share highlight, world-anchored formation and general labels, paginated formation orders and targets, a folding orders phase, resolving headline/loss figures/log, pause/half-speed/skip, camera presets and cursor-directed pan/zoom, round results, historical replay, withdrawal, and captive/property policy decisions. The HUD uses physical window dimensions while open and restores the prior canvas scaling when closed. At narrow widths the roster and order panel switch via a button; pages replace scrolling.

Strength shares use MilitaryCampaign.combat_summary. They are explicitly not victory odds or casualty projections. The 15% morale break point comes from the existing resolver. The signed change is the attacker share change in percentage points. Historical event labels substitute the actual armies for the resolver's legacy River Host/Hill Guard display names, without changing recorded simulation data.

## Orders and simulation

BattleRoundOrders validates per-formation Hold, Advance, Charge, and Fall back orders, including living targets for attacks. Directives persist in active engagements and are recorded with each round. Hold preserves the previous calculation. Other orders reuse existing offensive/push/cautious coefficients and bias contact allocation toward the chosen cohort. Temporary per-round modifiers are removed before carrying the result forward. No civilian muster, defense formula, unit balance, or campaign speed redesign is included.

Resolving commits one simulation round, then presents that immutable result for five seconds. Pause, speed, skip, and replay operate on the presentation. Replay reconstructs earlier cohort counts from recorded losses and does not call the resolver. The newest battle history entry is first, not last. Final committed context retains strategic aftermath details. Closing the new battle HUD returns to the map instead of reopening the old military modal.

Repeated visual types still share the existing diorama's aggregate model group. Nameplates are anchored to that group's position and separated to avoid overlap; the roster retains exact individual formation records.

## Validation

- 52 focused tests passed: formation-order validation/persistence, baseline Hold equivalence, deterministic targeted loss allocation and conservation, injury accounting, surprise hostilities/direct city orders, and inherited siege regressions.
- GPU mouse probe: map army click → contextual attack → paused round zero → target/Charge/Hold → resolve once → pause → skip → result → replay with campaign-state equality → next orders → natural defeat → return to map. Camera presets checked.
- Main 1600×900, 1000×720, and 900×700 screenshots reviewed. A synthetic 13-formation roster checks pagination and narrow-panel switching. Visible button bounds and order-panel/bottom-control separation are asserted.
- Victory policy controls are separately tested with an explicitly synthetic eight-captive UI fixture after the real battle. That fixture is not used in the interactive scenario.
- The baseline 180 attackers / 119 defenders / 600 residents / world seed 74017 remains on verified dry terrain, with music muted, paused on the map and no battle started. No campaign save is loaded or written.

Logs and screenshots are in `artifacts/hud-*.log` and `artifacts/battle-hud-*.png`. The scenario is `res://tests/manual_city_assault.tscn`; disposable verification flags are `--verify-hud`, `--verify-aftermath`, and optional `--verify-retreat`.

## Fonts and reference

Bundled unmodified Barlow Medium and Barlow Condensed Bold with their SIL Open Font License files:
- https://github.com/google/fonts/tree/main/ofl/barlow
- https://github.com/google/fonts/tree/main/ofl/barlowcondensed

Reference: supplied `Civ game battle screen feedback.zip`, README and HTML source. The app browser declined its local HTML URL; no alternative browser/hosting workaround was used. Verification images are actual Godot renders.

## Integrating after review

Cherry-pick only the HUD implementation commit and relevant tests/assets into the canonical integration branch. Keep the isolated scenario commit and its project configuration separate. Re-run the focused suites and mouse probe against the selected source, then update canonical release/provenance docs and launch only the canonical launcher. Preserve other worktrees and uncommitted files.
