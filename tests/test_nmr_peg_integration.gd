extends GdUnitTestSuite
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const Samples=preload("res://scripts/polymer_samples.gd")
const Acquisition=preload("res://scripts/nmr_acquisition.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("peg",5211)
func after_test()->void:WorldSimulation.clear()
func setup_line(item:String,target:int)->Dictionary:
	var spec:=I.product(item);var s=WorldSimulation.state
	s.known_discoveries.append(spec.gate);s.discovery_adoption[spec.gate]=1.0
	for tool:String in spec.tooling:s.resource_stockpiles[tool]=100.0
	assert_bool(WorldSimulation.military.start_production_line(item,target).get("ok",false)).is_true()
	return WorldSimulation.military.equipment_queue.back()
func test_retained_peg_quantitative_acquisition_supplies_paid_binder_without_bulk_certification()->void:
	WorldSimulation.scoped("peg",func()->void:
		var s=WorldSimulation.state;s.elapsed_days=0;s.settlement_site_committed=true;s.convoy_traveling=false
		s.population_allocations.Crafting=20;s.population_health=1.0;s.simulation_metrics.labor_efficiency=1.0
		var spec:=I.product("traceable_peg_batch")
		for item:String in spec.materials:s.resource_stockpiles[item]=float(spec.materials[item])*2.0
		Ops.data().last_day=0;Ops.data().services={"electricity":10.0,"polymer_stirred_work":10.0,"polymer_heat_removal":10.0}
		var job:=setup_line("traceable_peg_batch",2)
		P.advance(WorldSimulation.military,job,6);P.advance(WorldSimulation.military,job,6)
		assert_int(Samples.data().records.size()).is_equal(2)
		WorldSimulation.military.cancel_equipment_job(int(job.id))
		s.known_discoveries.append("polymer_solution_processing");s.discovery_adoption.polymer_solution_processing=1.0
		for item:String in ["Coal","Freshwater","Insulated Cable","Paper"]:s.resource_stockpiles[item]=100.0
		s.resource_stockpiles["NMR Methanol References"]=4.0
		s.resource_stockpiles["Controlled-Chain PEG"]=50.0
		for id:String in ["nmr_analytical_bench","steam_generator"]:Ops.data().plants[id]={"installed":1,"building":0,"work":0.0,"enabled":true}
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
				assert_bool(Ops.valid(damaged)).is_false()
		s.resource_stockpiles["Alumina Catalyst Supports"]=1.0
		Ops.data().services["electricity"]=10.0
		for item:String in ["characterized_controlled_peg","size_qualified_peg_binder","aqueous_peg_binder"]:
			var line:=setup_line(item,2 if item=="characterized_controlled_peg" else 1)
			P.advance(WorldSimulation.military,line,100)
			assert_int(int(line.completed)).is_equal(2 if item=="characterized_controlled_peg" else 1)
			WorldSimulation.military.cancel_equipment_job(int(line.id))
		assert_float(float(s.resource_stockpiles.get("Aqueous PEG Binder",0))).is_equal(1.0)
		assert_float(float(s.resource_stockpiles.get("Size-Characterized PEG Batches",0))).is_equal(0.0))

func test_retained_pp_tacticity_measurement_supplies_closures_without_certifying_bulk()->void:
	WorldSimulation.scoped("peg",func()->void:
		var s=WorldSimulation.state;s.elapsed_days=0;s.settlement_site_committed=true;s.convoy_traveling=false
		s.population_allocations.Crafting=20;s.population_health=1.0;s.simulation_metrics.labor_efficiency=1.0
		var spec:=I.product("traceable_pp_batch")
		for item:String in spec.materials:s.resource_stockpiles[item]=float(spec.materials[item])*2.0
		Ops.data().last_day=0;Ops.data().services={"electricity":10.0,"polymer_stirred_work":10.0,"polymer_heat_removal":10.0}
		var job:=setup_line("traceable_pp_batch",2)
		P.advance(WorldSimulation.military,job,7);P.advance(WorldSimulation.military,job,7)
		WorldSimulation.military.cancel_equipment_job(int(job.id))
		s.known_discoveries.append("polymer_solution_processing");s.discovery_adoption.polymer_solution_processing=1.0
		for item:String in ["Coal","Freshwater","Insulated Cable","Paper","Toluene"]:s.resource_stockpiles[item]=100.0
		s.resource_stockpiles["NMR Methanol References"]=4.0;s.resource_stockpiles["Raw Polypropylene"]=50.0
		for id:String in ["nmr_analytical_bench","steam_generator"]:Ops.data().plants[id]={"installed":1,"building":0,"work":0.0,"enabled":true}
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
				assert_bool(Ops.valid(damaged)).is_false()
		Ops.data().services["electricity"]=10.0;s.resource_stockpiles["LDPE Wash Bottle Bodies"]=1.0
		for item:String in ["spectrally_qualified_polypropylene","polypropylene_molding_grade","injected_pp_wash_closures","pp_closure_wash_bottles"]:
			var line:=setup_line(item,2 if item=="spectrally_qualified_polypropylene" else 1)
			P.advance(WorldSimulation.military,line,100)
			assert_int(int(line.completed)).is_equal(2 if item=="spectrally_qualified_polypropylene" else 1)
			WorldSimulation.military.cancel_equipment_job(int(line.id))
		assert_float(float(s.resource_stockpiles.get("Water Wash Bottles",0))).is_equal(1.0)
		assert_float(float(s.resource_stockpiles.get("Tacticity-Characterized PP Batches",0))).is_equal(0.0))

func test_quantitative_peg_and_pp_resume_full_save_without_duplicate_materials()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	for recipe:String in ["traceable_peg_batch","traceable_pp_batch"]:
		WorldSimulation.clear();WorldSimulation.create_actor("peg",5211)
		WorldSimulation.scoped("peg",func()->void:
			var s=WorldSimulation.state;s.elapsed_days=0;s.settlement_site_committed=true;s.convoy_traveling=false
			s.population_allocations.Crafting=20;s.population_health=1.0;s.simulation_metrics.labor_efficiency=1.0
			var spec:=I.product(recipe)
			for item:String in spec.materials:s.resource_stockpiles[item]=float(spec.materials[item])
			Ops.data().last_day=0;Ops.data().services={"electricity":10.0,"polymer_stirred_work":10.0,"polymer_heat_removal":10.0}
			var job:=setup_line(recipe,1);P.advance(WorldSimulation.military,job,100)
			WorldSimulation.military.cancel_equipment_job(int(job.id))
			s.known_discoveries.append("polymer_solution_processing");s.discovery_adoption.polymer_solution_processing=1.0
			for item:String in ["Coal","Freshwater","Insulated Cable","Paper","Toluene"]:s.resource_stockpiles[item]=100.0
			s.resource_stockpiles["NMR Methanol References"]=4.0
			for id:String in ["nmr_analytical_bench","steam_generator"]:Ops.data().plants[id]={"installed":1,"building":0,"work":0.0,"enabled":true}
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
