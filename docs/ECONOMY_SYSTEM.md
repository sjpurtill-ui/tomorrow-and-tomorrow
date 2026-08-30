# Economy simulation

The economy is a coordination layer over the physical simulation. It does not
create resources, ignore transport, or allow money to feed people. Food,
materials, labor, storage, extraction, and delivery remain the underlying
constraints.

## Exchange stages

1. **Resource obligations** — direct allocation, reciprocal labor, barter, and
   public stores dominate. Market values exist as internal comparison values,
   but monetization is capped at 12%.
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
