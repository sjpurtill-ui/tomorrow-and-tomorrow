# Whole-service training overview

Base: `8871aede04b06e94dd0dcf09ab0242a97daf4da3`.
Worktree: `/Users/seanpurtill/Documents/Codex/tt-service-training-overview`.
Branch: `codex/service-training-overview`. Primary agent is the designated integrator.

Navy and Air training summaries now account for every owned force in the selected service instead of displaying the last processed force's message. Four colored counts and proportion bars distinguish training rotations, mission/travel assignments, home crews at the selected proficiency target, and paused training. Total crews and actual attendance are shown separately. Repeated pause reasons are grouped; the first three appear directly, with the full list available from the Paused indicator. Empty services explicitly say that no forces are commissioned.

The snapshot is read-only and independent of force iteration order. Rival forces and the other service are excluded. Counts describe task forces/air wings rather than individual craft. A force with a training rotation counts under Training even if remaining qualified crews continue missions. Target met covers home crews; deployed forces remain On assignment. Staff still apply policy changes on their next daily review, as explained in the view. These are training categories, not a claim that every force counted On assignment is currently achieving mission effects.

Unavailable bases, missing equipment/crews and lost-carrier diversion clear stale training attendance when operations process them. Repairs publish their actual status. Reaching the policy target records that fact and clears the prior exercise message. Roster activity uses the same eligibility/freshness report. Costs, training rates, mission controls and combat calculations are unchanged. Army retains its existing general-led training summary.

Owned files: `scripts/military_training_staff.gd`, `scripts/joint_operations.gd`, `scripts/hud/military_roster_screen.gd`, `tests/test_training_strategy.gd` and this handoff. No shared hotspot edits or conflicts. Existing optional training-day/status/attendance fields are reused; no save schema change or migration.

Final worktree validation: **79 tests passed**, zero errors, failures or orphans (`/tmp/tt-service-overview-worktree.log`). Suites: training strategy (26), joint operations (5), joint campaign loop (30), main-map services (6), training accounting (10), map dismissal (2). Five new cases cover mixed service counts, order independence and read-only behavior, target completion, base/equipment failures and recovery, empty/awaiting services, and stable UI indicators/layout. The initial run encountered a type-inference parse error and runner crash; the explicit boolean fix passed the subsequent targeted and full relevant runs.

Headless checks validate actual Control state, layout and retained nodes, not native visual interaction. No graphical probe or player/editor restart. Test userdata is isolated; the temporary override is removed after validation. Canonical integration and validation are recorded separately. No remote push or other task/worktree changes.
