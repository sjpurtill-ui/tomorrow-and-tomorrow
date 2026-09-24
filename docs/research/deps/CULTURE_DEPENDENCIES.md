# Culture dependencies

Machine-readable source: `culture.json`. Contract: `MAPPING_CONTRACT.md`. Any-sets are separated by ` / ` within brackets.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 1 | `shared_hearth_gatherings` |  |  | `ember_tending` |  |
| 2 | `communal_work_songs` |  |  |  |  |
| 3 | `oral_epics` |  |  | `shared_hearth_gatherings` |  |
| 4 | `genealogical_recitation` |  |  | `oral_epics` |  |
| 5 | `named_landmark_lore` |  |  | `route_memory` |  |
| 6 | `curious_questioning_custom` | `shared_hearth_gatherings` |  |  |  |
| 7 | `bone_flutes_drums` | `shared_hearth_gatherings`, `controlled_flaking` |  |  |  |
| 8 | `circle_dances` | `shared_hearth_gatherings` |  | `communal_work_songs`, `bone_flutes_drums` |  |
| 9 | `house_floor_burial` | `genealogical_recitation` | [`adobe_wall_construction` / `framed_construction`] |  |  |
| 10 | `ochre_grave_goods` | `house_floor_burial` |  |  |  |
| 12 | `kin_body_ornament` | `named_descent_lines` | [`mineral_pigment_preparation` / `bone_needle_sewing` / `cordage`] |  |  |
| 14 | `hearth_shrine_offerings` | `shared_hearth_gatherings` |  | `house_floor_burial`, `oral_epics` |  |
| 16 | `plastered_ancestor_skulls` | `house_floor_burial`, `clay_shaping` |  |  |  |
| 18 | `mourning_days` |  | [`house_floor_burial` / `ochre_grave_goods`] | `genealogical_recitation` |  |
| 20 | `festival_calendar` | `seasonal_patterns` | [`moon_counting` / `phenology_signs`] | `crop_calendars` |  |
| 25 | `reciprocal_gift_exchange` | `guest_host_reciprocity` |  | `trade_partner_tokens`, `shared_hearth_gatherings` |  |
| 28 | `origin_story` | `oral_epics`, `hearth_shrine_offerings` |  | `named_landmark_lore` |  |
| 30 | `pottery_style_identity` | `pit_firing`, `kin_body_ornament` |  |  |  |
| 32 | `ancestor_figurines` | `clay_shaping` | [`plastered_ancestor_skulls` / `house_floor_burial`] | `pit_firing` |  |
| 35 | `pit_pebble_game` | `counting_words` |  | `shared_hearth_gatherings` |  |
| 38 | `first_fruits_offering` | `hearth_shrine_offerings`, `seed_selection` |  | `festival_calendar` |  |
| 40 | `winter_tale_nights` | `oral_epics`, `festival_calendar` |  |  |  |
| 45 | `named_star_figures` | `oral_epics` |  | `moon_counting`, `weather_sign_reading` |  |
| 50 | `shrine_wall_painting` | `mineral_pigment_preparation`, `hearth_shrine_offerings` | [`adobe_wall_construction` / `wattle_and_daub_walls`] | `lime_burning` |  |
| 55 | `ritual_masks_costumes` | `circle_dances`, `hearth_shrine_offerings` |  | `kin_body_ornament`, `hide_smoke_curing` |  |
| 60 | `sacred_places` | `named_landmark_lore`, `hearth_shrine_offerings` |  | `origin_story` |  |
| 65 | `coming_of_age_rites` | `kin_body_ornament`, `festival_calendar` |  | `circle_dances` |  |
| 75 | `cooperative_harvest_gatherings` | `crop_calendars` |  | `work_party_feasts`, `communal_work_songs` |  |
| 80 | `household_lineage_tokens` | `genealogical_recitation`, `owner_marks` |  | `clay_counting_tokens` |  |
| 85 | `cross_craft_visiting` | `part_time_specialists` |  | `reciprocal_gift_exchange`, `guest_host_reciprocity` |  |
| 90 | `memorial_cairn_marking` | `cairn_sightline_marking` |  | `named_landmark_lore` |  |
| 95 | `marriage_feasts` | `village_marriage_alliances`, `reciprocal_gift_exchange` |  | `bride_wealth_gifts` |  |
| 100 | `mutual_aid_customs` | `reciprocal_gift_exchange` |  | `kin_care_widows_orphans`, `work_party_feasts` |  |
| 110 | `first_shrine_house` | `sacred_places` | [`central_hall_houses` / `adobe_wall_construction` / `mould_made_mudbricks`] | `petition_speakers`, `leader_feast_obligations` |  |
| 115 | `praise_songs` | `first_shrine_house` |  | `communal_work_songs`, `oral_epics` |  |
| 120 | `rattles_drums_pipes` | `bone_flutes_drums`, `pit_firing` |  |  |  |
| 130 | `traveling_storyteller_exchange` | `oral_epics`, `guest_host_reciprocity` |  |  | min_settlements=2 |
| 135 | `graveside_libations` | `mourning_days` |  | `ancestor_figurines` |  |
| 145 | `disaster_memory_markers` | `memorial_cairn_marking`, `flood_mark_reading` |  |  |  |
| 150 | `grief_support_customs` | `mourning_days`, `mutual_aid_customs` |  |  |  |
| 152 | `puzzle_riddle_contests` | `childrens_question_circles` |  | `pit_pebble_game`, `festival_wrestling_races` |  |
| 155 | `festival_wrestling_races` | `festival_calendar` |  | `sparring_customs` |  |
| 160 | `emblem_processions` | `first_shrine_house`, `festival_calendar` |  | `first_fruits_offering` |  |
| 180 | `proverbs` | `mnemonic_verse_encoding` |  | `repeated_recitation_training` |  |
| 190 | `temple_festival_meals` | `temple_common_storehouse`, `festival_calendar` |  | `leader_feast_obligations` |  |
| 200 | `flood_origin_stories` | `origin_story`, `disaster_memory_markers` |  |  | environment=river |
| 210 | `rank_inlay_ornament` | `hereditary_chiefly_rank`, `kin_body_ornament` |  | `bitumen_sealing`, `bow_drill_drive` |  |
| 225 | `naming_day_rites` | `genealogical_recitation` |  | `coming_of_age_rites`, `hearth_shrine_offerings` |  |
| 240 | `seasonal_commemoration_rites` | `disaster_memory_markers`, `solar_year_reckoning` |  |  |  |
| 250 | `public_debate_custom` | `free_adult_assembly` |  | `problem_council_sessions`, `childrens_question_circles` |  |
| 255 | `rank_dress_styles` | `hereditary_chiefly_rank` | [`plain_weaving` / `bone_needle_sewing`] | `rank_inlay_ornament` |  |
| 262 | `craft_lineage_naming` | `full_time_specialists`, `genealogical_recitation` |  |  |  |
| 265 | `intermarriage_visiting_customs` | `village_marriage_alliances`, `guest_host_reciprocity` |  |  | min_settlements=2 |
| 268 | `visiting_specialist_consultations` | `standing_arbiter_appointment`, `guest_host_reciprocity` |  | `traveling_storyteller_exchange` |  |
| 275 | `stone_relief_carving` | `shrine_wall_painting` | [`copper_casting` / `ground_stone_axes`] | `stamp_seals` |  |
| 280 | `banded_procession_vessels` | `emblem_processions` | [`tube_drilled_stone_vessels` / `painted_pottery`] | `stone_relief_carving` |  |
| 285 | `temple_singers_lamenters` | `praise_songs`, `temple_high_steward` |  | `mourning_days` |  |
| 290 | `guest_friendship` | `guest_host_reciprocity`, `reciprocal_gift_exchange` |  | `trade_colonies` | min_settlements=2 |
| 300 | `founder_story_recitation` | `origin_story`, `solar_year_reckoning` |  | `genealogical_recitation` |  |
| 310 | `board_race_games` | `pit_pebble_game` |  | `festival_wrestling_races` |  |
| 320 | `new_year_festival` | `festival_calendar`, `solar_year_reckoning`, `temple_high_steward` |  | `founder_story_recitation`, `emblem_processions` |  |
| 330 | `town_identity` | `emblem_processions`, `town_enclosure_walls` |  | `new_year_festival` | min_settlements=2 |
| 350 | `theophoric_names` | `naming_day_rites` |  | `temple_singers_lamenters`, `praise_songs` |  |
| 360 | `shared_meal_obligations` | `temple_festival_meals`, `mutual_aid_customs` |  |  |  |
| 365 | `votive_figures` | `ancestor_figurines`, `first_shrine_house` | [`stone_relief_carving` / `copper_casting`] |  |  |
| 375 | `seasonal_hymn_cycles` | `praise_songs`, `solar_year_reckoning` |  | `temple_singers_lamenters`, `new_year_festival` |  |
| 380 | `harps_and_lyres` | `rattles_drums_pipes`, `joinery` |  | `temple_singers_lamenters`, `cordage` |  |
| 385 | `chamber_tombs` | `hereditary_chiefly_rank` | [`corbelled_vaults` / `dressed_stone_masonry` / `mould_made_mudbricks`] | `ochre_grave_goods`, `graveside_libations` |  |
| 395 | `temple_choirs` | `temple_singers_lamenters`, `rattles_drums_pipes` |  | `harps_and_lyres`, `bronze_alloying` |  |
| 400 | `comparative_craft_gatherings` | `cross_craft_visiting`, `full_time_specialists` | [`seasonal_trade_gathering` / `market_timing_knowledge`] |  |  |
| 403 | `inlaid_mosaic_panels` | `rank_inlay_ornament`, `bitumen_sealing` |  | `banded_procession_vessels` |  |
| 405 | `wisdom_instructions` | `proverbs` | [`written_lore_tablets` / `mnemonic_verse_encoding`] |  |  |
| 420 | `festival_dancers_acrobats` | `festival_wrestling_races`, `new_year_festival` |  | `circle_dances` |  |
| 430 | `officiant_vestments` | `ritual_masks_costumes`, `plain_weaving` |  | `ceremonial_investiture`, `temple_high_steward` |  |
| 440 | `envoy_reception` | `guest_friendship`, `kingship` |  |  | contact_required=yes |
| 445 | `calendar_feast_days` | `temple_festival_meals` | [`intercalated_calendar` / `star_rising_civil_year`] |  |  |
| 450 | `royal_mourning` | `kingship`, `mourning_days` |  | `temple_singers_lamenters` |  |
| 455 | `royal_stone_portraits` | `stone_relief_carving`, `kingship` | [`copper_carpentry_tools` / `dressed_stone_masonry`] |  |  |
| 460 | `royal_wrestling_matches` | `festival_wrestling_races`, `kingship` |  |  |  |
| 470 | `dream_interpretation` | `temple_high_steward` |  | `written_lore_tablets`, `proverbs` |  |
| 480 | `debate_poems` | `public_debate_custom`, `written_lore_tablets` |  |  |  |
| 490 | `heroic_song_cycle` | `oral_epics`, `kingship`, `written_lore_tablets` |  | `harps_and_lyres` |  |
| 500 | `royal_ancestor_offerings` | `dynastic_succession`, `graveside_libations` |  | `royal_mourning`, `moon_counting` |  |
| 505 | `love_wedding_songs` | `marriage_feasts` |  | `harps_and_lyres`, `written_lore_tablets` |  |
| 510 | `city_laments` | `temple_singers_lamenters`, `written_lore_tablets` |  | `town_identity`, `scaling_ladders_rams` |  |
| 520 | `offering_omens` | `temple_high_steward`, `written_lore_tablets` |  | `dream_interpretation`, `harvest_offering_shares` |  |
| 530 | `god_boat_procession` | `emblem_processions` | [`river_craft` / `hide_covered_boats` / `plank_extended_dugouts`] |  | environment=river |
| 540 | `letters_to_the_god` | `sealed_tablet_letters` |  | `petition_speakers` |  |
| 545 | `palace_wall_painting` | `shrine_wall_painting`, `kingship` | [`lime_plastered_floors` / `gypsum_mortar`] |  |  |
| 555 | `scribal_songs_satires` | `public_schools`, `scribal_copying_tests` |  | `debate_poems` |  |
| 560 | `pilgrimage` | `new_year_festival` | [`road_stations` / `guest_friendship` / `donkey_caravans`] | `stepped_temple_towers`, `sacred_places` | min_settlements=4 |
| 570 | `foreign_fashion_adoption` | `rank_dress_styles` | [`envoy_reception` / `merchant_quarters_abroad` / `trade_colonies`] |  | contact_required=yes |
| 580 | `sung_divine_narrative` | `seasonal_hymn_cycles`, `heroic_song_cycle` |  | `harps_and_lyres` |  |
| 590 | `feast_of_the_dead` | `graveside_libations`, `calendar_feast_days` |  | `royal_ancestor_offerings` |  |
| 600 | `festival_bread_sharing` | `calendar_feast_days`, `work_gang_bakeries` |  | `temple_festival_meals`, `named_breads` |  |
