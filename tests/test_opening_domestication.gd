extends GdUnitTestSuite

const Opportunities=preload("res://scripts/opening_opportunities.gd")
const Craft=preload("res://scripts/civilian_goods.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(6421);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.ensure_population_total(100);GameState.settlement_site_committed=true
	GameState.population_allocations.Food=10
	GameState.food_stocks={"Fresh food":100.0,"Stored food":100.0}
	GameState.known_discoveries.append("seasonal_patterns");GameState.discovery_adoption.seasonal_patterns=1.0

func after_test()->void:
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func advance(first:int,count:int,context:Dictionary={"settled":true,"freshwater":1.0,"foraging":1.0})->void:
	for day in range(first,first+count):
		GameState.elapsed_days=day;Opportunities.advance(context)

func fertile()->Dictionary:
	return {"id":"fertile_test","resource":"Fertile Soil","stage":"recognized","quality":.8,"remaining":1000.0}

func suitable_game()->Dictionary:
	return {"id":"herd_test","resource":"Game","stage":"recognized","quality":.85,"potential":.7,"remaining":100.0}

func test_selective_planting_requires_two_real_seed_cycles()->void:
	GameState.resource_deposits=[fertile()]
	var staples_before:=float(GameState.food_stocks["Stored food"])
	advance(0,91)
	assert_bool(Opportunities.ready("seed_selection")).is_false()
	assert_int(int(Opportunities.program_report().seed.harvests)).is_equal(1)
	advance(91,91)
	assert_bool(Opportunities.ready("seed_selection")).is_true()
	assert_int(int(Opportunities.program_report().seed.harvests)).is_equal(2)
	assert_float(float(GameState.food_stocks["Stored food"])).is_less(staples_before)
	assert_float(float(Opportunities.program_report().seed.retained)).is_greater(0.0)

func test_planting_cannot_bootstrap_without_fertile_ground_and_seed()->void:
	advance(0,200)
	assert_bool(Opportunities.ready("seed_selection")).is_false()
	assert_float(float(Opportunities.program_report().seed.retained)).is_equal(0.0)
	GameState.known_discoveries.append("seed_selection");GameState.discovery_adoption.seed_selection=1.0
	DiscoverySystem.refresh_operating_effects()
	assert_float(Craft.factor("seed_selection")).is_equal(0.0)
	assert_float(float(FoodSystem._produce(10,1.0,1.0,false)["Dry staples"])).is_equal(0.0)

func test_taming_requires_a_suitable_population_and_sustained_feed()->void:
	GameState.resource_deposits=[{"id":"unsuitable","resource":"Game","stage":"recognized","quality":.3,"remaining":100.0}]
	advance(0,70)
	assert_bool(Opportunities.ready("animal_taming")).is_false()
	assert_float(float(Opportunities.program_report().herd.animals)).is_equal(0.0)
	GameState.resource_deposits=[suitable_game()]
	var feed_before:=float(GameState.food_stocks["Fresh food"])
	advance(70,60)
	assert_bool(Opportunities.ready("animal_taming")).is_true()
	assert_float(float(Opportunities.program_report().herd.animals)).is_greater_equal(4.0)
	assert_float(float(GameState.resource_deposits[0].remaining)).is_equal(96.0)
	assert_float(float(GameState.food_stocks["Fresh food"])).is_less(feed_before)

func test_animal_knowledge_has_no_effect_without_a_living_herd()->void:
	GameState.known_discoveries.append("animal_taming");GameState.discovery_adoption.animal_taming=1.0
	DiscoverySystem.refresh_operating_effects()
	assert_float(DiscoverySystem.effect("food_output")).is_equal(0.0)
	GameState.resource_deposits=[suitable_game()]
	advance(0,1)
	DiscoverySystem.refresh_operating_effects()
	assert_float(Craft.factor("animal_taming")).is_equal(1.0)
	assert_float(DiscoverySystem.effect("food_output")).is_equal_approx(.004,.000001)
	GameState.resource_deposits.clear();advance(1,1)
	assert_float(Craft.factor("animal_taming")).is_equal(1.0)
	GameState.food_stocks["Fresh food"]=0.0;GameState.food_stocks["Stored food"]=0.0;advance(2,1)
	DiscoverySystem.refresh_operating_effects()
	assert_float(Craft.factor("animal_taming")).is_equal(0.0)
	assert_float(DiscoverySystem.effect("food_output")).is_equal(0.0)

func test_program_state_is_bounded_and_save_valid()->void:
	GameState.resource_deposits=[fertile(),suitable_game()]
	advance(0,10)
	assert_bool(Opportunities.valid(JSON.parse_string(JSON.stringify(GameState.opening_opportunities)))).is_true()
	var malformed:=GameState.opening_opportunities.duplicate(true);malformed.programs.herd.animals=INF
	assert_bool(Opportunities.valid(malformed)).is_false()
	assert_str(WorldSimulation.validate_payload(WorldSimulation.export_state())).is_empty()
