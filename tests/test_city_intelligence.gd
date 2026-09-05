extends GdUnitTestSuite

func before_test()->void:
	GameState.reset_for_new_world(424242)
	SettlementModel.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world(); CivilizationSystem.initialize()
	MilitaryCampaign.reset_for_new_world(); ForeignDiplomacy.reset_for_new_world()
	GameState.initialize_population_model(); GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]; SettlementModel.ensure_founded()
	FoodSystem.reset_for_new_world(); FoodSystem.initialize(); FoodSystem.receive_external_food(10000)
	GameState.civic_api_enabled=false
	for civ:Dictionary in CivilizationSystem.civilizations:
		civ.player_relation.contact_level=2; civ.player_relation.opinion=.5

func intel(): return CivilizationSystem.city_intelligence
func civ()->Dictionary: return CivilizationSystem.civilizations[0]
func region(index:int=0)->String: return String(civ().strategic_regions[index].id)
func observe(city_id:String,quality:float=.8,day:int=10,observer:String="player")->void:
	intel().publish(observer,intel().capture(observer,city_id,quality,day,"test physical visit","test_visit"),day+2)

func test_one_city_does_not_reveal_its_siblings_and_known_locations_are_independent()->void:
	observe(region())
	assert_int(intel().known_cities().size()).is_equal(1)
	assert_int(CivilizationSystem.campaign_targets(String(civ().id)).size()).is_equal(1)
	assert_dict(intel().known("player",region(1))).is_empty()
	observe(region(1))
	assert_int(intel().known_cities().size()).is_equal(2)
	assert_bool(intel().known("player",region()).position!=intel().known("player",region(1)).position).is_true()
	assert_bool(intel().known("player",region()).name!=intel().known("player",region(1)).name).is_true()

func test_reports_freeze_hidden_values_and_age_without_reading_current_world()->void:
	GameState.elapsed_days=12; observe(region())
	var before:Dictionary=intel().known("player",region())
	civ().population*=10; civ().military_population*=20; civ().food_days=0
	civ().strategic_regions[0].population*=10; civ().strategic_regions[0].controller=String(CivilizationSystem.civilizations[1].id)
	assert_dict(intel().known("player",region())).is_equal(before)
	var later:Dictionary=intel().known("player",region(),400)
	assert_str(later.freshness).is_equal("stale")
	assert_float(float(later.fields.population.high)).is_greater(float(before.fields.population.high))
	assert_str(later.controller).is_equal(String(civ().id))
	observe(region(),.8,401)
	assert_str(intel().known("player",region(),403).controller).is_equal(String(CivilizationSystem.civilizations[1].id))

func test_low_quality_has_unknown_fields_not_fabricated_zeroes()->void:
	observe(region(),.3)
	var city:Dictionary=intel().known("player",region())
	assert_bool(city.fields.has("population")).is_true()
	assert_bool(city.fields.has("garrison") or city.fields.has("supply")).is_false()
	assert_str(intel().describe(city)).contains("Unknown")
	assert_str(city.name).is_equal("Unidentified settlement")

func test_scout_carries_observations_until_return_and_does_not_resample_on_delivery()->void:
	var mission:Dictionary={}
	var place:Dictionary=intel().site(region())
	intel().stage(mission,"player",intel().vector(place.position),.8,10,"outward_visit")
	assert_dict(intel().known("player",region())).is_empty()
	var saved:Dictionary=mission.city_observations[region()].duplicate(true)
	civ().strategic_regions[0].population*=10
	intel().deliver(mission,"player",40)
	var city:Dictionary=intel().known("player",region(),10)
	assert_dict(city.fields.population).is_equal(saved.fields.population.merged({"age_days":0,"stale":false}))
	assert_int(city.observed_day).is_equal(10)
	assert_int(city.reported_day).is_equal(40)

func test_reciprocal_observation_uses_same_thresholds_and_only_nearby_player_city()->void:
	var primary:=String(GameState.player_settlements[0].id)
	var distant:Dictionary=GameState.player_settlements[0].duplicate(true)
	distant.id="second_city"; distant.name="Distant Town"; distant.primary=false; distant.position=Vector2(9000,0); distant.population_share=.1
	GameState.player_settlements.append(distant)
	var party:Dictionary={}
	intel().stage(party,String(civ().id),intel().vector(intel().site(primary).position),.45,20,"foreign_scout")
	assert_array(intel().known_cities(String(civ().id))).is_empty()
	intel().deliver(party,String(civ().id),30)
	var city:Dictionary=intel().known(String(civ().id),primary,30)
	assert_bool(city.fields.has("population") and not city.fields.has("garrison") and not city.fields.has("supply")).is_true()
	assert_dict(intel().known(String(civ().id),"second_city")).is_empty()
	observe(region(),.45,20)
	assert_bool(intel().known("player",region()).fields.has("garrison")).is_false()

func test_ai_cannot_target_unknown_home_or_read_changed_live_player_strength()->void:
	var relation:Dictionary=civ().player_relation
	relation.at_war=true; relation.treaty="war"; relation.rival_contact_level=2; relation.rival_player_intelligence=1
	CivilizationSystem._queue_player_incident_if_due(civ(),relation,30)
	assert_array(CivilizationSystem.pending_player_incidents).is_empty()
	var primary:=String(GameState.player_settlements[0].id)
	observe(primary,.8,10,String(civ().id)); GameState.elapsed_days=20
	var before:Dictionary=intel().player_estimate(String(civ().id))
	var threat_before:=CivilizationSystem._external_threat(civ())
	GameState.population_exact*=10; MilitaryCampaign.home_army["troops"]=100000
	assert_dict(intel().player_estimate(String(civ().id))).is_equal(before)
	assert_float(CivilizationSystem._external_threat(civ())).is_equal(threat_before)
	CivilizationSystem._queue_player_incident_if_due(civ(),relation,30)
	assert_int(CivilizationSystem.pending_player_incidents.size()).is_equal(1)
	GameState.elapsed_days=500
	assert_bool(intel().player_estimate(String(civ().id)).known).is_false()

func test_migration_preserves_only_reported_home_without_inventing_statistics()->void:
	var capital:=region(4)
	civ().player_relation.home_location_known=true; civ().player_relation.home_position=intel().site(capital).position
	civ().player_relation.last_observed_day=10
	var saved:=CivilizationSystem.export_state(); saved.erase("city_intelligence")
	var result:=CivilizationSystem.import_state(saved)
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	assert_int(intel().known_cities().size()).is_equal(1)
	assert_dict(intel().known("player",capital).fields).is_empty()
	assert_dict(intel().known("player",region())).is_empty()

func test_bad_intel_import_is_atomic_and_actual_save_load_preserves_records()->void:
	observe(region()); GameState.elapsed_days=20
	var before:=CivilizationSystem.export_state()
	var bad:=before.duplicate(true); bad.city_intelligence.player[region()].fields.population.low=-1
	assert_bool(CivilizationSystem.import_state(bad).has("error")).is_true()
	assert_dict(CivilizationSystem.export_state()).is_equal(before)
	var slot:="city_intelligence_probe"
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	intel().records.clear()
	var result:=SaveSystem.load_game(slot)
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	# JSON round-trips Vector2-origin coordinates with decimal precision.
	var loaded:Dictionary=intel().records.player[region()]
	var expected:Dictionary=before.city_intelligence.player[region()]
	assert_float(float(loaded.position.x)).is_equal_approx(float(expected.position.x),.001)
	assert_float(float(loaded.position.z)).is_equal_approx(float(expected.position.z),.001)
	assert_dict(loaded.fields).is_equal(expected.fields)
	loaded.erase("position"); expected.erase("position")
	assert_dict(loaded).is_equal(expected)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))

func test_high_country_contact_does_not_unlock_unobserved_city_targets_or_live_assessment()->void:
	civ().player_relation.contact_intelligence=1; civ().player_relation.at_war=true; civ().player_relation.treaty="war"
	assert_array(CivilizationSystem.campaign_targets(String(civ().id))).is_empty()
	assert_bool(CivilizationSystem.offensive_campaign_data(String(civ().id),50,region()).has("error")).is_true()
	observe(region()); GameState.elapsed_days=20
	var before:=CivilizationSystem.strategic_assessment(String(civ().id),region())
	civ().military_population*=100
	assert_dict(CivilizationSystem.strategic_assessment(String(civ().id),region())).is_equal(before)
	assert_int(CivilizationSystem.military_movement_destinations().size()).is_equal(2)

func test_army_runner_delivers_frozen_city_observation_only_after_travel()->void:
	GameState.elapsed_days=10
	var place:Dictionary=intel().site(region())
	var army:Dictionary={"army_id":42,"name":"Test host","troops":20,"position":place.position,"status":"stationed","location_id":region(),"runner_count":2,"last_runner_departure_day":10,"last_report":{"day":0}}
	MilitaryCampaign.field_armies.append(army)
	MilitaryCampaign._dispatch_army_runner(army,10)
	assert_dict(intel().known("player",region())).is_empty()
	var expected:Dictionary=MilitaryCampaign.runner_messages[0].snapshot.city_observations[region()].fields.population.duplicate(true)
	civ().strategic_regions[0].population*=100
	GameState.elapsed_days=int(MilitaryCampaign.runner_messages[0].arrival_day)
	MilitaryCampaign._process_army_runners_day()
	assert_dict(intel().records.player[region()].fields.population).is_equal(expected)

func test_lost_scout_report_never_publishes_city_knowledge()->void:
	var mission:Dictionary={"mission_id":777,"personnel":0}
	intel().stage(mission,"player",intel().vector(intel().site(region()).position),.8,10,"lost scouts")
	CivilizationSystem.scout_missions.append(mission)
	CivilizationSystem._fail_player_scout_mission(mission,{"fate":"destroyed","civ_id":civ().id},30)
	assert_dict(intel().known("player",region())).is_empty()
	assert_array(CivilizationSystem.scout_missions).is_empty()

func test_real_foreign_scout_return_publishes_only_its_carried_observation()->void:
	var primary:=String(GameState.player_settlements[0].id)
	var home:Vector2=intel().vector(intel().site(primary).position)
	var scout:Dictionary={"id":"test_scout","civ_id":civ().id,"kind":"scout","point_a":home+Vector2(100,0),"point_b":home,"depart_day":0,"leg_days":30,"last_report_cycle":0,"disabled_until_day":0,"search_sequence":0}
	CivilizationSystem.foreign_formations.assign([scout])
	intel().sample_missions(30)
	assert_dict(intel().known(String(civ().id),primary)).is_empty()
	CivilizationSystem._process_foreign_scout_reports(60)
	assert_int(intel().known(String(civ().id),primary,60).observed_day).is_equal(30)

func test_unobserved_capital_and_hidden_rank_are_not_public()->void:
	var options:=CivilizationSystem.war_goal_options(String(civ().id))
	assert_str(String(options[1].target_region_id)).is_empty()
	GameState.known_discoveries.assign(["tallies","standard_measures","census_rolls","statistical_inference"])
	for discovery in GameState.known_discoveries: GameState.discovery_adoption[discovery]=1.0
	assert_int(CivilizationSystem.known_competition_snapshot().player_rank).is_equal(-1)

func test_location_only_report_supports_named_army_movement_without_revealing_controller()->void:
	var location:Dictionary=intel().location_record(intel().site(region()),20,"returned location","test")
	intel().publish("player",location,30)
	var destination:=MilitaryCampaign._movement_destination(region())
	assert_dict(destination).is_not_empty()
	assert_str(String(destination.controller)).is_empty()
	assert_bool(bool(destination.available_campaign)).is_false()
	assert_dict(intel().known("player",region()).fields).is_empty()
	MilitaryCampaign.field_armies=[{"army_id":991,"name":"Test","troops":6,"status":"stationed","location_id":"field_position","position":location.position.duplicate(true)}]
	assert_bool(MilitaryCampaign.move_field_army(991,region()).has("ok")).is_true()
	assert_str(String(MilitaryCampaign.field_armies[0].location_id)).is_equal(region())
	assert_int(int(MilitaryCampaign.field_armies[0].troops)).is_equal(6)
