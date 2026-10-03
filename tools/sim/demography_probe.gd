extends Node
## Founding demography in the REAL engine, headless (docs/PEOPLE_FIRST.md B,
## frontier growth): runs fresh owned worlds for a few decades and prints one
## line a year per people: people, births and deaths that year, crude birth
## and death rates, the age mix, life expectancy, infant deaths, the engine's
## expected deaths a year by age band, and the land and care factors.
## Never launches or touches the player's game.
##   Godot --headless --path <worktree> res://tools/sim/demography_probe.tscn -- --seeds=74119,5150 --years=20 [--ai]
const Day=preload("res://scripts/civilization_day.gd")
const Indicators=preload("res://scripts/civilization_indicators.gd")
const EarlyCare=preload("res://scripts/early_life_conditions.gd")

func _arg(name:String,fallback:String)->String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--%s=" % name):return arg.substr(name.length()+3)
		if arg=="--%s" % name:return "1"
	return fallback

func _ready()->void:
	var years:=int(_arg("years","20"))
	var ai:=_arg("ai","")=="1"
	for seed_text:String in _arg("seeds","74119").split(","):
		await _run(int(seed_text),years,ai)
	get_tree().quit(0)

func _run(seed_value:int,years:int,ai:bool)->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=func(origin:Vector2)->Dictionary:
		var profile:Dictionary=PlanetEnvironment.profile_at(origin).duplicate(true)
		profile.merge({"forage":0.62,"game":0.52,"fertility":0.58,"growing_season":0.62,"water_access":0.62,"rainfall_variability":0.30,"precipitation":0.55},true)
		var wood:={"position":Vector3(origin.x,0,origin.y),"density":0.55,"area_km2":9.0}
		return {"environment_profile":profile,"surface_water_distance_km":0.5,"surface_water_recognized":true,"woodland_catchment":wood,
			"surface_material_catchments":{"Timber":wood,"Stone":{"position":Vector3(origin.x,0,origin.y),"density":0.35,"area_km2":9.0},"Fiber Plants":{"position":Vector3(origin.x,0,origin.y),"density":0.5,"area_km2":9.0}}}
	WorldSimulation.create_actor("ec",seed_value,Vector2.ZERO)
	WorldSimulation.enabled=true
	WorldSimulation.scoped("ec",func()->void:WorldSimulation.world.scout_land_authority=func(_p:Vector2)->bool:return true)
	WorldSimulation.submit("ec",{"kind":"found"})
	print("seed %d %s, %d years" % [seed_value,"computer ruler" if ai else "leaders' split",years])
	print("year people born died  CBR  CDR  growth | children youth early estab mature elders (%) | e0   IMR | expected deaths a year: children youth early estab mature elders | conception frontier spare crowd capacity carers health")
	var last:={"births":0,"deaths":0,"people":120.0}
	WorldSimulation.scoped("ec",func()->void:last.people=float(WorldSimulation.state.population_exact))
	for day in range(1,years*365+1):
		WorldSimulation.scoped("ec",func()->void:
			var state:=WorldSimulation.state
			state.elapsed_days=day
			if ai:preload("res://scripts/civilization_controller.gd").choose_orders("ec")
			var before_dead:=int(state.lifetime_deaths)
			Day.advance(day,Day.context(Vector2.ZERO))
			# Each day's deaths by the cause the engine names, and its expected toll.
			var comps:Dictionary=state.simulation_metrics.get("mortality_components",{})
			var tally:Dictionary=last.get("tally",{})
			for cause:Variant in comps:tally[String(cause)]=float(tally.get(String(cause),0.0))+float(comps[cause])*float(state.population_exact)/365.0
			tally["counted"]=float(tally.get("counted",0.0))+float(int(state.lifetime_deaths)-before_dead)
			last["tally"]=tally
			if day%365==0:
				last.merge(_line(int(day/365),last),true)
				var said:PackedStringArray=[]
				for cause:String in tally:said.append("%s %.1f" % [cause.left(10),float(tally[cause])])
				print("      this year by cause (expected from the day's rates; counted = deaths registered): "+", ".join(said))
				last["tally"]={}
		)
		if day%60==0:await get_tree().process_frame
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()

func _line(year:int,last:Dictionary)->Dictionary:
	var state:=WorldSimulation.state
	var people:=float(state.population_exact)
	var born:=int(state.lifetime_births)-int(last.births)
	var died:=int(state.lifetime_deaths)-int(last.deaths)
	var mid:=maxf(1.0,(people+float(last.people))*0.5)
	var mix:PackedStringArray=[]
	for key in state.POPULATION_AGE_COHORTS:mix.append("%4.1f" % (100.0*float(state.population_cohorts.get(key,0.0))/maxf(1.0,people)))
	var cf:float=state._mortality_condition_factor()
	var hazards:Dictionary=state._natural_cohort_hazards(cf)
	var expected:PackedStringArray=[]
	for key in state.POPULATION_AGE_COHORTS:expected.append("%4.1f" % (float(state.population_cohorts.get(key,0.0))*clampf(float(hazards[key])*cf,0.0001,0.98)))
	var care:Dictionary=state.early_care
	var comps:Dictionary=state.simulation_metrics.get("mortality_components",{})
	var other:PackedStringArray=[]
	for cause:Variant in comps:
		if String(cause)!="Natural causes" and float(comps[cause])>0.0005:other.append("%s %.1f" % [String(cause).left(9),1000.0*float(comps[cause])])
	var hard:=0
	for e:Dictionary in preload("res://scripts/hardship_log.gd").entries():hard+=int(e.get("dead",0))
	print("      housing %.2f; per 1,000 a year: natural %.1f%s; misfortune dead so far %d; newborn deaths %d, mothers %d" % [float(state.simulation_metrics.get("housing_ratio",0.0)),1000.0*float(comps.get("Natural causes",0.0))," · "+", ".join(other) if not other.is_empty() else "",hard,int(state.lifetime_neonatal_deaths),int(state.lifetime_maternal_deaths)])
	print("%4d %6.1f %4d %4d %4.0f %4.0f %+5.2f%% | %s | %4.1f %4.0f | %s | %5.3f %5.3f %5.3f %5.3f %6.0f %4.2f %4.2f" % [year,people,born,died,1000.0*born/mid,1000.0*died/mid,100.0*(people-float(last.people))/maxf(1.0,float(last.people)),
		" ".join(mix),state.projected_life_expectancy(),Indicators.infant_mortality_per_1000(state,WorldSimulation.discovery)," ".join(expected),
		float(care.get("conception",1.0)),float(care.get("frontier",0.0)),float(care.get("spare_land",0.0)),float(care.get("crowding",0.0)),float(care.get("carrying_capacity",0.0)),float(care.get("carer_cover",0.0)),float(state.population_health)])
	return {"births":state.lifetime_births,"deaths":state.lifetime_deaths,"people":people}
