extends GdUnitTestSuite

func before_test()->void:
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false
	CivilizationSystem.reset_for_new_world();CivilizationSystem.initialize();MilitaryCampaign.reset_for_new_world()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.strategic_regions[0].population=1000.0;civ.strategic_regions[0].resistance=.8
	civ.strategic_regions[0].controller="player"
	MilitaryCampaign.occupation_forces.append({"civ_id":civ.id,"region_id":civ.strategic_regions[0].id,"troops":5,"supply_level":1.0,"readiness":1.0})
func cid()->String:return String(CivilizationSystem.civilizations[0].id)
func rid()->String:return String(CivilizationSystem.civilizations[0].strategic_regions[0].id)

func test_tiny_presence_cannot_enforce_control_or_destructive_orders()->void:
	var before:=CivilizationSystem.civilizations.duplicate(true)
	assert_bool(CivilizationSystem.occupation_control(cid(),rid()).controlled).is_false()
	for order in ["raze","forced_labor","military_rule"]:
		assert_bool(CivilizationSystem.set_occupation_policy(cid(),rid(),order).has("error")).is_true()
	assert_bool(CivilizationSystem.occupation_resident_order(cid(),rid(),"kill_residents",1000).has("error")).is_true()
	assert_array(CivilizationSystem.civilizations).is_equal(before)
	assert_bool(CivilizationSystem.set_occupation_policy(cid(),rid(),"self_rule").has("ok")).is_true()

func test_viable_control_depends_on_supply_and_resistance()->void:
	MilitaryCampaign.occupation_forces[0].troops=100
	assert_bool(CivilizationSystem.occupation_control(cid(),rid()).controlled).is_true()
	assert_bool(CivilizationSystem.occupation_control(cid(),rid(),true).controlled).is_false()
	MilitaryCampaign.occupation_forces[0].supply_level=.1
	assert_bool(CivilizationSystem.occupation_control(cid(),rid()).controlled).is_false()

func test_unsupported_occupation_does_not_generate_production_income()->void:
	CivilizationSystem.civilizations[0].strategic_regions[0].role="works"
	assert_float(float(CivilizationSystem.player_effects().occupied_production_bonus)).is_equal(0.0)
	MilitaryCampaign.occupation_forces[0].troops=200
	assert_float(float(CivilizationSystem.player_effects().occupied_production_bonus)).is_greater(0.0)

func test_coercion_cooldown_survives_json_and_invalid_dates_are_rejected()->void:
	var model=preload("res://scripts/occupation_governance.gd")
	var region:=CivilizationSystem.region_snapshot(cid(),rid())
	region.governance=model.state(region);region.governance.last_coercive_day=12
	var restored:Dictionary=JSON.parse_string(JSON.stringify(region))
	assert_array(model.validate(restored)).is_empty()
	assert_int(int(restored.governance.last_coercive_day)).is_equal(12)
	restored.governance.last_coercive_day=-1
	assert_array(model.validate(restored)).is_not_empty()

func test_small_settlement_has_smaller_requirement_not_universal_minimum()->void:
	CivilizationSystem.civilizations[0].strategic_regions[0].population=20.0
	CivilizationSystem.civilizations[0].strategic_regions[0].resistance=.1
	assert_bool(CivilizationSystem.occupation_control(cid(),rid()).controlled).is_true()
	var low:=int(CivilizationSystem.occupation_control(cid(),rid()).required)
	CivilizationSystem.civilizations[0].strategic_regions[0].population=10000.0
	assert_int(int(CivilizationSystem.occupation_control(cid(),rid()).required)).is_greater(low*100)

func test_supported_coercion_cannot_repeat_or_exceed_free_personnel()->void:
	MilitaryCampaign.occupation_forces[0].troops=400
	assert_bool(CivilizationSystem.occupation_coercion_availability(cid(),rid(),1000).has("error")).is_true()
	assert_bool(CivilizationSystem.occupation_resident_order(cid(),rid(),"kill_residents",10).has("ok")).is_true()
	var after:=CivilizationSystem.civilizations.duplicate(true)
	assert_bool(CivilizationSystem.occupation_resident_order(cid(),rid(),"kill_residents",10).has("error")).is_true()
	assert_bool(CivilizationSystem.set_occupation_policy(cid(),rid(),"raze").has("error")).is_true()
	assert_array(CivilizationSystem.civilizations).is_equal(after)

func test_battle_victory_does_not_give_tiny_surviving_force_a_city()->void:
	var civ:Dictionary=CivilizationSystem.civilizations[0].duplicate(true)
	civ.strategic_regions[0].controller=civ.id;CivilizationSystem.civilizations[0]=civ
	var before:=civ.duplicate(true)
	var result:=CivilizationSystem._capture_region(civ,rid(),{"remaining_troops":5},{})
	assert_bool(result.outcome.get("region_captured",false)).is_false()
	assert_dict(result.civilization).is_equal(before)
	result=CivilizationSystem._capture_region(civ,rid(),{"remaining_troops":200,"supply_level":.05,"readiness":.4},{})
	assert_bool(result.outcome.get("region_captured",false)).is_false()
	result=CivilizationSystem._capture_region(civ,rid(),{"remaining_troops":200},{})
	assert_bool(result.outcome.get("region_captured",false)).is_true()

func test_perimeter_capacity_scales_and_starvation_does_not_power_empty_siege()->void:
	var inputs:={"population":1000,"defenders":100,"besiegers":5,"besieger_supply":1.0,"defender_food_days":0,"fortification":.5}
	assert_bool(SiegeModel.capacity(inputs).viable).is_false()
	var previous:={"last_day":0,"start_day":0,"pressure":0.0}
	var result:=SiegeModel.advance(previous,1,inputs)
	assert_float(float(result.blockade)).is_equal(0.0)
	assert_float(float(result.pressure)).is_equal(0.0)
	inputs.besiegers=250
	assert_bool(SiegeModel.capacity(inputs).viable).is_true()
	inputs.besieger_supply=.05
	assert_bool(SiegeModel.capacity(inputs).viable).is_false()
	inputs.population=100000;inputs.besieger_supply=1.0
	assert_bool(SiegeModel.capacity(inputs).viable).is_false()

func test_siege_entry_and_daily_recheck_reject_patrol_without_starting_war()->void:
	GameState.ensure_population_total(10000);GameState.resource_stockpiles["Food"]=1000000.0
	MilitaryCampaign.raise_recruits(200);MilitaryCampaign.start_training("levy","improvised",200)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true));MilitaryCampaign.training_queue.clear()
	MilitaryCampaign.create_field_army(200)
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.strategic_regions[0].controller=civ.id;civ.player_relation.at_war=false
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",rid(),.8,0,"army arrival","test"),0)
	var army:Dictionary=MilitaryCampaign.field_armies[0]
	army.location_id=rid();army.position=CivilizationSystem.city_intelligence.site(rid()).position;army.troops=5
	assert_bool(MilitaryCampaign.start_offensive_siege(cid(),rid(),int(army.army_id)).has("error")).is_true()
	assert_bool(civ.player_relation.at_war).is_false()
	assert_dict(MilitaryCampaign.active_siege).is_empty()
	var incident:=CivilizationSystem.offensive_campaign_data(cid(),5,rid());incident.field_army_id=army.army_id
	MilitaryCampaign._create_civilization_threat(incident,"offensive")
	assert_bool(MilitaryCampaign.begin_siege().has("error")).is_true()
	MilitaryCampaign.active_threat.clear();army.troops=200;army.supply_level=1.0;army.provision_ratio=1.0
	assert_bool(MilitaryCampaign.start_offensive_siege(cid(),rid(),int(army.army_id)).has("ok")).is_true()
	MilitaryCampaign.field_armies[0].troops=5
	GameState.elapsed_days=1;MilitaryCampaign.last_processed_day=1;MilitaryCampaign._process_siege_day()
	assert_dict(MilitaryCampaign.active_siege).is_empty()

func test_new_garrison_commits_enough_real_soldiers_for_effective_control()->void:
	MilitaryCampaign.occupation_forces.clear()
	GameState.ensure_population_total(10000);GameState.resource_stockpiles["Food"]=1000000.0
	MilitaryCampaign.raise_recruits(200);MilitaryCampaign.start_training("levy","improvised",200)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true));MilitaryCampaign.training_queue.clear()
	MilitaryCampaign.create_field_army(200)
	var army:Dictionary=MilitaryCampaign.field_armies[0];army.readiness=.5;army.supply_level=.8
	var required:=float(CivilizationSystem.occupation_control(cid(),rid()).required)
	var result:=MilitaryCampaign.establish_occupation_force(cid(),CivilizationSystem.region_snapshot(cid(),rid()),required,int(army.army_id))
	assert_bool(result.has("error")).is_false()
	assert_bool(CivilizationSystem.occupation_control(cid(),rid()).controlled).is_true()
	assert_int(int(result.troops)+int(MilitaryCampaign.field_armies[0].troops)).is_equal(200)
