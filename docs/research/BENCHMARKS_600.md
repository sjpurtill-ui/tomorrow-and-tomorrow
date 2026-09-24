# Historical benchmarks for the 600-year window

Phase 3 balance target. User direction: "Progression needs to match the year benchmarks in realistic historical human terms. We can't create superhumans just because we progressed so early."

The same numbers are in machine-readable form in `docs/research/benchmarks_600.json` (metric → game year → min / low / typical / high / max). The balance harness (`tests/research_600_campaign_probe.gd`) measures the metrics that have a `probe_key`.

## How to read these tables

- **Game years and history.** Game year 0 ≈ 5000 BCE, 100 ≈ 4000 BCE, 300 ≈ 3000 BCE, 600 ≈ 1500 BCE (`TechnologyEras.CURVE`). The research design compresses 3,500 years of history into 600 game years. People are born, age and die on the game calendar, so every vital rate below is **per game year**.
- **Low / typical / high** describe poor, ordinary and high-achieving societies of that era. Good play should land near **high**, poor play near **low**.
  - **High-achieving** means the best-documented societies of the era: Ubaid and Uruk Mesopotamia, Naqada and Old Kingdom Egypt, and later Middle and New Kingdom Egypt and Old Babylonian cities. It never means beyond them.
- **Min / max** mark the edge of what is historically plausible at all. A simulated value outside them is a balance failure.
- **The founders' society.** The game starts with 120 founders. Absolute sizes for that society are derived from plausible growth rates, and capped by the settlement sizes documented for each era. Historical settlement sizes are listed separately.

## Vital rates

| Metric | Year 0 (5000 BCE) | Year 100 (4000 BCE) | Year 300 (3000 BCE) | Year 600 (1500 BCE) |
|---|---|---|---|---|
| Life expectancy at birth, years (low / typical / high) | 20 / 25 / 30 | 21 / 26 / 31 | 21 / 27 / 33 | 22 / 28 / 35 |
| Plausible bounds | 18–33 | 18–34 | 18–36 | 18–38 |
| Infant mortality per 1,000 births (low / typical / high) | 330 / 260 / 200 | 320 / 250 / 190 | 310 / 240 / 180 | 300 / 220 / 160 |
| Plausible bounds | 160–400 | 150–400 | 140–400 | 130–380 |
| Child mortality, ages 1–4, per 1,000 (4q1) | 260 / 200 / 150 | 250 / 190 / 140 | 240 / 180 / 130 | 230 / 170 / 120 |
| Maternal deaths per 100,000 births | 2,000 / 1,400 / 1,000 | 1,900 / 1,300 / 950 | 1,800 / 1,250 / 900 | 1,700 / 1,150 / 800 |
| Total fertility (births per woman) | 4.5 / 5.5 / 6.5 | 4.5 / 5.8 / 6.8 | 4.5 / 5.8 / 6.8 | 4.5 / 5.6 / 6.5 |
| Crude birth / death rate per 1,000 (typical) | 44 / 40 | 44 / 39 | 43 / 38 | 42 / 37 |
| Growth, % per game year (low / typical / high) | −0.5 / 0.4 / 1.2 | −0.3 / 0.5 / 1.2 | −0.2 / 0.4 / 1.0 | −0.2 / 0.3 / 0.8 |
| Plausible growth bounds | −2.0 to 2.0 | −1.0 to 1.8 | −1.0 to 1.5 | −1.0 to 1.3 |

Why these values:

- **Life expectancy.** Pre-modern life expectancy at birth sits at 20–35 years, dominated by child deaths.
  - Coale–Demeny West model life tables, levels 3–7 (e0 25–35), are the standard reference for pre-modern populations (Coale & Demeny 1983; Chamberlain 2006, *Demography in Archaeology*, ch. 3).
  - Skeletal series from Neolithic and Bronze Age sites give adult ages at death in the low-to-mid 30s, and e0 of about 20–30 once infants are counted (Angel 1984, in Cohen & Armelagos, *Paleopathology at the Origins of Agriculture*; Bocquet-Appel & Naji 2006).
  - Even well-recorded Roman Egypt had e0 of about 22–25 (Bagnall & Frier 1994, *The Demography of Roman Egypt*; Scheidel 2001, *Death on the Nile*).
  - The ceiling of 38 at 1500 BCE is deliberately generous for a well-fed elite-led city. A founding band should not start above about 30.
- **Infant and child mortality.** A meta-analysis of 20 hunter-gatherer and 43 historical populations found that about 27% of infants died before age 1, and about 47% of children died before puberty (Volk & Atkinson 2013, *Evolution and Human Behavior* 34:182–192).
- **Maternal mortality.** Pre-modern maternal mortality was about 1–1.5% of births, i.e. 1,000–1,500 per 100,000 (Loudon 1992, *Death in Childbirth*; Chamberlain 2006). The best recorded pre-modern midwifery rarely fell below about 500.
- **Fertility and growth.**
  - Neolithic farming raised fertility to a total of about 6–7 births per woman, from about 4–5 among foragers (Bocquet-Appel 2011, *Science* 333:560–561, "the Neolithic Demographic Transition").
  - Long-run growth nevertheless stayed near 0.1% per year, because booms were cancelled by famine, epidemic and war (Hassan 1981, *Demographic Archaeology*; Livi-Bacci 2017, *A Concise History of World Population*).
  - A young farming population on open land can grow about 1–1.5% a year for several generations, as on the LBK expansion front (Shennan 2018, *The First Farmers of Europe*).
  - Growth above about 2% a year sustained over a century is not plausible pre-modern. It needs modern mortality.

## Settlement and society scale

| Metric | Year 0 | Year 100 | Year 300 | Year 600 |
|---|---|---|---|---|
| Founders' society population (low / typical / high) | 120 | 60 / 300 / 900 | 80 / 1,200 / 6,000 | 100 / 3,500 / 20,000 |
| Plausible bounds | 100–140 | 30–1,500 | 30–15,000 | 30–60,000 |
| Largest settlements of the era (historical) | villages 100–300; Çatalhöyük-type towns up to 3,000–8,000 (earlier) | 150–1,000; Tripolye mega-sites and Ubaid towns 5,000–15,000 | 300–5,000; Uruk 25,000–50,000 | 500–10,000; Thebes and Babylon 50,000–80,000 |
| Built density, people per hectare | 50–200 | 50–200 | 80–250 | 100–300 |

Sources:

- **Uruk** reached about 250 ha and 25,000–50,000 people by about 3000 BCE (Adams 1981, *Heartland of Cities*; Algaze 2008, *Ancient Mesopotamia at the Dawn of Civilization*).
- **Largest cities by 1500 BCE** held about 50,000–80,000 (Modelski 2003, *World Cities: −3000 to 2000*; Chandler 1987).
- **Çatalhöyük** held 3,500–8,000 people (Hodder 2006). The Tripolye mega-sites of about 4000 BCE held 10,000–15,000 (Müller et al. 2016).
- **Density** of Near Eastern towns was about 100–300 per hectare (Postgate 1994, *Early Mesopotamia*).

The founders' ranges follow from the growth bounds. For example, 120 people × e^(1.0% × 100 years) ≈ 330, and the most a century of frontier growth adds is roughly ×3–7.

## Work, food and productivity

| Metric | Year 0 | Year 100 | Year 300 | Year 600 |
|---|---|---|---|---|
| Labor time spent getting and processing food, % (low / typical / high) | 75 / 62 / 52 | 72 / 60 / 50 | 70 / 56 / 45 | 68 / 52 / 40 |
| Households not primarily farming, % (historical) | 3 / 8 / 12 | 5 / 10 / 15 | 8 / 18 / 32 | 10 / 22 / 38 |
| Grain harvested per seed sown | 3 / 5 / 8 | 4 / 6 / 10 | 5 / 10 / 25 | 5 / 10 / 20 |
| Largest single project, person-days | ~10³ (longhouse, ditched enclosure) | ~10⁴–10⁵ (Ubaid temple platform, passage grave) | ~10⁵–10⁶ (Uruk Eanna terrace, city wall) | ~10⁶–10⁷ (ziggurat of Ur; Great Pyramid ~2560 BCE ≈ 10⁷) |

Why these values:

- **Food labor.** Early farming households spent most of their working year on food, including grinding grain, which alone took hours a day (Molleson 1994). The game's "Food" allocation is a share of labor time, not of households, so it is benchmarked against time use.
  - Only palace and temple economies moved a third or more of households off the land, and they relied on corvée in the farming off-season (Postgate 1994; Kemp 2006, *Ancient Egypt: Anatomy of a Civilization*).
- **Yields.** Ur III texts give about 1:20–1:25 for irrigated barley in good years, and Egypt about 1:10. Rain-fed Neolithic fields gave about 1:4–1:8 (Postgate 1994; Halstead 2014, *Two Oxen Ahead*).
- **Monuments.** The Great Pyramid took about 20,000–25,000 workers over about 20 years (Lehner 1997, *The Complete Pyramids*).

## Tools, crafts, knowledge and reach

| Metric | Year 0 (5000 BCE) | Year 100 (4000 BCE) | Year 300 (3000 BCE) | Year 600 (1500 BCE) |
|---|---|---|---|---|
| Craft and tool proxies | ground stone and flint; coil pottery; flax plain weave; cold-worked native copper | smelted and cast copper (Varna, about 4500 BCE); kilns at about 900 °C; tournette | arsenical copper common; first tin bronze; wheel-thrown pottery; lost wax; cylinder seals | tin bronze standard; spoked chariot wheels; core-formed glass; iron still rare |
| Major innovations per century (low / typical / high) | 0.5 / 1.5 / 3 | 1 / 2 / 4 | 2 / 4 / 6 | 2 / 3 / 5 |
| Design discoveries learned per 50-year block, % of that block's registry targets | 35 / 65 / 85 | 35 / 70 / 90 | 35 / 70 / 90 | 35 / 70 / 90 |
| Literacy, % of adults | 0 | 0 | ≤ 0.5 (scribes) | about 0.5–1 |
| Largest force fielded | 10–60 (raiding party) | 20–300 | 100–3,000 (city levy) | 300–20,000 (a great state) |
| Share of workers under arms or on watch, % | 2–8 | 2–8 | 2–10 | 2–10 |
| Trade reach, km | 150–800 (obsidian) | 200–1,500 | 400–3,000 (lapis lazuli) | 500–4,000 (tin, copper, glass) |

Sources:

- **Metals.** Roberts, Thornton & Pigott 2009, *Antiquity* 83; Radivojević et al. 2010 (copper smelting by about 5000 BCE in the Balkans).
- **Writing.** Writing appears about 3300–3200 BCE (Schmandt-Besserat 1996; Englund 1998).
- **Literacy.** Egyptian literacy was at most about 1% (Baines & Eyre 1983).
- **Armies.**
  - Talheim, about 5000 BCE, was the massacre of a whole community of 34 people.
  - The Stele of the Vultures, about 2450 BCE, records a city-state phalanx of hundreds.
  - At Megiddo (1457 BCE) and Kadesh (1274 BCE) armies numbered about 10,000–20,000 or more (Hamblin 2006, *Warfare in the Ancient Near East to 1600 BC*).
- **Trade.**
  - Obsidian fall-off: Renfrew, Dixon & Cann 1968.
  - Badakhshan lapis in Uruk and Naqada contexts: Algaze 2008.
  - The Uluburun cargo (about 1300 BCE) carried copper, tin and glass across the eastern Mediterranean.

**Innovation pace in the game.** The design registry spreads its 1,101 items over the window as follows:

| Years | 0–49 | 50–99 | 100–149 | 150–199 | 200–249 | 250–299 | 300–349 | 350–399 | 400–449 | 450–499 | 500–549 | 550–600 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Items targeted | 259 | 115 | 94 | 84 | 76 | 77 | 57 | 77 | 77 | 61 | 60 | 64 |

- Most items are small practices. Only a handful per century are historically major. That handful is tracked through the milestone ids in `benchmarks_600.json`.
- A milestone passes when it lands inside its design band.

## Allowed lead over history

The user allows play to run ahead of history "within a reasonable deviation", as long as every lead costs something elsewhere. The allowed deviation is:

- **Milestones.** A milestone may land up to about 20% before its design year, but never before its band's low edge. The era gate (`earliest_year` = band low) enforces the floor in the engine. For writing (`pictographic_records`, year 255) that is year 215. For bronze (360) it is 320, and for place value (510) it is 470.
  - The band low is about 12–25% before the design year, so "one band early" and "20% early" coincide.
  - Landing after the band's high edge is a pacing failure too.
- **Outcome facets.** Good play should sit between typical and high. A facet may exceed the era's high value by at most 15% of the gap between typical and high. For example, at year 300 life expectancy may reach 33 + 0.15 × (33 − 27) ≈ 34.
  - The 15% margin absorbs single-seed noise and the aggregate model's coarseness. Anything beyond it counts as superhuman, and the min/max plausibility bounds still apply.
  - Why 15%: the documented spread between typical and best societies of an era is itself the historical record of how far a well-run society led its neighbours. A lead of more than about a sixth of that spread again has no documented precedent.
- **Trade-offs.** No strategy may lead on every facet. The price of each lead is set out below:
  - **Research.** Heavy research moves workers into Knowledge and out of food, craft and building, which slows growth and food security.
  - **One line.** Maximizing one line leaves the other lines unlearned.
  - **Early bonuses.** Early care or military emphasis comes at the expense of stores or tools.
  - The line-maximization matrix and the mixed-allocation sweep (`docs/research/LINE_MAX_MATRIX.md`) check this.

## What the game must never show before year 600

These are the "superhuman" signals the harness checks for:

- **Life.** Life expectancy above about 38, infant mortality below about 130 per 1,000, or maternal mortality below about 500 per 100,000.
- **Growth.** Sustained growth above about 1.5–2% a year for a century.
- **Knowledge.** Writing before about year 215 (the band low of `pictographic_records`), tin bronze before about 320, place value before about 470, or iron smelting before about 660.
- **Effects.** Any effect total above its era ceiling (`SocietyModel.era_ceiling_for`).
