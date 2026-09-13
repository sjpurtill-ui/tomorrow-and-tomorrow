extends GdUnitTestSuite
const B=preload("res://scripts/food_batches.gd")
const K=preload("res://scripts/food_batch_knowledge.gd")
const G=preload("res://scripts/grain_processing.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("batches",442)
func after_test()->void:WorldSimulation.clear()
func prepare()->void:
	WorldSimulation.state.settlement_site_committed=true;WorldSimulation.state.convoy_traveling=false
	WorldSimulation.state.food_stocks={"Fresh plants":0.0,"Fresh meat":0.0,"Fish":0.0,"Dry staples":100000.0,"Preserved food":0.0}
	WorldSimulation.state.founding_manifest.food_storage_rations=1000000.0
func equip(id:String)->void:
	var spec:Dictionary=K.METHODS[id];var gates:Array=spec.requires_all.duplicate();gates.append(id)
	for group:Array in spec.requires_any:gates.append(group[0])
	for gate:String in gates:
		if gate not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(gate)
		WorldSimulation.state.discovery_adoption[gate]=1.0
	for material:String in spec.cost:WorldSimulation.state.resource_stockpiles[material]=1000.0
	for material:String in spec.inputs:WorldSimulation.state.resource_stockpiles[material]=1000.0
	assert_bool(B.install(id).get("ok",false)).is_true()
func report()->Dictionary:return {"workers":0.0,"loss":0.0,"inputs":{},"methods":{}}
func energy()->float:return WorldSimulation.food._stock_total()+G.in_process()+B.in_process()
func test_operating_methods_have_reachable_real_inputs()->void:
	WorldSimulation.scoped("batches",func()->void:
		assert_int(K.entries().size()).is_equal(22)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		var outputs:Array=WorldSimulation.resources.catalog.keys()
		for product:Dictionary in preload("res://scripts/civilian_industry.gd").PRODUCTS.values():outputs.append(product.output)
		for spec:Dictionary in K.METHODS.values():
			for material:String in spec.cost.keys()+spec.inputs.keys():assert_bool(material in outputs).override_failure_message(material).is_true()
	)
func test_installation_debits_only_after_knowledge_and_supply_checks()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();assert_bool(B.install("controlled_baking").has("error")).is_true()
		equip("controlled_baking")
		assert_float(float(WorldSimulation.state.resource_stockpiles.Clay)).is_equal(994.0)
		assert_int(B.data().tools.controlled_baking).is_equal(1)
		WorldSimulation.state.resource_stockpiles.Stone=0.0
		var stock:=WorldSimulation.state.resource_stockpiles.duplicate()
		assert_bool(B.install("controlled_baking").has("error")).is_true();assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(stock)
	)
func test_admission_uses_actual_grain_and_conserves_energy()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();equip("food_pounding_mortars");equip("cereal_dehulling")
		var before:=energy();WorldSimulation.state.elapsed_days=1
		B.advance(100,100,false);assert_float(B.total(true)).is_equal(0.0)
		G.data().stocks.clean=100.0;G.data().stocks.grain=100.0;before=energy();WorldSimulation.state.elapsed_days=2
		var result:=B.advance(100,100,false)
		assert_float(B.available_total()).is_greater(0.0)
		assert_float(energy()+float(result.loss)).is_equal_approx(before,.000001)
	)
func test_washing_keeps_edible_residue_and_charges_water()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();equip("starch_washing_separation");var lot:=B.add_lot("meal",100,0)
		var before:=energy();var result:=report();var water:=float(WorldSimulation.state.resource_stockpiles.Freshwater)
		B.process_lot("starch_washing_separation",lot,10,result,1)
		assert_float(energy()+float(result.loss)).is_equal_approx(before,.000001)
		assert_float(float(WorldSimulation.state.resource_stockpiles.Freshwater)).is_less(water)
		var residue:=0.0
		for child:Dictionary in B.data().lots:
			if child.kind=="residue":residue+=float(child.amount)
		assert_float(residue).is_greater(0.0)
	)
func test_flatbread_does_not_require_leavening_and_baking_needs_fuel()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();equip("controlled_baking");var lot:=B.add_lot("dough",10,0)
		assert_bool("dough_leavening" in WorldSimulation.state.known_discoveries).is_false()
		WorldSimulation.state.resource_stockpiles.Timber=0.0;var result:=report()
		assert_float(B.process_lot("controlled_baking",lot,1,result,1)).is_equal(0.0)
		WorldSimulation.state.resource_stockpiles.Timber=1.0;var before:=energy()
		B.process_lot("controlled_baking",lot,1,result,1)
		assert_float(B.available_total()).is_equal_approx(9.5,.000001)
		assert_float(energy()+float(result.loss)).is_equal_approx(before,.000001)
	)
func test_fermentation_holds_food_and_cultures_shorten_only_supported_batches()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();equip("dough_leavening");equip("controlled_baking")
		var lot:=B.add_lot("dough",10,0);var result:=report();B.process_lot("dough_leavening",lot,1,result,1)
		var leavened:Dictionary=B.data().lots.back()
		assert_int(leavened.ready).is_equal(3)
		assert_float(B.process_lot("controlled_baking",leavened,1,result,2)).is_equal(0.0)
		assert_float(B.available_total()).is_equal(0.0)
		B.add_lot("starter",1,0);lot=B.add_lot("dough",10,1)
		var before:=energy();var loss:=float(result.loss)
		B.process_lot("dough_leavening",lot,1,result,1)
		assert_int(B.data().lots.back().ready).is_equal(2)
		assert_float(energy()+float(result.loss)-loss).is_equal_approx(before,.000001)
	)
func test_partial_assay_does_not_mark_unexamined_food()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();equip("food_acidity_measurement");var lot:=B.add_lot("bread",100,0);var before:=energy();var result:=report()
		B.process_lot("food_acidity_measurement",lot,.1,result,1)
		assert_bool(lot.observations.has("acidity")).is_false();assert_float(float(lot.amount)).is_equal(94.0)
		assert_bool(B.data().lots.back().observations.has("acidity")).is_true()
		assert_float(energy()+float(result.loss)).is_equal_approx(before,.000001)
	)
func test_measurements_follow_their_lot_prerequisites()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();equip("food_water_activity_measurement");var lot:=B.add_lot("bread",10,0);var result:=report()
		assert_float(B.process_lot("food_water_activity_measurement",lot,1,result,1)).is_equal(0.0)
		equip("humidity_measurement");B.process_lot("humidity_measurement",lot,1,result,1);lot=B.data().lots.back()
		assert_float(B.process_lot("food_water_activity_measurement",lot,1,result,1)).is_greater(0.0)
		lot=B.data().lots.back();assert_bool(lot.observations.has("activity")).is_true()
		assert_bool(B.eligible(lot,"review",1)).is_false()
	)
func test_leak_checks_expire_and_unchecked_packaging_gives_no_storage_bonus()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();var lot:=B.add_lot("bread",100,0);lot.seal=1.0;lot.observations.barrier=0
		WorldSimulation.state.elapsed_days=1
		assert_float(B.spoil(false,1)).is_equal_approx(1.5,.000001)
		lot.observations.leak=1;lot.observations.leak_pass=true
		var before:=float(lot.amount);assert_float(B.spoil(false,1)).is_equal_approx(before*.015*.35,.000001)
		WorldSimulation.state.elapsed_days=4;before=lot.amount
		assert_float(B.spoil(false,1)).is_equal_approx(before*.015,.000001)
	)
func test_all_operations_share_workers_and_same_day_is_idempotent()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare()
		for id:String in K.METHODS:equip(id)
		for kind:String in B.KINDS:
			var lot:=B.add_lot(kind,100,0)
			if kind in B.Selected.KINDS:
				var source_kind:String={"leached_acorn_meal":"selected_acorns","pressed_root_pulp":"selected_roots","split_pulses":"selected_pulses"}.get(kind,kind)
				lot.source_id="0:0:"+source_kind;lot.source_origin=[0.0,0.0]
		for key:String in G.STOCKS:G.data().stocks[key]=100.0
		WorldSimulation.state.elapsed_days=1;var before:=energy();var result:=B.advance(10,100,false)
		assert_float(float(result.workers)).is_less_equal(2.000001)
		assert_float(energy()+float(result.loss)).is_equal_approx(before,.000001)
		var saved:=B.data().duplicate(true);B.advance(10,100,false);assert_dict(B.data()).is_equal(saved)
		assert_bool(B.valid(saved)).override_failure_message(str(saved)).is_true()
	)
func test_consumption_and_forecast_count_ready_food_once()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();WorldSimulation.state.food_stocks["Dry staples"]=0.0
		B.add_lot("bread",10,0);B.add_lot("dough",20,0)
		var before:=energy();var result:=WorldSimulation.food._consume(6)
		assert_float(float(result["Dry staples"])).is_equal(6.0);assert_float(energy()).is_equal(before-6)
		assert_float(B.in_process()).is_equal(20.0)
		var state:=B.data().duplicate(true);WorldSimulation.food._forecast(3,{},WorldSimulation.food._calculate_demand(false),false);assert_dict(B.data()).is_equal(state)
	)
func test_malformed_and_legacy_owned_state()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();B.add_lot("bread",10,0);var valid:=B.data().duplicate(true)
		assert_bool(B.valid(valid)).is_true();valid.lots[0].amount=NAN;assert_bool(B.valid(valid)).is_false()
	)
	var saved:=WorldSimulation.export_state().duplicate(true)
	saved.actors.batches.state.GameState.erase("food_batches")
	assert_bool(WorldSimulation.import_state(saved).get("ok",false)).is_true()
	assert_dict(WorldSimulation.actors.batches.systems.GameState.food_batches).is_equal(B.empty_state())
func test_independent_owners_match_without_changing_human_stocks()->void:
	WorldSimulation.create_actor("other",442);var human:=GameState.food_batches.duplicate(true)
	for owner:String in ["batches","other"]:
		WorldSimulation.scoped(owner,func()->void:
			prepare();equip("food_pounding_mortars");equip("hand_dough_forming");equip("controlled_baking")
			G.data().stocks.flour=100.0
			for day in range(1,5):WorldSimulation.state.elapsed_days=day;B.advance(20,100,false)
		)
	assert_dict(WorldSimulation.actors.batches.systems.GameState.food_batches).is_equal(WorldSimulation.actors.other.systems.GameState.food_batches)
	assert_dict(GameState.food_batches).is_equal(human)
func test_all_eight_inspection_methods_apply_paid_records_to_one_lot()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();var lot:=B.add_lot("bread",10,0);var result:=report();var before:=energy()
		for mode:String in ["humidity","trace","loss","acidity","activity","review","barrier","leak"]:
			var id:=""
			for candidate:String in K.METHODS:
				if K.METHODS[candidate].mode==mode:id=candidate;break
			equip(id);assert_float(B.process_lot(id,lot,1,result,1)).is_greater(0.0)
			lot=B.data().lots.back();assert_bool(lot.observations.has(mode)).is_true()
		assert_bool(lot.observations.leak_pass).is_true();assert_float(float(lot.seal)).is_equal(1.0)
		assert_int(result.methods.size()).is_equal(8)
		assert_float(energy()+float(result.loss)).is_equal_approx(before,.000001)
	)
func test_real_food_day_stock_net_includes_processing_and_shared_workers()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();equip("controlled_baking");equip("food_pounding_mortars");equip("hand_dough_forming")
		G.data().stocks.flour=100.0;B.add_lot("dough",100,0)
		WorldSimulation.state.population_allocations.Food=40;WorldSimulation.state.population_allocations.Logistics=30
		WorldSimulation.state.elapsed_days=1;var before:=WorldSimulation.food._stock_total()
		var result:=WorldSimulation.food.process_day({"traveling":false},1.0,1.0)
		assert_float(float(result.food_net)).is_equal_approx(WorldSimulation.food._stock_total()-before,.000001)
		assert_float(float(result.food_batches.workers)).is_less_equal(WorldSimulation.state.effective_workers("Logistics")*.2+.000001)
		assert_float(float(WorldSimulation.state.resource_stockpiles.Food)).is_equal_approx(WorldSimulation.food._stock_total(),.000001)
		assert_bool(B.valid(B.data())).override_failure_message(str(B.data())).is_true()
	)
func test_owned_save_roundtrip_preserves_lots_tools_and_next_day()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();equip("controlled_baking");var lot:=B.add_lot("leavened",20,1);lot.ready=3
	)
	var saved:=WorldSimulation.export_state().duplicate(true)
	WorldSimulation.scoped("batches",func()->void:WorldSimulation.state.elapsed_days=3;B.advance(100,100,false))
	var expected:Dictionary=WorldSimulation.actors.batches.systems.GameState.food_batches.duplicate(true)
	assert_bool(WorldSimulation.import_state(bytes_to_var(var_to_bytes(saved))).get("ok",false)).is_true()
	WorldSimulation.scoped("batches",func()->void:WorldSimulation.state.elapsed_days=3;B.advance(100,100,false))
	assert_dict(WorldSimulation.actors.batches.systems.GameState.food_batches).is_equal(expected)
func test_full_save_file_restores_food_lots_and_missing_legacy_field()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(442);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize();CivilizationSystem.reset_for_new_world()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	prepare();equip("controlled_baking");equip("grain_parboiling");var lot:=B.add_lot("dough",20,0);lot.ready=3
	B.add_lot("wet_parboiled",8,0).ready=2;B.add_lot("solar_drying",6,0).ready=1
	var expected:=B.data().duplicate(true);var slot:="food_batches_%d"%OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	GameState.food_batches=B.empty_state();var restored:=SaveSystem.load_game(slot)
	assert_bool(restored.get("ok",false)).override_failure_message(str(restored)).is_true();assert_dict(B.data()).is_equal(expected)
	var payload:=SaveSystem._read_payload(slot);payload.reflected_GameState.erase("food_batches")
	assert_bool(SaveSystem._write_payload(SaveSystem.slot_path(slot),payload).get("ok",false)).is_true()
	restored=SaveSystem.load_game(slot);DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(restored.get("ok",false)).is_true();assert_dict(B.data()).is_equal(B.empty_state())
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func test_inspector_install_button_uses_actual_quote()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();equip("controlled_baking")
		var panel:=preload("res://scripts/hud/food_batches_panel.gd").new();panel.subject="controlled_baking";auto_free(panel);add_child(panel)
		var before:=float(WorldSimulation.state.resource_stockpiles.Clay);panel.install_button.pressed.emit()
		assert_int(B.data().tools.controlled_baking).is_equal(2)
		assert_float(float(WorldSimulation.state.resource_stockpiles.Clay)).is_equal(before-6.0)
		assert_str(panel.details.text).contains("2 installed")
	)
func test_repackaging_pays_again_and_requires_a_new_leak_check()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();equip("food_package_barrier_testing");var lot:=B.add_lot("bread",10,0)
		lot.observations={"review":0,"barrier":0,"leak":1,"leak_pass":true};lot.seal=.5
		var cloth:=float(WorldSimulation.state.resource_stockpiles["Woven Cloth"]);var result:=report()
		assert_float(B.process_lot("food_package_barrier_testing",lot,1,result,3)).is_greater(0.0)
		lot=B.data().lots.back();assert_bool(lot.observations.has("leak")).is_false()
		assert_float(float(WorldSimulation.state.resource_stockpiles["Woven Cloth"])).is_less(cloth)
		assert_bool(B.eligible(lot,"leak",3)).is_true()
	)
func test_lot_capacity_stalls_without_consuming_inputs_or_discarding_food()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();equip("controlled_baking")
		for i in B.LIMIT:B.add_lot("dough",1,0)
		var before:=energy();var fuel:=float(WorldSimulation.state.resource_stockpiles.Timber);var result:=report()
		assert_float(B.process_lot("controlled_baking",B.data().lots[0],.01,result,1)).is_equal(0.0)
		assert_float(energy()).is_equal(before);assert_float(float(WorldSimulation.state.resource_stockpiles.Timber)).is_equal(fuel)
		assert_float(B.process_lot("controlled_baking",B.data().lots[0],1,result,1)).is_greater(0.0)
		assert_int(B.data().lots.size()).is_equal(B.LIMIT)
	)
func test_one_machine_cannot_process_multiple_full_shifts_across_lots()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();equip("controlled_baking");var first:=B.add_lot("dough",100,0);var second:=B.add_lot("dough",100,0);var result:=report()
		B.process_lot("controlled_baking",first,100,result,1)
		assert_float(B.process_lot("controlled_baking",second,100,result,1)).is_equal(0.0)
		assert_float(float(result.methods.controlled_baking)).is_equal(24.0)
		assert_float(float(result.workers)).is_equal(1.0)
	)
func test_existing_milled_flour_forms_dough_without_a_redundant_pounding_gate()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();equip("hand_dough_forming");G.data().stocks.flour=100.0;G.data().stocks.fine=100.0
		var before:=energy();WorldSimulation.state.elapsed_days=1;var result:=B.advance(100,100,false)
		assert_bool("food_pounding_mortars" in WorldSimulation.state.known_discoveries).is_false()
		assert_float(B.in_process()).is_equal_approx(18*.995,.000001)
		assert_float(float(result.methods.hand_dough_forming)).is_equal(18.0)
		assert_float(energy()+float(result.loss)).is_equal_approx(before,.000001)
	)
func test_steward_installs_dough_tools_for_existing_meal_lots()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();equip("hand_dough_forming");B.data().tools.erase("hand_dough_forming");B.add_lot("meal",100,0)
		var timber:=float(WorldSimulation.state.resource_stockpiles.Timber);WorldSimulation.state.elapsed_days=1
		B.advance(100,100,false)
		assert_int(int(B.data().tools.get("hand_dough_forming",0))).is_equal(1)
		assert_float(float(WorldSimulation.state.resource_stockpiles.Timber)).is_equal(timber-2)
		assert_float(B.in_process()).is_greater(0.0)
	)
func test_parboiling_reserves_real_grain_and_pays_both_heat_and_later_drying()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();equip("grain_parboiling");WorldSimulation.state.resource_stockpiles.Stone=0.0
		G.data().stocks.grain=16.0;var before:=energy();WorldSimulation.state.elapsed_days=1
		var result:=B.advance(100,100,false)
		assert_float(G.data().stocks.grain).is_equal(0.0)
		assert_float(B.in_process()).is_equal_approx(15.52,.000001)
		assert_float(float(result.inputs.Freshwater)).is_equal_approx(2.88,.000001)
		assert_float(float(result.inputs.Timber)).is_equal_approx(.64,.000001)
		assert_float(energy()+float(result.loss)).is_equal_approx(before,.000001)
		WorldSimulation.state.elapsed_days=2;B.advance(100,100,false)
		assert_float(B.available_total()).is_equal(0.0)
		WorldSimulation.state.elapsed_days=3;before=energy();result=B.advance(100,100,false)
		assert_float(B.in_process()).is_equal(0.0)
		assert_float(B.available_total()).is_equal_approx(15.4424,.000001)
		assert_float(float(result.inputs.Timber)).is_equal_approx(15.52*.015,.000001)
		assert_bool(result.inputs.has("Freshwater")).is_false()
		assert_float(energy()+float(result.loss)).is_equal_approx(before,.000001)
		assert_float(float(B.issue(100).processed)).is_equal_approx(15.4424,.000001)
	)
func test_parboiling_missing_water_or_drying_fuel_cannot_finish_food()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();equip("grain_parboiling");WorldSimulation.state.resource_stockpiles.Stone=0.0
		G.data().stocks.grain=10.0;WorldSimulation.state.resource_stockpiles.Freshwater=0.0;WorldSimulation.state.elapsed_days=1
		B.advance(100,100,false);assert_float(G.data().stocks.grain).is_equal(10.0)
		WorldSimulation.state.resource_stockpiles.Freshwater=100.0;WorldSimulation.state.elapsed_days=2;B.advance(100,100,false)
		WorldSimulation.state.resource_stockpiles.Timber=0.0;WorldSimulation.state.elapsed_days=4
		B.advance(100,100,false);assert_float(B.available_total()).is_equal(0.0);assert_float(B.in_process()).is_greater(0.0)
	)
func solar_environment(temperature:float,precipitation:float)->void:
	WorldSimulation.state.player_settlements=[{"id":"drying","primary":true,"environment_profile":{"mean_temperature_c":temperature,"seasonality_c":0.0,"precipitation":precipitation}}]
func test_solar_chamber_consumes_actual_plants_and_waits_for_weather_and_work()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();equip("indirect_solar_food_drying");solar_environment(25.0,.2)
		WorldSimulation.state.food_stocks["Fresh plants"]=20.0;var before:=energy();WorldSimulation.state.elapsed_days=1
		var result:=B.advance(100,100,false)
		assert_float(B.in_process()).is_equal_approx(20.0,.000001)
		assert_float(float(WorldSimulation.state.food_stocks["Fresh plants"])).is_equal_approx(0.0,.000001)
		assert_float(float(result.workers)).is_equal_approx(1.0,.000001)
		assert_dict(result.inputs).is_empty();assert_float(energy()).is_equal_approx(before,.000001)
		WorldSimulation.state.elapsed_days=2;solar_environment(0.0,.2);B.advance(100,100,false)
		assert_float(B.available_total()).is_equal(0.0)
		WorldSimulation.state.elapsed_days=3;solar_environment(25.0,1.0);B.advance(100,100,false)
		assert_float(B.available_total()).is_equal(0.0)
		WorldSimulation.state.elapsed_days=4;solar_environment(25.0,.2);B.advance(0,100,false)
		assert_float(B.available_total()).is_equal(0.0)
		WorldSimulation.state.elapsed_days=5;result=B.advance(100,100,false)
		assert_float(B.available_total()).is_equal_approx(18.4,.000001)
		assert_float(energy()+float(result.loss)).is_equal_approx(before,.000001)
		assert_float(float(B.issue(100).processed)).is_equal_approx(18.4,.000001)
	)
func test_solar_and_fuel_are_paid_alternatives_for_wet_grain()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();equip("grain_parboiling");equip("indirect_solar_food_drying");solar_environment(25.0,.2)
		WorldSimulation.state.resource_stockpiles.Timber=0.0;var lot:=B.add_lot("wet_parboiled",10,0);lot.ready=2
		WorldSimulation.state.elapsed_days=2;var result:=B.advance(100,100,false)
		assert_float(B.available_total()).is_equal_approx(9.95,.000001)
		assert_dict(result.inputs).is_empty();assert_bool(result.methods.has("grain_parboiling")).is_false()
	)
func test_drying_quota_is_shared_across_lots_and_new_chamber_loading()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();equip("indirect_solar_food_drying");solar_environment(25.0,.2)
		B.add_lot("solar_drying",10,0);B.add_lot("solar_drying",20,0);WorldSimulation.state.food_stocks["Fresh plants"]=30.0
		WorldSimulation.state.elapsed_days=2;var result:=B.advance(1000,100,false)
		assert_float(float(result.methods.indirect_solar_food_drying)).is_equal_approx(20.0,.000001)
		assert_float(float(WorldSimulation.state.food_stocks["Fresh plants"])).is_equal(30.0)
		assert_float(B.in_process()).is_equal_approx(10.0,.000001)
		var expected:=B.data().duplicate(true);B.advance(1000,100,false);assert_dict(B.data()).is_equal(expected)
	)
func test_conditioning_never_reserves_last_rations_or_bypasses_lot_limit()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();equip("grain_parboiling");WorldSimulation.state.resource_stockpiles.Stone=0.0
		WorldSimulation.state.food_stocks["Dry staples"]=0.0;G.data().stocks.grain=10.0
		WorldSimulation.state.elapsed_days=1;B.advance(100,100,false);assert_float(B.in_process()).is_equal(0.0)
		WorldSimulation.state.food_stocks["Dry staples"]=100000.0
		for i in B.LIMIT:B.add_lot("meal",1,0)
		var inputs:=WorldSimulation.state.resource_stockpiles.duplicate();WorldSimulation.state.elapsed_days=2;B.advance(100,100,false)
		assert_float(G.data().stocks.grain).is_equal(10.0);assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(inputs)
	)
func test_wet_conditioning_binary_save_continues_without_free_completion()->void:
	WorldSimulation.scoped("batches",func()->void:
		prepare();equip("grain_parboiling");WorldSimulation.state.resource_stockpiles.Stone=0.0
		G.data().stocks.grain=8.0;WorldSimulation.state.elapsed_days=1;B.advance(100,100,false)
		var encoded:=var_to_bytes(B.data());assert_bool(B.valid(bytes_to_var(encoded))).is_true()
		var loaded:Dictionary=bytes_to_var(encoded);B.data().clear();B.data().merge(loaded,true)
		WorldSimulation.state.elapsed_days=2;B.advance(100,100,false);assert_float(B.available_total()).is_equal(0.0)
		WorldSimulation.state.elapsed_days=3;B.advance(100,100,false);assert_float(B.available_total()).is_greater(0.0)
		assert_bool(B.valid(B.data())).override_failure_message(str(B.data())).is_true()
	)
