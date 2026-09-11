extends RefCounted
## One ordered calendar step. Controllers choose orders; this code owns effects.
const BUILD=preload("res://scripts/settlement_construction.gd")

static func context(origin:Vector2,traveling:bool=false)->Dictionary:
	var result:={"origin":Vector3(origin.x,0,origin.y),"settlement_origin":Vector3(origin.x,0,origin.y),"traveling":traveling,"settled":WorldSimulation.state.settlement_site_committed,"foraging":.78 if traveling else 1.0,"food":1.0,"exploration":.8 if traveling else .5,"travel":1.0 if traveling else .1,"fiber":.5,"fire":.6,"administration":.5,"defense":.3,"tools":WorldSimulation.consequences.tools_factor(),"insight":WorldSimulation.consequences.discovery_multiplier()}
	var journey:=WorldSimulation.state.founding_journey
	result.travel_days_remaining=maxf(0,float(journey.get("duration_days",0))-float(journey.get("elapsed",0))) if traveling else 0.0
	result.travel_distance_remaining_km=origin.distance_to(journey.get("destination",origin)) if traveling else 0.0
	if WorldSimulation.context_provider.is_valid():
		result.merge(WorldSimulation.context_provider.call(origin),true)
	else:
		result.environment_profile=PlanetEnvironment.profile_at(origin)
		# Headless worlds may supply a measured geographic provider. Never infer
		# potable water or charted ground from an aggregate food-capacity score.
	for key in ["biome","temperature","precipitation","fertility"]:result[key]=result.environment_profile.get(key,0)
	result.foraging=maxf(float(result.foraging),float(result.environment_profile.get("forage",0)))
	if float(result.get("surface_water_distance_km",INF))<=6:result.freshwater=1.0
	if "Hearth Circle" in WorldSimulation.state.settlement_completed:result.merge({"construction":1.0,"storage":.8,"timber":.7})
	result.merge(WorldSimulation.state.active_field_observation_signals(int(WorldSimulation.state.elapsed_days)))
	return result

static func advance(day:int,daily_context:Dictionary,construction:Callable=Callable(),timings:Dictionary={},secondary_timings:Dictionary={})->Dictionary:
	var stamp:=Time.get_ticks_usec() if not timings.is_empty() else 0
	WorldSimulation.state.elapsed_days=day
	WorldSimulation.state.convoy_traveling=bool(daily_context.get("traveling",false))
	if WorldSimulation.military.recovery.home_unavailable():
		WorldSimulation.military.recovery.advance(day)
		for city in WorldSimulation.state.player_settlements:
			if bool(city.get("primary",false)) or not String(city.get("occupied_by","")).is_empty():continue
			WorldSimulation.settlements.process_city_resources(String(city.id),context(city.position),func()->void:BUILD.process_day())
		return {"discoveries":[],"resources":[],"events":[],"progression":[],"arrival":{}}
	WorldSimulation.state.synchronize_population_allocations()
	preload("res://scripts/technology_operations.gd").advance(day)
	stamp=record_timing(timings,"operations",stamp)
	var discoveries:=WorldSimulation.discovery.process_day(daily_context)
	stamp=record_timing(timings,"discovery",stamp)
	var resource_events:=WorldSimulation.resources.process_day(daily_context)
	stamp=record_timing(timings,"resources",stamp)
	WorldSimulation.state.synchronize_population_allocations()
	var events:Array[Dictionary]=WorldSimulation.settlements.with_local_population(func()->Array[Dictionary]:return WorldSimulation.consequences.process_day(daily_context),true)
	stamp=record_timing(timings,"consequences",stamp)
	events.append_array(WorldSimulation.civics.process_day(day))
	stamp=record_timing(timings,"civics",stamp)
	events.append_array(WorldSimulation.settlements.with_local_population(func()->Array[Dictionary]:return WorldSimulation.economy.process_day(daily_context)))
	stamp=record_timing(timings,"economy",stamp)
	events.append_array(WorldSimulation.government.process_day(day))
	stamp=record_timing(timings,"government",stamp)
	var build:=construction if construction.is_valid() else func()->void:BUILD.process_day()
	WorldSimulation.settlements.with_local_population(build)
	stamp=record_timing(timings,"construction",stamp)
	for city in WorldSimulation.state.player_settlements:
		if bool(city.get("primary",false)) or not String(city.get("occupied_by","")).is_empty():continue
		var local_context:=context(city.position)
		WorldSimulation.settlements.process_city_resources(String(city.id),local_context,build,secondary_timings)
	stamp=record_timing(timings,"secondary_settlements",stamp)
	WorldSimulation.settlements.process_city_trade()
	stamp=record_timing(timings,"city_trade",stamp)
	WorldSimulation.settlements.process_local_month(daily_context)
	stamp=record_timing(timings,"settlement_morphology",stamp)
	var progression_events:=WorldSimulation.progression.process_day(day)
	stamp=record_timing(timings,"progression",stamp)
	if WorldSimulation.military.last_processed_day<day:
		WorldSimulation.military.last_processed_day=day
		WorldSimulation.military._process_military_day()
	preload("res://scripts/civilization_travel.gd").advance(1.0)
	stamp=record_timing(timings,"military_and_travel",stamp)
	var arrival:=advance_convoy()
	stamp=record_timing(timings,"convoy",stamp)
	return {"discoveries":discoveries,"resources":resource_events,"events":events,"progression":progression_events,"arrival":arrival}

static func advance_convoy()->Dictionary:
	var convoy:=WorldSimulation.state.settlement_convoy
	if not bool(convoy.get("active",false)):return {}
	var origin:Vector2=convoy.origin
	var destination:Vector2=convoy.destination
	var progress:=clampf((WorldSimulation.state.elapsed_days-float(convoy.depart_day))/maxf(.5,float(convoy.duration_days)),0,1)
	WorldSimulation.settlements.update_settlement_convoy(origin.lerp(destination,progress),progress)
	if progress<1:return {}
	return WorldSimulation.settlements.complete_settlement_convoy(destination)

static func record_timing(timings:Dictionary,phase:String,start:int)->int:
	if timings.is_empty():return 0
	var now:=Time.get_ticks_usec()
	var record:Dictionary=timings.get(phase,{"calls":0,"microseconds":0})
	record.calls+=1;record.microseconds+=now-start;timings[phase]=record
	return now
