extends GdUnitTestSuite
const K=preload("res://scripts/clothing_knowledge.gd")
const C=preload("res://scripts/household_clothing.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const F=preload("res://scripts/civilian_production_planner.gd")
const IDS=["buttonhole_edge_reinforcement","snap_fastener_closures"]
const ITEMS=["closure_sewing_needles","matched_wooden_buttons","reinforced_buttonhole_panels","checked_button_fronts","garment_snap_dies","garment_snap_shells","garment_snap_rings","matched_garment_snaps","gauged_leather_closure_tabs","checked_snap_leather_panels"]
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("closures",1261)
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func prepare(id:String)->void:
	var s=WorldSimulation.state;s.settlement_site_committed=true;s.convoy_traveling=false
	s.population_allocations.Crafting=100;s.population_allocations.Logistics=100;s.population_health=1;s.simulation_metrics.labor_efficiency=1
	for parent:String in [id]+K.METHODS[id].requires_all:learn(parent)
	for field:String in ["cost","inputs"]:
		for item:String in K.METHODS[id][field]:
			if item==C.BONE_RESOURCE:C.data().bone_stock=100.0
			else:s.resource_stockpiles[item]=100.0
func report()->Dictionary:return {"workers":0.0,"inputs":{},"methods":{},"discarded":0.0}
func start(item:String,target:int=1)->Dictionary:
	learn(I.product(item).gate)
	var result:=WorldSimulation.military.start_production_line(item,target)
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	return WorldSimulation.military.equipment_queue.back() if result.get("ok",false) else {}
func finish(item:String,target:int=3)->void:
	var job:=start(item,target)
	if job.is_empty():return
	P.advance(WorldSimulation.military,job,100.0)
	assert_int(int(job.completed)).is_greater(0)
	WorldSimulation.military.cancel_equipment_job(int(job.id))
func stock_external_inputs()->void:
	var outputs:Array=[]
	for item:String in ITEMS:outputs.append(I.product(item).output)
	for item:String in ITEMS:
		for field:String in ["materials","tooling"]:
			for resource:String in I.product(item)[field]:
				if resource not in outputs:WorldSimulation.state.resource_stockpiles[resource]=100.0
	for output:String in outputs:WorldSimulation.state.resource_stockpiles[output]=0.0
func test_exact_predicates_and_fractional_paid_recipe_save_continuation()->void:
	WorldSimulation.scoped("closures",func()->void:
		assert_array(K.METHODS[IDS[0]].requires_all).is_equal(["bone_needle_sewing","garment_pattern_cutting"])
		assert_array(K.METHODS[IDS[1]].requires_all).is_equal(["leather_goods_patterning","elastic_deformation"])
		for id:String in IDS:assert_array(K.METHODS[id].requires_any).is_empty()
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		for item:String in ITEMS:
			var spec:=I.product(item)
			for field:String in ["materials","tooling"]:
				for resource:String in spec[field]:WorldSimulation.state.resource_stockpiles[resource]=100.0
			WorldSimulation.state.resource_stockpiles[spec.output]=0.0
			var job:=start(item)
			if job.is_empty():return
			var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
			P.advance(WorldSimulation.military,job,float(spec.days)/2.0)
			assert_int(int(job.completed)).is_equal(0)
			var saved:Dictionary=bytes_to_var(var_to_bytes(job));assert_str(P.validate_saved({"equipment_queue":[saved]})).is_empty()
			P.advance(WorldSimulation.military,saved,float(spec.days)/2.0)
			assert_int(int(saved.completed)).is_equal(1)
			for resource:String in spec.materials:assert_float(float(before[resource])-float(WorldSimulation.state.resource_stockpiles[resource])).is_equal_approx(float(spec.materials[resource]),.000001)
			before=WorldSimulation.state.resource_stockpiles.duplicate(true);P.advance(WorldSimulation.military,saved,100)
			assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
			WorldSimulation.military.cancel_equipment_job(int(job.id)))
func test_manufactured_buttons_reinforced_openings_and_checked_fronts_become_garments()->void:
	WorldSimulation.scoped("closures",func()->void:
		prepare(IDS[0]);stock_external_inputs()
		for item:String in ITEMS.slice(0,4):finish(item)
		assert_bool(C.install(IDS[0]).get("ok",false)).is_true()
		var fronts:=C.available("Button-Closed Garment Fronts");var r:=report();C.operate(IDS[0],1,100,0,r)
		assert_float(C.count()).is_greater(0);assert_str(C.data().lots[0].kind).is_equal("fit")
		assert_float(C.available("Button-Closed Garment Fronts")).is_less(fronts)
		assert_float(float(C.coverage(100,0).cold)).is_equal_approx(C.count()*.42/100,.000001)
		assert_float(float(r.workers)).is_less_equal(1.0))
func test_manufactured_springs_shells_supported_tabs_and_checked_snap_panels_feed_leather()->void:
	WorldSimulation.scoped("closures",func()->void:
		prepare(IDS[1]);stock_external_inputs()
		for item:String in ITEMS.slice(4):finish(item,6 if item=="garment_snap_dies" else 3)
		assert_bool(C.install(IDS[1]).get("ok",false)).is_true()
		var panels:=C.available("Snap-Fastened Leather Panels");var r:=report();C.operate(IDS[1],1,100,0,r)
		assert_float(C.count()).is_greater(0);assert_str(C.data().lots[0].kind).is_equal("leather")
		assert_float(C.available("Snap-Fastened Leather Panels")).is_less(panels)
		assert_float(float(C.coverage(100,0).cold)).is_equal_approx(C.count()*.32/100,.000001)
		assert_bool(C.compatible_service("wash",C.data().lots[0])).is_false())
func test_unchecked_parts_and_missing_spring_cannot_substitute_for_finished_closure()->void:
	WorldSimulation.scoped("closures",func()->void:
		for id:String in IDS:
			prepare(id);C.install(id)
			var output:String="Button-Closed Garment Fronts" if id==IDS[0] else "Snap-Fastened Leather Panels"
			WorldSimulation.state.resource_stockpiles[output]=0.0
			for raw:String in ["Reinforced Buttonhole Panels","Matched Wooden Buttons","Garment Snap Shell Sets","Flexible Leather"]:WorldSimulation.state.resource_stockpiles[raw]=100.0
			C.operate(id,10,100,0,report());assert_float(C.count()).is_equal(0.0)
		stock_external_inputs();finish("garment_snap_dies");finish("garment_snap_shells")
		var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		var blocked:=WorldSimulation.military.start_production_line("matched_garment_snaps",1)
		assert_bool(blocked.has("error")).is_true();assert_str(String(blocked.get("error",""))).contains("Garment Snap Spring Rings")
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before);assert_float(C.available("Matched Garment Snap Sets")).is_equal(0.0))
func test_paid_installation_known_prerequisites_and_daily_work_do_not_repeat()->void:
	WorldSimulation.scoped("closures",func()->void:
		prepare(IDS[0]);WorldSimulation.state.known_discoveries.erase("garment_pattern_cutting")
		assert_bool(C.quote(IDS[0]).has("error")).is_true();learn("garment_pattern_cutting")
		var needles:=C.available("Hand Sewing Needle Sets")
		WorldSimulation.state.elapsed_days=1;var result:=C.advance(5,100,false)
		assert_int(int(C.data().tools.get(IDS[0],0))).is_equal(1)
		assert_float(C.available("Hand Sewing Needle Sets")).is_equal(needles-1)
		assert_float(float(result.workers)).is_less_equal(1.0);assert_float(C.count()).is_greater(0)
		var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true);var ledger:=C.data().duplicate(true)
		C.advance(5,100,false);assert_dict(C.data()).is_equal(ledger);assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before))
func test_planner_orders_missing_checked_front_and_controller_supplies_daily_consumer()->void:
	WorldSimulation.scoped("closures",func()->void:
		prepare(IDS[0]);stock_external_inputs()
		for item:String in ITEMS.slice(0,3):finish(item)
		var order:=F.clothing_recommendation();assert_str(String(order.get("item",""))).is_equal("checked_button_fronts")
		preload("res://scripts/civilization_controller.gd").production_order("closures",order)
		assert_int(WorldSimulation.military.equipment_queue.size()).is_equal(1)
		if WorldSimulation.military.equipment_queue.is_empty():return
		P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue[0],100)
		var fronts:=C.available("Button-Closed Garment Fronts");assert_float(fronts).is_greater(0)
		WorldSimulation.state.elapsed_days=1;C.advance(5,100,false)
		assert_float(C.count()).is_greater(0);assert_float(C.available("Button-Closed Garment Fronts")).is_less(fronts))
func test_full_save_preserves_partial_closure_work_and_actor_garments()->void:
	WorldSimulation.scoped("closures",func()->void:
		prepare(IDS[0]);stock_external_inputs()
		for item:String in ITEMS.slice(0,3):finish(item)
		var job:=start("checked_button_fronts");P.advance(WorldSimulation.military,job,.75);C.add("fit",2,.6))
	WorldSimulation.create_actor("other_closures",1262)
	WorldSimulation.scoped("other_closures",func()->void:C.add("leather",3,.8))
	var slot:="garment_closures_%d"%OS.get_process_id();assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();var result:=SaveSystem.load_game(slot);DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	if not result.get("ok",false):return
	WorldSimulation.scoped("closures",func()->void:
		assert_float(C.count()).is_equal(2.0)
		var job:Dictionary=WorldSimulation.military.equipment_queue.back();P.advance(WorldSimulation.military,job,.75)
		assert_int(int(job.completed)).is_equal(1);assert_float(C.available("Button-Closed Garment Fronts")).is_equal(1.0)
		var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true);P.advance(WorldSimulation.military,job,100)
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before))
	WorldSimulation.scoped("other_closures",func()->void:assert_float(C.count()).is_equal(3.0);assert_str(C.data().lots[0].kind).is_equal("leather"))
