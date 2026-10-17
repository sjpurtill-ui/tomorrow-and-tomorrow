extends GdUnitTestSuite
const S=preload("res://scripts/production_shortage.gd")
const P=preload("res://scripts/persistent_production.gd")
const Provider=preload("res://scripts/hud/content/dock_content_production.gd")
const Queue=preload("res://scripts/hud/production_queue.gd")

func before_test()->void:
	preload("res://tests/production_screen_capture.gd").seed_world()

func test_worst_resource_and_twenty_unit_threshold()->void:
	var ledger:={"Steel":2.0,"Aluminum":0.0}
	var result:=S.evaluate({"Steel":2.0,"Aluminum":1.0},11,ledger)
	assert_float(float(result.factor)).is_equal_approx(5.45/11,.000001)
	assert_int(int(result.stopped)).is_equal(1)
	assert_float(float(S.evaluate({"Steel":1.0},1,{"Steel":-18.0}).factor)).is_equal_approx(.05,.000001)
	assert_float(float(S.evaluate({"Steel":1.0},1,{"Steel":-19.0}).factor)).is_equal(0.0)

func test_priority_claims_do_not_reset_at_next_line()->void:
	var ledger:={"Steel":2.0}
	var first:=S.evaluate({"Steel":2.0},10,ledger)
	var next:=S.evaluate({"Steel":2.0},10,ledger)
	assert_float(float(first.factor)).is_greater(0)
	assert_float(float(next.factor)).is_equal(0.0)

func test_bounded_formula_matches_slot_by_slot_reference()->void:
	var random:=RandomNumberGenerator.new();random.seed=871
	for trial in 150:
		var slots:=random.randi_range(1,100)
		var bill:={"a":float(random.randi_range(1,8)),"b":float(random.randi_range(1,8))}
		var available:={"a":random.randf_range(-30,300),"b":random.randf_range(-30,300)}
		var output:=0.0
		for index in slots:
			var worst:=maxf(0,maxf(float(bill.a)*(index+1)-float(available.a),float(bill.b)*(index+1)-float(available.b)))
			output+=clampf(1.0-worst*.05,0,1)
		assert_float(float(S.evaluate(bill,slots,available).factor)).is_equal_approx(output/slots,.000001)
	assert_float(float(S.evaluate({"a":1.0},10000000,{"a":0.0}).factor)).is_equal_approx(9.5/10000000,.000000001)

func test_start_and_advance_without_operating_inputs()->void:
	MilitaryCampaign.equipment_queue.clear()
	GameState.resource_stockpiles.Timber=0.0
	var result:=MilitaryCampaign.start_production_line("improvised",0)
	assert_bool(result.has("ok")).is_true()
	var job:Dictionary=MilitaryCampaign.equipment_queue[0]
	var factor:=float(P.shortage_plan(MilitaryCampaign)[int(job.id)].factor)
	assert_float(factor).is_greater(0)
	assert_float(factor).is_less(1)
	P.advance(MilitaryCampaign,job,float(job.work_per_item))
	assert_float(float(job.last_work)).is_equal_approx(float(job.work_per_item)*factor,.000001)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(0.0)

func test_forecast_matches_real_day_and_paused_line_claims_nothing()->void:
	GameState.resource_stockpiles.Timber=0.0
	var forecast:=MilitaryCampaign.production_lines_snapshot()
	var expected:Dictionary={}
	for row:Dictionary in forecast.lines:expected[int(row.id)]=float(row.daily_work)
	MilitaryCampaign._process_equipment_production_day()
	for job:Dictionary in MilitaryCampaign.equipment_queue:
		assert_float(float(job.last_work)).is_equal_approx(float(expected[int(job.id)])*WorldSimulation.span,.00001)
	MilitaryCampaign.equipment_queue[0].paused=true
	var plan:=P.shortage_plan(MilitaryCampaign)
	assert_bool(plan.has(int(MilitaryCampaign.equipment_queue[0].id))).is_false()

func test_all_rows_visible_grid_dispatches_and_updates_retain_controls()->void:
	var provider=Provider.new(null,null)
	assert_array(provider.meta().subtabs).contains("Military").contains("Civilian")
	var block:Dictionary=provider.tab(0).blocks[0]
	var actions:Array=[]
	block.on_action=func(id,action,value):actions.append([id,action,value])
	var screen:Control=auto_free(Queue.new());screen.custom_minimum_size.x=540;add_child(screen);screen.setup(block)
	await get_tree().process_frame
	var lines:Array=block.lines
	for line:Dictionary in lines:
		var row:Control=screen.find_child("Line%d" % int(line.id),true,false)
		assert_bool(row.is_visible_in_tree()).is_true()
		assert_int(row.find_child("CapacityGrid",true,false).get_child_count()).is_equal(15)
		assert_float(row.size.y).is_less(190)
	var grid:Node=screen.find_child("CapacityGrid",true,false)
	var slot:Button=grid.get_child(0)
	slot.pressed.emit()
	assert_int(actions.size()).is_equal(1)
	assert_str(actions[0][1]).is_equal("hands")
	assert_bool(screen.update_block(block)).is_true()
	assert_object(screen.find_child("CapacityGrid",true,false)).is_same(grid)
	var civil:Dictionary=provider.tab(1).blocks[0]
	assert_str(civil.mode).is_equal("civilian")
	assert_str(civil.civilian_lines[0].id).is_equal("food")

func test_finite_target_does_not_asymptotically_stall_under_shortage()->void:
	var job:Dictionary=MilitaryCampaign.equipment_queue[0]
	job.target_stock=1;job.progress_days=float(job.work_per_item)*.9
	MilitaryCampaign.military_inventory[String(job.item)]=0
	P.advance(MilitaryCampaign,job,float(job.work_per_item),{"factor":.5})
	assert_int(P.stock(MilitaryCampaign,job)).is_equal(1)
	assert_str(P.state(MilitaryCampaign,job)).is_equal("Target met")

func test_extreme_shortage_stops_actual_work_then_recovers()->void:
	var job:Dictionary=MilitaryCampaign.equipment_queue[0]
	var before:=float(job.progress_days)
	P.advance(MilitaryCampaign,job,100,{"factor":0.0})
	assert_float(float(job.last_work)).is_equal(0.0)
	assert_float(float(job.progress_days)).is_equal(before)
	P.advance(MilitaryCampaign,job,float(job.work_per_item),{"factor":1.0})
	assert_int(int(job.completed)).is_greater(0)

func test_all_naval_and_air_products_reach_the_same_catalog()->void:
	var catalog=preload("res://scripts/joint_force_catalog.gd")
	for unit:Dictionary in catalog.UNITS.values():
		var gate:=String(unit.gate)
		if gate not in GameState.known_discoveries:GameState.known_discoveries.append(gate)
		GameState.discovery_adoption[gate]=1.0
	var products:=P.available_products(MilitaryCampaign)
	for unit:Dictionary in catalog.UNITS.values():
		assert_bool(String(unit.equipment) in products).override_failure_message(String(unit.label)+" missing from production").is_true()
