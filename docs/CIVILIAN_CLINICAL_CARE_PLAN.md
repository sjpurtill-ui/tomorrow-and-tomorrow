# Civilian clinical care — operating delivery in progress

HELD worktree `/Users/seanpurtill/Documents/Codex/tt-civilian-clinical-care`,
branch `codex/civilian-clinical-care`, base
`e274af65573cad257567ba698db292be898dfb3a`.
The integrator requested civilian care with actual local supplies, finite staff,
bounded records and consequences. No runtime acceptance or promotion is claimed.

## Inspected behavior

ConsequenceEngine currently computes population health from intake, shelter,
exposure, environmental pressure and discovery effects. SettlementModel scopes
secondary resources, health and daily consequences; WorldSimulation supplies the
same owner abstraction to non-player civilizations. These are the authorities to
extend. GovernmentPeopleSystem remains the labor allocator. GameState.effective_workers
already subtracts absent scholars from Knowledge; any clinical reservation must
apply after that subtraction and must not reserve the same staff twice.

Existing military FieldMedicine operates on equipped detachments and wounded pools.
This task does not alter it, permanent injury records or military personnel.
Civilian episodes are bounded aggregate simulation records, never a person entity
for every citizen, new inhabitants, or a second death ledger.

## Bounded identity set

- `clinical_observation_rounds`: requires `case_records` and one of
  `birth_attendants` or `civic_infirmaries`. Repeat dated observation before treating
  an old assessment as current. Record supplies and staff time are finite.
- `clinical_pulse_assessment`: requires `clinical_observation_rounds` and
  `standard_measures`. Adds a contextual observation that improves prioritization
  and follow-up; it does not diagnose every disease or cure patients.
- `nursing_care_organization`: requires `clinical_observation_rounds` and
  `crew_handoffs`. Maintain practical care continuity with actual allocated carers,
  local water, cloth and shelter. Interrupted staffing or supplies breaks continuity.

Existing prerequisite identities are retained, not recounted. Three possible
promotions, zero new authored identities. Hand hygiene and rehydration are excluded
from this delivery: Laundry Soap and untreated Freshwater are not automatically
qualified clinical preparations. Other therapies and measurements need their own
physical and assessment support before later promotion.

## Owner and causal contract

Care demand follows existing local population and modeled illness/exposure burden.
A bounded episode group records onset, remaining affected population equivalents,
observation dates, assessment, and continuity. It never invents named patient data.
Admission plus outstanding demand cannot exceed the local living population.
Records distinguish unobserved need, assessed need, supported care and recovery.

Use one daily staff budget shared by observation and care. A Knowledge reservation
reduces other Knowledge work. Compute available carers from the same post-absence,
post-injury capacity used by effective_workers; avoid recursive reservations and
avoid making care happen only after research has already spent today's workers.
Local-population scopes and absent staff must remain authoritative.

Spend actual local supplies only for delivered work. A source shortage lowers work
and leaves visible unmet demand. Repeated calls on the same day cannot duplicate
observations, supplies, staff or benefits. Imported supplies may be used without
manufacturing knowledge; knowledge alone produces no water, cloth or records.
Observation changes prioritization and continuity; it does not itself give a flat
health bonus. Supported care can reduce a bounded portion of the existing modeled
health/mortality pressure. The existing population transition remains the sole
owner of births/deaths; no care helper writes those counters or restores the dead.
Coefficients are game abstractions, not clinical predictions.

State must be optional for legacy worlds, scoped with secondary-city resources,
validated for human and owned-actor payloads, bounded in record count and finite
numeric values, and preserved across whole-game save/load. Occupied or inaccessible
cities receive no new service. Travel cannot operate a fixed infirmary implicitly.
The health inspector must show local staff commitment, supplies used, unmet demand,
assessment/continuity and realized effects. Ordinary care is automatic within labor
and resources; no mandatory patient-by-patient administration screen.

## Required acceptance

Verify shortage-limited work, staff conservation against research and traveling
scholars, one daily service transaction, observation freshness, pulse-based assessment,
interrupted and restored nursing continuity, bounded aggregate records/population,
real health or mortality consequences, secondary-city and actor isolation, occupation,
legacy absence, malformed payload rejection and whole-game save continuation.
Verify existing affected city/population/research behavior and graph closure once
connected. Run focused follow-ups for actual changes or failures, not repeated broad
campaign simulations. Full historical pacing and the overall 5,000-discovery goal
remain unfinished and are not proven by this feature's local checks.

Shared changes will be narrow additions in GameState, SettlementModel, SaveSystem,
WorldSimulation, ConsequenceEngine, discovery registration and the health inspector.
Preserve record media, geared workshops, rail, food conditioning and current clinical
foundations. Coordinate any resupply planner/controller changes with the integrator.

## Foundation checkpoint

The integrator accepted the three-identity scope and narrow owner/resupply changes.
`civilian_care_fabric.gd` now models up to 32 aggregate episodes, population-bound
admission, dated paid observations, pulse-informed prioritization, shared observation
and nursing time, local record clay/water/cloth expenditure, broken or sustained
continuity, and a 30-entry report history. A repeated service call on the same day
returns the existing report. This helper is not registered or called by gameplay.

Next: owner-local daily admission and recovery accounting, nonrecursive Knowledge
reservation before research, optional local state validation/save connections,
ConsequenceEngine and health inspector integration, then coherent operating tests.
The fabric must still be compiled and tested after connection; this checkpoint is
HELD and is not evidence of live clinical service or discovery promotion.
