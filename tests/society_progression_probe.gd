extends Node

func _ready()->void:
	GameState.world_seed=24681357
	GameState.elapsed_days=0.0
	GameState.initialize_citizen_registry()
	GameState.population_health=0.78
	GameState.food_security=0.82
	GameState.housing_capacity=140
	GameState.settlement_site_committed=true
	GameState.known_discoveries=[]
	GameState.discovery_log=[]
	GameState.discovery_adoption={}
	GameState.knowledge_effects={}
	GameState.society_capacities={}
	var able:=GameState.able_population()
	GameState.population_allocation_percentages={"Food":32.0,"Survey":6.0,"Extraction":10.0,"Construction":9.0,"Crafting":8.0,"Logistics":7.0,"Knowledge":18.0,"Administration":6.0,"Defense":4.0}
	GameState.population_allocations={"Food":roundi(able*0.32),"Survey":roundi(able*0.06),"Extraction":roundi(able*0.10),"Construction":roundi(able*0.09),"Crafting":roundi(able*0.08),"Logistics":roundi(able*0.07),"Knowledge":roundi(able*0.18),"Administration":roundi(able*0.06),"Defense":0}
	var used:=0
	for allocation in GameState.population_allocations.values(): used+=int(allocation)
	GameState.population_allocations["Defense"]=maxi(0,able-used)
	GameState.research_allocations={"demography":1,"nutrition":1,"health":1,"labor":1,"knowledge":1,"production":1,"infrastructure":1,"logistics":1,"ecology":1,"institutions":1,"security":1,"culture":1}
	for dynamic_id in GameState.research_subcategory_allocations:
		var first:=true
		for subcategory in GameState.research_subcategory_allocations[dynamic_id]:
			GameState.research_subcategory_allocations[dynamic_id][subcategory]=1 if first else 0
			first=false
	GameState.simulation_metrics={"health":0.78,"knowledge":0.38,"cohesion":0.67,"ecology":0.79,"security":0.55,"legitimacy":0.66,"food_diet_quality":0.68,"material_capacity":0.50,"logistics":0.44,"labor_efficiency":0.74}
	GameState.resource_deposits=[]
	GameState.resource_stockpiles={}
	ResourceSystem.initialize()
	for resource_name in ResourceSystem.catalog:
		GameState.resource_deposits.append({"resource":resource_name,"stage":"developed","lifetime_extracted":500.0})
		GameState.resource_stockpiles[resource_name]=250.0
	DiscoverySystem.initialized=false
	DiscoverySystem.catalog.resize(24)
	DiscoverySystem.initialize()
	DiscoverySystem.reset_society_clock()
	var errors:=DiscoverySystem.validate_catalog()
	if not errors.is_empty(): return _fail("catalog contract: %s" % "; ".join(errors))
	var checkpoints:Dictionary={}
	var context={"food":1.0,"nature":0.9,"administration":0.8,"storage":0.8,"construction":0.8,"health":0.8,"population":0.7,"freshwater":1.0,"illness":0.25,"education":0.65,"information":0.8,"materials":0.9,"crafting":0.85,"fiber":0.8,"timber":0.8,"stone":0.8,"fire":0.7,"trade":0.6,"travel":0.7,"logistics":0.7,"survey":0.7,"exploration":0.6,"defense":0.5,"danger":0.2,"training":0.5,"law":0.6,"water":0.8,"injury":0.15,"warfare":0.4,"infrastructure":0.6,"sustenance":0.9,"coal":0.6,"salt":0.6,"clay":0.7}
	if "--capacity" in OS.get_cmdline_user_args():
		GameState.elapsed_days=1.0
		DiscoverySystem.process_day(context)
		print("CAPACITY_PROBE ",JSON.stringify({"population":GameState.population_exact,"allocations":GameState.population_allocations,"inquiry":GameState.research_allocations,"metrics":GameState.simulation_metrics,"capacities":GameState.society_capacities}))
		get_tree().quit(0)
		return
	for day in range(1,73001):
		GameState.elapsed_days=float(day)
		DiscoverySystem.process_day(context)
		if day==365 and "--year" in OS.get_cmdline_user_args():
			print("YEAR_CAPACITY_PROBE ",JSON.stringify({"allocations":GameState.population_allocations,"inquiry":GameState.research_allocations,"effects":GameState.knowledge_effects,"capacities":GameState.society_capacities}))
			get_tree().quit(0)
			return
		if day in [365,3650,9125,18250,36500,73000]:
			checkpoints[day/365]={"discoveries":GameState.known_discoveries.size(),"mind":GameState.combined_intelligence,"effects":GameState.knowledge_effects.size()}
	for value in GameState.discovery_adoption.values():
		if float(value)<0.0 or float(value)>1.0: return _fail("adoption escaped bounds")
	for value in GameState.society_capacities.values():
		if float(value)<0.0 or float(value)>1.15: return _fail("capacity escaped bounds")
	if GameState.society_subcategories.size()!=12: return _fail("society dashboard did not expose all twelve dynamics")
	for dynamic_id in GameState.society_subcategories:
		var subcategories:Dictionary=GameState.society_subcategories[dynamic_id]
		if subcategories.size()!=4: return _fail("%s did not expose four causal subcategories" % dynamic_id)
		for value in subcategories.values():
			if float(value)<0.0 or float(value)>1.0: return _fail("%s subcategory escaped bounds" % dynamic_id)
	var at_25:int=int((checkpoints[25] as Dictionary).discoveries)
	var at_200:int=int((checkpoints[200] as Dictionary).discoveries)
	if at_25<18: return _fail("progression stalled: only %d discoveries by year 25" % at_25)
	if at_25>100: return _fail("progression exhausted too early: %d discoveries by year 25" % at_25)
	if at_200<70: return _fail("two-century possibility space too sparse: %d" % at_200)
	print("SOCIETY_PROGRESSION ",JSON.stringify(checkpoints))
	print("SOCIETY_PROGRESSION_PASS discoveries=%d/%d" % [at_200,DiscoverySystem.catalog.size()])
	get_tree().quit(0)

func _fail(message:String)->void:
	push_error("SOCIETY_PROGRESSION_FAIL "+message)
	get_tree().quit(1)
