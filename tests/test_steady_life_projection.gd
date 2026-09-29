extends GdUnitTestSuite
## How long we live reads a month of risks, not one day's luck.
##
## The player, at the life-expectancy chart: "what are these stupid schizo
## bumps in life expectancy caused by 'living conditions have changed' and
## then the reverse!" A village on short water carries a thirst risk that
## climbs with each short day; one wet day resets it. The monthly count read
## the day's raw risks, so a lucky day showed as three winters gained and the
## next month took them back. The projection now reads the risks averaged over
## about a month (GameState.exceptional_hazard_smoothed); deaths still happen
## at each day's own risk.

const DAY:=1.0/30.0
const THIRSTY:={"Natural causes":0.010,"Dehydration":0.012,"Illness":0.004}
const WET_DAY:={"Natural causes":0.010,"Dehydration":0.0,"Illness":0.004}

func before_test()->void:
	GameState.reset_for_new_world(74017)
	GameState.ensure_population_total(120);GameState.housing_capacity=140
	GameState.population_health=0.95;GameState.food_security=0.9

func after_test()->void:
	GameState.reset_for_new_world(74017)

func _live(risks:Dictionary,days:int)->void:
	GameState.simulation_metrics["mortality_components"]=risks.duplicate()
	for i in days:GameState.smooth_exceptional_hazard(DAY)

func _raw()->float:
	var kept:=GameState.exceptional_hazard_smoothed
	GameState.exceptional_hazard_smoothed=-1.0
	var raw:=GameState.projected_life_expectancy()
	GameState.exceptional_hazard_smoothed=kept
	return raw

func test_one_wet_day_does_not_move_how_long_we_live()->void:
	_live(THIRSTY,90)
	var steady:=GameState.projected_life_expectancy()
	_live(WET_DAY,1)
	# Read raw, that one day would have shown more than a winter gained.
	assert_float(_raw()-steady).is_greater(1.0)
	assert_float(absf(GameState.projected_life_expectancy()-steady)).override_failure_message("one wet day moved it by %.2f winters" % absf(GameState.projected_life_expectancy()-steady)).is_less(0.4)

func test_a_lasting_change_still_shows_within_a_season()->void:
	_live(THIRSTY,90)
	var before:=GameState.projected_life_expectancy()
	_live(WET_DAY,90)
	var raw:=_raw()
	assert_float(raw-before).is_greater(1.0)
	assert_float(absf(GameState.projected_life_expectancy()-raw)).override_failure_message("after a season of water it still lags by %.2f" % absf(GameState.projected_life_expectancy()-raw)).is_less(0.3)

func test_a_new_world_starts_from_its_first_day()->void:
	assert_float(GameState.exceptional_hazard_smoothed).is_less(0.0)
	_live(THIRSTY,1)
	assert_float(GameState.exceptional_hazard_smoothed).is_equal_approx(0.016,0.0001)
	assert_float(GameState.projected_life_expectancy()).is_equal_approx(_raw(),0.001)
