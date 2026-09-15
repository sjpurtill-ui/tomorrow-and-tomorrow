# Shared workshops and appointment controls

Base: `2edae731d433a753186eb13e55cc61982ab2053e`.
Worker: `/Users/seanpurtill/Documents/Codex/tt-production-overview-appointments`,
branch `codex/production-overview-appointments`. Root is the designated integrator.

## Behavior

- Shared production has compact, scalable product glyphs, per-line work progress,
  present stock, finite targets, and separate Finished/Attention views. Long
  blockers wrap and increase row height. The board is available through Military
  Supply and Economy → Materials → Shared Workshops. Legacy supply uses the same
  board; manual controls are collapsed.
- The actual quartermaster, or founding steward, schedules known civilian study,
  clothing, nutrient and operating inputs plus equipment for explicitly requested
  army recruitment. One changed order per day, alternating first consideration
  between civilian and military needs. Existing workforce, recipe, tooling and
  material gates remain authoritative. No automatic new armies, research,
  diplomacy, installations or conjured resources.
- Manual lines are protected. Explicit delegation hands over unpaused lines;
  continuous orders become finite. Staff reuse completed lines, never discard
  unfinished work, reserved inputs, or outstanding trials. Pausing, retooling or
  setting a target manually removes staff ownership. Cancelling/fulfilling army
  demand stops additional equipment after any already-started item is finished.
- Bounded receipts record actual positive output-store deltas around each daily
  job advance, including fractional co-products and separately marked repairs.
  They survive issuing goods, removal of batches/lines, and campaign save/load.
  Processing/rejection counters and opening inventory are not fabricated output.
- Appointments resolve stable living-person IDs instead of transient shortlists.
  The dock retains its own shortlist, refreshes immediately and reports failure.
  Clickable rows accept mouse and keyboard input through child labels. The legacy
  screen no longer claims success after a rejected appointment or offers locked
  offices as available. Founding government explains the next office threshold.

## Validation

131 cases passed with zero errors, failures or orphans across:
`test_workshop_steward.gd` (including inherited persistent production cases),
`test_appointment_controls.gd`, `test_government_people_system.gd`,
`test_civilian_production_planner.gd`, `test_training_strategy.gd`, and
`test_civilization_owned_simulation.gd`.

`python3 tools/macos_capture/run.py production_appointments_probe` passed with
guarded background native rendering at 540 and 400 logical pixels. Actual mouse
events select production, preserve the Finished tab on refresh, open a vacant
office and complete an appointment. Labels/rows fit, including a long blocker.
Captures: `artifacts/production-appointments/`; log under
`artifacts/macos-background-capture/`. No visible test window or player restart.

## Compatibility and limits

Optional `workshop_management` is saved within the existing campaign authority.
Old saves begin with delegation enabled for new orders but existing unmarked
lines remain manual. No past production is invented. Finished view shows the
latest 30 days within a maximum of 256 daily product entries. Receipts describe
net additions to a product store during the job, not industrial gross throughput
when a process consumes and returns the same resource. The scheduler cannot solve
absent raw materials, unknown recipes, missing services or workshop capacity;
it reports the constraint. It does not automatically install new facilities.
Product glyphs use authored silhouettes for common items and a workshop gear for
other recipes; they are not claims of complete product-specific art coverage.

Shared edits: narrow appointment-only changes in `local_terrain.gd`, production
hooks/save adapter in `military_campaign.gd`, and shared dock row input handling.
No terrain, project settings, population authority, save-system or archive copying.
Generated `.uid` files and private capture overrides are excluded from delivery.
An existing player process retains its old bundled scripts until normal relaunch.
