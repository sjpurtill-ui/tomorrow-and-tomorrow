# Division designer

## Player contract

War opens a retained formation designer instead of Defense allocation controls. Only People → Defense assigns manpower. Saving a template never recruits, consumes equipment, changes a field order, or moves population. Generals continue to command. The existing reserve, fort and supply rules remain authoritative.

The classic layout in the user's reference is five support slots beside twenty-five combat slots, with Base Stats, Combat Stats and Equipment Cost visible together at ordinary widths. At narrow widths two visible buttons switch composition/statistics; there are no dropdowns. The draft survives simulation ticks. Save, Use as army standard and Reset stay at the bottom. Equipment is searchable and paged six at a time; unavailable choices state their discovery/adoption gate.

The fresh test settlement has **3 Defense personnel**, so its default levy band contains **3 people**. A new default is bounded to 1–20, drawn from current recruitment capacity. Count shortcuts show only sizes within existing allocated Defense manpower. A manually planned larger design displays its personnel shortfall; planning does not conjure recruits. Population alone neither unlocks a unit nor improves its training, armor or organization. Developed armies use adopted units and issued equipment. A default design's name follows actual composition (e.g. Infantry group or Armored battalion); a custom name stays unchanged. The 2,050-person tank/rifle capture is an artificial modern layout test, not an early levy band or evidence of natural campaign progression.

## Existing systems and persistence

Slots compile to existing unit/weapon/count template entries. Recruitment/deployment still consume those entries through the existing roster and queues. Optional `designer_slots`, `automatic_name`, and `active_division_template_id` save fields preserve older saves. Old saves retain the prior automatic makeup until the player chooses a standard. The editor opens the selected standard by default. Legacy templates that cannot fit without dropping groups are blocked from overwriting/activation, leaving their original entries intact.

An active standard supplies composition proportions and exact equipment choices to existing automatic staffing. Largest-remainder assignment conserves every person, including tiny armies. At-home retraining transfers at most the existing 2% daily budget (at least one person), requires actual new equipment, returns old equipment and reduces drill through the existing transfer path. Away troops retain their current equipment. Workshop demand reads the standard's real shortfall. Saved standards are explicit designs: new technology makes new options available, but does not silently rewrite a player-selected equipment specification.

The editor holds at most 64 designs and 30 groups per design, with a 100,000-person design validation ceiling. These are template bounds, not a new population or recruitment pool. Larger military totals remain aggregate and field visuals remain bounded.

## Stat meanings and progression

The labels match the supplied HOI4 reference; formulas use this game's existing simulation and units. This is not a claim of literal current HOI4 combat-math parity. The official [HOI4 strategy guide](https://forumcontent.paradoxplaza.com/public/paradox/banners/HoI_IV_Strategy_Guide.pdf) supports the composition/support/stat comparison model. The user's classic reference determines layout rather than subsequent HOI4 designer revisions.

| Metric | Native interpretation |
| --- | --- |
| Max speed | Slowest group pace, divided by eight travel hours; terrain/supply still apply. |
| HP | 0.025 per person; a display of existing personnel strength, not another health pool. |
| Organization | Manpower-weighted unit cohesion × drill factor × 30; improves resistance to morale wear. |
| Recovery rate | Organization points per supplied resting field day with ordinary leadership; initiative improves recovery. |
| Reconnaissance | Equipped, trained scout share × 10; improves favorable matchup exploitation. |
| Suppression | Personnel in thousands; existing occupation requires actual garrison soldiers. No added town-watch defense. |
| Weight | Actual equipment delivery loads. |
| Supply use | Existing carrier food + equipment stores bill in thousands of loads/day, before foraging. |
| Reliability | Baseline 80%, rising with equipped repair staffing to at most 98%; applied to home equipment wear. |
| Trickleback | Existing medical care capacity × 0.08 as a share of formation manpower/day at full supplies. Home care still consumes dressings and medicine. No duplicate free healing. |
| Exp. loss | Experience dilution for a reference 10% raw replacement event; actual arrivals determine actual dilution. |
| Fuel use | Estimated motor/tracked fuel component: 60% of its existing stores bill. Included in supply, not an additional commodity debit. |
| Soft attack | Actual total unarmored-target attack / 1,000. |
| Hard attack | Same attack after actual piercing against reference armor 1.0. Actual enemy armor changes results. |
| Air attack | Equipped AA firepower / 1,000; reduces actual hostile air pressure. |
| Defense | Total defending protection / 1,000, including equipped engineers. |
| Breakthrough | Attacking protection / 1,000; branch-dependent exposure is applied in actual exchanges and odds. |
| Armor / Piercing | Manpower-weighted preview; combat still resolves each cohort separately. |
| Initiative | Equipped trained scout share × 0.5, capped at 20%; improves recovery. |
| Entrenchment | Equipped trained engineer share, capped at 25%; additional defending protection. |
| Combat width | Personnel / 1,000. Existing frontage counts support personnel too; it is not HOI4's zero-width support rule. |
| Hardness | Manpower-weighted issued equipment hardness. |
| Manpower | Exact total personnel; machine crews use existing crew ratios. |
| Training time | Longest existing unit training requirement. |
| Production cost | Existing equipment quantities × actual recipe work. |

Force totals grow with people. Rates, speed and weighted qualities do not multiply just because the population grows. Some early metrics appropriately remain zero (armor, AA, fuel), while walking speed and basic equipment reliability remain physically sensible. The preview assumes full equipment and offers raw/trained drill; actual shortages and conditions reduce field effectiveness.

New combat adaptations in this delivery are attacking protection, cohesion-dependent morale wear, equipped support effects for reconnaissance/engineers/AA, recovery initiative and repair reliability. They are real balance changes, not decorative statistics. Medical service, foraging, recruitment and the population ledger retain their existing costs and authority. The UI does not add direct tactical orders or automatic technology-based army enlargement.

## Validation and limits

Headless coverage includes tiny-scale metrics, staffing conservation, held equipment consumption, save/load and invalid-slot handling, legacy overflow protection, name/preset progression, locked equipment, actual attack/defense/AA effects, medical-capacity agreement, retained draft and absence of War allocation controls. Existing combat, medicine, sustainment, foraging, provisions, template, army makeup, war-screen and front-visual suites are included in the final run.

Guarded offscreen native captures at 1280 and 500 pixels verify the real UI, both narrow tabs and fixed footer, with no player window opened. Prepared modern captures verify layout only. No claim is made of a full campaign naturally progressing through every military era. The already running player process keeps its loaded build until a normal relaunch.

Final validation: 157 distinct cases across 13 suites pass. Report 7 supplies 133 non-War cases; after replacing the obsolete removed-control assertion, report 8 supplies all 24 War cases with zero errors/failures/orphans. Native capture log: `/tmp/tt-division-capture-final.log`.
