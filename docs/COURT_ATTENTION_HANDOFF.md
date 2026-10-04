# Court attention and ambient timing

Worker: `codex/court-attention`, `C:/Users/sjpur/tt-court-interior-seating`, base `05c9ecce98486738b60236844dc51dc4dcdc1aba`. Owned source: `court_stage.gd`, `court_director.gd`, `court_acting.gd`; focused tests and a private capture fixture. The canonical checkout was not edited or launched.

## Behavior

- Conversation focus follows the current speaker. Short director glances retain their duration, then return to the conversation or ordinary idle attention. A newer focus supersedes old attention; hidden, detached or freed gaze targets release. Existing direct persistent-look callers keep their API behavior.
- Speakers begin immediately; listeners notice in a short deterministic sequence ordered by actual room distance. The live god-voice response is scheduled once, rather than the stage preempting the director's later ripple. Standalone director behavior and its other seeded reactions remain intact. Reduced motion omits the listener delays.
- Delayed ordinary looks cannot steal a newer speaker's attention. Explicit divine/order/direction/execution gaze beats remain authoritative. Held, prop-specific and authored movement performances reject routine conversation resets. Speech mouth/face delivery remains independent.
- Ambient loops skip actors who are speaking, walking, reacting or performing a held act, and wait during executions. Missed loops are rescheduled rather than replayed in a burst. Initial held ambient states retry after an occupied actor becomes free. Overlapping hushes keep the longest deadline for both stage and actor.
- Pre-tree focus requests share one deferred connection and retain only the newest request. Focus expires on the actor's existing paused/visible animation clock; no new per-frame solver or animation resource copies were added.

No source animation, rig, garment, walking cadence, turning interpolation, storm-out sequence, execution choreography, adjudication, population or save schema changed. Saves remain compatible. These three shared court files were assigned exclusively to this worker; the integrator owns delivery to main.

## Verification

- Baseline source from `05c9ecce`, with the eight original-API regression cases: **18 failing assertions**, zero engine/test errors, exit100. `artifacts/court-attention-baseline.log`, `reports/report_37`. The baseline source was restored only temporarily in the worker's three owned files, then the exact working bytes were restored.
- Combined corrected matrix: **160/160 tests, 8/8 suites**, zero errors, failures, skips or orphans; no engine/script errors, exit0. Suites: attention (11 at that checkpoint), acting, motion, director, etiquette, set-stage, execution stage and pose clearance. `artifacts/court-attention-combined-final-tests.log`, `reports/report_39`.
- Final focused suite: **12/12 pass**, zero errors, failures, skips or orphans, no engine/script errors, exit0; includes pre-tree supersession and hidden/departed target coverage. `artifacts/court-attention-final-focused.log`, `reports/report_42`. Earlier pre-tree attempts correctly exposed duplicate signal registration and were fixed with one latest-request slot.
- Actual modern audience headless fixture completes all four attention phases. `artifacts/court-attention-probe-headless.log`.
- Final tracked private GUI process **PID64524, exit0**, no engine/script errors, **295 JPEG frames / 10.02 seconds** (about29.4fps). `artifacts/court-attention-gpu-final.log` and `.runner.txt`. The existing Compatibility depth-of-field warning is unchanged. Process inventory confirmed no remaining Godot game/test process; GPU reservation was released.

Final visual evidence (ignored, not source assets):

- `reports/court_attention/attention-replay.gif`: timestamp-paced normal-speed replay.
- `reports/court_attention/attention-contact-sheet.png`: onset, speaker switch, god response and recovery samples.
- `reports/court_attention/timing.json` and `frame_*.jpg`: full-resolution source sequence and actual elapsed times.

The live petition fixture has a small, tightly framed roster and some occluded listeners. Reviewed samples show eased, readable turns and no pose disruption; this is not evidence of every dense crowd configuration. Deterministic tests separately cover listener staggering, stale callbacks, protected actions, short-glance return, freed/hidden targets and overlapping hushes. The first private startup failed natively before OpenGL/project code (PID39260, exit3221226505); a separate console/PNG attempt completed but its capture-write overhead reduced sampling to7.6fps, so neither is the accepted normal-speed evidence. Their logs remain distinct.

Generated imports, UIDs, captures, reports and the pre-existing local early-settlement test are excluded. That unrelated test's SHA256 remains `3AD943645A68BE6629B3E3555E4C125EF2F44DB04CC2FE4C160E0A3408D15B4E`.
