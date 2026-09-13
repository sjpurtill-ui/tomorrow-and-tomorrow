# Metallurgy, casting and finishing — implementation in progress

Worktree: `/Users/seanpurtill/Documents/Codex/tt-metallurgy-processes`.
Branch: `codex/metallurgy-processes`.
Base: verified 843 checkpoint `59f146e5fa9badfa24f147e3adad48d9a3bc968e`.
Not an integration handoff. No new operating discoveries claimed.

Updated deliberately from verified 856 main checkpoint
`68cd6f66b1d13c7e05d0bcee94216d21168b3a14`; additive Industry merge was clean.
The original manufacturing delivery and correction remain frozen and are now
integrated by the designated integrator.

Latest connected route: selected steel → retained thermal treatment → paid
destructive section and reflected field → section-checked normalized stock →
plain shaft blanks. Four additional recipes provide the furnace, selected
steel, treatment and actual shaft consumer. This is one selected treatment,
not universal steel qualification or the whole twelve-method batch.
The section's source/job/site/ordinal, consumed 0.02 material, preparation
supplies, work/energy, generated field and measured result remain attached to
the workpiece; repeated calls cannot duplicate stock or reuse the section.

Approved narrow PersistentProduction hooks now handle thermal dispatch,
reserved-feed eligibility, retool disposal and validation. Ops requests power
for retained local thermal pieces after free feed is exhausted. Thermal-model
energy converts to existing game electricity through the recipe's explicit
0.01 scale; section acquisition pays its separate 0.2 electricity. This keeps
model thermal units separate from the game's service units.

Connected metallurgy suites: 10/10 pass, zero errors/failures/skips/orphans,
`/tmp/tt-metallurgy-connected-tests-final.log`. These include actual workshop
setup, final-feed reservation, pending power demand, paid partial section
reload, accepted stock and the shaft consumer. The initial connected test
exposed missing reserved-feed eligibility; corrected before the passing run.
Daily generator execution, full SaveSystem roundtrip, passive calendar cooling,
stronger thermal-history provenance, supply audit and remaining methods still
need implementation/verification. Definitions remain unregistered.
Shared-hook regression: metallurgy workshop, existing machine parts and
technology operations suites pass 32/32, zero errors/failures/skips/orphans
(`/tmp/tt-metallurgy-shared-regression.log`, 12.755 seconds).

Honing and superfinishing now run through the existing reserved machine
workpiece/inspection path. Two additive machine kinds retain three long
reciprocating passes or thirty short oscillating passes, respectively. The
selected model retains 32 surface-height samples and three eight-angle
diameter stations; contact-comparator inspection quantizes those samples and
computes mean absolute profile deviation, roundness and taper. These are
normalized game metrology values, not industrial dimensional tolerances.
Wear affects manufactured profiles and can cause rejection. Prequalified
reamed sleeves/ground shafts are required; this route does not claim to repair
arbitrary deep defects or turn unqualified blanks into precision stock.

Eight additional recipes provide the comparator, finishing stones, two heads,
two finished parts and two real bearing-assembly consumers. The wear-history
validator now permits ten named machine kinds; original eight methods retain
their behavior. `test_surface_finishing.gd` plus existing machine parts pass
15/15, zero errors/failures/skips/orphans
(`/tmp/tt-surface-finishing-tests.log`, 7.108 seconds). Includes partial-motion
reload, observed profiles, worn-tool rejection and actual consumer stock debit.
Full acquisition, supply closure, capital recipe coverage, art and canonical
integration remain pending; neither discovery is registered yet.

Phase survey now has an actual retained workshop path: eighteen 0.05-unit
lead/tin samples spanning three weighed compositions and six target
temperatures. Each sample runs a paid thermal stage and records quantized
temperature and standard-tilt mobility; partial observations survive serialized
continuation. The selected composition is derived from the recorded first
fully flowing temperature. Only a survey supporting the selected low-melting
composition grants the chart required by a solder recipe; other results yield
unresolved notes. Consumed alloy samples become spent sample stock. The paid
chart is installed as tooling for solder preparation. A further motor-lead
recipe exists but its consumer behavior has not yet been exercised.

The Pb-Sn eutectic anchor follows the
[NIST assessed Pb-Sn system](https://www.metallurgy.nist.gov/phase/solder/pbsn.html).
Liquidus interpolation, mobility and game heat/work parameters are explicitly
simplified game models; solid solubility, equilibrium phase fractions and
kinetic effects are not represented. This is a bounded observed melting-range
survey, not a complete assessed phase diagram for every alloy.

`test_alloy_phase_trials.gd` and metallurgy workshop pass 5/5, zero
errors/failures/skips/orphans (`/tmp/tt-alloy-connected-final.log`). Includes
actual weighed stock reservation, eighteen recorded observations, partial
reload, composition selection from observations and chart-consuming solder
production. Initial run caught a GDScript type inference error, corrected.
The twelve definitions remain unregistered; overall completion is unproven.

Casting now has two retained staged workshop paths for selected copper
bearing brackets. Investment builds and dries three shell layers and removes
the pattern in a separately powered burnout before pouring. Lost-foam uses
a coated/dried sand-supported pattern present during the pour. Stage charges,
thermal work, moisture removal, remaining pattern units and paid inspection
persist with the original job. Worn setups reject; accepted blanks enter an
actual shaft-bearing machining recipe. This is a normalized small-bracket
process model, not a general mold-flow or solidification solver.

Six additional recipes supply molding apparatus, expanded pattern production,
ventilation apparatus, the two casting routes and the bearing consumer.
`test_casting_workshop.gd` passes 2/2, zero errors/failures/skips/orphans
(`/tmp/tt-casting-tests.log`): distinct pattern-at-pour states, three versus one
coat, partial paid-mold reload, real consumer debit, powerless-burnout stall
and worn-setup rejection. Still pending: source-qualified EPS density/residue
trials (current recipe is not sufficient evidence of that), full precursor
closure, stronger aggregate history validation, actual calendar solidification
and daily generation tests. Neither casting method is registered yet.

The twelve definitions in `metallurgy_process_knowledge.gd` preserve the exact
authored AND/OR predicates. They remain unregistered until their actual
processes, observations, acquisition and downstream consumers are working.

Initial precursor implementation adds eleven paid recipes: benzene separation,
ethylbenzene production, iron oxide and potassium promoter preparation,
dehydrogenation catalyst preparation, crude styrene, monomer separation,
thermal polystyrene, vacuum devolatilization, pentane separation, and a
material-process vacuum pump assembly. All use existing knowledge gates.
Thermal polymerization consumes the existing stirred-reactor and heat-removal
services; no new service or save authority is introduced. Recipe yields and
work quantities are bounded game quantities, not industrial design values.

Primary process support:

- [PlasticsEurope styrene process guide](https://plasticseurope.org/wp-content/uploads/2018/09/Styrene_SAFE_HANDLING_GUIDE_2024_FINAL_24102024_v2.pdf): benzene/ethene through ethylbenzene to styrene.
- [EPA AP-42 polystyrene](https://www.epa.gov/sites/default/files/2020-10/documents/c06s06-3.pdf): thermal initiation, residual-monomer removal and pelletizing; blowing-agent incorporation and expansion are separate operations.
- [EPA ethylbenzene process report](https://nepis.epa.gov/Exe/ZyPURL.cgi?Dockey=9101O876.TXT): selected aluminum-chloride alkylation pathway.
- [Experimental foam-pattern study](https://scholarsmine.mst.edu/masters_theses/88/): EPS and EPS/PMMA pattern degradation; existing LDPE insulation stock is not being relabeled as qualified casting patterns.
- [Pre-pour pattern removal example](https://patents.google.com/patent/US4995443A/en): supports a selected later plastic-pattern shell process. It does not date ancient investment casting.

Still required: qualified expandable pattern fabrication and trials; retained
shell layers/drying/burnout versus pattern-consuming metal fill; physical
casting inspection and machining consumers; controlled thermal and induction
treatment; composition/temperature phase evidence; prepared grain measurements;
unloaded residual-strain-release measurement; fracture testing with crack
geometry and validity checks; welding heat-affected material qualification;
vacuum melting; honing and superfinishing with actual cylinder/bearing consumers.
Material preparation alone does not satisfy these operating requirements.

Initial verification: `test_metallurgy_feedstocks.gd` passes 2/2 tests, zero
errors/failures/skips/orphans (`/tmp/tt-metallurgy-feed-tests.log`). It exercises
all eleven recipes across partial serialized job continuation with exact feed
debits, plus polymerization blocked by absent cooling and resumed with paid
capacity. It does not establish automatic daily dispatch, end-to-end chemical
stock closure, pattern qualification or the twelve discovery mechanisms.

Thermal runner: `metallurgy_thermal_cycle.gd` now retains a selected specimen's
temperature, thermal capacity, paid energy/coolant receipts, peak temperature,
hot exposure and stage history. A lumped heat-loss calculation makes specimen
capacity and supplied power affect the actual temperature; thermostat control
stops excessive heating. Air cooling requires elapsed process work, while a
selected quench also requires finite coolant. This is a normalized game model,
not a general steel heat-treatment solver or engineering qualification.
Its runner owns no stocks and currently has no production dispatch hook.
Adapter debit, recipe/source binding and stronger saved-state provenance remain
necessary before use in accepted production.

`test_metallurgy_thermal_cycle.gd`: 3/3 pass, zero errors/failures/skips/orphans
(`/tmp/tt-metallurgy-thermal-tests.log`). Covers energy starvation, capacity
sensitivity, serialized partial thermal continuation, retained hot exposure,
air cooling, coolant-limited quenching and malformed progress. Existing
precursor tests were not repeated because this module does not change them.

New `metallurgy_workshop.gd` adapter reserves one source-bound workpiece,
debits actual Ops electricity and quench water receipts, records spent water,
retains partial work, and stops at inspection without issuing accepted stock.
`test_metallurgy_workshop.gd` passes 2/2 tests, zero errors/failures/skips/orphans
(`/tmp/tt-metallurgy-workshop-tests.log`): the final free feed is reserved once,
an energy outage cannot advance active heating, serialized work resumes to
inspection, unpaid tooling blocks reservation, and retool disposal gives no
refund. These use an explicit test recipe; final recipes, actual apparatus
construction, inspection/acceptance, calendar-time passive cooling and the
daily production/save hooks are not yet wired. Do not present this as a
completed heat-treatment discovery.

Grain inspection now has a bounded pixel-based measurement module. It reads
six horizontal/vertical test lines from a retained calibrated reflected-light
field, records resolved boundary-band crossings, and reports a field-specific
mean intercept and resolution/calibration uncertainty. It does not read a
latent grain-size property or equate a small grain measurement with strength.
Insufficient crossings, invalid calibration, unprepared sections and
transmitted illumination cannot qualify. This is a selected game measurement,
not an ASTM certification or whole-lot sampling conclusion.

Four additional paid recipes provide section-preparation fixtures, a carbon-
illuminated reflected-light microscope, nitrate-derived acid, and dilute steel
etchant. Recipe tests now cover fifteen precursors/apparatus outputs.
`test_metallurgy_grain_measurement.gd` plus the updated feedstock suite pass
4/4 tests, zero errors/failures/skips/orphans
(`/tmp/tt-metallurgy-grain-tests.log`). Field production from an actual reserved
metal section, section/coupon destruction, paid image acquisition and accepted
material release remain to be connected; current measurement tests use explicit
image fixtures.

Measurement references:
[Buehler metallographic preparation and reflected-light contrast](https://www.buehler.com/assets/solutions/technotes/TechNote_MPA_Vol-6-Issue-1_0516_WEB.pdf),
[Buehler steel preparation/etchant selection](https://www.buehler.com/solutions/buehler-solutions/solutions-by-material/solutions-by-material-carbon-steels/),
and [NIST optical grain-boundary/intercept analysis](https://github.com/usnistgov/grain-size-analysis-tools).

Also pending: full material closure audit, acquisition checks, save validation,
imagery and canonical integration. The integrator owns imagery and the shared
manufacturing merge. Do not edit PersistentProduction or the machine adapters
until updating deliberately to its forthcoming verified manufacturing base.

The full project objective remains 5,000 distinct authored and operating
discoveries, validated branching/recovery, viable full-history progression,
civilian/military consequences and the approved imagery. This batch is only a
portion of that unfinished objective.

### Casting material provenance follow-up
Saved casting moisture, evaporated water, pattern units, shell layers and pour readings now reconstruct from paid stage history. A changed aggregate, altered frame material state or forged pour temperature is rejected even when inspection readings and acceptance are changed to match. This does not yet replay thermal energy histories or complete EPS source qualification/calendar cooling.
Targeted casting suite: 3/3 passed, no errors or skips, /tmp/tt-casting-balance-tests.log (963 ms test execution). Existing serialized partial molds and both actual bearing consumers still pass. No schema fields added; legitimately generated partial records remain compatible. Scope remains HELD/unregistered, canonical count unchanged. Changes confined to casting_workshop.gd, its tests and this progress document; no shared-file conflict in this follow-up.

### Induction surface-hardening operating path (HELD)
Added induction_case_cycle.gd and induction_workshop.gd, four additive recipes and narrow P/Ops dispatch, reservation, validation, retool and pending-power hooks. The selected five-cell radial model deposits frequency/gap-dependent heat, exchanges heat between cells, spends spray water and records surface transformation separately from the core. Fixed paid steps replay all temperatures, peaks and transformation flags on validation. A paid destructive section indentation comparison accepts surface/core contrast; an actual consumer spends accepted shafts to produce existing Crank Assemblies stock.
The selected response uses normalized game units, not real hardness, calibrated case depths or general steel constitutive behavior. Frequency, coil geometry and quenching distinguish surface treatment: https://inductothermgroup.com/hardening-and-tempering-with-induction/ . Capital component qualification, forming geometry, tempering, cool-enough section handling, fractional work below .05, calendar-time outages and full daily generator/SaveSystem paths remain unfinished. Do not promote this path or count it as production-ready. The present final 20 ticks are passive model cooling, not tempering.
Verification: test_induction_workshop (2), test_casting_workshop (3), test_metallurgy_workshop (3), all 8 passed without skips/errors in 2.262 seconds: /tmp/tt-induction-connected-tests.log. Tests cover poor coupling rejection, rewritten radial history rejection, water starvation/resume/serialized pending validation, actual material debits and crank consumer. They seed apparatus and do not establish complete capital supply closure. Initial test failure was integer expected values in float stock assertions, corrected before passing run.
Save compatibility: optional new job state only; no existing fields changed. Existing normalizing/casting partial records passed. Ownership conflicts: additive civilian_industry and approved narrow persistent_production/technology_operations hooks; no GameState, SaveSystem, UI or canonical edits. Eight of twelve paths now have partial implementations; four untouched paths are residual stress, fracture toughness, welding metallurgy and vacuum melting. All twelve remain unregistered and HELD.

### Induction tempering, fractional labor and idle cooling
Supersedes the initial induction cycle's missing tempering/cooling and lost substep labor. The retained route now has 20 heating, 20 spray-quench, 20 paid furnace-tempering and 40 cooling steps, followed by .5 inspection work (5.5 total work, 16.4 total electricity). Furnace and lathe apparatus are required. Surface acceptance requires measured indentation contrast, sufficient modeled temper exposure and temperature <=150 before section work. Work smaller than .05 persists as bounded labor credit; 550 increments of .01 complete with the same paid energy.
The P.advance entry synchronizes elapsed idle days even when production is paused or has zero work. Missing water/power and skipped calendar days cool the retained radial state; repeated same-day calls do not double-age. Consecutive idle days are compressed and reconstructed deterministically during save validation. Slow idle cooling cannot stand in for paid quenching. This is still a selected normalized radial model: validation of actual daily generator dispatch/full SaveSystem, apparatus qualification, shaft geometry and calibration remain required before registration. Calendar synchronization is lazy on the production advance entry; no separate global clock/owner was added.
Targeted induction suite: 4/4 passed, no errors/skips, 1.179s, /tmp/tt-induction-outage-tests-final.log. Covers partial labor serialization, exact total work/energy, mandatory tempering, cool inspection, water outage/resume, poor coupling rejection, replay tampering, skipped-quench rejection and repeated/adjacent idle days. An initial GDScript inferred-bool parse error was corrected; final run clean.
Save scope: this unintegrated WIP induction record now requires last_day and the expanded cycle/temper history. Initial worker-only induction prototype records are not migrated; no canonical save could contain this unregistered route. Existing canonical recipe/job schemas unchanged. Batch remains HELD; four method paths still unbuilt and integrated count remains856.

### Residual-stress measurement path and suspended induction correction
Added residual_slitting.gd, slitting_workshop.gd and three recipes. A paid selected strip is plastically bent, unloaded to zero resultant force/moment and cut incrementally. Three depth readings contain measured strain and uncertainty; the observer solves the triangular compliance relation and propagates uncertainty, inferring the last two layers through unloaded equilibrium. Loaded measurements are rejected. Raw latent residual values do not enter the observer. Source preparation, work/energy and each cut reading are reconstructed during validation. Reports are consumed when calibrating a slitting station; the station still needs application to independently manufactured workpieces before method promotion.
This is a normalized five-layer strip with a layer-release beam approximation, not a finite-element slit solution, arbitrary part geometry or certified stress measurement. Calibration fixture geometry, material-dependent elastic/plastic constants, instrument fabrication/qualification, real workpiece provenance and the calibrated-station downstream application remain incomplete. Primary method reference: https://www2.lanl.gov/residual/method.shtml (incremental material removal, measured strain versus depth, compliance inversion). No discovery registered.
Integrator-reported induction issue fixed: P.advance now evaluates eligibility and supplies zero usable work to idle synchronization when a persistent line is ineligible. Actual military production-day test reaches target stock while a hot workpiece is pending, with power/water and nominal labor available; thermal ticks stop and the hot part cools. This covers the prior gap beyond paused/zero-work tests.
Verification: residual slitting2 + induction5 =7/7 passed, no errors/skips,2.130s, /tmp/tt-slitting-connected-tests-final.log. Tests cover zero unloaded force/moment, inversion accuracy within propagated uncertainty, externally loaded rejection, paid partial save roundtrip/readout corruption rejection, report consumption and actual production-day target suspension. Initial parser failure from reserved identifier signal was corrected before the clean run.
Optional slitting job fields leave existing schemas unchanged; new WIP data only. Shared modifications confined to additive Industry and approved P/Ops hooks. No canonical/main edits. Nine of twelve methods now have partial operating paths; fracture toughness, welding metallurgy and vacuum melting remain unbuilt. Batch remains HELD pending applications, qualification, acquisition/closure, full-save/daily checks and integration.

### Fracture trial operating path (HELD)
Added fracture_trial.gd and fracture_workshop.gd, three recipes and approved P/Ops retained-job hooks. A selected compact-tension coupon consumes material/tool/paper supplies, paid preparation,1,000 fatigue-precrack cycles,15 increasing-opening load points and post-fracture front measurements. Initial/final three-point fronts, orientation, dimensions and force/opening trace remain attached to the source job and reserved material. Reconstruction rejects forged cycles or changed evidence. A paid reference-station recipe consumes the provisional record.
The observer checks precrack length, crack-front uniformity, monotonic opening, departure from initial loading slope, load nonlinearity, ligament/thickness bounds and actual extension. Failed checks return comparison_only. Successful results are selected_specimen_provisional, never certified K_IC. The geometry factor follows the compact-tension expression reported by NASA: https://ntrs.nasa.gov/api/citations/19920021173/downloads/19920021173.pdf?attachment=true . Precracked initial/final measurements follow the method distinction described by NIST: https://www.nist.gov/publications/assessment-different-approaches-measuring-crack-sizes-fatigue-and-fracture-mechanics . This is not a complete standards implementation.
Limitations: normalized selected specimen response, fixed reference resistance, simplified fatigue growth and discrete secant/peak selection; independently measured elastic/yield properties and geometry calibration, fatigue load-range validity, source-lot-specific materials, final-front uniformity/measurement uncertainty, comparison station downstream damage-tolerance application and full daily/save/closure remain pending. Do not register/promote it yet or claim general metal toughness prediction. Reference stations do not themselves provide field damage tolerance.
Tests: fracture2 + residual2 all4 passed, no skips/errors,2.066s, /tmp/tt-fracture-connected-tests.log. Actual paid precrack at500cycles reloads, stalls without power, completes and consumes report into a station. Observer rejects thin geometry, missing precrack, malformed loading trace and absent measured extension. First tool invocation used a mistyped runner path and ran no tests; only the subsequent four-test run is evidence.
Save compatibility: new optional fracture records only, no existing job schema changes. Shared-file scope remains additive Industry and narrow P/Ops. No canonical edits. Ten of twelve method paths now partial; welding metallurgy and vacuum melting remain unbuilt. The entire batch stays HELD/unregistered and canonical discovery count remains856.

### Welding metallurgy selected-joint path (HELD)
Added weld_metallurgy.gd/weld_workshop.gd, welded strap qualification and bearing-frame consumer recipes. Reserved1.02 selected steel units and preparation/flux/inspection supplies produce one accepted or rejected strap plus.02 destructive witness sections. The retained record reconstructs local weld/adjacent/base temperatures, pressure bonding and oxide expulsion, then controlled cooling. Observation contains a resolved joint-section pixel line, indentation traverse and bend-opening trace; qualification uses those observations, not direct latent bond state. Actual accepted straps are consumed into existing Shaft Bearings stock.
Two targeted tests pass (617ms), /tmp/tt-weld-tests.log: controlled cooling accepts, rapid cooling and an incomplete bond reject; observer remains independent after latent state changes; paid partial record reloads and the actual consumer debits accepted output. These are selected normalized responses, not general alloy welding predictions. Relevant method references: https://www.twi-global.com/technical-knowledge/faqs/what-is-forge-welding and https://www.twi-global.com/technical-knowledge/faqs/what-is-the-heat-affected-zone .
Still HELD: current qualification settings are fixed per recipe; separate source-lot process choices and comparative production histories, actual hammer drive/service qualification, calendar cooling/outage behavior, calibrated witness preparation/bend geometry, independent residual/fracture application, full-save/daily/capital closure and acquisition are incomplete. The current scalar paid energy is a declared workshop budget, not a calibrated calorimetric balance. Do not count this as a completed registered discovery. New optional weld records only; no canonical schema/main changes. Shared changes confined to additive Industry and approved P/Ops hooks. Eleven of12 now partial; vacuum melting remains unbuilt.

### Vacuum melting selected-charge path (HELD)
Added vacuum_melt.gd/vacuum_workshop.gd plus chamber, selected copper melt and wire-consumer recipes. A retained1.05-unit copper charge undergoes pumping, heating, gas release, cooling and section inspection. Leak-dependent chamber pressure limits degassing. The source-gas balance separates dissolved/headspace/extracted gas; metal vapor loss, casting sprue and destructive witness mass are recorded. Accepted or rejected cast mass is actual remaining mass rather than an automatic1-unit yield. The output plus.02 witness,.01 sprue, condensate and extracted source gas balances to the original charge. Existing oxides are not claimed removed and no general chemical purity inference is made from section porosity.
Tests vacuum2+weld2 all4 passed, no errors/skips,1.153s, /tmp/tt-vacuum-connected-tests.log. Demonstrates leakage causing rejection, gas/metal balance, actual partial reload and accepted cast metal consumption into Copper Wire. Pressure/temperature/gas records reconstruct against the paid work. Relevant primary scope reference: https://www.ald-vt.com/wp-content/uploads/2017/12/general-broschure.pdf .
Limits: selected initial gas condition is assumed, not independently assayed per source lot; chamber leak and treatment settings fixed per recipe; calendar leakage/solidification through interruptions and separate pump/heat service receipts incomplete; gas model is normalized rather than species-resolved equilibrium, air leakage not a tracked commodity mass; full composition testing, capital qualification, actual daily/full-save behavior and acquisition/closure remain required. Inspection currently samples modeled section porosity and cast mass only. New optional job record; existing canonical schema unchanged. No main/art/registration changes.
All12 authorized methods now have partial paths. This is NOT READY: residual/fracture still need independent workpieces and calibrated downstream decisions; each method retains the qualification, source-provenance, calendar/daily, full-save and supply/acquisition gaps documented above. Next implementation work should close these gaps, not promote partial paths or add more apparatus-only records. Integrated count remains856.

### Independent formed workpieces and residual-stress disposition
Added formed_workpiece.gd and four recipes: gentle/heavier cold forming, external residual assessment, and checked-blank bearing manufacture. Forming consumes actual steel in a separate production job, retaining one bounded source record until collected; the assessment consumes that record once and the corresponding material stock. The paid observer receives cut-depth strain readings from the independently produced bar. Its measured stress plus propagated uncertainty determines whether the remaining.8 material becomes Stress-Checked Steel Blanks or Stress-Rejected Steel Blanks;.2 goes to destructive coupons. Accepted stock is actually consumed into Shaft Bearings. This advances residual assessment beyond the earlier self-generated reference/station-only path.
The calibrated station uses declared1e-6 normalized strain resolution versus1e-5 for reference apparatus; coarse uncertainty cannot satisfy the.2 disposition bound. The bound was not relaxed. Actual independent fabrication/verification of this resolution is still capital-qualification work, not established by these tests. The selected five-layer elastic/plastic bar approximation remains unchanged; no arbitrary-geometry assertion.
Tests3/3 passed, no errors/skips,826ms,/tmp/tt-external-residual-final.log. Independent gentle/heavy forming leads to accept/reject respectively, source collection is recorded, partial assessment serializes with both job records, and the accepted consumer debits. Test fixture explicitly provides two production lines; initial one-line fixture could not start the independent assessment. A floating-point mismatch in the supported calibrated uncertainty constant was corrected before the clean run.
Source metadata lives on the existing job, not a new global/save owner. Closing/retooling a producer loses uncollected provenance; stock alone cannot be assessed as traceable. Cross-job duplicate-source validation, cancellation/retained-source lifecycle, material-supply/capital qualification and full SaveSystem/daily tests remain necessary. Current record changes affect isolated unregistered prototypes only. All12 remain HELD and unregistered; no canonical/main edits or count increase.

### Cross-job source validation and independent fracture disposition
Formed.validate_links now runs after per-job production validation. It rejects duplicate source ownership/consumption, nonpersistent trial claims and disagreement between a retained producer record and consuming trial. A closed producer need not remain in the queue: the consumed source snapshot stays with the trial. Both residual and fracture tests prove rejection of a restored unconsumed producer and a second consuming job claiming the same source.
External fracture assessment now consumes a separately manufactured traceable bar through the same one-use handoff. The selected specimen response varies with plastic work derived from the producer's forming history; its observed precrack/force-opening/final-front record is evaluated without exposing that latent resistance to the observer. A provisional measured threshold routes.8 remaining material to Toughness-Screened Steel Blanks or Toughness-Rejected Steel Blanks;.2 remains the broken specimen. An actual bearing-frame recipe consumes accepted stock. This closes the apparatus-only nature of the initial fracture path, but does not establish certified damage tolerance.
Limitations remain explicit: selected normalized constitutive relation and threshold, independent material-property/calibration evidence, geometry/uncertainty/standard validity refinements, cancellation/retool source lifecycle and full-save/daily/supply qualification. Source snapshot validation establishes internal consistency, not cryptographic provenance. No new global owner or save authority. The unregistered worker prototype's finished fracture record now includes its disposition; no canonical save is affected.
Six residual/fracture tests passed, no errors/skips,1.648s,/tmp/tt-independent-metal-assessment-final.log. Source-link-only intermediate3-test run also passed. Initial combined run found a GDScript inferred-bool parse error; explicit bool fixed before the clean run. Tests cover two independent forming histories, measured accept/reject, actual accepted consumers, duplicate/revived source rejection, producer-absent retained evidence, precrack reload and malformed geometry. No broad suite repeated beyond these changed paths. All12 methods remain HELD/unregistered; no main or art changes, count856.

### Whole-game persistence and formed-source lifecycle
Full SaveSystem.save_game/load_game now exercised across13 retained process scenarios in separate actors: normalizing, induction fractional work, both casting routes, alloy phase survey, honing, superfinishing, reference residual/fracture, weld/vacuum, and independent residual/fracture with their separate producer jobs. Exact queues and material stocks survive clearing/reloading the world; each process resumes to an output. This proves the exercised save boundary, not whole-campaign pacing or complete daily autonomous operation. The first run correctly stalled induction inspection because the fixture omitted Paper; the corrected fixture supplies the actual inspection requirement.
Integrator-authorized military_campaign.gd hotspot change is exactly one line in cancel_equipment_job, invoking P.close before persistent-job removal. P.close delegates to Formed.clear. Finished unconsumed source quantity is downgraded once into Unqualified Formed Steel with exact debit; unfinished reserved feed is never refunded. Secondary source stores use existing with_city_resources. If an original store cannot safely resolve (including primary stock from an active secondary scope), cancellation/retooling returns a store-specific error and retains the line/ownership rather than touching current stock. Consumed/absent records are idempotent. Missing/non-string pending site and impossible unfinished-plus-uncollected source states are rejected.
Final verification:4 lifecycle cases plus1 full-game save test encompassing13 retained scenarios;5/5 passed, no errors/skips,12.115s,/tmp/tt-metallurgy-save-lifecycle-final.log. Includes actual cancellation and retool, repeat cleanup, partial no-refund, consumed piece, unavailable-store retention, exact original-secondary-store downgrade with current-store stock untouched, malformed source data and full source/consumer queues. Test save slots are unique codex_metallurgy timestamps and only their created files are removed. No player launch or canonical edits.
This removes the exercised full-save and formed-source cleanup gaps. Method-specific apparatus/measurement fidelity, supply closure, remaining thermal/calendar operation gaps, actual generator-driven daily trials and acquisition/registration still remain. HELD. Include the one-line military hotspot explicitly in the eventual frozen handoff.

### Structural supply closure and missing ink repair
Added isolated tools/technology-review/audit_metallurgy_supply.gd. It supplies the12 prototype discovery IDs only to the audit, without registering them, and includes deferred metallographic/induction inspection supplies in fabrication closure. The audit found four residual/fracture recipes consuming undefined Ink; corrected them to the existing Printing Ink supply chain and updated the affected fixtures.
Clean structural audit:729 recipes (including5 analytical routes),27 facilities,9 closure rounds,0 unknown sources/gates and0 blocked recipes/facilities. /tmp/tt-metallurgy-supply-audit-fixed.log. This assumes all knowledge/raw resources available and quality-success outcomes; existing specialist external reserves remain explicit. It does not verify finite quantities, geography, calendar, labor, capital qualification, research-material coupling, external stock exhaustion or campaign viability. Initial audit tool eager preloads encountered autoload initialization errors; deferred runtime loads corrected that before the clean run.
Affected operating tests: residual3+fracture3,6/6 passed without errors/skips in1.666s,/tmp/tt-metallurgy-ink-tests.log. This removes missing source identity blockers, not the remaining operational/qualification gates. All12 remain HELD/unregistered; no canonical changes.

### Generator-driven daily process execution
Added test_metallurgy_daily_power.gd. Eleven separate actor scenarios commission a steam generator through Ops.install and10 real installation days, then invoke Ops.advance and MilitaryCampaign._process_equipment_production_day until process completion. No electricity service is injected. Actual coal decreases, reserved work proceeds after feed leaves free stock, accepted output is produced, and saved job validation passes. Scenarios cover normalizing/section inspection, induction, both casting routes, phase survey, honing/superfinishing, residual/fracture references, weld and vacuum.
One test with11 scenarios passed without errors/skips,3.317s,/tmp/tt-metallurgy-daily-power.log. Inputs, apparatus and generator construction materials are seeded, so this does not prove capital fabrication or novice progression. Discovery adoption is supplied in the isolated fixture, not registered. The fixture provides a healthy100-craftsperson workplace and sufficient fuel/water, runs at most200days per scenario, and proves normal daily dispatch only. Independent source-to-assessment, thermal interruption consequences, finite research acquisition and full-history pacing remain outside this check.
This removes the normal generator/daily dispatch uncertainty for the exercised process routes. Remaining review should focus on the documented behavioral/qualification gaps rather than repeat these unchanged checks. All12 methods still HELD/unregistered; canonical count unchanged.

### Calendar interruptions for welding and vacuum melting

Added retained pause events and a last-observed day to both pending process records. Persistent production synchronizes them before returning for ineligible or unstaffed work. Idle days cool the workpiece; an unpowered vacuum chamber approaches ambient pressure according to its selected leak coefficient. Paid work, charge ownership and accumulated extracted gas remain unchanged. Reconstructed evidence and final witnesses include those interruptions, including after serialization. Repeated calls on the same day do not cool twice.

Verification: five tests across test_metallurgy_interruptions.gd, test_weld_metallurgy.gd and test_vacuum_melt.gd passed, zero errors/failures/skips/orphans, 1.678 seconds; /tmp/tt-thermal-interruptions.log. New integration regression covers both recipes, paused days, power loss, reload, resumption and record validation. Existing tests retain accepted-product consumers and vacuum charge conservation. No full campaign or player launch performed.

HELD: all twelve discoveries remain unregistered. Normalized cooling/leak response is not calibrated physical time or calorimetry; fractional powered days still use paid-work timing. Other metallurgy thermal adapters still need interruption handling. Capital fabrication/qualification, independent material assays, full acquisition/branching promotion and imagery remain outstanding. New WIP records require pauses/last_day and reject earlier isolated WIP records; no canonical save schema changed. Shared conflict: persistent_production.gd adds two idle synchronization calls beside the induction hook.

### Branching and purchased-research integration evidence

The isolated discovery definitions now list their actual gated production items and operating contracts. No catalog registration changed. A new acquisition suite injects the twelve definitions only into its test catalog and resets that catalog afterward. It exercises actual research purchase dispatch, payment, foreign negotiation, return delivery and local Knowledge work for each identity. Delivered studies become evidence with the existing 2.5 study multiplier; they do not grant discovery mastery, equipment queues or welded stock. A second case removes every ALL parent and every OR group, then tries each alternative, against both local and imported-evidence routes. Imported evidence preserves foundations. Both cases passed (twelve purchase scenarios plus all branch mutations), zero errors/failures/skips/orphans in 7.491 seconds; /tmp/tt-metallurgy-acquisition.log. This proves selected purchase/branch behavior, not all scholar, partnership, loss-recovery or campaign pacing paths.

New operating-identity gap found: metal_grain_size_measurement has inspection code but no independently gated operation. Normalizing currently performs that measurement internally. It therefore cannot yet count as a distinct operating discovery. Fix its explicit operating capability before registration; do not count recipe metadata as implementation. The eleven other identities have mapped recipe gates, but that mapping alone does not prove their capital chains or complete operating contracts. All twelve remain HELD.

### Grain-size measurement now gates the actual inspection stage

Normalizing's recipe declares metal_grain_size_measurement as its inspection gate. Heating can proceed independently; the retained steel then waits without spending section supplies or inspection electricity until the method is known and adopted at the existing 0.10 production threshold. Persistent production reports that specific reason and does not allocate productive work to the held inspection. The section adapter independently checks the gate, so direct calls cannot bypass it. The discovery definition lists the inspection operation and its physical contract. This addresses the operating-identity gap recorded above without introducing a duplicate normalizing discovery or granting stock on research.

Regression verifies unknown and under-adopted measurement both block, the workpiece and stocks remain unchanged, and adopted measurement resumes sectioning and supplies accepted steel to the existing shaft consumer. Five tests passed across workshop, daily generator dispatch (11 scenarios), and full SaveSystem roundtrip (13 scenarios), zero errors/failures/skips/orphans in 14.968s; /tmp/tt-grain-operating-gate-fixed.log. Initial run had two test-only type-inference errors and a later engine crash; those are not counted as success. The corrected run completed normally. No player launch or canonical changes.

No save shape changed in this gate change. A previously saved unfinished normalizing specimen may now wait for grain-measurement adoption; already completed products are not revoked. Purchased research retains its tested evidence/study route. Direct production licensing for an inspection-only subject is not currently offered by the shared license system and was not added here. Remaining: capital/measurement qualification, selected-material characterization, other retained thermal interruptions, full recovery/partnership/scholar coverage, promotion and imagery. All twelve remain HELD. Shared conflicts: civilian_industry.gd recipe field; persistent_production.gd inspection wait reason. No military_campaign.gd edits in this commit.

### Idle heat-treatment cooling

Pending metallurgy thermal work now records last observed day and cumulative idle days. Persistent production synchronizes this before eligibility returns; the adapter also synchronizes direct advancement. Missed days cool the workpiece using the current stage's passive loss and heat capacity. No paid work, energy, coolant or hot-work credit is awarded. Same-day calls are idempotent; inspection waits also cool. Calendar fields are validated and retained through serialization.

Four workshop tests passed in 1.177s, zero errors/failures/skips/orphans, /tmp/tt-normalizing-idle-fixed.log. A hundred-day interruption cools the selected specimen below30, preserves paid quantities and prior hot work, survives serialization, and resumes with less hot work than an uninterrupted cycle. Initial test expected total hot work below1, but the run already accumulated1.3 before interruption; corrected the assertion to measure preserved prior work and no additional cold hold credit. This exposes an existing limitation: acceptance uses cumulative hot work, not a qualified continuous hold. No claim that this alone makes normalizing fully physical. Full SaveSystem and daily campaign checks were not repeated for this change.

HELD. New isolated pending records require last_day/idle_days; older WIP pending records without them are rejected. Canonical remains unchanged. Remaining includes continuous thermal-history qualification/replay, casting and phase-trial calendar behavior, capital and material qualification, full research recovery routes, catalog promotion and art. Shared conflict: one synchronization call in persistent_production.gd. No other worktree or player session changed.
