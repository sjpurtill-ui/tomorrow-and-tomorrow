# Archived first-300-year observations

These are historical checkpoints from development, not the current release checklist. Earlier unresolved issues may have been fixed later. In particular, the construction-labor test subsequently passed in the 65-case military operating run, and home provisions, delivered equipment, civilian investment, managed batch recovery and government succession have since been corrected. Use [the current assessment](FIRST_300_YEARS_PACING.md) for readiness status.

# First 300 years: prehistoric civilization pacing

Accepted direction: begin with a capable prehistoric community, not an 800 BC state and not people without inherited survival skills. Calendar years express campaign time, not literal archaeological chronology.

## Current validation status (September 21)

The 300-year endpoint is still being validated. The dated sections below retain earlier observations; their open problems should not be read as a list of unfixed current defects.

- Generated founding sites: 48 real terrain sites across three seeds satisfy food, growing-season, temperature, drinking water, wood, stone and fiber requirements. Later chosen settlements may depend on trade.
- Full world: player plus three opponents completed 25 years with zero state errors and valid player/owned binary save payloads. This is headless simulation evidence, not a rendered load or visual review. See `technology-review/pacing/first300-world25.json`.
- New cool opening: 25 years, 194 people, 25 known practices, 345 timber in stock, 57 spears and 8 fitted post/beam sets produced; save valid. Earlier treeless starts are preserved as recovery scenarios, not recommended generated starts.
- Material recovery: the warm year-100 campaign resumed building-component output after depleted-front and worker-allocation fixes. The older treeless cool campaign recovered equipped spear and bow forces through real supplies over years 100–105.
- Matched decisions: same seed and final terrain site, five years each. Makers assigned research to infrastructure/production; Military to security/logistics and produced more weapons. Both maintained provisions; neither received grants. See `technology-review/pacing/first300-matched-decisions-5.json`.
- Player panels: 20 headless checks pass for live progress, settlement histories, visible civilian production, culture effects/presentation and research navigation. Visual inspection remains with the user.

Outstanding release evidence: finish the long campaigns, review their adopted and physically operating capabilities, and verify their final saves and continuation. Do not replace these checks with structural graph reachability or calendar unlocks.

## Player-facing targets

| Years | Civilian capability | Military capability |
| --- | --- | --- |
| 0–25 | Surviving settlement, visible tool/binding production, improved food storage | Usable local defense; basic spear production from founding; early ranged development |
| 25–75 | Settled food, pottery or local alternatives, specialists | Equipped militia, patrols, distinct roles and trained leadership |
| 75–150 | Connected settlements, exchange, durable public works | Formations, missile support, fortifications, reliable supply |
| 150–300 | Established agrarian society, administrative depth, conditional early metallurgy | Regional campaigning, specialists, siege labor, replacements |

These are balance acceptance targets rather than automatic calendar unlocks. Inhospitable environments, losses and deliberate choices can delay capabilities, but the UI must expose the reason.

## Implemented foundation

New-world reset inherits ten everyday practices: seasonal observation, edible-resource recognition, wood/fiber grading, controlled flaking, cordage, hafted tools, food drying, watch rotation and hafted weapons. These are fully adopted knowledge; their effects still use ordinary physical stocks and operating requirements. Founding supplies contain a small per-person allocation of tools, bindings, drying mats, flint and stone. They are finite, decay/consume normally and are not replenished by reopening a panel or initializing resources again.

Spears are immediately a known production recipe. The player still needs labor, materials, capacity, orders, recruitment and training. No free military inventory, formations or advanced discoveries are added. This baseline applies equally through shared new-world reset for player and opponent actors. Existing saves retain their recorded knowledge and stocks; this is not a silent campaign migration.

## Measurement

The existing full daily pacing diagnostic now includes military recipe availability, stored weapons, equipped weapons and household craft stocks. Existing civilian metrics separately capture workshop recipes, lines, manufactured stocks and installed/running services. Stocks alone do not prove domestic manufacture, and recipe availability does not prove a fielded army.

Run tools/audit_history_pacing.gd with --days=109500 and an explicit output path. The harness has a wall limit and reports whether the target actually completed. It models one isolated AI civilization, synthetic recognized river access and no foreign exchange; it cannot certify the entire player world. Use multiple seeds and subsequent full-world checks before claiming a 300-year balance pass.

## Remaining pacing work

- Complete contemporary 300-year runs across several environments and record first produced/equipped capability dates, not just annual stocks.
- Trace gaps between new military knowledge, automatic demand, production, issue and field formation.
- Calibrate early investigations against 25/75/150/300-year capability targets without a universal research speed multiplier.
- Audit late research dependencies against physical experiment/production prerequisites. The historical 250-year result with modern knowledge and no installed industry is a warning, not proof about the current build.
- Check transfer of knowledge through real contact and trade; isolated seats should not determine all balance targets.

No late-game speed or calendar lock changes are included in the founding baseline.

## First implementation evidence

Seed 91420, current isolated daily harness: a 60-second bounded run reached day 4456 (12.21 years), not the requested 300-year endpoint. Inherited ten practices remained distinct from three discoveries: hide floats at year 6.68, war bows at 9.47 and selective planting at 11.38. Tools, bindings and drying mats were maintained; fourteen spears existed in stock. This establishes a more capable start, not complete field readiness.

Follow-up supply inspection found the AI did not order replacement weapons for existing formations and could not reuse finished military lines through its civilian-only reuse path. The controller now considers existing force demand and reuses only finished, unpaused, unreserved AI-owned lines. Human-controlled lines and unfinished trials remain excluded. A subsequent year-one run stocked both levy weapons and spears, but equipped counts remained zero: deployed-force equipment delivery remains an open issue and prevents claiming the military pacing target is achieved.

Validation: founding knowledge, finite one-time supplies, paid spear production, AI line reuse protection, causal opening crafts, isolated city/actor stocks, and production-evidence tests. Existing causal tests now explicitly start with empty knowledge; independent civilizations are expected to retain their own founding supplies instead of zero stocks. No player save was overwritten or migrated.


## Geography and decisions: acceptance criteria

The opening is a viable community with inherited skills, not an identical resource bundle that cancels its location. Placement should change both opportunity and cost. Knowledge, adoption, materials, staffed production and usable capability are separate stages.

| Starting circumstances | Decisions the player should face | Evidence required |
| --- | --- | --- |
| Reliable river and fertile land | Expand cultivation and storage, or retain a diverse food economy; invest in flood resilience | Different food reliability, surplus, labor and flood losses, not just a yield label |
| Woodland and good stone | Specialize in tools, timber and construction; decide how much to extract and preserve | Actual output, regrowth pressure and building completion; maintained tools consume material |
| Dry country or sparse timber | Prioritize water, preservation, exchange or relocation; choose locally feasible building methods | A viable alternative with costs; no timber or freshwater created by a research unlock |
| Coast and waterways | Develop water access, boats and exchange if local conditions support them | Recognized navigable access and real transported stocks; coast alone must not count as drinking water |
| Cold or short growing season | Secure seasonal reserves, shelter and clothing before expanding commitments | Winter consumption and survival costs visible before a crisis |
| Limited ore or isolation | Develop substitutes, obtain samples through contact, trade for inputs, or settle a resource site | Knowledge alone cannot operate an unavailable material chain; isolation limits acquisition |
| Nearby societies | Choose exchange, accommodation, competition or conquest | Contact, reputation and transport change outcomes; opponents obey the same physical constraints |

Research choices must alter practical opportunity: a choice has a discoverable benefit, prerequisites, a credible route to adoption, and an opportunity cost in labor or attention. Civic choices must change the ability to carry out that route through priorities, obligations, legitimacy or institutional capacity. Leaders handle routine work within those choices. Do not require the player to repair every idle line manually.

Compare matched runs: same seed and population with different environmental conditions; then the same site with different research/civic priorities. Change one factor at a time before running combined scenarios. Record at years 25, 75, 150 and 300: survival and reserves; local materials and shortages; actual household/workshop outputs; completed buildings by settlement; discoveries versus adopted and operating capabilities; troops trained/equipped/supplied; contacts and exchange. Record first capability dates and periods stalled, with causes. A second viable path is required where the design promises alternatives. A universally rich synthetic river site cannot validate globe placement.

These are acceptance criteria, not claims that all paths are implemented or verified. Current unresolved cases include at-home food delivery being capped by field logistics, idle civilian workshops, advanced knowledge without an operating industry, remote replacement delivery, and full-world interaction/performance.

## Stationed equipment delivery checkpoint

Daily equipment and ammunition issue now includes field armies physically stationed at the home settlement, sharing finite inventory and the reserve's remaining delivery capacity. Moving, remote, engaged and convoy forces do not receive this local issue. Three focused checks cover shared stock/capacity, sub-item budgets and excluded locations. No save schema change.

The ongoing seed-91420 reference run reached year 30 with seven equipped levy weapons and five equipped spears. It still had no operating civilian workshop lines, and aggregate provision delivery was about 63% despite ample stocks. This is intermediate evidence, not a 300-year pass. The run includes only the stationed-equipment patch over 3044691; later changes require separate validation.


## Local provisions and first matched decisions

Home-stationed personnel eat from ordinary settlement provisions without a cart/supply-groups technology penalty. Physically remote or moving forces retain field transport constraints. FoodSystem still consumes actual stocks; scarcity reduces deliveries. Mixed-force accounting allocates the consumed rations according to local/remote access and credits separately delivered food only to its recipient. General-campaign prepaid forces remain excluded. No save migration.

Validation: 54 of 55 cases pass across seven suites, including all four new local/mixed/scarcity/credit cases. The sole failure is `test_construction_diverts_existing_city_workers_without_extra_labor` (2.0 versus expected 2.5), reproduced unchanged on pre-patch `70faecc`; it remains an unrelated construction-labor issue, not a passing check.

The pacing harness now accepts `--wood-density=0.65` and `--ambition=makers` (or another normal century ambition). Leaving either absent preserves the reference scenario. The wood override changes only timber catchments; it is deliberately not described as an entire climate or biome. Ambitions use the ordinary validated choice, including subsequent century choices, without granting research or stocks.

Four matched one-year runs at seed 91420 completed: wooded/sparse timber crossed with makers/sustenance. At the wooded site, makers ended with 185.56 timber and 31.88 food days; sustenance with 86.38 timber and 54.27 food days. Both completed five founding buildings. Sparse-timber counterparts exhausted timber and completed only four and three buildings respectively. Makers directed attention toward infrastructure/production; sustenance toward nutrition/ecology. All retained ten inherited practices at year one, so this does not establish divergent long-term discoveries. Household tool stocks were almost exhausted at the sparse site: viable adaptation there remains an acceptance blocker. See `technology-review/pacing/first300-paired-opening.json` for matched stocks, labor and attention.

These results establish causal differences in the opening. They do not certify cold/dry/coastal starts, contact and trade, remote campaigning, or the 300-year endpoint.


## Completed 25-year follow-up

The local-provisions update completed 9,125 daily ticks (25 years), seed 91420, in 226.65 seconds. End state: 192 people in three settlements; 24 known practices (ten inherited, fourteen discovered); seven equipped spears and nine equipped levy weapons; 57.35 food days, actual intake 100%, provision access 100%. One working civilian line had completed 42 fitted post/beam batches; its retained stock was about 0.50 units, so stock alone would understate output. Household tools, bindings, drying mats, joined components and unfired vessels were maintained. No installed industrial plants and no equipped bows despite known bow craft. The local food correction improves actual research/production/settlement outcomes without changing research speed constants.

This fulfills a bounded 25-year reference run, not all opening acceptance criteria or the 300-year milestone. Bow availability versus deployed roles, sparse-resource recovery, regional exchange, later material-dependent research and full-world performance remain open. The longer baseline diagnostic predates the food correction and must not be presented as validation of this updated economy. Compact evidence: `technology-review/pacing/first300-local-provisions-25.json`.
