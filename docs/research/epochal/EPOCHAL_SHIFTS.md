# Epochal shifts: shocks, collapses and the rise of new peoples

Status: modelled, not baked in. The model lives in `tools/sim/shocks/` and runs on its own: `python -m tools.sim.shocks.demo`. SIM integrates it only **after** the years 600–1200 research pass is baked in. Its eras already run past year 600, through iron-age, classical, medieval, early-modern, industrial and modern conditions, so it is ready for that later step. No SIM or game file was changed.

User direction: *"We also need to think about epochal shifts… We don't need to bake this in right away, but we should model it."* Later directions: *"I don't want the shocks to be named after real history, this is alternative history,"* and *"New civs should be able to arise throughout the game as well, including those that 'rise from the ashes'."*

## 1. Principles

1. **Emergent, never scheduled.** No shock is tied to a calendar date. Each one starts from a hazard computed from a civ's current condition: crowding, trade, stores, legitimacy, inequality, overreach, mobilisation, alliances and accumulated strain. Once started, it spreads through the contact, trade, war and alliance graph. The same world can live through three plagues in a century, or none.
2. **Same rules for everyone.** AI civs and the player's people face identical hazards. The player's divine acts change the *conditions* that the hazards read. They never switch hazards off.
3. **No victory, no defeat.** A collapse ends a state, not the game. The god always has a people (§6.4). History continues after every catastrophe.
4. **Historically plausible ranges.** Frequencies, magnitudes, durations and recovery times sit inside the ranges in §9. The same model has to produce both the dark centuries and the rebounds.
5. **Alternative history.** Real events are used only as calibration (§9–§10). Every shock and people is named in-world (§7).
6. **The god sees consequences.** The god hears omens through the court, acts through commands the engine always answers, and reads what happened in the chronicle.

## 2. Two clocks

- **Lived clock (game years).** People are born and die on the game calendar. Rates for what a population *lives through* (plagues, famines, wars, collapses) are therefore per **game** century. A villager's lifetime sees about as many plagues as a historical one did.
- **Era clock (historical year).** `TechnologyEras.CURVE` squeezes 7,000 years of technique into 3,000 game years: game 600 is about 1500 BCE, 1200 is about 350 CE, 2000 is 1600 and 3000 is 2030. Each civ's era is **its own knowledge frontier** (`era_year`). The era decides which shocks can exist at all and how big they get. For example, there is no coinage crisis before credit and no industrial mass mobilisation before industry. A lagging civ keeps pre-modern hazards while its neighbour industrialises.

## 3. Taxonomy

Legend: **T** triggers (emergent conditions), **P** propagation, **M** magnitude, **D** duration, **R** recovery and paradoxical after-effects, **±** what lowers (−) or raises (+) the risk. `[Cn]` are calibration references in §10.

### 3.1 Pestilence (`pandemic`)
Generic kinds: `fever`, `pestilence`, `great_pestilence`, `stranger_sickness`.
- **T.** A new pathogen appears where people are crowded (density), trade is far-reaching, hunger has weakened bodies and armies camp. The disease stock (`disease_endowment`, from domesticated animals) sets the pathogen pool.
- **P.** Each wave hits a civ once. It jumps along contact × trade links, and war links add to the chance. Quarantine (health knowledge × institutions) cuts transmission by up to 70%. Immunity after a wave fades with a half-life of about 18 years as new generations grow up, so endemic killers **return every 8–20 years, weaker each time** (up to 6 recurrences).
- **Virgin soil.** When contact first joins two pools that differ by more than 0.3, the naive people suffer 3–6 waves of the "strangers' sickness". Their pool rises about a third of the way toward the foreign one with each wave. Total mortality across the waves reaches 60–95% [C4]. These waves cannot spread back into the source population.
- **M.** Single-wave mortality = virulence (lognormal, median 6%) × (0.5 + density) × (1 − immunity) × (1 − medicine)² × (1 + 0.6 × famine) × virgin factor, capped at 60%. `medicine` = health knowledge × an era ceiling (0.35 early to 0.95 modern), so modern medicine is decisive and early medicine is weak [C1–C5].
- **D.** Each wave is front-loaded over 1–3 years.
- **R.** Legitimacy −0.4m, cohesion −0.3m and institutions −0.5m proportionally, where m is the wave's mortality. The paradox is labour scarcity. For 30 years afterwards productivity rises by 0.6m and inequality falls by 0.6m. Knowledge rises by 0.12m, as labour-saving invention follows, and health knowledge by 0.15m, as quarantine is learned [C2][C19].
- **±** − sanitation, quarantine, stores, lower density. + famine, war camps, far trade, crowded cities.

### 3.2 Hunger (`famine`)
Generic kinds: `hunger`, `great_hunger`.
- **T.** A food shortfall forms from this year's harvest: weather noise, climate episodes, war, collapse and migration losses, plus population pressure above 85% of capacity. It is offset by a buffer of stores, trade (unless partners are short too), relief institutions and diverse food sources. The annual probability is a small background dearth risk that rises steeply with the shortfall, plus near-certain famine when the gap is wide. After a famine comes a 6-year refractory spell, because stores are rebuilt and there are fewer mouths.
- **P.** Famine is local, but it pushes emigrants outward, which raises migration pressure next door, and it feeds pestilence.
- **M.** Mortality 0.2–25%, typically 2–6%. Emigration is 0.5% + 0.3m. Stores are emptied. Legitimacy takes a hit: bread riots and doubt about the god.
- **D.** 1–2 years.
- **R.** Survivors have more land each, so there is a Malthusian relief.
- **±** − stores, granaries, many food sources, trade, relief institutions, fertiliser and rail in the modern era. + drought, war, crowding, a single staple.

### 3.3 Climate (`climate`, exogenous)
Generic kinds: `cold_year`, `long_winter`, `drought_years`, `great_drought`, `cold_age`.
- **T.** Exogenous Poisson processes:
  - notable eruption year: 1.3 per century;
  - double-eruption long winter with a decade-long tail: 0.10 per century;
  - regional multi-decade drought (12–280 years): 0.14 per region per century;
  - multi-century cold age (150–420 years), which also raises harvest variance by 60%: 0.04 per century [C6–C8].
- **P.** Volcanic and cold events hit every living civ. Droughts hit one region.
- **M.** Food loss is scaled by vulnerability, which falls with food diversity and with modern agriculture. Long winters take 20–70% off the first harvest.
- **R.** Recovery is slow when drought persists: median 44 years to regain population. Droughts push emigrants and drive the drought → hunger → migration → war → collapse chain.
- **±** − diversification, stores, trade in unaffected regions. + a single staple, marginal land, a region-wide drought.

### 3.4 War of many peoples (`war`)
Generic kinds: `general_war`, `grinding_war`, `war_of_opportunity`, `war_of_many_peoples`.
- **T.** Two routes:
  - **Escalation** of an ordinary host war. The hazard rises with alliance entanglement (the allied share of both principals) and arms races (mobilisation).
  - **Pressure wars** between neighbours, from migrant floods, a schism on either side, a collapsing neighbour (a power vacuum), famine, or a military-technical edge.
- **P.** Allies answer the call with a chance that falls with distance and with each link in the chain. Blocs therefore form but seldom swallow the world. Trade across the front drops to 20%.
- **M.** Mobilisation is capped by era: about 3–7% of the population pre-modern, 18–20% in the industrial mass-war era, and falling after it. Total deaths (military, civilian and disease) have an era median of 3–7%, lognormal, capped at 45%. The weaker side hosts the fighting and suffers ×1.8. A war whose mobilisation reaches 12% or more becomes a `war_of_many_peoples`. One lasting 20 years or more becomes a `grinding_war` [C9–C11].
- **D.** Era median 4.5–10 years, up to 32.
- **R.** Winners gain institutions (war makes states). Losers lose 0.1–0.3 legitimacy and gain strain, which drives later collapses. Mass mobilisation levels inequality (−0.12) and speeds industry, knowledge and medicine [C11][C19].
- **±** − few alliances, low mobilisation, strong cohesion without doctrinal quarrels. + alliance webs, arms races, schisms, vacuums, technological imbalance.

### 3.5 Migration and invasion (`migration`)
Generic kinds: `border_migration`, `folk_wandering`, `rider_raids`, `horde_conquest`.
- **T.** Pressure = steppe exposure × nomad-era factor × (1 + 2.5 × regional drought) + 6 × neighbours' emigrant outflow. The nomad-era factor rises with chariots, then mounted archery, and falls with gunpowder. It is amplified by weak institutions and strain, and damped by mobilisation.
- **P.** Emigrants from famine, collapse and drought are routed each year to neighbours in proportion to contact and room to live; 30% are lost on the road.
- **M.** Severity s = Beta(1.3, 3.5) × pressure. Deaths 1% + 22%·s^1.5. Legitimacy, cohesion and institutions fall, up to 40%·s. Steppe peoples arrive from beyond the map (2–14% of the host population). About half of the invasions with s > 0.6 are **conquests**, with a new ruling class: inequality up, then institutional rebuilding [C12–C14].
- **D.** 2–40 years.
- **R.** A conquest leaves a hybrid order. Large migrations can found a new people (§6).

### 3.6 Coin and credit crises (`economic`)
Generic kinds: `debt_crisis`, `coin_ruin`, `broken_treasury`, `market_crash`.
- **T.** Only in credit economies. Driven by war spending (mobilisation above 3%), overreach, weak institutions, trade partners already in crisis (contagion), active war, strain and debt-driven inequality.
- **M.** Output −6% to −36% (hump-shaped), legitimacy −0.3·s, inequality +0.08·s, trade down.
- **D.** 3–50 years.
- **R.** With probability equal to institutional strength, a **reform** follows (debt remission, recoinage, a fiscal settlement): institutions +0.05, inequality −0.1·s [C15][C16].

### 3.7 Schism and overturning (`upheaval`)
Generic kinds: `prophet_schism`, `new_faith`, `great_schism`, `overturning`.
- **T.** Grief and strain, inequality, falling legitimacy, and literate, trading societies where ideas travel. Contagious across contact.
- **M.** Cohesion −0.4·s, legitimacy −0.3·s, a small institutional loss. Raises pressure-war risk with neighbours.
- **D.** 8–80 years.
- **R.** A new synthesis follows: cohesion +0.25·s and knowledge +0.04·s over 20 years. **For this game an upheaval is theological.** It is a prophet, a heresy or a rival cult arguing about *the god*. The god's response decides whether it becomes renewed reverence, dread, or apostasy (§8) [C17].

### 3.8 New craft (`tech`)
Generic kinds: `new_metal`, `press_and_powder`, `engine_age`, `lightning_age`, `thinking_machines`.
- **T.** Knowledge and trade, plus diffusion from neighbours who have it.
- **M.** Capacity up to +25%, productivity +0.08·s, inequality +0.1·s while it lasts, then −0.05·s. Legitimacy −0.1·s from displaced trades. Knowledge up.
- **D.** 15–80 years.
- **R.** A military-technical edge raises pressure-war risk against neighbours without it [C18].

### 3.9 Unmaking (`collapse`)
Generic kinds: `state_collapse`, `systemic_collapse` (three or more linked polities falling within 50 years).
- **T.** Low legitimacy, factional cohesion, entrenched inequality, overextension, accumulated strain (the main cascade channel), trade partners collapsing (systemic contagion) and overpopulation beyond capacity. Gated on having a state at all: institutions above about 0.1. There is a 60-year grace period after a collapse ends, while the new order takes hold.
- **M.** Severity s = Beta(2, 2.6):
  - deaths 3% + 25%·s and emigration 3% + 12%·s;
  - **institutions −40% to −90%**, legitimacy −0.1 − 0.4·s, knowledge −0.12·s (literacy lost);
  - trade links cut to 30–100% of their level; capacity −25%·s (works and irrigation fall into ruin).
- **D.** 15–240 years, hump-shaped: decline, then trough.
- **R.** The **new order**: legitimacy +0.3, inequality −0.15·s (the great levelling), institutions rebuilt at +0.25·s over 60 years, knowledge +0.05·s (reorganisation invents), cohesion +0.2. Collapse also gives birth to **successor peoples** (§6) [C20–C24].

### 3.10 Cascades
Every onset records a *parent*: the strongest recent shock among that type's drivers, in the civ or, for migration and war, in a neighbour. Drivers:

| Shock | Drivers |
|---|---|
| famine | climate, war, collapse, migration, pestilence |
| migration | climate, famine, collapse, war |
| war | migration, upheaval, economic, tech, famine, collapse |
| collapse | war, migration, famine, economic, pestilence, climate, upheaval |

The strain accumulator (0 to 2, decaying 10% a year) carries trauma between shocks: deaths, shock-driven food loss, institutional and legitimacy losses, and emigration.

## 4. Hazard model

Every endogenous hazard has the same form:

```
h_i,k(year) = base_k(H_i) / 100 × exp( Σ_j β_kj · (x_ij − x_ref_j) ) × gate_k(i) + contagion_k(i)
```

- `base_k(H)` is a per-century rate for a reference polity of historical era H, read from a piecewise-linear era table (`catalog.BASE`).
- `x` are state variables, and `β` are the coefficients in `engine.py` (one block per shock).
- `gate` removes impossible cases: no collapse without a state, no credit crisis before credit, no repeat while the same shock is active.
- Contagion runs over the contact or trade graph: partners in crisis, neighbours in upheaval, neighbours with new technology.

Climate is exogenous. Famine uses a shortfall-driven probability (§3.2). Pestilence and war propagate across the graph. `rate_scale` is a single difficulty or tuning knob.

**Court warnings.** A warning event is raised when a hazard is both high (above 1.2% a year; 0.3% for war) and well above its era's reference rate (at least 2×; 1.5× for war), at most once per 15 years per type per civ. It carries the lit **signs**, such as `crowding`, `far trade`, `thin stores`, `single staple`, `doubt`, `factions`, `overreach`, `grandees`, `partners falling`, `riders seen`, `refugees`, `alliances` or `arms race`. For pestilence, a rumour warning precedes infection whenever contagion pressure from an infected neighbour is high ("sickness in neighbouring lands").

## 5. Monte Carlo results vs historical base rates

`python -m tools.sim.shocks.demo --write` runs 6 fixed eras × 12 runs × 600 years and 8 campaigns × 3,000 years, with 16 starting civs and 36 slots. It takes about 20 seconds on this machine. Full output: [MC_RESULTS.md](MC_RESULTS.md). Rates are per civ per game century.

| Metric | bronze | classical | medieval | early-modern | industrial | modern | historical (ancient / medieval–early-modern / industrial–modern) |
|---|---|---|---|---|---|---|---|
| pestilence, ≥5% dead | 0.22 | 0.45 | 0.67 | 1.04 | 0.25 | 0.00 | 0.2–0.7 / 0.5–1.6 / 0–0.3 |
| pestilence, ≥25% dead | 0.01 | 0.03 | 0.03 | 0.03 | 0.00 | 0.00 | 0–0.1 / 0.03–0.2 / 0–0.03 |
| hunger, ≥2% dead | **1.80** | 1.23 | 0.94 | **0.32** | 0.09 | **0.00** | 0.5–1.5 / 0.5–2 / 0.05–0.4 |
| climate shock | 1.55 | 1.37 | 1.56 | 1.31 | 1.48 | 1.88 | 1–2.5 everywhere |
| collapse | 0.42 | 0.37 | 0.28 | 0.14 | 0.05 | 0.05 | 0.15–0.5 / 0.1–0.4 / 0.03–0.2 |
| general war (participation) | 0.27 | 0.37 | 0.39 | **0.28** | 0.33 | 0.30 | 0.15–0.6 / 0.3–1 / 0.2–0.8 |
| invasion / migration | 0.16 | 0.43 | 0.47 | **0.13** | 0.01 | 0.01 | 0.15–0.6 / 0.15–0.6 / 0–0.15 |
| coin / credit crisis | 0.70 | 0.64 | 0.82 | 0.90 | 1.05 | 1.00 | 0.1–0.8 / 0.4–1.5 / 0.8–2.5 |
| schism / overturning | 0.15 | 0.24 | 0.35 | 0.31 | 0.37 | 0.43 | 0.1–0.4 / 0.2–0.6 / 0.2–0.7 |
| new craft | 0.11 | 0.13 | 0.19 | 0.25 | 0.90 | 1.10 | 0.03–0.2 / 0.1–0.4 / 0.5–1.5 |

**55 of 60 cells fall inside the historical range.** The 5 misses (in bold) sit within about 0.2 of a range edge, and they move in and out between seeds.

**Magnitudes.** Median / 90th-percentile / maximum population loss for each civ hit:

| Shock | median | p90 | max |
|---|---|---|---|
| pestilence wave | 2.7% | 10% | 60% |
| hunger | 5.6% | 12% | 33% |
| war | 6.4% | 17% | 58% |
| migration | 3.1% | 8.8% | 23% |
| collapse | 18.5% | 30% | 42% |

Collapse removes a median 56% of institutions (72% at p90). Virgin-soil contact killed a median **92%** (90th percentile 97%) of the isolated peoples it reached, across all waves. That is at the top of the calibrated 50–90% band; the virgin virulence of 0.2 is the tuning knob.

**Recovery.** Median years to regain 95% of the pre-shock population (90th percentile in brackets):

| Shock | median | p90 |
|---|---|---|
| pestilence | 8 | 56 |
| hunger | 7 | 101 |
| war | 13 | 66 |
| migration | 8 | 49 |
| climate (droughts) | 44 | 160 |
| collapse | 69 | 223 |

Only 52% of collapses fully recover the old population; 37% of the collapsed civs vanish or are absorbed before they do.

**Cascades.** 47% of all onsets are triggered or amplified by an earlier shock, and 63% of collapses have a preceding shock. The commonest chains are:

- famine → collapse → famine
- famine → migration → famine
- climate → collapse → famine
- climate → famine → migration

The full climate → famine → migration → war → collapse chain occurs, but rarely: 22 times in the whole run set, as it should be.

**Warnings.**

- Pestilence and hunger give good warning: 87% and 76% of onsets were preceded by a court warning, at 1.6 and 1.0 warnings per civ per century.
- Collapse: 41% warned; migration: 38%; credit crises: 37%.
- Schisms (11%) and wars of many peoples (10%) mostly come as surprises.

That split is intended: the god gets omens, not certainty.

**Emergence** (3,000-year campaign, starting with 20 peoples):

- Peoples alive: a median of 30 at year 600, 32 at 1200 and 36 at 3000, where the 36-slot budget binds.
- Births 0.32 and deaths 0.30 per civ per century.
- Births by kind: successor 48%, secession 23%, uprising 11%, colony 9%, nomad confederacy 6%, newcomers 3%.
- **92% of new peoples are successor states with a lineage claim.**
- Deaths: absorbed 85%, union 15%.
- 1,608 would-be births were suppressed for lack of a free slot. That is the budget constraint of §11.

## 6. Civilizational emergence (`emergence.py`)

### 6.1 Births
| Kind | Trigger (emergent) | What the newborn inherits |
|---|---|---|
| `successor` | A collapse onset: Poisson(0.1 + 0.9 × s × size) fragments, up to 5. A severe collapse can disperse the parent entirely into its fragments ("rise from the ashes"). | A share of people and land, 70–95% of the parent's knowledge, low institutions, the parent's disease pool and immunity, half its strain, a **lineage claim** (a name that shares the parent's first syllable), a grievance against the parent, and the parent's culture id. |
| `secession` | Hazard from overreach, weak legitimacy and cohesion, time since the last split, strain, and upheaval. Gated on size. | 10–30% of people and land, 90–100% of knowledge, 60–90% of institutions. 40% chance of a war of independence. |
| `uprising` | Revolt hazard from inequality, low legitimacy, strain and famine. **Most revolts are crushed**: success = 4% + 15% × (1 − institutions) × (1 − 10 × mobilisation). | 5–20% of people, low inequality, war with the parent. |
| `newcomers` | A migration of severity ≥ 0.35 settles, with chance 0.35·s. | People from beyond the map or from the source neighbour. The name comes from the migration episode, a hostile border. |
| `confederacy` | Nomad pressure on an open frontier. | A new mobile people beyond the frontier: high mobilisation and aggression, low density, war with its anchor. |
| `colony` | Colonies founded by trading, crowded civs, gated by sea reach. Independence hazard grows with the colony's size relative to its parent, its age and the parent's weakness, and spreads in waves after other independences. | Knowledge and institutions from the parent, a far position, often war. |

### 6.2 Deaths
| Kind | Trigger |
|---|---|
| `absorbed` (war) | The loser of a general war, with under 35% of the winner's population, is annexed with an era chance: 35% pre-1900, 3% after the mid-20th-century norm against conquest [C25]. |
| `absorbed` (assimilation) | A small, weak people beside one at least 1.5× larger is gradually annexed or assimilated (the era rate falls to about 0 in the modern era). |
| `union` | Kindred (same culture id) or allied small peoples merge, more likely under a common threat. |
| `dispersed` | Population falls below a viable floor. The people scatter into their neighbours. |

### 6.3 Why this shape
Historical polity turnover is high: the mean lifespan of empires is about 220 years [C22], and pre-1945 state death is about 0.2–0.3 per state per century [C25]. Most new states come from fragmentation, secession or decolonisation rather than from nothing. The campaign run reproduces three things:

- a consolidation dip in the early-modern era, when absorption is strongest;
- a refill by colonial independence in the industrial–modern era;
- turnover of about 0.3 per civ per century.

### 6.4 The player's people can fracture; the god is never lost
The god is god of a **people and its faith**, not of a state.

- **A province breaks away.** The breakaway people keep a `devotion` to the god equal to the parent's × U(0.2, 1.0). The engine emits a `god_choice` event. The court should turn it into a divine moment: *which people carries your name?*
  - **Stay** with the loyal core. This is the default.
  - **Follow** the breakaway.
  - **Claim both.** The breakaway becomes a *daughter people* with weaker, indirect influence: envoys rather than court, and a smaller share of divine attention.
  - **Disown** them. They become a rival AI civ with a grievance and a heresy.
- **The player's state collapses entirely** (dispersed or absorbed). The engine emits `god_follows`. The god passes to the successor with the largest share, or else to the absorber, or else to the nearest people: the faithful carry the god with them. The court re-opens among a new people, with a new name, a lineage claim and memory (the chronicle and a scarred reverence). **No defeat state exists.**
- **Absorption by assimilation** never quietly takes the god's people. It can still fall in war or union, and then it continues through `god_follows`.
- **Union led by the player** keeps the player's people as the uniting crown.

## 7. Naming: alternative history

- **Types and kinds are generic ids.** Types: `pandemic`, `famine`, `climate`, `war`, `migration`, `economic`, `upheaval`, `tech`, `collapse`. Kinds: `great_pestilence`, `long_winter`, `war_of_many_peoples`, `state_collapse`, `systemic_collapse`, and so on (`names.KINDS`). `KIND_TITLES` gives the player-facing category words: "great pestilence", "long winter", "war of many peoples", "unmaking", "great unravelling".
- **Event names are generated at runtime** from templates filled with the affected people's own names and city names. Examples from the demo:
  - *the Speckled Sickness of the Gulsir years*
  - *the Unmaking of Kassul*
  - *the Ash Winter of the Inovar*
  - *the Lean Years of the Orathi*
  - *the War of Four Peoples*
  - *the Grey Riders*
  - *the Broken Tallies*
  - *the Two Altars*
  - *the Dark-Metal Turn*
  - *the Great Unravelling*
- **Newborn peoples** get names built from the game's fictional identity roster (`CivilizationIdentity.PROFILES`). Successors keep the parent's first syllable, so a lineage is audible: Orathi → Omeir, Oselruun. Syllables are never taken from descriptive English place names such as "Seven Wells".
- **When baking in:**
  - Port `names.py` into GDScript next to `civilization_identity.gd`. The roster has only 36 identities, and `index_for` wraps `civ_N` modulo 36, so newborn civs need generated identities, palettes and symbols.
  - Add a small blocklist so that generated names never coincide with real places or events. Some roster words already resemble real toponyms; audit the roster once.
  - Use the era-appropriate words (`KIND_TITLES`) through the dialogue anachronism gate: no "credit crash" before credit.

## 8. How it should feel to the god

### 8.1 Omens, voiced in court
Warnings are **signs**, not forecasts. Each warning's lit signs map to a voice:

| Signs | Who speaks | Example voice (a template, not a script) |
|---|---|---|
| `sickness in neighbouring lands`, `far trade`, `crowding` | a foreign envoy (they arrive unbidden) or a summoned trade official | "Their caravans came in with three dead drivers. The harbour-master burned the bales." |
| `thin stores`, `bad harvest`, `single staple` | a steward, when summoned | "The pits are half-full. If the rains fail again we will eat seed." |
| `doubt`, `factions`, `grandees`, `overreach`, `exhaustion` | a counsellor, a priest, or a petitioner | "In the far valleys they no longer pour the libation." |
| `riders seen`, `refugees`, `drought beyond the border` | a frontier envoy or scout report | "Whole villages walk south with their herds. They are not raiders yet." |
| `alliances`, `arms race`, `schism`, `weak neighbour` | an envoy | "Our ally's quarrel with the Vardun will be ours by spring." |
| `partners failing`, `war spending`, `debt` | a treasurer | "The tallies are broken; half the grain-debts cannot be paid." |

Officials speak only when the god summons them. Only foreign envoys arrive unbidden. The hazard itself is never shown as a number; its signs are.

### 8.2 Choices during the crisis
The god's commands go through the existing Court and consequence engine. **Every order gets an in-character reply and a bounded, sensible effect.** Nothing is menu-only, and there is no mandatory form-filling. Levers map to the hazard inputs:

| Crisis | Levers | Hazard inputs they move |
|---|---|---|
| pestilence | close the gates, burn the dead, send the sick outside the walls, forbid gatherings | quarantine; lowers transmission, costs trade and cohesion |
| hunger | open the granaries, forbid hoarding, move grain | reserve, relief, legitimacy |
| war | keep out of an ally's quarrel | alliance entanglement |
| collapse | punish the grandees, release debts | inequality, legitimacy |
| schism | answer the prophet: bless, silence, or terrify | cohesion, reverence |

Divine acts are god-scale. A **blessing** raises reverence; a **terror** raises dread. Both steady legitimacy in the short run, and both also move the upheaval hazard, in opposite ways over the long run. A people who read a plague as the god's wrath can turn to penitence, which raises cohesion and devotion, or to apostasy, which feeds the schism hazard. **The shock is not cancelled. The god shapes its conditions and its meaning.**

### 8.3 The chronicle afterwards
Each episode leaves a named entry in the chronicle, observed rather than invented, in keeping with the chronicle's rule. The entry records:

- when it began, which peoples it touched and how many died (`deaths_by_type`);
- what it led to, from the parent chain: "the Thirst of Senovar → the Lean Years of the Orathi → the Unmaking of Kassul";
- what it left behind: after-effects such as "wages rose for a generation", "the old families were broken" or "the new order rebuilt the canals";
- the new peoples born from it, with their lineage claims.

Chronicle "chapters" can then be named after epochs: *the years after the Great Unravelling*.

## 9. Interface for SIM (no SIM files edited)

```python
from tools.sim.shocks import apply_shocks, apply_deltas, apply_emergence, apply_changes
events, deltas = apply_shocks(state, civ_graph, rng, year, params=None)   # once per game year, after host update
apply_deltas(state, civ_graph, deltas)                                     # or apply them SIM's own way
e_events, changes = apply_emergence(state, civ_graph, rng, year, events)   # births/deaths of peoples
apply_changes(state, civ_graph, changes, year)                             # slot-based reference application
```

- **`state`** is a dict of per-civ numpy arrays, one entry per civ *slot*. Required keys: `pop`, `capacity`, `era_year`. Every other key has a default (`engine.STATE_KEYS`): `alive`, `density`, `trade`, `health_knowledge`, `food_reserve` (years), `diversification`, `inequality`, `legitimacy`, `cohesion`, `institutions`, `overextension`, `mobilization`, `knowledge`, `steppe_exposure`, `productivity`, `aggression`, `disease_endowment`. Optional `names` and `cities` lists feed in-world naming. Emergence also needs `territory`, `x`, `y`, `region`, `is_player` and `devotion`.
- **`civ_graph`**: `contact` (N×N, required), `trade`, `war` (bool), `alliance` (bool), `region` (N ints).
- **Memory.** The engine keeps its bookkeeping in `state["shock_memory"]` and `state["emergence_memory"]`: episodes, immunity, disease pools, strain, recurrence queues, colonies and lineage records. These must be carried and saved with the host state. `reset_slot` and `retire_slot` keep them consistent when slots are reused.
- **`deltas`** (the engine never writes host variables):
  - `pop_loss_frac` (dies this year), `emigrants` and `immigrants` (people);
  - `food_mult` and `output_mult` (this year only), `capacity_mult` (lasting);
  - additive changes to `legitimacy`, `cohesion`, `institutions`, `inequality`, `trade`, `knowledge`, `health_knowledge`, `productivity` and `food_reserve`;
  - `mobilization_floor`, `war_start` and `war_end` pairs, `trade_link_mult` and `war_pressure` (N×N);
  - `deaths_by_type`.
- **Events**: `onset`, `spread`, `end`, `systemic` and `warning`, with `type`, `kind`, in-world `name`, `parent` and `warned`. Emergence adds `birth`, `suppressed`, `union`, `uprising_crushed`, `colony_founded`, `god_choice` and `god_follows`.
- `state["shock_hazard"]` and `state["shock_signs"]` hold this year's hazards and lit signs, for the court.
- **Surrogate bridge**: `adapters.row_from_surrogate(sur)` and `stack_rows` (read-only; verified against `simlib.make("sensible", 1)`). Set `harvest_noise_sd=0` when the host already draws weather.

### Integrated into the surrogate (opt-in)

`tools/sim/shock_world.py` binds the detailed surrogate to slot 0 of this world. It is enabled with `--shocks` or `simlib.run(..., shocks=True)` and is off by default. Its mapping refines the table below. Density is the era norm × crowding (population ÷ housing). Capacity comes from food security. Institutions are the era norm × (institutions capacity, education). The player's famine deaths are left to the surrogate's hunger model. Results are in `SHOCKS_IN_SURROGATE.md`.

### Variable mapping

| Shock key | Surrogate (`tools/sim/model.py`) | Game |
|---|---|---|
| `pop`, `capacity` | `population`, `housing_capacity` | player: `WorldSimulation` population; AI: `civ.population`, `civ.food_capacity` |
| `era_year` | `ceiling_era` | the knowledge frontier from `TechnologyEras` (`civ.knowledge` for AI) |
| `density` | population ÷ `settlements` | settlement sizes; region population shares |
| `trade` | `trade_capacity` effect + `logistics` | `SocietyExchange` routes; `civ.logistics`; `open_trade` diplomacy |
| `health_knowledge` | `health_protection`, `sanitation`, `water_safety`, `disease_exposure` effects | `EarlyLifeConditions.RELIEF_CHANNELS` (same four channels) |
| `food_reserve` | `stored_days / 365` | player stored food ÷ need; AI `civ.food_days / 365` |
| `diversification` | `diet_window` | the food source mix in `food_system` (gathering, hunting, fishing, cultivation) |
| `legitimacy`, `cohesion` | `legitimacy`, `cohesion` | `consequence_engine.governance_metrics()`; `civ.cohesion` |
| `institutions` | capacities and education (proxy) | GovernmentPeopleSystem offices staffed × policy execution |
| `inequality` | *none yet* | **gap**: derive from housing, food access and office holding when baked in |
| `overextension` | logistics vs settlements | `civ.territory`, `strategic_regions` vs `civ.logistics` |
| `mobilization`, `aggression` | `security` (proxy) | `civ.military_population / population`, `civ.aggression` |
| `contact`, `war`, `alliance` | (single-society) | `CivilizationSystem` contact and fog, `war_history`, `non_aggression`, alliances |
| `devotion` | – | the reverence/dread of the player's people |

## 10. Calibration sources (real history, used only as calibration)

| Ref | Calibration anchor |
|---|---|
| C1 | Antonine plague, 165–180 CE: about 7–15% of the Roman Empire. |
| C2 | Justinianic plague, 541–549, recurring until about 750: 15–40% in core cities, with recurrences every 10–20 years. |
| C3 | Black Death, 1347–51: 30–50% of Europe (some estimates 60%). Recurrences until about 1720. Post-plague real wages rose and inequality fell (Scheidel 2017; Alfani). |
| C4 | Americas, 1520–1620: waves of smallpox, measles, typhus and cocoliztli, up to about 90% cumulative mortality (Crosby; Koch et al. 2019). |
| C5 | 1918 influenza: 1–3% worldwide, about 5% in the worst large populations; cholera in the 19th century was usually under 1–2% nationally. |
| C6 | 536/540 CE volcanic winter and the Late Antique Little Ice Age, 536–660 (Sigl et al. 2015; Büntgen et al. 2016). Notable eruptions: Huaynaputina 1600, Tambora 1815. |
| C7 | The 4.2 ka event, about 2200 BCE: 200–300 years of aridity, contemporary with the fall of Akkad (Weiss 1993/2017). Late Bronze Age drought, about 1200 BCE. |
| C8 | Little Ice Age, about 1300–1850; the 17th-century "General Crisis" (Parker 2013). |
| C9 | Thirty Years' War, 1618–48: German lands −15–30%, some regions over 50% (Wilson 2009). |
| C10 | World War I: mobilisation about 20% of the population in France and Germany, military deaths about 3–4% of the population. World War II: USSR about 14%, Poland about 17%, Germany about 8–10%. |
| C11 | War making states (Tilly 1990); mass mobilisation levelling inequality (Scheidel 2017). |
| C12 | Sea Peoples, about 1200 BCE (Cline 2014). |
| C13 | Gothic and Hunnic migrations, 376–476. |
| C14 | Mongol conquests, 1206–1260s: northern China and Khwarazm −30–50% (disputed), Hungary 1241–42 −15–50%. |
| C15 | Old Babylonian debt crises and misharum edicts; Roman third-century debasement (silver content from about 90% to under 5%). |
| C16 | Spanish defaults 1557–1647; banking and sovereign crises about 1–2 per century per state in the modern era (Reinhart & Rogoff 2009); 1929–33 output −25% (US). |
| C17 | The Axial Age; the spread of Christianity and Islam; the Reformation, 1517–1648; the Age of Revolutions, 1775–1848; 1917. |
| C18 | Iron, about 1200–900 BCE; printing and gunpowder, 1450–1550; industrialisation, 1760–1870; electrification, 1880–1930; computing, 1950–2000. |
| C19 | Great Famine, 1315–17: 5–12% of northern Europe. France 1693–94: about 7%. Ireland 1845–52: about 12% dead plus about 12% emigrated. Bengal 1943: about 5% (Ó Gráda 2009). |
| C20 | Late Bronze Age collapse, about 1200–1150 BCE: Mycenaean settlement counts fell about 60–75% and Linear B was lost; iron and the alphabet followed (Cline 2014). |
| C21 | Western Rome, 400–600: the city of Rome fell from about 1M to under 50k, Italy by 30–50%; successor kingdoms followed. |
| C22 | Babylon: sacked 1595 BCE (Hittites), then long revival and decline; eclipsed after 539 BCE and Seleucia. Akkad about 2200 BCE; Ur III about 2004 BCE. Empire lifespans average about 220 years (Arbesman 2011). |
| C23 | Collapse as a response to diminishing returns on complexity (Tainter 1988); secular cycles of about 200–300 years (Turchin & Nefedov 2009). |
| C24 | Levelling after collapse and plague (Scheidel 2017). |
| C25 | State death: about 66 of 207 states died between 1816 and 2000, almost all before 1945 (Fazal 2007). Decolonisation raised the UN from 51 to 193 members. |

Frequency ranges in the §5 table (`catalog.HISTORICAL_BASE_RATES`) are judgement syntheses of these sources, per polity per century. They are not measured statistics. Treat them as plausibility bands.

## 11. Baking-in plan (after the years 600–1200 research pass)

### Systems each shock touches
| Game system | Shocks |
|---|---|
| `food_system` (weather factor, food source health, stores) | climate: add the regional drought and cold-age regimes to `_weather_yield_factor`. Famine: shortfall and stores; `food_mult` becomes a yield multiplier. |
| `early_life_conditions` and the disease burden | pestilence: a per-wave mortality spike through the existing excess-mortality path. `RELIEF_CHANNELS` feed `health_knowledge`; immunity and the disease pool are new state. |
| `civilization_system` and `civilization_relations` (AI civs, relations, wars, alliances, `war_history`) | war escalation, pressure wars, migration and invasion, contagion over contact, collapse of AI civs, emergence (births and deaths of civs). |
| `consequence_engine` (legitimacy, cohesion, governance metrics, directives) | the level deltas; divine commands during crises move the hazard inputs; after-effects become time-limited modifiers. |
| `government_people_system` | institutions (staffed offices); collapse vacates offices; secession takes officials with it. |
| `audience_director`, `audience_hall` (envoys), the court | warnings as envoy visits (unbidden) and as answers when officials are summoned; `god_choice` moments. |
| `campaign_chronicle` | named episodes, cascade links, after-effects, lineages. |
| `military_campaign` (generals) | a war of many peoples raises mobilisation. Generals fight it; the player sets objectives. |
| `save_system` | `shock_memory`, `emergence_memory` and new-civ identities. |

### Phased order
1. **Hooks only.** Wire `apply_shocks` into SIM's multi-civ surrogate. Tune `rate_scale` against the post-600 benchmarks. No game changes.
2. **Climate and hunger** in `food_system`. Least intrusive, most legible, easiest to warn about.
3. **Pestilence** through `early_life_conditions`, with envoy rumours and quarantine commands.
4. **Collapse, schism and credit crises** for AI civs first, then for the player (legitimacy and cohesion channels), with chronicle naming.
5. **War escalation and migration** in `civilization_system`, with generals executing.
6. **Emergence**: successor and seceding civs, dynamic slots, newborn identities, and `god_choice`/`god_follows` in court.
7. **Tech disruption**, once the research tree reaches industrial eras.

### Game constraints to solve before phase 6
- `CivilizationSystem.MIN_RIVAL_CIVILIZATIONS = 12` and `MAX_RIVAL_CIVILIZATIONS = 36`. The roster, `MAX_FOREIGN_FORMATIONS = 36 × 3`, per-civ region and formation arrays, and the identity roster (36 profiles, `index_for` wrapping modulo 36) all assume a fixed set. Use a **slot pool** as the model does: dead slots are recycled, and a birth with no free slot stays an autonomous province, so it is suppressed and counted.
- **AI controller spawn.** A newborn needs strategy, identity, cities (from its parent's regions), strategic regions, formations, and a relation seeded from its grievance and lineage.
- **Diplomacy and contact.** A successor inherits its parent's contacts and fog, and the parent's treaties need rules: void, inherited or contested. A player's breakaway starts at war or tense peace.
- **Save format.** `CivilizationSystem.SAVE_VERSION` is 10. Add versioned `shock_memory`, `emergence_memory` and a civ lineage table. Old saves load with empty memory, which is safe because every hazard is computed from current state.
- **Performance.** The engine is O(N²) in slots per year for the contact math. The demo runs 36 slots × 3,000 years in about 6 s per campaign in single-threaded Python, including the demo's own bookkeeping. In GDScript, evaluate hazards on the existing 30-day strategic turn, not daily.

### Risks
- **Player frustration.** A plague or collapse must never feel like a dice roll from nowhere.
  - Mitigations: warnings with lit signs; causal parents in the chronicle; god-level levers; the refractory and grace periods; `rate_scale` as a difficulty setting.
  - Never stack a collapse on a new player civ in its first century. The institution gate and the 60-year grace already bias against it.
- **Fairness.** AI civs use identical hazards. The player's advantage is foresight and divine levers, not immunity.
- **Balance with the research benchmarks.** Shocks lower long-run growth toward the historical ~0.1% a year, so the growth benchmarks were set assuming booms and busts. Re-run the 600–1200 benchmarks with shocks on.
- **Save compatibility.** Covered above. Emergence changes civ counts, so any code that assumes a stable civ index must use ids.
- **Naming leaks.** Generated names can coincide with real ones. Add a blocklist and an audit (§7).

## 12. Known limitations of the model
- The demo host (`world.py`) is a deliberately simple multi-civ stand-in: logistic growth, and levels that relax toward era norms. SIM's single-society surrogate has no inequality variable and no multi-civ graph yet; `adapters.py` bridges what exists.
- Most shocks are evaluated once a year. Within-year timing (harvest season, campaign season) is the game's job.
- Rates are per civ, so a world with more small civs sees more events in total. Calibrate against the game's real civ sizes when baking in.
- In the campaign run, industrial-era civs that lag in health knowledge see more pestilence than the fixed-era runs: 0.95 against 0.25 per century. The game's medicine research pace will set this.
- War-of-many-peoples and schism warnings are rare by design. If playtests find that too harsh, lower `warn_ratio` for those types.
