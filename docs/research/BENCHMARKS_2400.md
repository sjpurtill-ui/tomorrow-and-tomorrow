# Historical benchmarks for the 1800–2400 window

This file continues `BENCHMARKS_1800.md` for the fourth research block, game years 1800–2400 (about AD 1360–1800). It is the Phase 3 balance target for that block. The user's direction still applies: "Progression needs to match the year benchmarks in realistic historical human terms. We can't create superhumans just because we progressed so early."

The same numbers are in machine-readable form in `docs/research/benchmarks_2400.json`, with the schema of the earlier files: metric → game year → min / low / typical / high / max.

Year 1800 repeats `benchmarks_1800.json` exactly for every shared metric (27 of 29; the JSON's `join_1800` block lists them), so the files join without a step. Merge them by taking the union of each metric's `years`. Two metrics are new in this window, state revenue and message speed. They carry a 1800 row of their own so they interpolate from the join.

## How to read these tables

- **Game years and history.** `TechnologyEras.CURVE` (`[[1500,1000],[2000,1600],[2400,1800],[2800,1950],[3000,2030]]` in `scripts/technology_eras.gd`) places the checkpoints as follows:

  | Game year | 1800 | 1900 | 2000 | 2100 | 2200 | 2300 | 2400 |
  |---|---|---|---|---|---|---|---|
  | Historical year | ≈ AD 1360 | ≈ 1480 | 1600 | 1650 | 1700 | 1750 | 1800 |

  - From game 1800 to 2000, one game year covers 1.2 historical years. From 2000 to 2400 it covers only **0.5**: history is stretched, not squeezed, for the first time. The block puts 440 historical years into 600 lived years.
  - People are still born, age and die on the game calendar, so every vital rate is **per game year**. Compounded rates such as growth and population stay on the lived clock. In the stretched half this means 400 lived years of early-modern demographic rates. The typical growth rates are therefore set at the historical per-year rates, not doubled, and the typical population stays small.
- **Floor / typical / best.** `low` / `typical` / `high` describe poor, ordinary and best-plausible societies of the era. Good play should land between typical and high, and poor play near low.
- **What "best-plausible" means.** It follows the historical arc of the window:
  - recovery from the great mortality and the late-medieval crisis (1800–1900);
  - the gunpowder, printing and oceanic transitions (1900–2000);
  - the seventeenth-century general crisis, with its long wars, cold decades, state breakdowns and plague recurrences (2000–2150);
  - the fiscal-military states, the scientific academies and agricultural improvement (2150–2350);
  - the Enlightenment societies at the threshold of steam industry (2350–2400).

  It means the best-documented society of that stage, and never beyond it. Steam factories, railways and industrial mobilization belong to the next window.
- **Min / max** mark the edge of what is historically plausible at all. A simulated value outside them is a balance failure. Only a logged shock may push a value past them, as set out in "Shocks widen the floor" below.
- **Real history is calibration only.** The JSON contains no real names. The sources below are cited by author and title, and the societies are described generically.

## Vital rates

| Metric (low / typical / high) | 1800 | 1900 | 2000 | 2100 | 2200 | 2300 | 2400 |
|---|---|---|---|---|---|---|---|
| Life expectancy at birth, years | 21 / 28 / 37 | 22 / 29 / 37 | 22 / 30 / 38 | 22 / 30 / 38 | 22 / 31 / 39 | 23 / 32 / 40 | 24 / 34 / 41 |
| Plausible bounds | 18–42 | 18–42 | 18–43 | 18–43 | 18–44 | 18–45 | 18–47 |
| Infant mortality per 1,000 | 300 / 205 / 150 | 300 / 205 / 148 | 300 / 205 / 145 | 300 / 205 / 145 | 295 / 200 / 140 | 290 / 195 / 135 | 280 / 185 / 125 |
| Plausible bounds | 115–390 | 115–390 | 110–380 | 110–380 | 105–380 | 100–370 | 90–360 |
| Child mortality 1–4 per 1,000 (4q1) | 225 / 160 / 108 | 225 / 158 / 106 | 222 / 155 / 104 | 222 / 155 / 104 | 220 / 152 / 100 | 215 / 148 / 95 | 210 / 140 / 85 |
| Maternal deaths per 100,000 births | 1,500 / 950 / 600 | 1,500 / 950 / 600 | 1,480 / 925 / 590 | 1,480 / 900 / 575 | 1,450 / 875 / 550 | 1,400 / 825 / 520 | 1,300 / 750 / 450 |
| Maternal floor (min) | 400 | 400 | 390 | 380 | 360 | 340 | 300 |
| Total fertility | 4 / 5 / 6 | 4 / 5 / 6 | 4 / 5 / 6.1 | 4 / 5 / 6.1 | 4 / 5 / 6.2 | 3.9 / 5 / 6.3 | 3.8 / 5 / 6.4 |
| TFR bounds | 3–7.5 | 3–7.5 | 3–7.8 | 3–8 | 3–8 | 2.9–8.2 | 2.7–8.4 |
| Crude birth / death rate per 1,000 (typical) | 39 / 37.5 | 39 / 37 | 39 / 36 | 38 / 37 | 38 / 36 | 38 / 35 | 38 / 34 |
| Growth, % per game year | -0.3 / 0.15 / 0.4 | -0.2 / 0.15 / 0.45 | -0.2 / 0.25 / 0.55 | -0.3 / 0.1 / 0.4 | -0.2 / 0.15 / 0.45 | -0.2 / 0.25 / 0.6 | -0.1 / 0.35 / 0.8 |
| Plausible growth bounds | -1 to 0.9 | -1 to 0.9 | -1 to 1 | -1.2 to 0.9 | -1 to 0.9 | -1 to 1.1 | -1 to 1.4 |

Why these values:

- **Life expectancy rises slowly, and only at the top.**
  - Family reconstitution puts English e0 at about 32–40 from 1540 to 1800. It dipped to the low 30s in the late seventeenth century and passed 38–40 only after 1750 (Wrigley & Schofield 1981, *The Population History of England 1541–1871*; Wrigley, Davies, Oeppen & Schofield 1997, *English Population History from Family Reconstitution*).
  - Most of the continent was worse. France in the 1740s had e0 of about 25, and about 28–33 by the 1790s. Large cities stayed population sinks (Flinn 1981, *The European Demographic System 1500–1820*; Livi-Bacci 2000, *The Population of Europe*).
  - The best groups were the elites and the healthiest rural districts. Peers and ruling families reached e0 of about 45–47 by 1750–1800 (Hollingsworth 1964 on the British peerage). The max therefore rises from 42 to 47, the high only from 37 to 41, and the typical from 28 to 34.
- **Infant and child mortality.**
  - English infant mortality was about 150–190 per 1,000 and fell to about 140 by 1800. France, the German lands and most cities stayed at 200–300 (Wrigley et al. 1997; Flinn 1981).
  - Smallpox made child mortality (1–4) the deadliest age band until inoculation, which entered use in the 1720s and spread widely only after the 1760s. The min falls from 80 to 60, mostly after 2200.
- **Maternal mortality** fell from about 1,000–1,500 per 100,000 in the seventeenth century to about 500–700 in England by 1800. Trained midwives, forceps and fewer high-order births drove the fall. Lying-in hospitals were often worse, because of puerperal fever. The best rural registers reached about 400–500 (Loudon 1992, *Death in Childbirth*; Wrigley et al. 1997).
- **Fertility.** Late marriage and high celibacy in the northwest European pattern held TFR at about 4–5.5 (Hajnal 1965). Early-marrying frontier and colonial populations reached 7–8. The first deliberate decline, among elites and in parts of one large kingdom, appears in the last decades. So the min falls to 2.7 and the max rises to 8.4 at 2400, while the typical stays at 5.
- **Growth.**
  - Plague recurrences kept Europe's population near its 1350s level until about 1450. Recovery then ran at about 0.3–0.5% a year to 1600. The seventeenth-century crisis stalled it, and growth accelerated to 0.5–1% after 1750 (Livi-Bacci 2017, *A Concise History of World Population*; Parker 2013, *Global Crisis*).
  - World population went from about 350–380 million in 1400 to about 900–950 million in 1800 (McEvedy & Jones 1978; Livi-Bacci 2017).
  - The typical row follows that path: 0.15 → 0.25 → 0.1 (the crisis) → 0.35. The high rises to 0.8, and the max to 1.4, the rate of a frontier or colonial society with cheap land and no famine.
  - The min of −1.2 at 2100 marks the general-crisis century. There, war, plague and the cold decades cut some regions by a third.

## Settlement and society scale

| Metric (low / typical / high) | 1800 | 1900 | 2000 | 2100 | 2200 | 2300 | 2400 |
|---|---|---|---|---|---|---|---|
| Founders' society population | 100 / 48,000 / 8 M | 100 / 56,000 / 9 M | 110 / 72,000 / 11 M | 110 / 80,000 / 12 M | 110 / 93,000 / 14 M | 120 / 120,000 / 17 M | 120 / 170,000 / 22 M |
| Plausible bounds | 30–25 M | 30–27 M | 30–30 M | 30–32 M | 30–35 M | 30–45 M | 30–60 M |
| Largest settlements of the era (historical) | 800 / 18,000 / 800,000 | 800 / 18,000 / 800,000 | 800 / 20,000 / 800,000 | 800 / 20,000 / 800,000 | 900 / 22,000 / 900,000 | 900 / 23,000 / 1 M | 1,000 / 25,000 / 1.1 M |
| Largest settlement max | 1.5 M | 1.5 M | 1.5 M | 1.5 M | 1.5 M | 1.5 M | 1.5 M |
| Urban share: % living in places of 5,000+ | 3 / 12 / 30 | 3 / 12 / 30 | 3 / 12 / 32 | 3 / 12 / 35 | 3 / 12 / 35 | 3 / 12 / 36 | 3 / 13 / 38 |
| Urban share max | 45 | 45 | 45 | 45 | 45 | 45 | 48 |
| Built density, people per hectare | 100 / 200 / 350 | 100 / 200 / 350 | 100 / 200 / 350 | 100 / 200 / 350 | 100 / 200 / 380 | 100 / 200 / 400 | 100 / 200 / 400 |

Why these values:

- **The founders' society.**
  - The typical row compounds the typical growth rates from the 1800 join value of 48,000: 48,000 × e^(Σ rate × 100) ≈ 170,000 by 2400.
  - The high row does **not** compound the high rate. Compounding would carry the 1800 high of 8 million past 80 million, which only the largest agrarian empires held.
  - Instead the high follows the best-plausible single realm. It goes from 8 million (a large late-medieval kingdom after the great mortality) to 22 million (a large western monarchy of about 1800, which held 25–29 million).
  - The max of 60 million allows for the conquest and absorption of other peoples by an early-modern empire. The largest agrarian empires, at 150–300 million by 1800, reached that size by absorbing other peoples over millennia (McEvedy & Jones 1978; Maddison 2001, *The World Economy: A Millennial Perspective*).
- **Largest settlements.**
  - The largest cities held about 0.5–1 million throughout: the eastern imperial capitals, the great river capitals, the largest imperial capital on the straits (about 700,000 by 1600), the shogunal capital (about 1 million by 1720) and the largest western capital (about 1 million by 1800).
  - The max therefore holds at 1.5 million, as in the 1800 file. The high rises from 0.8 to 1.1 million (Chandler 1987, *Four Thousand Years of Urban Growth*; Bairoch 1988, *Cities and Economic Development*; de Vries 1984, *European Urbanization 1500–1800*).
- **Urban share.**
  - About 30–40% of people lived in towns of 5,000+ in the most urban regions: the Low Countries at about 1650–1700, and England at about 25–30% by 1800.
  - Europe as a whole was about 10–13% urban, and most agrarian empires were about 5–10% (de Vries 1984; Bairoch 1988; Allen 2000, *European Review of Economic History* 4).
  - The typical value stays at 12–13%, and the high rises to 38%.
- **Density.** Tenement cores of the largest cities held 400–600 per hectare by the eighteenth century, while ordinary towns held 100–250. The high therefore rises to 400 and the max to 600 after 2200.

## Work, food and productivity

| Metric (low / typical / high) | 1800 | 1900 | 2000 | 2100 | 2200 | 2300 | 2400 |
|---|---|---|---|---|---|---|---|
| Labor time on food, % | 60 / 45 / 32 | 60 / 44 / 31 | 60 / 43 / 30 | 60 / 42 / 29 | 59 / 41 / 28 | 59 / 40 / 27 | 58 / 38 / 25 |
| Food labor, plausible bounds | 25–85 | 24–85 | 23–85 | 22–85 | 21–85 | 20–85 | 18–85 |
| Households not primarily farming, % | 13 / 26 / 42 | 13 / 27 / 43 | 13 / 28 / 45 | 13 / 29 / 48 | 14 / 30 / 50 | 14 / 32 / 53 | 15 / 35 / 58 |
| Grain harvested per seed sown | 4 / 9 / 18 | 4 / 9 / 18 | 4 / 9 / 18 | 4 / 9 / 18 | 5 / 9 / 19 | 5 / 10 / 19 | 5 / 10 / 20 |
| Largest single project, person-days (typical / high) | 2×10⁶ / 3×10⁷ | 2×10⁶ / 4×10⁷ | 2×10⁶ / 5×10⁷ | 2×10⁶ / 5×10⁷ | 2×10⁶ / 6×10⁷ | 2.5×10⁶ / 6×10⁷ | 3×10⁶ / 8×10⁷ |
| Largest project max | 10⁸ | 1.5×10⁸ | 2×10⁸ | 2×10⁸ | 2×10⁸ | 2.5×10⁸ | 3×10⁸ |
| Energy captured, kcal per person per day | 15,000 / 23,000 / 31,000 | 15,000 / 23,000 / 31,000 | 15,000 / 24,000 / 32,000 | 15,000 / 24,000 / 32,000 | 15,000 / 25,000 / 34,000 | 15,000 / 26,000 / 36,000 | 16,000 / 27,000 / 38,000 |
| Energy max | 34,000 | 35,000 | 36,000 | 37,000 | 39,000 | 42,000 | 45,000 |

Why these values:

- **Food labor and non-food households.**
  - The farm share of the English workforce fell from about 75% in 1500 to about 55% in 1700 and about 35–40% in 1800. In the Low Countries it was about 40% by 1650. France stayed at about 60–65% in 1789, and most of the world at 70–80% (Allen 2000; Broadberry et al. 2015, *British Economic Growth 1270–1870*; Wrigley 2004 on the occupational structure).
  - The game measures labor time, not heads, so its values run lower than the farm share. The typical falls from 45 to 38 and the high from 32 to 25.
  - The non-food high rises to 58% and the max to 68%.
- **Yields.**
  - Medieval open-field grain yielded about 3–5 : 1. Convertible husbandry, fodder crops and legume rotations raised the best western yields to about 8–12 : 1 by 1700–1800 (Slicher van Bath 1963, *The Agrarian History of Western Europe*; Overton 1996, *Agricultural Revolution in England*).
  - Irrigated rice returned far more per seed. That is why the high and max (20 / 32) sit above the western record.
- **Largest projects.**
  - Bastioned fortress belts, the rebuilt northern frontier wall of the largest eastern empire, the great summit canal of the southern kingdom (about 12,000 workers for 15 years) and the largest palace complex (tens of thousands of workers over decades) each took about 10⁷–10⁸ person-days (Parker 1988, *The Military Revolution*; Mukerji 2009, *Impossible Engineering*).
  - The max rises to 3×10⁸ to allow for a whole grand-canal restoration or wall programme.
- **Energy capture.**
  - The western core rose from about 26,000–27,000 kcal per person per day around 1400–1500 to about 32,000 by 1700 and about 38,000 by 1800. The eastern core was at about 33,000–36,000 by 1800 (Morris 2013, *The Measure of Civilization*; Malanima 2006 on energy consumption in pre-industrial Europe).
  - Coal-burning regions ran above that. The max therefore reaches 45,000 at 2400. The typical rises only from 23,000 to 27,000, because peasant economies stayed near the organic-economy ceiling (Wrigley 2010, *Energy and the English Industrial Revolution*).

## Tools, crafts, knowledge and reach

| Metric (low / typical / high) | 1800 | 1900 | 2000 | 2100 | 2200 | 2300 | 2400 |
|---|---|---|---|---|---|---|---|
| Craft and tool proxies | blast furnace; cannon; spectacles; mechanical clock | movable metal type; carvel ships; matchlock | bastion forts; telescope (end); ocean crossings | microscope; pendulum clock; calculus; air pump | coke smelting; atmospheric engine; flying shuttle | spinning frames; chronometer; inoculation | separate-condenser engine; mule; optical telegraph |
| Major innovations per century (world) | 2 / 3 / 5 | 2 / 4 / 6 | 3 / 5 / 8 | 3 / 6 / 9 | 3 / 6 / 9 | 4 / 7 / 10 | 4 / 8 / 11 |
| Design items learned per 50-year block, % of that block's targets | 35 / 70 / 90 | 35 / 70 / 90 | 35 / 70 / 90 | 35 / 70 / 90 | 35 / 70 / 90 | 35 / 70 / 90 | 35 / 70 / 90 |
| Discoveries known, cumulative | 1,060 / 2,115 / 2,720 | 1,120 / 2,245 / 2,885 | 1,185 / 2,370 / 3,045 | 1,245 / 2,495 / 3,210 | 1,310 / 2,620 / 3,370 | 1,375 / 2,745 / 3,530 | 1,435 / 2,875 / 3,695 |
| Discoveries known, bounds | 455–3,024 | 480–3,204 | 510–3,384 | 535–3,564 | 560–3,744 | 590–3,924 | 615–4,104 |
| Literacy, % of adults | 2 / 8 / 20 | 2 / 9 / 22 | 2 / 11 / 27 | 2 / 13 / 32 | 3 / 15 / 37 | 3 / 18 / 45 | 4 / 22 / 55 |
| Literacy max | 30 | 32 | 40 | 48 | 56 | 70 | 80 |
| Largest force fielded (people) | 500 / 8,000 / 150,000 | 500 / 9,000 / 150,000 | 800 / 12,000 / 200,000 | 1,000 / 15,000 / 250,000 | 1,000 / 20,000 / 350,000 | 1,500 / 25,000 / 400,000 | 2,000 / 30,000 / 600,000 |
| Largest force max | 600,000 | 600,000 | 650,000 | 700,000 | 800,000 | 900,000 | 1.5 M |
| Peak mobilization, % of all people | 0.3 / 1.2 / 5 | 0.3 / 1.2 / 4 | 0.4 / 1.5 / 4 | 0.5 / 1.5 / 4.5 | 0.5 / 1.5 / 4.5 | 0.5 / 1.8 / 4.5 | 0.5 / 2 / 5 |
| Peak mobilization max | 15 | 12 | 10 | 12 | 12 | 12 | 14 |
| Mounted share of the largest force, % | 5 / 15 / 35 | 5 / 20 / 40 | 5 / 20 / 35 | 5 / 20 / 35 | 5 / 18 / 30 | 5 / 16 / 28 | 5 / 15 / 25 |
| Workers under arms or on watch, % (game Defense) | 2 / 5 / 10 | 2 / 5 / 10 | 2 / 5 / 10 | 2 / 5 / 10 | 2 / 5 / 10 | 2 / 5 / 10 | 2 / 5 / 11 |
| Trade reach, km | 1,000 / 4,000 / 12,000 | 1,000 / 4,500 / 13,000 | 1,000 / 5,500 / 16,000 | 1,100 / 6,000 / 18,000 | 1,200 / 7,000 / 20,000 | 1,500 / 8,000 / 20,000 | 1,500 / 10,000 / 22,000 |
| Trade reach max | 16,000 | 16,000 | 25,000 | 25,000 | 25,000 | 25,000 | 25,000 |
| Institutional reach, km radius | 30 / 150 / 1,500 | 30 / 160 / 1,800 | 30 / 180 / 2,500 | 35 / 200 / 3,000 | 40 / 220 / 3,500 | 40 / 250 / 4,000 | 40 / 300 / 5,000 |
| Institutional reach max | 4,000 | 4,000 | 10,000 | 12,000 | 15,000 | 15,000 | 18,000 |
| State revenue, % of output (new) | 1.5 / 4 / 8 | 1.5 / 4 / 9 | 2 / 5 / 10 | 2 / 5 / 11 | 2 / 6 / 12 | 2 / 6 / 13 | 2 / 7 / 15 |
| State revenue max | 12 | 13 | 15 | 17 | 18 | 20 | 24 |
| Official message speed, km/day (new) | 25 / 40 / 150 | 25 / 45 / 160 | 30 / 50 / 180 | 30 / 55 / 180 | 30 / 60 / 200 | 35 / 70 / 220 | 40 / 80 / 250 |
| Message speed max | 300 | 300 | 350 | 350 | 350 | 400 | 3,000 |

Why these values:

- **Innovation pace.** This window holds more of history's major innovations than any before it: gunpowder artillery and hand firearms, movable metal type and the screw press, ocean-going full-rigged ships and oceanic navigation, the telescope, microscope, pendulum clock, barometer and air pump, the calculus, coke smelting, the atmospheric and then the separate-condenser engine, and mechanized spinning.
  - The per-century count therefore rises from 3 to 8 typical and to 15 max. As in the earlier files, this is per historical century.
- **Literacy.**
  - Signature literacy in England rose from about 10–20% of men around 1500 to about 30% (men) by 1640, about 45% by 1700, and about 60% of men and 40% of women by 1800 (Cressy 1980, *Literacy and the Social Order*; Houston 2002, *Literacy in Early Modern Europe*).
  - The Low Countries and the reading campaigns of some northern churches reached 70–90% reading ability. France was about 37% in the 1780s, and most of eastern and southern Europe was under 20%. Male literacy in the island realm of the far east was about 40–50% by 1800.
  - Book production grew about a hundredfold after printing (Buringh & van Zanden 2009, *Journal of Economic History* 69).
  - The high therefore rises from 20 to 55 and the max from 30 to 80, while the typical rises only from 8 to 22.
- **Armies.**
  - Late-medieval royal armies had about 10,000–30,000 men. The largest western monarchy kept about 150,000 in the 1630s and about 350,000–400,000 by 1700–1710 (Lynn 1997, *Giant of the Grand Siècle*). Revolutionary and imperial armies passed 1 million by 1794–1812. The largest eastern empires held 0.5–1 million men in their standing forces (Parker 1988).
  - The max therefore reaches 1.5 million at 2400. The high is 600,000, the largest force of a strong realm in the 1790s.
  - Peak mobilization was 1–3% of population in most states. A small northern kingdom under constant war and one militarized eastern kingdom reached 4–7%, and the mass levy of 1793–1794 reached about 3–4% of a much larger population.
  - The high therefore rises from 4 to 5 and the max to 14. The catalog's `WAR_MOBILIZATION_CAP` (4% at 1600 and 7% at 1790 in `tools/sim/shocks/catalog.py`) agrees.
- **Cavalry.** Heavy cavalry made up about 20–30% of European field armies in the sixteenth century, and about 15–25% after pike-and-shot and then the bayonet (Parker 1988). Steppe and frontier forces stayed almost entirely mounted. So the typical falls from 20 to 15 and the high from 40 to 25, while the max stays at 100.
- **Trade reach.**
  - At the join, goods crossed the old world by sea lanes and caravan routes, about 10,000–16,000 km.
  - From about game 1950 the oceanic crossings joined every inhabited continent. The galleon and cape routes carried silver, spices and textiles 15,000–25,000 km, and the max of 25,000 km is a route half-way round the world (Findlay & O'Rourke 2007, *Power and Plenty*; Crosby 1972, *The Columbian Exchange*).
- **Institutional reach.**
  - Late-medieval kingdoms enforced rulings about 300–600 km from the court, and the largest eastern empire about 2,000 km.
  - Oceanic empires collected dues and enforced royal justice in viceroyalties 9,000–15,000 km from the court, with a year's lag. Registers, intendants and censuses deepened control at home. The max therefore jumps to 10,000 at 2000 and reaches 18,000 by 2400 (Elliott 2006, *Empires of the Atlantic World*; Bayly 1989, *Imperial Meridian*).
- **State revenue (new).**
  - Late-medieval crowns took about 1–4% of output in ordinary years. By the eighteenth century the leading fiscal-military state took about 10–12% in peace and over 20% in war, and the Low Countries' provinces were similar. The largest western monarchy took about 7–10%. The great agrarian empires of the east took only about 2–4% (Brewer 1989, *The Sinews of Power*; Bonney 1999, *The Rise of the Fiscal State in Europe*; Karaman & Pamuk 2010, *Journal of Economic History* 70; Dincecco 2011, *Political Transformations and Public Finances*).
  - The typical rises from 4 to 7, the high from 8 to 15 and the max to 24.
  - In the game this corresponds to `state_capacity` and `cap_institutions`, so `probe_key` is null.
- **Message speed (new).**
  - Ordinary letters and news moved about 30–60 km a day by foot and horse post. Relay couriers of great states and merchant houses made 150–250 km a day, and exceptional relays up to about 300 (Braudel 1972, *The Mediterranean*, on the speed of news; Behringer 2003 on the imperial post).
  - The optical telegraph of the 1790s carried short official messages hundreds of km in hours. It is the only reason the 2400 max jumps to 3,000 km/day; the high stays at 250. The design registry places it at about game 2390 (`shutter_signal_frames`).

**Innovation pace in the game.** The 1800–2400 design registry (`docs/research/y1800/registry_2400.json`, then `data/research/blocks/y1800_2400.json`) did not exist when this file was written.

- The cumulative targets therefore take the 3,024 items targeted by 1800 (1,123 + 964 + 937, the same count the 1800 file uses). To that they add about 1,080 new items (12 lines × about 90, the size the list brief asks for), spread evenly at about 90 per 50-year block.
- That gives about 3,204 by 1900, 3,384 by 2000, 3,564 by 2100, 3,744 by 2200, 3,924 by 2300 and 4,104 by 2400.
- The "discoveries known" band takes 15% / 35% / 70% / 90% / 100% of the cumulative target as min / low / typical / high / max. That is the rule of the earlier files, and it matches the per-50 band.
- **Regenerate** `discoveries_known` (the generator is parameterised on the count) once the 1800–2400 registry exists. Rebucket by its actual 50-year counts, and use the registry block to replace the provisional milestone list.
- **Provisional milestones.** The 17 milestone ids in the JSON are existing game catalog ids (`scripts/*_knowledge.gd`, `technology_eras.gd` `HISTORICAL_YEAR`) whose calibration year falls in the window, and none is gated on a resource or coast as far as the catalog shows:
  - pike drill; screw-press printing; matchlock drill; comparative anatomy; symbolic algebra; measured kinematics; logarithms;
  - coordinate geometry; probability theory; differential calculus; precision thermometry; flying shuttles;
  - biological classification; multi-spindle spinning; cylinder boring; feedback governors; statistical inference.
  - Coke firing (needs coal), naval gunnery and carvel construction (probably need a coast) are left out.

## Allowed lead over history

The rule of the earlier windows carries over: play may lead history "within a reasonable deviation" only if every lead costs something elsewhere.

- **Milestones.** A milestone may land up to **2%** of its design year early, but never before `band_low`. Landing after `band_high` is a pacing failure.
  - At design years 1800–2400, the 1800 file's 3% would allow 54–72 game years, and 5% would allow 90–120. From game 2000, one game year is only half a historical year, so even 2% (36–48 game years) is 18–24 historical years of lead. In practice `band_low` is the binding floor, as in the earlier windows.
- **Outcome facets.** The default stays at 15% of |high − typical| above `high`. `per_metric_over_high_fraction_of_typical_to_high_gap` sets it per metric:

| Lead allowed (share of the typical→high gap) | Metrics | Why |
|---|---|---|
| 0.25 | largest project, major innovations, trade reach, message speed | order-of-magnitude or count metrics, where the record itself is ±25% |
| 0.20 | literacy, institutional reach | reconstructions vary widely (signature literacy against reading literacy; nominal against effective rule) |
| 0.15 | life expectancy, infant / child / maternal mortality, CDR, largest settlement, urban share, food labor, non-food households, yields, per-50 discoveries, energy capture, state revenue | same as the earlier windows |
| 0.10 | population, growth, discoveries known | compounded or cumulative. Leading on them for 600 lived years multiplies, so the margin is tighter |
| 0 | TFR, CBR, density, army size, army share, Defense share, cavalry share | `better: neither`. Being above high is a different society, not a better one |

- **Trade-offs.** The trade-offs of the earlier windows still apply: cities cost life expectancy, armies cost food labor and growth, and credit raises crisis risk. This window adds four more:
  - **Oceanic reach** imports new diseases, and contact exposes isolated peoples to virgin-soil epidemics.
  - **Fiscal extraction** above about 10% of output raises revolt and revolution risk and costs rural growth.
  - **Funded debt** and share trading raise financial-panic risk.
  - **Enclosure and improvement** raise yields but displace smallholders. Stature and child survival fell in the late eighteenth century even in the most improved economy (Komlos 1998, *Journal of Economic History* 58).

## Shocks widen the floor

The JSON block `shock_widening` gives the widening per shock type and per metric. It works as in the earlier files:

- Each adjustment is `<field>_mult` or `<field>_add`, and every adjustment moves the band toward the worse outcome.
- An adjustment applies only to checkpoints whose window overlaps a logged shock and its recovery. A shock-free run is judged on the plain bands.
- Concurrent shocks multiply their `_mult` values and add their `_add` values. None may pass `hard_floor`: life expectancy 15, population 30, growth −3%/yr, CDR 90.
- `hazard_key_for_type` maps each shock type to the hazard key that focus files scale with `shock_hazard_mult`.

The hazards per game century are the `tools/sim/shocks/catalog.py` "medieval" group, which the catalog also uses for the early-modern band, plus its upheaval row. The rates are per historical century. From game 2000 a game century covers only 50 historical years, so a run near the top of a range is already shock-heavy.

| Shock (hazard key) | Rate per game century | Typical toll |
|---|---|---|
| Pandemic wave (`pandemic_ge_5pct`) | 0.5–1.6 | 10–20% in a bad wave, up to half of a city |
| Great pandemic or contact epidemic (`pandemic_ge_25pct`) | 0.03–0.2 | 25–90% |
| Famine (`famine_ge_2pct`) | 0.5–2.0 | 2–10% |
| Financial panic (`economic_crisis`) | 0.4–1.5 | no direct deaths |
| General war (`general_war`) | 0.3–1.0 | 5–40% regionally over a generation |
| Invasion (`invasion_migration`) | 0.1–0.4 | falls away after about 2200 |
| Revolution (`upheaval`) | 0.2–0.6 | institutional, not demographic |
| State collapse (`collapse`) | 0.1–0.4 | 20–35% |

- **Plague recurrences and new crowd diseases (pandemic wave, peak risk 1800–2200).**
  - After the great mortality, plague returned every 10–20 years for three centuries. Major urban outbreaks killed 20–50% of a city: the northern capitals in 1603, 1625 and 1665, and the southern trading cities in 1630 and 1656.
  - Typhus, the sweating sickness and smallpox added to the toll. The last large western outbreaks were in the 1720s and 1740s (Benedictow 2004, *The Black Death*; Slack 1985, *The Impact of Plague in Tudor and Stuart England*; Alfani 2013, *European Review of Economic History* 17).
  - **Widening:** population low × 0.75, life expectancy low −4, CDR low +15, infant and child mortality low +40, and urban share, largest settlement and army size × 0.7.
- **Contact epidemic (peak risk 2000–2400).**
  - When oceanic contact reached peoples with no exposure to old-world crowd diseases, smallpox, measles and influenza killed 50–90% of them over a century (Crosby 1972; Livi-Bacci 2008, *Conquest*; Cook 1998, *Born to Die*).
  - It applies only to a run whose shock log records such a contact. Population low × 0.2 is the deepest widening in any window. This is why the focus file gives isolated peoples ×2 on `pandemic_ge_25pct`.
- **Famine (all window).** The coldest decades of the little ice age, such as the 1590s and 1690s, and volcanic summers caused repeated failures. The 1690s famines killed 10–15% in parts of the northwest (Parker 2013; Appleby 1978 on English famine). The entry repeats the 1200 file's: population × 0.9, life expectancy −2 and infant mortality +30.
- **War (all window).**
  - Confessional and succession wars were long. The worst, 1618–1648, cost the German lands 20–40% of their people, mostly through camp disease and famine (Wilson 2009, *Europe's Tragedy*; Outram 2002).
  - **Widening:** population low × 0.8, growth −0.3, peak mobilization +4, Defense share +8, trade reach × 0.7, life expectancy −2.
  - Industrial mass mobilization is not in this window. The `WAR_MOBILIZATION_CAP` reaches 7% only at 1790.
- **Financial panic (peak risk 2000–2400).**
  - One great empire defaulted on its crown debt in 1557, 1560, 1575, 1596, 1607, 1627 and 1647. The 1720 share bubbles collapsed in two capitals in the same year (Reinhart & Rogoff 2009, *This Time Is Different*; Kindleberger 1978, *Manias, Panics and Crashes*; Drelichman & Voth 2014, *Lending to the Borrower from Hell*).
  - **Widening:** non-food households × 0.85, largest project × 0.5, trade and institutional reach × 0.8, army size × 0.7, state revenue × 0.6.
- **Revolution (peak risk 2100–2400).**
  - The great peasant wars of 1381 and 1524–1525 fall at game years about 1818 and 1937. Mid-seventeenth-century civil wars and regime crises came in 1640–1660 (game 2080–2120), and the revolutions of 1776–1799 at game years 2352–2398 (Goldstone 1991, *Revolution and Rebellion in the Early Modern World*).
  - **Widening:** institutional reach and state revenue × 0.5, largest project × 0.5, peak mobilization +3 (revolutionary levies), and growth −0.2.
- **State collapse (peak risk 2050–2150).**
  - A dynastic breakdown in the largest eastern empire, combining rebellion, invasion and famine in 1628–1683, cost it perhaps a fifth to a third of its people (Parker 2013; Marks 2012).
  - **Widening:** population low × 0.6, institutional reach and state revenue × 0.3, trade reach × 0.6, urban share × 0.6, largest project × 0.3.
- **Invasion (peak risk 1800–2100).** Mounted conquests and frontier migrations continued into the seventeenth century. The last great steppe confederation was destroyed in the 1750s. The widening is milder than in the 1800 file: population × 0.7 and institutional reach × 0.5.

## What the game must never show before year 2400

These are the "superhuman" signals. Each assumes no logged shock and is measured after the allowed lead.

- **Life.** Life expectancy above about 47, infant mortality below about 90 per 1,000, maternal mortality below about 300 per 100,000, or child mortality (1–4) below about 60.
- **Growth.** Growth sustained above about 1.4% a year for a century, or a founders' society above about 60 million.
- **Scale.** A city above about 1.5 million, or an urban share above about 48%.
- **Knowledge and people.**
  - Literacy above about 80%.
  - More than about 14% of all people under arms, or a force above 1.5 million.
  - State revenue above about 24% of output in an ordinary year.
  - Energy capture above about 45,000 kcal per person per day. That would mean steam industry and coal on a nineteenth-century scale.
  - Trade reach above 25,000 km.
  - Official messages faster than about 400 km/day before `shutter_signal_frames` (optical telegraph).
- **Milestones.** Any milestone before its `band_low`. Calculus before about 2100, flying shuttles before about 2230, or feedback governors before about 2340 would be flagged even before the registry sets its bands.
- **Effects.** Any effect total above its era ceiling (`SocietyModel.era_ceiling_for`). The catalog's `MEDICINE_CEILING` interpolates from 0.45 at AD 1400 to about 0.76 at AD 1800. Inoculation and quarantine help, but health knowledge alone never makes a run immune to a logged pandemic wave.

## For the surrogate and check tools

- **Loading the file.** `tools/sim/facets.py` and `tools/research/benchmark_report.py` still read only `benchmarks_600.json`.
  - To use this window, load all four base files and merge each metric's `years`. Years 1200 and 1800 are identical across the joins.
  - For year > 1800, take `milestones.ids` and `allowed_deviation` from this file.
- **New metrics.** `state_revenue_pct_output` and `message_speed_km_per_day` have `probe_key: null`. They are judged by proxy: `state_capacity` / `cap_institutions` and `cap_logistics` (focus file `surrogate_proxies`). Energy capture and cavalry share come from the 1800 file.
- **Check years.** `tune.py` `CHECK_YEARS` and the sweep runs must reach 1900–2400, and the runs must go past `--years 1800`.
- **Per-metric leads.** As noted in the 1200 file, `facets.flag` should prefer `per_metric_over_high_fraction_of_typical_to_high_gap[metric]`. `sweep_strategies.py`'s `high × (1 + margin)` test should be aligned with `high + margin × |high − typical|`.
- **Shock widening.** `shock_widening` is advisory data, and no tool reads it yet. `hazard_key_for_type` is new here. It lets a shock layer map a logged shock type to the hazard key that the focus files scale.
- **Registry.** Regenerate `discoveries_known` and `milestones` from the 1800–2400 registry when it lands. The generator's registry count is the only input that needs to change.
