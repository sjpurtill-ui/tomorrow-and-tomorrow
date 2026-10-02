# The arc of business

From household crafts to corporations: one business sector per people, which the god shapes with a single stance and a few court orders. It raises the people's productivity, concentrates wealth, and brings booms and busts at stated odds. The code is in `scripts/enterprise.gd` (stage 1) and `scripts/great_houses.gd` (stage 2).

Read `docs/ADJUDICATION.md` (one ledger, stated odds, seeded rolls), `docs/ECONOMY_SYSTEM.md` (the purse, money stages, wealth shares) and `docs/STANDING_DESIGN.md` (every people follows the same rules) first.

## Why

The user asked for "the arc of business — early shops into corporations — something you set policy with, that impacts the nation's productivity."

The game already chooses a form of organized production by the people's values (`societal_values_model.gd`: mutual associations, licensed guilds or open professions). It also has about 30 commerce discoveries, from hired-labour contracts to audited company accounts. None of this changes what people make. Business has no body in the game yet.

## Stage 1: the business sector (`enterprise.gd`)

One record per people: `GameState.enterprise` (saved; every people keeps its own in its own scope).

### Rungs

Each rung is reached when its knowledge is held and the people's money allows it. The words follow the age ([[era-grounded-dialogue]], alternative-history naming: no real company names).

| Rung | Name shown | Needs | Most of the workers it can hold | Gain per worker in it |
|---|---|---|---|---|
| 0 | Household crafts | none | 0 | 0 |
| 1 | Stalls and hired workshops | weighed metal or coin, and prices kept (`economy_metrics.price_observations>0`) | 4% | 0.15 |
| 2 | Merchant houses and guilds | rung 1 + any of `licensed_merchant_houses`, `large_owner_workshops`, `licensed_guilds`, `craft_guilds` | 10% | 0.25 |
| 3 | Banking houses and long-distance partnerships | rung 2 + coin + any of `bills_of_exchange`, `branch_banking_houses`, `voyage_partnerships`, `district_royal_banks` | 16% | 0.32 |
| 4 | Chartered companies | rung 3 + `joint_stock_company` | 28% | 0.42 |
| 5 | Corporations | rung 4 + `limited_liability_registration` | 55% | 0.55 |

"Knowledge held" means `DiscoverySystem` adoption of at least 0.25 (as elsewhere). A people never falls back a rung for losing a discovery. It can fall back for losing money (if coin is lost, rungs that need coin are suspended).

### Size

`share` is the share of the working people in private business. Each month it moves toward its target:

`target = rung_cap × stance_reach × market × credit`

- `market` = clamp(market_access, 0.3, 1.0)
- `credit` = 0.7 + 0.3 × (credit available ÷ credit ceiling from `_process_credit`). Before credit exists this term is 0.85.

It moves a twelfth of the gap a year while growing, and a quarter a year while shrinking (failures are fast, building is slow). A bust cuts it at once (see below).

### What it does (the engine's numbers, shown on every screen)

- **Work.** `productivity = 1 + share × gain × form × stance_gain`. This multiplies the working efficiency in `consequence_engine.gd` (at the `OfficeLevers.labour()` seam). The 1.12 ceiling on that efficiency is raised by the same factor, so the gain is real.
  - Corporations at full size under Open: 1 + 0.55 × 0.55 × 1.0 × 1.15 ≈ 1.35.
  - Shops at full size: 1 + 0.04 × 0.15 ≈ 1.006 (small, as early shops were).
- **Goods.** The same factor multiplies civilian goods (`civilian_goods.gd`, which today ignores how well people work) and the making capacity target (`material_target`).
- **Trade reach.** Market access gets + share × 0.3 (houses and companies carry trade further).
- **Wealth.** Business pulls the richest fifth's share up by `share × stance_concentration` within the age's bounds (`economy_system.gd` WEALTH_BOUNDS). Through the existing social pressure, that weighs on trust.
- **The form** comes from the values-chosen variant of ORGANIZED PRODUCTION, which until now did nothing:
  - mutual associations: gain ×0.95, concentration ×0.6, bust odds ×0.8;
  - licensed guilds: reach ×0.85, gain ×1.0, concentration ×1.0;
  - open professions: reach ×1.1, gain ×1.08, concentration ×1.2, bust odds ×1.15.

### The stance (the god's lever; one at a time; set like the levy)

| Stance | Plain words | Reach | Gain | Wealth to the rich | Bust odds | The purse |
|---|---|---|---|---|---|---|
| Guarded | "Guilds and rules: steady and fair, slower" | ×0.75 | ×0.95 | ×0.5 | ×0.5 | nothing |
| Chartered | "You grant charters for a fee: favoured trades grow fast, wealth gathers" | ×0.9 | ×1.0 | ×1.3 | ×1.0 | charter fees: 1 part in 20 of the sector's output, taken with the levy |
| Open | "Free trade and enterprise: fastest growth, more inequality, booms and busts" | ×1.0 | ×1.15 | ×1.5 | ×1.6 | nothing beyond the levy |
| State works | (needs `nationalized_core_industries`) "The state runs the great works" | ×0.8 | ×0.85 | ×0.3 | ×0.2 | the sector's surplus: 1 part in 10 of its output |

- The default is Guarded at every rung until the god chooses another (changed in review: fees never start unasked). Each new rung is told once, with what each stance would do there.
- Changing the stance costs a little trust: 2 points, told once.
- Computer rulers choose by temperament: assertive and disciplined → Chartered, open-minded → Open, empathetic → Guarded. A ruler at war never chooses Open.

### Booms and busts (stated odds, seeded rolls)

- While the sector is well short of its target (target above share × 1.05) and credit is more than half used, it is **booming**. Productivity gets +2% while it lasts. Boom months count up to 24 at most.
- Each month one seeded roll against `p_bust = base × stance × form × (1 − banking) × (1 + boom_months/24)`, where:
  - `base` by rung is 0, 0.001, 0.002, 0.003, 0.004, 0.005 a month;
  - `banking` = 0.4 × max adoption of `double_entry_ledgers`, `audited_company_accounts` and `chartered_central_bank`.
- **A bust:**
  - share falls by a third at once;
  - productivity −4% for 6 to 12 months (seeded), easing;
  - debt defaults through the existing credit ledger;
  - the richest fifth loses 2 points of share, and cohesion −0.04.
  - The Chronicle tells it once ("The great houses of X failed one after another…"). The god may bail out (stage 2).
- The yearly odds are shown plainly: "About 1 in 40 years at this stance".

### Where the player sees it

The **Wealth tab** gets a "Business" section, between "Where it comes from" and "The levy":
- the ladder of rungs, with the people's rung marked and what the next needs;
- the share of workers in business, as a bar against its target;
- the effects line: "+6% to all work · +6% goods · trade reach +3 · the rich +2 points";
- the three or four stance buttons, each with its numbers (as the levy buttons have);
- the bust odds and any boom or bust under way.

Every number is the engine's own ([[explain-impact-of-things]]).

The court reads plain words ("open the markets to all", "grant charters", "guard the trades", "let the state run the works"), through office buttons on the Treasurer or Steward: one family "Business ▾" ([[orders-by-office]]). It answers questions about business from a fact sheet.

### Parity and save

- Every people keeps `enterprise` in its own scope and steps it monthly from `civilization_day.gd` (beside the purse settle).
- Computer rulers set the stance through a new `civilization_orders` kind "business".
- Older saves start at the rung their knowledge allows, with share at 40% of that rung's target. They grow into it; there is no sudden jump.

### Stage 1 as built (2026-10-02)

Where the design left room, the code does this (`scripts/enterprise.gd`):

- **Target** is never more than the rung can hold (`rung_cap`); the form's reach multiplies the stance's. Before craft guilds are known there is no form, and every form number is 1.
- **Wealth.** Where custom pulls the richest fifth back to (the age's ordinary share) rises by `(ceiling - ordinary) x min(1, share x stance_wealth x form_wealth)`. So the pull always stays inside the age's bounds, and the stance matters at every rung. Examples at coin: banking houses (16%) under Chartered add 5 points; corporations (55%) under Open add 21, and under Guarded 7.
- **Charter fees and the state works' surplus** are a share of the business sector's part of each day's output (`output x share`), as far as the keepers reach (`realm_purse.reach`). They are taken in each town's own day beside the levy (`realm_purse.accrue`).
  - After coinage the monetized part is paid in coin from households. The levy and the fees share one draw a day: at most a quarter of the households' coin (`COIN_DRAW`).
  - The rest is taken in kind, only from food beyond a town's 45 days. Nothing is made up.
  - The purse records them as "charter" in its month and towns. The board shows "Charter fees" (or "The state works") in "Where it comes from" and in the budget. The monthly reckoning notes them on their own line. The economy's revenue for the day counts them with the levy.
  - Every screen and the court give the fee both ways: at today's size and once grown.
- **Trust cost.** A change of stance takes 2 points of legitimacy in every town, but only once business exists (rung 1 or more). The purse's record notes it once. At rung 0 the word is kept for later and costs nothing.
- **Boom.** The sector booms while its target is above its share × 1.05 and more than half the recorded credit is used (the capital's `credit_utilization`). `boom_months` counts up to 24, and is cleared when the boom ends or a bust strikes.
- **The roll.** Each month the roll comes first, against the odds the screens stated all month (the boom months as they stood). Then the share grows and the boom is counted. The roll is seeded by `hash(world_seed, people, month index)`, and only rungs 1 and up with a share above 0 roll. A step over part of a month (the first after a load) rolls only that part: `1 - (1 - p)^(days/30)`.
- **Stated odds are the rolled odds.** The stance buttons, the court reply and the fact sheet all quote the current month's odds, booms included. Busts simulated over centuries with seeded rolls match them (tests/test_enterprise.gd, rung 5):

| Stance and credit | Stated | Simulated |
|---|---|---|
| Guarded, no credit | 1 in 33 years | 1 in 34 (44 busts in 1,500 years) |
| Guarded, credit 70% used | 1 in 21 | 1 in 23 (65 busts in 1,500 years) |
| Open, credit 70% used | 1 in 5.7 | 1 in 5.8 (137 busts in 800 years) |

  With credit used heavily, a sector that busts keeps falling short of its target, so it stays booming: in the Open run, 98 months in 100. That doubles the odds.
- **Food and the making capacity.** The harvest takes the factor whole: the usual efficiency curve is read on the hands' own efficiency and then multiplied by the factor, within what the land yields. The making capacity's target is raised before its usual ceiling (0.96), so every reader sees it in its usual range.
- **Computer rulers** weigh the stance once a year. A war's start or end does not flip it month by month, and at war Open is never chosen.
- **A bust's debts.** The debts written off are a third of the sector's part of recorded credit. The sector holds credit at twice its share of the workers, at most 90 in 100. The write-off goes through each town's own credit ledger (`credit_default`, "Business failures"). The 2 points come off the richest fifth, never below the age's floor, and are shared out to the other fifths by their shares. Holding together falls 0.04 in every town.
- **The court** reads a stance only from words aimed at the trades as a whole. "Keep the prisoner guarded", "a chartered ship", "give licences to the hunters" and "open trade routes to the east" are not stances. It answers business questions only when business is named ("business", "merchant houses", "the trades", "charter fees", or a bust or boom of the trades). Loose words ("companies of spearmen", "the guild of hunters") are left to other answers.
- **Words by age.** Before guilds are known, Guarded reads "Old custom and rules". Before writing, Chartered reads "You sell the right to trade".
- **Where it runs.** The month runs in the "enterprise" step of `civilization_day.gd`, after the purse. The daily readers (`factor()`, `market_bonus()`, `wealth_lift()`, `purse_rate()`) read only the cached record.

## Stage 2: great houses (`great_houses.gd`, after stage 1 ships)

- A handful of named houses or companies, at most 5 per people, rise from the sector, with alternative-history names. Each has:
  - a founder (a court person, summonable), a trade, a town and a size (its share of the sector);
  - a temper that comes from its founder.
- Court orders on them: back one (purse money for faster growth and its trade's gain), break one (its share scatters; anger among the rich; trust from the poor), bail one out in a bust (purse money to shorten it), and charter one abroad (trade reach into a rival's market).
- **Economy as war** ([[economy-as-war]]): a house can buy into a rival people's trade (share of their tribute, toll or market). It can squeeze them (the existing trade squeeze). It can be seized when war comes.
- HistoricalFigures gains a Merchant role: founders of great houses become notable figures.

## Benchmarks

- Early shops add almost nothing (under 1%). Merchant houses and banking add a few percent.
- Chartered companies and corporations add 10–35% to output per worker over a century. That matches the organizational share of the early-modern and industrial gains, beside technology's larger share.
- Busts come every few decades in open commercial economies (roughly 1 in 20–40 years) and rarely under guarded ones.
- Wealth concentration stays inside each age's bounds.
