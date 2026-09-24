extends Node
## Multi-decade early-game probe: sensible, poor and health/food-focused play on
## disposable actors. Prints checkpoint rows; asserts only finite invariants.
## Usage: Godot --headless --path <worktree> res://tests/early_consequences_probe.tscn -- [--years=N] [--seeds=a,b] [--scenarios=a,b,c]
const Day=preload("res://scripts/civilization_day.gd")
const Indicators=preload("res://scripts/civilization_indicators.gd")
const CHECKPOINT_YEARS:Array[int]=[1,2,3,5,10,15,20,25,30,35,40,50,60,75,100]
const DOMAINS:Array[String]=["demography","nutrition","health","labor","knowledge","production","infrastructure","logistics","ecology","institutions","security","culture"]
var failures:Array[String]=[]

func _scenarios()->Dictionary:
	return {
		"sensible":{"site":"good","focus":"","policies":[],"research":{"demography":2,"nutrition":3,"health":3,"labor":2,"knowledge":2,"production":3,"infrastructure":2,"logistics":1,"ecology":1,"institutions":1,"security":1,"culture":1}},
		"poor":{"site":"poor","focus":"development","policies":["foraging_drive","labor_mobilization"],"research":{"demography":0,"nutrition":0,"health":0,"labor":2,"knowledge":5,"production":6,"infrastructure":2,"logistics":1,"ecology":0,"institutions":2,"security":5,"culture":1}},
		# A grown agricultural town (save-compatibility / mid-game scale check).
		"town":{"site":"good","focus":"","policies":[],"population":2400,"known":["seed_selection","crop_calendars","smoking","wound_cleaning","herbal_classification","clean_water","birth_attendants","labor_rotations","shared_childcare","hearth_roasting_control","drainage","well_siting","tallies","public_stores"],"research":{"demography":2,"nutrition":3,"health":3,"labor":2,"knowledge":2,"production":3,"infrastructure":2,"logistics":1,"ecology":1,"institutions":1,"security":1,"culture":1}},
		# An AI ruler: the ordinary rival controller chooses research and orders.
		"ai":{"site":"good","focus":"","policies":[],"ai":true,"research":{}},
		"focused":{"site":"good","focus":"","policies":[],"targets":["wound_cleaning","herbal_classification","clean_water","birth_attendants","shared_childcare","labor_rotations","hearth_roasting_control","smoking","food_pounding_mortars","earth_oven_cooking","maternal_recovery","well_siting","drainage","public_stores"],"research":{"demography":4,"nutrition":6,"health":6,"labor":2,"knowledge":2,"production":3,"infrastructure":2,"logistics":1,"ecology":1,"institutions":1,"security":0,"culture":0}},
		# Same emphasis, but also moves labor into research (settlement focus).
		"scholars":{"site":"good","focus":"research","policies":[],"targets":["wound_cleaning","herbal_classification","clean_water","birth_attendants","shared_childcare","labor_rotations","hearth_roasting_control","smoking","food_pounding_mortars","earth_oven_cooking","maternal_recovery","well_siting","drainage","public_stores"],"research":{"demography":4,"nutrition":6,"health":6,"labor":2,"knowledge":2,"production":3,"infrastructure":2,"logistics":1,"ecology":1,"institutions":1,"security":0,"culture":0}},
	}

func _site_profile(origin:Vector2,site:String)->Dictionary:
	var profile:Dictionary=PlanetEnvironment.profile_at(origin).duplicate(true)
	if site=="poor":
		profile.merge({"forage":0.26,"game":0.22,"fertility":0.22,"growing_season":0.34,"water_access":0.12,"rainfall_variability":0.62,"precipitation":0.30},true)
	else:
		profile.merge({"forage":0.62,"game":0.52,"fertility":0.58,"growing_season":0.62,"water_access":0.62,"rainfall_variability":0.30,"precipitation":0.55},true)
	return profile

func _arg(name:String,fallback:String)->String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--%s=" % name):return arg.substr(name.length()+3)
	return fallback

func _ready()->void:
	var years:=int(_arg("years","100"))
	preload("res://scripts/early_life_conditions.gd").legacy_comparison="--legacy" in OS.get_cmdline_user_args()
	var seeds:Array[int]=[]
	for part in _arg("seeds","74119").split(","):seeds.append(int(part))
	var wanted:=_arg("scenarios","sensible,poor,focused").split(",")
	var scenarios:=_scenarios()
	for scenario_name in wanted:
		for seed_value in seeds:
			await _run(scenario_name,scenarios[scenario_name],seed_value,years)
	WorldSimulation.clear()
	print("EC_FAILURES ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)

func _run(scenario_name:String,scenario:Dictionary,seed_value:int,years:int)->void:
	WorldSimulation.clear()
	var site:=String(scenario.site)
	var water_km:=2.2 if site=="poor" else 0.2
	WorldSimulation.context_provider=func(origin:Vector2)->Dictionary:
		var wood:={"position":Vector3(origin.x,0,origin.y),"density":0.55,"area_km2":9.0}
		return {"environment_profile":_site_profile(origin,site),"surface_water_distance_km":water_km,"surface_water_recognized":true,"woodland_catchment":wood,"surface_material_catchments":{"Timber":wood,"Stone":{"position":Vector3(origin.x,0,origin.y),"density":0.35,"area_km2":9.0},"Fiber Plants":{"position":Vector3(origin.x,0,origin.y),"density":0.5,"area_km2":9.0}}}
	WorldSimulation.create_actor("ec",seed_value,Vector2.ZERO)
	WorldSimulation.enabled=true
	WorldSimulation.scoped("ec",func()->void:
		WorldSimulation.state.ensure_population_total(int(scenario.get("population",120)))
		for id:String in scenario.get("known",[]):
			if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
		WorldSimulation.world.scout_land_authority=func(_p:Vector2)->bool:return true
	)
	WorldSimulation.submit("ec",{"kind":"ambition","id":"makers"})
	var founded:=WorldSimulation.submit("ec",{"kind":"found"})
	if founded.has("error"):failures.append("%s/%d found: %s" % [scenario_name,seed_value,str(founded)])
	var research:Dictionary=scenario.research
	for domain in DOMAINS if not bool(scenario.get("ai",false)) else []:WorldSimulation.submit("ec",{"kind":"research_emphasis","domain":domain,"weight":int(research.get(domain,0))})
	var start_population:=int(scenario.get("population",120))
	var tally:={"shortage_days":0,"shortage_episodes":0,"in_shortage":false,"hunger_days":0,"min_intake":1.0,"peak_population":start_population,"min_population":start_population}
	var start:=Time.get_ticks_msec()
	for day in range(1,years*365+1):
		WorldSimulation.scoped("ec",func()->void:
			var state:=WorldSimulation.state
			state.elapsed_days=day
			if day%30==1:
				# The primary record appears once the hearth is built; keep its measured
				# site profile on the scenario's ground.
				for index in state.player_settlements.size():
					state.player_settlements[index]["environment_profile"]=_site_profile(Vector2.ZERO,site)
			if String(scenario.focus)!="" and day%30==2:
				for city:Dictionary in state.player_settlements:
					if bool(city.get("primary",false)) and bool(city.get("auto_manage",true)):WorldSimulation.government.set_settlement_focus(String(city.id),String(scenario.focus))
			if day%30==4:
				# A health-minded ruler points investigators at specific care practices.
				var claimed:Dictionary={}
				for id:String in scenario.get("targets",[]):
					if id in state.known_discoveries:continue
					var entry:Dictionary=WorldSimulation.discovery.discovery_definition(id)
					if entry.is_empty():continue
					var channel:="%s::%s" % [String(entry.get("dynamic","")),String(entry.get("subcategory",""))]
					if claimed.has(channel):continue
					if bool(WorldSimulation.discovery.select_research_target(id).get("ok",false)):claimed[channel]=true
			for policy_id:String in scenario.policies:
				if day%120==3:WorldSimulation.consequences.apply_policy(policy_id,0.18,120.0,"probe")
			if bool(scenario.get("ai",false)):preload("res://scripts/civilization_controller.gd").choose_orders("ec")
			Day.advance(day,Day.context(Vector2.ZERO))
			var metrics:Dictionary=state.simulation_metrics
			var intake:=float(metrics.get("food_intake_ratio",1.0))
			var short:=intake<0.95
			if short:
				tally.shortage_days=int(tally.shortage_days)+1
				if not bool(tally.in_shortage):tally.shortage_episodes=int(tally.shortage_episodes)+1
			tally.in_shortage=short
			if float((metrics.get("mortality_components",{}) as Dictionary).get("Hunger",0.0))>0.004:tally.hunger_days=int(tally.hunger_days)+1
			tally.min_intake=minf(float(tally.min_intake),intake)
			tally.peak_population=maxi(int(tally.peak_population),state.population_total)
			tally.min_population=mini(int(tally.min_population),state.population_total)
			if day%365==0 and int(day/365.0) in CHECKPOINT_YEARS:_checkpoint(scenario_name,seed_value,int(day/365.0),tally,start)
		)
		if day%60==0:await get_tree().process_frame
	WorldSimulation.scoped("ec",func()->void:
		var state:=WorldSimulation.state
		if state.population_total<=0:failures.append("%s/%d died out" % [scenario_name,seed_value])
		for key in ["food_days","food_intake_ratio"]:
			var amount:=float(state.simulation_metrics.get(key,-1))
			if not is_finite(amount) or amount<0:failures.append("Invalid %s: %s/%d" % [key,scenario_name,seed_value])
		if not is_finite(state.projected_life_expectancy()):failures.append("Invalid life expectancy %s/%d" % [scenario_name,seed_value])
	)

func _checkpoint(scenario_name:String,seed_value:int,year:int,tally:Dictionary,start:int)->void:
	var state:=WorldSimulation.state
	var metrics:Dictionary=state.simulation_metrics
	var known:Array=state.known_discoveries
	var health_known:=0
	var food_known:=0
	for id:String in known:
		var entry:Dictionary=WorldSimulation.discovery.discovery_definition(id)
		var dynamic:=String(entry.get("dynamic",""))
		if dynamic in ["health","demography"]:health_known+=1
		elif dynamic=="nutrition":food_known+=1
	var care_source:Dictionary=state.early_care
	var care:Dictionary={}
	for key:String in ["under5","child","adult","neonatal","maternal","conception","diet","overwork","infant_loss"]:care[key]=snappedf(float(care_source.get(key,1.0)),0.001)
	for category:Dictionary in care_source.get("categories",[]):care[String(category.id)]=snappedf(float(category.coverage),0.01)
	var harvest:Dictionary={}
	var raw_harvest:Dictionary=metrics.get("food_harvest",{})
	for key:String in raw_harvest:harvest[key]=snappedf(float(raw_harvest[key]),0.1)
	var capacity:Dictionary={}
	var raw_capacity:Dictionary=WorldSimulation.food.wild_food_capacity()
	for key:String in raw_capacity:capacity[key]=snappedf(float((raw_capacity[key] as Dictionary).rations),0.1)
	if "--debug-research" in OS.get_cmdline_user_args():
		print("EC_RESEARCH ",JSON.stringify({"year":year,"active":state.active_investigations,"progress":state.discovery_progress,"allocations":state.research_subcategory_allocations,"knowledge_workers":state.effective_workers("Knowledge"),"known":state.known_discoveries}))
	print("EC_ROW ",JSON.stringify({
		"scenario":scenario_name,"legacy":preload("res://scripts/early_life_conditions.gd").legacy_comparison,"seed":seed_value,"year":year,"population":state.population_total,
		"life_expectancy":snappedf(state.projected_life_expectancy(),0.1),
		"infant_mortality":snappedf(Indicators.infant_mortality_per_1000(state,WorldSimulation.discovery),0.1),
		"health":snappedf(state.population_health,0.001),"food_security":snappedf(state.food_security,0.001),
		"food_days":snappedf(float(metrics.get("food_days",0)),0.1),"diet":snappedf(float(state.food_history[-1].get("diet_quality",0)) if not state.food_history.is_empty() else 0.0,0.001),
		"malnutrition":snappedf(state.malnutrition_burden,0.001),"births":state.lifetime_births,"deaths":state.lifetime_deaths,
		"neonatal":state.lifetime_neonatal_deaths,"maternal":state.lifetime_maternal_deaths,
		"shortage_days":tally.shortage_days,"shortage_episodes":tally.shortage_episodes,"hunger_days":tally.hunger_days,"min_intake":snappedf(float(tally.min_intake),0.001),
		"peak":tally.peak_population,"min":tally.min_population,"discoveries":known.size(),"health_known":health_known,"food_known":food_known,
		"food_share":snappedf(float(state.population_allocation_percentages.get("Food",0)),0.1),"source_health":state.food_source_health,
		"care":care,"harvest":harvest,"capacity":capacity,"need":snappedf(float(metrics.get("food_consumption",0)),0.1),"seconds":(Time.get_ticks_msec()-start)/1000
	}))
