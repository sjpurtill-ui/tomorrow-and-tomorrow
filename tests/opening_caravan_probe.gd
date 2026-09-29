extends Node
## OPENING CARAVAN PROBE: the founding travellers on the real map of new worlds.
##
## The player's report (2026-09-28): "opening caravan movement is totally
## fucked, I click and click and it just sits there with no water and dies."
## The leader walked the people to ground with no water, stopped managing them
## on arrival, and then refused every order because the vessels were empty.
##
## For each seed, on the real map:
##   walk    a 15 km order ends where the people can drink, and nobody goes
##           thirsty in the days after;
##   stuck   a party that arrived on dry ground (an older save) is moved to
##           water before the vessels run out;
##   dry     an order given by a party with nothing to drink and empty vessels
##           is carried out (to water first), never refused;
##   clicks  orders to random ground 3-40 km away are mostly carried out.
## Prints OPENING_CARAVAN PASS and exits 0 when all hold. Seeds from
## OPENING_SEEDS (comma separated; about 70 s a seed) or one default seed.
const Leader:=preload("res://scripts/caravan_leader.gd")
const Travel:=preload("res://scripts/civilization_travel.gd")

var failures:Array[String]=[]
var map:Node

func _ready()->void:call_deferred("run")

func frames(count:int=2)->void:
	for index in count:await get_tree().process_frame

func expect(condition:bool,message:String)->void:
	if not condition:failures.append(message)

func run()->void:
	var started:=Time.get_ticks_msec()
	var seeds:Array=[741991]
	var env:=OS.get_environment("OPENING_SEEDS").strip_edges()
	if env!="":
		seeds=[]
		for part in env.split(","):seeds.append(int(part))
	for seed_value in seeds:await _one(int(seed_value))
	WorldSimulation.clear()
	print("OPENING_CARAVAN seeds %s in %.0f s" % [str(seeds),float(Time.get_ticks_msec()-started)/1000.0])
	if failures.is_empty():
		print("OPENING_CARAVAN PASS  walks end by water with no thirst, a dry arrival camp moves to water, a dry party's order is carried out")
		get_tree().quit(0)
	else:
		for failure in failures:print("OPENING_CARAVAN FAIL: "+failure)
		get_tree().quit(1)

## The same resets as the game's New world (local_terrain._restart_world).
func _new_world(seed_value:int)->void:
	GameState.reset_for_new_world(seed_value)
	DiscoverySystem.reset_for_new_world();ProgressionSystem.reset_for_new_world();PlanetEnvironment.reset_for_new_world()
	ResourceSystem.reset_for_new_world();EconomySystem.reset_for_new_world();SettlementModel.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world();AdvisorSystem.reset_for_new_world();FoodSystem.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	WorldFacts.reset_for_new_world();PronouncementInterpreter.reset_for_new_world()
	GameState.select_founding_focus("provision")

func _here()->Vector2:
	if not GameState.founding_journey.is_empty():return Travel.journey_position(GameState.founding_journey)
	return Vector2(map.settler_marker.position.x,map.settler_marker.position.z)

func _state()->String:
	var here:=_here()
	var caravan:Dictionary=GameState.founding_journey.get("caravan",{})
	return "day %d at (%.1f,%.1f) %s, water %.1f days, drinking %d%%, source %s km, %d people; %s" % [int(GameState.elapsed_days),here.x,here.y,String(caravan.get("mode","-")),float(GameState.water_metrics.get("days",0)),roundi(float(GameState.water_metrics.get("intake_ratio",0))*100.0),str(snappedf(float(GameState.water_metrics.get("source_distance_km",-1)),0.1)),int(GameState.population_total),String(caravan.get("intent",""))]

## Days pass on the real calendar; returns the thirst days seen.
func _days(count:int,label:String)->int:
	var thirsty:=0
	for day in count:
		map.advance_world_time(1.0)
		if float(GameState.water_metrics.get("intake_ratio",1.0))<0.98:thirsty+=1
		if OS.has_environment("OPENING_VERBOSE"):print("    %s: %s" % [label,_state()])
	return thirsty

func _boot(seed_value:int)->void:
	_new_world(seed_value)
	map=load("res://local_terrain.tscn").instantiate();add_child(map)
	await frames(3)
	map._set_game_speed(1)

func _free_map()->void:
	map.queue_free()
	await frames(3)

func _dry_point_near(center:Vector2,seed_value:int)->Variant:
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value+17
	for attempt in 200:
		var point:=center+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(4.0,20.0)
		var data:=Leader.sample(point)
		if Leader.water_known(data) and not Leader.drinkable(data) and bool(data.get("land",true)) and bool(map._settlement_surface_assessment(Vector3(point.x,0,point.y)).get("valid",false)):return point
	return null

func _one(seed_value:int)->void:
	# ---- walk: a plain order 15 km out ends where the people can drink
	await _boot(seed_value)
	var start:=_here()
	var walked:=false
	for spoke in 8:
		var destination:=start+Vector2.from_angle(TAU*float(spoke)/8.0)*15.0
		var result:Dictionary=WorldSimulation.submit("player",{"kind":"move","destination":destination})
		if result.has("error"):continue
		walked=true
		print("SEED %d walk: %s" % [seed_value,String(result.get("plan","")).substr(0,220)])
		break
	expect(walked,"seed %d: no 15 km order was carried out" % seed_value)
	var thirsty:=_days(16,"walk")
	var camp:=_here()
	print("  after 16 days: %s" % _state())
	expect(Leader.drinkable(Leader.sample(camp)),"seed %d: the walk ended where there is nothing to drink (%s)" % [seed_value,_state()])
	expect(float(GameState.water_metrics.get("source_distance_km",99.0))<=Leader.DRINK_KM+0.01,"seed %d: the water ledger finds no water within a day's carry of the camp (%s)" % [seed_value,_state()])
	expect(thirsty<=1,"seed %d: %d thirsty days after an ordinary walk" % [seed_value,thirsty])
	# ---- clicks: random ground 3-40 km away
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var refused:=0
	var reasons:Dictionary={}
	var here:=_here()
	var now:=Travel.situation()
	for index in 24:
		var point:=here+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(3.0,40.0)
		if not bool(map._settlement_surface_assessment(Vector3(point.x,0,point.y)).get("valid",false)):continue
		var camp_ground:=Leader.camp_ground(point,0.5)
		var plan:Dictionary={} if camp_ground.is_empty() else Leader.plan_route(here,camp_ground.point,{"daily_km":float(now.daily_km),"vessel_days":float(now.water_capacity_days),"competency":0.5,"start_water_days":float(now.water_days)})
		if not bool(plan.get("ok",false)):
			refused+=1
			var why:=String(plan.get("reason","no water near that ground")).substr(0,60)
			reasons[why]=int(reasons.get(why,0))+1
	print("  random ground: %d of 24 would be refused %s" % [refused,str(reasons)])
	await _free_map()
	# ---- stuck: an older save's party that arrived on dry ground
	await _boot(seed_value)
	start=_here()
	var dry:Variant=_dry_point_near(start,seed_value)
	expect(dry is Vector2,"seed %d: no dry ground found near the start to test" % seed_value)
	if dry is Vector2:
		var point:Vector2=dry
		var path:=[start,point]
		var plan:=Leader._finish_plan(path,Leader.profile_path(path),"direct",{"safe_dry_km":0.0,"daily_km":12.0,"vessel_days":2.0,"direct_km":start.distance_to(point),"direct_longest_dry_km":0.0},{"skip_route_provider":true})
		var record:=Leader.new_record("founding",Leader.choose_leader(0,"founding"),start,point,plan,float(GameState.elapsed_days))
		record["progress_km"]=float(record.total_km)
		record["mode"]="arrived"
		GameState.founding_journey={"origin":start,"destination":point,"duration_days":1.0,"elapsed":1.0,"active":false,"camped_foraging":true,"camp_position":point,"caravan":record}
		WorldSimulation.world.record_player_travel(point)
		map.travel_active=false
		var stuck_thirst:=_days(8,"stuck")
		var moved_to:=_here()
		print("SEED %d stuck at (%.1f,%.1f), %.1f km from water: %s" % [seed_value,point.x,point.y,float(Leader.sample(point).get("water_km",-1)),_state()])
		expect(Leader.drinkable(Leader.sample(moved_to)),"seed %d: the dry arrival camp was not moved to water (%s)" % [seed_value,_state()])
		expect(stuck_thirst<=2,"seed %d: %d thirsty days while leaving a dry camp" % [seed_value,stuck_thirst])
	await _free_map()
	# ---- dry: empty vessels, nothing to drink, then an order
	await _boot(seed_value)
	start=_here()
	dry=_dry_point_near(start,seed_value+1)
	if dry is Vector2:
		var point:Vector2=dry
		WorldSimulation.world.record_player_travel(point)
		map.settler_marker.position=Vector3(point.x,map._height_at(point.x,point.y),point.y)
		_days(1,"dry")
		GameState.resource_stockpiles["Freshwater"]=0.0
		var target:=point+(point-start).normalized()*10.0
		var result:Dictionary=WorldSimulation.submit("player",{"kind":"move","destination":target})
		print("SEED %d dry order: %s" % [seed_value,String(result.get("error",result.get("plan",""))).substr(0,220)])
		expect(not result.has("error"),"seed %d: a party with nothing to drink had its order refused: %s" % [seed_value,String(result.get("error",""))])
		var dry_thirst:=_days(8,"dry")
		print("  after 8 days: %s" % _state())
		expect(Leader.drinkable(Leader.sample(_here())),"seed %d: the dry party did not reach water (%s)" % [seed_value,_state()])
		expect(dry_thirst<=3,"seed %d: %d thirsty days getting a dry party to water" % [seed_value,dry_thirst])
	await _free_map()
