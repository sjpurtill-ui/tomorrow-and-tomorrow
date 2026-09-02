extends Node

func _settlement_model() -> Node:
	return get_node("/root/SettlementModel")

func _food_system() -> Node:
	return get_node("/root/FoodSystem")

func _ready()->void:
	call_deferred("_run")

func _run()->void:
	var args:=OS.get_cmdline_user_args()
	var scenario:="haul"
	if "--no-haul" in args: scenario="no-haul"
	elif "--overflow" in args: scenario="overflow"
	elif "--far" in args: scenario="far"
	elif "--knowledge" in args: scenario="knowledge"
	elif "--restart" in args: scenario="restart"
	_reset_state()
	if scenario=="restart":
		_reset_world_systems(13579)
		ConsequenceEngine.initialize()
		DiscoverySystem.initialize()
		var first_cohorts:Dictionary=GameState.population_cohorts.duplicate(true)
		var first_catalog_count:int=DiscoverySystem.catalog.size()
		GameState.elapsed_days=818.5
		GameState.known_discoveries=["cordage","basketry"]
		GameState.society_subcategories={"old world":{"ghost":1.0}}
		GameState.resource_stockpiles={"Timber":999.0}
		GameState.council_inbox=[{"text":"old world"}]
		GameState.lifetime_deaths=17
		_reset_world_systems(13579)
		ConsequenceEngine.initialize()
		var repeated_cohorts:Dictionary=GameState.population_cohorts.duplicate(true)
		if first_cohorts!=repeated_cohorts: return _fail("same seed did not reproduce the aggregate population state")
		if GameState.elapsed_days!=0.0 or not GameState.known_discoveries.is_empty() or not GameState.society_subcategories.is_empty() or not GameState.council_inbox.is_empty() or GameState.lifetime_deaths!=0: return _fail("old-world simulation state survived restart")
		DiscoverySystem.initialize()
		if DiscoverySystem.catalog.size()!=first_catalog_count or first_catalog_count<100: return _fail("discovery catalog duplicated or failed to restore after restart: %d then %d entries" % [first_catalog_count,DiscoverySystem.catalog.size()])
		_reset_world_systems(24680)
		ConsequenceEngine.initialize()
		if GameState.world_seed!=24680: return _fail("new world seed did not replace the prior world identity")
		if GameState.population_cohorts!=first_cohorts: return _fail("world identity distorted the requested aggregate starting population")
		print("RESTART_PROBE ",JSON.stringify({"same_seed_repeatable":true,"new_world_identity":true,"day":GameState.elapsed_days,"population":GameState.population_total}))
		return _pass(scenario)
	if scenario=="knowledge":
		DiscoverySystem.initialize()
		var validation_errors:Array[String]=DiscoverySystem.validate_catalog()
		if not validation_errors.is_empty(): return _fail("knowledge catalog contract errors: %s" % "; ".join(validation_errors))
		var all_ids:Dictionary={}
		var direction_counts:Dictionary={}
		for discovery in DiscoverySystem.catalog:
			all_ids[String(discovery.id)]=true
			direction_counts[String(discovery.direction)]=int(direction_counts.get(String(discovery.direction),0))+1
		for direction in GameState.research_allocations:
			if int(direction_counts.get(direction,0))<80: return _fail("thin discovery frontier for %s" % direction)
		for discovery in DiscoverySystem.catalog:
			for requirement in discovery.get("requires",[]):
				if not all_ids.has(String(requirement)): return _fail("unknown discovery prerequisite %s for %s" % [requirement,discovery.id])
		var copper_definition:=DiscoverySystem.discovery_definition("copper_smelting")
		if DiscoverySystem._resource_requirements_met(copper_definition.resource_requirements): return _fail("copper knowledge was eligible without copper")
		var copper:=ResourceSystem._deposit("Copper Ore",Vector3(4,0,0),1.0,2000.0,0)
		copper.stage="accessible"
		GameState.resource_deposits=[copper]
		if not DiscoverySystem._resource_requirements_met(copper_definition.resource_requirements): return _fail("accessible copper did not satisfy copper knowledge")
		GameState.resource_deposits=[]
		GameState.elapsed_days=100.0
		GameState.research_allocations={"demography":0,"nutrition":1,"health":0,"labor":0,"knowledge":0,"production":0,"infrastructure":0,"logistics":0,"ecology":0,"institutions":0,"security":0,"culture":0}
		for dynamic_id in GameState.research_subcategory_allocations:
			for subcategory in GameState.research_subcategory_allocations[dynamic_id]: GameState.research_subcategory_allocations[dynamic_id][subcategory]=0
		GameState.research_subcategory_allocations.nutrition["Daily supply"]=1
		DiscoverySystem.refresh_investigations()
		var first_investigation:=String(GameState.active_investigations.get("nutrition::Daily supply",""))
		if first_investigation=="": return _fail("assigned inquiry direction did not begin an eligible investigation")
		GameState.known_discoveries.append(first_investigation)
		DiscoverySystem.refresh_investigations()
		var next_investigation:=String(GameState.active_investigations.get("nutrition::Daily supply",""))
		if next_investigation=="" or next_investigation==first_investigation: return _fail("completed investigation did not yield a new inquiry")
		GameState.known_discoveries=["copper_smelting","woven_carriers"]
		DiscoverySystem.reset_society_clock()
		DiscoverySystem.society_model.process_day(DiscoverySystem.catalog,{"materials":1.0,"crafting":1.0,"fiber":1.0,"travel":1.0})
		if DiscoverySystem.effect("tool_quality")<=0.0 or DiscoverySystem.effect("haul_capacity")<=0.0: return _fail("known practices produced no cross-system effects")
		print("RESOURCE_PROBE ",JSON.stringify({"scenario":scenario,"possibilities":DiscoverySystem.catalog.size(),"tool_effect":DiscoverySystem.effect("tool_quality"),"haul_effect":DiscoverySystem.effect("haul_capacity")}))
		return _pass(scenario)
	if scenario=="overflow":
		GameState.resource_stockpiles={"Food":3600.0,"Timber":1200.0}
		ResourceSystem.process_day({"origin":Vector3.ZERO,"tools":0.35,"settled":true})
		var lost:=float(GameState.material_metrics.get("lost_today",0.0))
		print("RESOURCE_PROBE ",JSON.stringify({"scenario":scenario,"lost":lost,"stored":GameState.resource_stockpiles.get("Timber",0.0)}))
		if lost<=1.0: return _fail("overflowing an open yard caused no material loss")
		return _pass(scenario)
	var distance:=60.0 if scenario=="far" else 8.0
	var deposit:=ResourceSystem._deposit("Timber",Vector3(distance,0,0),1.0,10000.0,0)
	deposit.stage="accessible"
	deposit.route=1.0
	GameState.resource_deposits=[deposit]
	GameState.population_allocations["Extraction"]=12
	GameState.population_allocations["Logistics"]=0 if scenario=="no-haul" else 12
	var stored_before:=float(GameState.resource_stockpiles.get("Timber",0.0))
	var days:=50 if scenario!="far" else 90
	for day in days:
		GameState.elapsed_days=float(day)
		ResourceSystem.process_day({"origin":Vector3.ZERO,"tools":0.45,"settled":true})
	var source:=float(deposit.stock_at_source)
	var moving:=ResourceSystem.in_transit_for(deposit)
	var stored:=float(GameState.resource_stockpiles.get("Timber",0.0))
	print("RESOURCE_PROBE ",JSON.stringify({"scenario":scenario,"source":source,"moving":moving,"stored":stored,"extracted":deposit.lifetime_extracted,"delivered":deposit.lifetime_delivered,"travel_days":deposit.travel_days}))
	if scenario=="no-haul":
		if source<=1.0 or stored>stored_before+0.01: return _fail("material moved without carriers or failed to accumulate at source")
	elif scenario=="haul":
		if stored<=1.0 or float(deposit.lifetime_delivered)<=1.0: return _fail("nearby hauled material never reached storage")
		if int(deposit.travel_days)<1: return _fail("shipment had no travel time")
	else:
		if int(deposit.travel_days)<5: return _fail("distant shipment travel time is implausibly short")
		if moving<=5.0: return _fail("distance did not create a meaningful in-transit inventory")
	_pass(scenario)

func _reset_state()->void:
	GameState.world_seed=90210
	GameState.elapsed_days=0.0
	GameState.population_exact=120.0
	GameState.population_total=120
	GameState.resource_deposits.clear()
	GameState.resource_stockpiles.clear()
	GameState.resource_events.clear()
	GameState.resource_practice.clear()
	GameState.resource_priorities.clear()
	GameState.material_history.clear()
	GameState.known_discoveries.clear()
	GameState.settlement_completed.clear()
	GameState.settlement_site_committed=true
	GameState.settlement_founded_at=Vector3.ZERO
	GameState.population_allocations={"Food":30,"Survey":6,"Extraction":8,"Construction":8,"Crafting":5,"Logistics":5,"Knowledge":4,"Administration":3,"Defense":3}
	GameState.simulation_metrics={"labor_efficiency":0.78,"material_capacity":0.18,"knowledge":0.18}
	ResourceSystem.initialized=false
	DiscoverySystem.reset_for_new_world()
	ResourceSystem.initialize()

func _reset_world_systems(new_seed:int)->void:
	GameState.reset_for_new_world(new_seed)
	DiscoverySystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	_settlement_model().reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	_food_system().reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	WorldFacts.reset_for_new_world()

func _fail(message:String)->void:
	push_error("Resource flow regression: "+message)
	get_tree().quit(1)

func _pass(scenario:String)->void:
	print("RESOURCE_FLOW_PASS ",scenario)
	get_tree().quit(0)
