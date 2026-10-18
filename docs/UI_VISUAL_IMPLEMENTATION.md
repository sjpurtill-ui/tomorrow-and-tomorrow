# Visual audit implementation tracker

Authorized scope: all proposals in [UI_VISUAL_AUDIT.md](UI_VISUAL_AUDIT.md), approved October 18, 2026. Integrator works in `/Users/seanpurtill/Documents/Codex/tt-hoi4-production`, branch `codex/visual-comparison-screens`, base `b8499d6f6aa6e3315763e3f351373bbcba038a1e`.

Unchecked entries remain required work. An integrated source change is not a claim that a running player has reloaded it. Each batch needs source/behavior checks, representative actual rendered review, a verified remote push and canonical integration.

## Batch 0–1: controls and material needs

- [x] Shared retained comparison widgets and bounded visible choices.
- [ ] Buildings: visible categories, material need/have, capacity before/after, builder/queue state.
- [x] All seven storage types: capacity, expansion costs/gains, actual status and direct actions.
- [ ] Food/water: aligned supply/consumption/coverage, losses and reserve trend.
- [ ] Materials: protected supplies/free stock and arrivals/losses; hauling and storage bottlenecks.
- [ ] Global town/realm scope, compact map controls, stable interaction while running.
- [ ] Rule check: border-fort-only effects; remove rejected non-fort watch effects if active.

## Batch 2: people and production

- [ ] People: reconciled allocation strip, selected mode, donor/recipient change, effects and explicit estimate failures.
- [ ] Home: compact coverage comparisons and visible current-work choices.
- [ ] Military production: dense simultaneous lines, actual efficiency/resource penalty/stop threshold.
- [ ] Civilian production: consistent rows, purpose, inputs/output/target.
- [ ] Production catalog, selected line and receipts: bounded visual choices and history.
- [ ] Wealth/purse: distinct accounts and funded service cost/coverage comparisons.

## Batch 3: knowledge and health

- [ ] Research: retained active lanes, visible waiting fields and evidence/effects.
- [ ] Knowledge exploration: direct field/status choices and bounded dependency branch.
- [ ] Research totals by additive category, last three discoveries and secondary archive.
- [ ] Longevity: real unlocked/delivered benefits and adoption blockers, honest attribution.
- [ ] Hardship: existing timeline plus selected event loss pictograms.
- [ ] Population/capacity details: reconciled flow, trustworthy cohorts, bounded death archive.

## Batch 4: households and politics

- [ ] Early household court and reachable titles/actions checked in play.
- [ ] Family court: portraits, program gains/drawbacks/cost, rivalry and wants.
- [ ] Evolution through all five population thresholds and organization stages.
- [ ] Separate favor/endorsement/funding consequences, without moving workers.
- [x] Culture: all official/lived value pairs and actual bonuses.
- [ ] Audience/diplomacy: visible targets/actions and adjudicated consequence receipt.

## Batch 5: military and world

- [ ] Army: one Defense manpower source, equipment/readiness, forage/supply comparison.
- [ ] Actual map marching/V deployment/front thinning/flanking/penetration, including tiny blobs.
- [ ] Leaders/command/service: direct choices and general-led objectives; reconcile legacy routes.
- [ ] Siege, battle report, occupation and recovery comparisons.
- [ ] Peoples/Standing: direct counterpart choices, paired reported values and confidence.
- [ ] Known world/expeditions: map-linked targets, costs, routes, return findings.
- [ ] Spies/community projects: direct choices and cost/effect/risk.
- [ ] City/contact/scout dossiers and world history.

## Batch 6: secondary screens and validation

- [ ] Chronicle years/demography/buildings, one selected account.
- [ ] Artifact gallery/exchange and Great Works atlas.
- [ ] Orders/notifications/manual discovery reader; preserve quiet routine events.
- [ ] Founding/resume gating, travel and naming.
- [ ] Save/load/restart/settings/control layout and available audio buses/voice diagnostic.
- [ ] Normal/narrow/high-scale review; early/mature/empty/blocked/unknown states.
- [ ] Live refresh/focus/scroll/click checks across every main screen.
- [ ] Final remote verification, integration record and player release preparation.

## Checkpoint 1 — Buildings, storage and daily needs

Implemented: reusable retained same-unit comparison tile; visible Building section buttons; material have/need and capacity now/after; expansion bills, gain and builder progress on all seven store tiles; protected-work supplies/free-stock reading in Materials; actual meal/water requirement comparisons; compact responsive Food painting and source grid. The broader map/queue/flow work, incoming-storage projections and other unchecked tasks remain outstanding.

Validation: 49 distinct cases across storage (13), construction (15), Food (10), Materials (9) and comparison widgets (2) pass assertions with no errors/failures. The existing construction suite still reports three orphan nodes and exit 101; the other 34 cases report no orphans. Final logs: `/tmp/tt-visual-batch1-final.log`, `/tmp/tt-visual-buildings-final.log`, `/tmp/tt-visual-batch1-layout.log`. Guarded native renders reviewed at 1280 and 360 widths for Buildings, storage, Food and Materials; the capture exited. Test fixtures and captured files remain local. No simulation rule, allocation or save-schema change. Existing field/action handlers retained.

## Checkpoint 2 — Visible choices and retained Research

Implemented bounded visible choices across eleven UI components (Home, Research, knowledge, Peoples, Known World, expeditions, scouting, Standing, spies, gallery and exchange). Shared trays preserve identity, metadata and disabled state; searches and pages keep large sets bounded. Research daily numeric refresh retains allocation controls and uses current callbacks; actual structural question changes still use the dock's preserved view state. Native review includes wide/narrow layouts and corrected Standing legend wrapping. All broader redesign tasks above remain required; replacing selectors does not complete their screen redesigns. Integration status records tests and the combined-suite collection-state limitation.

## Checkpoint 3 — All values together; storage arrivals

All ten value axes are visible with lived/official markers and poles, retained value-only updates, exact family shift/target context and existing bonus/history displays. All seven store tiles include scoped physical arrivals, converted bulk loads and a labelled capacity projection; current/incoming/overflow segments share one scale. Existing building actions/costs/progress remain visible. Culture/storage have 23 passing checks and reviewed actual wide/narrow native renders. No rules/save-schema changes.
