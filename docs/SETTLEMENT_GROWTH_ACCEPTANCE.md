# Persistent settlement growth acceptance

`tests/settlement_growth_acceptance_probe.tscn` exercises the live
`local_terrain.gd` footprint refresh and queued patch rebuild path. It does not
call the retired district atlas helpers or load a campaign save. The deterministic
seed is `625114`, shared with the city evolution visual fixture.

The specimen starts with four inherited plots, adds a separately connected
quarter, creates contemporary district construction through the settlement model,
changes one building's damage and repair appearance, and pans/zooms a paused retained
view. It records patch node identities/signatures and cumulative rebuild counts,
checks that unchanged geometry survives, and checks the two-job queue slice cap.
Parcel generation and material fields are checked independently of renderer
identity. The later construction uses the model's district-plot constructor at
a fixed site with generation selected by the actual supported-new-fabric policy.
Completion is explicitly prepared for the visual specimen; it is not a claim
that the full simulation selected or completed that location.

A separate table-driven matrix covers every supported fabric generation 0–12
from the founding year through year 3000, including industrial and modern
construction. Each independent specimen supplies capable crews and materials,
adopts only catalogue knowledge eligible at its recorded year, and then calls
the actual new-fabric selector and district constructor. The report records
capability inputs, selected generation, form, style, storeys, and actual rendered
mesh fingerprints and roof/building counts. This is an explicitly capable visual-history fixture, not
an assertion that calendar passage awards those capabilities in a campaign.

The final stress sequence grows 96→128→129 prepared plots, crossing the detailed
layout limit, then damages and repairs plot 129. It reports changed and retained
plot patches, checks inherited parcel records, verifies unaffected patches
survive the local repair, drains the queue and measures the 129-plot steady view.
Growth crosses complete stable ID shards, so every inherited active plot patch
must survive both additions. Hidden cached specimens never count as retention.
It supplies observed timings without treating a guessed latency as a pass.

Run only in a worker/integration worktree. Use its absolute project path and an
ignored `override.cfg` to isolate userdata before importing or running:

```ini
[application]
config/use_custom_user_dir=true
config/custom_user_dir_name="TomorrowandTomorrow-settlement-growth-acceptance"
```

Import with Godot `--headless --audio-driver Dummy --editor --import --path
<absolute worktree>`. After a first clean-checkout import, repeat once if the
initial scan encountered fonts before their import was available. Existing
untextured court meshes may report the documented UV/tangent import diagnostic;
new script/runtime errors are failures.

Headless functional run:

```powershell
& $Godot --headless --audio-driver Dummy --path $Project `
  --log-file "$Project/artifacts/settlement-growth-headless.log" `
  res://tests/settlement_growth_acceptance_probe.tscn -- `
  --settlement-growth-acceptance
```

Private GPU timing run (explicit Dummy audio is applied by the runner):

```powershell
& "$Project/tools/run_isolated_gpu_probe.ps1" -Godot $Godot -Project $Project `
  -Scene res://tests/settlement_growth_acceptance_probe.tscn `
  -LogFile "$Project/artifacts/settlement-growth-timing.log" `
  -UserArguments '--settlement-growth-acceptance' -TimeoutSeconds 180
```

Run again with `-UserArguments '--settlement-growth-acceptance --capture'` and a
separate log to save six growth stages, thirteen era specimens and five stress
stages. `timing.json` and `capture.json`, under
`artifacts/settlement-growth`, remain separate. Never use a capture run's frame
times as performance evidence: screenshots synchronize and read back the GPU.
The runner must report exit 0; the log must contain the final acceptance summary
with zero failed checks, and no script/engine errors. A frame-limit or timeout
without that summary is not a pass.

For targeted diagnosis, `--stress-only` runs just the 96/128/129 boundary sequence.
Combining that with `--capture --isolate-ground` also captures shared stage and
prop visibility separately from the ground frames and procedural halo uniforms.
These images deliberately disable layers and are diagnostic views, not player
presentation. Independent era and stress specimens clear painted ground between
wholesale record resets; the main persistent growth sequence never clears it.

The report includes refresh submission time, queued slice p50/p95/max, peak queue
size, cumulative renderer job statistics, the complete home ground paint report,
steady and paused-camera frame samples, memory, and draw
calls. Frame timings include the host's frame scheduling and presentation; they
are comparative observations, not a portable FPS guarantee. The cooperative
time budget cannot preempt an individual mesh job, so inspect `max_job_usec` as
well as the job-count cap. New visible patches in a larger city can legitimately
need building; the zero-rebuild camera assertion is scoped to this retained view.

This fixture isolates settlement geometry on flat ground. It does not certify
all terrain variations, full-campaign simulation throughput, demographic growth,
construction cost accounting, or an uninterrupted 3000-year playthrough. Those
belong to the focused model tests and separate campaign benchmarks. Generated
images, reports, imports, UIDs and `override.cfg` are excluded from source delivery.

## Verification checkpoint

The baseline combined runtime at `8f1a0d8e894401a8fec89e3b5edf33a978529982` includes
the model growth policy, persistent patch renderer, incremental layout work and
camera ground tiles. A private GPU timing run on Godot 4.7.2, Compatibility
OpenGL, RTX 4090, at 1600×900 passed 169/169 checks. The process exited 0;
its command line named the isolated acceptance worktree and Dummy audio.
The separate capture run passed 193/193, saved 24 images, and exited 0 with no
script or engine errors. Visual inspection covered the founding shelters,
inherited plus later construction, the year-3000 building, and the 129-plot view.
Building counts exclude hidden cache roots and include the actual architecture
kit batches as well as early/organic models and fallback roofs.

| Mutation | Old active plot patches retained | Old plot patches replaced | New plot patches |
| --- | ---: | ---: | ---: |
| 96→128 plots | 14 | 0 | 4 |
| 128→129 plots | 18 | 0 | 1 |
| Repair plot 129 | 18 | 1 | 0 |

Initial steady, paused pan/zoom and 129-plot steady refresh p95 were 0.914,
0.886 and 1.146 ms respectively. Each interval performed zero geometry and
ground texture rebuilds. Frame p95 was 20.2–20.4 ms under this host's scheduling.

Growth is not yet free of frame hitches. Adding plot 129 took 160.7 ms to submit,
including 130.1 ms in the ground wrapper; its raster report measured 114.6 ms.
Repair submission took 146.4 ms, with 112.1 ms raster time. Maximum observed
individual mesh job was 32.2 ms and layout step 34.4 ms. The two-job cap and
cooperative budget bound work counts, but cannot preempt these individual jobs.
These are measured costs, not pass/fail latency thresholds.

The ground-layer isolation probe identified the former broad polygonal fields
as the procedural cultivation halo. They persisted with stage/props hidden and
disappeared when only `sg_halos` was zeroed. The combined runtime disables that
home halo and draws recorded cultivated ground. Independent prepared-era resets
explicitly clear the ground cache; ordinary persistent growth does not.

This delivery adds only the probe scene, its script, and this document. It changes
no runtime source or save schema. It must run with isolated userdata and does not
certify a running player process has loaded any integration commit.
