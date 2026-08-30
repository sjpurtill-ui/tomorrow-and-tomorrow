extends Node

var failures:Array[String]=[]

func _ready()->void:
	for population in [24,120,1200]:
		_run_scale(population)
	if not failures.is_empty():
		for failure in failures: push_error("Economy scale regression: "+failure)
		get_tree().quit(1)
		return
	print("ECONOMY_SCALE_PASS populations=24,120,1200")
	get_tree().quit(0)

func _run_scale(population:int)->void:
	GameState.reset_for_new_world(91000+population)
	FoodSystem.reset_for_new_world()
	EconomySystem.reset_for_new_world()
	GameState.population_total=population
	GameState.population_exact=float(population)
	GameState.citizen_registry=[]
	GameState.citizen_registry_initialized=false
	GameState.initialize_citizen_registry()
	GameState.synchronize_population_allocations()
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.water_metrics={"intake_ratio":1.0,"source_accessible":true,"days":3.0}
	GameState.housing_capacity=population
	GameState.external_trade_policy="closed"
	GameState.simulation_metrics={"food_days":40.0,"food_consumption":float(population),"food_eaten":float(population),"food_intake_ratio":1.0,"food_production":float(population)*1.05,"logistics":0.52,"legitimacy":0.74,"storage_function":0.65}
	GameState.society_capacities={"production":0.50,"institutions":0.52,"logistics":0.52}
	GameState.material_metrics={"delivered_today":float(population)*0.10,"lost_today":0.0}
	GameState.discovery_adoption["tallies"]=0.75
	GameState.discovery_adoption["standard_measures"]=0.75
	GameState.discovery_adoption["copper_smelting"]=0.75
	var efficiency:=EconomySystem._metal_processing_efficiency()
	var raw_metal:=EconomySystem.currency_metal_requirement()/maxf(0.01,efficiency)*1.25
	GameState.resource_stockpiles={"Food":float(population)*40.0,"Timber":float(population)*2.0,"Stone":float(population)*1.6,"Clay":float(population)*0.65,"Fiber Plants":float(population)*0.65,"Copper Ore":raw_metal,"Tin Ore":0.0,"Iron Ore":0.0}
	GameState.elapsed_days=1.0
	EconomySystem.process_day()
	_expect(GameState.economy_stage==EconomySystem.STAGE_METAL,"population %d failed its scaled metal benchmark" % population)
	var circulating_metal_per_person:=GameState.weighed_metal_circulation/maxf(1.0,GameState.population_exact)
	_expect(circulating_metal_per_person>=0.075 and circulating_metal_per_person<=0.09,"population %d received distorted weighed-metal liquidity %.3f per person" % [population,circulating_metal_per_person])
	GameState.elapsed_days=2.0
	EconomySystem.process_day()
	_expect(GameState.economy_stage==EconomySystem.STAGE_CURRENCY,"population %d failed its scaled currency benchmark" % population)
	var supply_per_person:=GameState.currency_supply/maxf(1.0,GameState.population_exact)
	var reserve_per_person:=EconomySystem._monetary_reserve_value()/maxf(1.0,GameState.population_exact)
	_expect(supply_per_person>=0.70 and supply_per_person<=0.80,"population %d received a distorted per-person founding issue %.3f" % [population,supply_per_person])
	_expect(reserve_per_person>=0.32 and reserve_per_person<=0.43,"population %d received a distorted per-person reserve %.3f" % [population,reserve_per_person])
	for day in range(3,368):
		GameState.elapsed_days=float(day)
		GameState.resource_stockpiles["Food"]=maxf(float(GameState.resource_stockpiles.get("Food",0.0)),float(population)*40.0)
		EconomySystem.process_day()
	_expect(bool(EconomySystem.accounting_audit().ok),"population %d failed accounting after one scaled year" % population)
	_expect(GameState.currency_supply<=EconomySystem._monetary_reserve_value()*2.5+0.001,"population %d exceeded its scaled reserve ceiling" % population)
	_expect(float(GameState.economy_metrics.price_index)>0.25 and float(GameState.economy_metrics.price_index)<3.5,"population %d price level escaped broad scale bounds" % population)

func _expect(condition:bool,message:String)->void:
	if not condition: failures.append(message)
