# Court flogging

The adjudicated flogging order previously played obedience and witness gestures,
but no physical punishment. Successful `maim` / `harm: beat` results now start a
separate nonfatal court performance through the actual audience modal.

## Behavior

Three available adult court supporters approach the adjudicated victim and
deliver four staggered blows each with clenched fists. The imported character rigs use bounded arm
IK to reach the victim's moving upper body; a hit is accepted only within 5 cm.
Targets and initial blood placement use chest/head transforms captured inside
the victim's skeleton modifier. Reading another skeleton later can return its
restored standing pose; that must never substitute for the visible kneeling pose.
Victim recoil, a worsening slump, sound and blood follow actual contact. Full
gore adds body stains and pooled floor splats; mild keeps the physical action
without blood, and off keeps the existing text outcome. Existing child gates
remain in force.

The performance uses the current cast and room paths. With only two eligible
supporters, two participate; an absent named actor or fewer than two reachable
supporters falls back to the existing outcome. It does not invent a substitute
for an explicitly adjudicated actor.

The victim remains alive according to the engine's existing injury decision.
The animation never changes the person, population, injury or save ledger, and
never enters the execution player's fatal cleanup. Typed orders, envoy menu
actions and known-person judgments share this presentation route. Departures
wait for completion. Ordinary speech and acting cannot interrupt participants.
The action owns a full-body camera frame that includes the surrounding floor;
queued conversation shots cannot crop away the punishment. Clicking to skip,
closing the modal and switching audiences release transient
modifiers and tweens and restore the cast, including a skip during arrival.

## Validation and delivery

Worktree: `C:/Users/sjpur/tt-people-grown-land`, branch
`codex/court-flogging`, base `8acdd002`.

Focused regression suites cover actual command/menu/person routes, identity,
adult supporters, visual settings, failure fallback, skip/close/arrival cleanup,
imported-rig contact under victim recoil, and the existing dog execution route.
`tests/court_beating_preview.tscn` exercises real typed and office-order paths in
a normal chapter-03 room using isolated QA data and the private GPU runner.
Generated images and audit data remain under `artifacts/court-beating/` and are
not source assets. Live player processes are never restarted by this review.

Final headless validation passed 20/20 checks: 11 actual-route/lifecycle/camera
cases, eight imported-rig/eligibility/blood cases and the GPU probe parse check.
Report 70 and `artifacts/court-flogging/camera-contact-rerun.log` contain the
results, with zero errors, failures, skips or orphans. The transformed-rig
contact cases measured at most 3.8 cm, including victim recoil and collapse.

No save migration is required. A running player needs a normal save, exit and
restart through the canonical launcher to load the new scripts.
