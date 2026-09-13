extends GdUnitTestSuite
const C=preload("res://scripts/household_clothing.gd")
const K=preload("res://scripts/clothing_knowledge.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("clothes",442)
func after_test()->void:WorldSimulation.clear()
func prepare()->void:WorldSimulation.state.settlement_site_committed=true;WorldSimulation.state.convoy_traveling=false
func equip(id:String)->void:
	var spec:Dictionary=K.METHODS[id];var gates:Array=spec.requires_all.duplicate();gates.append(id)
	for group:Array in spec.requires_any:gates.append(group[0])
	for gate:String in gates:
		if gate not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(gate)
		WorldSimulation.state.discovery_adoption[gate]=1.0
	for item:String in spec.cost:
		if item==C.BONE_RESOURCE:C.data().bone_stock=1000.0
		else:WorldSimulation.state.resource_stockpiles[item]=1000.0
	for item:String in spec.inputs:WorldSimulation.state.resource_stockpiles[item]=1000.0
	assert_bool(C.install(id).get("ok",false)).is_true()
func report()->Dictionary:return {"workers":0.0,"inputs":{},"methods":{},"discarded":0.0}
func test_sixteen_methods_have_real_inputs_and_graph_contracts()->void:
	WorldSimulation.scoped("clothes",func()->void:
		assert_int(K.entries().size()).is_equal(16)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		var outputs:Array=WorldSimulation.resources.catalog.keys();outputs.append(C.BONE_RESOURCE)
		for product:Dictionary in preload("res://scripts/civilian_industry.gd").PRODUCTS.values():outputs.append(product.output)
		for spec:Dictionary in K.METHODS.values():
			for item:String in spec.inputs.keys()+spec.cost.keys():assert_bool(item in outputs).override_failure_message(item).is_true()
	)
func test_installation_requires_knowledge_materials_and_settlement()->void:
	WorldSimulation.scoped("clothes",func()->void:
		prepare();assert_bool(C.install("knitted_loop_fabrics").has("error")).is_true();equip("knitted_loop_fabrics")
		assert_float(float(WorldSimulation.state.resource_stockpiles.Timber)).is_equal(998.0)
		WorldSimulation.state.convoy_traveling=true;var stock:=WorldSimulation.state.resource_stockpiles.duplicate()
		assert_bool(C.install("knitted_loop_fabrics").has("error")).is_true();assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(stock)
	)
func test_knit_twill_pile_debit_yarn_and_share_finite_daily_work()->void:
	WorldSimulation.scoped("clothes",func()->void:
		prepare()
		for id:String in ["knitted_loop_fabrics","twill_weave_structures","pile_fabric_weaving"]:equip(id)
		var yarn:=float(WorldSimulation.state.resource_stockpiles["Spun Yarn"]);var result:=C.advance(10,100,false)
		assert_float(float(result.workers)).is_equal_approx(2.0,.000001)
		assert_float(C.count()).is_equal_approx(5.0,.000001)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Spun Yarn"])).is_equal_approx(yarn-5.6,.000001)
		var count:=C.count();assert_float(float(C.advance(10,100,false).workers)).is_equal(0.0);assert_float(C.count()).is_equal(count)
		WorldSimulation.state.elapsed_days=1;C.advance(100,100,false)
		assert_float(float(C.data().report.methods.pile_fabric_weaving)).is_equal(2.0)
	)
func test_missing_yarn_or_workers_produces_nothing()->void:
	WorldSimulation.scoped("clothes",func()->void:
		prepare();equip("knitted_loop_fabrics");C.advance(0,100,false);assert_float(C.count()).is_equal(0.0)
		WorldSimulation.state.elapsed_days=1;WorldSimulation.state.resource_stockpiles["Spun Yarn"]=0.0;C.advance(100,100,false);assert_float(C.count()).is_equal(0.0)
	)
func test_layering_consumes_two_spare_garments_and_improves_actual_coverage()->void:
	WorldSimulation.scoped("clothes",func()->void:
		prepare();equip("layered_clothing_design");C.add("knit",110);var result:=report()
		C.operate("layered_clothing_design",10,100,1,result)
		assert_float(C.count()).is_equal(102.0);assert_float(float(result.workers)).is_equal(1.0)
		assert_float(float(C.coverage(100,1).cold)).is_greater(.32)
		var amount:=C.count();C.operate("layered_clothing_design",10,100,1,result);assert_float(C.count()).is_equal(amount)
	)
func test_washing_requires_water_and_withholds_wet_clothing_until_next_day()->void:
	WorldSimulation.scoped("clothes",func()->void:
		prepare();equip("textile_laundering_practice");C.add("knit",12,1,.8);var result:=report()
		WorldSimulation.state.resource_stockpiles.Freshwater=0.0;C.operate("textile_laundering_practice",10,12,1,result)
		assert_float(float(result.workers)).is_equal(0.0)
		WorldSimulation.state.resource_stockpiles.Freshwater=20.0;C.operate("textile_laundering_practice",10,12,1,result)
		assert_float(C.count()).is_equal(12.0);assert_float(float(C.coverage(12,1).issued)).is_equal(0.0)
		assert_float(float(C.coverage(12,2).issued)).is_equal(12.0);assert_float(float(WorldSimulation.state.resource_stockpiles.Freshwater)).is_equal_approx(10.4,.000001)
	)
func test_moisture_lining_pays_materials_and_only_changes_treated_units()->void:
	WorldSimulation.scoped("clothes",func()->void:
		prepare();equip("textile_moisture_transport");C.add("twill",12);var result:=report()
		var cloth:=float(WorldSimulation.state.resource_stockpiles["Woven Cloth"]);C.operate("textile_moisture_transport",10,12,1,result)
		assert_float(C.count()).is_equal(12.0);assert_float(float(C.coverage(12,1).storm)).is_equal_approx(.2,.000001)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Woven Cloth"])).is_equal_approx(cloth-.48,.000001)
	)
func test_wear_is_finite_and_existing_garments_do_not_grant_manufacture()->void:
	WorldSimulation.scoped("clothes",func()->void:
		prepare();C.add("pile",100,.151);C.advance(0,100,true)
		assert_float(C.count()).is_equal(0.0);assert_float(float(C.coverage(100,1).cold)).is_equal(0.0)
		assert_bool("pile_fabric_weaving" in WorldSimulation.state.known_discoveries).is_false()
	)
func test_coverage_never_exceeds_population_or_protects_empty_stock()->void:
	WorldSimulation.scoped("clothes",func()->void:
		assert_float(float(C.coverage(100,1).cold)).is_equal(0.0);C.add("pile",10000,1,0,true,true)
		var result:=C.coverage(100,1);assert_float(float(result.issued)).is_equal(100.0);assert_float(float(result.cold)).is_less_equal(.8)
	)
func test_malformed_and_secondary_city_states_are_rejected()->void:
	var state:=C.empty_state();state.lots=[{"kind":"knit","amount":INF}];assert_bool(C.valid(state)).is_false()
	assert_bool(C.valid_settlements([{"local_resources":{"household_clothing":state}}])).is_false()
	assert_bool(C.valid_settlements([{"local_resources":{}}])).is_true()
func test_owned_save_roundtrip_preserves_next_day_and_isolation()->void:
	WorldSimulation.create_actor("other",443)
	WorldSimulation.scoped("clothes",func()->void:prepare();equip("knitted_loop_fabrics");equip("textile_durability_testing");C.add("fit",150,.8);C.advance(100,100,false))
	var saved:=WorldSimulation.export_state().duplicate(true)
	WorldSimulation.scoped("clothes",func()->void:WorldSimulation.state.elapsed_days=1;C.advance(100,100,false))
	var expected:Dictionary=WorldSimulation.actors.clothes.systems.GameState.household_clothing.duplicate(true)
	assert_bool(WorldSimulation.import_state(bytes_to_var(var_to_bytes(saved))).get("ok",false)).is_true()
	WorldSimulation.scoped("clothes",func()->void:WorldSimulation.state.elapsed_days=1;C.advance(100,100,false))
	assert_dict(WorldSimulation.actors.clothes.systems.GameState.household_clothing).is_equal(expected)
	WorldSimulation.scoped("other",func()->void:assert_float(C.count()).is_equal(0.0))
func test_inspector_displays_service_and_paid_install()->void:
	WorldSimulation.scoped("clothes",func()->void:
		prepare();equip("knitted_loop_fabrics")
		var panel:VBoxContainer=auto_free(preload("res://scripts/hud/clothing_panel.gd").new());panel.subject="knitted_loop_fabrics";add_child(panel)
		panel.install_button.pressed.emit();assert_int(C.data().tools.knitted_loop_fabrics).is_equal(2)
		assert_bool(panel.details.text.contains("garments")).is_true()
	)
func test_full_save_file_restores_clothes_and_accepts_missing_legacy_field()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(442);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize();CivilizationSystem.reset_for_new_world()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	prepare();equip("knitted_loop_fabrics");C.add("knit",12,.8,.2,false,false,3);C.add("fit",5,.5);C.data().bone_stock=.25;equip("textile_durability_testing");C.operate("textile_durability_testing",1,0,0,report())
	var expected:=C.data().duplicate(true);var slot:="clothing_%d"%OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true();GameState.household_clothing=C.empty_state()
	assert_bool(SaveSystem.load_game(slot).get("ok",false)).is_true();assert_dict(C.data()).is_equal(expected)
	var payload:=SaveSystem._read_payload(slot);payload.reflected_GameState.erase("household_clothing")
	assert_bool(SaveSystem._write_payload(SaveSystem.slot_path(slot),payload).get("ok",false)).is_true()
	var restored:=SaveSystem.load_game(slot);DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(restored.get("ok",false)).is_true();assert_dict(C.data()).is_equal(C.empty_state())
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func test_secondary_city_clothes_are_local_and_save_separately()->void:
	WorldSimulation.scoped("clothes",func()->void:
		prepare();C.add("sew",20);C.data().bone_stock=.5
		WorldSimulation.state.player_settlements.append({"id":"second","name":"Second","position":Vector2(10,0),"population_share":.25,"founded_day":0})
		WorldSimulation.settlements.with_city_resources("second",func()->void:
			assert_float(C.count()).is_equal(0.0);C.add("fit",3);C.data().bone_stock=.1
			WorldSimulation.food.process_day({"traveling":false},1,1)
			assert_float(float(C.coverage(100,0).issued)).is_equal(3.0)
		)
		assert_float(C.count()).is_equal(20.0);assert_float(C.available(C.BONE_RESOURCE)).is_equal(.5)
	)
	var saved:=WorldSimulation.export_state();assert_bool(WorldSimulation.import_state(saved).get("ok",false)).is_true()
	WorldSimulation.scoped("clothes",func()->void:
		assert_float(C.count()).is_equal(20.0);assert_float(C.available(C.BONE_RESOURCE)).is_equal(.5)
		WorldSimulation.settlements.with_city_resources("second",func()->void:assert_float(C.count()).is_equal(3.0);assert_float(C.available(C.BONE_RESOURCE)).is_equal(.1))
	)
func test_actual_daily_health_consumes_only_supplied_cold_coverage()->void:
	WorldSimulation.scoped("clothes",func()->void:
		prepare();var state=WorldSimulation.state
		var environment:=PlanetEnvironment.profile_at(Vector2.ZERO);environment.hazards={"cold":1.0,"heat":0.0,"disease":0.0,"storm":1.0}
		state.player_settlements.append({"id":"home","name":"Home","primary":true,"position":Vector2.ZERO,"population_share":1.0,"founded_day":0,"environment_profile":environment})
		state.housing_capacity=0;C.add("pile",state.population_exact)
		WorldSimulation.consequences.process_day({"traveling":false})
		var covered:=float(state.simulation_metrics.clothing_coverage.cold)
		assert_float(covered).is_greater(0.0)
		assert_float(float(state.simulation_metrics.environmental_health_cost)).is_equal_approx(.024*.77*(1-covered),.000001)
		assert_float(float(state.simulation_metrics.environmental_health_cost)).is_less(.024*.77)
		var storm:=float(state.simulation_metrics.clothing_coverage.storm)
		assert_float(float(state.simulation_metrics.mortality_components.Exposure)).is_equal_approx(.53*.040+(.018*(1-covered)+.006*(1-storm))*.77,.000001)
		assert_bool(C.valid(C.data())).is_true()
	)
func learn(id:String)->void:
	var spec:Dictionary=K.METHODS[id];var gates:Array=spec.requires_all.duplicate();gates.append(id)
	for group:Array in spec.requires_any:gates.append(group[0])
	for gate:String in gates:
		if gate not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(gate)
		WorldSimulation.state.discovery_adoption[gate]=1.0
func test_bone_recovery_is_bounded_once_per_day_and_pays_for_sewing_needles()->void:
	WorldSimulation.scoped("clothes",func()->void:
		prepare();learn("bone_needle_sewing")
		WorldSimulation.state.resource_stockpiles={"Stone":10.0,"Timber":10.0,"Woven Cloth":2.0,"Spun Yarn":1.0}
		assert_bool(C.install("bone_needle_sewing").has("error")).is_true()
		C.advance(0,100,false,50);assert_float(C.available(C.BONE_RESOURCE)).is_equal_approx(.1,.000001)
		C.advance(0,100,false,5000);assert_float(C.available(C.BONE_RESOURCE)).is_equal_approx(.1,.000001)
		assert_bool(C.install("bone_needle_sewing").get("ok",false)).is_true()
		assert_float(C.available(C.BONE_RESOURCE)).is_equal_approx(0,.000001)
		var result:=report();C.operate("bone_needle_sewing",10,100,0,result)
		assert_float(C.count()).is_equal(2.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Woven Cloth"])).is_equal_approx(.6,.000001)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Spun Yarn"])).is_equal_approx(.8,.000001)
		WorldSimulation.state.elapsed_days=1;C.advance(0,100,false,100000)
		assert_float(C.available(C.BONE_RESOURCE)).is_equal(5.0)
	)
func test_patterns_save_cloth_and_grading_speeds_fitted_work_with_real_inputs()->void:
	WorldSimulation.scoped("clothes",func()->void:
		prepare()
		for id:String in ["bone_needle_sewing","garment_pattern_cutting","garment_size_grading"]:
			WorldSimulation.state.household_clothing=C.empty_state();equip(id)
			var cloth:=float(WorldSimulation.state.resource_stockpiles["Woven Cloth"]);var result:=report()
			C.operate(id,10,100,0,result)
			assert_float(C.count()).is_equal(float(K.METHODS[id].rate))
			var cloth_per_garment:=(cloth-float(WorldSimulation.state.resource_stockpiles["Woven Cloth"]))/C.count()
			assert_float(cloth_per_garment).is_equal_approx(.7 if id=="bone_needle_sewing" else .55,.000001)
			assert_float(float(result.workers)).is_equal(1.0)
			if id=="garment_size_grading":assert_float(float(result.inputs.Paper)).is_equal_approx(.025,.000001)
	)
func test_repairs_charge_only_for_treated_condition_and_never_create_garments()->void:
	WorldSimulation.scoped("clothes",func()->void:
		prepare();equip("textile_repair_methods");C.add("sew",20,.4)
		var cloth:=float(WorldSimulation.state.resource_stockpiles["Woven Cloth"]);var yarn:=float(WorldSimulation.state.resource_stockpiles["Spun Yarn"])
		var result:=report();C.operate("textile_repair_methods",100,100,0,result)
		assert_float(C.count()).is_equal(20.0);assert_float(float(C.data().lots[0].condition)).is_equal_approx(.52,.000001)
		assert_float(float(result.workers)).is_equal(1.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Woven Cloth"])).is_equal_approx(cloth-.64,.000001)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Spun Yarn"])).is_equal_approx(yarn-.24,.000001)
		C.operate("textile_repair_methods",100,100,0,result)
		assert_float(float(C.data().lots[0].condition)).is_equal_approx(.52,.000001)
		WorldSimulation.state.resource_stockpiles["Spun Yarn"]=0.0;C.operate("textile_repair_methods",100,100,1,report())
		assert_float(float(C.data().lots[0].condition)).is_equal_approx(.52,.000001)
	)
func test_partial_repairs_respect_condition_ceiling_and_do_not_rebuild_ruined_stock()->void:
	WorldSimulation.scoped("clothes",func()->void:
		prepare();equip("textile_repair_methods");C.add("fit",20,.59);C.operate("textile_repair_methods",100,100,0,report())
		assert_float(float(C.data().lots[0].condition)).is_equal_approx(.59+.26*8.0/20.0,.000001)
		C.data().lots[0].condition=.14;var result:=report();C.operate("textile_repair_methods",100,100,1,result)
		assert_float(float(result.workers)).is_equal(0.0);assert_float(float(C.data().lots[0].condition)).is_equal(.14)
	)
func test_actual_food_day_recovers_only_new_hunting_not_meat_stores_or_forecasts()->void:
	WorldSimulation.scoped("clothes",func()->void:
		prepare();learn("bone_needle_sewing");WorldSimulation.food.initialize()
		var state=WorldSimulation.state
		state.food_stocks["Fresh meat"]=10000.0;state.population_allocations.Food=0;state.population_allocations.Logistics=0
		state.resource_stockpiles.Timber=0.0;state.resource_stockpiles.Stone=0.0
		WorldSimulation.food.process_day({"traveling":false},1,1)
		assert_float(C.available(C.BONE_RESOURCE)).is_equal(0.0)
		state.elapsed_days=1;state.population_allocations.Food=20
		var result:=WorldSimulation.food.process_day({"traveling":false},1,1)
		assert_float(float(result.food_harvest["Fresh meat"])).is_greater(0.0)
		assert_float(C.available(C.BONE_RESOURCE)).is_equal_approx(minf(state.population_exact*.05,float(result.food_harvest["Fresh meat"])*.002),.000001)
		var before:=C.available(C.BONE_RESOURCE)
		WorldSimulation.food._forecast(90,result.food_harvest,result.food_demand_breakdown,false)
		assert_float(C.available(C.BONE_RESOURCE)).is_equal(before)
	)
func test_bone_stock_is_optional_in_old_records_but_malformed_stock_is_rejected()->void:
	var old:=C.empty_state();old.erase("bone_stock");assert_bool(C.valid(old)).is_true()
	old.bone_stock=INF;assert_bool(C.valid(old)).is_false()
	old.bone_stock=-1;assert_bool(C.valid(old)).is_false()

func test_powered_washing_pays_actual_power_soap_water_and_shared_capacity()->void:
	WorldSimulation.scoped("clothes",func()->void:
		prepare();equip("mechanical_washing_machines");C.add("sew",40,1,.8)
		var state=WorldSimulation.state;state.technology_operations.last_day=int(state.elapsed_days);state.technology_operations.services.electricity=2.0
		state.resource_stockpiles["Laundry Soap"]=1.0;state.resource_stockpiles.Freshwater=100.0
		var r:=report();C.operate("mechanical_washing_machines",10,40,0,r)
		assert_float(float(r.methods.mechanical_washing_machines)).is_equal(24.0)
		assert_float(float(r.workers)).is_equal(1.0)
		assert_float(float(r.inputs.Electricity)).is_equal_approx(1.2,.000001)
		assert_float(float(state.resource_stockpiles["Laundry Soap"])).is_equal_approx(.52,.000001)
		assert_float(float(state.resource_stockpiles.Freshwater)).is_equal_approx(92.8,.000001)
		assert_float(float(C.coverage(40,0).issued)).is_equal(16.0)
		assert_float(float(C.coverage(40,1).issued)).is_equal(40.0)
		assert_float(C.count()).is_equal(40.0)
		for lot:Dictionary in C.data().lots:
			if int(lot.ready)==1:assert_float(float(lot.condition)).is_equal(.998)
		var stocks:Dictionary=state.resource_stockpiles.duplicate(true)
		C.operate("mechanical_washing_machines",10,40,0,r)
		assert_dict(state.resource_stockpiles).is_equal(stocks)
	)
func test_unpowered_or_unsupplied_machine_does_not_consume_garments_or_materials()->void:
	WorldSimulation.scoped("clothes",func()->void:
		prepare();equip("mechanical_washing_machines");C.add("fit",5,.8,.8)
		var state=WorldSimulation.state;state.technology_operations.last_day=int(state.elapsed_days)
		for missing:String in ["electricity","Laundry Soap","Freshwater"]:
			state.technology_operations.services.electricity=2.0;state.resource_stockpiles["Laundry Soap"]=2.0;state.resource_stockpiles.Freshwater=2.0
			if missing=="electricity":state.technology_operations.services.electricity=0.0
			else:state.resource_stockpiles[missing]=0.0
			var lots:Array=C.data().lots.duplicate(true);var stocks:Dictionary=state.resource_stockpiles.duplicate(true)
			var r:=report();C.operate("mechanical_washing_machines",1,5,0,r)
			assert_float(float(r.workers)).is_equal(0.0);assert_array(C.data().lots).is_equal(lots);assert_dict(state.resource_stockpiles).is_equal(stocks)
	)
func test_power_demand_requires_dirty_local_supplied_stock()->void:
	WorldSimulation.scoped("clothes",func()->void:
		prepare();equip("mechanical_washing_machines");WorldSimulation.state.population_allocations.Logistics=100.0
		C.add("sew",10,1,.8)
		assert_float(C.power_demand()).is_equal(.5)
		C.data().lots[0].soil=.33;assert_float(C.power_demand()).is_equal(.5)
		WorldSimulation.state.resource_stockpiles["Laundry Soap"]=0.0
		assert_float(C.power_demand()).is_equal(0.0)
		WorldSimulation.state.resource_stockpiles["Laundry Soap"]=10.0;WorldSimulation.state.resource_settlement_id="secondary"
		assert_float(C.power_demand()).is_equal(0.0)
		assert_bool(C.quote("mechanical_washing_machines").has("error")).is_true()
	)
func test_durability_trials_remove_samples_and_require_five_paid_days()->void:
	WorldSimulation.scoped("clothes",func()->void:
		prepare();equip("textile_durability_testing");C.add("sew",2,.8)
		var state=WorldSimulation.state;state.resource_stockpiles.Freshwater=1.0;state.resource_stockpiles.Paper=1.0
		var r:=report();C.operate("textile_durability_testing",1,1,0,r)
		assert_float(C.count()).is_equal(1.75);assert_int(int(C.data().trials.sew.cycles)).is_equal(1)
		assert_float(float(r.workers)).is_equal(.5)
		C.operate("textile_durability_testing",1,1,0,r)
		assert_int(int(C.data().trials.sew.cycles)).is_equal(1)
		state.resource_stockpiles.Paper=0.0;C.operate("textile_durability_testing",1,1,1,report())
		assert_int(int(C.data().trials.sew.cycles)).is_equal(1)
		state.resource_stockpiles.Paper=.08
		state.household_clothing=JSON.parse_string(JSON.stringify(C.data()))
		assert_bool(C.valid(C.data())).is_true()
		for day:int in range(2,6):C.operate("textile_durability_testing",1,1,day,report())
		assert_int(int(C.data().trials.sew.cycles)).is_equal(5)
		assert_float(float(C.data().trials.sew.condition)).is_equal_approx(.7,.000001)
		assert_float(float(C.data().lots[0].condition)).is_equal(.8)
		assert_float(C.count()).is_equal(1.75)
		assert_float(float(state.resource_stockpiles.Freshwater)).is_equal_approx(.5,.000001)
		C.operate("textile_durability_testing",100,1,6,report());assert_float(C.count()).is_equal(1.75)
		var invalid:Dictionary=C.data().duplicate(true);invalid.trials.sew.sample=100.0;assert_bool(C.valid(invalid)).is_false()
		invalid=C.data().duplicate(true);invalid.trials.sew.condition=INF;assert_bool(C.valid(invalid)).is_false()
	)
func test_wear_trials_never_take_the_last_needed_garment()->void:
	WorldSimulation.scoped("clothes",func()->void:
		prepare();equip("textile_durability_testing");C.add("knit",1)
		var stocks:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		C.operate("textile_durability_testing",20,1,0,report())
		assert_float(C.count()).is_equal(1.0);assert_dict(C.data().trials).is_empty();assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(stocks)
	)

func test_actual_generator_responds_to_laundry_demand_and_pays_fuel()->void:
	WorldSimulation.scoped("clothes",func()->void:
		prepare();equip("mechanical_washing_machines")
		var state=WorldSimulation.state;var ops=preload("res://scripts/technology_operations.gd")
		state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
		state.population_allocations.Crafting=100.0;state.population_allocations.Logistics=100.0
		var spec:Dictionary=ops.PLANTS.steam_generator
		for gate:String in [spec.gate]+spec.requires:
			if gate not in state.known_discoveries:state.known_discoveries.append(gate)
			state.discovery_adoption[gate]=1.0
		for item:String in spec.cost:state.resource_stockpiles[item]=100.0
		for item:String in spec.inputs:state.resource_stockpiles[item]=100.0
		C.add("sew",10,1,.8)
		assert_str(String(preload("res://scripts/power_investment_planner.gd").recommendation().get("plant",""))).is_equal("steam_generator")
		C.data().lots=[]
		assert_bool(ops.install("steam_generator").get("ok",false)).is_true()
		for day:int in range(1,12):state.elapsed_days=day;ops.advance(day)
		assert_float(float(state.resource_stockpiles.Coal)).is_equal(100.0)
		C.add("sew",10,1,.8);state.elapsed_days=12;ops.advance(12)
		assert_float(ops.service("electricity")).is_equal(.5)
		assert_float(float(state.resource_stockpiles.Coal)).is_less(100.0)
		C.operate("mechanical_washing_machines",1,10,12,report())
		assert_float(ops.service("electricity")).is_equal_approx(0,.000001)
		assert_float(float(C.coverage(10,12).issued)).is_equal(0.0)
	)
