extends GdUnitTestSuite
const I=preload("res://scripts/civilian_industry.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const Samples=preload("res://scripts/polymer_samples.gd")
const Acquisition=preload("res://scripts/nmr_acquisition.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("peg",5211)
func after_test()->void:WorldSimulation.clear()
const Bills=preload("res://scripts/goods_bills.gd")
func supply(bill:Dictionary,scale:float=1.0)->void:
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	for item:String in bill:stocks[item]=float(stocks.get(item,0))+float(bill[item])*scale
## `count` retained specimens of `recipe`: the first prepared and paid at the
## bench from raw materials and goods, further ones recorded directly (the bench
## prepares one at a time).
func retain(recipe:String,count:int)->void:
	var spec:=I.product(recipe);var s=WorldSimulation.state
	var gates:Array=[spec.gate]
	if spec.get("requires") is Array:gates.append_array(spec.requires)
	for gate:String in gates:s.known_discoveries.append(gate);s.discovery_adoption[gate]=1.0
	var bill:=Samples.preparation_bill(recipe)
	supply(bill);var before:Dictionary=s.resource_stockpiles.duplicate()
	assert_bool(Samples.prepare(recipe)).is_true()
	for item:String in bill:assert_float(float(s.resource_stockpiles[item])).is_equal_approx(float(before[item])-float(bill[item]),.000001)
	if count>1:Samples.completed(recipe,count-1)
	assert_int(Samples.data().records.size()).is_equal(count)
## Bench maintenance, fuel, references and acquisition supplies as raw materials and goods.
func operate()->void:
	var s=WorldSimulation.state
	s.known_discoveries.append("polymer_solution_processing");s.discovery_adoption.polymer_solution_processing=1.0
	supply(Ops.PLANTS.nmr_analytical_bench.inputs,100.0);supply(Bills.flatten({"Paper":1.0,"Toluene":5.0,"Freshwater":7.0}))
	for item:String in ["Coal","Freshwater"]:s.resource_stockpiles[item]=100.0
	supply(preload("res://scripts/nmr_calibration.gd").REFERENCE,4.0)
	for id:String in ["nmr_analytical_bench","steam_generator"]:Ops.data().plants[id]={"installed":1,"building":0,"work":0.0,"enabled":true}
func test_retained_peg_quantitative_acquisition_supplies_paid_binder_without_bulk_certification()->void:
	WorldSimulation.scoped("peg",func()->void:
		var s=WorldSimulation.state;s.elapsed_days=0;s.settlement_site_committed=true;s.convoy_traveling=false
		s.population_allocations.Crafting=20;s.population_health=1.0;s.simulation_metrics.labor_efficiency=1.0
		retain("traceable_peg_batch",2);operate()
		s.resource_stockpiles["Controlled-Chain PEG"]=50.0
		for day:int in range(1,40):s.elapsed_days=day;Ops.advance(day)
		for id:String in ["1","2"]:
			var report:=Acquisition.report(id)
			assert_str(report.status).override_failure_message(str(report)).is_equal("resolved")
			if report.status!="resolved":return
			assert_bool(report.interpretation.distribution_measured).is_false()
			assert_bool(report.interpretation.stock_qualified).is_false()
			assert_float(float(report.interpretation.mean_dp)).is_greater(10.0)
		assert_float(float(s.resource_stockpiles.get("Size-Characterized PEG Batches",0))).is_equal(2.0)
		assert_float(float(s.resource_stockpiles["Controlled-Chain PEG"])).is_equal(50.0)
		assert_bool(Ops.valid(Ops.data())).is_true()
		# Corrupt persisted nested evidence must reject before report evaluation.
		for key:String in ["step","origin","noise_estimate"]:
			for invalid:Variant in ["bad",[],{},NAN]:
				var damaged:=Ops.data().duplicate(true)
				damaged.polymer_samples.records["1"].observation[key]=invalid
				assert_bool(Ops.valid(damaged)).is_false()
		if Samples.data().records["1"].recipe=="traceable_peg_batch":
			for invalid:Variant in ["bad",[],null]:
				var damaged:=Ops.data().duplicate(true)
				damaged.polymer_samples.records["1"].observation.peg_observation=invalid
				assert_bool(Ops.valid(damaged)).is_false())

func test_retained_pp_tacticity_measurement_supplies_closures_without_certifying_bulk()->void:
	WorldSimulation.scoped("peg",func()->void:
		var s=WorldSimulation.state;s.elapsed_days=0;s.settlement_site_committed=true;s.convoy_traveling=false
		s.population_allocations.Crafting=20;s.population_health=1.0;s.simulation_metrics.labor_efficiency=1.0
		retain("traceable_pp_batch",2);operate()
		s.resource_stockpiles["Raw Polypropylene"]=50.0
		for day:int in range(1,40):s.elapsed_days=day;Ops.advance(day)
		for id:String in ["1","2"]:
			var report:=Acquisition.report(id)
			assert_str(report.status).override_failure_message(str(report)).is_equal("resolved")
			if report.status!="resolved":return
			assert_bool(report.interpretation.full_stereosequence_measured).is_false()
		assert_float(float(s.resource_stockpiles.get("Tacticity-Characterized PP Batches",0))).is_equal(2.0)
		assert_float(float(s.resource_stockpiles["Raw Polypropylene"])).is_equal(50.0)
		assert_bool(Ops.valid(Ops.data())).is_true()
		# Corrupt persisted nested evidence must reject before report evaluation.
		for key:String in ["step","origin","noise_estimate"]:
			for invalid:Variant in ["bad",[],{},NAN]:
				var damaged:=Ops.data().duplicate(true)
				damaged.polymer_samples.records["1"].observation[key]=invalid
				assert_bool(Ops.valid(damaged)).is_false()
		if Samples.data().records["1"].recipe=="traceable_peg_batch":
			for invalid:Variant in ["bad",[],null]:
				var damaged:=Ops.data().duplicate(true)
				damaged.polymer_samples.records["1"].observation.peg_observation=invalid
				assert_bool(Ops.valid(damaged)).is_false())

func test_quantitative_peg_and_pp_resume_full_save_without_duplicate_materials()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	for recipe:String in ["traceable_peg_batch","traceable_pp_batch"]:
		WorldSimulation.clear();WorldSimulation.create_actor("peg",5211)
		WorldSimulation.scoped("peg",func()->void:
			var s=WorldSimulation.state;s.elapsed_days=0;s.settlement_site_committed=true;s.convoy_traveling=false
			s.population_allocations.Crafting=20;s.population_health=1.0;s.simulation_metrics.labor_efficiency=1.0
			retain(recipe,1);operate()
			for day:int in range(1,11):s.elapsed_days=day;Ops.advance(day)
			assert_str(Samples.data().records["1"].status).is_equal("acquiring")
			assert_float(float(Samples.data().records["1"].acquisition.work)).is_equal(2.0))
		var slot:="quantitative_polymer_%s_%d"%[recipe,OS.get_process_id()]
		assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
		WorldSimulation.clear();var restored:=SaveSystem.load_game(slot)
		assert_bool(restored.get("ok",false)).override_failure_message(str(restored)).is_true()
		if restored.get("ok",false):
			WorldSimulation.scoped("peg",func()->void:
				var s=WorldSimulation.state;var before:Dictionary=s.resource_stockpiles.duplicate(true)
				assert_float(Acquisition.advance("1",100)).is_equal(0.0)
				assert_bool(s.resource_stockpiles==before).is_true()
				for day:int in range(11,15):s.elapsed_days=day;Ops.advance(day)
				assert_str(Acquisition.report("1").status).is_equal("resolved")
				assert_float(float(s.resource_stockpiles.get(I.product(recipe).output,0))).is_equal(0.0))
		assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
		var completed:=SaveSystem._read_payload(slot)
		WorldSimulation.clear();restored=SaveSystem.load_game(slot)
		assert_bool(restored.get("ok",false)).override_failure_message(str(restored)).is_true()
		if restored.get("ok",false):
			WorldSimulation.scoped("peg",func()->void:
				var s=WorldSimulation.state
				var output:="Size-Characterized PEG Batches" if recipe=="traceable_peg_batch" else "Tacticity-Characterized PP Batches"
				assert_float(float(s.resource_stockpiles.get(output,0))).is_equal(1.0)
				assert_str(Acquisition.report("1").status).is_equal("resolved")
				Acquisition.release_characterized_specimen(Samples.data().records["1"])
				assert_float(float(s.resource_stockpiles.get(output,0))).is_equal(1.0))
		# Exercise the actual full-load rejection boundary before world reset.
		var observation:Dictionary=completed.curated_WorldSimulation.actors.peg.state.GameState.technology_operations.polymer_samples.records["1"].observation
		if recipe=="traceable_peg_batch":observation.peg_observation="damaged"
		else:observation.noise_estimate=[]
		assert_bool(SaveSystem._write_payload(SaveSystem.slot_path(slot),completed).get("ok",false)).is_true()
		assert_bool(SaveSystem.load_game(slot).has("error")).is_true()
		assert_bool(WorldSimulation.export_state().actors.has("peg")).is_true()
		DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
