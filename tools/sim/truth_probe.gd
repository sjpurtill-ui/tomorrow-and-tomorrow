extends Node
## Ground-truth recorder for the Python surrogate (tools/sim/calibrate.py).
## Runs the REAL daily engine headless on a disposable actor (same harness as
## tests/early_consequences_probe.gd) and writes one small JSON file per run:
## a row per game year plus every discovery with its day, artifact finds and
## study progress. Never launches or touches the player's game.
## Usage:
##   Godot --headless --path <worktree> res://tools/sim/truth_probe.tscn -- --scenario=sensible --seed=74119 --years=100 --out=<file.json>
const Day=preload("res://scripts/civilization_day.gd")
const Indicators=preload("res://scripts/civilization_indicators.gd")
const DOMAINS:Array[String]=["demography","nutrition","health","labor","knowledge","production","infrastructure","logistics","ecology","institutions","security","culture"]
const ROLES:Array[String]=["Food","Survey","Extraction","Construction","Crafting","Logistics","Knowledge","Administration","Defense"]

## Scenario knobs mirror tools/sim/scenarios.json (the surrogate's policies).
func _scenarios()->Dictionary:
	var sensible_research:={"demography":2,"nutrition":3,"health":3,"labor":2,"knowledge":2,"production":3,"infrastructure":2,"logistics":1,"ecology":1,"institutions":1,"security":1,"culture":1}
	return {
		"sensible":{"site":"good","focus":"","policies":[],"research":sensible_research},
		"poor":{"site":"poor","focus":"development","policies":["foraging_drive","labor_mobilization"],"research":{"demography":0,"nutrition":0,"health":0,"labor":2,"knowledge":5,"production":6,"infrastructure":2,"logistics":1,"ecology":0,"institutions":2,"security":5,"culture":1}},
		"research":{"site":"good","focus":"research","policies":[],"research":{"demography":1,"nutrition":2,"health":2,"labor":1,"knowledge":8,"production":4,"infrastructure":1,"logistics":1,"ecology":1,"institutions":3,"security":0,"culture":2}},
		"ai":{"site":"good","focus":"","policies":[],"ai":true,"research":{}},
		# Sensible play plus scouting parties and the artifact-study role. A small
		# legendary set is also placed in the collection at day 400 so study pace
		# is measured even if the headless ground yields few finds.
		"artifacts":{"site":"good","focus":"","policies":[],"research":sensible_research,"scouting":0.05,"study_weight":2,"seed_finds":400},
	}

func _site_profile(origin:Vector2,site:String)->Dictionary:
	var profile:Dictionary=PlanetEnvironment.profile_at(origin).duplicate(true)
	if site=="poor":
		profile.merge({"forage":0.26,"game":0.22,"fertility":0.22,"growing_season":0.34,"water_access":0.12,"rainfall_variability":0.62,"precipitation":0.30},true)
	else:
		profile.merge({"forage":0.62,"game":0.52,"fertility":0.58,"growing_season":0.62,"water_access":0.62,"rainfall_variability":0.30,"precipitation":0.55},true)
	return profile

## Deterministic surveyed ground for scouting parties (headless worlds have no
## terrain). Varies smoothly so river/coast/stone cells occur at plausible rates.
func _ground(position:Vector2,site:String)->Dictionary:
	var a:=sin(position.x/41.0)*cos(position.y/57.0)
	var b:=sin((position.x+position.y)/83.0)
	var profile:=_site_profile(position,site)
	profile.merge({"biome":"grassland","river_distance_km":absf(a)*24.0,"coastal":b>0.92,"stone":0.35+0.3*b,"slope":0.06+0.08*absf(a),
		"relief":0.2*a,"resource_potentials":{"Clay":0.5,"Stone":0.5,"Timber":0.55,"Fiber Plants":0.5,"Flint":0.4,"Copper Ore":0.3+0.2*b}},true)
	return profile

func _arg(name:String,fallback:String)->String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--%s=" % name):return arg.substr(name.length()+3)
	return fallback

func _ready()->void:
	var scenario_name:=_arg("scenario","sensible")
	var seed_value:=int(_arg("seed","74119"))
	var years:=int(_arg("years","50"))
	var out:=_arg("out","user://sim_truth_%s_%d.json" % [scenario_name,seed_value])
	var result:=await _run(scenario_name,_scenarios()[scenario_name],seed_value,years)
	var file:=FileAccess.open(out,FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	WorldSimulation.clear()
	print("SIM_TRUTH ",out," rows=",(result.rows as Array).size()," discoveries=",(result.discoveries as Array).size())
	get_tree().quit(0)

func _run(scenario_name:String,scenario:Dictionary,seed_value:int,years:int)->Dictionary:
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
		WorldSimulation.world.scout_land_authority=func(_p:Vector2)->bool:return true
		if scenario.has("scouting"):WorldSimulation.world.ground_survey_authority=func(p:Vector2)->Dictionary:return _ground(p,site)
	)
	WorldSimulation.submit("ec",{"kind":"ambition","id":"makers"})
	WorldSimulation.submit("ec",{"kind":"found"})
	for domain in DOMAINS if not bool(scenario.get("ai",false)) else []:
		WorldSimulation.submit("ec",{"kind":"research_emphasis","domain":domain,"weight":int((scenario.research as Dictionary).get(domain,0))})
	if scenario.has("scouting"):WorldSimulation.submit("ec",{"kind":"scouting_policy","share":float(scenario.scouting),"focus":"exploration"})
	if scenario.has("study_weight"):
		WorldSimulation.scoped("ec",func()->void:preload("res://scripts/artifact_collection.gd").set_study_weight(int(scenario.study_weight)))
	var rows:Array=[]
	var discoveries:Array=[]
	var holder:Dictionary={"starting":[]}
	var tally:={"shortage_days":0,"hunger_days":0,"seen":0,"births":0,"deaths":0}
	var start:=Time.get_ticks_msec()
	WorldSimulation.scoped("ec",func()->void:
		holder.starting=WorldSimulation.state.known_discoveries.duplicate()
		tally.seen=(holder.starting as Array).size()
		rows.append(_row(0,tally,start))
	)
	for day in range(1,years*365+1):
		WorldSimulation.scoped("ec",func()->void:
			var state:=WorldSimulation.state
			state.elapsed_days=day
			if day%30==1:
				for index in state.player_settlements.size():state.player_settlements[index]["environment_profile"]=_site_profile(Vector2.ZERO,site)
			if String(scenario.focus)!="" and day%30==2:
				for city:Dictionary in state.player_settlements:
					if bool(city.get("primary",false)) and bool(city.get("auto_manage",true)):WorldSimulation.government.set_settlement_focus(String(city.id),String(scenario.focus))
			for policy_id:String in scenario.policies:
				if day%120==3:WorldSimulation.consequences.apply_policy(policy_id,0.18,120.0,"probe")
			if bool(scenario.get("ai",false)):preload("res://scripts/civilization_controller.gd").choose_orders("ec")
			if int(scenario.get("seed_finds",-1))==day:_seed_finds(day)
			Day.advance(day,Day.context(Vector2.ZERO))
			var known:Array=state.known_discoveries
			while int(tally.seen)<known.size():
				var id:=String(known[int(tally.seen)])
				discoveries.append([day,id,String(WorldSimulation.discovery.discovery_definition(id).get("dynamic",""))])
				tally.seen=int(tally.seen)+1
			var metrics:Dictionary=state.simulation_metrics
			if float(metrics.get("food_intake_ratio",1.0))<0.95:tally.shortage_days=int(tally.shortage_days)+1
			if float((metrics.get("mortality_components",{}) as Dictionary).get("Hunger",0.0))>0.004:tally.hunger_days=int(tally.hunger_days)+1
			if day%365==0:rows.append(_row(int(day/365.0),tally,start))
		)
		if day%60==0:await get_tree().process_frame
	return {"schema":"sim_truth/1","scenario":scenario_name,"seed":seed_value,"years":years,"scenario_config":scenario,
		"starting_known":holder.starting,"rows":rows,"discoveries":discoveries,"seconds":(Time.get_ticks_msec()-start)/1000.0}

## Places a legendary set and two ordinary site pieces in the collection, as if
## a party had just returned (claimed, so no rival can take them).
func _seed_finds(day:int)->void:
	var Sites:=preload("res://scripts/artifact_sites.gd")
	var ex:Dictionary=WorldSimulation.state.society_exchange
	var seen:Dictionary=ex.get("artifact_sites",{})
	var legend:Dictionary=Sites.legends(int(WorldSimulation.state.world_seed))[0]
	var pieces:Array=[]
	for index:int in int(legend.set_size):pieces.append(Sites.piece(legend,index,day))
	for rx:int in range(0,40):
		var site:=Sites.region_site(int(WorldSimulation.state.world_seed),rx,7)
		if site.is_empty():continue
		pieces.append(Sites.piece(site,0,day))
		if pieces.size()>=5:break
	for item:Dictionary in pieces:
		item["seeded"]=true
		ex.collections[String(item.id)]=item
		seen[String(item.id)]=true
	ex["artifact_sites"]=seen

func _row(year:int,tally:Dictionary,start:int)->Dictionary:
	var state:=WorldSimulation.state
	var metrics:Dictionary=state.simulation_metrics
	var cohorts:Dictionary={}
	for key in state.POPULATION_AGE_COHORTS:cohorts[key]=snappedf(float(state.population_cohorts.get(key,0.0)),0.01)
	var pregnant:=0.0
	for key in ["first_trimester","second_trimester","third_trimester"]:pregnant+=float(state.pregnancy_cohorts.get(key,0.0))
	var workers:Dictionary={}
	for role in ROLES:workers[role]=snappedf(float(state.effective_workers(role)),0.01)
	var alloc:Dictionary={}
	for role in ROLES:alloc[role]=snappedf(float(state.population_allocation_percentages.get(role,0.0)),0.1)
	var effects:Dictionary={}
	for key:Variant in state.knowledge_effects:
		var value:=float(state.knowledge_effects[key])
		if absf(value)>0.00005:effects[String(key)]=snappedf(value,0.0001)
	var capacities:Dictionary={}
	for key:Variant in state.society_capacities:capacities[String(key)]=snappedf(float(state.society_capacities[key]),0.001)
	var channel_capacity:=0.0
	var channels:=0
	for channel:Variant in state.active_investigations:
		var id:=String(state.active_investigations[channel])
		var entry:Dictionary=WorldSimulation.discovery.discovery_definition(id)
		if entry.is_empty():continue
		channel_capacity+=float(WorldSimulation.discovery.research_capacity_for(String(entry.dynamic),String(entry.subcategory)).get("progress_multiplier",0.0))
		channels+=1
	var per_line:Dictionary={}
	for id:Variant in state.known_discoveries:
		var line:=String(WorldSimulation.discovery.discovery_definition(String(id)).get("dynamic",""))
		per_line[line]=int(per_line.get(line,0))+1
	var harvest:Dictionary={}
	for key:Variant in (metrics.get("food_harvest",{}) as Dictionary):harvest[String(key)]=snappedf(float(metrics.food_harvest[key]),0.1)
	var source_health:Dictionary={}
	for key:Variant in state.food_source_health:source_health[String(key)]=snappedf(float(state.food_source_health[key]),0.001)
	var A:=preload("res://scripts/artifact_collection.gd")
	var art_count:=0;var art_studied:=0;var art_seeded:=0;var art_prestige:=0.0;var art_study_sum:=0.0;var rarity:Dictionary={}
	for item:Dictionary in state.society_exchange.get("collections",{}).values():
		if String(item.get("kind",""))!="artifact":continue
		art_count+=1;art_prestige+=A.prestige(item);art_study_sum+=float(item.get("study",0.0))
		if float(item.get("study",0.0))>=1.0:art_studied+=1
		if bool(item.get("seeded",false)):art_seeded+=1
		rarity[str(int(item.get("rarity",0)))]=int(rarity.get(str(int(item.get("rarity",0))),0))+1
	var bonuses:Dictionary=state.society_exchange.get("artifact_bonuses",{})
	var allure:=float(preload("res://scripts/artifact_culture.gd").allure()) if art_count>0 else 0.0
	var research_alloc:Dictionary={}
	for line in DOMAINS:research_alloc[line]=int(state.research_allocations.get(line,0))
	return {"year":year,"population":state.population_total,"cohorts":cohorts,"pregnant":snappedf(pregnant,0.01),
		"life_expectancy":snappedf(state.projected_life_expectancy(),0.1),
		"infant_mortality":snappedf(Indicators.infant_mortality_per_1000(state,WorldSimulation.discovery),0.1),
		"health":snappedf(state.population_health,0.001),"food_security":snappedf(state.food_security,0.001),
		"food_days":snappedf(float(metrics.get("food_days",0)),0.1),"intake":snappedf(float(metrics.get("food_intake_ratio",1.0)),0.001),
		"diet":snappedf(float(state.food_history[-1].get("diet_quality",0)) if not state.food_history.is_empty() else 0.0,0.001),
		"malnutrition":snappedf(state.malnutrition_burden,0.001),"births":state.lifetime_births,"deaths":state.lifetime_deaths,
		"neonatal":state.lifetime_neonatal_deaths,"maternal":state.lifetime_maternal_deaths,
		"shortage_days":tally.shortage_days,"hunger_days":tally.hunger_days,
		"alloc":alloc,"workers":workers,"research_alloc":research_alloc,"study_weight":int(A.study_role().weight),
		"scholarship":snappedf(float(state.scholarship_level),0.01),"education":snappedf(Indicators.education_index(state),0.001),
		"knowledge_metric":snappedf(float(metrics.get("knowledge",0.0)),0.0001),"material_capacity":snappedf(float(metrics.get("material_capacity",0.0)),0.001),
		"cohesion":snappedf(float(metrics.get("cohesion",0.0)),0.001),"housing_ratio":snappedf(float(metrics.get("housing_ratio",0.0)),0.001),
		"ecology":snappedf(float(metrics.get("ecology",0.0)),0.001),"labor_efficiency":snappedf(float(metrics.get("labor_efficiency",0.0)),0.001),
		"capacities":capacities,"channels":channels,"channel_capacity":snappedf(channel_capacity,0.0001),
		"known":state.known_discoveries.size(),"per_line":per_line,"effects":effects,
		"harvest":harvest,"need":snappedf(float(metrics.get("food_consumption",0)),0.1),"source_health":source_health,
		"settlements":state.player_settlements.size(),"completed":state.settlement_completed.size(),
		"artifacts":{"count":art_count,"studied":art_studied,"seeded":art_seeded,"prestige":snappedf(art_prestige,0.01),"study_sum":snappedf(art_study_sum,0.001),
			"rarity":rarity,"science":snappedf(float(bonuses.get("science",0.0)),0.0001),"culture":snappedf(float(bonuses.get("culture",0.0)),0.0001),
			"allure":snappedf(allure,0.0001),"scout_parties":WorldSimulation.world.scout_missions.size() if WorldSimulation.world!=null else 0,
			"scouting_status":String(WorldSimulation.world.scouting_staff.data.get("status","")) if WorldSimulation.world!=null else "","sites_seen":(state.society_exchange.get("artifact_sites",{}) as Dictionary).size()},
		"seconds":(Time.get_ticks_msec()-start)/1000.0}
