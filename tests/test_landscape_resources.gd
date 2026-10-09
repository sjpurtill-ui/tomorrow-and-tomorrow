extends GdUnitTestSuite
const Terrain:=preload("res://scripts/local_terrain.gd")
const Pools:=preload("res://scripts/material_pools.gd")
func before_test()->void:
	GameState.reset_for_new_world(864209)
	MilitaryCampaign.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	ResourceSystem.initialize()
	GameState.resource_deposits=[]

func after_test()->void:
	WorldSimulation.context_provider=Callable()
	WorldSimulation.surface_material_provider=Callable()

func _context(density:float)->Dictionary:
	return {"settled":true,"origin":Vector3.ZERO,"woodland_catchment":{"density":density,"area_km2":9.0,"position":Vector3(0.5,0,0.5)}}

func test_visible_woodland_supplies_timber_as_the_seats_pool()->void:
	ResourceSystem.ensure_pools(_context(0.7))
	assert_int(GameState.resource_deposits.size()).is_equal(1)
	var pool:Dictionary=GameState.resource_deposits[0]
	assert_bool(Pools.is_pool(pool)).is_true()
	assert_str(String(pool.resource)).is_equal("Timber")
	assert_str(String(pool.stage)).is_equal("developed")
	assert_float(float(pool.remaining)).is_equal_approx(9.0*0.7*600.0,0.001)
	assert_float(float(pool.area_km2)).is_equal(9.0)

func test_repeat_sampling_does_not_duplicate_or_refill_cut_woodland()->void:
	ResourceSystem.ensure_pools(_context(0.7))
	GameState.resource_deposits[0].remaining=12.0
	ResourceSystem.ensure_pools(_context(0.9))
	assert_int(GameState.resource_deposits.size()).is_equal(1)
	assert_float(float(GameState.resource_deposits[0].remaining)).is_equal(12.0)

func test_a_cut_pool_opens_the_next_ring_of_real_cover()->void:
	ResourceSystem.ensure_pools(_context(0.7))
	var pool:Dictionary=GameState.resource_deposits[0]
	var first:=float(pool.initial_amount)
	pool.remaining=0.0
	GameState.population_allocations.Logistics=12
	WorldSimulation.surface_material_provider=func(point:Vector2)->Dictionary:
		return {"Timber":{"density":0.8,"area_km2":9.0,"position":Vector3(point.x,0,point.y)}}
	ResourceSystem.ensure_pools(_context(0.7))
	assert_int(GameState.resource_deposits.size()).is_equal(1)
	assert_int(int(pool.ring)).is_equal(1)
	assert_float(float(pool.remaining)).is_equal_approx(8.0*9.0*0.8*600.0,0.001)
	assert_float(float(pool.initial_amount)).is_equal_approx(first+8.0*9.0*0.8*600.0,0.001)
	assert_float(Pools.reach_km(pool)).is_equal(4.5)

func test_older_woods_fold_into_the_pool_with_their_cut_stock_and_loads()->void:
	var old:=ResourceSystem._deposit("Timber",Vector3(0.5,0,0.5),0.7,50.0,0)
	old.landscape_source="woodland_catchment";old.stage="developed";old.remaining=40.0
	old["stock_at_source"]=3.0
	old["shipments"]=[[5,2.0]];old["in_transit"]=2.0
	GameState.resource_deposits.append(old)
	GameState.resource_stockpiles["Timber"]=0.0
	ResourceSystem.ensure_pools(_context(0.7))
	assert_int(GameState.resource_deposits.size()).is_equal(1)
	var pool:Dictionary=GameState.resource_deposits[0]
	assert_bool(Pools.is_pool(pool)).is_true()
	assert_float(float(pool.remaining)).is_equal(40.0)
	assert_float(float(pool.initial_amount)).is_equal(50.0)
	assert_float(float(pool.stock_at_source)).is_equal(3.0)
	# The load already on the road reaches the stores.
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(2.0)

func test_treeless_land_and_unfounded_convoy_do_not_create_woodland_supply()->void:
	ResourceSystem.ensure_pools(_context(0.01))
	var context:=_context(0.8)
	context["settled"]=false
	ResourceSystem.ensure_pools(context)
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
	ResourceSystem._process_material_flow(_context(0.7))
	var pool:=Pools.pool_of("Timber")
	pool.remaining=0.0
	ResourceSystem._process_material_flow(_context(0.7))
	assert_float(float(pool.remaining)).is_greater(0.0)
	assert_float(float(pool.stock_at_source)).is_equal(0.0)
	pool.remaining=pool.initial_amount
	ResourceSystem._process_material_flow(_context(0.7))
	assert_float(float(pool.remaining)).is_equal(float(pool.initial_amount))

func _surface_context()->Dictionary:
	return {"settled":true,"origin":Vector3.ZERO,"surface_material_catchments":{"Stone":{"density":0.5,"position":Vector3.ZERO,"area_km2":9.0},"Fiber Plants":{"density":0.6,"position":Vector3(1,0,0),"area_km2":9.0}}}

func test_stone_and_fiber_are_seat_pools_without_random_deposits()->void:
	ResourceSystem.ensure_pools(_surface_context())
	assert_int(GameState.resource_deposits.size()).is_equal(2)
	for source in GameState.resource_deposits:
		assert_bool(Pools.is_pool(source)).is_true()
		assert_float(float(source.remaining)).is_greater(0.0)
	ResourceSystem.ensure_pools(_surface_context())
	assert_int(GameState.resource_deposits.size()).is_equal(2)

func test_found_stone_waits_until_workable_then_joins_the_pool()->void:
	var old:=ResourceSystem._deposit("Stone",Vector3(4,0,0),0.7,10.0,0)
	old.remaining=6.0
	old.stock_at_source=4.0
	GameState.resource_deposits.append(old)
	ResourceSystem.ensure_pools(_surface_context())
	assert_bool(GameState.resource_deposits.has(old)).is_true()
	old.stage="accessible"
	ResourceSystem.ensure_pools(_surface_context())
	assert_bool(GameState.resource_deposits.has(old)).is_false()
	var stone:=Pools.pool_of("Stone")
	assert_float(float(stone.stock_at_source)).is_equal(4.0)
	assert_float(float(stone.remaining)).is_equal_approx(9.0*0.5*1000.0+6.0,0.001)

func test_only_fiber_regrows_and_empty_stone_receives_no_cutting_labor()->void:
	ResourceSystem.ensure_pools(_surface_context())
	var stone:=Pools.pool_of("Stone")
	var fiber:=Pools.pool_of("Fiber Plants")
	stone.remaining=0.0
	fiber.remaining=1.0
	GameState.population_allocations["Extraction"]=6
	GameState.population_allocations["Logistics"]=0
	ResourceSystem._process_material_flow(_surface_context())
	assert_float(float(stone.remaining)).is_equal(0.0)
	assert_int(int(stone.workers)).is_equal(0)
	assert_int(int(fiber.workers)).is_equal(6)
	GameState.population_allocations["Extraction"]=0
	fiber.remaining=0.0
	ResourceSystem._process_material_flow(_surface_context())
	assert_float(float(fiber.remaining)).is_greater(0.0)

func test_barren_and_unfounded_ground_add_no_surface_stocks()->void:
	var context:=_surface_context()
	context.surface_material_catchments.Stone.density=0.01
	context.surface_material_catchments["Fiber Plants"].density=0.0
	ResourceSystem.ensure_pools(context)
	assert_array(GameState.resource_deposits).is_empty()
	context=_surface_context()
	context.settled=false
	ResourceSystem.ensure_pools(context)
	assert_array(GameState.resource_deposits).is_empty()

func test_sparse_surface_stone_is_available_without_a_point_occurrence()->void:
	var context:=_surface_context()
	context.surface_material_catchments.Stone.density=0.05
	ResourceSystem.ensure_pools(context)
	assert_float(float(Pools.pool_of("Stone").get("remaining",0.0))).is_greater(0.0)

func test_accessible_medicinal_plants_are_gathered_and_delivered()->void:
	var herbs:=ResourceSystem._deposit("Medicinal Plants",Vector3.ZERO,0.8,100.0,0)
	herbs.stage="accessible";herbs.access=1.0
	GameState.resource_deposits=[herbs]
	GameState.resource_stockpiles["Medicinal Plants"]=0.0
	GameState.population_allocations.Extraction=8;GameState.population_allocations.Logistics=8
	ResourceSystem._process_material_flow({"settled":false,"origin":Vector3.ZERO,"tools":1.0})
	assert_float(float(herbs.extracted_today)).is_greater(0.0)
	GameState.elapsed_days+=1
	ResourceSystem._process_material_flow({"settled":false,"origin":Vector3.ZERO,"tools":1.0})
	assert_float(float(GameState.resource_stockpiles["Medicinal Plants"])).is_greater(0.0)

func test_storage_loss_report_names_material_and_storage_type()->void:
	GameState.resource_stockpiles={"Clay":10000.0}
	var report:=ResourceSystem._apply_material_storage_losses([])
	assert_float(float(report.total)).is_greater(0.0)
	assert_float(float(report.by_resource.Clay)).is_greater(0.0)
	assert_bool((report.used_by_type as Dictionary).has("covered")).is_true()

func test_surface_stone_mesh_uses_metre_scale_not_hill_scale()->void:
	assert_float(Terrain.SURFACE_STONE_RADIUS_KM.x).is_greater(0.0)
	assert_float(Terrain.SURFACE_STONE_RADIUS_KM.y).is_less_equal(0.005)

func test_a_pool_counts_as_the_faces_a_people_works_at_once()->void:
	ResourceSystem.ensure_pools(_context(0.7))
	var copper:=ResourceSystem._deposit("Copper Ore",Vector3.ZERO,.7,1000.0,1)
	copper.stage="accessible";copper.access=1.0;copper.route=1.0
	GameState.resource_deposits.append(copper)
	GameState.resource_stockpiles={"Timber":0.0,"Copper Ore":0.0}
	GameState.population_allocations.Extraction=600
	ResourceSystem._process_material_flow(_context(0.7))
	var timber:=Pools.pool_of("Timber")
	# Five faces of timber to one copper pit at 600 cutters (FRONT_HANDS 150).
	assert_int(ResourceSystem.working_fronts()).is_equal(5)
	assert_float(float(timber.workers)/maxf(1.0,float(copper.workers))).is_greater(3.0)

func test_overstock_releases_workers_for_missing_materials_without_free_output()->void:
	GameState.resource_stockpiles={"Timber":0.0,"Stone":1000.0}
	GameState.population_allocations.Extraction=10
	GameState.population_allocations.Logistics=10
	var timber:=ResourceSystem._deposit("Timber",Vector3.ZERO,.7,1000.0,0)
	var stone:=ResourceSystem._deposit("Stone",Vector3.ZERO,.7,1000.0,1)
	for deposit:Dictionary in [timber,stone]:
		deposit.stage="accessible";deposit.access=1.0;deposit.route=1.0
	GameState.resource_deposits=[timber,stone]
	ResourceSystem._process_material_flow({"settled":false,"origin":Vector3.ZERO,"tools":1.0})
	assert_float(float(timber.daily_yield)).is_greater(float(stone.daily_yield)*5.0)
	assert_float(float(timber.remaining)).is_less(1000.0)
	assert_float(float(timber.lifetime_extracted)).is_greater(0.0)
	assert_float(float(GameState.material_metrics.extraction_workers)).is_less_equal(10.0)
func test_fractional_work_is_not_reported_as_no_extractors()->void:
	var deposit:=ResourceSystem._deposit("Timber",Vector3.ZERO,.7,100.0,0)
	deposit.stage="accessible";deposit.workers=0;deposit.daily_yield=.08;deposit.route=1.0
	var events:Array[Dictionary]=[]
	ResourceSystem._update_deposit_bottleneck(deposit,1.0,events)
	assert_str(String(deposit.bottleneck)).is_equal("Flowing")

func test_overflowing_unused_ores_release_finite_workers_for_timber()->void:
	GameState.resource_stockpiles={"Timber":0.0,"Copper Ore":10.0,"Iron Ore":10.0}
	GameState.founding_manifest={}
	GameState.population_allocations.Extraction=10
	GameState.population_allocations.Logistics=10
	var timber:=ResourceSystem._deposit("Timber",Vector3.ZERO,.7,1000.0,0)
	var copper:=ResourceSystem._deposit("Copper Ore",Vector3.ZERO,.7,1000.0,1)
	for deposit:Dictionary in [timber,copper]:
		deposit.stage="accessible";deposit.access=1.0;deposit.route=1.0
	GameState.resource_deposits=[timber,copper]
	ResourceSystem._process_material_flow({"settled":false,"origin":Vector3.ZERO,"tools":1.0})
	assert_float(float(timber.daily_yield)).is_greater(float(copper.daily_yield)*20.0)
	assert_float(float(copper.daily_yield)).is_greater(0.0)
	# Ordinary renewable occurrences recover 35% of the actual cut at source.
	assert_float(float(timber.remaining)+float(timber.lifetime_extracted)*.65).is_equal_approx(1000.0,.000001)
	assert_float(float(copper.remaining)+float(copper.lifetime_extracted)).is_equal_approx(1000.0,.000001)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(0.0) # Still must haul it home.
	assert_float(float(GameState.material_metrics.extraction_workers)).is_less_equal(10.0)

func test_gathering_preserves_samples_explicit_priorities_and_needed_inputs()->void:
	GameState.founding_manifest={}
	GameState.resource_stockpiles={"Copper Ore":10.0,"Iron Ore":.5,"Coal":10.0}
	assert_float(float(ResourceSystem._storage_gathering_priorities().get("Copper Ore",1))).is_equal(.05)
	assert_bool(ResourceSystem._storage_gathering_priorities().has("Iron Ore")).is_false()
	GameState.resource_priorities["Copper Ore"]=2.0
	assert_bool(ResourceSystem._storage_gathering_priorities().has("Copper Ore")).is_false()
	GameState.resource_priorities.clear()
	# Only military lines remain; an axe line draws Copper Ore.
	MilitaryCampaign.equipment_queue=[{"job_type":"production","item":"axe","materials":{"Copper Ore":.4,"Timber":.4,"Tin Ore":.08},"persistent":true,"target_stock":5,"progress_days":0.0,"paused":false}]
	assert_bool(ResourceSystem._storage_gathering_priorities().has("Copper Ore")).is_false()
	MilitaryCampaign.equipment_queue[0].paused=true
	assert_bool(ResourceSystem._storage_gathering_priorities().has("Copper Ore")).is_true()
	MilitaryCampaign.equipment_queue[0].paused=false
	var held:=MilitaryCampaign.military_inventory.duplicate(true);MilitaryCampaign.military_inventory["axe"]=5
	assert_bool(ResourceSystem._storage_gathering_priorities().has("Copper Ore")).is_true()
	MilitaryCampaign.military_inventory=held;MilitaryCampaign.equipment_queue=[]
	GameState.resource_stockpiles.Coal=1000.0 # An overflowing store of fuel.
	GameState.technology_operations={"plants":{"steam_generator":{"installed":1,"enabled":true}}}
	assert_bool(ResourceSystem._storage_gathering_priorities().has("Coal")).is_false()
	GameState.technology_operations.plants.steam_generator.enabled=false
	assert_bool(ResourceSystem._storage_gathering_priorities().has("Coal")).is_true()

func test_free_storage_keeps_unused_materials_available_for_future_choices()->void:
	GameState.resource_stockpiles={"Copper Ore":10.0}
	GameState.founding_manifest={"secure_storage_bulk":100.0}
	assert_bool(ResourceSystem._storage_gathering_priorities().has("Copper Ore")).is_false()

func test_known_craft_can_accumulate_startup_inputs_before_a_line_exists()->void:
	GameState.resource_stockpiles={"Copper Ore":3.0}
	GameState.founding_manifest={}
	GameState.known_discoveries=[]
	assert_bool(ResourceSystem._storage_gathering_priorities().has("Copper Ore")).is_true()
	GameState.known_discoveries=["copper_smelting"]
	assert_bool(ResourceSystem._storage_gathering_priorities().has("Copper Ore")).is_false()
	GameState.resource_stockpiles["Copper Ore"]=10.0
	assert_bool(ResourceSystem._storage_gathering_priorities().has("Copper Ore")).is_true()
	GameState.known_discoveries=[]
	assert_bool(ResourceSystem._storage_gathering_priorities().has("Copper Ore")).is_true()

func test_a_pool_remembers_where_its_woods_were_opened()->void:
	var old:=ResourceSystem._deposit("Timber",Vector3(6.0,0,0),0.7,50.0,0)
	old.landscape_source="woodland_catchment";old.stage="developed"
	GameState.resource_deposits.append(old)
	ResourceSystem.ensure_pools(_context(0.7))
	var cells:Array=Pools.pool_of("Timber").cells
	assert_bool(cells.has([6.0,0.0])).is_true()
