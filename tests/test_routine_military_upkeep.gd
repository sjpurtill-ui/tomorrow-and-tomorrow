extends GdUnitTestSuite
func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(7511);MilitaryCampaign.reset_for_new_world();GovernmentPeopleSystem.reset_for_new_world();SettlementModel.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.resource_stockpiles.Timber=100.0
	GameState.population_allocations.Crafting=100;GameState.population_allocations.Logistics=100
	GameState.population_health=1.0;GameState.simulation_metrics.labor_efficiency=1.0
	GameState.settlement_plots=[{"land_use":"workshop","worker_capacity":100,"condition":1.0,"status":"active","damage":{}}]
	MilitaryCampaign.military_inventory.improvised=0
	GameState.settlement_name="Workshop Town";GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(12,0,-8)
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
func start(target:int)->Dictionary:
	var result:=MilitaryCampaign.start_production_line("improvised",target)
	assert_bool(result.has("ok")).is_true()
	return MilitaryCampaign.equipment_queue.back()
const Upkeep=preload("res://scripts/routine_military_upkeep.gd")
func test_repairs_run_without_player_orders_even_with_manual_production()->void:
	MilitaryCampaign.workshop.set_enabled(false)
	MilitaryCampaign.damaged_equipment.improvised=3
	GameState.resource_stockpiles.Timber=.2 # enough to repair three, not manufacture even one
	for day in range(3):MilitaryCampaign._process_equipment_production_day()
	assert_int(int(MilitaryCampaign.damaged_equipment.improvised)).is_equal(0)
	assert_int(int(MilitaryCampaign.military_inventory.improvised)).is_equal(3)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(.011,.000001)
	assert_str(String(MilitaryCampaign.workshop.data.receipts[0].kind)).is_equal("repair")
func test_repair_waits_for_inputs_and_does_not_duplicate_reserved_items()->void:
	MilitaryCampaign.damaged_equipment.improvised=3
	GameState.resource_stockpiles.Timber=0
	Upkeep.prepare(MilitaryCampaign)
	assert_array(MilitaryCampaign.equipment_queue).is_empty()
	GameState.resource_stockpiles.Timber=1
	Upkeep.prepare(MilitaryCampaign)
	var stock:=float(GameState.resource_stockpiles.Timber)
	Upkeep.prepare(MilitaryCampaign)
	assert_int(MilitaryCampaign.equipment_queue.size()).is_equal(1)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(stock)
func test_unequipped_levies_receive_staff_repaired_gear()->void:
	MilitaryCampaign.army_templates=[]
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Reserve",[{"id":1,"unit":"levy","weapon":"improvised","count":3,"equipment":0,"training":.4}],.8,.7)
	MilitaryCampaign.damaged_equipment.improvised=3
	GameState.resource_stockpiles.Timber=.2
	for day in range(100,104):
		GameState.elapsed_days=day
		MilitaryCampaign.workshop.advance(day)
		MilitaryCampaign._process_equipment_production_day()
		MilitaryCampaign._deliver_inventory_replacements(100)
	assert_int(int(MilitaryCampaign.home_army.formations[0].equipment)).is_equal(3)
	assert_int(int(MilitaryCampaign.military_inventory.improvised)).is_equal(0)
	assert_int(int(MilitaryCampaign.damaged_equipment.improvised)).is_equal(0)
func test_completed_staff_line_yields_to_automatic_repairs()->void:
	var job:=start(1);job.planner_managed=true
	MilitaryCampaign.military_inventory.improvised=1
	MilitaryCampaign.damaged_equipment.improvised=2
	Upkeep.prepare(MilitaryCampaign)
	assert_int(MilitaryCampaign.equipment_queue.size()).is_equal(1)
	assert_str(String(MilitaryCampaign.equipment_queue[0].job_type)).is_equal("repair")
func test_repair_page_is_status_not_a_player_order()->void:
	MilitaryCampaign.damaged_equipment.improvised=2
	var content=preload("res://scripts/hud/content/dock_content_production.gd").new(null,null)
	var report:Dictionary=content._repairs()
	assert_str(String(report.blocks[0].type)).is_equal("rows")
	assert_bool(report.blocks[0].items[0].has("on_press")).is_false()
	Upkeep.prepare(MilitaryCampaign)
	report=content._repairs()
	assert_str(String(report.blocks[0].items[0].detail)).is_equal("Staff repairs underway")
	assert_object(load("res://scripts/military_command_ui.gd")).is_not_null()

func test_unequipped_levies_receive_new_gear_without_player_orders()->void:
	MilitaryCampaign.army_templates=[]
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Reserve",[{"id":1,"unit":"levy","weapon":"improvised","count":3,"equipment":0,"training":.4}],.8,.7)
	for day in range(100,104):
		GameState.elapsed_days=day
		MilitaryCampaign.workshop.advance(day)
		MilitaryCampaign._process_equipment_production_day()
		MilitaryCampaign._deliver_inventory_replacements(100)
	assert_int(int(MilitaryCampaign.home_army.formations[0].equipment)).is_equal(3)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_less(100.0)


