extends Node
## Phase 3 balance harness: 600-year headless campaigns on disposable actors
## through the real daily pipeline (civilization_day.gd), measured against the
## historical benchmark table in docs/research/BENCHMARKS_600.md.
##
## Usage:
##   Godot --headless --path <worktree> res://tests/research_600_campaign_probe.tscn -- \
##     [--years=600] [--seeds=74119,5021] [--scenarios=sensible,poor,research,ai,balanced,max_health] [--every=25]
##
## Prints one RC_ROW JSON line per checkpoint and one RC_SUMMARY line per run
## (milestone years, discoveries per 50 years, effect-over-ceiling violations).
## Asserts only invariants: the society survives, numbers stay finite, and no
## effect total ever exceeds its era ceiling. Benchmark ranges are compared by
## tools/research/benchmark_report.py, not here, so a run never "passes" by
## tuning the probe itself.
const Day=preload("res://scripts/civilization_day.gd")
const Indicators=preload("res://scripts/civilization_indicators.gd")
const EarlyCare=preload("res://scripts/early_life_conditions.gd")
const Research600=preload("res://scripts/research_600_catalog.gd")
const GameStateScript=preload("res://scripts/game_state.gd")
const DOMAINS:Array[String]=["demography","nutrition","health","labor","knowledge","production","infrastructure","logistics","ecology","institutions","security","culture"]
## Registry milestones whose landing year is reported against the design band.
const MILESTONES:Array[String]=["copper_smelting","ox_drawn_ard","solid_wheel_assembly","pictographic_records","four_wheeled_wagons","sail_panel_cutting","standard_sign_lists","kiln_fired_bricks","bronze_alloying","phonetic_notation","formal_archives","place_value","spoked_wheel_assembly","consonantal_alphabet","written_law_code"]
## Effect channels whose totals are reported at every checkpoint.
const WATCHED:Array[String]=["construction_rate","craft_output","tool_quality","labor_efficiency","health_protection","disease_exposure","nutrition_quality","maternal_safety","neonatal_survival","state_capacity","knowledge_preservation","knowledge_rate","food_output","cultivation_yield","food_storage","water_safety","sanitation","housing_output","haul_capacity","trade_capacity","warfare_readiness","security_efficiency"]
var failures:Array[String]=[]

func _scenarios()->Dictionary:
	return {
		# (a) Good site, delegated labor, broad research.
		"sensible":{"site":"good","focus":"","policies":[],"research":{"demography":2,"nutrition":3,"health":3,"labor":2,"knowledge":2,"production":3,"infrastructure":2,"logistics":1,"ecology":1,"institutions":1,"security":1,"culture":1}},
		# (b) Poor site, labor drives, no care research.
		"poor":{"site":"poor","focus":"development","policies":["foraging_drive","labor_mobilization"],"research":{"demography":0,"nutrition":0,"health":0,"labor":2,"knowledge":5,"production":6,"infrastructure":2,"logistics":1,"ecology":0,"institutions":2,"security":5,"culture":1}},
		# (c) Research-led: settlement research focus and heavy, broad emphasis.
		"research":{"site":"good","focus":"research","policies":[],"research":{"demography":3,"nutrition":4,"health":4,"labor":3,"knowledge":6,"production":4,"infrastructure":3,"logistics":3,"ecology":2,"institutions":3,"security":2,"culture":2}},
		# (d) The ordinary rival controller chooses research and orders.
		"ai":{"site":"good","focus":"","policies":[],"ai":true,"research":{}},
		# Line-maximization matrix (docs/research/LINE_MAX_MATRIX.md): the same
		# good-site play with 2 on every line, or 12 on one line and 0 elsewhere.
		"balanced":{"site":"good","focus":"","policies":[],"research":_uniform(2)},
	}

func _uniform(weight:int,line:String="")->Dictionary:
	var result:Dictionary={}
	for domain:String in DOMAINS:result[domain]=weight if line=="" else (12 if domain==line else 0)
	return result

func _scenario(scenario_name:String)->Dictionary:
	if scenario_name.begins_with("max_") and scenario_name.substr(4) in DOMAINS:
		return {"site":"good","focus":"","policies":[],"research":_uniform(0,scenario_name.substr(4))}
	return _scenarios().get(scenario_name,{})

func _site_profile(origin:Vector2,site:String)->Dictionary:
	var profile:Dictionary=PlanetEnvironment.profile_at(origin).duplicate(true)
	if site=="poor":
		profile.merge({"forage":0.26,"game":0.22,"fertility":0.22,"growing_season":0.34,"water_access":0.12,"rainfall_variability":0.62,"precipitation":0.30},true)
	else:
		profile.merge({"forage":0.62,"game":0.52,"fertility":0.58,"growing_season":0.62,"water_access":0.62,"rainfall_variability":0.30,"precipitation":0.55,"river_distance_km":1.0},true)
	return profile

func _arg(name:String,fallback:String)->String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--%s=" % name):return arg.substr(name.length()+3)
	return fallback

func _ready()->void:
	var years:=int(_arg("years","600"))
	var every:=int(_arg("every","25"))
	var seeds:Array[int]=[]
	for part in _arg("seeds","74119").split(","):seeds.append(int(part))
	var wanted:=_arg("scenarios","sensible,poor,research,ai").split(",")
	for scenario_name in wanted:
		var scenario:=_scenario(scenario_name)
		if scenario.is_empty():
			failures.append("unknown scenario "+scenario_name)
			continue
		for seed_value in seeds:
			await _run(scenario_name,scenario,seed_value,years,every)
	WorldSimulation.clear()
	print("RC_FAILURES ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)

func _run(scenario_name:String,scenario:Dictionary,seed_value:int,years:int,every:int)->void:
	WorldSimulation.clear()
	var site:=String(scenario.site)
	var water_km:=2.2 if site=="poor" else 0.2
	WorldSimulation.context_provider=func(origin:Vector2)->Dictionary:
		var wood:={"position":Vector3(origin.x,0,origin.y),"density":0.55,"area_km2":9.0}
		return {"environment_profile":_site_profile(origin,site),"surface_water_distance_km":water_km,"surface_water_recognized":true,"woodland_catchment":wood,"surface_material_catchments":{"Timber":wood,"Stone":{"position":Vector3(origin.x,0,origin.y),"density":0.35,"area_km2":9.0},"Fiber Plants":{"position":Vector3(origin.x,0,origin.y),"density":0.5,"area_km2":9.0},"Clay":{"position":Vector3(origin.x,0,origin.y),"density":0.45,"area_km2":9.0}}}
	WorldSimulation.create_actor("rc",seed_value,Vector2.ZERO)
	WorldSimulation.enabled=true
	WorldSimulation.scoped("rc",func()->void:
		WorldSimulation.state.ensure_population_total(120)
		WorldSimulation.world.scout_land_authority=func(_p:Vector2)->bool:return true
	)
	WorldSimulation.submit("rc",{"kind":"ambition","id":"makers"})
	var founded:=WorldSimulation.submit("rc",{"kind":"found"})
	if founded.has("error"):failures.append("%s/%d found: %s" % [scenario_name,seed_value,str(founded)])
	var research:Dictionary=scenario.research
	for domain in DOMAINS if not bool(scenario.get("ai",false)) else []:WorldSimulation.submit("rc",{"kind":"research_emphasis","domain":domain,"weight":int(research.get(domain,0))})
	var tally:={"births":0,"deaths":0,"maternal":0,"population":120,"known":0,"milestones":{},"per_50":{},"violations":{},"max_ratio":{},"start":Time.get_ticks_msec()}
	for day in range(1,years*365+1):
		WorldSimulation.scoped("rc",func()->void:
			var state:=WorldSimulation.state
			state.elapsed_days=day
			if day%30==1:
				for index in state.player_settlements.size():
					state.player_settlements[index]["environment_profile"]=_site_profile(Vector2.ZERO,site)
			if String(scenario.focus)!="" and day%30==2:
				for city:Dictionary in state.player_settlements:
					if bool(city.get("primary",false)) and bool(city.get("auto_manage",true)):WorldSimulation.government.set_settlement_focus(String(city.id),String(scenario.focus))
			for policy_id:String in scenario.policies:
				if day%120==3:WorldSimulation.consequences.apply_policy(policy_id,0.18,120.0,"probe")
			if bool(scenario.get("ai",false)):preload("res://scripts/civilization_controller.gd").choose_orders("rc")
			Day.advance(day,Day.context(Vector2.ZERO))
			if day%30==0:_track(tally,day)
			if day%365==0:
				var year:=int(day/365.0)
				if year in [1,10,50] or year%every==0:_checkpoint(scenario_name,seed_value,year,tally)
		)
		if day%60==0:await get_tree().process_frame
	WorldSimulation.scoped("rc",func()->void:
		var state:=WorldSimulation.state
		if state.population_total<=0:failures.append("%s/%d died out" % [scenario_name,seed_value])
		if not is_finite(state.projected_life_expectancy()):failures.append("Invalid life expectancy %s/%d" % [scenario_name,seed_value])
		if not (tally.violations as Dictionary).is_empty():failures.append("%s/%d effects above era ceiling: %s" % [scenario_name,seed_value,str(tally.violations)])
		var bands:Dictionary={}
		for id:String in MILESTONES:
			var item:Dictionary=Research600.item(id)
			bands[id]=[item.get("band_low",0),item.get("target_year",item.get("proposed_year",0)),item.get("band_high",0)]
		print("RC_SUMMARY ",JSON.stringify({"scenario":scenario_name,"seed":seed_value,"years":years,"milestones":tally.milestones,"bands":bands,"per_50":tally.per_50,"violations":tally.violations,"max_ratio":tally.max_ratio,"known":state.known_discoveries.size(),"seconds":(Time.get_ticks_msec()-int(tally.start))/1000}))
	)

## Monthly: milestone landing years, discoveries per 50-year block, and the
## largest effect-total / era-ceiling ratio seen (must never exceed 1).
func _track(tally:Dictionary,day:int)->void:
	var state:=WorldSimulation.state
	var year:=float(day)/365.0
	var known:Array=state.known_discoveries
	if known.size()!=int(tally.known):
		var block:=str(int(year/50.0)*50)
		tally.per_50[block]=int((tally.per_50 as Dictionary).get(block,0))+known.size()-int(tally.known)
		tally.known=known.size()
		for id:String in MILESTONES:
			if id in known and not (tally.milestones as Dictionary).has(id):tally.milestones[id]=snappedf(year,0.1)
	var model:Variant=WorldSimulation.discovery.society_model
	if not model.has_method("era_ceiling"):return
	var totals:Dictionary=model.effect_totals
	for key:Variant in totals:
		var ceiling:Vector2=model.era_ceiling(String(key))
		var value:=float(totals[key])
		var ratio:=0.0
		if value>0.0 and ceiling.y>0.0:ratio=value/ceiling.y
		elif value<0.0 and ceiling.x<0.0:ratio=value/ceiling.x
		if ratio>float((tally.max_ratio as Dictionary).get(key,0.0)):tally.max_ratio[key]=snappedf(ratio,0.001)
		if ratio>1.0005:tally.violations[key]="%.3f>%.3f@%.0f" % [value,ceiling.y if value>0.0 else ceiling.x,year]

func _checkpoint(scenario_name:String,seed_value:int,year:int,tally:Dictionary)->void:
	var state:=WorldSimulation.state
	var metrics:Dictionary=state.simulation_metrics
	var cohorts:Dictionary=state.population_cohorts
	# Vital rates since the previous checkpoint.
	var births:=state.lifetime_births-int(tally.births)
	var deaths:=state.lifetime_deaths-int(tally.deaths)
	var maternal:=state.lifetime_maternal_deaths-int(tally.maternal)
	var span_years:=float(year-int(tally.get("year",0)))
	var start_population:=maxf(1.0,float(tally.population))
	var growth:=(pow(maxf(1.0,float(state.population_total))/start_population,1.0/maxf(1.0,span_years))-1.0)*100.0
	var mean_population:=maxf(1.0,(start_population+float(state.population_total))*0.5)
	var women_15_45:=0.5*(float(cohorts.get("youth",0.0))*10.0/11.0+float(cohorts.get("early_adults",0.0))+float(cohorts.get("established_adults",0.0)))
	var tfr:=float(births)/maxf(1.0,span_years)/maxf(1.0,women_15_45)*30.0
	tally.births=state.lifetime_births
	tally.deaths=state.lifetime_deaths
	tally.maternal=state.lifetime_maternal_deaths
	tally.population=state.population_total
	tally.year=year
	# Child (1-4) mortality from the same life table as life expectancy.
	var condition:float=state._mortality_condition_factor()
	var exceptional:float=state._current_exceptional_mortality_rate()
	var survive:=1.0
	for age in range(1,5):
		var hazard:float=GameStateScript.BASELINE_HAZARD_BY_AGE[age]*EarlyCare.age_multiplier(state.early_care,age,condition)
		survive*=1.0-clampf(hazard*condition+exceptional,0.0001,0.98)
	var effects:Dictionary={}
	var ceilings:Dictionary={}
	var model:Variant=WorldSimulation.discovery.society_model
	for key:String in WATCHED:
		effects[key]=snappedf(float(model.effect(key)),0.001)
		if model.has_method("era_ceiling"):ceilings[key]=snappedf(float((model.era_ceiling(key) as Vector2).y if key!="disease_exposure" else (model.era_ceiling(key) as Vector2).x),0.001)
	var adoption_sum:=0.0
	for id:String in state.known_discoveries:adoption_sum+=clampf(float(state.discovery_adoption.get(id,0.0)),0.0,1.0)
	print("RC_ROW ",JSON.stringify({
		"scenario":scenario_name,"seed":seed_value,"year":year,"population":state.population_total,"settlements":state.player_settlements.size(),
		"growth_pct":snappedf(growth,0.01),"life_expectancy":snappedf(state.projected_life_expectancy(),0.1),
		"infant_mortality":snappedf(Indicators.infant_mortality_per_1000(state,WorldSimulation.discovery),0.1),
		"child_mortality_1_4":snappedf((1.0-survive)*1000.0,0.1),
		"maternal_per_100k":snappedf(float(maternal)/maxf(1.0,float(births))*100000.0,1.0),
		"cbr":snappedf(float(births)/maxf(1.0,span_years)/mean_population*1000.0,0.1),"cdr":snappedf(float(deaths)/maxf(1.0,span_years)/mean_population*1000.0,0.1),
		"tfr":snappedf(tfr,0.01),"health":snappedf(state.population_health,0.001),"food_security":snappedf(state.food_security,0.001),
		"diet":snappedf(EarlyCare.diet_window(state),0.001),"food_share":snappedf(float(state.population_allocation_percentages.get("Food",0)),0.1),
		"knowledge_share":snappedf(float(state.population_allocation_percentages.get("Knowledge",0)),0.1),
		"defense_share":snappedf(float(state.population_allocation_percentages.get("Defense",0)),0.1),
		"education":snappedf(Indicators.education_index(state),0.001),
		"food_per_worker":snappedf(float(metrics.get("food_production",metrics.get("food_consumption",0.0)))/maxf(1.0,state.effective_workers("Food")),0.01),
		"housing":state.housing_capacity,"works":state.settlement_completed.size(),"last_works":state.settlement_completed.slice(maxi(0,state.settlement_completed.size()-3)),
		"discoveries":state.known_discoveries.size(),"mean_adoption":snappedf(adoption_sum/maxf(1.0,float(state.known_discoveries.size())),0.001),
		"effects":effects,"ceilings":ceilings,"care":{"under5":snappedf(float(state.early_care.get("under5",1.0)),0.01),"neonatal":snappedf(float(state.early_care.get("neonatal",1.0)),0.01),"adult":snappedf(float(state.early_care.get("adult",1.0)),0.01)},
		"milestones":(tally.milestones as Dictionary).duplicate(),
		"seconds":(Time.get_ticks_msec()-int(tally.start))/1000
	}))
