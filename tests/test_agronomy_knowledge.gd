extends GdUnitTestSuite
const A=preload("res://scripts/agronomy_knowledge.gd")
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("farm_ruler",91420)
func after_test()->void:WorldSimulation.clear()
func setup()->void:
	WorldSimulation.state.settlement_site_committed=true
	WorldSimulation.state.population_allocations.Food=30
	WorldSimulation.state.known_discoveries.assign(["seed_selection"])
	WorldSimulation.state.discovery_adoption.seed_selection=1.0
	preload("res://scripts/opening_opportunities.gd").data().programs.seed.retained=maxf(.5,WorldSimulation.state.population_exact*.01)
func learn(id:String,adoption:float=1.0)->void:
	WorldSimulation.state.known_discoveries.append(id);WorldSimulation.state.discovery_adoption[id]=adoption
func test_authored_catalog_contracts_are_valid()->void:
	WorldSimulation.scoped("farm_ruler",func()->void:
		assert_int(A.entries().size()).is_equal(20)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(A.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
	)
func test_establishment_changes_only_real_cultivation_and_pays_labor_cost()->void:
	WorldSimulation.scoped("farm_ruler",func()->void:
		setup();var food:=WorldSimulation.food
		var baseline:Dictionary=food._produce(30,1,1,false)
		learn("germination_trials")
		var actual:Dictionary=food._produce(30,1,1,false)
		assert_float(absf(float(actual["Dry staples"])/float(baseline["Dry staples"])-1.025*.995)).is_less(.000001)
		for type:String in ["Fresh plants","Fresh meat","Fish"]:assert_float(float(actual[type])).is_equal(float(baseline[type]))
		assert_float(float(food._produce(0,1,1,false)["Dry staples"])).is_equal(0.0)
	)
func test_cover_crop_costs_current_harvest_while_reducing_soil_damage()->void:
	WorldSimulation.scoped("farm_ruler",func()->void:
		setup();var food:=WorldSimulation.food
		WorldSimulation.state.food_source_health.Cultivation=.5
		food._update_source_health({"Dry staples":1.0},200,false)
		var unprotected:=float(WorldSimulation.state.food_source_health.Cultivation)
		WorldSimulation.state.food_source_health.Cultivation=.5
		learn("green_manure_crops")
		assert_float(float(A.factors()["yield"])).is_less(1.0)
		food._update_source_health({"Dry staples":1.0},200,false)
		assert_float(float(WorldSimulation.state.food_source_health.Cultivation)).is_greater(unprotected)
	)
func test_absent_adoption_staff_settlement_or_cultivation_keeps_baseline()->void:
	WorldSimulation.scoped("farm_ruler",func()->void:
		setup();learn("regional_seed_trials",0)
		assert_float(float(A.factors()["yield"])).is_equal(1.0)
		WorldSimulation.state.discovery_adoption.regional_seed_trials=1.0
		assert_float(float(A.factors(true)["yield"])).is_equal(1.0)
		WorldSimulation.state.population_allocations.Food=0;assert_float(float(A.factors()["yield"])).is_equal(1.0)
		WorldSimulation.state.population_allocations.Food=30;WorldSimulation.state.settlement_site_committed=false
		assert_float(float(A.factors()["yield"])).is_equal(1.0)
		WorldSimulation.state.settlement_site_committed=true;WorldSimulation.state.known_discoveries.erase("seed_selection")
		assert_float(float(A.factors()["yield"])).is_equal(1.0)
	)
func test_same_family_does_not_stack_and_all_families_remain_bounded()->void:
	WorldSimulation.scoped("farm_ruler",func()->void:
		setup();learn("seedbed_firming");var strongest:=A.factors()
		for id:String in ["germination_trials","seed_cleaning","sowing_depth_trials","row_spacing_trials"]:learn(id)
		assert_dict(A.factors()).is_equal(strongest)
		for item:Dictionary in A.entries():
			if item.id not in WorldSimulation.state.known_discoveries:learn(item.id)
		var combined:=A.factors()
		assert_float(float(combined.soil_damage)).is_greater_equal(.35)
		assert_float(float(combined.weather_buffer)).is_less_equal(.3)
		assert_float(float(combined["yield"])).is_less_equal(1.3)
	)
func test_weather_buffer_only_softens_adverse_weather_and_does_not_make_food()->void:
	assert_float(A.weather_factor(.5,{"weather_buffer":.2})).is_equal(.6)
	assert_float(A.weather_factor(1.1,{"weather_buffer":.2})).is_equal(1.1)
func test_owned_methods_do_not_leak_into_player_state()->void:
	var known:=GameState.known_discoveries.duplicate();var stocks:=GameState.resource_stockpiles.duplicate(true)
	WorldSimulation.scoped("farm_ruler",func()->void:setup();learn("regional_seed_trials");A.factors())
	assert_array(GameState.known_discoveries).is_equal(known)
	assert_dict(GameState.resource_stockpiles).is_equal(stocks)
func test_authoring_rejects_invalid_profiles_and_inspector_shows_costs()->void:
	WorldSimulation.scoped("farm_ruler",func()->void:
		var item:Dictionary=A.entries()[0].duplicate(true)
		item.agronomy_profile.labor_cost=-.1
		assert_bool(preload("res://scripts/technology_catalog_contract.gd").validate([item],WorldSimulation.discovery.technology_catalog).is_empty()).is_false()
		var description:=WorldSimulation.discovery._discovery_effect_summary(A.entries()[11])
		assert_bool(description.contains("labor cost 2.0%")).is_true()
		assert_bool(description.contains("harvest-area cost 4.0%")).is_true()
	)
