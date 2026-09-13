extends GdUnitTestSuite
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const Samples=preload("res://scripts/polymer_samples.gd")
const SEC=preload("res://scripts/sec_acquisition.gd")
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("sec",5571)
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func make(item:String,target:int)->void:
	var spec:=I.product(item);var s=WorldSimulation.state
	if spec.gate not in s.known_discoveries:s.known_discoveries.append(spec.gate)
	s.discovery_adoption[spec.gate]=1.0
	for tool:String in spec.tooling:s.resource_stockpiles[tool]=100.0
	Ops.data().services["electricity"]=100.0
	var started:Dictionary=WorldSimulation.military.start_production_line(item,target)
	assert_bool(started.get("ok",false)).override_failure_message(str(started)).is_true()
	if not started.get("ok",false):return
	var job:Dictionary=WorldSimulation.military.equipment_queue.back()
	if item=="sec_traceable_peg_batch":
		for index:int in target:P.advance(WorldSimulation.military,job,6.0)
	else:P.advance(WorldSimulation.military,job,100)
	assert_int(int(job.completed)).is_greater(0)
	WorldSimulation.military.cancel_equipment_job(int(job.id))
func prepare(count:int=4)->void:
	var s=WorldSimulation.state;s.elapsed_days=0;s.settlement_site_committed=true;s.convoy_traveling=false
	s.population_allocations.Crafting=40;s.population_health=1.0;s.simulation_metrics.labor_efficiency=1.0
	Ops.data().last_day=0
	var components:Array[String]=["sec_metering_pump","sec_optical_flow_cell","sec_bench_assembly","sec_packed_column","sec_reference_solutions"]
	var outputs:Array=[]
	for item:String in components:outputs.append(I.product(item).output)
	for item:String in components:
		for material:String in I.product(item).materials:
			if material not in outputs:s.resource_stockpiles[material]=100.0
	for item:String in components:make(item,1)
	assert_float(float(s.resource_stockpiles["SEC Metering Pumps"])).is_equal(0.0)
	assert_float(float(s.resource_stockpiles["SEC Optical Flow Cells"])).is_equal(0.0)
	s.known_discoveries.append("electrical_measurement");s.discovery_adoption.electrical_measurement=1.0
	assert_bool(Ops.install("sec_analytical_bench").get("ok",false)).is_true()
	assert_float(float(s.resource_stockpiles["SEC Bench Assemblies"])).is_equal(0.0)
	s.resource_stockpiles["Coal"]=1000.0;s.resource_stockpiles["Freshwater"]=1000.0
	Ops.data().plants["steam_generator"]={"installed":1,"building":0,"work":0.0,"enabled":true}
	for day:int in range(1,9):s.elapsed_days=day;Ops.advance(day)
	assert_int(int(Ops.data().plants.sec_analytical_bench.installed)).is_equal(1)
	var spec:=I.product("sec_traceable_peg_batch")
	for material:String in spec.materials:s.resource_stockpiles[material]=float(spec.materials[material])*count+10.0
	Ops.data().services["polymer_stirred_work"]=100.0;Ops.data().services["polymer_heat_removal"]=100.0
	make("sec_traceable_peg_batch",count)
	s.resource_stockpiles["Freshwater"]=1000.0
	assert_int(Samples.data().records.size()).is_equal(count)
func test_paid_column_and_retained_distributions_select_actual_binder_routes()->void:
	WorldSimulation.scoped("sec",func()->void:
		prepare()
		var s=WorldSimulation.state;var coal_before:=float(s.resource_stockpiles.Coal)
		for day:int in range(9,31):s.elapsed_days=day;Ops.advance(day)
		assert_float(float(s.resource_stockpiles["Packed Aqueous SEC Columns"])).is_equal(0.0)
		assert_float(float(s.resource_stockpiles["SEC PEG Reference Sets"])).is_equal(0.0)
		assert_float(float(s.resource_stockpiles.Coal)).is_less(coal_before)
		assert_float(float(s.resource_stockpiles.get("Distribution-Qualified PEG Batches",0))).is_equal(2.0)
		assert_float(float(s.resource_stockpiles.get("Broad-Range Recovered PEG Batches",0))).is_equal(2.0)
		assert_int(int(SEC.column().remaining_runs)).is_equal(4)
		for id:String in Samples.data().records:
			assert_str(SEC.report(Samples.data().records[id]).status).is_equal("resolved")
		assert_bool(Ops.valid(Ops.data())).is_true()
		s.resource_stockpiles["Alumina Catalyst Supports"]=10.0
		make("sec_distribution_binder",2);make("sec_broad_recovered_binder",3)
		assert_float(float(s.resource_stockpiles["Binder-Grade PEG"])).is_equal(3.0)
		assert_float(float(s.resource_stockpiles["Distribution-Qualified PEG Batches"])).is_equal(0.0)
		assert_float(float(s.resource_stockpiles["Broad-Range Recovered PEG Batches"])).is_equal_approx(.8,.000001)
		make("aqueous_peg_binder",1)
		assert_float(float(s.resource_stockpiles["Aqueous PEG Binder"])).is_equal(1.0))
func test_column_shortage_does_not_consume_sample_and_same_day_cannot_accelerate()->void:
	WorldSimulation.scoped("sec",func()->void:
		prepare(1);var s=WorldSimulation.state
		s.resource_stockpiles["SEC PEG Reference Sets"]=0.0
		s.elapsed_days=9;Ops.advance(9)
		assert_bool(SEC.column().is_empty()).is_true()
		assert_float(float(s.resource_stockpiles["Packed Aqueous SEC Columns"])).is_equal(1.0)
		assert_float(float(s.resource_stockpiles["Sealed SEC PEG Batches"])).is_equal(1.0)
		s.resource_stockpiles["SEC PEG Reference Sets"]=1.0
		s.elapsed_days=10;Ops.advance(10)
		assert_float(float(SEC.column().work)).is_equal(1.0)
		Ops.data().services["sec_column_time"]=100.0
		SEC.advance_pending();SEC.advance_pending()
		assert_float(float(SEC.column().work)).is_equal(1.0)
		assert_float(float(s.resource_stockpiles["Sealed SEC PEG Batches"])).is_equal(1.0)
		assert_bool(Ops.valid(Ops.data())).is_true())

func test_partial_and_completed_sec_runs_survive_full_save_without_second_payment()->void:
	WorldSimulation.scoped("sec",func()->void:
		prepare(1);var s=WorldSimulation.state
		for day:int in range(9,17):s.elapsed_days=day;Ops.advance(day)
		assert_float(float(Samples.data().records["1"].acquisition.work)).is_equal(2.0))
	var slot:="sec_operation_%d"%OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();var restored:=SaveSystem.load_game(slot)
	assert_bool(restored.get("ok",false)).override_failure_message(str(restored)).is_true()
	if restored.get("ok",false):
		WorldSimulation.scoped("sec",func()->void:
			var s=WorldSimulation.state;var before:Dictionary=s.resource_stockpiles.duplicate(true)
			SEC.advance_pending()
			assert_float(float(Samples.data().records["1"].acquisition.work)).is_equal(2.0)
			assert_dict(s.resource_stockpiles).is_equal(before)
			for day:int in range(17,19):s.elapsed_days=day;Ops.advance(day)
			assert_float(float(s.resource_stockpiles.get("Distribution-Qualified PEG Batches",0))).is_equal(1.0))
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();restored=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(restored.get("ok",false)).override_failure_message(str(restored)).is_true()
	if not restored.get("ok",false):return
	WorldSimulation.scoped("sec",func()->void:
		var record:Dictionary=Samples.data().records["1"]
		assert_str(SEC.report(record).status).is_equal("resolved")
		SEC.release(record);SEC.release(record)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Distribution-Qualified PEG Batches"])).is_equal(1.0)
		var damaged:=Ops.data().duplicate(true);damaged.polymer_samples.records["1"].sec_calibration=[]
		assert_bool(Ops.valid(damaged)).is_false()
		damaged=Ops.data().duplicate(true);damaged.sec_column.standards="bad"
		assert_bool(Ops.valid(damaged)).is_false())
func test_column_expiry_during_outage_loses_run_without_free_grade()->void:
	WorldSimulation.scoped("sec",func()->void:
		prepare(1);var s=WorldSimulation.state
		for day:int in range(9,16):s.elapsed_days=day;Ops.advance(day)
		assert_float(float(Samples.data().records["1"].acquisition.work)).is_equal(1.0)
		s.elapsed_days=50;Ops.advance(50)
		assert_str(Samples.data().records["1"].status).is_equal("measurement_failed")
		assert_float(float(s.resource_stockpiles.get("Distribution-Qualified PEG Batches",0))).is_equal(0.0)
		assert_float(float(s.resource_stockpiles["Sealed SEC PEG Batches"])).is_equal(0.0)
		assert_bool(Ops.valid(Ops.data())).is_true())
