extends GdUnitTestSuite
func before_test()->void:
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false
	GameState.ensure_population_total(200);GameState.settlement_completed=["Hearth Circle"];GameState.settlement_name="Old Home";GameState.settlement_site_committed=true
	CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();SettlementModel.reset_for_new_world();SettlementModel.ensure_founded()
	FoodSystem.reset_for_new_world();FoodSystem.initialize();FoodSystem.receive_external_food(100000)
	GameState.resource_stockpiles.Timber=1000.0
	CivilizationSystem.set_scout_geography_authority(func(_p:Vector2)->bool:return true)
	CivilizationSystem.set_ground_survey_authority(func(_p:Vector2)->Dictionary:return {"river_distance_km":2.0,"forage":.7,"fertility":.7})
	model().surface_assessor=func(_p:Vector3)->Dictionary:return {"valid":true}
	var civ:Dictionary=CivilizationSystem.civilizations[0];civ.player_relation.at_war=true
	MilitaryCampaign._create_civilization_threat({"source_civ_id":civ.id,"source_name":civ.name,"strength":1000,"incident_kind":"campaign"},"defensive")
	assert_bool(MilitaryCampaign.begin_siege().get("ok",false)).is_true()
func model():return MilitaryCampaign.recovery
func civ_id()->String:return String(CivilizationSystem.civilizations[0].id)
func prepare_success()->void:
	assert_bool(model().prepare(20,90).has("ok")).is_true()
	var seed_value:=GameState.world_seed^int(MilitaryCampaign.active_siege.threat.seed)
	for attempt in 100:
		var rng:=RandomNumberGenerator.new();rng.seed=seed_value^attempt*104729
		if rng.randf()<.70:model().data.attempts=attempt;break
	assert_bool(model().escape("east").get("escaped",false)).is_true()
func represented()->float:
	var count:=float(model().data.remnant.get("people",0))
	for city:Dictionary in GameState.player_settlements:count+=SettlementModel._settlement_population(city)
	return count
func test_preparation_reserves_real_supplies_and_cancels_without_population_change()->void:
	var people:=GameState.population_total;var food:=FoodSystem.total_stored();var timber:=float(GameState.resource_stockpiles.Timber)
	assert_bool(model().prepare(20,30).has("ok")).is_true()
	assert_float(FoodSystem.total_stored()).is_equal_approx(food-600,.001)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(timber-4,.001)
	assert_int(GameState.population_total).is_equal(people)
	assert_int(int(CivilizationSystem.player_population_commitments().total_absent)).is_equal(20)
	assert_float(model().defense_factor()).is_less(1.0)
	assert_bool(model().cancel_preparation().has("ok")).is_true()
	assert_float(FoodSystem.total_stored()).is_equal_approx(food,.001)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(timber,.001)
func test_escape_capture_travel_and_new_capital_conserve_people_and_knowledge()->void:
	GameState.known_discoveries.append("food_drying")
	var people:=GameState.population_total;var original:=SettlementModel._primary_settlement_id()
	prepare_success()
	assert_float(represented()).is_equal_approx(float(people),.001)
	assert_bool(model().capture(civ_id()).has("ok")).is_true()
	assert_bool(model().home_unavailable()).is_true()
	assert_float(represented()).is_equal_approx(float(people),.001)
	model().advance(3)
	assert_str(String(model().data.remnant.phase)).is_equal("camped")
	assert_bool(model().seek_site("east",32).has("ok")).is_true()
	model().advance(7)
	assert_dict(model().data.remnant).is_empty()
	assert_bool(model().home_unavailable()).is_false()
	assert_str(SettlementModel._primary_settlement_id()).is_not_equal(original)
	assert_str(String(SettlementModel.settlement_record(original).occupied_by)).is_equal(civ_id())
	assert_float(represented()).is_equal_approx(float(GameState.population_total),.001)
	assert_int(GameState.population_total).is_equal(people)
	assert_array(GameState.known_discoveries).contains("food_drying")
	assert_int(int(MilitaryCampaign.settlement_defense.stage)).is_equal(0)
	assert_array(SettlementModel.validate_settlement_network()).is_empty()
func test_intercepted_group_stays_in_population_and_cannot_duplicate_supplies()->void:
	assert_bool(model().prepare(20,30).has("ok")).is_true()
	MilitaryCampaign.active_siege.blockade=.9
	var seed_value:=GameState.world_seed^int(MilitaryCampaign.active_siege.threat.seed)
	for attempt in 100:
		var rng:=RandomNumberGenerator.new();rng.seed=seed_value^attempt*104729
		if rng.randf()>.4:model().data.attempts=attempt;break
	var before:=GameState.population_total
	assert_bool(model().escape("east").get("escaped",true)).is_false()
	assert_int(GameState.population_total).is_equal(before)
	assert_dict(model().data.remnant).is_empty()
	assert_dict(model().data.preparation).is_empty()
func test_occupied_decision_takes_time_and_persists()->void:
	assert_bool(model().capture(civ_id()).has("ok")).is_true()
	var id:=SettlementModel._primary_settlement_id()
	var before:=float(model().data.occupied[0].region.governance.support)
	assert_bool(model().queue_resistance(id,"organize").has("ok")).is_true()
	assert_float(float(model().data.occupied[0].region.governance.support)).is_equal(before)
	var saved:Dictionary=JSON.parse_string(JSON.stringify(model().data))
	assert_array(preload("res://scripts/siege_recovery.gd").validate(saved)).is_empty()
	model().data=saved;model().advance(30)
	assert_dict(model().data.occupied[0].order).is_empty()
	assert_float(float(model().data.occupied[0].region.governance.support)).is_greater(before)

func test_another_city_survives_without_receiving_captured_stores()->void:
	var original:=SettlementModel._primary_settlement_id()
	var second:Dictionary={"id":"settlement_002","sequence":2,"primary":false,"name":"Harbor","position":Vector2(100,0),"population_share":.25,"founded_day":0,"status":"established","territory_context":{},"environment_profile":{}}
	GameState.player_settlements.append(second);GameState.next_player_settlement_id=3;SettlementModel._ensure_city_resources(second)
	second.local_resources.resource_stockpiles.Timber=7.0
	assert_bool(model().capture(civ_id()).has("ok")).is_true()
	assert_str(SettlementModel._primary_settlement_id()).is_equal("settlement_002")
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(7.0)
	assert_float(float(SettlementModel.settlement_record(original).local_resources.resource_stockpiles.Timber)).is_equal(1000.0)
	assert_float(represented()).is_equal_approx(GameState.population_exact,.001)
	assert_bool(model().home_unavailable()).is_false()
func test_invalid_rebuilding_site_does_not_create_a_city()->void:
	prepare_success();model().capture(civ_id());model().advance(3)
	var count:=GameState.player_settlements.size()
	model().surface_assessor=func(_p:Vector3)->Dictionary:return {"valid":false,"reason":"River channel"}
	assert_bool(model().seek_site("east").has("error")).is_true()
	assert_int(GameState.player_settlements.size()).is_equal(count)
	assert_str(String(model().data.remnant.phase)).is_equal("camped")
