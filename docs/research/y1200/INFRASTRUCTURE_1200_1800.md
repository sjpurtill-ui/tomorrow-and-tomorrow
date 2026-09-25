# Infrastructure: years 1200–1800

**Scope.** The game's **Infrastructure** research line covers building and civil works: arches, vaults and domes, roofs and heating, water supply and drainage, dikes, bridges, locks and town fabric. This list continues `docs/research/y600/INFRASTRUCTURE_600_1200.md` (which ends with squinch domes, tile-banded walls and iron tie rods). Names describe generic practices. Real history is used only to calibrate timing. Harbor, road and bridge items are marked "(shared: logistics)"; walls, castles and siege works belong to Security.

**Historical anchor.** `CURVE` in `scripts/technology_eras.gd` (`[[800,-500],[1500,1000],[2000,1600]]`, read from `origin/codex/research-600`) maps game 1200 ≈ AD 360, 1300 ≈ 570, 1400 ≈ 790, 1500 ≈ 1000, 1600 ≈ 1120, 1700 ≈ 1240 and 1800 ≈ 1360. Between 1200 and 1500, one game year is about 2.1 real years; between 1500 and 1800 it is 1.2, so the high-medieval centuries are twice as dense per game year. The calibration sources run in order:
- late-antique long conduits, pendentive domes and half-domes (1205–1295)
- eastern and southern building: stepwells, open-spandrel bridges and bracket-set timber towers (1305–1340)
- pointed and horseshoe arches, ribbed domes, wind catchers and estuary embankments (1360–1500)
- rib vaults, double-shell domes, tide gates, chimneys and flying buttresses (1550–1655)
- tracery, stone town houses, cloth halls, town halls with belfries and flat segmental bridges (1690–1790)

**Research time.** Times are game years of work by a staffed Infrastructure team. Real minutes are for **1 day/s** (speed setting 4): 1 game year takes about 6 real minutes, and 10 game years take about 1 hour.

**Id column.** A plain id is in the main catalog today (`scripts/*.gd`); its catalog year is in `HISTORICAL_YEAR`. `NEW` = not authored yet. No `NEW` slug repeats an id in `docs/research/registry.json` (0–600), `docs/research/y600/registry_1200.json` (600–1200) or a quoted id in `scripts/*.gd`. "(continues: id)" names the earlier registry item, or an item in this list, that a row improves.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). `n/r` = in the catalog but never reached in a recorded run. `—` = not in main.

## Years 1200–1500 (≈ AD 360–1000)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 1205 (1165–1245) | Long conduits draw water from distant hills through tunnels and bridges (continues: arcaded_aqueduct_bridges) | 12 y | 73 min | NEW · long_distance_conduits | — |
| 1210 (1180–1240) | Old dressed stone taken down and reused in new walls and halls | 4 y | 24 min | NEW · reused_stone_building | — |
| 1225 (1193–1257) | Valve pits regulate a reservoir's outflow (continues: spillway_reservoirs) | 8 y | 49 min | NEW · reservoir_valve_pits | — |
| 1232 (1200–1264) | Great open-air walled cisterns inside the town (continues: columned_underground_cisterns) | 8 y | 49 min | NEW · open_town_cisterns | — |
| 1240 (1205–1275) | Great earthen reservoirs feed networks of channels (shared: nutrition) | 10 y | 61 min | NEW · great_tank_reservoirs | — |
| 1255 (1225–1285) | Lead sheet laid over domes and roofs (continues: lead_sheet_rolling) | 5 y | 30 min | NEW · lead_sheet_roofing | — |
| 1270 (1238–1302) | Thin brick domes and vaults laid in light mortar without centering (continues: vaulting_tubes) | 8 y | 49 min | NEW · thin_brick_shell_vaults | — |
| **1285 (1245–1325)** | **Domes on pendentives over a square bay (continues: squinch_domes)** | 16 y | 98 min | NEW · pendentive_domes | — |
| 1295 (1263–1327) | Half-domes shoulder the thrust of a central dome | 8 y | 49 min | NEW · buttressing_half_domes | — |
| 1305 (1270–1340) | Stepwells: stair galleries descend to groundwater | 10 y | 61 min | NEW · stepwells | — |
| **1320 (1280–1360)** | **Segmental arch bridges with open spandrels (shared: logistics)** | 14 y | 85 min | NEW · open_spandrel_arch_bridges | — |
| 1335 (1300–1370) | Timber towers carried on interlocking bracket sets | 10 y | 61 min | NEW · bracket_set_timber_towers | — |
| 1348 (1316–1380) | Post-built timber halls with plank walls (continues: long_span_timber_halls) | 6 y | 37 min | NEW · plank_walled_timber_halls | — |
| 1360 (1330–1390) | Horseshoe arches on reused columns | 5 y | 30 min | NEW · horseshoe_arches | — |
| 1372 (1340–1404) | Domed steam bathhouses (continues: heated_public_baths) | 8 y | 49 min | NEW · domed_steam_baths | — |
| 1380 (1348–1412) | Garden courts divided by stone water channels | 6 y | 37 min | NEW · channelled_garden_courts | — |
| 1385 (1353–1417) | Weirs across rivers divert water into canals (shared: nutrition) | 8 y | 49 min | NEW · river_diversion_weirs | — |
| 1398 (1368–1428) | Carved stucco decoration over brick | 5 y | 30 min | NEW · carved_stucco | — |
| 1402 (1367–1437) | Cross-plan halls with a central dome on four piers (continues: pendentive_domes) | 10 y | 61 min | NEW · cross_domed_halls | — |
| **1410 (1370–1450)** | **Pointed arches cut the outward thrust** | 12 y | 73 min | NEW · pointed_arches | — |
| 1415 (1380–1450) | Stone spire towers corbelled to a curved peak | 10 y | 61 min | NEW · corbelled_spire_towers | — |
| 1422 (1390–1454) | Wind catchers draw breezes down into rooms | 6 y | 37 min | NEW · wind_catchers | — |
| 1435 (1403–1467) | Paved causeways across marshes (shared: logistics) | 6 y | 37 min | NEW · marsh_causeways | — |
| 1448 (1413–1483) | Ribbed domes on intersecting arches | 10 y | 61 min | NEW · intersecting_rib_domes | — |
| 1460 (1428–1492) | Tall brick towers with internal stairs | 8 y | 49 min | NEW · brick_stair_towers | — |
| 1472 (1440–1504) | Mill dams, head-races and tail-races (shared: production) | 6 y | 37 min | NEW · mill_leats | — |
| 1480 (1448–1512) | Timber bridges on stone piers with cutwaters (shared: logistics) | 6 y | 37 min | NEW · cutwater_pier_bridges | — |
| 1498 (1466–1530) | Earthen embankments hold back estuary tides (continues: flood_levees) | 8 y | 49 min | NEW · estuary_embankments | — |

## Years 1500–1800 (≈ AD 1000–1360)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 1502 (1472–1532) | Spiral stairs turning on a central newel | 5 y | 30 min | NEW · newel_spiral_stairs | — |
| 1515 (1480–1550) | Deep brine wells bored by percussion and lined with tubes (shared: production) | 10 y | 61 min | NEW · percussion_drilled_wells | — |
| 1528 (1496–1560) | Timber cribs filled with stone form quays and piers (shared: logistics) | 6 y | 37 min | NEW · crib_work_quays | — |
| 1535 (1503–1567) | Honeycomb corbelled niches fill the corners of vaults | 8 y | 49 min | NEW · honeycomb_corbel_vaults | — |
| 1545 (1513–1577) | Courtyards with a vaulted open hall on each side | 8 y | 49 min | NEW · four_hall_courtyards | — |
| 1550 (1518–1582) | Buttresses stiffen walls against vault thrust | 8 y | 49 min | masonry_buttressing | n/r |
| 1566 (1534–1598) | Vaulted cloister walks around a courtyard | 6 y | 37 min | NEW · vaulted_cloister_walks | — |
| 1572 (1537–1607) | Double-shell domes: a tall outer dome over a low inner one | 10 y | 61 min | NEW · double_shell_domes | — |
| **1582 (1542–1622)** | **Rib vaults on pointed arches** | 14 y | 85 min | NEW · rib_vaults | — |
| 1590 (1558–1622) | Tide gates that close themselves on the flood (continues: estuary_embankments) | 6 y | 37 min | NEW · self_closing_tide_gates | — |
| 1596 (1564–1628) | Domes faced with glazed tiles (shared: production) | 6 y | 37 min | NEW · glazed_tile_domes | — |
| 1606 (1576–1636) | Latrine towers with chutes clear of the walls (shared: health) | 5 y | 30 min | NEW · latrine_chute_towers | — |
| 1612 (1580–1644) | Treadwheel cranes set in the roof space (continues: counterweight_cranes) | 6 y | 37 min | NEW · roof_treadwheel_cranes | — |
| 1616 (1586–1646) | Scaffolds anchored in put-log holes and spiral ramps | 5 y | 30 min | NEW · putlog_scaffolding | — |
| 1620 (1588–1652) | Spring water piped to town fountains and cisterns (continues: stamped_lead_pipes) | 8 y | 49 min | NEW · piped_town_conduits | — |
| 1628 (1596–1660) | Clustered piers carry high arcades | 6 y | 37 min | NEW · clustered_piers | — |
| 1634 (1604–1664) | Vaulted undercrofts for storage beneath halls | 5 y | 30 min | NEW · vaulted_undercrofts | — |
| **1642 (1602–1682)** | **Hooded fireplaces and wall chimneys** | 10 y | 61 min | NEW · wall_chimneys | — |
| **1648 (1608–1688)** | **Flying buttresses carry vault thrust over the aisles (continues: masonry_buttressing)** | 14 y | 85 min | NEW · flying_buttresses | — |
| 1654 (1624–1684) | Bored-log water mains under the streets (continues: wooden_log_conduits) | 5 y | 30 min | NEW · bored_log_mains | — |
| 1655 (1625–1685) | Pinnacles load the buttresses to steady them (continues: masonry_buttressing) | 5 y | 30 min | NEW · buttress_pinnacles | — |
| 1658 (1623–1693) | Stone bridges lined with houses and shops (shared: logistics) | 10 y | 61 min | NEW · inhabited_bridges | — |
| 1664 (1634–1694) | Lead flashing seals roof edges and chimney joints | 5 y | 30 min | roof_flashing_interfaces | n/r |
| 1668 (1636–1700) | Moulded and glazed brick architecture (continues: clamp_fired_brick) | 8 y | 49 min | NEW · moulded_brick_architecture | — |
| 1672 (1642–1702) | Worn joints raked out and repointed | 5 y | 30 min | masonry_repointing | n/r |
| 1678 (1646–1710) | Crown-post and scissor-braced roofs | 8 y | 49 min | NEW · crown_post_roofs | — |
| 1682 (1652–1712) | Carved spouts throw roof water clear of the walls | 4 y | 24 min | NEW · carved_rain_spouts | — |
| 1684 (1654–1714) | Repair mortar matched to the old wall | 5 y | 30 min | mortar_compatibility_assessment | n/r |
| 1690 (1660–1720) | Lead gutters and downpipes carry roof water to the drains (continues: carved_rain_spouts) | 5 y | 30 min | NEW · lead_rain_gutters | — |
| **1692 (1652–1732)** | **Tracery windows of carved stone bars** | 10 y | 61 min | NEW · bar_tracery_windows | — |
| 1698 (1666–1730) | Full-size drawings on tracing floors and wooden templates (shared: knowledge) | 8 y | 49 min | NEW · tracing_floor_templates | — |
| 1700 (1668–1732) | Stone town houses with vaulted shops on the ground floor | 6 y | 37 min | NEW · stone_merchant_houses | — |
| 1704 (1672–1736) | Great round windows of radiating tracery (continues: bar_tracery_windows) | 6 y | 37 min | NEW · rose_windows | — |
| 1716 (1684–1748) | Covered markets and cloth halls (shared: institutions) | 8 y | 49 min | NEW · covered_cloth_halls | — |
| 1722 (1690–1754) | Jettied timber-framed town houses | 6 y | 37 min | NEW · jettied_timber_houses | — |
| **1735 (1695–1775)** | **Town halls with a belfry and council chamber (shared: institutions)** | 12 y | 73 min | NEW · belfry_town_halls | — |
| 1742 (1712–1772) | Stone party walls between houses stop fire | 5 y | 30 min | NEW · stone_party_walls | — |
| 1754 (1722–1786) | Tiled stoves heat rooms without smoke | 8 y | 49 min | NEW · tiled_stoves | — |
| 1760 (1728–1792) | Streets paved by town ordinance from paving tolls (continues: curbed_paved_streets) | 6 y | 37 min | NEW · toll_paved_streets | — |
| 1766 (1734–1798) | Geometric rules size piers and buttresses (shared: knowledge) | 8 y | 49 min | NEW · geometric_design_rules | — |
| 1774 (1742–1806) | Leaded glass windows in houses (continues: glazed_windows) | 6 y | 37 min | NEW · house_glass_windows | — |
| 1780 (1748–1812) | Arcaded walks around the market square (continues: standard_lot_grid_towns) | 6 y | 37 min | NEW · arcaded_market_squares | — |
| 1788 (1753–1823) | Wide, flat segmental arches for town bridges (continues: open_spandrel_arch_bridges) | 10 y | 61 min | NEW · flat_segmental_bridges | — |

## Pacing

| Years | 1200–1250 | 1250–1300 | 1300–1350 | 1350–1400 | 1400–1450 | 1450–1500 | 1500–1550 | 1550–1600 | 1600–1650 | 1650–1700 | 1700–1750 | 1750–1800 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Infrastructure advances | 5 | 4 | 4 | 5 | 6 | 4 | 5 | 6 | 8 | 12 | 6 | 6 |

The total is **71** advances: 28 in 1200–1500 and 43 in 1500–1800, with 4 catalog ids and 67 new items. 8 rows are key thresholds. The first half is thinner because each game year there covers about 2.1 real years of slower early-medieval change; after 1500 one game year is 1.2 real years and the high-medieval expansion lands one advance about every 7 years (every 11 before 1500). Short items take 4–6 years; the long thresholds take 12–16 years (73–98 real minutes).

**Key thresholds:**
1. **Domes and vaults:** thin brick shells (1270) → **pendentive domes (1285)** → half-domes (1295) → cross-plan domed halls (1402) → ribbed domes (1448) → double-shell domes (1572) → **rib vaults (1582)** → **flying buttresses (1648)** → pinnacles (1655). The very tall glass-filled houses of the god are Culture's (`pointed_arch_glass_temples`, 1625), and the great domed temple is Culture's too (`great_domed_temple`, 1283).
2. **Arches and windows:** horseshoe arches (1360) → **pointed arches (1410)** → honeycomb corbels (1535) → clustered piers (1628) → **bar tracery (1692)** → rose windows (1704) → house glass windows (1774).
3. **Water and land:** long conduits (1205) → valve pits (1225) → open cisterns (1232) → great reservoirs (1240) → stepwells (1305) → river weirs (1385) → estuary embankments (1498) → tide gates (1590) → piped town conduits (1620) → bored-log mains (1654). Pound locks are Logistics' (`canal_locks`, 1493); sluiced polders and dike boards are Ecology's (`sluiced_polders` 1555, `dike_boards` 1700).
4. **Bridges:** **open-spandrel arch bridges (1320)** → cutwater piers (1480) → inhabited bridges (1658) → flat segmental bridges (1788).
5. **Houses and towns:** **chimneys (1642)** → stone merchant houses (1700) → jettied houses (1722) → party walls (1742) → tiled stoves (1754); cloth halls (1716) → **town halls with belfries (1735)** → paved streets (1760) → arcaded market squares (1780). Planned plot towns are Demography's (`burgage_plot_towns`, 1640), and fire-roof ordinances are Security's (`fireproof_roof_ordinance`, 1660).

**Government and civic life.** These discoveries should visibly change the court and the seat of rule:
- `pendentive_domes` (1285) and `cross_domed_halls` (1402): the ruler's audience hall and palace sanctuary take a central dome.
- `wall_chimneys` (1642): the great hall gets a hooded fireplace; the ruler can hold council in a private chamber, and the household splits into hall and chamber.
- `covered_cloth_halls` (1716) and `belfry_town_halls` (1735): towns gain a council house with a belfry, a new seat of civic rule beside the ruler's hall.
- `toll_paved_streets` (1760): streets are paved under town law, with wardens of the streets.
- `rib_vaults`, `flying_buttresses` and `bar_tracery_windows` (1582–1692): the seat of rule moves from thick-walled halls to tall vaulted halls lit by large windows.

## Currently far too early / too late (infrastructure, main)

| Item | Seen | Belongs |
|---|---|---|
| canal_locks (catalog AD 984 ≈ 1493; direction Infrastructure) | n/r | 1493, placed by **Logistics**. It is not relisted here. The registry merge should decide the canonical line, because the catalog direction is Infrastructure. |
| masonry_buttressing (catalog AD 1747) | n/r | Too late in the catalog. It belongs at 1550, before flying_buttresses (1648). |
| roof_flashing_interfaces / masonry_repointing / mortar_compatibility_assessment (catalog AD 1200 ≈ 1667) | n/r | 1664 / 1672 / 1684 |
| precision_machinery (catalog AD 1350) | 217 | Belongs later. Measured bearings, guides and cutting tools are 18th-century (≈ game 2370). |
| mine_airways (catalog AD 1747) | 147 | Belongs later (≈ AD 1500–1550 → game ≈ 1920) |
| concrete_formwork_systems / concrete_mix_design (catalog AD 1747) | n/r | Belongs later (≈ game 2370) |
| Hammer-beam roofs, drainage windmills | — | Belongs later (≈ AD 1400–1450 → game 1833–1875) |
