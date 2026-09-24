# Institutions: the first 600 years

**Scope.** The game's **Institutions** research line (`institutions` dynamic; `direction: "Society"` entries, which `discovery_system.gd` maps to `institutions`) has four channels: Administration, Legitimacy, State capacity and Institutional flexibility. It covers councils and elders, chiefdom and authority, customary law, dispute settlement, oaths, redistribution and obligation, property and boundaries, offices, tribute and levies, and the god's house as storehouse. In main it has 16 entries: `labor_rotations`, `customary_law` and `public_stores` (`discovery_system.gd`), nine in `society_knowledge_catalog.gd` (`household_councils` to `professional_service`), and four in `civic_administration_knowledge.gd`. Only 8 of them belong before year 600. The era branch adds 32 `institutions` practices in `early_practice_knowledge.gd`. Some `culture` "Shared legitimacy" practices mainly govern councils, oaths and disputes. They are listed here and marked (shared: culture), and the Culture list does not repeat them. Store accounts, seals, witnessed records, sealed receipts and sworn interpreters are already in Knowledge (see Knowledge). `labor_rotations` is `Society` in the catalog, but its main effect is labor, so it is marked (shared: labor).

**Historical anchor.** Game years 0–300 correspond to roughly 5000–3000 BC (late Neolithic to proto-writing). Years 300–600 correspond to roughly 3000–1500 BC (early writing, tablet schools, place value). This is the pacing curve from `codex/era-research-pacing` (`technology_eras.gd`).

**Research time.** Time is given in game years while a staffed Institutions team is working on the item. Real minutes are for **1 day/s** (speed setting 4). In real time, 1 game year is about 6 minutes, and 10 game years are about 1 hour. At 3 days/s, divide by 3. At 8 h/s, multiply by 3.

**Id column.** `id` = in the main catalog today. `(era)` = written on the unmerged branch `codex/era-research-pacing` and not yet in main. `NEW` = not authored yet.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`), or `≈` for an estimate from the prerequisite graph. It is `—` when the item is not in main.

## Years 0–300 (≈ 5000–3000 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 1 (0–3) | Labor rotations: households take turns at shared work (shared: labor) | 1 y | 6 min | labor_rotations | 9 |
| 2 (0–5) | Seasonal duty rosters | 1.5 y | 9 min | seasonal_duty_rosters (era) | — |
| 3 (0–6) | Council messengers call households to a gathering | 1.5 y | 9 min | council_messenger_duty (era) | — |
| 4 (0–8) | Any adult may speak against a proposal | 1.5 y | 9 min | dissenting_voice_custom (era) | — |
| 5 (1–10) | The headman gives back what is brought to him | 2 y | 12 min | leader_gift_redistribution (era) | — |
| 6 (2–10) | Household task tallies | 2 y | 12 min | household_task_ledgers (era) | — |
| 7 (2–12) | Agreements bind only when spoken before witnesses (shared: culture) | 2 y | 12 min | witnessed_agreement_customs (era) | — |
| 8 (3–14) | Elders consulted before a hard decision | 2 y | 12 min | elder_consultation_rites (era) | — |
| 10 (4–16) | Household councils: one recognized speaker per household | 3 y | 18 min | household_councils | 15 |
| 12 (5–20) | Elders must assent before a decision binds (shared: culture) | 3 y | 18 min | elder_council_assent (era) | — |
| 14 (6–22) | Seasonal counts of what each household brought | 3 y | 18 min | seasonal_tribute_counts (era) | — |
| 16 (8–25) | A custom changes only by open agreement | 2 y | 12 min | consensus_amendment_custom (era) | — |
| 18 (8–28) | Fields and pastures held by lineage | 3 y | 18 min | NEW | — |
| 20 (10–30) | Injury paid for in goods (blood-price) | 3 y | 18 min | NEW | — |
| 24 (12–35) | A leader chosen for a season of need | 3 y | 18 min | NEW | — |
| 28 (15–40) | Speakers carry household petitions to the living god | 3 y | 18 min | NEW | — |
| 30 (18–45) | Casting out as the gravest sentence | 3 y | 18 min | NEW | — |
| 35 (20–50) | Customary law: remembered judgments bind later ones | 5 y | 30 min | customary_law | 23 |
| 40 (25–55) | Common store kept under watch (shared: nutrition) | 4 y | 24 min | public_stores | 29 |
| 45 (30–60) | Go-betweens mediate quarrels between households | 3 y | 18 min | NEW | — |
| 50 (35–70) | Bride-wealth agreements between lineages | 4 y | 24 min | NEW | — |
| 55 (40–75) | Oath before the god to settle an unwitnessed claim | 4 y | 24 min | NEW | — |
| 60 (45–80) | Inheritance shares divided among heirs by custom | 4 y | 24 min | NEW | — |
| 65 (45–85) | Field edges marked with stones and ditches | 4 y | 24 min | NEW | — |
| 70 (50–90) | Labor-debt tallies: who owes whom a day's work | 4 y | 24 min | labor_debt_tallies (era) | — |
| 75 (55–95) | Feasts owed by leaders to their followers | 4 y | 24 min | NEW | — |
| 80 (60–100) | Grain for the store weighed in public (shared: culture) | 3 y | 18 min | public_grain_weighing (era) | — |
| 85 (60–110) | Set shares of the harvest offered to the god | 5 y | 30 min | NEW | — |
| 90 (65–115) | Public praise of faithful service | 3 y | 18 min | public_praise_assemblies (era) | — |
| 95 (70–120) | New customs tried for a season first | 3 y | 18 min | trial_custom_periods (era) | — |
| 100 (75–125) | Boundary oaths sworn at the marker stones | 4 y | 24 min | boundary_oath_rituals (era) | — |
| 105 (80–130) | Stewardship of the store passes in turn | 4 y | 24 min | rotating_stewardship (era) | — |
| 110 (85–135) | New officeholders serve a trial term | 3 y | 18 min | probationary_appointment_custom (era) | — |
| **115 (85–150)** | **The god's house as common storehouse: offerings kept and reissued** | 8 y | 49 min | NEW | — |
| 120 (90–150) | Boundary marker surveys | 4 y | 24 min | boundary_marker_surveys (era) | — |
| 125 (95–155) | Grievances aired before the assembled settlement (shared: culture) | 3 y | 18 min | public_dispute_airing (era) | — |
| 130 (100–160) | Keepers appointed over the god's offerings | 5 y | 30 min | NEW | — |
| 135 (105–165) | Villages reconcile their tribute counts | 5 y | 30 min | intervillage_tribute_reconciliation (era) | — |
| **140 (100–185)** | **Paramount chief over several villages** | 10 y | 61 min | NEW | — |
| 145 (110–175) | Restitution settled through a mediator | 4 y | 24 min | mediated_restitution_custom (era) | — |
| 150 (115–180) | Shared-labor registers | 4 y | 24 min | shared_labor_registers (era) | — |
| 152 (115–185) | Rules that lapse unless renewed each season | 3 y | 18 min | sunset_rule_custom (era) | — |
| 154 (115–190) | Council speakers take turns in a set order (shared: culture) | 2 y | 12 min | rotating_speaker_order (era) | — |
| 157 (120–190) | A standing arbiter appointed | 5 y | 30 min | standing_arbiter_appointment (era) | — |
| 165 (125–200) | Only named keepers may break a store seal | 4 y | 24 min | NEW | — |
| 170 (130–205) | The god's house issues rations to its workers | 6 y | 37 min | NEW | — |
| 180 (140–215) | Overseers of work gangs for canals and building (shared: labor) | 6 y | 37 min | NEW | — |
| 190 (150–230) | Chiefly lineages: rank passes by birth | 8 y | 49 min | NEW | — |
| 200 (160–240) | Assembly of all free adults for grave matters | 5 y | 30 min | NEW | — |
| 210 (170–245) | Grain levy accounting | 6 y | 37 min | grain_levy_accounting (era) | — |
| 215 (175–250) | Subject villages bring tribute at set seasons | 6 y | 37 min | NEW | — |
| 225 (185–260) | Standing grievance hearings | 4 y | 24 min | public_grievance_hearings (era) | — |
| 240 (200–275) | Arbiters travel a circuit of villages | 6 y | 37 min | regional_arbitration_circuits (era) | — |
| 245 (205–280) | Formal oath-taking at the god's house (shared: culture) | 4 y | 24 min | formal_oath_taking (era) | — |
| 255 (215–290) | Councils reform their own procedure | 5 y | 30 min | council_reformation_practice (era) | — |
| **260 (215–305)** | **High steward of the god's house leads the town** | 12 y | 73 min | NEW | — |
| 265 (225–300) | Households audit each other's grain | 5 y | 30 min | cross_household_grain_audits (era) | — |
| 268 (225–305) | Registers of who witnessed each oath (shared: culture) | 5 y | 30 min | oath_witness_registers (era) | — |
| 272 (230–310) | Levies coordinated across a district | 6 y | 37 min | regional_levy_coordination (era) | — |
| 280 (240–315) | Ration lists by worker and month | 6 y | 37 min | NEW | — |
| 285 (245–320) | A settled case may be reopened on appeal | 4 y | 24 min | appeal_reopening_custom (era) | — |
| 288 (245–325) | Heir named in public before the elders | 5 y | 30 min | succession_naming_rites (era) | — |
| 295 (250–335) | Household census rolls | 8 y | 49 min | census_rolls | 54 |
| 300 (255–340) | Scheduled public levies of labor and goods | 8 y | 49 min | public_levies | 61 |

## Years 300–600 (≈ 3000–1500 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 310 (280–345) | Titled overseers of fields, granary and works | 6 y | 37 min | NEW | — |
| 320 (285–355) | Fields sold before witnesses with their bounds recited | 6 y | 37 min | NEW | — |
| 330 (295–365) | Loans of grain and silver at fixed interest | 8 y | 49 min | NEW | — |
| 345 (310–380) | Temple and palace households keep separate stores | 8 y | 49 min | NEW | — |
| 355 (320–390) | Registers shared between settlements | 6 y | 37 min | cross_settlement_registries (era) | — |
| **365 (320–410)** | **Kingship: the war-leader rules for life** | 15 y | 91 min | NEW | — |
| 375 (340–410) | Officials invested before the god | 5 y | 30 min | ceremonial_investiture (era) | — |
| 378 (340–415) | Right to petition the assembly (shared: culture) | 5 y | 30 min | assembly_petition_rights (era) | — |
| 385 (350–420) | Governors over subject towns | 10 y | 61 min | NEW | — |
| 390 (355–425) | Heralds proclaim decisions in the square | 4 y | 24 min | NEW | — |
| 400 (360–440) | Tribute schedules fixed by amount and date | 8 y | 49 min | codified_tribute_schedules (era) | — |
| 405 (365–445) | Specialized courts: judges by kind of dispute | 10 y | 61 min | specialized_courts | ≈80 |
| 410 (370–450) | Boundary treaty between towns sworn before the gods | 8 y | 49 min | NEW | — |
| 415 (375–455) | Rule passes to a named heir of the ruling house | 8 y | 49 min | NEW | — |
| 420 (380–460) | Councils review past judgments as precedent | 6 y | 37 min | precedent_review_councils (era) | — |
| 425 (385–465) | Standard weights proclaimed and checked by officials | 6 y | 37 min | NEW | — |
| 430 (390–470) | Debt-release proclamations | 8 y | 49 min | NEW | — |
| 440 (400–480) | Sworn treaty with a foreign ruler on trade and peace | 8 y | 49 min | NEW | — |
| 445 (405–485) | Ruler's messengers carry sealed passes and road rations (shared: logistics) | 6 y | 37 min | NEW | — |
| 455 (415–495) | Estates of the god's house worked by tenants and dependents | 8 y | 49 min | NEW | — |
| 460 (420–500) | Harvest dues assessed by field area (shared: nutrition) | 8 y | 49 min | NEW | — |
| 465 (425–505) | Inscriptions declare the ruler's works and justice (shared: culture) | 6 y | 37 min | NEW | — |
| **480 (435–525)** | **Written law collection with set penalties by case** | 15 y | 91 min | NEW | — |
| 485 (445–525) | Judges sworn to the god on taking office | 5 y | 30 min | NEW | — |
| 490 (450–530) | Sworn witnesses and written testimony at trial | 6 y | 37 min | NEW | — |
| 500 (460–540) | Provinces send yearly accounts to the capital | 8 y | 49 min | NEW | — |
| 510 (470–550) | Adoption, marriage and inheritance by sealed contract | 6 y | 37 min | NEW | — |
| 515 (475–555) | Tolls on caravans at frontier posts (shared: logistics) | 6 y | 37 min | NEW | — |
| 525 (485–565) | Property registers | 10 y | 61 min | property_registers | ≈90 |
| 530 (490–570) | Town mayors and elders answer to the governor | 6 y | 37 min | NEW | — |
| 535 (495–575) | Appeal from local judges to the ruler's court | 6 y | 37 min | NEW | — |
| 540 (500–580) | Price and wage schedules proclaimed | 8 y | 49 min | NEW | — |
| 545 (505–585) | Merchant houses licensed to trade abroad (shared: logistics) | 8 y | 49 min | NEW | — |
| **550 (505–595)** | **Law set up in stone in a public place** | 10 y | 61 min | NEW | — |
| 555 (515–595) | Land granted in return for service (shared: security) | 10 y | 61 min | NEW | — |
| 560 (520–600) | Jurisdiction boundaries: which court and governor rules each district | 10 y | 61 min | jurisdiction_boundaries | ≈140 |
| 570 (530–610) | Palace and temple workshops given quotas (shared: production) | 8 y | 49 min | NEW | — |
| 580 (540–620) | Inspectors ride circuit over the governors | 6 y | 37 min | NEW | — |
| 590 (550–630) | Ruler's letters to governors answered in a set form | 6 y | 37 min | NEW | — |
| 600 (560–640) | Service-land registers checked against census rolls | 8 y | 49 min | NEW | — |

## Pacing

| Years | 0–50 | 50–100 | 100–150 | 150–200 | 200–250 | 250–300 | 300–350 | 350–400 | 400–450 | 450–500 | 500–550 | 550–600 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Institutions advances | 20 | 10 | 10 | 8 | 6 | 10 | 4 | 6 | 9 | 6 | 8 | 7 |

The total is **104** advances: 64 in the first 300 years and 40 in the next 300. Across the four channels, one lands about every 6 years. Early customs take 1–5 years, so councils, elders and obligations all advance together from the start. From year 115, the god's house, the chiefdom and the priest-steward become long thresholds (8–12 years). After year 300, offices, kingship and written law take 6–15 years each, so the count per window falls while each step matters more.

**Key thresholds:**
1. **Authority:** household councils (10) → elder assent (12) → leader for a season (24) → paramount chief (140) → chiefly lineages (190) → priest-steward of the town (260) → kingship (365) → heir of the ruling house (415).
2. **Law and disputes:** witnessed agreements (7) → blood-price (20) → customary law (35) → oath before the god (55) → standing arbiter (157) → arbitration circuits (240) → appeal (285) → specialized courts (405) → written law collection (480) → law set in stone (550).
3. **Obligation and store:** headman's gifts (5) → common store (40) → harvest shares to the god (85) → the god's house as storehouse (115) → rations (170) → levy accounting (210) → census and public levies (295–300) → dues by field area (460) → yearly provincial accounts (500).
4. **Land and boundary:** lineage fields (18) → marked field edges (65) → boundary oaths (100) → boundary surveys (120) → witnessed field sales (320) → boundary treaty (410) → property registers (525) → jurisdiction boundaries (560).

## Currently too early (institutions line, main)

These are placement targets only. The "Seen" column is the earliest year observed in recorded runs, or estimated from the graph where marked ≈.

| Item | Seen | Belongs |
|---|---|---|
| census_rolls / public_levies | 54 / 61 | 295 / 300 |
| specialized_courts (needs formal_archives, census_rolls) | ≈80 | 405 |
| property_registers | ≈90 | 525 |
| craft_guilds | ≈100 | Beyond 600 (historical ≈ 1100 AD) |
| apprentice_contracts (labor; needs customary_law) | 108 | ≈ 540 |
| jurisdiction_boundaries | ≈140 | 560 |
| public_credit / risk_pools / professional_service | not yet seen | Beyond 600 |

`customary_law` (seen at 23) is placed at 35. The era table dates it to 3000 BC (year 300). However, its catalog observation describes remembered oral judgments, which come well before written law. The written form is the "Written law collection" at 480.
