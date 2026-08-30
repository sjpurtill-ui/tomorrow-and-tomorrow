class_name CombatSimulatorTest
extends GdUnitTestSuite

const COMBAT_SIMULATOR_SCRIPT := preload("res://scripts/combat_simulator.gd")

var simulator: RefCounted


func before_test() -> void:
	simulator = auto_free(COMBAT_SIMULATOR_SCRIPT.new())


func test_same_seed_produces_the_same_battle() -> void:
	var attacker: Dictionary = simulator.create_force("River Host", 120)
	var defender: Dictionary = simulator.create_force("Hill Guard", 100)
	var first: Dictionary = simulator.simulate(attacker, defender, {"seed": 42})
	var second: Dictionary = simulator.simulate(attacker, defender, {"seed": 42})
	assert_dict(first).is_equal(second)


func test_simulation_does_not_mutate_input_forces() -> void:
	var attacker := {"name": "River Host", "population": 120}
	var defender := {"name": "Hill Guard", "troops": 100}
	simulator.simulate(attacker, defender, {"seed": 7})
	assert_dict(attacker).is_equal({"name": "River Host", "population": 120})
	assert_dict(defender).is_equal({"name": "Hill Guard", "troops": 100})


func test_casualties_are_conserved() -> void:
	var result: Dictionary = simulator.simulate(
		simulator.create_force("River Host", 120),
		simulator.create_force("Hill Guard", 100),
		{"seed": 99}
	)
	assert_int(result.attacker.initial_troops).is_equal(result.attacker.remaining_troops + result.attacker.casualties)
	assert_int(result.defender.initial_troops).is_equal(result.defender.remaining_troops + result.defender.casualties)
	assert_int(result.attacker.remaining_troops).is_greater_equal(0)
	assert_int(result.defender.remaining_troops).is_greater_equal(0)


func test_terrain_advantage_reduces_defender_losses() -> void:
	var attacker: Dictionary = simulator.create_force("River Host", 140)
	var defender: Dictionary = simulator.create_force("Hill Guard", 100)
	var open_ground: Dictionary = simulator.simulate(attacker, defender, {"seed": 314, "terrain_defense": 1.0})
	var fortified_ground: Dictionary = simulator.simulate(attacker, defender, {"seed": 314, "terrain_defense": 1.8})
	assert_int(fortified_ground.defender.casualties).is_less_equal(open_ground.defender.casualties)


func test_existing_army_population_field_is_supported() -> void:
	var result: Dictionary = simulator.simulate(
		{"name": "Founding Convoy", "population": 120},
		{"name": "Raiders", "population": 80},
		{"seed": 5, "max_rounds": 1}
	)
	assert_int(result.attacker.initial_troops).is_equal(120)
	assert_int(result.defender.initial_troops).is_equal(80)
	assert_int(result.round_count).is_equal(1)


func test_formation_weapons_derive_different_combat_stats() -> void:
	var levy: Dictionary = simulator.create_formation_force("Levy", [
		{"unit": "levy", "weapon": "improvised", "count": 100}
	])
	var trained: Dictionary = simulator.create_formation_force("Shield Line", [
		{"unit": "line_infantry", "weapon": "sword_shield", "count": 100}
	])
	assert_float(trained.attack).is_greater(levy.attack)
	assert_float(trained.defense).is_greater(levy.defense)
	assert_float(trained.armor).is_greater(levy.armor)
	assert_float(simulator.force_readiness(trained).organization).is_greater(simulator.force_readiness(levy).organization)


func test_spears_counter_cavalry_but_archers_do_not() -> void:
	var spears: Dictionary = simulator.create_formation_force("Spears", [{"unit": "line_infantry", "weapon": "spear", "count": 100}])
	var archers: Dictionary = simulator.create_formation_force("Archers", [{"unit": "skirmisher", "weapon": "bow", "count": 100}])
	var cavalry: Dictionary = simulator.create_formation_force("Cavalry", [{"unit": "cavalry", "weapon": "lance", "count": 100}])
	var spear_evaluation: Array[Dictionary] = simulator.evaluate_force(spears, cavalry)
	var archer_evaluation: Array[Dictionary] = simulator.evaluate_force(archers, cavalry)
	assert_float(spear_evaluation[0].matchup).is_greater(1.0)
	assert_float(archer_evaluation[0].matchup).is_less(1.0)


func test_cohort_casualties_sum_to_force_casualties() -> void:
	var attacker: Dictionary = simulator.create_formation_force("Mixed", [
		{"unit": "levy", "weapon": "improvised", "count": 50},
		{"unit": "line_infantry", "weapon": "spear", "count": 50}
	])
	var defender: Dictionary = simulator.create_formation_force("Guard", [{"unit": "line_infantry", "weapon": "spear", "count": 100}])
	var result: Dictionary = simulator.simulate(attacker, defender, {"seed": 77, "max_rounds": 1})
	var cohort_survivors := 0
	for cohort in result.attacker.formations:
		cohort_survivors += int(cohort.count)
	assert_int(cohort_survivors).is_equal(result.attacker.remaining_troops)
	assert_int((result.rounds[0].attacker_cohort_equipment_losses as Array).size()).is_equal((result.attacker.formations as Array).size())


func test_spoils_are_deducted_from_the_defeated_force() -> void:
	var loser:Dictionary=simulator.create_formation_force("Loser",[{"unit":"line_infantry","weapon":"spear","count":40,"equipment":40}])
	var winner:Dictionary=simulator.create_formation_force("Winner",[{"unit":"levy","weapon":"improvised","count":40,"equipment":40}])
	var rng:=RandomNumberGenerator.new(); rng.seed=91
	var before:=int(loser.formations[0].equipment)
	var spoils:Dictionary=simulator._battle_spoils(loser,winner,"surrender",rng)
	var captured:=int(spoils.weapons.get("spear",0))
	assert_int(captured).is_greater(0)
	assert_int(int(loser.formations[0].equipment)+captured).is_equal(before)
	var archers:Dictionary=simulator.create_formation_force("Archers",[{"unit":"skirmisher","weapon":"bow","count":40,"equipment":40,"ammunition":180,"ammunition_required":240}])
	rng.seed=91
	var arrow_spoils:Dictionary=simulator._battle_spoils(archers,winner,"surrender",rng)
	var captured_arrows:=int(arrow_spoils.consumables.get("arrows",0))
	assert_int(captured_arrows).is_greater(0)
	assert_int(int(archers.formations[0].ammunition)+captured_arrows).is_equal(180)


func test_equipment_and_manpower_are_separate_inputs() -> void:
	var equipped: Dictionary = simulator.create_formation_force("Equipped", [{"unit":"line_infantry","weapon":"spear","count":100,"equipment":100}])
	var undersupplied: Dictionary = simulator.create_formation_force("Undersupplied", [{"unit":"line_infantry","weapon":"spear","count":100,"equipment":35}])
	var opponent: Dictionary = simulator.create_formation_force("Opponent", [{"unit":"levy","weapon":"improvised","count":100,"equipment":100}])
	var equipped_stats: Array[Dictionary] = simulator.evaluate_force(equipped,opponent)
	var undersupplied_stats: Array[Dictionary] = simulator.evaluate_force(undersupplied,opponent)
	assert_int(equipped.troops).is_equal(undersupplied.troops)
	assert_float(equipped_stats[0].attack).is_greater(undersupplied_stats[0].attack)
	assert_float(equipped_stats[0].defense).is_greater(undersupplied_stats[0].defense)


func test_aggregate_readiness_combines_manpower_equipment_condition_and_organization() -> void:
	var full: Dictionary = simulator.create_formation_force("Full", [{"unit":"line_infantry","weapon":"spear","count":100,"authorized_count":100,"equipment":100,"equipment_required":100}],1.0)
	var depleted: Dictionary = simulator.create_formation_force("Depleted", [{"unit":"line_infantry","weapon":"spear","count":60,"authorized_count":100,"equipment":45,"equipment_required":100}],0.55)
	var full_readiness: Dictionary = simulator.force_readiness(full,0.90)
	var depleted_readiness: Dictionary = simulator.force_readiness(depleted,0.50)
	assert_float(full_readiness.aggregate).is_greater(depleted_readiness.aggregate)
	assert_float(depleted_readiness.manpower).is_equal_approx(0.60,0.001)
	assert_float(depleted_readiness.equipment).is_equal_approx(0.45,0.001)


func test_preparation_day_restores_organization_and_delivers_limited_equipment() -> void:
	var force: Dictionary = simulator.create_formation_force("Recovering", [{"unit":"line_infantry","weapon":"spear","count":80,"authorized_count":100,"equipment":40,"equipment_required":100}],0.45)
	var result: Dictionary = simulator.advance_preparation_day(force,{"equipment_replacements":12,"organization_recovery":0.10})
	var prepared: Dictionary = result.force
	assert_int(prepared.formations[0].equipment).is_equal(52)
	assert_int(result.equipment_delivered).is_equal(12)
	assert_float(prepared.morale).is_equal_approx(0.55,0.001)
	assert_int(force.formations[0].equipment).is_equal(40)


func test_fractional_recovery_eventually_returns_single_casualties() -> void:
	var force:Dictionary=simulator.create_formation_force("Recovering",[{"unit":"levy","weapon":"improvised","count":8,"authorized_count":10,"equipment":10,"equipment_required":10}],0.7)
	assert_int(force.reserve_manpower).is_equal(0)
	force["scattered_pool"]=1
	force["wounded_pool"]=1
	for day in 20:
		force=simulator.advance_preparation_day(force,{"recovery_multiplier":1.0,"manpower_replacements":0}).force
	assert_int(force.scattered_pool).is_equal(0)
	assert_int(force.wounded_pool).is_equal(0)


func test_tactical_leadership_exploits_favorable_matchups() -> void:
	var cavalry: Dictionary = simulator.create_formation_force("Cavalry",[{"unit":"cavalry","weapon":"lance","count":100}])
	var ordinary: Dictionary = simulator.create_formation_force("Ordinary Spears",[{"unit":"line_infantry","weapon":"spear","count":100}])
	var expert: Dictionary = ordinary.duplicate(true)
	ordinary["commander"]=simulator.create_commander("Ordinary",0.5,0.1,0.5,0.5)
	expert["commander"]=simulator.create_commander("Expert",0.5,0.9,0.5,0.5)
	var ordinary_stats: Array[Dictionary] = simulator.evaluate_force(ordinary,cavalry)
	var expert_stats: Array[Dictionary] = simulator.evaluate_force(expert,cavalry)
	assert_float(expert_stats[0].attack).is_greater(ordinary_stats[0].attack)


func test_resolute_commander_reduces_morale_shock() -> void:
	var attacker: Dictionary = simulator.create_formation_force("Attackers",[{"unit":"levy","weapon":"improvised","count":100}])
	var brittle: Dictionary = simulator.create_formation_force("Brittle",[{"unit":"levy","weapon":"improvised","count":100}])
	var resolute: Dictionary = brittle.duplicate(true)
	brittle["commander"]=simulator.create_commander("Brittle",0.5,0.5,0.5,0.1)
	resolute["commander"]=simulator.create_commander("Resolute",0.5,0.5,0.5,0.9)
	var brittle_result: Dictionary = simulator.simulate(attacker,brittle,{"seed":91,"max_rounds":1})
	var resolute_result: Dictionary = simulator.simulate(attacker,resolute,{"seed":91,"max_rounds":1})
	assert_float(resolute_result.defender.morale).is_greater(brittle_result.defender.morale)


func test_archers_need_and_expend_ammunition() -> void:
	var supplied:Dictionary=simulator.create_formation_force("Supplied",[{"unit":"skirmisher","weapon":"bow","count":40,"ammunition":240,"ammunition_required":240}])
	var empty:Dictionary=simulator.create_formation_force("Empty",[{"unit":"skirmisher","weapon":"bow","count":40,"ammunition":0,"ammunition_required":240}])
	var target:Dictionary=simulator.create_formation_force("Target",[{"unit":"levy","weapon":"improvised","count":40}])
	assert_float(simulator.evaluate_force(supplied,target)[0].attack).is_greater(simulator.evaluate_force(empty,target)[0].attack)
	assert_float(simulator.force_readiness(supplied).aggregate).is_greater(simulator.force_readiness(empty).aggregate)
	var result:Dictionary=simulator.simulate(supplied,target,{"seed":73,"max_rounds":1})
	var used:=int(result.rounds[0].attacker_cohort_ammunition_used[0])
	assert_int(used).is_greater(0)
	assert_int(int(result.attacker.formations[0].ammunition)+used).is_equal(240)


func test_equipped_siege_engineers_reduce_prepared_terrain_advantage() -> void:
	var ordinary:Dictionary=simulator.create_formation_force("Ordinary",[{"unit":"line_infantry","weapon":"spear","count":100,"equipment":100}])
	var engineers:Dictionary=simulator.create_formation_force("Engineers",[
		{"unit":"line_infantry","weapon":"spear","count":75,"equipment":75},
		{"unit":"siege_engineer","weapon":"siege_kit","count":25,"equipment":25}
	])
	var defender:Dictionary=simulator.create_formation_force("Fort Guard",[{"unit":"line_infantry","weapon":"spear","count":100,"equipment":100}])
	var ordinary_result:Dictionary=simulator.simulate(ordinary,defender,{"seed":14,"max_rounds":1,"terrain_defense":1.6})
	var engineer_result:Dictionary=simulator.simulate(engineers,defender,{"seed":14,"max_rounds":1,"terrain_defense":1.6})
	assert_float(float(ordinary_result.effective_terrain_defense)).is_equal_approx(1.6,0.001)
	assert_float(float(engineer_result.effective_terrain_defense)).is_less(1.6)
	assert_float(float(engineer_result.siege_terrain_reduction)).is_greater(0.0)


func test_artillery_separates_crew_guns_and_rounds() -> void:
	var supplied:Dictionary=simulator.create_formation_force("Battery",[{"unit":"field_artillery","weapon":"field_gun","count":25,"equipment":5,"ammunition":40}])
	var empty:Dictionary=simulator.create_formation_force("Empty Battery",[{"unit":"field_artillery","weapon":"field_gun","count":25,"equipment":5,"ammunition":0}])
	var target:Dictionary=simulator.create_formation_force("Target",[{"unit":"line_infantry","weapon":"spear","count":80,"equipment":80}])
	assert_int(int(supplied.formations[0].equipment_required)).is_equal(5)
	assert_int(int(supplied.formations[0].ammunition_required)).is_equal(40)
	assert_float(simulator.evaluate_force(supplied,target)[0].attack).is_greater(simulator.evaluate_force(empty,target)[0].attack)
	var supplied_readiness:Dictionary=simulator.force_readiness(supplied)
	var empty_readiness:Dictionary=simulator.force_readiness(empty)
	assert_float(float(empty_readiness.aggregate)).is_less(float(supplied_readiness.aggregate)*0.40)
	assert_float(float(empty_readiness.operational_fill)).is_equal(0.0)
	var result:Dictionary=simulator.simulate(supplied,target,{"seed":117,"max_rounds":1})
	var rounds_used:=int(result.rounds[0].attacker_cohort_ammunition_used[0])
	assert_int(rounds_used).is_greater(0)
	assert_int(int(result.attacker.formations[0].ammunition)+rounds_used).is_equal(40)
