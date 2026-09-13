extends GdUnitTestSuite
const S=preload("res://scripts/microscopy_samples.gd")
func test_isolation_transfers_finite_named_material_and_never_grants_purity()->void:
	var ledger:=S.empty_state()
	var source:=S.add(ledger,"starter",1,0,"home",0,.04,{"viability":.9,"contamination":.4})
	S.measure(ledger,source,0,false,["microbial_observation"])
	var child:=S.isolate(ledger,source,1)
	assert_float(float(source.amount)+float(child.amount)).is_equal(.04)
	assert_int(int(child.parent)).is_equal(int(source.id))
	assert_float(float(child.contamination)).is_greater(0.0)
	assert_bool(S.valid(ledger)).is_true()
func test_growth_and_time_lapse_require_distinct_days_and_supplied_media()->void:
	var ledger:=S.empty_state()
	var sample:=S.add(ledger,"starter",1,0,"home",0,.04,{"viability":.9,"contamination":.1})
	assert_bool(S.grow(sample,0,.02,true)).is_false()
	assert_bool(S.grow(sample,1,0.0,true)).is_false()
	assert_bool(S.grow(sample,1,.02,true)).is_true()
	var before:=sample.duplicate(true)
	assert_bool(S.grow(sample,1,.02,true)).is_false()
	assert_dict(sample).is_equal(before)
	S.measure(ledger,sample,1,false,["cell_division_observation"])
	assert_bool(sample.methods.has("division")).is_false()
	S.grow(sample,2,.02,true);S.measure(ledger,sample,2,false,["cell_division_observation"])
	assert_bool(sample.methods.has("division")).is_true()
	S.expire(ledger,22)
	assert_array(ledger.specimens).is_empty()
func test_paid_local_lab_reserves_after_care_and_observes_real_starter_lots_once_per_day()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("lab",91420)
	WorldSimulation.scoped("lab",func()->void:
		var state=WorldSimulation.state
		state.settlement_site_committed=true;state.population_allocations.Knowledge=20
		WorldSimulation.settlements.ensure_founded()
		for entry:Dictionary in preload("res://scripts/microscopy_knowledge.gd").entries():state.known_discoveries.append(entry.id);state.discovery_adoption[entry.id]=1.0
		state.known_discoveries.append_array(["precision_thermometry","clinical_observation_rounds"])
		state.discovery_adoption.clinical_observation_rounds=1.0
		var lab=preload("res://scripts/microscopy_lab.gd")
		var care=preload("res://scripts/civilian_care.gd")
		var raw:=state.effective_workers("Knowledge",false,true)
		var reserved:=lab.reserved(state,state.effective_workers("Knowledge",false,false,false,true))
		assert_float(state.effective_workers("Knowledge")+care.staff()+reserved).is_equal_approx(raw,.00001)
		state.resource_stockpiles={"Compound Microscopes":1.0,"Laboratory Glassware":20.0,"Specimen Slides":10.0,"Glass Tubes":2.0,"Copper Wire":1.0,"Glass Vessels":2.0,"Charcoal":2.0,"Freshwater":20.0,"Plant Tannin Extract":2.0,"Printed Sheets":2.0,"Clay":2.0}
		state.food_stocks={"Dry staples":20.0}
		var batches=preload("res://scripts/food_batches.gd")
		batches.add_lot("starter",2,0);batches.add_lot("starter",2,0)
		for day:int in range(1,7):
			state.elapsed_days=day
			lab.advance(false)
			var stocks:Dictionary=state.resource_stockpiles.duplicate(true)
			var ledger:Dictionary=state.microscopy.duplicate(true)
			lab.advance(false)
			assert_dict(state.resource_stockpiles).is_equal(stocks)
			assert_dict(state.microscopy).is_equal(ledger)
		assert_float(float(state.resource_stockpiles["Compound Microscopes"])).is_equal(0.0)
		assert_float(float(state.food_stocks["Dry staples"])).is_less(20.0)
		assert_float(float(batches.data().lots[0].amount)).is_less(2.0)
		assert_array(state.microscopy.protocols).is_not_empty()
		assert_bool(S.valid(state.microscopy)).is_true()
	)
	WorldSimulation.clear()
