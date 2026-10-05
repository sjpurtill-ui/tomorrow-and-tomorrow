# Great Work 3D acceptance

Final private GPU acceptance passes **252/252 checks across twelve cases and
eighteen captures**, with no engine/script errors and confirmed process exit 0.
The run uses Godot 4.7.2, Compatibility/OpenGL 3.3, and an NVIDIA RTX 4090.
Evidence is local under `artifacts/great-work-accepted-gpu/capture.json`, with
`artifacts/great-work-accepted-gpu.log` and its `.runner.txt` companion. The
runner's process was PID 42772; it rendered on a private, non-input desktop.

Runtime source in the acceptance checkout is
`1c07e5a1cc4c962965d49e69b774afb3dccf5d10`, including origin/main
`8bd11fddd7bc0f177c2c914fa992527451d7d026` and the calendar wording update.
It includes Model/View through `ec691b17`, Atlas through `928d999f`, ceremony
through `5fd87a55` (including `434a08f5` framing), and the queued court fade
fix `8a2e2d29`. Runtime GDScript content matches root integration `72ea607b`.

The probe mounts the actual Great Works Atlas and AudienceDirector dedication
UI. It reuses the existing experience probe's deterministic in-memory
founder/contact setup (seed 515151), commissions through
`GreatWorks.commission`, and supplies explicit prepared elapsed construction.
Active crews come from a real daily work pass. Near-completion finishes through
`advance_record` and its seeded outcome. Shortage uses actual missing materials;
the ruin uses the engine's collapse outcome helper.

| Cases | Coverage |
| --- | --- |
| 01-03 | Early foundations, raising and crowning; live daily progress from an initially paused host |
| 04-05 | Material-stalled work and an engine-recorded collapse |
| 06-08 | Middle construction, year-3000 construction, and daily-engine completion |
| 09-12 | Offering, ribbon, illumination, and narrow/dark unveiling dedications |

Prepared middle/industrial/future states use game years 2000/2700/3000 and
actual catalog skills, including clothing and lighting. Year 3000 uses the
supported modern tier 5; the calendar does not invent a new construction tier.
These are prepared-record presentation/contract tests, not a continuous
multi-century campaign.

All eight Atlas cases contain actual meshes, correctly reflect progress and
crew status, retain geometry during orbit/zoom, and stop requesting idle redraws.
The live case starts Normal (speed 3), reads real daily work, retains its model
within the same visible construction course, and restores the original pause.
To verify actual GPU idling, each case records viewport pixels, hides only its
fixture geometry without requesting a render, and confirms identical pixels.
An explicit camera request then produces different pixels; geometry is restored
before capture. All eight sleep/wake pairs pass. This deliberately tests the
rendered image instead of the cached node update-mode getter
([Godot source](https://github.com/godotengine/godot/blob/master/scene/main/viewport.cpp)).

Ceremonies verify opt-in opening, no gifts/rewards for preview, postpone/reopen
preservation, names recorded through the engine, real planned gifts conserved
between donor and recipient stocks, duplicate-delivery rejection, and pause
cleanup. Every cast record mounts a real court figure, with at most six people.
Dedication retains the monument and settles the viewport. All naming, postpone,
dedicate and result-close controls remain reachable at 1920x1080 and 1138x640.
Whole-work and speaker/ritual views were visually inspected, including dark
unveiling and the year-3000 opening lights.

The acceptance owns only this document and the two new
`tests/great_work_3d_acceptance` files. It loads/saves no campaign and changes no
player preferences or save format. Its fixture host only provides the simulation
speed interface; the real world clock is not run for centuries. Existing suites
remain the authority for seeded odds, deaths, owner scoping, restoration, legacy
loads, rivalry and policy effects. This run verifies bounded geometry and idle
render behavior, not full-world frame-rate performance or other GPU backends.

Run with an ignored acceptance-specific `override.cfg` whose custom userdata
name contains `acceptance`, Dummy audio, and an explicit isolated project path:

```powershell
& $Godot --headless --audio-driver Dummy --path $Project `
  --log-file "$Project/artifacts/great-work-functional.log" `
  res://tests/great_work_3d_acceptance.tscn -- --great-work-acceptance --require-3d

& "$Project/tools/run_isolated_gpu_probe.ps1" -Godot $Godot -Project $Project `
  -Scene res://tests/great_work_3d_acceptance.tscn `
  -LogFile "$Project/artifacts/great-work-accepted-gpu.log" `
  -UserArguments '--great-work-acceptance --require-3d --capture --out=res://artifacts/great-work-accepted-gpu' `
  -TimeoutSeconds 480
```

`--case=<case-id>` selects one fixture; `--out=...` changes its output directory.
Strict mode requires the actual 3D views. Base mode only validates the prepared
engine/UI fixture and must not be reported as 3D acceptance. GPU pixel checks
and captures are skipped headlessly. A pass requires the final summary, no
failures or engine/script errors, and confirmed exit. Generated images, logs,
imports and test userdata remain local. Earlier `combined`, `final` and
`delivery` artifact folders are intermediate evidence; `accepted` is the
complete passing run on the final runtime above.
