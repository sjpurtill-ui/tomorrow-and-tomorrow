extends Node

# The economy is an accounting and exchange layer over the physical simulation.
# It never creates food or materials: scarcity, transport and storage remain owned
# by FoodSystem and ResourceSystem.

const STAGE_SUBSISTENCE := "subsistence"
const STAGE_METAL := "weighed_metal"
const STAGE_CURRENCY := "currency"
const STAGE_NAMES := {
	STAGE_SUBSISTENCE:"Direct allocation & reciprocity",
	STAGE_METAL:"Weighed-metal exchange",
	STAGE_CURRENCY:"Currency economy"
}
const BASE_VALUES := {
	"Food":1.0,"Timber":2.4,"Stone":1.8,"Clay":1.1,"Fiber Plants":2.0,
	"Salt":4.0,"Medicinal Plants":5.5,"Copper Ore":8.0,"Tin Ore":11.0,
	"Iron Ore":9.0,"Coal":3.5,"Transport Carts":24.0,"Coin":1.0
}
const METAL_VALUES := {"Copper Ore":1.0,"Tin Ore":1.4,"Iron Ore":0.7,"Coin":1.0}
const PUBLIC_SPENDING_PRIORITIES := ["balanced","civil_first","military_first"]

var initialized := false
var last_processed_day := -1

func reset_for_new_world()->void:
	initialized=false
	last_processed_day=-1

func initialize()->void:
	if initialized: return
	initialized=true
	_ensure_state()

func _ensure_state()->void:
	if GameState.economy_stage not in [STAGE_SUBSISTENCE,STAGE_METAL,STAGE_CURRENCY]:
		GameState.economy_stage=STAGE_SUBSISTENCE
	if GameState.public_spending_priority not in PUBLIC_SPENDING_PRIORITIES:
		GameState.public_spending_priority="balanced"
	if GameState.economy_metrics.is_empty():
		GameState.economy_metrics={"stage":GameState.economy_stage,"stage_name":STAGE_NAMES[GameState.economy_stage],"monetization":0.0,"market_access":0.0,"distribution_reach":0.0,"price_index":0.0,"price_observations":0,"inflation":0.0,"trade_volume":0.0,"reciprocal_surplus":0.0,"active_trade_partners":0,"foreign_trade_available":false,"tax_revenue":0.0,"subsistence_share":1.0,"metal_reserve":0.0,"money_supply":0.0,"velocity":0.0,"fiscal_balance":0.0}
	if GameState.currency_supply>0.0 and GameState.private_currency+GameState.currency_hoards+GameState.public_treasury+GameState.mutual_aid_reserve<=0.0:
		GameState.private_currency=maxf(0.0,GameState.currency_supply-GameState.public_treasury)
	var composed_metal:=_weighed_metal_value()
	if GameState.weighed_metal_circulation>0.0 and composed_metal<=0.0:
		GameState.weighed_metal_composition["Coin"]=GameState.weighed_metal_circulation
	else:
		GameState.weighed_metal_circulation=composed_metal

func process_day(context:Dictionary={}) -> Array[Dictionary]:
	initialize()
	for resource_name_variant in GameState.resource_stockpiles:
		if float(GameState.resource_stockpiles[resource_name_variant])>0.001:
			GameState.economy_known_goods[String(resource_name_variant)]=true
	var day:=int(GameState.elapsed_days)
	if day==last_processed_day: return []
	last_processed_day=day
	var events:Array[Dictionary]=[]
	_update_benchmarks(events)
	var previous_index:=float(GameState.economy_metrics.get("price_index",0.0))
	var market_access:=_market_access(context)
	var monetization:=_monetization(market_access)
	var trade_volume:=_trade_volume(market_access,monetization)
	_update_currency_demand(trade_volume,monetization)
	var price_index:=_update_prices(market_access,trade_volume)
	var active_trade_partners:=active_external_trade_partner_count()
	var external_trade:=_process_external_trade(market_access,trade_volume,active_trade_partners)
	var recorded_comparison_today:=trade_volume>0.001 and _comparison_values_observable()
	var market_volatility:=_market_volatility(price_index,30)
	var reliability:=_exchange_reliability(market_access,market_volatility)
	var currency_liquidity:=_process_currency_liquidity(reliability,market_volatility)
	var metal_exchange:=_process_weighed_metal_exchange(trade_volume,monetization,reliability)
	var credit:=_process_credit(trade_volume,market_access,reliability,events)
	var mutual_aid:=_process_mutual_risk_pool(trade_volume,float(credit.defaulted))
	var military_burden:=_military_burden_snapshot()
	var finance:=_process_public_finance(trade_volume,monetization,military_burden)
	var tax_capacity:Dictionary=finance.tax_capacity
	currency_liquidity["liquid_private"]=GameState.private_currency
	currency_liquidity["transactional_share"]=GameState.private_currency/maxf(1.0,GameState.currency_supply) if GameState.economy_stage==STAGE_CURRENCY else 0.0
	currency_liquidity["nontransactional_share"]=(GameState.public_treasury+GameState.currency_hoards+GameState.mutual_aid_reserve)/maxf(1.0,GameState.currency_supply) if GameState.economy_stage==STAGE_CURRENCY else 0.0
	var revenue:=float(finance.revenue)
	var upkeep:=float(finance.spending)
	var fiscal_outlook:=_fiscal_outlook_for(30.0,trade_volume,monetization,military_burden,GameState.public_treasury,GameState.private_currency,GameState.tax_rate)
	var inflation:=clampf(price_index/maxf(0.01,previous_index)-1.0,-0.25,0.50) if price_index>0.0 and previous_index>0.0 else 0.0
	var available_metal:=_available_metal_value()
	var reserve:=_monetary_reserve_value()
	var liquid_money:=maxf(0.0,GameState.private_currency)
	var velocity:=trade_volume/maxf(1.0,liquid_money) if GameState.economy_stage==STAGE_CURRENCY else 0.0
	var real_accounts:=_real_economy_accounts(trade_volume,market_access,military_burden)
	var public_obligations:=_process_resource_obligations(real_accounts,monetization,reliability)
	real_accounts["public_obligations"]=public_obligations
	real_accounts["obligation_pressure"]=clampf(float(real_accounts.obligation_pressure)+float(public_obligations.pressure),0.0,1.0)
	var inequality:=_update_wealth_distribution(monetization,inflation,float(credit.default_rate),revenue,real_accounts)
	var household_welfare:=household_welfare_snapshot(real_accounts,monetization,market_access)
	real_accounts["household_welfare"]=household_welfare
	var exchange_mix:=_exchange_mix(monetization,reliability)
	var economic_pressure:=_economic_social_pressure(inflation,float(credit.default_rate),inequality,market_access,reliability,real_accounts,finance,mutual_aid,currency_liquidity,household_welfare)
	_validate_currency_conservation()
	GameState.economy_metrics={
		"stage":GameState.economy_stage,"stage_name":STAGE_NAMES[GameState.economy_stage],
		"monetization":monetization,"market_access":market_access,"distribution_reach":market_access,"price_index":price_index,"price_observations":int(GameState.economy_metrics.get("price_observations",0))+(1 if recorded_comparison_today else 0),
		"inflation":inflation,"market_volatility":market_volatility,"trade_volume":trade_volume,"reciprocal_surplus":trade_volume,"active_trade_partners":active_trade_partners,"foreign_trade_available":active_trade_partners>0,"tax_revenue":revenue,"tax_capacity":tax_capacity,"tax_compliance":tax_capacity.compliance,"effective_tax_rate":tax_capacity.effective_rate,"tax_noncompliance_gap":tax_capacity.noncompliance_gap,"tax_liquidity_gap":tax_capacity.liquidity_gap,
		"public_upkeep":upkeep,"fiscal_balance":revenue-upkeep,
		"subsistence_share":1.0-monetization,"metal_available":available_metal,"weighed_metal_circulation":GameState.weighed_metal_circulation,"weighed_metal_composition":GameState.weighed_metal_composition.duplicate(true),"metal_exchange":metal_exchange,"metal_trade_turnover":metal_exchange.turnover,"metal_velocity":metal_exchange.velocity,"weighed_metal_losses":GameState.weighed_metal_losses,"metal_reserve":reserve,"reserve_composition":GameState.monetary_reserve_metals.duplicate(true),
		"money_supply":GameState.currency_supply,"money_demand":GameState.currency_demand,"liquid_money":liquid_money,"transactional_money":liquid_money,"transactional_share":currency_liquidity.transactional_share,"treasury":GameState.public_treasury,"private_currency":GameState.private_currency,"currency_hoards":GameState.currency_hoards,"currency_liquidity":currency_liquidity,"currency_confidence":currency_liquidity.confidence,"hoard_share":currency_liquidity.hoard_share,"velocity":velocity,
		"exchange_reliability":reliability,"shortage_pressure":_shortage_pressure(),
		"credit_outstanding":GameState.credit_outstanding,"credit_created":credit.created,"credit_repaid":credit.repaid,"credit_defaulted":credit.defaulted,"default_rate":credit.default_rate,
		"credit_limit":credit.limit,"credit_utilization":credit.utilization,
		"mutual_aid":mutual_aid,"mutual_aid_reserve":GameState.mutual_aid_reserve,
		"inequality":inequality,"social_pressure":economic_pressure,"household_welfare":household_welfare,"household_hardship_share":household_welfare.hardship_share,"lower_household_access":household_welfare.lower_access,"household_access_gap":household_welfare.access_gap,"reserve_ratio":reserve/maxf(1.0,GameState.currency_supply),"exchange_mix":exchange_mix,
		"external_trade":external_trade,"external_trade_policy":GameState.external_trade_policy,"external_trade_credit":GameState.external_trade_credit,"external_exports":GameState.external_trade_exports,"external_imports":GameState.external_trade_imports,"external_trade_losses":GameState.external_trade_losses,
		"real_economy":real_accounts,"essential_coverage":real_accounts.essential_coverage,"food_coverage":real_accounts.food_coverage,"material_coverage":real_accounts.material_coverage,
		"collective_labor_share":real_accounts.collective_labor_share,"exchangeable_surplus_value":real_accounts.exchangeable_surplus_value,"real_output_per_capita":real_accounts.output_per_capita,
		"resource_obligation_pressure":real_accounts.obligation_pressure,"public_obligations":public_obligations,"obligation_regime":public_obligations.regime,"in_kind_labor_arrears":GameState.in_kind_labor_arrears,"in_kind_material_arrears":GameState.in_kind_material_arrears,
		"private_liquidity_days":real_accounts.private_liquidity_days,"labor_return_index":real_accounts.labor_return_index,"daily_labor_income":real_accounts.daily_labor_income
	}
	GameState.economy_metrics["military_burden"]=military_burden
	GameState.economy_metrics["civil_upkeep"]=finance.civil_upkeep
	GameState.economy_metrics["military_upkeep"]=finance.military_upkeep
	GameState.economy_metrics["civil_upkeep_due"]=finance.civil_due
	GameState.economy_metrics["military_upkeep_due"]=finance.military_due
	GameState.economy_metrics["public_spending_priority"]=finance.spending_priority
	GameState.economy_metrics["civil_payment_coverage"]=finance.civil_coverage
	GameState.economy_metrics["military_payment_coverage"]=finance.military_coverage
	GameState.economy_metrics["civil_arrears"]=GameState.civil_arrears
	GameState.economy_metrics["military_arrears"]=GameState.military_arrears
	GameState.economy_metrics["public_arrears"]=GameState.civil_arrears+GameState.military_arrears
	GameState.economy_metrics["public_debt"]=GameState.public_debt
	GameState.economy_metrics["public_borrowing"]=finance.borrowing
	GameState.economy_metrics["debt_service"]=finance.debt_service
	GameState.economy_metrics["interest_accrued"]=finance.interest_accrued
	GameState.economy_metrics["debt_capacity"]=finance.debt_capacity
	GameState.economy_metrics["fiscal_outlook"]=fiscal_outlook
	GameState.economy_metrics["fiscal_headroom"]=fiscal_outlook.discretionary_headroom
	GameState.economy_metrics["fiscal_coverage"]=fiscal_outlook.coverage_ratio
	var audit:=accounting_audit()
	GameState.economy_metrics["accounting_audit"]=audit
	if not bool(audit.ok): _threshold_event(events,"accounting_invariant","Economic Accounts Diverge","The economy detected an internal conservation failure: %s" % "; ".join(audit.violations),1)
	GameState.economy_history.append({"day":day,"stage":GameState.economy_stage,"price_index":price_index,"trade_volume":trade_volume,"metal_circulation":GameState.weighed_metal_circulation,"metal_turnover":metal_exchange.turnover,"external_exports":external_trade.exports,"external_imports":external_trade.imports,"trade_credit":GameState.external_trade_credit,"treasury":GameState.public_treasury,"money_supply":GameState.currency_supply,"currency_hoards":GameState.currency_hoards,"currency_confidence":currency_liquidity.confidence,"credit":GameState.credit_outstanding,"inequality":inequality,"inflation":inflation,"essential_coverage":real_accounts.essential_coverage,"household_hardship_share":household_welfare.hardship_share,"lower_household_access":household_welfare.lower_access,"household_access_gap":household_welfare.access_gap,"output_per_capita":real_accounts.output_per_capita,"obligation_regime":public_obligations.regime,"labor_obligation_coverage":public_obligations.labor_coverage,"material_obligation_coverage":public_obligations.material_coverage,"tax_compliance":tax_capacity.compliance,"effective_tax_rate":tax_capacity.effective_rate,"spending_priority":finance.spending_priority,"civil_payment_coverage":finance.civil_coverage,"military_payment_coverage":finance.military_coverage,"fiscal_status":fiscal_outlook.status,"fiscal_coverage":fiscal_outlook.coverage_ratio,"fiscal_headroom":fiscal_outlook.discretionary_headroom,"prices":GameState.market_prices.duplicate(true)})
	if GameState.economy_history.size()>730: GameState.economy_history.pop_front()
	if absf(inflation)>=0.035:
		_threshold_event(events,"price_shock","Prices Shift",("Exchange values rose" if inflation>0.0 else "Exchange values fell")+" %d%% as stocks, demand, and monetary circulation changed." % roundi(absf(inflation)*100.0),30)
	if market_volatility>=0.025: _threshold_event(events,"market_volatility","Unstable Terms of Exchange","Daily comparison values have moved an average of %.1f%% across the recent market window, weakening confidence in deferred exchange." % (market_volatility*100.0),30)
	var shortage:=_shortage_pressure()
	if shortage>0.62: _threshold_event(events,"market_seizure","Exchange Under Strain","Essential shortages are forcing exchange back toward direct allocation, favors, and emergency obligations.",30)
	if float(real_accounts.essential_coverage)<0.62: _threshold_event(events,"subsistence_gap","Essential Claims Unmet","Food, shelter, and useful material access cover only %d%% of ordinary subsistence claims. Exchange media cannot repair the underlying physical gap." % roundi(float(real_accounts.essential_coverage)*100.0),30)
	if float(household_welfare.claim_exclusion)>0.08 and float(real_accounts.essential_coverage)>=0.72: _threshold_event(events,"household_exclusion","Unequal Claims Restrict Essentials","Physical essentials cover %d%% of aggregate need, but lower-household access is estimated at only %d%%. Direct provisioning, reciprocal claims, wages, and liquid balances are not reaching households evenly." % [roundi(float(real_accounts.essential_coverage)*100.0),roundi(float(household_welfare.lower_access)*100.0)],45)
	if float(real_accounts.collective_labor_share)>0.38: _threshold_event(events,"obligation_burden","Collective Duties Crowd Households","Administration, defense, mobilization, and public works now claim %d%% of able labor, leaving less time for household production and reciprocal exchange." % roundi(float(real_accounts.collective_labor_share)*100.0),45)
	if String(public_obligations.regime)=="scheduled in-kind levies" and not GameState.economy_benchmarks.has("scheduled_public_levies"):
		GameState.economy_benchmarks["scheduled_public_levies"]={"day":day,"from":"customary obligations"}
		events.append(_event("Public Levies Scheduled","Household rolls, customary law, and recorded schedules now make labor and material dues predictable, appealable, and persistent when unpaid.","major"))
	if float(public_obligations.pressure)>0.12: _threshold_event(events,"in_kind_arrears","In-Kind Obligations Accumulate","Unrendered collective work and material contributions now equal %.1f labor-days and %.1f value in carried obligations." % [GameState.in_kind_labor_arrears,GameState.in_kind_material_arrears],30)
	if float(external_trade.get("claim_limit",0.0))>0.0 and GameState.external_trade_credit/float(external_trade.claim_limit)>0.95: _threshold_event(events,"foreign_claim_limit","Regional Buyers Saturated","The settlement holds nearly as many claims on regional partners as current routes and institutions can support. Further exports need imports or deeper trade capacity.",60)
	if float(external_trade.get("claim_loss",0.0))>0.05: _threshold_event(events,"foreign_claim_loss","Foreign Claims Impaired","Weak regional capacity made %.1f units of accumulated trade claims unrecoverable today." % float(external_trade.claim_loss),45)
	if float(credit.get("utilization",0.0))>0.90: _threshold_event(events,"credit_limit","Private Credit Tightens","Recorded private obligations use %d%% of supportable capacity. New credit is scarce until claims are repaid or productive security improves." % roundi(float(credit.utilization)*100.0),60)
	if GameState.economy_stage==STAGE_CURRENCY:
		if GameState.public_treasury<_public_upkeep(military_burden).total*7.0: _threshold_event(events,"empty_treasury","Public Treasury Thin","Current public holdings cover less than a week of administrative, works, and military monetary obligations.",45)
		if reserve/maxf(1.0,GameState.currency_supply)<0.50: _threshold_event(events,"weak_reserve","Currency Backing Narrows","Issued currency is approaching the reserve limit. Further issue will be constrained and trust is exposed to shocks.",90)
		if GameState.civil_arrears+GameState.military_arrears>maxf(2.0,GameState.population_exact*0.10): _threshold_event(events,"public_arrears","Public Obligations Unpaid","The treasury has carried %.1f units of unpaid civil and military obligations into another day." % (GameState.civil_arrears+GameState.military_arrears),30)
		if float(finance.debt_capacity)>0.0 and GameState.public_debt/float(finance.debt_capacity)>0.82: _threshold_event(events,"public_debt","Public Credit Near Its Limit","Recorded public claims have reached %d%% of supportable capacity. New borrowing is constrained and future levies face debt service." % roundi(GameState.public_debt/float(finance.debt_capacity)*100.0),90)
		if float(currency_liquidity.hoard_share)>0.24: _threshold_event(events,"currency_hoarding","Currency Leaves Circulation","Households now hold %d%% of issued currency outside active exchange. Taxes, credit, and ordinary purchases face a liquidity shortage even though the units still exist." % roundi(float(currency_liquidity.hoard_share)*100.0),45)
		if GameState.tax_rate>=0.12 and float(tax_capacity.compliance)<0.55: _threshold_event(events,"levy_resistance","Levy Compliance Erodes","Only %d%% of administratively assessed exchange is expected to comply at the current statutory rate. Legitimacy, records, arrears, inequality, and rate pressure all shape collection." % roundi(float(tax_capacity.compliance)*100.0),60)
		if float(tax_capacity.liquidity_gap)>0.05: _threshold_event(events,"levy_liquidity_gap","Households Cannot Pay Assessed Levy","The assessed levy exceeds active household currency by %.1f units. Raising the statutory rate cannot collect money that is parked elsewhere or does not exist." % float(tax_capacity.liquidity_gap),45)
		if float(finance.civil_coverage)<0.55: _threshold_event(events,"civil_payments_displaced","Civil Obligations Deferred","Only %d%% of civil obligations were paid under the %s spending priority. Administrative and public-works arrears continue to accumulate." % [roundi(float(finance.civil_coverage)*100.0),String(finance.spending_priority).replace("_"," ")],30)
		if float(finance.military_coverage)<0.55: _threshold_event(events,"military_payments_displaced","Military Obligations Deferred","Only %d%% of military monetary obligations were paid under the %s spending priority. Payroll and upkeep arrears continue to accumulate." % [roundi(float(finance.military_coverage)*100.0),String(finance.spending_priority).replace("_"," ")],30)
		if String(fiscal_outlook.status)=="default risk": _threshold_event(events,"fiscal_default_risk","Public Finance Cannot Clear","Visible treasury holdings, receipts, and safe borrowing cover only %d%% of the next thirty days of civil, military, arrears, and interest obligations." % roundi(float(fiscal_outlook.coverage_ratio)*100.0),30)
		elif String(fiscal_outlook.status)=="strained": _threshold_event(events,"fiscal_strain","Treasury Has Little Margin","The current thirty-day fiscal forecast clears narrowly, leaving the settlement exposed to a trade, price, or mobilization shock.",45)
	if inequality>0.48: _threshold_event(events,"wealth_concentration","Claims Concentrate","A growing share of exchange claims is held by the wealthiest households, adding pressure to cohesion and legitimacy.",120)
	for event in events:
		GameState.economy_events.push_front(event)
	if GameState.economy_events.size()>120: GameState.economy_events.resize(120)
	return events

func _update_benchmarks(events:Array[Dictionary])->void:
	var adoption_measures:=DiscoverySystem.adoption("standard_measures")
	var adoption_tallies:=DiscoverySystem.adoption("tallies")
	var production:=float(GameState.society_capacities.get("production",0.0))
	var institutions:=float(GameState.society_capacities.get("institutions",0.0))
	var logistics:=float(GameState.society_capacities.get("logistics",0.0))
	var surplus_days:=float(GameState.simulation_metrics.get("food_days",0.0))
	if GameState.economy_stage==STAGE_SUBSISTENCE:
		var metal_available:=_available_metal_value()>=metal_stage_requirement() and DiscoverySystem.adoption("copper_smelting")>=0.18
		if adoption_measures>=0.32 and adoption_tallies>=0.25 and production>=0.24 and metal_available:
			place_weighed_metal_in_circulation(founding_weighed_metal_requirement(),"Founding weighed-metal exchange stock")
			_transition(STAGE_METAL,events,"Shared weights, tallies, and a dependable metal surplus now let obligations be settled beyond direct barter.")
	elif GameState.economy_stage==STAGE_METAL:
		var institutional_base:=institutions>=0.38 and logistics>=0.32 and surplus_days>=21.0
		var knowledge_base:=adoption_measures>=0.62 and adoption_tallies>=0.58
		if institutional_base and knowledge_base and _available_metal_value()>=currency_metal_requirement():
			var commitment:=commit_metal_to_reserve(founding_reserve_requirement(),"Founding monetary reserve")
			if float(commitment.get("accepted",0.0))>=founding_reserve_requirement()-0.001:
				_issue_currency_internal(founding_currency_issue(),"Founding issue",0.12)
				_transition(STAGE_CURRENCY,events,"Trusted measures, recorded accounts, trade reach, food reserves, and public authority now support issued currency.")

func metal_stage_requirement()->float:
	return maxf(6.0,GameState.population_exact*0.20)

func currency_metal_requirement()->float:
	return maxf(20.0,GameState.population_exact*(2.0/3.0))

func founding_reserve_requirement()->float:
	return maxf(10.0,GameState.population_exact/3.0)

func founding_currency_issue()->float:
	return maxf(10.0,GameState.population_exact*0.75)

func founding_weighed_metal_requirement()->float:
	return maxf(2.0,GameState.population_exact*0.08)

func _transition(next_stage:String,events:Array[Dictionary],reason:String)->void:
	var prior:=GameState.economy_stage
	GameState.economy_stage=next_stage
	GameState.economy_benchmarks[next_stage]={"day":int(GameState.elapsed_days),"from":prior}
	events.append(_event("Exchange Benchmark Reached","%s begins. %s %s" % [STAGE_NAMES[next_stage],reason,("Resource payment remains valid." if next_stage==STAGE_METAL else "Barter and weighed metal remain valid settlement media.")],"major"))

func _market_access(context:Dictionary)->float:
	if not GameState.settlement_site_committed or "Hearth Circle" not in GameState.settlement_completed: return 0.0
	if float(GameState.water_metrics.get("intake_ratio",0.0))<0.98: return 0.0
	var logistics:=float(GameState.simulation_metrics.get("logistics",0.16))
	var admin:=float(GameState.population_allocations.get("Administration",0))/maxf(1.0,GameState.population_exact*0.05)
	var storage:=float(GameState.simulation_metrics.get("storage_function",0.0))
	var foreign_access:=float(CivilizationSystem.player_effects().market_access_bonus)
	return clampf(logistics*0.36+admin*0.14+storage*0.10+DiscoverySystem.effect("trade_capacity")*0.32+DiscoverySystem.effect("standardization")*0.24+GameState.founding_effect("trade_access")+ProgressionSystem.effect("trade_capacity")+foreign_access,0.0,1.0)

func _monetization(market_access:float)->float:
	match GameState.economy_stage:
		STAGE_METAL:
			var potential:=clampf(0.08+market_access*0.38+DiscoverySystem.adoption("standard_measures")*0.18,0.08,0.62)
			var metal_liquidity:=clampf(GameState.weighed_metal_circulation/maxf(0.01,founding_weighed_metal_requirement()),0.0,1.0)
			return clampf(potential*(0.22+metal_liquidity*0.78),0.02,0.62)
		STAGE_CURRENCY:
			var trust:=_exchange_reliability(market_access)
			var recent_inflation:=maxf(0.0,float(GameState.economy_metrics.get("inflation",0.0)))
			var liquid_share:=clampf(GameState.private_currency/maxf(1.0,GameState.currency_supply),0.0,1.0)
			return clampf((0.12+market_access*0.35+trust*0.35-recent_inflation*0.50)*(0.62+liquid_share*0.38),0.06,0.88)
		_: return clampf(market_access*0.10,0.0,0.12)

func _update_prices(market_access:float,trade_volume:float=1.0)->float:
	# A comparison value is recorded evidence, not a hidden design constant and
	# not a foreign market quote. Founders can allocate goods and reciprocate
	# immediately, but they cannot report prices until shared measures and tallies
	# make separate exchanges comparable. Later exchange stages already require
	# those practices at their transition gates.
	if not _comparison_values_observable():
		return 0.0
	if trade_volume<=0.001:
		return float(GameState.economy_metrics.get("price_index",0.0)) if int(GameState.economy_metrics.get("price_observations",0))>0 else 0.0
	var weighted:=0.0
	var weights:=0.0
	var population:=maxf(1.0,GameState.population_exact)
	for resource_name in BASE_VALUES:
		var stock:=float(GameState.resource_stockpiles.get(resource_name,0.0))
		if not _resource_is_economically_known(String(resource_name),stock): continue
		var desired:=_desired_stock(String(resource_name),population)
		var scarcity:=clampf(desired/maxf(0.25,stock),0.35,4.5)
		var monetary_pressure:=1.0
		if GameState.economy_stage==STAGE_CURRENCY and GameState.currency_demand>0.0:
			var spendable_supply:=maxf(0.0,GameState.private_currency)
			monetary_pressure=pow(clampf(spendable_supply/GameState.currency_demand,0.55,2.8),0.12)
		var target:=float(BASE_VALUES[resource_name])*pow(scarcity,0.42)*monetary_pressure*(1.0+float(GameState.material_metrics.get("lost_today",0.0))/maxf(10.0,population)*0.08)
		var old:=float(GameState.market_prices.get(resource_name,BASE_VALUES[resource_name]))
		var damping:=0.035+market_access*0.025
		GameState.market_prices[resource_name]=lerpf(old,target,damping)
		var weight:=3.0 if resource_name=="Food" else 1.0
		weighted+=float(GameState.market_prices[resource_name])/float(BASE_VALUES[resource_name])*weight
		weights+=weight
	return weighted/maxf(1.0,weights)


func _comparison_values_observable()->bool:
	if GameState.economy_stage!=STAGE_SUBSISTENCE:
		return true
	return DiscoverySystem.adoption("standard_measures")>=0.15 and DiscoverySystem.adoption("tallies")>=0.12


func active_external_trade_partner_count()->int:
	return maxi(0,int(CivilizationSystem.player_effects().get("active_trade_partners",0)))

func _resource_is_economically_known(resource_name:String,stock:float)->bool:
	if stock>0.001: return true
	# Once any exchange has established a comparison ledger, previously quoted
	# goods remain requestable even when their local stock reaches zero.
	if bool(GameState.economy_known_goods.get(resource_name,false)): return true
	for deposit_variant in GameState.resource_deposits:
		var deposit:Dictionary=deposit_variant
		if String(deposit.get("resource",""))==resource_name and String(deposit.get("stage","unknown"))!="unknown": return true
	return false

func _desired_stock(resource_name:String,population:float)->float:
	match resource_name:
		"Food": return population*30.0
		"Timber": return population*1.5
		"Stone": return population*1.2
		"Clay","Fiber Plants": return population*0.45
		"Transport Carts": return maxf(1.0,population/30.0)
		_: return population*0.16

func _trade_volume(market_access:float,monetization:float)->float:
	if market_access<=0.0: return 0.0
	var delivered:=float(GameState.material_metrics.get("delivered_today",0.0))
	var food_surplus:=maxf(0.0,float(GameState.simulation_metrics.get("food_net",float(GameState.simulation_metrics.get("food_production",0.0))-float(GameState.simulation_metrics.get("food_consumption",GameState.population_exact)))))
	# Only surplus and newly delivered physical goods can change hands. Ordinary
	# subsistence production is consumption, not trade.
	return (delivered+food_surplus)*market_access*(0.35+monetization*0.65)

func _process_external_trade(market_access:float,domestic_trade:float,contract_partners_override:int=-1)->Dictionary:
	# The optional override is an isolated accounting-test seam. Runtime callers
	# always pass the authoritative treaty count produced by CivilizationSystem.
	var active_partners:=active_external_trade_partner_count() if contract_partners_override<0 else maxi(0,contract_partners_override)
	var result:={"exports":0.0,"imports":0.0,"exported_goods":{},"imported_goods":{},"friction":0.0,"credit":GameState.external_trade_credit,"claim_limit":0.0,"claim_loss":0.0,"partners":active_partners,"available":active_partners>0}
	if active_partners<=0:
		_update_food_import_dependence(0.0)
		return result
	if GameState.economy_stage==STAGE_SUBSISTENCE:
		_update_food_import_dependence(0.0)
		return result
	var reach:=clampf((market_access-0.24)/0.76,0.0,1.0)
	var stage_capacity:=0.42 if GameState.economy_stage==STAGE_METAL else 0.72
	var value_capacity:=maxf(GameState.population_exact*0.015,domestic_trade)*reach*stage_capacity
	var institutions:=clampf(float(GameState.society_capacities.get("institutions",0.25)),0.0,1.0)
	var claim_limit:=maxf(GameState.population_exact*3.0,value_capacity*120.0*(0.55+institutions))
	result.claim_limit=claim_limit
	if GameState.external_trade_credit>claim_limit:
		var excess:=GameState.external_trade_credit-claim_limit
		var impairment:=minf(excess,maxf(0.01,excess*0.02))
		GameState.external_trade_credit-=impairment
		GameState.external_trade_losses+=impairment
		result.claim_loss=impairment
		result.credit=GameState.external_trade_credit
		_ledger("external_claim_loss",impairment,"regional_trade_account","written_off","Foreign counterpart capacity contracted")
	if GameState.external_trade_policy=="closed" or market_access<0.28:
		_update_food_import_dependence(0.0)
		return result
	var friction:=clampf(0.22-market_access*0.10-(0.05 if GameState.economy_stage==STAGE_CURRENCY else 0.0)-DiscoverySystem.effect("standardization")*0.10,0.06,0.24)
	var export_share:=0.55
	var import_share:=0.45
	match GameState.external_trade_policy:
		"export_surplus": export_share=0.90; import_share=0.10
		"relief_imports": export_share=0.20; import_share=0.80
	var export_budget:=minf(value_capacity*export_share,maxf(0.0,claim_limit-GameState.external_trade_credit))
	var export_candidates:Array[Dictionary]=[]
	for resource_name in ["Food","Timber","Stone","Clay","Fiber Plants","Salt","Medicinal Plants","Coal"]:
		var stock:=maxf(0.0,float(GameState.resource_stockpiles.get(resource_name,0.0)))
		if not _resource_is_economically_known(resource_name,stock): continue
		var desired:=_desired_stock(resource_name,maxf(1.0,GameState.population_exact))
		var exportable:=maxf(0.0,stock-desired*1.25)
		if exportable<=0.001: continue
		export_candidates.append({"resource":resource_name,"quantity":exportable,"score":exportable/maxf(0.01,desired)})
	export_candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.score)>float(b.score))
	for candidate_variant in export_candidates:
		if export_budget<=0.001: break
		var candidate:Dictionary=candidate_variant
		var resource_name:=String(candidate.resource)
		var unit_value:=maxf(0.01,float(GameState.market_prices.get(resource_name,BASE_VALUES.get(resource_name,1.0))))
		var requested:=minf(float(candidate.quantity),export_budget/maxf(0.01,unit_value*(1.0-friction)))
		var removed:=_remove_trade_resource(resource_name,requested)
		var gross:=removed*unit_value
		var earned:=gross*(1.0-friction)
		if earned<=0.0: continue
		GameState.external_trade_credit+=earned
		GameState.external_trade_exports+=earned
		result.exports=float(result.exports)+earned
		result.friction=float(result.friction)+gross-earned
		result.exported_goods[resource_name]=float(result.exported_goods.get(resource_name,0.0))+removed
		export_budget-=earned
		_ledger("external_export",earned,"material_stores","regional_trade_account","Exported %.2f %s after trade friction" % [removed,resource_name])
	var import_budget:=minf(GameState.external_trade_credit,value_capacity*import_share)
	var import_candidates:Array[Dictionary]=[]
	for resource_name_variant in BASE_VALUES:
		var resource_name:=String(resource_name_variant)
		if resource_name in ["Coin","Transport Carts"]: continue
		var stock:=maxf(0.0,float(GameState.resource_stockpiles.get(resource_name,0.0)))
		if not _resource_is_economically_known(resource_name,stock): continue
		var desired:=_desired_stock(resource_name,maxf(1.0,GameState.population_exact))
		var deficit:=maxf(0.0,desired*0.75-stock)
		if deficit<=0.001: continue
		import_candidates.append({"resource":resource_name,"quantity":deficit,"score":deficit/maxf(0.01,desired)})
	import_candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.score)>float(b.score))
	var food_imported:=0.0
	for candidate_variant in import_candidates:
		if import_budget<=0.001 or GameState.external_trade_credit<=0.001: break
		var candidate:Dictionary=candidate_variant
		var resource_name:=String(candidate.resource)
		var unit_cost:=maxf(0.01,float(GameState.market_prices.get(resource_name,BASE_VALUES.get(resource_name,1.0)))*(1.0+friction))
		var requested:=minf(float(candidate.quantity),minf(import_budget,GameState.external_trade_credit)/unit_cost)
		var received:=_receive_trade_resource(resource_name,requested)
		var paid:=minf(GameState.external_trade_credit,received*unit_cost)
		if paid<=0.0: continue
		GameState.external_trade_credit-=paid
		GameState.external_trade_imports+=paid
		result.imports=float(result.imports)+paid
		result.imported_goods[resource_name]=float(result.imported_goods.get(resource_name,0.0))+received
		if resource_name=="Food": food_imported+=received
		import_budget-=paid
		_ledger("external_import",paid,"regional_trade_account","material_stores","Imported %.2f %s" % [received,resource_name])
	GameState.external_trade_credit=maxf(0.0,GameState.external_trade_credit)
	result.credit=GameState.external_trade_credit
	_update_food_import_dependence(food_imported)
	return result

func _remove_trade_resource(resource_name:String,requested:float)->float:
	if resource_name=="Food": return FoodSystem.issue_for_obligation(requested,"trade","Food export")
	var available:=maxf(0.0,float(GameState.resource_stockpiles.get(resource_name,0.0)))
	var removed:=minf(available,maxf(0.0,requested))
	GameState.resource_stockpiles[resource_name]=available-removed
	return removed

func _receive_trade_resource(resource_name:String,requested:float)->float:
	var received:=maxf(0.0,requested)
	if resource_name=="Food": return FoodSystem.receive_external_food(received)
	GameState.resource_stockpiles[resource_name]=float(GameState.resource_stockpiles.get(resource_name,0.0))+received
	return received

func _update_food_import_dependence(food_imported:float)->void:
	var food_need:=maxf(0.01,float(GameState.simulation_metrics.get("food_consumption",GameState.population_exact)))
	var daily_share:=clampf(food_imported/food_need,0.0,1.0)
	var prior:=clampf(float(GameState.simulation_metrics.get("food_import_share",0.0)),0.0,1.0)
	GameState.simulation_metrics["food_import_share"]=lerpf(prior,daily_share,0.04)

func cycle_external_trade_policy()->String:
	var policies:=["balanced","relief_imports","export_surplus","closed"]
	var index:=policies.find(GameState.external_trade_policy)
	GameState.external_trade_policy=String(policies[(index+1)%policies.size()])
	_ledger("policy",0.0,"sovereign","regional_trade",GameState.external_trade_policy.replace("_"," ").capitalize()+" trade stance")
	return GameState.external_trade_policy

func _real_economy_accounts(trade_volume:float,market_access:float,military_burden:Dictionary={})->Dictionary:
	# These accounts observe the physical simulation; they do not consume a second
	# ration or material unit. FoodSystem and ResourceSystem remain authoritative.
	var population:=maxf(1.0,GameState.population_exact)
	var able:=maxf(1.0,float(GameState.able_population()))
	var food_need:=maxf(0.01,float(GameState.simulation_metrics.get("food_consumption",population)))
	var fallback_eaten:=minf(food_need,maxf(0.0,float(GameState.resource_stockpiles.get("Food",0.0))))
	var food_eaten:=maxf(0.0,float(GameState.simulation_metrics.get("food_eaten",fallback_eaten)))
	var food_coverage:=clampf(float(GameState.simulation_metrics.get("food_intake_ratio",food_eaten/food_need)),0.0,1.0)
	var material_coverage:=0.0
	for resource_name in ["Timber","Stone","Clay","Fiber Plants"]:
		var desired:=_desired_stock(resource_name,population)
		material_coverage+=clampf(float(GameState.resource_stockpiles.get(resource_name,0.0))/maxf(0.01,desired),0.0,1.0)
	material_coverage/=4.0
	var housing_ratio:=clampf(float(GameState.housing_capacity)/population,0.0,1.0)
	if GameState.convoy_traveling:
		housing_ratio=clampf(0.20+float(GameState.population_allocations.get("Logistics",0))/maxf(1.0,population*0.10)*0.27+float(GameState.population_allocations.get("Construction",0))/maxf(1.0,population*0.12)*0.17,0.0,0.86)
	var essential_coverage:=clampf(food_coverage*0.62+material_coverage*0.18+housing_ratio*0.20,0.0,1.0)
	var mobilized:=_first_numeric(military_burden,["mobilized_population","field_personnel","mobilized_citizens","field_soldiers"])
	var security_duty:=maxf(mobilized,float(GameState.population_allocations.get("Defense",0))*0.50)
	var workshop_diversion:=clampf(_first_numeric(military_burden,["workshop_diversion"]),0.0,1.0)
	var diverted_craft_labor:=float(GameState.population_allocations.get("Crafting",0))*workshop_diversion
	var collective_labor:=float(GameState.population_allocations.get("Administration",0))+float(GameState.population_allocations.get("Construction",0))*0.35+float(GameState.population_allocations.get("Logistics",0))*0.20+security_duty+diverted_craft_labor
	var collective_labor_share:=clampf(collective_labor/able,0.0,1.0)
	var exchangeable_surplus_value:=0.0
	for resource_name_variant in BASE_VALUES:
		var resource_name:=String(resource_name_variant)
		var stock:=maxf(0.0,float(GameState.resource_stockpiles.get(resource_name,0.0)))
		if not _resource_is_economically_known(resource_name,stock): continue
		var surplus:=maxf(0.0,stock-_desired_stock(resource_name,population))
		exchangeable_surplus_value+=surplus*float(GameState.market_prices.get(resource_name,BASE_VALUES[resource_name]))
	var food_output:=maxf(0.0,float(GameState.simulation_metrics.get("food_production",0.0)))*float(GameState.market_prices.get("Food",1.0))
	var delivered_output:=maxf(0.0,float(GameState.material_metrics.get("delivered_today",0.0)))*2.0
	var output_value:=food_output+delivered_output
	var essential_basket_cost:=food_need*float(GameState.market_prices.get("Food",1.0))+population*(0.006*float(GameState.market_prices.get("Timber",2.4))+0.004*float(GameState.market_prices.get("Fiber Plants",2.0))+0.002*float(GameState.market_prices.get("Stone",1.8))+0.002*float(GameState.market_prices.get("Clay",1.1)))
	var private_liquidity_days:=GameState.private_currency/maxf(0.01,essential_basket_cost) if GameState.economy_stage==STAGE_CURRENCY else 0.0
	var daily_labor_income:=output_value*clampf(0.68+market_access*0.12,0.62,0.82)
	var labor_income_per_able:=daily_labor_income/able
	var basket_per_person:=essential_basket_cost/population
	var labor_return_index:=clampf(labor_income_per_able/maxf(0.01,basket_per_person),0.0,3.0)
	var equipment_backlog:=_first_numeric(military_burden,["equipment_backlog_work"])
	var backlog_pressure:=clampf(equipment_backlog/maxf(1.0,population)*0.08,0.0,0.08)
	var obligation_pressure:=clampf((1.0-essential_coverage)*0.72+maxf(0.0,collective_labor_share-0.18)*0.85+(1.0-market_access)*0.04+backlog_pressure,0.0,1.0)
	return {"food_need":food_need,"food_delivered":food_eaten,"food_coverage":food_coverage,"material_coverage":material_coverage,"shelter_coverage":housing_ratio,"essential_coverage":essential_coverage,"collective_labor":collective_labor,"collective_labor_share":collective_labor_share,"mobilized_labor":mobilized,"diverted_craft_labor":diverted_craft_labor,"equipment_backlog_work":equipment_backlog,"exchangeable_surplus_value":exchangeable_surplus_value,"daily_output_value":output_value,"output_per_capita":output_value/population,"essential_basket_cost":essential_basket_cost,"basket_per_person":basket_per_person,"daily_labor_income":daily_labor_income,"labor_income_per_able":labor_income_per_able,"labor_return_index":labor_return_index,"private_liquidity_days":private_liquidity_days,"obligation_pressure":obligation_pressure,"observed_trade":trade_volume}

func _process_resource_obligations(real_accounts:Dictionary,monetization:float,reliability:float)->Dictionary:
	# Public labor and material dues classify work and goods already handled by the
	# physical simulation. They never remove a second unit from stores. Unfulfilled
	# assessed dues persist here as claims, not as invented resources or currency.
	var population:=maxf(1.0,GameState.population_exact)
	var able:=maxf(1.0,float(GameState.able_population()))
	var levy_adoption:=DiscoverySystem.adoption("public_levies")
	var rotations:=DiscoverySystem.adoption("labor_rotations")
	var public_stores:=DiscoverySystem.adoption("public_stores")
	var councils:=DiscoverySystem.adoption("household_councils")
	var customary_law:=DiscoverySystem.adoption("customary_law")
	var tallies:=DiscoverySystem.adoption("tallies")
	var admin_coverage:=clampf(float(GameState.population_allocations.get("Administration",0))/maxf(1.0,population*0.04),0.0,1.0)
	var scheduled:=levy_adoption>=0.25
	var regime:="customary obligations"
	if scheduled: regime="scheduled in-kind levies"
	if GameState.economy_stage==STAGE_CURRENCY: regime="monetary levy with residual dues"
	var in_kind_share:=1.0
	match GameState.economy_stage:
		STAGE_METAL: in_kind_share=clampf(0.88-monetization*0.32,0.62,0.85)
		STAGE_CURRENCY: in_kind_share=clampf(0.34-monetization*0.22+(1.0-reliability)*0.12,0.12,0.42)
	var assessment_reach:=clampf(0.40+councils*0.10+customary_law*0.12+tallies*0.10+admin_coverage*0.10+levy_adoption*0.24,0.30,1.0)
	var settlement_complexity:=minf(0.035,float(GameState.settlement_completed.size())/population*0.10)
	var gross_labor_due:=able*(0.028+settlement_complexity)*in_kind_share
	var assessed_labor_due:=gross_labor_due*assessment_reach
	var labor_carry:=0.96 if scheduled else 0.35
	if GameState.economy_stage==STAGE_CURRENCY: labor_carry=0.90
	var carried_labor:=maxf(0.0,GameState.in_kind_labor_arrears)*labor_carry
	var labor_outstanding:=carried_labor+assessed_labor_due
	var rendered_labor:=maxf(0.0,float(real_accounts.get("collective_labor",0.0)))*clampf(0.68+rotations*0.20+levy_adoption*0.12,0.68,1.0)
	var labor_fulfilled:=minf(labor_outstanding,rendered_labor)
	GameState.in_kind_labor_arrears=maxf(0.0,labor_outstanding-labor_fulfilled)
	var gross_material_due:=population*(0.0075+settlement_complexity*0.20)*in_kind_share
	var assessed_material_due:=gross_material_due*assessment_reach
	var material_carry:=0.97 if scheduled else 0.30
	if GameState.economy_stage==STAGE_CURRENCY: material_carry=0.90
	var carried_material:=maxf(0.0,GameState.in_kind_material_arrears)*material_carry
	var material_outstanding:=carried_material+assessed_material_due
	var delivered_value:=maxf(0.0,float(GameState.material_metrics.get("delivered_today",0.0)))*2.0
	var common_store_share:=clampf(0.16+public_stores*0.38+levy_adoption*0.28+admin_coverage*0.10,0.16,0.92)
	var material_fulfilled:=minf(material_outstanding,delivered_value*common_store_share)
	GameState.in_kind_material_arrears=maxf(0.0,material_outstanding-material_fulfilled)
	var labor_coverage:=labor_fulfilled/maxf(0.001,labor_outstanding) if labor_outstanding>0.0 else 1.0
	var material_coverage:=material_fulfilled/maxf(0.001,material_outstanding) if material_outstanding>0.0 else 1.0
	var labor_arrears_days:=GameState.in_kind_labor_arrears/maxf(0.05,assessed_labor_due)
	var material_arrears_days:=GameState.in_kind_material_arrears/maxf(0.05,assessed_material_due)
	var unassessed_share:=1.0-assessment_reach
	var pressure:=clampf(labor_arrears_days/30.0*0.18+material_arrears_days/30.0*0.16+unassessed_share*0.035,0.0,0.38)
	if labor_fulfilled>0.0: _ledger("labor_due_rendered",labor_fulfilled,"households","collective_works","%s labor service" % regime)
	if material_fulfilled>0.0: _ledger("material_due_rendered",material_fulfilled,"households","public_stores","%s material contribution value" % regime)
	return {"regime":regime,"scheduled":scheduled,"scheduled_adoption":levy_adoption,"in_kind_share":in_kind_share,"assessment_reach":assessment_reach,"gross_labor_due":gross_labor_due,"labor_due":assessed_labor_due,"labor_outstanding":labor_outstanding,"labor_fulfilled":labor_fulfilled,"labor_arrears":GameState.in_kind_labor_arrears,"labor_coverage":clampf(labor_coverage,0.0,1.0),"gross_material_due":gross_material_due,"material_due":assessed_material_due,"material_outstanding":material_outstanding,"material_fulfilled":material_fulfilled,"material_arrears":GameState.in_kind_material_arrears,"material_coverage":clampf(material_coverage,0.0,1.0),"pressure":pressure}

func _process_public_finance(trade_volume:float,monetization:float,military_burden:Dictionary={})->Dictionary:
	if GameState.economy_stage!=STAGE_CURRENCY: return {"revenue":0.0,"spending":0.0,"civil_upkeep":0.0,"military_upkeep":0.0,"civil_due":0.0,"military_due":0.0,"civil_coverage":1.0,"military_coverage":1.0,"spending_priority":GameState.public_spending_priority,"borrowing":0.0,"debt_service":0.0,"interest_accrued":0.0,"debt_capacity":0.0,"tax_capacity":_tax_capacity_for(GameState.tax_rate,trade_volume,monetization,GameState.private_currency)}
	var admin_coverage:=clampf(float(GameState.population_allocations.get("Administration",0))/maxf(1.0,GameState.population_exact*0.04),0.0,1.0)
	var tax_capacity:=_tax_capacity_for(GameState.tax_rate,trade_volume,monetization,GameState.private_currency)
	var revenue:=float(tax_capacity.collectible)
	GameState.private_currency-=revenue
	GameState.public_treasury+=revenue
	var debt_capacity:=_public_debt_capacity(trade_volume,monetization,admin_coverage,GameState.tax_rate,float(tax_capacity.compliance))
	var interest_accrued:=0.0
	if GameState.public_debt>0.0:
		var institutions:=clampf(float(GameState.society_capacities.get("institutions",0.25)),0.0,1.0)
		var utilization:=GameState.public_debt/maxf(1.0,debt_capacity)
		var annual_rate:=clampf(0.025+(1.0-institutions)*0.055+utilization*0.035-DiscoverySystem.adoption("public_credit")*0.015,0.012,0.14)
		interest_accrued=GameState.public_debt*annual_rate/365.0
		GameState.public_debt+=interest_accrued
		GameState.public_interest_accrued+=interest_accrued
	var upkeep:=_public_upkeep(military_burden)
	var civil_obligation:=GameState.civil_arrears+float(upkeep.civil)
	var military_obligation:=GameState.military_arrears+float(upkeep.military)
	var requested:=civil_obligation+military_obligation
	var borrowing:=0.0
	if GameState.public_treasury<requested and DiscoverySystem.adoption("public_credit")>=0.25:
		var debt_room:=maxf(0.0,debt_capacity-GameState.public_debt)
		borrowing=minf(requested-GameState.public_treasury,minf(debt_room,GameState.private_currency))
		GameState.private_currency-=borrowing
		GameState.public_treasury+=borrowing
		GameState.public_debt+=borrowing
		GameState.public_borrowed+=borrowing
		if borrowing>0.0: _ledger("public_borrowing",borrowing,"private","public","Treasury obligation issue")
	var allocation:=_allocate_public_spending(GameState.public_treasury,civil_obligation,military_obligation,GameState.public_spending_priority)
	var spending:=float(allocation.spending)
	GameState.public_treasury-=spending
	GameState.private_currency+=spending
	if revenue>0.0: _ledger("tax",revenue,"private","public","Exchange levy")
	if spending>0.0: _ledger("spending",spending,"public","private","Civil and military public obligations")
	var civil_paid:=float(allocation.civil_paid)
	var military_paid:=float(allocation.military_paid)
	GameState.civil_arrears=maxf(0.0,civil_obligation-civil_paid)
	GameState.military_arrears=maxf(0.0,military_obligation-military_paid)
	var debt_service:=minf(GameState.public_debt,minf(GameState.public_treasury,maxf(0.0,revenue-spending)*0.55+GameState.public_treasury*0.12))
	if debt_service>0.0:
		GameState.public_treasury-=debt_service
		GameState.private_currency+=debt_service
		GameState.public_debt=maxf(0.0,GameState.public_debt-debt_service)
		GameState.public_debt_repaid+=debt_service
		_ledger("public_debt_service",debt_service,"public","private","Public credit principal and interest")
	return {"revenue":revenue,"spending":spending,"civil_upkeep":civil_paid,"military_upkeep":military_paid,"civil_due":float(upkeep.civil),"military_due":float(upkeep.military),"civil_coverage":allocation.civil_coverage,"military_coverage":allocation.military_coverage,"spending_priority":allocation.priority,"borrowing":borrowing,"debt_service":debt_service,"interest_accrued":interest_accrued,"debt_capacity":debt_capacity,"tax_capacity":tax_capacity}

func _public_debt_capacity(trade_volume:float,monetization:float,admin_coverage:float,tax_rate_override:float=-1.0,compliance_override:float=1.0)->float:
	var adoption:=DiscoverySystem.adoption("public_credit")
	if adoption<0.25: return 0.0
	var effective_tax_rate:=GameState.tax_rate if tax_rate_override<0.0 else clampf(tax_rate_override,0.0,0.25)
	var annual_revenue_base:=maxf(GameState.population_exact*0.05,trade_volume*clampf(effective_tax_rate,0.01,0.25)*admin_coverage*monetization*clampf(compliance_override,0.0,1.0)*365.0)
	var institutions:=clampf(float(GameState.society_capacities.get("institutions",0.25)),0.0,1.0)
	return maxf(0.0,annual_revenue_base*(0.35+adoption*1.65)*clampf(0.45+institutions,0.45,1.45)+GameState.currency_supply*adoption*0.12)

func _public_upkeep(military_burden:Dictionary={})->Dictionary:
	if GameState.economy_stage!=STAGE_CURRENCY: return {"civil":0.0,"military":0.0,"total":0.0}
	var civil:=GameState.settlement_completed.size()*0.018+float(GameState.population_allocations.get("Administration",0))*0.004
	var military:=_first_numeric(military_burden,["currency_upkeep_units","suggested_currency_upkeep","suggested_currency_stage_upkeep","suggested_currency_stage_payroll","suggested_payroll_upkeep","currency_upkeep","currency_payroll"])
	military=clampf(military,0.0,maxf(1.0,GameState.population_exact*0.50))
	return {"civil":civil,"military":military,"total":civil+military}

func tax_capacity_snapshot(rate:float=-1.0,trade_volume:float=-1.0,monetization:float=-1.0)->Dictionary:
	var effective_rate:=GameState.tax_rate if rate<0.0 else rate
	var observed_trade:=float(GameState.economy_metrics.get("trade_volume",0.0)) if trade_volume<0.0 else trade_volume
	var observed_monetization:=float(GameState.economy_metrics.get("monetization",0.0)) if monetization<0.0 else monetization
	return _tax_capacity_for(effective_rate,observed_trade,observed_monetization,GameState.private_currency)

func _tax_capacity_for(rate:float,trade_volume:float,monetization:float,private_currency:float)->Dictionary:
	var statutory_rate:=clampf(rate,0.0,0.25)
	var result:={"active":GameState.economy_stage==STAGE_CURRENCY,"statutory_rate":statutory_rate,"compliance":0.0,"administrative_reach":0.0,"taxable_exchange":0.0,"statutory_assessment":0.0,"administratively_assessed":0.0,"compliant_assessment":0.0,"collectible":0.0,"effective_rate":0.0,"noncompliance_gap":0.0,"liquidity_gap":0.0}
	if GameState.economy_stage!=STAGE_CURRENCY: return result
	var admin_coverage:=clampf(float(GameState.population_allocations.get("Administration",0))/maxf(1.0,GameState.population_exact*0.04),0.0,1.0)
	var legitimacy:=clampf(float(GameState.simulation_metrics.get("legitimacy",0.50)),0.0,1.0)
	var institutions:=clampf(float(GameState.society_capacities.get("institutions",0.25)),0.0,1.0)
	var records:=maxf(DiscoverySystem.adoption("tallies"),DiscoverySystem.adoption("property_registers"))
	var inequality:=clampf(float(GameState.economy_metrics.get("inequality",0.32)),0.0,1.0)
	var arrears_ratio:=clampf((GameState.civil_arrears+GameState.military_arrears)/maxf(1.0,GameState.population_exact*0.15),0.0,1.0)
	var rate_strain:=maxf(0.0,statutory_rate-0.10)*1.80+maxf(0.0,statutory_rate-0.18)*1.50
	var compliance:=clampf(0.38+admin_coverage*0.20+legitimacy*0.18+institutions*0.12+records*0.10-inequality*0.08-arrears_ratio*0.15-rate_strain,0.18,0.98)
	var taxable_exchange:=maxf(0.0,trade_volume)*clampf(monetization,0.0,1.0)
	var statutory_assessment:=taxable_exchange*statutory_rate
	var administratively_assessed:=statutory_assessment*admin_coverage
	var compliant_assessment:=administratively_assessed*compliance
	var collectible:=minf(maxf(0.0,private_currency),compliant_assessment)
	result.compliance=compliance
	result.administrative_reach=admin_coverage
	result.taxable_exchange=taxable_exchange
	result.statutory_assessment=statutory_assessment
	result.administratively_assessed=administratively_assessed
	result.compliant_assessment=compliant_assessment
	result.collectible=collectible
	result.effective_rate=collectible/maxf(0.001,taxable_exchange) if taxable_exchange>0.0 else 0.0
	result.noncompliance_gap=maxf(0.0,administratively_assessed-compliant_assessment)
	result.liquidity_gap=maxf(0.0,compliant_assessment-collectible)
	return result

func set_public_spending_priority(priority:String)->String:
	var normalized:=priority.strip_edges().to_lower().replace("-","_").replace(" ","_")
	if normalized not in PUBLIC_SPENDING_PRIORITIES: normalized="balanced"
	GameState.public_spending_priority=normalized
	_ledger("policy",0.0,"sovereign","public_finance","Public spending priority: %s" % normalized.replace("_"," "))
	return normalized

func cycle_public_spending_priority()->String:
	var current:=PUBLIC_SPENDING_PRIORITIES.find(GameState.public_spending_priority)
	return set_public_spending_priority(String(PUBLIC_SPENDING_PRIORITIES[(current+1)%PUBLIC_SPENDING_PRIORITIES.size()]))

func _allocate_public_spending(available:float,civil_due:float,military_due:float,priority:String="balanced")->Dictionary:
	var normalized:=priority if priority in PUBLIC_SPENDING_PRIORITIES else "balanced"
	var civil:=maxf(0.0,civil_due)
	var military:=maxf(0.0,military_due)
	var spending:=minf(maxf(0.0,available),civil+military)
	var civil_paid:=0.0
	var military_paid:=0.0
	match normalized:
		"civil_first":
			civil_paid=minf(civil,spending)
			military_paid=minf(military,maxf(0.0,spending-civil_paid))
		"military_first":
			military_paid=minf(military,spending)
			civil_paid=minf(civil,maxf(0.0,spending-military_paid))
		_:
			var total_due:=civil+military
			var paid_ratio:=spending/maxf(0.001,total_due) if total_due>0.0 else 1.0
			civil_paid=civil*paid_ratio
			military_paid=military*paid_ratio
	return {"priority":normalized,"available":maxf(0.0,available),"spending":civil_paid+military_paid,"civil_due":civil,"military_due":military,"civil_paid":civil_paid,"military_paid":military_paid,"civil_coverage":civil_paid/maxf(0.001,civil) if civil>0.0 else 1.0,"military_coverage":military_paid/maxf(0.001,military) if military>0.0 else 1.0}

func fiscal_outlook(days:float=30.0,trade_volume:float=-1.0,monetization:float=-1.0,military_burden:Dictionary={})->Dictionary:
	# A read-only planning view. It does not promise future production or create
	# purchasing power; it projects only the currently visible fiscal base.
	var horizon:=clampf(days,1.0,365.0)
	var observed_trade:=trade_volume if trade_volume>=0.0 else float(GameState.economy_metrics.get("trade_volume",0.0))
	var observed_monetization:=monetization if monetization>=0.0 else float(GameState.economy_metrics.get("monetization",0.0))
	var burden:Dictionary=military_burden.duplicate(true) if not military_burden.is_empty() else _military_burden_snapshot()
	return _fiscal_outlook_for(horizon,observed_trade,observed_monetization,burden,GameState.public_treasury,GameState.private_currency,GameState.tax_rate)

func _fiscal_outlook_for(days:float,trade_volume:float,monetization:float,military_burden:Dictionary,treasury:float,private_currency:float,tax_rate:float,spending_priority:String="")->Dictionary:
	var horizon:=clampf(days,1.0,365.0)
	var tax_capacity:=_tax_capacity_for(tax_rate,trade_volume,monetization,private_currency)
	var daily_revenue:=float(tax_capacity.collectible)
	var upkeep:Dictionary=_public_upkeep(military_burden)
	var daily_civil:=float(upkeep.civil)
	var daily_military:=float(upkeep.military)
	var debt_capacity:=_public_debt_capacity(trade_volume,monetization,float(tax_capacity.administrative_reach),tax_rate,float(tax_capacity.compliance))
	var institutions:=clampf(float(GameState.society_capacities.get("institutions",0.25)),0.0,1.0)
	var utilization:=GameState.public_debt/maxf(1.0,debt_capacity)
	var annual_interest_rate:=clampf(0.025+(1.0-institutions)*0.055+utilization*0.035-DiscoverySystem.adoption("public_credit")*0.015,0.012,0.14) if GameState.public_debt>0.0 else 0.0
	var daily_interest:=GameState.public_debt*annual_interest_rate/365.0
	var civil_arrears:=maxf(0.0,GameState.civil_arrears)
	var military_arrears:=maxf(0.0,GameState.military_arrears)
	var existing_arrears:=civil_arrears+military_arrears
	var daily_commitment:=daily_civil+daily_military+daily_interest
	var projected_due:=existing_arrears+daily_commitment*horizon
	var projected_revenue:=daily_revenue*horizon
	var cash_available:=maxf(0.0,treasury)+projected_revenue
	var debt_room:=maxf(0.0,debt_capacity-GameState.public_debt)
	var borrowable_private:=maxf(0.0,private_currency-daily_revenue)
	var borrowing_headroom:=minf(debt_room,borrowable_private) if DiscoverySystem.adoption("public_credit")>=0.25 else 0.0
	var funded_available:=cash_available+borrowing_headroom
	var normalized_priority:=GameState.public_spending_priority if spending_priority=="" else spending_priority
	if normalized_priority not in PUBLIC_SPENDING_PRIORITIES: normalized_priority="balanced"
	var projected_civil_due:=civil_arrears+daily_civil*horizon
	var projected_military_due:=military_arrears+daily_military*horizon
	var program_funds:=maxf(0.0,funded_available-daily_interest*horizon)
	var projected_allocation:=_allocate_public_spending(program_funds,projected_civil_due,projected_military_due,normalized_priority)
	var coverage_ratio:=funded_available/projected_due if projected_due>0.0001 else 1.0
	var unfunded:=maxf(0.0,projected_due-funded_available)
	var protected_buffer:=existing_arrears+daily_commitment*14.0
	var discretionary_headroom:=maxf(0.0,treasury-protected_buffer)
	var net_daily:=daily_revenue-daily_commitment
	var runway_days:=365.0 if net_daily>=0.0 else clampf(maxf(0.0,treasury-existing_arrears)/maxf(0.001,-net_daily),0.0,365.0)
	var status:="sound"
	if unfunded>0.001 or existing_arrears>maxf(1.0,(daily_civil+daily_military)*14.0): status="default risk"
	elif coverage_ratio<1.15 or runway_days<30.0: status="strained"
	elif discretionary_headroom<=0.001: status="thin"
	var warning:="Current receipts and treasury cover the visible obligations."
	match status:
		"default risk": warning="Visible treasury, receipts, and safe borrowing cannot cover the forecast obligations."
		"strained": warning="The forecast clears only narrowly; a price, trade, or mobilization shock could create arrears."
		"thin": warning="The treasury is solvent but has no balance above a conservative fourteen-day obligation buffer."
	return {"active":GameState.economy_stage==STAGE_CURRENCY,"days":horizon,"status":status,"warning":warning,"spending_priority":normalized_priority,"daily_revenue":daily_revenue,"tax_compliance":tax_capacity.compliance,"effective_tax_rate":tax_capacity.effective_rate,"tax_noncompliance_gap":tax_capacity.noncompliance_gap,"tax_liquidity_gap":tax_capacity.liquidity_gap,"daily_civil":daily_civil,"daily_military":daily_military,"daily_interest":daily_interest,"existing_arrears":existing_arrears,"projected_civil_due":projected_civil_due,"projected_military_due":projected_military_due,"projected_civil_paid":projected_allocation.civil_paid,"projected_military_paid":projected_allocation.military_paid,"civil_coverage":projected_allocation.civil_coverage,"military_coverage":projected_allocation.military_coverage,"projected_due":projected_due,"projected_revenue":projected_revenue,"projected_cash_before_borrowing":cash_available-projected_due,"borrowing_headroom":borrowing_headroom,"coverage_ratio":coverage_ratio,"unfunded":unfunded,"protected_buffer":protected_buffer,"discretionary_headroom":discretionary_headroom,"runway_days":runway_days,"debt_capacity":debt_capacity,"annual_interest_rate":annual_interest_rate}

func _military_burden_snapshot()->Dictionary:
	var campaign:=get_node_or_null("/root/MilitaryCampaign")
	if campaign==null or not campaign.has_method("economic_burden_snapshot"): return {}
	var snapshot_variant:Variant=campaign.call("economic_burden_snapshot")
	if snapshot_variant is not Dictionary: return {}
	return (snapshot_variant as Dictionary).duplicate(true)

func _first_numeric(source:Dictionary,keys:Array[String])->float:
	for key in keys:
		if not source.has(key): continue
		var value:Variant=source[key]
		if value is float or value is int: return maxf(0.0,float(value))
	return 0.0

func _metal_processing_efficiency()->float:
	var smelting:=DiscoverySystem.adoption("copper_smelting")
	var casting:=DiscoverySystem.adoption("copper_casting")
	return clampf(0.35+smelting*0.45+casting*0.20,0.20,0.95)

func _available_metal_value()->float:
	var efficiency:=_metal_processing_efficiency()
	var result:=0.0
	for resource_name in METAL_VALUES:
		var processing:=1.0 if resource_name=="Coin" else efficiency
		result+=float(GameState.resource_stockpiles.get(resource_name,0.0))*float(METAL_VALUES[resource_name])*processing
	return result

func _monetary_reserve_value()->float:
	var result:=0.0
	for value in GameState.monetary_reserve_metals.values(): result+=maxf(0.0,float(value))
	return result

func _weighed_metal_value()->float:
	var result:=0.0
	for value in GameState.weighed_metal_composition.values(): result+=maxf(0.0,float(value))
	return result

func _process_weighed_metal_exchange(trade_volume:float,monetization:float,reliability:float)->Dictionary:
	var result:={"active":false,"turnover":0.0,"velocity":0.0,"wear_loss":0.0,"circulation":GameState.weighed_metal_circulation}
	if GameState.economy_stage==STAGE_SUBSISTENCE or GameState.weighed_metal_circulation<=0.0001: return result
	result.active=true
	var measures:=DiscoverySystem.adoption("standard_measures")
	var turnover_capacity:=GameState.weighed_metal_circulation*clampf(0.07+reliability*0.13+measures*0.08,0.06,0.28)
	var metal_trade_share:=monetization if GameState.economy_stage==STAGE_METAL else clampf(0.08+(1.0-reliability)*0.05,0.05,0.16)
	var turnover:=minf(maxf(0.0,trade_volume)*metal_trade_share,turnover_capacity)
	var wear_rate:=clampf(0.000015+(1.0-measures)*0.000035+(1.0-reliability)*0.000025,0.00001,0.00008)
	var wear_loss:=_remove_weighed_metal_value(turnover*wear_rate+GameState.weighed_metal_circulation*0.000001)
	GameState.weighed_metal_losses+=wear_loss
	GameState.weighed_metal_circulation=_weighed_metal_value()
	if wear_loss>=0.01: _ledger("weighed_metal_wear",wear_loss,"metal_circulation","lost","Abrasion, clipping, and assay loss")
	result.turnover=turnover
	result.velocity=turnover/maxf(0.001,GameState.weighed_metal_circulation)
	result.wear_loss=wear_loss
	result.circulation=GameState.weighed_metal_circulation
	return result

func _remove_weighed_metal_value(requested_value:float)->float:
	var remaining:=minf(maxf(0.0,requested_value),_weighed_metal_value())
	var removed:=0.0
	var names:Array[String]=[]
	for resource_name_variant in GameState.weighed_metal_composition: names.append(String(resource_name_variant))
	names.sort()
	for resource_name in names:
		if remaining<=0.000001: break
		var held:=maxf(0.0,float(GameState.weighed_metal_composition.get(resource_name,0.0)))
		var taken:=minf(held,remaining)
		GameState.weighed_metal_composition[resource_name]=held-taken
		if float(GameState.weighed_metal_composition[resource_name])<=0.000001: GameState.weighed_metal_composition.erase(resource_name)
		remaining-=taken
		removed+=taken
	return removed

func _shortage_pressure()->float:
	var total:=0.0
	for resource_name in ["Food","Timber","Stone","Fiber Plants"]:
		var desired:=_desired_stock(resource_name,maxf(1.0,GameState.population_exact))
		total+=clampf(1.0-float(GameState.resource_stockpiles.get(resource_name,0.0))/maxf(1.0,desired),0.0,1.0)
	return total/4.0

func _exchange_reliability(market_access:float,market_volatility:float=-1.0)->float:
	var legitimacy:=float(GameState.simulation_metrics.get("legitimacy",0.5))
	var institutions:=float(GameState.society_capacities.get("institutions",0.25))
	var backing:=clampf(_monetary_reserve_value()/maxf(1.0,GameState.currency_supply*0.40),0.0,1.0) if GameState.economy_stage==STAGE_CURRENCY else 0.5
	var volatility:=float(GameState.economy_metrics.get("market_volatility",0.0)) if market_volatility<0.0 else market_volatility
	return clampf(legitimacy*0.36+institutions*0.30+market_access*0.18+backing*0.16-clampf(volatility*1.8,0.0,0.14),0.0,1.0)

func _market_volatility(current_index:float,lookback_days:int=30)->float:
	var samples:Array[float]=[]
	var start:=maxi(0,GameState.economy_history.size()-maxi(2,lookback_days))
	for index in range(start,GameState.economy_history.size()):
		samples.append(maxf(0.001,float(GameState.economy_history[index].get("price_index",1.0))))
	samples.append(maxf(0.001,current_index))
	if samples.size()<2: return 0.0
	var movement:=0.0
	for index in range(1,samples.size()): movement+=absf(samples[index]/samples[index-1]-1.0)
	return movement/float(samples.size()-1)

func _process_currency_liquidity(reliability:float,market_volatility:float)->Dictionary:
	var result:={"active":false,"confidence":0.0,"hoard_share":0.0,"desired_hoard_share":0.0,"transactional_share":0.0,"nontransactional_share":0.0,"hoarded_today":0.0,"released_today":0.0,"liquid_private":GameState.private_currency,"hoards":GameState.currency_hoards}
	if GameState.economy_stage!=STAGE_CURRENCY or GameState.currency_supply<=0.0: return result
	result.active=true
	var institutions:=clampf(float(GameState.society_capacities.get("institutions",0.25)),0.0,1.0)
	var reserve_security:=clampf(_monetary_reserve_value()/maxf(1.0,GameState.currency_supply*0.40),0.0,1.0)
	var recent_inflation:=absf(float(GameState.economy_metrics.get("inflation",0.0)))
	var price_stability:=clampf(1.0-market_volatility*7.0-recent_inflation*2.5,0.0,1.0)
	var arrears_ratio:=clampf((GameState.civil_arrears+GameState.military_arrears)/maxf(1.0,GameState.population_exact*0.15),0.0,1.0)
	var fiscal_confidence:=1.0-arrears_ratio
	var confidence:=clampf(reliability*0.35+reserve_security*0.25+price_stability*0.18+institutions*0.12+fiscal_confidence*0.10,0.0,1.0)
	var desired_share:=clampf(0.025+maxf(0.0,0.68-confidence)*0.62+maxf(0.0,recent_inflation-0.02)*0.45,0.02,0.38)
	var target:=GameState.currency_supply*desired_share
	var hoarded_today:=0.0
	var released_today:=0.0
	if target>GameState.currency_hoards:
		hoarded_today=minf(GameState.private_currency,(target-GameState.currency_hoards)*0.08)
		GameState.private_currency-=hoarded_today
		GameState.currency_hoards+=hoarded_today
	elif target<GameState.currency_hoards:
		released_today=minf(GameState.currency_hoards,(GameState.currency_hoards-target)*0.045)
		GameState.currency_hoards-=released_today
		GameState.private_currency+=released_today
	if hoarded_today>=0.01: _ledger("currency_hoarded",hoarded_today,"private","hoards","Household precautionary balances")
	if released_today>=0.01: _ledger("currency_released",released_today,"hoards","private","Household balances return to exchange")
	result.confidence=confidence
	result.hoard_share=GameState.currency_hoards/maxf(1.0,GameState.currency_supply)
	result.desired_hoard_share=desired_share
	result.hoarded_today=hoarded_today
	result.released_today=released_today
	result.liquid_private=GameState.private_currency
	result.hoards=GameState.currency_hoards
	result.transactional_share=GameState.private_currency/maxf(1.0,GameState.currency_supply)
	result.nontransactional_share=(GameState.public_treasury+GameState.currency_hoards+GameState.mutual_aid_reserve)/maxf(1.0,GameState.currency_supply)
	return result

func _update_currency_demand(trade_volume:float,monetization:float)->void:
	if GameState.economy_stage!=STAGE_CURRENCY: return
	var target:=maxf(GameState.population_exact*0.42,trade_volume*28.0*monetization)
	if GameState.currency_demand<=0.0: GameState.currency_demand=target
	else: GameState.currency_demand=lerpf(GameState.currency_demand,target,0.025)

func _process_credit(trade_volume:float,market_access:float,reliability:float,events:Array[Dictionary])->Dictionary:
	if GameState.economy_stage==STAGE_SUBSISTENCE or DiscoverySystem.adoption("tallies")<0.25:
		return {"created":0.0,"repaid":0.0,"defaulted":0.0,"default_rate":0.0,"limit":0.0,"utilization":0.0}
	var opening:=GameState.credit_outstanding
	var shortage:=_shortage_pressure()
	var records:=DiscoverySystem.adoption("property_registers")
	var courts:=DiscoverySystem.adoption("specialized_courts")
	var secured_base:=GameState.population_exact*0.12+trade_volume*45.0+float(GameState.economy_metrics.get("exchangeable_surplus_value",0.0))*0.025
	var liquid_share:=clampf(GameState.private_currency/maxf(1.0,GameState.currency_supply),0.0,1.0) if GameState.economy_stage==STAGE_CURRENCY else 1.0
	var credit_limit:=maxf(1.0,secured_base*(0.28+reliability*0.52+records*0.18+courts*0.12)*(0.55+DiscoverySystem.adoption("tallies")*0.45)*(0.65+liquid_share*0.35))
	var desired_creation:=trade_volume*market_access*reliability*(1.0-shortage*0.65)*0.018*(0.55+liquid_share*0.45)
	var created:=minf(desired_creation,maxf(0.0,credit_limit-opening))
	var repaid:=minf(opening,opening*(0.0025+reliability*0.0045))
	var exposed:=maxf(0.0,opening+created-repaid)
	var default_rate:=clampf(0.0002+(1.0-reliability)*0.0015+shortage*0.0025,0.0,0.025)
	var defaulted:=minf(exposed,exposed*default_rate)
	GameState.credit_outstanding=maxf(0.0,exposed-defaulted)
	GameState.credit_defaulted+=defaulted
	if created>0.0: _ledger("credit_created",created,"creditors","debtors","Recorded trade credit")
	if repaid>0.0: _ledger("credit_repaid",repaid,"debtors","creditors","Obligation settled")
	if defaulted>0.0: _ledger("credit_default",defaulted,"debtors","creditors","Obligation written off")
	if default_rate>0.008 and defaulted>0.2:
		_threshold_event(events,"defaults","Obligations Fail","Shortage and weak trust caused %.1f units of recorded obligations to default." % defaulted,45)
	return {"created":created,"repaid":repaid,"defaulted":defaulted,"default_rate":default_rate,"limit":credit_limit,"utilization":GameState.credit_outstanding/maxf(1.0,credit_limit)}

func _process_mutual_risk_pool(trade_volume:float,defaulted_claims:float)->Dictionary:
	var adoption:=DiscoverySystem.adoption("risk_pools")
	var result:={"active":false,"contribution":0.0,"payout":0.0,"capacity":0.0,"reserve":GameState.mutual_aid_reserve}
	if GameState.economy_stage!=STAGE_CURRENCY or adoption<0.25: return result
	result.active=true
	var capacity:=maxf(GameState.population_exact*0.35,trade_volume*45.0)*(0.45+adoption*0.75)
	result.capacity=capacity
	var contribution_target:=trade_volume*0.004*adoption
	var contribution:=minf(GameState.private_currency,minf(contribution_target,maxf(0.0,capacity-GameState.mutual_aid_reserve)))
	GameState.private_currency-=contribution
	GameState.mutual_aid_reserve+=contribution
	var prior_coverage:=clampf(float(GameState.economy_metrics.get("essential_coverage",1.0)),0.0,1.0)
	var relief_need:=maxf(0.0,defaulted_claims)*0.65*adoption+maxf(0.0,0.72-prior_coverage)*GameState.population_exact*0.018*adoption
	var payout:=minf(GameState.mutual_aid_reserve,relief_need)
	GameState.mutual_aid_reserve-=payout
	GameState.private_currency+=payout
	if contribution>0.0: _ledger("risk_pool_contribution",contribution,"private","mutual_aid","Mutual loss contribution")
	if payout>0.0: _ledger("risk_pool_payout",payout,"mutual_aid","private","Default and subsistence relief")
	result.contribution=contribution
	result.payout=payout
	result.reserve=GameState.mutual_aid_reserve
	return result

func _update_wealth_distribution(monetization:float,inflation:float,default_rate:float,revenue:float,real_accounts:Dictionary={})->float:
	if GameState.wealth_shares.size()!=5: GameState.wealth_shares=[0.08,0.13,0.19,0.25,0.35]
	var shortage:=_shortage_pressure()
	var labor_return:=float(real_accounts.get("labor_return_index",1.0))
	var wage_pressure:=maxf(0.0,0.75-labor_return)*0.00010-maxf(0.0,labor_return-1.15)*0.000035
	var concentration_delta:=clampf(shortage*0.00020+maxf(0.0,inflation)*0.0015+default_rate*0.006+monetization*0.000025+wage_pressure-revenue/maxf(1.0,GameState.currency_supply)*0.0008,-0.0002,0.0008)
	GameState.wealth_shares[0]=maxf(0.01,GameState.wealth_shares[0]-concentration_delta*0.55)
	GameState.wealth_shares[1]=maxf(0.03,GameState.wealth_shares[1]-concentration_delta*0.30)
	GameState.wealth_shares[4]=minf(0.75,GameState.wealth_shares[4]+concentration_delta*0.85)
	var total:=0.0
	for share in GameState.wealth_shares: total+=float(share)
	for index in GameState.wealth_shares.size(): GameState.wealth_shares[index]=float(GameState.wealth_shares[index])/maxf(0.001,total)
	return _quintile_gini(GameState.wealth_shares)

func _quintile_gini(shares:Array[float])->float:
	var cumulative:=0.0
	var area:=0.0
	for share in shares:
		var next:=cumulative+float(share)
		area+=(cumulative+next)*0.5*0.2
		cumulative=next
	return clampf(1.0-2.0*area,0.0,1.0)

func household_welfare_snapshot(real_accounts:Dictionary={},monetization:float=-1.0,market_access:float=-1.0,private_liquidity:float=-1.0,statutory_tax_rate:float=-1.0)->Dictionary:
	# This is an observational distribution forecast, not five hidden inventories.
	# Physical systems still own delivery; quintile claim shares only estimate who
	# can reach the available basket through the exchange channels of this stage.
	var accounts:=real_accounts
	if accounts.is_empty():
		var observed_accounts:Variant=GameState.economy_metrics.get("real_economy",{})
		if observed_accounts is Dictionary: accounts=(observed_accounts as Dictionary)
	var observed_monetization:=monetization if monetization>=0.0 else float(GameState.economy_metrics.get("monetization",0.0))
	var observed_access:=market_access if market_access>=0.0 else float(GameState.economy_metrics.get("market_access",0.0))
	var liquid_private:=private_liquidity if private_liquidity>=0.0 else GameState.private_currency
	var tax_rate:=statutory_tax_rate if statutory_tax_rate>=0.0 else GameState.tax_rate
	var physical_coverage:=clampf(float(accounts.get("essential_coverage",0.0)),0.0,1.0)
	var basket_cost:=maxf(0.01,float(accounts.get("essential_basket_cost",maxf(1.0,GameState.population_exact))))
	var labor_income:=maxf(0.0,float(accounts.get("daily_labor_income",0.0)))
	var market_exposure:=0.08
	var concentration_weight:=0.10
	var liquidity_draw:=0.0
	match GameState.economy_stage:
		STAGE_SUBSISTENCE:
			market_exposure=clampf(0.05+observed_monetization*0.35+observed_access*0.03,0.05,0.13)
			concentration_weight=0.10
		STAGE_METAL:
			market_exposure=clampf(0.22+observed_monetization*0.50+observed_access*0.08,0.25,0.58)
			concentration_weight=0.36
		_:
			market_exposure=clampf(0.48+observed_monetization*0.38+observed_access*0.08,0.56,0.90)
			concentration_weight=0.58
			# A thirtieth of active balances may smooth a daily income interruption,
			# but precautionary hoards and public money remain unavailable here.
			liquidity_draw=minf(liquid_private/30.0,basket_cost*0.25)
	var compliance:=clampf(float(GameState.economy_metrics.get("tax_compliance",0.75)),0.18,0.98)
	var tax_drag:=tax_rate*compliance if GameState.economy_stage==STAGE_CURRENCY else 0.0
	var disposable_claim_capacity:=maxf(0.0,labor_income*(1.0-tax_drag)+liquidity_draw)
	var aggregate_affordability:=clampf(disposable_claim_capacity/maxf(0.01,basket_cost*market_exposure),0.0,1.25)
	var shares:Array[float]=GameState.wealth_shares.duplicate()
	if shares.size()!=5: shares=[0.08,0.13,0.19,0.25,0.35]
	var share_total:=0.0
	for share in shares: share_total+=maxf(0.0,float(share))
	var quintile_claim_shares:Array[float]=[]
	var quintile_affordability:Array[float]=[]
	var quintile_access:Array[float]=[]
	var hardship_share:=0.0
	var severe_hardship_share:=0.0
	var average_access:=0.0
	var average_affordability:=0.0
	for index in 5:
		var wealth_share:=maxf(0.0,float(shares[index]))/maxf(0.001,share_total)
		var claim_share:=0.20*(1.0-concentration_weight)+wealth_share*concentration_weight
		var relative_claims:=claim_share/0.20
		var affordability:=clampf(aggregate_affordability*relative_claims,0.0,1.0)
		var access_ratio:=physical_coverage*((1.0-market_exposure)+market_exposure*affordability)
		quintile_claim_shares.append(claim_share)
		quintile_affordability.append(affordability)
		quintile_access.append(access_ratio)
		average_affordability+=affordability*0.20
		average_access+=access_ratio*0.20
		hardship_share+=clampf((0.90-access_ratio)/0.45,0.0,1.0)*0.20
		severe_hardship_share+=clampf((0.60-access_ratio)/0.25,0.0,1.0)*0.20
	var lower_access:=(quintile_access[0]+quintile_access[1])*0.50
	var middle_access:=quintile_access[2]
	var upper_access:=(quintile_access[3]+quintile_access[4])*0.50
	var access_gap:=maxf(0.0,upper_access-lower_access)
	var claim_exclusion:=maxf(0.0,physical_coverage-average_access)
	var status:="secure"
	if physical_coverage<0.65 or hardship_share>=0.48: status="widespread hardship"
	elif lower_access<0.72: status="lower households excluded"
	elif lower_access<0.88 or access_gap>0.12: status="uneven access"
	elif physical_coverage<0.92: status="fragile"
	return {"stage":GameState.economy_stage,"status":status,"physical_coverage":physical_coverage,"market_exposure":market_exposure,"direct_provisioning_share":1.0-market_exposure,"basket_cost":basket_cost,"disposable_claim_capacity":disposable_claim_capacity,"liquidity_draw_per_day":liquidity_draw,"aggregate_affordability":aggregate_affordability,"affordability_index":average_affordability,"quintile_claim_shares":quintile_claim_shares,"quintile_affordability":quintile_affordability,"quintile_access":quintile_access,"lower_access":lower_access,"middle_access":middle_access,"upper_access":upper_access,"average_access":average_access,"access_gap":access_gap,"claim_exclusion":claim_exclusion,"hardship_share":clampf(hardship_share,0.0,1.0),"severe_hardship_share":clampf(severe_hardship_share,0.0,1.0),"tax_drag":tax_drag}

func _exchange_mix(monetization:float,reliability:float)->Dictionary:
	var mix:Dictionary
	var metal_liquidity:=clampf(GameState.weighed_metal_circulation/maxf(0.01,founding_weighed_metal_requirement()),0.0,1.0)
	match GameState.economy_stage:
		STAGE_SUBSISTENCE:
			mix={"public_allocation":0.40,"reciprocity":0.34,"barter":0.26,"weighed_metal":0.0,"recorded_credit":0.0,"currency":0.0}
		STAGE_METAL:
			var credit_share:=clampf(GameState.credit_outstanding/maxf(1.0,GameState.credit_outstanding+GameState.population_exact)*0.35,0.02,0.12)
			var potential_metal:=maxf(0.0,monetization-credit_share)
			var metal_share:=potential_metal*metal_liquidity
			mix={"public_allocation":0.25,"reciprocity":0.20,"barter":maxf(0.08,0.55-monetization)+(potential_metal-metal_share),"weighed_metal":metal_share,"recorded_credit":credit_share,"currency":0.0}
		_:
			var crisis_reversion:=clampf((0.55-reliability)*0.50+_shortage_pressure()*0.22,0.0,0.30)
			var credit_share:=clampf(GameState.credit_outstanding/maxf(1.0,GameState.credit_outstanding+GameState.currency_supply)*0.55,0.03,0.18)
			var currency_share:=maxf(0.04,monetization-credit_share)
			var potential_metal:=0.08+crisis_reversion*0.05
			var metal_share:=potential_metal*metal_liquidity
			mix={"public_allocation":0.14+crisis_reversion*0.45,"reciprocity":0.11+crisis_reversion*0.30,"barter":0.10+crisis_reversion*0.20+(potential_metal-metal_share),"weighed_metal":metal_share,"recorded_credit":credit_share,"currency":currency_share}
	var total:=0.0
	for share in mix.values(): total+=float(share)
	for channel in mix: mix[channel]=float(mix[channel])/maxf(0.001,total)
	return mix

func _economic_social_pressure(inflation:float,default_rate:float,inequality:float,market_access:float,reliability:float,real_accounts:Dictionary={},finance:Dictionary={},mutual_aid:Dictionary={},currency_liquidity:Dictionary={},household_welfare:Dictionary={})->float:
	var arrears_pressure:=clampf((GameState.civil_arrears+GameState.military_arrears)/maxf(1.0,GameState.population_exact)*0.08,0.0,0.08)
	var real_pressure:=float(real_accounts.get("obligation_pressure",0.0))*0.08
	var debt_capacity:=float(finance.get("debt_capacity",0.0))
	var debt_pressure:=maxf(0.0,GameState.public_debt/maxf(1.0,debt_capacity)-0.55)*0.04 if debt_capacity>0.0 else 0.0
	var labor_return_pressure:=maxf(0.0,0.70-float(real_accounts.get("labor_return_index",1.0)))*0.035
	var hoarding_pressure:=maxf(0.0,float(currency_liquidity.get("hoard_share",0.0))-0.12)*0.08
	var distribution_pressure:=float(household_welfare.get("claim_exclusion",0.0))*0.06+float(household_welfare.get("access_gap",0.0))*0.025
	var hardship:=_shortage_pressure()*0.10+real_pressure+debt_pressure+labor_return_pressure+hoarding_pressure+distribution_pressure+maxf(0.0,inflation)*0.20+default_rate*0.8+maxf(0.0,inequality-0.32)*0.12+maxf(0.0,GameState.tax_rate-0.12)*0.10+arrears_pressure
	var risk_pool_relief:=float(mutual_aid.get("payout",0.0))/maxf(1.0,GameState.population_exact)*0.06
	var coordination_benefit:=market_access*reliability*0.025+clampf(risk_pool_relief,0.0,0.02)
	return clampf(coordination_benefit-hardship,-0.20,0.025)

func set_tax_rate(rate:float)->float:
	GameState.tax_rate=clampf(rate,0.0,0.25)
	_ledger("policy",GameState.tax_rate,"sovereign","economy","Exchange levy rate")
	return GameState.tax_rate

func preview_policy(action:String,amount:float=0.0)->Dictionary:
	# This forecast is deliberately pure: UI and advisors can inspect hard limits
	# without initializing systems, moving an account, or adding a ledger entry.
	var normalized:=action.strip_edges().to_upper()
	var reserve:=_monetary_reserve_value()
	var available:=_available_metal_value()
	var circulation:=GameState.weighed_metal_circulation
	var supply:=GameState.currency_supply
	var treasury:=GameState.public_treasury
	var tax_rate:=GameState.tax_rate
	var trade_policy:=GameState.external_trade_policy
	var spending_priority:=GameState.public_spending_priority
	var observed_trade:=float(GameState.economy_metrics.get("trade_volume",0.0))
	var observed_monetization:=float(GameState.economy_metrics.get("monetization",0.0))
	var burden:Dictionary={}
	var burden_variant:Variant=GameState.economy_metrics.get("military_burden",{})
	if burden_variant is Dictionary: burden=(burden_variant as Dictionary).duplicate(true)
	if burden.is_empty(): burden=_military_burden_snapshot()
	var before_fiscal:=_fiscal_outlook_for(30.0,observed_trade,observed_monetization,burden,GameState.public_treasury,GameState.private_currency,GameState.tax_rate)
	var requested:=absf(amount)
	var accepted:=0.0
	var reason:=""
	var warning:=""
	match normalized:
		"LEVY −","LEVY -","LEVY +":
			var target:=clampf(tax_rate+amount,0.0,0.25)
			accepted=absf(target-tax_rate)
			tax_rate=target
			reason="Exchange levy changes to %.0f%%." % (tax_rate*100.0)
			warning="Collection still depends on administration, monetized trade, and liquid household balances."
		"BACK METAL":
			accepted=minf(requested,available) if DiscoverySystem.adoption("copper_smelting")>=0.18 else 0.0
			available-=accepted
			reserve+=accepted
			reason="%.1f metal value can move from ordinary stores into backing." % accepted
			warning="Committed metal cannot also supply tools, buildings, arms, or weighed trade."
		"RELEASE METAL":
			var required:=supply/2.5 if GameState.economy_stage==STAGE_CURRENCY else 0.0
			accepted=minf(requested,maxf(0.0,reserve-required))
			available+=_preview_returned_available_value(GameState.monetary_reserve_metals,accepted)
			reserve-=accepted
			reason="%.1f surplus reserve value can safely return to stores." % accepted
			warning="The remaining reserve must continue to support every issued unit at the 2.5× ceiling."
		"METAL TO TRADE":
			accepted=minf(requested,available) if DiscoverySystem.adoption("copper_smelting")>=0.18 else 0.0
			available-=accepted
			circulation+=accepted
			reason="%.1f processed metal value can enter weighed exchange." % accepted
			warning="Circulating metal is unavailable to workshops and reserve backing until withdrawn."
		"WITHDRAW TRADE METAL":
			accepted=minf(requested,circulation)
			available+=_preview_returned_available_value(GameState.weighed_metal_composition,accepted)
			circulation-=accepted
			reason="%.1f weighed-metal value can return to ordinary stores." % accepted
			warning="A thinner metal stock reduces the intermediate exchange channel and shifts settlement back toward barter."
		"ISSUE":
			if GameState.economy_stage==STAGE_CURRENCY:
				accepted=minf(requested,maxf(0.0,reserve*2.5-supply))
			supply+=accepted
			treasury+=accepted
			reason="%.1f new reserve-backed units can enter the public treasury." % accepted
			warning="Issued units remain inactive in the treasury until spent; disbursement can raise prices when goods and money demand do not grow with it."
		"RETIRE":
			if GameState.economy_stage==STAGE_CURRENCY: accepted=minf(requested,minf(treasury,supply))
			supply-=accepted
			treasury-=accepted
			reason="%.1f treasury-held units can be retired." % accepted
			warning="Retirement reduces public liquidity; it does not return backing to stores until surplus reserve is released."
		"SPENDING","SPENDING PRIORITY":
			var priority_index:=PUBLIC_SPENDING_PRIORITIES.find(spending_priority)
			spending_priority=String(PUBLIC_SPENDING_PRIORITIES[(priority_index+1)%PUBLIC_SPENDING_PRIORITIES.size()])
			accepted=1.0
			reason="Public payment priority changes to %s." % spending_priority.replace("_"," ")
			warning="Priority changes who is paid first when funds are short; it does not reduce total obligations, create currency, or erase displaced arrears."
		"TRADE":
			var policies:= ["balanced","relief_imports","export_surplus","closed"]
			var index:=policies.find(trade_policy)
			trade_policy=String(policies[(index+1)%policies.size()])
			accepted=1.0
			reason="Regional trade stance changes to %s." % trade_policy.replace("_"," ")
			warning="Imports remain limited by accumulated external claims; exports still protect domestic buffers."
		_:
			reason="Unknown economy policy."
	var after_fiscal:=_fiscal_outlook_for(30.0,observed_trade,observed_monetization,burden,maxf(0.0,treasury),GameState.private_currency,tax_rate,spending_priority)
	if normalized in ["LEVY −","LEVY -","LEVY +"]:
		reason+=" At current conditions, compliance is %d%% and the effective levy is %.1f%%, yielding about %.2f per day." % [roundi(float(after_fiscal.tax_compliance)*100.0),float(after_fiscal.effective_tax_rate)*100.0,float(after_fiscal.daily_revenue)]
	if bool(after_fiscal.active) and String(after_fiscal.status)!="sound":
		warning+=" Fiscal outlook is %s: %s" % [String(after_fiscal.status),String(after_fiscal.warning)]
	return {"action":normalized,"requested":requested,"accepted":accepted,"reason":reason,"warning":warning,"before":{"available_metal":_available_metal_value(),"circulating_metal":GameState.weighed_metal_circulation,"reserve":_monetary_reserve_value(),"issue_ceiling":_monetary_reserve_value()*2.5,"money_supply":GameState.currency_supply,"transactional_money":GameState.private_currency,"transactional_share":GameState.private_currency/maxf(1.0,GameState.currency_supply),"treasury":GameState.public_treasury,"tax_rate":GameState.tax_rate,"trade_policy":GameState.external_trade_policy,"spending_priority":GameState.public_spending_priority,"fiscal_outlook":before_fiscal},"after":{"available_metal":maxf(0.0,available),"circulating_metal":maxf(0.0,circulation),"reserve":maxf(0.0,reserve),"issue_ceiling":maxf(0.0,reserve*2.5),"money_supply":maxf(0.0,supply),"transactional_money":GameState.private_currency,"transactional_share":GameState.private_currency/maxf(1.0,supply),"treasury":maxf(0.0,treasury),"tax_rate":tax_rate,"trade_policy":trade_policy,"spending_priority":spending_priority,"fiscal_outlook":after_fiscal}}

func _preview_returned_available_value(composition:Dictionary,requested_value:float)->float:
	var remaining:=maxf(0.0,requested_value)
	var available_gain:=0.0
	var efficiency:=_metal_processing_efficiency()
	var names:Array[String]=[]
	for resource_name_variant in composition: names.append(String(resource_name_variant))
	names.sort()
	for resource_name in names:
		if remaining<=0.0001: break
		var released_value:=minf(remaining,maxf(0.0,float(composition.get(resource_name,0.0))))
		available_gain+=released_value*(1.0 if resource_name=="Coin" or not METAL_VALUES.has(resource_name) else efficiency)
		remaining-=released_value
	return available_gain

func issue_currency(requested:float,reason:String="Public issue")->Dictionary:
	initialize()
	if GameState.economy_stage!=STAGE_CURRENCY: return {"accepted":0.0,"reason":"Currency has not emerged"}
	var accepted:=_issue_currency_internal(requested,reason,1.0)
	return {"accepted":accepted,"requested":requested,"money_supply":GameState.currency_supply,"treasury":GameState.public_treasury,"reserve_ratio":_monetary_reserve_value()/maxf(1.0,GameState.currency_supply)}

func transfer_currency(requested:float,source:String,destination:String,reason:String="Currency transfer")->Dictionary:
	initialize()
	if GameState.economy_stage!=STAGE_CURRENCY: return {"accepted":0.0,"requested":requested,"reason":"Currency has not emerged"}
	var from_account:=_normalized_currency_account(source)
	var to_account:=_normalized_currency_account(destination)
	if from_account=="" or to_account=="": return {"accepted":0.0,"requested":requested,"reason":"Unknown currency account"}
	if from_account==to_account: return {"accepted":0.0,"requested":requested,"reason":"Source and destination are the same account"}
	var accepted:=minf(maxf(0.0,requested),_currency_account_balance(from_account))
	_set_currency_account(from_account,_currency_account_balance(from_account)-accepted)
	_set_currency_account(to_account,_currency_account_balance(to_account)+accepted)
	if accepted>0.0: _ledger("currency_transfer",accepted,from_account,to_account,reason)
	return {"accepted":accepted,"requested":requested,"source":from_account,"destination":to_account,"money_supply":GameState.currency_supply,"source_balance":_currency_account_balance(from_account),"destination_balance":_currency_account_balance(to_account)}

func _normalized_currency_account(account:String)->String:
	var normalized:=account.strip_edges().to_lower().replace("-","_").replace(" ","_")
	if normalized in ["public","treasury","state","state_treasury","sovereign"]: return "public"
	if normalized in ["private","households","household","troops","circulation"]: return "private"
	if normalized in ["hoard","hoards","household_hoards","savings","precautionary_balances"]: return "hoards"
	if normalized in ["mutual_aid","risk_pool","mutual","insurance"]: return "mutual_aid"
	return ""

func _currency_account_balance(account:String)->float:
	match account:
		"public": return GameState.public_treasury
		"private": return GameState.private_currency
		"hoards": return GameState.currency_hoards
		"mutual_aid": return GameState.mutual_aid_reserve
	return 0.0

func _set_currency_account(account:String,value:float)->void:
	match account:
		"public": GameState.public_treasury=maxf(0.0,value)
		"private": GameState.private_currency=maxf(0.0,value)
		"hoards": GameState.currency_hoards=maxf(0.0,value)
		"mutual_aid": GameState.mutual_aid_reserve=maxf(0.0,value)

func commit_metal_to_reserve(requested_value:float,reason:String="Monetary reserve commitment")->Dictionary:
	initialize()
	if DiscoverySystem.adoption("copper_smelting")<0.18: return {"accepted":0.0,"requested":requested_value,"reason":"Usable metal cannot yet be produced reliably"}
	var transfer:=_take_physical_metal_from_stores(requested_value)
	var committed:=float(transfer.accepted)
	var processed_values:Dictionary=transfer.processed_values
	for resource_name_variant in processed_values:
		var resource_name:=String(resource_name_variant)
		GameState.monetary_reserve_metals[resource_name]=float(GameState.monetary_reserve_metals.get(resource_name,0.0))+float(processed_values[resource_name])
	if committed>0.0: _ledger("metal_committed",committed,"material_stores","monetary_reserve",reason)
	return {"accepted":committed,"requested":requested_value,"consumed":transfer.consumed,"reserve_value":_monetary_reserve_value(),"available_metal":_available_metal_value(),"processing_efficiency":transfer.processing_efficiency}

func place_weighed_metal_in_circulation(requested_value:float,reason:String="Metal placed in exchange")->Dictionary:
	initialize()
	if DiscoverySystem.adoption("copper_smelting")<0.18: return {"accepted":0.0,"requested":requested_value,"reason":"Usable metal cannot yet be produced reliably"}
	var transfer:=_take_physical_metal_from_stores(requested_value)
	var accepted:=float(transfer.accepted)
	var processed_values:Dictionary=transfer.processed_values
	for resource_name_variant in processed_values:
		var resource_name:=String(resource_name_variant)
		GameState.weighed_metal_composition[resource_name]=float(GameState.weighed_metal_composition.get(resource_name,0.0))+float(processed_values[resource_name])
	GameState.weighed_metal_circulation=_weighed_metal_value()
	if accepted>0.0: _ledger("weighed_metal_placed",accepted,"material_stores","metal_circulation",reason)
	return {"accepted":accepted,"requested":requested_value,"consumed":transfer.consumed,"circulation":GameState.weighed_metal_circulation,"composition":GameState.weighed_metal_composition.duplicate(true),"available_metal":_available_metal_value(),"processing_efficiency":transfer.processing_efficiency}

func withdraw_weighed_metal(requested_value:float,reason:String="Metal withdrawn from exchange")->Dictionary:
	initialize()
	var accepted:=minf(maxf(0.0,requested_value),_weighed_metal_value())
	var remaining:=accepted
	var returned:Dictionary={}
	var names:Array[String]=[]
	for resource_name_variant in GameState.weighed_metal_composition: names.append(String(resource_name_variant))
	names.sort()
	for resource_name in names:
		if remaining<=0.0001: break
		var held_value:=maxf(0.0,float(GameState.weighed_metal_composition.get(resource_name,0.0)))
		var withdrawn_value:=minf(held_value,remaining)
		if withdrawn_value<=0.0: continue
		GameState.weighed_metal_composition[resource_name]=held_value-withdrawn_value
		if float(GameState.weighed_metal_composition[resource_name])<=0.0001: GameState.weighed_metal_composition.erase(resource_name)
		var store_resource:=resource_name if METAL_VALUES.has(resource_name) else "Coin"
		var store_quantity:=withdrawn_value/maxf(0.001,float(METAL_VALUES.get(store_resource,1.0)))
		GameState.resource_stockpiles[store_resource]=float(GameState.resource_stockpiles.get(store_resource,0.0))+store_quantity
		returned[store_resource]=float(returned.get(store_resource,0.0))+store_quantity
		remaining-=withdrawn_value
	var withdrawn:=accepted-maxf(0.0,remaining)
	GameState.weighed_metal_circulation=_weighed_metal_value()
	if withdrawn>0.0: _ledger("weighed_metal_withdrawn",withdrawn,"metal_circulation","material_stores",reason)
	return {"accepted":withdrawn,"requested":requested_value,"returned":returned,"circulation":GameState.weighed_metal_circulation,"composition":GameState.weighed_metal_composition.duplicate(true),"available_metal":_available_metal_value()}

func _take_physical_metal_from_stores(requested_value:float)->Dictionary:
	var remaining:=maxf(0.0,requested_value)
	var accepted:=0.0
	var consumed:Dictionary={}
	var processed_values:Dictionary={}
	var efficiency:=_metal_processing_efficiency()
	for resource_name in ["Coin","Copper Ore","Tin Ore","Iron Ore"]:
		if remaining<=0.0001: break
		var stock:=maxf(0.0,float(GameState.resource_stockpiles.get(resource_name,0.0)))
		var value_per_raw:=float(METAL_VALUES[resource_name])*(1.0 if resource_name=="Coin" else efficiency)
		var raw_needed:=remaining/maxf(0.001,value_per_raw)
		var raw_used:=minf(stock,raw_needed)
		var processed_value:=raw_used*value_per_raw
		if raw_used<=0.0: continue
		GameState.resource_stockpiles[resource_name]=stock-raw_used
		consumed[resource_name]=raw_used
		processed_values[resource_name]=processed_value
		accepted+=processed_value
		remaining-=processed_value
	return {"accepted":accepted,"requested":requested_value,"consumed":consumed,"processed_values":processed_values,"processing_efficiency":efficiency}

func release_surplus_reserve(requested_value:float,reason:String="Surplus reserve release")->Dictionary:
	initialize()
	var reserve_before:=_monetary_reserve_value()
	var required_reserve:=GameState.currency_supply/2.5 if GameState.economy_stage==STAGE_CURRENCY else 0.0
	var releasable:=maxf(0.0,reserve_before-required_reserve)
	var accepted:=minf(maxf(0.0,requested_value),releasable)
	var remaining:=accepted
	var returned:Dictionary={}
	var reserve_names:Array[String]=[]
	for reserve_name_variant in GameState.monetary_reserve_metals:
		reserve_names.append(String(reserve_name_variant))
	reserve_names.sort()
	for reserve_name in reserve_names:
		if remaining<=0.0001: break
		var held_value:=maxf(0.0,float(GameState.monetary_reserve_metals.get(reserve_name,0.0)))
		var released_value:=minf(held_value,remaining)
		if released_value<=0.0: continue
		GameState.monetary_reserve_metals[reserve_name]=held_value-released_value
		if float(GameState.monetary_reserve_metals[reserve_name])<=0.0001: GameState.monetary_reserve_metals.erase(reserve_name)
		var store_resource:=reserve_name if METAL_VALUES.has(reserve_name) else "Coin"
		var store_quantity:=released_value/maxf(0.001,float(METAL_VALUES.get(store_resource,1.0)))
		GameState.resource_stockpiles[store_resource]=float(GameState.resource_stockpiles.get(store_resource,0.0))+store_quantity
		returned[store_resource]=float(returned.get(store_resource,0.0))+store_quantity
		remaining-=released_value
	var released:=accepted-maxf(0.0,remaining)
	if released>0.0: _ledger("metal_released",released,"monetary_reserve","material_stores",reason)
	return {"accepted":released,"requested":requested_value,"releasable_before":releasable,"required_reserve":required_reserve,"reserve_value":_monetary_reserve_value(),"returned":returned,"money_supply":GameState.currency_supply}

func receive_war_wealth(amount:float,destination:String="public",reason:String="War wealth received")->Dictionary:
	initialize()
	var accepted:=maxf(0.0,amount)
	var normalized:=destination.strip_edges().to_lower()
	var to_public:=normalized in ["public","treasury","state","state treasury","sovereign"]
	if accepted<=0.0:
		return {"accepted":0.0,"destination":"public" if to_public else "private","medium":"none"}
	if GameState.economy_stage!=STAGE_CURRENCY:
		GameState.resource_stockpiles["Coin"]=float(GameState.resource_stockpiles.get("Coin",0.0))+accepted
		_ledger("war_wealth_received",accepted,"external","material_stores",reason)
		return {"accepted":accepted,"destination":"collective stores","medium":"physical coin and bullion","material_deposited":accepted,"currency_deposited":0.0}
	GameState.monetary_reserve_metals["War Bullion"]=float(GameState.monetary_reserve_metals.get("War Bullion",0.0))+accepted
	var deposited:=_issue_currency_internal(accepted,reason,1.0 if to_public else 0.0)
	_ledger("war_wealth_received",accepted,"external","public" if to_public else "private",reason)
	return {"accepted":accepted,"destination":"public" if to_public else "private","medium":"reserve-backed currency","material_deposited":0.0,"currency_deposited":deposited,"reserve_value":_monetary_reserve_value(),"money_supply":GameState.currency_supply}

func retire_currency(requested:float,reason:String="Currency retirement")->Dictionary:
	initialize()
	if GameState.economy_stage!=STAGE_CURRENCY: return {"accepted":0.0,"reason":"Currency has not emerged"}
	var accepted:=minf(maxf(0.0,requested),minf(GameState.public_treasury,GameState.currency_supply))
	GameState.public_treasury-=accepted
	GameState.currency_supply-=accepted
	GameState.currency_retired+=accepted
	if accepted>0.0: _ledger("currency_retired",accepted,"public","retired",reason)
	return {"accepted":accepted,"requested":requested,"money_supply":GameState.currency_supply,"treasury":GameState.public_treasury}

func _issue_currency_internal(requested:float,reason:String,public_share:float)->float:
	var maximum:=maxf(0.0,_monetary_reserve_value()*2.5)
	var accepted:=minf(maxf(0.0,requested),maxf(0.0,maximum-GameState.currency_supply))
	var public_amount:=accepted*clampf(public_share,0.0,1.0)
	GameState.currency_supply+=accepted
	GameState.currency_issued+=accepted
	GameState.public_treasury+=public_amount
	GameState.private_currency+=accepted-public_amount
	if accepted>0.0: _ledger("currency_issued",accepted,"mint","circulation",reason)
	return accepted

func _validate_currency_conservation()->void:
	var accounted:=GameState.private_currency+GameState.currency_hoards+GameState.public_treasury+GameState.mutual_aid_reserve
	var difference:=GameState.currency_supply-accounted
	if absf(difference)<=0.0001: return
	if difference>0.0:
		GameState.private_currency+=difference
	else:
		var excess:=-difference
		var private_reduction:=minf(excess,GameState.private_currency)
		GameState.private_currency-=private_reduction
		excess-=private_reduction
		if excess>0.0:
			var treasury_reduction:=minf(excess,GameState.public_treasury)
			GameState.public_treasury-=treasury_reduction
			excess-=treasury_reduction
		if excess>0.0:
			var aid_reduction:=minf(excess,GameState.mutual_aid_reserve)
			GameState.mutual_aid_reserve-=aid_reduction
			excess-=aid_reduction
		if excess>0.0: GameState.currency_hoards=maxf(0.0,GameState.currency_hoards-excess)
	_ledger("reconciliation",difference,"accounts","circulation","Corrected legacy or rounding difference")

func accounting_audit()->Dictionary:
	var violations:Array[String]=[]
	var currency_accounts:=GameState.private_currency+GameState.currency_hoards+GameState.public_treasury+GameState.mutual_aid_reserve
	var currency_difference:=GameState.currency_supply-currency_accounts
	if absf(currency_difference)>0.001: violations.append("currency supply differs from circulation accounts")
	var reserve_value:=_monetary_reserve_value()
	var currency_ceiling:=reserve_value*2.5
	if GameState.economy_stage==STAGE_CURRENCY and GameState.currency_supply>currency_ceiling+0.001: violations.append("currency supply exceeds committed reserve ceiling")
	var expected_trade_claims:=GameState.external_trade_exports-GameState.external_trade_imports-GameState.external_trade_losses
	var trade_difference:=GameState.external_trade_credit-expected_trade_claims
	if absf(trade_difference)>0.001: violations.append("regional trade claims do not reconcile")
	if GameState.external_trade_credit< -0.001: violations.append("regional trade claims are negative")
	if GameState.public_debt< -0.001: violations.append("public debt is negative")
	if GameState.mutual_aid_reserve< -0.001: violations.append("mutual-aid reserve is negative")
	if GameState.currency_hoards< -0.001: violations.append("currency hoards are negative")
	if GameState.in_kind_labor_arrears< -0.001: violations.append("in-kind labor arrears are negative")
	if GameState.in_kind_material_arrears< -0.001: violations.append("in-kind material arrears are negative")
	var weighed_metal_composed:=_weighed_metal_value()
	var weighed_metal_difference:=GameState.weighed_metal_circulation-weighed_metal_composed
	if absf(weighed_metal_difference)>0.001: violations.append("weighed-metal circulation differs from its physical composition")
	if GameState.weighed_metal_circulation< -0.001: violations.append("weighed-metal circulation is negative")
	if GameState.weighed_metal_losses< -0.001: violations.append("weighed-metal losses are negative")
	for resource_name_variant in GameState.resource_stockpiles:
		var resource_name:=String(resource_name_variant)
		if float(GameState.resource_stockpiles[resource_name])< -0.001: violations.append("negative material store: "+resource_name)
	for reserve_name_variant in GameState.monetary_reserve_metals:
		var reserve_name:=String(reserve_name_variant)
		if float(GameState.monetary_reserve_metals[reserve_name])< -0.001: violations.append("negative monetary reserve: "+reserve_name)
	return {"ok":violations.is_empty(),"violations":violations,"currency_difference":currency_difference,"currency_ceiling":currency_ceiling,"reserve_value":reserve_value,"trade_difference":trade_difference,"expected_trade_claims":expected_trade_claims,"currency_hoards":GameState.currency_hoards,"weighed_metal_difference":weighed_metal_difference,"weighed_metal_circulation":GameState.weighed_metal_circulation,"weighed_metal_losses":GameState.weighed_metal_losses,"public_debt":GameState.public_debt,"mutual_aid_reserve":GameState.mutual_aid_reserve,"in_kind_labor_arrears":GameState.in_kind_labor_arrears,"in_kind_material_arrears":GameState.in_kind_material_arrears}

func _ledger(kind:String,amount:float,source:String,destination:String,memo:String)->void:
	GameState.economic_ledger.append({"day":int(GameState.elapsed_days),"kind":kind,"amount":amount,"source":source,"destination":destination,"memo":memo})
	if GameState.economic_ledger.size()>1000: GameState.economic_ledger.pop_front()

func quote(resource_name:String,quantity:float=1.0)->Dictionary:
	initialize()
	var observed:=GameState.market_prices.has(resource_name) and int(GameState.economy_metrics.get("price_observations",0))>0
	var unit:=float(GameState.market_prices.get(resource_name,0.0)) if observed else 0.0
	return {"resource":resource_name,"quantity":maxf(0.0,quantity),"unit_value":unit,"total_value":unit*maxf(0.0,quantity),"observed":observed,"stage":GameState.economy_stage,"settlement_medium":settlement_medium()}

func settlement_medium()->String:
	match GameState.economy_stage:
		STAGE_METAL: return "resources, labor obligations, or weighed metal"
		STAGE_CURRENCY: return "currency, weighed metal, resources, or recorded credit"
		_: return "direct allocation of physical resources, shared reserves, labor, and reciprocal obligations"

func known_market_snapshot()->Array[Dictionary]:
	initialize()
	var result:Array[Dictionary]=[]
	if int(GameState.economy_metrics.get("price_observations",0))<=0:
		return result
	for resource_name_variant in BASE_VALUES:
		var resource_name:=String(resource_name_variant)
		var stock:=float(GameState.resource_stockpiles.get(resource_name,0.0))
		if not _resource_is_economically_known(resource_name,stock): continue
		var trend:=market_trend(resource_name,30)
		result.append({"resource":resource_name,"stock":stock,"unit_value":float(GameState.market_prices.get(resource_name,BASE_VALUES[resource_name])),"base_value":float(BASE_VALUES[resource_name]),"trend_30d":trend.change,"high_30d":trend.high,"low_30d":trend.low})
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return String(a.resource)<String(b.resource))
	return result

func market_trend(resource_name:String,lookback_days:int=30)->Dictionary:
	initialize()
	if not GameState.market_prices.has(resource_name):
		return {"resource":resource_name,"days":lookback_days,"first":0.0,"current":0.0,"change":0.0,"high":0.0,"low":0.0,"observed":false}
	var current:=float(GameState.market_prices.get(resource_name,0.0))
	var first:=current
	var high:=current
	var low:=current
	var found:=false
	var start:=maxi(0,GameState.economy_history.size()-maxi(1,lookback_days))
	for index in range(start,GameState.economy_history.size()):
		var prices:Dictionary=GameState.economy_history[index].get("prices",{})
		if not prices.has(resource_name): continue
		var value:=maxf(0.001,float(prices[resource_name]))
		if not found: first=value; found=true
		high=maxf(high,value)
		low=minf(low,value)
	return {"resource":resource_name,"days":lookback_days,"first":first,"current":current,"change":current/maxf(0.001,first)-1.0,"high":high,"low":low}

func benchmark_status()->Dictionary:
	var production:=float(GameState.society_capacities.get("production",0.0))
	var institutions:=float(GameState.society_capacities.get("institutions",0.0))
	var logistics:=float(GameState.society_capacities.get("logistics",0.0))
	var food_days:=float(GameState.simulation_metrics.get("food_days",0.0))
	var measures:=DiscoverySystem.adoption("standard_measures")
	var tallies:=DiscoverySystem.adoption("tallies")
	var smelting:=DiscoverySystem.adoption("copper_smelting")
	var reserve:=_available_metal_value()
	if GameState.economy_stage==STAGE_SUBSISTENCE:
		return {"next_stage":STAGE_NAMES[STAGE_METAL],"requirements":[
			{"name":"Shared measures adoption","value":measures,"target":0.32},
			{"name":"Tallies adoption","value":tallies,"target":0.25},
			{"name":"Copper smelting practice","value":smelting,"target":0.18},
			{"name":"Production capacity","value":production,"target":0.24},
			{"name":"Usable metal surplus","value":reserve,"target":metal_stage_requirement()}
		]}
	if GameState.economy_stage==STAGE_METAL:
		return {"next_stage":STAGE_NAMES[STAGE_CURRENCY],"requirements":[
			{"name":"Shared measures adoption","value":measures,"target":0.62},
			{"name":"Tallies adoption","value":tallies,"target":0.58},
			{"name":"Institutional capacity","value":institutions,"target":0.38},
			{"name":"Logistics capacity","value":logistics,"target":0.32},
			{"name":"Stored food","value":food_days,"target":21.0},
			{"name":"Usable uncommitted metal","value":reserve,"target":currency_metal_requirement()}
		]}
	return {"next_stage":"Mature currency institutions","requirements":[
		{"name":"Exchange reliability","value":float(GameState.economy_metrics.get("exchange_reliability",0.0)),"target":0.75},
		{"name":"Reserve ratio","value":_monetary_reserve_value()/maxf(1.0,GameState.currency_supply),"target":0.50},
		{"name":"Market access","value":float(GameState.economy_metrics.get("market_access",0.0)),"target":0.70},
		{"name":"Public credit practice","value":DiscoverySystem.adoption("public_credit"),"target":0.50}
	]}

func _threshold_event(events:Array[Dictionary],id:String,title:String,description:String,cooldown:int)->void:
	var key:="economy_"+id
	if int(GameState.last_simulation_event_days.get(key,-100000))+cooldown>int(GameState.elapsed_days): return
	GameState.last_simulation_event_days[key]=int(GameState.elapsed_days)
	var event:=_event(title,description,"warning")
	event["condition_id"]=key
	event["recurring_condition"]=true
	events.append(event)

func _event(title:String,description:String,severity:String)->Dictionary:
	return {"day":int(GameState.elapsed_days),"title":title,"description":description,"domain":"economy","severity":severity}
