extends GdUnitTestSuite
const R=preload("res://scripts/field_repair.gd")
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("repair_ruler",91420)
func after_test()->void:WorldSimulation.clear()
func setup_crew()->Node:
	var host:=WorldSimulation.military
	WorldSimulation.state.known_discoveries.append(R.ID)
	WorldSimulation.state.discovery_adoption[R.ID]=1.0
	WorldSimulation.state.population_allocations.Crafting=0
	WorldSimulation.state.resource_stockpiles={"Timber":20.0,"Stone":20.0}
	WorldSimulation.state.simulation_metrics.food_intake_ratio=1.0
	host.home_army={"supply_level":1.0,"formations":[{"unit":"field_repair_company","weapon":"repair_kit","count":10,"equipment":10,"training":1.0,"personnel_condition":1.0}]}
	return host
func test_crew_requires_tools_training_provisions_and_home_station()->void:
	WorldSimulation.scoped("repair_ruler",func()->void:
		var host:=setup_crew()
		assert_float(R.capacity(host)).is_equal(1.0)
		host.training_program={"scope":"army"}
		assert_float(R.capacity(host)).is_equal(0.0)
		host.training_program={}
		WorldSimulation.state.simulation_metrics.food_intake_ratio=0.0
		assert_float(R.capacity(host)).is_equal(0.0)
		WorldSimulation.state.simulation_metrics.food_intake_ratio=1.0
		host.home_army.formations[0].equipment=0
		assert_float(R.capacity(host)).is_equal(0.0)
		host.home_army.formations[0].equipment=10;host.home_army.formations[0].training=0
		assert_float(R.capacity(host)).is_equal(0.0)
		host.home_army.formations[0].training=1;host.home_army.supply_level=0
		assert_float(R.capacity(host)).is_equal(0.0)
		host.home_army.supply_level=1;WorldSimulation.state.convoy_traveling=true
		assert_float(R.capacity(host)).is_equal(0.0)
		WorldSimulation.state.convoy_traveling=false
		var away:Dictionary=host.home_army.duplicate(true);away.merge({"army_id":17,"status":"marching","location_id":"elsewhere"})
		host.home_army.formations=[];host.field_armies.clear();host.field_armies.append(away)
		assert_float(R.capacity(host)).is_equal(0.0)
		away.status="stationed";away.location_id="player_home"
		assert_float(R.capacity(host)).is_equal(1.0)
	)
func test_automatic_repair_restores_only_real_damage_and_reserves_materials()->void:
	WorldSimulation.scoped("repair_ruler",func()->void:
		var host:=setup_crew();host.damaged_equipment={"improvised":4};host.military_inventory={}
		host._process_equipment_production_day()
		assert_int(int(host.military_inventory.get("improvised",0))).is_equal(4)
		assert_int(int(host.damaged_equipment.improvised)).is_equal(0)
		assert_float(float(WorldSimulation.state.resource_stockpiles.Timber)).is_equal_approx(20.0-4*.35*.18,.000001)
		host._process_equipment_production_day()
		assert_int(int(host.military_inventory.improvised)).is_equal(4)
	)
func test_unknown_equipment_and_missing_materials_are_not_repaired()->void:
	WorldSimulation.scoped("repair_ruler",func()->void:
		var host:=setup_crew();host.damaged_equipment={"service_rifle":1,"improvised":1};host.military_inventory={}
		WorldSimulation.state.resource_stockpiles={}
		host._process_equipment_production_day()
		assert_array(host.equipment_queue).is_empty()
		WorldSimulation.state.resource_stockpiles={"Timber":20.0,"Stone":20.0}
		host._process_equipment_production_day()
		assert_int(int(host.damaged_equipment.service_rifle)).is_equal(1)
		assert_int(int(host.military_inventory.get("service_rifle",0))).is_equal(0)
	)
func test_daily_budget_is_shared_and_paused_jobs_are_respected()->void:
	WorldSimulation.scoped("repair_ruler",func()->void:
		var host:=setup_crew();host.damaged_equipment={"improvised":40}
		var order:Dictionary=host.queue_equipment_repair("improvised",20)
		assert_bool(order.has("error")).is_false()
		var second:Dictionary=host.equipment_queue[0].duplicate(true);second.id=999
		host.equipment_queue.append(second)
		host._process_equipment_production_day()
		var work:=0.0
		for job:Dictionary in host.equipment_queue:work+=float(job.progress_days)
		assert_float(work).is_equal(1.0)
		for job:Dictionary in host.equipment_queue:job.paused=true
		host.damaged_equipment={}
		host._process_equipment_production_day()
		var paused_work:=0.0
		for job:Dictionary in host.equipment_queue:paused_work+=float(job.progress_days)
		assert_float(paused_work).is_equal(work)
	)
func test_partial_repair_survives_save_and_cancel_restores_unfinished_damage()->void:
	WorldSimulation.scoped("repair_ruler",func()->void:
		var host:=setup_crew();host.home_army.formations[0].count=1;host.damaged_equipment={"improvised":10};host.military_inventory={}
		host._process_equipment_production_day()
		assert_int(int(host.military_inventory.improvised)).is_equal(1)
		var saved:Dictionary=JSON.parse_string(JSON.stringify(host.equipment_queue[0]))
		host.equipment_queue[0]=saved
		assert_bool(host.cancel_equipment_job(int(saved.id)).get("cancelled",false)).is_true()
		assert_int(int(host.damaged_equipment.improvised)).is_equal(9)
		assert_int(int(host.military_inventory.improvised)).is_equal(1)
		assert_array(host.equipment_queue).is_empty()
	)
func test_role_is_gated_paid_and_has_no_offensive_attack()->void:
	WorldSimulation.scoped("repair_ruler",func()->void:
		var host:=WorldSimulation.military;host.aggregate_recruits=10
		var original_home:Dictionary=host.home_army.duplicate(true)
		assert_bool(host.start_training("field_repair_company","repair_kit",5).has("error")).is_true()
		setup_crew()
		assert_bool(host.queue_equipment_production("repair_kit",5).has("error")).is_false()
		assert_float(float(WorldSimulation.state.resource_stockpiles.Timber)).is_equal(10.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles.Stone)).is_equal(10.0)
		WorldSimulation.state.population_allocations.Crafting=30
		for day in 1000:
			WorldSimulation.state.elapsed_days=day
			host._process_equipment_production_day()
			if host.equipment_queue.is_empty():break
		assert_int(int(host.military_inventory.get("repair_kit",0))).is_equal(5)
		host.home_army=original_home
		assert_bool(host.start_training("field_repair_company","repair_kit",5).has("error")).is_false()
		assert_int(host.aggregate_recruits).is_equal(5)
		assert_array(host.validate_military_progression()).is_empty()
		var payload:Dictionary=host.export_state()
		assert_bool(host.import_state(payload).has("error")).is_false()
		assert_str(String(host.training_queue[0].unit)).is_equal("field_repair_company")
		assert_float(float(CombatSimulator.UNIT_TYPES.field_repair_company.attack)).is_equal(0.0)
		assert_float(float(CombatSimulator.WEAPONS.repair_kit.attack)).is_equal(0.0)
	)
