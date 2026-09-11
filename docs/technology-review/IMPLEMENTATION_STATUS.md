# Full-history technology implementation

The user approved the design on September 10, 2026. The target remains 5,000 distinct discoveries across the full historical and future span. The 600 review candidates are subject names awaiting individual production contracts; they are not 600 implemented discoveries.

Current branch state after the fifth checkpoint: **241 live discoveries**, against the 5,000-discovery target. Earlier checkpoint counts below are historical.

## First checkpoint: routes and purchased studies

Implementation worktree: `/Users/seanpurtill/Documents/Codex/tt-technology-implementation`
Branch: `codex/technology-implementation`
Base main: `940d5a2ad848d9f45b8d98825cd5219a3eda83e9`
Approved review brought into this branch as `b1d3406` (same content as design commit `a9562d7`).

Implemented in this worktree:

- Shared AND prerequisites and multiple OR groups; explicit learning routes retain common foundations.
- Foreign evidence can support an alternative causal route, preserving a single discovery and adoption record.
- Manuscript libraries offer a slower alternative to printing; public theatre can build on oral epics or festivals; apprenticeship can build on several crafts.
- Route-specific missing foundations and pace are shown in the research inspector. Alternative links include routes named local; locked questions do not reveal route labels or suppliers.
- After experimental controls and public schools, an exposed unresolved investigation offers research purchasing. The proposal uses ordinary envoys, physical payment goods, provisions and travel. Quotes do not inspect hidden supplier knowledge.
- At the actual encounter, the supplier must know and have adopted the subject, have Knowledge staff, and permit open sharing. The returned study requires local examination before its research multiplier applies. Purchased evidence uses 2.5 times the route baseline; ordinary exchanged evidence uses 1.8. These are initial balance values, not calibrated campaign claims.
- Payment settles through the ordinary counterpart resource ledger on the embassy's return. Refusal, missing delivery or insufficient collection capacity returns unused payment once. Travel provisions remain consumed. Existing studies are not purchased repeatedly and weaker later evidence does not overwrite a purchased study.
- Headless graph audit reports live and proposed counts separately and detects missing prerequisites and unrecoverable causal cycles.

Live count remains 197: this checkpoint changes the underlying rules and acquisition behavior. It does not claim the catalog expansion is complete.

## Remaining approved work

1. Author individual discovery contracts, prerequisites, operation requirements and grounded consequences for the full historical and future catalog. Preserve the approved 24-field and historical coverage targets.
2. Calibrate visiting scholar duration, teaching effectiveness and price across campaign eras; add negotiated terms and opponent invitation strategy. The second checkpoint implements the initial physical visit below.
3. Extend partnerships, research licensing and imported-service dependencies, including interruption and domestic substitution.
4. Implement broader military role families, equipment, doctrine, training, support and general-led behavior. The 96 reviewed roles are not yet a production roster.
5. Add the required civilian and future operating models, then run full-campaign reachability, pacing, conservation, parity and performance checks.
6. Produce the approved paper-and-gouache art for finalized identities and verify its game presentation.
7. Integrate tested checkpoints through the designated integrator and verify the combined canonical build.

## Compatibility and limits

Existing discovery IDs, effects and saves retain their authorities. New fields are optional within the existing exchange/mission records; old saves require no new top-level state. Origin validation accepts authored route IDs. Purchase metadata is validated for type and remains bounded by existing mission/collection limits. Historical records produced by this version are not promised compatible with an older executable.

Rules run in the current WorldSimulation owner scope. The human interface can dispatch purchases; automatic opponent purchase strategy has not been added. Suppliers already use their actual owner state. New pricing uses the existing physical gift quotations; negotiated currency prices, licenses and original research contracts remain pending.

No changes have been merged into main and no player build has been launched. Native visual inspection of the new purchase panel and whole-campaign balance remain outstanding. The headless UI test covers its real offer and dispatch action, not visual rendering.

## Checkpoint verification

Final individual-suite runs: **77 cases passed**, with zero errors, failures, skipped cases, orphan nodes or script errors:

| Suite | Cases |
| --- | ---: |
| Technology requirements | 9 |
| Research purchasing | 10 |
| Society exchange | 26 |
| Technology tree | 9 |
| Discovery projects | 9 |
| Research interface | 9 |
| Diplomatic journeys | 5 |

Command for each suite, using its filename: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/seanpurtill/Documents/Codex/tt-technology-implementation -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a res://tests/test_<suite>.gd`. Suites were run in separate engine processes; a combined invocation unexpectedly discovered only the first suite's count in later suites and was not used as final coverage evidence. Final logs: `/tmp/tt-tech-final-<suite>.log`; machine-readable summary: `artifacts/technology-implementation/test-results.json`.

Graph audit: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/seanpurtill/Documents/Codex/tt-technology-implementation -s res://tools/audit_technology_graph.gd`. Result: 197 live discoveries, four explicit learning routes across the three revised subjects, all existing alternative routes included in causal validation, zero graph errors, 5,000 proposed target, complete_catalog=false.

Shared integration files: `scripts/discovery_system.gd`, `scripts/civilization_system.gd`, `scripts/society_exchange.gd`, `scripts/knowledge_pathways.gd`, and the existing research interface files. No changes to terrain, project settings, civic labor ownership, military campaign control, top-level GameState or SaveSystem. No known conflicts against the unchanged base. Commit only the listed implementation, tests, audit and status record; generated UID files and captures are excluded. This checkpoint is ready for integrator review; remaining approved work above is unfinished.


## Second checkpoint: visiting scholars

Continues from `5b6908b227add8ad36c5734a141eb1dfff436c35` on the same isolated branch. READY for integrator review; not integrated or launched in the player build.

Apprenticeship contracts or public schools enable invitations through the research inspector. The proposal carries a physical payment and prepays the visitor's travel and board. Quotes use known contact information without inspecting hidden supplier discoveries. At the actual encounter, an open-sharing supplier must know and have adopted the subject and retain at least one Knowledge worker after sending one specialist.

The specialist travels with the returning envoys, teaches the selected investigation for 60 days, then travels home. One unit of effective Knowledge capacity is removed from the source throughout travel and teaching. The specialist remains in the source population; no new people or permanent researcher allocation are created. Available local Knowledge workers receive a 1.5 research multiplier during the delivered visit. This preserves prerequisites, local research work, and accumulated progress; it awards no instant discovery or permanent evidence. War suspends teaching, and the contractual return date still releases the source worker. Return travel is scheduled aggregate simulation, without a separate map figure or interception model.

Payment settles through the ordinary embassy counterpart ledger. A refused visit returns payment and prepaid visitor rations once; envoy provisions remain spent. The inspector offers both studies and visitors once both capabilities exist. Registers are bounded to 32 active records per owner and expired records are pruned. Optional records serialize inside the existing society exchange authority; old saves without them remain valid. New executables are required to resume scholar records with their behavior.

Verification: nine new scholar cases plus the previous 77 regression cases passed in separate headless processes, with zero errors, failures, skipped cases or orphan nodes. Tests cover arrival-gated teaching, subject specificity, departure/return boundaries, staffing and overbooking, real bilateral payment, refusal refunds, population conservation, serialized state and malformed metadata, war and host staff requirements, hidden supplier knowledge, and the panel's real invitation action. Logs: `/tmp/tt-scholar-<suite>.log`. Native visual inspection, full save-file loading, automatic opponent invitation strategy, whole-campaign balance, and map travel interception remain unverified or unimplemented.

Additional shared integration hotspot: `scripts/game_state.gd`, limited to subtracting absent scholars from effective Knowledge capacity. Other changes: scholar contract helper and tests, existing embassy dispatch, purchase return/refund hooks, exchange validation/pruning, pathway multiplier and research inspector. Civic labor allocation remains under its existing authority. No terrain, project settings, military command or SaveSystem changes. The live discovery catalog is still 197; this checkpoint does not implement the 5,000-entry catalog, military expansion, or artwork.


## Third checkpoint: first production catalog expansion

Continues from `722b319a41a7cabea71a4e9f0dd8c640dae34b13`, same worktree and branch, original base `940d5a2`. READY for integrator review; no canonical merge or player launch.

Twelve authored discoveries are now included in the live catalog: Root Cellars, Raised Granaries, Hermetic Grain Storage, Brine Fermentation, Vinegar Pickling, Dated Stock Rotation, Protected Wellheads, Rainwater Cisterns, Water Settling Basins, Slow Sand Filtration, Water Service Inspections, and Separate Clean-Water Storage. They retain separate mechanisms and individual production notes; existing drying, smoking, salting and general fermentation identities were preserved. Total live discoveries: **209**.

Every addition uses explicit common foundations and an authored learning route. Cistern lining can follow vessels, lime mortar or bitumen; water inspections can build on protected wells or cisterns while still requiring records and measures. The full causal audit includes all existing alternatives and reports zero errors. This does not establish environmental feasibility or measured campaign completion times.

Six storage methods have food-category preservation profiles, rather than applying the same spoilage reduction to every food. Root cellars protect plants; raised granaries and hermetic bins protect dry staples. Profiles scale with adoption, combine multiplicatively, require a settled community and Logistics or Crafting capacity, and do not apply while traveling. Current spoilage and forecasts both use the profiles; forecast factors are calculated once per forecast. The research inspector and discovery summaries describe the full-adoption values and limits. Rival owners read their own knowledge and adoption.

A new production-contract audit rejects duplicate identities, missing descriptions/contract notes, unsupported aggregate effect keys, invalid magnitudes, unsupported food categories and additions with no implemented consequence. It complements the causal graph audit. It is an authoring check, not a historical or full simulation feasibility proof.

**96 cases passed** in separate headless processes: 10 food/water production tests and all 86 preceding regression cases. New cases check global graph/contract validity, alternate cistern and inspection foundations, category-specific actual food losses, adoption and absent staffing, travel/settlement restrictions, matching forecasts without stock mutation, independent rival ownership, malformed authoring data and explanatory text. Logs: `/tmp/tt-food-<suite>.log`; graph result: `/tmp/tt-food-graph.log`; test summary: `artifacts/technology-implementation/food-water-test-results.json`. No script errors, failures, skipped cases or orphan nodes. `git diff --check` passes.

Save compatibility: existing IDs and saved ownership remain unchanged; the catalog additions become available under the existing research rules when this executable loads a world. Preservation profiles are definition data, not a new save authority. Existing research and adoption dictionaries remain authoritative. The food system now applies these new known methods to actual stocks.

Limits: water improvements use existing aggregate water-access/safety effects, not site-specific hydraulic structures or treatment plants. Food processes use the existing five broad food categories; their recipes, dedicated buildings, salt/acid inputs and process labor are not separately consumed or scheduled. Earliest dates and magnitudes are initial design values. Full 2,500–3,000-year pacing, modern/future infrastructure, military expansion, 5,000 authored identities, artwork and native visual review remain outstanding. This slice must not be described as the completed historical technology system.

Shared integration files: DiscoverySystem, FoodSystem and the research inspector, plus the existing graph audit. New files: `scripts/food_water_knowledge.gd`, `scripts/technology_catalog_contract.gd`, and `tests/test_food_water_knowledge.gd`. No GameState, SaveSystem, terrain, project settings or military ownership changes in this checkpoint. No known conflicts against the branch's preceding checkpoint; integration with other branches has not been attempted.


## Fourth checkpoint: military education by role

Continues from `24fcf88` on the same isolated worktree/branch (original base `940d5a2`). READY for integrator review; not merged or launched in the canonical game.

Eight production discoveries: Skirmish Pair Drill, Mounted Remount School, Siege Crew Rehearsals, Mountain Field School, Range Estimation Drill, Gun Detachment School, Engineer Demonstration Ranges, and Mechanized Crew School. They connect military roles to existing weapons, handling, surveying/measurement, craft, staff and teaching foundations. All eight pass the production contract and causal graph audits. The live catalog is **217**, with 24 explicit learning routes and zero graph errors.

Each teaching practice specifies the land roles it helps. Full adoption reduces newly scheduled training time by 15% for those roles; partial adoption scales the benefit. Overlapping practices multiply, with a 30% total reduction ceiling. The existing training scheduler retains recruits, weapons, training places, provisions, prototype restrictions and day advancement. Existing queued orders retain their recorded duration; discovering a school does not instantaneously train soldiers or rewrite an underway commitment. Recruitment quotations use the same duration calculation, including their food estimate. The inspector explains the affected roles and new-order restriction. Each civilization reads its own knowledge/adoption.

This strengthens the training dimension of the existing 50 land archetypes. It does not add unit archetypes or claim new tactical behavior. Naval and air crew education, distinct battlefield doctrine, richer maneuver/countermeasure behaviors, dedicated school facilities, instructor qualifications, full military content breadth and balance remain outstanding. The existing 21 naval and 16 air types remain unchanged. General-led operational control is untouched.

Verification: **111 tests passed** across 11 separately executed headless suites. Seven new education cases cover valid graph/roles, role-specific adoption scaling, alternate foundations, actual training-order creation without rewriting older orders, recruit and equipment-knowledge gates, independent rival ownership and explanatory text. Regression suites cover training accounting (10), staff strategy (27), staffing actions (2), recruitment reconciliation (13), all land/naval/air equipment catalogs and production (6), food/water (10), technology requirements (9), technology tree (9), discovery projects (9), and research interface (9). No errors, failures, skips or orphan nodes. One pre-existing training-accounting assertion expected the obsolete phrase “Prototype intake”; it now checks the existing “Experimental units are limited” message, retaining its recruit-conservation and empty-queue assertions. Logs: `/tmp/tt-education-*.log`; summary: `artifacts/technology-implementation/military-education-test-results.json`. Graph log: `/tmp/tt-military-graph.log`. `git diff --check` passes.

Compatibility: stable existing unit and discovery identities, no new save fields, no instant equipment or training upgrades. Old saves load new definitions through the existing discovery catalog. Existing training orders keep their saved schedules; newly scheduled orders can use adopted teaching. No guarantees for loading newly discovered IDs in an older executable.

Shared integration files: `scripts/discovery_system.gd`, `scripts/military_unit_catalog.gd`, the research inspector, production validator and graph audit. New files: military education catalog and its test suite. The training-accounting test has the wording correction above. No MilitaryCampaign, combat simulator, GameState, SaveSystem, terrain or project settings edits. No known conflicts against the preceding branch checkpoint; cross-branch integration remains unverified. Whole-campaign pacing, the remaining 4,783 target discoveries, artwork and canonical integration are unfinished.


## Fifth checkpoint: shared civilian science

Continues from `0bee4c0`. Twenty-four individually named scientific/engineering foundations now connect optics, heat, electricity, instrumentation, chemistry and aerodynamics to existing practical capabilities. Each foundation has audited downstream consumers; these new theory nodes add no global production bonus or operating plant. Eight existing IDs were rewired and classified as civilian research: steam propulsion, fuel refining, internal combustion, powered flight, advanced airframes, atomic physics, reactor engineering and jet propulsion. Their existing aggregate effects and saved progress are retained. Atomic physics no longer requires naval fire control; advanced civilian airframes no longer require bombing or fighter tactics. The shared catalog has 241 live entries and zero graph/production-contract errors.

Seven new tests verify all 24 contracts, actual downstream links, civilian reachability after removing every security-domain node, indispensable reactor foundations, stable IDs/progress, rejection of invented downstream uses and removal of stale research-channel assignments after reclassification. With seven relevant regression suites, 66 cases passed with no errors, failures, skips or orphans. Logs: `/tmp/tt-science-<suite>.log`; graph: `/tmp/tt-science-graph.log`. Reclassification now removes an old channel assignment before allocating the question in its new domain, preventing duplicate simultaneous work while retaining its progress.

Changed shared files: DiscoverySystem, existing joint force knowledge definitions, production contract validator and graph audit. New civilian science definitions and tests. No new saved state, unit types, plant simulation, terrain, military command or project settings changes. Existing active questions may need their new civilian foundations before work resumes; previously earned knowledge is retained. Earliest dates are uncalibrated floors, not historical dates or full-campaign pacing evidence. This checkpoint is isolated, ready for integration review, and work continues toward the remaining scope.
