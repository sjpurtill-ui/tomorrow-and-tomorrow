extends GdUnitTestSuite
const K=preload("res://scripts/textile_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const M=preload("res://scripts/field_medicine.gd")
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("textile_ruler",994)
func after_test()->void:WorldSimulation.clear()
func outfit()->Dictionary:
	return {"wounded_pool":20,"disabled_pool":0,"formations":[{"unit":"medical_detachment","weapon":"medical_kit","count":10,"equipment":10,"training":1.0,"personnel_condition":1.0}]}
func make(item:String,amount:int)->void:
	assert_bool(WorldSimulation.military.start_production_line(item,amount).get("ok",false)).is_true()
	var job:Dictionary=WorldSimulation.military.equipment_queue.back()
	P.advance(WorldSimulation.military,job,float(I.product(item).days)*amount)
	assert_int(int(job.completed)).is_equal(amount)
	assert_bool(WorldSimulation.military.cancel_equipment_job(int(job.id)).get("cancelled",false)).is_true()
func test_six_authored_discoveries_have_valid_production_contracts()->void:
	WorldSimulation.scoped("textile_ruler",func()->void:
		assert_int(K.entries().size()).is_equal(6)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
	)
func test_raw_fibers_become_real_dressings_through_paid_intermediates()->void:
	WorldSimulation.scoped("textile_ruler",func()->void:
		for entry:Dictionary in K.entries():WorldSimulation.state.known_discoveries.append(entry.id);WorldSimulation.state.discovery_adoption[entry.id]=1.0
		WorldSimulation.state.resource_stockpiles={"Fiber Plants":20.0,"Freshwater":20.0,"Clay":30.0,"Timber":30.0,"Stone":20.0,"Medicinal Plants":1.0}
		make("retted_fibers",2);make("spun_yarn",2);make("loom_weights",2);make("woven_cloth",1);make("woven_dressings",1)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Woven Dressings"])).is_equal(1.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Woven Cloth"])).is_equal_approx(.8,.000001)
		var before_fiber:=float(WorldSimulation.state.resource_stockpiles["Fiber Plants"])
		var care:=M.provide(outfit(),1.0)
		assert_float(float(care.cases)).is_equal(5.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Woven Dressings"])).is_equal_approx(.9,.000001)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Fiber Plants"])).is_equal(before_fiber)
	)
func test_dressings_and_raw_fiber_combine_without_double_consumption()->void:
	WorldSimulation.scoped("textile_ruler",func()->void:
		WorldSimulation.state.resource_stockpiles={"Woven Dressings":.04,"Fiber Plants":.3,"Medicinal Plants":1.0}
		var quoted:=M.quote(outfit(),1.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Woven Dressings"])).is_equal(.04)
		assert_float(float(quoted.cases)).is_equal(5.0)
		M.provide(outfit(),1.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Woven Dressings"])).is_equal_approx(0,.000001)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Fiber Plants"])).is_equal_approx(0,.000001)
	)
func test_dressings_do_not_replace_staff_medicine_or_provisions()->void:
	WorldSimulation.scoped("textile_ruler",func()->void:
		WorldSimulation.state.resource_stockpiles={"Woven Dressings":1.0}
		assert_float(float(M.provide(outfit(),1.0).cases)).is_equal(0.0)
		WorldSimulation.state.resource_stockpiles["Medicinal Plants"]=1.0
		assert_float(float(M.provide(outfit(),0.0).cases)).is_equal(0.0)
		var a:=outfit();a.formations=[]
		assert_float(float(M.provide(a,1.0).cases)).is_equal(0.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Woven Dressings"])).is_equal(1.0)
	)
func test_partial_textile_job_roundtrip_finishes_once()->void:
	WorldSimulation.scoped("textile_ruler",func()->void:
		WorldSimulation.state.known_discoveries.append("woven_dressings");WorldSimulation.state.discovery_adoption.woven_dressings=1.0
		WorldSimulation.state.resource_stockpiles={"Woven Cloth":1.0,"Freshwater":2.0,"Clay":2.0}
		assert_bool(WorldSimulation.military.start_production_line("woven_dressings",1).get("ok",false)).is_true()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		P.advance(WorldSimulation.military,job,1.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles.get("Woven Dressings",0))).is_equal(0.0)
		var restored:Dictionary=JSON.parse_string(JSON.stringify(job))
		assert_str(P.validate_saved({"equipment_queue":[restored]})).is_empty()
		P.advance(WorldSimulation.military,restored,1.0);P.advance(WorldSimulation.military,restored,100.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Woven Dressings"])).is_equal(1.0)
	)
