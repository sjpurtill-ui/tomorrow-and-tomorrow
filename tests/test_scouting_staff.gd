extends GdUnitTestSuite
const System=preload("res://scripts/civilization_system.gd")
var system:Node
func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(112358);ProgressionSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();FoodSystem.reset_for_new_world()
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

func test_nomadic_search_is_distinct_from_explicit_hostile_foreign_recruitment()->void:
	var open_option:Dictionary=system._scout_target_option("recruit_people")
	assert_str(String(open_option.kind)).is_equal("recruit_nomads")
	assert_str(String(open_option.label)).contains("NOMADIC")
	system.civilizations.append({"id":"neighbor","name":"Neighbor","player_relation":{"at_war":false},"strategic_regions":[]})
	system.city_intelligence.records.player={"town":{"city_id":"town","name":"Foreign Town","civ_id":"neighbor","controller":"neighbor","position":{"x":30.0,"z":0.0},"observed_day":0,"reported_day":0,"source":"physical visit","reference":"test","fields":{}}}
	var hostile:Dictionary=system._scout_target_option("recruit:town")
	assert_str(String(hostile.kind)).is_equal("recruit_people_visit")
	assert_str(String(hostile.label)).contains("HOSTILE")

func test_nomadic_bands_move_are_finite_and_end_at_world_urbanization()->void:
	system.nomad_sightings.append({"id":"nomads_1","day":0,"position":{"x":20.0,"z":0.0},"anchor":{"x":20.0,"z":0.0},"band_hint":"a family band","population":12,"attraction":.5,"wander_radius":10.0,"wander_period":360.0,"phase":0.0})
	assert_vector(system._nomad_position(system.nomad_sightings[0],0)).is_not_equal(system._nomad_position(system.nomad_sightings[0],90))
	assert_int(int(system.nomadic_recruitment_status().remaining_known)).is_equal(12)
	for civ in system.civilizations:
		civ["progression_tiers"]={"institutions":2,"infrastructure":2,"logistics":2}
	var status:Dictionary=system.nomadic_recruitment_status()
	assert_bool(status.available).is_false()
	assert_bool(status.urbanized).is_true()
	assert_str(String(status.message)).contains("no longer")

func test_organized_scouting_evolves_into_real_deposit_prospecting()->void:
	GameState.known_discoveries.append("ore_assaying")
	var option:Dictionary=system._scout_target_option("rare_resources")
	assert_str(String(option.kind)).is_equal("prospect_resources")
	var deposits_before:=GameState.resource_deposits.size()
	system.set_ground_survey_authority(func(_point:Vector2)->Dictionary:
		return {"biome":"hills","resource_potentials":{"Gold Ore":.92},"signature":"test-gold"})
	var mission:Dictionary={"target_kind":"prospect_resources","mission_id":91,"origin_position":{"x":0.0,"z":0.0},"discoveries":[]}
	var note:String=system._resolve_prospecting(mission,[{"x":0.0,"z":0.0},{"x":30.0,"z":0.0},{"x":60.0,"z":0.0},{"x":0.0,"z":0.0}],300)
	assert_int(GameState.resource_deposits.size()).is_equal(deposits_before+1)
	assert_str(String(GameState.resource_deposits[-1].resource)).is_equal("Gold Ore")
	assert_str(note).contains("gold")
	assert_int((mission.discoveries as Array).size()).is_equal(1)

func test_expansion_city_can_be_selected_as_the_physical_scout_origin()->void:
	GameState.player_settlements.append({"id":"rivermeet","name":"Rivermeet","position":Vector2(500,0),"primary":false,"population_share":.2,"occupied_by":"player"})
	assert_bool(bool(system.scouting_staff.set_origin("rivermeet").get("ok",false))).is_true()
	var quote:Dictionary=system.scout_mission_quote(30,"open_world","east",4,false,"rivermeet")
	assert_bool(bool(quote.get("can_dispatch",false))).override_failure_message(str(quote)).is_true()
	assert_str(String(quote.origin_label)).is_equal("Rivermeet")
	assert_dict(quote.route_plan.route[0]).is_equal({"x":500.0,"z":0.0})
	var sent:Dictionary=system.dispatch_scouts(30,"open_world","east",4,false,"rivermeet")
	assert_bool(bool(sent.get("ok",false))).override_failure_message(str(sent)).is_true()
	assert_str(String(system.scout_missions[0].origin_city_id)).is_equal("rivermeet")
	assert_str(String(system.scout_missions[0].origin_label)).is_equal("Rivermeet")
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
	var mission:Dictionary={"target_kind":"recruit_people_visit","start_day":10}
	var empty:Array[Dictionary]=[]
	assert_array(system.scouting_staff.returned_influence(mission,empty,30)).is_empty()
	assert_float(float(civ.player_relation.opinion)).is_equal(before)
	var reports:Array[Dictionary]=[{"controller":id,"observed_day":20,"observation_days":4}]
	assert_int(system.scouting_staff.returned_influence(mission,reports,30).size()).is_equal(1)
	assert_float(float(civ.player_relation.opinion)).is_greater(before)
	assert_float(float(preload("res://scripts/society_exchange.gd").known_relation(id).familiarity)).is_greater(0.0)
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

func report_community(id:String,position:Vector2)->void:
	system.initialize()
	system.civilizations.append({"id":id,"name":id.capitalize(),"world_position":position,"strategic_regions":[],"player_relation":{"opinion":.3,"at_war":false,"contact_level":2}})
	if not system.city_intelligence.records.has("player"):system.city_intelligence.records.player={}
	system.city_intelligence.records.player[id+"_city"]={"city_id":id+"_city","name":id.capitalize()+" Town","civ_id":id,"controller":id,"position":{"x":position.x,"z":position.y},"observed_day":0,"reported_day":0,"source":"physical visit","reference":"test","fields":{}}

func test_standing_recruitment_never_auto_targets_a_known_foreign_city()->void:
	GameState.housing_capacity=100;GameState.population_allocations.Administration=0
	report_community("nearby",Vector2(30,0))
	system.scouting_staff.set_policy(.05,"recruitment");system.scouting_staff.advance(0)
	assert_int(system.scout_missions.size()).is_equal(1)
	var party:Dictionary=system.scout_missions[0]
	assert_str(party.target_kind).is_equal("recruit_nomads")
	assert_str(String(party.target_city_id)).is_empty()
	assert_str(String(party.target_civ_id)).is_empty()
	assert_int(system.scouting_staff.snapshot().reception.capacity).is_equal(0)
	assert_str(system.scouting_staff.snapshot().reception.message).contains("Housing:")

func test_recruitment_without_known_communities_searches_without_creating_people()->void:
	system.initialize();system.city_intelligence.records.clear()
	var population:=GameState.population_exact;var fog:Dictionary=system.fog_snapshot().duplicate(true)
	system.scouting_staff.set_policy(.05,"recruitment");system.scouting_staff.advance(0)
	assert_int(system.scout_missions.size()).is_equal(1)
	assert_str(system.scout_missions[0].target_kind).is_equal("recruit_nomads")
	assert_str(system.scouting_staff.data.status).contains("wandering bands")
	assert_float(GameState.population_exact).is_equal(population)
	assert_dict(system.fog_snapshot()).is_equal(fog)
	assert_bool(system._scout_route_is_land(system.scout_missions[0].route)).is_true()

func test_staff_do_not_visit_a_known_community_beyond_ninety_days_reach()->void:
	var distance:float=system.scout_one_way_range(90)*1.1
	report_community("faraway",Vector2(distance,0))
	system.scouting_staff.set_policy(.05,"recruitment");system.scouting_staff.advance(0)
	assert_int(system.scout_missions.size()).is_equal(1)
	assert_str(system.scout_missions[0].target_kind).is_equal("recruit_nomads")
	assert_str(String(system.scout_missions[0].target_city_id)).is_empty()

func test_foreign_community_routes_do_not_affect_staff_nomad_search()->void:
	report_community("island",Vector2(20,0));report_community("connected",Vector2(0,60))
	system.set_scout_geography_authority(func(point:Vector2)->bool:return point.x<10)
	system.scouting_staff.set_policy(.05,"recruitment");system.scouting_staff.advance(0)
	assert_int(system.scout_missions.size()).is_equal(1)
	assert_str(system.scout_missions[0].target_kind).is_equal("recruit_nomads")
	assert_str(String(system.scout_missions[0].target_city_id)).is_empty()

func test_staff_fit_a_smaller_party_to_provisions_without_spending_home_reserve()->void:
	var reserve:=GameState.population_exact*.9*7
	GameState.resource_stockpiles.Food=reserve+34;GameState.food_stocks={"Preserved food":reserve+34}
	system.scouting_staff.set_policy(.10,"exploration");system.scouting_staff.advance(0)
	assert_int(system.scout_missions.size()).is_equal(1)
	assert_int(system.scout_missions[0].personnel).is_equal(2)
	assert_float(FoodSystem.total_stored()).is_greater_equal(reserve)

func test_one_person_allocation_explains_minimum_party_and_food_wait_is_precise()->void:
	system.scouting_staff.set_policy(.005,"recruitment");system.scouting_staff.advance(0)
	assert_array(system.scout_missions).is_empty()
	assert_str(system.scouting_staff.data.status).contains("at least 2")
	GameState.resource_stockpiles.Food=GameState.population_exact*.9*7+20
	GameState.food_stocks={"Preserved food":GameState.resource_stockpiles.Food}
	system.scouting_staff.set_policy(.05,"recruitment");system.scouting_staff.advance(1)
	assert_array(system.scout_missions).is_empty()
	assert_str(system.scouting_staff.data.status).contains("20 food available")
	assert_str(system.scouting_staff.data.status).contains("needs 33")

func test_exploration_can_cross_a_charted_neighborhood_to_a_more_distant_frontier()->void:
	system.initialize()
	# All routes possible under the old automatic 90-day budget are charted.
	var near:float=system.scout_one_way_range(90)*.58+40
	system._add_revealed_area(Vector2.ZERO,near,"previous expeditions")
	GameState.resource_stockpiles.Food=100000;GameState.food_stocks={"Preserved food":100000.0}
	system.scouting_staff.set_policy(.05,"exploration");system.scouting_staff.advance(0)
	assert_int(system.scout_missions.size()).override_failure_message(str(system.scouting_staff.data)).is_equal(1)
	var party:Dictionary=system.scout_missions[0]
	var reached:=false
	for point:Dictionary in party.route:
		if Vector2(point.x,point.z).length()>near:reached=true
	assert_bool(reached).is_true()

func test_scouting_status_and_reception_shortages_fit_narrow_panel()->void:
	CivilizationSystem.reset_for_new_world()
	CivilizationSystem.scouting_staff.set_policy(.05,"recruitment")
	GameState.housing_capacity=100;GameState.population_allocations.Administration=0
	GameState.simulation_metrics.food_days=5;GameState.water_metrics={"intake_ratio":.5}
	var panel_script=preload("res://scripts/hud/scouting_policy_panel.gd")
	for shape:Vector2i in [Vector2i(960,720),Vector2i(340,640)]:
		var viewport:=SubViewport.new();viewport.size=shape;add_child(viewport)
		var layer:=CanvasLayer.new();viewport.add_child(layer)
		var sheet=panel_script.new();layer.add_child(sheet)
		await await_idle_frame();await await_idle_frame()
		assert_bool(Rect2(Vector2.ZERO,shape).encloses(sheet.panel.get_global_rect())).is_true()
		assert_str(sheet.reception.text).contains("INVITATIONS ON HOLD")
		assert_str(sheet.reception.text).contains("Housing:")
		assert_bool(sheet.reception.size.x<=sheet.panel.size.x).is_true()
		assert_str(sheet.review.text).contains("next game day")
		viewport.queue_free();await await_idle_frame()
