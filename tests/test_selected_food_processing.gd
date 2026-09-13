extends GdUnitTestSuite
const S=preload("res://scripts/selected_food_processing.gd")
const B=preload("res://scripts/food_batches.gd")
const K=preload("res://scripts/food_batch_knowledge.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("selected",442)
func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func know(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func prepare()->void:
	var state=WorldSimulation.state;state.settlement_site_committed=true;state.convoy_traveling=false;state.elapsed_days=90
	state.food_stocks={"Fresh plants":0.0,"Fresh meat":0.0,"Fish":0.0,"Dry staples":10000.0,"Preserved food":0.0}
	state.founding_manifest.food_storage_rations=1000000.0
	state.population_allocations.Food=20;state.population_allocations.Logistics=20
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
	for id:String in S.RAW.values():
		know(id);var spec:Dictionary=K.METHODS[id]
		for gate:String in spec.requires_all:know(gate)
		for group:Array in spec.requires_any:know(group[0])
		for resource:String in spec.cost:state.resource_stockpiles[resource]=1000.0
		for resource:String in spec.inputs:state.resource_stockpiles[resource]=1000.0
		assert_bool(B.install(id).get("ok",false)).is_true()
func context()->Dictionary:
	return {"settlement_origin":Vector3.ZERO,"origin":Vector3.ZERO,"traveling":false,"environment_profile":{"land":true,"temperature":.6,"precipitation":.6,"woodland":.7,"forage":.8,"mean_temperature_c":20.0,"seasonality_c":0.0}}
func raw(kind:String,amount:float=10)->Dictionary:
	var lot:=B.add_lot(kind,amount,int(WorldSimulation.state.elapsed_days))
	lot.source_id="0:0:"+kind;lot.source_origin=[0.0,0.0];return lot
func report()->Dictionary:return {"workers":0.0,"loss":0.0,"inputs":{},"methods":{}}
func test_generated_sources_are_stable_local_and_reject_unsuitable_habitat()->void:
	var p:Dictionary=context().environment_profile
	var a:=S.opportunities(p,Vector2.ZERO,442)
	assert_array(a).is_not_empty();assert_array(S.opportunities(p,Vector2.ZERO,442)).is_equal(a)
	for source:Dictionary in a:assert_bool(S.RAW.has(source.kind)).is_true()
	p.land=false;assert_array(S.opportunities(p,Vector2.ZERO,442)).is_empty()
	p.land=true;p.temperature=0;p.precipitation=0;p.woodland=0
	assert_array(S.opportunities(p,Vector2.ZERO,442)).is_empty()
func test_collection_spends_food_work_has_local_capacity_and_is_idempotent()->void:
	WorldSimulation.scoped("selected",func()->void:
		prepare();var before:=WorldSimulation.state.food_stocks.duplicate(true)
		var collected:=S.harvest(context(),20,1,1,100)
		assert_float(float(collected.workers)).is_greater(0.0);assert_float(float(collected.workers)).is_less_equal(1.6)
		assert_float(float(collected.gathered)).is_greater(0.0)
		assert_dict(WorldSimulation.state.food_stocks).is_equal(before)
		var lots:Array=B.data().lots.duplicate(true)
		assert_float(float(S.harvest(context(),100000,1,1,100000).gathered)).is_equal(0.0)
		assert_array(B.data().lots).is_equal(lots)
		WorldSimulation.state.elapsed_days+=1
		assert_float(float(S.harvest(context(),100000,1,1,100000).gathered)).is_less_equal(200.0)
		assert_float(B.available_total()).is_equal(0.0))
func test_missing_recognition_workers_access_and_unknown_lots_produce_no_food()->void:
	WorldSimulation.scoped("selected",func()->void:
		prepare();WorldSimulation.state.known_discoveries.erase("edible_resource_recognition")
		assert_float(float(S.harvest(context(),20,1,1,100).gathered)).is_equal(0.0)
		know("edible_resource_recognition");WorldSimulation.state.elapsed_days+=1
		assert_float(float(S.harvest(context(),0,1,1,100).gathered)).is_equal(0.0)
		WorldSimulation.state.elapsed_days+=1
		assert_float(float(S.harvest(context(),20,1,1,100,0).gathered)).is_equal(0.0)
		var bad:=B.empty_state();bad.lots=[raw("unknown_plant")];bad.next_id=2
		assert_bool(B.valid(bad)).is_false()
		B.data().lots.clear();WorldSimulation.state.food_stocks["Fresh plants"]=100.0
		S.process(10,10,report(),90)
		assert_float(float(WorldSimulation.state.food_stocks["Fresh plants"])).is_equal(100.0))
func test_shelling_and_screening_release_less_food_than_identified_inputs()->void:
	WorldSimulation.scoped("selected",func()->void:
		prepare();raw("selected_nuts");raw("selected_fruit")
		var r:=report();var before:=float(WorldSimulation.state.food_stocks["Dry staples"])
		var used:=S.process(10,10,r,90)
		assert_float(used).is_less_equal(10.0)
		assert_float(float(WorldSimulation.state.food_stocks["Dry staples"])-before).is_equal_approx(5.76,.000001)
		assert_float(float(WorldSimulation.state.food_stocks["Fresh plants"])).is_equal(7.5)
		assert_float(float(r.loss)).is_equal_approx(4.74,.000001)
		assert_float(float(r.inputs.Freshwater)).is_equal(1.0))
func test_roots_pulses_and_acorns_wait_for_qualified_cooking_and_supplies()->void:
	WorldSimulation.scoped("selected",func()->void:
		prepare();raw("selected_roots");raw("selected_pulses");raw("selected_acorns",5)
		var r:=report();S.process(20,10,r,90)
		assert_float(B.available_total()).is_equal(0.0)
		assert_float(float(WorldSimulation.state.food_stocks["Fresh plants"])).is_equal(0.0)
		know("hearth_roasting_control");know("clay_shaping")
		WorldSimulation.state.resource_stockpiles.Timber=100.0;WorldSimulation.state.resource_stockpiles.Stone=100.0;WorldSimulation.state.resource_stockpiles.Clay=100.0
		S.process(20,10,report(),90)
		assert_float(float(WorldSimulation.state.food_stocks["Fresh plants"])).is_equal(0.0)
		WorldSimulation.state.resource_stockpiles.Freshwater=0
		S.process(20,10,report(),92)
		assert_float(float(WorldSimulation.state.food_stocks["Fresh plants"])).is_equal(0.0)
		WorldSimulation.state.resource_stockpiles.Freshwater=100
		var cooked:=report();S.process(20,10,cooked,92)
		assert_float(float(WorldSimulation.state.food_stocks["Fresh plants"])).is_equal_approx((8+8.2+3.25)*.95,.000001)
		assert_float(float(cooked.inputs.Timber)).is_greater(0.0)
		assert_float(B.in_process()).is_equal(0.0))
func test_zero_and_partial_logistics_and_water_limit_each_step()->void:
	WorldSimulation.scoped("selected",func()->void:
		prepare();raw("selected_acorns")
		assert_float(S.process(0,10,report(),90)).is_equal(0.0)
		WorldSimulation.state.resource_stockpiles.Freshwater=.75
		var r:=report();S.process(10,10,r,90)
		assert_float(float(r.methods.acorn_leaching)).is_equal(.5)
		assert_float(float(r.workers)).is_equal(.1)
		assert_float(float(WorldSimulation.state.resource_stockpiles.Freshwater)).is_equal(0.0)
		assert_float(B.in_process()).is_equal_approx(9.5+.325,.000001))
func test_daily_food_batch_budget_does_not_refill_processing_or_inputs()->void:
	WorldSimulation.scoped("selected",func()->void:
		prepare();raw("selected_acorns",20)
		B.advance(10,10,false)
		var lots:Array=B.data().lots.duplicate(true);var stocks:=WorldSimulation.state.resource_stockpiles.duplicate(true)
		assert_float(float(B.advance(100,10,false).workers)).is_equal(0.0)
		assert_array(B.data().lots).is_equal(lots);assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(stocks))
func test_secondary_city_lots_inputs_and_collection_stamp_remain_local()->void:
	WorldSimulation.scoped("selected",func()->void:
		prepare();raw("selected_nuts",4)
		var home:=B.data().duplicate(true);var supplies:=WorldSimulation.state.resource_stockpiles.duplicate(true)
		WorldSimulation.state.player_settlements.append({"id":"food-city","primary":false,"position":Vector2(3,4),"name":"Food City"})
		WorldSimulation.settlements.with_city_resources("food-city",func()->void:
			prepare();raw("selected_acorns",5)
			var r:=B.advance(20,10,false)
			assert_float(float(r.methods.get("acorn_leaching",0))).is_equal(5.0)
			assert_float(B.in_process()).is_equal(3.25))
		assert_dict(B.data()).is_equal(home)
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(supplies)
		WorldSimulation.settlements.with_city_resources("food-city",func()->void:
			assert_str(String(B.data().lots[0].kind)).is_equal("leached_acorn_meal")))
func test_owned_actor_does_not_share_ingredient_lots_or_knowledge()->void:
	WorldSimulation.create_actor("other-food",443)
	WorldSimulation.scoped("selected",func()->void:prepare();raw("selected_roots",5))
	WorldSimulation.scoped("other-food",func()->void:
		assert_float(B.in_process()).is_equal(0.0)
		assert_bool("root_grating_dewatering" in WorldSimulation.state.known_discoveries).is_false())
	WorldSimulation.scoped("selected",func()->void:assert_float(B.in_process()).is_equal(5.0))
func test_binary_save_preserves_unfinished_acorn_lot_and_paid_work()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.scoped("selected",func()->void:
		prepare();raw("selected_acorns",5);B.advance(20,10,false)
		know("hearth_roasting_control");know("clay_shaping")
		WorldSimulation.state.resource_stockpiles.Timber=100;WorldSimulation.state.resource_stockpiles.Stone=100;WorldSimulation.state.resource_stockpiles.Clay=100)
	var slot:="selected_food_%d"%OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();var loaded:=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(loaded.get("ok",false)).override_failure_message(str(loaded)).is_true()
	if not loaded.get("ok",false):return
	WorldSimulation.scoped("selected",func()->void:
		assert_float(B.in_process()).is_equal(3.25)
		assert_str(String(B.data().lots[0].source_id)).is_equal("0:0:selected_acorns")
		assert_float(float(B.advance(100,10,false).workers)).is_equal(0.0)
		WorldSimulation.state.elapsed_days=92;B.advance(20,10,false)
		assert_float(B.in_process()).is_equal(0.0)
		assert_float(float(WorldSimulation.state.food_stocks["Fresh plants"])).is_equal_approx(3.25*.95,.000001))
func test_selected_lot_validation_rejects_missing_and_nonfinite_provenance()->void:
	WorldSimulation.scoped("selected",func()->void:
		prepare();var lot:=raw("selected_fruit")
		assert_bool(B.valid(B.data())).is_true()
		lot.source_origin[0]=INF;assert_bool(B.valid(B.data())).is_false()
		lot.source_origin[0]=0;lot.erase("source_id");assert_bool(B.valid(B.data())).is_false())
func test_actual_food_day_removes_collectors_from_legacy_harvest()->void:
	WorldSimulation.scoped("selected",func()->void:
		prepare();var state=WorldSimulation.state
		var workers:=float(state.effective_workers("Food"))
		var baseline:Dictionary=WorldSimulation.food._produce(workers,1,1,false)
		var daily:Dictionary=WorldSimulation.food.process_day(context(),1,1)
		var paid:=float(daily.selected_food_harvest.workers)
		assert_float(paid).is_greater(0.0)
		assert_float(paid).is_less_equal(workers*.08)
		var expected:=float(baseline["Fresh plants"])*(1.0-paid/workers)
		assert_float(float(daily.food_harvest["Fresh plants"])).is_equal_approx(expected,.000001)
		assert_float(float(daily.food_batches.workers)+float(daily.grain_processing.workers)+float(daily.food_preparation.workers_reserved)).is_less_equal(float(state.effective_workers("Logistics"))))
func test_automatic_equipment_requires_work_demand_and_pays_actual_tools()->void:
	WorldSimulation.scoped("selected",func()->void:
		prepare();B.data().tools.erase("nut_kernel_shelling")
		var before:=float(WorldSimulation.state.resource_stockpiles.Stone)
		S.process(10,10,report(),90)
		assert_bool(B.data().tools.has("nut_kernel_shelling")).is_false()
		raw("selected_nuts",1)
		S.process(0,10,report(),90)
		assert_bool(B.data().tools.has("nut_kernel_shelling")).is_false()
		S.process(10,10,report(),90)
		assert_int(int(B.data().tools.nut_kernel_shelling)).is_equal(1)
		assert_float(before-float(WorldSimulation.state.resource_stockpiles.Stone)).is_equal_approx(2.001,.000001))
func test_invalid_source_lot_is_rejected_before_work_or_material_debits()->void:
	WorldSimulation.scoped("selected",func()->void:
		prepare();var lot:=raw("selected_acorns");lot.source_id="unknown"
		var before:=WorldSimulation.state.resource_stockpiles.duplicate(true);var r:=report()
		assert_float(S.process(10,10,r,90)).is_equal(0.0)
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
		assert_float(float(lot.amount)).is_equal(10.0)
		assert_float(float(WorldSimulation.state.food_stocks["Fresh plants"])).is_equal(0.0))
