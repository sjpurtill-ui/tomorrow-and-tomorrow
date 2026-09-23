extends GdUnitTestSuite
const I=preload("res://scripts/civilian_industry.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const Samples=preload("res://scripts/polymer_samples.gd")
const SEC=preload("res://scripts/sec_acquisition.gd")
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("sec",5571)
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func learn(gate:String)->void:
	var s=WorldSimulation.state
	if gate not in s.known_discoveries:s.known_discoveries.append(gate)
	s.discovery_adoption[gate]=1.0
func supply(bill:Dictionary,scale:float=1.0)->void:
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	for item:String in bill:stocks[item]=float(stocks.get(item,0))+float(bill[item])*scale
## Paid, commissioned bench with one retained batch prepared from raw materials
## and Civilian Goods; `column` also stocks the column and first run supplies.
func prepare(column:bool=true)->void:
	var s=WorldSimulation.state;s.elapsed_days=0;s.settlement_site_committed=true;s.convoy_traveling=false
	s.population_allocations.Crafting=40;s.population_health=1.0;s.simulation_metrics.labor_efficiency=1.0
	Ops.data().last_day=0
	var bench:Dictionary=Ops.PLANTS.sec_analytical_bench;var batch:=I.product(SEC.PREPARATION)
	for gate:String in [bench.gate]+bench.requires+[batch.gate]:learn(gate)
	var bill:=Samples.preparation_bill(SEC.PREPARATION)
	assert_bool(bill.has("Sealed SEC PEG Batches") or SEC.COLUMN.has("Packed Aqueous SEC Columns")).is_false()
	for item:String in bill:
		if item not in ["Coal","Freshwater"]:s.resource_stockpiles[item]=0.0
	for item:String in bench.cost:s.resource_stockpiles[item]=float(bench.cost[item])
	assert_bool(Ops.install("sec_analytical_bench").get("ok",false)).is_true()
	for item:String in bench.cost:assert_float(float(s.resource_stockpiles[item])).is_equal(0.0)
	s.resource_stockpiles["Coal"]=1000.0;s.resource_stockpiles["Freshwater"]=1000.0
	Ops.data().plants["steam_generator"]={"installed":1,"building":0,"work":0.0,"enabled":true}
	for day:int in range(1,9):s.elapsed_days=day;Ops.advance(day)
	assert_int(int(Ops.data().plants.sec_analytical_bench.installed)).is_equal(1)
	assert_int(Samples.data().records.size()).is_equal(0)
	supply(bill);var before:Dictionary=s.resource_stockpiles.duplicate()
	assert_bool(Samples.prepare(SEC.PREPARATION)).is_true()
	for item:String in bill:assert_float(float(s.resource_stockpiles[item])).is_equal_approx(float(before[item])-float(bill[item]),.000001)
	if column:supply(SEC.COLUMN);supply(SEC.RUN,1.5)
	s.resource_stockpiles["Freshwater"]=1000.0
	assert_int(Samples.data().records.size()).is_equal(1)
## Column supplies other than those the bench and generator also draw daily.
func column_stock()->Dictionary:
	var result:Dictionary={}
	for item:String in SEC.COLUMN:
		if item not in ["Coal","Freshwater"]:result[item]=float(WorldSimulation.state.resource_stockpiles.get(item,0))
	return result
func test_paid_column_resolves_retained_distribution_once()->void:
	WorldSimulation.scoped("sec",func()->void:
		prepare()
		var s=WorldSimulation.state;var coal_before:=float(s.resource_stockpiles.Coal)
		var supplies:=column_stock()
		for day:int in range(9,31):s.elapsed_days=day;Ops.advance(day)
		for item:String in supplies:assert_float(float(s.resource_stockpiles[item])).is_less(float(supplies[item]))
		assert_float(float(s.resource_stockpiles.Coal)).is_less(coal_before)
		assert_float(float(s.resource_stockpiles.get("Distribution-Qualified PEG Batches",0))+float(s.resource_stockpiles.get("Broad-Range Recovered PEG Batches",0))).is_equal(1.0)
		assert_int(int(SEC.column().remaining_runs)).is_equal(7)
		# A released grade ends the programme's demand for further retained batches.
		assert_int(Samples.data().records.size()).is_equal(1)
		for id:String in Samples.data().records:
			assert_str(SEC.report(Samples.data().records[id]).status).is_equal("resolved")
		assert_bool(Ops.valid(Ops.data())).is_true())
func test_column_shortage_does_not_consume_sample_and_same_day_cannot_accelerate()->void:
	WorldSimulation.scoped("sec",func()->void:
		prepare(false);var s=WorldSimulation.state
		s.elapsed_days=9;Ops.advance(9)
		assert_bool(SEC.column().is_empty()).is_true()
		assert_str(Samples.data().records["1"].status).is_equal("unmeasured")
		assert_int(Samples.data().records.size()).is_equal(1)
		supply(SEC.COLUMN);supply(SEC.RUN,1.5)
		s.elapsed_days=10;Ops.advance(10)
		assert_float(float(SEC.column().work)).is_equal(1.0)
		Ops.data().services["sec_column_time"]=100.0
		SEC.advance_pending();SEC.advance_pending()
		assert_float(float(SEC.column().work)).is_equal(1.0)
		assert_str(Samples.data().records["1"].status).is_equal("unmeasured")
		assert_bool(Ops.valid(Ops.data())).is_true())
func test_partial_and_completed_sec_runs_survive_full_save_without_second_payment()->void:
	WorldSimulation.scoped("sec",func()->void:
		prepare();var s=WorldSimulation.state
		for day:int in range(9,17):s.elapsed_days=day;Ops.advance(day)
		assert_float(float(Samples.data().records["1"].acquisition.work)).is_equal(2.0))
	var slot:="sec_operation_%d"%OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();var restored:=SaveSystem.load_game(slot)
	assert_bool(restored.get("ok",false)).override_failure_message(str(restored)).is_true()
	if restored.get("ok",false):
		WorldSimulation.scoped("sec",func()->void:
			var s=WorldSimulation.state;var before:Dictionary=s.resource_stockpiles.duplicate(true)
			SEC.advance_pending()
			assert_float(float(Samples.data().records["1"].acquisition.work)).is_equal(2.0)
			assert_dict(s.resource_stockpiles).is_equal(before)
			for day:int in range(17,19):s.elapsed_days=day;Ops.advance(day)
			assert_float(float(s.resource_stockpiles.get("Distribution-Qualified PEG Batches",0))).is_equal(1.0))
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();restored=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(restored.get("ok",false)).override_failure_message(str(restored)).is_true()
	if not restored.get("ok",false):return
	WorldSimulation.scoped("sec",func()->void:
		var record:Dictionary=Samples.data().records["1"]
		assert_str(SEC.report(record).status).is_equal("resolved")
		SEC.release(record);SEC.release(record)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Distribution-Qualified PEG Batches"])).is_equal(1.0)
		var damaged:=Ops.data().duplicate(true);damaged.polymer_samples.records["1"].sec_calibration=[]
		assert_bool(Ops.valid(damaged)).is_false()
		damaged=Ops.data().duplicate(true);damaged.sec_column.standards="bad"
		assert_bool(Ops.valid(damaged)).is_false())
func test_column_expiry_during_outage_loses_run_without_free_grade()->void:
	WorldSimulation.scoped("sec",func()->void:
		prepare();var s=WorldSimulation.state
		for day:int in range(9,16):s.elapsed_days=day;Ops.advance(day)
		assert_float(float(Samples.data().records["1"].acquisition.work)).is_equal(1.0)
		s.elapsed_days=50;Ops.advance(50)
		assert_str(Samples.data().records["1"].status).is_equal("measurement_failed")
		assert_float(float(s.resource_stockpiles.get("Distribution-Qualified PEG Batches",0))).is_equal(0.0)
		assert_int(Samples.data().records.size()).is_equal(1)
		assert_bool(Ops.valid(Ops.data())).is_true())

func test_live_sec_panel_reports_supplies_capacity_results_and_pause_without_side_effects()->void:
	WorldSimulation.scoped("sec",func()->void:
		var panel:VBoxContainer=auto_free(preload("res://scripts/hud/technology_operations_panel.gd").new())
		panel.subject="size_exclusion_chromatography";add_child(panel)
		assert_str(panel.specimen_report.text).contains("Missing for preparation:")
		for item:String in SEC.COLUMN:
			if float(WorldSimulation.state.resource_stockpiles.get(item,0))<float(SEC.COLUMN[item]):assert_str(panel.specimen_report.text).contains(item)
		prepare()
		var s=WorldSimulation.state
		for day:int in range(9,19):s.elapsed_days=day;Ops.advance(day)
		var before:Dictionary=Ops.data().duplicate(true);var stocks:Dictionary=s.resource_stockpiles.duplicate(true)
		panel.refresh();panel.refresh()
		assert_str(panel.specimen_report.text).contains("7 runs remaining")
		assert_str(panel.specimen_report.text).contains("Relative size bins")
		assert_str(panel.specimen_report.text).contains("selected binder route")
		assert_dict(Ops.data()).is_equal(before);assert_dict(s.resource_stockpiles).is_equal(stocks)
		panel.rows.sec_analytical_bench.pause.pressed.emit()
		assert_bool(Ops.data().plants.sec_analytical_bench.enabled).is_false()
		s.elapsed_days=19;Ops.advance(19);panel.refresh()
		assert_float(Ops.service("sec_column_time")).is_equal(0.0)
		assert_str(panel.rows.sec_analytical_bench.label.text).contains("Paused")
		assert_str(preload("res://scripts/nmr_acquisition.gd").report_text()).is_equal("No prepared NMR specimens."))

func test_remote_store_specimen_cannot_spend_primary_column_supplies()->void:
	WorldSimulation.scoped("sec",func()->void:
		prepare();var s=WorldSimulation.state
		Samples.data().records["1"].source_store="remote_store"
		var supplies:=column_stock()
		s.elapsed_days=9;Ops.advance(9)
		assert_bool(SEC.column().is_empty()).is_true()
		assert_dict(column_stock()).is_equal(supplies)
		var before:Dictionary=s.resource_stockpiles.duplicate(true)
		s.resource_settlement_id="remote_store"
		assert_float(Ops.service("sec_column_time")).is_equal(0.0)
		assert_bool(Ops.quote("sec_analytical_bench").has("error")).is_true()
		SEC.advance_pending()
		assert_dict(s.resource_stockpiles).is_equal(before)
		assert_bool(SEC.column().is_empty()).is_true()
		s.resource_settlement_id="")
func test_two_civilizations_keep_identical_sample_ids_and_grades_separate()->void:
	var initial:Dictionary={}
	WorldSimulation.scoped("sec",func()->void:
		prepare();var s=WorldSimulation.state
		for day:int in range(9,16):s.elapsed_days=day;Ops.advance(day)
		initial["stocks"]=s.resource_stockpiles.duplicate(true)
		initial["ledger"]=Ops.data().duplicate(true))
	WorldSimulation.create_actor("other_sec",5572)
	WorldSimulation.scoped("other_sec",func()->void:
		prepare();var s=WorldSimulation.state
		for day:int in range(9,19):s.elapsed_days=day;Ops.advance(day)
		assert_float(float(s.resource_stockpiles.get("Distribution-Qualified PEG Batches",0))).is_equal(1.0))
	WorldSimulation.scoped("sec",func()->void:
		var s=WorldSimulation.state
		assert_dict(s.resource_stockpiles).is_equal(initial.stocks)
		assert_dict(Ops.data()).is_equal(initial.ledger)
		assert_float(float(Samples.data().records["1"].acquisition.work)).is_equal(1.0)
		for day:int in range(16,19):s.elapsed_days=day;Ops.advance(day)
		assert_float(float(s.resource_stockpiles.get("Distribution-Qualified PEG Batches",0))).is_equal(1.0))
	WorldSimulation.scoped("other_sec",func()->void:
		assert_float(float(WorldSimulation.state.resource_stockpiles.get("Distribution-Qualified PEG Batches",0))).is_equal(1.0)
		assert_int(int(SEC.column().remaining_runs)).is_equal(7))
