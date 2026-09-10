extends GdUnitTestSuite
const System=preload("res://scripts/civilization_system.gd")
var system:Node
func before_test()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(112358);MilitaryCampaign.reset_for_new_world();FoodSystem.reset_for_new_world()
	GameState.ensure_population_total(200);GameState.settlement_site_committed=true
	GameState.resource_stockpiles.Food=10000.0;GameState.food_stocks={"Preserved food":10000.0}
	system=auto_free(System.new());system.reset_for_new_world();system.register_player_origin(Vector2.ZERO)
	system.set_scout_geography_authority(func(_point:Vector2)->bool:return true)
func after_test()->void:
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func test_policy_setting_and_repeated_views_never_move_spend_or_reveal()->void:
	var fog:Dictionary=system.fog_snapshot().duplicate(true);var food:=FoodSystem.total_stored()
	assert_bool(system.scouting_staff.set_policy(.05,"exploration").has("ok")).is_true()
	for i in 10:system.scouting_staff.snapshot();system.scout_mission_quote(30,"open_world","",4,true)
	assert_array(system.scout_missions).is_empty();assert_float(FoodSystem.total_stored()).is_equal(food)
	assert_dict(system.fog_snapshot()).is_equal(fog)
	assert_bool(system.scouting_staff.set_policy(.5,"exploration").has("error")).is_true()
	assert_bool(system.scouting_staff.set_policy(.05,"unknown").has("error")).is_true()
func test_staff_obey_allocation_depart_once_and_wait_for_returns()->void:
	system.scouting_staff.set_policy(.05,"exploration")
	for day in 28:
		GameState.elapsed_days=day;system.scouting_staff.advance(day)
		var count:int=system.scouting_staff.snapshot().away
		assert_int(count).is_less_equal(10)
		var food:=FoodSystem.total_stored();var parties:int=system.scout_missions.size()
		system.scouting_staff.set_policy(.06,"recruitment");system.scouting_staff.set_policy(.05,"exploration");system.scouting_staff.advance(day)
		assert_int(system.scout_missions.size()).is_equal(parties);assert_float(FoodSystem.total_stored()).is_equal(food)
	assert_int(system.scouting_staff.snapshot().away).is_greater(0)
	var party:Dictionary=system.scout_missions[0]
	assert_bool(party.staff_managed).is_true()
	var existing:Array=system.scout_missions.duplicate(true)
	system.scouting_staff.set_policy(0,"exploration");system.scouting_staff.advance(100)
	assert_array(system.scout_missions).is_equal(existing)
	# Return releases the actual commitment; the policy organizes a replacement.
	system.scout_missions.clear();system.scouting_staff.set_policy(.05,"exploration");system.scouting_staff.advance(101)
	assert_int(system.scout_missions.size()).is_equal(1)
	assert_str(system.scout_missions[0].target_kind).is_equal("explore")
func test_supply_and_founding_checks_prevent_unsustainable_departures()->void:
	system.scouting_staff.set_policy(.10,"exploration")
	GameState.settlement_site_committed=false;system.scouting_staff.advance(1)
	assert_array(system.scout_missions).is_empty()
	GameState.settlement_site_committed=true;GameState.resource_stockpiles.Food=100;GameState.food_stocks={"Preserved food":100}
	system.scouting_staff.advance(8);assert_array(system.scout_missions).is_empty()
	assert_float(FoodSystem.total_stored()).is_equal(100.0)
	GameState.resource_stockpiles.Food=10000;GameState.food_stocks={"Preserved food":10000}
	system.scouting_staff.advance(15);assert_int(system.scout_missions.size()).is_equal(1)
	assert_float(FoodSystem.total_stored()).is_greater(200*.9*7)
func test_wandering_is_a_physical_closed_route_with_no_remote_reveal()->void:
	var before:Dictionary=system.fog_snapshot().duplicate(true)
	var q:Dictionary=system.scout_mission_quote(30,"open_world","",4,true)
	assert_bool(q.can_dispatch).override_failure_message(str(q)).is_true()
	assert_bool(q.route_plan.get("circuit",false)).is_true()
	var route:Array=q.route_plan.route
	assert_int(route.size()).is_greater(5);assert_int(route.size()).is_less_equal(system.SCOUT_ROUTE_POINT_LIMIT)
	assert_dict(route[0]).is_equal(route[-1]);assert_bool(system._scout_route_is_land(route)).is_true()
	assert_float(system._scout_route_distance(route)).is_less_equal(system.scout_one_way_range(30)*2)
	system.dispatch_scouts(30,"open_world","",4,true)
	var party:Dictionary=system.scout_missions[0];var end:=int(party.actual_return_day)
	assert_vector(system.city_intelligence.mission_position(party,0)).is_equal(Vector2.ZERO)
	assert_vector(system.city_intelligence.mission_position(party,end)).is_equal(Vector2.ZERO)
	assert_vector(system.city_intelligence.mission_position(party,end*.25)).is_not_equal(system.city_intelligence.mission_position(party,end*.75))
	for day in end:system.city_intelligence.sample_missions(day)
	assert_dict(system.fog_snapshot()).is_equal(before)
	# The actual return reveals only a narrow trail, never the enclosed polygon.
	system.civilizations.clear();system._complete_scout_mission(party,end)
	assert_array(system.scout_missions).is_empty()
	var untouched:=Vector2(2000,2000)
	assert_bool(system._position_is_revealed(untouched)).is_false()
	assert_int(int(system.scout_reports[0].distance_km)).is_equal(roundi(system._scout_route_distance(route)))
func test_long_request_on_small_island_uses_short_trip_and_cost()->void:
	system.set_scout_geography_authority(func(point:Vector2)->bool:return point.length()<10)
	var q:Dictionary=system.scout_mission_quote(365,"open_world","",4,true)
	assert_bool(q.can_dispatch).is_true();assert_int(q.duration_days).is_equal(30)
	assert_float(float(q.provisions)).is_equal(4*30*.55)
func test_policy_and_circuit_survive_json_without_duplicate_departure()->void:
	system.scouting_staff.set_policy(.05,"exploration");system.scouting_staff.advance(0)
	var payload:Dictionary=JSON.parse_string(JSON.stringify(system.export_state()))
	var food:=FoodSystem.total_stored()
	var copy:Node=auto_free(System.new());copy.reset_for_new_world();copy.set_scout_geography_authority(func(_p:Vector2)->bool:return true)
	assert_bool(copy.import_state(payload).has("ok")).is_true()
	copy.scouting_staff.advance(0)
	assert_int(copy.scout_missions.size()).is_equal(system.scout_missions.size())
	assert_float(FoodSystem.total_stored()).is_equal(food)
	assert_bool(copy.scout_missions[0].get("circuit",false)).is_true()
	payload.scouting_staff.share=100
	assert_bool(copy.import_state(payload).has("error")).is_true()
func test_known_or_reserved_routes_lose_preference_without_peeking_at_foreign_state()->void:
	var explorer=preload("res://scripts/scout_frontier.gd").new(system,100,0)
	var route:Array[Dictionary]=[{"x":0.0,"z":0.0},{"x":100.0,"z":0.0}]
	var plan:Dictionary={"ok":true,"route":route}
	var fresh:float=explorer.score(plan)
	system.scout_missions.assign([{"route":route}])
	var next=preload("res://scripts/scout_frontier.gd").new(system,100,0)
	assert_float(next.score(plan)).is_less(fresh*.5)
func test_goodwill_requires_actual_returned_city_observation_and_has_revisit_cooldown()->void:
	system.initialize();var civ:Dictionary=system.civilizations[0];var id:=String(civ.id)
	var before:=float(civ.player_relation.opinion)
	var mission:Dictionary={"target_kind":"recruit_people","start_day":10}
	var empty:Array[Dictionary]=[]
	assert_array(system.scouting_staff.returned_influence(mission,empty,30)).is_empty()
	assert_float(float(civ.player_relation.opinion)).is_equal(before)
	var reports:Array[Dictionary]=[{"controller":id,"observed_day":20,"observation_days":4}]
	assert_int(system.scouting_staff.returned_influence(mission,reports,30).size()).is_equal(1)
	assert_float(float(civ.player_relation.opinion)).is_greater(before)
	assert_array(system.scouting_staff.returned_influence(mission,reports,31)).is_empty()

func test_spatial_index_matches_exact_old_chart_queries_including_large_diagonals()->void:
	system.revealed_areas.clear()
	system._add_revealed_area(Vector2(-20,-30),24,"test")
	system._add_revealed_trail([{"x":-100.0,"z":-100.0},{"x":8000.0,"z":8000.0}],18,"test",1)
	system._add_revealed_trail([{"x":100.0,"z":0.0},{"x":50.0,"z":170.0},{"x":-120.0,"z":200.0}],18,"test",1)
	var index=preload("res://scripts/scout_chart_index.gd").new(system.revealed_areas)
	var rng:=RandomNumberGenerator.new();rng.seed=909
	for i in 300:
		var point:=Vector2(rng.randf_range(-150,300),rng.randf_range(-150,300))
		assert_bool(index.contains(point)).is_equal(system._position_is_revealed(point))

func test_each_civilization_saves_its_own_policy_without_changing_the_player()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("scout_test",112358,Vector2(300,0))
	WorldSimulation.scoped("scout_test",func()->void:
		WorldSimulation.world.scouting_staff.set_policy(.08,"recruitment")
		WorldSimulation.world.scouting_staff.data.last_day=99
	)
	var payload:Dictionary=WorldSimulation.capture_actor("scout_test")
	assert_float(float(payload.scouting_staff.share)).is_equal(.08)
	assert_str(String(payload.scouting_staff.focus)).is_equal("recruitment")
	assert_int(payload.scouting_staff.last_day).is_equal(99)
	assert_float(float(CivilizationSystem.scouting_staff.data.share)).is_equal(0.0)
	WorldSimulation.clear()
