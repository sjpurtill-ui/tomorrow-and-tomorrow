# Military campaign services: review proposal

Nine additional D20 discovery proposals. These are design contracts, not operating discoveries. The batch adds no live units, runtime code or images. Its historical horizon labels are editorial proposals, not first-invention dates or a validated campaign calendar.

Generals allocate personnel, equipment, movement and service priorities. The player discusses objectives and sees shortages and consequences through existing conversations. GovernmentPeopleSystem remains responsible for settlement labor and civic officials; MilitaryCampaign remains responsible for military rosters and losses. A named service role below is a capability consumer, not an additional discovery or a free specialist.

## Distinct capabilities and implementation evidence required

### Military Billeting Allocation

Match actual arriving service personnel to available shelter while recording household occupancy and compensation obligations.

Requires: militia_muster_registers, census_rolls.

Paid operating inputs: Dated local capacity survey, authorized quartermasters, shelter access, bedding, food and actual institutional access, requisition and compensation obligations with finite resources.

Player consequence: Sheltered troops can recover from exposure, but occupied beds cannot also shelter civilians; overcrowding and unpaid obligations damage health and relations.

Boundary: Muster registers establish who owes service; this allocates scarce occupied shelter without creating buildings.

Acceptance scenario: Two arriving groups cannot reserve the same beds; denied access leaves soldiers unsheltered and unpaid bills persist.

### Campaign Baggage Prioritization

Allocate finite campaign carrying capacity among subsistence, repair supplies and discretionary baggage, retaining the cost of excluded loads.

Requires: supply_groups, material_accounting.

Paid operating inputs: Actual loads and carriers, measured carrying limits, general-approved priorities and time to repack.

Player consequence: A lighter force can move more readily but sacrifices endurance or repair capacity; stored and abandoned loads remain separate from carried inventory.

Boundary: Supply groups move goods; this resolves competing load demands before departure and exposes what the army leaves behind.

Acceptance scenario: Reducing baggage improves movement only after unloading; omitted food cannot feed troops and no carrier exceeds its physical capacity.

### Field Kitchen Detachments

Organize movable communal meal preparation with an explicit setup, cooking, distribution and pack-down cycle.

Requires: campaign_ration_specifications, supply_groups. Also requires one of: earth_oven_cooking, household_cooking_stoves.

Paid operating inputs: Assigned cooks, carried vessels, suitable food, water, fuel, preparation space and transport; stove and earth-oven routes retain different equipment and setup costs.

Player consequence: Turn actual provisions into served meals during halts; relocation interrupts service and draws cooks from the available workforce.

Boundary: Ration specifications describe food suitability; kitchens deliver cooked meals at a place and time. Domestic stoves alone do not provide a moving service.

Acceptance scenario: A march during preparation preserves or spoils the actual unfinished batch under food rules; neither raw and cooked inventory nor home and army meals are double counted.

### Campaign Equipment Salvage

Recover accessible abandoned equipment into inspected custody, separating repairable items, reusable parts and scrap.

Requires: material_accounting, supply_groups.

Paid operating inputs: Physical access, recovery labor and transport, item provenance, inspection capacity and finite repair materials.

Player consequence: Recover some lost material at the expense of time and carrying space; recovered objects remain unavailable for service until compatible and inspected.

Boundary: Armored recovery retrieves disabled vehicles; field diagnostics identifies faults. This owns recovery custody and finite disposition across ordinary campaign equipment.

Acceptance scenario: Revisiting the same site cannot recover an item twice; inaccessible losses stay lost and incompatible recovered equipment cannot refill a unit.

### Strength Return Reconciliation

Reconcile dated unit strength returns across transfers, absence, hospitalization and confirmed losses without treating nominal enrollment as available strength.

Requires: militia_muster_registers, material_accounting.

Paid operating inputs: Unit clerks, delivered returns with reporting times, transfer references and time to investigate contradictions.

Player consequence: Generals receive a more reliable own-force readiness estimate; unresolved absences remain uncertain rather than becoming recruits or confirmed casualties.

Boundary: Muster records service obligations; this reconciles changing operational presence across units. It does not replace payroll verification or enemy-information fusion.

Acceptance scenario: A transferred person is never available in two formations; late returns cannot reverse confirmed later events or conjure missing personnel.

### Field Telephone Line Deployment

Install, test, maintain and recover temporary wired voice links between actual field endpoints.

Requires: telephone_circuits, signals_detachment_training.

Paid operating inputs: Compatible instruments, finite wire, power sources, line crews, accessible routes and repair time.

Player consequence: Command messages travel through working field links with delay and outage; moving headquarters can strand endpoints and consumes relocation labor.

Boundary: Telephone circuits supply voice transmission; exchange networks connect subscribers. This qualifies a temporary moving field installation, not encryption.

Acceptance scenario: Broken or unpowered links stop delivery; recovering wire removes that link and cannot duplicate its inventory.

### Artillery Sound Ranging

Interpret coordinated acoustic observations as an uncertain, dated source-location report within a qualified observation envelope.

Requires: geodetic_reference_frames, military_cartographic_reporting, acoustic_diaphragms, signals_detachment_training.

Paid operating inputs: Trained observers, functioning acoustic recorders, checked timing and survey references, environmental observations and maintained communication.

Player consequence: Generals gain fallible indirect observation when a detectable event occurs; noise, timing errors and missing stations can make a report unusable.

Boundary: Observation liaison carries reports; this produces an acoustic observation. It does not automatically aim weapons or reveal all enemies.

Acceptance scenario: No event produces no location; inconsistent timing or inadequate observations withhold a location rather than providing perfect hidden state.

### Artillery Flash Spotting

Associate separately observed brief optical events into a qualified, dated location estimate while retaining ambiguous associations.

Requires: geodetic_reference_frames, military_cartographic_reporting, signals_detachment_training.

Paid operating inputs: Trained observers, surveyed observation positions, suitable optics, adequate visibility and an operating reporting link.

Player consequence: Provide a distinct visual observation channel whose usefulness changes with visibility and obstruction; unrelated events cannot be assumed identical.

Boundary: Sound ranging observes acoustics; flash spotting depends on visual event correspondence. Neither substitutes for the other under all conditions.

Acceptance scenario: Obscured or unmatched observations do not reveal a precise source; duplicated reports of one event are not independent evidence.

### Military Decoy Fabrication

Build and evaluate expendable visual representations that may be mistaken for specified equipment under limited viewing conditions.

Requires: field_concealment_practice, material_accounting.

Paid operating inputs: Craft labor, actual frame and covering materials, transport, deployment time and independent visual evaluation.

Player consequence: A deployed decoy may influence an observer interpretation but has no fighting strength; inspection, weather and viewpoint can expose it.

Boundary: Concealment changes exposure of real assets; this creates a separate physical false visual object. It cannot alter an opponent belief without observation.

Acceptance scenario: A fabricated object consumes material, has zero combat capacity and only affects an observer through the same fallible sighting model as other objects.

## Branching and recovery

Nine proposals use mandatory AND foundations. Field kitchens additionally use one OR group: earth-oven cooking or household cooking stoves. That is a choice of operating method, not free access to either equipment chain. Imported service can be used without granting domestic mastery; local discovery must still satisfy its foundation and demonstration predicates.

Every entry carries an explicit recovery contract. Scholar envoys need a competent reachable source, payment or trade, travel and finite local instruction. Partnerships consume reciprocal contributions and require delivered evidence. Later purchased research pays for investigation, not guaranteed success. Imported services depend on actual supplier staff/equipment and continuing support. Reverse engineering needs an accessible specimen or record and does not recover invisible production knowledge automatically. No route grants troops, duplicate goods, free local expertise or a waived physical operating requirement. Early access to foreign teachers and later research commissioning still need era-appropriate institutions in implementation; this batch does not invent those institutions or certify that they already work.

## Semantic exclusions

Military road traffic and rail timetable entries were excluded because existing road_traffic_coordination and rail_timetable_coordination already own those mechanisms. A military label alone would inflate the tree. Military payroll auditing likewise belongs to existing public_payroll_verification. Pattern camouflage was deferred because field_concealment_practice already covers adapting signatures to conditions; a separate material qualification mechanism would need a stronger distinction. Maritime salvage and armored vehicle recovery retain their existing specialist scopes. Strength returns address dated own-force presence, not payroll or enemy intelligence.

## Historical evidence and its limits

The National Army Museum documents sound ranging and flash spotting as separate observation technologies used on the Western Front: [Weapons of the Western Front](https://www.nam.ac.uk/explore/weapons-western-front). This supports including distinct acoustic and optical channels. Their proposed resource accounting, uncertainty behavior, prerequisites and acceptance scenarios above are game design inferences, not claims that the museum specifies this dependency graph.

The remaining proposals are explicit design candidates requiring historical regional examples before the historical review gate can be closed. No universal invention order is asserted. This batch closes identity and branch authoring work only; it does not certify exhaustive historical review, balance, campaign duration or realistic implementation.

## Integration handoff

Worktree: /Users/seanpurtill/Documents/Codex/tt-military-history-depth
Branch: codex/military-history-depth
Base: 24cfea7d76295608099335083ee2c59956fd32d1

Owned files: this review and master-catalog/military-campaign-services-depth.json. Shared coverage and historical allocation regeneration belong to the integrator. Expected local identity accounting is 3,457 authored identities (3,447 base +10); runtime remains unchanged by this batch. D20 rises from180 to190 of its280 editorial target. Save format is unchanged. No runtime shared-file conflict or player launch.

Implementation remains required for all ten entries, along with dedicated approved-style imagery, historical review and measured progression. Do not promote these rows to implemented on the basis of catalog validation.

Validation: the existing master-catalog checker passed against this worktree with its coverage write captured in memory: 3,457 distinct identities, zero missing parents, zero unreachable drafts and zero normalized-name duplicates. D20 is190/280. Shared coverage files were not changed. `git diff --check` passed. These checks cover structural catalog validity, not historical accuracy or operating behavior; no Godot suite was rerun for these documentation-only changes.

## Integrator disposition

The proposed `artillery_survey_datum_control` identity is excluded: existing `geodetic_reference_frames` already owns consistent spatial references across measured positions. Sound ranging and flash spotting retain that foundation plus `military_cartographic_reporting` for dated, attributable campaign reports. Neither existing identity is rewritten. The remaining nine are authored drafts only. Historical evidence and its unresolved early-horizon limits are recorded in `Military Campaign Services Evidence.md`. Billeting follows actual societal obligations; inspected serviceable salvage can be reissued without unnecessary repair.
