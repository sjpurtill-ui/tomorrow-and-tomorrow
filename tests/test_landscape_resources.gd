extends GdUnitTestSuite
const Terrain:=preload("res://scripts/local_terrain.gd")
func before_test()->void:
	GameState.reset_for_new_world(864209)
	MilitaryCampaign.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	ResourceSystem.initialize()
	GameState.resource_deposits=[]

func after_test()->void:
	WorldSimulation.context_provider=Callable()

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

func test_exhausted_surface_front_moves_to_real_nearby_cover()->void:
	ResourceSystem._ensure_woodland_supply(_context(0.7))
	var first:Dictionary=GameState.resource_deposits[0]
	first.remaining=0.0
	GameState.population_allocations.Logistics=12
	WorldSimulation.context_provider=func(point:Vector2)->Dictionary:
		return {"woodland_catchment":{"density":0.8,"area_km2":9.0,"position":Vector3(point.x,0,point.y)},"surface_material_catchments":{}}
	ResourceSystem._ensure_woodland_supply(_context(0.7))
	assert_int(GameState.resource_deposits.size()).is_equal(2)
	var next:Dictionary=GameState.resource_deposits[1]
	assert_str(String(next.landscape_source)).is_equal("woodland_catchment")
	assert_float(float(next.remaining)).is_greater(0.0)
	assert_float((next.position as Vector3).distance_to(first.position)).is_greater_equal(2.5)

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

func _surface_context()->Dictionary:
	return {"settled":true,"origin":Vector3.ZERO,"surface_material_catchments":{"Stone":{"density":0.5,"position":Vector3.ZERO,"area_km2":9.0},"Fiber Plants":{"density":0.6,"position":Vector3(1,0,0),"area_km2":9.0}}}

func test_stone_and_fiber_do_not_need_random_deposits()->void:
	ResourceSystem._ensure_surface_material_supplies(_surface_context())
	assert_int(GameState.resource_deposits.size()).is_equal(2)
	for source in GameState.resource_deposits:
		assert_str(String(source.stage)).is_equal("accessible")
		assert_float(float(source.remaining)).is_greater(0.0)
	ResourceSystem._ensure_surface_material_supplies(_surface_context())
	assert_int(GameState.resource_deposits.size()).is_equal(2)

func test_surface_source_adoption_preserves_depletion_and_shipments()->void:
	var old:=ResourceSystem._deposit("Stone",Vector3.ZERO,0.7,10.0,0)
	old.remaining=0.0
	old.stock_at_source=4.0
	old.shipments=[{"quantity":2.0,"arrival_day":5}]
	GameState.resource_deposits.append(old)
	ResourceSystem._ensure_surface_material_supplies(_surface_context())
	assert_float(float(old.remaining)).is_equal(0.0)
	assert_float(float(old.stock_at_source)).is_equal(4.0)
	assert_int(old.shipments.size()).is_equal(1)
	assert_int(GameState.resource_deposits.size()).is_equal(2)

func test_only_fiber_regrows_and_empty_stone_receives_no_cutting_labor()->void:
	ResourceSystem._ensure_surface_material_supplies(_surface_context())
	var stone:Dictionary=GameState.resource_deposits[0]
	var fiber:Dictionary=GameState.resource_deposits[1]
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
	ResourceSystem._ensure_surface_material_supplies(context)
	assert_array(GameState.resource_deposits).is_empty()
	context=_surface_context()
	context.settled=false
	ResourceSystem._ensure_surface_material_supplies(context)
	assert_array(GameState.resource_deposits).is_empty()

func test_sparse_surface_stone_is_available_without_a_point_occurrence()->void:
	var context:=_surface_context()
	context.surface_material_catchments.Stone.density=0.05
	ResourceSystem._ensure_surface_material_supplies(context)
	var found:=false
	for deposit in GameState.resource_deposits:
		if String(deposit.resource)=="Stone":
			found=true
			assert_float(float(deposit.remaining)).is_greater(0.0)
	assert_bool(found).is_true()

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

func test_material_flow_calls_a_depleted_source_exhausted()->void:
	var renderer:Node3D=auto_free(Terrain.new())
	var rows:Array[Dictionary]=renderer._material_flow_rows([{"resource":"Salt","stage":"developed","remaining":0.0,"stock_at_source":0.0,"shipments":[],"workers":0,"extracted_today":0.0,"bottleneck":"Source exhausted"}])
	assert_int(rows.size()).is_equal(1)
	assert_str(String(rows[0].status)).is_equal("EXHAUSTED")
	var brief:Dictionary=renderer._material_constraint_brief({"lost_today":2.0,"losses_by_resource":{"Clay":1.7}},1,100.0,20.0)
	assert_str(String(brief.status)).contains("STORAGE IS LOSING")
	assert_str(String(brief.why)).contains("Clay")

func test_regrowth_does_not_trap_extractors_on_a_depleted_front()->void:
	ResourceSystem._ensure_woodland_supply(_context(0.7))
	var first:Dictionary=GameState.resource_deposits[0]
	first.remaining=0.2
	GameState.population_allocations.Logistics=12
	WorldSimulation.context_provider=func(point:Vector2)->Dictionary:
		return {"woodland_catchment":{"density":0.8,"area_km2":9.0,"position":Vector3(point.x,0,point.y)},"surface_material_catchments":{}}
	var timber:=float(GameState.resource_stockpiles.Timber)
	ResourceSystem._ensure_woodland_supply(_context(0.7))
	assert_int(GameState.resource_deposits.size()).is_equal(2)
	assert_float(float(first.remaining)).is_equal(0.2)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(timber)
	ResourceSystem._ensure_woodland_supply(_context(0.7))
	assert_int(GameState.resource_deposits.size()).is_equal(2)

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
	MilitaryCampaign.equipment_queue=[{"job_type":"civilian","item":"refined_copper","materials":{"Copper Ore":2.0,"Timber":2.0},"persistent":true,"target_stock":5,"progress_days":0.0,"paused":false}]
	assert_bool(ResourceSystem._storage_gathering_priorities().has("Copper Ore")).is_false()
	MilitaryCampaign.equipment_queue[0].paused=true
	assert_bool(ResourceSystem._storage_gathering_priorities().has("Copper Ore")).is_true()
	MilitaryCampaign.equipment_queue[0].paused=false
	GameState.resource_stockpiles["Refined Copper"]=5.0
	assert_bool(ResourceSystem._storage_gathering_priorities().has("Copper Ore")).is_true()
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
