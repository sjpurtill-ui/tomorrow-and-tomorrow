# Phase 4: all-era rebalance, 0–3000 (research_3000)

Branch `codex/research-1200`. Targets: `benchmarks_{600,1200,1800,2400,3000}.json` and their focus files, judged with `tools/research/focus_bench.py`. Surrogate: `tools/sim` (`docs/research/SURROGATE_SIM.md`, section "0–3000").

## What was wrong

1. **Clamp saturation.** Every block's effects were authored against the flat modern clamps, so the all-line totals passed most clamps by 1200 (state capacity 1.69 against 0.90 at 1800, labor demand 2.7–4.2 against 0.35). Later discoveries did nothing and costs stopped biting.
2. **Pacing.** In the surrogate the later blocks either stalled (an inland one-territory world never unlocked coast, dry-country and later-resource foundations, and the fitted throughput drift was extrapolated over millennia) or, once those were fixed, learned the whole registry as soon as each gate opened.
3. **Modern mortality and fertility.** Research only removed the pre-modern excess over the baseline life table, so life expectancy stayed about 28 and infant mortality about 200 until 3000; fertility had no transition.
4. **Display identity.** 17 mechanics and mathematics ids failed the catalog contract because the design blocks retitle them.

## Engine changes

### Era ceilings to 3000 (`scripts/society_model.gd`)
- `MODERN_ERA` is 3000 (2030 CE). After 600 the ceiling closes the gap between the year-600 anchor and `EFFECT_LIMITS` along `LATER_RISE` (general keys: 0.10 at 1200, 0.20 at 1800, 0.33 at 2400, 0.70 at 2800, 1.0 at 3000) or `TECH_LATER_RISE` (technical keys, a little faster), or a key's own curve (`OWN_LATER_RISE`, `OWN_EARLY_RISE`).
- New keys, each era-capped and consumed: `modern_survival` (modern medicine and public health), `fertility_transition` (births couples choose not to have), `literacy` (share of adults who read), `farm_mechanization` (extra output per farm worker). Their own curves follow the benchmark rows century by century; literacy tracks 0.9 of the benchmark's high row, including the medieval dip.
- `SUSTAINABLE_SPECIALISTS` continues to 0.30 at 3000.

### Effect budget (`tools/research/rebalance_effects_3000.py`)
- All five blocks are budgeted together, key by key, in 50-year blocks. From 600 on, a block's benefits share one scale so the full-knowledge total follows the era ceiling (never scaled up; every value keeps at least 5%). The 0–600 benefits keep their Phase 3 balance.
- Costs follow a cost track (0.30 → 0.85 of the harmful bound from 0 to 3000) in every block, so a cost never passes its clamp and keeps biting. Full-knowledge labor demand is now 0.19 at 600 and 0.34 at 3000 (it was 1.65 and 4.19).
- The four new keys are placed from `tools/research/modern_transition_3000.json`: curated items with weights plus rules (for example every health item after 2250 for modern survival; schooling, child-labor law, pensions, women's rights and contraception across culture, labor, institutions, demography and knowledge for the fertility transition). The rebalance then scales them to their ceilings, so the values in the effect files are small and nothing arrives before its century.
- Pre-balance values are kept under each effect file's `balance_3000.source`; the pass is idempotent. Per-block scales: `docs/research/balance_3000_blocks.tsv`.

### Modern mortality and fertility (`scripts/early_life_conditions.gd`, `game_state.gd`, `consequence_engine.gd`)
- Mortality falls first: `modern_survival` up to `MODERN_BURDEN_LIFT` (0.22) clears the pre-modern burden; past `MODERN_TABLE_ONSET` (0.15) it also lowers the baseline table itself, reaching `MODERN_TABLE_DEPTH` (0.92) at `MODERN_TABLE_FULL` (0.55), weighted by band (children 1.0, adults 0.9, elders 0.75, newborns 0.85, mothers 1.0). Work accidents fall with the adult factor.
- Newborn and maternal floors are lowered (neonatal care 0.1, rate 0.0008; maternal care 0.02, rate 0.00002) so modern rates are reachable; they only bind in the modern era.
- The fertility transition = the `fertility_transition` total + 0.28 × (urban share − 0.25) + 0.22 × (literacy − 0.55), capped at 0.80, multiplies conceptions after every other factor.
- `ERA_BURDEN.maternal` 2.6 → 3.7: with a mapped river site birth attendants open, and maternal deaths fell to about 630 per 100,000 at 600 (past the benchmark high 800). They now sit at about 900.
- `TERRITORY_CAPACITY` continues to 60,000 per territory at 3000.

### Indicators (`scripts/civilization_indicators.gd`)
- `literacy()` is the era-capped literacy total. `urban_share()` = 0.91 × (1 − food labor share)^3.2, scaled from 0 for a band of 300 people to full at about 9,500.

### Food and labor (`scripts/food_system.gd`, `government_people_system.gd`)
- Cultivated staples × (1 + `farm_mechanization`).
- `FOOD_LABOR_FLOOR` follows the benchmark's typical food labor share to 3000 (0.08 at 3000).
- Planners release surplus food workers once stores hold 45 days and workers out-produce the need (down to 1.15 × the needed share); the floor still applies. Before this, the base weight kept 35–42% of labor on food forever.

### Research pacing (`scripts/research_600_catalog.gd`, `discovery_system.gd`)
- **Diffusion**: a line with no emphasis still works its first channel at team scale 0.4 (neighbours, traders, migrants).
- `PACE_BY_YEAR` continues to 3000: 0.30 at 700, 0.20 at 1200, 0.17 at 1800, 0.15 at 2400, 0.10 at 3000.
- **Parallel capacity**: a staffed channel's progress × `1 + 0.25 × log10(population / 4,000) × lerp(0.6, 1.2, institutions) × (1 + literacy)` (1 below 4,000 people).
- **Superseded practice**: an item's relevance year is the latest design year among it and everything that transitively requires it. Past `STALE_GRACE` (60 years) its difficulty doubles every 30 years; past 4× it is abandoned (a running investigation pauses and keeps its progress). Foundations of current questions never go stale.
- Lines take up the current frontier before older leftovers (candidate score − 20 per 30 years behind), put dead ends (nothing later builds on them) last (−200), and do foundation work for their current questions before a deferred question.
- **A seeded half of dead ends per world** (`DEAD_END_VIABLE` 0.5, in `_path_is_viable`): which dead-end practices a society meets depends on its land and history. Key thresholds and every foundation stay open.

### Catalog contract (`scripts/technology_catalog_contract.gd`)
- The display identity check reads the live entry's name, which a design block may retitle. This fixes the 12 mechanics and 5 mathematics failures.

### Benchmarks
- `discoveries_known` rows after 1800 were provisional ("recompute when the block is baked"). `tools/research/rescale_known_benchmarks.py` recomputes them from the baked registry with the files' own shares (0.15 / 0.35 / 0.70 / 0.90 / 1.00 of the cumulative target): 4,164 items by 2400 and 5,737 by 3000 instead of 4,104 and 5,184.

## Results

### Per era, before → after (surrogate, 3 seeds, no shocks)

Each cell reads before → after (benchmark low / typical / high). "Before" is the branch at 5966aed2 with the surrogate extended to 0–3000 (all blocks, realistic world); literacy and urban share did not exist then. The known benchmark rows after 1800 are the rescaled ones. `per_50` counts the block's items known by the block's end.

### balanced

| year | life_expectancy | infant_mortality | tfr | population | urban_share | literacy | known | per_50 |
|---:|---|---|---|---|---|---|---|---|
| 600 | 26.6 → 27.6 (22.0/28.0/35.0) | 223 → 209 (300/220/160) | 5.07 → 4.84 (4.50/5.60/6.50) | 3,295 → 3,512 (100/3,500/20,000) | n/a → 6 (0/8/20) | n/a → 1 (0/0/1) | 980 → 946 (390/790/1010) | 27 → 65 (25/70/90) |
| 1200 | 26.6 → 27.4 (22.0/28.0/37.0) | 222 → 211 (300/210/150) | 4.85 → 4.62 (4.30/5.30/6.30) | 10,727 → 32,977 (100/16,000/600,000) | n/a → 12 (3/12/28) | n/a → 9 (1/5/10) | 1695 → 1835 (730/1460/1880) | 27 → 73 (35/70/90) |
| 1800 | 27.4 → 27.5 (21.0/28.0/37.0) | 211 → 209 (300/205/150) | 4.87 → 4.56 (4.00/5.00/6.00) | 36,508 → 69,084 (100/48,000/8,000,000) | n/a → 13 (3/12/30) | n/a → 15 (2/8/20) | 2457 → 2572 (1060/2115/2720) | 17 → 65 (35/70/90) |
| 2400 | 27.8 → 28.9 (24.0/34.0/41.0) | 203 → 195 (280/185/125) | 4.62 → 4.38 (3.80/5.00/6.40) | 88,233 → 129,633 (120/170,000/22,000,000) | n/a → 20 (3/13/38) | n/a → 42 (4/22/55) | 2799 → 3456 (1457/2915/3748) | 9 → 62 (35/70/90) |
| 2600 | 28.2 → 34.8 (28.0/38.0/46.0) | 200 → 149 (260/170/105) | 4.56 → 4.22 (3.50/4.50/5.90) | 105,716 → 222,476 (150/360,000/73,000,000) | n/a → 25 (5/20/55) | n/a → 71 (8/40/85) | 2857 → 3865 (1624/3248/4176) | 3 → 70 (35/70/90) |
| 2800 | 28.2 → 58.4 (42.0/58.0/69.0) | 199 → 38 (150/70/30) | 4.52 → 2.87 (2.20/3.00/4.80) | 123,231 → 452,148 (250/885,000/231,000,000) | n/a → 40 (12/38/75) | n/a → 84 (25/70/97) | 2904 → 4325 (1836/3671/4720) | 0 → 67 (35/70/90) |
| 3000 | 28.2 → 79.7 (62.0/77.0/82.0) | 199 → 5 (40/8/3) | 4.44 → 2.12 (1.30/1.70/2.30) | 125,282 → 613,687 (300/1,780,000/660,000,000) | n/a → 56 (30/70/88) | n/a → 85 (60/92/99) | 2914 → 4679 (2008/4016/5163) | 2 → 59 (35/70/90) |

Centuries passing the focus judgement: before 0/30, after 6/30.

### sensible

| year | life_expectancy | infant_mortality | tfr | population | urban_share | literacy | known | per_50 |
|---:|---|---|---|---|---|---|---|---|
| 600 | 26.6 → 27.6 (22.0/28.0/35.0) | 223 → 209 (300/220/160) | 5.07 → 4.84 (4.50/5.60/6.50) | 3,308 → 3,528 (100/3,500/20,000) | n/a → 6 (0/8/20) | n/a → 1 (0/0/1) | 979 → 945 (390/790/1010) | 27 → 65 (25/70/90) |
| 1200 | 26.6 → 27.5 (22.0/28.0/37.0) | 222 → 210 (300/210/150) | 4.84 → 4.61 (4.30/5.30/6.30) | 10,780 → 33,093 (100/16,000/600,000) | n/a → 12 (3/12/28) | n/a → 9 (1/5/10) | 1685 → 1738 (730/1460/1880) | 27 → 51 (35/70/90) |
| 1800 | 27.5 → 27.6 (21.0/28.0/37.0) | 210 → 208 (300/205/150) | 4.87 → 4.55 (4.00/5.00/6.00) | 36,806 → 69,267 (100/48,000/8,000,000) | n/a → 14 (3/12/30) | n/a → 14 (2/8/20) | 2457 → 2423 (1060/2115/2720) | 18 → 47 (35/70/90) |
| 2400 | 27.9 → 29.0 (24.0/34.0/41.0) | 203 → 194 (280/185/125) | 4.61 → 4.38 (3.80/5.00/6.40) | 89,081 → 130,603 (120/170,000/22,000,000) | n/a → 20 (3/13/38) | n/a → 35 (4/22/55) | 2799 → 3210 (1457/2915/3748) | 9 → 42 (35/70/90) |
| 2600 | 28.3 → 33.3 (28.0/38.0/46.0) | 199 → 159 (260/170/105) | 4.55 → 4.33 (3.50/4.50/5.90) | 106,763 → 229,117 (150/360,000/73,000,000) | n/a → 24 (5/20/55) | n/a → 64 (8/40/85) | 2857 → 3584 (1624/3248/4176) | 3 → 52 (35/70/90) |
| 2800 | 28.3 → 57.4 (42.0/58.0/69.0) | 198 → 40 (150/70/30) | 4.51 → 2.97 (2.20/3.00/4.80) | 124,467 → 471,250 (250/885,000/231,000,000) | n/a → 41 (12/38/75) | n/a → 79 (25/70/97) | 2903 → 4020 (1836/3671/4720) | 0 → 55 (35/70/90) |
| 3000 | 28.3 → 79.3 (62.0/77.0/82.0) | 198 → 6 (40/8/3) | 4.43 → 2.13 (1.30/1.70/2.30) | 126,528 → 664,314 (300/1,780,000/660,000,000) | n/a → 56 (30/70/88) | n/a → 80 (60/92/99) | 2914 → 4395 (2008/4016/5163) | 2 → 49 (35/70/90) |

Centuries passing the focus judgement: before 0/30, after 6/30.

### research

| year | life_expectancy | infant_mortality | tfr | population | urban_share | literacy | known | per_50 |
|---:|---|---|---|---|---|---|---|---|
| 600 | 26.5 → 27.5 (22.0/28.0/35.0) | 225 → 211 (300/220/160) | 5.11 → 4.87 (4.50/5.60/6.50) | 3,063 → 3,276 (100/3,500/20,000) | n/a → 6 (0/8/20) | n/a → 1 (0/0/1) | 924 → 930 (390/790/1010) | 21 → 61 (25/70/90) |
| 1200 | 26.4 → 27.1 (22.0/28.0/37.0) | 224 → 214 (300/210/150) | 4.91 → 4.67 (4.30/5.30/6.30) | 10,089 → 31,059 (100/16,000/600,000) | n/a → 12 (3/12/28) | n/a → 10 (1/5/10) | 1533 → 1739 (730/1460/1880) | 21 → 61 (35/70/90) |
| 1800 | 27.0 → 27.1 (21.0/28.0/37.0) | 216 → 213 (300/205/150) | 4.95 → 4.62 (4.00/5.00/6.00) | 33,983 → 65,163 (100/48,000/8,000,000) | n/a → 13 (3/12/30) | n/a → 15 (2/8/20) | 2306 → 2456 (1060/2115/2720) | 16 → 54 (35/70/90) |
| 2400 | 27.3 → 28.3 (24.0/34.0/41.0) | 210 → 201 (280/185/125) | 4.72 → 4.47 (3.80/5.00/6.40) | 81,743 → 122,384 (120/170,000/22,000,000) | n/a → 20 (3/13/38) | n/a → 44 (4/22/55) | 2656 → 3268 (1457/2915/3748) | 7 → 48 (35/70/90) |
| 2600 | 27.6 → 33.0 (28.0/38.0/46.0) | 207 → 162 (260/170/105) | 4.66 → 4.39 (3.50/4.50/5.90) | 97,819 → 215,333 (150/360,000/73,000,000) | n/a → 25 (5/20/55) | n/a → 75 (8/40/85) | 2713 → 3660 (1624/3248/4176) | 3 → 61 (35/70/90) |
| 2800 | 27.7 → 56.7 (42.0/58.0/69.0) | 206 → 42 (150/70/30) | 4.63 → 2.98 (2.20/3.00/4.80) | 113,939 → 429,693 (250/885,000/231,000,000) | n/a → 40 (12/38/75) | n/a → 85 (25/70/97) | 2761 → 4102 (1836/3671/4720) | 0 → 60 (35/70/90) |
| 3000 | 27.6 → 73.8 (62.0/77.0/82.0) | 206 → 12 (40/8/3) | 4.55 → 2.22 (1.30/1.70/2.30) | 115,888 → 581,756 (300/1,780,000/660,000,000) | n/a → 55 (30/70/88) | n/a → 86 (60/92/99) | 2771 → 4432 (2008/4016/5163) | 2 → 51 (35/70/90) |

Centuries passing the focus judgement: before 0/30, after 6/30.

### poor

| year | life_expectancy | infant_mortality | tfr | population | urban_share | literacy | known | per_50 |
|---:|---|---|---|---|---|---|---|---|
| 600 | 22.6 → 26.7 (22.0/28.0/35.0) | 303 → 222 (300/220/160) | 5.51 → 5.16 (4.50/5.60/6.50) | 82 → 555 (100/3,500/20,000) | n/a → 2 (0/8/20) | n/a → 1 (0/0/1) | 369 → 691 (390/790/1010) | 0 → 26 (25/70/90) |
| 1200 | 24.1 → 25.5 (22.0/28.0/37.0) | 282 → 233 (300/210/150) | 5.38 → 4.95 (4.30/5.30/6.30) | 70 → 2,537 (100/16,000/600,000) | n/a → 2 (3/12/28) | n/a → 6 (1/5/10) | 484 → 899 (730/1460/1880) | 0 → 5 (35/70/90) |
| 1800 | 24.0 → 25.6 (21.0/28.0/37.0) | 284 → 230 (300/205/150) | 5.32 → 4.99 (4.00/5.00/6.00) | 76 → 1,793 (100/48,000/8,000,000) | n/a → 6 (3/12/30) | n/a → 7 (2/8/20) | 553 → 999 (1060/2115/2720) | 0 → 2 (35/70/90) |
| 2400 | 23.8 → 25.7 (24.0/34.0/41.0) | 282 → 228 (280/185/125) | 5.33 → 5.01 (3.80/5.00/6.40) | 84 → 841 (120/170,000/22,000,000) | n/a → 2 (3/13/38) | n/a → 7 (4/22/55) | 639 → 1054 (1457/2915/3748) | 0 → 0 (35/70/90) |
| 2600 | 23.8 → 25.9 (28.0/38.0/46.0) | 283 → 225 (260/170/105) | 5.30 → 4.99 (3.50/4.50/5.90) | 84 → 817 (150/360,000/73,000,000) | n/a → 2 (5/20/55) | n/a → 7 (8/40/85) | 669 → 1074 (1624/3248/4176) | 0 → 1 (35/70/90) |
| 2800 | 23.6 → 25.9 (42.0/58.0/69.0) | 282 → 225 (150/70/30) | 5.28 → 5.00 (2.20/3.00/4.80) | 85 → 815 (250/885,000/231,000,000) | n/a → 2 (12/38/75) | n/a → 7 (25/70/97) | 689 → 1091 (1836/3671/4720) | 0 → 0 (35/70/90) |
| 3000 | 23.7 → 25.9 (62.0/77.0/82.0) | 281 → 225 (40/8/3) | 5.28 → 5.00 (1.30/1.70/2.30) | 86 → 848 (300/1,780,000/660,000,000) | n/a → 2 (30/70/88) | n/a → 7 (60/92/99) | 712 → 1104 (2008/4016/5163) | 0 → 0 (35/70/90) |

Centuries passing the focus judgement: before 0/30, after 7/30.


### Pass rates (focus_bench: ABOVE FOCUS HIGH / OUT OF BOUNDS, UNPAID required cost, FREE LUNCH vs balanced)

| scenario | before (30 centuries) | after, no shocks | after, shocks | after, ignoring the balanced known cost |
|---|---:|---:|---:|---:|
| balanced | 0 | 6 | 6 | 29 / 29 (no shocks / shocks) |
| sensible | 0 | 6 | 5 | 28 / 28 |
| research | 0 | 6 | 5 | 26 / 24 |
| poor | 0 | 7 | 6 | 7 / 6 |

- The one failure left for balanced, sensible and research is **UNPAID balanced**: from 700 on, `benchmarks_focus_*` requires any run with a balanced component to know fewer discoveries than the base typical (70% of the registry). In this engine the design graph makes foundations mandatory and spreading emphasis over all lines is the most efficient way to reach them (Phase 3's finding), so balanced play knows 80–88% of the registry, between the typical and high rows. Meeting the rule would take a much slower pace that drops discoveries-per-50 below its minimum (tested: known 1,442 at 1200 needs per-50 of 2%). This is a conflict between the benchmark design and the research graph, reported rather than tuned away.
- Other remaining flags: growth once at 700 (the first daughter settlement adds 1.6 territories at once), literacy once at 1300 (the medieval dip) and knowledge's population cost unpaid in 4 early centuries.
- **Strategy sweep** (`STRATEGY_SWEEP.md`, 255 strategies × 1 seed × 3000 years, run before the diffusion rule): no free lunch against balanced and no strictly dominant strategy in any century; the Pareto front holds 9–40 strategies. Pass rates by window 82% (0–600), 22% (600–1200), 26%, 29%, 17% (2400–3000). Most later failures are single-line pairs and triples that put no emphasis on 10 of 12 lines: they fall out of bounds on discoveries-per-50 (minimum 20%) and, after 2400, on modern mortality and fertility.
- **Line matrix** (`LINE_MAX_MATRIX.md`, 3 seeds × 3000 years): every `lead_<line>` run (12 on its line, 1 elsewhere) passes almost every century from 800 to 2900; the flags are growth at 700 and fertility at 3000. The degenerate `max_<line>` runs (0 on every other line) stall and fall out of bounds on discoveries.

### Shocks (surrogate, balanced, per game century vs the benchmark hazard range)

Collapse, pandemics ≥ 1/5/25 %, upheaval and invasion/migration land inside or near their ranges; economic crises run high after 2400 (2.2 against 0.8–2.5 in the 3000 window, 0.4–1.5 in the 2400 window); **famine ≥ 2 % and general war run low** (0.06–0.17 per century against 0.5–2.0 and 0.2–1.0), because the player civ rarely goes to war or starves in the shock world. With shocks the per-era outcomes move little (balanced population at 3000: 614,000 → 565,000; e0 unchanged) and the pass rates are within one century of the shock-free runs.

### Calibration and real-engine checks

- `check.py`: OK, 7 truth runs within tolerance (score 120; 126 read at the truth's revision 6a9abee0). Truth: fresh 100-year runs (sensible 5150, research, poor ×2, AI, artifacts 50 y) and a 200-year sensible run.
- Later-era spot checks (`spot_check.py`, real engine seeded with the surrogate's society, 20–40 years): 0 values out of tolerance at 1200, 1800, 2400 and 2750 (population, e0, IMR, known, food security, health). The surrogate runs 1–3 years of e0 below the engine.
- `early_consequences_probe`: `EC_FAILURES []` for sensible, poor and focused. `test_research_600/1200/1800/2400/3000/blocks`, `test_early_life_conditions`, `test_mechanics_knowledge`, `test_mathematics_knowledge`: pass.
- The diffusion rule (`DIFFUSION_TEAM`) came after the last engine runs; under the no-engine-runs rule it is checked in the surrogate only. It changes the poor run most (it now learns care practices slowly and grows to about 550 people by 600 instead of a remnant of 80).

## Known limitations

- The balanced known cost (above) and the per-50 minimum for single-line strategies.
- Famine and war rates in the shock world are below the historical ranges.
- Population is inside every band but below the typical row after 2400 (614,000 against 1.78 million at 3000): one headless territory's capacity plus the surrogate's player model (one daughter settlement per 150 crowded years from 600).
- Food labor falls to about 13% by 3000 (typical 8%); urban share reaches about 56% (typical 70%).
- The surrogate's player model founds daughter settlements; the engine leaves that to the player.
- Some real-engine behaviour after the last engine run (diffusion) is only mirrored, not measured.

## Save compatibility

Old saves load. The new effect keys, early-care entries (`modern`, `fertility_transition`) and indicators are recomputed from known discoveries on the next day and default to "none" when absent. Known discoveries are never revoked: an item a world does not offer, or a superseded one, stays known if already learned; a running investigation on it pauses and keeps its progress. No save fields were added.

## Shared-file edits

Hotspots: `scripts/game_state.gd` (conception × (1 − transition); lower newborn and maternal floors) and `scripts/discovery_system.gd` (parallel capacity, staleness and dead ends in difficulty, eligibility and candidate score, foundations first, diffusion channels, per-world dead-end viability). Other shared scripts: `society_model.gd`, `early_life_conditions.gd`, `consequence_engine.gd` (reproduction context, work accidents), `civilization_indicators.gd`, `food_system.gd` (mechanization), `government_people_system.gd` (food floor, surplus release), `research_600_catalog.gd`, `technology_catalog_contract.gd`. Data: all 60 effect files (effects rewritten, `balance_3000.source` added) and the `discoveries_known` rows of `benchmarks_2400.json` / `benchmarks_3000.json`.

