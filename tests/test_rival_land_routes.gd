extends GdUnitTestSuite
## Rival armies march by land: round bays, never across the sea, deterministic,
## bounded in cost, and saved.

const RR:=preload("res://scripts/rival_land_routes.gd")
const Route:=preload("res://scripts/army_land_route.gd")
const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")

var bay_centre:=Vector2.ZERO
var bay_radius:=0.0
var mode:="bay"

func _land(p:Vector2)->bool:
	match mode:
		"islands": return p.distance_to(Vector2(0,0))<4.0 or p.distance_to(Vector2(90,0))<4.0
		"coast":
			# A ragged continent with inland seas: land unless inside one of a few
			# fixed lakes and bays (deterministic, costs like terrain queries).
			for k in 12:
				var c:=Vector2(cos(k*1.7)*900.0,sin(k*2.3)*500.0)
				if p.distance_to(c)<180.0+60.0*sin(k): return false
			return true
	return p.distance_to(bay_centre)>bay_radius

func before_test()->void:
	GameState.reset_for_new_world(9091)
	CivilizationSystem.reset_for_new_world()
	CivilizationSystem.initialize()
	Route.clear_cache()
	mode="bay"
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))

func after_test()->void:
	CivilizationSystem.set_scout_geography_authority(Callable())
	Route.clear_cache()
	CivilizationSystem.reset_for_new_world()
	GameState.reset_for_new_world(9091)

func _expedition()->Dictionary:
	for f:Dictionary in CivilizationSystem.foreign_formations:
		if String(f.kind)=="expedition": return f
	return {}

func _across_bay(f:Dictionary)->void:
	f.point_a=Vector2(0,0); f.point_b=Vector2(90,20)
	bay_centre=Vector2(45,10); bay_radius=28.0
	f.erase("route"); f.erase("command_position")

func test_rival_march_goes_round_the_bay_and_never_enters_water()->void:
	var f:=_expedition()
	_across_bay(f)
	var straight_leg:=float(f.leg_days)
	assert_bool(RR.pending(f)).is_true()
	# Before its road is planned it holds at home, never on the water.
	assert_vector(CivilizationSystem._foreign_formation_position(f,float(f.depart_day)+straight_leg*0.5)).is_equal(Vector2(0,0))
	for day in 20:
		RR.advance(CivilizationSystem.foreign_formations,day)
		if not RR.pending(f): break
	assert_str(String(f.land_route_state)).is_equal("ok")
	assert_float(float(f.leg_days)).is_greater(straight_leg)
	var leg:=float(f.leg_days)
	for k in 101:
		var at:=CivilizationSystem._foreign_formation_position(f,float(f.depart_day)+leg*2.0*float(k)/100.0)
		assert_bool(_land(at)).override_failure_message("rival stood in water at %s" % at).is_true()
	var road:=Route.unpack(f.land_route)
	for k in road.size()-1:
		assert_bool(Route.segment_land(road[k],road[k+1],Callable(self,"_land"),0.05,0.0)).is_true()

func test_rival_with_no_land_route_stays_home()->void:
	mode="islands"
	var f:=_expedition()
	f.point_a=Vector2(0,0); f.point_b=Vector2(90,0); f.erase("route"); f.erase("command_position")
	RR.plan(f,Callable(self,"_land"))
	assert_str(String(f.land_route_state)).is_equal("none")
	for k in 21:
		assert_vector(CivilizationSystem._foreign_formation_position(f,float(k)*10.0)).is_equal(Vector2(0,0))

func test_planning_is_deterministic_for_a_seed()->void:
	var f:=_expedition(); _across_bay(f)
	var g:=f.duplicate(true)
	RR.plan(f,Callable(self,"_land"))
	Route.clear_cache()
	RR.plan(g,Callable(self,"_land"))
	assert_array(f.land_route).is_equal(g.land_route)
	assert_float(float(f.leg_days)).is_equal(float(g.leg_days))

func test_daily_planning_is_bounded_and_fast()->void:
	mode="coast"
	var formations:=CivilizationSystem.foreign_formations
	var managed:=0
	for f:Dictionary in formations:
		if RR.managed(f): managed+=1
	var days:=0; var worst_ms:=0.0; var total_ms:=0.0
	while days<200:
		var began:=Time.get_ticks_usec()
		var planned:=RR.advance(formations,days)
		var ms:=float(Time.get_ticks_usec()-began)/1000.0
		assert_int(planned).is_less_equal(RR.PLANS_PER_DAY)
		worst_ms=maxf(worst_ms,ms); total_ms+=ms
		days+=1
		if planned==0: break
		assert_int(int(Route.last_stats.get("expanded",0))).is_less_equal(Route.MAX_EXPANDED)
	print("RIVAL ROUTES %d managed formations planned in %d days; worst day %.1f ms, total %.1f ms" % [managed,days,worst_ms,total_ms])
	for f:Dictionary in formations:
		assert_bool(RR.pending(f)).override_failure_message(String(f.id)).is_false()
	# Planned days never repeat the work: the next day costs nothing.
	var again:=Time.get_ticks_usec()
	assert_int(RR.advance(formations,days+1)).is_equal(0)
	assert_float(float(Time.get_ticks_usec()-again)/1000.0).is_less(20.0)
	assert_float(worst_ms).is_less(3000.0)

func test_sighting_shows_heading_and_the_road_it_is_on()->void:
	var f:=_expedition(); _across_bay(f)
	RR.plan(f,Callable(self,"_land"))
	var seen:=RR.motion_at(f,float(f.depart_day)+float(f.leg_days)*0.3)
	assert_bool(bool(seen.moving)).is_true()
	assert_int((seen.road_ahead as Array).size()).is_greater_equal(2)
	for p in seen.road_ahead: assert_bool(_land(Vector2(float(p.x),float(p.z)))).is_true()
	# The war map's enemy arrow follows that road.
	var road:=Overlay._road_of(seen.road_ahead)
	var enemy:=[{"id":"e","pos":road[0],"strength":200.0,"age_days":0,"moving":true,"heading":float(seen.heading),"seen_day":0,"road":road}]
	var scene:=Overlay.compose({"mode":"host","stage":"reckoned","home":Vector2(-200,-200),"friendly":[],"enemy":enemy,"raids":[],"engagements":[]})
	var arrow:Dictionary={}
	for a:Dictionary in scene.arrows:
		if not bool(a.ours): arrow=a
	assert_dict(arrow).is_not_empty()
	for p:Vector2 in arrow.points: assert_bool(_land(p)).override_failure_message("enemy arrow over water at %s" % p).is_true()

func test_route_fields_survive_a_json_save_round_trip()->void:
	var f:=_expedition(); _across_bay(f)
	RR.plan(f,Callable(self,"_land"))
	var id:=String(f.id)
	var route:Array=f.land_route.duplicate(true)
	var parsed:Variant=JSON.parse_string(JSON.stringify(CivilizationSystem.export_state()))
	assert_bool(bool(CivilizationSystem.import_state(parsed).get("ok",false))).is_true()
	assert_array(CivilizationSystem.validate_state()).is_empty()
	var back:Dictionary={}
	for g:Dictionary in CivilizationSystem.foreign_formations:
		if String(g.id)==id: back=g
	assert_int((back.land_route as Array).size()).is_equal(route.size())
	for k in route.size():
		assert_float(float(back.land_route[k].x)).is_equal_approx(float(route[k].x),0.001)
		assert_float(float(back.land_route[k].z)).is_equal_approx(float(route[k].z),0.001)
	assert_bool(RR.pending(back)).is_false()

func test_no_survey_keeps_the_old_straight_line()->void:
	CivilizationSystem.set_scout_geography_authority(Callable())
	var f:=_expedition(); _across_bay(f)
	assert_int(RR.advance(CivilizationSystem.foreign_formations,1)).is_equal(0)
	var mid:=CivilizationSystem._foreign_formation_position(f,float(f.depart_day)+float(f.leg_days)*0.5)
	assert_vector(mid).is_equal_approx(Vector2(45,10),Vector2(0.01,0.01))
