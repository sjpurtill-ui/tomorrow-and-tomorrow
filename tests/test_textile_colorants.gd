extends GdUnitTestSuite
const K=preload("res://scripts/clothing_knowledge.gd")
const CK=preload("res://scripts/colorant_knowledge.gd")
const C=preload("res://scripts/household_clothing.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const F=preload("res://scripts/civilian_production_planner.gd")
const IDS=["mineral_pigment_preparation", "textile_dye_extraction", "textile_dye_fixation", "resist_dye_patterning", "textile_printing", "textile_calendering"]
const ITEMS=["ochre_levigation", "fine_ochre_pigment", "earth_pigment_ink", "ochre_relief_sheets", "textile_tannin_colorant", "scoured_plant_cloth", "textile_ferrous_mordant", "tannin_mordanted_cloth", "checked_tannin_cloth", "bound_resist_cloth", "resist_tannin_bath", "checked_resist_cloth", "textile_printing_blocks", "tannin_printing_paste", "printed_tannin_cloth", "checked_printed_cloth", "textile_finishing_rolls", "calendered_plant_cloth"]
const EXPECTED={"mineral_pigment_preparation": {"requires_all": ["stone_sorting", "clay_testing"], "requires_any": []}, "textile_dye_extraction": {"requires_all": ["fiber_grading"], "requires_any": [["herbal_classification", "mineral_pigment_preparation"]]}, "textile_dye_fixation": {"requires_all": ["textile_dye_extraction", "experimental_controls"], "requires_any": []}, "resist_dye_patterning": {"requires_all": ["textile_dye_fixation", "cordage"], "requires_any": []}, "textile_printing": {"requires_all": ["textile_dye_fixation", "printing_process"], "requires_any": []}, "textile_calendering": {"requires_all": ["plain_weaving", "mechanical_screw_presses"], "requires_any": []}}
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("colorants",641)
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func ready()->void:
	var state=WorldSimulation.state;state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
	state.technology_operations.last_day=int(state.elapsed_days);state.technology_operations.services["electricity"]=100.0
	for id:String in IDS:
		learn(id)
		for parent:String in EXPECTED[id].requires_all:learn(parent)
	learn("herbal_classification")
func equipment(id:String)->void:
	learn(id)
	for parent:String in K.METHODS[id].requires_all:learn(parent)
	for field:String in ["cost","inputs"]:
		for item:String in K.METHODS[id][field]:
			if item==C.BONE_RESOURCE:C.data().bone_stock=100.0
			else:WorldSimulation.state.resource_stockpiles[item]=100.0
	assert_bool(C.install(id).get("ok",false)).is_true()
func report()->Dictionary:return {"workers":0.0,"inputs":{},"methods":{},"discarded":0.0}
func start(item:String,target:int=1)->Dictionary:
	learn(I.product(item).gate)
	var result:=WorldSimulation.military.start_production_line(item,target)
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	return WorldSimulation.military.equipment_queue.back() if result.get("ok",false) else {}
func finish(item:String,target:int=4)->void:
	var job:=start(item,target)
	if job.is_empty():return
	P.advance(WorldSimulation.military,job,100.0)
	assert_int(int(job.completed)).is_greater(0)
	WorldSimulation.military.cancel_equipment_job(int(job.id))
func external_stock()->void:
	var outputs:Array=[]
	for item:String in ITEMS:outputs.append(I.product(item).output)
	for item:String in ITEMS:
		for field:String in ["materials","tooling"]:
			for resource:String in I.product(item)[field]:
				if resource not in outputs:WorldSimulation.state.resource_stockpiles[resource]=100.0
	for output:String in outputs:WorldSimulation.state.resource_stockpiles[output]=0.0
func test_six_exact_authored_predicates_and_eighteen_paid_continuations()->void:
	WorldSimulation.scoped("colorants",func()->void:
		ready()
		var entries:Dictionary={}
		for r:Dictionary in CK.entries():entries[r.id]=r
		for id:String in IDS:
			var r:Dictionary=K.METHODS[id] if K.METHODS.has(id) else entries[id]
			assert_array(r.requires_all).is_equal(EXPECTED[id].requires_all)
			assert_array(r.requires_any).is_equal(EXPECTED[id].requires_any)
		for item:String in ITEMS:
			var spec:=I.product(item)
			for field:String in ["materials","tooling"]:
				for resource:String in spec[field]:WorldSimulation.state.resource_stockpiles[resource]=100.0
			WorldSimulation.state.resource_stockpiles[spec.output]=0.0
			var job:=start(item)
			if job.is_empty():return
			var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
			P.advance(WorldSimulation.military,job,float(spec.days)/2)
			assert_int(int(job.completed)).is_equal(0)
			var saved:Dictionary=bytes_to_var(var_to_bytes(job));assert_str(P.validate_saved({"equipment_queue":[saved]})).is_empty()
			P.advance(WorldSimulation.military,saved,float(spec.days)/2)
			assert_int(int(saved.completed)).is_equal(1)
			for resource:String in spec.materials:assert_float(float(before[resource])-C.available(resource)).is_equal_approx(float(spec.materials[resource]),.000001)
			before=WorldSimulation.state.resource_stockpiles.duplicate(true);P.advance(WorldSimulation.military,saved,100)
			assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
			WorldSimulation.military.cancel_equipment_job(int(job.id)))
func test_actual_colorant_and_pigment_chains_reach_garment_and_printed_sheets()->void:
	WorldSimulation.scoped("colorants",func()->void:
		ready();external_stock();WorldSimulation.state.resource_stockpiles["Spun Yarn"]=100.0
		for item:String in ITEMS.slice(0,9):finish(item,8)
		assert_float(C.available("Printed Sheets")).is_greater(0)
		WorldSimulation.state.resource_stockpiles["Hand Sewing Needle Sets"]=10
		assert_bool(C.install("textile_dye_fixation").get("ok",false)).is_true()
		var before:=C.available("Fixed Tannin Cloth")
		C.operate("textile_dye_fixation",1,1,0,report())
		assert_float(C.count()).is_greater(0)
		assert_float(C.available("Fixed Tannin Cloth")).is_less(before)
		assert_str(C.data().lots[0].fabric).is_equal("tannin"))
func test_finished_cloth_identity_is_required_without_protection_bonus()->void:
	WorldSimulation.scoped("colorants",func()->void:
		ready()
		for id:String in IDS.slice(2):
			equipment(id);C.data().lots=[]
			var inputs:Dictionary=K.METHODS[id].inputs
			var cloth:=String(inputs.keys()[0]);WorldSimulation.state.resource_stockpiles[cloth]=0.0
			C.operate(id,1,1,0,report());assert_float(C.count()).is_equal(0.0)
			WorldSimulation.state.resource_stockpiles[cloth]=10
			C.operate(id,1,1,0,report())
			var amount:=C.count();var actual:=C.coverage(1,0)
			assert_str(C.data().lots[0].fabric).is_equal(K.METHODS[id].fabric)
			assert_bool(C.valid(C.data())).is_true()
			C.data().lots=[];C.add("fit",amount)
			assert_dict(C.coverage(1,0)).is_equal(actual))
func test_weighted_finish_merge_and_paid_washing_preserve_pattern_but_fade()->void:
	WorldSimulation.scoped("colorants",func()->void:
		ready();equipment("textile_laundering_practice")
		C.add("fit",1,1,.6,false,false,0,"tannin",{},.5)
		C.add("fit",1,1,.6,false,false,0,"tannin",{},1)
		assert_float(C.data().lots[0].finish_strength).is_equal_approx(.75,.00001)
		C.operate("textile_laundering_practice",10,2,1,report())
		assert_float(C.count()).is_equal(2.0)
		assert_str(C.data().lots[0].fabric).is_equal("tannin")
		assert_float(C.data().lots[0].finish_strength).is_equal_approx(.72,.00001)
		assert_int(C.data().lots[0].ready).is_equal(2)
		assert_bool(C.valid(C.data())).is_true())
func test_finish_wears_only_issued_share_once_per_day_and_repair_does_not_redye()->void:
	WorldSimulation.scoped("colorants",func()->void:
		ready();C.add("fit",2,1,0,false,false,0,"printed")
		C.advance(0,1,false)
		assert_float(C.data().lots[0].finish_strength).is_equal_approx(.9995,.000001)
		var before:=C.data().duplicate(true);C.advance(0,1,false);assert_dict(C.data()).is_equal(before)
		equipment("textile_repair_methods");C.data().lots[0].condition=.5
		var cloth_before:=C.available("Woven Cloth")
		C.operate("textile_repair_methods",1,1,0,report())
		assert_float(C.data().lots[0].condition).is_greater(.5)
		assert_float(C.available("Woven Cloth")).is_less(cloth_before)
		assert_float(C.data().lots[0].finish_strength).is_equal_approx(.9995,.000001)
		var malformed:=C.data().duplicate(true);malformed.lots[0].finish_strength=NAN;assert_bool(C.valid(malformed)).is_false())
func test_planner_orders_missing_finished_cloth_from_paid_recipe()->void:
	WorldSimulation.scoped("colorants",func()->void:
		ready();equipment("textile_dye_fixation")
		WorldSimulation.state.resource_stockpiles["Fixed Tannin Cloth"]=0.0
		var spec:=I.product("checked_tannin_cloth")
		for field:String in ["materials","tooling"]:
			for resource:String in spec[field]:WorldSimulation.state.resource_stockpiles[resource]=100.0
		var order:=F.clothing_recommendation()
		assert_str(String(order.get("item",""))).is_equal("checked_tannin_cloth"))
func test_ochre_recognition_and_shared_finite_reserve_never_regrow()->void:
	WorldSimulation.scoped("colorants",func()->void:
		var resources=WorldSimulation.resources
		assert_bool(resources.recognition_ready("Ochre Earth")).is_false()
		learn("stone_sorting");learn("clay_testing")
		assert_bool(resources.recognition_ready("Ochre Earth")).is_true()
		assert_bool(resources.catalog["Ochre Earth"].renewable).is_false()
		var deposit:=resources._deposit("Ochre Earth",Vector3.ZERO,1,2,0,"world_geology")
		deposit.world_key="colorant-test-earth"
		WorldSimulation.geography_stock[deposit.world_key]={"remaining":2.0,"initial_amount":2.0}
		var geology=preload("res://scripts/civilization_resources.gd")
		assert_float(geology.withdraw(deposit,1.5)).is_equal(1.5)
		geology.renew(deposit,1.5);assert_float(float(deposit.remaining)).is_equal(.5)
		assert_float(geology.withdraw(deposit,10)).is_equal(.5)
		geology.renew(deposit,.5);assert_float(float(deposit.remaining)).is_equal(0.0))
func test_full_save_preserves_finishes_and_independent_actor_plain_clothes()->void:
	WorldSimulation.scoped("colorants",func()->void:ready();C.add("fit",2,1,0,false,false,0,"resist",{},.7))
	WorldSimulation.create_actor("plain-colorants",642)
	WorldSimulation.scoped("plain-colorants",func()->void:C.add("fit",3))
	var slot:="colorant_%d_%d"%[OS.get_process_id(),Time.get_ticks_usec()]
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true();WorldSimulation.clear()
	var result:=SaveSystem.load_game(slot);DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	if not result.get("ok",false):return
	WorldSimulation.scoped("colorants",func()->void:
		assert_str(C.data().lots[0].fabric).is_equal("resist")
		assert_float(C.data().lots[0].finish_strength).is_equal_approx(.7,.000001))
	WorldSimulation.scoped("plain-colorants",func()->void:
		assert_str(C.data().lots[0].fabric).is_equal("plain")
		assert_bool(C.data().lots[0].has("finish_strength")).is_false())
func test_panel_displays_four_finite_finish_swatches_without_duplicates()->void:
	WorldSimulation.scoped("colorants",func()->void:
		ready()
		for fabric:String in C.FINISH_FABRICS:C.add("fit",1,1,0,false,false,0,fabric,{},.6)
		var panel=auto_free(preload("res://scripts/hud/clothing_panel.gd").new());panel.subject="textile_printing";add_child(panel)
		for i in range(3):panel.refresh();assert_int(panel.finishes.get_child_count()).is_equal(4)
		assert_str(panel.details.text).contains("block printed garments")
		assert_str(panel.details.text).contains("finish 60%"))
