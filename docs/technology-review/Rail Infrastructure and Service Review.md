# Rail infrastructure and service discoveries

READY authored design delivery: 24 new distinct drafts in `master-catalog/rail-infrastructure-service-depth.json`. Worktree `/Users/seanpurtill/Documents/Codex/tt-rail-coverage`, branch `codex/rail-coverage`, base `b363f6c6aceaf42515e020281934cef26cb217fd`. These definitions are proposals for operating implementation, not live gameplay. They add no runtime recipes, facilities or images.

The catalog previously covered rail foundations, turnouts, block signaling, electric traction and continuous brakes at a broad level. This batch specifies the maintenance and interface methods that determine whether those networks can remain usable. Freight and military supply can eventually benefit from reliable rail capacity, while occupation, unavailable parts, route restrictions and work closures can interrupt it. This does not implement that campaign connection or change the general-led command model.

## Proposed discoveries and decisions

| Group | Distinct discoveries | Proposed operating decision |
|---|---|---|
| Track support and material | Rail Fastening Load Transfer; Ballast Tamping; Ballast Fines Removal; Rail Profile Restoration; Rail Thermal Stress Management | Spend materials, crews and service closures to recover qualified condition; use restrictions when maintenance cannot be supplied. |
| Track and vehicle evidence | Rail Internal Flaw Inspection; Rail Geometry Recording; Wheel Rail Profile Qualification; Wheel Rail Friction Management; Wayside Bearing Heat Detection; Wheel Impact Load Monitoring | Pay for observations and respond to findings; neither missing evidence nor a successful inspection repairs physical damage. |
| Movement permission | Rail Track Circuit Detection; Rail Axle Count Detection; Turnout Position Proving; Train Braking Curve Supervision; Rail Worksite Possession Control | Balance network capacity against uncertain occupancy, point condition, stopping evidence and protected maintenance time. |
| Traction power | Overhead Contact Tensioning; Pantograph Contact Qualification; Traction Substation Conversion; Rail Return Current Control; Regenerative Rail Energy Reception | Invest in compatible infrastructure and maintenance; account for supply limits and a real recipient for recovered energy. |
| Route compatibility | Rail Vehicle Clearance Assessment; Rail Route Axle Load Qualification; Platform Train Gap Assessment | Match actual rolling stock and loads to the route, rather than treating track gauge alone as universal compatibility. |

These are distinct qualification or service mechanisms, not renamed locomotives or numerical levels of a generic rail bonus. Existing `rail_gauge_standards` defines compatible spacing; clearance assessment addresses the vehicle envelope, axle-load qualification addresses structural loading, and platform-gap assessment addresses boarding interfaces. Existing `ultrasonic_flaw_mapping` supplies a general observation method; the new rail service adds rail-specific coverage, access and consequence requirements. Existing `railway_interlocking` coordinates permission; turnout proving supplies evidence about the actual switch. Existing electric traction remains the broad vehicle drive capability; the new power methods concern its physical network interfaces.

## Branching review

Every mandatory prerequisite is required and every alternative group requires one member. Internal rail inspection offers qualified acoustic OR magnetic approaches after nondestructive-inspection foundations. Imported inspection equipment is still subject to local coverage trials. There is no invented calendar, nationality or geographical mastery gate.

Electrical conversion does not require the purchaser to discover transformer or rectifier manufacture. Regenerative reception does not force every railway to manufacture capacitors or master a particular grid-estimation algorithm; installed compatible storage or a receptive network is an operating requirement. Braking supervision does not force track circuits or axle counters where another qualified localization and movement-authority system is used. These distinctions prevent equipment-supply alternatives from becoming false learning dependencies.

Each entry includes five proposed disadvantaged recovery contracts: paid traveling specialist instruction, contributed partnership trials, commissioned research, licensed/imported service, and analysis of acquired samples or records. All require actual access, delay, scarce provider capacity and local qualification. Paying for a service grants neither instant mastery nor the ability to manufacture its components. For service practices, reverse engineering means reconstructing evidence and testing it locally; an artifact alone cannot establish hidden procedures.

## Historical and technical evidence

Sources support the physical mechanisms; prerequisite selection, recovery terms and gameplay consequences are design judgments. No cited document establishes the proposed game balance or a unique invention date. H04/H05 mappings are editorial capability horizons and are not calendar unlocks.

- [FTA track inspection and maintenance report](https://www.transit.dot.gov/sites/fta.dot.gov/files/2022-05/FTA-Report-No-0215.pdf), sections 4–5: inspection coverage and track renewal methods.
- [FRA continuous welded rail material](https://railroads.fra.dot.gov/safety-data/forms-guides-publications/continuous-welded-rail): restrained-rail service context.
- [FRA inspection research](https://railroads.dot.gov/program-areas/track-and-structures/inspection-techniques): geometry and support observations.
- [FRA wheel/rail friction research](https://railroads.dot.gov/elibrary/survey-wheelrail-friction): contact and friction-management context.
- [FRA wayside detector guide](https://railroads.dot.gov/elibrary/implementation-guide-wayside-detector-systems): bearing and impact observation systems.
- [Network Rail track circuits](https://www.networkrail.co.uk/stories/track-circuits-explained/) and [points failures](https://www.networkrail.co.uk/rail-travel/delays-explained/signals-and-points-failure/): occupancy and switch-state evidence.
- [Network Rail network statement](https://www.networkrail.co.uk/wp-content/uploads/2016/12/2027-Network-Statement.pdf): route compatibility and alternative train detection.
- [FTA transit systems handbook](https://www.transit.dot.gov/sites/fta.dot.gov/files/2020-09/TAM-Systems-Handbook.pdf), section 3.4: traction-power interfaces.
- [Regenerative braking research](https://arxiv.org/abs/1808.05938): energy reception alternatives.
- [ERA braking curves](https://www.era.europa.eu/mt/node/1831): stopping-envelope supervision.
- [Network Rail track work](https://www.networkrail.co.uk/our-work/looking-after-the-railway/track/): protected maintenance context.

## Validation and integration

`python3 tools/technology-review/check_master_catalog.py` passes. All 24 new IDs are unique, normalized names are unique, every prerequisite resolves and every draft is reachable under the current AND/OR closure. All 24 horizon assignments have matching scope digests. D09 has 108 accounted identities against its 180 allocation; no candidate-atlas completion is claimed. An initially mistyped parent was rejected before writing the catalog and corrected to existing drainage knowledge.

This base contains naval runtime but its committed baseline ledger still records 671 live definitions. Thus this branch's authoring report is 671 baseline + 2,445 drafts = 3,116 distinct identities, leaving 1,884 to author. Main has since reconciled naval promotion to 673. The integrator must preserve that newer baseline and regenerate coverage; promotion changes draft/live distribution, not these 24 new identities or the 3,116 total. Do not overwrite canonical baseline or art catalog from this branch.

Merge the new JSON and this review, append the 24 horizon mappings while preserving any newer mappings, and regenerate coverage. No runtime or save schema changes, no game launch, and no gameplay tests are warranted for this authored-only delivery. Catalog checks prove bookkeeping and dependency closure, not historical completeness, operating capability or millennial progression. Those remain outstanding under the full goal.
