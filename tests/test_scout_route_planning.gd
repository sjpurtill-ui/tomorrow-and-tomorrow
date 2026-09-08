extends GdUnitTestSuite
const System=preload("res://scripts/civilization_system.gd")
const Terrain=preload("res://scripts/local_terrain.gd")
var system:Node

func before_test()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(112358);MilitaryCampaign.reset_for_new_world();FoodSystem.reset_for_new_world()
	GameState.ensure_population_total(200);GameState.settlement_site_committed=true
	GameState.resource_stockpiles.Food=5000.0;GameState.food_stocks={"Preserved food":5000.0}
	system=auto_free(System.new());system.reset_for_new_world();system.register_player_origin(Vector2.ZERO)

func after_test()->void:
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func test_party_choice_searches_the_opposite_compass_sector()->void:
	var rng:=RandomNumberGenerator.new();rng.seed=42
	var expected:=RandomNumberGenerator.new();expected.seed=42
	var available_direction:=Vector2.RIGHT.rotated(expected.randf_range(-PI,PI)+PI)
	system.set_scout_geography_authority(func(point:Vector2)->bool:return point.length()<2.0 or point.normalized().dot(available_direction)>.96)
	var plan:Dictionary=system._plan_open_scout_route(1000.0,rng)
	assert_bool(bool(plan.get("ok",false))).override_failure_message(str(plan)).is_true()
	assert_float(float(plan.distance_km)).is_equal_approx(1000.0,.001)
	assert_bool(system._scout_route_is_land(plan.route)).is_true()
	var last:Dictionary=plan.route.back()
	assert_float(Vector2(last.x,last.z).normalized().dot(available_direction)).is_greater(.96)

func test_all_durations_can_choose_a_local_survey_on_a_small_island()->void:
	system.set_scout_geography_authority(func(point:Vector2)->bool:return point.length()<10.0)
	for duration in system.SCOUT_DURATIONS:
		var quote:Dictionary=system.scout_mission_quote(duration,"open_world")
		assert_bool(bool(quote.can_dispatch)).override_failure_message(str(quote)).is_true()
		assert_float(float(quote.planned_outward_km)).is_between(0.1,10.0)
		assert_float(float(quote.planned_outward_km)).is_less(float(quote.one_way_range_km)*.30)
		assert_float(float(quote.charted_route_km)).is_equal_approx(float(quote.planned_outward_km)*2.0,.001)
		assert_bool(system._scout_route_is_land(quote.route_plan.route)).is_true()

func test_automatic_quote_is_stable_and_departure_uses_the_quoted_route()->void:
	system.set_scout_geography_authority(func(point:Vector2)->bool:return point.x<20.0)
	var known:Dictionary=system.fog_snapshot().duplicate(true)
	var food:=FoodSystem.total_stored()
	for target in ["open_world","recruit_people"]:
		var quote:Dictionary=system.scout_mission_quote(30,target)
		var repeated:Dictionary=system.scout_mission_quote(30,target)
		assert_bool(bool(quote.can_dispatch)).is_true()
		assert_dict(quote.route_plan).is_equal(repeated.route_plan)
		assert_array(system.scout_missions).is_empty()
		assert_float(FoodSystem.total_stored()).is_equal(food)
		var sent:Dictionary=system.dispatch_scouts(30,target)
		assert_bool(bool(sent.get("ok",false))).override_failure_message(str(sent)).is_true()
		assert_array(system.scout_missions[0].route).is_equal(quote.route_plan.route)
		assert_float(float(system.scout_missions[0].planned_distance)).is_equal(float(quote.planned_outward_km))
		assert_float(FoodSystem.total_stored()).is_equal_approx(food-float(quote.provisions),.001)
		assert_dict(system.fog_snapshot()).is_equal(known)
		system.scout_missions.clear();food=FoodSystem.total_stored()

func test_no_local_route_is_blocked_in_preview_before_spending()->void:
	system.set_scout_geography_authority(func(point:Vector2)->bool:return point.length()<.1)
	var food:=FoodSystem.total_stored();var population:=GameState.population_exact
	var quote:Dictionary=system.scout_mission_quote(30)
	assert_bool(bool(quote.can_dispatch)).is_false()
	assert_bool(bool(quote.route_plan.get("ok",true))).is_false()
	assert_str(String(quote.blocker)).contains("walkable route from home")
	assert_bool(system.dispatch_scouts(30).has("error")).is_true()
	assert_float(FoodSystem.total_stored()).is_equal(food)
	assert_float(GameState.population_exact).is_equal(population)
	assert_array(system.scout_missions).is_empty()

func test_blocked_ordered_heading_does_not_silently_dispatch_the_other_way()->void:
	system.set_scout_geography_authority(func(point:Vector2)->bool:return point.x<=.1)
	var ordered:Dictionary=system.scout_mission_quote(30,"open_world","east")
	assert_bool(bool(ordered.can_dispatch)).is_false()
	assert_str(String(ordered.blocker)).contains("EAST").contains("another heading")
	assert_bool(system.dispatch_scouts(30,"open_world","east").has("error")).is_true()
	assert_bool(bool(system.scout_mission_quote(30).can_dispatch)).is_true()

func test_card_shows_planned_route_and_return_instead_of_theoretical_reach_or_safety()->void:
	var terrain:Node3D=auto_free(Terrain.new())
	var quote:Dictionary={"personnel":6,"provisions":99.0,"one_way_range_km":10000.0,"planned_outward_km":42.0,"route_plan":{"ok":true,"distance_km":42.0,"planned_heading":"west"},"risk":{"label":"LOW"},"can_dispatch":true}
	var card:String=terrain._scout_mission_card_text(30,quote)
	assert_str(card).contains("OUTWARD ROUTE ~42 KM").contains("WEST").contains("RETURN INCLUDED").contains("DANGERS UNKNOWN")
	assert_bool("REACH" in card or "RISK LOW" in card or "10.0K" in card).is_false()
	quote.can_dispatch=false;quote.route_plan={"ok":false};quote.blocker="No walkable route from home."
	var blocked:String=terrain._scout_mission_card_text(30,quote)
	assert_str(blocked).contains("BLOCKED").contains("No walkable route")
	assert_bool("OUTWARD ROUTE" in blocked).is_false()

func test_generated_home_geography_has_valid_previews_for_all_four_durations()->void:
	# The current session's last logged world seed. Use only generated terrain,
	# never load or write the player's campaign and never instantiate a scene.
	GameState.world_seed=1090456577
	system.reset_for_new_world()
	var terrain:Node3D=auto_free(Terrain.new())
	terrain._configure_shape();terrain._configure_noise();terrain._prepare_river_course()
	var home:Vector3=terrain._find_camp_position()
	system.register_player_origin(Vector2(home.x,home.z))
	system.set_scout_geography_authority(Callable(terrain,"_scout_land_at"))
	var start:=Time.get_ticks_msec()
	for duration in system.SCOUT_DURATIONS:
		var quote:Dictionary=system.scout_mission_quote(duration)
		assert_bool(bool(quote.can_dispatch)).override_failure_message(str(quote)).is_true()
		assert_bool(system._scout_route_is_land(quote.route_plan.route)).is_true()
		assert_float(float(quote.planned_outward_km)).is_less_equal(float(quote.one_way_range_km)+.001)
		print("SCOUT_PREVIEW duration=",duration," outward_km=",quote.planned_outward_km," heading=",quote.route_plan.get("planned_heading",""))
	print("SCOUT_FOUR_PREVIEWS_MSEC=",Time.get_ticks_msec()-start)

func test_toolbar_route_reuse_still_rechecks_supplies_and_geography_changes()->void:
	var calls:Dictionary={"count":0}
	system.set_scout_geography_authority(func(_point:Vector2)->bool:calls.count+=1;return true)
	var quote:Dictionary=system.scout_mission_quote(30)
	assert_bool(bool(quote.can_dispatch)).is_true()
	var samples:=int(calls.count)
	# A consumer's copy cannot change the next proposal or eventual departure.
	quote.route_plan.route.clear()
	var repeated:Dictionary=system.scout_mission_quote(30)
	assert_int(repeated.route_plan.route.size()).is_greater_equal(2)
	assert_int(int(calls.count)).is_equal(samples)
	GameState.resource_stockpiles.Food=0.0;GameState.food_stocks={}
	assert_bool(bool(system.scout_mission_quote(30).can_dispatch)).is_false()
	assert_int(int(calls.count)).is_equal(samples)
	GameState.resource_stockpiles.Food=5000.0;GameState.food_stocks={"Preserved food":5000.0}
	system.set_scout_geography_authority(func(_point:Vector2)->bool:return false)
	var changed:Dictionary=system.scout_mission_quote(30)
	assert_bool(bool(changed.can_dispatch)).is_false()
	assert_str(String(changed.blocker)).contains("departure point on land")
