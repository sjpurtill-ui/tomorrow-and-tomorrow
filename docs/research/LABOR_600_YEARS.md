# Labor: the first 600 years

**Scope.** The game's **Labor** research line (`labor` dynamic) has four channels: Able workforce, Work efficiency, Coordination and Workload balance. It covers the division of labor, work parties, seasonal rhythms, specialization, apprenticeship as work, obligatory labor (corvée), work songs and rest customs. The main catalog has only four `labor` entries, all in `technology_branch_catalog.gd`: `crew_handoffs`, `apprentice_contracts`, `work_rest_limits` and `work_motion_studies`. The line's root, `labor_rotations`, is tagged `Society` (institutions) in `discovery_system.gd`, but it is plainly labor and is listed here. `public_levies` (the corvée) is also Society-tagged and is marked as shared. The branch `codex/era-research-pacing` adds 32 labor practices in `early_practice_knowledge.gd`. Crew rotation, work songs and harvest customs that the branch files under infrastructure or culture are listed here as **(shared: X)**. Ration accounting and records belong to Knowledge, food to Nutrition, levies as law to Institutions, and craft methods to Production.

**Historical anchor.** Game years 0–300 correspond to roughly 5000–3000 BC (household and village labor, work feasts, megalith and dyke work parties, the first full-time specialists and ration workers of Uruk). Years 300–600 correspond to roughly 3000–1500 BC (corvée gangs of Old Kingdom Egypt, Ur III work norms and man-day accounts, Old Babylonian hire and apprenticeship contracts). This is the pacing curve from `codex/era-research-pacing` (`technology_eras.gd`).

**Research time.** Time is given in game years while a staffed Labor team is working on the item. Real minutes are for **1 day/s** (speed setting 4). In real time, 1 game year is about 6 minutes, and 10 game years are about 1 hour. At 3 days/s, divide by 3. At 8 h/s, multiply by 3.

**Id column.** `id` = in the main catalog today. `(era)` = written on the unmerged branch `codex/era-research-pacing` (`early_practice_knowledge.gd`) and not yet in main. `NEW` = not authored yet.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`), or `≈` for an estimate from the prerequisite graph. It is `—` when the item is not in main.

## Years 0–300 (≈ 5000–3000 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 1 (0–3) | Shared work taken in turns | 1.5 y | 9 min | labor_rotations | 9 |
| 2 (0–4) | Household tasks divided by age and season | 1 y | 6 min | NEW | — |
| 3 (0–5) | Tasks assigned at dawn | 1 y | 6 min | dawn_task_briefings (era) | — |
| 4 (0–6) | Aptitude trials for new hands | 1 y | 6 min | aptitude_trials (era) | — |
| 5 (0–8) | Hard tasks done in pairs | 1 y | 6 min | paired_task_assignment (era) | — |
| 6 (1–10) | Rest breaks timed by the sun | 1 y | 6 min | rest_break_timing (era) | — |
| 8 (2–12) | Shared work signals: calls and claps | 1.5 y | 9 min | shared_work_signals (era) | — |
| 10 (3–15) | Seasonal round: set times to plant, fell and build | 2 y | 12 min | NEW | — |
| 12 (4–18) | Task sequencing habits | 1.5 y | 9 min | task_sequencing_habits (era) | — |
| 14 (5–20) | Midday rest in the hot season | 1.5 y | 9 min | NEW | — |
| 16 (6–22) | Children's light tasks: bird-scaring and gleaning | 1.5 y | 9 min | NEW | — |
| 18 (6–25) | Skilled hands recognized by name | 2 y | 12 min | skill_recognition (era) | — |
| 20 (8–28) | Communal work songs (shared: culture) | 2 y | 12 min | communal_work_songs (era) | — |
| 22 (10–30) | Heavy tasks rotated among the able | 2 y | 12 min | rotating_heavy_tasks (era) | — |
| 25 (10–35) | Herding rotas for common flocks (shared: nutrition) | 2 y | 12 min | NEW | — |
| **28 (12–38)** | **Neighbour work party repaid with a feast** | 3 y | 18 min | NEW | — |
| 32 (15–42) | Festival rest days (shared: culture) | 2 y | 12 min | NEW | — |
| **36 (18–48)** | **Part-time craft specialists within households** | 4 y | 24 min | NEW | — |
| 40 (20–52) | Building work kept for the slack season | 3 y | 18 min | NEW | — |
| 45 (25–60) | Harvests brought in by households in turn (shared: culture) | 3 y | 18 min | cooperative_harvest_gatherings (era) | — |
| 50 (28–65) | Children learn a craft beside a parent | 3 y | 18 min | NEW | — |
| 55 (30–70) | Economical movement habits | 2 y | 12 min | motion_economy_habits (era) | — |
| 58 (32–75) | Recovery days after heavy tasks | 2 y | 12 min | recovery_days_after_heavy_tasks (era) | — |
| 62 (35–80) | Boundary markers for parallel crews | 2 y | 12 min | boundary_markers_parallel_crews (era) | — |
| 66 (38–85) | Cross-training circuits | 2 y | 12 min | cross_training_circuits (era) | — |
| 72 (42–95) | Neighbours rebuild for a family in need (shared: culture) | 3 y | 18 min | mutual_aid_customs (era) | — |
| 80 (48–105) | Task captains | 3 y | 18 min | task_captains (era) | — |
| 88 (55–115) | Hauling chants to time a pull | 2 y | 12 min | NEW | — |
| 95 (60–125) | Paced work cycles | 2 y | 12 min | paced_work_cycles (era) | — |
| **100 (65–135)** | **Great work parties for megaliths and dykes** | 8 y | 49 min | NEW | — |
| 110 (70–145) | Mentored task learning | 3 y | 18 min | mentored_task_learning (era) | — |
| 120 (80–155) | Seasonal labor pooling | 3 y | 18 min | seasonal_labor_pooling (era) | — |
| 130 (90–165) | Batch size set by fatigue | 2 y | 12 min | batch_sizing_by_fatigue (era) | — |
| 135 (95–170) | Elder instruction days | 2 y | 12 min | elder_instruction_days (era) | — |
| 140 (100–175) | Labor borrowed between households | 2 y | 12 min | household_labor_borrowing (era) | — |
| 145 (105–180) | Runner relays between work sites (shared: logistics) | 2 y | 12 min | runner_relays_between_work_sites (era) | — |
| **155 (115–195)** | **Full-time specialists fed from shared stores** | 10 y | 61 min | NEW | — |
| 165 (125–205) | Overseer's tally of loads carried (shared: knowledge) | 3 y | 18 min | NEW | — |
| **180 (140–220)** | **Owed work days for the shrine store (shared: institutions)** | 8 y | 49 min | NEW | — |
| 195 (155–235) | Tools staged for handoff | 2 y | 12 min | tool_handoff_staging (era) | — |
| 205 (165–245) | Scheduling across work parties | 3 y | 18 min | cross_party_scheduling (era) | — |
| **215 (175–255)** | **Fixed grain rations per worker** | 10 y | 61 min | NEW | — |
| 225 (185–265) | Craft quarters: specialists cluster by trade | 5 y | 30 min | NEW | — |
| 235 (195–275) | Specialist rotation ladders | 3 y | 18 min | specialist_rotation_ladders (era) | — |
| 240 (200–280) | Crews hand over unfinished work by tally | 3 y | 18 min | crew_handoffs | 15 |
| 248 (208–288) | Capacity ledgers (shared: knowledge) | 3 y | 18 min | capacity_ledgers (era) | — |
| 252 (212–292) | Tool reach zoning | 2 y | 12 min | tool_reach_zoning (era) | — |
| 262 (222–302) | Joint crew debriefs | 2 y | 12 min | joint_crew_debriefs (era) | — |
| 268 (228–308) | Skilled helpers placed with masters | 3 y | 18 min | journeyman_placement (era) | — |
| 280 (240–320) | Age-graded load limits | 3 y | 18 min | age_graded_load_limits (era) | — |
| 290 (250–330) | Named ration lists of dependent workers (shared: knowledge) | 5 y | 30 min | NEW | — |

## Years 300–600 (≈ 3000–1500 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 310 (280–340) | Apprentice works for keep while learning | 4 y | 24 min | NEW | — |
| **330 (290–370)** | **Seasonal corvée levy for canals and walls (shared: institutions)** | 12 y | 73 min | public_levies | 61 |
| 345 (305–385) | Workshop layout planning | 3 y | 18 min | workshop_layout_planning (era) | — |
| 350 (310–390) | Scribes assigned to count crews (shared: knowledge) | 5 y | 30 min | NEW | — |
| 355 (315–395) | Gangs of ten under a foreman | 5 y | 30 min | NEW | — |
| 365 (325–405) | Recognized master craftworkers | 4 y | 24 min | certified_craft_competence (era) | — |
| **380 (340–420)** | **Named gangs in rotating watches for great works** | 10 y | 61 min | NEW | — |
| 385 (345–425) | Great works scheduled for the flood season | 5 y | 30 min | NEW | — |
| **390 (350–430)** | **Workers' village beside a great work** | 8 y | 49 min | NEW | — |
| 400 (360–440) | Shift overlap briefings | 2 y | 12 min | shift_overlap_briefings (era) | — |
| 410 (370–450) | Water carriers, cooks and bakers assigned to crews | 4 y | 24 min | NEW | — |
| 420 (380–460) | Fatigue-aware task assignment | 3 y | 18 min | fatigue_aware_task_assignment (era) | — |
| 425 (385–465) | Field work allotted by measured plots (shared: knowledge) | 4 y | 24 min | NEW | — |
| 430 (390–470) | Daily brick quota per moulder | 5 y | 30 min | NEW | — |
| 440 (400–480) | Harvest hands hired for the season | 5 y | 30 min | NEW | — |
| **450 (410–490)** | **Standard daily task norms for digging and carrying** | 10 y | 61 min | NEW | — |
| 460 (420–500) | Weaving teams on rations (shared: production) | 5 y | 30 min | NEW | — |
| 470 (430–510) | Lighter tasks and rations for sick and aged workers (shared: health) | 5 y | 30 min | NEW | — |
| **480 (440–520)** | **Man-day accounts of labor owed and done (shared: knowledge)** | 10 y | 61 min | NEW | — |
| 490 (450–530) | Fixed rest days in the working month | 4 y | 24 min | NEW | — |
| 500 (460–540) | Substitutes hired to serve another's levy | 5 y | 30 min | NEW | — |
| **520 (480–560)** | **Labor hired for silver or grain by sealed agreement** | 10 y | 61 min | NEW | — |
| 530 (490–570) | Hire rates set by trade and skill | 6 y | 37 min | NEW | — |
| **540 (500–580)** | **Apprentice contracts with a set term** | 8 y | 49 min | apprentice_contracts | 108 |
| 555 (515–595) | Exemption from levy for temple or craft service (shared: institutions) | 5 y | 30 min | NEW | — |
| 570 (530–610) | Foremen's daily attendance lists | 5 y | 30 min | NEW | — |
| 580 (540–620) | Trade elders speak for workshop crews | 5 y | 30 min | NEW | — |
| 590 (550–630) | Masters train a set number of apprentices | 4 y | 24 min | NEW | — |
| 600 (560–640) | Skilled crews lent between cities | 5 y | 30 min | NEW | — |

## Pacing

| Years | 0–50 | 50–100 | 100–150 | 150–200 | 200–250 | 250–300 | 300–350 | 350–400 | 400–450 | 450–500 | 500–550 | 550–600 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Labor advances | 20 | 9 | 7 | 4 | 6 | 5 | 3 | 6 | 6 | 5 | 4 | 5 |

The total is **80** advances: 51 in the first 300 years and 29 in the next 300. Across the four channels, one lands about every 7–8 years. Household and work-party customs are quick (1–3 years) and front-loaded. Organized labor (rations, corvée, gangs, norms, hire) takes 8–12 years a step, so the count per window thins after year 300 while each step matters more.

**Key thresholds:**
1. **Division of labor:** household tasks by age and season (2) → part-time specialists (36) → full-time specialists (155) → craft quarters (225) → master craftworkers (365) → rates set by trade (530).
2. **Collective work:** turns (1) → work songs (20) → work feast (28) → megalith and dyke parties (100) → owed shrine work (180) → corvée levy (330) → rotating gangs (380) → workers' village (390).
3. **Rest and load:** sun-timed breaks (6) → hot-season rest (14) → festival rest days (32) → recovery days (58) → age-graded limits (280) → care for sick and aged workers (470) → monthly rest days (490).
4. **Learning the work:** aptitude trials (4) → learning beside a parent (50) → mentored learning (110) → skilled helpers (268) → apprentice for keep (310) → apprentice contracts (540).
5. **Measuring work:** loads tallied (165) → grain rations (215) → brick quotas (430) → task norms (450) → man-day accounts (480) → hired labor (520).

## Currently far too early (labor line, main)

These are placement targets only. The "Seen" column is the earliest year observed in recorded runs, or estimated from the graph where marked ≈.

| Item | Seen | Belongs |
|---|---|---|
| crew_handoffs (only needs labor_rotations) | 15 | 240 |
| work_rest_limits (measured fatigue and injury limits) | 28 | Beyond 600 (≈ 2670) |
| public_levies | 61 | 330 |
| apprentice_contracts | 108 | 540 |
| work_motion_studies | 141 | Beyond 600 (≈ 2700) |
