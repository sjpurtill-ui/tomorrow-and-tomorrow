# Full-history technology implementation

The user approved the design on September 10, 2026. The target remains 5,000 distinct discoveries across the full historical and future span. The 600 review candidates are subject names awaiting individual production contracts; they are not 600 implemented discoveries.

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
