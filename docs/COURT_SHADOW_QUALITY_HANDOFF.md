# Court shadow quality

Worker branch `codex/court-shadow-quality`, base `1ed8b1fc6c7ac894fd6bc0df57041e35d4d2ab24`, checkout `C:/Users/sjpur/tt-court-interior-seating`.

The seated-speech camera showed large teeth along straight window-sill shadows even at high quality. The previous two cascades assigned only 3m to the near map, leaving the wall behind the speaker in the coarse 30m map. Compatibility also expands the shadow frustum for a light's angular size without implementing its PCSS softening. This follows Godot's [cascade/frustum construction](https://github.com/godotengine/godot/blob/4.7/servers/rendering/renderer_scene_cull.cpp#L1958) and [Compatibility shadow sampling](https://github.com/godotengine/godot/blob/4.7/drivers/gles3/shaders/scene.glsl#L1282).

Only the court sun changes. High uses four cascades with 3.6m, 8.4m, 15.6m and 30m coverage; low uses two with 3.6m and 18m coverage. Existing maximum reach and normal/depth bias remain. Split blending is disabled, avoiding coarse-map contamination of close shadows. Angular size is zero only on Compatibility; the existing 1.2 degrees remains on renderers supporting PCSS. No project settings, renderer limits, shaders, meshes, simulation or save fields change.

## Evidence

- Godot 4.7.2 headless: new light-factory/quality-transition test plus chapter-set suite **10/10 pass**, no errors, failures or orphans (`artifacts/court-shadow-tests.log`).
- Private-desktop GPU comparison: chapters **0, 7, 9, 15**, both audience and seated-speech cameras, each with old high baseline, new high and new low. **PASS 4**, no logged engine/script errors; existing Compatibility depth-of-field warning remains. PID24112 exited0. Twenty-four images are in `reports/court_shadows/`; log `artifacts/court-shadow-final.log`.
- The fixture measures the chapter09 straight wall-shadow edge after removing camera projection slope and asserts both improved edge accuracy and retained contrast. Baseline edge RMS **6.4006px**, high **0.8171px**, low **0.7616px**. Shadow contrast **0.3527**, **0.3680**, **0.3586**, respectively. Camera transforms are asserted identical for each comparison.
- Same-camera candidates demonstrated that lower normal bias causes surface striping; it was rejected. The final captures retain actor/furniture shadows, including the outdoor camp and modern conference-room overview.

Reproduce with the private runner (not the player launcher):

```powershell
& tools/run_isolated_gpu_probe.ps1 -Godot (Get-Command Godot_v4.7.2-stable_win64_console.exe).Source -Project C:/Users/sjpur/tt-court-interior-seating -Scene res://tests/court_shadow_probe.tscn -LogFile C:/Users/sjpur/tt-court-interior-seating/artifacts/court-shadow-final.log -UserArguments '--reference --chapters=0,7,9,15 --acting-review --quality=high' -TimeoutSeconds 240 -QuitAfterFrames 30000
```

The quality levels now use four/two shadow passes instead of two/one; the existing automatic downgrade remains active. Validation used an RTX4090 Compatibility renderer, not a low-end GPU or Forward+. The pixel assertion is deliberately tied to the named chapter09 fixed camera and wall patch; update that fixture if its geometry/camera is intentionally changed. Some subpixel stair-stepping remains. Captures are stills, not a claim that all possible camera motion is alias-free. No global shadow settings are changed. CourtSet light/quality sections are the sole production-file integration overlap.
