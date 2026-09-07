# Citizen production lines — September 7, 2026

READY from `/Users/seanpurtill/.codex/worktrees/c2aa/tomorrow-and-tomorrow`,
branch `codex/citizen-production-lines`, base
`1e57003ab6fcc34b571036cde6cf8ff78a50d81b`.

## Delivered behavior

The existing military Supply dock defaults to persistent production, with continuous
output or a ready-stock target. Targets pause and automatically resume when stores
are drawn down. Lines retain practice while idle; retooling discards unfinished
work and retains 65% efficiency within an output category or 35% across categories,
with a 10% floor. Practice grows only through actual work.

Materials are consumed proportionally as work proceeds, never reserved for an
infinite order. Shortages stop work and deliveries permit automatic resumption.
Finished equipment, ammunition and carts enter the existing authoritative stores;
training and field delivery still consume those stores through their own systems.
Line count remains bounded by the existing research and supporting-domain gates.
All item counts and progress remain aggregate, including billion-item targets.

The player sets the military share of the existing Crafting occupation (35% default),
then relative priorities within that share. Priorities divide effort, and higher
priority lines receive scarce shared inputs first (oldest wins ties). Paused,
stock-satisfied and material-blocked lines take no weight; if no line can work,
all crafting effort remains available to existing civilian systems. Partial-day
shortages may leave some reserved effort unused until the next daily evaluation.

Effective workers account for permanent injuries. Health, existing labor efficiency,
Logistics labor, and recorded workshop/household condition and structural damage
multiply production rate. Carried/domestic craft has half facility effectiveness
when no workplace plots have been recorded. GovernmentPeopleSystem still assigns
citizens; no second labor pool, clock, population authority or save system exists.
FoodSystem and ConsequenceEngine already use civilian_crafting_fraction, so military
allocation changes their available crafting effort. Their production chains were
not replaced. Rival industry remains its existing aggregate supporting-domain model;
this delivery does not introduce per-rival persistent line orders.

Both the main Supply dock and the legacy command Supply tab expose the controls.
The legacy tab now scrolls. One-time production and repair batches retain prepaid
materials and cancellation rules; the new labor-share control also governs them.

## Validation

Worker: 62/62 cases passed across persistent production (14), equipment quotes (6),
military development, military training accounting, battle injuries and progression.
Zero errors, failures, skipped tests, or orphans; log `/tmp/production-regression.log`.
Includes shortage/material conservation, targets and replenishment, pause, priorities,
shared labor, injuries, damaged workplaces, retooling, ammunition/carts, partial-work
save/reload deterministic continuation, billion-item completion and saved pause,
invalid-state rejection, actual main-dock start/pause callbacks, and 500px layout.
Headless editor import and git diff --check passed. Headless layout does not certify
mouse interaction or GPU rendering. Canonical integration and launch recorded separately.

## Compatibility and integration

Existing finite orders remain finite, with their reserved materials. New persistent
line fields and the crafting share are stored in MilitaryCampaign's existing payload;
older saves default to 35%. No save deletion or world regeneration is required.
Older executable versions do not understand persistent line semantics; do not use
this delivery's saves with an older build.

Shared hotspot: scripts/military_campaign.gd. Other edited files are the two Supply
UIs; new adapter, legacy panel and tests are isolated files. No changes to terrain,
GovernmentPeopleSystem, GameState, DiscoverySystem or SaveSystem ownership.
No shared-file conflict was present at handoff. No remote push.
