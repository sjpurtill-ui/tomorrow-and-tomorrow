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
		Ops.data().services["electricity"]=10.0;s.resource_stockpiles["LDPE Wash Bottle Bodies"]=1.0
		for item:String in ["spectrally_qualified_polypropylene","polypropylene_molding_grade","injected_pp_wash_closures","pp_closure_wash_bottles"]:
			var line:=setup_line(item,2 if item=="spectrally_qualified_polypropylene" else 1)
			P.advance(WorldSimulation.military,line,100)
			assert_int(int(line.completed)).is_equal(2 if item=="spectrally_qualified_polypropylene" else 1)
			WorldSimulation.military.cancel_equipment_job(int(line.id))
		assert_float(float(s.resource_stockpiles.get("Water Wash Bottles",0))).is_equal(1.0)
		assert_float(float(s.resource_stockpiles.get("Tacticity-Characterized PP Batches",0))).is_equal(0.0))
