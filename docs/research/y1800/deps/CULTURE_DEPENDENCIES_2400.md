# Culture dependencies: years 1800–2400

Machine-readable source: `partials/kicl.json` (knowledge, institutions, culture, labor). Contract: the 600–1200 and 1200–1800 mappings (`docs/research/y600/deps/partials/kicl.json`, `docs/research/y1200/deps/partials/kicl.json`, merged by `tools/research/merge_graph_1200.py` and `merge_graph_1800.py`). Ids come from `registry_2400.json`, the 1200–1800 graph (`docs/research/y1200/deps/graph_1800.json`), the 600–1200 graph, the 0–600 graph and the game's baked blocks. Prerequisites may be ids of any earlier block in any line, or 1800–2400 ids, and every prerequisite and precedent is dated at or before its dependent (registry target years; earlier blocks at their baked years). Brackets mark a parent from another line or an earlier block: `[production]` is a 1800–2400 id owned by Production, `[ecology, 1200-1800]` is a 1200–1800 Ecology id, `[0-600]` is a same-line 0–600 id. `contact_required` marks items that need ocean contact, directly or through a contact-gated hard parent. No year moves are proposed for this line.

**98 entries, 162 hard edges, 171 precedent edges, 0 requires_any groups.** Contact-gated: `tea_hut_ceremony`, `voyage_national_epic`, `coffeehouse_public_talk`.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 1808 | `civic_humanism` | `court_learning_revival` [1200-1800], `old_text_recovery` [1200-1800] |  | `elected_town_consuls` [institutions, 1200-1800], `letter_writing_art` [knowledge, 1200-1800] |  |
| 1809 | `masked_spirit_drama` | `pantomime_dance_theatre` [600-1200] |  | `liturgical_drama` [1200-1800], `shadow_puppet_theatre` [1200-1800], `pleasure_quarter_storytellers` [1200-1800] |  |
| 1822 | `pilgrim_tale_cycle` | `townsfolk_tale_collections` [1200-1800], `frame_story_collections` [1200-1800] |  | `pilgrim_road_badges` [1200-1800], `vernacular_learned_writing` [knowledge, 1200-1800] |  |
| 1825 | `courtesy_manners_books` | `knightly_conduct_code` [1200-1800] |  | `rank_sumptuary_laws` [institutions, 1200-1800], `mirror_for_rulers` [1200-1800] |  |
| 1838 | `defence_of_women_book` | `vernacular_learned_writing` [knowledge, 1200-1800] |  | `courtly_love_lyric` [1200-1800], `vernacular_allegory_epic` [1200-1800] |  |
| 1848 | `inward_devotion_movement` | `private_devotion_books` [1200-1800], `poor_devout_dissent` [1200-1800] |  | `devotee_communities_under_rule` [1200-1800] |  |
| 1850 | `town_rhetoric_chambers` | `court_poetry_contests` [1200-1800], `guild_cycle_plays` [1200-1800] |  | `revised_town_statute_books` [institutions, 1200-1800] |  |
| 1854 | `single_point_perspective_painting` | `mirror_grid_perspective` [knowledge], `naturalistic_fresco_cycles` [1200-1800] |  | `school_perspective_optics` [knowledge, 1200-1800] |  |
| 1860 | `oil_glaze_painting` | `oil_varnish_paints` [production, 1200-1800], `painted_panel_portraits` [600-1200] |  | `naturalistic_fresco_cycles` [1200-1800] |  |
| 1861 | `burgher_portraiture` | `oil_glaze_painting` |  | `painted_panel_portraits` [600-1200], `chartered_town_liberties` [institutions, 1200-1800] |  |
| 1867 | `freestanding_bronze_statuary` | `cast_bronze_doors` [production, 1200-1800], `lifesize_stone_statues` [600-1200] |  | `civic_humanism`, `portrait_likeness_sculpture` [600-1200] |  |
| 1879 | `court_dance_manuals` | `measured_rhythm_notation` [1200-1800] |  | `courtesy_manners_books`, `ruler_town_entries` [1200-1800] |  |
| 1885 | `revived_philosophy_academy` | `civic_humanism`, `old_text_recovery` [1200-1800] |  | `rival_tongue_translation_school` [knowledge, 1200-1800], `philosophy_school_communities` [600-1200] |  |
| 1892 | `printed_vernacular_romances` | `chivalric_romance` [1200-1800], `town_printing_houses` [knowledge] |  | `printed_broadsides` [knowledge] |  |
| 1900 | `tea_hut_ceremony` | `teahouse_tea` [nutrition, 1200-1800] |  | `contemplative_ascent_schools` [600-1200], `ink_wash_painting` [1200-1800] | contact_required=yes |
| 1905 | `dignity_of_person_oration` | `revived_philosophy_academy` |  | `civic_humanism` |  |
| 1912 | `soul_reckoning_morality_plays` | `guild_cycle_plays` [1200-1800] |  | `vernacular_allegory_epic` [1200-1800], `dance_of_death_images` [1200-1800] |  |
| 1916 | `dry_contemplation_gardens` | `leisure_gardens` [600-1200], `contemplative_ascent_schools` [600-1200] |  | `ink_wash_painting` [1200-1800], `monumental_landscape_painting` [1200-1800], `tea_hut_ceremony` |  |
| 1917 | `pedlar_chapbooks` | `printed_broadsides` [knowledge] |  | `printed_vernacular_romances`, `town_printing_houses` [knowledge] |  |
| 1918 | `printed_part_books` | `polyphonic_choirbooks` [1200-1800], `metal_type_casting` [knowledge] |  | `town_printing_houses` [knowledge], `measured_rhythm_notation` [1200-1800] |  |
| 1920 | `civic_marble_colossus` | `lifesize_stone_statues` [600-1200], `civic_humanism` |  | `colossal_city_statue` [600-1200], `freestanding_bronze_statuary` |  |
| 1923 | `painted_vault_cycle` | `naturalistic_fresco_cycles` [1200-1800], `single_point_perspective_painting` |  | `civic_marble_colossus` |  |
| 1925 | `trickster_jest_books` | `printed_broadsides` [knowledge] |  | `beast_epic_satire` [1200-1800], `pedlar_chapbooks` |  |
| 1926 | `praise_of_folly_satire` | `civic_humanism`, `town_printing_houses` [knowledge] |  | `beast_epic_satire` [1200-1800], `carnival_misrule` [1200-1800], `philological_forgery_critique` [knowledge] |  |
| 1930 | `ideal_commonwealth_fiction` | `civic_humanism`, `town_printing_houses` [knowledge] |  | `praise_of_folly_satire`, `transoceanic_contact_voyages` [logistics] |  |
| 1931 | `printed_reform_dispute` | `poor_devout_dissent` [1200-1800], `town_printing_houses` [knowledge] |  | `printed_broadsides` [knowledge], `philological_forgery_critique` [knowledge], `conciliar_supremacy` [institutions] |  |
| 1935 | `vernacular_scripture` | `printed_reform_dispute`, `printed_scripture_folio` [knowledge] |  | `vernacular_learned_writing` [knowledge, 1200-1800], `hard_word_glossaries` [knowledge, 1200-1800] |  |
| 1937 | `everyday_tongue_hymns` | `congregational_hymns` [600-1200], `printed_reform_dispute` |  | `devotional_songs_common_tongue` [1200-1800], `printed_part_books` |  |
| 1940 | `courtier_ideal_book` | `courtesy_manners_books`, `knightly_conduct_code` [1200-1800] |  | `civic_humanism`, `town_printing_houses` [knowledge] |  |
| 1942 | `emblem_books` | `town_printing_houses` [knowledge], `moralized_bestiaries` [1200-1800] |  | `heraldic_arms` [1200-1800], `civic_humanism` |  |
| 1954 | `masked_stock_comedy` | `carnival_misrule` [1200-1800] |  | `town_rhetoric_chambers`, `pantomime_dance_theatre` [600-1200] |  |
| 1958 | `artists_lives_history` | `paired_lives_biography` [600-1200], `town_printing_houses` [knowledge] |  | `painted_vault_cycle`, `civic_humanism` |  |
| 1967 | `sorcery_panics` | `orthodoxy_tribunal` [institutions], `town_printing_houses` [knowledge] |  | `inquisitorial_written_procedure` [institutions, 1200-1800], `printed_broadsides` [knowledge] |  |
| 1969 | `drawing_academy` | `revived_philosophy_academy`, `single_point_perspective_painting` |  | `artists_lives_history`, `craft_guilds` [institutions, 1200-1800] |  |
| 1971 | `peasant_genre_painting` | `oil_glaze_painting` |  | `burgher_portraiture` |  |
| 1977 | `voyage_national_epic` | `transoceanic_contact_voyages` [logistics], `book_of_kings_epic` [1200-1800] |  | `town_printing_houses` [knowledge] | contact_required=yes |
| 1980 | `public_playhouses` | `public_theatre` [600-1200], `soul_reckoning_morality_plays` |  | `masked_stock_comedy`, `town_rhetoric_chambers` |  |
| 1983 | `personal_essays` | `town_printing_houses` [knowledge], `civic_humanism` |  | `commonplace_books` [knowledge, 1200-1800], `confessional_autobiography` [1200-1800] |  |
| 1984 | `court_ballet_spectacle` | `court_dance_manuals` |  | `ruler_town_entries` [1200-1800], `masked_stock_comedy` |  |
| 1992 | `realm_history_plays` | `public_playhouses`, `book_of_kings_epic` [1200-1800] |  | `vernacular_town_chronicles` [1200-1800] |  |
| 2000 | `chiaroscuro_painting` | `oil_glaze_painting` |  | `painted_vault_cycle`, `single_point_perspective_painting` |  |
| 2000 | `sung_drama_opera` | `court_ballet_spectacle`, `measured_rhythm_notation` [1200-1800] |  | `revived_philosophy_academy`, `tragic_drama_contests` [600-1200] |  |
| 2004 | `figured_bass_monody` | `printed_part_books`, `measured_rhythm_notation` [1200-1800] |  | `sung_drama_opera` |  |
| 2006 | `riverbank_dance_theatre` | `masked_spirit_drama`, `pleasure_quarter_storytellers` [1200-1800] |  |  |  |
| 2010 | `comic_knight_novel` | `chivalric_romance` [1200-1800], `printed_vernacular_romances` |  | `trickster_jest_books` |  |
| 2020 | `salon_conversation` | `courtier_ideal_book` |  | `defence_of_women_book`, `court_ballet_spectacle` |  |
| 2040 | `burgher_still_life` | `oil_glaze_painting` |  | `peasant_genre_painting`, `burgher_portraiture` |  |
| 2070 | `tongue_purity_academy` | `revived_philosophy_academy`, `hard_word_glossaries` [knowledge, 1200-1800] |  | `salon_conversation`, `town_printing_houses` [knowledge] |  |
| 2072 | `three_unities_tragedy` | `public_playhouses`, `tragic_drama_contests` [600-1200] |  | `tongue_purity_academy` |  |
| 2074 | `public_opera_house` | `sung_drama_opera`, `public_playhouses` |  | `figured_bass_monody` |  |
| 2084 | `civic_group_portraits` | `burgher_portraiture`, `chiaroscuro_painting` |  | `trained_town_bands` [security], `guild_patron_feasts` [1200-1800] |  |
| 2096 | `royal_art_academy` | `drawing_academy` |  | `tongue_purity_academy` |  |
| 2100 | `coffeehouse_public_talk` | `coffee_houses` [nutrition], `printed_weekly_news` [knowledge] |  | `salon_conversation` | contact_required=yes |
| 2120 | `perspective_scenery_stage` | `public_playhouses`, `single_point_perspective_painting` |  | `court_ballet_spectacle`, `public_opera_house` |  |
| 2122 | `royal_dance_academy` | `court_ballet_spectacle`, `royal_art_academy` |  | `court_dance_manuals` |  |
| 2128 | `comedy_of_manners` | `public_playhouses`, `masked_stock_comedy` |  | `three_unities_tragedy`, `salon_conversation` |  |
| 2134 | `first_fall_epic` | `vernacular_allegory_epic` [1200-1800], `vernacular_scripture` |  | `town_printing_houses` [knowledge] |  |
| 2136 | `verse_fables` | `moralized_bestiaries` [1200-1800], `tongue_purity_academy` |  | `beast_epic_satire` [1200-1800], `emblem_books` |  |
| 2156 | `pilgrim_allegory_prose` | `vernacular_scripture`, `vernacular_allegory_epic` [1200-1800] |  | `pedlar_chapbooks`, `inward_devotion_movement` |  |
| 2166 | `public_collection_museum` | `chartered_experimental_society` [knowledge], `ruler_founded_universities` [knowledge] |  | `pressed_plant_herbaria` [ecology], `far_land_specimen_voyages` [ecology] |  |
| 2170 | `floating_world_prints` | `printing_process` [knowledge, 1200-1800], `pleasure_quarter_storytellers` [1200-1800] |  | `riverbank_dance_theatre`, `block_printed_books` [knowledge, 1200-1800] |  |
| 2174 | `ancients_moderns_quarrel` | `tongue_purity_academy` |  | `royal_art_academy`, `experimental_protocol_publication` [knowledge] |  |
| 2178 | `toleration_letter` | `rite_toleration_edict` [institutions] |  | `systematic_doubt_method` [knowledge], `test_oath_for_office` [institutions] |  |
| 2180 | `puppet_duty_dramas` | `shadow_puppet_theatre` [1200-1800], `riverbank_dance_theatre` |  | `floating_world_prints` |  |
| 2194 | `fairy_tale_collections` | `salon_conversation`, `town_printing_houses` [knowledge] |  | `frame_story_collections` [1200-1800], `verse_fables` |  |
| 2200 | `hammer_keyboard` | `great_pipe_organs` [1200-1800], `harps_and_lyres` [0-600] |  | `string_ratio_harmonics` [knowledge, 600-1200], `figured_bass_monody` |  |
| 2210 | `soloist_concertos` | `figured_bass_monody`, `public_opera_house` |  | `printed_part_books` |  |
| 2222 | `periodical_essay_sheets` | `daily_printed_newspaper` [knowledge], `personal_essays` |  | `coffeehouse_public_talk` |  |
| 2224 | `bat_ball_wager_matches` | `civic_games` [600-1200] |  | `coffeehouse_public_talk`, `daily_printed_newspaper` [knowledge] |  |
| 2234 | `fraternal_lodges` | `masons_lodge_rules` [labor, 1200-1800] |  | `coffeehouse_public_talk`, `chartered_experimental_society` [knowledge] |  |
| 2238 | `castaway_realist_novel` | `daily_printed_newspaper` [knowledge], `printed_vernacular_romances` |  | `personal_essays`, `periodical_essay_sheets` |  |
| 2240 | `grand_tour_travel` | `passenger_coach` [logistics], `travel_passports` [security] |  | `public_collection_museum`, `royal_art_academy` |  |
| 2244 | `equal_temperament_tuning` | `string_ratio_harmonics` [knowledge, 600-1200], `logarithms` [knowledge] |  | `hammer_keyboard`, `mechanical_oscillation` [knowledge] |  |
| 2256 | `ballad_opera_satire` | `public_opera_house`, `pedlar_chapbooks` |  | `comedy_of_manners`, `estates_parties` [institutions] |  |
| 2260 | `playful_shell_ornament` | `ornamental_plaster_ceilings` [infrastructure], `grand_palace_court` [institutions] |  | `scagliola_stucco` [infrastructure] |  |
| 2264 | `satirical_print_series` | `rolling_intaglio_printing` [knowledge], `periodical_essay_sheets` |  | `comedy_of_manners`, `emblem_books` |  |
| 2280 | `epistolary_novel` | `castaway_realist_novel`, `public_letter_post` [logistics] |  | `salon_conversation` |  |
| 2284 | `public_oratorio` | `public_opera_house`, `everyday_tongue_hymns` |  | `great_pipe_organs` [1200-1800] |  |
| 2290 | `landscape_park_gardens` | `axial_palace_gardens` [infrastructure] |  | `monumental_landscape_painting` [1200-1800], `grand_tour_travel`, `enclosure_by_agreement` [ecology] |  |
| 2296 | `buried_town_excavation` | `old_text_recovery` [1200-1800], `public_collection_museum` |  | `grand_tour_travel`, `relative_stratigraphy` [ecology] |  |
| 2306 | `realm_public_museum` | `public_collection_museum` |  | `biological_reference_collections` [ecology], `reasoned_trades_encyclopedia` [knowledge] |  |
| 2310 | `neoclassical_revival` | `buried_town_excavation`, `royal_art_academy` |  | `grand_tour_travel` |  |
| 2318 | `philosophical_satire_tale` | `periodical_essay_sheets` |  | `castaway_realist_novel`, `praise_of_folly_satire` |  |
| 2320 | `four_movement_symphony` | `soloist_concertos` |  | `public_oratorio`, `equal_temperament_tuning` |  |
| 2322 | `sentimental_novel` | `epistolary_novel` |  | `subscription_libraries` [knowledge] |  |
| 2324 | `natural_education_treatise` | `compulsory_parish_schooling` [knowledge] |  | `social_contract_doctrine` [institutions], `sentimental_novel` |  |
| 2328 | `ruined_castle_terror_tales` | `sentimental_novel` |  | `landscape_park_gardens`, `subscription_libraries` [knowledge] |  |
| 2330 | `subscription_concerts` | `soloist_concertos`, `public_oratorio` |  | `four_movement_symphony`, `subscription_libraries` [knowledge] |  |
| 2336 | `annual_art_exhibition` | `royal_art_academy` |  | `realm_public_museum`, `daily_printed_newspaper` [knowledge] |  |
| 2344 | `string_quartet` | `four_movement_symphony` |  | `subscription_concerts`, `salon_conversation` |  |
| 2348 | `storm_passion_poetry` | `sentimental_novel` |  | `natural_education_treatise`, `realm_history_plays` |  |
| 2356 | `folk_song_collections` | `pedlar_chapbooks`, `storm_passion_poetry` |  | `fairy_tale_collections` |  |
| 2368 | `dare_to_know_essay` | `periodical_essay_sheets` |  | `reasoned_trades_encyclopedia` [knowledge], `systematic_doubt_method` [knowledge], `press_freedom_statute` [institutions] |  |
| 2372 | `servants_comic_opera` | `public_opera_house`, `comedy_of_manners` |  | `ballad_opera_satire` |  |
| 2380 | `national_civic_festivals` | `single_national_assembly` [institutions] |  | `declaration_of_rights` [institutions], `ruler_town_entries` [1200-1800] |  |
| 2384 | `national_flag_anthem` | `heraldic_arms` [1200-1800], `single_national_assembly` [institutions] |  | `national_civic_festivals`, `realm_republic` [institutions] |  |
| 2384 | `womens_rights_treatise` | `declaration_of_rights` [institutions], `defence_of_women_book` |  | `natural_education_treatise` |  |
| 2396 | `plain_speech_nature_poetry` | `folk_song_collections` |  | `landscape_park_gardens`, `storm_passion_poetry` |  |

## Cross-line prerequisites assumed from other 1800–2400 lines

These ids are mapped by other partials in parallel; each edge assumes the parent keeps its registry year. Hard edges only; precedents are listed in the table.

- `passenger_coach` (logistics 1878) → `grand_tour_travel`
- `transoceanic_contact_voyages` (logistics 1912) → `voyage_national_epic`
- `public_letter_post` (logistics 1930) → `epistolary_novel`
- `ornamental_plaster_ceilings` (infrastructure 1932) → `playful_shell_ornament`
- `travel_passports` (security 1950) → `grand_tour_travel`
- `coffee_houses` (nutrition 1962) → `coffeehouse_public_talk`
- `axial_palace_gardens` (infrastructure 2124) → `landscape_park_gardens`

## Prerequisites from the other kicl lines

- `ruler_founded_universities` (knowledge 1821) → `public_collection_museum`
- `mirror_grid_perspective` (knowledge 1846) → `single_point_perspective_painting`
- `metal_type_casting` (knowledge 1875) → `printed_part_books`
- `printed_scripture_folio` (knowledge 1879) → `vernacular_scripture`
- `printed_broadsides` (knowledge 1890) → `pedlar_chapbooks`
- `printed_broadsides` (knowledge 1890) → `trickster_jest_books`
- `town_printing_houses` (knowledge 1892) → `artists_lives_history`
- `town_printing_houses` (knowledge 1892) → `emblem_books`
- `town_printing_houses` (knowledge 1892) → `fairy_tale_collections`
- `town_printing_houses` (knowledge 1892) → `ideal_commonwealth_fiction`
- `town_printing_houses` (knowledge 1892) → `personal_essays`
- `town_printing_houses` (knowledge 1892) → `praise_of_folly_satire`
- `town_printing_houses` (knowledge 1892) → `printed_reform_dispute`
- `town_printing_houses` (knowledge 1892) → `printed_vernacular_romances`
- `town_printing_houses` (knowledge 1892) → `sorcery_panics`
- `orthodoxy_tribunal` (institutions 1898) → `sorcery_panics`
- `rite_toleration_edict` (institutions 1998) → `toleration_letter`
- `rolling_intaglio_printing` (knowledge 2000) → `satirical_print_series`
- `printed_weekly_news` (knowledge 2010) → `coffeehouse_public_talk`
- `logarithms` (knowledge 2028) → `equal_temperament_tuning`
- `compulsory_parish_schooling` (knowledge 2038) → `natural_education_treatise`
- `chartered_experimental_society` (knowledge 2120) → `public_collection_museum`
- `grand_palace_court` (institutions 2164) → `playful_shell_ornament`
- `daily_printed_newspaper` (knowledge 2204) → `castaway_realist_novel`
- `daily_printed_newspaper` (knowledge 2204) → `periodical_essay_sheets`
- `declaration_of_rights` (institutions 2352) → `womens_rights_treatise`
- `single_national_assembly` (institutions 2378) → `national_civic_festivals`
- `single_national_assembly` (institutions 2378) → `national_flag_anthem`

## Year adjustments

None.
