extends Node

var failures:Array[String]=[]

func _ready()->void:
	_resource_collapse()
	_weighed_metal_trade()
	_currency_reserve_cap()
	_fiscal_and_institutional_shocks()
	_foreign_claim_contraction()
	if not failures.is_empty():
		for failure in failures: push_error("Economy shock regression: "+failure)
		get_tree().quit(1)
		return
	print("ECONOMY_SHOCK_MATRIX_PASS scenarios=5")
	get_tree().quit(0)

func _base(population:int=120)->void:
	GameState.reset_for_new_world(330000+population+failures.size())
	FoodSystem.reset_for_new_world()
	EconomySystem.reset_for_new_world()
	GameState.population_total=population
	GameState.population_exact=float(population)
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.water_metrics={"intake_ratio":1.0,"source_accessible":true,"days":3.0}
	GameState.housing_capacity=population
	GameState.external_trade_policy="closed"
	GameState.population_allocations={"Food":roundi(population*0.30),"Survey":roundi(population*0.05),"Extraction":roundi(population*0.08),"Construction":roundi(population*0.07),"Crafting":roundi(population*0.05),"Logistics":roundi(population*0.05),"Knowledge":roundi(population*0.04),"Administration":roundi(population*0.05),"Defense":roundi(population*0.03)}
	GameState.simulation_metrics={"food_days":40.0,"food_consumption":float(population),"food_eaten":float(population),"food_intake_ratio":1.0,"food_production":float(population)*1.05,"logistics":0.52,"legitimacy":0.74,"storage_function":0.65}
	GameState.society_capacities={"production":0.50,"institutions":0.52,"logistics":0.52}
	GameState.material_metrics={"delivered_today":float(population)*0.10,"lost_today":0.0}
	GameState.resource_stockpiles={"Food":float(population)*40.0,"Timber":float(population)*2.0,"Stone":float(population)*1.6,"Clay":float(population)*0.65,"Fiber Plants":float(population)*0.65,"Copper Ore":0.0,"Tin Ore":0.0,"Iron Ore":0.0}

func _enable_currency()->void:
	GameState.discovery_adoption["tallies"]=0.75
	GameState.discovery_adoption["standard_measures"]=0.75
	GameState.discovery_adoption["copper_smelting"]=0.75
	var efficiency:=EconomySystem._metal_processing_efficiency()
	GameState.resource_stockpiles["Copper Ore"]=EconomySystem.currency_metal_requirement()/maxf(0.01,efficiency)*1.35
	GameState.elapsed_days=1.0
	EconomySystem.process_day()
	GameState.elapsed_days=2.0
	EconomySystem.process_day()
	_expect(GameState.economy_stage==EconomySystem.STAGE_CURRENCY,"capable setup did not reach currency")

func _resource_collapse()->void:
	_base()
	GameState.settlement_site_committed=false
	GameState.housing_capacity=0
	GameState.resource_stockpiles["Food"]=1.0
	GameState.resource_stockpiles["Timber"]=0.0
	GameState.resource_stockpiles["Stone"]=0.0
	GameState.resource_stockpiles["Fiber Plants"]=0.0
	GameState.simulation_metrics["food_eaten"]=1.0
	GameState.simulation_metrics["food_intake_ratio"]=1.0/120.0
	GameState.simulation_metrics["food_production"]=0.0
	var stores_before:=GameState.resource_stockpiles.duplicate(true)
	GameState.elapsed_days=1.0
	EconomySystem.process_day()
	_expect(GameState.economy_stage==EconomySystem.STAGE_SUBSISTENCE,"collapse invented a later exchange institution")
	_expect(GameState.currency_supply==0.0 and GameState.credit_outstanding==0.0,"collapse invented financial claims")
	_expect(float(GameState.economy_metrics.essential_coverage)<0.20,"collapse was hidden by nominal indicators")
	_expect(float(GameState.economy_metrics.social_pressure)<-0.05,"collapse created no material social pressure")
	_expect(GameState.resource_stockpiles==stores_before,"economy double-consumed collapsed stores")

func _weighed_metal_trade()->void:
	_base()
	GameState.discovery_adoption["tallies"]=0.40
	GameState.discovery_adoption["standard_measures"]=0.45
	GameState.discovery_adoption["copper_smelting"]=0.40
	GameState.resource_stockpiles["Copper Ore"]=EconomySystem.metal_stage_requirement()/EconomySystem._metal_processing_efficiency()*1.25
	GameState.resource_stockpiles["Timber"]=1000.0
	GameState.resource_stockpiles["Fiber Plants"]=0.0
	GameState.economy_known_goods["Fiber Plants"]=true
	GameState.external_trade_policy="balanced"
	GameState.elapsed_days=1.0
	EconomySystem.process_day()
	GameState.elapsed_days=2.0
	EconomySystem.process_day()
	_expect(GameState.economy_stage==EconomySystem.STAGE_METAL,"weighed-metal scenario skipped or missed its stage")
	_expect(GameState.currency_supply==0.0,"weighed-metal trade minted currency")
	_expect(GameState.weighed_metal_circulation>0.0 and float(GameState.economy_metrics.metal_trade_turnover)>0.0,"weighed-metal scenario had no physical metal circulation or turnover")
	_expect(GameState.external_trade_exports>0.0 and GameState.external_trade_imports>0.0,"weighed-metal trade failed to exchange physical surplus")
	_expect(is_equal_approx(GameState.external_trade_credit,GameState.external_trade_exports-GameState.external_trade_imports-GameState.external_trade_losses),"metal-stage trade claims did not reconcile")

func _currency_reserve_cap()->void:
	_base()
	_enable_currency()
	var result:=EconomySystem.issue_currency(1000000.0,"Shock-matrix overissue")
	_expect(float(result.accepted)<1000000.0,"reserve ceiling accepted an unlimited issue")
	_expect(GameState.currency_supply<=EconomySystem._monetary_reserve_value()*2.5+0.001,"overissue breached committed backing")
	_expect(bool(EconomySystem.accounting_audit().ok),"reserve-cap shock broke accounting")

func _fiscal_and_institutional_shocks()->void:
	_base()
	_enable_currency()
	GameState.tax_rate=0.0
	GameState.public_treasury=0.0
	GameState.currency_hoards=0.0
	GameState.private_currency=GameState.currency_supply
	var unfunded:=EconomySystem._process_public_finance(0.0,0.0,{"currency_upkeep_units":8.0})
	_expect(float(unfunded.borrowing)==0.0 and GameState.military_arrears>=8.0,"pre-credit war obligations did not become arrears")
	GameState.discovery_adoption["public_credit"]=0.80
	GameState.civil_arrears=0.0
	GameState.military_arrears=0.0
	GameState.public_debt=0.0
	GameState.public_treasury=0.0
	GameState.currency_hoards=0.0
	GameState.private_currency=GameState.currency_supply
	var bridged:=EconomySystem._process_public_finance(50.0,0.60,{"currency_upkeep_units":8.0})
	_expect(float(bridged.borrowing)>0.0 and GameState.public_debt>0.0,"adopted public credit failed to bridge wartime finance")
	_expect(GameState.military_arrears<0.001,"supportable borrowing still left wartime arrears")
	GameState.discovery_adoption["risk_pools"]=0.80
	GameState.economy_metrics["essential_coverage"]=1.0
	EconomySystem._process_mutual_risk_pool(100.0,0.0)
	var pool_before:=GameState.mutual_aid_reserve
	GameState.economy_metrics["essential_coverage"]=0.35
	var relief:=EconomySystem._process_mutual_risk_pool(0.0,5.0)
	_expect(pool_before>0.0 and float(relief.payout)>0.0,"mature mutual aid failed under a household shock")
	_expect(bool(EconomySystem.accounting_audit().ok),"credit and mutual-aid shock broke accounting")

func _foreign_claim_contraction()->void:
	_base()
	_enable_currency()
	GameState.external_trade_exports=1000.0
	GameState.external_trade_imports=0.0
	GameState.external_trade_losses=0.0
	GameState.external_trade_credit=1000.0
	GameState.external_trade_policy="closed"
	var contraction:=EconomySystem._process_external_trade(0.05,0.0)
	_expect(float(contraction.claim_loss)>0.0,"collapsed counterpart capacity preserved every foreign claim")
	_expect(GameState.external_trade_credit<1000.0,"foreign impairment did not reduce claims")
	_expect(is_equal_approx(GameState.external_trade_credit,GameState.external_trade_exports-GameState.external_trade_imports-GameState.external_trade_losses),"foreign impairment escaped the trade identity")

func _expect(condition:bool,message:String)->void:
	if not condition: failures.append(message)
