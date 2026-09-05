extends GdUnitTestSuite
func before_test()->void:
	GameState.reset_for_new_world(864209)
	ResourceSystem.reset_for_new_world()
	ResourceSystem.initialize()
	GameState.resource_deposits=[]

func _context(density:float)->Dictionary:
	return {"settled":true,"origin":Vector3.ZERO,"woodland_catchment":{"density":density,"area_km2":9.0,"position":Vector3(0.5,0,0.5)}}

func test_visible_woodland_supplies_timber_without_a_random_occurrence()->void:
	ResourceSystem._ensure_woodland_supply(_context(0.7))
	assert_int(GameState.resource_deposits.size()).is_equal(1)
	var supply:Dictionary=GameState.resource_deposits[0]
	assert_str(String(supply.resource)).is_equal("Timber")
	assert_str(String(supply.stage)).is_equal("accessible")
	assert_float(float(supply.remaining)).is_greater(0.0)

func test_repeat_sampling_does_not_duplicate_or_refill_cut_woodland()->void:
	ResourceSystem._ensure_woodland_supply(_context(0.7))
	GameState.resource_deposits[0].remaining=12.0
	ResourceSystem._ensure_woodland_supply(_context(0.9))
	assert_int(GameState.resource_deposits.size()).is_equal(1)
	assert_float(float(GameState.resource_deposits[0].remaining)).is_equal(12.0)

func test_existing_local_source_keeps_its_inventory_and_shipments()->void:
	var old:=ResourceSystem._deposit("Timber",Vector3.ZERO,0.7,10.0,0)
	old["stock_at_source"]=3.0
	old["shipments"]=[{"quantity":2.0,"arrival_day":5}]
	GameState.resource_deposits.append(old)
	ResourceSystem._ensure_woodland_supply(_context(0.7))
	assert_int(GameState.resource_deposits.size()).is_equal(1)
	assert_float(float(old.remaining)).is_equal(10.0)
	assert_float(float(old.stock_at_source)).is_equal(3.0)
	assert_int(old.shipments.size()).is_equal(1)

func test_treeless_land_and_unfounded_convoy_do_not_create_woodland_supply()->void:
	ResourceSystem._ensure_woodland_supply(_context(0.01))
	var context:=_context(0.8)
	context["settled"]=false
	ResourceSystem._ensure_woodland_supply(context)
	assert_array(GameState.resource_deposits).is_empty()

func test_trees_are_not_free_delivered_stock_without_workers()->void:
	GameState.population_allocations["Extraction"]=0
	GameState.population_allocations["Logistics"]=0
	var stock:=float(GameState.resource_stockpiles.Timber)
	ResourceSystem._process_material_flow(_context(0.7))
	assert_float(float(GameState.resource_stockpiles.Timber)).is_less_equal(stock)
	assert_float(float(GameState.material_metrics.extracted_today)).is_equal(0.0)

func test_idle_woodland_regrows_at_source_with_a_capacity_limit()->void:
	GameState.population_allocations["Extraction"]=0
	GameState.population_allocations["Logistics"]=0
	ResourceSystem._ensure_woodland_supply(_context(0.7))
	var source:Dictionary=GameState.resource_deposits[0]
	source.remaining=0.0
	ResourceSystem._process_material_flow(_context(0.7))
	assert_float(float(source.remaining)).is_greater(0.0)
	assert_float(float(source.stock_at_source)).is_equal(0.0)
	source.remaining=source.initial_amount
	ResourceSystem._process_material_flow(_context(0.7))
	assert_float(float(source.remaining)).is_equal(float(source.initial_amount))
