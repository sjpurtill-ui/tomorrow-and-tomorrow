extends GdUnitTestSuite
const Investment=preload("res://scripts/building_material_investment.gd")
const Fabric=preload("res://scripts/settlement_fabric_operations.gd")
const ITEM="Building Shade Lattices"
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("fabric_delivery",1301)
func after_test()->void:
	WorldSimulation.clear()
func test_secondary_demand_orders_and_transports_components_without_free_stock()->void:
	WorldSimulation.scoped("fabric_delivery",func()->void:
		var state=WorldSimulation.state;var model=WorldSimulation.settlements
		state.ensure_population_total(400);state.settlement_site_committed=true;state.convoy_traveling=false
		state.settlement_completed.assign(["Hearth Circle"]);model.ensure_founded()
		state.known_discoveries.assign(["building_shading_design","seasonal_patterns","geometric_survey"])
		state.discovery_adoption.building_shading_design=1.0
		state.population_allocations.Construction=20;state.population_allocations.Crafting=20;state.population_allocations.Logistics=100
		state.resource_stockpiles.Stone=2.0
		state.resource_stockpiles.Timber=20.0;state.resource_stockpiles["Fiber Plants"]=10.0
		state.player_settlements.append({"id":"second","name":"Second","primary":false,"position":Vector2(10,0),"population_share":.25,"founded_day":0})
		WorldSimulation.system("CivilizationSystem").register_player_origin(Vector2.ZERO)
		WorldSimulation.system("CivilizationSystem").record_player_travel(Vector2(10,0))
		state.society_capacities.logistics=.8;state.society_capacities.institutions=.8
		model.with_city_resources("second",func()->void:state.resource_stockpiles.Food=10000.0)
		var order:=Investment.fabric_recommendation()
		assert_str(String(order.get("item",""))).is_equal("building_shade_lattices")
		assert_int(int(order.get("target",0))).is_equal(2)
		assert_float(float(state.resource_stockpiles.get(ITEM,0))).is_equal(0.0)
		# Owned manufactured goods are the transport fixture; production is checked
		# separately through the real daily allocator in check_fabric_owner.gd.
		state.resource_stockpiles[ITEM]=2.0
		model.process_city_trade()
		var shipped:=0.0
		for shipment:Dictionary in state.city_trade_shipments:
			if String(shipment.resource)==ITEM and String(shipment.destination_id)=="second":shipped+=float(shipment.quantity)
		assert_float(shipped).is_equal(1.0)
		assert_float(float(state.resource_stockpiles[ITEM])+shipped).is_equal(2.0)
		assert_float(float(model.city_resource_snapshot("second").stores.get(ITEM,0))).is_equal(0.0)
		assert_dict(Investment.fabric_recommendation()).is_empty()
		model.process_city_trade()
		var again:=0.0
		for shipment:Dictionary in state.city_trade_shipments:
			if String(shipment.resource)==ITEM:again+=float(shipment.quantity)
		assert_float(again).is_equal(shipped)
		state.elapsed_days=20;state.society_capacities.logistics=0;model.process_city_trade()
		assert_float(float(model.city_resource_snapshot("second").stores.get(ITEM,0))).is_equal(shipped)
		var capital:Dictionary=state.resource_stockpiles.duplicate(true)
		model.with_city_resources("second",func()->void:
			var choice:=Fabric.choose_retrofit(state.settlement_plots,state.resource_stockpiles,state.known_discoveries,state.discovery_adoption)
			assert_dict(choice).is_not_empty()
			assert_bool(model.start_fabric_retrofit(int(choice.plot_id),String(choice.method)).get("ok",false)).is_true())
		assert_dict(state.resource_stockpiles).is_equal(capital))

func test_shared_method_definitions_do_not_cache_a_societys_eligibility()->void:
	var known:Array=["seasonal_patterns"]
	assert_bool(Fabric.foundations_met("building_shading_design",known)).is_false()
	known.append("geometric_survey")
	assert_bool(Fabric.foundations_met("building_shading_design",known)).is_true()
	assert_bool(Fabric.foundations_met("building_shading_design",[])).is_false()
	known.erase("seasonal_patterns")
	assert_bool(Fabric.foundations_met("building_shading_design",known)).is_false()
	assert_bool(Fabric.foundations_met("unknown_method",known)).is_false()
