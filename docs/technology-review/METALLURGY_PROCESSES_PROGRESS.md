# Metallurgy, casting and finishing — implementation in progress

Worktree: `/Users/seanpurtill/Documents/Codex/tt-metallurgy-processes`.
Branch: `codex/metallurgy-processes`.
Base: verified 843 checkpoint `59f146e5fa9badfa24f147e3adad48d9a3bc968e`.
Not an integration handoff. No new operating discoveries claimed.

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

Also pending: full material closure audit, acquisition checks, save validation,
imagery and canonical integration. The integrator owns imagery and the shared
manufacturing merge. Do not edit PersistentProduction or the machine adapters
until updating deliberately to its forthcoming verified manufacturing base.

The full project objective remains 5,000 distinct authored and operating
discoveries, validated branching/recovery, viable full-history progression,
civilian/military consequences and the approved imagery. This batch is only a
portion of that unfinished objective.
