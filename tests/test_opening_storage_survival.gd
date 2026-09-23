extends GdUnitTestSuite
const Goods=preload("res://scripts/civilian_goods.gd")
func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(41);MilitaryCampaign.reset_for_new_world()
	GameState.resource_stockpiles.clear();GameState.founding_manifest.clear()
	GameState.settlement_completed.clear();GameState.settlement_plots.clear()
	GameState.known_discoveries.clear();GameState.discovery_adoption.clear()
func after_test()->void:WorldSimulation.clear()
func test_civilian_goods_have_one_wear_owner_and_do_not_fill_raw_yard()->void:
	GameState.resource_stockpiles={Goods.GOODS:10.0}
	var events:Array[Dictionary]=[]
	assert_float(ResourceSystem._stored_bulk()).is_equal(0.0)
	ResourceSystem._apply_material_storage_losses(events)
	assert_float(float(GameState.resource_stockpiles[Goods.GOODS])).is_equal(10.0)
	GameState.civilian_goods=Goods.empty_state();GameState.civilian_goods.last_day=0;GameState.elapsed_days=1
	Goods.advance()
	assert_float(Goods.stock()).is_equal_approx(10.0*(1.0-Goods.DAILY_WEAR),.00001)
	Goods.advance()
	assert_float(Goods.stock()).is_equal_approx(10.0*(1.0-Goods.DAILY_WEAR),.00001)
func test_exposed_flint_survives_a_year_without_becoming_free_or_indestructible()->void:
	GameState.resource_stockpiles={"Stone":10000.0,"Flint":2.0}
	var events:Array[Dictionary]=[]
	for day in 365:ResourceSystem._apply_material_storage_losses(events)
	assert_float(float(GameState.resource_stockpiles.Flint)).is_greater(1.5)
	assert_float(float(GameState.resource_stockpiles.Flint)).is_less(2.0)
func test_organic_overflow_still_needs_storage()->void:
	GameState.resource_stockpiles={"Timber":1000.0,"Fiber Plants":1000.0}
	var events:Array[Dictionary]=[]
	ResourceSystem._apply_material_storage_losses(events)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_less(980.0)
	assert_float(float(GameState.resource_stockpiles["Fiber Plants"])).is_less(980.0)
