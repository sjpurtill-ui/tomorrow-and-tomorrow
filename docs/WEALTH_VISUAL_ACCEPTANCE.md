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

Seven views cover light and dark palettes at 1920×1080, the real compact
1138×640 HUD, and a regular 540-pixel dock. The expanded Wealth width is chosen
by the live HUD's layout rule. Every view captures top, middle and bottom of
the actual scrolling page. The 540-pixel case deliberately applies the existing
regular dock width after the normal Wealth layout settles.

Checks cover the actual Wealth tab and named data controls; goods and artifact
totals from the ledger; placement of the treasury versus the food-store link;
viewport bounds and horizontal overflow; retained board identity and unchanged
economic records after refresh; and navigation to Materials, Production/Military,
the common store and the real collection panel. Existing realm-purse and
enterprise suites cover levy, spending and business-stance effects.

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

This delivery owns only the probe script, scene and this document. It changes no
runtime or save format. Generated captures, reports, import metadata, UIDs and
userdata configuration remain local and are excluded from the commit.

## Baseline verification

Against integrated main `d7d4850ce54a154545188aa7005c08a6e58a7ca7`, the
headless probe passes 190/190 with no script/engine errors. Live dock widths are
980 pixels at 1920×1080, 739.7 pixels at 1138×640, and 540 pixels in the explicit
regular-width case. The deterministic held artifact resolves to approved
`prehistoric-v1/artifact-0900.png`. This checkpoint verifies the harness and
existing data/navigation contract; redesigned visual acceptance is pending.
