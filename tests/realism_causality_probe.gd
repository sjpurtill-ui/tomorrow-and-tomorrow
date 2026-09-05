extends Node

var failures:Array[String]=[]

func _ready()->void:
	_test_no_water_no_exchange()
	_test_surplus_required_for_exchange()
	_test_price_requires_transaction()
	_test_foreign_trade_requires_contract()
	_test_water_is_consumed()
	_test_visible_surface_water_sustains_founders()
	_test_storage_has_physical_source()
	if not failures.is_empty():
		for failure in failures: push_error("Realism causality: "+failure)
		get_tree().quit(1)
		return
	print("REALISM_CAUSALITY_PROBE_PASS")
	get_tree().quit(0)

func _base_state()->void:
	GameState.reset_for_new_world(91823)
	ResourceSystem.reset_for_new_world()
	EconomySystem.reset_for_new_world()
	ResourceSystem.initialize()
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.population_exact=120.0
	GameState.population_total=120
	GameState.population_allocations["Administration"]=6
	GameState.simulation_metrics={"food_intake_ratio":1.0,"food_production":120.0,"food_consumption":120.0,"logistics":0.45,"storage_function":0.4}
	GameState.material_metrics={"delivered_today":0.0,"lost_today":0.0}
	GameState.water_metrics={"intake_ratio":1.0,"source_accessible":true,"days":2.0}

func _test_no_water_no_exchange()->void:
	_base_state()
	GameState.water_metrics={"intake_ratio":0.0,"source_accessible":false,"days":0.0}
	GameState.simulation_metrics["food_production"]=180.0
	GameState.material_metrics["delivered_today"]=20.0
	GameState.elapsed_days=1.0
	EconomySystem.process_day()
	_check(is_zero_approx(float(GameState.economy_metrics.market_access)),"market access existed without water")
	_check(is_zero_approx(float(GameState.economy_metrics.trade_volume)),"trade existed without water")
	_check(is_zero_approx(float(GameState.economy_metrics.price_index)),"price index existed without a transaction")

func _test_surplus_required_for_exchange()->void:
	_base_state()
	GameState.elapsed_days=2.0
	EconomySystem.process_day()
	_check(is_zero_approx(float(GameState.economy_metrics.trade_volume)),"subsistence food production was counted as trade")
	GameState.simulation_metrics["food_production"]=150.0
	GameState.elapsed_days=3.0
	EconomySystem.process_day()
	_check(float(GameState.economy_metrics.trade_volume)>0.0,"real food surplus produced no reciprocal exchange")

func _test_price_requires_transaction()->void:
	_base_state()
	GameState.elapsed_days=4.0
	EconomySystem.process_day()
	_check(is_zero_approx(float(GameState.economy_metrics.price_index)),"untraded inventory generated an observed price")
	GameState.material_metrics["delivered_today"]=5.0
	GameState.elapsed_days=5.0
	EconomySystem.process_day()
	_check(is_zero_approx(float(GameState.economy_metrics.price_index)),"unmeasured reciprocal exchange was mislabeled as a market price")
	_check(GameState.market_prices.is_empty(),"founding society received hidden market quotes before it could record comparable exchange")
	GameState.discovery_adoption["standard_measures"]=0.20
	GameState.discovery_adoption["tallies"]=0.20
	GameState.elapsed_days=6.0
	EconomySystem.process_day()
	_check(float(GameState.economy_metrics.price_index)>0.0,"shared measures and a physical exchange produced no recorded comparison value")

func _test_foreign_trade_requires_contract()->void:
	_base_state()
	GameState.economy_stage=EconomySystem.STAGE_METAL
	GameState.external_trade_policy="balanced"
	GameState.resource_stockpiles["Timber"]=800.0
	GameState.resource_stockpiles["Fiber Plants"]=0.0
	var no_contract:=EconomySystem._process_external_trade(0.90,100.0,0)
	_check(is_zero_approx(float(no_contract.exports)) and is_zero_approx(float(no_contract.imports)),"foreign goods moved without an emissary-established contract")
	_check(not bool(no_contract.available),"foreign trade was advertised without a real counterpart")

func _test_water_is_consumed()->void:
	_base_state()
	GameState.resource_deposits=[]
	GameState.resource_stockpiles["Freshwater"]=120.0
	ResourceSystem.process_day({})
	_check(is_zero_approx(float(GameState.resource_stockpiles.Freshwater)),"daily drinking water was not removed from stores")
	_check(is_equal_approx(float(GameState.water_metrics.consumed_today),120.0),"water demand did not follow population")

func _test_visible_surface_water_sustains_founders()->void:
	_base_state()
	GameState.resource_deposits=[]
	GameState.resource_stockpiles["Freshwater"]=0.0
	GameState.water_metrics={}
	var opening_access:=ResourceSystem.water_access_snapshot({"surface_water_distance_km":5.5,"surface_water_recognized":true})
	_check(bool(opening_access.recognized) and bool(opening_access.accessible),"charted founding hydrology was absent before the first simulation tick")
	var minimum_intake:=1.0
	for day in range(1,25):
		GameState.elapsed_days=float(day)
		ResourceSystem.process_day({"origin":Vector3.ZERO,"surface_water_distance_km":5.5})
		minimum_intake=minf(minimum_intake,float(GameState.water_metrics.intake_ratio))
	_check(minimum_intake>=0.98,"founders beside visible surface water suffered a drinking-water shortfall")
	_check(String(GameState.water_metrics.source_kind)=="visible river or drainage","rendered hydrology was not recorded as the drinking-water source")
	_check(float(GameState.water_metrics.source_distance_km)==5.5,"water source distance was not preserved for player-facing causality")
	var access:=ResourceSystem.water_access_snapshot()
	_check(bool(access.recognized) and String(access.source_origin)=="mapped_hydrology","visible hydrology was not exposed as a recognized geographic source")
	_check(String(access.source_id)=="local_surface_hydrology","river access depended on an arbitrary point deposit")
	_check(bool(access.supports_drinking) and bool(access.supports_food_gathering),"recognized river access did not propagate into survival and food capabilities")

func _test_storage_has_physical_source()->void:
	_base_state()
	var capacities:=ResourceSystem.storage_capacities()
	_check(is_equal_approx(float(capacities.dry),float(GameState.founding_manifest.dry_storage_bulk)),"dry storage appeared outside the founding manifest")
	_check(float(capacities.sealed)>0.0 and float(capacities.secure)>0.0,"portable storage assets were not explicit")

func _check(condition:bool,message:String)->void:
	if not condition: failures.append(message)
