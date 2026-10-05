# Trade visual acceptance

`tests/trade_visual_acceptance_probe.tscn` mounts the actual Trade dock through
`command_rail_hud.gd`, `dock_content_economy.gd`, `dock_panel.gd`, and
`trade_board.gd`. It prepares in-memory records and pauses simulation. No player
campaign is loaded, saved, or represented by its screenshots. The fixture shell
does not initialize terrain. The approval preview initializes the real HUD
readings from prepared daily food and water reports; those readings appear
on the top bar above the page. As in the Wealth probe, it
disconnects only the unrelated Court-button prewarm timer before mounting the
short-lived HUD shell.

Seed 661288, day 420, supplies empty and word-only contact states plus barter
and coin fixtures. Three real WorldSimulation actors have prepared stores and
reports. Two have actual Trade ledger records with several goods each way,
one long name, a toll awaiting an answer, a paid tribute record, an embargo,
and a previous answer. The third is known only by word. Monthly flow history
is prepared in the ledger's real shape; these fixtures do not claim a campaign
has simulated that history.

Nine cases exercise light and dark palettes, 980px expanded docks, 540px
regular docks and the shared dock's 375px minimum (331px Trade content). An
independent regression mounts the actual TradeBoard in a 320px scroll viewport;
the existing dock chrome cannot itself shrink to that width. Exact
width, minimum size, viewport containment and all visible descendant horizontal
bounds are asserted. The named hero and partner charts must contain the exact
values read from the ledger, with seasonal conversion performed once. Resource
quantities must occupy a single line, so digit wrapping cannot masquerade as
separate values. Word-only
contacts must have no measured flow chart or trade actions.

Unchanged refresh and the actual dock's rebuild must retain the Trade board,
hero chart and partner cards while preserving the trade, stock, purse,
population and order records. Top, middle, bottom and opened squeeze/buy menus
are captured. Menus use the real callbacks; popup windows are embedded in the
test viewport so their contents appear in viewport captures.

`tests/test_trade_visuals.gd` checks the same presentation contract and invokes
real stance, squeeze and buy-menu handlers. A purchase must move equal goods
between the real stores, spend the stated amount, and register one order. The
existing `test_trade_and_pressure.gd` and `test_trade_pacts.gd` suites remain the
broader simulation regressions.

Use an isolated worktree with this ignored `override.cfg`:

```ini
[application]
config/use_custom_user_dir=true
config/custom_user_dir_name="TomorrowandTomorrow-trade-acceptance"
```

After the normal headless project import:

```powershell
& $Godot --headless --audio-driver Dummy --path $Project `
  --log-file "$Project/artifacts/trade-functional.log" `
  res://tests/trade_visual_acceptance_probe.tscn -- --trade-acceptance

& "$Project/tools/run_isolated_gpu_probe.ps1" -Godot $Godot -Project $Project `
  -Scene res://tests/trade_visual_acceptance_probe.tscn `
  -LogFile "$Project/artifacts/trade-capture.log" `
  -UserArguments '--trade-acceptance --capture' -TimeoutSeconds 240
```

`--case=coin-dark-regular` selects one named fixture. `--out=res://artifacts/name`
chooses a local output directory. A successful run requires the final
`TRADE_VISUAL_ACCEPTANCE` summary with no failures, engine/script logs reviewed,
and process exit 0. A timeout or frame-limit exit is not a pass. Graphical runs
use only the private-desktop runner with Dummy audio and the worker's explicit
absolute project path; its probe process must be confirmed exited afterward.

`--preview` prepares a single actual Trade prototype at 1536x1024 for the
user's visual approval. It captures only the top of the runtime page, preserves
the runtime dock sizing, and places a small TEST / Prepared records label
outside the page. The optional `--case=coin-light` or `--case=coin-dark` changes
the prepared economy/palette. This mode runs no acceptance contracts and writes
`prototype.json` plus `trade-preview.png`, with `TRADE_PROTOTYPE_CAPTURE` as its
completion marker. A successful prototype capture is not visual approval or
permission to integrate.

Source scope is the new regression script, probe script/scene and this document.
No runtime or save-format changes. Imports, UIDs, captures, reports, logs and
isolated userdata remain local and are excluded from source delivery.

## Verification

Source is held for the user's approval of the revised visual direction. The
first runtime prototype was captured in nine views; those images are retained
as local evidence, not an accepted design. No integration into the current game
is authorized before the user approves the rendered example.

Against runtime source `219f2c47` (worker cherry-pick `5b39dee0`), nine nonvisual
regressions passed in report 4; the directional-update regression passed in
report 6 after correcting its test wait to follow the runtime's wall-clock
throttle. Headless fixed-frame time advanced a SceneTreeTimer faster than that
monotonic clock. The test now waits for wall time without forcing a refresh.
The direct 320px board fits; the actual shared dock's minimum is 375px, leaving
331px of Trade content. Broad visual acceptance awaits the revised prototype
and the user's design approval.

This is a HELD harness checkpoint for the integrator's preview work. The next
runtime iteration adds a collapsed TermsToggle / TradeTerms disclosure and
reworks the whole page chrome. Broad acceptance must open that disclosure
before exercising its visible menus and be reconciled with the approved
layout. The assertion-free preview mode remains intended for that approval
step; the previous prototype's passing checks do not certify the new design.

## Live readings on the top bar (approval revision)

The top bar projects the exact caption, value, note and warning color already
formatted by CommandRailHUD. It follows the strip's era and width visibility,
retains the existing hover details and click destinations, and updates retained
controls without rebuilding Trade or moving its scroll position. Notes remain in
the existing hover details and accessibility text; warning values retain their
warning color. The readings replace the wordmark while a page is open, beside
the existing city selector. Closing the page restores the map strip. It adds no
simulation calculations and changes no save format. The top bar is shared by
all open pages at this
checkpoint. The full illustrated-page revision remains HELD for user approval.

`tests/test_folio_readings.gd` checks hidden-strip parity, live shortage updates,
keyboard focus, navigation, hover detail, era changes, reopening, economic-state
preservation and top-bar containment at 1536 and 1138px canvas widths.
The 1536x1024 GPU example is retained locally in
`artifacts/trade-top-bar-preview/trade-preview.png`; its daily reports are
prepared in memory and are not readings from the user's current campaign.

Verification: all three focused regressions passed with zero errors, failures
or orphan nodes (report 13). The clock overlap case includes a long date and
temperature string. Broad page acceptance remains pending visual approval.
