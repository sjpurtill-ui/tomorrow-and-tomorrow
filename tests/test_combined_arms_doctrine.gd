extends GdUnitTestSuite
const D=preload("res://scripts/combined_arms_doctrine.gd")
const Sim=preload("res://scripts/combat_simulator.gd")
var sim:RefCounted
func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(414);DiscoverySystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	sim=auto_free(Sim.new())
func after_test()->void:
	GameState.elapsed_days=0;WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func group(unit:String,weapon:String,count:int=100)->Dictionary:
	return {"unit":unit,"weapon":weapon,"count":count,"equipment":count,"training":1.0}
func force()->Dictionary:
	return sim.create_formation_force("Combined force",[group("armored_formation","armored_vehicle"),group("rifle_infantry","service_rifle")])
func enemy()->Dictionary:
	return sim.create_formation_force("Antitank force",[group("anti_tank","anti_tank_kit",200)])
func rehearse(a:Dictionary,days:int=40)->Dictionary:
	for n in days:a=sim.advance_preparation_day(a,{"equipment_replacements":0,"manpower_replacements":0,"doctrine_levels":{"infantry_tank_cooperation":1.0},"doctrine_supply":1.0}).force
	return a
func test_authored_doctrines_have_real_rules_and_no_global_effects()->void:
	assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(D.entries(),DiscoverySystem.technology_catalog)).is_empty()
	for entry:Dictionary in D.entries():assert_dict(entry.effects).is_empty()
func test_research_enables_rehearsal_but_does_not_instantly_improve_combat()->void:
	var a:=force();var b:=enemy()
	GameState.known_discoveries.append("infantry_tank_cooperation");GameState.discovery_adoption.infantry_tank_cooperation=1.0
	assert_float(float(D.levels().infantry_tank_cooperation)).is_equal(1.0)
	assert_float(float(sim.evaluate_force(a,b)[0].doctrine_defense)).is_equal(1.0)
	var prepared:=rehearse(a)
	assert_float(float(sim.evaluate_force(prepared,b)[0].doctrine_defense)).is_equal(1.2)
	assert_float(float(sim.evaluate_force(prepared,b)[0].defense)).is_greater(float(sim.evaluate_force(a,b)[0].defense))
	assert_dict(a.formations[0].doctrines).is_empty()
func test_no_rehearsal_without_research_supply_or_supporting_troops()->void:
	var a:=force()
	assert_dict(sim.advance_preparation_day(a,{"doctrine_supply":1.0}).force.formations[0].doctrines).is_empty()
	assert_dict(sim.advance_preparation_day(a,{"doctrine_levels":{"infantry_tank_cooperation":1.0},"doctrine_supply":0.0}).force.formations[0].doctrines).is_empty()
	a.formations.pop_back()
	assert_dict(rehearse(a).formations[0].doctrines).is_empty()
func test_support_loss_or_empty_ammunition_removes_the_operating_benefit()->void:
	var a:=rehearse(force());var b:=enemy()
	a.formations[1].ammunition=0
	assert_float(float(sim.evaluate_force(a,b)[0].doctrine_defense)).is_equal(1.0)
	a=rehearse(force());a.formations[1].equipment=0
	assert_float(float(sim.evaluate_force(a,b)[0].doctrine_defense)).is_equal(1.0)
	a=rehearse(force());a.formations[1].count=0
	assert_float(float(sim.evaluate_force(a,b)[0].doctrine_defense)).is_equal(1.0)
func test_wrong_opponent_does_not_trigger_a_universal_armor_bonus()->void:
	var a:=rehearse(force())
	var b:Dictionary=sim.create_formation_force("Infantry",[group("rifle_infantry","service_rifle",200)])
	assert_float(float(sim.evaluate_force(a,b)[0].doctrine_defense)).is_equal(1.0)
func test_small_support_detachment_only_protects_a_fraction_of_the_force()->void:
	var a:=rehearse(force());a.formations[1].count=5
	var factor:float=sim.evaluate_force(a,enemy())[0].doctrine_defense
	assert_float(factor).is_greater(1.0);assert_float(factor).is_less(1.1)
func test_battle_normalization_preserves_rehearsal_and_changes_actual_losses()->void:
	var ordinary:=force();var prepared:=rehearse(ordinary);var b:=enemy()
	var ordinary_losses:=0;var prepared_losses:=0
	for seed in range(1,21):
		var first:Dictionary=sim.simulate(b,ordinary,{"seed":seed,"max_rounds":4})
		var second:Dictionary=sim.simulate(b,prepared,{"seed":seed,"max_rounds":4})
		ordinary_losses+=200-int(first.defender.remaining_troops)
		prepared_losses+=200-int(second.defender.remaining_troops)
	assert_int(prepared_losses).is_less(ordinary_losses)
func test_replacements_dilute_coordinated_practice_instead_of_inheriting_it_free()->void:
	var a:=rehearse(force());a.formations[0].count=50;a.reserve_manpower=50
	var rebuilt:Dictionary=sim.advance_preparation_day(a,{"manpower_replacements":100,"equipment_replacements":0}).force
	assert_int(int(rebuilt.formations[0].count)).is_greater(50)
	assert_float(float(rebuilt.formations[0].doctrines.infantry_tank_cooperation)).is_less(1.0)
func test_saved_practice_survives_and_malformed_values_are_rejected()->void:
	var a:=rehearse(force());var saved:Dictionary=JSON.parse_string(JSON.stringify(a))
	assert_bool(D.valid_tree(saved)).is_true()
	assert_float(float(sim.evaluate_force(sim._normalize_force(saved,"Saved"),enemy())[0].doctrine_defense)).is_equal(1.2)
	saved.formations[0].doctrines.infantry_tank_cooperation=3.0
	assert_bool(D.valid_tree(saved)).is_false()
	assert_bool(MilitaryCampaign.import_state({"home_army":saved}).has("error")).is_true()
func test_practice_ceiling_uses_the_current_civilizations_adoption()->void:
	GameState.known_discoveries.append("infantry_tank_cooperation");GameState.discovery_adoption.infantry_tank_cooperation=.25
	var a:=force()
	for n in 40:a=sim.advance_preparation_day(a,{"doctrine_levels":D.levels(),"doctrine_supply":1.0}).force
	assert_float(float(a.formations[0].doctrines.infantry_tank_cooperation)).is_equal(.25)
	WorldSimulation.create_actor("neighbor",414,Vector2(30,0))
	var levels:Dictionary=WorldSimulation.scoped("neighbor",func()->Dictionary:return D.levels())
	assert_dict(levels).is_empty()

func test_each_doctrine_needs_its_specific_target_support_and_threat()->void:
	var cases:=[
		["skirmisher_infantry_screens","spearman","spear","skirmisher","bow","cavalry","lance"],
		["engineer_infantry_security","combat_engineer","engineering_kit","rifle_infantry","service_rifle","machine_gun_company","machine_gun"],
		["infantry_antitank_coordination","rifle_infantry","service_rifle","anti_tank","anti_tank_kit","armored_formation","armored_vehicle"],
		["cavalry_infantry_liaison","cavalry","lance","spearman","spear","pikeman","pike"],
		["gun_line_security","field_artillery","field_gun","rifle_infantry","service_rifle","cavalry","lance"],
		["infantry_tank_cooperation","armored_formation","armored_vehicle","rifle_infantry","service_rifle","anti_tank","anti_tank_kit"]
	]
	assert_int(cases.size()).is_equal(D.RULES.size())
	for example:Array in cases:
		var a:Dictionary=sim.create_formation_force("Mixed",[group(example[1],example[2]),group(example[3],example[4])])
		var b:Dictionary=sim.create_formation_force("Threat",[group(example[5],example[6])])
		assert_float(float(sim.evaluate_force(a,b)[0].doctrine_defense)).is_equal(1.0)
		for n in 40:a=sim.advance_preparation_day(a,{"doctrine_levels":{example[0]:1.0},"doctrine_supply":1.0}).force
		assert_float(float(sim.evaluate_force(a,b)[0].doctrine_defense)).is_equal(1.0+float(D.RULES[example[0]].defense))
		var unrelated:Dictionary=sim.create_formation_force("Unrelated threat",[group("levy","improvised")])
		assert_float(float(sim.evaluate_force(a,unrelated)[0].doctrine_defense)).is_equal(1.0)
		a.formations.pop_back()
		assert_float(float(sim.evaluate_force(a,b)[0].doctrine_defense)).is_equal(1.0)

func test_real_campaign_preparation_applies_owned_research_to_existing_troops()->void:
	GameState.ensure_population_total(10000);GameState.settlement_site_committed=true
	GameState.population_allocations.Logistics=100;GameState.food_security=1.0
	GameState.simulation_metrics.food_intake_ratio=1.0;GameState.resource_stockpiles.Food=1000000.0
	GameState.known_discoveries.append("infantry_tank_cooperation");GameState.discovery_adoption.infantry_tank_cooperation=1.0
	MilitaryCampaign.home_army=force();MilitaryCampaign.home_army.supply_level=1.0
	MilitaryCampaign._process_military_day()
	assert_float(float(MilitaryCampaign.home_army.formations[0].doctrines.get("infantry_tank_cooperation",0))).is_greater(0.0)
	assert_str(DiscoverySystem._discovery_effect_summary(DiscoverySystem.discovery_definition("infantry_tank_cooperation"))).contains("Requires rehearsal")

func test_full_military_save_round_trip_retains_practiced_formations()->void:
	MilitaryCampaign.home_army=rehearse(force())
	MilitaryCampaign.home_army.formations[0].id=1;MilitaryCampaign.home_army.formations[1].id=2
	MilitaryCampaign.next_formation_id=3
	var payload:Dictionary=JSON.parse_string(JSON.stringify(MilitaryCampaign.export_state()))
	var loaded:=MilitaryCampaign.import_state(payload)
	assert_bool(loaded.get("ok",false)).override_failure_message(JSON.stringify(loaded)).is_true()
	assert_float(float(MilitaryCampaign.home_army.formations[0].doctrines.infantry_tank_cooperation)).is_equal(1.0)
