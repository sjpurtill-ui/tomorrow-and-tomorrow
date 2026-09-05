extends GdUnitTestSuite

func before_test()->void:
	GameState.reset_for_new_world(74017)
	GameState.ensure_population_total(10000)
	GameState.settlement_site_committed=true
	CivilizationSystem.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world(); ForeignDiplomacy.ensure()
	FoodSystem.reset_for_new_world()
	MilitaryCampaign.settlement_defense={"stage":2,"integrity":1.0,"project_stage":-1,"project_progress":0.0,"project_work":0.0,"reserved_materials":{},"completed_day":0}
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.player_relation["at_war"]=true
	civ.player_relation["contact_level"]=2
	civ.player_relation["contact_intelligence"]=.8
	civ.player_relation["home_location_known"]=true

func _begin_home()->Dictionary:
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	MilitaryCampaign._create_civilization_threat({"source_civ_id":civ.id,"source_name":civ.name,"strength":1000,"technology":.2,"readiness":.8,"incident_kind":"campaign"},"defensive")
	return MilitaryCampaign.begin_siege()

func test_siege_starts_without_battle_or_population_duplication()->void:
	var population:=GameState.population_total
	var result:=_begin_home()
	assert_bool(result.get("ok",false)).is_true()
	assert_bool(MilitaryCampaign.active_engagement.is_empty()).is_true()
	assert_bool(MilitaryCampaign.active_threat.is_empty()).is_true()
	assert_int(GameState.population_total).is_equal(population)
	assert_bool(MilitaryCampaign.siege_snapshot().active).is_true()

func test_daily_progress_is_idempotent_and_supply_limits_endurance()->void:
	_begin_home()
	CivilizationSystem.civilizations[0]["food_days"]=0.0
	var population:=GameState.population_total
	GameState.elapsed_days=1; MilitaryCampaign.last_processed_day=1
	MilitaryCampaign._process_siege_day()
	var once:=MilitaryCampaign.active_siege.duplicate(true)
	MilitaryCampaign._process_siege_day()
	assert_dict(MilitaryCampaign.active_siege).is_equal(once)
	for day in range(2,8):
		GameState.elapsed_days=day; MilitaryCampaign.last_processed_day=day
		MilitaryCampaign._process_siege_day()
	assert_bool(MilitaryCampaign.active_siege.is_empty()).is_true()
	assert_int(MilitaryCampaign.siege_history.size()).is_equal(1)
	assert_int(GameState.population_total).is_equal(population)

func test_home_blockade_reduces_actual_harvest_without_deleting_stores()->void:
	FoodSystem.initialize()
	GameState.population_allocations["Food"]=100
	var normal:=FoodSystem._produce(GameState.effective_workers("Food"),1,1,false)
	var expected:=0.0
	for amount in normal.values(): expected+=float(amount)
	_begin_home(); MilitaryCampaign.active_siege["blockade"]=.75
	var result:=FoodSystem._process_local_day({},1,1)
	assert_float(float(result.food_production)).is_equal_approx(expected*.4,.001)
	assert_int(GameState.population_total).is_equal(10000)

func test_enemy_supply_public_view_uses_returned_observations_only()->void:
	_begin_home()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ["food_days"]=123.456
	var public:=MilitaryCampaign.siege_public_snapshot()
	assert_str(String(public.enemy_supply_assessment)).contains("No reliable")
	assert_str(JSON.stringify(public)).not_contains("123.456")
	CivilizationSystem.diplomatic_history=[{"civ_id":civ.id,"returned_day":2,"observations":["Visible food reserves appear precarious"]}]
	public=MilitaryCampaign.siege_public_snapshot()
	assert_int(int(public.enemy_supply_report_day)).is_equal(-1)
	assert_str(String(public.enemy_supply_assessment)).contains("No reliable")

func test_siege_save_json_roundtrip_and_bad_state_rollback()->void:
	_begin_home()
	var before:=MilitaryCampaign.active_siege.duplicate(true)
	var saved:Dictionary=JSON.parse_string(JSON.stringify(MilitaryCampaign.export_state()))
	var restored:=MilitaryCampaign.import_state(saved)
	assert_bool(restored.get("ok",false)).is_true()
	assert_str(String(MilitaryCampaign.active_siege.id)).is_equal(String(before.id))
	saved.active_siege["fatigue"]=-1
	var invalid:=MilitaryCampaign.import_state(saved)
	assert_bool(invalid.has("error")).is_true()
	assert_float(float(MilitaryCampaign.active_siege.fatigue)).is_equal(float(before.fatigue))
	saved=MilitaryCampaign.export_state(); saved.erase("active_siege"); saved.erase("siege_history")
	assert_bool(MilitaryCampaign.import_state(saved).get("ok",false)).is_true()
	assert_bool(MilitaryCampaign.active_siege.is_empty()).is_true()

func test_negotiation_cannot_lift_fresh_siege_without_agreed_conditions()->void:
	_begin_home()
	var identity:=String(MilitaryCampaign.active_siege.id)
	var rival:=String(MilitaryCampaign.active_siege.attacker_id)
	assert_bool(MilitaryCampaign.negotiated_siege_withdrawal(identity,rival).has("error")).is_true()
	var territory:=CivilizationSystem.player_territory_balance
	MilitaryCampaign.active_siege["fatigue"]=.8
	assert_bool(MilitaryCampaign.negotiated_siege_withdrawal(identity,rival).get("ok",false)).is_true()
	assert_float(CivilizationSystem.player_territory_balance).is_equal(territory)

func test_relieving_force_strength_changes_access_without_new_player_people()->void:
	_begin_home()
	var original:=MilitaryCampaign.active_siege.duplicate(true)
	var inputs:={"besiegers":1000,"defenders":200,"population":10000,"besieger_supply":1.0,"defender_food_days":20,"fortification":.4,"defender_relief":0}
	var unrelieved:=SiegeModel.advance(original,1,inputs)
	inputs.defender_relief=2000
	var relieved:=SiegeModel.advance(original,1,inputs)
	assert_float(float(relieved.blockade)).is_less(float(unrelieved.blockade))
	assert_dict(MilitaryCampaign.active_siege).is_equal(original)
	assert_int(GameState.population_total).is_equal(10000)

func test_billion_population_siege_retains_bounded_state_and_rejects_fake_receipts()->void:
	_begin_home()
	var original:=MilitaryCampaign.active_siege.duplicate(true)
	var huge:=SiegeModel.advance(original,1,{"besiegers":100000000,"defenders":50000000,"population":1000000000,"besieger_supply":.8,"defender_food_days":30,"defender_relief":0})
	assert_int(huge.size()).is_less(35)
	assert_bool(MilitaryCampaign.receive_siege_relief(String(original.id),"invented").get("ok",false)).is_false()
	assert_int((MilitaryCampaign.active_siege.relief as Array).size()).is_equal(0)

func _offensive_fixture()->Dictionary:
	GameState.resource_stockpiles["Food"]=1000000.0
	MilitaryCampaign.raise_recruits(200)
	MilitaryCampaign.start_training("levy","improvised",200)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()
	MilitaryCampaign.create_field_army(200)
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",String(region.id),.8,0,"army arrival","test"),0)
	var army:Dictionary=MilitaryCampaign.field_armies[0]
	army["location_id"]=String(region.id)
	army["position"]={"x":120.0,"z":75.0}
	return {"civ":String(civ.id),"region":String(region.id),"army":int(army.army_id)}

func test_offensive_requires_presence_locks_army_saves_and_returns_physically()->void:
	var fixture:=_offensive_fixture()
	MilitaryCampaign.field_armies[0]["location_id"]="player_home"
	assert_bool(MilitaryCampaign.start_offensive_siege(fixture.civ,fixture.region).has("error")).is_true()
	assert_bool(MilitaryCampaign.active_threat.is_empty()).is_true()
	MilitaryCampaign.field_armies[0]["location_id"]=fixture.region
	assert_bool(MilitaryCampaign.start_offensive_siege(fixture.civ,fixture.region).get("ok",false)).is_true()
	assert_bool(MilitaryCampaign.move_field_army(fixture.army,"player_home").has("error")).is_true()
	assert_bool(MilitaryCampaign.validate_state().is_empty()).is_true()
	assert_bool(MilitaryCampaign.import_state(JSON.parse_string(JSON.stringify(MilitaryCampaign.export_state()))).get("ok",false)).is_true()
	var malformed:=MilitaryCampaign.export_state()
	malformed.field_armies[0]["status"]="stationed"
	assert_bool(MilitaryCampaign.import_state(malformed).has("error")).is_true()
	var population:=GameState.population_total
	MilitaryCampaign.siege_order(String(MilitaryCampaign.active_siege.id),"withdraw")
	assert_str(String(MilitaryCampaign.field_armies[0].status)).is_equal("moving")
	assert_int(GameState.population_total).is_equal(population)
	assert_bool(MilitaryCampaign.validate_state().is_empty()).is_true()

func test_assault_uses_pressure_and_fatigue_without_resolving_twice()->void:
	var fixture:=_offensive_fixture()
	MilitaryCampaign.start_offensive_siege(fixture.civ,fixture.region)
	MilitaryCampaign.active_siege["pressure"]=.8
	MilitaryCampaign.active_siege["fatigue"]=.6
	var original_defense:=float(MilitaryCampaign.active_siege.threat.terrain_defense)
	var resolved:=MilitaryCampaign.threats_resolved
	assert_bool(MilitaryCampaign.siege_order(String(MilitaryCampaign.active_siege.id),"assault").get("ok",false)).is_true()
	assert_bool(MilitaryCampaign.active_siege.is_empty()).is_true()
	assert_bool(MilitaryCampaign.active_engagement.is_empty()).is_false()
	assert_float(float(MilitaryCampaign.active_engagement.terrain_defense)).is_less(original_defense)
	assert_int(MilitaryCampaign.threats_resolved).is_equal(resolved)
	assert_bool(MilitaryCampaign.validate_state().is_empty()).is_true()

func test_stores_buffer_civilian_starvation_and_real_monthly_reserves_decline()->void:
	var fixture:=_offensive_fixture()
	MilitaryCampaign.start_offensive_siege(fixture.civ,fixture.region)
	MilitaryCampaign.active_siege["blockade"]=.9
	var original:Dictionary=CivilizationSystem.civilizations[0].duplicate(true)
	original["food_capacity"]=float(original.population)*.9
	original["food_days"]=40.0
	var buffered:=CivilizationSystem._advance_civilization(original.duplicate(true))
	assert_float(float(buffered.food_days)).is_less(40.0)
	original["food_days"]=0.0
	var hungry:=CivilizationSystem._advance_civilization(original.duplicate(true))
	assert_float(float(hungry.deaths_last_turn)).is_greater(float(buffered.deaths_last_turn))
	assert_float(float(MilitaryCampaign.siege_effects_for_civilization(String(CivilizationSystem.civilizations[1].id)).food_output_multiplier)).is_equal(1.0)

func test_fortified_deadline_begins_siege_and_same_day_new_siege_has_new_identity()->void:
	_begin_home()
	var first_id:=String(MilitaryCampaign.active_siege.id)
	MilitaryCampaign._end_siege("Test ceasefire")
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	MilitaryCampaign._create_civilization_threat({"source_civ_id":civ.id,"source_name":civ.name,"strength":1000,"incident_kind":"campaign"},"defensive")
	MilitaryCampaign.active_threat["deadline_day"]=-1
	MilitaryCampaign._process_threat_day()
	assert_bool(MilitaryCampaign.active_siege.is_empty()).is_false()
	assert_str(String(MilitaryCampaign.active_siege.id)).is_not_equal(first_id)
	assert_bool(MilitaryCampaign.active_engagement.is_empty()).is_true()
