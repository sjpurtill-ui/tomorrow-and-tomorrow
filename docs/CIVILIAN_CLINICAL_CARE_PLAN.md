# Civilian clinical care — operating implementation

Delivery worktree `/Users/seanpurtill/Documents/Codex/tt-civilian-clinical-care`,
branch `codex/civilian-clinical-care`, base
`e274af65573cad257567ba698db292be898dfb3a`.
The integrator requested civilian care with actual local supplies, finite staff,
bounded records and consequences. Canonical integration and catalog promotion belong to the integrator.

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
  local water and cloth. Shelter remains an existing living-condition input. Interrupted staffing or supplies breaks continuity.

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

## Implemented behavior

The daily ConsequenceEngine invokes the local care owner before computing the
health target. Nursing recovery adds at most 0.025 to that target; the existing
0.022 daily health interpolation and population transition still own downstream
health and mortality. A paired actual daily simulation verifies the resulting
health difference equals paid relief times 0.022. No helper writes births or deaths.

The default standing duty reserves 25% of available Knowledge capacity after
injuries and absent scholar envoys. The health panel offers 0%, 25%, or 50% duty;
its selected-city report includes staff, observed/supported/waiting burden, supply
expenditure, continuing care and additional recovery. The same reservation applies
before and after care, including shortages, so research cannot reuse carers after
the last supply is spent. Unused duty remains reserved until the player changes it.
No discovered rounds, travel, or occupation means no care reservation or service.

DiscoverySystem research capacity and program summary, SocietyModel's three
observation work calculations, ConsequenceEngine knowledge generation, and the
ResearchAtlas available-workforce readout now consume effective Knowledge capacity.
Raw allocated population and emphasis weights remain headcounts, not a second pool
of available workers. A zero-care fixture retains 11 researchers after one of 12
scholars departs; 25% care leaves 8.25, regardless of service/research call order.

Observation costs 0.5 worker-days and 0.005 clay per population equivalent; pulse
adds 0.125 worker-days and refines subsequent scheduling within coarse assessment
groups. Nursing costs 0.5 worker-days, 0.25 water and 0.02 woven cloth. Its base
additional resolution is 3% of supported burden, with a bounded continuity bonus
only after a real previous-day observation. These are explicit gameplay coefficients.
Episodes are capped at 32 and report history at 30; records exceeding local living
population scale down without creating another death count.

The existing production planner can supply cloth from known, equipped recipes,
consuming yarn and crafting work. City trade requests local care clay and cloth,
reserves donor requirements and debits shipments before delayed delivery. Clay
extraction and drinking-water provision retain their existing resource owners.
Imported cloth works without granting manufacturing knowledge.

Optional legacy state starts empty. New human and owned-civilization payloads
validate finite fields, dated records, unique bounded episodes, staff conservation,
paid supplies and bounded health relief. Full save/load preserves both civilizations'
care and supplies, and same-day continuation cannot charge either a second time.

## Limits and integration

This is supportive care with coarse assessment, not a disease-specific treatment
model. Record media here use clay; later media-specific substitution is not yet
implemented. Hand hygiene, clinical preparations and new military medicine remain
outside these three promotions. No new artwork is included. Full-history pacing
and the remaining authored/operating catalog are unfinished.

Integrate the complete range after e274af6, including b8097cd (scope), 8527336
(fabric), and the final operating commit. Preserve newer metal-process entries and
all existing recipes when reconciling DiscoverySystem. Other shared changes are
narrow additions in GameState, SettlementModel, SaveSystem, WorldSimulation,
ConsequenceEngine, SocietyModel, the controller, atlas and health-panel sources.
Do not use this older-base worktree's 696-entry snapshot to replace current main's
700-entry catalog: this delivery adds exactly three existing authored identities.

## Validation evidence

Godot 4.7.2, explicit worktree above, headless GdUnit command:

```
Godot --headless --path /Users/seanpurtill/Documents/Codex/tt-civilian-clinical-care -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a tests/test_civilian_care.gd -a tests/test_city_resources.gd -a tests/test_civilization_owned_simulation.gd -a tests/test_research_foundations.gd -a tests/test_research_redistribution.gd
```

57/57 cases passed in 35.499 seconds, zero failures/errors/skips/orphans.
Includes 18 clinical cases and existing affected city, owned-world and research
behavior. Output: `/tmp/tt-clinical-acceptance2.log`.
An initial combined invocation exposed a missing test-provider constructor argument;
that test setup was fixed before the successful run. No player process was touched.

`tools/audit_technology_graph.gd` reports 696 live discoveries, 478 explicit routes,
329 reachable products and 18 reachable facilities, with no graph or production
errors on this older 693-discovery base. This is structural evidence, not historical
campaign pacing evidence. Output: `/tmp/tt-clinical-graph.log`.

Normal headless project boot (`--quit-after 2`) exited 0 and reached
`DIRECTION_SCREEN_READY` without script errors; `/tmp/tt-clinical-boot.log`.

## Canonical acceptance

INTEGRATED: source `9c6ec61`, runtime merge `45891f6`, runtime plus art canonical `851a0cad29aa55e6a7fd689d58b5775af3cf7bba`. Combined worktree acceptance: 114 cases across clinical care, city resources, owned civilizations, research foundations/redistribution, record media, metal processes, civilian production planning, technology operations and atlas. Canonical: 43 cases across clinical care, city resources and atlas. All pass with zero errors/failures/skips/orphans. Logs `/tmp/tt-clinical-combined-results.json` and `/tmp/tt-clinical-canonical-canonical-results.json`. Clean graph and exact snapshot contain703, not the older worker696. Three art textures pass canonical768px/mipmap loads. Human/actor and local-city save continuation pass; no new population authority. The headless boot reaches the direction screen with an exit-time resource cleanup warning; no player launch, package rebuild or historical pacing claim.
