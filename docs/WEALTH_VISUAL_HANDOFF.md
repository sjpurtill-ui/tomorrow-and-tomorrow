# Graphical Wealth screen

Base: synchronized canonical and origin/main `d7d4850ce54a154545188aa7005c08a6e58a7ca7`.
Integration workspace: `C:/Users/sjpur/.codex/worktrees/settlement-growth-integration/TomorrowandTomorrow`.
Branch: `codex/wealth-visuals`. Root owns integration and the Wealth board;
workers own the chart helper, lower work ledger and isolated acceptance probe.

## Player-visible changes

The Wealth page now leads with a large goods balance, its value in rations,
and a ring showing how much stock is available after household and workshop
needs. A shared-scale comparison shows goods per person against the existing
age benchmark. Illustrated timber, stone and fibre readings show alternative
buying power at the current prices; they are not extra stocks or simultaneous
purchases.

Three illustrated cards show daily making, actual held treasures and material
stores. Craft imagery follows the existing supported knapping/basket/kiln/anvil
selector. A treasure image must resolve from an actually held artifact through
the approved origin-aware artwork lookup. Empty collections remain empty.
Existing coin illustrations remain confined to the currency account ledger.

Five equal-width columns show the actual wealth shares of five equally sized
household groups. Business keeps its current effects, next requirements and
stance actions; its choices wrap within narrower cards. The common store and
coin treasury retain their existing placement and controls. Levy choices also
wrap inside narrow panels; this shared layout applies to the food-store levy
without changing its actions.

The lower work ledger presents actual daily work, a measured effectiveness
gauge, health/shelter/goodwill indicators, the settlement leader, and recorded
money-account balances and history. Its 0-150% gauge marks the 100% baseline;
missing measurements are identified rather than filled with sample data.

## Source ownership

- `scripts/hud/purse_board.gd`: root; layout, existing live data presentation,
  approved art binding, navigation and scoped refresh signatures.
- `scripts/hud/wealth_graphics.gd`: worker source `86e3962e`, integrated as
  `85230b98`; ring, household columns and paired comparison bars.
- `scripts/hud/wealth_ledger.gd`: worker source `85cb63c7`, integrated as
  `2ac4cf0d`; lower work and money-account presentation.
- `tests/wealth_visual_acceptance_probe.gd/.tscn`: acceptance worker; real
  economy provider, dock and controls mounted on an isolated test shell;
  final worker source `efe3dfa7`, integrated as `021ee10d`.
- Focused regression tests and these delivery/acceptance documents.

No shared simulation files, project settings, economic formulas, save format,
population counts, labor allocation or state ownership change. Existing art
resources are reused; this task creates no new image assets. Prior renderer,
terrain and settlement work stays intact.

## Retention and responsive behavior

Custom charts have no process loop or per-frame node creation. The board keeps
its existing one-second checks and rebuilds only sections whose displayed data
changes. Relative-price changes invalidate buying-power readings even if food
value is unchanged. Unrelated material changes retain the goods hero. The lower
ledger updates figures on its existing controls. Responsive grids rearrange
existing cards and use the containing scroll viewport to avoid a wide layout
trapping its own minimum width.

Both light and dark presentation use the shared text-safe theme colors. The
craft glyph sits on a small paper mount so its detail remains readable in dark
mode; existing painted material and artifact images remain mounted artwork.
Navigation links are keyboard-focusable and keep their original destinations.

## Validation

Initial board/model regression passed 57/57 across the Wealth visual, realm
purse and enterprise suites. Worker ledger checks passed 15/15, including
existing home-dock prose contracts, 320px light/dark layout, missing measures,
above-baseline output, account actions and retained live controls. Chart worker
checks passed 8/8 for zero/partial/full stock, true common scales, invalid input
guards, theme behavior, array snapshots and idle retention.

The final combined five-suite regression passed 72/72 against runtime
`46c42c1a`, including levy wrapping, report 14, exit 0. Its log is local
`artifacts/wealth-final-tests.log`. The runner reports no test failures,
skips or orphans;
resource/RID cleanup diagnostics at process exit remain a known test-run
limitation, and are not described as a clean engine log.

The final private-desktop GPU run against runtime `46c42c1a` passed 363/363:
336 functional/layout checks and 27 captures across nine prepared cases.
Expanded panels measure 980px, compact panels about 739.7px, and regular
panels exactly 540px, including open business choices and the coin treasury.
Both themes, zero/low stock, real held-artifact binding, current production,
navigation and unchanged-control retention are covered. The engine log is
clean and isolated process 56184 exited with code 0. The probe excludes the
unrelated Court-button background prewarm hook; no Court runtime was changed.

See `WEALTH_VISUAL_ACCEPTANCE.md` for the final integrated rendering checks,
fixture descriptions, exact captures and reproduction. Captures use the actual
Wealth dock with prepared in-memory records, not a running player campaign.

## Delivery and compatibility

The canonical checkout's 4700 pre-existing modified/untracked files have a
separate SHA256 inventory for preservation checking. Task delivery must pass
the incoming-path collision check, push and freshly verify origin/main, then
fast-forward canonical main and verify those existing bytes.

No user game or editor is launched, stopped or restarted. The next normal
canonical launch loads the new scripts. Isolated captures, logs, reports,
engine imports, generated UIDs and test userdata stay local and are excluded.
