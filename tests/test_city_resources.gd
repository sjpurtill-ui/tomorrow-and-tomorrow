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
	assert_float(GameState.population_exact).is_equal(population)
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

func test_transport_progression_improves_reach_and_capacity()->void:
	GameState.society_capacities["logistics"]=0.3
	var early:=SettlementModel.city_trade_capacity()
	GameState.society_capacities["logistics"]=0.8
	var late:=SettlementModel.city_trade_capacity()
	assert_float(float(late.range_km)).is_greater(float(early.range_km))
	assert_float(float(late.speed_km_per_day)).is_greater(float(early.speed_km_per_day))
	assert_float(float(late.capacity_per_worker)).is_greater(float(early.capacity_per_worker))

func test_local_storage_does_not_inherit_primary_warehouses()->void:
	GameState.settlement_completed.append("Storage Pits")
	GameState.settlement_plots.append({"land_use":"storage","status":"active","worker_count":10,"worker_capacity":10,"storage_capacity":10000.0,"condition":1.0,"form":"stone warehouse"})
	var primary_capacity:=float(ResourceSystem.storage_capacities().covered)
	var local_capacity:float=SettlementModel.with_city_resources("dawngate",func()->float: return float(ResourceSystem.storage_capacities().covered))
	assert_float(primary_capacity).is_greater(1000.0)
	assert_float(local_capacity).is_less(10.0)

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
