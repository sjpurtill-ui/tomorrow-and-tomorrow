# Focus benchmarks for the 600-year window

User direction: "I WANT BENCHMARKS BASED ON FOCUSES!"

`benchmarks_600.json` gives every civilization one band per metric and game year. That single band cannot tell a society that chose war from one that chose granaries. This file gives each **focus** its own historical profile:

- **Higher bands on the focus metrics.** A focus may pace ahead of the generic band, within a stated deviation.
- **Lower bands elsewhere.** Every focus has a **required cost**: from game year 100 on, at least one directional metric has its typical below the base typical. This is the anti-dominance rule. Advantages carry costs elsewhere.

The surrogate can then judge each strategy against its own historical profile.

Files:

- `docs/research/benchmarks_focus_600.json` holds the machine-readable data (schema `benchmarks_focus/1`, window 0–600, base `benchmarks_600.json`).
- `docs/research/benchmarks_focus_1200.json` continues it for 600–1200. It uses the same schema, and its year-600 row copies this file's year-600 positions.
- `tools/research/focus_bench.py` resolves effective bands for either window, classifies strategies, judges runs and validates both files.

Game year 0 ≈ 5000 BCE, 100 ≈ 4000 BCE, 300 ≈ 3000 BCE, 600 ≈ 1500 BCE (`TechnologyEras.CURVE`).

## How a focus band is built

A **position** is a point on the base band's own scale, oriented so that larger is better. For `neither` metrics, larger simply means numerically larger.

| position | meaning |
|---|---|
| −2 | worse plausibility bound (min, or max for `lower` metrics) |
| −1 | base low |
| 0 | base typical |
| 1 | base high |
| 2 | better plausibility bound |

- Values between anchors are interpolated linearly. For the log-scale metrics (population, largest settlement, largest work, levy size, trade reach) they are interpolated geometrically.
- A focus modifier is the triple `[low, typical, high]`. Min and max never move, so a focus can never make a value that is implausible for the era plausible.
- Each focus metric uses a named preset at full effect:

| preset | [low, typical, high] | used for |
|---|---|---|
| boost+ / boost / boost- | [−0.5, 0.6, 1.35] / [−0.7, 0.35, 1.2] / [−0.85, 0.15, 1.08] | focus metrics |
| cost- / cost / cost+ | [−1.1, −0.2, 0.9] / [−1.25, −0.4, 0.75] / [−1.45, −0.65, 0.5] | costs |
| up+ / up / up- and down- / down / down+ | the same shapes for `neither` metrics | shifted metrics (levy, defense share, density, TFR, CBR) |
| steady | [−0.8, 0, 0.9] | balanced: higher floor, lower ceiling |
| peakless | [−0.9, −0.2, 0.7] | balanced: no era-leading works |

- **Ramp.** Presets are scaled by the ramp 0 / 0.5 / 0.85 / 1.0 at years 0 / 100 / 300 / 600: `by_year = neutral + ramp × (preset − neutral)`.
  - The 120 founders are the same whatever the player will choose, so required costs apply from year 100.
  - The 600–1200 file holds line focuses at full strength from 600.
- **Allowed lead.** A boosted metric may pass its *effective* high by 0.25 × |effective high − effective typical|. The exceptions are health 0.15, insular 0.15 and balanced 0.10.
  - Neutral metrics keep the base 0.15.
  - Cost and shifted metrics get no lead: shifted metrics must stay inside the shifted low..high.
- **Milestones.** `allowed_lead.milestone_early_fraction` is **absolute**, the same representation as the 600–1200 file: `{focus_lines, other_lines, floor}`.
  - Registry items in the focus's lines (`strategy.lines`) may land up to 25 % of the design year early (23 % for archetypes, 20 % for balanced and insular).
  - Other lines keep the base 20 %.
  - `band_low` stays the floor and `band_high` the ceiling. `fs.milestone_early_fraction(focus, line, year)` resolves this, including for blends.
- **Shock hazards.** `shock_hazard_mult` multiplies the per-century hazards of `tools/sim/shocks/catalog.py`, using the same values as the 600–1200 file for the same focus.
  - Values above 1: logistics and maritime get more epidemics, temple economies more collapse, militarised states more war.
  - Values below 1: ecology gets fewer famines and collapses, balanced slightly fewer famines, and insular fewer epidemics, collapses and wars.
  - Lower is better. The validator counts these as dimensions in pairwise dominance.
- **Two record metrics.** `largest_settlement_historical` and `major_innovations_per_century` are era-wide records in the base file. Here they are read as the largest settlement a society with this focus reached, and the innovations it originated. The 600–1200 file treats both as `context` and fades these effects out by 700.

## Strategy mapping (the surrogate's terms)

Research share = emphasis units on a line ÷ all units (the `research_emphasis` order, as in `sweep_strategies.py` / `matrix.py`). Classification, as implemented by `FocusBench.classify` and shared by both files:

1. **Explicit focus.** A strategy dict with `"focus_id"` is judged under that focus or blend. (`"focus"` in a spec is the settlement focus of `government_people_system.gd`.)
2. **Archetype.** An archetype matches when its three lines hold ≥ 55 % of units combined, ≥ 12 % each, and no line holds ≥ 40 %. The best combined share wins. Archetypes are matched on the raw research shares.
3. **Line focus.**
   - Each line with ≥ 25 % gets weight min(1, (share − 1/12) / (0.40 − 1/12)). The rest of the weight goes to `balanced`, and the focus is that blend (positions are averaged). So ≥ 40 % gives a pure line focus, and a 6/6 pair gives a 50/50 blend.
   - A line focus's labor/decree **signature** adds 0.15 to that line's share. Examples: Defense labor ≥ 8 % or `expanded_watch` for security; `knowledge_share` ≥ 15 for knowledge.
4. **Balanced.** No line at ≥ 25 %. The `balanced` (2 each) and `sensible` (max 3/22) baselines both land here.
5. **Timed strategies** (`phases`) are classified per phase. Judge a century by the phase active during most of it.

Canonical surrogate runs (`strategy.surrogate_spec` in the JSON; site `good`):

- **Line focuses** are `matrix.py lead_<line>`: 12 units on the line and 1 elsewhere, 52 % on the line.
- **Labor** is the sensible mix with the listed roles set. The other non-food roles absorb the difference in proportion.

| focus | research | knowledge_share | labor changes | decrees | signature |
|---|---|---:|---|---|---|
| knowledge | knowledge 12 of 23 | 17.5 | (rescaled by knowledge_share) | directed_inquiry | knowledge_share ≥ 15 or directed_inquiry |
| institutions | institutions 12 of 23 | — | Administration 9 | public_assembly, wealth_levy | Administration ≥ 8 or wealth_levy |
| culture | culture 12 of 23 | — | sensible | public_assembly | — |
| labor | labor 12 of 23 | — | sensible | labor_mobilization | labor_mobilization |
| production | production 12 of 23 | — | Crafting 22, Extraction 12 | craft_mobilization | Crafting ≥ 20 or craft_mobilization |
| infrastructure | infrastructure 12 of 23 | — | Construction 20 | emergency_building | Construction ≥ 18 or a building decree |
| nutrition | nutrition 12 of 23 | — | sensible | — | — |
| health | health 12 of 23 | — | sensible | care_rotation | care_rotation |
| demography | demography 12 of 23 | — | sensible | family_support | family_support / coercive_pronatalism |
| logistics | logistics 12 of 23 | — | Logistics 12 | route_priority | Logistics ≥ 11 or route/market decree |
| ecology | ecology 12 of 23 | — | sensible | conservation_order | conservation_order |
| security | security 12 of 23 | — | Defense 9 | expanded_watch | Defense ≥ 8 or watch/conscription |
| balanced | 2 on every line | — | sensible | — | — |
| militarised agrarian state | security 5, nutrition 5, institutions 4 (61 %) | — | Defense 9, Administration 6 | conscription_drive, labor_mobilization | — |
| maritime trading league | logistics 6, production 5, culture 3 (61 %) | — | Logistics 12, Crafting 18 | route_priority, market_deregulation | — |
| temple / scribal economy | institutions 5, knowledge 5, culture 4 (61 %) | 10 | Administration 8 | directed_inquiry, public_assembly, wealth_levy | — |
| expansionist settler state | demography 5, logistics 4, security 4 (59 %) | — | Logistics 9, Defense 5 | family_support | — |
| insular subsistence people | ecology 6, nutrition 4, health 4 (61 %) | — | Food 42, Knowledge 3, Logistics 4.5, Crafting 10, Construction 10 | conservation_order | — |

Every canonical spec classifies to its own focus (checked with `focus_bench.classify` at years 300 and 800).

## Headline differences at year 600 (≈ 1500 BCE)

Values are the effective typical. The arrow shows the base typical → the focus typical. "Band" gives the focus's effective low–high where only the band edges move.

| focus | boosted | costs | shifted / band | required costs (any one) |
|---|---|---|---|---|
| knowledge | non-food hh % 22→24; per-50 % 70→82; major innov. 3.0→3.7; literacy % 0.5→0.8 | growth % 0.3→0.2; pop 3,500→1,719; largest work 300k→77k | levy 2,000→936; defense % 5.0→4.6 | largest work, pop, growth % |
| institutions | largest settlement 5,000→12k; non-food hh % 22→28; largest work 300k→2.5M; literacy % 0.5→0.57 | e0 28→26; IMR 220→236; 4q1 170→182 | density 180→198; levy 2,000→2,825 | e0, 4q1 |
| culture | largest settlement 5,000→7,259; largest work 300k→1.0M; trade km 2,000→2,219 | growth % 0.3→0.2; food labor % 52→55; per-50 % 70→63; major innov. 3.0→2.8 | — | per-50 %, food labor %, growth % |
| labor | food labor % 52→45; non-food hh % 22→28; yield 10→12; largest work 300k→508k | e0 28→27; MMR 1,150→1,260; CDR 37→38 | — | e0, MMR, CDR |
| production | non-food hh % 22→32; largest work 300k→508k; per-50 % 70→73; major innov. 3.0→3.7; trade km 2,000→2,549 | e0 28→27; growth % 0.3→0.2; yield 10→9.0 | — | e0, growth %, yield |
| infrastructure | largest settlement 5,000→22k; non-food hh % 22→24; yield 10→12; largest work 300k→2.5M | IMR 220→236; 4q1 170→182; CDR 37→40 | density 180→228 | IMR, CDR |
| nutrition | e0 28→29; 4q1 170→162; growth % 0.3→0.48; pop 3,500→6,442; food labor % 52→48; yield 10→16 | largest work 300k→152k; per-50 % 70→63; trade km 2,000→1,149 | levy 2,000→1,505 | per-50 %, trade km |
| health | e0 28→30; IMR 220→199; 4q1 170→152; MMR 1,150→1,028; CDR 37→35; growth % 0.3→0.37 | food labor % 52→55; non-food hh % 22→20; largest work 300k→152k | — | food labor %, largest work |
| demography | MMR 1,150→1,098; growth % 0.3→0.6; pop 3,500→9,960 | 4q1 170→182; food labor % 52→58; non-food hh % 22→20 | TFR 5.6→6.2; CBR 42→45 | food labor %, 4q1, non-food hh % |
| logistics | largest settlement 5,000→7,259; non-food hh % 22→24; per-50 % 70→73; major innov. 3.0→3.3; trade km 2,000→3,031 | IMR 220→236; CDR 37→38; yield 10→9.0 | — | CDR, yield |
| ecology | e0 28→29; 4q1 170→162; CDR 37→36; yield 10→12 | growth % 0.3→0.1; pop 3,500→844; largest settlement 5,000→1,991; non-food hh % 22→20; largest work 300k→152k | — | pop, growth %, largest settlement |
| security | largest settlement 5,000→7,259; largest work 300k→508k | e0 28→27; growth % 0.3→0.2; food labor % 52→58; per-50 % 70→63 | density 180→198; levy 2,000→10k; defense % 5.0→8.5 | food labor %, growth %, e0 |
| balanced | — | largest work 300k→152k; major innov. 3.0→2.8 | floor raised and ceiling lowered on 13 metrics (e.g. e0 band 23–34, pop 204–17k, per-50 % 42–88) | major innov., largest work |
| militarised agrarian state | growth % 0.3→0.37; pop 3,500→4,546; largest settlement 5,000→7,259; yield 10→14; largest work 300k→1.0M | e0 28→26; 4q1 170→182; per-50 % 70→63; trade km 2,000→1,516 | levy 2,000→10k; defense % 5.0→7.0 | e0, 4q1 |
| maritime trading league | largest settlement 5,000→7,259; non-food hh % 22→32; per-50 % 70→73; major innov. 3.0→3.7; trade km 2,000→3,031 | CDR 37→38; growth % 0.3→0.2; pop 3,500→844; yield 10→8.0 | levy 2,000→936; defense % 5.0→4.6 | pop, yield, CDR |
| temple / scribal economy | largest settlement 5,000→12k; non-food hh % 22→32; largest work 300k→2.5M; per-50 % 70→77; major innov. 3.0→3.3; literacy % 0.5→0.8 | e0 28→27; IMR 220→236; growth % 0.3→0.2 | density 180→198 | e0, growth % |
| expansionist settler state | growth % 0.3→0.6; pop 3,500→9,960; trade km 2,000→2,219 | 4q1 170→182; largest settlement 5,000→1,991; largest work 300k→77k; per-50 % 70→63 | TFR 5.6→6.0; CBR 42→44; density 180→148; levy 2,000→5,024; defense % 5.0→5.8 | largest settlement, largest work, 4q1 |
| insular subsistence people | e0 28→29; IMR 220→211; 4q1 170→162; CDR 37→36 | growth % 0.3→0.1; pop 3,500→347; largest settlement 5,000→1,119; food labor % 52→55; non-food hh % 22→14; yield 10→9.0; largest work 300k→33k; per-50 % 70→56; major innov. 3.0→2.6; trade km 2,000→1,149 | density 180→148; levy 2,000→936 | pop, non-food hh %, per-50 % |

Any year and metric can be read with `python tools/research/focus_bench.py table <focus> <year>`, or `band <focus> <metric> <year>`.

## Calibration notes (real history; never in game data)

Each focus is calibrated to the generic range stated in its JSON `calibration` field. The examples behind those ranges:

- **Knowledge.** Calendar and record keepers: Late Neolithic and Chalcolithic token and tally systems, Uruk proto-cuneiform accounting, Egyptian astronomical calendars. Specialists were about 1–3 % of adults. Literacy stayed under 1 % before 1500 BCE (Baines 1983; Postgate 1994). The labor cost follows the engine: the Knowledge labor share draws from construction, crafts and defense.
- **Institutions.** Early Dynastic and Ur III Mesopotamia, and Old Kingdom Egypt. Corvée works reached 10⁶–10⁷ person-days (Lehner 1997). Skeletal series show stature loss and enamel hypoplasia under early states, with no gain in e0 (Cohen & Armelagos 1984; Scott 2017, *Against the Grain*).
- **Culture.** Non-state monument builders: Göbekli Tepe, Maltese temples, Orkney and Stonehenge, Carnac. Monuments ran to 10⁴–10⁶ person-days. Feasting consumed the surplus (Dietler & Hayden 2001). Long-distance prestige goods included Alpine jade axes (about 1,500 km) and Spondylus shell.
- **Labor.** Plough and draught-animal intensification: the secondary products revolution (Sherratt 1981). The skeletal burden shows as osteoarthritis, and quern-related pathology in women (Molleson 1994).
- **Production.** Varna and the Balkan copper province, Chalcolithic Levant, Early Bronze Anatolia. Arsenical copper toxicity and charcoal demand were the costs. Craft households were about 10–20 %.
- **Infrastructure.** Walled towns such as Jericho, Habuba Kabira, Mohenjo-daro and Uruk. Densities were 150–300 per hectare. The urban penalty of crowd disease is documented for later towns (Wrigley; Scheidel 2001), and early towns showed high infant death.
- **Nutrition.** Intensive mixed farming as reconstructed by Bogaard (2004) and Halstead (2014). Irrigated yields were 1:10–1:20. Villages were self-sufficient, with narrow exchange.
- **Health.** Long-term care of the disabled, such as the Man Bac burial (Tilley 2015). Egyptian medical practice is known from papyri that postdate the window. e0 gains stay a few years; maternal deaths stay at 500 per 100,000 or more (Loudon 1992).
- **Demography.** The Neolithic demographic transition (Bocquet-Appel 2011), with TFR 6.5–7.5. Earlier weaning raised mortality at ages 1–4.
- **Logistics.** The Uruk expansion colonies, obsidian networks, lapis lazuli from Badakhshan to Egypt (about 4,000 km), the Dilmun and Magan trade. Travellers were exposed to disease, and the road took field labor.
- **Ecology.** Jōmon Japan, the Northwest Coast, and Ertebølle Denmark before farming. These were stable and healthy at low density, with small villages and few specialists.
- **Security.** Talheim and Schöneck-Kilianstädten (LBK massacre sites), fortified Chalcolithic and Early Bronze villages, the Tell Brak walls. Violent trauma appears on 10–20 % of skeletons in contested zones.
- **Balanced.** The ordinary farming village world of the era: a broad base that gives fewer collapses, but no era-leading works.
- **Militarised agrarian state.** Akkad, the Early Dynastic city wars, Middle Kingdom Nubian forts, the Hittite levy toward 1500 BCE. Levies reached thousands to tens of thousands.
- **Maritime trading league.** Early Cycladic and Minoan Crete, and the Dilmun and Gulf trade. Populations were small on thin arable land, while the share of crafts was high.
- **Temple / scribal economy.** Ubaid and Uruk temple households, and the Lagash and Ur III ration lists. Writing arose from accounting (Nissen, Damerow & Englund 1993).
- **Expansionist settler state.** The LBK expansion across Central Europe (about 5500–4900 BCE): 1–1.5 %/yr growth, uniform longhouse villages, massacre sites at the frontier (Shennan 2018).
- **Insular subsistence people.** Late Jōmon, Neolithic island communities, and forager enclaves beside farmers.

## What the surrogate needs to judge each run against its focus profile

The requirements below apply to `tools/sim/facets.py`, `matrix.py` and `sweep_strategies.py`. The helper side is done; each item is an edit to `tools/sim`, which this task did not touch.

1. **Pass the full strategy to the model.**
   - `sweep_strategies._run` builds `scenario_override` from `research`, `knowledge_share` and `phases` only, and forces sensible labor.
   - It should also pass `labor`, `policies` and `scouting` from the strategy dict. Without them, security and production runs cannot move labor, and decree-based signatures have no effect.
   - The canonical specs are `focuses[*].strategy.surrogate_spec`. Add them as a `kind: "focus"` strategy family by loading the two focus JSON files.
2. **Expose `defense_share` as a facet.** It is already in each surrogate row. Map it to `defense_labor_share`, as `focus_bench.FACET_TO_METRIC` does.
3. **Classify every run.** Call `fs.classify(strategy, year=c)` per century; phases are handled. Store the resulting focus or blend with the run.
4. **Judge with the focus band instead of the generic one.**
   - Replace `facets.flag(bench, f, c, v)` with `fs.judge(focus, FACET_TO_METRIC[f], c, v)`. It returns `within`, `above high (allowed)`, `ABOVE FOCUS HIGH`, `below low` or `OUT OF BOUNDS`.
   - In `sweep_strategies.py`, count "benchmark exceedances" as `ABOVE FOCUS HIGH` or `OUT OF BOUNDS` under the run's own focus.
   - Keep the generic flags as a second column for comparison.
5. **Enforce the cost.** Call `fs.check_run(focus, {century: facets}, balanced={century: balanced_facets})`. It returns:
   - required-cost status per century: `paid`, `UNPAID` or `unmeasured`. This counts only surrogate-measured metrics (probe_key) worse than the base typical.
   - relative status per century against the same-seed balanced run on `focuses[*].surrogate.boost_facets` and `cost_facets`, with a ±2 % margin: `paid`, `FREE LUNCH` or `no effect`.
   - `ok`. Report `UNPAID` and `FREE LUNCH` runs; they replace the old "free lunch vs balanced" list.
6. **Milestones.** Replace the single `milestone_early_fraction` in `sweep_strategies.py` with `fs.milestone_early_fraction(focus, row['line'], design_year)`.
7. **Shocks** (`--shocks`). Scale the catalog hazards by `fs.shock_hazard_mult(focus, year)`, which both windows now set. Judge shock-hit centuries with benchmarks_1200.json `shock_widening` as before.

## Validation

`python tools/research/focus_bench.py` (default `validate`) currently gives **0 errors and 1 warning** over both files. The checks are:

- schema and metric keys;
- roles consistent with each metric's `better` direction;
- positions ordered and within ±2;
- resolved bands in order at every checkpoint;
- every focus has a cost metric and a non-empty required cost that sits below the base typical from `from_year`;
- no focus is better-or-equal to the base typical on every directional metric;
- no real historical names in either JSON (word-boundary match);
- continuity of the year-600 join (none reported).

Warnings list pairwise dominance between focuses (band typicals plus shock hazards), pair blends with no cost left, and focuses whose required costs the surrogate cannot measure. The one current warning is balanced (see below).

## Known limitations

- **Insular subsistence has band typicals no better than health's.** Its advantage is resilience: lower pandemic, collapse and war hazards. It is therefore not reported as dominated, but its band profile is deliberately a low-ambition choice.
- **Balanced's required costs are not measured by the surrogate.** Its costs are largest work and major innovations, and neither has a probe_key. It is the reference run for every relative check, so the surrogate enforces it through its lowered ceilings (high position 0.9 or 0.7, lead 0.10).
- **Blends average positions.** A 6/6 pair of two line focuses keeps both components' costs only on average. The validator raises no pair-blend warning for the current profiles.
- **The surrogate sits far outside the base bands today** (for example population in the millions at 600 in `LINE_MAX_MATRIX.md`). Focus bands cannot fix calibration: every focus keeps min/max unchanged, so those runs stay `OUT OF BOUNDS` under any focus.
- **`food_labor_share` barely responds to strategy in the surrogate** until labor is passed through (item 1 above). Several required costs (security, culture, health, demography) rely on it.
