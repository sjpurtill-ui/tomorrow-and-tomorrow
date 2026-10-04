# Court figure outline depth

Worker branch `codex/court-figure-ink`, base `e5c5a8b84adda017cc6adea65cda55afba748952`, checkout `C:/Users/sjpur/tt-court-interior-seating`. The base includes the sewn collar repair and court shadow checkpoint.

The figure outline expanded back-facing triangles only in screen XY, at their original depth. At concave chest/armpit folds this let the outline overdraw the painted cloth, appearing as black triangular holes. Turning off ink removed these marks, confirming that the cloth itself was continuous.

Both `court_figure_ink.gdshader` and `court_figure_uber_ink.gdshader` retain their original 1.7px screen-space expansion and recess only its depth by one outline-width in view space. Pixel conversion uses projected W for perspective/orthographic cameras and absolute vertical focal scale for flipped render targets. No new uniforms, materials, cache entries, resources per figure, body/garment meshes, animation tracks or save fields are introduced. Figure3D setup, material ownership and walking hooks are untouched.

## Validation

- Godot4.7.2 Compatibility, private desktop: **28 merged pose/camera combinations**, each rendered with legacy, fixed and no-ink passes, **84 images**. Medieval/business clothing, four adult/old body variants, sit, seated speech, standing speech, walking, kneel and cross-sit at two angles; four detailed closeups. PID32108 exited0, no logged errors.
- The fixed business male seated closeup's automated image regression measures chest/armpit patches against the no-ink reference: **164 unwanted dark pixels → 2**. Shoulder silhouette patches remain **542 → 542**. The diagnostic asserts at least85% internal-mark reduction and at least95% retained silhouette, with a reproducing legacy baseline.
- **Four additional unmerged orthographic closeups**, again legacy/fixed/no-ink (**12 images**), exercise the separate non-merged shader and orthographic depth conversion. PID81204 exited0, no logged errors. Corrected clothing and retained silhouettes visually inspected.
- Full-body sitting, walking and cross-sit samples reviewed: dark business shoes remain dark, clothing contours remain outlined, and collar interiors retain cloth color. The figures in these captures predate the independently owned walking-hand-clearance follow-up.

Logs: `artifacts/court-ink-final-poses.log`, `artifacts/court-ink-final-unmerged.log`. Captures: `reports/court_figure_ink/merged/` and `reports/court_figure_ink/unmerged-orthographic/`. Generated files are excluded from Git.

```powershell
& tools/run_isolated_gpu_probe.ps1 -Godot (Get-Command Godot_v4.7.2-stable_win64_console.exe).Source -Project C:/Users/sjpur/tt-court-interior-seating -Scene res://tests/court_figure_ink_probe.tscn -LogFile C:/Users/sjpur/tt-court-interior-seating/artifacts/court-ink-final-poses.log -TimeoutSeconds 240 -QuitAfterFrames 30000
# For the second path, add -UserArguments 'collar-only unmerged orthographic'.
```

The quantitative patches are intentionally bound to the named fixed closeup; update them if that diagnostic camera/pose changes. Small subpixel marks can remain. This does not repair genuine cloth/body intersections or certify every possible pose. Forward+ was not rendered. Initial experimental normal extrusion and a wrong-sign projection candidate were rejected; neither is in production. Only the two figure ink shaders overlap production integration; the diagnostic is separate from the walking worker's pose harness.
