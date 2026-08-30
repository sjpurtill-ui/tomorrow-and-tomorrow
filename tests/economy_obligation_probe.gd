extends Node

var failures:Array[String]=[]

func _ready()->void:
	_run_obligation_sequence()
	if not failures.is_empty():
		for failure in failures: push_error("Economy obligation regression: "+failure)
		get_tree().quit(1)
		return
	print("ECONOMY_OBLIGATION_PASS customary_scheduled_currency")
	get_tree().quit(0)

func _run_obligation_sequence()->void:
	GameState.reset_for_new_world(771204)
	FoodSystem.reset_for_new_world()
	EconomySystem.reset_for_new_world()
	GameState.population_total=120
	GameState.population_exact=120.0
	GameState.settlement_site_committed=true
	GameState.housing_capacity=120
	GameState.external_trade_policy="closed"
	GameState.population_allocations={"Food":45,"Survey":0,"Extraction":0,"Construction":0,"Crafting":0,"Logistics":0,"Knowledge":0,"Administration":0,"Defense":0}
	GameState.simulation_metrics={"food_days":40.0,"food_consumption":120.0,"food_eaten":120.0,"food_intake_ratio":1.0,"food_production":120.0,"logistics":0.45,"legitimacy":0.70,"storage_function":0.55}
	GameState.society_capacities={"production":0.50,"institutions":0.50,"logistics":0.45}
	GameState.material_metrics={"delivered_today":0.0,"lost_today":0.0}
	GameState.resource_stockpiles={"Food":4800.0,"Timber":240.0,"Stone":190.0,"Clay":80.0,"Fiber Plants":80.0,"Copper Ore":0.0,"Tin Ore":0.0,"Iron Ore":0.0}
	var stores_before:=GameState.resource_stockpiles.duplicate(true)
	GameState.elapsed_days=1.0
	EconomySystem.process_day()
	var customary:Dictionary=GameState.economy_metrics.public_obligations
	_expect(String(customary.regime)=="customary obligations","founding obligations were not customary")
	_expect(float(customary.labor_arrears)>0.0 and float(customary.material_arrears)>0.0,"unrendered customary dues left no visible shortfall")
	_expect(GameState.resource_stockpiles==stores_before,"obligation accounting consumed physical stores a second time")
	_expect(GameState.currency_supply==0.0,"customary dues minted currency")
	var customary_reach:=float(customary.assessment_reach)
	var customary_labor_arrears:=GameState.in_kind_labor_arrears
	GameState.discovery_adoption["labor_rotations"]=0.80
	GameState.discovery_adoption["household_councils"]=0.80
	GameState.discovery_adoption["customary_law"]=0.80
	GameState.discovery_adoption["census_rolls"]=0.80
	GameState.discovery_adoption["public_stores"]=0.80
	GameState.discovery_adoption["public_levies"]=0.80
	GameState.discovery_adoption["tallies"]=0.80
	GameState.elapsed_days=2.0
	var events:=EconomySystem.process_day()
	var scheduled:Dictionary=GameState.economy_metrics.public_obligations
	_expect(String(scheduled.regime)=="scheduled in-kind levies","adopted levies did not establish a scheduled regime")
	_expect(float(scheduled.assessment_reach)>customary_reach,"records and administration did not widen assessment reach")
	_expect(GameState.in_kind_labor_arrears>customary_labor_arrears,"recorded unpaid labor dues did not persist and accumulate")
	_expect(GameState.economy_benchmarks.has("scheduled_public_levies") and not events.is_empty(),"scheduled levies produced no institutional benchmark event")
	var labor_arrears_before_service:=GameState.in_kind_labor_arrears
	var material_arrears_before_service:=GameState.in_kind_material_arrears
	GameState.population_allocations["Administration"]=6
	GameState.population_allocations["Construction"]=8
	GameState.population_allocations["Logistics"]=5
	GameState.material_metrics["delivered_today"]=20.0
	GameState.elapsed_days=3.0
	EconomySystem.process_day()
	var serviced:Dictionary=GameState.economy_metrics.public_obligations
	_expect(float(serviced.labor_coverage)>0.95 and float(serviced.material_coverage)>0.95,"adequate service and deliveries did not fulfill assessed dues")
	_expect(GameState.in_kind_labor_arrears<labor_arrears_before_service and GameState.in_kind_material_arrears<material_arrears_before_service,"rendered obligations did not reduce carried arrears")
	var scheduled_in_kind_share:=float(serviced.in_kind_share)
	GameState.discovery_adoption["standard_measures"]=0.80
	GameState.discovery_adoption["copper_smelting"]=0.80
	GameState.resource_stockpiles["Copper Ore"]=EconomySystem.currency_metal_requirement()/maxf(0.01,EconomySystem._metal_processing_efficiency())*1.35
	GameState.elapsed_days=4.0
	EconomySystem.process_day()
	GameState.elapsed_days=5.0
	EconomySystem.process_day()
	var monetary:Dictionary=GameState.economy_metrics.public_obligations
	_expect(GameState.economy_stage==EconomySystem.STAGE_CURRENCY,"capable obligation sequence did not reach currency")
	_expect(String(monetary.regime)=="monetary levy with residual dues","currency failed to commute most public dues into money")
	_expect(float(monetary.in_kind_share)<scheduled_in_kind_share,"currency did not reduce the in-kind share of public obligations")
	_expect(float(GameState.economy_metrics.tax_revenue)>0.0,"monetary taxation did not coexist with residual service dues")
	_expect(bool(EconomySystem.accounting_audit().ok),"obligation sequence failed the accounting audit")

func _expect(condition:bool,message:String)->void:
	if not condition: failures.append(message)
