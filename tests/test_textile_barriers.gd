extends GdUnitTestSuite
const K=preload("res://scripts/clothing_knowledge.gd")
const C=preload("res://scripts/household_clothing.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const F=preload("res://scripts/civilian_production_planner.gd")
const B=preload("res://scripts/textile_barriers.gd")
const IDS=["textile_waterproofing","garment_seam_sealing"]
const ITEMS=["textile_coating_machine","textile_coating_grade","polyethylene_coated_textile","stitched_rain_shell_panels","textile_heat_sealing_tools","compatible_polyethylene_seam_tape"]
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
	s.technology_operations.last_day=int(s.elapsed_days);s.technology_operations.services["electricity"]=100.0
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
func shell_setup()->void:
	for id:String in IDS:
		prepare(id);assert_bool(C.install(id).get("ok",false)).is_true()
	WorldSimulation.state.resource_stockpiles["Stitched Rain-Shell Panels"]=0.0
	WorldSimulation.state.resource_stockpiles["Polyethylene-Coated Textile"]=100.0
	WorldSimulation.state.resource_stockpiles.Freshwater=100.0
	WorldSimulation.state.resource_stockpiles["Spun Yarn"]=100.0
	C.add("rain_shell",1)
func one_day(day:int,id:String)->void:
	WorldSimulation.state.elapsed_days=day
	WorldSimulation.state.technology_operations.last_day=day
	WorldSimulation.state.technology_operations.services["electricity"]=100.0
	C.operate(id,10,1,day,report())
func qualify_surface()->void:
	for day:int in range(1,4):one_day(day,IDS[0])
func test_authored_predicates_and_six_paid_recipe_continuations()->void:
	WorldSimulation.scoped("closures",func()->void:
		assert_array(K.METHODS[IDS[0]].requires_all).is_equal(["plain_weaving","adhesive_bond_design"])
		assert_array(K.METHODS[IDS[1]].requires_all).is_equal(["textile_waterproofing","sewing_machine_mechanisms"])
		for item:String in ITEMS:
			prepare(IDS[0]);prepare(IDS[1]);var spec:=I.product(item)
			for field:String in ["materials","tooling"]:
				for resource:String in spec[field]:WorldSimulation.state.resource_stockpiles[resource]=100.0
			WorldSimulation.state.resource_stockpiles[spec.output]=0.0
			var job:=start(item)
			if job.is_empty():return
			var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
			P.advance(WorldSimulation.military,job,float(spec.days)/2)
			assert_int(int(job.completed)).is_equal(0)
			var saved:Dictionary=bytes_to_var(var_to_bytes(job));assert_str(P.validate_saved({"equipment_queue":[saved]})).is_empty()
			P.advance(WorldSimulation.military,saved,float(spec.days)/2);assert_int(int(saved.completed)).is_equal(1)
			for resource:String in spec.materials:assert_float(float(before[resource])-C.available(resource)).is_equal_approx(float(spec.materials[resource]),.000001)
			before=WorldSimulation.state.resource_stockpiles.duplicate(true);P.advance(WorldSimulation.military,saved,100)
			assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
			WorldSimulation.military.cancel_equipment_job(int(job.id)))
func test_real_coating_chain_creates_shell_but_only_three_paid_days_qualify_it()->void:
	WorldSimulation.scoped("closures",func()->void:
		prepare(IDS[0]);stock_external_inputs()
		for item:String in ITEMS.slice(0,4):finish(item,8)
		finish("polyethylene_coated_textile",1)
		assert_bool(C.install(IDS[0]).get("ok",false)).is_true()
		C.operate(IDS[0],1,1,0,report())
		assert_float(C.count()).is_greater(0)
		assert_bool(B.surface_ready(C.data().lots[0])).is_false()
		WorldSimulation.state.resource_stockpiles["Stitched Rain-Shell Panels"]=0.0
		var water:=C.available("Freshwater")
		for day:int in range(1,4):
			one_day(day,IDS[0]);var before:=C.data().duplicate(true);C.operate(IDS[0],100,1,day,report());assert_dict(C.data()).is_equal(before)
		assert_bool(B.surface_ready(C.data().lots[0])).is_true()
		assert_float(C.available("Freshwater")).is_less(water)
		assert_float(float(C.coverage(1,3).storm)).is_greater(.3)
		assert_float(float(C.coverage(1,3).cold)).is_less(.19))
func test_missing_water_work_or_finished_panel_cannot_create_qualification()->void:
	WorldSimulation.scoped("closures",func()->void:
		shell_setup();WorldSimulation.state.resource_stockpiles.Freshwater=0.0
		C.operate(IDS[0],100,1,1,report());assert_array(C.data().lots[0].barrier.surface_loss).is_empty()
		WorldSimulation.state.resource_stockpiles.Freshwater=100.0
		C.operate(IDS[0],0,1,2,report());assert_array(C.data().lots[0].barrier.surface_loss).is_empty()
		C.data().lots=[];C.operate(IDS[0],100,1,3,report());assert_float(C.count()).is_equal(0.0))
func test_sealing_needs_qualified_shell_tape_power_and_later_leak_checks()->void:
	WorldSimulation.scoped("closures",func()->void:
		shell_setup();one_day(0,IDS[1]);assert_bool(C.data().lots[0].barrier.sealed).is_false()
		qualify_surface();var before:Dictionary=C.data().duplicate(true)
		WorldSimulation.state.technology_operations.services["electricity"]=0.0
		C.operate(IDS[1],100,1,4,report());assert_dict(C.data()).is_equal(before)
		WorldSimulation.state.technology_operations.services["electricity"]=100
		WorldSimulation.state.resource_stockpiles["Polyethylene Seam Tape"]=0.0
		C.operate(IDS[1],100,1,4,report());assert_dict(C.data()).is_equal(before)
		WorldSimulation.state.resource_stockpiles["Polyethylene Seam Tape"]=100.0
		one_day(4,IDS[1]);assert_bool(C.data().lots[0].barrier.sealed).is_true();assert_bool(B.seam_ready(C.data().lots[0])).is_false()
		for day:int in range(5,8):one_day(day,IDS[1])
		assert_bool(B.seam_ready(C.data().lots[0])).is_true();assert_float(float(C.coverage(1,7).storm)).is_greater(.45)
		assert_float(C.available("Polyethylene Seam Tape")).is_equal_approx(100.0-.066,.000001))
func test_insufficient_bond_fails_and_excess_heat_damages_actual_shell()->void:
	WorldSimulation.scoped("closures",func()->void:
		shell_setup();qualify_surface();C.data().sealing_profile={"heat":.5,"pressure":1.0}
		one_day(4,IDS[1]);for day:int in range(5,8):one_day(day,IDS[1])
		assert_bool(B.seam_ready(C.data().lots[0])).is_false();assert_float(float(C.data().lots[0].barrier.seam_loss[0])).is_greater(.08)
		C.data().sealing_profile={"heat":1.5,"pressure":1.0};var condition:=float(C.data().lots[0].condition)
		one_day(8,IDS[1]);assert_float(float(C.data().lots[0].condition)).is_equal_approx(condition-.2,.000001)
		assert_bool(B.seam_ready(C.data().lots[0])).is_false();assert_bool(C.valid(C.data())).is_true())
func test_partial_work_preserves_untested_remainder_and_finite_garment_count()->void:
	WorldSimulation.scoped("closures",func()->void:
		shell_setup();var before:=C.count()
		C.operate(IDS[0],.2,1,1,report());assert_float(C.count()).is_equal_approx(before,.000001)
		assert_int(C.data().lots.size()).is_equal(2)
		var observed:=0.0
		for lot:Dictionary in C.data().lots:
			if lot.barrier.surface_loss.size()==1:observed+=float(lot.amount)
		assert_float(observed).is_equal_approx(.3,.000001);assert_bool(C.valid(C.data())).is_true())
func test_washing_and_repair_remove_qualification_and_plain_garments_stay_unchanged()->void:
	WorldSimulation.scoped("closures",func()->void:
		shell_setup();qualify_surface();C.data().lots[0].soil=.6
		var wash:="textile_laundering_practice";prepare(wash);assert_bool(C.install(wash).get("ok",false)).is_true()
		C.operate(wash,100,1,4,report());assert_bool(B.surface_ready(C.data().lots[0])).is_false()
		C.data().lots[0].ready=0;C.data().lots[0].condition=.4
		var cloth:=C.available("Polyethylene-Coated Textile");one_day(5,IDS[0]);assert_float(C.available("Polyethylene-Coated Textile")).is_less(cloth)
		assert_bool(B.surface_ready(C.data().lots[0])).is_false()
		C.data().lots=[];C.add("fit",1);var plain:Array=C.data().lots.duplicate(true)
		one_day(6,IDS[1]);assert_array(C.data().lots).is_equal(plain))
func test_planner_seam_tape_demand_and_power_follow_actual_pending_shell()->void:
	WorldSimulation.scoped("closures",func()->void:
		shell_setup();qualify_surface()
		assert_float(C.power_demand()).is_greater(0)
		var needs:=B.demand(C,IDS[1],1,3);assert_float(float(needs["Polyethylene Seam Tape"])).is_equal(.06)
		WorldSimulation.state.resource_stockpiles["Polyethylene Seam Tape"]=0
		WorldSimulation.state.resource_stockpiles["Textile-Coating Polyethylene"]=100
		WorldSimulation.state.resource_stockpiles["Textile Coating Machines"]=100
		WorldSimulation.state.resource_stockpiles["Gauge Blocks"]=100
		var order:=F.clothing_recommendation();assert_str(String(order.get("item",""))).is_equal("compatible_polyethylene_seam_tape")
		assert_float(C.power_demand()).is_equal(0.0))
func test_full_save_resumes_pending_surface_checks_and_rejects_invalid_metadata()->void:
	WorldSimulation.scoped("closures",func()->void:shell_setup();one_day(1,IDS[0]))
	WorldSimulation.create_actor("dry_clothes",1262)
	WorldSimulation.scoped("dry_clothes",func()->void:C.add("fit",2))
	var slot:="barrier_%d_%d"%[OS.get_process_id(),Time.get_ticks_usec()]
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true();WorldSimulation.clear()
	var loaded:=SaveSystem.load_game(slot);DirAccess.remove_absolute(SaveSystem.slot_path(slot));assert_bool(loaded.get("ok",false)).override_failure_message(str(loaded)).is_true()
	if not loaded.get("ok",false):return
	WorldSimulation.scoped("closures",func()->void:
		assert_int(C.data().lots[0].barrier.surface_loss.size()).is_equal(1)
		var before:=C.data().duplicate(true);one_day(1,IDS[0]);assert_dict(C.data()).is_equal(before)
		one_day(2,IDS[0]);one_day(3,IDS[0]);assert_bool(B.surface_ready(C.data().lots[0])).is_true()
		var corrupt:=C.data().duplicate(true);corrupt.lots[0].barrier.surface_loss=[NAN];assert_bool(C.valid(corrupt)).is_false())
	WorldSimulation.scoped("dry_clothes",func()->void:assert_float(C.count()).is_equal(2.0);assert_str(C.data().lots[0].kind).is_equal("fit"))
func test_daily_owner_shares_finite_logistics_power_and_does_not_repeat()->void:
	WorldSimulation.scoped("closures",func()->void:
		shell_setup();qualify_surface()
		WorldSimulation.state.elapsed_days=4
		WorldSimulation.state.technology_operations.last_day=4
		WorldSimulation.state.technology_operations.services["electricity"]=1.0
		var result:=C.advance(1,1,false)
		assert_float(float(result.workers)).is_equal_approx(.2,.000001)
		assert_float(float(WorldSimulation.state.technology_operations.services["electricity"])).is_equal_approx(.96,.000001)
		var before:=C.data().duplicate(true);var stock:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		C.advance(1,1,false);assert_dict(C.data()).is_equal(before);assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(stock))
func test_full_garment_ledger_waits_without_charging_or_losing_sample()->void:
	WorldSimulation.scoped("closures",func()->void:
		shell_setup()
		for index:int in range(C.LIMIT-1):C.add("fit",1,1,0,false,false,100+index)
		assert_int(C.data().lots.size()).is_equal(C.LIMIT)
		var before:=C.data().duplicate(true);var stock:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		C.operate(IDS[0],100,1,1,report());assert_dict(C.data()).is_equal(before);assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(stock)
		C.data().lots.pop_back();C.operate(IDS[0],100,1,2,report())
		var observed:=0.0
		for lot:Dictionary in C.data().lots:
			if lot.kind=="rain_shell" and lot.barrier.surface_loss.size()==1:observed+=float(lot.amount)
		assert_float(observed).is_equal(1.0))

func test_failed_surface_gets_paid_patch_then_fresh_observations()->void:
	WorldSimulation.scoped("closures",func()->void:
		shell_setup();C.data().lots[0].condition=.65
		qualify_surface()
		assert_bool(B.surface_ready(C.data().lots[0])).is_false()
		assert_bool(B.needs_patch(C.data().lots[0])).is_true()
		assert_bool(B.demand(C,IDS[0],1,4).has("Spun Yarn")).is_true()
		var cloth:=C.available("Polyethylene-Coated Textile")
		one_day(4,IDS[0])
		assert_float(cloth-C.available("Polyethylene-Coated Textile")).is_equal_approx(.12,.000001)
		assert_array(C.data().lots[0].barrier.surface_loss).is_empty()
		assert_bool(B.surface_ready(C.data().lots[0])).is_false()
		for day:int in range(5,8):one_day(day,IDS[0])
		assert_bool(B.surface_ready(C.data().lots[0])).is_true())

func test_clothing_panel_handles_every_garment_and_reports_actual_checks()->void:
	WorldSimulation.scoped("closures",func()->void:
		shell_setup();qualify_surface()
		C.add("tied",1);C.add("quilt",1)
		var panel=auto_free(preload("res://scripts/hud/clothing_panel.gd").new())
		panel.subject=IDS[1];add_child(panel)
		assert_str(panel.details.text).contains("tied garments")
		assert_str(panel.details.text).contains("quilted garments")
		assert_str(panel.details.text).contains("surface qualified; surface 3/3, seam 0/3")
		assert_str(panel.details.text).contains("electricity per processed unit")
		one_day(4,IDS[1]);for day:int in range(5,8):one_day(day,IDS[1])
		panel.refresh();assert_str(panel.details.text).contains("seams qualified"))
