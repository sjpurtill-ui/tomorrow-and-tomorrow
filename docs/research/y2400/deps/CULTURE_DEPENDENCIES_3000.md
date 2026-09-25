# Culture dependencies: years 2400–3000

Machine-readable source: `partials/kicl.json` (knowledge, institutions, culture, labor). Contract: the 600–1200 mapping (`docs/research/y600/deps/partials/kicl.json`, merged by `tools/research/merge_graph_1200.py`) and its 1200–1800 and 1800–2400 successors. Ids come from `registry_3000.json`, `registry_2400.json` with the 1800–2400 partials, the 1200–1800 graph (`docs/research/y1200/deps/graph_1800.json`), and the game's baked 0–600 and 600–1200 blocks. Prerequisites may be ids of any earlier block in any line, or 2400–3000 ids, and every prerequisite and precedent is dated at or before its dependent (registry target years after the year adjustments; earlier blocks at their baked or graph years). Brackets mark a parent from another line or an earlier block: `[production]` is a 2400–3000 id owned by Production, `[ecology, 1800-2400]` is a 1800–2400 Ecology id, `[1200-1800]` is a same-line 1200–1800 id. `contact_required` marks items that need ocean contact, directly or through a contact-gated hard parent. Chains are modern (AD 1800–2030). No year moves are proposed for this line.

**100 entries, 155 hard edges, 177 precedent edges, 0 requires_any groups.**

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 2403 | `panorama_rotundas` | `single_point_perspective_painting` [1800-2400] |  | `perspective_scenery_stage` [1800-2400], `landscape_park_gardens` [1800-2400] |  |
| 2419 | `reading_circles` | `subscription_libraries` [knowledge, 1800-2400], `periodical_essay_sheets` [1800-2400] |  | `coffeehouse_public_talk` [1800-2400], `salon_conversation` [1800-2400] |  |
| 2429 | `gymnastics_grounds` | `natural_education_treatise` [1800-2400] |  | `national_civic_festivals` [1800-2400] |  |
| 2437 | `historical_novel` | `castaway_realist_novel` [1800-2400] |  | `ruined_castle_terror_tales` [1800-2400], `folk_song_collections` [1800-2400], `realm_history_plays` [1800-2400] |  |
| 2440 | `civic_concert_halls` | `subscription_concerts` [1800-2400] |  | `four_movement_symphony` [1800-2400], `public_opera_house` [1800-2400] |  |
| 2440 | `home_art_songs` | `hammer_keyboard` [1800-2400] |  | `folk_song_collections` [1800-2400], `plain_speech_nature_poetry` [1800-2400] |  |
| 2443 | `comparative_philology` | `standard_tongue_dictionary` [knowledge, 1800-2400], `written_grammar` [knowledge, 600-1200] |  | `folk_song_collections` [1800-2400], `philological_forgery_critique` [knowledge, 1800-2400], `research_university` [knowledge] |  |
| 2469 | `temperance_societies` | `spirit_licensing_duties` [nutrition, 1800-2400] |  | `inward_devotion_movement` [1800-2400], `friendly_society_boxes` [labor, 1800-2400] |  |
| 2480 | `grand_opera_houses` | `public_opera_house` [1800-2400] |  | `gas_lit_streets` [infrastructure], `civic_concert_halls` |  |
| 2480 | `national_tongue_revival` | `comparative_philology` |  | `folk_song_collections` [1800-2400], `tongue_purity_academy` [1800-2400], `national_flag_anthem` [1800-2400] |  |
| 2483 | `god_revival_meetings` | `inward_devotion_movement` [1800-2400] |  | `wandering_preacher_orders` [1200-1800], `rite_toleration_edict` [institutions, 1800-2400] |  |
| 2488 | `penny_daily_press` | `daily_printed_newspaper` [knowledge, 1800-2400], `cylinder_press_printing` [knowledge] |  | `continuous_paper_machine` [production], `reading_circles`, `press_freedom_statute` [institutions, 1800-2400] |  |
| 2496 | `serialized_novels` | `penny_daily_press` |  | `historical_novel` |  |
| 2504 | `portrait_photo_studios` | `fixed_light_images` [knowledge] |  | `burgher_portraiture` [1800-2400] |  |
| 2509 | `political_cartoon_weeklies` | `penny_daily_press`, `stone_lithography` [knowledge, 1800-2400] |  | `satirical_print_series` [1800-2400] |  |
| 2515 | `family_winter_feast` | `prepaid_stamp_postage` [logistics] |  | `calendar_feast_days` [0-600], `guild_patron_feasts` [1200-1800], `stone_lithography` [knowledge, 1800-2400] |  |
| 2520 | `realist_novel` | `historical_novel`, `serialized_novels` |  | `castaway_realist_novel` [1800-2400] |  |
| 2528 | `common_ownership_doctrine` | `division_of_labor_doctrine` [labor, 1800-2400] |  | `machine_breaking_riots` [labor, 1800-2400], `ideal_commonwealth_fiction` [1800-2400], `social_contract_doctrine` [institutions, 1800-2400], `strike_funds` [labor, 1800-2400] |  |
| 2528 | `national_unity_movements` | `national_tongue_revival` |  | `national_flag_anthem` [1800-2400], `national_civic_festivals` [1800-2400], `penny_daily_press` |  |
| 2528 | `womens_rights_convention` | `womens_rights_treatise` [1800-2400] |  | `temperance_societies`, `bound_labor_abolition_movement` [labor, 1800-2400] |  |
| 2533 | `sacred_text_criticism` | `philological_forgery_critique` [knowledge, 1800-2400], `comparative_philology` |  | `deep_time_geology` [ecology, 1800-2400] |  |
| 2536 | `great_realms_exhibition` | `prefabricated_iron_glass_halls` [infrastructure] |  | `annual_art_exhibition` [1800-2400], `public_steam_railway` [logistics], `great_realm_conference` [institutions] |  |
| 2547 | `excursion_tourism` | `public_steam_railway` [logistics], `intercity_passenger_railway` [logistics] |  | `grand_tour_travel` [1800-2400], `spa_town_physicians` [health, 1800-2400] |  |
| 2547 | `war_photography` | `fixed_light_images` [knowledge] |  | `portrait_photo_studios`, `penny_daily_press` |  |
| 2552 | `mountain_climbing_clubs` | `excursion_tourism` |  | `plain_speech_nature_poetry` [1800-2400], `landscape_park_gardens` [1800-2400] |  |
| 2568 | `codified_ball_games` | `bat_ball_wager_matches` [1800-2400] |  | `gymnastics_grounds`, `saturday_half_holiday` [labor], `public_steam_railway` [logistics] |  |
| 2573 | `childrens_books` | `fairy_tale_collections` [1800-2400], `cylinder_press_printing` [knowledge] |  | `printed_alphabet_primers` [knowledge, 1800-2400], `natural_education_treatise` [1800-2400] |  |
| 2587 | `national_history_lessons` | `compulsory_elementary_schooling` [knowledge], `national_unity_movements` |  | `historical_novel` |  |
| 2589 | `layered_excavation` | `buried_town_excavation` [1800-2400], `relative_stratigraphy` [ecology, 1800-2400] |  | `deep_time_geology` [ecology, 1800-2400] |  |
| 2597 | `open_air_light_painting` | `annual_art_exhibition` [1800-2400], `oil_glaze_painting` [1800-2400] |  | `fixed_light_images` [knowledge], `coal_tar_dyes` [production], `public_steam_railway` [logistics] |  |
| 2600 | `variety_music_halls` | `gas_lit_streets` [infrastructure], `public_playhouses` [1800-2400] |  | `servants_comic_opera` [1800-2400], `ballad_opera_satire` [1800-2400] |  |
| 2605 | `recorded_sound` | `acoustic_diaphragms` [knowledge] |  | `harmonic_analysis` [knowledge], `rolled_tinplate` [production, 1800-2400] |  |
| 2613 | `brand_advertising` | `penny_daily_press` |  | `limited_liability_registration` [institutions], `mail_order_parcel_trade` [logistics] |  |
| 2619 | `monument_protection_law` | `layered_excavation`, `realm_public_museum` [1800-2400] |  | `national_history_lessons` |  |
| 2621 | `endowed_town_libraries` | `public_libraries` [600-1200], `subscription_libraries` [knowledge, 1800-2400] |  | `compulsory_elementary_schooling` [knowledge], `reading_circles` |  |
| 2627 | `professional_sport_leagues` | `codified_ball_games` |  | `saturday_half_holiday` [labor], `intercity_passenger_railway` [logistics], `penny_daily_press` |  |
| 2632 | `constructed_common_language` | `comparative_philology` |  | `interrealm_postal_union` [logistics], `great_realms_exhibition` |  |
| 2635 | `handcraft_revival` | `iron_power_loom_sheds` [production] |  | `handloom_weaver_distress` [labor], `realist_novel` |  |
| 2637 | `workers_festival_day` | `eight_hour_campaign` [labor], `common_ownership_doctrine` |  | `national_civic_festivals` [1800-2400] |  |
| 2640 | `mystery_fiction` | `serialized_novels` |  | `detective_branch` [security], `ruined_castle_terror_tales` [1800-2400] |  |
| 2643 | `open_air_folk_museum` | `realm_public_museum` [1800-2400], `folk_song_collections` [1800-2400] |  | `handcraft_revival`, `national_unity_movements` |  |
| 2653 | `moving_pictures` | `fixed_light_images` [knowledge], `celluloid_moulding` [production] |  | `panorama_rotundas`, `electric_street_lighting` [infrastructure] |  |
| 2656 | `revived_realm_games` | `codified_ball_games`, `gymnastics_grounds` |  | `great_realms_exhibition`, `layered_excavation` |  |
| 2664 | `peace_congresses` | `interrealm_arbitration` [institutions] |  | `neutral_wounded_convention` [health], `womens_rights_convention` |  |
| 2667 | `million_reader_dailies` | `penny_daily_press`, `wood_pulp_paper` [production] |  | `compulsory_elementary_schooling` [knowledge], `brand_advertising`, `electrical_telegraphy` [knowledge] |  |
| 2669 | `great_merit_prizes` | `research_university` [knowledge], `refereed_journals` [knowledge] |  | `civil_merit_order` [institutions], `stable_blasting_explosive` [security] |  |
| 2680 | `abstract_painting` | `open_air_light_painting` |  | `fixed_light_images` [knowledge] |  |
| 2688 | `youth_scouting` | `gymnastics_grounds` |  | `mountain_climbing_clubs` |  |
| 2693 | `syncopated_dance_music` | `variety_music_halls` |  | `recorded_sound`, `chattel_bondage_abolition` [labor], `hammer_keyboard` [1800-2400] |  |
| 2701 | `newspaper_puzzles` | `million_reader_dailies` |  |  |  |
| 2704 | `war_newsreels_posters` | `moving_pictures`, `million_reader_dailies` |  | `war_photography`, `brand_advertising` |  |
| 2707 | `ethnographic_fieldwork` | `comparative_philology`, `research_university` [knowledge] |  | `far_land_specimen_voyages` [ecology, 1800-2400], `fixed_light_images` [knowledge], `recorded_sound` |  |
| 2720 | `radio_broadcasting` | `amplitude_modulation` [knowledge], `tuned_radio_reception` [knowledge] |  | `recorded_sound`, `million_reader_dailies` |  |
| 2720 | `unknown_warrior_remembrance` | `national_unity_movements` |  | `war_newsreels_posters`, `national_civic_festivals` [1800-2400] |  |
| 2725 | `inner_voice_novel` | `realist_novel` |  | `talking_cure` [health] |  |
| 2725 | `public_broadcasting_charter` | `radio_broadcasting` |  | `press_freedom_statute` [institutions, 1800-2400], `rate_regulation_commissions` [institutions] |  |
| 2731 | `film_studio_system` | `moving_pictures` |  | `limited_liability_registration` [institutions], `brand_advertising` |  |
| 2739 | `sound_films` | `moving_pictures`, `recorded_sound`, `triode_valves` [knowledge] |  | `radio_broadcasting` |  |
| 2747 | `world_ball_cup` | `codified_ball_games`, `professional_sport_leagues` |  | `revived_realm_games`, `radio_broadcasting` |  |
| 2755 | `leader_mass_rallies` | `one_party_state` [institutions], `radio_broadcasting` |  | `national_civic_festivals` [1800-2400], `war_newsreels_posters` |  |
| 2760 | `mass_paperbacks` | `cylinder_press_printing` [knowledge], `wood_pulp_paper` [production] |  | `million_reader_dailies`, `endowed_town_libraries` |  |
| 2760 | `picture_story_magazines` | `million_reader_dailies` |  | `newspaper_puzzles`, `political_cartoon_weeklies` |  |
| 2763 | `photo_news_magazines` | `war_photography`, `million_reader_dailies` |  | `picture_story_magazines` |  |
| 2763 | `television_broadcasting` | `radio_broadcasting`, `thermionic_emission` [knowledge], `photoconductivity` [knowledge] |  | `moving_pictures`, `sound_films` |  |
| 2765 | `animated_features` | `sound_films`, `film_studio_system` |  | `political_cartoon_weeklies` |  |
| 2795 | `long_play_records` | `recorded_sound`, `thermoplastic_processing` [production] |  | `radio_broadcasting` |  |
| 2800 | `broadcast_rites` | `radio_broadcasting`, `god_revival_meetings` |  | `television_broadcasting` |  |
| 2808 | `televised_state_rites` | `television_broadcasting` |  | `unknown_warrior_remembrance`, `ceremonial_crown` [institutions] |  |
| 2812 | `electric_youth_music` | `syncopated_dance_music`, `triode_valves` [knowledge] |  | `long_play_records`, `radio_broadcasting` |  |
| 2812 | `mass_television_age` | `television_broadcasting` |  | `rural_electrification` [infrastructure], `transistor_amplifiers` [production] |  |
| 2825 | `charter_flight_holidays` | `excursion_tourism`, `pressurized_airliner_cabins` [logistics] |  | `jet_airliners` [logistics], `paid_annual_holidays` [labor] |  |
| 2825 | `mass_image_art` | `abstract_painting` |  | `brand_advertising`, `photo_news_magazines`, `mass_television_age` |  |
| 2825 | `televised_debates` | `mass_television_age` |  | `mass_political_parties` [institutions] |  |
| 2832 | `nonviolent_rights_movements` | `universal_rights_declaration` [institutions] |  | `chattel_bondage_abolition` [labor], `mass_television_age`, `peace_congresses` |  |
| 2842 | `worldwide_live_broadcast` | `relay_satellites` [knowledge], `mass_television_age` |  |  |  |
| 2845 | `youth_counterculture` | `electric_youth_music`, `mass_higher_education` [knowledge] |  | `nonviolent_rights_movements`, `oral_contraceptive_pill` [demography] |  |
| 2850 | `womens_liberation_movement` | `womens_rights_convention`, `womens_suffrage` [institutions] |  | `oral_contraceptive_pill` [demography], `youth_counterculture`, `equal_pay_law` [labor] |  |
| 2852 | `many_cultures_policy` | `civil_rights_law` [institutions] |  | `guest_worker_programmes` [demography], `dependency_self_rule` [institutions] |  |
| 2855 | `electronic_games` | `integrated_circuits` [production], `mass_television_age` |  |  |  |
| 2855 | `world_heritage_list` | `monument_protection_law`, `world_assembly_of_realms` [institutions] |  | `layered_excavation` |  |
| 2865 | `home_video_recording` | `mass_television_age` |  | `long_play_records`, `transistor_amplifiers` [production] |  |
| 2872 | `portable_music_players` | `transistor_amplifiers` [production] |  | `long_play_records`, `electric_youth_music` |  |
| 2872 | `spoken_rhythm_music` | `electric_youth_music` |  | `long_play_records` |  |
| 2875 | `continuous_news_channels` | `mass_television_age`, `relay_satellites` [knowledge] |  | `worldwide_live_broadcast` |  |
| 2880 | `digital_music_discs` | `pulse_code_modulation` [knowledge], `long_play_records` |  | `single_chip_processors` [production] |  |
| 2888 | `benefit_broadcast_concerts` | `worldwide_live_broadcast`, `electric_youth_music` |  | `peace_congresses` |  |
| 2912 | `online_forums` | `world_hypertext_web` [knowledge] |  | `store_forward_archives` [knowledge] |  |
| 2922 | `file_sharing_networks` | `internetworking_protocols` [knowledge], `digital_music_discs` |  | `online_forums` |  |
| 2935 | `online_social_networks` | `world_hypertext_web` [knowledge], `online_forums` |  | `ranked_search_indexes` [knowledge] |  |
| 2938 | `user_video_sharing` | `world_hypertext_web` [knowledge], `home_video_recording` |  | `online_social_networks`, `file_sharing_networks` |  |
| 2945 | `streaming_media` | `cloud_data_halls` [knowledge], `digital_music_discs` |  | `user_video_sharing` |  |
| 2952 | `networked_protest_movements` | `online_social_networks`, `pocket_networked_computers` [knowledge] |  | `nonviolent_rights_movements` |  |
| 2955 | `algorithmic_feeds` | `online_social_networks`, `ranked_search_indexes` [knowledge] |  | `deep_learning_networks` [knowledge] |  |
| 2965 | `networked_disinformation` | `algorithmic_feeds` |  | `state_propaganda_ministry` [institutions] |  |
| 2965 | `short_viral_video` | `user_video_sharing`, `pocket_networked_computers` [knowledge] |  | `algorithmic_feeds` |  |
| 2970 | `online_influencers` | `user_video_sharing`, `streaming_media` |  | `brand_advertising`, `short_viral_video` |  |
| 2975 | `remote_video_gatherings` | `cloud_data_halls` [knowledge], `streaming_media` |  | `networked_telework` [labor], `broadcast_rites` |  |
| 2982 | `generated_media` | `deep_learning_networks` [knowledge] |  | `large_language_models` [knowledge] |  |
| 2995 | `media_provenance_marks` | `generated_media`, `public_key_ciphers` [knowledge] |  | `networked_disinformation` |  |
| 3000 | `shared_virtual_venues` | `streaming_media`, `electronic_games` |  | `remote_video_gatherings` |  |

## Cross-line prerequisites assumed from other 2400–3000 lines

Hard parents owned by lines outside knowledge, institutions, culture and labor, mapped in parallel by other agents:

- `gas_lit_streets` (infrastructure 2422) → `variety_music_halls`
- `iron_power_loom_sheds` (production 2440) → `handcraft_revival`
- `public_steam_railway` (logistics 2467) → `excursion_tourism`
- `intercity_passenger_railway` (logistics 2480) → `excursion_tourism`
- `prepaid_stamp_postage` (logistics 2507) → `family_winter_feast`
- `prefabricated_iron_glass_halls` (infrastructure 2533) → `great_realms_exhibition`
- `wood_pulp_paper` (production 2565) → `mass_paperbacks`
- `wood_pulp_paper` (production 2565) → `million_reader_dailies`
- `celluloid_moulding` (production 2587) → `moving_pictures`
- `thermoplastic_processing` (production 2759) → `long_play_records`
- `pressurized_airliner_cabins` (logistics 2773) → `charter_flight_holidays`
- `transistor_amplifiers` (production 2807) → `portable_music_players`
- `integrated_circuits` (production 2825) → `electronic_games`

## Prerequisites from the other kicl lines

- `research_university` (knowledge 2427) → `ethnographic_fieldwork`
- `research_university` (knowledge 2427) → `great_merit_prizes`
- `cylinder_press_printing` (knowledge 2437) → `childrens_books`
- `cylinder_press_printing` (knowledge 2437) → `mass_paperbacks`
- `cylinder_press_printing` (knowledge 2437) → `penny_daily_press`
- `fixed_light_images` (knowledge 2504) → `moving_pictures`
- `fixed_light_images` (knowledge 2504) → `portrait_photo_studios`
- `fixed_light_images` (knowledge 2504) → `war_photography`
- `compulsory_elementary_schooling` (knowledge 2587) → `national_history_lessons`
- `interrealm_arbitration` (institutions 2592) → `peace_congresses`
- `photoconductivity` (knowledge 2595) → `television_broadcasting`
- `acoustic_diaphragms` (knowledge 2603) → `recorded_sound`
- `eight_hour_campaign` (labor 2634) → `workers_festival_day`
- `womens_suffrage` (institutions 2648) → `womens_liberation_movement`
- `thermionic_emission` (knowledge 2659) → `television_broadcasting`
- `refereed_journals` (knowledge 2667) → `great_merit_prizes`
- `triode_valves` (knowledge 2683) → `electric_youth_music`
- `triode_valves` (knowledge 2683) → `sound_films`
- `tuned_radio_reception` (knowledge 2688) → `radio_broadcasting`
- `amplitude_modulation` (knowledge 2699) → `radio_broadcasting`
- `one_party_state` (institutions 2712) → `leader_mass_rallies`
- `world_assembly_of_realms` (institutions 2787) → `world_heritage_list`
- `universal_rights_declaration` (institutions 2795) → `nonviolent_rights_movements`
- `pulse_code_modulation` (knowledge 2812) → `digital_music_discs`
- `relay_satellites` (knowledge 2830) → `continuous_news_channels`
- `relay_satellites` (knowledge 2830) → `worldwide_live_broadcast`
- `mass_higher_education` (knowledge 2832) → `youth_counterculture`
- `civil_rights_law` (institutions 2835) → `many_cultures_policy`
- `public_key_ciphers` (knowledge 2865) → `media_provenance_marks`
- `internetworking_protocols` (knowledge 2882) → `file_sharing_networks`
- `world_hypertext_web` (knowledge 2902) → `online_forums`
- `world_hypertext_web` (knowledge 2902) → `online_social_networks`
- `world_hypertext_web` (knowledge 2902) → `user_video_sharing`
- `ranked_search_indexes` (knowledge 2920) → `algorithmic_feeds`
- `cloud_data_halls` (knowledge 2940) → `remote_video_gatherings`
- `cloud_data_halls` (knowledge 2940) → `streaming_media`
- `pocket_networked_computers` (knowledge 2942) → `networked_protest_movements`
- `pocket_networked_computers` (knowledge 2942) → `short_viral_video`
- `deep_learning_networks` (knowledge 2955) → `generated_media`

## Year adjustments

None.
