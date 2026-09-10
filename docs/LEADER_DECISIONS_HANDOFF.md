# Ruler-led opponent decisions

Worktree: `/Users/seanpurtill/Documents/Codex/tt-leader-decisions`
Branch: `codex/leader-decisions`
Base: `84dcddb8b95e53aed1527dd74d407182f1f8dd45`
Owner/integrator: primary agent; no concurrent workers.

## Problem and behavior

Equal simulation rules did not mean varied play. The existing controller selected century ambitions by ID, then used identical recruitment, training, scout duration, settlement distance, unit ranking and diplomacy thresholds. The foreign leader's visible personality/goals were largely disconnected from those choices.

The controller now derives preferences from **the same sovereign personality used by ForeignDiplomacy and foreign-leader conversation**, including openness, discipline, empathy, assertiveness and tolerance for risk. Its leading stated goal receives actual research emphasis. Scarcity and active war can override ordinary preferences: reasonable emergency convergence is intentional, and twelve forced unique actions would not be credible.

Preferences affect the next available century ambition, distribution of the existing research-emphasis budget, fraction of recruitable people committed, training investment, role preference among eligible land units, affordable naval/air equipment selection, exploratory duration, settlement reserve requirements/distance/site priorities, trade/goodwill/war/peace choices, defensive versus offensive objectives and separate naval/air mission rankings. Failed long scout journeys fall back to feasible shorter journeys. Diplomacy tries supported destinations in ranked order. Campaign targets come only from returned city reports. Existing production lines update their target through the same validated player-facing adapter.

The small starting force can vary within its real recruitment ceiling. No AI population, equipment, research capacity, income, base, readiness, mission range or material bonus was added. All mutations pass through existing validated orders, including new explicit adapters for research emphasis and production targets. Local staff still own ordinary city labor and training execution. Macro attention is redistributed, never enlarged. A full military production line or lack of resources still blocks an order.

Monthly strategic reviews are phase-distributed by stable civilization identity; each ruler still reviews twelve times per 360 days. This reduces the old synchronized spike rather than throttling AI. Daily rules and all civilization turns are unchanged. Existing century commitments remain binding until the same next-century choice offered to the player.

The shared agenda also fixes a false hunger check: raw food output was compared against population without its actual ration demand, labeling otherwise well-provisioned rulers hungry. Agenda urgency now uses reserve days and a supplied actual intake ratio.

## Validation

All **72 worktree cases pass**, zero errors/failures/skips/orphans, in `test_civilization_strategy`, `test_civilization_owned_simulation`, `test_joint_force_catalog`, `test_training_strategy` and `test_discovery_projects` (`/tmp/tt-leader-tests-final.log`). Eleven new cases verify actual divergent orders from identical conditions, emergency constraints, meaningful research at a small budget, budget conservation, distinct feasible service missions, air-equipment resource gates, twelve varied ruler profiles with equal decision frequency, player-state isolation, rejection of invalid orders and campaign/save continuity. The existing identical-input/manual-controller parity tests still pass.

A private mature-campaign release probe confirms actual different research allocations and training policies while continuing every actor. Several actors in this campaign are short of food, so many prioritize survival. Exact final performance/canonical results are recorded in `INTEGRATION_STATUS.md`. The optional `--strategies` probe output includes preferences and actual bounded order receipts for inspection; it never changes the save and is not in the normal export.

## Compatibility and limits

No save version change. Personality is the same deterministic persisted-world identity used by the existing diplomatic persona. New decisions take effect at the next monthly review; no campaign reset is needed. This binds the current sovereign persona to strategy; it does not add sovereign succession or rewrite the GovernmentPeople roster. Human decisions remain manual, and the prototype general-led campaign is unchanged. This is bounded deterministic strategy, not a claim of optimal human-level tactics. Physical constraints can legitimately make rulers choose alike. The earlier subject-art worktree remains separate and incomplete.

Shared changes: `civilization_controller.gd`, `civilization_orders.gd`, `leader_personality.gd`; new `civilization_strategy.gd`; focused tests and the opt-in mature-save probe. No player game was launched or interrupted.
