# Court presence sound

READY for combined integration. Worker branch `codex/court-presence-sound`, based on `066cac48f43c43312d5d2a2fa8892e8f36e2399a`, in `C:/Users/sjpur/.codex/worktrees/court-chapter-assets/TomorrowandTomorrow`.

The god's existing synthesized timbres now have a short hush, distinct attack, quieter bed beneath the words, and a finite release measured from the actual line duration. Wrath attacks in .24 seconds after a .18-second hush and settles from -11 to -22 dB; favour rises in .55 seconds after .08 seconds and settles from -14 to -23 dB; neutral awe rises in .70 seconds after .12 seconds and settles from -19 to -27 dB. Tails last 1.60, 1.05 and 1.20 seconds respectively. The stable portion of the existing cached swell supplies the timbre, so two slow attacks no longer multiply together. A continuing same-tone line extends the bed without retriggering the loud entrance. The room's low bed also dips during the hush.

Room reverb now follows the actual selected chapter and physical indoor/floor facts: open air, timber, courtyard, masonry, record chamber, office and furnished conference room have progressively appropriate damping and room size. Modern offices no longer inherit the same long, wet hall response as stone halls. Existing construction-cap selection remains upstream; calendar year alone never changes acoustics, and no new instruments, technology or events are invented.

The presence uses one replaceable frame-clock envelope instead of a delayed stop callback. Close/hide cancels bed, crowd, duck and music fades, invalidates unfinished voice jobs and clears queued cues. The execution music fade is now owned too, preventing its old stop callback from silencing a reopened court. Close immediately stops court audio, matching hidden-stage behavior. All audio still passes through the existing Court volume/mute bus; existing panning, music-stop, wrath impact and engine-provided reaction hooks remain authoritative.

Changed production file: `scripts/hud/court_sound.gd` only. Dedicated regression: `tests/test_court_presence_sound.gd`. No save schema, simulation, ledger, stage, shader, room asset or garment changes. No new audio asset, bus, pool or stream-cache key. Existing two cached presence timbres are reused.

Validation: Godot 4.7.2, explicit worktree path, headless and `--audio-driver Dummy`; no user audio or GPU window. Four suites passed **48/48**, zero errors/failures/skips/orphans:

- `test_court_presence_sound`: 8, including actual cached waveform sample peak/click checks, measured speech-bed energy reduction, all three envelope boundaries, repeated lines, close/reopen with unfinished voice/impact/music fades, actual reverb settings, unknown action silence, mute and hidden-stage cancellation.
- `test_court_sound`: 25 existing synthesis, voice, panning, hush and music tests.
- `test_court_sound_stage`: 1 real-modal panning test, 5.7 dB left and 5.8 dB right. Its existing headless depth-of-field warning is unrelated to sound.
- `test_court_exec_sound`: 14 existing execution track and reaction checks.

Evidence: `artifacts/presence-sound-final-tests.log`, `reports/report_10/results.xml`. Invocation uses `--script res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a <each suite above> -c --ignoreHeadlessMode`.

Limits: waveform checks establish levels, clean boundaries and event/cancellation behavior, not a subjective speaker/headphone listening verdict. Combined real-time audiovisual review belongs to the integrator. The earlier parser-only failed run was repaired and is not counted as acceptance. This worker has not merged main or launched the player game. Generated caches/imports and unrelated changes remain excluded.
