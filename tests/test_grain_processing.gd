extends GdUnitTestSuite
const G=preload("res://scripts/grain_processing.gd")
const O=preload("res://scripts/technology_operations.gd")
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("grain",731)
func after_test()->void:WorldSimulation.clear()
func prepare()->void:
	var state=WorldSimulation.state
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.food_stocks={"Fresh plants":0.0,"Fresh meat":0.0,"Fish":0.0,"Dry staples":10000.0,"Preserved food":0.0}
	state.founding_manifest.food_storage_rations=100000.0
func equip(id:String)->void:
	var state=WorldSimulation.state;var spec:=G.definition(id)
	for gate:String in spec.requires+[id]:
		if gate not in state.known_discoveries:state.known_discoveries.append(gate)
		state.discovery_adoption[gate]=1.0
	for item:String in spec.cost:state.resource_stockpiles[item]=1000.0
	assert_bool(G.install(id).get("ok",false)).is_true()
func tick(day:int,cultivated:float=0,workers:float=10,demand:float=100)->Dictionary:
	WorldSimulation.state.elapsed_days=day
	var result:=G.advance(cultivated,workers,demand,false)
	WorldSimulation.state.food_stocks["Dry staples"]-=float(result.routed)
	return result
func energy()->float:return WorldSimulation.food._stock_total()+G.in_process()
func test_seven_unique_operating_contracts_have_reachable_foundations()->void:
	WorldSimulation.scoped("grain",func()->void:
		assert_int(G.entries().size()).is_equal(7)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(G.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		var outputs:Array=WorldSimulation.resources.catalog.keys()
		for item:Dictionary in preload("res://scripts/civilian_industry.gd").PRODUCTS.values():outputs.append(item.output)
		for spec:Dictionary in G.METHODS.values():
			for item:String in spec.cost:assert_bool(item in outputs).override_failure_message(item).is_true()
	)
func test_installation_requires_knowledge_and_debits_actual_equipment_once()->void:
	WorldSimulation.scoped("grain",func()->void:
		prepare();var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		assert_bool(G.install("roller_grain_milling").has("error")).is_true()
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
		equip("roller_grain_milling")
		assert_float(float(WorldSimulation.state.resource_stockpiles["Electric Motors"])).is_equal(999.0)
		assert_int(int(G.data().tools.roller_grain_milling)).is_equal(1)
	)
func test_threshing_reclassifies_only_finite_new_cultivation_and_loses_food()->void:
	WorldSimulation.scoped("grain",func()->void:
		prepare();equip("threshing_frames");var before:=energy()
		var report:=tick(1,100,100)
		assert_float(float(report.routed)).is_equal(25.0)
		assert_float(float(G.data().stocks.grain)).is_equal(24.5)
		assert_float(energy()+float(report.loss)).is_equal_approx(before,.000001)
		var idle:=tick(2,0,100)
		assert_float(float(idle.routed)).is_equal(0.0)
	)
func test_all_steps_share_one_handler_budget_and_conserve_energy()->void:
	WorldSimulation.scoped("grain",func()->void:
		prepare()
		for id:String in G.METHODS:equip(id)
		equip("grain_milling")
		for key:String in G.STOCKS:G.data().stocks[key]=100.0
		WorldSimulation.state.resource_stockpiles.Freshwater=100.0
		WorldSimulation.state.technology_operations.last_day=1;WorldSimulation.state.technology_operations.services.electricity=2.0
		var before:=energy();var report:=tick(1,1000,10)
		assert_float(float(report.workers)).is_less_equal(2.000001)
		assert_float(float(report.electricity)).is_less_equal(2.0)
		assert_float(energy()+float(report.loss)).is_equal_approx(before,.000001)
		var stocks:Dictionary=G.data().duplicate(true)
		tick(1,1000,10)
		assert_dict(G.data()).is_equal(stocks)
	)
func test_powered_milling_waits_for_power_without_free_output()->void:
	WorldSimulation.scoped("grain",func()->void:
		prepare();equip("roller_grain_milling");G.data().stocks.dry=100.0
		WorldSimulation.state.resource_stockpiles.Stone=0.0
		var report:=tick(1)
		assert_float(float(G.data().stocks.flour)).is_equal(0.0)
		assert_float(float(report.electricity)).is_equal(0.0)
		WorldSimulation.state.technology_operations.last_day=2;WorldSimulation.state.technology_operations.services.electricity=1.0
		report=tick(2)
		assert_float(float(G.data().stocks.flour)).is_equal_approx(24.25,.000001)
		assert_float(float(report.electricity)).is_equal_approx(1.0,.000001)
	)
func test_sampling_precedes_forced_drying_and_samples_are_not_returned()->void:
	WorldSimulation.scoped("grain",func()->void:
		prepare();equip("grain_moisture_testing");equip("forced_air_grain_drying")
		G.data().stocks.clean=20.0
		WorldSimulation.state.technology_operations.last_day=1;WorldSimulation.state.technology_operations.services.electricity=1.0
		var first:=tick(1)
		assert_float(float(G.data().stocks.dry)).is_equal(0.0)
		assert_float(float(G.data().stocks.tested)).is_equal_approx(19.98,.000001)
		assert_float(float(first.loss)).is_equal_approx(.02,.000001)
		WorldSimulation.state.technology_operations.last_day=2;WorldSimulation.state.technology_operations.services.electricity=1.0
		tick(2)
		assert_float(float(G.data().stocks.dry)).is_equal_approx(19.98*.995,.000001)
	)
func test_sifting_retains_edible_bran_without_duplicating_flour()->void:
	WorldSimulation.scoped("grain",func()->void:
		prepare();equip("flour_sifting");G.data().stocks.flour=20.0
		var before:=energy();var report:=tick(1)
		assert_float(float(G.data().stocks.fine)).is_equal(15.0)
		assert_float(float(G.data().stocks.bran)).is_equal_approx(4.6,.000001)
		assert_float(float(G.data().stocks.flour)).is_equal(0.0)
		assert_float(energy()+float(report.loss)).is_equal_approx(before,.000001)
	)
func test_malting_ties_up_surplus_for_four_days_and_needs_finishing_workers()->void:
	WorldSimulation.scoped("grain",func()->void:
		prepare();equip("grain_malting");G.data().stocks.clean=100.0
		assert_bool(G.install("grain_malting").get("ok",false)).is_true()
		WorldSimulation.state.resource_stockpiles.Freshwater=100.0
		var first:=tick(1,0,10,100)
		assert_float(float(first.committed)).is_equal(30.0)
		assert_float(G.in_process()).is_equal(30.0)
		var water:=float(WorldSimulation.state.resource_stockpiles.Freshwater)
		for day in range(2,6):tick(day,0,0,100)
		assert_float(float(G.data().stocks.malt)).is_equal(0.0)
		var last:=tick(6,0,1,100)
		assert_float(float(last.released)).is_equal_approx(13.2,.000001)
		assert_float(float(WorldSimulation.state.resource_stockpiles.Freshwater)).is_equal(water)
		assert_float(G.in_process()).is_equal_approx(15.0,.000001)
	)
func test_storage_limits_and_spoilage_also_cover_grain_in_process()->void:
	WorldSimulation.scoped("grain",func()->void:
		prepare();WorldSimulation.state.food_stocks["Dry staples"]=0.0
		WorldSimulation.state.founding_manifest.food_storage_rations=50.0
		G.data().stocks.dry=80.0;G.data().batches=[{"amount":20.0,"ready_day":5}]
		var losses:=WorldSimulation.food._apply_storage_capacity()
		assert_float(float(losses["Grain processing"])).is_equal(50.0)
		assert_float(energy()).is_equal(50.0)
		var lost:=G.spoil(false,1.0)
		assert_float(lost).is_greater(0.0)
		assert_float(energy()+lost).is_equal_approx(50.0,.000001)
	)
func test_external_food_withdrawal_consumes_grain_once_and_forecast_is_read_only()->void:
	WorldSimulation.scoped("grain",func()->void:
		prepare();WorldSimulation.state.food_stocks["Dry staples"]=0.0;G.data().stocks.flour=100.0
		assert_float(WorldSimulation.food.issue_for_obligation(40.0)).is_equal(40.0)
		assert_float(G.available_total()).is_equal(60.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles.Food)).is_equal(60.0)
		var before:Dictionary=G.data().duplicate(true)
		WorldSimulation.food._forecast(30,{},WorldSimulation.food._calculate_demand(false),false)
		assert_dict(G.data()).is_equal(before)
	)
func test_owned_save_restore_preserves_tools_stocks_and_delayed_work()->void:
	WorldSimulation.scoped("grain",func()->void:
		prepare();equip("grain_malting");G.data().stocks.clean=80.0
		WorldSimulation.state.resource_stockpiles.Freshwater=100.0;tick(1)
	)
	var saved:=WorldSimulation.export_state().duplicate(true)
	var before:Dictionary=WorldSimulation.actors.grain.systems.GameState.grain_processing.duplicate(true)
	WorldSimulation.actors.grain.systems.GameState.grain_processing=G.empty_state()
	assert_bool(WorldSimulation.import_state(bytes_to_var(var_to_bytes(saved))).get("ok",false)).is_true()
	assert_dict(WorldSimulation.actors.grain.systems.GameState.grain_processing).is_equal(before)
func test_bad_nested_save_records_are_rejected_before_operation()->void:
	var bad:=G.empty_state();bad.stocks.grain=-1.0
	assert_bool(G.valid(bad)).is_false()
	assert_bool(G.valid_settlements([{"local_resources":false}])).is_false()
	bad=G.empty_state();bad.batches=[{"amount":1.0,"ready_day":NAN}]
	assert_bool(G.valid(bad)).is_false()
	bad=G.empty_state();bad.report={"inputs":{"Timber":-1.0}}
	assert_bool(G.valid(bad)).is_false()
func test_food_day_reports_actual_available_stock_and_leaves_no_double_count()->void:
	WorldSimulation.scoped("grain",func()->void:
		prepare();equip("threshing_frames");equip("winnowing_practice");equip("grain_milling")
		WorldSimulation.state.population_allocations.Food=40
		WorldSimulation.state.population_allocations.Logistics=20
		WorldSimulation.state.elapsed_days=1
		var before:=WorldSimulation.food._stock_total()
		var report:=WorldSimulation.food.process_day({"traveling":false},1.0,1.0)
		assert_float(float(report.food_net)).is_equal_approx(WorldSimulation.food._stock_total()-before,.000001)
		assert_float(float(report.grain_processing.workers)).is_less_equal(WorldSimulation.state.effective_workers("Logistics")*.2+.000001)
		assert_float(float(WorldSimulation.state.resource_stockpiles.Food)).is_equal_approx(WorldSimulation.food._stock_total(),.000001)
		assert_bool(G.valid(G.data())).is_true()
	)
func test_food_uses_ready_flour_before_staples_but_keeps_raw_grain_for_processing()->void:
	WorldSimulation.scoped("grain",func()->void:
		prepare();G.data().stocks.grain=20.0;G.data().stocks.flour=10.0
		var details:Dictionary={};var consumed:=WorldSimulation.food._consume(15.0,details)
		assert_float(float(consumed["Dry staples"])).is_equal(15.0)
		assert_float(float(details.processed)).is_equal(10.0)
		assert_float(float(G.data().stocks.grain)).is_equal(20.0)
		WorldSimulation.state.food_stocks["Dry staples"]=0.0
		consumed=WorldSimulation.food._consume(5.0)
		assert_float(float(consumed["Dry staples"])).is_equal(5.0)
		assert_float(float(G.data().stocks.grain)).is_equal(15.0)
	)
func test_power_request_is_bounded_by_real_inputs_and_other_handling_work()->void:
	WorldSimulation.scoped("grain",func()->void:
		prepare();equip("roller_grain_milling");equip("flour_sifting")
		WorldSimulation.state.population_allocations.Logistics=20
		G.data().stocks.dry=1.0
		assert_float(G.power_demand()).is_less_equal(.040001)
		G.data().stocks.dry=0.0
		assert_float(G.power_demand()).is_equal(0.0)
	)
func test_inspector_installs_paid_tools_and_retains_an_explanation()->void:
	WorldSimulation.scoped("grain",func()->void:
		prepare();equip("flour_sifting")
		var panel:VBoxContainer=auto_free(preload("res://scripts/hud/grain_processing_panel.gd").new())
		panel.subject="flour_sifting";add_child(panel)
		var before:=float(WorldSimulation.state.resource_stockpiles["Woven Cloth"])
		panel.install_button.pressed.emit()
		assert_float(float(WorldSimulation.state.resource_stockpiles["Woven Cloth"])).is_equal(before-1.0)
		assert_str(panel.details.text).contains("2 installed")
		assert_str(panel.install_button.tooltip_text).contains("Woven Cloth")
	)
func test_same_processing_orders_match_across_independent_owners()->void:
	WorldSimulation.create_actor("other",731)
	var human:=GameState.grain_processing.duplicate(true)
	for owner:String in ["grain","other"]:
		WorldSimulation.scoped(owner,func()->void:
			prepare();equip("threshing_frames");equip("winnowing_practice");equip("grain_milling")
			for day in range(1,6):tick(day,100,10)
		)
	assert_dict(WorldSimulation.actors.grain.systems.GameState.grain_processing).is_equal(WorldSimulation.actors.other.systems.GameState.grain_processing)
	assert_dict(GameState.grain_processing).is_equal(human)
func test_legacy_owner_without_grain_field_receives_empty_processing_state()->void:
	var saved:=WorldSimulation.export_state().duplicate(true)
	saved.actors.grain.state.GameState.erase("grain_processing")
	WorldSimulation.actors.grain.systems.GameState.grain_processing.stocks.grain=123.0
	assert_bool(WorldSimulation.import_state(saved).get("ok",false)).is_true()
	assert_dict(WorldSimulation.actors.grain.systems.GameState.grain_processing).is_equal(G.empty_state())
