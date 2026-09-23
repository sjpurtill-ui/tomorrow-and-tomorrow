extends GdUnitTestSuite
const K=preload("res://scripts/printing_knowledge.gd")
const S=preload("res://scripts/paper_study.gd")
const GOODS:="Civilian Goods"
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("printer",995)
func after_test()->void:WorldSimulation.clear()
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func test_eight_authored_methods_validate_against_the_catalog()->void:
	WorldSimulation.scoped("printer",func()->void:
		assert_int(K.entries().size()).is_equal(8)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
	)
func test_printed_and_blank_paper_support_are_finite_alternatives()->void:
	WorldSimulation.scoped("printer",func()->void:
		var state=WorldSimulation.state;var printed:=S.bill("Printed Sheets");var paper:=S.bill("Paper")
		for input:String in printed:state.resource_stockpiles[input]=100.0
		for input:String in paper:state.resource_stockpiles[input]=100.0
		learn("paper_making")
		var result:=S.use(10.0,100.0)
		assert_float(float(result.progress)).is_equal_approx(12.0,.000001)
		assert_float(float(result.paper)).is_equal_approx(.1,.000001)
		# Adopted printing is preferred over blank paper.
		learn("hand_relief_printing")
		result=S.use(10.0,100.0)
		assert_float(float(result.progress)).is_equal_approx(13.0,.000001)
		assert_float(float(result.printed_sheets)).is_equal_approx(.1,.000001)
		assert_float(float(result.paper)).is_equal(0.0)
		# Both draw on the same finite goods: once printing uses them up, blank
		# paper has nothing left and the rest of the work is plain study.
		state.resource_stockpiles[GOODS]=float(printed[GOODS])*5.0
		result=S.use(10.0,100.0)
		assert_float(float(result.work)).is_equal_approx(10.0,.000001)
		assert_float(float(result.progress)).is_equal_approx(5*1.3+5,.000001)
		assert_float(float(result.paper)).is_equal_approx(0.0,.000001)
		assert_float(float(state.resource_stockpiles[GOODS])).is_equal_approx(0.0,.000001)
		state.resource_stockpiles[GOODS]=1.0
		result=S.use(10.0,1.3)
		assert_float(float(result.work)).is_equal_approx(1.0,.000001)
		assert_float(float(result.progress)).is_equal_approx(1.3,.000001)
		var stocks:Dictionary=state.resource_stockpiles.duplicate(true)
		S.use(10.0,0.0);S.use(0.0,100.0)
		assert_dict(state.resource_stockpiles).is_equal(stocks)
	)
