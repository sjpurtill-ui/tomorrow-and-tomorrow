extends GdUnitTestSuite

func before_test()->void:
	GameState.reset_for_new_world(772241)
	ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	SettlementModel.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_site_committed=true
	GameState.settlement_name="First City"
	SettlementModel.ensure_founded()
	ResourceSystem.initialize()
	FoodSystem.initialize()
	GameState.player_settlements.append({"id":"dawngate","name":"Dawngate","primary":false,"position":Vector2(10,0),"population_share":0.25,"founded_day":0})
	CivilizationSystem.register_player_origin(Vector2.ZERO)
	CivilizationSystem.record_player_travel(Vector2(10,0))

func test_city_stores_are_independent_and_empty_legacy_cities_do_not_copy_capital()->void:
	var before:=GameState.resource_stockpiles.duplicate(true)
	var snapshot:=SettlementModel.city_resource_snapshot("dawngate")
	assert_float(float(snapshot.stores.get("Timber",0.0))).is_equal(0.0)
	SettlementModel.with_city_resources("dawngate",func()->void:
		GameState.resource_stockpiles["Timber"]=7.0
		GameState.resource_priorities["Stone"]="high"
	)
	assert_dict(GameState.resource_stockpiles).is_equal(before)
	assert_float(float(SettlementModel.city_resource_snapshot("dawngate").stores.Timber)).is_equal(7.0)
	assert_bool(GameState.resource_priorities.has("Stone")).is_false()

func test_secondary_daily_food_and_water_cannot_consume_capital_stores()->void:
	var before:=GameState.resource_stockpiles.duplicate(true)
	var population:=GameState.population_exact
	var allocations:=GameState.population_allocations.duplicate(true)
	SettlementModel.process_city_resources("dawngate",{"origin":Vector3(10,0,0),"traveling":false,"surface_water_distance_km":1.0})
	var snapshot:=SettlementModel.city_resource_snapshot("dawngate")
	assert_dict(GameState.resource_stockpiles).is_equal(before)
	assert_float(SettlementModel.primary_population_exact()).is_equal_approx(population*.75,.00001)
	assert_dict(GameState.population_allocations).is_equal(allocations)
	assert_float(float(snapshot.water.required_today)).is_equal(population*0.25)
	assert_int(snapshot.food_history.size()).is_equal(1)
	SettlementModel.process_city_resources("dawngate",{"origin":Vector3(10,0,0)})
	assert_int(SettlementModel.city_resource_snapshot("dawngate").food_history.size()).is_equal(1)

func test_selection_does_not_change_simulation_or_primary_name()->void:
	assert_bool(bool(SettlementModel.select_settlement("dawngate").ok)).is_true()
	assert_str(GameState.settlement_name).is_equal("First City")
	assert_str(String(SettlementModel.selected_settlement().name)).is_equal("Dawngate")
	assert_bool(bool(SettlementModel.select_settlement("missing").ok)).is_false()
	assert_str(GameState.selected_player_settlement_id).is_equal("dawngate")

func test_arrival_preserves_only_conserved_convoy_cargo()->void:
	GameState.settlement_convoy={"active":true,"destination":Vector2(20,0),"arrival_day":2.0,"progress":1.0,"duration_days":2.0,"population":40,"population_share":0.1,"food_committed":1880.0,"materials_committed":{"Timber":6.0,"Fiber Plants":4.0}}
	GameState.elapsed_days=2.0
	var before:=GameState.resource_stockpiles.duplicate(true)
	var result:=SettlementModel.complete_settlement_convoy(Vector2(20,0))
	assert_bool(result.ok).is_true()
	var stores:Dictionary=SettlementModel.city_resource_snapshot(String(result.settlement.id)).stores
	assert_float(float(stores.Food)).is_equal(1800.0)
	assert_float(float(stores.get("Timber",0.0))).is_equal(0.0) # Founding materials were spent on the new settlement.
	assert_bool(stores.has("Stone")).is_false()
	assert_dict(GameState.resource_stockpiles).is_equal(before)

func test_trade_is_gated_and_deliveries_are_conserved_and_delayed()->void:
	GameState.resource_stockpiles["Timber"]=100.0
	SettlementModel.process_city_trade()
	assert_array(GameState.city_trade_shipments).is_empty()
	GameState.society_capacities["logistics"]=0.8
	GameState.society_capacities["institutions"]=0.8
	GameState.elapsed_days=1.0
	SettlementModel.process_city_trade()
	assert_int(GameState.city_trade_shipments.size()).is_greater(0)
	var shipped:=0.0
	for shipment in GameState.city_trade_shipments:
		if String(shipment.resource)=="Timber": shipped+=float(shipment.quantity)
	assert_float(shipped).is_greater(0.0)
	assert_float(float(GameState.resource_stockpiles.Timber)+shipped).is_equal_approx(100.0,0.00001)
	assert_float(float(SettlementModel.city_resource_snapshot("dawngate").stores.get("Timber",0.0))).is_equal(0.0)
	# Declining logistics stops new dispatch, not delivery of existing cargo.
	GameState.society_capacities["logistics"]=0.0
	GameState.elapsed_days=20.0
	SettlementModel.process_city_trade()
	assert_float(float(SettlementModel.city_resource_snapshot("dawngate").stores.Timber)).is_equal_approx(shipped,0.00001)
	assert_array(GameState.city_trade_shipments).is_empty()

func test_large_town_can_export_timber_while_retaining_local_construction_buffer()->void:
	GameState.population_exact=2000.0;GameState.population_total=2000
	for city:Dictionary in GameState.player_settlements:city.erase("population_state")
	GameState.resource_stockpiles.Timber=80.0
	GameState.society_capacities.logistics=.8;GameState.society_capacities.institutions=.8
	GameState.elapsed_days=1.0
	SettlementModel.process_city_trade()
	var shipped:=0.0
	for shipment:Dictionary in GameState.city_trade_shipments:
		if shipment.resource=="Timber":shipped+=float(shipment.quantity)
	assert_float(shipped).is_greater(0.0)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_greater_equal(20.0)
	assert_float(float(GameState.resource_stockpiles.Timber)+shipped).is_equal_approx(80.0,.000001)

func test_transport_progression_improves_reach_and_capacity()->void:
	GameState.society_capacities["logistics"]=0.3
	var early:=SettlementModel.city_trade_capacity()
	GameState.society_capacities["logistics"]=0.8
	var late:=SettlementModel.city_trade_capacity()
	assert_float(float(late.range_km)).is_greater(float(early.range_km))
	assert_float(float(late.speed_km_per_day)).is_greater(float(early.speed_km_per_day))
	assert_float(float(late.capacity_per_worker)).is_greater(float(early.capacity_per_worker))

func _local_covered_storage(city_id:String)->float:
	return SettlementModel.with_city_resources(city_id,func()->float:
		return SettlementModel.with_local_population(func()->float:
			SettlementModel.rebuild_summary()
			return float(ResourceSystem.storage_capacities().covered)))

func test_local_storage_does_not_inherit_primary_warehouses()->void:
	# Built storage is a city capacity from its own population, era, condition
	# and carriers; a drawn warehouse plot adds nothing by itself.
	GameState.settlement_completed.append("Storage Pits")
	GameState.population_allocations.Logistics=maxi(int(GameState.population_allocations.get("Logistics",0)),200)
	GameState.city_form={"tier":3.0,"condition":1.0}
	SettlementModel.rebuild_summary()
	var primary_capacity:=float(ResourceSystem.storage_capacities().covered)
	GameState.settlement_plots.append({"id":9999,"land_use":"storage","status":"active","worker_count":10,"worker_capacity":10,"storage_capacity":10000.0,"condition":1.0,"form":"stone warehouse"})
	SettlementModel.rebuild_summary()
	assert_float(float(ResourceSystem.storage_capacities().covered)).is_equal_approx(primary_capacity,.000001)
	var local_capacity:=_local_covered_storage("dawngate")
	assert_float(primary_capacity).is_greater(local_capacity)
	# Storage Pits belong to the capital, not to Dawngate.
	assert_float(primary_capacity-local_capacity).is_greater(140.0)
	# Raising Dawngate's own era and condition raises only its storage.
	var city:=SettlementModel.settlement_record("dawngate")
	city.local_resources.city_form={"tier":3.0,"condition":1.0}
	assert_float(_local_covered_storage("dawngate")).is_greater(local_capacity)
	SettlementModel.rebuild_summary()
	assert_float(float(ResourceSystem.storage_capacities().covered)).is_equal_approx(primary_capacity,.000001)

func test_blocked_route_cannot_teleport_goods()->void:
	GameState.society_capacities["logistics"]=0.8
	GameState.society_capacities["institutions"]=0.8
	GameState.resource_stockpiles["Timber"]=100.0
	SettlementModel.process_city_trade(func(_source:Dictionary,_destination:Dictionary)->Dictionary: return {"valid":false})
	assert_array(GameState.city_trade_shipments).is_empty()
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(100.0)

func test_food_trade_uses_the_food_ledger_and_records_transit_loss()->void:
	GameState.society_capacities["logistics"]=0.8
	GameState.society_capacities["institutions"]=0.8
	FoodSystem.receive_external_food(10000.0)
	var before:=FoodSystem.total_stored()
	SettlementModel.process_city_trade()
	var shipped:=0.0
	for shipment in GameState.city_trade_shipments:
		if String(shipment.resource)=="Food": shipped+=float(shipment.quantity)
	assert_float(shipped).is_greater(0.0)
	assert_float(FoodSystem.total_stored()+shipped).is_equal_approx(before,0.00001)
	assert_float(float(GameState.resource_stockpiles.Food)).is_equal_approx(FoodSystem.total_stored(),0.00001)
	GameState.society_capacities["logistics"]=0.0
	GameState.elapsed_days=20.0
	SettlementModel.process_city_trade()
	var arrived:=float(SettlementModel.city_resource_snapshot("dawngate").stores.Food)
	assert_float(arrived).is_greater(0.0)
	assert_float(arrived).is_less(shipped)
	var lost:=0.0
	for entry in GameState.city_trade_history:
		if String(entry.status)=="delivered" and String(entry.resource)=="Food": lost+=float(entry.lost)
	assert_float(arrived+lost).is_equal_approx(shipped,0.00001)

func test_second_city_cannot_provision_a_convoy_from_capital_stores()->void:
	GameState.population_exact=1000.0
	GameState.population_total=1000
	GameState.resource_stockpiles={"Food":100000.0,"Timber":1000.0,"Fiber Plants":1000.0}
	CivilizationSystem.record_player_travel(Vector2(20,0))
	var quote:=SettlementModel.settlement_convoy_quote(Vector2(20,0),2.0)
	assert_str(String(quote.get("origin_id",""))).is_equal("dawngate")
	assert_bool(bool(quote.ok)).is_false()
	assert_bool("travel rations" in String(quote.reason)).is_true()

func test_secondary_woodland_supply_is_local_and_does_not_duplicate_capital()->void:
	var before:=GameState.resource_deposits.duplicate(true)
	var context:={"settled":true,"origin":Vector3(10,0,0),"woodland_catchment":{"density":0.65,"area_km2":9.0,"position":Vector3(10,0,0)}}
	SettlementModel.with_city_resources("dawngate",func()->void: ResourceSystem._ensure_woodland_supply(context))
	assert_array(GameState.resource_deposits).is_equal(before)
	var deposits:Array=SettlementModel.city_resource_snapshot("dawngate").get("deposits",[])
	assert_int(deposits.size()).is_equal(1)
	assert_str(String(deposits[0].landscape_source)).is_equal("woodland_catchment")

func test_stone_and_fiber_catchments_belong_to_their_own_city()->void:
	var before:=GameState.resource_deposits.duplicate(true)
	var stores:=GameState.resource_stockpiles.duplicate(true)
	var context:={"settled":true,"origin":Vector3(10,0,0),"surface_material_catchments":{"Stone":{"density":0.5,"position":Vector3(10,0,0)},"Fiber Plants":{"density":0.6,"position":Vector3(11,0,0)}}}
	SettlementModel.with_city_resources("dawngate",func()->void: ResourceSystem._ensure_surface_material_supplies(context))
	assert_array(GameState.resource_deposits).is_equal(before)
	assert_dict(GameState.resource_stockpiles).is_equal(stores)
	assert_int(SettlementModel.city_resource_snapshot("dawngate").deposits.size()).is_equal(2)

func test_finished_conduits_travel_before_secondary_installation()->void:
	var planner=preload("res://scripts/water_conveyance_investment.gd")
	var water=preload("res://scripts/water_conveyance.gd")
	var previous:Callable=WorldSimulation.context_provider
	WorldSimulation.context_provider=func(origin:Vector2)->Dictionary:
		return {"origin":Vector3(origin.x,1,origin.y),"terrain_height_at":func(x:float,_z:float)->float:return 11-x,"environment_profile":{},"water_conveyance_sources":[{"id":"upstream","position":Vector3(9,2,0),"revealed":true}]}
	GameState.population_allocations.Construction=100
	GameState.population_allocations.Logistics=100
	GameState.population_health=1.0;GameState.simulation_metrics.labor_efficiency=1.0
	GameState.society_capacities.logistics=.8;GameState.society_capacities.institutions=.8
	for id:String in ["gravity_conduit_grade_control","joinery","clay_pipe_socket_jointing"]:
		GameState.known_discoveries.append(id);GameState.discovery_adoption[id]=1.0
	GameState.water_metrics={"intake_ratio":1.0,"source_distance_km":0.0}
	# A timber line's bill is raw materials and Civilian Goods; the capital holds it.
	var cost:Dictionary={}
	SettlementModel.with_city_resources("dawngate",func()->void:
		GameState.simulation_metrics.labor_efficiency=1.0
		GameState.water_metrics={"intake_ratio":.5,"source_distance_km":1.0}
		GameState.resource_stockpiles={"Clay":2.0}
		SettlementModel.with_local_population(func()->void:
			for option:Dictionary in planner.candidates():
				if option.material=="timber":cost.merge(option.terms.cost,true)))
	assert_dict(cost).is_not_empty()
	assert_bool(cost.has("Wooden Conduits")).is_false()
	# Dawngate already holds its clay; the capital holds ample goods and timber
	# beyond its own reserves.
	GameState.resource_stockpiles={}
	for item:String in cost:
		if item!="Clay":GameState.resource_stockpiles[item]=float(cost[item])*3.0
	var capital:Dictionary=GameState.resource_stockpiles.duplicate()
	SettlementModel.process_city_trade()
	var shipped:Dictionary={}
	for shipment:Dictionary in GameState.city_trade_shipments:
		shipped[shipment.resource]=float(shipped.get(shipment.resource,0.0))+float(shipment.quantity)
	assert_bool(shipped.has("Clay")).is_false()
	for item:String in capital:
		assert_float(float(shipped.get(item,0.0))).is_equal_approx(float(cost[item]),.000001)
		assert_float(float(GameState.resource_stockpiles.get(item,0.0))).is_equal_approx(float(capital[item])-float(cost[item]),.000001)
	planner.recommendation()
	var city:Dictionary=SettlementModel.settlement_record("dawngate")
	assert_array(city.local_resources.water_conveyance.lines).is_empty()
	GameState.elapsed_days=20
	GameState.society_capacities.logistics=0.0
	SettlementModel.process_city_trade()
	for item:String in cost:assert_float(float(city.local_resources.resource_stockpiles.get(item,0))).is_greater_equal(float(cost[item])-.000001)
	planner.recommendation()
	assert_int(city.local_resources.water_conveyance.lines.size()).is_equal(1)
	for item:String in cost:assert_float(float(city.local_resources.resource_stockpiles.get(item,0))).is_less(float(cost[item]))
	assert_array(water.data().lines).is_empty()
	assert_bool("wooden_log_conduits" in GameState.known_discoveries).is_false()
	WorldSimulation.context_provider=previous

func test_arrived_timber_is_available_to_daily_household_work()->void:
	MilitaryCampaign.reset_for_new_world()
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	EconomySystem.reset_for_new_world();EconomySystem.initialize()
	ConsequenceEngine.reset_for_new_world();ConsequenceEngine.initialize()
	# Household goods draw on the raw basket; only the arriving timber can feed it.
	for item:String in preload("res://scripts/civilian_goods.gd").BASKET:GameState.resource_stockpiles[item]=0.0
	GameState.resource_stockpiles["Civilian Goods"]=0.0
	GameState.population_allocations.Crafting=20
	var primary:=String(GameState.player_settlements[0].id)
	GameState.city_trade_shipments=[{"id":999,"source_id":"dawngate","destination_id":primary,"resource":"Timber","quantity":2.0,"travel_days":1.0,"arrival_day":1.0}]
	var observed:={"tools_before_construction":0.0}
	var context:Dictionary=preload("res://scripts/civilization_day.gd").context(Vector2.ZERO)
	context.settled=true;context.surface_water_distance_km=.1;context.surface_water_recognized=true
	preload("res://scripts/civilization_day.gd").advance(1,context,func()->void:
		if GameState.resource_settlement_id.is_empty():observed.tools_before_construction=float(GameState.resource_stockpiles.get("Civilian Goods",0)))
	assert_float(float(observed.tools_before_construction)).is_greater(0.0)
	var timber:=float(GameState.resource_stockpiles.Timber)
	SettlementModel.receive_city_trade_arrivals()
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(timber)
	assert_float(timber).is_less(2.0)
