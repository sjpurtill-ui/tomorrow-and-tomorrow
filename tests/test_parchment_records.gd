extends GdUnitTestSuite
const K=preload("res://scripts/parchment_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const S=preload("res://scripts/paper_study.gd")
const E=preload("res://scripts/society_exchange.gd")
const F=preload("res://scripts/civilian_production_planner.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("parchment_owner",996)
func after_test()->void:WorldSimulation.clear()
func note(kind:String="knowledge")->Dictionary:
	return {"id":"local_note","kind":kind,"name":"Local comparison","source_id":"","source_name":"Local","position":{"x":0.0,"z":0.0},"observed_day":0,"returned_day":0,"discovery_id":"clay_shaping","study":0.0,"work":100.0,"signals":[]}
func know(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func provision(item:String)->Dictionary:
	var spec:=I.product(item);know(String(spec.gate))
	for r:String in spec.materials:WorldSimulation.state.resource_stockpiles[r]=100.0
	for r:String in spec.tooling:WorldSimulation.state.resource_stockpiles[r]=100.0
	assert_bool(WorldSimulation.military.start_production_line(item,1).get("ok",false)).is_true()
	return WorldSimulation.military.equipment_queue.back()
func test_parchment_preserves_its_untanned_skin_foundations()->void:
	WorldSimulation.scoped("parchment_owner",func()->void:
		assert_int(K.entries().size()).is_equal(1)
		assert_array(K.entries()[0].requires_all).is_equal(["hafted_tools","curing_regimens"])
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty())
func test_real_hunting_collects_once_for_parchment_without_tanning_or_fat_recovery()->void:
	WorldSimulation.scoped("parchment_owner",func()->void:
		know("parchment_record_preparation")
		var state=WorldSimulation.state;state.ensure_population_total(100);state.settlement_site_committed=true;state.convoy_traveling=false
		state.population_allocations.Food=20;state.population_allocations.Logistics=0
		WorldSimulation.food.initialize()
		var result:=WorldSimulation.food.process_day({"traveling":false},1,1)
		assert_float(float(result.food_harvest["Fresh meat"])).is_greater(0)
		var hides:=float(state.resource_stockpiles.get("Raw Hides",0))
		assert_float(hides).is_equal_approx(minf(2,float(result.food_harvest["Fresh meat"])*.001),.000001)
		assert_float(float(state.resource_stockpiles.get("Recovered Animal Fat",0))).is_equal(0.0)
		know("hide_tanning");preload("res://scripts/household_clothing.gd").advance(0,100,false,10000)
		assert_float(float(state.resource_stockpiles["Raw Hides"])).is_equal(hides))
func test_all_three_routes_spend_real_inputs_and_require_finished_work()->void:
	WorldSimulation.scoped("parchment_owner",func()->void:
		for item:String in ["parchment_prepared_skins","parchment_sheets","parchment_record_books"]:
			var spec:=I.product(item);var job:=provision(item)
			WorldSimulation.state.resource_stockpiles[spec.output]=0.0
			var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
			P.advance(WorldSimulation.military,job,float(spec.days)*.5)
			assert_int(int(job.completed)).is_equal(0)
			var restored:Dictionary=bytes_to_var(var_to_bytes(job));assert_str(P.validate_saved({"equipment_queue":[restored]})).is_empty()
			P.advance(WorldSimulation.military,restored,float(spec.days)*.5)
			assert_float(float(WorldSimulation.state.resource_stockpiles[spec.output])).is_equal(1.0)
			for r:String in spec.materials:assert_float(float(before[r])-float(WorldSimulation.state.resource_stockpiles[r])).is_equal_approx(float(spec.materials[r]),.000001)
			WorldSimulation.military.cancel_equipment_job(int(job.id)))
func test_tanned_or_raw_hides_cannot_replace_prepared_parchment_skins()->void:
	WorldSimulation.scoped("parchment_owner",func()->void:
		var job:=provision("parchment_sheets")
		WorldSimulation.state.resource_stockpiles["Parchment Prepared Skins"]=0.0
		WorldSimulation.state.resource_stockpiles["Raw Hides"]=100.0;WorldSimulation.state.resource_stockpiles["Flexible Leather"]=100.0;WorldSimulation.state.resource_stockpiles["Tanned Leather"]=100.0
		var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		P.advance(WorldSimulation.military,job,100)
		assert_int(int(job.completed)).is_equal(0);assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before))
func test_imported_parchment_spends_only_actual_study_work_without_teaching_manufacture()->void:
	WorldSimulation.scoped("parchment_owner",func()->void:
		WorldSimulation.state.resource_stockpiles["Parchment Sheets"]=1.0
		var result:=S.use(10,100,note())
		assert_float(float(result.work)).is_equal(10.0);assert_float(float(result.progress)).is_equal(12.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Parchment Sheets"])).is_equal_approx(.94,.000001)
		assert_bool("parchment_record_preparation" in WorldSimulation.state.known_discoveries).is_false()
		result=S.use(100,.12,note());assert_float(float(result.work)).is_equal_approx(.1,.000001)
		assert_float(float(result.progress)).is_equal_approx(.12,.000001)
		var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true);S.use(0,100,note());S.use(100,0,note());assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before))
func test_actual_arrived_collection_study_pays_parchment_once_and_preserves_missing_evidence()->void:
	WorldSimulation.scoped("parchment_owner",func()->void:
		var state=WorldSimulation.state;state.ensure_population_total(100);state.population_allocations.Knowledge=20;state.simulation_metrics.food_intake_ratio=1.0
		state.resource_stockpiles["Parchment Sheets"]=1.0
		E.data().collections.local_note=note();var later:=note();later.id="later";later.returned_day=100;E.data().collections.later=later
		var work:=state.effective_workers("Knowledge")*.15;E.advance(1)
		assert_float(float(E.data().collections.local_note.study)).is_equal_approx(work*1.2/100,.000001)
		assert_float(float(E.data().collections.later.study)).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Parchment Sheets"])).is_equal_approx(1-work*.006,.000001)
		var before:Dictionary=state.resource_stockpiles.duplicate(true);E.advance(1);assert_dict(state.resource_stockpiles).is_equal(before))
func test_actual_planner_finishes_imported_skins_without_paper_or_tanning()->void:
	WorldSimulation.scoped("parchment_owner",func()->void:
		var state=WorldSimulation.state;state.population_allocations.Knowledge=20;state.population_allocations.Crafting=40
		know("parchment_record_preparation")
		for r:String in I.PRODUCTS.parchment_sheets.materials:state.resource_stockpiles[r]=100.0
		for r:String in I.PRODUCTS.parchment_sheets.tooling:state.resource_stockpiles[r]=100.0
		E.data().collections.local_note=note()
		var order:=F.study_recommendation();assert_str(String(order.get("item",""))).is_equal("parchment_sheets")
		preload("res://scripts/civilization_controller.gd").production_order("parchment_owner",order)
		assert_array(WorldSimulation.military.equipment_queue).is_not_empty()
		if WorldSimulation.military.equipment_queue.is_empty():return
		P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue.back(),5)
		assert_float(float(state.resource_stockpiles["Parchment Sheets"])).is_equal(1.0)
		assert_dict(F.study_recommendation()).is_empty()
		assert_bool("hide_tanning" in state.known_discoveries).is_false())
func test_full_actor_save_continues_paid_parchment_and_prior_study_once()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.scoped("parchment_owner",func()->void:
		var job:=provision("parchment_sheets");job.target_stock=3;P.advance(WorldSimulation.military,job,2.5)
		var state=WorldSimulation.state;state.ensure_population_total(100);state.population_allocations.Knowledge=20;state.simulation_metrics.food_intake_ratio=1.0
		state.resource_stockpiles["Parchment Sheets"]=1.0;E.data().collections.local_note=note();E.advance(1))
	var slot:="parchment_%d"%OS.get_process_id();var okay:=SaveSystem.save_game(slot)
	assert_bool(okay.get("ok",false)).override_failure_message(str(okay)).is_true()
	WorldSimulation.clear();var loaded:=SaveSystem.load_game(slot);DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(loaded.get("ok",false)).override_failure_message(str(loaded)).is_true()
	if loaded.get("ok",false):
		WorldSimulation.scoped("parchment_owner",func()->void:
			var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true);E.advance(1);assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
			var job:Dictionary=WorldSimulation.military.equipment_queue.back();P.advance(WorldSimulation.military,job,2.5)
			assert_int(int(job.completed)).is_equal(1))
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
