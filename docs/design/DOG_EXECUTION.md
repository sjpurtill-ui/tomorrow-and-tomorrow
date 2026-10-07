# Death by hounds

October 6, 2026. Authorized task: finish and integrate the existing "feed them
to the dogs" animation with a frightening tone. Branch `codex/dog-execution`,
based on canonical and remote main `75806bff`.

## Performance

The existing dogs execution now gives the pack 2.2 seconds to approach before
the victim falls. Three dogs take separate ankle/cuff contacts and tug with
staggered phases while the victim claws at the ground, holds on briefly, loses
their grip and is dragged behind the court screen or through the doorway.
The baked goodbye wave is interrupted. Feeding stays at the completed drag
endpoint for 2.4 seconds; it cannot be cancelled by a competing fetch route.
The scene ends at court time 14.8 seconds, after a witness reaction and quiet
hold on the pack and trail. There is no returning bone, wagging reward,
drumroll, musical punchline or congratulatory audience response.

The adult victim uses the existing recorded male/female scream performances.
Snarls, falls, scrapes, tugs and diminishing crunches follow the visual beats.
Children cover their eyes; adults recoil and remain stricken. The menu calls
the method "Death by hounds"; its existing ID and accepted order wording stay
compatible. The existing mild/off settings and child vocal suppression remain.

## Implementation and bounds

`court_dog_attack.gd` owns only presentation contact state. It reads the posed
feet of the existing human rig. The animal modifier applies chest, neck and
head rotations after the authored dog animation, keeping the jaws at those
targets without changing root height or stretching bones. A maximum of three
dogs and 18 temporary ground marks is enforced. The court's cancellable tween
owns the contact clock; there are no independent attack timers.

Natural completion and skip both remove the additional dogs, contact controller,
ground marks and follow/aftermath tweens. The resident court dog regains its
original transform, clip position, mood and visibility. Pending bark/scratch
callbacks are cancelled so they cannot interrupt or outlive the performance.
No simulation, death, population, office, order, adjudication or saved-field
authority changes. All artwork, rigs and recordings are existing game assets.

## Validation and evidence

- Combined six-suite headless run: 78/78, report 53, no errors, failures, skips
  or orphans. Suites cover dog contact, executions/director, stage, sound,
  execution paths and execution set.
- The first GPU review found a real single-pass jaw gap missed by the initial
  fixture. The corrected fixture resets the authored pose before each modifier
  pass; all five contact tests pass (report 54), with a 3.5 cm limit across
  normal and transformed court frames. The correction was then rendered again.
- Final private GPU captures in court tiers 0 and 1: three contacts, maximum
  rendered gap 2.342/2.327 cm; victim travel 5.39/7.11 m; all 18 ground marks
  remain bounded. Both natural completion and mid-attack skip leave zero extra
  dogs, stop their tweens and restore the resident dog with zero home error.
- Contact, drag, aftermath, witness reaction, final hold and cleanup images
  reviewed in both settings. The final hold shows the pack beside the screen
  or doorway; the victim disappears before the feeding aftermath. In the
  longhouse, one witness briefly overlaps the second drag from this camera.
- Diagnostic scene: `tests/court_dogs_preview.tscn --tier=0|1 --fps=8` through
  the private-desktop runner with Dummy audio. Frames are buffered in RAM
  before PNG encoding. It calls the real stage API; it does not itself
  adjudicate an order. The old greeting bubble in that diagnostic is not
  evidence of conversation after a real death order.
- Actual order flow: `tests/court_execution_clip.tscn --only=dogs --tier=0`
  passes headless. `modal.office_order` returns `executed=true`, `removed=true`,
  `verb=kill`; the stage selects dogs, starts the execution and completes it.
  Exit 0 with no script or engine errors (`order-flow.log`).

Local evidence remains under `artifacts/dog-execution/`: `combined-tests.log`,
`tier0.log`, `tier1.log`, and per-tier `audit.json`, stills and sequence GIFs.
The invalid first draft is separate and is not counted as a passing review.
Generated captures, import caches, override settings and saves are excluded
from source delivery. The private probes have exited. The running player is
left alone and loads these scripts after a normal save, exit and relaunch.
