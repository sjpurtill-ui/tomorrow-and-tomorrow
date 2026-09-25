# Historical benchmarks for the 1200–1800 window

This file continues `BENCHMARKS_1200.md` for the third research block, game years 1200–1800 (about AD 360–1360). It is the Phase 3 balance target for that block. The user's direction still applies: "Progression needs to match the year benchmarks in realistic historical human terms. We can't create superhumans just because we progressed so early."

The same numbers are in machine-readable form in `docs/research/benchmarks_1800.json`. It uses the schema of `benchmarks_600.json` and `benchmarks_1200.json`: metric → game year → min / low / typical / high / max.

Year 1200 in the new file repeats `benchmarks_1200.json` exactly for every shared metric, so the files join without a step. Merge them by taking the union of each metric's `years`. Two metrics are new in this window (energy capture and cavalry share); they carry a 1200 row so they interpolate from the join.

## How to read these tables

- **Game years and history.** `TechnologyEras.CURVE` (`[[800,-500],[1500,1000],[2000,1600]]` in `scripts/technology_eras.gd`) places the checkpoints as follows:

  | Game year | 1200 | 1300 | 1400 | 1500 | 1600 | 1700 | 1800 |
  |---|---|---|---|---|---|---|---|
  | Historical year | ≈ AD 360 | ≈ 570 | ≈ 790 | AD 1000 | 1120 | 1240 | 1360 |

  - Between game years 1200 and 1500, one game year covers about 2.14 historical years. After game year 1500 it covers 1.2.
  - People are still born, age and die on the game calendar, so every vital rate is **per game year**.
  - The block squeezes about 1,000 years of history into 600 lived years. Compounded rates such as growth and population therefore stay on the lived clock, not the historical one.
- **Floor / typical / best.** `low` / `typical` / `high` describe poor, ordinary and best-plausible societies of the era. Good play should land between typical and high, and poor play near low.
- **What "best-plausible" means.** It follows the historical arc of the window: the late imperial states and their fragmentation (1200–1300), the early successor kingdoms, steppe confederations and the great caliphal and eastern empires (1300–1500), and the high agrarian expansion with its charters, communes, universities and long-distance trade (1500–1800). It means the best-documented society of that stage, and never beyond it.
- **Min / max** mark the edge of what is historically plausible at all. A simulated value outside them is a balance failure. Only a logged shock may push a value past them, as set out in "Shocks widen the floor" below.
- **The window ends just after the great mortality.** Game 1780–1800 is AD 1340–1360. The plain bands describe a shock-free society; the great pandemic and the great famine before it are handled by `shock_widening`, not by lowering the plain bands.
- **Real history is calibration only.** The JSON contains no real names. The sources below are cited by author and title, and the societies are described generically.

## Vital rates

| Metric (low / typical / high) | 1200 | 1300 | 1400 | 1500 | 1600 | 1700 | 1800 |
|---|---|---|---|---|---|---|---|
| Life expectancy at birth, years | 22 / 28 / 37 | 21 / 27 / 35 | 22 / 28 / 36 | 22 / 28 / 37 | 22 / 29 / 38 | 22 / 29 / 38 | 21 / 28 / 37 |
| Plausible bounds | 18–40 | 18–40 | 18–40 | 18–41 | 18–42 | 18–42 | 18–42 |
| Infant mortality per 1,000 | 300 / 210 / 150 | 310 / 220 / 155 | 300 / 210 / 150 | 300 / 205 / 150 | 290 / 200 / 145 | 290 / 200 / 145 | 300 / 205 / 150 |
| Plausible bounds | 120–390 | 120–400 | 120–390 | 115–380 | 115–380 | 115–380 | 115–390 |
| Child mortality 1–4 per 1,000 (4q1) | 230 / 165 / 110 | 240 / 170 / 115 | 230 / 165 / 110 | 225 / 160 / 108 | 220 / 155 / 105 | 220 / 155 / 105 | 225 / 160 / 108 |
| Maternal deaths per 100,000 births | 1,600 / 1,000 / 650 | 1,650 / 1,050 / 700 | 1,600 / 1,000 / 650 | 1,550 / 1,000 / 650 | 1,500 / 950 / 600 | 1,500 / 950 / 600 | 1,500 / 950 / 600 |
| Maternal floor (min) | 450 | 450 | 450 | 425 | 400 | 400 | 400 |
| Total fertility | 4.3 / 5.3 / 6.3 | 4.3 / 5.3 / 6.3 | 4.3 / 5.3 / 6.3 | 4.3 / 5.2 / 6.2 | 4.2 / 5.2 / 6.2 | 4.2 / 5.1 / 6.1 | 4.0 / 5.0 / 6.0 |
| Crude birth / death rate per 1,000 (typical) | 41 / 38 | 40 / 39 | 40 / 38.5 | 40 / 38 | 40 / 37.5 | 39 / 36.5 | 39 / 37.5 |
| Growth, % per game year | -0.20 / 0.20 / 0.40 | -0.40 / 0.10 / 0.35 | -0.30 / 0.15 / 0.40 | -0.20 / 0.20 / 0.50 | -0.20 / 0.25 / 0.55 | -0.20 / 0.25 / 0.50 | -0.30 / 0.15 / 0.40 |
| Plausible growth bounds | -1.0 to 0.8 | -1.5 to 0.8 | -1.0 to 0.8 | -1.0 to 0.9 | -1.0 to 1.0 | -1.0 to 1.0 | -1.0 to 0.9 |

Why these values:

- **Life expectancy barely moves.** Pre-modern e0 stayed in the 20s and low 30s throughout.
  - Late-imperial provincial census data give e0 of about 20–25 (Bagnall & Frier 1994), and early medieval cemetery series suggest 25–30 (Wood 1998; Chamberlain 2006, *Demography in Archaeology*).
  - High-medieval elites did better but not much: English ducal and tenant-in-chief families had e0 of about 25–33 (Hollingsworth 1977; Russell 1948), and the Westminster monks, a well-fed and well-housed group, had e20 of about 28 further years (Harvey 1993, *Living and Dying in England 1100–1540*).
  - The 1300 dip reflects the first great pandemic wave and the cold decades after 536 (Harper 2017; Büntgen et al. 2016, *Nature Geoscience* 9). The 1800 dip reflects a saturated, famine-prone countryside just before the great mortality (Campbell 2016).
  - The high value rises only from 37 to 38 and the max from 40 to 42. Hospitals, licensing and isolation of the sick raise the ceiling only a little (`MEDICINE_CEILING` 0.35 → 0.45 by historical 1400).
- **Infant, child and maternal mortality.**
  - Medieval infant mortality was about 200–300 per 1,000 and child mortality 1–4 about 150–250 (Shahar 1990, *Childhood in the Middle Ages*; Lewis 2007, *The Bioarchaeology of Children*; Woods 2007 on pre-modern infant mortality).
  - Midwife licensing and foundling houses change outcomes only at the margin. Maternal mortality stays around 1% of births (Loudon 1992); the floor drops only from 450 to 400.
- **Fertility.**
  - Total fertility stays about 5–5.3 until 1600, then eases to about 5.0 by 1800.
  - The low edge falls to 4.0 by 1800. Later marriage and service before marriage appear in the high-medieval north-west (Hajnal 1965; Smith 1981; design item `service_before_marriage` at 1750), and celibate religious communities remove adults from marriage.
- **Growth.**
  - World population rose from about 190–200 million in AD 400 to about 400–450 million before the great mortality (McEvedy & Jones 1978; Livi-Bacci 2017; Maddison project), about 0.07–0.1% per historical year on average.
  - Growth was uneven: near zero or negative in AD 500–700 (pandemic, cold, fragmentation), about 0.1% in 700–1000, and 0.2–0.4% in the high-medieval clearing of 1000–1300, when many European regions doubled or tripled (Russell 1958; Campbell 2016, *The Great Transition*; Broadberry et al. 2015).
  - On the lived game clock that gives typical growth of 0.1% (1300), rising to 0.25% (1600–1700), and falling back to 0.15% (1800). A well-run frontier society reaches about 0.5–0.55% at the peak of clearing.
  - Growth min is −1.5 at 1300, the pandemic and fragmentation century. It is −1.0 elsewhere.

## Settlement and society scale

| Metric (low / typical / high) | 1200 | 1300 | 1400 | 1500 | 1600 | 1700 | 1800 |
|---|---|---|---|---|---|---|---|
| Founders' society population | 100 / 16 k / 600 k | 100 / 18 k / 850 k | 100 / 20 k / 1.2 M | 100 / 25 k / 2 M | 100 / 32 k / 3.5 M | 100 / 41 k / 5.5 M | 100 / 48 k / 8 M |
| Plausible bounds | 30–3 M | 30–4 M | 30–5 M | 30–8 M | 30–12 M | 30–18 M | 30–25 M |
| Largest settlements of the era (historical) | 600 / 12 k / 500 k | 500 / 10 k / 500 k | 500 / 10 k / 800 k | 600 / 12 k / 800 k | 800 / 15 k / 1 M | 800 / 18 k / 1 M | 800 / 18 k / 800 k |
| Largest settlement max | 1 M | 1 M | 1.2 M | 1.2 M | 1.5 M | 1.5 M | 1.5 M |
| Urban share: % living in places of 5,000+ | 3.0 / 12 / 28 | 2.0 / 8.0 / 25 | 2.0 / 8.0 / 25 | 2.0 / 9.0 / 25 | 3.0 / 10 / 28 | 3.0 / 11 / 30 | 3.0 / 12 / 30 |
| Urban share max | 40 | 40 | 40 | 40 | 40 | 45 | 45 |
| Built density, people per hectare | 100 / 200 / 350 | 90 / 180 / 330 | 90 / 180 / 330 | 100 / 200 / 350 | 100 / 200 / 350 | 100 / 200 / 350 | 100 / 200 / 350 |

Why these values:

- **The founders' society.**
  - The typical row compounds the typical growth rates from 16,000 at 1200: 16,000 × e^(Σ rate × 100), using each checkpoint's rate for the century before it. That gives about 48,000 by 1800.
  - The high row compounds the high rates from 600,000 at 1200. That reaches about 8 million by 1800: the size of the largest single kingdoms of the high-medieval west (France was about 16–20 million in 1328; England about 4.5–5 million in 1300; Campbell 2000; Broadberry et al. 2015).
  - The largest empires of the window held 50–120 million (the eastern empire around 1100 had about 100 million; Maddison; Elvin 1973). As in the previous window, they reached that size by absorbing other peoples. The max of 25 M at 1800 assumes the game folds absorbed peoples into the society.
- **Largest settlements.**
  - The old imperial capital shrank from several hundred thousand to a few tens of thousands during the window's first two centuries. The new eastern capital held about 300,000–500,000 by 550 (Krautheimer 1983; Chandler 1987).
  - The eastern imperial and caliphal capitals reached about 0.8–1 million by 800–900. The largest eastern commercial capitals held about 1 million or more between 1100 and 1250 (Chandler 1987; Modelski 2003; Morris 2013).
  - The largest western cities of 1300 held 100,000–200,000 (Paris, Milan, Venice, Florence).
- **Urban share.**
  - Western Europe fell to perhaps 3–5% urban after the fragmentation, recovering to about 8–10% by 1300. Flanders and Tuscany reached 25–35% (Bairoch 1988, *Cities and Economic Development*; de Vries 1984; Malanima 2005).
  - The caliphal heartlands and the eastern empire were about 10–20% urban at their peaks.
- **Density.** Early medieval towns thinned out inside their old walls (about 80–150 per hectare). Walled high-medieval towns held 150–300, and the densest quarters of the largest cities up to 500 (Hohenberg & Lees 1985; Nicholas 1997, *The Growth of the Medieval City*).

## Work, food and productivity

| Metric (low / typical / high) | 1200 | 1300 | 1400 | 1500 | 1600 | 1700 | 1800 |
|---|---|---|---|---|---|---|---|
| Labor time on food, % | 63 / 47 / 35 | 66 / 50 / 37 | 65 / 49 / 36 | 63 / 47 / 35 | 62 / 46 / 34 | 60 / 45 / 33 | 60 / 45 / 32 |
| Food labor, plausible bounds | 28–85 | 28–88 | 28–85 | 26–85 | 25–85 | 25–85 | 25–85 |
| Households not primarily farming, % | 12 / 25 / 40 | 10 / 20 / 35 | 10 / 20 / 35 | 12 / 22 / 38 | 12 / 24 / 40 | 13 / 26 / 42 | 13 / 26 / 42 |
| Grain harvested per seed sown | 4.0 / 9.0 / 16 | 4.0 / 8.0 / 16 | 4.0 / 8.0 / 16 | 4.0 / 8.0 / 16 | 4.0 / 9.0 / 18 | 4.0 / 9.0 / 18 | 4.0 / 9.0 / 18 |
| Largest single project, person-days | 30 k / 1 M / 30 M | 20 k / 500 k / 30 M | 20 k / 500 k / 20 M | 30 k / 1 M / 20 M | 30 k / 1 M / 30 M | 50 k / 2 M / 30 M | 50 k / 2 M / 30 M |
| Largest project max | 100 M | 100 M | 100 M | 100 M | 100 M | 100 M | 100 M |
| Energy capture, kcal per person per day (new) | 15 k / 22 k / 30 k | 14 k / 21 k / 28 k | 14 k / 21 k / 28 k | 15 k / 22 k / 29 k | 15 k / 22 k / 30 k | 15 k / 23 k / 31 k | 15 k / 23 k / 31 k |
| Energy capture, plausible bounds | 8,000–33 k | 8,000–32 k | 8,000–32 k | 8,000–32 k | 8,000–33 k | 8,000–34 k | 8,000–34 k |

Why these values:

- **Food labor.**
  - The fragmentation pushed households back toward self-provisioning, so the 1300 row is worse than 1200.
  - Heavy ploughs, horse collars and horseshoes, three-field rotation, water and wind mills, and quick-ripening rice then cut the time needed for food. About 75–85% of people still lived mainly from farming in most regions (Wickham 2005; Campbell 2000; Broadberry et al. 2015 give an agricultural labor share of about 57% for England in 1381).
- **Non-food households.**
  - The best high-medieval regions (Flanders, Tuscany, the lower Yangzi) reached about 40–45% outside farming. A whole realm reached about 20–30% (Broadberry et al. 2015; Malanima 2005; Elvin 1973).
- **Yields.**
  - Rain-fed northern grain yielded about 1:3–1:5 per seed; the best manors of Artois, Flanders and eastern England yielded 1:8–1:15 (Slicher van Bath 1963; Campbell 2000).
  - Irrigated and double-cropped rice returned far more per seed (1:20–1:30 or more), which sets the max. The typical row stays at 8–9, and the high rises to 18.
- **Construction.**
  - Great churches and castles took about 10⁵–10⁷ person-days each. The domed church of 537 used about 10,000 builders for five years, about 1.5×10⁷ (Mainstone 1988).
  - The largest single work, the 605–611 grand canal, is credited with millions of conscripts, about 10⁸ person-days; it sets the max rather than the high.
  - Typical projects fall to 5×10⁵ in 1300–1400 and rise to 2×10⁶ by 1700–1800, when cathedral building was at its height (Vroom 2010; Knoop & Jones 1967).
- **Energy capture (new).**
  - Morris (2013, *The Measure of Civilization*) puts the western core at about 31,000 kcal per person per day at the imperial peak, about 25,000 by 700, and back to about 27,000–29,000 by 1300. The eastern core rose from about 27,000 to about 29,000–30,000 in the eleventh century.
  - These are core figures, so they set the high. Ordinary agrarian societies ran at about 18,000–24,000, and poor ones at 12,000–15,000.
  - Water and wind mills, draft horses and coal are the main drivers in this window. The 1086 survey counts about 6,000 water mills in England alone (Holt 1988).

## Tools, crafts, knowledge and reach

| Metric (low / typical / high) | 1200 | 1300 | 1400 | 1500 | 1600 | 1700 | 1800 |
|---|---|---|---|---|---|---|---|
| Craft and tool proxies | codified law; domes on pendentives | stirrups; silk; block printing (east) | horse collar; mouldboard plough; algebra | three fields; spinning wheel; porcelain; locks | universities; rib vaults; compass | clocks; windmills; paper mills | blast furnace; black powder (late); pestilence boards |
| Major innovations per century | 1.0 / 2.0 / 4.0 | 1.0 / 2.0 / 4.0 | 1.0 / 2.0 / 4.0 | 2.0 / 3.0 / 5.0 | 2.0 / 3.0 / 5.0 | 2.0 / 4.0 / 6.0 | 2.0 / 3.0 / 5.0 |
| Design items learned per 50-year block, % of that block's targets | 35 / 70 / 90 | 35 / 70 / 90 | 35 / 70 / 90 | 35 / 70 / 90 | 35 / 70 / 90 | 35 / 70 / 90 | 35 / 70 / 90 |
| Discoveries known, cumulative | 730 / 1,460 / 1,880 | 770 / 1,545 / 1,985 | 815 / 1,630 / 2,100 | 870 / 1,745 / 2,240 | 915 / 1,835 / 2,355 | 980 / 1,960 / 2,525 | 1,060 / 2,115 / 2,720 |
| Discoveries known, bounds | 315–2,087 | 330–2,206 | 350–2,331 | 375–2,490 | 395–2,618 | 420–2,803 | 455–3,024 |
| Literacy, % of adults | 1.0 / 5.0 / 10 | 0.50 / 3.0 / 8.0 | 0.50 / 3.0 / 8.0 | 1.0 / 4.0 / 10 | 1.0 / 5.0 / 12 | 1.0 / 6.0 / 15 | 2.0 / 8.0 / 20 |
| Literacy max | 15 | 12 | 12 | 15 | 18 | 22 | 30 |
| Largest force fielded (people) | 500 / 6,000 / 150 k | 500 / 5,000 / 100 k | 400 / 5,000 / 100 k | 500 / 5,000 / 100 k | 500 / 6,000 / 100 k | 500 / 8,000 / 150 k | 500 / 8,000 / 150 k |
| Largest force max | 500 k | 400 k | 400 k | 500 k | 500 k | 600 k | 600 k |
| Peak mobilization, % of all people | 0.50 / 1.5 / 4.0 | 0.30 / 1.2 / 4.0 | 0.30 / 1.0 / 4.0 | 0.30 / 1.0 / 4.0 | 0.30 / 1.0 / 4.0 | 0.30 / 1.2 / 5.0 | 0.30 / 1.2 / 5.0 |
| Peak mobilization max | 10 | 12 | 12 | 12 | 15 | 15 | 15 |
| Mounted share of the largest force, % (new) | 5.0 / 15 / 35 | 5.0 / 18 / 40 | 5.0 / 20 / 40 | 5.0 / 20 / 45 | 5.0 / 20 / 45 | 5.0 / 18 / 40 | 5.0 / 15 / 35 |
| Workers under arms or on watch, % (game Defense) | 2.0 / 5.0 / 10 | 2.0 / 5.0 / 10 | 2.0 / 5.0 / 10 | 2.0 / 5.0 / 10 | 2.0 / 5.0 / 10 | 2.0 / 5.0 / 10 | 2.0 / 5.0 / 10 |
| Trade reach, km | 800 / 3,000 / 9,000 | 600 / 2,500 / 9,000 | 700 / 3,000 / 10 k | 800 / 3,000 / 10 k | 800 / 3,500 / 10 k | 1,000 / 4,000 / 11 k | 1,000 / 4,000 / 12 k |
| Trade reach max | 12 k | 12 k | 13 k | 14 k | 15 k | 16 k | 16 k |
| Institutional reach, km radius | 30 / 150 / 1,500 | 20 / 100 / 1,500 | 20 / 80 / 1,500 | 20 / 80 / 1,200 | 25 / 100 / 1,500 | 25 / 120 / 2,000 | 30 / 150 / 1,500 |
| Institutional reach max | 2,500 | 2,500 | 3,000 | 3,000 | 3,000 | 4,000 | 4,000 |

Why these values:

- **Crafts and machines.**
  - Stirrups reach the west about 600–700; the rigid horse collar and nailed horseshoes spread about 800–1000 (White 1962; Langdon 1986, *Horses, Oxen and Technological Innovation*).
  - Block printing is attested by about 700–800 in the east; paper spreads west through the caliphal lands after 750 (Bloom 2001, *Paper Before Print*).
  - Water-powered fulling, the spinning wheel, windmills (post mills after 1180), mechanical clocks (about 1270–1330) and the western blast furnace (about 1300–1350) close the window (Gimpel 1976, *The Medieval Machine*; Lucas 2006, *Wind, Water, Work*).
- **Major innovations per century.** The early centuries of the window had few new major techniques anywhere (2), and the high-medieval centuries more (3–4), as in Morris's and Mokyr's (1990, *The Lever of Riches*) counts.
- **Literacy.**
  - Western lay literacy fell to about 1–2% after the fragmentation, while the eastern empire and the caliphal cities kept perhaps 5–10% among town men (Harris 1989 for the late imperial baseline; Wickham 2005).
  - Buringh & van Zanden (2009, *J. Econ. Hist.* 69) estimate western literacy from manuscript and book production: about 1% in 1000, rising to about 5–10% by 1300–1400. The eastern examination empire had a literate elite of perhaps 10% of men (Chaffee 1985).
  - The Tuscan towns are the max. Around 1338 one chronicler claims 8,000–10,000 children in Florence's reading schools, which would put town literacy near 30% or more (Black 2007).
- **Armies.**
  - Western field armies were small: 5,000–15,000 for a major campaign, with 20,000–30,000 for the largest royal hosts (Contamine 1984, *War in the Middle Ages*; Verbruggen 1997).
  - The eastern empire kept about 100,000–150,000 soldiers in the ninth century (Treadgold 1995); the eastern and caliphal empires fielded 100,000–500,000 at their peaks. Steppe confederations mobilized 10–15% of all people (May 2007; Allsen 1987), which sets the 15% max.
  - Settled realms mobilized about 0.5–2% of the population. `WAR_MOBILIZATION_CAP` in `tools/sim/shocks/catalog.py` falls from 7% at AD 0 to 3% at 1000 and 4% at 1600, which matches the typical rows.
- **Cavalry share (new).** Late-imperial field armies were about 20–30% mounted; western feudal hosts about 15–40% (knights and mounted sergeants); steppe armies were all mounted, which sets the 100% max. Infantry revived at the window's end (communal militias, pike and longbow), so the typical share falls back to 15% by 1800 (Contamine 1984; Bachrach 2001).
- **Trade.** The monsoon and caravan routes kept the long-distance reach of the imperial age (about 9,000–12,000 km). Under the great steppe empire of the thirteenth century, goods and travellers crossed the whole landmass, about 12,000–16,000 km (Abu-Lughod 1989, *Before European Hegemony*; McCormick 2001, *Origins of the European Economy*). No ocean crossings between continents appear before the window's end.
- **Institutional reach.**
  - After the fragmentation, a western lord's rule reached about 20–80 km; a strong kingdom such as the Frankish empire, about 500–1,000 km (Wickham 2005; Reynolds 1994).
  - The caliphal and eastern empires ruled 2,000–3,000 km radii through post roads and governors. The great steppe empire ruled about 4,000 km, loosely, which sets the max at 1700–1800 (Allsen 1987; Kennedy 2004).

**Innovation pace in the game.** The 1200–1800 design registry (`docs/research/y1200/registry_1800.json`, 937 canonical items, 159 `key_threshold`, not yet baked into `data/research/blocks/`) spreads its items as follows:

| Years | 1200–1249 | 1250–1299 | 1300–1349 | 1350–1399 | 1400–1449 | 1450–1499 | 1500–1549 | 1550–1599 | 1600–1649 | 1650–1699 | 1700–1749 | 1750–1800 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Items targeted | 58 | 61 | 67 | 58 | 83 | 76 | 65 | 63 | 92 | 93 | 108 | 113 |

- Adding the 2,087 items targeted by 1200 gives the cumulative targets: about 2,206 by 1300, 2,331 by 1400, 2,490 by 1500, 2,618 by 1600, 2,803 by 1700 and 3,024 by 1800.
- The "discoveries known" band takes 35% / 70% / 90% of the cumulative target as low / typical / high and about 15% as min, the same rule as the previous window. The max counts every targeted item.
- **Rescale when the block is baked.** If baking changes the item count, recompute the rows as 0.15 / 0.35 / 0.70 / 0.90 / 1.00 × the cumulative target. The 1200 row stays fixed.
- The 21 milestone ids in the JSON are unconditional `key_threshold` items of historical weight: place-value digits with zero, the jurists' digest, paired stirrups, the rigid horse collar, block printing, homage, the mouldboard plough, algebra, ward hospitals, three-field rotation, fiefs for service, the spinning wheel, the couched lance, the chartered university, bills of exchange, the scholastic method, the estates assembly, counterweight engines, the experimental program, the verge-escapement clock and pestilence health boards.
  - Items gated on a resource, coast, river or region are left out so that the milestone check does not fail on the map: porcelain (porcelain clay), silk reeling, the blast furnace (iron ore), black powder (nitre), polders, ocean sailing and quick-ripening rice.

## Allowed lead over history

The rule from the earlier windows carries over: play may lead history "within a reasonable deviation" only if every lead costs something elsewhere.

- **Milestones.** A milestone may land up to 3% of its design year early, but never before `band_low`. Landing after `band_high` is a pacing failure.
  - The fraction drops from 0.05 to 0.03 because `sweep_strategies.py` applies `max(band_low, design × (1 − f))` to absolute game years. At design year 1700, 5% would allow 85 years of lead, while 3% allows 51, which is about one registry band.
  - The block's bands sit 30–45 years below the design year, so `band_low` is still the binding floor in practice.
- **Outcome facets.** The default stays at 15% of |high − typical| above `high`, and `per_metric_over_high_fraction_of_typical_to_high_gap` is unchanged from `benchmarks_1200.json`. The two new metrics get 0.15 (energy capture, a reconstructed index) and 0 (cavalry share, `better: neither`).

| Lead allowed (share of the typical→high gap) | Metrics | Why |
|---|---|---|
| 0.25 | largest project, major innovations, trade reach | order-of-magnitude or count metrics, where the record itself is ±25% |
| 0.20 | literacy, institutional reach | reconstructions vary by a factor of 2 |
| 0.15 | life expectancy, infant / child / maternal mortality, CDR, largest settlement, urban share, food labor, non-food households, yields, per-50 discoveries, energy capture | as in the earlier windows |
| 0.10 | population, growth, discoveries known | compounded or cumulative |
| 0 | TFR, CBR, density, army size, army share, cavalry share, Defense share | `better: neither`. Being above high is a different society, not a better one |

- **Trade-offs added in this window.**
  - **Towns and trade.** Urban share, trade reach and long-distance connections raise pandemic exposure; the great mortality struck ports and towns first.
  - **Mounted war.** A high cavalry share needs fodder and pasture, which costs grain land and food labor.
  - **Bound labor.** Manorial dues and week-work raise lords' surplus and building, at the cost of peasant health, mobility and revolt risk.
  - **Credit.** Bills of exchange and deposit banking raise trade reach and the risk of a credit panic.

## Shocks widen the floor

The JSON block `shock_widening` gives the widening per shock type and per metric, with the same rules as the previous window:

- **How the adjustments are written.** Each adjustment is `<field>_mult` or `<field>_add`, where the field is min, low, typical, high or max. Every adjustment moves the band toward the worse outcome.
- **When they apply.** An adjustment applies only to checkpoints whose window overlaps a shock logged in that run, plus its recovery window. A shock-free run is judged on the plain bands.
- **Combining shocks.** Concurrent shocks multiply their `_mult` values and add their `_add` values. None may pass `hard_floor`: life expectancy 15, population 30, growth −3%/yr, CDR 90.
- **Several peaks.** Where a shock type has more than one peak in the window, `peak_risk_game_years` is a list of [from, to] pairs.

The hazards per game century follow `tools/sim/shocks/catalog.py`, medieval band (historical 500–1450). Game 1200–1270 (AD 360–500) still falls in its classical band. Two keys are new in this window: `invasion_migration` and `upheaval`.

| Shock | Rate per game century | Typical toll |
|---|---|---|
| Collapse (fragmentation) | 0.1–0.4 | 30–50% population loss over a century in the core |
| Pestilence (≥ 5% dead) | 0.5–1.6 | returning plague and smallpox waves |
| Pestilence (≥ 25% dead) | 0.03–0.2 | the two great pandemics |
| Famine (≥ 2% dead) | 0.5–2.0 | the multi-year great famine near the end |
| Credit crisis | 0.4–1.5 | debasements; banking-house failures |
| General war | 0.3–1.0 | |
| Invasion or migration (new key) | 0.15–0.6 | steppe conquests, sea raiders, migrating peoples |
| Upheaval (new key) | 0.2–0.6 | peasant risings, craft revolts, succession wars |

**Pestilence (peak risk about game 1280–1380 and 1780–1800).**

- The first great pandemic (AD 541–549, game about 1285–1290) and its returns over two centuries killed perhaps 25–50% of the people of the eastern Mediterranean in the first wave, though the size is debated (Little (ed.) 2007, *Plague and the End of Antiquity*; Harper 2017; Mordechai & Eisenberg 2019 argue for a smaller toll).
- The great mortality of 1346–1353 (game about 1790–1795) killed about 35–60% in the most affected regions and about a third of western Europe (Benedictow 2004, *The Black Death 1346–1353*; Campbell 2016; Green (ed.) 2014).
- **Widening:**
  - population low × 0.5 (min × 0.55), growth low −0.6 (min −1.0);
  - life expectancy low −5 (min −3), CDR low +25 (max +30);
  - infant mortality low +40, child mortality low +50;
  - urban share × 0.6, largest settlement × 0.5, army size × 0.6, non-food households × 0.8.
- **Recovery** takes 60–200 game years. Populations did not recover their pre-plague levels for a century or more after either pandemic.
- Isolation of arrivals and pestilence boards (design items `pestilence_health_boards` at 1790 and `arrival_isolation_period` at 1797) arrive only at the end. They reduce the toll only a little (`MEDICINE_CEILING` 0.45).

**Collapse by fragmentation (peak risk about game 1220–1320).**

- The western half of the late empire broke into successor kingdoms over AD 400–550 (game about 1220–1290). Tax collection failed, towns shrank to a fraction of their size, coin and long-distance trade dwindled, literacy retreated to the god's houses, and building shrank to wood (Ward-Perkins 2005, *The Fall of Rome and the End of Civilization*; Wickham 2005; Heather 2005).
- **Widening:** population low × 0.6, growth low −0.5 (min −0.8); largest settlement × 0.2, urban share low × 0.3 and typical × 0.6, non-food households × 0.6; literacy low 0 and typical × 0.4; largest project × 0.2, trade reach × 0.4, institutional reach × 0.2; energy capture × 0.85; per-50 discoveries low −15; Defense share high +5.
- **Recovery** takes 80–250 game years. Historically recovery took 300–500 years in the west.

**Invasion or migration (peaks about 1200–1300, 1450–1550 and 1680–1720).**

- Migrating peoples of the fifth and sixth centuries; the sea raiders and horse raiders of the ninth and tenth centuries; the great steppe conquest of the thirteenth century, which destroyed cities and irrigation works and killed a large share of the people in parts of the conquered lands (May 2007; Allsen 1987; the demographic tolls are debated).
- **Widening:** population low × 0.6 (min × 0.7), growth low −0.5; institutional reach × 0.5, largest settlement × 0.5, urban share × 0.7, trade reach × 0.7; peak mobilization max +5; Defense share high and max +10.
- **Recovery** takes 30–150 game years.

**Credit crisis (larger after bills of exchange, about game 1650; peak about 1780–1800).** Coin debasement, runs on money-changers and the failure of the great Tuscan banking houses in the 1340s when a king defaulted (Hunt 1994, *The Medieval Super-Companies*; Spufford 1988, *Money and its Use in Medieval Europe*). The widening is the same as in the previous window; there is no direct effect on vital rates.

**Famine** (the great famine of 1315–1317 is game about 1746–1748; it killed 5–15% in northern Europe; Jordan 1996, *The Great Famine*) takes about 12% of population, cuts life expectancy by 3, adds 40 per 1,000 to infant mortality and 6 points to food labor.

**War** takes about 10% of population, lets peak mobilization rise by 3 points and Defense share by 8, and cuts trade reach to × 0.7 and the largest project to × 0.7.

**Upheaval (peak about 1750–1800).** Peasant risings against dues (1358, 1381), craft revolts against merchant councils (Flanders 1302, Florence 1378) and succession wars (Cohn 2006, *Lust for Liberty*). Widening: institutional reach × 0.7, non-food households × 0.9, largest project × 0.6, growth low −0.2, Defense share high +5.

## What the game must never show before year 1800

These are the "superhuman" signals. Each assumes no logged shock and is measured after the allowed lead.

- **Life.** Life expectancy above about 42, infant mortality below about 115 per 1,000, or maternal mortality below about 400 per 100,000.
- **Growth.** Growth sustained above about 1% a year for a century, or a founders' society above about 25 million.
- **Scale.** A city above about 1.5 million, or an urban share above 45%.
- **Knowledge and people.**
  - Literacy above 30%.
  - More than about 15% of all people under arms (and above 12% for anyone but a steppe people).
  - Trade reach above about 16,000 km (no ocean crossings to other continents).
  - Energy capture above about 34,000 kcal per person per day (no steam, no fossil fuel beyond local coal).
- **Milestones.** Any milestone before its `band_low`. For example: printing before 1315, the mouldboard plough before 1355, the chartered university before 1580, or the mechanical clock before 1692.
- **Weapons.** Gunpowder weapons deciding battles before the window's end. `black_powder` is targeted at 1787, and guns belong to the next window.

## For the surrogate and check tools

- **Loading the file.** Load `benchmarks_600.json`, `benchmarks_1200.json` and this file and merge each metric's `years`. Year 1200 is identical in `benchmarks_1200.json` and this file. For year > 1200, take `milestones.ids` and `allowed_deviation` from this file.
- **New metrics.** `energy_capture_kcal_per_capita_day` and `cavalry_share_of_force_pct` have `probe_key: null`. The focus file maps them to surrogate facets (`labor_efficiency`, `cap_production`; `warfare_readiness`).
- **Registry.** `discoveries_known` and `per_50` need the 1200–1800 block loaded by the catalog (`cat.design_year`, `simlib.milestone_years`, `cat.index`). The block is currently `docs/research/y1200/registry_1800.json` in the `tt-research-plausibility` worktree; it is not yet in `data/research/blocks/`. Until it is baked, the milestone check would skip these ids silently.
- **Check years.** `tune.py` `CHECK_YEARS` must be extended to 1300–1800, and runs must go past `--years 1200`.
- **Shock widening.** `shock_widening` is advisory data that no tool reads yet. The multi-peak `peak_risk_game_years` lists and the two new hazard keys need handling when a tool does read it.

