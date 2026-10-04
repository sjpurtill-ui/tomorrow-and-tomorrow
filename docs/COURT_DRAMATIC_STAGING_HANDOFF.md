# Court dramatic staging handoff

Worker: `codex/court-dramatic-staging`, `C:/Users/sjpur/tt-court-interior-seating`, base `066cac48f43c43312d5d2a2fa8892e8f36e2399a`. Owned source: `court_director.gd`, `court_stage.gd`, `court_camera.gd`, plus one focused suite and actual-modal replay fixture. The canonical checkout and player game were not touched.

## Behavior

God address, favour and wrath have a short anticipation, one eased composition, a still hold, and a return to the room. The addressed person stays on the room's established camera side; the medium composition leaves their hands visible, and cowering keeps the whole body in frame until the existing 2.5-second kneel has finished. Favour's earlier envy cutaway no longer interrupts its camera move; the envy performance itself remains. No physical beat, animation track, ledger result, or execution choreography changed.

The stage snapshots every queued camera beat's priority and deadline. Cosmetic presence shots (including comic cutaways) expire after a newer speaker, presence, command, close or departure. The original physical callbacks remain independent. Executions retain priority over decorative movement and shake. Explicit invalid, leaving, hidden or freed targets neither acquire camera priority nor redirect special lighting onto the main petitioner. Untargeted god speech still addresses the main petitioner.

Reduced motion uses the same meaningful static framing with no camera travel or shake; enabling it during existing motion settles the camera. The new address shot also survives viewport reframing through the existing camera API.

## Validation

Godot 4.7.2 headless:

- Focused final lifecycle suite: **11/11**, no errors/failures/orphans, report49, `artifacts/court-dramatic-lifecycle-final.log`. Covers camera hold/insets, seated/standing heights, reduced-motion toggle, explicit target agreement, stale callback cancellation, captured priority, freed targets and all four retained execution priorities. Original cower/defy beats and timing are asserted separately.
- Existing Director, attention, Stage, camera composition, set-stage and execution suites: **122/122** passed in report47, `artifacts/court-dramatic-combined.log`. That run's three new-test failures were fixture mistakes interpreting raw versus lowered director beats; those were corrected and rerun in the focused suite. Earlier fixture runs remain distinct from accepted evidence.
- Actual 1280×720 year3000 modal replay: **PASS**, 717 sampled frames over24 seconds, five phases, `artifacts/court-dramatic-replay-headless.log`. This verifies runtime routing and a still camera hold, not rendered appearance.
- Reduced-motion actual-modal replay: **PASS**, 718 samples/five phases, exit0, `artifacts/court-dramatic-reduced-headless.log`; every sample asserts the camera is stationary.
- `git diff --check` clean. Existing Compatibility depth-of-field warning is unchanged.

Root owns the final combined GPU review with its new light and sound. No GPU process was started for this checkpoint. The exact new composition and interaction with the final effects remain a visual acceptance gate.

## Replay

Use `tools/run_isolated_gpu_probe.ps1` with the explicit worktree path and scene `res://tests/court_dramatic_capture.tscn`. User arguments: `--year=3000` or `--year=1400`, optionally `--reduced`. Allow at least90 seconds for initialization and the24-second sequence. The scene uses the real audience modal with explicit fixture responses (`blessed`, then `cower`); it does not adjudicate or mutate a campaign outcome.

It writes JPEG frames and `timing.json` to `reports/court_dramatic/<year>[-reduced]/`. Times: ordinary speech0s, god address2s, favour8s, wrath14s, new speaker21s. Review the camera's complete transitions at normal speed, especially the full-body hold through the kneel and the restrained recovery. The timing file records the shot, movement state, transform position and field of view for every sample.

## Integration

Presentation only; no save schema change. Shared files are the three owned court scripts above; root's CourtSet/effects/sound work is separate. Unrelated local image import metadata and `tests/test_early_settlement_visual.gd` remain excluded and preserved (test SHA256 `3AD943645A68BE6629B3E3555E4C125EF2F44DB04CC2FE4C160E0A3408D15B4E`). Generated logs/captures are local evidence, not source assets. Pushing this worker branch does not deliver it to canonical main.
