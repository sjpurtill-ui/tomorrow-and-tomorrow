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
- `PACE_BY_YEAR` continues to 3000: 0.30 at 700, 0.20 at 1200, 0.17 at 1800, 0.15 at 2400, 0.10 at 3000.
- **Parallel capacity**: a staffed channel's progress × `1 + 0.25 × log10(population / 4,000) × lerp(0.6, 1.2, institutions) × (1 + literacy)` (1 below 4,000 people).
- **Superseded practice**: an item's relevance year is the latest design year among it and everything that transitively requires it. Past `STALE_GRACE` (60 years) its difficulty doubles every 30 years; past 4× it is abandoned (a running investigation pauses and keeps its progress). Foundations of current questions never go stale.
- Lines take up the current frontier before older leftovers (candidate score − 20 per 30 years behind), put dead ends (nothing later builds on them) last (−200), and do foundation work for their current questions before a deferred question.
- **A seeded half of dead ends per world** (`DEAD_END_VIABLE` 0.5, in `_path_is_viable`): which dead-end practices a society meets depends on its land and history. Key thresholds and every foundation stay open.

### Catalog contract (`scripts/technology_catalog_contract.gd`)
- The display identity check reads the live entry's name, which a design block may retitle. This fixes the 12 mechanics and 5 mathematics failures.

### Benchmarks
- `discoveries_known` rows after 1800 were provisional ("recompute when the block is baked"). `tools/research/rescale_known_benchmarks.py` recomputes them from the baked registry with the files' own shares (0.15 / 0.35 / 0.70 / 0.90 / 1.00 of the cumulative target): 4,164 items by 2400 and 5,737 by 3000 instead of 4,104 and 5,184.

<!-- RESULTS -->
