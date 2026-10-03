# Economy simulation

The economy is a coordination layer over the physical simulation. It does not
create resources, ignore transport, or allow money to feed people. Food,
materials, labor, storage, extraction, and delivery remain the underlying
constraints.

## The realm's purse (scripts/realm_purse.gd)

One account the god commands for the whole people. Towns keep their own
stores, money stage and households' money; the public account is the realm's,
and it holds only what is really in it. Before coinage it is **the common
store**: food the levy took out of each town's own stores, counted in rations.
After coinage it is **the treasury**: coin with its backing, plus the food
still taken in kind, counted in coin at the market price (the unit changes once,
at coinage). Working metal does not make the store silver.
Older saves merge every town's treasury, public debt and soldiers' arrears into
it once on load, moving each treasury's coin out of its town's circulation with
its backing; no town keeps a treasury, borrows or pays upkeep afterwards, and
the per-town public finance described further down is superseded by it.

Why it changed (2026-10-02): the levy used to be only written down. Nothing
left the towns' stores, pay handed nothing over, and nothing rotted, so the
player's year-237 store read 225,000 "silver" against 100,000 rations in all
seven towns. A purse kept that way is counted again once on load: it keeps
a year of the levy at its own last pace, and the record says so.

- **The levy** is light, usual or heavy: a plain fraction of every harvest and
  load brought in (light a quarter, usual half, heavy all of the age's most:
  a tenth before money, a fifth at weighed metal and coin, up to a third once
  the state counts every household). Each town's own economy day takes it:
  output x rate x the realm's reach (office_levers.reach with tallies and
  registers) x (1 - the share hidden), as food out of that town's stores
  (FoodSystem.take_for_levy, from fresh and stored food in the share each is
  held). The keepers take only what a town holds beyond 45 days of its need,
  where its food security starts to fall: what a town without that much
  cannot give stays with it ("left with hungry towns"). After coinage the
  food is kept at one book price (the market price at coinage), so a ration
  in is a ration out whatever grain fetches. After coinage the households' money share is paid in coin, with
  its backing. It weighs on trust in the chiefs (up to 4.8 points) and on
  holding together (up to 2.6) through the social pressure, beside its clamp.
- **Rot**: the store's food rots each month at the capital's own rate for
  stored food (FoodSystem.stored_spoilage_rate: storage pits, preserving
  methods and the keeper of stores lower it). So the store cannot grow without
  end: it settles where the levy left over after pay equals what rots.
- **The lines**, reckoned once a month for the month past: old debts (a
  quarter of the purse at most), the soldiers' pay (half a day's output per
  head for each soldier at arms, a quarter for those in drill), food for hungry
  towns (the store's own food carried from the capital first; then, with coin,
  food bought at the seller's market price, a delivery between towns), hired
  crews (building +15%) and the scholars' keep (research +12%), each a seventh
  of a day's output per head. Pay is food back in common hands: into every town's
  stores by its share of the people (a great work's wages into that town's).
  Unpaid soldiers lose will (6 points a month at most), readiness (to 0.85
  after three months) and some go home (1 in 50 a month, 1 in 25 from the
  third), through MilitaryCampaign.pay_shortfall.
- **Wealth shares** (by fifths) are concentrated by want, rising prices,
  defaults and money, and shared back toward each age's ordinary share
  (subsistence 38%, weighed metal 45%, coin 50% for the richest fifth) by
  custom, feasts, the purse's pay and a tax on the rich, within each age's
  floor and ceiling (28-55%, 32-65%, 35-75%). Each place moves the realm's
  shares by its share of the people.
- **Charter fees** (the Chartered stance on business, one part in twenty of
  the business sector's part of the output) and **the state works' surplus**
  (State works, one part in ten) are taken with the levy, out of each town's
  own stores or households' coin, never made up (enterprise.gd,
  docs/BUSINESS_ARC.md). The business sector also multiplies the working
  efficiency, civilian goods and the making capacity, widens market access,
  and lifts where the richest fifth settles, inside the age's bounds.
- Every people keeps its own purse; computer rulers set the same levers by
  their nature (civilization_controller.gd purse_orders).
- Other systems use `balance()`, `deposit(amount, why)`,
  `spend(amount, why) -> bool`, `pay_home(amount, why)`, `unit_word()`,
  `account_name()`, `history()`, `season()` and `forecast()`.

## Goods, barter and arms (2026-10-02, docs/PEOPLE_FIRST.md D)

Making is a path: makers turn what is cut, dug and carried into goods, goods
are the first currency, and a making people can buy and make arms.

- **Goods** (`civilian_goods.gd`): one stock counted in goods-worth (worth
  6 rations at the reference price). A maker makes CRAFT_SHARE (0.18) of a day
  x 5 x the crafts known (+5 in 100 each) x how well people work (the
  working efficiency, which carries the business factor): 0.72 a day at the
  usual pace (0.8), so **ten makers make about 7 goods a day, some 43
  rations' worth** (8.6 with the founders' four crafts). Makers make for the
  homes first (their target x 1.2), then **for barter**, up to 4 goods-worth
  a head held, drawing for barter only on materials beyond half of what the
  stores want (the builders' share stays). Goods wear 0.4 in 100 a day.
  **A little extra for a making people** (the user, 2026-10-02: "make it be
  a little extra"): once more than 5 in 100 make, each maker makes more, up
  to +15 in 100 when 1 in 5 make, and the homes and market hold up to half
  again as many goods a head. A balanced people gets none of it; arms stay
  as dear.
  `spare()` (beyond the homes' need), `draw(n)` (learners' and buyers' use),
  `buys(n)`, `worth_in_rations(n)` and `role_effect("Crafting")` (what making
  does now and with ten more makers) are its readers.
- **Barter from year one**: the first stage is named "Barter" (its id stays
  `subsistence` for saves). Prices are kept from the first day goods change
  hands (no tallies needed at home; strangers still begin with gifts until
  tallies and measures or a meeting place, `values_comparable_abroad()`).
  The day's goods count in the trade volume and the output; the part that
  changes hands is goods made x market access (`economy_metrics.goods_made`,
  `goods_worth`, `goods_changed`, `goods_traded_days`). Market access gains up
  to 0.08 from makers and 0.06 from carriers at 5 in 100 of the people each
  (`barter_reach()`). Barter's share of exchange grows from 26 to 48 in 100
  with market access.
- **Goods buy** (`trade_ledger.gd deal_terms` / `goods_deal`): between two
  peoples who barter (past their first seasons of gifts), goods buy what the
  other has to spare (beyond 1.1 x its wanted holding) at the seller's price
  x 1.2, and made **arms** the same way. Every buyer, the god included, meets
  the same terms:
  - **Families who come to work** (children with them, every one counted):
    only from a people that goes hungry (eating under 90 in 100 of its need)
    or is broken by war; only as many as its food cannot feed, at most 2 in
    100 of its people in one deal, never leaving it under 30; one families
    deal a pair a season (92 days: four a year at most); only from a people
    that holds the buyer at 0 or better. The price is a person's year of work:
    365 days of the seller's output a head (a year's food at least), in goods.
    Families moving warm no one, so a repeat is never easier.
  - **Our own taken captive**: each raid that takes ours records them with the
    holder, ages as taken (`war_loop.gd _our_captives_lost` ->
    `note_captives`, the pair's `captives` record). A ransom (120 rations a
    head in goods) brings them home from that record, children and grown as
    they were taken, and takes none of the holder's own people. An older save
    has no record: those taken before it cannot be ransomed, and the terms
    say so.

  Goods and the good or the people move through the one ledger (move, the
  pair's flows, kinds and `deals`); counts add up on both sides. The Trade
  page's "Buy with goods" menu states each term (read once a day for each
  people, `deal_offers`). Computer rulers buy arms when their watch lacks them
  (at war, or with three sets' worth of goods to spare) and, when fed, take in
  families on the same terms (`trade_stances.gd goods_buys`). Goods for goods
  stays the season's coarse barter.
- **Arms** (`weapons_stock.gd`): one set arms one fighter. A spear and a bow
  take **10 maker-days** and 1.4 timber, 0.3 flint, 0.4 plant fiber (about 8
  goods, 48 rations); bronze 16 maker-days with copper and tin; iron 14;
  muskets 18; rifles 9; automatic rifles 7, with metals and coal. The goods a
  set forgoes are the household goods its maker-days make at full pace (a
  slower people takes more days but makes fewer goods a day: the pace
  cancels). While the watch lacks arms (at war on either side of a war or
  feud: 2 in 5), 1 in 5 of the makers make them and give the whole day to
  it: no goods, and none of the makers' other work (`game_state.gd
  effective_workers("Crafting")` and the tools-and-materials count leave
  them out).
  The made stock is "Arms" in every town's stores (worn like durable things
  in a yard), priced at 48. Only made sets beyond what the watch still lacks
  are traded; the old armoury's spears and bows arm the watch and count as
  held for it, but are never traded, paid or given away, and no toll,
  tribute or gift is paid in arms unless chosen.
  **Wired to the watch** (`watch_military.gd`, workstream E): the military's
  five accessors are the stock's, on the military passed to them.
  `weapons_held(item)`, `take_weapons(n, item)`, `return_weapons(n, item)`
  and `lose_weapons(n, item)` take the kit named. The makers' arms are tied
  to their age (`arms_age`): the best age whose knowledge is held, whose
  materials are in store or being dug (else the next age down: bronze known
  with no tin still makes spears and bows), and one of whose weapons (stone: spear; bronze: sword and shield or axe, or spear;
  iron adds the pike; muskets; rifles) a line unit of ours can carry with its
  practice learned (never a prototype cohort). That weapon is the watch's
  kit (`watch_military arms_kit`); a made set can be any weapon of that age's
  list in a fighter's hands, so spearmen are still armed by bronze-age
  makers. Made sets go first, then the armoury's kits of the weapon; exact
  with part sets; on a day the age's materials are being dug but not yet in
  store, the makers make the next age down meanwhile. Men at home with what
  comes to hand take up made arms as the sets come, only as many as there
  are sets in hand (`rekit_for_made` splits them off, their drill kept, their
  old arms to the armoury), each with the first weapon on the age's list
  their unit can carry (a spear for the levy, whatever the age), so an older
  save's levy is armed, never left waiting and never stripped. Kits handed back (a stand-down, a cancelled or retrained drill, a
  garrison, a draft or a band's spare) go to the armoury as that kit; losses
  in battle go on the arms record. `weapons_issued()` reads what the
  formations carry (`weapons_carried`). `arms_wanted()` = what the watch
  lacks that made sets can fill, weapon by weapon (`arms_gaps_by_weapon`: per
  formation of a made weapon its missing sets, a crew weapon per weapon; the
  levy to re-kit; new drill orders' unreserved sets, never a field draft's or
  a reinforcement's, which are their formation's own gap; less the sets on
  the road with drafts; the watch not yet serving), each less the armoury's
  own kits of that weapon, then less the made sets in store: each set counted
  once. The record's `issued` is only a statistic.
  Joining the watch, finishing drill, the daily re-arming at home, a field
  draft's gear, an army build's and a deployment line's reserve and a
  general's resupply all draw through `take_weapons`.

## Exchange stages

1. **Barter** (id `subsistence`) — barter of goods for food and materials,
   reciprocal labor and public stores. Prices are kept from the first barter;
   monetization is capped at 12%.
2. **Weighed-metal exchange** — requires adopted tallies and shared measures,
   productive capacity, and a usable metal surplus. Resources and labor remain
   valid payment. Standard weights reduce the coincidence-of-wants problem.
   Reaching this stage moves a population-scaled founding quantity of physical
   metal from ordinary stores into a separately composed exchange stock; the
   label is therefore not a fictitious monetization percentage.
3. **Currency economy** — requires deeper adoption of tallies and measures,
   institutional and logistics capacity, food reserves, and substantial metal
   backing. Currency begins alongside barter, metal, resources, and credit; it
   does not delete them.

The gates are capability-based rather than calendar-based. A disrupted society
can reach them late, while an unusually capable one can reach them early.
Metal-surplus, founding-reserve, and initial-issue quantities also scale with
population while preserving the original 120-person balance point. A hamlet
therefore does not need a city's bullion stock, and a city cannot monetize
itself on a village-sized reserve.
The stages are historical capabilities, not exclusive modes. Public allocation,
reciprocity, barter, weighed metal, recorded credit, and currency coexist in a
normalized daily exchange mix. Crisis shifts activity back toward direct
allocation and reciprocal exchange without pretending that currency knowledge
has been forgotten.

## Daily model

`EconomySystem` derives market access from settlement, logistics,
administration, storage, trade knowledge, and standardization. Resource prices
move gradually toward scarcity-derived values; the damping prevents single-day
noise from producing absurd shocks. Delivered goods and food flow determine
potential trade volume.
The market snapshot exposes rolling 30-day commodity trends and the economy
tracks mean price-index movement as volatility. Persistent instability weakens
exchange reliability and deferred settlement even when the latest daily change
looks small.

Weighed metal is conserved physical property. Coin, copper, tin, or iron moves
from material stores through current processing yields into a composition
account held for exchange. Its daily turnover is limited by the size of that
stock, adopted measures, and trust. Active handling causes a very small assay,
clipping, and abrasion loss; idle metal has only a minute custody loss. The
player may place more metal into exchange or withdraw it back to physical
stores. Metal in circulation is no longer available for tools, arms, buildings,
or reserve backing, and withdrawal does not create new metal. A failed or thin
metal stock pushes transactions back toward barter and reciprocity even after
the historical capability has been learned.

Every stage also keeps a non-monetary real-economy account: food actually
delivered, shelter and useful-material coverage, collective labor claims,
exchangeable physical surplus, and output per person. These figures observe the
authoritative food, material, population, and military systems and never consume
their stocks a second time. Unmet essentials and excessive collective duties
create obligation pressure even when prices or the treasury look healthy.
An aggregate labor-return index compares the productive value attributable to
labor per able person with the current essential basket per resident. It is a
real-income signal, not a fabricated wage payment or a hidden household wallet;
low returns gradually worsen concentration and social pressure.

The opening economy has its own public-finance loop before money. Customary
obligations assess a limited share of communal labor and material needs; current
Administration, Construction, Logistics, Defense, and military mobilization
show the collective service actually being rendered, while material deliveries
show contributions reaching common stores. The obligation account only
classifies those authoritative flows—it does not remove citizens or goods a
second time. Unfulfilled assessed duties become labor-day and material-value
arrears. Under custom, much of an old informal claim lapses as circumstances and
memory change. Once Scheduled Public Levies are adopted, census rolls, tallies,
law, and administration widen assessment, improve fulfillment, and preserve
unpaid claims as recorded obligations. Currency later commutes most public dues
into the exchange levy, but a bounded residual service and in-kind share remains
available and rises modestly when monetary exchange loses reliability.

The currency stage adds a bounded tax rate, collection limited by
administrative coverage, private holdings, and monetization; public upkeep;
treasury; private circulation; money demand and supply; circulation velocity;
reserve backing; wealth concentration; and exchange reliability.
Taxation and spending transfer existing currency; only explicit issuance
changes the money supply.

The displayed levy is statutory, not magically collectible. Daily tax capacity
starts with monetized exchange, then applies administrative reach and household
compliance. Compliance responds to legitimacy, institutions, tallies or
property records, inequality, accumulated public arrears, and increasing
resistance above moderate rates. A final liquidity cap prevents the treasury
from collecting units households do not possess. The dashboard separately
shows statutory and effective rates, compliance, noncompliance loss, and any
liquidity-limited gap; the same constraints feed fiscal forecasts and public
debt capacity.

Issued currency is reconciled across four conserved accounts: active household
balances, the public treasury, precautionary household hoards, and the mutual
risk pool. Only active household balances currently drive ordinary purchases,
price pressure, private-credit liquidity, monetization, and transaction
velocity. Treasury currency becomes transactional when public spending moves it
to households; hoards return when confidence recovers; risk-pool balances return
through relief. Issuance therefore does not pretend to raise current purchasing
pressure while the new units still sit unspent in the treasury.

Confidence combines exchange reliability, committed backing, price
stability, institutions, and the public arrears record. When confidence falls,
households gradually move their own liquid units into hoards; when it recovers,
they release them gradually. Hoards remain part of the conserved money supply,
but they cannot currently pay taxes, support public or private credit, enter a
mutual-risk pool, or add spending pressure to prices. This produces a liquidity
contraction without destroying money, and makes a high nominal supply visibly
different from money that is actually changing hands.
Civil and military obligations that cannot be paid remain as separate arrears;
they are not erased at day end and eventually damage social confidence.
The public balance is also accompanied by a read-only fiscal outlook. It
projects thirty days from the currently observed trade base, monetization,
administrative reach, liquid household balances, civil upkeep, the military
campaign's burden snapshot, arrears, debt interest, and bounded public-credit
capacity. A fourteen-day gross-obligation buffer distinguishes genuinely
discretionary headroom from cash already exposed to near-term commitments.
The forecast can be sound, thin, strained, or at default risk; it never reserves
funds by mutation, assumes new production, or silently creates borrowing.
When available funds cannot clear both categories, public payment can be
balanced, civil-first, or military-first. Balanced payment preserves the old
pro-rata behavior; the priority modes pay one category before the other. They
never change total spendable funds or erase the displaced claim: unpaid civil
or military obligations remain in their respective arrears accounts. The
dashboard and forecast expose both category coverage rates before a choice is
enacted.
Inflation is the daily change in the resource-weighted price index, not a fixed
scripted penalty. Shortage pressure remains separately visible so a nominally
healthy treasury cannot conceal physical scarcity.

Recorded credit is a non-monetary obligation stock. Daily trade can create
credit; reliability supports repayment; shortage and weak trust produce
defaults. Its ceiling is derived from population, trade flow, exchangeable
surplus, reliability, tallies, property records, and courts, preventing an
aggregate credit stock from growing without productive or institutional
support. Credit does not silently mint currency. Every tax, spending, issue,
retirement, credit, repayment, default, and reconciliation entry is retained in
a bounded economic ledger.

With adopted mutual risk pools, small trade-linked contributions move from
private circulation into a separately accounted mutual-aid reserve. Defaults
and severe prior-day subsistence gaps can trigger bounded payouts back to
private circulation. Contributions and payouts only transfer existing currency;
the pool cannot mint money, import goods, or disguise an unresolved physical
shortage.

Routine regional trade begins with weighed-metal exchange and can be governed
as balanced trade, relief-oriented imports, export accumulation, or closure.
The settlement exports only stock above a protected domestic buffer. Those
physical goods leave stores and earn a regional claim after friction; imports
spend that claim and arrive as physical food or materials. Imports therefore
cannot appear for free, domestic currency is not assumed to circulate abroad,
and the cumulative identity
`trade claims = export proceeds - import spending - recorded claim losses`
must hold. Regional counterpart demand is finite: route throughput, population,
and institutions cap claims held against outsiders, so an abstract infinite
buyer cannot absorb exports forever. If that capacity later contracts below
outstanding claims, the excess is gradually and visibly impaired rather than
silently retained as riskless wealth. Sustained food arrivals feed the
settlement model's import-dependence measure.

## Boundaries and data flow

`FoodSystem` and `ResourceSystem` own physical production, consumption,
spoilage, extraction, storage, and delivery. `MilitaryCampaign` owns armies and
publishes a read-only burden snapshot. `EconomySystem` observes those results,
then prices known goods, clears bounded regional trades, transfers conserved
currency, and publishes economic pressure for `ConsequenceEngine` and
prosperity signals for `SettlementModel`.

The deliberate trade-off is aggregation: household, creditor, and foreign
counterpart populations are represented as bounded accounts rather than
individual agents. This keeps a daily civilization simulation stable while
preserving the invariants that physical goods, currency, backing, trade claims,
and public debt cannot silently appear. Individual firms, multiple foreign
markets, and distinct currencies should be revisited only when the world model
has persistent counterpart settlements to own them.

Once public credit is substantially adopted, the treasury may bridge an
obligation shortfall by borrowing existing private currency. The transfer does
not change money supply. It creates a public debt claim bounded by tax capacity,
institutional strength, adoption, and the monetary base; interest accrues on
that claim, treasury surpluses service it, and borrowing stops at the ceiling so
unsupportable promises still become arrears.

Currency issuance is capped at 2.5 times committed metal reserve value in this
early monetary regime. Reserve commitment consumes physical coin or ore from
ordinary stores, applies the society's current processing loss, and sequesters
the resulting standardized metal value. Backing therefore has a real
opportunity cost: the same metal cannot also become tools, buildings, or arms.
The sovereign may commit additional metal, change the exchange levy, issue
within the resulting ceiling, or retire only units actually held by the public
treasury. Retired currency can make backing surplus to the live ceiling. Only
that excess may be released from reserve into ordinary physical stores, so
metal is not stranded forever and a release can never under-back circulation.
Processed reserve returned under its original material name retains the prior
smelting loss; external or generic bullion returns as secure physical Coin.

MilitaryCampaign remains authoritative for mobilization, field provisions,
equipment, damage, and workshop diversion. When it exposes
`economic_burden_snapshot()`, the economy consumes that contract read-only and
adds only its reported `currency_upkeep_units` to public finance. It
does not duplicate military state or generate resources to cover the burden.
Mobilized citizens, workshop diversion, and equipment backlog are also exposed
as collective labor and obligation pressure in the observational real-economy
account; field provisions remain physically consumed by `FoodSystem`.
War ransoms and spoils enter through `receive_war_wealth()`. Before domestic
currency, they remain physical coin/bullion in secure stores. In the currency
stage, external bullion increases committed reserve and supports an equal
deposit to the public treasury or private circulation; every receipt is
ledgered and currency-account conservation still holds.

## Public contract

- `EconomySystem.process_day(context)` advances the economy once per game day.
- `EconomySystem.quote(resource, quantity)` returns the current comparison
  value and accepted settlement media.
- `EconomySystem.preview_policy(action, amount)` returns a mutation-free
  forecast for the current levy, reserve, weighed-metal, issuance, retirement,
  or regional-trade controls. It reports the amount that can actually be
  accepted, before/after balances and hard ceilings, plus the principal
  physical or liquidity tradeoff. Dashboard tooltips consume this forecast;
  inspection never initializes accounts, enacts policy, or writes the ledger.
- `EconomySystem.fiscal_outlook(days, trade, monetization, military_burden)`
  returns a mutation-free solvency forecast, protected buffer, discretionary
  headroom, runway, bounded borrowing capacity, and civil/military cost split.
- `EconomySystem.tax_capacity_snapshot(rate, trade, monetization)` returns the
  current statutory assessment, administrative reach, compliance, effective
  rate, collectible revenue, noncompliance gap, and liquidity gap without
  transferring currency.
- `EconomySystem.set_public_spending_priority(priority)` and
  `cycle_public_spending_priority()` select balanced, civil-first, or
  military-first allocation when the treasury cannot clear every obligation.
- `EconomySystem.commit_metal_to_reserve(value, reason)` moves usable physical
  metal out of material stores and into monetary backing.
- `EconomySystem.place_weighed_metal_in_circulation(value, reason)` and
  `withdraw_weighed_metal(value, reason)` move processed physical metal between
  ordinary stores and the conserved intermediate exchange account.
- `EconomySystem.release_surplus_reserve(value, reason)` returns only backing
  above the current issue floor to physical stores without changing supply.
- `EconomySystem.transfer_currency(amount, source, destination, reason)` moves
  existing units among public, liquid-private, household-hoard, and mutual-aid
  accounts with validation and a ledger entry; it never changes supply.
- `EconomySystem.receive_war_wealth(amount, destination, reason)` is the
  conserved integration seam for military ransoms, plunder, and treasury
  spoils.
- `EconomySystem.accounting_audit()` reports currency-account reconciliation,
  weighed-metal circulation/composition identity, the reserve issue ceiling,
  regional-claim reconciliation, nonnegative stores, and public-debt validity.
  The daily dashboard snapshot carries the same audit.
- `GameState.economy_metrics` is the current dashboard snapshot.
- `GameState.economy_metrics.public_obligations` exposes the current customary,
  scheduled, or mixed monetary regime; assessment reach; in-kind share; labor
  and material dues, fulfillment, coverage, and carried arrears.
- `GameState.market_prices`, `economy_history`, and `economy_events` support UI,
  advisors, graphs, save data, and later trade actors.
- `GameState.economy_benchmarks` records irreversible historical transitions.

The regression suite covers the founding resource stage; customary, scheduled,
and monetary obligation regimes; both exchange benchmarks; reserve-backed
issuance; mixed settlement media; physical regional trade; scarcity pricing;
village-to-city population scaling; five deterministic shocks; one-year scaled
runs; mutation-safe policy and fiscal forecasts; statutory-versus-effective
levy collection; transactional currency segmentation; and a ten-year
accounting stress run.
