# Wealth visual acceptance

`tests/wealth_visual_acceptance_probe.tscn` mounts the actual economy Wealth tab:
`command_rail_hud.gd` → `dock_content_economy.gd` → `dock_panel.gd` →
`dock_blocks.gd` → `purse_board.gd`. The test shell builds the real folio chrome
and dock controls without initializing terrain or a saved campaign. It does not
substitute a drawing or a mock Wealth board for the runtime component.

The in-memory seed is 551188. Prepared fixtures cover a populated early barter
settlement, empty stores and no makers, and a developed coin economy. Numbers
come from the actual Goods, Standing, Purse and Enterprise readers. These are
explicit presentation fixtures, not claims about simulated demographic or
economic progression. Populated fixtures hold an actual `ArtifactCollection`
record made through `find_at`, using the collection tests' seed 777 and the first
deterministic site with approved prehistoric artwork. The poor fixture holds no
treasure. The report includes the record and approved image path.

Nine views cover light and dark palettes at 1920×1080, the real compact
1138×640 HUD, and regular 540-pixel barter and coin docks, including an opened
business-stance disclosure. The expanded Wealth width is chosen
by the live HUD's layout rule. Every view captures top, middle and bottom of
the actual scrolling page. The 540-pixel case deliberately applies the existing
regular dock width after the normal Wealth layout settles, reapplied over three
layout passes so old column minimums can relax. Exact requested width is
asserted independently of viewport fit; a failure logs the minimum-width tree.

Checks cover the actual Wealth tab and named data controls; goods and artifact
totals and current-day production from the ledger; placement of the treasury versus the food-store link;
viewport bounds and horizontal overflow; retained board identity and unchanged
economic records after refresh; and navigation to Materials, Production/Military,
the common store and the real collection panel. Existing realm-purse and
enterprise suites cover levy, spending and business-stance effects.
The visual checks also require visible availability, comparison and distribution
charts; responsive card/panel column counts at the runtime breakpoints; and the
exact approved texture associated with the actual held artifact record.

Run only in a worker/integration checkout with its absolute project path and
ignored isolated userdata configuration:

```ini
[application]
config/use_custom_user_dir=true
config/custom_user_dir_name="TomorrowandTomorrow-wealth-acceptance"
```

The script requires `--wealth-acceptance` and an acceptance-specific custom
user directory. It disables simulation processing, never loads a campaign and
does not invoke SaveSystem or change player preferences.

After the checkout's normal headless import, run the functional scene:

```powershell
& $Godot --headless --audio-driver Dummy --path $Project `
  --log-file "$Project/artifacts/wealth-functional.log" `
  res://tests/wealth_visual_acceptance_probe.tscn -- --wealth-acceptance
```

Capture only through the private-desktop runner, which supplies Dummy audio:

```powershell
& "$Project/tools/run_isolated_gpu_probe.ps1" -Godot $Godot -Project $Project `
  -Scene res://tests/wealth_visual_acceptance_probe.tscn `
  -LogFile "$Project/artifacts/wealth-capture.log" `
  -UserArguments '--wealth-acceptance --capture' -TimeoutSeconds 240
```

`--out=res://artifacts/<directory>` selects another output folder. Functional
and capture reports are separate JSON files. A successful run requires the final
`WEALTH_VISUAL_ACCEPTANCE` summary with zero failures, clean script/engine logs,
and process exit 0. A timeout or frame-limit exit without the summary is not a
pass. Screenshots are test specimens, never the current player game.

`--case=coin-regular` (or another case ID in the script) selects a single fixture.
The probe uses queued teardown and drains layout work between cases. Its HUD
subclass retains the real Court button but disconnects that button's pre-mount
court asset warmup hook: the unrelated four-second timer otherwise outlives
short-lived Wealth fixtures and logs a freed lambda capture. No court is opened
or verified by this probe. The Wealth board, charts, navigation and collection
panel use their runtime implementations.

This delivery owns only the probe script, scene and this document. It changes no
runtime or save format. Generated captures, reports, import metadata, UIDs and
userdata configuration remain local and are excluded from the commit.

## Baseline verification

Against integrated main `d7d4850ce54a154545188aa7005c08a6e58a7ca7`, the
headless probe passes 190/190 with no script/engine errors. Live dock widths are
980 pixels at 1920×1080, 739.7 pixels at 1138×640, and 540 pixels in the explicit
regular-width case. The deterministic held artifact resolves to approved
`prehistoric-v1/artifact-0900.png`. This checkpoint verifies the harness and
existing data/navigation contract before the redesigned visual acceptance below.

## Redesigned Wealth acceptance

Final runtime source is root checkpoint
`46c42c1a45ea74a2b3f11f209a8a99d510e68490`, tested through the matching
cherry-picked runtime at acceptance-worktree `0b78899a`. The final private GPU
run passes **363/363** checks: 336 functional assertions plus 27 saved captures,
with no script/engine errors. Godot 4.7.2 used the OpenGL compatibility renderer
on an RTX 4090. The private-desktop runner reports process 56184 exited 0, and
the process was confirmed absent afterward. This is visual/behavioral acceptance,
not a frame-rate benchmark.

| Cases | Requested and actual dock width | Current goods made/day |
| --- | ---: | ---: |
| Opening light / dark | 980 px | 5.6 |
| Poor light | 980 px | 0 |
| Coin light | 980 px | 94 |
| Coin compact light / dark | 739.7 px | 94 |
| Opening regular / open stance choices | 540 px | 5.6 |
| Coin regular | 540 px | 94 |

Every case also asserts that its combined minimum width fits the requested
width. Checks caught the original business-stance and levy rows forcing a wider
dock; the accepted runtime wraps those choices. The prepared production report
is stamped with the current day, so the real Production reader supplies the
same made-goods value displayed in Wealth. Disclosure opens without selecting
a new stance. Display refresh preserves the prepared economic records.

Local evidence is under `artifacts/wealth-final/`: `capture.json` records the
nine cases, full real artifact dictionaries, measured dock rectangles, economic
readings, assertions and image paths. Each case has `-top.png`, `-middle.png`
and `-bottom.png`. The clean engine log is
`artifacts/wealth-final-capture.log`; its `.runner.txt` companion records private
desktop isolation and exit status. Reviewed images include the expanded opening
hero, 540-pixel coin levy and spending controls, opened 540-pixel business
choices, and dark compact hero. Values, chart labels and controls are readable
without horizontal clipping in these specimens.

The fixture shell does not initialize terrain or feed the top-bar live KPIs;
those unrelated header readings show dashes. It does not test a continuously
running campaign, controller/keyboard traversal, or court asset preloading.
Economic policy effects remain the responsibility of the existing purse and
enterprise regression suites. All evidence files and isolated userdata remain
local; only the probe, scene and this document are source deliverables.
