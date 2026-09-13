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
	S.measure(ledger,sample,1,true,["cell_division_observation","microscopic_cell_observation"])
	assert_bool(sample.methods.has("division")).is_false()
	S.grow(sample,2,.02,true);S.measure(ledger,sample,2,true,["cell_division_observation","microscopic_cell_observation"])
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
func controlled_starter(ledger:Dictionary,mixed:float)->void:
	var parent:=S.add(ledger,"starter",1,0,"home",0,.04,{"viability":.9,"contamination":mixed})
	S.measure(ledger,parent,0,false,["microbial_observation"])
	var child:=S.isolate(ledger,parent,0)
	for day:int in range(1,11):
		S.grow(parent,day,.02,false);S.measure(ledger,parent,day,false,["microbial_observation"])
		S.grow(child,day,.02,false);S.measure(ledger,child,day,false,["microbial_observation"])
	S.record(ledger,child,10,"growth",{"line":int(child.line),"elapsed":9,"initial":float(child.history[0].cells),"final":float(child.history[-1].cells)})
func test_blank_control_separates_lab_contamination_from_source_starter_decision()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("controls",91420)
	WorldSimulation.scoped("controls",func()->void:
		var ledger:Dictionary=WorldSimulation.state.microscopy
		controlled_starter(ledger,0.0)
		assert_float(float(ledger.specimens[0].contamination)).is_greater(.35)
		assert_bool(preload("res://scripts/microscopy_lab.gd").starter_usable({"id":1,"created":0},10)).is_true()
		WorldSimulation.state.microscopy=S.empty_state();ledger=WorldSimulation.state.microscopy
		controlled_starter(ledger,.6)
		assert_bool(preload("res://scripts/microscopy_lab.gd").starter_usable({"id":1,"created":0},10)).is_false()
		var batches=preload("res://scripts/food_batches.gd")
		var lot:=batches.add_lot("starter",1.0,0)
		assert_float(batches.starter_available(10)).is_equal(0.0)
		batches.consume_starter(.5,10)
		assert_float(float(lot.amount)).is_equal(1.0)
		assert_bool(preload("res://scripts/microscopy_lab.gd").starter_usable({"id":2,"created":0},10)).is_true()
		assert_bool(preload("res://scripts/microscopy_lab.gd").starter_usable({"id":1,"created":0},14)).is_true()
		assert_bool(S.valid(ledger)).is_true()
		var bad:=ledger.duplicate(true);bad.specimens[1].methods.growth.source=99
		assert_bool(S.valid(bad)).is_false()
	)
	WorldSimulation.clear()
func test_failed_replication_can_retry_new_sources_and_heat_does_not_accumulate_across_gaps()->void:
	var ledger:=S.empty_state();ledger.work_bank=8.0
	var known:Array=["laboratory_notebooks","experimental_protocol_publication"]
	for id:int in [1,2]:
		var sample:=S.add(ledger,"starter",id,0,"home",0,.04,{"viability":1.0 if id==1 else .2})
		S.measure(ledger,sample,0,true,known);S.grow(sample,1,.02,true);S.measure(ledger,sample,1,true,known)
	var stocks:={"Printed Sheets":2.0,"Charcoal":2.0,"Freshwater":2.0}
	var lab=preload("res://scripts/microscopy_lab.gd")
	lab.interpret(ledger,stocks,known,1)
	assert_bool(lab.protocol_ready(ledger,"starter")).is_false()
	var third:=S.add(ledger,"starter",3,0,"home",0,.04,{"viability":.95})
	S.measure(ledger,third,0,true,known);S.grow(third,1,.02,true);S.measure(ledger,third,1,true,known)
	lab.interpret(ledger,stocks,known,1)
	assert_bool(lab.protocol_ready(ledger,"starter")).is_true()
	assert_float(float(stocks["Printed Sheets"])).is_equal_approx(1.8,.00001)
	ledger.tools={"bench":true,"thermometry":true}
	lab.prepare_station(ledger,stocks,["instrument_sterilization","precision_thermometry"],2)
	assert_int(int(ledger.tools.get("sterile_uses",0))).is_equal(0)
	lab.prepare_station(ledger,stocks,["instrument_sterilization","precision_thermometry"],5)
	assert_int(int(ledger.tools.get("sterile_uses",0))).is_equal(0)
	lab.prepare_station(ledger,stocks,["instrument_sterilization","precision_thermometry"],6)
	assert_int(int(ledger.tools.get("sterile_uses",0))).is_equal(2)
func test_real_crop_trial_rejects_recent_cellular_tissue_failure()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("crop_lab",91420)
	WorldSimulation.scoped("crop_lab",func()->void:
		var state=WorldSimulation.state
		var botany=preload("res://scripts/field_botany.gd")
		var lab=preload("res://scripts/microscopy_lab.gd")
		var known:Array=[]
		for entry:Dictionary in preload("res://scripts/field_botany_knowledge.gd").entries():known.append(entry.id)
		for entry:Dictionary in preload("res://scripts/microscopy_knowledge.gd").entries():known.append(entry.id)
		var field:=botany.empty_state();field.balance=true
		botany.retain_seed(field,100,"home",0);field.lines[0].drought_tolerance=.28
		botany.sow_trial(field,0,"home",0)
		for day:int in range(1,91):botany.observe(field,day,"home",known,1,1,1)
		botany.sow_trial(field,1,"home",90)
		for day:int in range(91,177):botany.observe(field,day,"home",known,1,1,1)
		var comparison:=field.duplicate(true)
		for day:int in range(177,181):botany.observe(comparison,day,"home",known,1,1,1)
		assert_bool(comparison.vouchers[-1].qualified).is_true()
		state.field_botany=field
		state.resource_stockpiles={"Specimen Slides":1.0,"Freshwater":1.0,"Steel Tool Bits":1.0}
		state.microscopy.work_bank=1.0
		botany.observe(field,177,"home",known,1,1,1)
		lab.collect_plant(state.microscopy,state.resource_stockpiles,177)
		var sample:Dictionary=state.microscopy.specimens[0]
		for day:int in range(177,180):
			if day>177:botany.observe(field,day,"home",known,1,1,1)
			if S.grow(sample,day,.02,true):S.record(state.microscopy,sample,day,"culture",{"media":float(sample.media),"aseptic":true,"line":0})
			lab.prepare_section(state.microscopy,sample,state.resource_stockpiles,day)
			S.measure(state.microscopy,sample,day,true,known)
		var starter:=S.add(state.microscopy,"starter",3,177,"home",177,.01,{"viability":1.0})
		S.measure(state.microscopy,starter,179,false,known)
		lab.interpret(state.microscopy,{},known,179)
		var retained:Dictionary=lab.field_evidence(int(field.trials[0].line.id),90,180)
		assert_dict(retained).is_not_empty()
		sample.viability=1.0;sample.profile.tissue_order=1.0
		assert_dict(lab.field_evidence(int(field.trials[0].line.id),90,180)).is_equal(retained)
		botany.observe(field,180,"home",known,1,1,1)
		assert_bool(field.vouchers[-1].qualified).is_false()
	)
	WorldSimulation.clear()

func test_replication_requires_matching_recorded_conditions()->void:
	var ledger:=S.empty_state()
	var known:Array=["laboratory_notebooks"]
	var a:=S.add(ledger,"starter",1,0,"home",0,.04,{"viability":.8})
	var b:=S.add(ledger,"starter",2,0,"home",0,.04,{"viability":.8})
	for sample:Dictionary in [a,b]:
		S.grow(sample,1,.02,true);S.measure(ledger,sample,1,true,known)
	var lab=preload("res://scripts/microscopy_lab.gd")
	assert_dict(lab.replication_pair(a,b)).is_not_empty()
	for field:String in ["source_stage","aseptic","contrast","blank_paid"]:
		var changed:=b.duplicate(true)
		if field=="source_stage":changed.history[0][field]=2
		elif field=="aseptic":changed.history[0][field]=true
		elif field=="contrast":changed.history[0][field]=.45
		else:changed.history[0][field]=0.0
		assert_dict(lab.replication_pair(a,changed)).is_empty()
	b.history.clear()
	assert_dict(lab.replication_pair(a,b)).is_empty()

func test_heat_evidence_expires_and_calibration_alone_is_valid()->void:
	var ledger:=S.empty_state();ledger.work_bank=8.0
	ledger.tools={"bench":true,"thermometry":true}
	var stocks:={"Freshwater":10.0,"Charcoal":10.0}
	var lab=preload("res://scripts/microscopy_lab.gd")
	lab.prepare_station(ledger,stocks,["precision_thermometry"],1)
	assert_bool(S.valid(ledger)).is_true()
	var known:Array=["precision_thermometry","instrument_sterilization"]
	lab.prepare_station(ledger,stocks,known,2)
	lab.prepare_station(ledger,stocks,known,3)
	assert_int(int(ledger.tools.sterile_uses)).is_equal(2)
	assert_bool(S.valid(ledger)).is_true()
	var forged:=ledger.duplicate(true);forged.tools.heat_readings[-1].observed_heat=.8
	assert_bool(S.valid(forged)).is_false()
	lab.prepare_station(ledger,stocks,known,6)
	assert_int(int(ledger.tools.sterile_uses)).is_equal(0)
	assert_bool(S.valid(ledger)).is_true()
	lab.prepare_station(ledger,stocks,known,40)
	assert_int(int(ledger.tools.calibration.day)).is_equal(40)
	assert_bool(S.valid(ledger)).is_true()

func test_histology_requires_paid_section_not_whole_sample_staining()->void:
	var ledger:=S.empty_state();ledger.work_bank=1.0
	var sample:=S.add(ledger,"plant",1,0,"home",0,.001,{"viability":.8,"tissue_order":.7})
	var known:Array=["tissue_histology","biological_staining"]
	S.measure(ledger,sample,0,true,known)
	assert_bool(sample.methods.has("tissue")).is_false()
	var lab=preload("res://scripts/microscopy_lab.gd")
	assert_bool(lab.prepare_section(ledger,sample,{},1)).is_false()
	var stocks:={"Steel Tool Bits":1.0,"Specimen Slides":1.0,"Freshwater":1.0}
	assert_bool(lab.prepare_section(ledger,sample,stocks,1)).is_true()
	assert_float(float(sample.amount)).is_equal_approx(.0009,.000001)
	assert_float(float(stocks["Steel Tool Bits"])).is_equal_approx(.999,.000001)
	S.measure(ledger,sample,1,true,known)
	assert_bool(sample.methods.has("tissue")).is_true()
	assert_bool(S.valid(ledger)).is_true()

func test_counts_alone_or_unresolved_or_missing_frame_cannot_prove_division()->void:
	var known:Array=["cell_division_observation","microscopic_cell_observation"]
	for mode:String in ["counts","unresolved","gap"]:
		var ledger:=S.empty_state()
		var sample:=S.add(ledger,"starter",1,0,"home",0,.04,{"viability":.9})
		if mode!="counts":S.grow(sample,1,.02,true)
		S.measure(ledger,sample,1,mode!="unresolved",known)
		var day:=3 if mode=="gap" else 2
		if mode=="counts":sample.cells+=10.0
		else:S.grow(sample,day,.02,true)
		S.measure(ledger,sample,day,true,known)
		assert_bool(sample.methods.has("division")).is_false()
