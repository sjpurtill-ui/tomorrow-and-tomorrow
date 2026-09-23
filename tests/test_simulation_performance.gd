extends GdUnitTestSuite
const Clock=preload("res://scripts/simulation_clock.gd")

func after_test()->void:
	WorldSimulation.clear()

func test_calendar_counts_long_frames_using_wall_time()->void:
	var clock=Clock.new()
	assert_float(clock.take_days(0,3.0)).is_equal(0.0)
	# A half-second render stall must retain 1.5 days, even if the engine
	# reports its maximum frame delta of about 0.133 seconds.
	assert_float(clock.take_days(500000,3.0)).is_equal(1.0)
	assert_float(clock.take_days(500000,3.0)).is_equal(0.5)
	assert_float(clock.take_days(500000,3.0)).is_equal(0.0)

func test_pause_and_speed_changes_do_not_replay_old_debt()->void:
	var clock=Clock.new()
	clock.take_days(0,3.0);clock.take_days(500000,3.0)
	assert_float(clock.take_days(510000,0.0)).is_equal(0.0)
	assert_float(clock.take_days(9000000,0.0)).is_equal(0.0)
	assert_float(clock.take_days(9000000,1.0)).is_equal(0.0)
	assert_float(clock.take_days(9250000,1.0)).is_equal(.25)
	assert_float(clock.take_days(10000000,3.0)).is_equal(0.0)
	assert_float(clock.take_days(10100000,3.0)).is_equal_approx(.3, .000001)

func test_clock_limits_work_per_frame_and_ignores_machine_suspend()->void:
	var clock=Clock.new();clock.take_days(0,3.0)
	assert_float(clock.take_days(2000000,3.0)).is_equal(1.0)
	assert_float(clock.pending_days).is_equal(5.0)
	assert_float(clock.take_days(20000000,3.0)).is_equal(0.0)
	assert_float(clock.pending_days).is_equal(0.0)

func test_observer_copies_remain_independent_between_owners()->void:
	var source:={"id":"alpha","regions":[{"population":120,"controller":"alpha"}],"traits":{"care":.7}}
	var one:=WorldSimulation._updated_observer_view(source,{})
	var two:=WorldSimulation._updated_observer_view(source,{})
	one.regions[0].controller="player";one.traits.care=.2
	assert_str(source.regions[0].controller).is_equal("alpha")
	assert_str(two.regions[0].controller).is_equal("alpha")
	assert_float(two.traits.care).is_equal(.7)
	var refreshed:=WorldSimulation._updated_observer_view(source,one)
	assert_dict(refreshed).is_equal(source)
	refreshed.regions[0].population=90
	assert_int(source.regions[0].population).is_equal(120)

func test_map_snapshots_exclude_history_without_changing_claims()->void:
	WorldSimulation.create_actor("map_test",777)
	WorldSimulation.scoped("map_test",func()->void:
		WorldSimulation.state.settlement_site_committed=true
		WorldSimulation.state.settlement_completed=["Hearth Circle"]
		WorldSimulation.settlements.ensure_founded()
		var city:Dictionary=WorldSimulation.state.player_settlements[0]
		city["local_resources"]={"economic_ledger":[]}
		for i in 1000:city.local_resources.economic_ledger.append({"day":i,"amount":i*2.0,"note":"Past city economy"})
		var full:=WorldSimulation.settlements.settlement_network_snapshot(true)
		var map:=WorldSimulation.settlements.settlement_network_snapshot()
		assert_bool(map.settlements[0].has("local_resources")).is_false()
		assert_int(var_to_bytes(map).size()).is_less(var_to_bytes(full).size()/10)
		full.settlements[0].erase("local_resources");full.settlements[0].erase("population_state")
		assert_dict(map).is_equal(full)
		assert_int(city.local_resources.economic_ledger.size()).is_equal(1000)
	)

func test_society_save_excludes_only_regenerable_definitions()->void:
	var model=preload("res://scripts/society_model.gd").new()
	model.definitions_by_id={"stone_sorting":{"name":"Stone Selection"}}
	model.effect_totals={"tool_quality":.04}
	var payload:=SaveSystem._capture_reflected(model,SaveSystem.SOCIETY_REFLECT_SKIP)
	assert_bool(payload.has("definitions_by_id")).is_false()
	assert_dict(payload.effect_totals).is_equal({"tool_quality":.04})
	payload.definitions_by_id={"stale":{"name":"Stale saved cache"}}
	var restored=preload("res://scripts/society_model.gd").new()
	SaveSystem._apply_reflected(restored,payload,SaveSystem.SOCIETY_REFLECT_SKIP)
	assert_dict(restored.definitions_by_id).is_empty()
	assert_dict(restored.effect_totals).is_equal(model.effect_totals)

func test_closed_direction_popup_does_not_destroy_saved_choice()->void:
	var direction=preload("res://scripts/people_direction.gd").new()
	direction.ambition="makers";direction.chosen_century=0
	direction.panel=Control.new();direction.panel.free()
	var saved:=SaveSystem._capture_reflected(direction,[])
	assert_str(saved.ambition).is_equal("makers")
	assert_int(saved.chosen_century).is_equal(0)
	assert_bool(saved.has("panel")).is_false()
	direction.free()

func test_society_effects_normalize_axes_without_mutating_history()->void:
	var model=preload("res://scripts/societal_values_model.gd")
	var inputs:Array[Dictionary]=[{}, {"lived":{"centralization":-2.0,"openness":3.0},"official":{"centralization":.9},"history":[{"day":1,"event":"remembered"}]},model.initial_state("makers",4242,"player")]
	for state in inputs:
		var before:=state.duplicate(true)
		var normalized:Dictionary=model.normalize_state(state)
		for effect in ["cohesion","legitimacy","institutions","knowledge","adoption","ecology","security","trade"]:
			assert_float(model.simulation_effect(state,effect)).is_equal(model.simulation_effect(normalized,effect))
		assert_dict(state).is_equal(before)

func test_claim_shape_cache_keeps_exact_geometry_as_inputs_change()->void:
	var model=auto_free(preload("res://scripts/settlement_model.gd").new())
	var city:={"id":"cache_city","position":Vector2(20,30)}
	var drivers:={"access_axes":[{"kind":"river","direction":Vector2(1,2),"influence":.8}]}
	var cold:PackedVector2Array=model._claim_boundary(city,2.0,drivers)
	assert_array(model._claim_boundary(city,2.0,drivers)).is_equal(cold)
	city.position=Vector2(40,60)
	drivers.access_axes[0].direction=Vector2(-1,2)
	var updated:PackedVector2Array=model._claim_boundary(city,3.0,drivers)
	model._claim_shape_cache.clear()
	assert_array(model._claim_boundary(city,3.0,drivers)).is_equal(updated)
	assert_bool(updated==cold).is_false()

func test_weekly_food_forecast_is_deterministic_and_reads_current_stocks()->void:
	WorldSimulation.create_actor("food_cache",4242)
	WorldSimulation.scoped("food_cache",func()->void:
		var state:=WorldSimulation.state
		var food:=WorldSimulation.food
		var profile:={"position":Vector2(12,-80),"seasonality_c":18.0,"growing_season":.6,"rainfall_variability":.7,"precipitation":.6}
		state.player_settlements=[{"id":"home","primary":true,"environment_profile":profile}]
		var harvest:={"Fresh plants":30.0,"Fresh meat":10.0,"Fish":5.0,"Dry staples":12.0}
		var demand:={"total":55.0,"climate":2.0,"rationing":0.0}
		for day in [0,1,91,365,6000]:
			state.elapsed_days=day
			state.food_stocks[food.STORED]=float(day+25)
			var stocks:Dictionary=state.food_stocks.duplicate()
			var warm:=food._forecast(harvest,demand)
			assert_dict(food._forecast(harvest,demand)).is_equal(warm)
			assert_dict(state.food_stocks).is_equal(stocks)
			state.food_stocks[food.STORED]=float(day+2500)
			var changed:=food._forecast(harvest,demand)
			assert_float(float(changed[90].ending_rations)).is_greater(float(warm[90].ending_rations))
		assert_bool(SaveSystem._capture_reflected(food,SaveSystem.REFLECT_SKIP.FoodSystem).has("_access_cache")).is_false()
		assert_bool(SaveSystem._capture_reflected(food,SaveSystem.REFLECT_SKIP.FoodSystem).has("_lever_cache")).is_false()
	)

func test_society_presentation_cache_tracks_values_and_owns_its_results()->void:
	var model=preload("res://scripts/societal_values_model.gd")
	for state:Dictionary in [{},{"history":[{"day":3}]},model.initial_state("makers",444,"reader")]:
		for i in 3:
			var normalized:Dictionary=model.normalize_state(state)
			assert_dict(model.identity_snapshot(state)).is_equal(normalized.identity)
			assert_dict(model.architecture_snapshot(state)).is_equal(normalized.architecture)
			var returned:Dictionary=model.identity_snapshot(state)
			returned.traits.clear();returned.name="Changed by reader"
			assert_dict(model.identity_snapshot(state)).is_equal(normalized.identity)
			state["lived"]={"centralization":float(i)/2.0,"hierarchy":.9}

func test_candidate_existence_matches_foundation_and_material_eligibility()->void:
	WorldSimulation.create_actor("candidate_check",789)
	WorldSimulation.scoped("candidate_check",func()->void:
		var research:=WorldSimulation.discovery
		research.initialize()
		for day in [0,120,1000,7000]:
			for channel in research.catalog_by_channel:
				assert_bool(research._channel_has_candidate(channel,day)).is_equal(not research._best_candidate_for_channel(channel,day).is_empty())
	)

func test_shared_troop_catalog_keeps_every_observer_and_owner_independent()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("alpha",717);WorldSimulation.create_actor("beta",717)
	WorldSimulation.scoped("alpha",func()->void:
		WorldSimulation.state.elapsed_days=5
		WorldSimulation.world.scout_missions.assign([{"mission_id":1,"start_day":0,"return_day":20,"personnel":3,"route":[{"x":0.0,"z":0.0},{"x":100.0,"z":0.0}]}])
	)
	var views=preload("res://scripts/civilization_combat.gd")
	var catalog:Dictionary=views.troop_catalog()
	var beta:Array[Dictionary]=views.troop_views("beta",catalog)
	var player:Array[Dictionary]=views.troop_views("player",catalog)
	assert_int(views.troop_views("alpha",catalog).size()).is_equal(0)
	assert_int(beta.size()).is_equal(1);assert_int(player.size()).is_equal(1)
	assert_dict(beta[0]).is_equal(player[0])
	beta[0].route[0].x=500.0;beta[0].command_position.x=500.0
	assert_float(float(player[0].route[0].x)).is_equal(0.0)
	assert_float(float(catalog.alpha[0].command_position.x)).is_equal(50.0)
	WorldSimulation.scoped("alpha",func()->void:assert_float(float(WorldSimulation.world.scout_missions[0].route[0].x)).is_equal(0.0))

func test_cached_weekly_forecast_ages_its_shortage_until_the_next_refresh()->void:
	WorldSimulation.create_actor("aged_forecast",4242)
	WorldSimulation.scoped("aged_forecast",func()->void:
		var state:=WorldSimulation.state;var food:=WorldSimulation.food
		state.player_settlements=[{"id":"home","primary":true,"environment_profile":{"position":Vector2(0,-80)}}]
		state.food_stocks={food.FRESH:0.0,food.STORED:3000.0}
		var demand:={"total":55.0,"climate":0.0,"rationing":0.0}
		state.elapsed_days=10
		var fresh:=food._forecast({},demand)
		assert_int(int(fresh[90].first_shortage_day)).is_greater(30)
		state.simulation_metrics.food_forecast_day=10
		state.simulation_metrics.food_forecast_30=fresh[30];state.simulation_metrics.food_forecast_90=fresh[90]
		state.elapsed_days=13
		var aged:=food._forecast({},demand)
		assert_int(int(aged.day)).is_equal(10)
		assert_int(int(aged[90].first_shortage_day)).is_equal(int(fresh[90].first_shortage_day)-3)
		state.elapsed_days=17
		assert_int(int(food._forecast({},demand).day)).is_equal(17)
	)

func test_navigation_yields_daily_work_without_catchup_debt()->void:
	var clock=Clock.new()
	clock.take_days(0,3.0)
	clock.take_days(2000000,3.0)
	assert_float(clock.pending_days).is_equal(5.0)
	for frame in range(1,601):
		assert_float(clock.take_days(2000000+frame*16667,3.0,true)).is_equal(0.0)
	assert_float(clock.pending_days).is_equal(0.0)
	var released:=2000000+600*16667
	assert_float(clock.take_days(released,3.0)).is_equal(0.0)
	assert_float(clock.take_days(released+100000,3.0)).is_equal_approx(.3,.000001)
	assert_float(clock.pending_days).is_equal(0.0)
