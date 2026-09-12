extends GdUnitTestSuite
const C=preload("res://scripts/civilization_controller.gd")
const P=preload("res://scripts/persistent_production.gd")
const I=preload("res://scripts/civilian_industry.gd")
const E=preload("res://scripts/society_exchange.gd")

func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("delivery",1031)

func after_test()->void:WorldSimulation.clear()

func setup()->void:
	var state=WorldSimulation.state
	state.initialize_population_model();state.ensure_population_total(400)
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1.0;state.population_allocations.Crafting=20
	state.population_allocations.Logistics=8;state.population_allocations.Knowledge=10
	state.simulation_metrics.merge({"labor_efficiency":1.0,"food_days":120.0,"food_intake_ratio":.94,"food_consumption":100.0,"army_provisions_required":10.0,"army_provision_delivery_ratio":.4},true)
	state.resource_stockpiles.clear();state.known_discoveries.clear()
	WorldSimulation.military.home_army.troops=48

func learn(id:String)->void:
	WorldSimulation.state.known_discoveries.append(id);WorldSimulation.state.discovery_adoption[id]=1.0

func test_delivery_shortfall_allows_paid_carts_and_keeps_training_suspended()->void:
	WorldSimulation.scoped("delivery",func()->void:
		setup();learn("cart_running_gear")
		var state=WorldSimulation.state;var host=WorldSimulation.military
		state.resource_stockpiles["Cart Assembly Kits"]=2.0
		var plan:=C.current_plan("delivery")
		assert_bool(plan.hungry).is_true();assert_bool(plan.food_shortage).is_false()
		var before:=host._daily_delivery_capacity()
		C.military_orders("delivery",plan)
		assert_str(host.training_staff.policy("army").id).is_equal("suspended")
		var job:Dictionary=host.equipment_queue[0]
		assert_str(String(job.item)).is_equal("assembled_transport_cart")
		assert_float(float(state.resource_stockpiles.get("Transport Carts",0))).is_equal(0.0)
		P.advance(host,job,2.0)
		assert_float(float(state.resource_stockpiles["Cart Assembly Kits"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Transport Carts"])).is_equal(2.0)
		assert_float(host._daily_delivery_capacity()).is_greater(before)
	)

func test_home_research_supply_can_continue_during_delivery_only_hunger()->void:
	WorldSimulation.scoped("delivery",func()->void:
		setup();learn("paper_making")
		var state=WorldSimulation.state;var item:=""
		for id:String in I.PRODUCTS:
			if I.PRODUCTS[id].output=="Paper" and I.PRODUCTS[id].gate=="paper_making":item=id;break
		assert_str(item).is_not_empty()
		var spec:Dictionary=I.PRODUCTS[item]
		for resource:String in spec.materials:state.resource_stockpiles[resource]=20.0
		for resource:String in spec.tooling:state.resource_stockpiles[resource]=20.0
		E.data().collections.returned={"study":0.0,"work":240.0,"returned_day":0}
		C.civilian_orders("delivery",C.current_plan("delivery"))
		assert_int(WorldSimulation.military.equipment_queue.size()).is_equal(1)
		var job:Dictionary=WorldSimulation.military.equipment_queue[0]
		assert_str(String(job.item)).is_equal(item)
		P.advance(WorldSimulation.military,job,float(job.work_per_item))
		assert_float(float(state.resource_stockpiles.Paper)).is_equal(1.0)
	)

func test_real_food_shortage_and_unknown_cause_still_block_production()->void:
	WorldSimulation.scoped("delivery",func()->void:
		setup();learn("cart_running_gear");WorldSimulation.state.resource_stockpiles["Cart Assembly Kits"]=2.0
		WorldSimulation.state.simulation_metrics.food_intake_ratio=.8
		var plan:=C.current_plan("delivery")
		assert_bool(plan.food_shortage).is_true();assert_bool(C.production_food_blocked(plan)).is_true()
		C.military_orders("delivery",plan);C.civilian_orders("delivery",plan)
		for job:Dictionary in WorldSimulation.military.equipment_queue:assert_str(String(job.item)).is_not_equal("assembled_transport_cart")
		assert_bool(C.production_food_blocked({"hungry":true})).is_true()
		assert_bool(C.production_food_blocked({"hungry":false})).is_false()
		assert_float(float(WorldSimulation.state.resource_stockpiles["Cart Assembly Kits"])).is_equal(2.0)
	)
