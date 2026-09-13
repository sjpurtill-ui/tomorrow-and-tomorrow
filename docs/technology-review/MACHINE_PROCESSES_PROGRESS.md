# Machine process implementation — in progress

Worktree `/Users/seanpurtill/Documents/Codex/tt-machine-processes`; branch `codex/machine-processes`; base verified 823 checkpoint `d4d3497dfe54cf0f087e843f5385a0852ad9c0be`. Integrator owns canonical main, imagery and textile/clothing/planner/panel changes. Microscopy is separately frozen for integration.

Approved 13 identities: fluid_film_bearings, cutting_fluid_management, machine_tool_stiffness_assessment, machine_condition_monitoring, numerical_machine_control, gear_power_skiving, wire_electrical_discharge_machining, sinker_electrical_discharge_machining, electrochemical_machining, abrasive_waterjet_cutting, ultrasonic_abrasive_machining, incremental_sheet_forming, ultrasonic_metal_joining. Authored ALL/OR copied exactly from machinery-fibers-earth.json and manufacturing-process-depth.json into unregistered machine_process_knowledge.gd. No operating count increase.

Coordinate execution now retains an immutable copied instruction list, position, cursor, completed-instruction trace and consumed work/energy. It advances along actual coordinate segments at each instruction's feed, stops at the supplied energy budget and resumes partial motion. Invalid paths and geometrically inconsistent saved progress fail closed. It produces no resources; workshop owner must debit service receipts and reserve actual compatible material/apparatus before invocation. `/tmp/tt-machine-coordinate.log`: 4/4 tests cover power-limited movement, resumed serialized state, zero-power/no repeated completion spending, invalid feed/position and skipped-instruction rejection. This is not workshop integration or whole-save proof.

Next implementation uses existing PersistentProduction/Ops authorities. Coordinate paths must drive specialized candidate production; no catalog-only production or generic global bonus. Each method needs distinct capital and compatible feed, work/energy, consumables and retained accepted/rejected parts. Fluid-film loss must affect loaded apparatus; cutting fluid must have actual supply/filter/waste cost; stiffness must be measured under load and constrain path tolerance; condition observations must govern maintenance eligibility. Existing consumers include generated-gear drives, checked bearing assemblies and motor housings/leads. Typed candidate inspection must precede downstream assembly, with no substitution of uninspected stock.

Outstanding: coordinated additive PersistentProduction dispatch/cleanup/validation and Ops state hooks; finite apparatus/recipes/process progression/inspection, local saved pending material, fail/recover behavior, downstream acceptance, paid acquisition, graph/source reconciliation and root art. Do not register or promote these 13 until operating proof exists.


## Persistent reserved workpieces

Integrator approved narrow PersistentProduction dispatch, cleanup and validation hooks. machine_workshop.gd now reserves a full compatible feed exactly once in the existing job, retains source job/ordinal/store/program, spends actual Ops electricity against path work, and pauses the resulting workpiece at inspection without producing accepted stock. Product changes abandon reserved material without a free refund. The persistent job state bypasses rechecking already-reserved feed and checks store ownership. No new Ops global ledger or save owner was needed.

`/tmp/tt-machine-workshop.log`: 20/20 (3 workpiece tests, 4 coordinate tests, 13 existing abrasive finishing cases). Checks cover single debit, serialization and resume, no power/no reservation, wrong-store inactivity, feed-provenance mutation, no output before inspection, plus inherited abrasive actual save and actor separation. New workpiece tests use an explicit test recipe; no production recipe or discovery has been registered. Actual machine recipes, apparatus, physical process measurements/acceptance and downstream consumers remain to implement. This adapter is infrastructure, not completion of any of the 13 discoveries.


## Typed manufacturing routes

Added 25 additive recipes: coordinate table; eight distinct process heads and eight inspected-part routes; eight downstream assembly/finishing recipes. Skiving, wire/sinker discharge, electrochemical machining, waterjet cutting, ultrasonic abrasive machining, incremental forming and ultrasonic metal joining reserve compatible feed/consumables, execute retained paths and spend a separate inspection stage. The paired process measures distinguish pitch/flank error, kerf/recast, cavity/electrode loss, profile/overcut, taper/roughness, hole/chipping, thinning/springback and unbonded fraction/joint damage. These are explicitly bounded game error models, not measured real-world engineering tolerances. Wear is captured at workpiece start and retained; subsequent tool changes cannot rewrite its report. A failed measured acceptance releases typed rejected stock, never accepted stock.

`/tmp/tt-machine-parts.log`: 5/5 pass, including a loop through all eight real PersistentProduction part recipes (startup capital, path completion, paid inspection and accepted stock), worn-waterjet rejection, and the three reserved-workpiece cases. Nested pending and completed reports validate recipe/source/ordinal/retained path/wear/physical measures/inspection payment/acceptance. This does not yet establish the downstream recipes, full save, or actual apparatus production from reachable inputs.

Remaining: fluid-film/cutting-fluid/stiffness/condition operations with actual apparatus consequences and paid maintenance; richer process controls beyond present feed/travel/wear measures; verify apparatus/input reachability and all downstream consumers; actual power exhaustion/restore and whole-save partial inspection; branching/recovery/acquisition, catalog registration and imagery. All13 remain unregistered, and no operating-count increase is claimed.


## Support apparatus and repair work in progress

Four paid apparatus recipes and per-line support state now exist. Loaded deflection and vibration observations spend work/paper/copper, retain measured values, stop deterioration for actual Steel/Graphite repair and partial repair work, and require recheck afterward. Small observation work accumulates without repurchasing completed observations. Water-bearing and filtered cutting-water installations require actual water/filter supplies during work; filtered effluent becomes Spent Machining Water. Supplied support reduces subsequent tool wear within the bounded model.

`/tmp/tt-machine-support.log` passes5/5 (3 support cases and2 eight-process/rejection cases). These are provisional. Integrator review correctly requires load/speed/flow-dependent film separation and a meaningful filter/chip/thermal effect beyond counters or wear credit; these remain outstanding. Selected bearing concept is water-supplied plain bearings, communicated to art owner. Also outstanding: process-specific paid inspection witness/apparatus and observable proxies, rather than universal exact latent readings; joint witness/proof and recast-section versus visible edge distinction. Saved support-state validation is not yet complete. No registration or handoff readiness.


## Bearing support and filter condition

Water-film support now evaluates normalized supported load, speed and supplied flow, and refuses motion when separation is below the selected threshold. Default operating load derives from retained toolpath feed plus current wear; no-fluid operation cannot obtain separation at any speed. Actual supported work retains flow/load/speed/separation and paid water in a dated observation. These are selected normalized bearing conditions, not universal engineering performance claims.

Filtered cutting water accumulates captured debris into a bounded filter load. Saturation constrains further machining; service consumes replacement cloth and retained partial work before clearing the filter, and sends the used element to Spent Machining Filters. Servicing runs during a paused pending workpiece without refunding or replacing its feed.

`/tmp/tt-machine-flow.log`: 7/7 support plus eight-process/rejection cases pass before the final default-load derivation from feed/wear; final derivation requires the next relevant combined check. Remaining review focus is process-appropriate paid witness/inspection proxies, support save validation and actual downstream/power/save/acquisition proof. No discovery registration.


## Process-specific observation and witness correction

Inspection now retains a method, quantized readings, resolution/uncertainty and paid installed apparatus appropriate to the process. Wire discharge edge-layer inspection requires a reserved .02 sheet witness, blade/abrasive/slide preparation and a compound microscope. Joined tabs reserve .03 copper from their actual feed for a destructive pull witness; the reported proxy is proof slip and visible joint damage, not an unsupported unbonded-area fraction. Witness source job/ordinal/store/material is immutable; preparation and destruction persist across partial inspection and cannot be omitted or reused. Remaining methods use master-gear roll/contact, cavity replica/electrode comparison, profile/overcut template, opposed kerf faces, magnified bore/chip observation or thickness/released-shape comparison.

Nested support validation now checks bounded repair/filter progress, paid service consistency, installed apparatus, measured decisions, observation dates/revisions and film separation/water receipts. `/tmp/tt-machine-inspection-validation.log` passes12/12 across support, all eight typed processes/rejection/witness cases and reserved-workpiece tests. This includes the final feed/wear default-bearing load from the previous commit. One earlier run had a test variable type-inference parse error and crashed; the variable was typed explicitly and the affected combined run passes. No broader or full-save claim.

Next: actual whole-save job/support/inspection continuity and power restoration, downstream assemblies and reachable apparatus inputs, product-change wear continuity, selected gear synchronization distinct from a generic XYZ move, acquisition/predicates/registration and art integration. Root separately completed13art in a06e1c19c10e1e83a3802a4674a79b679042fdef; still unbound. No operating count increase.


## Selected skiving synchronization

Skiving now executes and retains opposed cutter/workpiece turns for one explicitly selected external 30-tooth workpiece / 10-tooth cutter configuration at a 20-degree crossing angle. Axial feed progresses alongside those rotations. Loaded phase deviation depends on retained apparatus wear and contributes to the measured pitch-error channel. A completed XYZ path without a matching spindle record cannot pass inspection or saved-state validation. This is a bounded selected configuration, not a general involute tooth-surface solver or arbitrary gear program.

`/tmp/tt-machine-skiving.log`:5/5 process/witness tests pass, including all eight part recipes, partial spindle serialization/resume and missing-synchronization rejection. Full-save/integrated support continuity, product-change wear ownership, downstream/input reachability and acquisition/registration remain; no discovery-count increase.
