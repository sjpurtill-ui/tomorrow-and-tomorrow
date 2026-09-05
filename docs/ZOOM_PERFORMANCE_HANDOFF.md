# Zoom terrain streaming — September 5

Worker `C:/Users/sjpur/tt-zoom-performance`, branch `codex/zoom-performance`,
base `de1d41d2e933d61e448b14a9ad21353603ecfd67`.

## Cause and change

The regional builder ignored new camera requests until the old mesh finished.
It could therefore spend seconds finishing and installing an obsolete small
patch after a zoom-out. The world mesh was hidden at camera sizes <=280 whenever
any regional patch existed, even when that patch did not cover the view.

Latest snapped view now cancels obsolete work. A 33x33 geographic coverage pass
uses the same authoritative height/color samplers, followed by the original
161/201/257/385-resolution mesh. Full detail is not disabled. Stationary sampling
budget is 5ms, moving-camera budget remains 2.5ms. Four completed meshes are
cached, including their exact river-height fields. No unbounded job queue.
The world mesh remains visible outside the installed regional rectangle; a
world-material-only fragment cutout prevents overlap within that rectangle.
Fog, art sampling, geography, markers and simulation state are unchanged.

## Corrected comparable measurements

GPU: RTX4090, default OpenGL Compatibility renderer, 1280x720 window with normal
1920x1080 content scale. Identical seed184271 and camera sequence at population
120 then1,000,000. Baseline detached diagnostic checkout at the base commit.
Each stop has a360-frame timeout. No screenshots during timing. Coverage tests
actual camera-frustum corners at the focus plane, not the oversized desired
streaming rectangle. Initial experimental measurements were superseded because
PNG readback/encoding polluted frame costs and readiness accepted stale patches.

| Transition | Before full detail | After full detail |
|---|---:|---:|
| Initial size180 | 1.966s | 1.264s |
| Close size1.2 | >7.232s timeout | 5.979s |
| Pan/zoom size40 | 6.201s | 1.238s |
| Close size0.6 | >7.239s timeout | 6.300s |
| Repeat180, population1m | 6.801s | 0.050s |
| Repeat1.2 | >7.259s timeout | 0.080s |
| Repeat40 | 6.619s | 0.040s |
| Repeat0.6 | >7.258s timeout | 0.081s |

Uncovered frames: before0–338 per stop; after0 throughout. New pan coverage
arrived in97ms. Median frame time remained approximately20ms; p95 after was
20.1–25.7ms versus20.2–20.3ms before. This improves fill-in and revisit latency,
not every frame spike: initial transition max remained113ms. Cold fine-detail
sampling still takes seconds. The million-person fixture is synthetic, not a
loaded mature campaign. No player's camera/save was used or changed.

## Verification and limitations

Five terrain-builder/close-job/mesh cases pass. Expanded camera runtime probe
passes accumulated smooth zoom, anchor, no overshoot, four north resets, fast
zoom, retained patch, obsolete-job cancellation, coverage-first density,
four-entry bound and exact cached-mesh reuse. Separate GPU captures inspect
terrain transitions/final views; performance runs omit capture overhead.
The existing navigation profile can exercise repeated smooth wheel inputs.

Early disposable GPU probes accidentally played score; the integrator stopped
those exact test processes. All subsequent GPU runs use `--audio-driver Dummy`,
master-bus mute, hidden windows, guarded artifact output and explicit process
verification. No player process was stopped. This incident is not a game-audio fix.

Shared changes: local_terrain terrain fields, regional request/install methods,
terrain shader and terrain-only part of _update_scale_lod. No city-intel marker,
daily chart sampling, scouting UI or military edits. Save format unchanged.
Integrator must combine/test main and preserve the current session; a saved
restart is needed to guarantee the new renderer scripts are loaded. Do not
claim this worker commit shipped before that integration.
