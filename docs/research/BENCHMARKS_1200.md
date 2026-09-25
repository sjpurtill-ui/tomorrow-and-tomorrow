# Historical benchmarks for the 600–1200 window

This file continues `BENCHMARKS_600.md` for the second research block, game years 600–1200. It is the Phase 3 balance target for that block. The user's direction still applies: "Progression needs to match the year benchmarks in realistic historical human terms. We can't create superhumans just because we progressed so early."

The same numbers are in machine-readable form in `docs/research/benchmarks_1200.json`. It uses the schema of `benchmarks_600.json`: metric → game year → min / low / typical / high / max.

Year 600 in the new file repeats `benchmarks_600.json` exactly for every shared metric, so the two files join without a step. Merge them by taking the union of each metric's `years`.

## How to read these tables

- **Game years and history.** `TechnologyEras.CURVE` places the checkpoints as follows:

  | Game year | 600 | 700 | 800 | 900 | 1000 | 1100 | 1200 |
  |---|---|---|---|---|---|---|---|
  | Historical year | 1500 BCE | 1000 BCE | 500 BCE | ≈ 290 BCE | ≈ 70 BCE | ≈ 140 CE | ≈ 360 CE |

  - Between game years 600 and 800, one game year covers five historical years. After game year 800 it covers about 2.1.
  - People are still born, age and die on the game calendar, so every vital rate is **per game year**.
  - The block squeezes about 1,860 years of history into 600 lived years. Compounded rates such as growth and population therefore stay on the lived clock, not the historical one.
- **Floor / typical / best.** `low` / `typical` / `high` describe poor, ordinary and best-plausible societies of the era. Good play should land between typical and high, and poor play near low.
- **What "best-plausible" means.** It follows the historical arc of the window, from the late palace states, through the post-collapse village world, to the classical city-states, and then the large territorial and imperial states. It means the best-documented society of that stage, and never beyond it.
- **Min / max** mark the edge of what is historically plausible at all. A simulated value outside them is a balance failure. Only a logged shock may push a value past them, as set out in "Shocks widen the floor" below.
- **Real history is calibration only.** The JSON contains no real names. The sources below are cited by author and title, and the societies are described generically.

## Vital rates

| Metric (low / typical / high) | 600 | 700 | 800 | 900 | 1000 | 1100 | 1200 |
|---|---|---|---|---|---|---|---|
| Life expectancy at birth, years | 22 / 28 / 35 | 21 / 27 / 34 | 22 / 28 / 35 | 22 / 28 / 36 | 22 / 28 / 36 | 22 / 28 / 37 | 22 / 28 / 37 |
| Plausible bounds | 18–38 | 18–38 | 18–39 | 18–40 | 18–40 | 18–40 | 18–40 |
| Infant mortality per 1,000 | 300 / 220 / 160 | 310 / 230 / 165 | 300 / 220 / 160 | 300 / 215 / 155 | 300 / 210 / 150 | 300 / 210 / 150 | 300 / 210 / 150 |
| Plausible bounds | 130–380 | 130–400 | 125–380 | 120–380 | 120–380 | 120–380 | 120–390 |
| Child mortality 1–4 per 1,000 (4q1) | 230 / 170 / 120 | 240 / 175 / 125 | 230 / 170 / 120 | 225 / 165 / 115 | 225 / 160 / 110 | 225 / 160 / 110 | 230 / 165 / 110 |
| Maternal deaths per 100,000 births | 1,700 / 1,150 / 800 | 1,750 / 1,200 / 850 | 1,700 / 1,150 / 800 | 1,650 / 1,100 / 750 | 1,600 / 1,050 / 700 | 1,600 / 1,000 / 700 | 1,600 / 1,000 / 650 |
| Maternal floor (min) | 500 | 500 | 500 | 475 | 450 | 450 | 450 |
| Total fertility | 4.5 / 5.6 / 6.5 | 4.5 / 5.5 / 6.5 | 4.5 / 5.5 / 6.5 | 4.4 / 5.4 / 6.4 | 4.3 / 5.3 / 6.3 | 4.3 / 5.3 / 6.3 | 4.3 / 5.3 / 6.3 |
| Crude birth / death rate per 1,000 (typical) | 42 / 37 | 42 / 38 | 42 / 37 | 41 / 37 | 41 / 37 | 41 / 37 | 41 / 38 |
| Growth, % per game year | −0.2 / 0.3 / 0.8 | −0.3 / 0.15 / 0.5 | −0.2 / 0.3 / 0.7 | −0.2 / 0.3 / 0.7 | −0.2 / 0.3 / 0.6 | −0.2 / 0.25 / 0.5 | −0.2 / 0.2 / 0.4 |
| Plausible growth bounds | −1.0 to 1.3 | −1.5 to 1.2 | −1.0 to 1.2 | −1.0 to 1.1 | −1.0 to 1.0 | −1.0 to 0.9 | −1.0 to 0.8 |

Why these values:

- **Life expectancy stays flat.** Classical societies did not live longer than Bronze Age ones.
  - The best-recorded classical population, a census-registered imperial province, had e0 of about 20–25 (Bagnall & Frier 1994, *The Demography of Roman Egypt*).
  - Classical Mediterranean populations generally fit Coale–Demeny West levels 2–6, e0 about 20–30 (Frier 2000, *CAH* XI ch. 27; Scheidel 2001, "Roman age structure", *JRS* 91; Scheidel 2012, *Cambridge Companion to the Roman Economy* ch. 5).
  - Big cities were population sinks because of the "urban graveyard" effect (Scheidel 2003, "Germs for Rome"; Hopkins 1978, *Conquerors and Slaves*).
  - The high value rises only slowly, from 35 to 37, and the max stays at 40. These track the gains from medical schools, trained midwives and clean water (aqueducts, siphons), which reach mainly rural and elite households.
  - The 700 dip reflects the post-collapse world.
- **Infant, child and maternal mortality.**
  - Classical infant mortality was about 200–300 per 1,000, and roughly half of all children died before age 10 (Volk & Atkinson 2013; Frier 2000; Saller 1994, *Patriarchy, Property and Death in the Roman Family*).
  - The first midwifery manuals and gynecological treatises of the classical era did not change maternal outcomes much. Pre-modern maternal mortality remained about 1–1.5% of births (Loudon 1992; Chamberlain 2006).
  - The floor therefore drops only from 500 to 450.
- **Fertility.**
  - Total fertility stays at about 5–6 (Bagnall & Frier 1994 give TFR ≈ 6 for the imperial province).
  - The low edge falls to about 4.3 and the min to 3.0 because urban elites of the late classical era limited family size. The state answered with marriage-incentive laws and child-support funds (design items `marriage_incentive_laws` at 1033 and `alimentary_child_funds` at 1050).
- **Growth.**
  - Long-run growth over the whole window was about 0.1% per historical year. Over 1500 BCE–400 CE, world population rose from about 50 million to about 200 million (Livi-Bacci 2017; McEvedy & Jones 1978, *Atlas of World Population History*).
  - On the lived game clock this allows typical growth of about 0.2–0.3% per game year.
  - A well-run society expanding into open or conquered land can reach about 0.5–0.7%. That rate was seen in colonization waves and in the growth of classical core regions (Scheidel 2007, *Cambridge Economic History of the Greco-Roman World* ch. 3; Morris 2004 on growth of the classical Aegean).
  - The high value falls to 0.4 by 1200 because the late imperial era was demographically saturated.
  - Growth min is −1.5 at 700, the collapse window: a century that loses about 75% of its people. It is −1.0 elsewhere.

## Settlement and society scale

| Metric (low / typical / high) | 600 | 700 | 800 | 900 | 1000 | 1100 | 1200 |
|---|---|---|---|---|---|---|---|
| Founders' society population | 100 / 3,500 / 20,000 | 80 / 4,000 / 33,000 | 100 / 5,500 / 65,000 | 120 / 7,500 / 130,000 | 120 / 10,000 / 240,000 | 110 / 13,000 / 400,000 | 100 / 16,000 / 600,000 |
| Plausible bounds | 30–60,000 | 30–150,000 | 30–300,000 | 30–600,000 | 30–1.2 M | 30–2 M | 30–3 M |
| Largest settlements of the era (historical) | 500 / 5,000 / 60,000 | 300 / 4,000 / 60,000 | 500 / 6,000 / 100,000 | 500 / 8,000 / 200,000 | 600 / 10,000 / 400,000 | 600 / 12,000 / 600,000 | 600 / 12,000 / 500,000 |
| Largest settlement max | 80,000 | 100,000 | 200,000 | 400,000 | 600,000 | 1,000,000 | 1,000,000 |
| Urban share: % living in places of 5,000+ (new) | 0 / 8 / 20 | 0 / 5 / 15 | 1 / 8 / 20 | 2 / 10 / 25 | 2 / 12 / 28 | 3 / 12 / 30 | 3 / 12 / 28 |
| Urban share max | 35 | 30 | 35 | 40 | 40 | 40 | 40 |
| Built density, people per hectare | 100 / 180 / 300 | 80 / 160 / 280 | 100 / 180 / 300 | 100 / 200 / 350 | 100 / 200 / 350 | 100 / 200 / 350 | 100 / 200 / 350 |

Why these values:

- **The founders' society.**
  - The typical row compounds the typical growth rates: 3,500 × e^(Σ rate × 100).
  - The high row compounds the high rates from 20,000 at year 600. That reaches about 600,000 by 1200, the size of a strong regional kingdom or a large classical city-state league with its countryside.
  - The largest classical empires held 50–60 million (Scheidel 2009, *Rome and China*; Frier 2000; McEvedy & Jones). They reached that size by conquering and absorbing other peoples, not by the growth of one founding lineage.
  - The max of 3 M at 1200 assumes the game folds absorbed peoples into the society. Above that, the society would need growth that has no pre-modern precedent.
- **Largest settlements.**
  - The largest cities fell back after the late Bronze Age collapse, before they grew past their Bronze Age size.
  - The largest Iron Age imperial capital held about 100,000–200,000 by 500 BCE.
  - Hellenistic royal capitals and the largest capitals of the far east held 300,000–500,000 by 200 BCE.
  - The largest classical imperial capital held about 0.5–1 million around 1–150 CE, then declined. A late new capital held about 200,000–400,000 by 360 CE.
  - Sources: Chandler 1987, *Four Thousand Years of Urban Growth*; Modelski 2003; Morris 2013, *The Measure of Civilization* (largest-city series); Storey 1997, "The population of ancient Rome", *Antiquity* 71.
- **Urban share.**
  - About 20–30% of people lived in towns in the most urban classical core regions: a dense city-state heartland, or the imperial home peninsula with its capital.
  - The empire as a whole was 10–15% urban, and most regions were 5–10% (Hansen 2006, *Polis: An Introduction*; Wilson 2011, in Bowman & Wilson, *Settlement, Urbanization and Population*; Scheidel 2007).
  - Bronze Age river states were about 5–20% urban. After the collapse the eastern Mediterranean fell to a few percent (Knapp & Manning 2016, *AJA* 120).
- **Density.** Dense classical tenement districts reached 300–500 per hectare. Ordinary towns held 100–250 (Hansen 2006; Storey 1997; Wilson 2011).

## Work, food and productivity

| Metric (low / typical / high) | 600 | 700 | 800 | 900 | 1000 | 1100 | 1200 |
|---|---|---|---|---|---|---|---|
| Labor time on food, % | 68 / 52 / 40 | 70 / 54 / 42 | 66 / 50 / 38 | 65 / 49 / 37 | 64 / 48 / 36 | 63 / 47 / 35 | 63 / 47 / 35 |
| Food labor, plausible bounds | 32–85 | 32–88 | 30–85 | 30–85 | 28–85 | 28–85 | 28–85 |
| Households not primarily farming, % | 10 / 22 / 38 | 8 / 18 / 30 | 10 / 22 / 35 | 12 / 24 / 38 | 12 / 25 / 40 | 12 / 25 / 40 | 12 / 25 / 40 |
| Grain harvested per seed sown | 5 / 10 / 20 | 4 / 8 / 18 | 4 / 8 / 16 | 4 / 9 / 16 | 4 / 9 / 16 | 4 / 9 / 16 | 4 / 9 / 16 |
| Largest single project, person-days (typical / high) | 3×10⁵ / 10⁷ | 10⁵ / 3×10⁶ | 3×10⁵ / 10⁷ | 5×10⁵ / 2×10⁷ | 10⁶ / 3×10⁷ | 10⁶ / 3×10⁷ | 10⁶ / 3×10⁷ |
| Largest project max | 3×10⁷ | 3×10⁷ | 3×10⁷ | 5×10⁷ | 10⁸ | 10⁸ | 10⁸ |

Why these values:

- **Food labor.**
  - Iron plough shares, rotary querns, water mills (design year 893, overshot wheels 1012), crop rotation and a denser market all cut the time each household spent on food.
  - They cut it only modestly: about 75–80% of classical people still lived mainly from farming (Hopkins 1980, "Taxes and trade", *JRS* 70; Scheidel, Morris & Saller 2007, *Cambridge Economic History of the Greco-Roman World*; Temin 2013, *The Roman Market Economy*).
  - The 700 row is worse because of the post-collapse loss of specialists and stores.
- **Non-food households.**
  - The best classical core regions reached about 35–40% non-agricultural employment. A whole empire reached about 20–25% (Hopkins 1980; Scheidel & Friesen 2009, "The size of the economy", *JRS* 99; Wilson 2011).
- **Yields.**
  - Rain-fed classical wheat yielded about 1:4–1:10. Agronomy writers of the era quote 1:4 on poor land and up to 1:10–1:15 on the best land.
  - Irrigated river-valley grain yielded about 1:10–1:15 (Spurr 1986, *Arable Cultivation in Roman Italy*; Sallares 1991, *The Ecology of the Ancient Greek World*; Erdkamp 2005, *The Grain Market in the Roman Empire*).
  - The high value falls below the 600 figure of 20. Salinization ended the extreme irrigated yields of the early river states, and the centers of gravity moved to rain-fed land.
- **Construction.**
  - Classical temples and harbor moles took about 10⁵–10⁶ person-days.
  - The largest imperial frontier walls, aqueduct systems, amphitheaters and imperial tomb complexes took about 10⁶–10⁷ each.
  - The largest single imperial tomb-and-army complex of the far east is traditionally credited with hundreds of thousands of conscripts over decades, about 10⁸ person-days. That figure is almost certainly inflated, so it sets the max rather than the high (DeLaine 1997, *The Baths of Caracalla*, a costed classical building; Lancaster 2005; Hopkins 1978).

## Tools, crafts, knowledge and reach

| Metric (low / typical / high) | 600 | 700 | 800 | 900 | 1000 | 1100 | 1200 |
|---|---|---|---|---|---|---|---|
| Craft and tool proxies | tin bronze; chariots; glass | bloomery iron common; alphabet spreads | quench-hardened steel edges; coinage; triremes | cast iron (east); arch and vault; water mill | concrete; glass blowing; brass | paper; domes; hospitals (late) | codified law; state-run industry |
| Major innovations per century | 2 / 3 / 5 | 2 / 3 / 5 | 2 / 4 / 6 | 2 / 4 / 6 | 2 / 3 / 5 | 1 / 3 / 5 | 1 / 2 / 4 |
| Design items learned per 50-year block, % of that block's targets | 35 / 70 / 90 | 35 / 70 / 90 | 35 / 70 / 90 | 35 / 70 / 90 | 35 / 70 / 90 | 35 / 70 / 90 | 35 / 70 / 90 |
| Discoveries known, cumulative (new) | 390 / 790 / 1,010 | 450 / 900 / 1,160 | 515 / 1,030 / 1,325 | 575 / 1,155 / 1,485 | 640 / 1,275 / 1,640 | 690 / 1,380 / 1,775 | 730 / 1,460 / 1,880 |
| Discoveries known, bounds | 170–1,180 | 190–1,355 | 220–1,535 | 245–1,715 | 275–1,875 | 295–2,015 | 315–2,087 |
| Literacy, % of adults | 0 / 0.5 / 1 | 0 / 0.3 / 1 | 0.5 / 2 / 5 | 1 / 3 / 8 | 1 / 5 / 10 | 1 / 5 / 10 | 1 / 5 / 10 |
| Literacy max | 2 | 3 | 10 | 12 | 15 | 15 | 15 |
| Largest force fielded (people) | 300 / 2,000 / 20,000 | 200 / 1,500 / 15,000 | 500 / 3,000 / 40,000 | 500 / 5,000 / 60,000 | 500 / 6,000 / 100,000 | 500 / 6,000 / 150,000 | 500 / 6,000 / 150,000 |
| Largest force max | 40,000 | 40,000 | 100,000 | 150,000 | 300,000 | 450,000 | 500,000 |
| Peak mobilization, % of all people (new) | 0.3 / 1.5 / 4 | 0.3 / 1.5 / 4 | 0.5 / 2 / 6 | 0.5 / 2 / 6 | 0.5 / 2 / 7 | 0.5 / 1.5 / 4 | 0.5 / 1.5 / 4 |
| Peak mobilization max | 8 | 8 | 12 | 12 | 12 | 10 | 10 |
| Workers under arms or on watch, % (game Defense) | 2 / 5 / 10 | 3 / 6 / 12 | 2 / 5 / 10 | 2 / 5 / 10 | 2 / 5 / 10 | 2 / 5 / 10 | 2 / 5 / 10 |
| Trade reach, km | 500 / 2,000 / 4,000 | 300 / 1,500 / 3,000 | 500 / 2,000 / 4,000 | 600 / 2,500 / 5,000 | 800 / 3,000 / 8,000 | 800 / 3,000 / 9,000 | 800 / 3,000 / 9,000 |
| Trade reach max | 5,000 | 5,000 | 6,000 | 8,000 | 10,000 | 12,000 | 12,000 |
| Institutional reach, km radius (new) | 20 / 80 / 400 | 15 / 50 / 300 | 20 / 80 / 1,000 | 20 / 100 / 1,000 | 25 / 120 / 1,200 | 30 / 150 / 1,500 | 30 / 150 / 1,500 |
| Institutional reach max | 800 | 700 | 2,000 | 2,500 | 2,500 | 2,500 | 2,500 |

Why these values:

- **Metals and crafts.**
  - Bloomery iron became common after about 1200–1000 BCE (Snodgrass 1980; Waldbaum 1978, *From Bronze to Iron*).
  - Struck coinage appears about 600 BCE (Kroll 2012; Schaps 2004, *The Invention of Coinage*).
  - Cast iron was in use in the east by the 5th–4th centuries BCE (Wagner 2008, *Science and Civilisation in China* V:11).
  - Concrete and glass blowing date to the 1st century BCE, and paper to about 100 CE. These are the same dates the design registry uses.
- **Literacy.**
  - Harris 1989 (*Ancient Literacy*) is the standard ceiling. Classical city-states were at most about 5–10% literate overall, the classical empire under about 10–15%, and male city dwellers up to about 20–30%.
  - Bronze Age scribal literacy stayed at about 1% (Baines & Eyre 1983). The collapse erased it in some regions, so the 700 typical value is 0.3%.
  - The alphabet (`full_vowel_alphabet`, 740) is what lets the rate rise past about 1%.
- **Armies.**
  - Iron Age territorial empires fielded 50,000–100,000 at most in practice. The ancient totals of millions are rejected by modern scholarship (Hamblin; Briant 2002).
  - Classical city-states mobilized about 10–20% of citizen men for major campaigns, which is about 3–6% of all people. The high point of a classical republic at war was about 8–12% of the free population for a few years (Brunt 1971, *Italian Manpower*; Hansen 2006; Rosenstein 2004).
  - Standing imperial armies were about 300,000–450,000, which is about 0.5–1% of the population (MacMullen 1980; Scheidel 2009).
  - `WAR_MOBILIZATION_CAP` in `tools/sim/shocks/catalog.py` (5% at 1200 BCE, 7% at 0) agrees with these figures.
- **Trade.**
  - The collapse shrank exchange networks sharply.
  - By 500 BCE Phoenician-type maritime networks spanned the whole inland sea, about 4,000 km.
  - Monsoon crossings and overland relay trade linked the two ends of Eurasia, about 8,000–10,000 km (Parker 2008, *The Making of Roman India*; Hansen 2012, *The Silk Road*; Morris 2013 on the reach of exchange).
- **Institutional reach.**
  - A Bronze Age palace state ruled about 50–150 km (a few days' travel) around its center. A large river kingdom ruled about 400–600 km of valley (Postgate 1994; Kemp 2006).
  - The first multi-ethnic Iron Age empire ruled satrapies up to about 2,000 km from the court, but reached only loosely (Briant 2002).
  - Classical empires administered up to about 1,500–2,500 km. Imperial post systems carried orders about 50–150 km a day (Scheidel 2009; Scheidel & Meeks, *ORBIS*).
  - In the game this corresponds to `cap_institutions` / `state_capacity`, which are effect units. That is why `probe_key` is null.

**Innovation pace in the game.** The 600–1200 design registry (`data/research/blocks/y600_1200.json`) spreads its 964 items as follows. Of these, 146 are marked `key_threshold`.

| Years | 600–649 | 650–699 | 700–749 | 750–799 | 800–849 | 850–899 | 900–949 | 950–999 | 1000–1049 | 1050–1099 | 1100–1149 | 1150–1200 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Items targeted | 77 | 76 | 96 | 91 | 93 | 89 | 88 | 81 | 79 | 72 | 58 | 64 |

- Adding the 1,123 items of `research_600.json` gives the cumulative targets: about 1,286 by 700, 1,472 by 800, 1,649 by 900, 1,822 by 1000, 1,970 by 1100 and 2,087 by 1200.
- The "discoveries known" band takes 35% / 70% / 90% of the cumulative target as low / typical / high, which matches the per-50 band.
  - At 600 this gives 790 typical, close to the surrogate's current median of 755 (`STRATEGY_SWEEP.md`).
  - The max counts every item whose `min_year` has passed.
- The 21 milestone ids in the JSON are unconditional items of historical weight: crop rotation, full alphabet, elected magistrates, citizen infantry, struck coinage, three-banked warships, natural philosophy, relay roads, liquid iron, voussoir arch, axiomatic geometry, realm standardization, trigonometry, office examinations, monsoon crossings, public credit, concrete, glass blowing, paper, compiled law code and charity hospitals.
  - Items gated on a resource or environment, such as `bloomery_smelting` (needs Iron Ore) and `water_mills` (needs a river), are left out so that the milestone check does not fail on the map.

## Allowed lead over history

The rule from the 600 window carries over: play may lead history "within a reasonable deviation" only if every lead costs something elsewhere.

- **Milestones.** A milestone may land up to 5% of its design year early, but never before `band_low`. Landing after `band_high` is a pacing failure.
  - The fraction drops from 0.2 to 0.05 because `sweep_strategies.py` applies `max(band_low, design × (1 − f))` to absolute game years. At design year 1000, 20% would allow 200 years of lead, while 5% allows 50.
  - The block's bands sit about 30–45 years below the design year, so `band_low` is the binding floor in practice, just as in the 600 window.
- **Outcome facets.** The default stays at 15% of |high − typical| above `high`. `allowed_deviation.per_metric_over_high_fraction_of_typical_to_high_gap` sets it per metric:

| Lead allowed (share of the typical→high gap) | Metrics | Why |
|---|---|---|
| 0.25 | largest project, major innovations, trade reach | order-of-magnitude or count metrics, where the record itself is ±25% |
| 0.20 | literacy, institutional reach | reconstructions vary widely (Harris's range is itself a factor of 2) |
| 0.15 | life expectancy, infant / child / maternal mortality, CDR, largest settlement, urban share, food labor, non-food households, yields, per-50 discoveries | same as the 600 window |
| 0.10 | population, growth, discoveries known | compounded or cumulative. Leading on them for 600 years multiplies, so the margin is tighter |
| 0 | TFR, CBR, density, army size, army share, Defense share | `better: neither`. Being above high is a different society, not a better one |

- **Trade-offs.** The trade-offs from the 600 window still apply, and the 600–1200 block adds three more:
  - **Cities.** Urban share and large cities cost life expectancy (urban graveyard) and raise pestilence exposure.
  - **Armies.** Mobilization beyond about 6% costs food labor and growth.
  - **Credit.** Public credit and coinage raise the risk of a credit crisis.

## Shocks widen the floor

Shocks make the floor of this era much deeper than its typical value. Collapse, pestilence and credit crises are all recorded in this window. The JSON block `shock_widening` gives the widening per shock type and per metric:

- **How the adjustments are written.** Each adjustment is `<field>_mult` or `<field>_add`, where the field is min, low, typical, high or max. Every adjustment moves the band toward the worse outcome.
- **When they apply.** An adjustment applies only to checkpoints whose window overlaps a shock logged in that run, plus its recovery window. A shock-free run is judged on the plain bands.
- **Combining shocks.** Concurrent shocks multiply their `_mult` values and add their `_add` values. None may pass `hard_floor`: life expectancy 15, population 30, growth −3%/yr, CDR 90.

The hazards per game century follow `tools/sim/shocks/catalog.py`, ancient band:

| Shock | Rate per game century | Typical toll |
|---|---|---|
| Collapse | 0.15–0.5 | 30–60% population loss |
| Pestilence (≥ 5% dead) | 0.2–0.7 | a few per millennium lived |
| Pestilence (≥ 25% dead) | 0–0.1 | |
| Famine (≥ 2% dead) | 0.5–1.5 | |
| Credit crisis | 0.1–0.8 | rises once coin and written credit exist |
| General war | 0.15–0.6 | |

**Collapse of the palace economies (peak risk about game 640–720).**

- **What fails.** In the late Bronze Age, a centralized redistributive economy could fail as a system. Several such states did so within one or two generations:
  - rulers stopped collecting and redistributing;
  - specialists lost their rations, and scribal literacy ended;
  - long-distance exchange stopped;
  - people dispersed to villages;
  - the regional population fell by 30–60% over a century or more.
- **The triggers** were drought, interstate war, raiding by displaced peoples, and brittle over-centralization, working together (Cline 2014, *1177 B.C.*; Knapp & Manning 2016; Middleton 2017, *Understanding Collapse*; Tainter 1988, *The Collapse of Complex Societies*).
- **Game mapping.** The historical window of about 1200–1000 BCE falls at game years 660–700.
- **Allowed widening for a run with a logged collapse:**
  - population low × 0.4 (min × 0.5), growth low −0.6 and min −1.0;
  - largest settlement low × 0.2, urban share to 0 (typical × 0.4), non-food households × 0.5;
  - literacy low 0 and typical × 0.2;
  - largest project × 0.1, trade reach × 0.3, institutional reach × 0.2;
  - per-50 discoveries low −15 points, life expectancy low −2;
  - food labor low +8, Defense share high +5.
- **Recovery** takes 60–150 game years. Historically it took about 150–400 years, compressed by the 5:1 clock of this segment.
- **The design registry already expects a collapse.** `lost_age_remembrance` (676) and `village_self_rule_after_collapse` (686) are its designed after-effects.
- **What counts as good play** is resilience: diversified food, local self-rule, stores and records. It is not immunity. A best-play run may still be hit by a logged collapse. It should recover to the typical band within about 100 game years.

**Pestilence (peak risk about game 1050–1200).**

- Dense, connected imperial societies suffered crowd-disease pandemics lasting 5–20 years. They killed about 10–25% of people, most heavily in cities (Harper 2017, *The Fate of Rome*; Duncan-Jones 1996; Scheidel 2002 on plague mortality in a census-registered province).
- **Widening:**
  - population low × 0.7, life expectancy low −4 (min −2);
  - CDR low +15 (max +20);
  - infant and child mortality low +40;
  - urban share × 0.7, largest settlement × 0.6, army size × 0.6.
- **Recovery** takes 30–100 game years.
- Good sanitation and clinical knowledge cut exposure only a little. The pre-modern `MEDICINE_CEILING` is 0.35–0.45.

**Credit crisis (possible from about game 700, larger after `public_credit` at about 1000).**

- A lender panic or a coin debasement freezes building, forces land sales and leaves soldiers and officials unpaid. The classical record includes a capital-wide credit panic that the treasury ended with interest-free loans, and a century-long debasement that wrecked the silver coinage (Temin 2013; Harris 2008, *The Monetary Systems of the Greeks and Romans*; Duncan-Jones 1994).
- **Widening:** non-food households × 0.85, largest project × 0.5, trade reach × 0.8, institutional reach × 0.8, army size × 0.7.
- **Recovery** takes 5–30 game years.
- There is no direct effect on vital rates. Any such effect should come only through a triggered famine or war.

**Famine and war** have smaller entries in the JSON:

- **Famine** takes about 10% of population, cuts life expectancy by 2 and adds 30 per 1,000 to infant mortality.
- **War** takes about 15% of population, lets peak mobilization rise by 3 points, lets Defense share rise by 8, and cuts trade reach to × 0.7.

## What the game must never show before year 1200

These are the "superhuman" signals. Each assumes no logged shock and is measured after the allowed lead.

- **Life.** Life expectancy above about 40, infant mortality below about 120 per 1,000, or maternal mortality below about 450 per 100,000.
- **Growth.** Growth sustained above about 1% a year for a century after year 900, or a founders' society above about 3 million.
- **Scale.** A city above about 1 million, or an urban share above 40%.
- **Knowledge and people.**
  - Literacy above 15%.
  - More than about 12% of all people under arms.
  - Trade reach above about 12,000 km (no ocean crossings to other continents).
- **Milestones.** Any milestone before its `band_low`. For example: coinage before 760, concrete before 965, paper before 1050, or examinations before 935.
- **Effects.** Any effect total above its era ceiling (`SocietyModel.era_ceiling_for`).

## For the surrogate and check tools

- **Loading the file.** `tools/sim/facets.py` reads only `docs/research/benchmarks_600.json` (`BENCH_PATH`), and so does `tools/research/benchmark_report.py`.
  - To use this file, load both files and merge each metric's `years`. Year 600 is identical in both, and the merge was checked against `facets.flag` / `bench_at`.
  - For year > 600, take `milestones.ids` and `allowed_deviation` from this file.
- **Facet keys.** `facets.BENCH_KEYS` must gain `"known": "discoveries_known"` for the new cumulative metric. The other new metrics have `probe_key: null`.
  - `per_50` uses `cat.design_year`, so the catalog must load the y600_1200 block. So must `simlib.milestone_years` / `cat.index`, or else the milestones are skipped silently.
- **Check years.** `tune.py` `CHECK_YEARS = [100, 300, 600]` must be extended to 700–1200. The runs must also go past `--years 600`.
- **Per-metric leads.** `facets.flag` reads only the global `facet_over_high_fraction_of_typical_to_high_gap`. It should prefer `per_metric_over_high_fraction_of_typical_to_high_gap[metric]` when present.
  - `sweep_strategies.py` checks exceedance as `high × (1 + margin)` rather than `high + margin × |high − typical|`. That is a different, looser test. Align it if the new per-metric leads are to mean the same thing in both tools.
- **Shock widening.** `shock_widening` is advisory data. No tool reads it yet. Apply it only to runs whose shock log records the event.
