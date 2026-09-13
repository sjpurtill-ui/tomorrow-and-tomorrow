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
