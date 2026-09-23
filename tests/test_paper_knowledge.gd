extends GdUnitTestSuite
const K=preload("res://scripts/paper_knowledge.gd")
const S=preload("res://scripts/paper_study.gd")
const E=preload("res://scripts/society_exchange.gd")
const GOODS:="Civilian Goods"
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("papermaker",995)
func after_test()->void:WorldSimulation.clear()
## Paper adopted at `level`; every raw input on the paper bill plentiful and
## Civilian Goods set to `goods`.
func adopt_paper(level:float,goods:float)->Dictionary:
	var state=WorldSimulation.state
	state.known_discoveries.append("paper_making");state.discovery_adoption.paper_making=level
	var bill:=S.bill("Paper")
	for input:String in bill:state.resource_stockpiles[input]=100.0
	state.resource_stockpiles[GOODS]=goods
	return bill
func test_authored_paper_contracts_are_valid()->void:
	WorldSimulation.scoped("papermaker",func()->void:
		assert_int(K.entries().size()).is_equal(4)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
	)
func test_paper_support_is_stock_limited_and_never_spent_beyond_remaining_work()->void:
	WorldSimulation.scoped("papermaker",func()->void:
		var state=WorldSimulation.state
		state.resource_stockpiles[GOODS]=10.0
		# Goods alone are not paper: without the technique study is plain work.
		assert_float(float(S.use(10.0,20.0).progress)).is_equal(10.0)
		assert_float(float(state.resource_stockpiles[GOODS])).is_equal(10.0)
		var bill:=adopt_paper(1.0,0.0)
		state.resource_stockpiles[GOODS]=float(bill[GOODS])*5.0
		var partial:=S.use(10.0,20.0)
		assert_float(float(partial.progress)).is_equal_approx(11.0,.000001)
		assert_float(float(partial.work)).is_equal_approx(10.0,.000001)
		assert_float(float(partial.goods)).is_equal_approx(float(bill[GOODS])*5.0,.000001)
		assert_float(float(state.resource_stockpiles[GOODS])).is_equal_approx(0.0,.000001)
		state.resource_stockpiles[GOODS]=1.0
		var finish:=S.use(10.0,1.2)
		assert_float(float(finish.work)).is_equal_approx(1.0,.000001)
		assert_float(float(finish.progress)).is_equal_approx(1.2,.000001)
		assert_float(float(state.resource_stockpiles[GOODS])).is_equal_approx(1.0-float(bill[GOODS]),.000001)
		var stocks:Dictionary=state.resource_stockpiles.duplicate(true)
		S.use(10.0,0.0);S.use(0.0,100.0)
		assert_dict(state.resource_stockpiles).is_equal(stocks)
		# Barely known paper does not yet supply notes.
		state.discovery_adoption.paper_making=S.MIN_ADOPTION*.5
		assert_float(float(S.use(10.0,100.0).progress)).is_equal(10.0)
		assert_dict(state.resource_stockpiles).is_equal(stocks)
	)
func test_daily_collection_study_consumes_paper_only_for_arrived_unfinished_material()->void:
	WorldSimulation.scoped("papermaker",func()->void:
		var state=WorldSimulation.state
		state.ensure_population_total(100);state.population_allocations.Knowledge=20;state.simulation_metrics.food_intake_ratio=1.0
		var bill:=adopt_paper(1.0,1.0)
		E.data().collections={"a":{"id":"a","kind":"knowledge","name":"Account","source_id":"","discovery_id":"clay_shaping","study":0.0,"work":100.0,"returned_day":0,"signals":[]},"b":{"id":"b","kind":"knowledge","name":"Later","source_id":"","discovery_id":"clay_shaping","study":0.0,"work":100.0,"returned_day":100,"signals":[]}}
		var base:=state.effective_workers("Knowledge")*.15
		E.advance(1)
		assert_float(float(E.data().collections.a.study)).is_equal_approx(base*1.2/100.0,.000001)
		assert_float(float(E.data().collections.b.study)).is_equal(0.0)
		assert_float(float(state.resource_stockpiles[GOODS])).is_equal_approx(1.0-base*float(bill[GOODS]),.000001)
		var remaining:=float(state.resource_stockpiles[GOODS])
		E.advance(1)
		assert_float(float(state.resource_stockpiles[GOODS])).is_equal(remaining)
		E.data().collections.a.study=1.0;E.advance(2)
		assert_float(float(state.resource_stockpiles[GOODS])).is_equal(remaining)
	)
