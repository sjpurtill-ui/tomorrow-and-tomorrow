# First 300 years: prehistoric civilization pacing

Accepted direction: begin with a capable prehistoric community, not an 800 BC state and not people without inherited survival skills. Calendar years express campaign time, not literal archaeological chronology.

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
