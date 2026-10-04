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

The final ground tip `be859720da6a029a47326b26893bdeeda04facd9` also keys
paint by the actual contributing inputs. The targeted GPU timing probe passed
33/33 and exited 0 without script/engine errors. At 129 plots, damage and repair,
the home signature stayed unchanged and reused the 128-plot paint. Plot geometry
still changed where required, retaining the same 14/18 inherited roots and
replacing one repair patch.

| Final targeted mutation | Submission ms | Ground call ms | New home raster |
| --- | ---: | ---: | --- |
| Add plot 129 | 22.263 | 7.646 | No |
| Damage plot 129 | 17.802 | 6.980 | No |
| Repair plot 129 | 17.348 | 6.489 | No |

The 129-plot steady refresh p95 was 1.283 ms with zero geometry/ground churn.
The maximum queued builder was 10.470 ms and incremental layout step 16.600 ms.
The cold, direct 96-plot initialization still took 820.803 ms, including
511.839 ms in the request path. With no existing root, the first refresh bypasses
the incremental layout primer and can solve the full layout synchronously.
This startup limitation is separate from the measured incremental updates;
these results do not certify hitch-free initialization or hard frame deadlines.

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

In this baseline, adding plot 129 took 160.7 ms to submit,
including 130.1 ms in the ground wrapper; its raster report measured 114.6 ms.
Repair submission took 146.4 ms, with 112.1 ms raster time. Maximum observed
individual mesh job was 32.2 ms and layout step 34.4 ms. The two-job cap and
cooperative budget bound work counts, but cannot preempt these individual jobs.
These are measured costs, not pass/fail latency thresholds.

The raster optimization at `292c6afa2a248deae1276c18f0a5847889099366`
passed the same full GPU timing probe, 169/169, with the same patch retention.
Its separate targeted stress capture passed 38/38, saved five images and exited
0 without script/engine errors. The 129-plot image was visually inspected.
It resolves brush state once per line instead of for each stamp. Observed
before/after costs on this host were:

| Measured operation | Baseline ms | Optimized ms |
| --- | ---: | ---: |
| Add plot 129: submission | 160.653 | 42.148 |
| Add plot 129: home raster | 114.639 | 20.421 |
| Repair plot 129: submission | 146.433 | 37.509 |
| Repair plot 129: home raster | 112.105 | 19.999 |
| Maximum individual mesh job | 32.238 | 18.990 |
| Maximum incremental layout step | 34.414 | 17.385 |

These were separate GPU runs; changes in unrelated mesh/layout timing show
host variation, so the entire observed ratio cannot be attributed to the raster
change. The ground worker separately measured the raster in the same process:
129 plots 114.765→47.703 ms and repair 116.082→48.260 ms, with identical complete
image bytes at 96, 128, 129, damage and repair. Optimized steady refresh p95 was
1.409 ms initially, 0.860 ms while panning/zooming, and 1.295 ms at 129 plots,
again with zero geometry or ground texture rebuilds. A 42 ms mutation or a
19 ms indivisible job can still exceed a frame budget; this is not a claim of
hitch-free construction or a hard 2–4 ms deadline.

Each stage also records the home ground signature before and after refresh.
The `ground` object is the last completed raster report; its `build_usec` must
not be counted as fresh work when `ground_signature_changed` is false. Current
ground-call cost is separately available in `stats.refresh_costs.ground_usec`.

The ground-layer isolation probe identified the former broad polygonal fields
as the procedural cultivation halo. They persisted with stage/props hidden and
disappeared when only `sg_halos` was zeroed. The combined runtime disables that
home halo and draws recorded cultivated ground. Independent prepared-era resets
explicitly clear the ground cache; ordinary persistent growth does not.

This delivery adds only the probe scene, its script, and this document. It changes
no runtime source or save schema. It must run with isolated userdata and does not
certify a running player process has loaded any integration commit.
