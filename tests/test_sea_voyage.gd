extends GdUnitTestSuite
## Sea voyages (sea_voyage.gd): boats decide reach, the route sails water and
## walks land, and staff put to sea once the home country is charted.
const System=preload("res://scripts/civilization_system.gd")
const SeaVoyage=preload("res://scripts/sea_voyage.gd")
const COAST_BOATS:=["river_craft","hide_covered_boats","plank_extended_dugouts","sail_panel_cutting","sail_seaming","wayfinding_stars"]
const OCEAN_SHIPS:=["coastal_watercraft","mast_making","carvel_frame_construction","galley_navigation","ocean_sailing"]
var system:Node

## A small home island (x -40..0) and a far shore beyond `gap` km of sea.
static func _islands(gap:float)->Callable:
	return func(point:Vector2)->bool:return (point.x>=-40.0 and point.x<=0.0 and absf(point.y)<30.0) or point.x>gap

func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(112358);ProgressionSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();FoodSystem.reset_for_new_world()
	GameState.ensure_population_total(400);GameState.settlement_site_committed=true
	GameState.resource_stockpiles.Food=20000.0;GameState.food_stocks={"Preserved food":20000.0}
	system=auto_free(System.new());system.reset_for_new_world();system.register_player_origin(Vector2(-6.0,0.0))
	system.set_scout_geography_authority(_islands(60.0))

func after_test()->void:
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func _know(ids:Array)->void:
	for id:String in ids:
		if not id in GameState.known_discoveries:GameState.known_discoveries.append(id)
		GameState.discovery_adoption[id]=1.0

func _point(data:Dictionary)->Vector2:
	return Vector2(float(data.x),float(data.z))

func test_river_boats_cannot_put_to_sea_and_nothing_is_spent()->void:
	_know(["river_craft"])
	assert_bool(bool(SeaVoyage.capability().ok)).is_false()
	var food:=FoodSystem.total_stored()
	var quote:Dictionary=system.scout_mission_quote(90,"open_world","",0,false,"",false,true)
	assert_bool(bool(quote.can_dispatch)).is_false()
	assert_str(String(quote.blocker)).contains("rivers")
	assert_bool(system.dispatch_scouts(90,"open_world","",0,false,"",false,true).has("error")).is_true()
	assert_float(FoodSystem.total_stored()).is_equal(food)
	assert_array(system.scout_missions).is_empty()

func test_coastal_boats_cross_a_strait_land_and_walk_inland()->void:
	_know(COAST_BOATS)
	var craft:=SeaVoyage.capability()
	assert_bool(bool(craft.ok)).override_failure_message(str(craft)).is_true()
	assert_float(float(craft.offshore_km)).is_between(30.0,60.0)
	var quote:Dictionary=system.scout_mission_quote(90,"open_world","",0,false,"",false,true)
	assert_bool(bool(quote.can_dispatch)).override_failure_message(str(quote)).is_true()
	assert_str(String(quote.travel_mode)).is_equal("sea")
	var plan:Dictionary=quote.route_plan
	var route:Array=plan.route
	var voyage:Dictionary=plan.voyage
	assert_int(route.size()).is_less_equal(system.SCOUT_ROUTE_POINT_LIMIT)
	var landing_index:=int(voyage.landing_index)
	var landing:=_point(route[landing_index])
	# The far shore, not a beach of the home island.
	assert_float(landing.x).override_failure_message(str(route)).is_greater(60.0)
	assert_bool(system._scout_land_at(landing)).is_true()
	# Every sea leg is water; every step ashore is land.
	var voyage_planner:=SeaVoyage.new(system,Vector2(-6,0),craft)
	for k in range(int(voyage.sea_start)+1,landing_index):
		assert_bool(voyage_planner._sea_segment(_point(route[k-1]),_point(route[k]))).is_true()
	assert_int(route.size()-1-landing_index).is_greater(0)
	for k in range(landing_index+1,route.size()):
		assert_bool(system._scout_segment_is_land(_point(route[k-1]),_point(route[k]))).is_true()
	assert_float(float(voyage.shore_km)).is_greater(0.0)
	assert_float(float(voyage.sea_km)).is_greater(40.0)

func test_voyage_departs_returns_and_reports_by_sea()->void:
	_know(COAST_BOATS)
	var food:=FoodSystem.total_stored()
	var sent:Dictionary=system.dispatch_scouts(90,"open_world","",0,false,"",false,true)
	assert_bool(bool(sent.get("ok",false))).override_failure_message(str(sent)).is_true()
	assert_float(FoodSystem.total_stored()).is_less(food)
	var mission:Dictionary=system.scout_missions[0]
	assert_str(String(mission.travel_mode)).is_equal("sea")
	assert_bool(mission.voyage is Dictionary).is_true()
	assert_str(String(sent.message)).contains("by boat").contains("under sail")
	# The land audit leaves a voyage's sea legs alone.
	system._audit_active_scout_land_route()
	assert_str(String(system.scout_missions[0].route_status)).is_equal("outbound_and_returning")
	assert_array(system.validate_state()).is_empty()
	var saved:Dictionary=JSON.parse_string(JSON.stringify(mission))
	assert_str(String(saved.travel_mode)).is_equal("sea")
	system._complete_scout_mission(mission,int(mission.actual_return_day))
	assert_array(system.scout_missions).is_empty()
	var report:Dictionary=system.scout_reports[0]
	assert_str(String(report.travel_mode)).is_equal("sea")
	var journal:String=" ".join(PackedStringArray(report.journal))
	assert_str(journal).contains("They put to sea").contains("came ashore").contains("back to the boats")
	assert_str(String(system.last_scout_outcome.message)).contains("under sail")
	# The far shore is charted only on return.
	assert_bool(system.revealed_areas.size()>0).is_true()

func test_ocean_ships_cross_what_coastal_boats_cannot()->void:
	system.set_scout_geography_authority(_islands(300.0))
	_know(COAST_BOATS)
	var near:Dictionary=system.scout_mission_quote(180,"open_world","",0,false,"",false,true)
	var near_reaches:=bool(near.can_dispatch) and _point(near.route_plan.route[int(near.route_plan.voyage.landing_index)]).x>300.0
	assert_bool(near_reaches).override_failure_message(str(near.get("route_plan",{}))).is_false()
	_know(OCEAN_SHIPS)
	system.open_scout_plan_cache.clear()
	var far:Dictionary=system.scout_mission_quote(180,"open_world","",0,false,"",false,true)
	assert_bool(bool(far.can_dispatch)).override_failure_message(str(far)).is_true()
	assert_float(_point(far.route_plan.route[int(far.route_plan.voyage.landing_index)]).x).is_greater(300.0)
	assert_float(float(far.route_plan.voyage.open_km)).is_greater(100.0)

func test_staff_put_to_sea_once_the_home_island_is_charted()->void:
	_know(COAST_BOATS)
	system._add_revealed_area(Vector2(-20,0),70.0,"test: home island charted")
	system.scouting_staff.set_policy(.05,"exploration")
	for day in range(1,60,7):
		GameState.elapsed_days=day;system.scouting_staff.advance(day)
		if not system.scout_missions.is_empty():break
	assert_int(system.scout_missions.size()).override_failure_message(String(system.scouting_staff.data.status)).is_equal(1)
	assert_str(String(system.scout_missions[0].travel_mode)).is_equal("sea")
	assert_str(String(system.scouting_staff.data.status)).contains("put to sea")

func test_court_sea_order_sends_a_boat_party()->void:
	_know(COAST_BOATS)
	var sent:Dictionary=system.dispatch_scouts(90,"open_world","east",0,false,"",false,true)
	assert_bool(bool(sent.get("ok",false))).override_failure_message(str(sent)).is_true()
	var mission:Dictionary=system.scout_missions[0]
	assert_str(String(mission.ordered_heading)).is_equal("east")
	var landing:=_point(mission.route[int(mission.voyage.landing_index)])
	assert_float(landing.x).is_greater(60.0)

func test_a_harbour_on_the_waterline_launches_from_home()->void:
	_know(COAST_BOATS)
	system.register_player_origin(Vector2(0.4,0.0))
	assert_bool(system._scout_land_at(Vector2(0.4,0.0))).is_false()
	var quote:Dictionary=system.scout_mission_quote(90,"open_world","",0,false,"",false,true)
	assert_bool(bool(quote.can_dispatch)).override_failure_message(str(quote)).is_true()
	assert_float(float(quote.route_plan.voyage.walk_to_boat_km)).is_equal(0.0)
