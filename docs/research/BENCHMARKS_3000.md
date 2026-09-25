# Historical benchmarks for the 2400–3000 window

This file continues `BENCHMARKS_2400.md` for the last research block, game years 2400–3000, which is the end of the game. It is the Phase 3 balance target for that block. The user's direction still applies: "Progression needs to match the year benchmarks in realistic historical human terms. We can't create superhumans just because we progressed so early."

The same numbers are in machine-readable form in `docs/research/benchmarks_3000.json`. It uses the schema of `benchmarks_1200.json`: metric → game year → min / low / typical / high / max.

Year 2400 repeats `benchmarks_2400.json` exactly for every shared metric (copied from benchmarks_2400.json for 29 metrics), so the two files join without a step. Merge them by taking the union of each metric's `years`. The four metrics that `benchmarks_2400.json` introduced (state revenue, message speed, energy capture, cavalry share) are continued here to 3000. Two metrics are new in this window, secondary-sector labor and news reach. They carry a derived 2400 row so they interpolate from the join.

## How to read these tables

- **Game years and history.** `TechnologyEras.CURVE` places the checkpoints as follows:

  | Game year | 2400 | 2500 | 2600 | 2700 | 2800 | 2900 | 3000 |
  |---|---|---|---|---|---|---|---|
  | Historical year | 1800 | ≈ 1838 | 1875 | ≈ 1912 | 1950 | 1990 | 2030 |

  - Between game years 2400 and 2800, one game year covers 0.375 historical years. After 2800 it covers 0.4.
  - This is the only window in which the game clock runs *slower* than history. The block stretches about 230 years of history over 600 lived years.
  - People are still born, age and die on the game calendar, so every vital rate is **per game year**. Life expectancy, infant mortality and fertility follow the historical values of the matching date, because they describe individual lives.
  - Compounded quantities cannot also follow history year for year. Nineteenth-century natural increase of 1% a year, compounded over 600 lived years, would multiply a society about 400-fold. Growth is therefore set so that the **window's total population multiple** matches history. The world grew about 8-fold between 1800 and 2030, early industrial cores 3–6-fold, and settler societies 30–60-fold with immigration. The typical row here grows about 10-fold. Crude birth and death rates are set so that CBR − CDR ≈ the growth band. The demographic transition therefore shows the right levels at each date, with a narrower gap between births and deaths than history had.
- **Floor / typical / best.** `low` / `typical` / `high` describe poor, ordinary and best-plausible societies of the era. Good play should land between typical and high, and poor play near low.
- **What "best-plausible" means.** It follows the leaders of each date: the first coal-and-steam economies, then the early public-health states, then the high-income welfare states. It means the best-documented society of that date, and never beyond it. "Typical" sits between the world average and the leaders, since the player's society is assumed to take part in the transition.
- **Min / max** mark the edge of what is historically plausible at all. A simulated value outside them is a balance failure. Only a logged shock may push a value past them, as set out in "Shocks widen the floor" below.
- **Real history is calibration only.** The JSON contains no real names. The sources below are cited by author and title, and the societies are described generically.

## Vital rates

| Metric (low / typical / high) | 2400 | 2500 | 2600 | 2700 | 2800 | 2900 | 3000 |
|---|---|---|---|---|---|---|---|
| Life expectancy at birth, years | 24 / 34 / 41 | 26 / 36 / 43 | 28 / 38 / 46 | 32 / 45 / 55 | 42 / 58 / 69 | 55 / 70 / 77 | 62 / 77 / 82 |
| Plausible bounds | 18–47 | 20–48 | 22–51 | 25–60 | 30–72 | 40–80 | 45–86 |
| Infant mortality per 1,000 | 280 / 185 / 125 | 270 / 180 / 120 | 260 / 170 / 105 | 220 / 130 / 70 | 150 / 70 / 30 | 90 / 30 / 8 | 40 / 8 / 3 |
| Plausible bounds | 90–360 | 85–350 | 75–340 | 50–300 | 18–250 | 4–160 | 1.5–90 |
| Child mortality 1–4 per 1,000 (4q1) | 210 / 140 / 85 | 200 / 135 / 80 | 195 / 125 / 70 | 150 / 80 / 35 | 60 / 20 / 6 | 25 / 6 / 1.5 | 10 / 2 / 0.7 |
| Maternal deaths per 100,000 births | 1,300 / 750 / 450 | 1,250 / 720 / 430 | 1,150 / 650 / 380 | 900 / 500 / 250 | 500 / 150 / 40 | 250 / 40 / 7 | 120 / 15 / 4 |
| Maternal floor–ceiling | 300–2,300 | 280–2,200 | 250–2,000 | 150–1,600 | 25–1,200 | 3–900 | 2–600 |
| Total fertility | 3.8 / 5 / 6.4 | 3.8 / 4.9 / 6.2 | 3.5 / 4.5 / 5.9 | 2.8 / 3.8 / 5.2 | 2.2 / 3 / 4.8 | 1.7 / 2.3 / 3.6 | 1.3 / 1.7 / 2.3 |
| Total fertility bounds | 2.7–8.4 | 2.6–8 | 2.4–7.5 | 2–7.2 | 1.6–7 | 1.3–6.5 | 0.8–5 |
| Crude birth / death rate per 1,000 (typical) | 38 / 34 | 34.5 / 31 | 31 / 27 | 24 / 19 | 18 / 12 | 14 / 8.5 | 10.5 / 9 |
| Growth, % per game year | −0.1 / 0.35 / 0.8 | −0.1 / 0.35 / 0.6 | −0.1 / 0.4 / 0.6 | −0.1 / 0.45 / 0.6 | −0.2 / 0.45 / 0.55 | 0 / 0.5 / 0.7 | −0.3 / 0.2 / 0.35 |
| Plausible growth bounds | −1 to 1.4 | −1 to 1.4 | −1 to 1.4 | −1 to 1.5 | −1 to 1.5 | −0.8 to 1.6 | −0.8 to 1 |

Why these values:

- **Life expectancy: the mortality transition.**
  - In 1800, e0 was about 28–30 for the world and 35–40 in the best-recorded north-western societies (Wrigley & Schofield 1981, *The Population History of England*; Human Mortality Database, Sweden from 1751).
  - Leaders reached about 45 by 1875 and 55 by 1912. Most of the world stayed near 30 until 1900 (Riley 2005, "Estimates of regional and global life expectancy, 1800–2001", *Population and Development Review* 31).
  - By 1950 the leaders reached about 70 against a world average of 46. By 1990 the figures were 79 and 65. The United Nations projects about 84 and 74 for 2030 (UN *World Population Prospects 2024*).
  - Typical therefore rises from 34 to 77, and high from 41 to 82. The max of 86 is the best projected national value for 2030. The design target of "about 80" sits between typical and high at 3000. Best-practice e0 has risen about 2.5 years per decade since 1840 (Oeppen & Vaupel 2002, *Science* 296); the max row stays close to that line.
- **Infant and child mortality.**
  - Infant mortality in north-western Europe fell from about 150–200 per 1,000 in 1800 to 100 in the leaders by 1900. It reached 20–30 in 1950, 5–7 in 1990, and 2–3 in the best systems today. The world average was about 140 in 1950 and is about 25 now (Human Mortality Database; UN IGME 2023).
  - The high row reaches 3 per 1,000 at 3000, the design target. The min of 1.5 is the best recorded national rate.
  - Child mortality (4q1) fell even faster than infant mortality once vaccination, clean water and antibiotics arrived. It went from about 100–150 per 1,000 in 1800 to under 1 in the best systems today.
  - These three rates, and maternal mortality, interpolate on a log scale in the focus file, because they span two orders of magnitude.
- **Maternal mortality.**
  - It stayed at 400–1,000 per 100,000 through the nineteenth century. Hospital childbirth and puerperal fever kept it high until antisepsis, and it did not fall decisively until sulfonamides, antibiotics and blood transfusion arrived after 1935.
  - It then fell to 20–50 by 1950 in the leaders and to 3–10 today (Loudon 1992, *Death in Childbirth*; Högberg 2004 on Sweden; WHO 2023 *Trends in Maternal Mortality*).
- **Fertility: the fertility transition.**
  - TFR was about 5 in 1800. France began its decline early, with TFR near 3.4 by 1875. North-western Europe followed after 1880 (the Princeton project: Coale & Watkins 1986, *The Decline of Fertility in Europe*).
  - The industrial core fell below 3 by 1912 and to 2.0–2.5 by the 1930s. A baby boom followed (US 3.7 in 1957). TFR fell below replacement after 1975, to 1.3–1.8 by 1990–2030, and 0.7–1.0 in the lowest East Asian states. The world fell from 5.0 in 1950 to 3.3 in 1990 and about 2.2 now (UN WPP 2024; Chesnais 1992, *The Demographic Transition*).
  - Typical therefore goes 5.0 → 1.7, and the min at 3000 is 0.8. TFR is a `neither` metric, so high means more births, not better.
- **Growth.**
  - On the lived clock, the typical rate rises from 0.35 to 0.5% per game year across the mortality transition. It then falls to 0.2% by 3000 as TFR drops below replacement and population momentum runs out. Compounded, the typical society grows about 10-fold over the window, and a best-plausible one about 30-fold.
  - The low row falls to −0.3 at 3000, which is an ageing, shrinking society. Growth max 1.6 at 2900 is a settler or high-fertility society in the post-1950 mortality decline, which grew about 3% a year historically (1.2% on the stretched clock).

## Settlement and society scale

| Metric (low / typical / high) | 2400 | 2500 | 2600 | 2700 | 2800 | 2900 | 3000 |
|---|---|---|---|---|---|---|---|
| Founders' society population | 120 / 170 k / 22 M | 120 / 241 k / 40.1 M | 150 / 360 k / 73 M | 200 / 564 k / 133 M | 250 / 885 k / 231 M | 300 / 1.5 M / 465 M | 300 / 1.8 M / 660 M |
| Plausible bounds | 30–60 M | 30–120 M | 30–250 M | 30–450 M | 30–700 M | 30–1.2 B | 30–1.5 B |
| Largest settlements of the era (historical) | 1,000 / 25 k / 1.1 M | 1,200 / 35 k / 1.8 M | 1,500 / 60 k / 4 M | 2,000 / 120 k / 7 M | 3,000 / 300 k / 12 M | 5,000 / 800 k / 30 M | 5,000 / 1.5 M / 37 M |
| Largest settlement max | 1.5 M | 2.2 M | 4.5 M | 8 M | 14 M | 33 M | 42 M |
| Urban share: % living in places of 5,000+ | 3 / 13 / 38 | 4 / 16 / 45 | 5 / 20 / 55 | 8 / 27 / 65 | 12 / 38 / 75 | 22 / 60 / 82 | 30 / 70 / 88 |
| Urban share max | 48 | 55 | 65 | 75 | 85 | 95 | 98 |
| Built density, people per hectare | 100 / 200 / 400 | 100 / 200 / 400 | 100 / 200 / 450 | 80 / 150 / 400 | 40 / 90 / 250 | 25 / 60 / 200 | 25 / 60 / 200 |

Why these values:

- **The founders' society.**
  - The typical row compounds the typical growth rates from `benchmarks_2400.json`'s 170,000: 170,000 × e^(Σ rate × 100).
  - The high row compounds the high rates from 22 M, reaching about 660 M by 3000. That is the size of the largest continental federations of today, not counting the two 1.4-billion states. Those grew mostly by absorbing other peoples. The max of 1.5 B allows for such absorption.
- **Largest settlements.** The largest cities of the era held about 1.1 M in 1800, 1.8 M in 1838, 4 M in 1875, 7 M in 1912 and 12 M in 1950 (the largest metropolitan areas). They held about 30 M in 1990 and 37–39 M are projected for 2030 (Chandler 1987, *Four Thousand Years of Urban Growth*; Bairoch 1988, *Cities and Economic Development*; UN *World Urbanization Prospects 2018*).
- **Urban share.** Settlements of 5,000+ held about 7% of the world's people in 1800. The most urban societies were at 30–40%, and the most urban industrial society exceeded 50% by 1851 and about 75% by 1911.
  - The world urban share was 30% in 1950, 43% in 1990 and a projected 60% in 2030. High-income societies stand at 80–90%, and city-states at 100% (Bairoch 1988; de Vries 1984, *European Urbanization 1500–1800*; UN WUP 2018).
  - The typical row rises from 13% to 70%, and high from 38% to 88%, so the society moves "toward 80%" as asked.
- **Density.** The densest tenement districts of the 1880s–1900s reached 1,000+ per hectare. Rail and car suburbs then cut built densities to 20–60 per hectare by 1950–2030, while the densest modern cores keep 200–400 (Angel et al. 2011, *Making Room for a Planet of Cities*).

## Work, food, energy and building

| Metric (low / typical / high) | 2400 | 2500 | 2600 | 2700 | 2800 | 2900 | 3000 |
|---|---|---|---|---|---|---|---|
| Labor time on food, % | 58 / 38 / 25 | 56 / 36 / 22 | 53 / 33 / 18 | 48 / 28 / 13 | 42 / 22 / 9 | 33 / 13 / 5 | 26 / 8 / 3 |
| Food labor, plausible bounds | 18–85 | 15–85 | 12–85 | 8–80 | 5–75 | 3–70 | 2–65 |
| Households not primarily farming, % | 15 / 35 / 58 | 16 / 38 / 66 | 18 / 42 / 78 | 22 / 50 / 88 | 30 / 62 / 93 | 45 / 78 / 96 | 55 / 86 / 98 |
| Workforce in manufacturing, mining and building, % (new, `neither`) | 6 / 12 / 28 | 7 / 15 / 35 | 8 / 20 / 42 | 10 / 25 / 45 | 12 / 30 / 48 | 15 / 28 / 40 | 14 / 22 / 32 |
| Grain harvested per seed sown (wheat) | 5 / 10 / 20 | 5 / 10 / 20 | 6 / 11 / 22 | 6 / 12 / 24 | 7 / 14 / 28 | 10 / 25 / 45 | 12 / 30 / 55 |
| Energy captured, kcal per person per day | 16 k / 27 k / 38 k | 16 k / 30 k / 55 k | 17 k / 36 k / 80 k | 18 k / 45 k / 110 k | 20 k / 55 k / 150 k | 22 k / 75 k / 210 k | 25 k / 85 k / 200 k |
| Energy capture bounds | 9,000–45 k | 9,000–75 k | 9,000–110 k | 9,000–150 k | 9,000–200 k | 10 k–300 k | 10 k–450 k |
| Largest single project, person-days | 60 k / 3 M / 80 M | 60 k / 4 M / 100 M | 80 k / 5 M / 150 M | 100 k / 8 M / 200 M | 100 k / 15 M / 400 M | 200 k / 20 M / 500 M | 200 k / 20 M / 500 M |
| Largest project max | 300 M | 300 M | 400 M | 600 M | 1.2 B | 2 B | 2 B |

Why these values:

- **Food labor.** Agriculture held about 35% of the most industrial society's workforce in 1800, 22% in 1851 and 9% in 1911. It held 5% in 1950 and under 2% today.
  - A typical continental society went from about 60% in 1850 to about 30% in 1950 and 5–10% in 1990. The world was at 65% in 1950 and is about 26% today (Mitchell 2007, *International Historical Statistics*; Broadberry et al. 2015, *British Economic Growth 1270–1870*; ILO).
  - The game's Food allocation also counts processing and distribution, so the high row ends at 3% rather than 1.5%.
- **Secondary sector (new).** Manufacturing, mining and building took about 30% of the leading workforce in 1800, 43% in 1871 and a peak of about 48% in 1955. The share then fell to about 18% today. Late industrializers peaked lower and earlier ("premature deindustrialization": Rodrik 2016, *Journal of Economic Growth* 21).
  - The world share was about 15% in 1950 and 23% today (Broadberry et al. 2015; Herrendorf, Rogerson & Valentinyi 2014, *Handbook of Economic Growth* 2).
  - The metric is `better: neither`, because a high share is right in 1900 and a sign of lagging structural change by 2030. Focuses shift it but never boost it.
- **Yields.** English wheat yielded about 1:10 around 1800 and 1:12–15 by 1870 with drainage, guano and superphosphate. It reached about 1:20 by 1930 and 1:30–40 after synthetic nitrogen and new varieties. Modern wheat yields 7–9 t/ha from about 150 kg of seed, about 1:50–60 (Slicher van Bath 1963; Overton 1996, *Agricultural Revolution in England*; Federico 2005, *Feeding the World*; FAOSTAT).
- **Energy capture.** The metric continues `benchmarks_2400.json`, which uses Morris's measure of kcal per person per day; 1 GJ per year equals 655 kcal per day.
  - Morris puts the leading western core at about 38,000 in 1800, 92,000 in 1900 and about 230,000 in 2000 (Morris 2013, *The Measure of Civilization*, ch. 3).
  - The most industrial society used about 60–100 GJ per head in 1800–1850 against 15–25 GJ for organic economies. The leading consumer reached about 170 GJ in 1912, 230 GJ in 1950 and about 330 GJ around 1990, then fell toward 270 GJ with efficiency gains. The world average went from about 20 GJ in 1800 to 30 GJ in 1900, 40 GJ in 1950, 65 GJ in 1990 and about 80 GJ today (Kander, Malanima & Warde 2013, *Power to the People*; Smil 2017, *Energy and Civilization*; Fouquet 2008, *Heat, Power and Light*).
  - Typical rises from 27,000 to 85,000 kcal/day (41 → 130 GJ), and high from 38,000 to 210,000 before easing to 200,000. The max of 450,000 (about 690 GJ) is a small hydrocarbon exporter or a geothermal island today.
  - The focus file interpolates this metric on a log scale.
- **Construction.**
  - The largest canals and early trunk railways took about 10⁷ person-days. The largest interoceanic canals took about 10⁸: one employed 40,000–56,000 workers for a decade (McCullough 1977, *The Path Between the Seas*).
  - Mid-century national motorway programmes and the largest crash weapons and space programmes took 10⁸–10⁹ person-days each. The largest modern dams and rail networks take about 10⁸. That makes 5×10⁸ the best-plausible single project and 2×10⁹ the max.

## Knowledge, communication, the state and war

| Metric (low / typical / high) | 2400 | 2500 | 2600 | 2700 | 2800 | 2900 | 3000 |
|---|---|---|---|---|---|---|---|
| Major innovations per century (world) | 4 / 8 / 11 | 4 / 8 / 11 | 4 / 9 / 12 | 5 / 9 / 13 | 5 / 9 / 13 | 5 / 9 / 13 | 4 / 8 / 12 |
| Design items learned per 50-year block, % of that block's targets | 35 / 70 / 90 | 35 / 70 / 90 | 35 / 70 / 90 | 35 / 70 / 90 | 35 / 70 / 90 | 35 / 70 / 90 | 35 / 70 / 90 |
| Discoveries known, cumulative (provisional) | 1,435 / 2,875 / 3,695 | 1,500 / 3,000 / 3,855 | 1,560 / 3,125 / 4,020 | 1,625 / 3,250 / 4,180 | 1,690 / 3,375 / 4,340 | 1,750 / 3,505 / 4,505 | 1,815 / 3,630 / 4,665 |
| Discoveries known, bounds | 615–4,104 | 645–4,284 | 670–4,464 | 695–4,644 | 725–4,824 | 750–5,004 | 780–5,184 |
| Literacy, % of adults | 4 / 22 / 55 | 5 / 28 / 68 | 8 / 40 / 85 | 15 / 55 / 95 | 25 / 70 / 97 | 45 / 85 / 99 | 60 / 92 / 99 |
| Literacy max | 80 | 85 | 92 | 98 | 99 | 99.5 | 99.9 |
| News reach, % of households weekly (new) | 0.5 / 3 / 15 | 1 / 5 / 25 | 2 / 12 / 45 | 5 / 30 / 75 | 15 / 60 / 95 | 40 / 85 / 99 | 60 / 92 / 99.5 |
| Message speed, km per day | 40 / 80 / 250 | 50 / 150 / 1,500 | 100 / 1,000 / 20 k | 300 / 10 k / 40 k | 1,000 / 20 k / 40 k | 5,000 / 40 k / 40 k | 10 k / 40 k / 40 k |
| Trade reach, km | 1,500 / 10 k / 22 k | 1,500 / 12 k / 22 k | 2,000 / 14 k / 22 k | 2,500 / 15 k / 22 k | 2,500 / 15 k / 22 k | 3,000 / 17 k / 22 k | 3,000 / 18 k / 22 k |
| Institutional reach, km radius | 40 / 300 / 5,000 | 40 / 300 / 5,000 | 50 / 350 / 5,000 | 60 / 400 / 5,000 | 80 / 500 / 4,500 | 100 / 500 / 4,000 | 100 / 500 / 4,000 |
| State revenue, % of output (ordinary year) | 2 / 7 / 15 | 2 / 8 / 15 | 3 / 9 / 16 | 4 / 11 / 20 | 8 / 22 / 35 | 12 / 28 / 48 | 14 / 32 / 46 |
| Largest force fielded (people) | 2,000 / 30 k / 600 k | 2,000 / 30 k / 600 k | 2,000 / 35 k / 1.2 M | 3,000 / 60 k / 5 M | 3,000 / 80 k / 10 M | 2,000 / 40 k / 4 M | 2,000 / 30 k / 2.5 M |
| Largest force max | 1.5 M | 1.5 M | 2.5 M | 13 M | 15 M | 6 M | 4 M |
| Peak mobilization, % of all people | 0.5 / 2 / 5 | 0.5 / 1.5 / 4 | 0.5 / 2 / 5 | 1 / 4 / 12 | 1 / 5 / 13 | 0.3 / 1.5 / 5 | 0.3 / 1 / 4 |
| Peak mobilization max | 14 | 10 | 12 | 20 | 22 | 10 | 8 |
| Workers under arms or on watch, % (game Defense) | 2 / 5 / 11 | 1.5 / 4 / 9 | 1.5 / 4 / 9 | 2 / 4.5 / 10 | 2 / 5 / 12 | 1.5 / 3 / 7 | 1 / 2.5 / 5 |
| Mounted share of the largest force, % | 5 / 15 / 25 | 4 / 13 / 22 | 3 / 10 / 18 | 2 / 7 / 15 | 0 / 2 / 8 | 0 / 0 / 1 | 0 / 0 / 0.5 |

Why these values:

- **Literacy: toward universal.**
  - Adult literacy was about 12% worldwide in 1800 and 50–60% in the Protestant north-west (signature rates; Vincent 2000, *The Rise of Mass Literacy*; Buringh & van Zanden 2009).
  - Compulsory schooling laws (1840s–1880s) pushed the leaders past 90% by about 1900. The world reached 21% in 1900, 36% in 1950, 70% in 1990 and 87% today (van Zanden et al. 2014, *How Was Life?* ch. 5; UNESCO UIS).
  - Typical rises from 22% to 92%, and high reaches 99%: literacy becomes universal.
- **News reach (new).** Weekly newspapers reached a small minority of households in 1800. After the penny press and the telegraph (1840s–1870s), the leaders' mass dailies reached most households by 1900.
  - Radio reached 60–90% of households in the leaders by 1950, and television and then mobile phones reached near-universal coverage. About 95% of the world's people now live within mobile broadband coverage (Starr 2004, *The Creation of the Media*; ITU 2023).
- **Message speed.** This continues `benchmarks_2400.json`. The electric telegraph (the `electrical_telegraphy` milestone, game about 2533) takes the best service from optical-telegraph and relay speeds to effectively instantaneous on the wired network, and the submarine cables of the 1860s–1870s extend that worldwide.
  - The value 40,000 km/day stands for "anywhere on the globe the same day". Ordinary post travelled at rail speed, 500–1,000 km/day, until the telephone and radio (Headrick 1991, *The Invisible Weapon*).
- **Trade reach.** The whole globe was already within reach in 1800. The typical society's reach rises as steam shipping and the interoceanic canals open every region. The high is capped at about 22,000 km of route distance, and the max at 25,000.
- **Institutional reach.**
  - Continental national states registered people and enforced rulings across 500–2,000 km. The largest colonial empires ruled across oceans, and the telegraph made that practical after 1870 (Headrick 1981, *The Tools of Empire*).
  - Decolonization after 1945 shrinks the high and max: 4,000 km for continental federations, and 10,000 km for the few remaining overseas dependencies.
- **State revenue.** Central revenue was about 7–10% of output for a typical state before 1900. Only the most fiscal-military states raised 15–20%. The share jumped after 1914 and again after 1945, to 25–35% by 1950–1990 in industrial states and 40–55% in the most redistributive (Tanzi & Schuknecht 2000, *Public Spending in the 20th Century*; Lindert 2004, *Growing Public*). War years exceed the max and are covered by the total-war shock.
- **Armies and mobilization.**
  - The largest single field armies were about 600,000 around 1812 and 1.2 M in 1870. In the world wars, 5–13 M were under arms at once in a single state. The largest standing forces are about 2–2.5 M today.
  - At peak mobilization, great powers had 10–20% of their whole population under arms in 1914–18 and 1939–45 (about 12–13% at once, and 20% counting all who served). Since 1960 the figure is 0.5–1.5% (Broadberry & Harrison 2005, *The Economics of World War I*; Harrison 1998, *The Economics of World War II*).
  - `WAR_MOBILIZATION_CAP` in `tools/sim/shocks/catalog.py` (9% in 1860, 18% in 1914, 20% in 1945, 8% in 1960, 5% in 2030) agrees with these figures. The max of 20–22% at 2700–2800 matches it.
- **Cavalry.** Mounted troops were about 15–20% of large armies in 1800, 8–10% in 1914 and a few percent by 1939. They are gone after 1950. The max stays at 100% only while mounted steppe peoples still field armies (Showalter 2004; Keegan 1993, *A History of Warfare*).

**Innovation pace in the game.** No design registry exists yet for 2400–3000, or for 1200–2400 (`data/research/blocks.json` lists only `y0_600` and `y600_1200`).

- `discoveries_known` continues `benchmarks_2400.json`'s assumption: 4,104 items targeted by 2400, plus about 180 a game century, for about 5,184 by 3000. It keeps that file's 15% / 35% / 70% / 90% / 100% of the cumulative target.
- **Recompute both rows from the real blocks once they exist.** The per-50 band (35 / 70 / 90) is unaffected.
- **Milestones.** The 22 ids in the JSON are existing catalog ids from `scripts/technology_eras.gd` `HISTORICAL_YEAR` that fall in the window. The game year is in brackets:
  - **Power and materials:** steam propulsion (2464), electromagnetic induction (2483), steel refining (2549), internal combustion (2603), structural steel (2627), reinforced concrete (2627), catalytic ammonia synthesis (2701), nuclear fission (2768), jet propulsion (2771).
  - **Transport and communication:** rail track foundations (2523), electrical telegraphy (2533), telephone circuits (2659), powered flight (2675), triode valves (2683).
  - **Science and medicine:** cell theory (2504), preventive inoculation (2544), contagion mapping (2544), electromagnetic wave theory (2571), aseptic laboratory practice (2613).
  - **Computing and networks:** junction transistors (2803), stored-program control (2838), packet switching (2848).
  - They are judged against the registry's design bands once the block exists. Replace any that the block re-dates or gates on a resource.

## Allowed lead over history

The rule from the earlier windows carries over: play may lead history "within a reasonable deviation" only if every lead costs something elsewhere.

- **Milestones.** A milestone may land up to 2% of its design year early (48–60 game years, about 20 historical years), but never before `band_low`. Landing after `band_high` is a pacing failure.
  - The fraction is the same as `benchmarks_2400.json`'s 0.02. The 600–1200 window's 0.05 would allow 120–150 game years here, about 50 historical years, which would put the telephone before the telegraph.
- **Outcome facets.** The default stays at 15% of |high − typical| above `high`. `allowed_deviation.per_metric_over_high_fraction_of_typical_to_high_gap` sets it per metric:

| Lead allowed (share of the typical→high gap) | Metrics | Why |
|---|---|---|
| 0.25 | `largest_structure_person_days`, `major_innovations_per_century`, `trade_reach_km`, `message_speed_km_per_day` | order-of-magnitude or count metrics, where the record itself is ±25% |
| 0.20 | `literacy_pct`, `institutional_reach_km` | reconstructions vary widely |
| 0.15 | `life_expectancy`, `infant_mortality`, `child_mortality_1_4`, `maternal_per_100k`, `cdr`, `largest_settlement_historical`, `food_labor_share`, `non_food_population_share`, `grain_yield_ratio`, `discoveries_per_50_years`, `urban_share_pct`, `state_revenue_pct_output`, `energy_capture_kcal_per_capita_day`, `communication_reach_pct` | same as the earlier windows |
| 0.10 | `growth_pct`, `population`, `discoveries_known` | compounded or cumulative. A lead held for 600 years multiplies, so the margin is tighter |
| 0.00 | `tfr`, `cbr`, `settlement_density`, `army_levy_size`, `defense_labor_share`, `army_share_of_population_pct`, `cavalry_share_of_force_pct`, `manufacturing_labor_share_pct` | `better: neither`. Being above high is a different society, not a better one |

- **Trade-offs added in this window:**
  - **Coal and factories.** Energy and secondary-sector leads cost infant and adult mortality in the early decades, the urban penalty, until sanitation arrives about game 2650.
  - **Planning.** State-directed heavy industry costs yields, food labor and trade.
  - **Welfare.** Welfare-state health leads cost growth and fertility.
  - **Garrisons.** Permanent mobilization costs growth and trade, and raises total-war risk.

## Shocks widen the floor

The JSON block `shock_widening` gives the widening per shock type and per metric. Its rules are the same as in the earlier windows:

- **How the adjustments are written.** Each adjustment is `<field>_mult` or `<field>_add`.
- **When they apply.** Only to checkpoints whose window overlaps a logged shock and its recovery.
- **Combining shocks.** Concurrent shocks multiply their `_mult` values and add their `_add` values, but never past `hard_floor` (life expectancy 15, population 30, growth −3%/yr, CDR 90).

The hazards per game century follow `tools/sim/shocks/catalog.py` `HISTORICAL_BASE_RATES`, `modern` band. One game century here is about 38–40 historical years.

| Hazard key | Rate per game century | Note |
|---|---|---|
| `collapse` | 0.03–0.2 | systemic failure of a state and its economy |
| `pandemic_ge_1pct` | 0.3–1.2 | new here: waves that kill 0.5–3%, which is most of this era's pandemics |
| `pandemic_ge_5pct` | 0.0–0.3 | rare once sanitation and medicine arrive (`MEDICINE_CEILING` 0.8 → 0.95) |
| `pandemic_ge_25pct` | 0.0–0.03 |  |
| `famine_ge_2pct` | 0.05–0.6 | mostly before about game 2650, plus requisition famines to about 2850 |
| `economic_crisis` | 0.8–2.5 | banking panics, crashes and defaults |
| `depression` | 0.1–0.4 | new here: multi-year slumps |
| `general_war` | 0.2–0.8 |  |
| `total_war` | 0.0–0.6 | new here: mechanized mobilization, peak about game 2700–2790 |
| `upheaval` | 0.2–0.7 | revolutions and civil wars (the catalog's `upheaval`) |
| `invasion_migration` | 0.0–0.15 |  |

**Pandemic waves (peak risk about game 2400–2780).**

- Water-borne epidemics reached every port and rail town. The worst waves killed 1–3% of a city in a season (Evans 1987, *Death in Hamburg*; Hamlin 2009, *Cholera: The Biography*).
- The influenza pandemic at game about 2700 killed 1–3% of the world's people within two years (Johnson & Mueller 2002, *Bulletin of the History of Medicine* 76). Later pandemics killed 0.1–0.5%.
- **Widening:** population low × 0.95, life expectancy low −5 (min −3), CDR low +6 (max +10), infant and child mortality low +20, urban share × 0.95. **Recovery** takes 5–30 game years.

**Famine (to about game 2900).**

- Blight or drought in a society still living off its own harvest could kill 10–15% of people and drive as many to emigrate. Later, famines were mostly made by requisitioning and war (Ó Gráda 2009, *Famine: A Short History*; Davis 2001, *Late Victorian Holocausts*).
- **Widening:** population low × 0.85, growth low −0.4, life expectancy low −4, infant and child mortality low +40, food labor low +5, TFR low × 0.85.

**Financial panic (throughout).**

- A bank run, crash or sovereign default happens roughly once a decade somewhere (Reinhart & Rogoff 2009, *This Time Is Different*; Kindleberger & Aliber 2005, *Manias, Panics, and Crashes*).
- **Widening:** largest project × 0.5, trade reach × 0.85, energy × 0.92, secondary-sector low × 0.9. **Recovery** takes 3–15 game years.

**Depression (peak risk about game 2700–2800).**

- A prolonged slump after a financial collapse: 20–25% of the workforce idle, trade down by a third, births postponed (Eichengreen 1992, *Golden Fetters*).
- **Widening:** trade reach × 0.6, energy × 0.8, secondary-sector low × 0.75, TFR low × 0.85, growth low −0.2. **Recovery** takes 10–30 game years.

**General war (throughout).**

- A war between states with mass conscript armies but no full economic mobilization. **Widening:** population × 0.93, peak mobilization +3, Defense share +5, trade reach × 0.8, life expectancy −2.

**Total war (peak risk about game 2690–2800).**

- **What happens.** Railways, conscription and factory output let states put 10–20% of all people in uniform and turn half of output to war.
- **The toll.** The world wars killed about 1–2% of the belligerents' people in the first and 3–4% in the second, and 10–20% in the worst-hit states (Broadberry & Harrison 2005; Harrison 1998; Correlates of War).
- **Widening:**
  - population low × 0.8 (min × 0.85), growth low −0.5 (min −0.8);
  - life expectancy low −6 (min −5), CDR low +8 (max +15), infant mortality low +20;
  - peak mobilization high +8 (max +5), Defense share high and max +15, army size high × 1.5 (max × 1.3);
  - largest settlement low × 0.7 (bombing and siege), trade reach × 0.5, food labor +5;
  - TFR low × 0.8, secondary sector high +8 (max +5), energy low × 0.8.
- **Recovery** takes 15–50 game years. `WAR_MOBILIZATION_CAP` 18–20% is the absolute cap.

**Revolution (peak risk about game 2400–2850).**

- Revolutions and civil wars that overturn the regime, from the constitutional revolutions of the early nineteenth century to the social revolutions of the twentieth.
- **Widening:** population × 0.9, growth −0.3, institutional reach × 0.6, trade reach × 0.7, largest project × 0.5, life expectancy −3, energy × 0.85, Defense share +5. **Recovery** takes 10–40 game years.

**Systemic collapse (peak risk about game 2850–2950).**

- **What happens.** A planned or over-extended state fails as a system: supply chains and the currency break down, factories close, and the state fragments.
- **The record.** After the collapse of the planned economies (game about 2900), male e0 fell by about 6 years in the worst-hit successor state. Births halved, and output and energy use fell by a third to a half (Shkolnikov, McKee & Leon 2001, *The Lancet* 357; Kornai 1992).
- **Widening:** life expectancy low −6, population × 0.9, growth −0.6, energy × 0.6, secondary sector × 0.6, largest project × 0.2, institutional reach × 0.5, TFR × 0.7, infant mortality +15, CDR +5. **Recovery** takes 15–60 game years.

**Good play** is resilience, not immunity. Sanitation, stored food, relief institutions, diversified trade and legitimate government shorten recovery, but they do not prevent the shock.

## What the game must never show before year 3000

These are the "superhuman" signals. Each assumes no logged shock and is measured after the allowed lead.

- **Life, by date.**
  - Life expectancy above about 48 before 2500, 60 before 2700, 72 before 2800, 80 before 2900 or 86 at all.
  - Infant mortality below about 85 per 1,000 before 2500, 50 before 2700, 18 before 2800 or 1.5 at all.
  - Maternal mortality below about 150 per 100,000 before 2700.
- **Numbers and cities.**
  - Growth sustained above 1.6% a game year, or a founders' society above about 1.5 billion.
  - A city above about 4.5 M before 2600, 14 M before 2800 or 42 M at all.
  - An urban share above 55% before 2500.
- **Energy and schooling.**
  - Energy capture above about 75,000 kcal per person per day before 2500, 150,000 before 2700 or 450,000 at all.
  - Literacy above 85% before 2500.
  - News reach above 35% before 2500.
- **War.** More than about 14% of all people under arms before 2700, or more than 22% at any time.
- **Milestones.** Any milestone before its `band_low`. For example: telegraphy before game about 2480, powered flight before 2630, or transistors before 2760.
- **Effects.** Any effect total above its era ceiling (`SocietyModel.era_ceiling_for`).

## For the surrogate and check tools

- **Loading the file.** `tools/sim/facets.py` and `tools/research/benchmark_report.py` still read only `benchmarks_600.json`. Load every `benchmarks_*.json` and merge each metric's `years`; the 2400 row is identical in both files. For year > 2400, take `milestones.ids` and `allowed_deviation` from this file.
- **No absolute surrogate value.** Secondary-sector labor, news reach and energy capture have `probe_key: null`. The focus file maps them to proxy facets in `surrogate_proxies`: `cap_production`/`craft_output`, `cap_logistics`/`cohesion` and `cap_production`/`labor_efficiency`.
- **Check years.** `tune.py` `CHECK_YEARS` must be extended to 2500–3000, and runs must reach `--years 3000`.
- **The stretched clock.** The surrogate's vital rates must follow the per-game-year rates above, and its growth must stay inside the growth band. Transition-era natural increase of 1% a year (historical) held for 600 lived years would run 40 times past the population max. The simplest coupling is to scale net reproduction toward the CBR − CDR gap in this file.
- **Shock widening.** `shock_widening` is advisory data. The new hazard keys (`pandemic_ge_1pct`, `total_war`, `depression`) have no entries in `catalog.py` `HISTORICAL_BASE_RATES` yet.

## Join with the 1800–2400 window

- **Status.** Copied from benchmarks_2400.json for 29 metrics. Metrics copied: 29; own 2400 rows: manufacturing_labor_share_pct, communication_reach_pct.
- **Regenerating.** `benchmarks_2400.json` was still being written in parallel while this file was built. If it changes, regenerate this file (the generator re-copies the 2400 row) and re-check that the 2500 row still follows smoothly.
