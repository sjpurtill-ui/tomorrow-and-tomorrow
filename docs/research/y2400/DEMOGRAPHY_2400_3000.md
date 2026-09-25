# Demography: years 2400–3000

**Scope.** The **Demography** research line (`demography` dynamic) for game years 2400–3000, the end of the game. It covers counting people (censuses, civil registration, life tables and population registers), births and child survival, maternity care, contraception and assisted conception, marriage, divorce and family law, pensions and family allowances, and migration, citizenship and refugees. Healing belongs to Health, courts and ministries to Institutions, and wages, factory hours and child labour to Labor; rows that straddle are marked shared. Aggregate population counts stay the simulation's truth. These items adjust fertility, survival, migration, household formation and who counts as a member. Continues `docs/research/y1200/DEMOGRAPHY_1200_1800.md` and the 1800–2400 Demography list. Parish registers, bills of mortality and obstetric forceps are in the 1800–2400 window. The only catalog id in this line's window is `child_growth_records` (belongs-later, placed at 2667). `risk_pools` (catalog 1800) is already placed (Institutions, 850). Rows marked [gov: …] should be read together with the Institutions list in the civic-evolution pass.

**Historical anchor.** `scripts/technology_eras.gd` CURVE (read from `origin/codex/research-1200`) `[[2400,1800],[2800,1950],[3000,2030]]`: game 2400 ≈ AD 1800, 2500 ≈ 1838, 2600 ≈ 1875, 2700 ≈ 1912, 2800 = 1950, 2900 = 1990 and 3000 = 2030, the end of the game. Years 2400–2800 run at 0.375 historical years per game year (steam, railways, industrial chemistry, electricity and the world-scale industrial wars). Years 2800–3000 run at 0.4 (the antibiotic age to the near future). A game year is only four or five historical months, so bands are narrow: ±25 game years for ordinary rows and ±35 for key thresholds (about ±9 and ±13 historical years). Rows near the 2030 frontier are near-future practice; where they are not yet routine they are marked (speculative). None is science fiction. Names are generic alternative-history practices. Real people, companies, nations, wars and events are calibration only. (regional) items suit a climate or tradition and should be gated by terrain or culture.

**Research time.** Game years of staffed research on the item. Real time is for **1 day/s** (1 game year ≈ 6 min; 5 y ≈ 30 min; 10 y ≈ 61 min; 20 y ≈ 2 h). At 3 days/s, divide by 3.

**Id column.** A plain id is in the main catalog today (`scripts/*.gd` or `technology_eras.gd` HISTORICAL_YEAR). Its year is its catalog year through CURVE unless the last table gives a correction. `NEW · slug` = not authored yet. No slug repeats an id in `docs/research/registry.json` (0–600), `y600/registry_1200.json` (600–1200), `y1200/registry_1800.json` (1200–1800), `scripts/*.gd` or HISTORICAL_YEAR; a script checks this. "(continues: id)" names the earlier item a row improves: an item from those registries, an earlier row of this file, or a row of a sister 2400–3000 line. `(shared: X)` straddles another line; `(culture)` feeds this line from Culture. `[gov: offices|court|law|seat|towns|culture]` marks rows that change government, civic life or the court.

**"Today" column.** Earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). "not seen" means the catalog item never completed in a recorded run; `—` for items not in main.

## Years 2400–2700 (≈ AD 1800–1912)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 2411 (2386–2436) | Estates split equally among all children under the civil code (continues: universal_civil_code) (shared: institutions) | 5 y | 30 min | NEW · equal_partible_inheritance | — |
| 2416 (2391–2441) | Smallpox deaths fall in the tables after vaccination (continues: inoculation_mortality_reckoning) (shared: health) | 4 y | 24 min | NEW · vaccination_mortality_tables | — |
| 2432 (2407–2457) | Soldiers' families granted separation allowances (shared: security) | 4 y | 24 min | NEW · soldier_family_allowances | — |
| 2440 (2415–2465) | Pensions for war widows and the orphans of the fallen (continues: war_orphan_upkeep) (shared: security) [gov: offices] | 5 y | 30 min | NEW · war_dependants_pensions | — |
| 2453 (2428–2478) | Assisted emigration: the parish or state pays passage to new lands [gov: seat] | 6 y | 37 min | NEW · assisted_emigration | — |
| 2459 (2434–2484) | Marriage and birth rates reckoned for each age of women (continues: population_tables_office) | 6 y | 37 min | NEW · age_specific_fertility_rates | — |
| 2467 (2442–2492) | Life insurance priced from observed death tables (continues: age_priced_life_annuities) | 6 y | 37 min | NEW · mortality_table_insurance | — |
| 2480 (2455–2505) | State statistical office publishes population and trade tables (continues: population_tables_office) [gov: offices] | 8 y | 49 min | NEW · state_statistical_office | — |
| 2496 (2471–2521) | Colony lands sold in lots to pay the passage of young settler couples (continues: colonist_recruiting_agents) [gov: seat] | 6 y | 37 min | NEW · colony_land_sale_scheme | — |
| 2504 (2479–2529) | Registered deaths tabulated by cause, age and district (continues: civil_vital_registration, infant_death_causes) | 8 y | 49 min | NEW · cause_of_death_tables | — |
| **2509 (2474–2544)** | **Census by household schedule: every name, age, trade and birthplace (continues: decennial_apportionment_census)** | 10 y | 61 min | NEW · household_schedule_census | — |
| 2515 (2490–2540) | Life tables for the whole realm from census and registers (continues: life_expectancy_tables, cause_of_death_tables) | 8 y | 49 min | NEW · national_life_tables | — |
| 2517 (2492–2542) | Crèches for the infants of working mothers (continues: shared_childcare) | 5 y | 30 min | NEW · working_mothers_creches | — |
| 2525 (2500–2550) | Emigrant ships inspected for space, food and water by passenger law (shared: logistics) [gov: law] | 6 y | 37 min | NEW · emigrant_passenger_law | — |
| **2533 (2498–2568)** | **Mass emigration by steamship to distant lands (shared: logistics)** | 10 y | 61 min | NEW · steamship_mass_emigration | — |
| 2536 (2511–2561) | Mortality compared by district and trade (continues: national_life_tables) | 6 y | 37 min | NEW · district_mortality_comparison | — |
| 2539 (2514–2564) | Hospitals for sick children (shared: health) | 6 y | 37 min | NEW · childrens_hospitals | — |
| 2541 (2516–2566) | Congresses of statisticians agree how realms count people (shared: knowledge) | 5 y | 30 min | NEW · inter_realm_statistical_congress | — |
| 2547 (2522–2572) | Rubber sheaths for men sold openly | 5 y | 30 min | NEW · rubber_sheaths | — |
| 2552 (2527–2577) | Civil marriage before a registrar, without the shrine (continues: registered_marriage) (shared: institutions) [gov: law] | 6 y | 37 min | NEW · civil_marriage_registrar | — |
| 2560 (2535–2585) | Orphans boarded out to foster families instead of asylums (continues: orphan_chambers) | 5 y | 30 min | NEW · orphan_boarding_out | — |
| **2565 (2530–2600)** | **Homestead grants: free land to settler families who farm it (shared: institutions) [gov: seat]** | 10 y | 61 min | NEW · homestead_land_grants | — |
| 2579 (2554–2604) | Manufactured infant food and bottle feeding (continues: feeding_horns) (shared: nutrition) | 6 y | 37 min | NEW · manufactured_infant_food | — |
| 2587 (2562–2612) | Naturalisation law: citizenship after years of residence (continues: craftsman_naturalization) [gov: law] | 6 y | 37 min | NEW · residence_naturalisation | — |
| **2595 (2560–2630)** | **Family limitation spreads from the towns to every class (continues: marital_birth_limitation)** | 10 y | 61 min | NEW · family_limitation | — |
| 2597 (2572–2622) | Population pyramids chart ages and sexes (continues: household_schedule_census) | 4 y | 24 min | NEW · population_pyramid_charts | — |
| 2608 (2583–2633) | Heated incubators for premature infants | 6 y | 37 min | NEW · premature_infant_incubator | — |
| 2613 (2588–2638) | Antiseptic maternity wards cut deaths in childbirth (continues: lying_in_hospital) (shared: health) | 8 y | 49 min | NEW · antiseptic_maternity_wards | — |
| 2619 (2594–2644) | Womb sutured after caesarean birth: mother and child both survive (continues: postmortem_cesarean) | 8 y | 49 min | NEW · sutured_caesarean | — |
| 2627 (2602–2652) | Age of consent and minimum marriage age raised by law (continues: minimum_marriage_ages) [gov: law] | 5 y | 30 min | NEW · raised_consent_age | — |
| 2629 (2604–2654) | Settlement houses and trained social workers in poor districts (shared: institutions) | 6 y | 37 min | NEW · settlement_houses | — |
| 2637 (2612–2662) | Street-by-street surveys of household poverty (shared: institutions) | 6 y | 37 min | NEW · household_poverty_surveys | — |
| 2643 (2618–2668) | Census counts rooms and persons per room (continues: household_schedule_census) | 4 y | 24 min | NEW · room_overcrowding_census | — |
| 2645 (2620–2670) | Immigration station inspects arrivals for health and papers [gov: offices] | 6 y | 37 min | NEW · immigration_inspection_station | — |
| 2651 (2626–2676) | Infant milk depots and weighing clinics (continues: nursing_mother_diet) | 6 y | 37 min | NEW · infant_milk_depots | — |
| **2667 (2632–2702)** | **Child growth charted against age standards** | 8 y | 49 min | child_growth_records | 102 |
| 2667 (2642–2692) | Infant mortality rate published as the measure of a town's health | 5 y | 30 min | NEW · infant_mortality_index | — |
| 2672 (2647–2697) | Midwives trained, examined and registered by the state (continues: sworn_town_midwives) [gov: law] | 6 y | 37 min | NEW · registered_midwives | — |
| 2680 (2655–2705) | Health visitors call on every newborn's household | 6 y | 37 min | NEW · newborn_health_visitors | — |
| 2688 (2663–2713) | Child protection law: officers may remove neglected children (continues: orphan_guardianship) [gov: law] | 6 y | 37 min | NEW · child_protection_law | — |
| 2693 (2668–2718) | Antenatal clinics examine mothers before birth | 6 y | 37 min | NEW · antenatal_clinics | — |
| 2696 (2671–2721) | Maternity benefit paid under sickness insurance (continues: worker_sickness_insurance) | 5 y | 30 min | NEW · maternity_benefit | — |
| 2699 (2674–2724) | Children's bureau studies infant and child welfare [gov: offices] | 5 y | 30 min | NEW · childrens_welfare_bureau | — |

## Years 2700–3000 (≈ AD 1912–2030)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| **2709 (2674–2744)** | **Birth-control clinics for married women** | 8 y | 49 min | NEW · birth_control_clinics | — |
| 2723 (2698–2748) | Immigration quotas by origin (continues: immigration_inspection_station, frontier_passport_control) [gov: law] | 5 y | 30 min | NEW · origin_immigration_quotas | — |
| 2728 (2703–2753) | Population exchange by treaty after a war (shared: institutions) [gov: court] | 6 y | 37 min | NEW · treaty_population_exchange | — |
| 2733 (2708–2758) | Contributory pensions for widows and orphans (continues: old_age_pensions) (shared: institutions) [gov: offices] | 5 y | 30 min | NEW · widows_orphans_insurance | — |
| 2736 (2711–2761) | Adoption made a court order with sealed records (continues: heir_adoption) [gov: law] | 5 y | 30 min | NEW · court_adoption_orders | — |
| 2744 (2719–2769) | Demographic transition described: death rates fall first, then birth rates | 10 y | 61 min | NEW · demographic_transition_theory | — |
| 2752 (2727–2777) | Maternal deaths investigated one by one (continues: antenatal_clinics) | 5 y | 30 min | NEW · maternal_death_inquiries | — |
| 2757 (2732–2782) | Pronatalist bonuses and loans to married couples (continues: marriage_incentive_laws) [gov: law] | 5 y | 30 min | NEW · pronatalist_bonuses | — |
| 2763 (2738–2788) | Flying obstetric squads with blood and surgeons for home births | 5 y | 30 min | NEW · obstetric_flying_squads | — |
| 2771 (2746–2796) | Mass evacuation of children from bombed towns (shared: security) [gov: towns] | 5 y | 30 min | NEW · child_evacuation_schemes | — |
| 2773 (2748–2798) | Cohort-component projections of future population | 8 y | 49 min | NEW · cohort_population_projection | — |
| 2787 (2762–2812) | Displaced-persons camps and repatriation after a world war (shared: security) | 6 y | 37 min | NEW · displaced_persons_camps | — |
| **2787 (2752–2822)** | **Family allowances paid for every child (shared: institutions) [gov: offices]** | 8 y | 49 min | NEW · universal_family_allowances | — |
| 2789 (2764–2814) | Birth cohort followed from birth through life | 6 y | 37 min | NEW · birth_cohort_study | — |
| **2802 (2767–2837)** | **Refugee status and non-return defined by treaty (continues: refugee_land_settlement) [gov: law]** | 8 y | 49 min | NEW · refugee_convention | — |
| 2805 (2780–2830) | Hospital birth becomes the norm | 6 y | 37 min | NEW · hospital_birth_norm | — |
| 2812 (2787–2837) | Guest-worker programmes recruit foreign labour (shared: labor) [gov: law] | 5 y | 30 min | NEW · guest_worker_programmes | — |
| 2820 (2795–2845) | Household residence permits bind families to their town or village (continues: internal_passes) [gov: law] | 6 y | 37 min | NEW · household_residence_permits | — |
| **2825 (2790–2860)** | **Daily hormone pill prevents pregnancy** | 12 y | 73 min | NEW · oral_contraceptive_pill | — |
| 2825 (2800–2850) | Retirement villages and a long old age outside work | 4 y | 24 min | NEW · retirement_communities | — |
| 2828 (2803–2853) | Newborn blood spot screened for inherited disease | 5 y | 30 min | NEW · newborn_blood_screening | — |
| 2830 (2805–2855) | Intra-uterine devices and field family-planning workers | 6 y | 37 min | NEW · family_planning_fieldwork | — |
| 2838 (2813–2863) | Newborn intensive care nurseries (continues: premature_infant_incubator) | 8 y | 49 min | NEW · neonatal_intensive_care | — |
| 2840 (2815–2865) | Rh-incompatible mothers protected by an antibody injection | 5 y | 30 min | NEW · rh_disease_prevention | — |
| 2842 (2817–2867) | Points-based immigration by skills and language [gov: law] | 5 y | 30 min | NEW · points_based_immigration | — |
| 2845 (2820–2870) | Personal identity number on one continuous population register (continues: civil_vital_registration) [gov: offices] | 8 y | 49 min | NEW · continuous_population_register | — |
| 2845 (2820–2870) | Public campaigns for the small family (culture) [gov: culture] | 4 y | 24 min | NEW · small_family_campaigns | — |
| 2848 (2823–2873) | Divorce without fault (continues: civil_divorce_courts) (shared: institutions) [gov: law] | 4 y | 24 min | NEW · no_fault_divorce | — |
| 2850 (2825–2875) | Equal rights for children born outside marriage (continues: legitimation_by_marriage) [gov: law] | 4 y | 24 min | NEW · equal_birth_status | — |
| 2855 (2830–2880) | Ultrasound scans follow the unborn child | 6 y | 37 min | NEW · prenatal_ultrasound | — |
| 2858 (2833–2883) | Safe legal termination of pregnancy in clinics [gov: law] | 6 y | 37 min | NEW · legal_pregnancy_termination | — |
| 2860 (2835–2885) | Conference of realms on population and development (culture) [gov: court] | 4 y | 24 min | NEW · inter_realm_population_conference | — |
| 2860 (2835–2885) | Paid parental leave for mothers and fathers (shared: labor) [gov: law] | 6 y | 37 min | NEW · paid_parental_leave | — |
| **2870 (2835–2905)** | **Conception outside the body: the first test-tube birth** | 12 y | 73 min | NEW · in_vitro_fertilisation | — |
| 2870 (2845–2895) | Skin-to-skin care of small newborns by the mother | 4 y | 24 min | NEW · skin_to_skin_newborn_care | — |
| 2872 (2847–2897) | Birth quotas enforced by the state (a grave coercion with long consequences) [gov: law] | 8 y | 49 min | NEW · state_birth_quotas | — |
| 2878 (2853–2903) | Census drawn from registers without enumerators (continues: continuous_population_register) | 6 y | 37 min | NEW · register_based_census | — |
| 2885 (2860–2910) | Household sample surveys of fertility and child health across realms | 6 y | 37 min | NEW · fertility_sample_surveys | — |
| 2888 (2863–2913) | Hormone implants and injections for long-acting contraception (continues: oral_contraceptive_pill) | 5 y | 30 min | NEW · long_acting_contraception | — |
| 2888 (2863–2913) | Surrogate birth contracts regulated by law [gov: law] | 4 y | 24 min | NEW · surrogacy_contracts | — |
| 2898 (2873–2923) | Registered partnerships for unmarried couples [gov: law] | 4 y | 24 min | NEW · registered_partnerships | — |
| 2900 (2875–2925) | Embryos tested for inherited disease before implantation (continues: in_vitro_fertilisation) | 6 y | 37 min | NEW · preimplantation_testing | — |
| 2910 (2885–2935) | Sex-selective scanning banned (continues: prenatal_ultrasound) [gov: law] | 4 y | 24 min | NEW · sex_selection_ban | — |
| **2912 (2877–2947)** | **Long-term care insurance for the frail old [gov: offices]** | 8 y | 49 min | NEW · long_term_care_insurance | — |
| 2922 (2897–2947) | Emergency contraception sold over the counter | 4 y | 24 min | NEW · emergency_contraception | — |
| 2925 (2900–2950) | Dual citizenship permitted [gov: law] | 4 y | 24 min | NEW · dual_citizenship | — |
| 2938 (2913–2963) | Dementia care units and memory clinics (shared: health) | 6 y | 37 min | NEW · dementia_care_units | — |
| 2942 (2917–2967) | Migrants send wages home by mobile phone (shared: logistics) | 4 y | 24 min | NEW · mobile_remittances | — |
| 2945 (2920–2970) | Pension age tied to life expectancy (continues: old_age_pensions) (shared: institutions) [gov: law] | 5 y | 30 min | NEW · indexed_pension_age | — |
| 2955 (2930–2980) | Egg freezing lets women delay childbearing (continues: in_vitro_fertilisation) | 5 y | 30 min | NEW · egg_freezing | — |
| 2960 (2935–2985) | Births registered by mobile phone in remote districts | 4 y | 24 min | NEW · mobile_birth_registration | — |
| 2962 (2937–2987) | Ancestry read from a cheek swab (culture) | 4 y | 24 min | NEW · genetic_ancestry_testing | — |
| 2975 (2950–3000) | Weekly excess-death tracking in a pandemic (continues: cause_of_death_tables) | 5 y | 30 min | NEW · excess_death_tracking | — |
| 2978 (2953–3000) | Visas for remote workers who live in one realm and work for another [gov: law] | 4 y | 24 min | NEW · remote_worker_visas | — |
| 2980 (2955–3000) | Guaranteed childcare places and baby bonuses against very low birth rates (continues: pronatalist_bonuses) [gov: offices] | 6 y | 37 min | NEW · low_fertility_family_package | — |
| **2990 (2955–3000)** | **Planned resettlement of districts lost to rising seas and heat (speculative) (shared: ecology) [gov: seat]** | 8 y | 49 min | NEW · climate_managed_resettlement | — |
| 2998 (2973–3000) | Support for extremely premature infants in fluid-filled womb systems (speculative) | 10 y | 61 min | NEW · artificial_womb_support | — |

## Pacing

| Years | 2400–2450 | 2450–2500 | 2500–2550 | 2550–2600 | 2600–2650 | 2650–2700 | 2700–2750 | 2750–2800 | 2800–2850 | 2850–2900 | 2900–2950 | 2950–3000 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Demography advances | 4 | 5 | 10 | 7 | 8 | 9 | 6 | 8 | 14 | 13 | 8 | 8 |

The total is **100** advances: 43 in years 2400–2700 and 57 in 2700–3000, one about every 6.0 game years. Laws and single practices take 4–6 years (24–37 min). Censuses, registers and insurance schemes take 8–12 years. The 12 key thresholds take 8–12 years (49–73 min). The first century builds the statistical state on the 1800–2400 census and civil registers: cause-of-death tables, household schedules and life tables. It also opens mass emigration. The second brings family limitation, safer childbirth, pensions, infant clinics and growth charts. After 2700 come frontier papers and quotas, birth control, family allowances and refugee law, then the pill, test-tube conception and continuous population registers. The line ends with ageing and very low birth rates, and with speculative managed resettlement from climate change.

**Key thresholds:**
1. **Counting people:** 1800–2400's `decennial_apportionment_census` (2380) and `civil_vital_registration` (2385) → vaccination mortality tables (2416) → age-specific fertility rates (2459) → statistical office (2480) → cause-of-death tables (2504) → household-schedule census (2509) → national life tables (2515) → statistical congresses (2541) → population pyramids (2597) → cohort projections (2773) → continuous register (2845) → register-based census (2878) → Institutions' `digital_identity_register` (2930) → mobile birth registration (2960) → excess-death tracking (2975).
2. **Childbirth and infants:** 1800–2400's `lying_in_hospital` (2294) → chlorine hand-washing (Health, 2525) → antiseptic maternity wards (2613) → sutured caesarean (2619) → infant milk depots (2651) → `child_growth_records` (2667) → registered midwives (2672) → antenatal clinics (2693) → maternal death inquiries (2752) → hospital birth (2805) → newborn screening and intensive care (2828–2838).
3. **Fertility choice:** 1800–2400's `population_pressure_treatise` (2396) and `marital_birth_limitation` (2364) → rubber sheaths (2547) → family limitation (2595) → birth-control clinics (2709) → the pill (2825) → family-planning fieldwork (2830) → legal termination (2858) → in-vitro fertilisation (2870) → long-acting contraception (2888) → egg freezing (2955).
4. **Migration and membership:** assisted emigration (2453) → colony land sales (2496) → passenger law (2525) → steamship mass emigration (2533) → homestead grants (2565) → naturalisation (2587) → immigration station (2645) → Institutions' `frontier_passport_control` (2707) → origin quotas (2723) → refugee convention (2802) → guest workers (2812) → points-based entry (2842) → dual citizenship (2925) → managed climate resettlement (2990, speculative).
5. **Family, age and support:** Institutions' `poor_law_boards` (2491) → civil marriage (2552) → Institutions' `civil_divorce_courts` (2552), `married_women_property` (2619) and `old_age_pensions` (2637) → maternity benefit (2696) → widows' and orphans' insurance (2733) → family allowances (2787) → no-fault divorce (2848) → parental leave (2860) → long-term care insurance (2912) → indexed pension age (2945) → low-fertility family package (2980).
6. **Ownership of overlaps:** Health owns hospitals, antisepsis, chlorine hand-washing, sulfa drugs and oral rehydration; maternity wards, children's hospitals and dementia care are shared. Nutrition owns school meals, rickets, folic acid and therapeutic food; manufactured infant food is placed here (shared). Labor owns factory and child-labour law, friendly societies and seasonal migrant contracts; guest workers and parental leave are shared. Institutions owns courts, ministries and social-security administration, and keeps `poor_law_boards` (2491), `civil_divorce_courts` (2552), `married_women_property` (2619), `old_age_pensions` (2637), `frontier_passport_control` (2707), `welfare_state` (2789), `equal_marriage_law` (2928) and `digital_identity_register` (2930); this line continues them. Civil marriage, homestead grants, settlement houses, poverty surveys, family allowances and the population exchange are shared. Security owns evacuations as operations; soldiers' family allowances, war dependants' pensions, child evacuation and displaced-persons camps are shared.

## Government and civic life

These should visibly change government and civic life in the civic-evolution pass:
- **state_statistical_office (2480)** and **household_schedule_census (2509)**: building on the 1800–2400 census and civil registrars, a registrar general and a statistical office join the court, and the census book with its household schedules becomes the realm's count.
- **widows_orphans_insurance (2733)**, **universal_family_allowances (2787)**, **long_term_care_insurance (2912)** and **indexed_pension_age (2945)**: with Institutions' poor-law boards and pensions, relief moves from the parish to the state. A family-benefits office pays for children, widows and the frail old, and the pension age follows the life tables.
- **civil_marriage_registrar (2552)**, **no_fault_divorce (2848)**, **equal_birth_status (2850)** and **registered_partnerships (2898)**: with Institutions' divorce courts and equal marriage law, marriage becomes a civil contract under a family court, not a matter for the shrine alone. Succession at the seat of rule follows these rules.
- **homestead_land_grants (2565)**, **assisted_emigration (2453)** and **colony_land_sale_scheme (2496)**: a lands and emigration office settles new districts, and new towns are founded by settler families.
- **immigration_inspection_station (2645)**, **origin_immigration_quotas (2723)**, **refugee_convention (2802)** and **points_based_immigration (2842)**: frontier officials, consuls issuing visas and an immigration ministry appear. Refugee treaties bind the court's treatment of arrivals.
- **household_residence_permits (2820)** and **state_birth_quotas (2872)**: coercive tools a god-ruler can impose. They fix people in place and limit births, at a lasting cost in trust and in the age balance.
- **registered_midwives (2672)**, **childrens_welfare_bureau (2699)** and **child_protection_law (2688)**: a midwives' board, child welfare officers and a children's bureau become standing offices.

## Currently far too early / too late (demography line, main)

| Item | Seen | Belongs |
|---|---|---|
| child_growth_records (catalog 1900 ≈ 2667) | 102 | 2667. It is seen about 2,565 game years early. |
| risk_pools (catalog 1800 ≈ 2400) | — | Already placed by Institutions at 850 (600–1200). It is not relisted. |
| Parish registers, weekly bills of mortality, obstetric forceps | — | 1800–2400 window (≈ 1950 / 2190 / 2060) |
| Ten-yearly census, civil registration, population treatise | — | Placed by the 1800–2400 Demography list (2380 / 2385 / 2396). Household-schedule census placed here (2509). |

