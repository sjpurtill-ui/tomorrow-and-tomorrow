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

static func quote(destination:Vector2)->Dictionary:
	if WorldSimulation.state.settlement_site_committed:return {"error":"The settled population needs a founding convoy to move to another city."}
	var origin:=WorldSimulation.world.player_world_origin
	if not WorldSimulation.route_provider.is_valid():return {"error":"No geographic route assessment is available."}
	var route:Dictionary=WorldSimulation.route_provider.call(Vector3(origin.x,0,origin.y),Vector3(destination.x,0,destination.y))
	if not bool(route.get("valid",false)):return {"error":String(route.get("reason","No traversable route."))}
	var days:=maxf(.5,float(route.distance_km)/(SPEED_KM_DAY*float(route.terrain_modifier)))
	if days>endurance():return {"error":"The journey exceeds the population's provisions and foraging endurance."}
	if float(WorldSimulation.state.simulation_metrics.get("food_days",30))<2 and float(WorldSimulation.state.simulation_metrics.get("food_balance",-1))<0:return {"error":"Rebuild two days of marching provisions."}
	return {"ok":true,"origin":origin,"destination":destination,"duration_days":days,"elapsed":0.0,"active":true}

static func begin(destination:Vector2)->Dictionary:
	var result:=quote(destination)
	if result.has("error"):return result
	WorldSimulation.state.founding_journey=result.duplicate(true)
	WorldSimulation.state.convoy_traveling=true
	WorldSimulation.state.convoy_emergency_halt_reason=""
	return result

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
		WorldSimulation.state.convoy_traveling=false
		if halt:WorldSimulation.state.convoy_emergency_halt_reason="Poor health or insufficient provisions forced the journey to halt."
