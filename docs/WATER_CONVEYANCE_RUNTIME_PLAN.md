# Physical water conveyance — implementation contract

Status: approved scope, awaiting the verified combined construction/food base before runtime edits. Design worktree `/Users/seanpurtill/Documents/Codex/tt-water-design`, branch `codex/water-design`, base `ff0084b93d1fa758987f906442cd37b8092b40ff`. This document adds no discoveries and proves no runtime behavior.

## Existing authority and observed gap

`ResourceSystem._process_water_flow` selects accessible surveyed deposits or mapped surface hydrology, calculates household and organized collection, and owns the Freshwater stock debit for drinking. `SettlementModel.with_city_resources` swaps local inventories and persists them back to the owning city. Both remain authoritative. Nearby exposed water must remain usable by households without pipe technology.

The current water context supplies distance and sometimes a source identifier, but does not establish an intake position, hydraulic head or a surveyed route. Distance alone cannot justify gravity conveyance. A line must retain a verified source position, destination, route length and supporting grade observations. Unknown geometry blocks gravity commissioning; it must never be replaced with invented height values. Surveyed terrain and visible hydrology are evidence sources, not permission to expose hidden deposits.

## Paid construction and operation

Promote the ten conduit draft identities only when each has an actual consumer. Clay forming and firing produce intermediate and finished pipe stocks through existing workshops; fit gauges and gravity socket joints qualify installation choices. Timber conduits remain an alternative with their own raw inputs, tooling, losses and upkeep. Imported finished sections can supply construction without unlocking their manufacture.

Quotes select an actual source and a bounded route. They show length, materials, construction work, expected service limits and blockers. Starting work consumes the quoted local bill once. Installed lines retain their paid material provenance, construction progress, grade evidence, condition, obstruction, leakage estimate and last processed day. Finite Construction work competes with existing construction obligations; repeated calls for the same day cannot grant more work or delivery.

Gravity grade control accepts only a verified feasible route. Pumped service is a separate future or already-qualified equipment path requiring actual pumping capacity and power; do not smuggle it into gravity pipe technology. Bedding and loading assessment affect the installed section they treat. Inspection consumes work and updates observed condition; rodding removes supported obstructions through accessible maintained runs. Neither inspecting nor knowing a repair method restores condition for free.

The daily conveyance result reports water delivered to the same ResourceSystem collection calculation. Source availability, installed throughput, condition, obstructions and leakage bound delivery. It is not credited once to pipe stock and again to city stock. Household collection, carried water and conveyed water must share the existing collection/storage accounting, including overflow and drinking consumption. Pipe work must not increase source quality or grant disinfection. Conveyance should reduce dependence on hauling or extend verified access, not merely add a global research percentage.

## Player and rival use

Use the existing settlement/service inspector and ordinary investment flow. Show construction status, verified route, delivered quantity, losses and the concrete missing input. No mandatory logistics form or new population authority. Rival decisions use the same feasibility quote, local supply planning and paid start operation. They must account for benefit, competing labor and maintenance; they cannot construct using global or another city's stock.

## State and integration boundaries

Keep new city-local line records in the established state/save system and include their default in CITY_RESOURCE_DEFAULTS. Validate finite quantities, bounded collections, recognized material methods, route references and nonnegative dates in both human and actor payloads. Legacy saves initialize empty lines. A destroyed or inaccessible source disables its line without destroying stored household water. Moving a settlement cannot silently move an installed pipeline with it.

Expected shared edits: one ResourceSystem daily service hook; civilian workshop recipe registration; discovery registration and operating-contract validation; city-local state/default and human/actor save checks; existing inspector and investment hooks. Coordinate exact terrain/hydrology sampling APIs with the integrator before changing LocalTerrain. Do not replace terrain, food/grain ownership, or construction systems wholesale.

## Evidence required for delivery

- Actual source-to-city route: downhill succeeds when supplied; uphill and unknown geometry remain blocked without a qualified pump.
- Full paid manufacturing and construction path, including a timber alternative and an imported finished-section route without manufacturing mastery.
- Daily water conservation with household fetching, finite storage, shortage, leakage and repeated-day calls.
- A damaged or obstructed line loses capacity; paid compatible repair or rodding restores only supported service.
- Rival and secondary-city operation debit their own stocks and labor; source loss and settlement relocation invalidate service appropriately.
- Full save/load continuation preserves incomplete work and installed operation; absent legacy fields remain valid and malformed line records are rejected.
- Inspector reports match physical state. Run focused water/resource, owner/save and affected construction/production checks once after the cohesive implementation. Treat unrelated baseline failures separately and disclose them.

Full treatment, wastewater networks, historical pacing, the rest of the 5,000 discoveries and their artwork remain part of the larger goal. This conveyance batch cannot stand in for completion of those requirements.


## Working implementation checkpoint

Route survey and material-quote helpers exist, with six paid workshop recipes and ten unregistered discovery definitions. Runtime registration and water delivery are intentionally still incomplete; this is not a READY handoff. Forming/firing supply actual intermediate/final products; installations can use imported final products without granting manufacture. Daily construction helpers return work used so the caller can share the existing construction budget.

Three draft prerequisite corrections are required when promoting the verified runtime: ceramic socket joining uses shared measures plus lime mortar OR clay tempering, without mandatory pipe manufacture; bedding uses drainage plus joinery OR clay tempering; fit gauges use shared measures plus clay shaping OR joinery. These retain local installation competence while allowing imported sections. The old proposed predicates remain in the authored ledger until verified promotion records their reconciliation. Quantities are game batches and workload tuning, not engineering units or certified hydraulic ratings.


Checkpoint: ten definitions are now registered in the isolated worktree with six products and line-method consumers. Graph/production closure passes at 661 discoveries, 443 routes, 309 recipes and 17 facilities (`/tmp/tt-water-graph.log`), structural evidence only. Three route cases and four operating cases pass, including ResourceSystem stock conservation, paid imported sections, finite construction, repeated-day limits, source loss/relocation, compatible repair and actor isolation. Human/actor save validators, city defaults, maintenance sharing, primary-city inspector buttons and rival investment hooks are connected but full save continuation, secondary-city behavior, manufacturing bootstrap, control behavior and affected regressions remain to verify. Delivery is HELD until those checks and any fixes complete.


Acceptance checkpoint: 74 cases across water operations, building materials, civilian industry and SettlementModel pass; expanded final water checks now pass 11 operating cases plus three route cases. Full save restores paid unfinished work; secondary-city ResourceSystem processing uses its actual 200-person demand rather than the 1,000-person national total; the delayed secondary-city button callback debits that city's stocks. Normal headless boot exits cleanly. Source candidates now include bounded upstream points on existing authored waterways, ranked by verified gravity feasibility; at most four remain in cached geography. No terrain geometry is changed.

Remaining delivery issue: existing automatic intercity trade enumerates only raw goods, so a secondary city cannot yet request these finished conduit supplies through that flow. Integrate targeted, physically delivered conduit supply requests instead of creating stock locally or applying generic raw-material reserves to finished batches. Rival secondary-city construction must use the same supplied route. This remains HELD; do not claim campaign-wide secondary-city access merely from the scoped-stock tests.
