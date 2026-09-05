extends Node

var failures:Array[String]=[]

func _ready()->void:
	_reset()
	_test_resource_stage()
	_test_resource_stage_war_wealth()
	_test_metal_benchmark()
	_test_weighed_metal_circulation()
	_test_currency_benchmark()
	_test_currency_stage_war_wealth()
	_test_conserved_public_finance_and_currency_policy()
	_test_surplus_reserve_release()
	_test_conserved_currency_transfer_api()
	_test_currency_hoarding_and_recovery()
	_test_policy_previews_are_pure()
	_test_fiscal_outlook_contract()
	_test_public_spending_priorities()
	_test_tax_capacity_constraints()
	_test_transactional_liquidity_accounts()
	_test_value_conserved_external_trade()
	_test_food_imports_use_authoritative_food_store()
	_test_military_burden_contract()
	_test_unpaid_obligations_persist_as_arrears()
	_test_public_credit_transfers_existing_currency()
	_test_mutual_risk_pool_conserves_currency()
	_test_scarcity_prices()
	_test_credit_and_unknown_goods()
	if not failures.is_empty():
		for failure in failures: push_error("Economy regression: "+failure)
		get_tree().quit(1)
		return
	print("ECONOMY_PROBE_PASS ",JSON.stringify(GameState.economy_metrics))
	get_tree().quit(0)

func _reset()->void:
	GameState.reset_for_new_world(44017)
	EconomySystem.reset_for_new_world()
	GameState.population_exact=120.0
	GameState.population_total=120
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.water_metrics={"intake_ratio":1.0,"source_accessible":true,"days":3.0}
	GameState.resource_stockpiles={"Food":3600.0,"Timber":180.0,"Stone":140.0,"Fiber Plants":55.0,"Copper Ore":0.0,"Tin Ore":0.0,"Iron Ore":0.0}
	GameState.simulation_metrics={"food_days":30.0,"food_intake_ratio":1.0,"food_consumption":120.0,"logistics":0.42,"legitimacy":0.70,"food_production":132.0,"storage_function":0.5}
	GameState.society_capacities={"production":0.40,"institutions":0.45,"logistics":0.42}
	GameState.population_allocations["Administration"]=6
	GameState.material_metrics={"delivered_today":12.0,"lost_today":0.0}
	GameState.discovery_adoption["tallies"]=0.0
	GameState.discovery_adoption["standard_measures"]=0.0
	GameState.discovery_adoption["copper_smelting"]=0.0

func _test_resource_stage()->void:
	var stores_before:=GameState.resource_stockpiles.duplicate(true)
	GameState.elapsed_days=1.0
	EconomySystem.process_day()
	_check(GameState.economy_stage==EconomySystem.STAGE_SUBSISTENCE,"founding economy skipped the resource stage")
	_check(float(GameState.economy_metrics.subsistence_share)>0.85,"founding economy was implausibly monetized")
	_check(EconomySystem.settlement_medium().contains("resources"),"resource settlement disappeared at founding")
	_check(GameState.resource_stockpiles==stores_before,"observational resource accounts consumed physical stores twice")
	_check(GameState.economy_metrics.has("real_economy"),"resource stage omitted physical subsistence accounts")
	_check(float(GameState.economy_metrics.essential_coverage)>0.0,"resource stage reported no essential coverage despite abundant stores")
	_check(float(GameState.economy_metrics.labor_return_index)>=0.0,"resource stage omitted a bounded real labor return")

func _test_resource_stage_war_wealth()->void:
	var coin_before:=float(GameState.resource_stockpiles.get("Coin",0.0))
	var supply_before:=GameState.currency_supply
	var receipt:=EconomySystem.receive_war_wealth(10.0,"public","Resource-era ransom")
	_check(is_equal_approx(float(receipt.accepted),10.0),"resource-era war wealth was rejected")
	_check(is_equal_approx(float(GameState.resource_stockpiles.get("Coin",0.0)),coin_before+10.0),"resource-era war wealth did not remain physical")
	_check(is_equal_approx(GameState.currency_supply,supply_before),"resource-era war wealth minted currency early")

func _test_metal_benchmark()->void:
	GameState.resource_stockpiles["Copper Ore"]=80.0
	GameState.discovery_adoption["tallies"]=0.40
	GameState.discovery_adoption["standard_measures"]=0.45
	GameState.discovery_adoption["copper_smelting"]=0.30
	GameState.elapsed_days=2.0
	var events:=EconomySystem.process_day()
	_check(GameState.economy_stage==EconomySystem.STAGE_METAL,"metal benchmark did not transition")
	_check(not events.is_empty(),"metal benchmark produced no historical event")
	_check(float(GameState.economy_metrics.monetization)>=0.08,"metal exchange did not enter the exchange mix")

func _test_currency_benchmark()->void:
	var coin_before:=float(GameState.resource_stockpiles.get("Coin",0.0))
	GameState.resource_stockpiles["Copper Ore"]=220.0
	GameState.discovery_adoption["tallies"]=0.70
	GameState.discovery_adoption["standard_measures"]=0.72
	GameState.elapsed_days=3.0
	EconomySystem.process_day()
	_check(GameState.economy_stage==EconomySystem.STAGE_CURRENCY,"currency benchmark did not transition")
	_check(GameState.currency_supply>0.0,"currency transition issued no initial supply")
	_check(float(GameState.economy_metrics.money_supply)>0.0,"currency metrics omitted supply")
	_check(is_equal_approx(_currency_account_total(),GameState.currency_supply),"initial currency accounts do not conserve supply")
	_check(EconomySystem._monetary_reserve_value()>=39.999,"currency transition did not sequester a founding reserve")
	_check(float(GameState.resource_stockpiles.get("Coin",0.0))<coin_before,"founding reserve did not consume physical coin first")
	_check(float(GameState.resource_stockpiles.get("Copper Ore",0.0))<220.0,"founding reserve did not consume ordinary metal")

func _test_weighed_metal_circulation()->void:
	var founding_target:=EconomySystem.founding_weighed_metal_requirement()
	_check(GameState.weighed_metal_circulation>=founding_target-0.01,"metal benchmark created no scaled physical exchange stock")
	var circulation_before:=GameState.weighed_metal_circulation
	var available_before:=EconomySystem._available_metal_value()
	var placed:=EconomySystem.place_weighed_metal_in_circulation(5.0,"Probe exchange placement")
	_check(is_equal_approx(float(placed.accepted),5.0),"usable physical metal could not enter weighed exchange")
	_check(GameState.weighed_metal_circulation>=circulation_before+4.999,"metal placement did not increase circulation")
	_check(EconomySystem._available_metal_value()<=available_before-4.999,"circulating metal remained available for tools or reserve")
	var withdrawn:=EconomySystem.withdraw_weighed_metal(2.0,"Probe exchange withdrawal")
	_check(is_equal_approx(float(withdrawn.accepted),2.0),"circulating metal could not return to physical stores")
	_check(GameState.weighed_metal_circulation<=circulation_before+3.001,"withdrawn metal remained in circulation")
	var losses_before:=GameState.weighed_metal_losses
	var exchange:=EconomySystem._process_weighed_metal_exchange(100.0,0.45,0.75)
	_check(float(exchange.turnover)>0.0,"physical weighed metal produced no domestic exchange turnover")
	_check(GameState.weighed_metal_losses>losses_before,"active weighed exchange produced no bounded wear or assay loss")
	_check(bool(EconomySystem.accounting_audit().ok),"weighed-metal placement and withdrawal failed accounting audit")

func _test_currency_stage_war_wealth()->void:
	var reserve_before:=EconomySystem._monetary_reserve_value()
	var supply_before:=GameState.currency_supply
	var treasury_before:=GameState.public_treasury
	var private_before:=GameState.private_currency
	var physical_coin_before:=float(GameState.resource_stockpiles.get("Coin",0.0))
	var public_receipt:=EconomySystem.receive_war_wealth(10.0,"state treasury","Public ransom")
	var private_receipt:=EconomySystem.receive_war_wealth(7.0,"private","Distributed plunder")
	_check(is_equal_approx(float(public_receipt.currency_deposited),10.0),"public war wealth was not deposited as reserve-backed currency")
	_check(is_equal_approx(float(private_receipt.currency_deposited),7.0),"private war wealth was not deposited as reserve-backed currency")
	_check(is_equal_approx(EconomySystem._monetary_reserve_value(),reserve_before+17.0),"currency-era war bullion did not expand committed reserve")
	_check(is_equal_approx(GameState.currency_supply,supply_before+17.0),"currency-era war wealth did not expand supply by the conserved deposit")
	_check(is_equal_approx(GameState.public_treasury,treasury_before+10.0),"public war wealth reached the wrong account")
	_check(is_equal_approx(GameState.private_currency,private_before+7.0),"private war wealth reached the wrong account")
	_check(is_equal_approx(float(GameState.resource_stockpiles.get("Coin",0.0)),physical_coin_before),"currency-era bullion leaked into ordinary material stores")
	_check(is_equal_approx(_currency_account_total(),GameState.currency_supply),"war wealth broke currency conservation")

func _test_conserved_public_finance_and_currency_policy()->void:
	var supply_before:=GameState.currency_supply
	var total_before:=_currency_account_total()
	GameState.elapsed_days=4.0
	EconomySystem.process_day()
	_check(is_equal_approx(GameState.currency_supply,supply_before),"taxation or spending changed money supply")
	_check(is_equal_approx(_currency_account_total(),total_before),"public finance lost currency")
	_check(float(GameState.economy_metrics.tax_revenue)>0.0,"capable currency economy collected no levy")
	var tax_capacity:Dictionary=GameState.economy_metrics.tax_capacity
	_check(float(tax_capacity.collectible)<=float(tax_capacity.administratively_assessed)+0.001,"daily levy collection bypassed administrative assessment")
	_check(float(tax_capacity.compliance)>0.0 and float(tax_capacity.compliance)<1.0,"daily levy omitted bounded compliance")
	_check(is_equal_approx(float(GameState.economy_metrics.liquid_money),GameState.private_currency),"treasury or reserve accounts leaked into transactional money")
	var liquidity:Dictionary=GameState.economy_metrics.currency_liquidity
	_check(is_equal_approx(float(liquidity.transactional_share)+float(liquidity.nontransactional_share),1.0),"currency account shares do not reconcile to issued supply")
	var issue:=EconomySystem.issue_currency(1000.0,"Probe issue")
	_check(float(issue.accepted)<1000.0,"issuance request bypassed reserve cap")
	_check(GameState.currency_supply<=EconomySystem._monetary_reserve_value()*2.5+0.001,"supply exceeded reserve ceiling")
	var retired:=EconomySystem.retire_currency(5.0,"Probe retirement")
	_check(float(retired.accepted)>0.0,"funded retirement was rejected")
	_check(is_equal_approx(_currency_account_total(),GameState.currency_supply),"issue/retire cycle broke conservation")

func _test_conserved_currency_transfer_api()->void:
	var supply_before:=GameState.currency_supply
	var private_before:=GameState.private_currency
	var treasury_before:=GameState.public_treasury
	var transfer:=EconomySystem.transfer_currency(3.0,"households","state treasury","Probe levy transfer")
	_check(is_equal_approx(float(transfer.accepted),3.0),"valid currency transfer was rejected")
	_check(is_equal_approx(GameState.private_currency,private_before-3.0) and is_equal_approx(GameState.public_treasury,treasury_before+3.0),"currency transfer reached the wrong accounts")
	var hoards_before:=GameState.currency_hoards
	var saved:=EconomySystem.transfer_currency(1.0,"private","hoards","Probe precautionary saving")
	_check(is_equal_approx(float(saved.accepted),1.0) and is_equal_approx(GameState.currency_hoards,hoards_before+1.0),"validated transfer could not reach the hoard account")
	EconomySystem.transfer_currency(1.0,"hoards","private","Probe precautionary release")
	var rejected:=EconomySystem.transfer_currency(1.0,"unknown","public","Invalid transfer")
	_check(is_equal_approx(float(rejected.accepted),0.0),"unknown currency account was silently accepted")
	_check(is_equal_approx(GameState.currency_supply,supply_before),"account transfer changed the money supply")
	_check(bool(EconomySystem.accounting_audit().ok),"account transfer failed conservation audit")

func _test_surplus_reserve_release()->void:
	var reserve_before:=EconomySystem._monetary_reserve_value()
	var physical_coin_before:=float(GameState.resource_stockpiles.get("Coin",0.0))
	var expected_floor:=GameState.currency_supply/2.5
	var release:=EconomySystem.release_surplus_reserve(1000.0,"Probe surplus release")
	_check(float(release.accepted)>0.0,"retirement-created surplus reserve could not return to stores")
	_check(float(release.accepted)<=reserve_before-expected_floor+0.001,"reserve release exceeded the live issue floor")
	_check(EconomySystem._monetary_reserve_value()>=expected_floor-0.001,"reserve release under-backed remaining currency")
	_check(float(GameState.resource_stockpiles.get("Coin",0.0))>physical_coin_before,"released standardized metal did not return to physical stores")
	_check(bool(EconomySystem.accounting_audit().ok),"surplus reserve release failed accounting audit")

func _test_currency_hoarding_and_recovery()->void:
	var total_before:=_currency_account_total()
	var hoards_before:=GameState.currency_hoards
	var low_confidence:Dictionary={}
	for iteration in 40:
		low_confidence=EconomySystem._process_currency_liquidity(0.15,0.08)
	_check(float(low_confidence.confidence)<0.65,"severe distrust still reported high currency confidence")
	_check(GameState.currency_hoards>hoards_before+1.0,"low confidence did not move household currency into hoards")
	_check(is_equal_approx(_currency_account_total(),total_before),"hoarding minted or destroyed currency")
	var peak_hoards:=GameState.currency_hoards
	var released_total:=0.0
	for iteration in 100:
		var recovery:=EconomySystem._process_currency_liquidity(0.98,0.0)
		released_total+=float(recovery.released_today)
	_check(released_total>0.0 and GameState.currency_hoards<peak_hoards,"restored confidence did not release precautionary balances")
	_check(bool(EconomySystem.accounting_audit().ok),"currency hoarding and recovery failed accounting audit")

func _test_policy_previews_are_pure()->void:
	var snapshot:Dictionary={
		"stores":GameState.resource_stockpiles.duplicate(true),
		"reserve":GameState.monetary_reserve_metals.duplicate(true),
		"metal_composition":GameState.weighed_metal_composition.duplicate(true),
		"metal_circulation":GameState.weighed_metal_circulation,
		"supply":GameState.currency_supply,
		"treasury":GameState.public_treasury,
		"private":GameState.private_currency,
		"hoards":GameState.currency_hoards,
		"mutual":GameState.mutual_aid_reserve,
		"tax":GameState.tax_rate,
		"trade":GameState.external_trade_policy,
		"spending_priority":GameState.public_spending_priority,
		"ledger":GameState.economic_ledger.duplicate(true)
	}
	var actions:Array=[
		["LEVY +",0.01],["LEVY −",-0.01],["BACK METAL",6.0],
		["RELEASE METAL",6.0],["METAL TO TRADE",6.0],
		["WITHDRAW TRADE METAL",6.0],["ISSUE",12.0],
		["RETIRE",-6.0],["SPENDING",0.0],["TRADE",0.0]
	]
	for specification in actions:
		var preview:Dictionary=EconomySystem.preview_policy(String(specification[0]),float(specification[1]))
		_check(preview.has("before") and preview.has("after"),"policy preview omitted account forecasts for %s" % String(specification[0]))
		_check(float(preview.get("accepted",-1.0))>=0.0,"policy preview returned a negative accepted amount for %s" % String(specification[0]))
		_check((preview.after as Dictionary).has("fiscal_outlook"),"policy preview omitted fiscal consequences for %s" % String(specification[0]))
	var reserve:=EconomySystem._monetary_reserve_value()
	var issue_preview:Dictionary=EconomySystem.preview_policy("ISSUE",12.0)
	var expected_issue:=minf(12.0,maxf(0.0,reserve*2.5-GameState.currency_supply))
	_check(is_equal_approx(float(issue_preview.accepted),expected_issue),"issue preview disagreed with the live reserve ceiling")
	var retirement_preview:Dictionary=EconomySystem.preview_policy("RETIRE",-6.0)
	var expected_retirement:=minf(6.0,minf(GameState.public_treasury,GameState.currency_supply))
	_check(is_equal_approx(float(retirement_preview.accepted),expected_retirement),"retirement preview disagreed with treasury liquidity")
	var release_preview:Dictionary=EconomySystem.preview_policy("RELEASE METAL",6.0)
	var expected_release:=minf(6.0,maxf(0.0,reserve-GameState.currency_supply/2.5))
	_check(is_equal_approx(float(release_preview.accepted),expected_release),"reserve release preview disagreed with the backing floor")
	var trade_policies:Array=["balanced","relief_imports","export_surplus","closed"]
	var expected_trade:=String(trade_policies[(trade_policies.find(GameState.external_trade_policy)+1)%trade_policies.size()])
	var trade_preview:Dictionary=EconomySystem.preview_policy("TRADE")
	_check(String((trade_preview.after as Dictionary).trade_policy)==expected_trade,"trade preview did not forecast the next stance")
	_check(GameState.resource_stockpiles==snapshot.stores,"policy preview mutated physical stores")
	_check(GameState.monetary_reserve_metals==snapshot.reserve,"policy preview mutated reserve composition")
	_check(GameState.weighed_metal_composition==snapshot.metal_composition,"policy preview mutated weighed-metal composition")
	_check(is_equal_approx(GameState.weighed_metal_circulation,float(snapshot.metal_circulation)),"policy preview moved circulating metal")
	_check(is_equal_approx(GameState.currency_supply,float(snapshot.supply)) and is_equal_approx(GameState.public_treasury,float(snapshot.treasury)),"policy preview changed sovereign currency accounts")
	_check(is_equal_approx(GameState.private_currency,float(snapshot.private)) and is_equal_approx(GameState.currency_hoards,float(snapshot.hoards)) and is_equal_approx(GameState.mutual_aid_reserve,float(snapshot.mutual)),"policy preview changed household currency accounts")
	_check(is_equal_approx(GameState.tax_rate,float(snapshot.tax)) and GameState.external_trade_policy==String(snapshot.trade) and GameState.public_spending_priority==String(snapshot.spending_priority),"policy preview enacted a policy")
	_check(GameState.economic_ledger==snapshot.ledger,"policy preview added an economic ledger entry")
	_check(bool(EconomySystem.accounting_audit().ok),"policy preview failed the accounting audit")

func _test_fiscal_outlook_contract()->void:
	var accounts_before:=_currency_account_total()
	var ledger_before:=GameState.economic_ledger.duplicate(true)
	var trade_volume:=float(GameState.economy_metrics.get("trade_volume",0.0))
	var monetization:=float(GameState.economy_metrics.get("monetization",0.0))
	var peaceful:=EconomySystem.fiscal_outlook(30.0,trade_volume,monetization,{})
	var mobilized:=EconomySystem.fiscal_outlook(30.0,trade_volume,monetization,{"currency_upkeep_units":50.0,"field_soldiers":80})
	_check(bool(peaceful.active),"currency economy produced no active fiscal outlook")
	_check(float(peaceful.discretionary_headroom)<=GameState.public_treasury+0.001,"fiscal headroom exceeded treasury cash")
	_check(float(mobilized.daily_military)>float(peaceful.daily_military),"military burden snapshot did not raise forecast upkeep")
	_check(float(mobilized.protected_buffer)>float(peaceful.protected_buffer),"mobilization did not raise the protected treasury buffer")
	_check(float(mobilized.coverage_ratio)<float(peaceful.coverage_ratio),"mobilization did not reduce fiscal coverage")
	_check(String(mobilized.status)=="default risk","an overwhelming visible military payroll did not warn of default risk")
	var retirement:Dictionary=EconomySystem.preview_policy("RETIRE",-6.0)
	var before_fiscal:Dictionary=(retirement.before as Dictionary).fiscal_outlook
	var after_fiscal:Dictionary=(retirement.after as Dictionary).fiscal_outlook
	_check(float(after_fiscal.discretionary_headroom)<=float(before_fiscal.discretionary_headroom)+0.001,"retirement preview increased fiscal headroom")
	var higher_levy:Dictionary=EconomySystem.preview_policy("LEVY +",0.01)
	var levy_before:Dictionary=(higher_levy.before as Dictionary).fiscal_outlook
	var levy_after:Dictionary=(higher_levy.after as Dictionary).fiscal_outlook
	_check(float(levy_after.daily_revenue)>=float(levy_before.daily_revenue)-0.001,"higher levy preview reduced collectible revenue")
	_check(is_equal_approx(_currency_account_total(),accounts_before),"fiscal outlook moved conserved currency")
	_check(GameState.economic_ledger==ledger_before,"fiscal outlook wrote to the economic ledger")

func _test_public_spending_priorities()->void:
	var balanced:=EconomySystem._allocate_public_spending(5.0,4.0,4.0,"balanced")
	var civil_first:=EconomySystem._allocate_public_spending(5.0,4.0,4.0,"civil_first")
	var military_first:=EconomySystem._allocate_public_spending(5.0,4.0,4.0,"military_first")
	_check(is_equal_approx(float(balanced.civil_paid),2.5) and is_equal_approx(float(balanced.military_paid),2.5),"balanced priority did not allocate pro rata")
	_check(is_equal_approx(float(civil_first.civil_paid),4.0) and is_equal_approx(float(civil_first.military_paid),1.0),"civil-first priority did not protect civil obligations")
	_check(is_equal_approx(float(military_first.civil_paid),1.0) and is_equal_approx(float(military_first.military_paid),4.0),"military-first priority did not protect military obligations")
	_check(is_equal_approx(float(civil_first.spending),5.0) and is_equal_approx(float(military_first.spending),5.0),"spending priority created or destroyed available funds")
	var preview:Dictionary=EconomySystem.preview_policy("SPENDING")
	_check(String((preview.after as Dictionary).spending_priority)=="civil_first","spending preview did not forecast the next priority")
	var treasury_before:=GameState.public_treasury
	var private_before:=GameState.private_currency
	var civil_arrears_before:=GameState.civil_arrears
	var military_arrears_before:=GameState.military_arrears
	var debt_before:=GameState.public_debt
	var tax_before:=GameState.tax_rate
	var priority_before:=GameState.public_spending_priority
	var public_credit_before:=float(GameState.discovery_adoption.get("public_credit",0.0))
	var ledger_before:Array[Dictionary]=GameState.economic_ledger.duplicate(true)
	var scenario_private:=GameState.currency_supply-GameState.currency_hoards-GameState.mutual_aid_reserve-2.0
	GameState.tax_rate=0.0
	GameState.discovery_adoption["public_credit"]=0.0
	GameState.public_debt=0.0
	GameState.public_treasury=2.0
	GameState.private_currency=scenario_private
	GameState.civil_arrears=2.0
	GameState.military_arrears=0.0
	GameState.public_spending_priority="civil_first"
	var civil_result:=EconomySystem._process_public_finance(0.0,0.0,{"currency_upkeep_units":2.0})
	GameState.public_debt=0.0
	GameState.public_treasury=2.0
	GameState.private_currency=scenario_private
	GameState.civil_arrears=2.0
	GameState.military_arrears=0.0
	GameState.public_spending_priority="military_first"
	var military_result:=EconomySystem._process_public_finance(0.0,0.0,{"currency_upkeep_units":2.0})
	_check(float(civil_result.civil_upkeep)>float(military_result.civil_upkeep) and float(civil_result.military_upkeep)<float(military_result.military_upkeep),"daily public finance ignored its spending priority")
	_check(is_equal_approx(float(civil_result.spending),float(military_result.spending)),"priority changed total spendable treasury funds")
	GameState.public_treasury=treasury_before
	GameState.private_currency=private_before
	GameState.civil_arrears=civil_arrears_before
	GameState.military_arrears=military_arrears_before
	GameState.public_debt=debt_before
	GameState.tax_rate=tax_before
	GameState.public_spending_priority=priority_before
	GameState.discovery_adoption["public_credit"]=public_credit_before
	GameState.economic_ledger=ledger_before
	_check(bool(EconomySystem.accounting_audit().ok),"priority allocation failed accounting after restoration")

func _test_tax_capacity_constraints()->void:
	var accounts_before:=_currency_account_total()
	var ledger_before:=GameState.economic_ledger.duplicate(true)
	var low_rate:=EconomySystem.tax_capacity_snapshot(0.05,100.0,0.60)
	var high_rate:=EconomySystem.tax_capacity_snapshot(0.25,100.0,0.60)
	_check(float(high_rate.compliance)<float(low_rate.compliance),"high statutory levy produced no compliance strain")
	_check(float(high_rate.effective_rate)<float(high_rate.statutory_rate),"statutory levy was treated as fully effective")
	_check(float(high_rate.collectible)>float(low_rate.collectible),"higher levy never increased collectible revenue")
	_check(float(high_rate.collectible)/maxf(0.001,float(low_rate.collectible))<4.0,"fivefold statutory levy produced implausibly linear revenue")
	var cash_poor:=EconomySystem._tax_capacity_for(0.25,1000.0,1.0,0.5)
	_check(is_equal_approx(float(cash_poor.collectible),0.5) and float(cash_poor.liquidity_gap)>0.0,"levy capacity collected currency households did not hold")
	var administration_before:=int(GameState.population_allocations.get("Administration",0))
	GameState.population_allocations["Administration"]=0
	var unadministered:=EconomySystem.tax_capacity_snapshot(0.10,100.0,0.60)
	GameState.population_allocations["Administration"]=administration_before
	_check(is_equal_approx(float(unadministered.collectible),0.0),"levy collected revenue without administrative reach")
	var arrears_before:=GameState.civil_arrears
	GameState.civil_arrears=GameState.population_exact*0.15
	var distrusted:=EconomySystem.tax_capacity_snapshot(0.10,100.0,0.60)
	GameState.civil_arrears=arrears_before
	var trusted:=EconomySystem.tax_capacity_snapshot(0.10,100.0,0.60)
	_check(float(distrusted.compliance)<float(trusted.compliance),"public arrears did not reduce levy compliance")
	var levy_preview:Dictionary=EconomySystem.preview_policy("LEVY +",0.01)
	var preview_fiscal:Dictionary=(levy_preview.after as Dictionary).fiscal_outlook
	_check(float(preview_fiscal.tax_compliance)>0.0 and float(preview_fiscal.effective_tax_rate)<=GameState.tax_rate+0.011,"levy preview omitted effective collection limits")
	_check(is_equal_approx(_currency_account_total(),accounts_before),"tax-capacity forecast moved currency accounts")
	_check(GameState.economic_ledger==ledger_before,"tax-capacity forecast wrote to the ledger")

func _test_transactional_liquidity_accounts()->void:
	var prices_before:=GameState.market_prices.duplicate(true)
	var private_before:=GameState.private_currency
	var treasury_before:=GameState.public_treasury
	var accounts_before:=_currency_account_total()
	var movable:=minf(20.0,GameState.public_treasury)
	var treasury_heavy_index:=EconomySystem._update_prices(0.60)
	GameState.market_prices=prices_before.duplicate(true)
	GameState.public_treasury-=movable
	GameState.private_currency+=movable
	var household_liquid_index:=EconomySystem._update_prices(0.60)
	_check(household_liquid_index>treasury_heavy_index,"idle treasury balances exerted the same price pressure as household currency")
	GameState.market_prices=prices_before
	GameState.private_currency=private_before
	GameState.public_treasury=treasury_before
	_check(is_equal_approx(_currency_account_total(),accounts_before),"liquidity segmentation test changed conserved supply")
	var issue_preview:Dictionary=EconomySystem.preview_policy("ISSUE",12.0)
	var preview_before:Dictionary=issue_preview.before
	var preview_after:Dictionary=issue_preview.after
	_check(is_equal_approx(float(preview_after.transactional_money),float(preview_before.transactional_money)),"unspent issuance preview entered household circulation")
	_check(float(preview_after.transactional_share)<=float(preview_before.transactional_share)+0.001,"unspent issuance raised the transactional share")

func _test_value_conserved_external_trade()->void:
	GameState.external_trade_policy="balanced"
	GameState.resource_stockpiles["Timber"]=800.0
	GameState.resource_stockpiles["Fiber Plants"]=0.0
	var timber_before:=float(GameState.resource_stockpiles.Timber)
	var fiber_before:=float(GameState.resource_stockpiles["Fiber Plants"])
	var result:=EconomySystem._process_external_trade(0.90,100.0,1)
	var imported_quantity:=0.0
	for quantity in (result.imported_goods as Dictionary).values(): imported_quantity+=float(quantity)
	_check(float(result.exports)>0.0,"surplus goods produced no regional export claim")
	_check(float(result.imports)>0.0,"funded essential deficit produced no regional import")
	_check(float(GameState.resource_stockpiles.Timber)<timber_before,"exported physical goods remained in settlement stores")
	_check(imported_quantity>0.0,"import spending delivered no physical goods")
	_check(float(GameState.resource_stockpiles["Fiber Plants"])>fiber_before or float(GameState.resource_stockpiles.get("Clay",0.0))>0.0,"trade did not address any essential material deficit")
	_check(is_equal_approx(GameState.external_trade_credit,GameState.external_trade_exports-GameState.external_trade_imports-GameState.external_trade_losses),"regional trade claims were not value-conserved")
	GameState.external_trade_policy="closed"

func _test_food_imports_use_authoritative_food_store()->void:
	GameState.external_trade_policy="relief_imports"
	GameState.food_stocks={"Fresh plants":0.0,"Fresh meat":0.0,"Fish":0.0,"Dry staples":0.0,"Preserved food":0.0}
	GameState.resource_stockpiles["Food"]=0.0
	GameState.external_trade_credit+=50.0
	GameState.external_trade_exports+=50.0
	var result:=EconomySystem._process_external_trade(0.90,100.0,1)
	var typed_food:=0.0
	for amount in GameState.food_stocks.values(): typed_food+=float(amount)
	_check(float((result.imported_goods as Dictionary).get("Food",0.0))>0.0,"relief trade did not import food into a severe deficit")
	_check(typed_food>0.0 and is_equal_approx(typed_food,float(GameState.resource_stockpiles.Food)),"food imports bypassed the authoritative typed food store")
	_check(is_equal_approx(GameState.external_trade_credit,GameState.external_trade_exports-GameState.external_trade_imports-GameState.external_trade_losses),"food import broke the regional trade identity")
	GameState.external_trade_policy="closed"

func _test_scarcity_prices()->void:
	var prior:=float(GameState.market_prices.Food)
	GameState.resource_stockpiles["Food"]=12.0
	GameState.simulation_metrics["food_consumption"]=120.0
	GameState.simulation_metrics["food_eaten"]=12.0
	GameState.simulation_metrics["food_intake_ratio"]=0.10
	for day in range(5,35):
		GameState.elapsed_days=float(day)
		EconomySystem.process_day()
	_check(float(GameState.market_prices.Food)>prior,"scarcity did not raise the food price")
	_check(float(EconomySystem.market_trend("Food",30).change)>0.0,"sustained scarcity produced no positive food trend")
	_check(float(GameState.economy_metrics.market_volatility)>0.0,"moving prices produced no market volatility")
	_check(float(GameState.economy_metrics.essential_coverage)<0.65,"physical subsistence account concealed a severe food gap")
	_check(float(GameState.economy_metrics.resource_obligation_pressure)>0.20,"unmet essentials produced no obligation pressure")
	_check(float(GameState.economy_metrics.labor_return_index)>=0.0 and float(GameState.economy_metrics.labor_return_index)<=3.0,"labor return escaped its bounded comparison range")

func _test_military_burden_contract()->void:
	var burden:=EconomySystem._military_burden_snapshot()
	_check(burden.has("currency_upkeep_units"),"military read-only burden contract was not consumed")
	var upkeep:=EconomySystem._public_upkeep({"currency_upkeep_units":1.25})
	_check(is_equal_approx(float(upkeep.military),1.25),"reported military monetary upkeep was not included")
	_check(is_equal_approx(float(upkeep.total),float(upkeep.civil)+1.25),"military and civil upkeep did not compose")
	var peaceful:=EconomySystem._real_economy_accounts(10.0,0.50,{})
	var mobilized:=EconomySystem._real_economy_accounts(10.0,0.50,{"mobilized_citizens":18,"workshop_diversion":0.60,"equipment_backlog_work":80.0})
	_check(float(mobilized.collective_labor_share)>float(peaceful.collective_labor_share),"mobilization and workshop diversion did not raise collective labor claims")
	_check(float(mobilized.obligation_pressure)>float(peaceful.obligation_pressure),"military equipment backlog produced no real-economy pressure")

func _test_unpaid_obligations_persist_as_arrears()->void:
	var prior_tax:=GameState.tax_rate
	GameState.tax_rate=0.0
	GameState.public_treasury=0.0
	GameState.currency_hoards=0.0
	GameState.private_currency=GameState.currency_supply
	EconomySystem._process_public_finance(0.0,0.0,{"currency_upkeep_units":2.0})
	var carried:=GameState.civil_arrears+GameState.military_arrears
	_check(carried>2.0,"unfunded obligations vanished instead of becoming arrears")
	var next_due:=float(EconomySystem._public_upkeep({"currency_upkeep_units":2.0}).total)
	GameState.public_treasury=carried+next_due
	GameState.currency_hoards=0.0
	GameState.private_currency=GameState.currency_supply-GameState.public_treasury
	EconomySystem._process_public_finance(0.0,0.0,{"currency_upkeep_units":2.0})
	_check(GameState.civil_arrears+GameState.military_arrears<0.001,"funded prior obligations did not clear")
	_check(is_equal_approx(_currency_account_total(),GameState.currency_supply),"arrears payment broke currency conservation")
	GameState.tax_rate=prior_tax

func _test_public_credit_transfers_existing_currency()->void:
	GameState.discovery_adoption["public_credit"]=0.70
	var prior_tax:=GameState.tax_rate
	GameState.tax_rate=0.0
	GameState.public_debt=0.0
	GameState.public_treasury=0.0
	GameState.currency_hoards=0.0
	GameState.private_currency=GameState.currency_supply
	var supply_before:=GameState.currency_supply
	var finance:=EconomySystem._process_public_finance(40.0,0.60,{"currency_upkeep_units":3.0})
	_check(float(finance.borrowing)>0.0,"adopted public credit could not bridge a treasury obligation")
	_check(GameState.public_debt>0.0,"public borrowing created no repayable public claim")
	_check(GameState.civil_arrears+GameState.military_arrears<0.001,"funded public-credit obligation remained in arrears")
	_check(is_equal_approx(GameState.currency_supply,supply_before),"public borrowing minted or destroyed currency")
	_check(is_equal_approx(_currency_account_total(),GameState.currency_supply),"public borrowing broke account conservation")
	var debt_before_service:=GameState.public_debt
	GameState.public_treasury=10.0
	GameState.currency_hoards=0.0
	GameState.private_currency=GameState.currency_supply-10.0
	var service:=EconomySystem._process_public_finance(0.0,0.0,{})
	_check(float(service.debt_service)>0.0 and GameState.public_debt<debt_before_service,"funded treasury surplus did not service public debt")
	_check(is_equal_approx(_currency_account_total(),GameState.currency_supply),"public debt service broke account conservation")
	GameState.public_debt=0.0
	GameState.discovery_adoption["public_credit"]=0.0
	GameState.tax_rate=prior_tax

func _test_mutual_risk_pool_conserves_currency()->void:
	GameState.discovery_adoption["risk_pools"]=0.80
	var supply_before:=GameState.currency_supply
	var healthy:=EconomySystem._process_mutual_risk_pool(100.0,0.0)
	_check(float(healthy.contribution)>0.0 and GameState.mutual_aid_reserve>0.0,"adopted mutual risk pool collected no bounded contribution")
	GameState.economy_metrics["essential_coverage"]=0.40
	var crisis:=EconomySystem._process_mutual_risk_pool(0.0,4.0)
	_check(float(crisis.payout)>0.0,"funded mutual risk pool paid no crisis relief")
	_check(is_equal_approx(_currency_account_total(),supply_before),"mutual risk pool minted or lost currency")
	GameState.private_currency+=GameState.mutual_aid_reserve
	GameState.mutual_aid_reserve=0.0
	GameState.discovery_adoption["risk_pools"]=0.0

func _test_credit_and_unknown_goods()->void:
	var salt_before:=float(GameState.market_prices.get("Salt",-1.0))
	for day in range(35,95):
		GameState.elapsed_days=float(day)
		EconomySystem.process_day()
	_check(GameState.credit_outstanding>0.0,"recorded credit never emerged")
	_check(GameState.credit_outstanding<=float(GameState.economy_metrics.credit_limit)+0.001,"private credit exceeded its institutional and productive ceiling")
	_check(GameState.economic_ledger.size()>0,"economic activity produced no audit ledger")
	_check(is_equal_approx(float(GameState.market_prices.get("Salt",-1.0)),salt_before),"undiscovered salt distorted the known market")
	_check(GameState.economy_history.size()==94,"daily economy history skipped or duplicated days")
	_check(bool(EconomySystem.accounting_audit().ok),"final economy accounts failed conservation audit")

func _check(condition:bool,message:String)->void:
	if not condition: failures.append(message)

func _currency_account_total()->float:
	return GameState.private_currency+GameState.currency_hoards+GameState.public_treasury+GameState.mutual_aid_reserve
