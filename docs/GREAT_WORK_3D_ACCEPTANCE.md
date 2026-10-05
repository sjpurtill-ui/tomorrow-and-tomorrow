# Great Work 3D acceptance

The new `tests/great_work_3d_acceptance.tscn` mounts the actual Great Works
Atlas and AudienceDirector dedication UI. It reuses the existing experience
probe's deterministic in-memory founder/contact setup (seed 515151), commissions
through `GreatWorks.commission`, and supplies explicit prepared elapsed work.
It never loads or saves a campaign, changes player preferences, or opens the
current game. The fixture host only owns the simulation-speed interface.

Twelve bounded cases cover early foundations, raising and crowning; a real
material shortage; an engine-applied collapse; middle and year-3000 construction;
daily-engine completion; and offering, ribbon, illumination and narrow/dark
unveiling dedications. Prepared middle/industrial/future states use game years
2000/2700/3000 and actual catalog skills, including clothing and lighting.
Known skills gate each commission. Year 3000 uses the currently supported
modern tier 5; calendar time alone does not invent a new construction tier.
Prepared near-completion goes through `advance_record` and its seeded outcome.
These are presentation/contract tests, not a continuous campaign simulation.

Strict mode (`--require-3d`) requires the selected Atlas model and ceremonial
stage diagnostics, real geometry, bounded cast, orbit/zoom retention and paused
idle rendering. It checks the Atlas watch control against the existing host
clock, starts Normal (speed 3) from a previously paused host, restores that pause,
and reads a real daily progress change. No visual helper advances the
simulation itself. Base mode validates the engine/UI fixture before integration
and does not claim 3D acceptance.

Ceremony checks require opt-in opening, no gifts/rewards merely for preview,
postpone/reopen preservation, naming through the real engine, gift conservation
across donor/recipient stores, duplicate-delivery rejection and pause cleanup.
Existing Great Works suites remain the authority for seeded odds, named deaths,
owner scoping, restoration, legacy loads, rivalry and policy effects.

Run with an ignored acceptance-specific `override.cfg`, `--audio-driver Dummy`,
and the explicit worker/integration project path:

```powershell
& $Godot --headless --audio-driver Dummy --path $Project `
  --log-file "$Project/artifacts/great-work-functional.log" `
  res://tests/great_work_3d_acceptance.tscn -- --great-work-acceptance --require-3d

& "$Project/tools/run_isolated_gpu_probe.ps1" -Godot $Godot -Project $Project `
  -Scene res://tests/great_work_3d_acceptance.tscn `
  -LogFile "$Project/artifacts/great-work-capture.log" `
  -UserArguments '--great-work-acceptance --require-3d --capture' -TimeoutSeconds 480
```

`--case=<case-id>` selects one fixture; `--out=res://artifacts/<folder>` changes
the output directory. Functional/capture JSON reports stay separate. A pass
requires the final `GREAT_WORK_3D_ACCEPTANCE` summary, no failures or engine/script
errors, and confirmed process exit. Captures run only on the private desktop.
Generated images, logs, imports and test userdata remain local.

Base: `9984106042088ef8f499128d5dfa740602f8116a`. The preliminary base-mode run
passed 116/120 checks: the four old ceremony layouts exceeded the viewport, and
the old ruin plate emitted polygon triangulation errors. Both findings were
reported to their runtime owners. The final fixture adds explicit ceremony-mode
coverage and real-gift checks; final acceptance is pending runtime integration.
This delivery owns only this document
and the two new probe files; no runtime or save-format changes.
