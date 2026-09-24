# Culture: the first 600 years

**Scope.** The game's **Culture** research line (`culture` dynamic and direction) has four channels: Social cohesion, Shared legitimacy, Inquiry breadth and Collective memory. It covers language and storytelling, music and dance, ritual and ceremony, burial and ancestor rites, art and ornament, games, festivals, naming and identity, hospitality and exchange customs, and cosmology. The people revere their living god as well as their ancestors and the land, so rites here are addressed to the god. In main it has 6 entries in `technology_branch_catalog.gd`: `oral_epics`, `festival_calendar`, `civic_games`, `public_theatre`, `comparative_chronicles` and `public_libraries`. Only the first two belong before year 600. The era branch adds 32 `culture` practices in `early_practice_knowledge.gd`. The teaching and memory items already placed in Knowledge are left out here (see Knowledge): children's question circles, recitation drills, verse mnemonics, year names and event lists (`formal_chronicle_keeping`), and recited lore copied onto tablets. The "Shared legitimacy" practices that mainly govern councils, oaths and disputes are also left out (see Institutions): witnessed agreements, elder assent, public grain weighing, dispute airing, rotating speaker order, formal oath-taking, oath-witness registers and petition rights.

**Historical anchor.** Game years 0–300 correspond to roughly 5000–3000 BC (late Neolithic to proto-writing). Years 300–600 correspond to roughly 3000–1500 BC (early writing, tablet schools, place value). This is the pacing curve from `codex/era-research-pacing` (`technology_eras.gd`).

**Research time.** Time is given in game years while a staffed Culture team is working on the item. Real minutes are for **1 day/s** (speed setting 4). In real time, 1 game year is about 6 minutes, and 10 game years are about 1 hour. At 3 days/s, divide by 3. At 8 h/s, multiply by 3.

**Id column.** `id` = in the main catalog today. `(era)` = written on the unmerged branch `codex/era-research-pacing` and not yet in main. `NEW` = not authored yet.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`), or `≈` for an estimate from the prerequisite graph. It is `—` when the item is not in main.

## Years 0–300 (≈ 5000–3000 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 1 (0–3) | Shared hearth gatherings | 1 y | 6 min | shared_hearth_gatherings (era) | — |
| 2 (0–5) | Communal work songs | 1.5 y | 9 min | communal_work_songs (era) | — |
| 3 (0–6) | Oral epics: trained reciters keep long accounts | 2 y | 12 min | oral_epics | 16 |
| 4 (0–8) | Elders recite each household's lineage | 2 y | 12 min | genealogical_recitation (era) | — |
| 5 (0–10) | Every notable rock and spring has a naming story | 1.5 y | 9 min | named_landmark_lore (era) | — |
| 6 (1–12) | Children praised for asking why | 2 y | 12 min | curious_questioning_custom (era) | — |
| 7 (2–12) | Bone flutes and hand drums at gatherings | 2 y | 12 min | NEW · bone_flutes_drums | — |
| 8 (2–14) | Circle dances at gatherings | 2 y | 12 min | NEW · circle_dances | — |
| 9 (3–15) | The dead buried beneath the house floor | 2 y | 12 min | NEW · house_floor_burial | — |
| 10 (3–16) | Red ochre and grave goods for the dead | 2 y | 12 min | NEW · ochre_grave_goods | — |
| 12 (4–20) | Body paint, shell and bead ornament marking kin | 2 y | 12 min | NEW · kin_body_ornament | — |
| 14 (5–22) | Offerings to the living god at the hearth-shrine | 2 y | 12 min | NEW · hearth_shrine_offerings | — |
| 16 (6–25) | Ancestor skulls plastered and kept in the house | 3 y | 18 min | NEW · plastered_ancestor_skulls | — |
| 18 (8–28) | Mourning days of wailing and fasting | 2 y | 12 min | NEW · mourning_days | — |
| 20 (8–30) | Seasonal festival calendar | 3 y | 18 min | festival_calendar | 22 |
| 22 (10–32) | Guest-right: a stranger fed and protected for three days | 2 y | 12 min | NEW · guest_host_reciprocity (dup) | — |
| 25 (12–35) | Gifts given and returned bind households | 2 y | 12 min | NEW · reciprocal_gift_exchange | — |
| 28 (14–40) | Origin story: how the people and their god came to this land | 4 y | 24 min | NEW · origin_story | — |
| 30 (16–45) | Pottery motifs that mark a people (shared: production) | 3 y | 18 min | NEW · pottery_style_identity | — |
| 32 (18–48) | Clay figurines of ancestors | 3 y | 18 min | NEW · ancestor_figurines | — |
| 35 (20–50) | Pit-and-pebble counting game | 2 y | 12 min | NEW · pit_pebble_game | — |
| 38 (22–55) | First fruits offered to the god before the harvest is eaten | 2 y | 12 min | NEW · first_fruits_offering | — |
| 40 (25–60) | Winter tale nights | 2 y | 12 min | NEW · winter_tale_nights | — |
| 45 (28–65) | Star figures named in stories | 3 y | 18 min | NEW · named_star_figures | — |
| 50 (32–70) | Painted walls in shrine rooms | 4 y | 24 min | NEW · shrine_wall_painting | — |
| 55 (35–75) | Masks and costumes for rites | 3 y | 18 min | NEW · ritual_masks_costumes | — |
| 60 (40–80) | Sacred places set apart: spring, grove, high rock | 3 y | 18 min | NEW · sacred_places | — |
| 65 (45–85) | Coming-of-age rites for youths | 3 y | 18 min | NEW · coming_of_age_rites | — |
| 75 (50–95) | Cooperative harvest gatherings | 3 y | 18 min | cooperative_harvest_gatherings (era) | — |
| 80 (55–100) | Household lineage tokens | 3 y | 18 min | household_lineage_tokens (era) | — |
| 85 (60–105) | Crafters spend a season watching another craft | 3 y | 18 min | cross_craft_visiting (era) | — |
| 90 (65–110) | Memorial cairns at the sites of notable events | 3 y | 18 min | memorial_cairn_marking (era) | — |
| 95 (70–115) | Marriage feasts joining two lineages | 3 y | 18 min | NEW · marriage_feasts | — |
| 100 (75–125) | Mutual aid customs | 3 y | 18 min | mutual_aid_customs (era) | — |
| **110 (80–145)** | **A house for the god: the first shrine building (shared: institutions)** | 8 y | 49 min | NEW · first_shrine_house | — |
| 115 (85–145) | Songs of praise sung to the god at set times | 4 y | 24 min | NEW · praise_songs | — |
| 120 (90–150) | Rattles, clay drums and reed pipes | 3 y | 18 min | NEW · rattles_drums_pipes | — |
| 130 (100–160) | Traveling storytellers trade tales for lodging | 4 y | 24 min | traveling_storyteller_exchange (era) | — |
| 135 (105–165) | Libations poured for the ancestors at graves | 3 y | 18 min | NEW · graveside_libations | — |
| 140 (105–175) | Cemeteries set apart from the village | 5 y | 30 min | NEW · burial_ground_separation (dup) | — |
| 145 (110–180) | Flood-mark stones and their stories | 3 y | 18 min | disaster_memory_markers (era) | — |
| 150 (115–185) | Grief support customs | 3 y | 18 min | grief_support_customs (era) | — |
| 152 (115–190) | Riddle and puzzle contests | 2 y | 12 min | puzzle_riddle_contests (era) | — |
| 155 (120–190) | Wrestling and footraces at festivals | 3 y | 18 min | NEW · festival_wrestling_races | — |
| 160 (125–195) | Processions carry the god's emblem through the fields | 4 y | 24 min | NEW · emblem_processions | — |
| 170 (130–210) | The god's house raised on a platform above the town (shared: infrastructure) | 8 y | 49 min | NEW · shrine_terraces (dup) | — |
| 180 (140–220) | Proverbs passed down as counsel | 3 y | 18 min | NEW · proverbs | — |
| 190 (150–230) | Festival meals shared at the god's house | 4 y | 24 min | NEW · temple_festival_meals | — |
| 200 (160–240) | Stories of the great flood and the first days | 5 y | 30 min | NEW · flood_origin_stories | — |
| 210 (170–250) | Inlaid shell and stone ornament for high rank (shared: production) | 4 y | 24 min | NEW · rank_inlay_ornament | — |
| 225 (185–265) | Naming-day rites | 3 y | 18 min | naming_day_rites (era) | — |
| 240 (200–280) | A yearly rite on the date of a remembered disaster | 4 y | 24 min | seasonal_commemoration_rites (era) | — |
| 250 (210–285) | Rival explanations argued before the community | 4 y | 24 min | public_debate_custom (era) | — |
| 255 (215–290) | Hair and dress styles marking age and rank | 3 y | 18 min | NEW · rank_dress_styles | — |
| 262 (220–295) | Techniques credited to the teacher who began them | 3 y | 18 min | craft_lineage_naming (era) | — |
| 265 (225–300) | Visiting customs between intermarried villages | 4 y | 24 min | intermarriage_visiting_customs (era) | — |
| 268 (225–305) | Respected outsiders consulted on hard disputes | 3 y | 18 min | visiting_specialist_consultations (era) | — |
| 275 (230–315) | Relief carving on stone slabs | 6 y | 37 min | NEW · stone_relief_carving | — |
| 280 (240–320) | Offering processions shown in bands on vessels | 6 y | 37 min | NEW · banded_procession_vessels | — |
| 285 (245–325) | Singers and lamenters trained for the god's house | 6 y | 37 min | NEW · temple_singers_lamenters | — |
| 290 (250–330) | Guest-friendship between houses of different towns | 4 y | 24 min | NEW · guest_friendship | — |
| 300 (255–345) | The founder's story recited at the turn of the year | 6 y | 37 min | NEW · founder_story_recitation | — |

## Years 300–600 (≈ 3000–1500 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 310 (275–345) | Race games on a marked board with throwing sticks | 4 y | 24 min | NEW · board_race_games | — |
| **320 (280–370)** | **New-year festival of the god's renewal of the land** | 10 y | 61 min | NEW · new_year_festival | — |
| 330 (295–365) | Town identity: its own name, emblem and patron festival | 6 y | 37 min | NEW · town_identity | — |
| 350 (315–385) | Personal names that honor the god | 3 y | 18 min | NEW · theophoric_names | — |
| 360 (320–395) | Shared meal obligations | 4 y | 24 min | shared_meal_obligations (era) | — |
| 365 (325–400) | Votive figures stand in prayer before the god | 6 y | 37 min | NEW · votive_figures | — |
| 375 (335–410) | Hymn cycles for each season of the god's year | 6 y | 37 min | NEW · seasonal_hymn_cycles | — |
| 380 (340–420) | Tuned harps and lyres | 8 y | 49 min | NEW · harps_and_lyres | — |
| 385 (345–425) | Chamber tombs with rich goods for leading lineages | 8 y | 49 min | NEW · chamber_tombs | — |
| 395 (355–430) | Temple choirs with drums and cymbals | 6 y | 37 min | NEW · temple_choirs | — |
| 400 (360–440) | Craft specialists compare methods on market days | 6 y | 37 min | comparative_craft_gatherings (era) | — |
| 403 (360–445) | Inlaid mosaic panels of feasts and processions | 6 y | 37 min | NEW · inlaid_mosaic_panels | — |
| 405 (365–445) | Wisdom instructions from a father to his son | 6 y | 37 min | NEW · wisdom_instructions | — |
| 420 (380–460) | Dancers and acrobats at festivals | 4 y | 24 min | NEW · festival_dancers_acrobats | — |
| 430 (390–470) | Special garments and headdress for officiants | 4 y | 24 min | NEW · officiant_vestments | — |
| 440 (400–480) | Envoys received with a feast and gifts | 5 y | 30 min | NEW · envoy_reception | — |
| 445 (405–485) | Feast days fixed to the months of the god's calendar | 5 y | 30 min | NEW · calendar_feast_days | — |
| 450 (410–490) | Public days of lament for a dead ruler | 4 y | 24 min | NEW · royal_mourning | — |
| 455 (415–495) | Stone portraits of the ruler | 8 y | 49 min | NEW · royal_stone_portraits | — |
| 460 (420–500) | Wrestling and boxing matches before the ruler | 4 y | 24 min | NEW · royal_wrestling_matches | — |
| 470 (430–510) | Dreams read as messages from the god | 5 y | 30 min | NEW · dream_interpretation | — |
| 480 (440–520) | Debate poems: two rivals argue in verse | 6 y | 37 min | NEW · debate_poems | — |
| **490 (445–535)** | **Heroic song cycle of a great ruler** | 10 y | 61 min | NEW · heroic_song_cycle | — |
| 500 (460–540) | Monthly offerings for dead rulers | 5 y | 30 min | NEW · royal_ancestor_offerings | — |
| 505 (465–545) | Love songs and wedding songs | 4 y | 24 min | NEW · love_wedding_songs | — |
| 510 (470–550) | Laments for a ruined town | 6 y | 37 min | NEW · city_laments | — |
| 520 (480–560) | Omens read from offerings (shared: knowledge) | 6 y | 37 min | NEW · offering_omens | — |
| 530 (490–570) | The god's boat carried in procession | 8 y | 49 min | NEW · god_boat_procession | — |
| 540 (500–580) | Letters to the god laid before the shrine | 4 y | 24 min | NEW · letters_to_the_god | — |
| 545 (505–585) | Painted walls in palace halls | 6 y | 37 min | NEW · palace_wall_painting | — |
| 555 (515–595) | Tablet-house songs and satires | 5 y | 30 min | NEW · scribal_songs_satires | — |
| 560 (520–600) | Pilgrimage to the god's great house from distant towns | 6 y | 37 min | NEW · pilgrimage | — |
| 570 (530–610) | Foreign ornament and dress adopted | 4 y | 24 min | NEW · foreign_fashion_adoption | — |
| 580 (540–620) | Sung narrative of the god's deeds with music | 8 y | 49 min | NEW · sung_divine_narrative | — |
| 590 (550–630) | Yearly feast of the dead | 5 y | 30 min | NEW · feast_of_the_dead | — |
| 600 (560–640) | Festival bread from the god shared with every household | 4 y | 24 min | NEW · festival_bread_sharing | — |

## Pacing

| Years | 0–50 | 50–100 | 100–150 | 150–200 | 200–250 | 250–300 | 300–350 | 350–400 | 400–450 | 450–500 | 500–550 | 550–600 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Culture advances | 24 | 9 | 8 | 7 | 4 | 10 | 3 | 7 | 7 | 6 | 7 | 6 |

The total is **98** advances: 62 in the first 300 years and 36 in the next 300. Across the four channels, one lands about every 6 years. Culture is the most front-loaded line: song, dance, burial, ornament and story need no materials, so the first 50 years hold many 1–4-year customs. Long thresholds (8–10 years) mark the first shrine building, the new-year festival and the heroic song cycle. After year 300, most items tie culture to the god's house, the town and the ruler.

**Key thresholds:**
1. **Story and memory:** oral epics (3) → lineage recitation (4) → origin story (28) → traveling storytellers (130) → flood stories (200) → founder's story at the new year (300) → debate poems (480) → heroic song cycle (490) → sung narrative of the god's deeds (580).
2. **Rite and the god:** hearth-shrine offerings (14) → first fruits (38) → sacred places (60) → first shrine building (110) → praise songs (115) → raised god's house (170) → new-year festival (320) → votive figures (365) → pilgrimage (560).
3. **Burial and ancestors:** house-floor burial (9) → grave goods (10) → plastered skulls (16) → graveside libations (135) → cemeteries (140) → chamber tombs (385) → monthly offerings for dead rulers (500) → yearly feast of the dead (590).
4. **Music, dance and games:** work songs (2) → flutes and drums (7) → circle dances (8) → pebble game (35) → wrestling and footraces (155) → race board games (310) → tuned harps and lyres (380) → temple choirs (395).

## Currently too early (culture line, main)

These are placement targets only. The "Seen" column is the earliest year observed in recorded runs, or estimated from the graph where marked ≈.

| Item | Seen | Belongs |
|---|---|---|
| civic_games (agreed rules, measured contests across settlements) | 26 | Beyond 600 (≈ 760). Festival wrestling and footraces come at 155. |
| public_theatre | 142 | Beyond 600 (≈ 800) |
| comparative_chronicles | ≈80 | Beyond 600 (≈ 810) |
| public_libraries | not yet seen | Beyond 600 |

`oral_epics` (16) and `festival_calendar` (22) are within their bands.
