extends GdUnitTestSuite
## Marches weigh the ground (march_terrain.gd): hills, mountains, forest,
## marsh and rivers slow armies; passes, fords and roads are sought; the
## days stated are the days walked; rivals march by the same measure.

const March:=preload("res://scripts/march_terrain.gd")
const Route:=preload("res://scripts/army_land_route.gd")
const RR:=preload("res://scripts/rival_land_routes.gd")

var mode:="plain"

func _land(p:Vector2)->bool:
	return absf(p.x)<400.0 and absf(p.y)<400.0

func _ground(p:Vector2)->Dictionary:
	match mode:
		"hills": return {"h":0.3+0.2*sin(p.x*0.7),"slope":0.14,"wood":0.0,"wet":0.0}
		"forest": return {"h":0.2,"slope":0.0,"wood":1.0,"wet":0.0}
		"marsh": return {"h":0.05,"slope":0.0,"wood":0.0,"wet":1.0}
		"woods": return {"h":0.2,"slope":0.0,"wood":0.8,"wet":0.0}
		"range":
			# A mountain wall from x=15 to x=25, with a pass at z 10..16.
			if p.x>=15.0 and p.x<=25.0:
				if p.y>=10.0 and p.y<=16.0: return {"h":0.4,"slope":0.04,"wood":0.0,"wet":0.0}
				return {"h":3.0,"slope":0.6,"wood":0.0,"wet":0.0}
			return {"h":0.2,"slope":0.0,"wood":0.0,"wet":0.0}
	return {"h":0.2,"slope":0.0,"wood":0.0,"wet":0.0}

## A river along x=10, deep but for a ford at z 8..12.
var ford_open:=true
func _crossing(a:Vector2,b:Vector2)->String:
	if (a.x-10.0)*(b.x-10.0)>0.0 or is_equal_approx(a.x,b.x): return ""
	var t:=(10.0-a.x)/(b.x-a.x)
	var z:=lerpf(a.y,b.y,t)
	return "ford" if ford_open and z>=8.0 and z<=12.0 else "deep"

func before_test()->void:
	GameState.reset_for_new_world(551188);CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))
	CivilizationSystem.revealed_areas=[{"x":0.0,"z":0.0,"radius":300.0}]
	March.reset_overrides()
	March.ground_override=Callable(self,"_ground")
	March.use_roads_override=true
	Route.clear_cache()
	mode="plain"; ford_open=true
	MilitaryCampaign.field_armies=[_army(1)]

func after_test()->void:
	March.reset_overrides()
	Route.clear_cache()
	CivilizationSystem.set_scout_geography_authority(Callable())

func _army(id:int,unit:String="levy")->Dictionary:
	return {"army_id":id,"name":"Test Army","troops":40,"runner_count":1,"position":{"x":0.0,"z":0.0},"location_id":"player_home","status":"stationed","supply_level":1.0,"train":false,
		"formations":[{"unit":unit,"weapon":"improvised","count":40,"training":.6,"personnel_condition":1.0}]}

func _days_to(to:Vector2,force:Dictionary=MilitaryCampaign.field_armies[0])->Dictionary:
	Route.clear_cache()
	var road:=MilitaryCampaign.field_route(Vector2.ZERO,to,force)
	assert_bool(road.has("error")).override_failure_message(str(road)).is_false()
	return {"road":road,"days":MilitaryCampaign.march_days(force,road),"effort":float(road.effort_km),"km":float(road.length_km)}

func test_hills_are_slower_than_plains()->void:
	var plain:=_days_to(Vector2(60,0))
	mode="hills"
	var hills:=_days_to(Vector2(60,0))
	print("MARCH 60 km plains: %d days (%.1f level km); hills: %d days (%.1f level km)" % [plain.days,plain.effort,hills.days,hills.effort])
	assert_float(float(hills.effort)).is_greater(float(plain.effort)*1.3)
	assert_int(int(hills.days)).is_greater(int(plain.days))
	# Historical range: a levy on open ground makes roughly 10-25 km a day.
	assert_float(60.0/float(plain.days)).is_between(8.0,26.0)

func test_a_mountain_range_is_crossed_by_its_pass()->void:
	mode="range"
	var r:=_days_to(Vector2(40,0))
	var points:Array=r.road.points
	var crossed_at:=INF
	var prev:=Vector2.ZERO
	for p:Vector2 in points:
		if (prev.x-20.0)*(p.x-20.0)<=0.0 and prev.x!=p.x: crossed_at=lerpf(prev.y,p.y,(20.0-prev.x)/(p.x-prev.x))
		prev=p
	print("MARCH over the range: crossed x=20 at z=%.1f, %.1f km, %d days" % [crossed_at,r.km,r.days])
	assert_float(crossed_at).is_between(9.5,16.5)
	# The straight line over the peaks would be far worse.
	var line:=March.profile(Vector2.ZERO,[Vector2(40,0)],{"foot":1.0},Callable(self,"_land"))
	assert_float(float(line.effort_km)).is_greater(float(r.effort)*1.5)
	assert_str(March.ground_words(line)).contains("mountains")

func test_forest_and_marsh_are_slower()->void:
	var plain:=_days_to(Vector2(30,0))
	mode="forest"; var forest:=_days_to(Vector2(30,0))
	mode="marsh"; var marsh:=_days_to(Vector2(30,0))
	print("MARCH 30 km open %.1f / forest %.1f / marsh %.1f level km; days %d / %d / %d" % [plain.effort,forest.effort,marsh.effort,plain.days,forest.days,marsh.days])
	assert_float(float(forest.effort)).is_greater(float(plain.effort)*1.5)
	assert_float(float(marsh.effort)).is_greater(float(forest.effort))
	assert_int(int(marsh.days)).is_greater(int(plain.days))
	# Mounted men suffer more in marsh than foot.
	var foot:=March.class_factor({"wet":1.0},"foot"); var horse:=March.class_factor({"wet":1.0},"mounted"); var carts:=March.class_factor({"wet":1.0},"wheeled")
	assert_float(horse).is_greater(foot); assert_float(carts).is_greater(horse)

func test_a_ford_is_sought_and_deep_water_costs_days()->void:
	March.crossing_override=Callable(self,"_crossing")
	var r:=_days_to(Vector2(20,0))
	var crossed_at:=INF
	var prev:=Vector2.ZERO
	for p:Vector2 in r.road.points:
		if (prev.x-10.0)*(p.x-10.0)<=0.0 and prev.x!=p.x: crossed_at=lerpf(prev.y,p.y,(10.0-prev.x)/(p.x-prev.x))
		prev=p
	ford_open=false
	var deep:=_days_to(Vector2(20,0))
	print("MARCH 20 km across a river: by the ford at z=%.1f %d days (%.1f level km); no ford %d days (%.1f level km)" % [crossed_at,r.days,r.effort,deep.days,deep.effort])
	assert_float(crossed_at).is_between(7.5,12.5)
	assert_float(float(deep.effort)).is_greater(float(r.effort)+10.0)
	assert_int(int(deep.days)).is_greater(int(r.days))
	assert_str(String(r.road.get("ground_words",""))).contains("river")

func test_roads_are_faster()->void:
	mode="woods"
	var off:=_days_to(Vector2(40,0))
	March.roads_override=[{"a":Vector2(-2,0),"b":Vector2(42,0),"tier":2}]
	var on:=_days_to(Vector2(40,0))
	print("MARCH 40 km of woods: off road %d days (%.1f level km); made road %d days (%.1f level km)" % [off.days,off.effort,on.days,on.effort])
	assert_float(float(on.effort)).is_less(float(off.effort)*0.7)
	assert_int(int(on.days)).is_less(int(off.days))
	# A road a little off the line is still taken: the army goes round to it.
	March.roads_override=[{"a":Vector2(0,4),"b":Vector2(40,4),"tier":2}]
	var near:=_days_to(Vector2(40,0))
	assert_float(float(near.effort)).is_less(float(off.effort))

func test_the_stated_days_are_the_days_walked()->void:
	mode="hills"
	var order:=MilitaryCampaign.move_field_army_to_position(1,70,10)
	assert_bool(order.has("ok")).override_failure_message(str(order)).is_true()
	var stated:=int(order.days)
	var depart:=int(WorldSimulation.state.elapsed_days)
	var walked:=0
	while String(MilitaryCampaign.field_armies[0].status)=="moving" and walked<200:
		WorldSimulation.state.elapsed_days+=1
		MilitaryCampaign._process_field_army_movement_day()
		walked+=1
	print("MARCH stated %d days, walked %d days (%s)" % [stated,walked,String(order.message)])
	assert_int(absi(walked-stated)).is_less_equal(1)
	assert_str(String(MilitaryCampaign.field_armies[0].status)).is_equal("stationed")
	assert_float(float(MilitaryCampaign.field_armies[0].position.x)).is_equal_approx(70.0,0.01)
	# The card's "N days out" is the same reading while it marches.
	var again:=MilitaryCampaign.move_field_army_to_position(1,0,0)
	var card_days:=int(MilitaryCampaign.field_armies[0].arrival_day)-int(WorldSimulation.state.elapsed_days)
	assert_int(card_days).is_equal(int(again.days))
	WorldSimulation.state.elapsed_days+=1
	MilitaryCampaign._process_field_army_movement_day()
	var left:=int(MilitaryCampaign.field_armies[0].arrival_day)-int(WorldSimulation.state.elapsed_days)
	assert_int(absi(left-(int(again.days)-1))).is_less_equal(1)
	assert_int(depart).is_greater_equal(0)

func test_winter_slows_the_march_where_it_is_cold()->void:
	var mix:={"foot":1.0}
	# The season wave (PlanetEnvironment.season_wave): day 91 midsummer, day 274 midwinter here.
	var summer:=March.winter_factor(91,Vector2(0,-3000),0.3,mix)
	var winter:=March.winter_factor(274,Vector2(0,-3000),0.3,mix)
	assert_float(summer).is_equal(1.0)
	assert_float(winter).is_greater(summer)
	assert_float(March.winter_factor(355,Vector2(0,-3000),-1.0,mix)).is_equal(1.0)

func test_rivals_obey_the_same_costs()->void:
	CivilizationSystem.initialize()
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))
	var f:Dictionary={}
	for g:Dictionary in CivilizationSystem.foreign_formations:
		if String(g.kind)=="expedition": f=g; break
	assert_dict(f).is_not_empty()
	f.point_a=Vector2(0,0); f.point_b=Vector2(40,0); f.erase("route"); f.erase("command_position"); f.erase("formation_unit")
	mode="plain"; Route.clear_cache()
	RR.plan(f,Callable(self,"_land"))
	var flat_days:=float(f.leg_days)
	var g:=f.duplicate(true); g.erase("land_route_key")
	mode="range"; Route.clear_cache()
	RR.plan(g,Callable(self,"_land"))
	print("RIVAL 40 km: plains leg %.1f days, over the range (by its pass) %.1f days" % [flat_days,float(g.leg_days)])
	assert_float(float(g.leg_days)).is_greater(flat_days)
	var crossed:=false
	var road:=Route.unpack(g.land_route)
	for k in road.size()-1:
		if (road[k].x-20.0)*(road[k+1].x-20.0)<=0.0 and road[k].x!=road[k+1].x:
			var z:=lerpf(road[k].y,road[k+1].y,(20.0-road[k].x)/(road[k+1].x-road[k].x))
			crossed=z>=9.5 and z<=16.5
	assert_bool(crossed).is_true()
	# It moves slower where the ground is rough: halfway in time is not halfway in km.
	var mid:=RR.position(g,0.5)
	assert_bool(_land(mid)).is_true()
	assert_float(float(g.land_route_effort)).is_greater(float(g.land_route_km))
