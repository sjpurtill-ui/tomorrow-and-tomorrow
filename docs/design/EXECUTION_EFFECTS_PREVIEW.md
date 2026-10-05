# Execution effects preview — October 5, 2026

Status: user-approved October 5; integrated with main 5740f208 in runtime 182af02e.
Combined validation: 40/40 tests pass, zero errors/failures/skips/orphans (report 12).
Branch: codex/execution-effects. Base: 0b0f6c5b5b992867091d5fad7edc7ab0c937007a.
Worktree: C:/Users/sjpur/.codex/worktrees/food-folio/TomorrowandTomorrow.

Beheading blood now originates at the rendered torso stump, follows its translation
and rotation, and loses pressure into downward runoff. The existing tall repeating
jet and front-row spray are bypassed for this method. The body collapses sideways;
the head rolls a short distance and remains on the floor without the staged blink.
The generic named-target head flight no longer treats a floor mark as a pot.

Fire now lasts through a short struggle and a heavy collapse, with body-attached
flames, rising smoke, progressive patchy scorching, and subdued fixed embers.
The ash-crumble, smoke-ring and hand-warming punchline are removed from this act.
Its sound cues follow ignition, steps, collapse and lingering crackle.

Ownership: court_exec_stage.gd, court_execution_effects.gd, court_director.gd,
court_figure_gore.gd, court_gore_foley.gd, court_figure_uber.gdshader; regression
and isolated preview tests. Shared-file integration requires review of the court
stage/director, figure shader and sound schedule. No simulation hotspots changed.
The first two authored axe strokes and broader court art remain as before.

Validation: 37/37 tests, zero failures/errors/skips/orphans (report 9), covering
court execution stage, sounds, and figure gore. New regressions use an actual
split figure, move/rotate the torso, check wound attachment and falling pressure,
verify that the rolled head remains, and test scorch amounts and skip cleanup.
The old terminal-order fixture now summons an available officeholder rather than
assuming a debug petition can be generated in every opening state.

Private GPU captures: behead PID 68296 and fire PID 39408, both exit 0, no engine
or script errors. Beheading samples check source attachment within 0.03m; both
captures verify that effects disappear at scene end/skip. Images are captured in
memory and written after playback, avoiding PNG encoding slowing authored clips.
The expected Compatibility renderer depth-of-field warning remains unchanged.
The canonical player PID 37788 was left running and untouched.

Reproduction from this explicit worktree:
- Headless GdUnit: test_court_exec_stage.gd, test_court_exec_sound.gd,
  test_court_figure_gore.gd, with --audio-driver Dummy and --ignoreHeadlessMode.
- tools/run_isolated_gpu_probe.ps1, scene
  res://tests/court_execution_effects_preview.tscn, --method=behead or --method=fire.
- Local evidence: artifacts/execution-{behead,fire}.log,
  artifacts/execution-tests-final.log, artifacts/execution-preview/*-preview.gif.

Save compatibility: unchanged; presentation only, no ledger, death adjudication,
order parsing, casualties, population, save schema, or gore eligibility changes.
Existing mild/off and child exclusions remain authoritative. Graphics are authored
effects, not fluid or burn simulation. Review clips are silent; sound scheduling
and generated cues are covered by regression tests. Generated frames, GIFs, caches,
user data, and unrelated imported assets are excluded from the commit.

## Burning voice follow-up

The user rejected the synthesized scream as breathy singing. It is replaced
with recorded male/female performances (CC0; assets/audio/court/SOURCES.md),
beginning 0.1s past ignition at -5dB. The male recording lasts about 3.5s; the
female recording is a short natural 1.14s scream. Neither is looped or stretched.
Selection follows the victim's voice register, with at most 2% seeded rate
variation. These are two stock performances, not unique voices per individual.
The fire act's synthesized crowd reactions, cough and muttered aside are omitted
to remove the competing breathy overlay; other court scenes remain unchanged.
The victim's scream is independent of crowd dread,
respects gore-off, and uses the existing execution cancellation epoch and audio
pool so skipping stops queued/playing vocals and rejects late worker results.
No new room-reaction choice can make bystanders randomly scream this way.

Audio follow-up validation: 17/17 sound tests pass, zero errors, failures,
skips or orphans (report 11). Coverage includes victim attachment, ignition-relative timing,
duration, male/female recording distinction, deterministic output, bounded peaks,
edge fades, PCM import format, absence of the fire crowd overlay, gore-off and
stale-job cancellation. These checks do not establish perceived audio quality.
Two headless
6-second audio examples contain ignition, the scream and fire pops; no speaker
or player session was used. Reproduce with --headless --audio-driver Dummy
--path <this worktree> -s res://tests/court_burn_voice_preview.gd.
Examples: artifacts/execution-preview/burn-recorded-{male,female}.wav.

Additional shared ownership: court_sound.gd and court_reactions.gd. Audio previews
remain local. The user approved this follow-up and requested merging the full execution branch.
