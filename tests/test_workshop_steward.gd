extends "res://tests/test_persistent_production.gd"
const Manager=preload("res://scripts/workshop_steward.gd")
func before_test()->void:
	super.before_test()
	GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.population_allocations.Crafting=100
	GameState.population_allocations.Logistics=100
	GameState.settlement_name="Workshop Town"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(12,0,-8)
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
func test_scheduler_preserves_manual_targets_and_pauses()->void:
	var job:=start(5)
	var before:=job.duplicate(true)
	MilitaryCampaign.workshop.schedule({"item":"improvised","target":40})
	assert_dict(job).is_equal(before)
	MilitaryCampaign.configure_production_line(int(job.id),5,true)
	MilitaryCampaign.workshop.delegate_lines()
	assert_bool(bool(job.get("planner_managed",false))).is_false()
	assert_bool(job.paused).is_true()
func test_scheduling_pays_normal_inputs_and_marks_only_its_line()->void:
	var result:Dictionary=MilitaryCampaign.workshop.schedule({"item":"improvised","target":3})
	assert_bool(result.changed).is_true()
	var job:Dictionary=MilitaryCampaign.equipment_queue[0]
	assert_bool(job.planner_managed).is_true()
	var timber:=float(GameState.resource_stockpiles.Timber)
	Production.advance(MilitaryCampaign,job,100)
	assert_int(int(MilitaryCampaign.military_inventory.improvised)).is_equal(3)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(timber-3*.35,.00001)
func test_manager_will_not_discard_work_or_retool_manual_line()->void:
	var job:=start(1)
	GameState.known_discoveries.append("bow_craft");GameState.discovery_adoption.bow_craft=1.0
	Production.advance(MilitaryCampaign,job,float(job.work_per_item)*.5)
	MilitaryCampaign.workshop.delegate_lines()
	var before:=job.duplicate(true)
	MilitaryCampaign.workshop.schedule({"item":"arrows","target":2})
	assert_dict(job).is_equal(before)
	Production.advance(MilitaryCampaign,job,100)
	MilitaryCampaign.configure_production_line(int(job.id),1,false)
	before=job.duplicate(true)
	MilitaryCampaign.workshop.schedule({"item":"arrows","target":2})
	assert_dict(job).is_equal(before)
func test_receipts_survive_issue_cancel_and_round_trip()->void:
	var job:=start(3)
	MilitaryCampaign._process_equipment_production_day()
	assert_array(MilitaryCampaign.workshop.data.receipts).is_not_empty()
	var receipt:Dictionary=MilitaryCampaign.workshop.data.receipts[0]
	assert_float(float(receipt.quantity)).is_equal(float(MilitaryCampaign.military_inventory.improvised))
	MilitaryCampaign.military_inventory.improvised=0
	MilitaryCampaign.cancel_equipment_job(int(job.id))
	var saved:Dictionary=MilitaryCampaign.workshop.data.duplicate(true)
	MilitaryCampaign.workshop.reset();MilitaryCampaign.workshop.restore(saved)
	assert_dict(MilitaryCampaign.workshop.data).is_equal(saved)
	assert_str(Manager.validate(saved)).is_empty()
func test_receipts_ignore_existing_stock_and_rejected_output()->void:
	var job:=start(1)
	MilitaryCampaign.military_inventory.improvised=50
	MilitaryCampaign._process_equipment_production_day()
	assert_array(MilitaryCampaign.workshop.data.receipts).is_empty()
	var before:Dictionary=MilitaryCampaign.workshop.output_stocks(job)
	job.completed=500 # Processing alone is not accepted goods.
	MilitaryCampaign.workshop.record(job,before)
	assert_array(MilitaryCampaign.workshop.data.receipts).is_empty()
func test_coproduct_receipts_and_bounded_validation()->void:
	var job:={"item":"improvised","job_type":"production"}
	for day:int in 300:
		GameState.elapsed_days=day
		var before:Dictionary=MilitaryCampaign.workshop.output_stocks(job)
		MilitaryCampaign.military_inventory.improvised+=1
		MilitaryCampaign.workshop.record(job,before)
	assert_int(MilitaryCampaign.workshop.data.receipts.size()).is_equal(256)
	var bad:Dictionary=MilitaryCampaign.workshop.data.duplicate(true);bad.receipts[0].quantity=NAN
	assert_str(Manager.validate(bad)).is_not_empty()
	MilitaryCampaign.workshop.restore({})
	assert_array(MilitaryCampaign.workshop.data.receipts).is_empty()
func test_only_requested_armies_create_demand_and_cancel_stops_orders()->void:
	MilitaryCampaign.army_templates=[{"template_id":1,"entries":[{"unit":"levy","weapon":"improvised","count":5}],"recruitment_requested":false}]
	assert_array(MilitaryCampaign.workshop.army_demands()).is_empty()
	MilitaryCampaign.army_templates[0].recruitment_requested=true
	assert_int(int(MilitaryCampaign.workshop.army_demands()[0].target)).is_equal(5)
	MilitaryCampaign.workshop.advance(1)
	assert_int(MilitaryCampaign.equipment_queue.size()).is_equal(1)
	MilitaryCampaign.army_templates[0].recruitment_requested=false
	MilitaryCampaign.workshop.advance(2)
	assert_bool(bool(MilitaryCampaign.equipment_queue[0].paused)).is_true()
func test_daily_staff_review_is_idempotent_and_manual_mode_leaves_jobs()->void:
	var job:=start(4)
	MilitaryCampaign.workshop.set_enabled(false)
	var before:=job.duplicate(true)
	MilitaryCampaign.workshop.advance(2)
	assert_dict(job).is_equal(before)
	assert_int(int(MilitaryCampaign.workshop.data.last_day)).is_equal(2)
func test_player_manager_handles_real_civilian_study_demand()->void:
	GameState.population_allocations.Knowledge=20
	GameState.known_discoveries.append("paper_making");GameState.discovery_adoption.paper_making=1
	GameState.resource_stockpiles.merge({"Paper Pulp":5.0,"Freshwater":5.0,"Timber":20.0,"Fiber Plants":20.0},true)
	preload("res://scripts/society_exchange.gd").data().collections["test"]={"returned_day":0,"study":0.0,"work":240.0}
	MilitaryCampaign.workshop.advance(1)
	assert_int(MilitaryCampaign.equipment_queue.size()).is_equal(1)
	assert_str(String(MilitaryCampaign.equipment_queue[0].item)).is_equal("handmade_paper")
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(16.0)

func test_workshop_state_uses_existing_campaign_save_and_rejects_bad_receipts()->void:
	start(3);MilitaryCampaign._process_equipment_production_day()
	MilitaryCampaign.workshop.set_enabled(false)
	var saved:=MilitaryCampaign.export_state()
	MilitaryCampaign.workshop.reset()
	assert_bool(MilitaryCampaign.import_state(saved).has("ok")).is_true()
	assert_dict(MilitaryCampaign.workshop.data).is_equal(saved.workshop_management)
	var before:Dictionary=MilitaryCampaign.workshop.data.duplicate(true)
	saved.workshop_management.receipts[0].quantity=-1
	assert_bool(MilitaryCampaign.import_state(saved).has("error")).is_true()
	assert_dict(MilitaryCampaign.workshop.data).is_equal(before)

func test_completed_batch_remains_visible_after_queue_removal()->void:
	MilitaryCampaign.queue_equipment_production("improvised",1)
	MilitaryCampaign._process_equipment_production_day()
	assert_array(MilitaryCampaign.equipment_queue).is_empty()
	assert_int(MilitaryCampaign.workshop.data.receipts.size()).is_equal(1)
	assert_float(float(MilitaryCampaign.workshop.data.receipts[0].quantity)).is_equal(1.0)

func test_coproduct_ledger_uses_fractional_store_deltas()->void:
	var job:={"item":"metallographic_nitric_acid","job_type":"civilian"}
	var before:Dictionary=MilitaryCampaign.workshop.output_stocks(job)
	GameState.resource_stockpiles["Metallographic Nitric Acid"]=float(before["Metallographic Nitric Acid"])+1
	GameState.resource_stockpiles["Spent Etchant Sulfate Salts"]=float(before["Spent Etchant Sulfate Salts"])+1.5
	MilitaryCampaign.workshop.record(job,before)
	assert_int(MilitaryCampaign.workshop.data.receipts.size()).is_equal(2)
	var output:Dictionary={}
	for receipt:Dictionary in MilitaryCampaign.workshop.data.receipts:output[receipt.resource]=receipt.quantity
	assert_float(float(output["Spent Etchant Sulfate Salts"])).is_equal(1.5)

func test_delegating_continuous_order_finishes_one_item_then_can_retask()->void:
	var job:=start(0)
	Production.advance(MilitaryCampaign,job,float(job.work_per_item)*.5)
	MilitaryCampaign.workshop.delegate_lines()
	assert_int(int(job.target_stock)).is_equal(1)
	MilitaryCampaign.workshop.advance(1)
	assert_bool(job.paused).is_false()
	Production.advance(MilitaryCampaign,job,100)
	MilitaryCampaign.workshop.advance(2)
	assert_bool(job.paused).is_true()
	assert_int(int(MilitaryCampaign.military_inventory.improvised)).is_equal(1)

func test_player_manager_does_not_take_over_foreign_actor()->void:
	WorldSimulation.create_actor("workshop_neighbor",445)
	WorldSimulation.scoped("workshop_neighbor",func():
		var before:Dictionary=WorldSimulation.military.workshop.data.duplicate(true)
		WorldSimulation.military.workshop.advance(7)
		assert_dict(WorldSimulation.military.workshop.data).is_equal(before))
	WorldSimulation.clear()
