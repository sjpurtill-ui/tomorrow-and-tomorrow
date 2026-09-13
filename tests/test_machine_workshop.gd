extends GdUnitTestSuite
const M=preload("res://scripts/machine_workshop.gd")
const Ops=preload("res://scripts/technology_operations.gd")
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("machine_test",1210)
func after_test()->void:WorldSimulation.clear()
func spec()->Dictionary:
	return {"output":"Trial Plate","materials":{"Steel":1.0},"days":4.0,"power":8.0,"machine_program":[{"x":2.0,"y":0.0,"z":0.0,"feed":1.0}]}
func job()->Dictionary:
	return {"id":1,"item":"trial","completed":0,"target_stock":1,"progress_days":0.0,"last_consumed":{},"last_work":0.0}
func test_material_is_reserved_once_and_path_end_is_not_accepted_output()->void:
	WorldSimulation.scoped("machine_test",func()->void:
		var state=WorldSimulation.state;state.resource_stockpiles={"Steel":1.0}
		Ops.data().last_day=int(state.elapsed_days);Ops.data().services.electricity=2.0
		var line:=job();var definition:=spec()
		M.advance(line,definition,4)
		assert_float(float(state.resource_stockpiles.Steel)).is_equal(0.0)
		assert_float(float(line.progress_days)).is_equal(1.0)
		var restored:Dictionary=bytes_to_var(var_to_bytes(line))
		assert_str(M.validate_job(restored,definition)).is_empty()
		Ops.data().services.electricity=2.0
		M.advance(restored,definition,4)
		assert_str(restored.machine_pending.phase).is_equal("inspection")
		assert_float(float(state.resource_stockpiles.get("Trial Plate",0))).is_equal(0.0)
		assert_float(float(state.resource_stockpiles.Steel)).is_equal(0.0)
		assert_str(M.validate_job(restored,definition)).is_empty()
	)
func test_no_power_no_reservation_and_wrong_store_cannot_advance_workpiece()->void:
	WorldSimulation.scoped("machine_test",func()->void:
		var state=WorldSimulation.state;state.resource_stockpiles={"Steel":1.0}
		Ops.data().last_day=int(state.elapsed_days);Ops.data().services.electricity=0.0
		var line:=job();M.advance(line,spec(),2)
		assert_bool(line.has("machine_pending")).is_false()
		assert_float(float(state.resource_stockpiles.Steel)).is_equal(1.0)
		Ops.data().services.electricity=2.0;M.advance(line,spec(),1)
		state.resource_settlement_id="different_store"
		var before:=line.duplicate(true);M.advance(line,spec(),10)
		assert_dict(line).is_equal(before)
	)
func test_saved_workpiece_cannot_change_reserved_feed_or_recipe()->void:
	WorldSimulation.scoped("machine_test",func()->void:
		WorldSimulation.state.resource_stockpiles={"Steel":1.0}
		Ops.data().last_day=int(WorldSimulation.state.elapsed_days);Ops.data().services.electricity=2.0
		var line:=job();M.advance(line,spec(),1)
		line.machine_pending.reserved.Steel=0.0
		assert_str(M.validate_job(line,spec())).is_not_empty()
		M.clear(line)
		assert_bool(line.has("machine_pending")).is_false()
		assert_float(float(WorldSimulation.state.resource_stockpiles.Steel)).is_equal(0.0)
	)
