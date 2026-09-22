extends GdUnitTestSuite
const Repair=preload("res://scripts/managed_weapon_repair.gd")
const P=preload("res://scripts/persistent_production.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("repairs",118)
func after_test()->void:WorldSimulation.clear()
func setup()->Dictionary:
	var host=WorldSimulation.military
	WorldSimulation.state.resource_stockpiles.Timber=10.0
	host.damaged_equipment.improvised=10;host.military_inventory.improvised=0
	return {"id":99,"persistent":true,"item":"improvised","job_type":"production","materials":{"Timber":.35},"work_per_item":.25,"progress_days":.1,"completed":0,"paused":false,"target_stock":10,"allocation":1.0,"efficiency":1.0}
func test_repairs_pay_existing_costs_and_preserve_partial_manufacture()->void:
	WorldSimulation.scoped("repairs",func()->void:
		var job:=setup();var host=WorldSimulation.military
		assert_float(Repair.advance(host,job,.19)).is_equal_approx(0.0,.000001)
		assert_int(int(host.military_inventory.improvised)).is_equal(2)
		assert_int(int(host.damaged_equipment.improvised)).is_equal(8)
		assert_float(float(WorldSimulation.state.resource_stockpiles.Timber)).is_equal_approx(9.874,.000001)
		assert_float(float(job.progress_days)).is_equal(.1)
		assert_int(int(job.completed)).is_equal(0)
		assert_str(String(host.workshop.data.receipts[0].kind)).is_equal("repair")
	)
func test_unfinished_repair_reserves_damage_and_close_returns_only_unfinished_items()->void:
	WorldSimulation.scoped("repairs",func()->void:
		var job:=setup();var host=WorldSimulation.military
		Repair.advance(host,job,.05)
		var view:=P.snapshot(host,job,1.0,1.0)
		assert_str(String(view.state)).is_equal("Repairing equipment")
		assert_float(float(view.work_per_item)).is_equal_approx(.095,.000001)
		assert_float(float(view.progress_days)).is_equal_approx(.05,.000001)
		assert_int(int(host.damaged_equipment.improvised)).is_equal(9)
		assert_int(int(host.military_inventory.improvised)).is_equal(0)
		var restored:Dictionary=bytes_to_var(var_to_bytes(job))
		Repair.advance(host,restored,.045)
		assert_int(int(host.military_inventory.improvised)).is_equal(1)
		Repair.advance(host,restored,.01)
		assert_bool(P.close(restored)).is_true()
		assert_int(int(host.damaged_equipment.improvised)).is_equal(9)
		assert_float(float(restored.progress_days)).is_equal(.1)
	)
func test_repair_is_available_below_new_weapon_cost_but_not_without_inputs()->void:
	WorldSimulation.scoped("repairs",func()->void:
		var job:=setup();WorldSimulation.state.resource_stockpiles.Timber=.063
		assert_str(P.state(WorldSimulation.military,job)).is_equal("Repairing equipment")
		Repair.advance(WorldSimulation.military,job,.095)
		assert_int(int(WorldSimulation.military.military_inventory.improvised)).is_equal(1)
		assert_bool(Repair.available(WorldSimulation.military,job)).is_false()
	)
func test_manual_and_paused_lines_are_not_changed()->void:
	WorldSimulation.scoped("repairs",func()->void:
		var job:=setup();var host=WorldSimulation.military
		WorldSimulation.actors.repairs.controller="human"
		assert_bool(Repair.available(host,job)).is_false()
		job.planner_managed=true;host.workshop.data.enabled=true;job.paused=true
		assert_float(Repair.advance(host,job,1)).is_equal(1.0)
		assert_int(int(host.damaged_equipment.improvised)).is_equal(10)
	)
