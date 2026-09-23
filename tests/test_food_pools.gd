extends GdUnitTestSuite
## Food is held in two pools: fresh food spoils quickly and is eaten first;
## stored food is the reserve. Processing discoveries act as technique levers.
const Goods=preload("res://scripts/civilian_goods.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(9091);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.known_discoveries=[];GameState.discovery_adoption={}
	GameState.ensure_population_total(100)
	GameState.settlement_site_committed=true;GameState.convoy_traveling=false;GameState.resource_settlement_id=""
	GameState.population_allocations.Logistics=10;GameState.population_allocations.Crafting=10
	GameState.food_stocks={FoodSystem.FRESH:100.0,FoodSystem.STORED:1000.0}
	GameState.elapsed_days=120
	FoodSystem._lever_cache.clear()

func after_test()->void:
	FoodSystem._lever_cache.clear()
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func know(id:String,adoption:float=1.0)->void:
	if id not in GameState.known_discoveries:GameState.known_discoveries.append(id)
	GameState.discovery_adoption[id]=adoption
	FoodSystem._lever_cache.clear()

func supply_goods(coverage:float)->void:
	GameState.resource_stockpiles[Goods.GOODS]=Goods.target()*coverage
	FoodSystem._lever_cache.clear()

func test_fresh_food_is_eaten_before_the_stored_reserve()->void:
	GameState.food_stocks={FoodSystem.FRESH:20.0,FoodSystem.STORED:100.0}
	var eaten:=FoodSystem._consume(30.0)
	assert_float(float(eaten[FoodSystem.FRESH])).is_equal(20.0)
	assert_float(float(eaten[FoodSystem.STORED])).is_equal(10.0)
	assert_float(float(GameState.food_stocks[FoodSystem.FRESH])).is_equal(0.0)
	assert_float(float(GameState.food_stocks[FoodSystem.STORED])).is_equal(90.0)
	eaten=FoodSystem._consume(500.0)
	assert_float(float(eaten[FoodSystem.STORED])).is_equal(90.0)
	assert_float(FoodSystem._stock_total()).is_equal(0.0)

func test_stored_food_is_the_slow_spoiling_reserve()->void:
	GameState.food_stocks={FoodSystem.FRESH:1000.0,FoodSystem.STORED:1000.0}
	var lost:=FoodSystem._spoil(false)
	assert_float(float(lost[FoodSystem.FRESH])).is_greater(0.0)
	assert_float(float(lost[FoodSystem.STORED])).is_greater(0.0)
	assert_float(float(lost[FoodSystem.FRESH])).is_greater(float(lost[FoodSystem.STORED])*10.0)
	assert_float(float(GameState.food_stocks[FoodSystem.FRESH])).is_equal_approx(1000.0-float(lost[FoodSystem.FRESH]),.000001)
	assert_float(float(GameState.food_stocks[FoodSystem.STORED])).is_equal_approx(1000.0-float(lost[FoodSystem.STORED]),.000001)

func test_preservation_moves_fresh_food_into_the_stored_pool()->void:
	var logistics:=GameState.effective_workers("Logistics");var makers:=GameState.effective_workers("Crafting")
	var none:=FoodSystem._preserve(logistics,makers,false)
	assert_float(float(none.dried)).is_equal(0.0)
	know("food_drying")
	supply_goods(0.0)
	assert_float(float(FoodSystem._preserve(logistics,makers,false).dried)).is_equal(0.0)
	assert_float(float(GameState.food_stocks[FoodSystem.FRESH])).is_equal(100.0)
	supply_goods(1.0)
	var moved:=FoodSystem._preserve(logistics,makers,false)
	var dried:=float(moved.dried)
	assert_float(dried).is_greater(0.0)
	assert_float(float(GameState.food_stocks[FoodSystem.FRESH])).is_equal_approx(100.0-dried,.000001)
	assert_float(float(GameState.food_stocks[FoodSystem.STORED])).is_equal_approx(1000.0+dried*.88,.000001)
	# Preservation is a settlement practice; a travelling convoy dries nothing.
	assert_float(float(FoodSystem._preserve(logistics,makers,true).dried)).is_equal(0.0)

func test_preservation_lever_raises_throughput()->void:
	GameState.food_stocks={FoodSystem.FRESH:100000.0,FoodSystem.STORED:0.0}
	know("food_drying");supply_goods(1.0)
	var logistics:=GameState.effective_workers("Logistics");var makers:=GameState.effective_workers("Crafting")
	var plain:=float(FoodSystem._preserve(logistics,makers,false).dried)
	know("indirect_solar_food_drying")
	assert_float(FoodSystem.technique_lever("preservation")).is_equal_approx(.20,.000001)
	var improved:=float(FoodSystem._preserve(logistics,makers,false).dried)
	assert_float(improved).is_equal_approx(plain*1.20,.0001)

func test_technique_levers_scale_by_adoption_and_coverage_and_respect_caps()->void:
	supply_goods(1.0)
	know("edible_resource_recognition",.5)
	assert_float(FoodSystem.technique_lever("gathering")).is_equal_approx(.06,.000001)
	supply_goods(.5)
	assert_float(FoodSystem.technique_lever("gathering")).is_equal_approx(.03,.000001)
	supply_goods(0.0)
	assert_float(FoodSystem.technique_lever("gathering")).is_equal(0.0)
	supply_goods(1.0)
	for id:String in FoodSystem.TECHNIQUES:know(id)
	for lever:String in FoodSystem.LEVER_LIMITS:
		var uncapped:=0.0
		for id:String in FoodSystem.TECHNIQUES:uncapped+=float(FoodSystem.TECHNIQUES[id].get(lever,0.0))
		assert_float(FoodSystem.technique_lever(lever)).override_failure_message(lever).is_equal_approx(minf(uncapped,float(FoodSystem.LEVER_LIMITS[lever])),.000001)
	assert_float(FoodSystem.technique_lever("diet")).is_equal(float(FoodSystem.LEVER_LIMITS.diet))
	assert_float(FoodSystem.technique_lever("cultivation")).is_equal(float(FoodSystem.LEVER_LIMITS.cultivation))

func test_spoilage_levers_reduce_losses()->void:
	GameState.food_stocks={FoodSystem.FRESH:1000.0,FoodSystem.STORED:1000.0}
	var baseline:=FoodSystem._spoil(false)
	GameState.food_stocks={FoodSystem.FRESH:1000.0,FoodSystem.STORED:1000.0}
	supply_goods(1.0);know("postharvest_loss_measurement");know("food_retorts")
	var reduced:=FoodSystem._spoil(false)
	assert_float(float(reduced[FoodSystem.FRESH])).is_less(float(baseline[FoodSystem.FRESH]))
	assert_float(float(reduced[FoodSystem.STORED])).is_less(float(baseline[FoodSystem.STORED]))

func test_legacy_five_type_stocks_and_ledgers_fold_into_two_pools()->void:
	GameState.food_stocks={"Fresh plants":10.0,"Fresh meat":5.0,"Fish":2.0,"Dry staples":40.0,"Preserved food":8.0}
	var grain:=preload("res://scripts/grain_processing.gd").empty_state()
	var grain_key:String=grain.stocks.keys()[0]
	grain.stocks[grain_key]=6.0;grain.batches=[{"amount":3.0}]
	GameState.grain_processing=grain
	var lots:=preload("res://scripts/food_batches.gd").empty_state();lots.lots=[{"amount":4.0}]
	GameState.food_batches=lots
	FoodSystem.initialize()
	assert_int(GameState.food_stocks.size()).is_equal(2)
	assert_float(float(GameState.food_stocks[FoodSystem.FRESH])).is_equal_approx(17.0,.000001)
	assert_float(float(GameState.food_stocks[FoodSystem.STORED])).is_equal_approx(48.0+6.0+3.0+4.0,.000001)
	assert_float(FoodSystem.total_stored()).is_equal_approx(78.0,.000001)
	assert_float(float(GameState.grain_processing.stocks[grain_key])).is_equal(0.0)
	assert_array(GameState.food_batches.lots).is_empty()
	# Folding again adds nothing.
	FoodSystem._fold_legacy_pools()
	assert_float(FoodSystem._stock_total()).is_equal_approx(78.0,.000001)

func test_forecast_reports_thirty_and_ninety_days_and_the_first_shortage()->void:
	var demand:={"total":55.0,"climate":0.0,"rationing":0.0}
	GameState.food_stocks={FoodSystem.FRESH:0.0,FoodSystem.STORED:1000.0}
	var stocks:Dictionary=GameState.food_stocks.duplicate()
	var outlook:=FoodSystem._forecast({},demand)
	assert_int(int(outlook.day)).is_equal(120)
	assert_int(int(outlook[30].horizon)).is_equal(30)
	assert_int(int(outlook[90].horizon)).is_equal(90)
	# About 1000/55 days of stored food.
	var shortage:=int(outlook[30].first_shortage_day)
	assert_int(shortage).is_between(14,21)
	assert_int(int(outlook[90].first_shortage_day)).is_equal(shortage)
	assert_float(float(outlook[90].ending_rations)).is_less(1.0)
	assert_float(float(outlook[90].average_required)).is_greater_equal(55.0)
	assert_dict(GameState.food_stocks).is_equal(stocks)
	GameState.food_stocks={FoodSystem.FRESH:0.0,FoodSystem.STORED:1000000.0}
	outlook=FoodSystem._forecast({},demand)
	assert_int(int(outlook[30].first_shortage_day)).is_equal(-1)
	assert_int(int(outlook[90].first_shortage_day)).is_equal(-1)
	assert_float(float(outlook[90].spoilage)).is_greater(float(outlook[30].spoilage))

func test_forecast_counts_seasonal_harvest_into_the_right_pools()->void:
	var demand:={"total":55.0,"climate":0.0,"rationing":0.0}
	GameState.food_stocks={FoodSystem.FRESH:0.0,FoodSystem.STORED:0.0}
	var starving:=FoodSystem._forecast({},demand)
	assert_int(int(starving[30].first_shortage_day)).is_equal(1)
	var fed:=FoodSystem._forecast({"Fresh plants":40.0,"Dry staples":40.0},demand)
	assert_float(float(fed[30].average_production)).is_greater(0.0)
	assert_int(int(fed[30].first_shortage_day)).is_not_equal(1)
