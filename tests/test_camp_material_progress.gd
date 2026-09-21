extends GdUnitTestSuite
const Build=preload("res://scripts/settlement_construction.gd")
func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(4242)
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.population_allocations={"Extraction":4,"Construction":4,"Crafting":3,"Logistics":7,"Knowledge":2,"Food":30,"Survey":6}
	GameState.simulation_metrics={"labor_efficiency":1.0}
	GameState.resource_stockpiles={"Timber":0.0,"Fiber Plants":0.0}
func test_existing_founding_surface_front_becomes_usable_and_delivers()->void:
	var deposit:=ResourceSystem._deposit("Timber",Vector3.ZERO,1.0,600.0,0)
	deposit["landscape_source"]="woodland_catchment"
	ResourceSystem._seed_founding_surface_recognition(deposit)
	GameState.resource_deposits=[deposit]
	var context:={"settled":true,"origin":Vector3.ZERO,"woodland_catchment":{"density":0.6,"position":Vector3.ZERO,"area_km2":9.0},"tools":0.25}
	for day in range(1,8):
		GameState.elapsed_days=day
		ResourceSystem._process_material_flow(context)
	assert_int(GameState.resource_deposits.size()).is_equal(1)
	assert_bool(deposit.stage in ["accessible","developed"]).is_true()
	assert_float(float(GameState.resource_stockpiles.Timber)).is_greater(0.0)
	assert_float(float(deposit.lifetime_delivered)).is_greater(0.0)
func test_four_builders_can_finish_shelters_with_real_materials()->void:
	GameState.resource_stockpiles={"Timber":25.0,"Fiber Plants":0.0}
	for day in 60: Build.process_day()
	assert_bool("Lean-to Shelters" in GameState.settlement_completed).is_true()
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(0.0)
func test_missing_builders_or_materials_still_blocks_work()->void:
	for day in 60: Build.process_day()
	assert_bool("Lean-to Shelters" in GameState.settlement_completed).is_false()
	GameState.resource_stockpiles={"Timber":25.0}
	GameState.population_allocations.Construction=0
	for day in 60: Build.process_day()
	assert_bool("Lean-to Shelters" in GameState.settlement_completed).is_false()
func test_changed_panels_compile()->void:
	for path in ["res://scripts/hud/settlement_overview.gd","res://scripts/hud/construction_queue.gd","res://scripts/hud/content/dock_content_construction.gd","res://scripts/hud/content/dock_content_settlement.gd"]:
		assert_object(load(path)).is_not_null()
