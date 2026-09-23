extends GdUnitTestSuite
## Civilian Goods: one household stock made by Crafting workers from a raw
## basket, worn out daily, and read by techniques through goods coverage.
const Goods=preload("res://scripts/civilian_goods.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(5151);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.known_discoveries=[];GameState.discovery_adoption={}
	GameState.ensure_population_total(100)
	GameState.settlement_site_committed=true;GameState.convoy_traveling=false;GameState.resource_settlement_id=""
	GameState.population_allocations.Crafting=20
	GameState.resource_stockpiles={"Fiber Plants":100.0,"Timber":100.0,"Clay":100.0,"Stone":100.0,"Flint":100.0}
	GameState.civilian_goods=Goods.empty_state()
	GameState.elapsed_days=10

func after_test()->void:
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func know(id:String,adoption:float=1.0)->void:
	if id not in GameState.known_discoveries:GameState.known_discoveries.append(id)
	GameState.discovery_adoption[id]=adoption

func labor_output()->float:
	return GameState.effective_workers("Crafting")*Goods.CRAFT_SHARE*Goods.BASE_RATE*Goods.technique_output()

func test_crafting_labor_makes_goods_from_the_raw_basket_up_to_the_wanted_stock()->void:
	var before:Dictionary=GameState.resource_stockpiles.duplicate()
	var wanted:=Goods.target()*1.2
	assert_float(labor_output()).is_greater(wanted)
	var report:=Goods.advance()
	assert_float(float(report.made)).is_equal_approx(wanted,.00001)
	assert_float(Goods.stock()).is_equal_approx(wanted,.00001)
	assert_str(String(report.reason)).is_equal("Replenishing as needed")
	var drawn:=0.0
	for item:String in Goods.BASKET:
		var used:=float(before[item])-float(GameState.resource_stockpiles[item])
		assert_float(float(report.inputs[item])).is_equal_approx(used,.000001)
		drawn+=used
	assert_float(drawn).is_equal_approx(wanted*Goods.RAW_PER_UNIT,.000001)
	# With every material on hand the draw follows the basket weights.
	assert_float(float(report.inputs.Timber)/float(report.inputs["Fiber Plants"])).is_equal_approx(float(Goods.BASKET.Timber)/float(Goods.BASKET["Fiber Plants"]),.0001)

func test_output_is_limited_by_labor_and_by_raw_materials()->void:
	GameState.ensure_population_total(2000)
	GameState.population_allocations.Crafting=2
	var expected:=labor_output()
	assert_float(expected).is_less(Goods.target()*1.2)
	var report:=Goods.advance()
	assert_float(float(report.made)).is_equal_approx(expected,.00001)
	# One scarce material is covered by the rest of the basket.
	GameState.resource_stockpiles={"Stone":.05}
	GameState.elapsed_days+=1
	var stock_before:=Goods.stock()*(1.0-Goods.DAILY_WEAR)
	report=Goods.advance()
	assert_float(float(report.made)).is_equal_approx(.05/Goods.RAW_PER_UNIT,.00001)
	assert_float(float(GameState.resource_stockpiles.Stone)).is_equal_approx(0.0,.000001)
	assert_float(Goods.stock()).is_equal_approx(stock_before+.05/Goods.RAW_PER_UNIT,.00001)

func test_nothing_is_made_without_workers_materials_or_a_settled_site()->void:
	GameState.population_allocations.Crafting=0
	var report:=Goods.advance()
	assert_float(float(report.made)).is_equal(0.0)
	assert_str(String(report.reason)).is_equal("No craftspeople assigned")
	GameState.population_allocations.Crafting=20;GameState.resource_stockpiles={}
	GameState.elapsed_days+=1
	report=Goods.advance()
	assert_float(float(report.made)).is_equal(0.0)
	assert_str(String(report.reason)).contains("Needs timber")
	GameState.settlement_site_committed=false;GameState.resource_stockpiles={"Timber":10.0}
	GameState.elapsed_days+=1
	report=Goods.advance()
	assert_float(float(report.made)).is_equal(0.0)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(10.0)

func test_goods_wear_once_per_day_for_every_elapsed_day()->void:
	GameState.settlement_site_committed=false
	GameState.resource_stockpiles={Goods.GOODS:100.0}
	GameState.civilian_goods.last_day=5
	var report:=Goods.advance()
	assert_float(Goods.stock()).is_equal_approx(100.0*pow(1.0-Goods.DAILY_WEAR,5),.00001)
	assert_float(float(report.worn)).is_equal_approx((100.0-Goods.stock())/5.0,.00001)
	Goods.advance()
	assert_float(Goods.stock()).is_equal_approx(100.0*pow(1.0-Goods.DAILY_WEAR,5),.00001)

func test_coverage_is_stock_over_a_target_that_rises_with_adopted_techniques()->void:
	assert_float(Goods.target()).is_equal_approx(100.0*Goods.BASE_TARGET_PER_PERSON,.00001)
	GameState.resource_stockpiles[Goods.GOODS]=1.0
	assert_float(Goods.coverage()).is_equal_approx(.5,.00001)
	know("basketry",.5)
	assert_float(Goods.target()).is_equal_approx(100.0*(Goods.BASE_TARGET_PER_PERSON+float(Goods.TARGET_PER_PERSON.basketry)*.5),.00001)
	assert_float(Goods.coverage()).is_less(.5)
	GameState.resource_stockpiles[Goods.GOODS]=1000.0
	assert_float(Goods.coverage()).is_equal(1.0)
	GameState.resource_stockpiles[Goods.GOODS]=-5.0
	assert_float(Goods.coverage()).is_equal(0.0)

func test_technique_factor_follows_coverage_and_output_follows_adoption()->void:
	know("basketry");know("cordage",.5)
	GameState.resource_stockpiles[Goods.GOODS]=Goods.target()*.25
	assert_float(Goods.factor("basketry")).is_equal_approx(.25,.00001)
	assert_float(Goods.factor("cordage")).is_equal_approx(.25,.00001)
	assert_float(Goods.factor("oral_epics")).is_equal(1.0)
	assert_float(Goods.technique_output()).is_equal_approx(1.0+Goods.TECHNIQUE_OUTPUT*1.5,.00001)
	DiscoverySystem.refresh_operating_effects()
	var partial:=DiscoverySystem.effect("craft_output")
	GameState.resource_stockpiles[Goods.GOODS]=0.0
	DiscoverySystem.refresh_operating_effects()
	assert_float(DiscoverySystem.effect("craft_output")).is_less_equal(partial)
	assert_bool("basketry" in GameState.known_discoveries).is_true()

func test_legacy_household_products_fold_into_civilian_goods_once()->void:
	GameState.resource_stockpiles={"Woven Containers":3.0,"Cordage Bundles":2.0,"Sealed Clay Vessels":1.5,Goods.GOODS:1.0,"Timber":4.0}
	GameState.civilian_goods={"initialized":true,"last_day":-1,"report":{}}
	Goods.ensure_initialized()
	assert_float(Goods.stock()).is_equal_approx(7.5,.00001)
	for item:String in Goods.LEGACY_PRODUCTS:assert_bool(GameState.resource_stockpiles.has(item)).override_failure_message(item).is_false()
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(4.0)
	assert_bool(bool(GameState.civilian_goods.migrated)).is_true()
	GameState.resource_stockpiles["Woven Containers"]=9.0
	Goods.ensure_initialized()
	assert_float(Goods.stock()).is_equal_approx(7.5,.00001)
	assert_bool(Goods.valid(GameState.civilian_goods)).is_true()

func test_sealed_storage_rations_need_adopted_sealed_vessels_and_goods()->void:
	GameState.resource_stockpiles[Goods.GOODS]=40.0
	assert_float(Goods.sealed_storage_rations()).is_equal(0.0)
	know("sealed_vessels",.5)
	assert_float(Goods.sealed_storage_rations()).is_equal_approx(40.0*Goods.SEALED_STORAGE_SHARE*Goods.RATIONS_PER_SEALED_UNIT*.5,.00001)
	GameState.resource_stockpiles[Goods.GOODS]=0.0
	assert_float(Goods.sealed_storage_rations()).is_equal(0.0)

func test_malformed_state_is_rejected()->void:
	assert_bool(Goods.valid(Goods.empty_state())).is_true()
	assert_bool(Goods.valid({"initialized":true,"last_day":1.5,"report":{}})).is_false()
	assert_bool(Goods.valid({"initialized":true,"last_day":1,"report":[]})).is_false()
	assert_bool(Goods.valid("goods")).is_false()
