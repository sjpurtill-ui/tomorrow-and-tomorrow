extends GdUnitTestSuite
const Reserves=preload("res://scripts/local_material_reserves.gd")
const Build=preload("res://scripts/settlement_construction.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("reserves",118)
func after_test()->void:WorldSimulation.clear()
func test_construction_reserve_protects_real_bill_not_population_multiple()->void:
	WorldSimulation.scoped("reserves",func()->void:
		var s=WorldSimulation.state;s.population_exact=20000;s.settlement_completed.clear();s.settlement_completed.append("Hearth Circle")
		s.resource_stockpiles={"Timber":80.0,"Fiber Plants":80.0}
		var needs:=Reserves.calculate()
		assert_float(float(needs.Timber)).is_greater_equal(18.0)
		assert_float(float(needs.Timber)).is_less(80.0)
		assert_float(float(s.resource_stockpiles.Timber)).is_equal(80.0)
	)
func test_active_workshop_keeps_unpaid_batch_and_next_batch_inputs()->void:
	WorldSimulation.scoped("reserves",func()->void:
		var s=WorldSimulation.state;var host=WorldSimulation.military
		for project:Dictionary in Build._settlement_definitions():s.settlement_completed.append(String(project.name))
		host.equipment_queue.append({"persistent":true,"paused":false,"item":"improvised","job_type":"production","target_stock":10,"materials":{"Timber":40.0},"progress_days":.5,"work_per_item":1.0})
		host.military_inventory.improvised=0
		assert_float(float(Reserves.calculate().Timber)).is_equal(60.0)
		s.resource_settlement_id="secondary"
		assert_bool(Reserves.calculate().has("Timber")).is_false()
	)
