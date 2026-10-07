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
No player or editor process is restarted for tests; private GPU
review and isolated headless tests use the explicit worktree path.

The new `court_custody_stage.gd` owns approach, grip, binding, spaced escort
and restoration. `court_custody_grip.gd` caches the victim's rendered arm and
wrist transforms and places both guard hands and the visible cord from those
frames. Adult guards are preferred; an explicitly adjudicated actor remains
the first supporter. The modal checks successful typed/menu/person outcomes
and exact target IDs, and the stage holds dialogue, departure and camera control.

Twenty-nine focused behavioral checks passed across custody routing (12),
imported-rig grips and restraints (6), and existing flogging routes (11).
The initialized GPU probe parse check also passed. Reports 75 and 76 recorded
zero errors, failures or orphan nodes. Reduced motion preserves the authorized
final bound/departed state; releasing a person during binding cancels it cleanly.
An execution after detention removes the prior restraint presentation first.
Report 77 also verifies that a raw child record without an age cannot become
an adult supporter through cast normalization.

The first rendered review caught overlapping escort bodies despite clear
furniture paths. The corrected convoy follows checked paths at a common speed,
opens a 0.75 m following gap, clears actors only at the actual outside endpoint,
and returns guards separately. A focused unequal-path and corner regression
passes in report 78; the enhanced GPU probe also checks visible party clearance.

The private GPU probe is `tests/court_custody_preview.tscn`. Generated frames,
audit data and test logs live under `artifacts/court-custody/` and are excluded
from source commits. No saved fields or simulation rules change.
