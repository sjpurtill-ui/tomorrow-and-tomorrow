extends GdUnitTestSuite
const K=preload("res://scripts/clothing_knowledge.gd")
const C=preload("res://scripts/household_clothing.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const F=preload("res://scripts/civilian_production_planner.gd")
const IDS=["textile_braiding","quilted_layer_assembly"]
const ITEMS=["braided_garment_cords","plant_fiber_quilt_batts"]
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("layers",1210)
func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func prepare(id:String)->void:
	var s=WorldSimulation.state;s.settlement_site_committed=true;s.convoy_traveling=false
	s.population_allocations.Crafting=100;s.population_allocations.Logistics=100;s.population_health=1;s.simulation_metrics.labor_efficiency=1
	for method:String in [id]+K.METHODS[id].requires_all:learn(method)
	for field:String in ["cost","inputs"]:
		for r:String in K.METHODS[id][field]:
			if r==C.BONE_RESOURCE:C.data().bone_stock=100.0
			else:s.resource_stockpiles[r]=100.0
func report()->Dictionary:return {"workers":0.0,"inputs":{},"methods":{},"discarded":0.0}
func start(item:String,target:int=1)->Dictionary:
	var spec:=I.product(item);learn(spec.gate)
	for field:String in ["materials","tooling"]:
		for r:String in spec[field]:WorldSimulation.state.resource_stockpiles[r]=100.0
	WorldSimulation.state.resource_stockpiles[spec.output]=0.0
	var result:=WorldSimulation.military.start_production_line(item,target)
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	return WorldSimulation.military.equipment_queue.back() if result.get("ok",false) else {}
func test_original_predicates_and_two_fractional_production_routes()->void:
	WorldSimulation.scoped("layers",func()->void:
		assert_array(K.METHODS.textile_braiding.requires_all).is_equal(["cordage","yarn_tension_control"])
		assert_array(K.METHODS.quilted_layer_assembly.requires_all).is_equal(["bone_needle_sewing","layered_clothing_design"])
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		for n:int in range(2):
			prepare(IDS[n]);var spec:=I.product(ITEMS[n]);var job:=start(ITEMS[n]);var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
			if job.is_empty():return
			P.advance(WorldSimulation.military,job,float(spec.days)/2);assert_int(int(job.completed)).is_equal(0)
			var saved:Dictionary=bytes_to_var(var_to_bytes(job));assert_str(P.validate_saved({"equipment_queue":[saved]})).is_empty()
			P.advance(WorldSimulation.military,saved,float(spec.days)/2);assert_int(int(saved.completed)).is_equal(1)
			for r:String in spec.materials:assert_float(float(before[r])-float(WorldSimulation.state.resource_stockpiles[r])).is_equal_approx(float(spec.materials[r]),.000001)
			before=WorldSimulation.state.resource_stockpiles.duplicate(true);P.advance(WorldSimulation.military,saved,100);assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
			WorldSimulation.military.cancel_equipment_job(int(job.id)))
func test_paid_braids_fastened_into_actual_wraps_not_substituted_by_rope()->void:
	WorldSimulation.scoped("layers",func()->void:
		prepare(IDS[0]);var job:=start(ITEMS[0]);P.advance(WorldSimulation.military,job,2)
		assert_bool(C.install(IDS[0]).get("ok",false)).is_true()
		var r:=report();C.operate(IDS[0],1,100,0,r)
		assert_float(C.count()).is_equal(2.5);assert_float(float(r.inputs["Braided Garment Cords"])).is_equal(.375)
		assert_float(float(C.coverage(100,0).cold)).is_equal_approx(2.5*.25/100,.000001)
		WorldSimulation.state.resource_stockpiles["Braided Garment Cords"]=0.0;WorldSimulation.state.resource_stockpiles["Rope Coils"]=100.0
		C.operate(IDS[0],10,100,1,report());assert_float(C.count()).is_equal(2.5))
func test_quilting_needs_real_filling_and_preserves_figured_cloth_identity()->void:
	WorldSimulation.scoped("layers",func()->void:
		prepare(IDS[1]);var job:=start(ITEMS[1]);P.advance(WorldSimulation.military,job,2.5)
		assert_bool(C.install(IDS[1]).get("ok",false)).is_true()
		WorldSimulation.state.resource_stockpiles["Plant-Fiber Quilt Batts"]=0.0
		C.operate(IDS[1],100,100,0,report());assert_float(C.count()).is_equal(0.0)
		WorldSimulation.state.resource_stockpiles["Plant-Fiber Quilt Batts"]=1.0;WorldSimulation.state.resource_stockpiles["Figured Cloth"]=100.0
		var r:=report();C.operate(IDS[1],1,100,0,r)
		assert_float(C.count()).is_equal(.8);assert_float(C.figured_count()).is_equal(.8)
		assert_float(float(r.inputs["Plant-Fiber Quilt Batts"])).is_equal_approx(.52,.000001)
		assert_float(float(r.inputs["Figured Cloth"])).is_equal_approx(.88,.000001)
		assert_float(C.available("Woven Cloth")).is_equal(100.0)
		var cold:=float(C.coverage(100,0).cold);C.data().lots[0].condition=.5
		assert_float(float(C.coverage(100,0).cold)).is_equal_approx(cold*.5,.000001))
func test_quilt_repair_requires_replacement_filling_and_adds_no_garments()->void:
	WorldSimulation.scoped("layers",func()->void:
		prepare(IDS[1]);C.install(IDS[1]);C.add("quilt",10,.4)
		learn("textile_repair_methods");C.data().tools.textile_repair_methods=1
		C.operate("textile_repair_methods",10,9,0,report());assert_float(float(C.data().lots[0].condition)).is_equal(.4)
		WorldSimulation.state.resource_stockpiles["Plant-Fiber Quilt Batts"]=0.0
		C.operate(IDS[1],10,9,0,report());assert_float(float(C.data().lots[0].condition)).is_equal(.4)
		WorldSimulation.state.resource_stockpiles["Plant-Fiber Quilt Batts"]=1.0
		var r:=report();C.operate(IDS[1],1,9,0,r)
		assert_float(C.count()).is_equal(10.0);assert_float(float(C.data().lots[0].condition)).is_greater(.4)
		assert_float(float(r.inputs["Plant-Fiber Quilt Batts"])).is_equal_approx(.064,.000001)
		assert_float(float(r.workers)).is_equal(1.0))
func test_daily_clothing_owner_installs_pays_shared_budget_and_cannot_repeat()->void:
	WorldSimulation.scoped("layers",func()->void:
		prepare(IDS[1]);C.data().tools.clear();WorldSimulation.state.elapsed_days=1
		var first:=C.advance(5,100,false);assert_int(int(C.data().tools[IDS[1]])).is_equal(1)
		assert_float(float(first.workers)).is_less_equal(1.0);assert_float(C.count()).is_greater(0)
		var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true);var lots:Dictionary=C.data().duplicate(true)
		C.advance(5,100,false);assert_dict(C.data()).is_equal(lots);assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before))
func test_planner_requests_actual_filling_for_creation_and_existing_repairs()->void:
	WorldSimulation.scoped("layers",func()->void:
		prepare(IDS[1]);WorldSimulation.state.known_discoveries.clear();learn(IDS[1]);learn("bone_needle_sewing");learn("layered_clothing_design")
		WorldSimulation.state.resource_stockpiles["Plant-Fiber Quilt Batts"]=0.0;WorldSimulation.state.resource_stockpiles["Prepared Fibers"]=100.0;WorldSimulation.state.resource_stockpiles["Stone"]=100.0
		var order:=F.clothing_recommendation();assert_str(String(order.get("item",""))).is_equal(ITEMS[1])
		C.add("quilt",WorldSimulation.settlements.primary_population_exact()*1.1,.4)
		order=F.clothing_recommendation();assert_str(String(order.get("item",""))).is_equal(ITEMS[1]))
func test_full_save_continues_partial_filling_and_keeps_actor_lots_separate()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.scoped("layers",func()->void:
		prepare(IDS[1]);var job:=start(ITEMS[1]);P.advance(WorldSimulation.military,job,1.25);C.add("quilt",2,.6,0,false,false,0,"figured"))
	WorldSimulation.create_actor("other_layers",1211)
	WorldSimulation.scoped("other_layers",func()->void:C.add("tied",3,.9))
	var slot:="braided_quilted_%d"%OS.get_process_id();assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();var result:=SaveSystem.load_game(slot);DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	if not result.get("ok",false):return
	WorldSimulation.scoped("layers",func()->void:
		assert_float(C.count()).is_equal(2.0);assert_float(C.figured_count()).is_equal(2.0)
		var job:Dictionary=WorldSimulation.military.equipment_queue.back();P.advance(WorldSimulation.military,job,1.25)
		assert_int(int(job.completed)).is_equal(1);assert_float(C.available("Plant-Fiber Quilt Batts")).is_equal(1.0))
	WorldSimulation.scoped("other_layers",func()->void:assert_float(C.count()).is_equal(3.0);assert_str(String(C.data().lots[0].kind)).is_equal("tied"))
func test_controller_orders_filling_and_daily_clothing_consumes_manufactured_stock()->void:
	WorldSimulation.scoped("layers",func()->void:
		prepare(IDS[1]);WorldSimulation.state.resource_stockpiles["Plant-Fiber Quilt Batts"]=0.0
		WorldSimulation.state.resource_stockpiles["Prepared Fibers"]=100.0;WorldSimulation.state.resource_stockpiles["Stone"]=100.0
		var order:=F.clothing_recommendation();assert_str(String(order.get("item",""))).is_equal(ITEMS[1])
		preload("res://scripts/civilization_controller.gd").production_order("layers",order)
		assert_int(WorldSimulation.military.equipment_queue.size()).is_equal(1)
		if WorldSimulation.military.equipment_queue.is_empty():return
		P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue[0],100)
		var filling:=C.available("Plant-Fiber Quilt Batts");assert_float(filling).is_greater(0)
		assert_float(C.available("Prepared Fibers")).is_less(100)
		WorldSimulation.state.elapsed_days=1;C.advance(5,100,false)
		assert_float(C.count()).is_greater(0);assert_float(C.available("Plant-Fiber Quilt Batts")).is_less(filling))
