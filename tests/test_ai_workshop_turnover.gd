extends GdUnitTestSuite
const P=preload("res://scripts/persistent_production.gd")
const T=preload("res://scripts/ai_workshop_turnover.gd")
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("turnover",9241)
	WorldSimulation.scoped("turnover",func()->void:
		var s=WorldSimulation.state
		s.settlement_site_committed=true;s.convoy_traveling=false
		s.population_allocations.Crafting=40;s.population_allocations.Logistics=30
		for item:String in ["Timber","Clay","Stone","Fiber Plants","Prepared Fibers"]:s.resource_stockpiles[item]=100.0
		for id:String in ["fiber_retting","drop_spindles"]:
			s.known_discoveries.append(id);s.discovery_adoption[id]=1.0
	)
func after_test()->void:WorldSimulation.clear()
func line()->Dictionary:
	var host=WorldSimulation.military
	assert_bool(host.start_production_line("spun_yarn",12).get("ok",false)).is_true()
	var job:Dictionary=host.equipment_queue.back()
	P.advance(host,job,float(job.work_per_item)*1.5)
	return job
func test_consumed_intermediate_yields_after_one_paid_batch()->void:
	WorldSimulation.scoped("turnover",func()->void:
		var host=WorldSimulation.military;var job:=line()
		var previous:=job.duplicate(true);var stock:=float(WorldSimulation.state.resource_stockpiles["Prepared Fibers"])
		T.request("turnover",host,"spear",5)
		assert_bool(job.has("ai_turnover")).is_true()
		assert_float(float(job.progress_days)).is_equal(float(previous.progress_days))
		P.advance(host,job,100.0)
		assert_int(int(job.last_output)).is_equal(1)
		assert_float(float(job.progress_days)).is_equal(0.0)
		assert_bool(job.paused).is_true()
		assert_float(float(WorldSimulation.state.resource_stockpiles["Prepared Fibers"])).is_equal(stock-.5)
		T.advance("turnover",host)
		assert_str(job.item).is_equal("spear")
		assert_bool(job.paused).is_false()
		assert_bool(job.has("ai_turnover")).is_false()
		P.advance(host,job,100.0)
		assert_int(int(host.military_inventory.spear)).is_equal(5)
	)
func test_player_manual_and_reserved_work_are_protected()->void:
	WorldSimulation.scoped("turnover",func()->void:
		var host=WorldSimulation.military;var job:=line()
		T.request("player",host,"spear",5)
		assert_bool(job.has("ai_turnover")).is_false()
		job.reserved_materials={"Prepared Fibers":.5}
		T.request("turnover",host,"spear",5)
		assert_bool(job.has("ai_turnover")).is_false()
		job.reserved_materials={};job["casting_pending"]={}
		T.request("turnover",host,"spear",5)
		assert_bool(job.has("ai_turnover")).is_false()
	)
func test_supply_shock_resumes_original_line()->void:
	WorldSimulation.scoped("turnover",func()->void:
		var host=WorldSimulation.military;var job:=line()
		T.request("turnover",host,"spear",5);P.advance(host,job,100.0)
		WorldSimulation.state.resource_stockpiles.Stone=0.0
		T.advance("turnover",host)
		assert_str(job.item).is_equal("spun_yarn")
		assert_bool(job.paused).is_false()
		assert_bool(job.has("ai_turnover")).is_false()
	)
func test_pending_turnover_survives_owned_save()->void:
	WorldSimulation.scoped("turnover",func()->void:
		line()
		T.request("turnover",WorldSimulation.military,"spear",5)
	)
	var saved:=WorldSimulation.export_state()
	assert_bool(WorldSimulation.import_state(bytes_to_var(var_to_bytes(saved))).get("ok",false)).is_true()
	WorldSimulation.scoped("turnover",func()->void:
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		assert_bool(job.has("ai_turnover")).is_true()
		P.advance(WorldSimulation.military,job,100.0);T.advance("turnover",WorldSimulation.military)
		assert_str(job.item).is_equal("spear")
	)

func test_invalid_turnover_save_is_rejected()->void:
	WorldSimulation.scoped("turnover",func()->void:
		var job:=line()
		job.ai_turnover="invalid"
		assert_str(P.validate_saved({"equipment_queue":[job]})).is_not_empty()
		job.ai_turnover={"item":"spear","target":-2}
		assert_str(P.validate_saved({"equipment_queue":[job]})).is_not_empty()
	)

func test_routine_target_review_keeps_the_committed_batch_handoff()->void:
	WorldSimulation.scoped("turnover",func()->void:
		var host=WorldSimulation.military;var job:=line()
		assert_bool(T.request("turnover",host,"spear",5)).is_true()
		preload("res://scripts/civilization_controller.gd").ensure_line("turnover","spun_yarn",20)
		assert_bool(job.has("ai_turnover")).is_true()
		P.advance(host,job,100.0);T.advance("turnover",host)
		assert_str(job.item).is_equal("spear")
	)

func test_starved_partial_batch_is_saved_then_resumed_without_duplicate_work()->void:
	WorldSimulation.scoped("turnover",func()->void:
		var host=WorldSimulation.military;var state=WorldSimulation.state
		state.resource_stockpiles["Prepared Fibers"]=1.5
		var job:=line()
		assert_float(float(state.resource_stockpiles["Prepared Fibers"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Spun Yarn"])).is_equal(1.0)
		var partial:=float(job.progress_days)
		assert_bool(T.request("turnover",host,"retted_fibers",2)).is_true()
		T.advance("turnover",host)
		assert_str(job.item).is_equal("retted_fibers")
		assert_float(float(job.suspended_batches.spun_yarn.progress_days)).is_equal(partial)
		assert_float(float(state.resource_stockpiles["Prepared Fibers"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Spun Yarn"])).is_equal(1.0)
	)
	var saved:=bytes_to_var(var_to_bytes(WorldSimulation.export_state())) as Dictionary
	assert_bool(WorldSimulation.import_state(saved).get("ok",false)).is_true()
	WorldSimulation.scoped("turnover",func()->void:
		var host=WorldSimulation.military;var state=WorldSimulation.state;var job:Dictionary=host.equipment_queue.back()
		assert_bool(job.suspended_batches.has("spun_yarn")).is_true()
		var before:=float(state.resource_stockpiles["Fiber Plants"])
		P.advance(host,job,100.0)
		assert_float(float(state.resource_stockpiles["Prepared Fibers"])).is_equal(2.0)
		assert_float(float(state.resource_stockpiles["Fiber Plants"])).is_less(before)
		assert_bool(T.request("turnover",host,"spun_yarn",2)).is_true()
		T.advance("turnover",host)
		assert_str(job.item).is_equal("spun_yarn")
		assert_dict(job.suspended_batches).is_empty()
		assert_float(float(job.progress_days)).is_equal(float(job.work_per_item)*.5)
		P.advance(host,job,float(job.work_per_item)*.5)
		assert_float(float(state.resource_stockpiles["Spun Yarn"])).is_equal(2.0)
		assert_float(float(state.resource_stockpiles["Prepared Fibers"])).is_equal(1.5)
		assert_float(float(job.progress_days)).is_equal(0.0)
	)

func test_invalid_or_recursive_suspended_batch_is_rejected()->void:
	WorldSimulation.scoped("turnover",func()->void:
		var host=WorldSimulation.military;var job:=line()
		WorldSimulation.state.resource_stockpiles["Prepared Fibers"]=0.0
		T.request("turnover",host,"retted_fibers",2);T.advance("turnover",host)
		var batch:Dictionary=job.suspended_batches.spun_yarn
		batch.suspended_batches={}
		assert_str(P.validate_saved({"equipment_queue":[job]})).is_not_empty()
		batch.erase("suspended_batches");batch.progress_days=batch.work_per_item
		assert_str(P.validate_saved({"equipment_queue":[job]})).is_not_empty()
	)
