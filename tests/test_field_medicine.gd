extends GdUnitTestSuite
const M=preload("res://scripts/field_medicine.gd")
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("medic_ruler",91420)
func after_test()->void:WorldSimulation.clear()
func force()->Dictionary:
	return {"troops":10,"wounded_pool":100,"disabled_pool":20,"formations":[{"unit":"medical_detachment","weapon":"medical_kit","count":10,"equipment":10,"training":1.0,"personnel_condition":1.0}]}
func test_care_requires_equipped_trained_people_and_actual_supplies()->void:
	WorldSimulation.scoped("medic_ruler",func()->void:
		var a:=force();WorldSimulation.state.resource_stockpiles={"Fiber Plants":10.0,"Medicinal Plants":10.0}
		var care:=M.provide(a,1.0)
		assert_float(float(care.cases)).is_equal(5.0)
		assert_float(float(care.recovery)).is_equal(.4)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Fiber Plants"])).is_equal(9.5)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Medicinal Plants"])).is_equal(9.75)
		a.formations[0].equipment=0;assert_float(float(M.provide(a,1).cases)).is_equal(0.0)
		a.formations[0].equipment=10;a.formations[0].training=0;assert_float(float(M.provide(a,1).cases)).is_equal(0.0)
	)
func test_no_supplies_no_rations_or_only_permanent_injuries_gives_no_bonus()->void:
	WorldSimulation.scoped("medic_ruler",func()->void:
		var a:=force();WorldSimulation.state.resource_stockpiles={}
		assert_float(float(M.provide(a,1).cases)).is_equal(0.0)
		WorldSimulation.state.resource_stockpiles={"Fiber Plants":10.0,"Medicinal Plants":10.0}
		assert_float(float(M.provide(a,0).cases)).is_equal(0.0)
		a.disabled_pool=100;assert_float(float(M.provide(a,1).cases)).is_equal(0.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Fiber Plants"])).is_equal(10.0)
	)
func test_method_adoption_increases_capacity_without_free_staff()->void:
	WorldSimulation.scoped("medic_ruler",func()->void:
		var a:=force()
		for id:String in M.METHODS:WorldSimulation.state.known_discoveries.append(id);WorldSimulation.state.discovery_adoption[id]=1.0
		assert_float(M.capacity(a)).is_equal(12.5)
		a.formations.clear();assert_float(M.capacity(a)).is_equal(0.0)
	)
func test_simulator_extra_care_returns_only_recoverable_living_people()->void:
	var simulator:=CombatSimulator.new()
	var a:=force();a.disabled_pool=99;a.reserve_manpower=0;a.scattered_pool=0
	var result:=simulator.advance_preparation_day(a,{"medical_recovery":20.0,"manpower_replacements":0})
	assert_int(int(result.wounded_recovered)).is_equal(1)
	assert_int(int(result.force.disabled_pool)).is_equal(99)
func test_role_uses_paid_workshops_recruit_pool_and_saved_training()->void:
	WorldSimulation.scoped("medic_ruler",func()->void:
		var army:=WorldSimulation.military
		army.aggregate_recruits=10
		assert_bool(army.start_training("medical_detachment","medical_kit",5).has("error")).is_true()
		WorldSimulation.state.known_discoveries.append("litter_bearer_drill");WorldSimulation.state.discovery_adoption.litter_bearer_drill=1.0
		WorldSimulation.state.resource_stockpiles.Timber=10.0;WorldSimulation.state.resource_stockpiles["Fiber Plants"]=20.0
		var order:=army.queue_equipment_production("medical_kit",5)
		assert_bool(order.has("error")).is_false()
		assert_float(float(WorldSimulation.state.resource_stockpiles.Timber)).is_equal(5.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Fiber Plants"])).is_equal(10.0)
		assert_int(int(army.military_inventory.get("medical_kit",0))).is_equal(0)
		WorldSimulation.state.population_allocations.Crafting=30
		for day in 200:
			WorldSimulation.state.elapsed_days=day
			army._process_equipment_production_day()
		assert_int(int(army.military_inventory.get("medical_kit",0))).is_equal(5)
		var trained:=army.start_training("medical_detachment","medical_kit",5)
		assert_bool(trained.has("error")).is_false()
		assert_int(army.aggregate_recruits).is_equal(5)
		assert_array(army.validate_military_progression()).is_empty()
		var payload:Dictionary=army.export_state()
		var restored:=army.import_state(payload)
		assert_bool(restored.has("error")).is_false()
		assert_str(String(army.training_queue[0].unit)).is_equal("medical_detachment")
	)
func test_last_supply_limits_care_without_touching_player_stores()->void:
	var previous:=GameState.resource_stockpiles.duplicate(true)
	WorldSimulation.scoped("medic_ruler",func()->void:
		WorldSimulation.state.resource_stockpiles={"Fiber Plants":.1,"Medicinal Plants":10.0}
		assert_float(float(M.provide(force(),1).cases)).is_equal(1.0)
		assert_float(float(M.provide(force(),1).cases)).is_equal(0.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Fiber Plants"])).is_equal(0.0)
	)
	assert_dict(GameState.resource_stockpiles).is_equal(previous)
func test_medical_contracts_and_inspector_explain_actual_operating_requirements()->void:
	WorldSimulation.scoped("medic_ruler",func()->void:
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(M.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		for entry:Dictionary in M.entries():
			var description:=WorldSimulation.discovery._discovery_effect_summary(entry)
			assert_bool(description.contains("supplies")).is_true()
			assert_bool(description.contains("permanently disabled")).is_true()
	)
func test_medical_formation_adds_no_offensive_combat_power()->void:
	var simulator:=CombatSimulator.new()
	var a:=simulator.create_formation_force("Carers",force().formations)
	var enemy:=simulator.create_formation_force("Guard",[{"unit":"levy","weapon":"improvised","count":10}])
	var profiles:=simulator.evaluate_force(a,enemy)
	assert_float(simulator._cohort_power(profiles,1.0,1.0,.5)).is_equal(0.0)
	assert_int(int(a.troops)).is_equal(10)
func test_care_report_is_read_only_and_matches_actual_service()->void:
	WorldSimulation.scoped("medic_ruler",func()->void:
		WorldSimulation.state.resource_stockpiles={"Fiber Plants":.2,"Medicinal Plants":10.0}
		var before:=WorldSimulation.state.resource_stockpiles.duplicate(true)
		var report:=M.quote(force(),1)
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
		assert_float(float(report.cases)).is_equal(2.0)
		assert_str(String(report.reason)).is_equal("Remaining care supplies limit service")
		assert_bool(M.describe(report).contains("at home")).is_true()
		assert_dict(M.provide(force(),1)).is_equal(report)
	)
func test_capabilities_report_does_not_consume_care_materials()->void:
	WorldSimulation.scoped("medic_ruler",func()->void:
		WorldSimulation.state.resource_stockpiles={"Fiber Plants":10.0,"Medicinal Plants":10.0}
		WorldSimulation.military.home_army=WorldSimulation.military.simulator.create_formation_force("Carers",force().formations)
		WorldSimulation.military.home_army.wounded_pool=10
		var before:=WorldSimulation.state.resource_stockpiles.duplicate(true)
		var report:Dictionary=WorldSimulation.military.military_capabilities().medical_support
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
		assert_float(float(report.cases)).is_greater(0.0)
	)
func test_supply_panel_includes_the_medical_capacity_report()->void:
	var world:Node=auto_free(Node.new());var shell:Control=auto_free(Control.new())
	var provider:=preload("res://scripts/hud/content/dock_content_military.gd").new(world,shell)
	var report:={"capacity":5.0,"recoverable_wounded":12,"cases":2.0,"reason":"Remaining care supplies limit service"}
	var found:=false
	for block:Dictionary in provider._supply_blocks({}, {"medical_support":report}):
		if String(block.get("heading",""))=="HOME MEDICAL SUPPORT":
			found=true
			assert_bool(String(block.text).contains("12")).is_true()
			assert_bool(String(block.text).contains("Remaining care supplies")).is_true()
	assert_bool(found).is_true()
