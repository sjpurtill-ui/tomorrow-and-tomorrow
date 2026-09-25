# Production: years 1200–1800

**Scope.** The game's **Production** research line covers crafts and making: metals, ceramics, glass, textiles, dyes, leather, paper, and the mills and machines that drive them. This list continues `docs/research/y600/PRODUCTION_600_1200.md` (which ends with pattern welding, still-head distillation, hard soap and cylinder-blown panes). Names describe generic practices. Real history is used only to calibrate timing. Grain milling as food is Nutrition's; the mill machinery itself is placed here, as `water_mills` was in 600–1200.

**Historical anchor.** `CURVE` in `scripts/technology_eras.gd` (`[[800,-500],[1500,1000],[2000,1600]]`, read from `origin/codex/research-600`) maps game 1200 ≈ AD 360, 1300 ≈ 570, 1400 ≈ 790, 1500 ≈ 1000, 1600 ≈ 1120, 1700 ≈ 1240 and 1800 ≈ 1360. Between 1200 and 1500, one game year is about 2.1 real years; between 1500 and 1800 it is 1.2, so the high-medieval centuries are twice as dense per game year. The calibration sources run in order:
- **Iron:** co-fusion steel (1345) and great iron castings (1352) in an eastern-style branch → coal-fired smelting (1525) → water-blown stack bloomeries (1706) → the blast furnace (1772) and finery (1794) at the very end of the window
- **Ceramics:** pale hard-fired ware (1248) → tin glaze (1405) and lustre (1415) → true porcelain (1492) → celadon, stonepaste and sgraffito (1530–1595) → underglaze cobalt (1782)
- **Textiles:** silk reeling (1288) → cotton gin and bowing (1300–1310) → block printing on cloth (1320) → spinning wheel (1498) and knitting (1505) → fulling mills (1558) → broad loom (1570) → velvet (1680) → water-powered silk throwing (1748)
- **Power:** floating and horizontal mills (1262–1275) → tide mills (1332) → gearing (1370) → wind towers (1462) → cams and stamps (1545–1582) → post windmills (1654) → crank sawmills (1698)

**Research time.** Times are game years of work by a staffed Production team. Real minutes are for **1 day/s** (speed setting 4): 1 game year takes about 6 real minutes, and 10 game years take about 1 hour.

**Id column.** A plain id is in the main catalog today (`scripts/*.gd`); its catalog year is in `HISTORICAL_YEAR`. `NEW` = not authored yet. No `NEW` slug repeats an id in `docs/research/registry.json` (0–600), `docs/research/y600/registry_1200.json` (600–1200) or a quoted id in `scripts/*.gd`. "(continues: id)" names the earlier registry item, or an item in this list, that a row improves.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). `n/r` = in the catalog but never reached in a recorded run. `—` = not in main.

## Years 1200–1500 (≈ AD 360–1000)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 1210 (1180–1240) | Pawl-and-ratchet stops on winches and windlasses | 5 y | 30 min | ratchet_motion_control | n/r |
| 1215 (1185–1245) | Iron-gall ink brewed from oak galls and green vitriol (shared: knowledge) | 5 y | 30 min | NEW · iron_gall_ink | — |
| 1222 (1190–1254) | Gold parted from silver by salt cementation (continues: argentiferous_lead_working) | 8 y | 49 min | NEW · salt_cementation_parting | — |
| 1228 (1198–1258) | Niello: black sulphide inlay in silver | 5 y | 30 min | NEW · niello_inlay | — |
| 1235 (1203–1267) | Enamel fired in cells of soldered wire (continues: champleve_enamel) | 6 y | 37 min | NEW · wire_cell_enamel | — |
| 1242 (1212–1272) | Gold beaten to thin leaf between membranes | 5 y | 30 min | NEW · membrane_beaten_gold_leaf | — |
| 1248 (1213–1283) | Pale, hard-fired glazed ware close to porcelain (continues: high_fire_stoneware) | 10 y | 61 min | NEW · pale_hard_fired_ware | — |
| 1262 (1230–1294) | Floating mills moored in a river current (shared: nutrition) | 6 y | 37 min | NEW · floating_boat_mills | — |
| 1268 (1238–1298) | Frame saws with iron blades tensioned by a twisted cord | 4 y | 24 min | NEW · cord_tensioned_frame_saws | — |
| 1275 (1243–1307) | Horizontal-wheel mills on small, fast streams (continues: water_mills) (shared: nutrition) | 6 y | 37 min | NEW · horizontal_wheel_mills | — |
| **1288 (1248–1328)** | **Silkworm rearing and cocoon reeling (shared: nutrition, ecology)** | 12 y | 73 min | NEW · sericulture_reeling | — |
| 1295 (1263–1327) | Slit tapestry woven in silk | 6 y | 37 min | NEW · slit_silk_tapestry | — |
| 1300 (1268–1332) | Roller gin strips seed from cotton bolls | 6 y | 37 min | NEW · roller_cotton_gin | — |
| 1310 (1280–1340) | Cotton fibre fluffed with a vibrating bowstring | 4 y | 24 min | NEW · bow_fibre_fluffing | — |
| 1315 (1285–1345) | Glass beakers with applied trails and claws (continues: glass_blowing) | 5 y | 30 min | NEW · trailed_glass_vessels | — |
| 1320 (1288–1352) | Cloth printed with carved wooden blocks | 8 y | 49 min | textile_printing | n/r |
| 1332 (1300–1364) | Tide mills fill a pond at high water and grind on the ebb (shared: nutrition, infrastructure) | 8 y | 49 min | NEW · tide_mills | — |
| 1345 (1310–1380) | Edge steel made by melting cast iron into wrought iron (continues: crucible_steel_cakes) | 10 y | 61 min | NEW · co_fusion_steel | — |
| 1352 (1317–1387) | Great statues and bells cast in iron (continues: cast_iron_vessels) | 10 y | 61 min | NEW · monumental_iron_casting | — |
| 1358 (1326–1390) | Lacquer built up in many polished coats | 8 y | 49 min | NEW · multi_coat_lacquer | — |
| 1370 (1338–1402) | Mill gear trains of cog wheels and lantern pinions (continues: water_mills) | 6 y | 37 min | NEW · cog_and_lantern_gearing | — |
| 1380 (1350–1410) | Thin horn panes for lanterns and small windows | 4 y | 24 min | NEW · horn_lantern_panes | — |
| 1388 (1358–1418) | White leather tawed with alum and salt | 5 y | 30 min | NEW · alum_tawed_leather | — |
| 1395 (1363–1427) | Salt brine settled and filtered before boiling | 6 y | 37 min | brine_purification | 100 |
| **1405 (1365–1445)** | **Opaque white tin glaze over earthenware (continues: lead_glazed_ware)** | 12 y | 73 min | NEW · tin_opacified_glaze | — |
| 1415 (1383–1447) | Metallic lustre painted onto glazed ware | 8 y | 49 min | NEW · lustre_glazed_ware | — |
| 1420 (1390–1450) | Grindstones turned by a crank handle | 5 y | 30 min | NEW · crank_grindstones | — |
| 1422 (1392–1452) | Wet paper sheets pressed in a stack before drying (continues: paper_making) (shared: knowledge) | 5 y | 30 min | paper_sheet_pressing | n/r |
| 1435 (1403–1467) | Potash glass from the ash of forest plants (continues: decolorized_clear_glass) | 8 y | 49 min | NEW · potash_forest_glass | — |
| 1442 (1410–1474) | Gilt membrane thread woven into brocades (continues: gold_thread_embroidery) | 6 y | 37 min | NEW · gilt_membrane_thread | — |
| 1448 (1413–1483) | Great bells cast in pits beside the building (shared: culture) | 10 y | 61 min | NEW · pit_cast_bells | — |
| 1455 (1423–1487) | Bronze doors cast in relief panels | 8 y | 49 min | NEW · cast_bronze_doors | — |
| 1462 (1427–1497) | Vertical-axis windmills in walled wind towers (shared: nutrition) | 10 y | 61 min | NEW · vertical_axis_windmills | — |
| 1472 (1440–1504) | Figured silks with an extra binding warp (continues: drawloom_pattern_control) | 8 y | 49 min | NEW · lampas_figured_silks | — |
| 1480 (1450–1510) | Fine goatskin leather for shoes and bindings | 5 y | 30 min | NEW · fine_goatskin_leather | — |
| 1486 (1454–1518) | Edge-runner mills crush oil seed and ore | 6 y | 37 min | NEW · edge_runner_mills | — |
| **1492 (1452–1532)** | **True porcelain from white porcelain clay and porcelain stone (continues: pale_hard_fired_ware)** | 14 y | 85 min | NEW · kaolin_porcelain | — |
| **1498 (1458–1538)** | **Spinning wheel: a hand-turned wheel drives the spindle** | 12 y | 73 min | spinning_wheels | 99 |

## Years 1500–1800 (≈ AD 1000–1360)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 1505 (1473–1537) | Knitting: fabric built from interlocked loops | 8 y | 49 min | knitted_loop_fabrics | n/r |
| 1512 (1480–1544) | Warded locks and iron padlocks | 6 y | 37 min | NEW · warded_locks | — |
| 1525 (1490–1560) | Mineral coal fires iron smelting where wood is short (shared: ecology) | 10 y | 61 min | NEW · coal_fired_ironworking | — |
| 1532 (1500–1564) | Grey-green glaze from iron fired in a smoky kiln (continues: reduction_firing) | 8 y | 49 min | NEW · celadon_reduction_glaze | — |
| 1545 (1513–1577) | Cam shafts lift hammers, stamps and fulling stocks | 8 y | 49 min | cam_motion_design | n/r |
| **1558 (1518–1598)** | **Water-powered fulling mills (continues: fullers_earth_finishing)** | 12 y | 73 min | NEW · fulling_mills | — |
| 1564 (1534–1594) | Pattern scratched through slip before glazing | 5 y | 30 min | NEW · sgraffito_slipware | — |
| 1570 (1538–1602) | Broad treadle loom worked by two weavers (continues: treadle_frame_loom) | 8 y | 49 min | NEW · broad_treadle_loom | — |
| 1576 (1546–1606) | Nailers' households forge nails to a standard count (shared: labor) | 5 y | 30 min | NEW · nailer_workshops | — |
| 1582 (1550–1614) | Ore crushed by water-driven stamps (continues: cam_motion_design) | 8 y | 49 min | NEW · water_ore_stamps | — |
| 1588 (1558–1618) | Crushed ore washed in sluices and settling troughs | 5 y | 30 min | NEW · ore_washing_sluices | — |
| 1594 (1562–1626) | White stonepaste body of frit, quartz and clay | 8 y | 49 min | NEW · frit_stonepaste | — |
| 1600 (1568–1632) | Linseed-oil varnish and oil-bound paints (shared: culture) | 6 y | 37 min | NEW · oil_varnish_paints | — |
| **1608 (1568–1648)** | **Leaded stained-glass windows (shared: infrastructure)** | 12 y | 73 min | NEW · leaded_stained_glass | — |
| 1615 (1583–1647) | Scarlet from scale insects, mordanted with alum (continues: alum_mordant_dyeing) | 6 y | 37 min | NEW · scale_insect_scarlet | — |
| 1620 (1590–1650) | Linen bleached on open fields with lye and sour milk | 5 y | 30 min | NEW · field_linen_bleaching | — |
| 1625 (1593–1657) | Soap boiled in large coppers for sale (continues: salted_hard_soap) | 8 y | 49 min | soap_manufacture | n/r |
| 1630 (1598–1662) | Moulded bricks fired in clamps where stone is scarce (continues: kiln_fired_bricks) | 8 y | 49 min | NEW · clamp_fired_brick | — |
| 1636 (1606–1666) | Fustian: linen warp with cotton weft | 5 y | 30 min | NEW · fustian_cloth | — |
| 1640 (1610–1670) | Cloth nap raised with teasels and cropped with shears | 5 y | 30 min | NEW · teasel_nap_shearing | — |
| 1645 (1615–1675) | Bar iron cut to standard sizes for trade (shared: logistics) | 5 y | 30 min | NEW · standard_bar_iron | — |
| 1648 (1616–1680) | Alum rock mined, roasted and leached for mordant | 8 y | 49 min | NEW · alum_works | — |
| **1654 (1614–1694)** | **Post windmills turned to face the wind (shared: nutrition)** | 14 y | 85 min | NEW · post_windmills | — |
| 1660 (1628–1692) | Water-driven grinding and polishing wheels for blades | 6 y | 37 min | NEW · water_grinding_wheels | — |
| 1666 (1636–1696) | Garments closed with buttons and bound buttonholes | 5 y | 30 min | buttonhole_edge_reinforcement | n/r |
| 1670 (1638–1702) | Foot treadle drives the lathe | 6 y | 37 min | treadle_lathe_drive | n/r |
| **1676 (1636–1716)** | **Water-powered paper mills with stamping hammers (continues: paper_sheet_pressing)** | 12 y | 73 min | NEW · paper_stamping_mills | — |
| 1680 (1645–1715) | Velvet: cut pile raised over a woven ground | 10 y | 61 min | pile_fabric_weaving | n/r |
| 1684 (1654–1714) | Fibre carded with wire-toothed hand cards (continues: wire_drawing) | 5 y | 30 min | NEW · wire_hand_cards | — |
| 1694 (1662–1726) | Enamelled and gilded glass vessels | 6 y | 37 min | NEW · enamelled_gilt_glass | — |
| 1698 (1663–1733) | Water-powered sawmills with crank and sliding frame (continues: water_powered_stone_saws) | 10 y | 61 min | NEW · crank_driven_sawmills | — |
| 1702 (1672–1732) | Paper hardened for ink with gelatin size | 5 y | 30 min | NEW · gelatin_paper_sizing | — |
| 1706 (1671–1741) | Tall bloomery stacks blown by water-driven bellows (continues: water_driven_bellows) | 10 y | 61 min | NEW · water_blown_stack_bloomery | — |
| 1710 (1680–1740) | Two-colour inlaid floor tiles (shared: infrastructure) | 5 y | 30 min | NEW · inlaid_floor_tiles | — |
| 1714 (1682–1746) | Silver won from deep shafts in new mining districts (continues: argentiferous_lead_working) | 8 y | 49 min | NEW · deep_silver_mining | — |
| 1718 (1686–1750) | Horse gins wind ore and water up the shafts | 6 y | 37 min | NEW · horse_whim_hoists | — |
| 1722 (1690–1754) | Tinplate: iron sheet dipped in molten tin (continues: vessel_tinning) | 8 y | 49 min | NEW · tinned_iron_plate | — |
| 1726 (1694–1758) | Draw kilns burn lime without stopping (continues: lime_burning) | 6 y | 37 min | NEW · draw_lime_kilns | — |
| 1730 (1698–1762) | Ropewalks lay long ship cables (continues: rope_laying) | 6 y | 37 min | NEW · ropewalk_cables | — |
| 1736 (1704–1768) | Crown glass spun into round panes (continues: blown_cylinder_panes) | 8 y | 49 min | NEW · spun_crown_panes | — |
| 1740 (1708–1772) | Chains of rag balls pump water out of deep mines (continues: mine_drainage) | 8 y | 49 min | NEW · rag_chain_mine_pumps | — |
| 1744 (1714–1774) | Watermarks wired into paper moulds | 4 y | 24 min | NEW · paper_watermarks | — |
| **1748 (1708–1788)** | **Water-powered silk-throwing mills (continues: sericulture_reeling)** | 14 y | 85 min | NEW · silk_throwing_mills | — |
| 1752 (1720–1784) | Assay offices stamp tested gold and silver (shared: institutions) | 6 y | 37 min | NEW · assay_hallmarks | — |
| 1756 (1726–1786) | Yellow silver stain painted onto glass (continues: leaded_stained_glass) | 5 y | 30 min | NEW · silver_stain_glass | — |
| 1760 (1728–1792) | Wire drawn by water power (continues: wire_drawing) | 8 y | 49 min | NEW · water_wire_drawing | — |
| 1766 (1734–1798) | Gold and silver parted with strong acid (continues: salt_cementation_parting) | 8 y | 49 min | NEW · acid_gold_parting | — |
| **1772 (1732–1812)** | **Blast furnace: continuous smelting to liquid iron** | 16 y | 98 min | blast_furnace | 213 |
| 1777 (1745–1809) | Garments cut and tailored close to the body (shared: culture) | 8 y | 49 min | NEW · fitted_tailoring | — |
| 1782 (1750–1814) | Cobalt blue painted under the glaze (continues: kaolin_porcelain) | 8 y | 49 min | NEW · underglaze_cobalt_blue | — |
| **1794 (1754–1834)** | **Finery forge turns pig iron into bar iron** | 10 y | 61 min | finery_forges | n/r |

## Pacing

| Years | 1200–1250 | 1250–1300 | 1300–1350 | 1350–1400 | 1400–1450 | 1450–1500 | 1500–1550 | 1550–1600 | 1600–1650 | 1650–1700 | 1700–1750 | 1750–1800 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Production advances | 7 | 5 | 6 | 6 | 7 | 7 | 5 | 7 | 10 | 9 | 12 | 8 |

The total is **89** advances: 38 in 1200–1500 and 51 in 1500–1800, with 13 catalog ids and 76 new items. 11 rows are key thresholds. The first half is thinner because each game year there covers about 2.1 real years of slower early-medieval change; after 1500 one game year is 1.2 real years and the high-medieval expansion lands one advance about every 6 years (every 8 before 1500). Short items take 4–6 years; the long thresholds take 12–16 years (73–98 real minutes).

**Key thresholds:**
1. **Iron:** co-fusion steel (1345) → great iron castings (1352) → coal-fired smelting (1525) → standard bar iron (1645) → water-blown stack bloomery (1706) → **blast furnace (1772)** → **finery forge (1794)**. Bulk steel refining belongs far later.
2. **Ceramics:** pale hard-fired ware (1248) → **tin glaze (1405)** → lustre (1415) → **porcelain (1492)** → celadon (1532) → stonepaste (1594) → inlaid floor tiles (1710) → underglaze cobalt (1782).
3. **Glass:** trailed vessels (1315) → potash glass (1435) → **stained-glass windows (1608)** → enamelled glass (1694) → crown panes (1736) → silver stain (1756).
4. **Textiles:** **sericulture (1288)** → cotton gin (1300) → block-printed cloth (1320) → figured silks (1472) → **spinning wheel (1498)** → knitting (1505) → **fulling mills (1558)** → broad loom (1570) → velvet (1680) → **silk-throwing mills (1748)**.
5. **Power, mining and paper:** floating and horizontal mills (1262–1275) → tide mills (1332) → gearing (1370) → crank grindstones (1420) → wind towers (1462) → edge runners (1486) → cams (1545) → ore stamps (1582) → **post windmills (1654)** → crank sawmills (1698) → horse gins (1718) → mine pumps (1740) → water wire-drawing (1760). Paper: pressed sheets (1422) → **stamping mills (1676)** → gelatin sizing (1702) → watermarks (1744). Every mill is Production's; grinding dues and the miller's trade are Labor's and Nutrition's.

**Government and civic life.** These discoveries should visibly change the court and the seat of rule:
- `leaded_stained_glass` (1608): the ruler's hall and the great sanctuary get figured glass windows, and the throne room changes look.
- `paper_stamping_mills` (1676): cheap paper lets the chancery register every grant and judgment (Institutions `royal_chancery_office`, 1560; `chancery_enrolment_rolls`, 1666).
- `assay_hallmarks` (1752): an assay warden joins the mint and treasury offices.
- `fulling_mills` (1558) and `post_windmills` (1654): mill rights become a lord's right, and mill disputes come to court (Labor `mill_suit_obligation`, 1475).
- `blast_furnace` (1772): state ironworks and arms supply become a question for the council.

## Currently far too early / too late (production, main)

| Item | Seen | Belongs |
|---|---|---|
| spinning_wheels (catalog AD 1000 ≈ 1500) | 99 | 1498 |
| brine_purification (catalog AD 800 ≈ 1407) | 100 | 1395 |
| blast_furnace (catalog AD 1350 ≈ 1792) | 213 | 1772 |
| knitted_loop_fabrics (catalog AD 1000) | n/r | 1505 |
| textile_printing / soap_manufacture / cam_motion_design (catalog AD 1747–1780) | n/r | Too late in the catalog: 1320 / 1625 / 1545 |
| buttonhole_edge_reinforcement / pile_fabric_weaving / treadle_lathe_drive (catalog AD 1200 ≈ 1667) | n/r | 1666 / 1680 / 1670 |
| finery_forges (catalog AD 1350) | n/r | 1794 |
| ratchet_motion_control (catalog 300 BC ≈ 900) | n/r | It was never placed in 0–1200. It is placed here at 1210 as a stop on winches and windlasses. |
| paper_sheet_pressing (catalog AD 800 ≈ 1407) | n/r | 1422, after paper_making (1090) |
| resist_dye_patterning / textile_dye_fixation / investment_casting_process (catalog AD 1738–1747) | n/r | These belong earlier. Their practices are already placed as resist_dyeing (905), alum_mordant_dyeing (530) and lost_wax_casting (195). Re-date the catalog and do not relist them. |
| steel_refining (catalog AD 1856) | 217 | Belongs later (≈ 2210) |
| flyer_spinning (catalog AD 1533) | 189 | Belongs later (≈ 1940) |
| burin_engraving / copperplate_preparation (catalog AD 1430) | n/r / 134 | Belongs later (≈ 1858) |
| bolt_blank_forging (catalog 1000 BC) | n/r | Belongs later: threaded bolts and nuts ≈ AD 1450 (≈ 1875) |
| textile_calendering / multi_spindle_spinning / belt_power_transmission | n/r | Belongs later (catalog AD 1700–1780 → game ≈ 2330–2380) |
| chemical_distillation, wooden_movable_type, printing_process, relief_block_cutting | 57 / — / n/r / n/r | Not placed here. Knowledge owns them (1355–1746). |
