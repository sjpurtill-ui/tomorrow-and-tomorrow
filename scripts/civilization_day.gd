extends RefCounted
## One ordered calendar step. Controllers choose orders; this code owns effects.
const BUILD=preload("res://scripts/settlement_construction.gd")

static func context(origin:Vector2,traveling:bool=false)->Dictionary:
	var result:={"origin":Vector3(origin.x,0,origin.y),"settlement_origin":Vector3(origin.x,0,origin.y),"traveling":traveling,"settled":WorldSimulation.state.settlement_site_committed,"foraging":.78 if traveling else 1.0,"food":1.0,"exploration":.8 if traveling else .5,"travel":1.0 if traveling else .1,"fiber":.5,"fire":.6 if preload("res://scripts/fire_practice.gd").available() else .08,"administration":.5,"defense":.3,"tools":WorldSimulation.consequences.tools_factor(),"insight":WorldSimulation.consequences.discovery_multiplier()}
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
	# Synchronous form of the same ordered steps a scheduled day runs.
	var run:=plan(day,daily_context,construction,secondary_timings)
	var job:=preload("res://scripts/day_job.gd").new()
	job.add_group(WorldSimulation.actor_id,steps(run,timings),run)
	job.run_all()
	return run.result

static func plan(day:int,daily_context:Dictionary,construction:Callable=Callable(),secondary_timings:Dictionary={})->Dictionary:
	var discoveries:Array[Dictionary]=[]
	var resources:Array[Dictionary]=[]
	var events:Array[Dictionary]=[]
	var progression:Array[Dictionary]=[]
	var build:=construction if construction.is_valid() else func()->void:BUILD.process_day()
	return {"day":day,"context":daily_context,"build":build,"secondary_timings":secondary_timings,"result":{"discoveries":discoveries,"resources":resources,"events":events,"progression":progression,"arrival":{}}}

## One owner's calendar day as resumable steps. Each step runs under the
## owner's scope; shared state between steps lives only in `run`.
static func steps(run:Dictionary,timings:Dictionary={})->Array:
	var S=preload("res://scripts/day_job.gd")
	var day:int=run.day
	var daily_context:Dictionary=run.context
	var controller:=preload("res://scripts/civilization_controller.gd")
	return [
		S.step("arrivals",timings,func()->Variant:
			WorldSimulation.state.elapsed_days=day
			WorldSimulation.state.convoy_traveling=bool(daily_context.get("traveling",false))
			# Returned cargo belongs to today's local work, before households, building
			# and workshops compete for it. Dispatch of new shipments remains later.
			WorldSimulation.settlements.receive_city_trade_arrivals()
			if WorldSimulation.military.recovery.home_unavailable():
				WorldSimulation.military.recovery.advance(day)
				run.result={"discoveries":[],"resources":[],"events":[],"progression":[],"arrival":{}}
				run.halt=true
				return _city_steps(func()->void:BUILD.process_day(),{},timings,"recovery_settlements")
			WorldSimulation.state.synchronize_population_allocations()
			return null
	),
		S.step("operations",timings,func()->void:preload("res://scripts/technology_operations.gd").advance(day,daily_context)),
		S.step("discovery",timings,func()->void:run.result.discoveries=WorldSimulation.discovery.process_day(daily_context)),
		S.step("resources",timings,func()->void:run.result.resources=WorldSimulation.resources.process_day(daily_context)),
		S.step("civilian_review_due",timings,func()->Array:
			# Review new investment against today's delivered inputs, before recurring
			# consumption makes every setup appear permanently unaffordable.
			var id:=WorldSimulation.actor_id
			var parts:Array=[]
			if String(WorldSimulation.actors.get(id,{}).get("controller",""))=="ai" and controller.civilian_arrival_review_due(id,day):
				for part:Array in controller.civilian_order_steps(id,func()->Dictionary:return controller.current_plan(id)):parts.append(S.step(String(part[0]),timings,part[1]))
			elif id=="player":
				WorldSimulation.military.workshop.review_arrivals()
			return parts
	),
		S.step("consequences",timings,func()->void:
			WorldSimulation.state.synchronize_population_allocations()
			run.result.events=WorldSimulation.settlements.with_local_population(func()->Array[Dictionary]:return WorldSimulation.consequences.process_day(daily_context),true)
	),
		S.step("civics",timings,func()->void:
			WorldSimulation.settlements.with_local_population(func()->void:preload("res://scripts/opening_craft_practice.gd").advance())
			run.result.events.append_array(WorldSimulation.civics.process_day(day))
	),
		S.step("economy",timings,func()->void:run.result.events.append_array(WorldSimulation.settlements.with_local_population(func()->Array[Dictionary]:return WorldSimulation.economy.process_day(daily_context)))),
		S.step("government",timings,func()->void:run.result.events.append_array(WorldSimulation.government.process_day(day))),
		S.step("construction",timings,func()->void:WorldSimulation.settlements.with_local_population(run.build)),
		S.step("secondary_plan",timings,func()->Array:return _city_steps(run.build,run.secondary_timings,timings,"secondary_settlements")),
		S.step("city_trade",timings,func()->void:WorldSimulation.settlements.process_city_trade()),
		S.step("settlement_morphology",timings,func()->void:
			WorldSimulation.settlements.process_local_month(daily_context)
			preload("res://scripts/undertaking_system.gd").advance_all(day)
	),
		S.step("progression",timings,func()->void:run.result.progression=WorldSimulation.progression.process_day(day)),
		S.step("military_and_travel",timings,func()->void:
			if WorldSimulation.military.last_processed_day<day:
				WorldSimulation.military.last_processed_day=day
				WorldSimulation.military._process_military_day()
			preload("res://scripts/civilization_travel.gd").advance(1.0)
	),
		S.step("convoy",timings,func()->void:
			run.result.arrival=advance_convoy()
			if WorldSimulation.actor_id=="player" and WorldSimulation.state.settlement_site_committed:
				if controller.review_due("player",day):
					WorldSimulation.direction.ensure();WorldSimulation.direction._ensure_cultural_memory();WorldSimulation.direction.apply_inclinations(day)
					var drive:=preload("res://scripts/cultural_inheritance.gd").weight(WorldSimulation.direction.cultural_memory,"ambition","expansion",day)
					# Every culture can grow organically; expansionist traditions review more often.
					if WorldSimulation.direction.auto_settlement and (drive>=.35 or posmod(day/30,6)==0):controller.expansion_orders("player",controller.current_plan("player"))
	),
	]

## Each unoccupied secondary town is its own step, in settlement order.
static func _city_steps(build:Callable,secondary_timings:Dictionary,timings:Dictionary,label:String)->Array:
	var S=preload("res://scripts/day_job.gd")
	var result:Array=[]
	for city:Dictionary in WorldSimulation.state.player_settlements:
		if bool(city.get("primary",false)) or not String(city.get("occupied_by","")).is_empty():continue
		result.append(S.step(label,timings,func()->void:
			WorldSimulation.settlements.process_city_resources(String(city.id),context(city.position),build,secondary_timings)
		))
	return result

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
