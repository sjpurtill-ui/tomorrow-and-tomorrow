# Standing military training strategy

Base: `17da40af89d10e3b574f9de5adb923f1d0f90e4a`.
Worktree: `/Users/seanpurtill/Documents/Codex/tt-training-strategy`.
Branch: `codex/training-strategy`. Primary agent is the designated integrator.

## Behavior

Army, Navy and Air each have an independent saved training policy. Suspend stops training; Maintain rotates about 10% of qualified personnel toward 55% drill, Regular 25% toward 70%, and Intensive 50% toward 85%. Regular is the default. Initial recruits/crews are already withheld from service for full-time instruction; policy changes their intake pace separately. Changing settings does not grant progress, reset a course, or spend resources immediately.

Army staff select less-prepared eligible formations, organize gated exercises, and pause for a military emergency, inadequate equipment, poor condition, a reached proficiency target, or protected food reserves. New courses start automatically. Field formations can attend while assembled at home; marching and distant formations do not. The legacy single-course API remains for compatibility, with the same daily clock, policy limits and funding; the repeated start/cancel controls are replaced by standing policy controls.

Army exercise durations are six times the previous durations (72–252 effective days). Extra rations and equipment-wear rates per participant are four times higher. Basic land instruction uses three times catalog duration with a 45-effective-day floor and now charges extra rations. Naval and air instruction uses three times catalog duration with a 90-effective-day floor. Qualified crews exercise automatically at their home base under policy, paying additional rations, recipe-derived materials and fuel. Unavailable supplies pause progress atomically and name shortages. Repairs take priority when condition is too low. Mission assignments remain under their existing separate naval/air commands.

Rival land training uses the shared policy targets, course gates, duration, gain and cost constants in its aggregate monthly economy. Rival crews use the same daily training procedure as the player's crews, with food charged to the rival's food-days balance and materials/fuel to its military stores. No click-frequency reward or alternate rapid rival course formula remains. Economic representation is still aggregate for rival land forces; this is not a claim of full HOI4 economic/combat parity.

Military/F6 now opens a broad forces roster: unit emblems, personnel, equipment bars, drill, experience and staff activity. Army builds and supply remain accessible. Navy/Air have separate rosters and links to their main-map commands. Training Strategy exposes the four commitments visually, spending and staff reports. Controls/status update in place. Close, Escape and clicking the exposed map dismiss the overview. Army runner reports now carry a dated formation snapshot; older reports show unavailable composition until a new report arrives.

## Ownership and compatibility

New files: `military_training_staff.gd`, `hud/military_roster_screen.gd`, `test_training_strategy.gd`.
Shared integration changes: `military_campaign.gd`, `civilization_system.gd`, `joint_operations.gd`, military catalog/UI and command-rail/content adapters. GovernmentPeopleSystem retains labor/civic ownership; no individual-soldier authority or direct-cohort battle controls were introduced. Population remains aggregate.

Save version remains compatible via optional training-strategy/timing fields. Existing course/initial-instruction completion fractions are migrated once to the longer durations; retained experience and personnel remain. Policy, paid progress and the processed-day guard survive saves. Naval proficiency is optional on older force records. Merging service formations conserves proficiency weighting and the training-day guard.

## Validation and limits

Worktree: 80 tests passed, zero errors/failures/orphans across training strategy, training accounting, settlement defense, joint operations/campaign, force catalog, main-map services and map dismissal (`/tmp/tt-training-worktree-final.log`). Final shortage naming/repair refinement reruns the 15 strategy cases. Earlier fixtures were updated to advance distinct training days, fund real training materials and reflect limited staff rotations. Tests cover automatic progression/costs, repeated-order/same-day idempotence, shortages and recovery, target/suspend behavior, independent services, old/new saves, rival bounds, dated field reports and actual Control layout width/dismissal.

No graphical probe or player restart was performed. Headless UI checks validate controls/layout/state; native visual interaction is not claimed. The running player's loaded scripts are not assumed updated. Only the canonical integration and subsequent normal launch make the new build available in that session. No remote push or unrelated worktree synchronization.
