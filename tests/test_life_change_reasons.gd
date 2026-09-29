extends GdUnitTestSuite
## "Why lives grew longer or shorter" names what moved how long we live, with
## its numbers (the player, 2026-09-28: "These fucking mean NOTHING, explain
## them please!" about rows that said only "Living conditions changed").

const Words:=preload("res://scripts/hud/life_change_words.gd")

func before_test()->void:
	GameState.reset_for_new_world(5151)
	GameState.initialize_population_model()
	GameState.elapsed_days=400.0
	GameState.population_health=0.70
	GameState.food_security=0.60
	GameState.housing_capacity=int(GameState.population_exact)+10
	GameState.exceptional_hazard_smoothed=0.0
	GameState.exceptional_hazard_causes_smoothed={"Hunger":0.0,"Illness":0.0}
	GameState.health_history.clear()

func after_test()->void:
	GameState.health_history.clear()
	GameState.elapsed_days=0

func test_the_formula_is_the_one_life_expectancy_uses()->void:
	assert_float(GameState.life_expectancy_from(GameState.life_inputs())).is_equal_approx(GameState.projected_life_expectancy(),0.000001)

func test_more_food_is_named_with_its_numbers()->void:
	GameState.record_health_history(true)
	GameState.elapsed_days+=30.0
	GameState.food_security=0.80
	GameState.record_health_history(true)
	var point:Dictionary=GameState.health_history[-1]
	var reasons:Array=point.reasons
	assert_array(reasons).is_not_empty()
	assert_str(String(reasons[0].key)).is_equal("food")
	assert_float(float(reasons[0].years)).is_greater(0.0)
	var told:=Words.tell(reasons,float(point.delta),GameState.health_history.size()-1,GameState.health_history)
	assert_str(String(told.name)).is_equal("More food to go round")
	assert_str(String(told.why)).contains("Food to go round 60% → 80%")
	assert_str(String(told.category)).is_equal("Food")

func test_a_cause_of_death_is_told_by_name()->void:
	GameState.record_health_history(true)
	GameState.elapsed_days+=30.0
	GameState.exceptional_hazard_smoothed=0.03
	GameState.exceptional_hazard_causes_smoothed={"Hunger":0.03,"Illness":0.0}
	GameState.record_health_history(true)
	var point:Dictionary=GameState.health_history[-1]
	assert_float(float(point.delta)).is_less(0.0)
	var told:=Words.tell(point.reasons,float(point.delta),GameState.health_history.size()-1,GameState.health_history)
	assert_str(String(told.name)).is_equal("More deaths from hunger")
	assert_str(String(told.why)).contains("Yearly risk of dying of hunger 0 → 3 in 100")
	assert_str(String(told.category)).is_equal("Hunger")

func test_the_reasons_add_up_to_the_change()->void:
	GameState.record_health_history(true)
	GameState.elapsed_days+=30.0
	GameState.food_security=0.75
	GameState.population_health=0.60
	GameState.exceptional_hazard_smoothed=0.01
	GameState.exceptional_hazard_causes_smoothed={"Hunger":0.0,"Illness":0.01}
	GameState.record_health_history(true)
	var point:Dictionary=GameState.health_history[-1]
	var total:=0.0
	for reason:Dictionary in GameState.life_change_reasons(GameState.health_history[-2].inputs,point.inputs,float(point.delta)):total+=float(reason.years)
	assert_float(total).is_equal_approx(float(point.delta),0.05)

func test_an_older_month_without_causes_says_so_or_tells_its_health()->void:
	var history:Array=[{"day":0,"health":0.70},{"day":30,"health":0.64,"delta":-0.5}]
	var told:=Words.tell([],-0.5,1,history)
	assert_str(String(told.name)).is_equal("More people sick")
	assert_str(String(told.why)).is_equal("Health 70% → 64%")
	history=[{"day":0,"health":0.70},{"day":30,"health":0.70,"delta":0.6}]
	told=Words.tell([],0.6,1,history)
	assert_str(String(told.why)).contains("did not record its causes")
