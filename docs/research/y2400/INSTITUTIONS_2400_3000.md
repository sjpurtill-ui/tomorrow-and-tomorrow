# Institutions: years 2400–3000

**Scope.** This file is the **Institutions** line for game years 2400–3000 (`institutions` dynamic; `direction: "Society"`). It has four channels: Administration, Legitimacy, State capacity and Institutional flexibility, and it continues `y1200/INSTITUTIONS_1200_1800.md` and the 1800–2400 Institutions list. It carries most of the government change in this window: the civil code, administrative courts and constitutional courts, granted constitutions under the living god, ministries and the examined civil service, the widening vote, parties and ceremonial crowns, social insurance and the welfare state, central banks and money, one-party states, central planning and propaganda, the leagues and world assembly of realms, rights courts, and the digital state. The living god stands above every ruler, so constitutions are granted and sworn in the god's name. **No catalog id is placed here:** the only `Society` catalog id dated in this window, `risk_pools` (AD 1800), was already placed at 850. Items owned by other lines are left out: factory acts, unions, the eight-hour day and minimum wages (Labor); the census and civil registration (Demography); public health boards, the national health service and workers' sickness insurance (Health); conscription, town police, political police, mass interception, intelligence services, the wounded-protection and land-war conventions (Security); environmental agencies and parks (Ecology); the postal union and state railway administration (Logistics); abolition of estate privileges, the first civil code, the republic and the federal constitution (1800–2400 Institutions list). Several rows (the plebiscite, the one-party state, emergency decrees, the propaganda ministry, corporatist chambers) strengthen the state at the people's cost. They are real options, not upgrades.

**Government tags.** Rows that should visibly change government or civic life carry a tag in the Discovery column. The legend continues the 1200–1800 one:
- **[gov: offices]**: a new or reshaped office or agency.
- **[gov: court]**: a change in who sits in the ruling councils, chambers and assemblies, or who elects them.
- **[gov: law]**: a change in law or legal procedure.
- **[gov: seat]**: a change in the seat of rule, the head of state or the form of the realm.
- **[gov: towns]**: a change in the government of towns and districts.
- **[gov: culture]**: a change in the public opinion that government answers to (press, broadcast, movements); used mainly in Culture.

The civic-evolution pass should read these tags. Tagged rows in Knowledge and Culture are listed in those files and summarized below.

**Historical anchor.** The `CURVE` in `scripts/technology_eras.gd` (`[[2400,1800],[2800,1950],[3000,2030]]`) maps game 2400 to AD 1800, 2500 to ≈ 1838, 2600 to ≈ 1875, 2700 to ≈ 1912, 2800 to 1950, 2900 to ≈ 1990 and 3000 to 2030, the end of the game. Years 2400–2800 run at 0.375 historical years per game year: steam, railways and the telegraph, industrial chemistry, electricity, mass politics and the first world-scale industrial wars. Years 2800–3000 run at 0.4 historical years per game year: computing, nuclear power, spaceflight, networks and the information age, ending in the near future of 2030. Items near 3000 are plausible extensions of what exists by the mid-2020s, not science fiction. Names are generic alternative-history practices. Real places, people, companies, states, wars and religions are used only for calibration.

**Research time.** Time is given in game years while a staffed Institutions team is working on the item. Real minutes are for **1 day/s** (speed setting 4). In real time, 1 game year is about 6 minutes, and 10 game years are about 1 hour. At 3 days/s, divide by 3. At 8 h/s, multiply by 3.

**Id column.** A plain id is in the main catalog today; its game year comes from `HISTORICAL_YEAR` through `CURVE` unless the last table gives a correction. `NEW` = not authored yet. No `NEW` slug repeats an id in `docs/research/registry.json` (0–600), `docs/research/y600/registry_1200.json` (600–1200), `docs/research/y1200/registry_1800.json` (1200–1800, merge aliases included) or `scripts/*.gd`. "(continues: id)" names an earlier item that a row improves, an earlier row of this file, or a row in another 2400–3000 line.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). "not seen" means the catalog item never completed in a recorded run. It is `—` when the item is not in main.

## Years 2400–2700 (≈ AD 1800–1912)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 2403 (2378–2428) | Appointed prefects run the uniform departments [gov: offices] (continues: uniform_departments) | 8 y | 49 min | NEW · appointed_department_prefects | — |
| 2405 (2380–2430) | Order of merit open to commoners [gov: court] | 4 y | 24 min | NEW · civil_merit_order | — |
| **2411 (2376–2446)** | **One civil code for all persons, property and contracts [gov: law] (continues: compiled_civil_code)** | 15 y | 91 min | NEW · universal_civil_code | — |
| 2416 (2391–2441) | Administrative courts judge the state's own acts [gov: law] | 8 y | 49 min | NEW · administrative_courts | — |
| 2419 (2394–2444) | Commercial code for merchants, bills and companies [gov: law] (continues: universal_civil_code) | 6 y | 36 min | NEW · commercial_code | — |
| 2424 (2399–2449) | The assembly's ombudsman hears complaints against officials [gov: offices] | 6 y | 36 min | NEW · assembly_ombudsman | — |
| 2427 (2402–2452) | Single-minister departments, each answerable for its field [gov: offices] (continues: three_department_ministries) | 8 y | 49 min | NEW · single_minister_departments | — |
| **2437 (2402–2472)** | **Ruler bound by a granted written constitution under the god [gov: seat] (continues: great_liberties_charter)** | 12 y | 73 min | NEW · granted_constitution | — |
| 2440 (2415–2465) | Standing conference of great realms settles borders [gov: court] | 8 y | 49 min | NEW · great_realm_conference | — |
| 2443 (2418–2468) | Annual budget voted line by line by the chamber [gov: law] (continues: consented_taxation) | 6 y | 36 min | NEW · annual_budget_vote | — |
| 2453 (2428–2478) | Penitentiary sentences replace most hangings [gov: law] | 8 y | 49 min | NEW · penitentiary_sentences | — |
| 2480 (2455–2505) | Ministry of public instruction [gov: offices] | 6 y | 36 min | NEW · public_instruction_ministry | — |
| **2485 (2450–2520)** | **Franchise widened to middling householders [gov: court]** | 10 y | 61 min | NEW · householder_franchise | — |
| 2491 (2466–2516) | Central poor-law board with union workhouses [gov: offices] (continues: workhouse_test) | 8 y | 49 min | NEW · poor_law_boards | — |
| **2491 (2456–2526)** | **Customs union ends tolls between member realms [gov: seat]** | 8 y | 49 min | NEW · customs_union | — |
| 2496 (2471–2521) | Examined patent office grants inventors' rights [gov: offices] | 6 y | 36 min | NEW · examined_patent_office | — |
| **2509 (2474–2544)** | **Ministers resign when they lose a confidence vote in the elected chamber [gov: court] (continues: cabinet_first_minister)** | 10 y | 61 min | NEW · responsible_ministry | — |
| 2517 (2492–2542) | Central bank given sole right to issue notes [gov: offices] (continues: chartered_central_bank) | 8 y | 49 min | NEW · central_note_monopoly | — |
| 2520 (2495–2545) | Bankrupts discharged; prison for debt ends [gov: law] | 5 y | 30 min | NEW · bankruptcy_discharge | — |
| 2523 (2498–2548) | Grain tariffs repealed for free trade [gov: law] | 6 y | 36 min | NEW · grain_tariff_repeal | — |
| **2528 (2493–2563)** | **Every grown man votes [gov: court] (continues: householder_franchise)** | 12 y | 73 min | NEW · manhood_suffrage | — |
| **2533 (2498–2568)** | **Mass parties with platforms, clubs and newspapers [gov: court] (continues: estates_parties)** | 10 y | 61 min | NEW · mass_political_parties | — |
| 2536 (2511–2561) | Plebiscite confirms the ruler's rule by popular vote [gov: seat] | 6 y | 36 min | NEW · ruler_plebiscite | — |
| **2541 (2506–2576)** | **Civil service by open competitive examination [gov: offices] (continues: cameral_service_examinations)** | 12 y | 73 min | NEW · competitive_civil_service | — |
| 2547 (2522–2572) | Limited liability by simple registration [gov: law] | 8 y | 49 min | NEW · limited_liability_registration | — |
| 2549 (2524–2574) | Secret printed ballot [gov: law] | 8 y | 49 min | NEW · secret_printed_ballot | — |
| 2552 (2527–2577) | Divorce granted by civil courts [gov: law] | 5 y | 30 min | NEW · civil_divorce_courts | — |
| 2555 (2530–2580) | Ministry for distant dependencies [gov: offices] | 6 y | 36 min | NEW · dependencies_ministry | — |
| 2571 (2546–2596) | Elected rural district assemblies [gov: towns] | 6 y | 36 min | NEW · rural_district_assemblies | — |
| 2576 (2551–2601) | Central bank lends freely in panics (continues: central_note_monopoly) | 6 y | 36 min | NEW · lender_of_last_resort | — |
| 2576 (2551–2601) | Audit office reports to the chamber, not the ministers [gov: offices] (continues: fixed_court_of_accounts) | 6 y | 36 min | NEW · independent_audit_office | — |
| 2579 (2554–2604) | The crown reigns while ministers govern [gov: seat] (continues: granted_constitution) | 8 y | 49 min | NEW · ceremonial_crown | — |
| 2592 (2567–2617) | Standing arbitration between realms [gov: law] | 6 y | 36 min | NEW · interrealm_arbitration | — |
| 2592 (2567–2617) | Career diplomatic service with embassies in every realm [gov: offices] | 6 y | 36 min | NEW · career_diplomatic_service | — |
| 2595 (2570–2620) | Linked gold standard among trading realms | 8 y | 49 min | NEW · gold_standard_link | — |
| 2600 (2575–2625) | Towns own their water, gas and trams [gov: towns] | 6 y | 36 min | NEW · municipal_utilities | — |
| 2608 (2583–2633) | Probation and parole instead of the full sentence [gov: law] | 5 y | 30 min | NEW · probation_parole | — |
| 2619 (2594–2644) | Married women keep their own property [gov: law] | 6 y | 36 min | NEW · married_women_property | — |
| 2629 (2604–2654) | Public companies must publish audited accounts [gov: law] (continues: limited_liability_registration) | 5 y | 30 min | NEW · audited_company_accounts | — |
| 2635 (2610–2660) | Elected county councils [gov: towns] | 6 y | 36 min | NEW · elected_county_councils | — |
| 2637 (2612–2662) | Old-age pensions paid by the state [gov: offices] | 8 y | 49 min | NEW · old_age_pensions | — |
| 2640 (2615–2665) | Law against monopolies and price rings [gov: law] | 8 y | 49 min | NEW · antimonopoly_law | — |
| **2648 (2613–2683)** | **Women vote [gov: court] (continues: manhood_suffrage)** | 12 y | 73 min | NEW · womens_suffrage | — |
| 2661 (2636–2686) | Citizens' initiative and referendum [gov: law] | 6 y | 36 min | NEW · initiative_referendum | — |
| 2664 (2639–2689) | Proportional representation by party lists [gov: court] | 6 y | 36 min | NEW · proportional_representation | — |
| 2664 (2639–2689) | Juvenile courts [gov: law] | 5 y | 30 min | NEW · juvenile_courts | — |
| 2685 (2660–2710) | Commissions regulate rail, gas, power and water rates [gov: offices] | 6 y | 36 min | NEW · rate_regulation_commissions | — |
| 2696 (2671–2721) | Unemployment insurance [gov: offices] (continues: worker_sickness_insurance) | 8 y | 49 min | NEW · unemployment_insurance | — |
| 2696 (2671–2721) | Upper chamber loses its veto over money bills [gov: court] | 6 y | 36 min | NEW · upper_chamber_curbed | — |

## Years 2700–3000 (≈ AD 1912–2030)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| **2704 (2669–2739)** | **War economy boards direct industry, labour and raw materials [gov: offices]** | 10 y | 61 min | NEW · war_economy_boards | — |
| 2707 (2682–2732) | Passports and visas at every frontier [gov: law] | 6 y | 36 min | NEW · frontier_passport_control | — |
| **2712 (2677–2747)** | **One-party state: the ruling party fuses with the state [gov: seat]** | 12 y | 73 min | NEW · one_party_state | — |
| **2717 (2682–2752)** | **League of realms: standing assembly, council and secretariat [gov: court] (continues: great_realm_conference)** | 12 y | 73 min | NEW · league_of_realms | — |
| **2720 (2685–2755)** | **Constitutional court strikes down unlawful laws [gov: law]** | 10 y | 61 min | NEW · constitutional_court | — |
| 2725 (2700–2750) | Permanent court between realms [gov: law] (continues: interrealm_arbitration) | 6 y | 36 min | NEW · interrealm_permanent_court | — |
| 2736 (2711–2761) | Chambers of trades and employers sit in the state [gov: court] | 6 y | 36 min | NEW · corporatist_chambers | — |
| **2741 (2706–2776)** | **Five-year central plan for the whole economy [gov: offices]** | 12 y | 73 min | NEW · central_five_year_plan | — |
| 2747 (2722–2772) | Emergency decrees suspend the chamber [gov: law] (continues: emergency_safety_committee) | 6 y | 36 min | NEW · emergency_decree_rule | — |
| 2755 (2730–2780) | State propaganda ministry commands press and broadcast [gov: offices] | 8 y | 49 min | NEW · state_propaganda_ministry | — |
| 2755 (2730–2780) | Deposit insurance for small savers | 5 y | 30 min | NEW · deposit_insurance | — |
| 2757 (2732–2782) | Securities commission polices share markets [gov: offices] | 6 y | 36 min | NEW · securities_commission | — |
| 2757 (2732–2782) | National accounts measure total output [gov: offices] | 8 y | 49 min | NEW · national_income_accounts | — |
| 2763 (2738–2788) | State spending steadies the slump | 8 y | 49 min | NEW · countercyclical_spending | — |
| 2784 (2759–2809) | Fixed exchange accord and a world monetary fund | 8 y | 49 min | NEW · fixed_exchange_accord | — |
| **2787 (2752–2822)** | **World assembly of realms with a security council and agencies [gov: court] (continues: league_of_realms)** | 12 y | 73 min | NEW · world_assembly_of_realms | — |
| 2787 (2762–2812) | Tribunals try leaders for crimes against peoples [gov: law] | 8 y | 49 min | NEW · atrocity_tribunals | — |
| **2789 (2754–2824)** | **Welfare state: one social insurance and assistance office from cradle to grave [gov: offices] (continues: worker_sickness_insurance)** | 15 y | 91 min | NEW · welfare_state | — |
| 2789 (2764–2814) | Core industries taken into state ownership [gov: offices] | 6 y | 36 min | NEW · nationalized_core_industries | — |
| 2795 (2770–2820) | Declaration of the rights of every person, agreed between realms [gov: law] (continues: declaration_of_rights) | 8 y | 49 min | NEW · universal_rights_declaration | — |
| 2800 (2775–2825) | Regional court of personal rights [gov: law] | 6 y | 36 min | NEW · regional_rights_court | — |
| 2810 (2785–2835) | Value-added tax | 5 y | 30 min | NEW · value_added_tax | — |
| **2818 (2783–2853)** | **Common market of neighbouring realms [gov: seat]** | 10 y | 61 min | NEW · common_market_union | — |
| **2825 (2790–2860)** | **Self-rule granted to former dependencies [gov: seat] (continues: dependencies_ministry)** | 10 y | 61 min | NEW · dependency_self_rule | — |
| 2832 (2807–2857) | Public defenders for the accused poor [gov: law] | 5 y | 30 min | NEW · public_defenders | — |
| **2835 (2800–2870)** | **Civil rights law forbids discrimination [gov: law]** | 8 y | 49 min | NEW · civil_rights_law | — |
| 2838 (2813–2863) | Death penalty abolished [gov: law] | 5 y | 30 min | NEW · death_penalty_abolition | — |
| 2840 (2815–2865) | Freedom of information law [gov: law] | 5 y | 30 min | NEW · freedom_of_information | — |
| 2845 (2820–2870) | Ombudsmen for every ministry and town (continues: assembly_ombudsman) [gov: offices] | 4 y | 24 min | NEW · ombudsman_network | — |
| 2852 (2827–2877) | Floating currencies backed only by the state | 6 y | 36 min | NEW · floating_fiat_currency | — |
| 2858 (2833–2883) | Personal data protection law [gov: law] | 5 y | 30 min | NEW · personal_data_protection | — |
| 2860 (2835–2885) | Independent anti-corruption commission [gov: offices] | 6 y | 36 min | NEW · anticorruption_commission | — |
| 2872 (2847–2897) | State enterprises sold to shareholders | 6 y | 36 min | NEW · state_enterprise_privatization | — |
| 2885 (2860–2910) | Truth commissions hear victims of past rule by force [gov: law] | 5 y | 30 min | NEW · truth_commissions | — |
| 2898 (2873–2923) | Town budgets decided in open neighbourhood assemblies [gov: towns] | 5 y | 30 min | NEW · participatory_budgets | — |
| 2900 (2875–2925) | Independent central bank targets inflation [gov: offices] | 6 y | 36 min | NEW · inflation_targeting | — |
| 2905 (2880–2930) | Independent electoral commissions [gov: offices] | 5 y | 30 min | NEW · electoral_commissions | — |
| 2912 (2887–2937) | World trade body with dispute panels | 6 y | 36 min | NEW · trade_dispute_panels | — |
| 2922 (2897–2947) | Single currency shared by many realms (continues: common_market_union) | 8 y | 49 min | NEW · single_currency_union | — |
| 2925 (2900–2950) | Government services offered online [gov: offices] | 6 y | 36 min | NEW · online_government_services | — |
| 2928 (2903–2953) | Marriage open to all couples [gov: law] | 5 y | 30 min | NEW · equal_marriage_law | — |
| 2930 (2905–2955) | Permanent court for crimes against peoples [gov: law] (continues: atrocity_tribunals) | 6 y | 36 min | NEW · permanent_atrocity_court | — |
| 2930 (2905–2955) | Digital identity for signing and using public services online [gov: offices] (continues: continuous_population_register) | 6 y | 36 min | NEW · digital_identity_register | — |
| 2948 (2923–2973) | Bank resolution regimes and stress tests | 5 y | 30 min | NEW · bank_stress_tests | — |
| 2950 (2925–2975) | Open government data published by default [gov: offices] | 5 y | 30 min | NEW · open_government_data | — |
| 2960 (2935–2985) | Lobbying register and conflict-of-interest rules [gov: offices] | 5 y | 30 min | NEW · lobbying_register | — |
| 2970 (2945–2995) | Comprehensive data-rights regulation [gov: law] (continues: personal_data_protection) | 5 y | 30 min | NEW · comprehensive_data_rights | — |
| 2978 (2953–3000) | Minimum tax on large firms agreed between realms | 5 y | 30 min | NEW · global_minimum_tax | — |
| 2985 (2960–3000) | Risk-tiered law for learned-machine systems [gov: law] | 6 y | 36 min | NEW · learned_machine_law | — |
| 2992 (2967–3000) | Audits of algorithmic decisions in public offices [gov: offices] | 6 y | 36 min | NEW · algorithmic_decision_audits | — |
| 3000 (2975–3000) | Central-bank digital currency (continues: floating_fiat_currency) | 6 y | 36 min | NEW · central_bank_digital_currency | — |

## Pacing

| Years | 2400–2450 | 2450–2500 | 2500–2550 | 2550–2600 | 2600–2650 | 2650–2700 | 2700–2750 | 2750–2800 | 2800–2850 | 2850–2900 | 2900–2950 | 2950–3000 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Institutions advances | 10 | 6 | 10 | 9 | 8 | 6 | 9 | 11 | 9 | 6 | 9 | 7 |

The total is **100** advances: 49 in years 2400–2700 and 51 in years 2700–3000. Across the four channels, one lands about every 6 years. Most items take 5–8 years. Long thresholds (19 bold rows) take 10–15 years (1–1.5 real hours). 2400–2550 (≈ AD 1800–1856) is dense with codes, constitutions and franchise reform; 2700–2800 (≈ AD 1912–1950) with war boards, one-party states, planning and world bodies.

**Key thresholds:**
1. **Law and rights:** universal_civil_code (2411) → administrative_courts (2416) → constitutional_court (2720) → universal_rights_declaration (2795) → regional_rights_court (2800) → civil_rights_law (2835) → freedom_of_information (2840) → personal_data_protection (2858) → comprehensive_data_rights (2970) → learned_machine_law (2985).
2. **Who governs:** granted_constitution (2437) → householder_franchise (2485) → responsible_ministry (2509) → manhood_suffrage (2528) → mass_political_parties (2533) → secret_printed_ballot (2549) → womens_suffrage (2648) → proportional_representation (2664) → electoral_commissions (2905). The darker branch: ruler_plebiscite (2536) → one_party_state (2712) → emergency_decree_rule (2747) → state_propaganda_ministry (2755).
3. **Offices and the civil service:** appointed_department_prefects (2403) → single_minister_departments (2427) → public_instruction_ministry (2480) → competitive_civil_service (2541) → independent_audit_office (2576) → rate_regulation_commissions (2685) → war_economy_boards (2704) → national_income_accounts (2757) → online_government_services (2925) → algorithmic_decision_audits (2992).
4. **Social insurance:** poor_law_boards (2491) → old_age_pensions (2637) → unemployment_insurance (2696) → welfare_state (2789). Health owns `worker_sickness_insurance` (2621) and `national_health_service` (2795), which these rows build on.
5. **Money and the market:** central_note_monopoly (2517) → limited_liability_registration (2547) → lender_of_last_resort (2576) → gold_standard_link (2595) → antimonopoly_law (2640) → deposit_insurance (2755) → fixed_exchange_accord (2784) → floating_fiat_currency (2852) → inflation_targeting (2900) → single_currency_union (2922) → central_bank_digital_currency (3000). The planned branch: central_five_year_plan (2741) → nationalized_core_industries (2789) → state_enterprise_privatization (2872).
6. **Seat of rule:** granted_constitution (2437) → ruler_plebiscite (2536) → ceremonial_crown (2579) → one_party_state (2712) → common_market_union (2818) → dependency_self_rule (2825). The seat moves from a ruler's palace to a chamber, a cabinet room and ministries, and at the end to digital services.
7. **Between realms:** great_realm_conference (2440) → interrealm_arbitration (2592) → league_of_realms (2717) → interrealm_permanent_court (2725) → world_assembly_of_realms (2787) → atrocity_tribunals (2787) → trade_dispute_panels (2912) → permanent_atrocity_court (2930). Generals read the conventions; the player never directs units.
8. **Towns and districts:** rural_district_assemblies (2571) → municipal_utilities (2600) → elected_county_councils (2635).
9. **Ownership of overlaps:** labor law, unions and pensions for particular trades are Labor; `old_age_pensions` and `unemployment_insurance` are the state schemes. The convention protecting the wounded is Health's (`neutral_wounded_convention`, 2571, shared with Security); Security's `wounded_protection_convention` row was the same treaty and was dropped. It is not repeated here. National accounts are here; the census and civil registration are Demography. Town police, political police and mass interception are Security (`uniformed_beat_police` 2477, `political_police_bureau` 2613, `mass_signals_surveillance` 2928); Institutions keeps the courts, data laws and audits that check them, and the security council inside `world_assembly_of_realms`. The national health service and workers' sickness insurance are Health (`national_health_service`, `worker_sickness_insurance`); `welfare_state` is the wider insurance office. School laws are Knowledge (`compulsory_elementary_schooling`, `universal_secondary_schooling`); the ministry that runs them is here. Rail rates are regulated by `rate_regulation_commissions` (Logistics defers to it).

## Government and civic life

All tagged rows, by tag (for the civic-evolution pass):

   - **Offices (30):** `appointed_department_prefects` 2403, `assembly_ombudsman` 2424, `single_minister_departments` 2427, `public_instruction_ministry` 2480, `poor_law_boards` 2491, `examined_patent_office` 2496, `central_note_monopoly` 2517, `competitive_civil_service` 2541, `dependencies_ministry` 2555, `independent_audit_office` 2576, `career_diplomatic_service` 2592, `old_age_pensions` 2637, `rate_regulation_commissions` 2685, `unemployment_insurance` 2696, `war_economy_boards` 2704, `central_five_year_plan` 2741, `state_propaganda_ministry` 2755, `securities_commission` 2757, `national_income_accounts` 2757, `welfare_state` 2789, `nationalized_core_industries` 2789, `ombudsman_network` 2845, `anticorruption_commission` 2860, `inflation_targeting` 2900, `electoral_commissions` 2905, `online_government_services` 2925, `digital_identity_register` 2930, `open_government_data` 2950, `lobbying_register` 2960, `algorithmic_decision_audits` 2992.
   - **Court (12):** `civil_merit_order` 2405, `great_realm_conference` 2440, `householder_franchise` 2485, `responsible_ministry` 2509, `manhood_suffrage` 2528, `mass_political_parties` 2533, `womens_suffrage` 2648, `proportional_representation` 2664, `upper_chamber_curbed` 2696, `league_of_realms` 2717, `corporatist_chambers` 2736, `world_assembly_of_realms` 2787.
   - **Law (34):** `universal_civil_code` 2411, `administrative_courts` 2416, `commercial_code` 2419, `annual_budget_vote` 2443, `penitentiary_sentences` 2453, `bankruptcy_discharge` 2520, `grain_tariff_repeal` 2523, `limited_liability_registration` 2547, `secret_printed_ballot` 2549, `civil_divorce_courts` 2552, `interrealm_arbitration` 2592, `probation_parole` 2608, `married_women_property` 2619, `audited_company_accounts` 2629, `antimonopoly_law` 2640, `initiative_referendum` 2661, `juvenile_courts` 2664, `frontier_passport_control` 2707, `constitutional_court` 2720, `interrealm_permanent_court` 2725, `emergency_decree_rule` 2747, `atrocity_tribunals` 2787, `universal_rights_declaration` 2795, `regional_rights_court` 2800, `public_defenders` 2832, `civil_rights_law` 2835, `death_penalty_abolition` 2838, `freedom_of_information` 2840, `personal_data_protection` 2858, `truth_commissions` 2885, `equal_marriage_law` 2928, `permanent_atrocity_court` 2930, `comprehensive_data_rights` 2970, `learned_machine_law` 2985.
   - **Seat of rule (7):** `granted_constitution` 2437, `customs_union` 2491, `ruler_plebiscite` 2536, `ceremonial_crown` 2579, `one_party_state` 2712, `common_market_union` 2818, `dependency_self_rule` 2825.
   - **Towns and local government (4):** `rural_district_assemblies` 2571, `municipal_utilities` 2600, `elected_county_councils` 2635, `participatory_budgets` 2898.

   - **Tagged in other lines:** Knowledge — Law: `compulsory_elementary_schooling` 2587, `universal_secondary_schooling` 2784; Offices: `punched_card_tabulation` 2640, `state_great_laboratories` 2779. Culture — Public opinion and media: `penny_daily_press` 2488, `political_cartoon_weeklies` 2509, `womens_rights_convention` 2528, `common_ownership_doctrine` 2528, `national_history_lessons` 2587, `workers_festival_day` 2637, `million_reader_dailies` 2667, `war_newsreels_posters` 2704, `radio_broadcasting` 2720, `television_broadcasting` 2763, `televised_debates` 2825, `nonviolent_rights_movements` 2832, `youth_counterculture` 2845, `womens_liberation_movement` 2850, `many_cultures_policy` 2852, `continuous_news_channels` 2875, `online_social_networks` 2935, `networked_protest_movements` 2952, `algorithmic_feeds` 2955, `networked_disinformation` 2965; Seat of rule: `national_unity_movements` 2528, `great_realms_exhibition` 2536, `unknown_warrior_remembrance` 2720, `leader_mass_rallies` 2755, `televised_state_rites` 2808; Law: `monument_protection_law` 2619; Offices: `public_broadcasting_charter` 2725.

Untagged rows that still matter: `lender_of_last_resort`, `gold_standard_link`, `deposit_insurance`, `countercyclical_spending`, `fixed_exchange_accord`, `value_added_tax`, `floating_fiat_currency`, `state_enterprise_privatization`, `trade_dispute_panels`, `single_currency_union`, `bank_stress_tests` and `central_bank_digital_currency` change what the treasury and central bank can do, not who governs.

## Currently too early / too late (institutions line, main)

These are placement targets only. "Seen" is the earliest year in recorded runs.

| Item | Seen | Belongs |
|---|---|---|
| risk_pools (catalog AD 1800 ≈ 2400) | not seen | Already placed at 850 (600–1200). Its successors here are `deposit_insurance` (2755) and `old_age_pensions` (2637). |
| craft_guilds (catalog AD 1100) | ≈100 | Placed at 1583 (1200–1800). Guild and estate privileges end with the 1800–2400 list's `abolition_of_estate_privileges` (2378). |
| military_staffs (catalog AD 1326) | — | Security line (≈ 2200–2300). Civilian ministries that answer for war are `war_economy_boards` (2704). |
