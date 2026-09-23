extends GdUnitTestSuite
const K=preload("res://scripts/parchment_knowledge.gd")
const S=preload("res://scripts/paper_study.gd")
const E=preload("res://scripts/society_exchange.gd")
const GOODS:="Civilian Goods"
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("parchment_owner",996)
func after_test()->void:WorldSimulation.clear()
func note(kind:String="knowledge")->Dictionary:
	return {"id":"local_note","kind":kind,"name":"Local comparison","source_id":"","source_name":"Local","position":{"x":0.0,"z":0.0},"observed_day":0,"returned_day":0,"discovery_id":"clay_shaping","study":0.0,"work":100.0,"signals":[]}
func know(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
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
func test_parchment_study_spends_only_actual_work_without_teaching_manufacture()->void:
	WorldSimulation.scoped("parchment_owner",func()->void:
		var state=WorldSimulation.state;var bill:=S.bill("Parchment Sheets")
		for r:String in bill:state.resource_stockpiles[r]=1.0
		# Goods and hides alone are not parchment.
		var before:Dictionary=state.resource_stockpiles.duplicate(true)
		assert_float(float(S.use(10,100,note()).progress)).is_equal(10.0);assert_dict(state.resource_stockpiles).is_equal(before)
		know("parchment_record_preparation")
		var result:=S.use(10,100,note())
		assert_float(float(result.work)).is_equal_approx(10.0,.000001);assert_float(float(result.progress)).is_equal_approx(12.0,.000001)
		for r:String in bill:assert_float(float(state.resource_stockpiles[r])).is_equal_approx(1-10*float(bill[r]),.000001)
		assert_float(float(result.record_media["Parchment Sheets"])).is_equal_approx(.06,.000001)
		assert_bool("hide_tanning" in state.known_discoveries).is_false()
		result=S.use(100,.12,note());assert_float(float(result.work)).is_equal_approx(.1,.000001)
		assert_float(float(result.progress)).is_equal_approx(.12,.000001)
		before=state.resource_stockpiles.duplicate(true);S.use(0,100,note());S.use(100,0,note());assert_dict(state.resource_stockpiles).is_equal(before))
func test_actual_arrived_collection_study_pays_parchment_once_and_preserves_missing_evidence()->void:
	WorldSimulation.scoped("parchment_owner",func()->void:
		var state=WorldSimulation.state;state.ensure_population_total(100);state.population_allocations.Knowledge=20;state.simulation_metrics.food_intake_ratio=1.0
		know("parchment_record_preparation");var bill:=S.bill("Parchment Sheets")
		for r:String in bill:state.resource_stockpiles[r]=1.0
		E.data().collections.local_note=note();var later:=note();later.id="later";later.returned_day=100;E.data().collections.later=later
		var work:=state.effective_workers("Knowledge")*.15;E.advance(1)
		assert_float(float(E.data().collections.local_note.study)).is_equal_approx(work*1.2/100,.000001)
		assert_float(float(E.data().collections.later.study)).is_equal(0.0)
		assert_float(float(state.resource_stockpiles[GOODS])).is_equal_approx(1-work*float(bill[GOODS]),.000001)
		assert_float(float(state.resource_stockpiles["Raw Hides"])).is_equal_approx(1-work*float(bill["Raw Hides"]),.000001)
		var before:Dictionary=state.resource_stockpiles.duplicate(true);E.advance(1);assert_dict(state.resource_stockpiles).is_equal(before))
func test_full_actor_save_continues_paid_parchment_and_prior_study_once()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.scoped("parchment_owner",func()->void:
		know("parchment_record_preparation")
		var state=WorldSimulation.state;state.ensure_population_total(100);state.population_allocations.Knowledge=20;state.simulation_metrics.food_intake_ratio=1.0
		for r:String in S.bill("Parchment Sheets"):state.resource_stockpiles[r]=1.0
		E.data().collections.local_note=note();E.advance(1))
	var study:=float(WorldSimulation.actors.parchment_owner.systems.GameState.society_exchange.collections.local_note.study)
	var slot:="parchment_%d"%OS.get_process_id();var okay:=SaveSystem.save_game(slot)
	assert_bool(okay.get("ok",false)).override_failure_message(str(okay)).is_true()
	WorldSimulation.clear();var loaded:=SaveSystem.load_game(slot);DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(loaded.get("ok",false)).override_failure_message(str(loaded)).is_true()
	if loaded.get("ok",false):
		WorldSimulation.scoped("parchment_owner",func()->void:
			var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true);E.advance(1);assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
			assert_float(float(E.data().collections.local_note.study)).is_equal(study)
			assert_float(study).is_greater(0.0))
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
