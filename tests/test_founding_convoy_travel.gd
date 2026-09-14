extends GdUnitTestSuite

const Travel:=preload("res://scripts/civilization_travel.gd")
var previous_route_provider:Callable
var previous_context_provider:Callable

func before_test()->void:
	previous_route_provider=WorldSimulation.route_provider
	previous_context_provider=WorldSimulation.context_provider
	GameState.reset_for_new_world(4417)
	GameState.initialize_population_model()
	CivilizationSystem.reset_for_new_world()
	CivilizationSystem.player_world_origin=Vector2.ZERO
	CivilizationSystem.revealed_areas=[{"x":0.0,"z":0.0,"radius":2.0}]
	GameState.ensure_population_total(100)
	GameState.simulation_metrics.merge({"food_days":30.0,"food_balance":0.0,"food_production":100.0,"food_consumption":100.0},true)
	GameState.resource_stockpiles["Food"]=3000.0
	WorldSimulation.route_provider=func(from:Vector3,to:Vector3)->Dictionary:
		return {"valid":true,"distance_km":Vector2(from.x,from.z).distance_to(Vector2(to.x,to.z)),"terrain_modifier":1.0}
	WorldSimulation.context_provider=func(origin:Vector2)->Dictionary:
		return {
			"environment_profile":{"signature":"test-grassland","resource_potentials":{"Fertile Soil":0.8,"Game":0.55}},
			"surface_material_catchments":{
				"Timber":{"density":0.3,"position":Vector3(origin.x+1.0,0.0,origin.y)},
				"Stone":{"density":0.2,"position":Vector3(origin.x,0.0,origin.y+1.0)},
				"Fiber Plants":{"density":0.25,"position":Vector3(origin.x-1.0,0.0,origin.y)}
			},
			"woodland_catchment":{"density":0.3,"position":Vector3(origin.x+1.0,0.0,origin.y)}
		}

func after_test()->void:
	WorldSimulation.route_provider=previous_route_provider
	WorldSimulation.context_provider=previous_context_provider

func test_initial_convoy_can_enter_black_ground_then_camp_at_its_physical_position()->void:
	var destination:=Vector2(48,0)
	assert_bool(CivilizationSystem._position_is_revealed(destination)).is_false()
	var begun:Dictionary=Travel.begin(destination)
	assert_bool(bool(begun.get("ok",false))).is_true()
	GameState.founding_journey.elapsed=float(GameState.founding_journey.duration_days)*.5
	var camp:Dictionary=Travel.camp_to_forage()
	assert_bool(bool(camp.get("ok",false))).is_true()
	assert_vector(CivilizationSystem.player_world_origin).is_equal(Vector2(24,0))
	assert_bool(GameState.convoy_traveling).is_false()
	assert_bool(bool(GameState.founding_journey.get("camped_foraging",false))).is_true()
	assert_bool(bool(GameState.founding_journey.get("active",true))).is_false()
	assert_bool(CivilizationSystem._position_is_revealed(Vector2(30,0))).is_true()
	assert_bool(CivilizationSystem._position_is_revealed(Vector2(24,41))).is_false()
	assert_float(float((GameState.founding_journey.get("camp_survey",{}) as Dictionary).get("radius_km",0.0))).is_equal(6.25)
	var recognized:Array[String]=[]
	for deposit_variant in GameState.resource_deposits:
		var deposit:Dictionary=deposit_variant
		if String(deposit.get("stage",""))=="recognized":recognized.append(String(deposit.get("resource","")))
	assert_array(recognized).contains(["Timber","Stone","Fiber Plants","Fertile Soil","Game"])

func test_replenished_camp_stores_extend_the_next_possible_leg()->void:
	GameState.resource_stockpiles["Food"]=200.0
	GameState.simulation_metrics.food_days=2.0
	var destination:=Vector2(160,0)
	assert_bool(Travel.quote(destination).has("error")).is_true()
	assert_str(String(Travel.quote(destination).error)).contains("nearer point in the black").contains("camp there to forage")
	GameState.resource_stockpiles["Food"]=3000.0
	GameState.simulation_metrics.food_days=30.0
	assert_bool(bool(Travel.quote(destination).get("ok",false))).is_true()

func test_stopped_convoy_does_not_create_a_second_camp_action()->void:
	assert_bool(Travel.camp_to_forage().has("error")).is_true()
	assert_str(String(Travel.camp_to_forage().error)).contains("already stopped")

func test_arrival_automatically_becomes_a_stationary_foraging_camp()->void:
	var destination:=Vector2(16,0)
	var begun:Dictionary=Travel.begin(destination)
	GameState.founding_journey.elapsed=float(begun.duration_days)-.25
	GameState.simulation_metrics.merge({"travel_speed_factor":1.0,"health":1.0,"food_shortage_days":0.0},true)
	Travel.advance(1.0)
	assert_bool(bool(GameState.founding_journey.get("active",true))).is_false()
	assert_bool(bool(GameState.founding_journey.get("camped_foraging",false))).is_true()
	assert_vector(GameState.founding_journey.get("camp_position",Vector2.INF)).is_equal(destination)

func test_travel_council_says_when_to_stop_and_when_to_continue()->void:
	Travel.begin(Vector2(160,0))
	assert_str(String(Travel.advice().status)).is_equal("CONTINUE")
	GameState.resource_stockpiles.Food=100.0
	assert_str(String(Travel.advice().status)).is_equal("STOP & FORAGE")
	assert_bool(bool(Travel.advice().should_stop)).is_true()

func test_travel_council_says_when_camp_has_rebuilt_a_reserve()->void:
	GameState.founding_journey={"active":false,"camped_foraging":true,"camp_position":Vector2.ZERO}
	GameState.resource_stockpiles.Food=200.0
	assert_str(String(Travel.advice().status)).is_equal("KEEP FORAGING")
	GameState.resource_stockpiles.Food=3000.0
	assert_str(String(Travel.advice().status)).is_equal("READY TO CONTINUE")
	assert_bool(bool(Travel.advice().ready)).is_true()
