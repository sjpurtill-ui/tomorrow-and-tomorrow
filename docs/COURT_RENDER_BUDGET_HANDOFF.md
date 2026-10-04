# Court figure render allocation fix

Branch `codex/court-render-budget`; base `7aa02e1653064b31e67e11d8c309f25138847887`.
Worker checkout: `C:/Users/sjpur/tt-court-interior-seating`.

The actual year-3000 audience exhausted the Compatibility renderer's shader-instance buffer. The first reported stack was `CourtActing.library()` freeing its temporary glTF scene, but that animation file contains only the rig and one tiny stub mesh. Scene destruction flushes pending renderer instance updates, so that stack did not identify the allocation owner.

A business-dressed figure assigned per-instance shaders to 18 source body/clothing pieces, then hid those pieces and added four visible merged meshes. Two carried props were also prepared. The result was **24 shader-backed mesh instances per figure**, although only four body/clothing meshes were drawn. Hidden meshes still retain shader-instance allocations. Godot's [Compatibility allocator](https://github.com/godotengine/godot/blob/master/drivers/gles3/storage/material_storage.cpp) reserves a complete instance-uniform block for each such mesh; raising the project buffer limit would conceal the duplicated ownership.

`court_figure_3d.gd` now assigns draw materials only to the merged representation when merging is enabled. Original geometry, skin, morphs and rig remain available for redressing. Stale overrides are released on hidden source parts, on merged groups omitted by a new outfit, and when returning to the unmerged representation. The two carryable props keep their materials so they can appear without a rebuild. A merged business figure now uses **6** shader-backed mesh instances with no inactive source allocations.

No animation-library conversion, shader source, renderer limit, wardrobe asset, camera, stage or simulation changes are included. Save compatibility is unchanged.

## Validation

- Baseline new regression fails: 24 instances versus the expected maximum of 6, including 18 inactive source pieces.
- Budget, acting and motion suites: **63/63 pass**, no logged engine/script errors or orphans (`artifacts/court-render-budget-tests.log`).
- Final four budget regressions plus six gore tests: **10/10 pass**, no logged engine/script errors or orphans (`artifacts/court-render-budget-final-tests.log`). Tests cover redress/unmerge cycles preserving skeleton and player identity, rest transforms, expression morphs, walking, carried-prop materials/light, and removal/restoration of a merged clothing group.
- Actual audience GPU probe, unchanged larger cast from the base commit, year 3000 at **1920×1080 and 1280×720**, both room and speech states: **PASS**, no shader overflow or engine/script errors. Existing Compatibility depth-of-field warning remains. Private probe PID 57952 exited 0; GPU slot released.

GPU log: `artifacts/court-render-budget-modal-3000.log`. Four captures: `reports/court_evolution_modal/audience-3000-{1920x1080,1280x720}-{room,speaking}.png`. Generated captures/logs are excluded from Git. The probe is diagnostic, not the player's running game.

```powershell
& tools/run_isolated_gpu_probe.ps1 -Godot (Get-Command Godot_v4.7.2-stable_win64_console.exe).Source -Project C:/Users/sjpur/tt-court-interior-seating -Scene res://tests/court_evolution_modal_probe.tscn -LogFile C:/Users/sjpur/tt-court-interior-seating/artifacts/court-render-budget-modal-3000.log -UserArguments '--year=3000' -TimeoutSeconds 240
```

Only the figure material lifecycle and new regression file need integration. Other workers' FigureLook, room, roster and wardrobe edits are independent. This fixes the demonstrated buffer overflow; it does not establish the cause of an earlier, separate native GPU crash.
