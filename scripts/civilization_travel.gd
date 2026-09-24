extends RefCounted
## The founding journey: the first caravan. The ruler picks a destination; the
## caravan leader (caravan_leader.gd) plans the route over real water, decides
## every camp and resumes on its own. The consequence engine still consumes the
## party's real food and water each day at the caravan's actual position.
const SPEED_KM_DAY:=16.0
const Leader:=preload("res://scripts/caravan_leader.gd")

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
	var result:Dictionary
	if active:
		var remaining:=maxf(0.0,float(journey.get("duration_days",0.0))-float(journey.get("elapsed",0.0)))
		if food_days<3.0 or supported_days<remaining*1.05:
			result={"status":"STOP & FORAGE","ready":false,"should_stop":true,"tone":"danger","food_days":food_days,"supported_days":supported_days,"remaining_days":remaining,"approximate_reach_km":approximate_reach,"reason":"The Travel Council advises stopping on viable ground now: %.1f days remain in this leg, but current stores and route forage support about %.1f days." % [remaining,supported_days]}
		elif supported_days<remaining*1.35:
			result={"status":"CAMP SOON","ready":true,"should_stop":false,"tone":"warn","food_days":food_days,"supported_days":supported_days,"remaining_days":remaining,"approximate_reach_km":approximate_reach,"reason":"The convoy can continue, but its margin is thin: %.1f supported days against %.1f days still planned. Choose the next viable camp before conditions worsen." % [supported_days,remaining]}
		else:
			result={"status":"CONTINUE","ready":true,"should_stop":false,"tone":"good","food_days":food_days,"supported_days":supported_days,"remaining_days":remaining,"approximate_reach_km":approximate_reach,"reason":"The Travel Council judges this leg supportable: about %.1f days of endurance for %.1f days remaining." % [supported_days,remaining]}
	else:
		var ready:=food_days>=7.0 and supported_days>=14.0
		result={"status":"READY TO CONTINUE" if ready else "KEEP FORAGING","ready":ready,"should_stop":false,"tone":"good" if ready else "warn","food_days":food_days,"supported_days":supported_days,"remaining_days":0.0,"approximate_reach_km":approximate_reach,"reason":"The camp now supports about %.1f travel days—roughly %.0f km on ordinary ground. Order the next leg when its route fits that reserve." % [supported_days,approximate_reach] if ready else "Remain camped while Food workers gather locally. Stores currently support about %.1f travel days—roughly %.0f km on ordinary ground." % [supported_days,approximate_reach]}
	# The caravan leader acts on this judgment; while a caravan is under way or in
	# one of its own camps, the leader's intent leads the council's text.
	var caravan:Dictionary=journey.get("caravan",{})
	if not caravan.is_empty() and String(caravan.get("mode",""))!="arrived":
		var status:=Leader.status(caravan)
		result["leader"]=String(status.leader)
		result["intent"]=String(status.intent)
		result["caravan_mode"]=String(status.mode)
		if String(status.intent)!="":result["reason"]="%s — %s. %s" % [String(status.leader),String(status.intent),String(result.reason)]
	return result

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

## Today's situation of the founding party, as the leader reads it.
static func situation(days:float=1.0)->Dictionary:
	var state=WorldSimulation.state
	var population:=maxf(1.0,float(state.population_exact))
	var water:Dictionary=state.water_metrics
	var need:=maxf(1.0,float(water.get("required_today",population)))
	var stored:=float(state.resource_stockpiles.get("Freshwater",0.0))
	var capacity_days:=float(water.get("capacity",0.0))/need if float(water.get("capacity",0.0))>0.0 else float(state.founding_manifest.get("water_vessel_days",3.0))
	var metrics:Dictionary=state.simulation_metrics
	var health:=float(metrics.get("health",state.population_health))
	var factor:=clampf(float(metrics.get("travel_speed_factor",1.0)),.12,1.0)
	if not bool(state.convoy_traveling):factor=clampf(.22+health*.46+float(state.food_security)*.24,.3,1.0)
	var caravan:Dictionary=state.founding_journey.get("caravan",{})
	var scale:=float(caravan.get("speed_scale",1.0))
	# The day's drinking is taken before the leader decides, so at dawn the
	# vessels hold at most one day less than their capacity.
	return {
		"population":population,"water_days":stored/need,"water_capacity_days":maxf(.5,capacity_days-1.0),
		"supported_days":endurance(),"food_days":float(state.resource_stockpiles.get("Food",0.0))/population,
		"health":health,"daily_km":SPEED_KM_DAY*scale*factor,"days":days,"day":float(state.elapsed_days),
	}

static func begin(destination:Vector2)->Dictionary:
	if WorldSimulation.state.settlement_site_committed:return {"error":"The settled population needs a founding convoy to move to another city."}
	var origin:=WorldSimulation.world.player_world_origin
	if not WorldSimulation.route_provider.is_valid():return {"error":"No geographic route assessment is available."}
	var previous:Dictionary=WorldSimulation.state.founding_journey.get("caravan",{})
	var leader:Dictionary=previous.get("leader",{})
	if leader.is_empty():leader=Leader.choose_leader(0,"founding")
	var now:=situation()
	var plan:=Leader.plan_route(origin,destination,{"daily_km":float(now.daily_km),"vessel_days":float(now.water_capacity_days),"competency":float(leader.get("competency",.5)),"start_water_days":float(now.water_days)})
	if not bool(plan.get("ok",false)):
		var refusal:={"error":"%s: %s" % [String(leader.get("name","The caravan leader")),String(plan.get("reason","We cannot reach that ground."))],"leader":String(leader.get("name","")),"refused":true}
		if plan.get("alternative") is Vector2:refusal["alternative"]=plan.alternative
		return refusal
	var caravan:=Leader.new_record("founding",leader,origin,destination,plan,float(WorldSimulation.state.elapsed_days))
	var journey:={"ok":true,"origin":origin,"destination":destination,"duration_days":maxf(.5,float(plan.days)),"elapsed":0.0,"active":true,"caravan":caravan}
	WorldSimulation.state.founding_journey=journey
	WorldSimulation.state.convoy_emergency_halt_reason=""
	Leader.departure(caravan,situation())
	_sync_journey(journey,caravan,origin)
	var result:=journey.duplicate()
	result.erase("caravan")
	result["ok"]=true
	result["plan"]=String(caravan.get("summary",""))
	result["leader"]=String(leader.get("name",""))
	result["path"]=(caravan.get("path",[]) as Array).duplicate()
	return result

## The ruler's halt. The leader obeys, but will not hold the party in dry
## country: when water runs short it moves to the nearest water and holds there.
static func camp_to_forage()->Dictionary:
	if WorldSimulation.state.settlement_site_committed:return {"error":"The founding expedition has already committed to a settlement."}
	var journey:=WorldSimulation.state.founding_journey
	var caravan:Dictionary=journey.get("caravan",{})
	var leader_camp:=not caravan.is_empty() and String(caravan.get("mode","")) in Leader.CAMP_MODES
	if not bool(journey.get("active",false)) and not leader_camp:return {"error":"The founding convoy is already stopped and can forage here while time advances."}
	var position:=journey_position(journey)
	WorldSimulation.world.record_player_travel(position)
	var message:="The founding convoy has camped in place. Food workers now forage while the party charts water, site conditions, and obvious surface resources within 6 km; growing stores extends the next travel leg."
	if not caravan.is_empty():
		message=Leader.hold(caravan)+" "+message
		journey["caravan"]=caravan
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
	var duration:=maxf(0.001,float(journey.get("duration_days",0.0)))
	return {"ok":true,"position":position,"progress":clampf(float(journey.get("elapsed",0.0))/duration,0.0,1.0),"survey":survey,"message":message}

## The ruler's word to march on after a halt (or to cut a leader's camp short).
static func resume()->Dictionary:
	if WorldSimulation.state.settlement_site_committed:return {"error":"The founding expedition has already committed to a settlement."}
	var journey:=WorldSimulation.state.founding_journey
	var caravan:Dictionary=journey.get("caravan",{})
	if caravan.is_empty() or String(caravan.get("mode",""))=="arrived":return {"error":"There is no journey to resume; choose a destination on the map."}
	var text:=Leader.resume(caravan,situation())
	journey["caravan"]=caravan
	_sync_journey(journey,caravan,Leader.position(caravan))
	WorldSimulation.state.founding_journey=journey
	return {"ok":true,"message":text}

## True while the founding caravan is marching or in one of its leader's own
## camps (not after arrival, and not on a ruler's hold).
static func underway()->bool:
	var caravan:Dictionary=WorldSimulation.state.founding_journey.get("caravan",{})
	if caravan.is_empty() or WorldSimulation.state.settlement_site_committed:return bool(WorldSimulation.state.founding_journey.get("active",false))
	return String(caravan.get("mode","")) in ["marching","seeking_hold","watering","foraging","resting","provisioning"]

## Where the journey physically is: along the leader's route, or the straight
## line of a journey recorded before caravan leaders existed.
static func journey_position(journey:Dictionary)->Vector2:
	var caravan:Dictionary=journey.get("caravan",{})
	if not caravan.is_empty() and not (caravan.get("path",[]) as Array).is_empty():
		if bool(journey.get("active",false)):_progress_from_elapsed(journey,caravan)
		return Leader.position(caravan)
	if journey.has("camp_position") and not bool(journey.get("active",false)):
		var camp:Variant=journey.camp_position
		if camp is Vector2:return camp
	var origin:Vector2=journey.get("origin",WorldSimulation.world.player_world_origin)
	var destination:Vector2=journey.get("destination",origin)
	var duration:=maxf(0.001,float(journey.get("duration_days",0.0)))
	return origin.lerp(destination,clampf(float(journey.get("elapsed",0.0))/duration,0.0,1.0))

## elapsed/duration_days stay the public progress contract (UI, tests, older
## readers); the leader's progress along the route follows them.
static func _progress_from_elapsed(journey:Dictionary,caravan:Dictionary)->void:
	var duration:=maxf(0.001,float(journey.get("duration_days",0.0)))
	caravan["progress_km"]=clampf(float(journey.get("elapsed",0.0))/duration,0.0,1.0)*float(caravan.get("total_km",0.0))

static func _sync_journey(journey:Dictionary,caravan:Dictionary,position:Vector2)->void:
	journey["origin"]=caravan.get("origin",position)
	journey["destination"]=caravan.get("destination",position)
	journey["duration_days"]=maxf(.5,float(caravan.get("planned_days",.5)))
	journey["elapsed"]=Leader.progress_ratio(caravan)*float(journey.duration_days)
	var mode:=String(caravan.get("mode",""))
	if mode in Leader.CAMP_MODES or mode=="held":
		journey["active"]=false
		journey["camped_foraging"]=true
		var previous:Variant=journey.get("camp_position",null)
		if not previous is Vector2 or (previous as Vector2).distance_to(position)>0.25:
			journey["camp_position"]=position
			journey["camped_day"]=float(WorldSimulation.state.elapsed_days)
		WorldSimulation.state.convoy_traveling=false
	elif mode!="arrived":
		journey["active"]=true
		journey["camped_foraging"]=false
		WorldSimulation.state.convoy_traveling=true

## Old saves: a journey in motion without a leader gains one, who replans from
## the party's present position to the same destination.
static func ensure_caravan(journey:Dictionary)->Dictionary:
	var caravan:Dictionary=journey.get("caravan",{})
	if not caravan.is_empty() or not bool(journey.get("active",false)):return caravan
	var here:=journey_position(journey)
	var destination:Vector2=journey.get("destination",here)
	var leader:=Leader.choose_leader(0,"founding")
	var now:=situation()
	var plan:=Leader.plan_route(here,destination,{"daily_km":float(now.daily_km),"vessel_days":float(now.water_capacity_days),"competency":float(leader.competency),"start_water_days":float(now.water_days)})
	if not bool(plan.get("ok",false)):
		plan=Leader._finish_plan([here,destination],Leader.profile_path([here,destination]),"direct",{"safe_dry_km":0.0,"daily_km":SPEED_KM_DAY,"vessel_days":float(now.water_capacity_days),"direct_km":here.distance_to(destination),"direct_longest_dry_km":0.0},{"skip_route_provider":true})
	caravan=Leader.new_record("founding",leader,here,destination,plan,float(WorldSimulation.state.elapsed_days))
	Leader.report(caravan,"departure","A caravan leader takes charge","%s now leads the journey. %s" % [String(leader.name),String(caravan.summary)],"notice",true,"migrated")
	journey["caravan"]=caravan
	journey["elapsed"]=0.0
	journey["duration_days"]=maxf(.5,float(caravan.planned_days))
	journey["origin"]=here
	return caravan

static func advance(days:float)->void:
	var journey:=WorldSimulation.state.founding_journey
	if journey.is_empty() or WorldSimulation.state.settlement_site_committed:return
	var caravan:=ensure_caravan(journey)
	if caravan.is_empty() or String(caravan.get("mode",""))=="arrived":return
	if bool(journey.get("active",false)):_progress_from_elapsed(journey,caravan)
	var result:=Leader.step(caravan,situation(days))
	journey["caravan"]=caravan
	var point:=Leader.position(caravan)
	if float(result.get("moved_km",0.0))>0.0:WorldSimulation.world.record_player_travel(point)
	if bool(result.get("arrived",false)):
		journey["duration_days"]=maxf(.5,float(caravan.get("planned_days",.5)))
		journey["elapsed"]=float(journey.duration_days)
		journey["active"]=false
		journey["camped_foraging"]=true
		journey["camped_day"]=float(WorldSimulation.state.elapsed_days)
		journey["camp_position"]=point
		WorldSimulation.state.founding_journey=journey
		WorldSimulation.state.convoy_traveling=false
		var survey:Dictionary=WorldSimulation.world.record_founding_camp_survey(point)
		journey=WorldSimulation.state.founding_journey
		journey["camp_survey"]=survey
		WorldSimulation.state.founding_journey=journey
		WorldSimulation.state.convoy_emergency_halt_reason=""
		return
	var was_camped:=bool(journey.get("camped_foraging",false))
	var previous_camp:Variant=journey.get("camp_position",null)
	_sync_journey(journey,caravan,point)
	WorldSimulation.state.founding_journey=journey
	WorldSimulation.state.convoy_emergency_halt_reason=""
	if bool(journey.get("camped_foraging",false)):
		var moved_camp:=not was_camped or not previous_camp is Vector2 or (previous_camp as Vector2).distance_to(point)>0.25
		if moved_camp:
			var survey:Dictionary=WorldSimulation.world.record_founding_camp_survey(point)
			journey=WorldSimulation.state.founding_journey
			journey["camp_survey"]=survey
			WorldSimulation.state.founding_journey=journey
