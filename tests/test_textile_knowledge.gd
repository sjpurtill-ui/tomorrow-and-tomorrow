extends GdUnitTestSuite
const K=preload("res://scripts/textile_knowledge.gd")
const M=preload("res://scripts/field_medicine.gd")
const GOODS:="Civilian Goods"
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("textile_ruler",994)
func after_test()->void:WorldSimulation.clear()
func outfit()->Dictionary:
	return {"wounded_pool":20,"disabled_pool":0,"formations":[{"unit":"medical_detachment","weapon":"medical_kit","count":10,"equipment":10,"training":1.0,"personnel_condition":1.0}]}
func test_six_authored_discoveries_have_valid_production_contracts()->void:
	WorldSimulation.scoped("textile_ruler",func()->void:
		assert_int(K.entries().size()).is_equal(6)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
	)
func test_dressings_are_paid_from_civilian_goods_and_raw_materials()->void:
	WorldSimulation.scoped("textile_ruler",func()->void:
		var dressing:Dictionary=M.DRESSING
		assert_bool(dressing.has(GOODS)).is_true();assert_bool(dressing.has("Woven Dressings")).is_false()
		WorldSimulation.state.resource_stockpiles={"Medicinal Plants":1.0}
		for input:String in dressing:WorldSimulation.state.resource_stockpiles[input]=1.0
		var care:=M.provide(outfit(),1.0)
		assert_float(float(care.cases)).is_equal(5.0)
		for input:String in dressing:assert_float(float(WorldSimulation.state.resource_stockpiles[input])).is_equal_approx(1.0-5*float(dressing[input]),.000001)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Medicinal Plants"])).is_equal_approx(.75,.000001)
	)
func test_dressings_and_raw_fiber_combine_without_double_consumption()->void:
	WorldSimulation.scoped("textile_ruler",func()->void:
		# Dressings themselves contain fiber; fiber counted for dressings must not
		# also be counted as loose fiber for further cases.
		WorldSimulation.state.resource_stockpiles={GOODS:100.0,"Freshwater":100.0,"Fiber Plants":.05,"Medicinal Plants":1.0}
		var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		var quoted:=M.quote(outfit(),1.0)
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
		for input:String in quoted.inputs:assert_float(float(quoted.inputs[input])).override_failure_message("%s quoted %f of %f" % [input,float(quoted.inputs[input]),float(before.get(input,0))]).is_less_equal(float(before.get(input,0))+.000001)
		M.provide(outfit(),1.0)
		for input:String in before:assert_float(float(WorldSimulation.state.resource_stockpiles[input])).override_failure_message("%s went negative" % input).is_greater_equal(-.000001)
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
