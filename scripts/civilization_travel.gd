extends RefCounted
const SPEED_KM_DAY:=16.0
static func endurance()->float:
	var population:=maxf(1,WorldSimulation.state.population_exact)
	var food_days:=float(WorldSimulation.state.resource_stockpiles.get("Food",population*30))/population
	var workers:=float(WorldSimulation.state.population_allocations.get("Food",0))
	var produced:=float(WorldSimulation.state.simulation_metrics.get("food_production",workers*2.40))
	var need:=maxf(1,float(WorldSimulation.state.simulation_metrics.get("food_consumption",population)))
	var logistics:=clampf(float(WorldSimulation.state.population_allocations.get("Logistics",0))/maxf(1,population*.08),0,1)
	var ratio:=(produced/need)*(.38+logistics*.10)/1.14
	return 3650.0 if ratio>=.98 else maxf(2,food_days/maxf(.08,1-ratio)*.92)

static func advice()->Dictionary:
	var population:=maxf(1.0,WorldSimulation.state.population_exact)
	var food_days:=float(WorldSimulation.state.resource_stockpiles.get("Food",0.0))/population
	var supported_days:=endurance()
	var approximate_reach:=supported_days*SPEED_KM_DAY
	var journey:Dictionary=WorldSimulation.state.founding_journey
	var active:=bool(journey.get("active",false))
	if active:
		var remaining:=maxf(0.0,float(journey.get("duration_days",0.0))-float(journey.get("elapsed",0.0)))
		if food_days<3.0 or supported_days<remaining*1.05:
			return {"status":"STOP & FORAGE","ready":false,"should_stop":true,"tone":"danger","food_days":food_days,"supported_days":supported_days,"remaining_days":remaining,"approximate_reach_km":approximate_reach,"reason":"The Travel Council advises stopping on viable ground now: %.1f days remain in this leg, but current stores and route forage support about %.1f days." % [remaining,supported_days]}
		if supported_days<remaining*1.35:
			return {"status":"CAMP SOON","ready":true,"should_stop":false,"tone":"warn","food_days":food_days,"supported_days":supported_days,"remaining_days":remaining,"approximate_reach_km":approximate_reach,"reason":"The convoy can continue, but its margin is thin: %.1f supported days against %.1f days still planned. Choose the next viable camp before conditions worsen." % [supported_days,remaining]}
		return {"status":"CONTINUE","ready":true,"should_stop":false,"tone":"good","food_days":food_days,"supported_days":supported_days,"remaining_days":remaining,"approximate_reach_km":approximate_reach,"reason":"The Travel Council judges this leg supportable: about %.1f days of endurance for %.1f days remaining." % [supported_days,remaining]}
	var ready:=food_days>=7.0 and supported_days>=14.0
	return {"status":"READY TO CONTINUE" if ready else "KEEP FORAGING","ready":ready,"should_stop":false,"tone":"good" if ready else "warn","food_days":food_days,"supported_days":supported_days,"remaining_days":0.0,"approximate_reach_km":approximate_reach,"reason":"The camp now supports about %.1f travel days—roughly %.0f km on ordinary ground. Order the next leg when its route fits that reserve." % [supported_days,approximate_reach] if ready else "Remain camped while Food workers gather locally. Stores currently support about %.1f travel days—roughly %.0f km on ordinary ground." % [supported_days,approximate_reach]}

static func quote(destination:Vector2)->Dictionary:
	if WorldSimulation.state.settlement_site_committed:return {"error":"The settled population needs a founding convoy to move to another city."}
	var origin:=WorldSimulation.world.player_world_origin
	if not WorldSimulation.route_provider.is_valid():return {"error":"No geographic route assessment is available."}
	var route:Dictionary=WorldSimulation.route_provider.call(Vector3(origin.x,0,origin.y),Vector3(destination.x,0,destination.y))
	if not bool(route.get("valid",false)):return {"error":String(route.get("reason","No traversable route."))}
	var days:=maxf(.5,float(route.distance_km)/(SPEED_KM_DAY*float(route.terrain_modifier)))
	if days>endurance():return {"error":"This leg exceeds the convoy's current provisions and route-foraging endurance. Choose a nearer point in the black, camp there to forage, then continue."}
	if float(WorldSimulation.state.simulation_metrics.get("food_days",30))<2 and float(WorldSimulation.state.simulation_metrics.get("food_balance",-1))<0:return {"error":"Rebuild two days of marching provisions."}
	return {"ok":true,"origin":origin,"destination":destination,"duration_days":days,"elapsed":0.0,"active":true}

static func begin(destination:Vector2)->Dictionary:
	var result:=quote(destination)
	if result.has("error"):return result
	WorldSimulation.state.founding_journey=result.duplicate(true)
	WorldSimulation.state.convoy_traveling=true
	WorldSimulation.state.convoy_emergency_halt_reason=""
	return result

static func camp_to_forage()->Dictionary:
	if WorldSimulation.state.settlement_site_committed:return {"error":"The founding expedition has already committed to a settlement."}
	var journey:=WorldSimulation.state.founding_journey
	if not bool(journey.get("active",false)):return {"error":"The founding convoy is already stopped and can forage here while time advances."}
	var duration:=maxf(0.001,float(journey.get("duration_days",0.0)))
	var progress:=clampf(float(journey.get("elapsed",0.0))/duration,0.0,1.0)
	var origin:Vector2=journey.get("origin",WorldSimulation.world.player_world_origin)
	var destination:Vector2=journey.get("destination",origin)
	var position:=origin.lerp(destination,progress)
	WorldSimulation.world.record_player_travel(position)
	journey["active"]=false
	journey["camped_foraging"]=true
	journey["camped_day"]=float(WorldSimulation.state.elapsed_days)
	journey["camp_position"]=position
	WorldSimulation.state.founding_journey=journey
	WorldSimulation.state.convoy_traveling=false
	WorldSimulation.state.convoy_emergency_halt_reason=""
	var survey:Dictionary=WorldSimulation.world.record_founding_camp_survey(position)
	journey=WorldSimulation.state.founding_journey
	journey["camp_survey"]=survey
	WorldSimulation.state.founding_journey=journey
	return {"ok":true,"position":position,"progress":progress,"survey":survey,"message":"The founding convoy has camped in place. Food workers now forage while the party charts water, site conditions, and obvious surface resources within 6 km; growing stores extends the next travel leg."}

static func advance(days:float)->void:
	var journey:=WorldSimulation.state.founding_journey
	if not bool(journey.get("active",false)):return
	journey.elapsed=float(journey.elapsed)+days*clampf(float(WorldSimulation.state.simulation_metrics.get("travel_speed_factor",1)),.12,1)
	var progress:=clampf(float(journey.elapsed)/float(journey.duration_days),0,1)
	var point:Vector2=journey.origin.lerp(journey.destination,progress)
	WorldSimulation.world.record_player_travel(point)
	var metrics:=WorldSimulation.state.simulation_metrics
	var ratio:=float(metrics.get("food_balance",-1))+1.0
	var health:=float(metrics.get("health",WorldSimulation.state.population_health))
	var halt:=(float(metrics.get("food_days",0))<=.001 and ratio<.76 and float(metrics.get("food_shortage_days",0))>=6) or health<.30
	if halt or progress>=1:
		journey.active=false
		journey["camped_foraging"]=true
		journey["camped_day"]=float(WorldSimulation.state.elapsed_days)
		journey["camp_position"]=point
		WorldSimulation.state.founding_journey=journey
		WorldSimulation.state.convoy_traveling=false
		var survey:Dictionary=WorldSimulation.world.record_founding_camp_survey(point)
		journey=WorldSimulation.state.founding_journey
		journey["camp_survey"]=survey
		WorldSimulation.state.founding_journey=journey
		if halt:WorldSimulation.state.convoy_emergency_halt_reason="Poor health or insufficient provisions forced the journey to halt."
