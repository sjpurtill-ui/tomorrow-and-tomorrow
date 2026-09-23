extends GdUnitTestSuite
const K=preload("res://scripts/machine_tool_knowledge.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("machinist",1030)

func after_test()->void:WorldSimulation.clear()

func setup()->void:
	var state=WorldSimulation.state
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
	state.population_allocations.Crafting=40;state.population_allocations.Logistics=12
	state.resource_stockpiles.clear()
	for resource:String in ["Timber","Stone","Clay","Wrought Iron","Steel","Refined Copper","Charcoal","Fine Sand","Freshwater","Shaft Bearings","Gear Sets","Optical Lenses"]:state.resource_stockpiles[resource]=100000.0
	for entry:Dictionary in WorldSimulation.discovery.technology_catalog:
		if entry.id not in state.known_discoveries:state.known_discoveries.append(entry.id)
		state.discovery_adoption[entry.id]=1.0

func test_all_four_workshop_installations_pay_their_flattened_tool_bills()->void:
	WorldSimulation.scoped("machinist",func()->void:
		setup();var state=WorldSimulation.state
		for id:String in ["powered_workshop","controlled_workshop","sequenced_workshop","programmable_workshop"]:
			# Former tool-set kits are flattened into raw materials plus Civilian Goods.
			var cost:Dictionary=Ops.PLANTS[id].cost
			assert_bool(cost.has("Basic Machine Tool Sets") or cost.has("Precision Machine Tool Sets")).is_false()
			assert_float(float(cost.get("Civilian Goods",0))).is_greater(0.0)
			for resource:String in cost:
				state.resource_stockpiles[resource]=0.0 if resource=="Civilian Goods" else float(cost[resource])
			var before:Dictionary=state.resource_stockpiles.duplicate(true)
			assert_bool(Ops.install(id).has("error")).is_true()
			assert_dict(state.resource_stockpiles).is_equal(before)
			state.resource_stockpiles["Civilian Goods"]=float(cost["Civilian Goods"])
			assert_bool(Ops.install(id).get("ok",false)).is_true()
			for resource:String in cost:assert_float(float(state.resource_stockpiles[resource])).is_equal_approx(0.0,.000001)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
	)

func test_missing_reference_tools_or_unknown_practice_prevents_scraping()->void:
	WorldSimulation.scoped("machinist",func()->void:
		setup();var state=WorldSimulation.state;var host=WorldSimulation.military
		assert_array(P.startup_blockers(host,"scraped_machine_ways")).is_not_empty()
		state.resource_stockpiles["Surface Plates"]=1.0;state.resource_stockpiles["Machinist Straightedges"]=1.0
		state.known_discoveries.erase("machine_way_scraping");state.discovery_adoption.erase("machine_way_scraping")
		var before:Dictionary=state.resource_stockpiles.duplicate(true)
		assert_bool(host.start_production_line("scraped_machine_ways",1).has("error")).is_true()
		assert_dict(state.resource_stockpiles).is_equal(before)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
	)
