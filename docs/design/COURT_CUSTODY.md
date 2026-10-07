# Arrest and detention in the court

## Behavior

Successful detention previously produced acknowledgments and a solo led exit.
Physical custody now lets two eligible adult supporters approach the
adjudicated person, take hold of them, secure visible wrist bonds and escort
them through the room's actual exit when the engine requires departure.

The exact successful result controls the performance. A known person bound for
questioning remains alive and visible in court with their bonds; a subsequent
successful release removes those bonds. Failed orders, absent targets and
unreachable named actors retain the existing factual outcome without inventing
a different person to perform it. The scene never changes detention, population,
injury, officeholding or save state.

Physical grips and cord placement must follow the victim's rendered bone
transforms captured inside their skeleton modifier. Contact tests against a
restored standing pose do not verify what the player sees. Floor routes must
remain clear of furniture, and the camera must show participants and restraints.
Gore settings do not suppress this non-graphic scene. Children do not participate;
reduced motion goes directly to the authorized bound or departed state.

Skip, close, audience reset and natural completion must release temporary
modifiers, movement and camera ownership. Persistent bonds belong to the bound
person only and must disappear on release or stage destruction. A completed
escort must not start another solo exit afterward.

## Development record

Worktree: `C:/Users/sjpur/tt-people-grown-land`.
Branch: `codex/court-arrest`. Updated base: `253ec3b4`.
Source checkpoint: `c963e4ab`; combined with main `73e15df0` at `01324831`.
No player or editor process is restarted for tests; private GPU
review and isolated headless tests use the explicit worktree path.

The new `court_custody_stage.gd` owns approach, grip, binding, spaced escort
and restoration. `court_custody_grip.gd` caches the victim's rendered arm and
wrist transforms and places both guard hands and the visible cord from those
frames. Adult guards are preferred; an explicitly adjudicated actor remains
the first supporter. The modal checks successful typed/menu/person outcomes
and exact target IDs, and the stage holds dialogue, departure and camera control.

Final combined-source validation passed all 32 checks in report 80: custody
routing (12), imported-rig grips, restraints and convoy movement (8), existing
flogging routes (11), and the initialized GPU probe parser (1). There were zero
errors, failures, skips or orphan nodes. Reduced motion preserves the authorized
final bound/departed state; releasing a person during binding cancels it cleanly.
An execution after detention removes the prior restraint presentation first.
Report 77 also verifies that a raw child record without an age cannot become
an adult supporter through cast normalization.

The first rendered review caught overlapping escort bodies despite clear
furniture paths. The corrected convoy follows checked paths at a common speed,
opens a 0.75 m following gap, clears actors only at the actual outside endpoint,
and returns guards separately. A focused unequal-path and corner regression
passes in report 78; the enhanced GPU probe also checks visible party clearance.
Two seconds without any convoy progress completes the authorized custody
outcome and releases the scene rather than holding the court indefinitely;
report 79 covers this fallback. Normal rendered acceptance must finish naturally
without that fallback.

The private GPU probe is `tests/court_custody_preview.tscn`. Generated frames,
audit data and test logs live under `artifacts/court-custody/` and are excluded
from source commits. No saved fields or simulation rules change.

Final private GPU acceptance passed all three actual-order cases on the merged
source: typed arrest of a 45-year-old summoned official, nonterminal known-person
binding followed by release, and binding skipped after the cord appears followed
by release. The normal cases completed without the stall fallback. Worst sampled
grip error against the independently captured rendered arm was 0.84 mm; cord
placement stayed attached to the rendered wrists. All 85 escort floor-clearance
samples passed. Visible party spacing stayed at least 0.50 m during the initial
grip-to-escort transition, and both guards returned exactly to their saved
positions. The final escort frame clearly separates all three full figures.
Target identity, living status and population were preserved in every case;
release removed both pose modifier and cord. PID 46772 exited 0 with no runtime
errors, and the private test did not interrupt the player.

Evidence: `audit.json`, `grip.png`, `binding.png`, `escort.png`,
`held-visible.png`, and `skip-cleanup.png` under the artifact directory above.
Validation uses prepared chapter-03 fixtures and the actual offline order reader;
it does not claim a live model response or exhaustive review of every court era.
A normal restart through the canonical launcher loads the integrated scripts.
