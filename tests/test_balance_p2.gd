extends GdUnitTestSuite
## Balance P2 (docs/PEOPLE_FIRST.md, "Balance P2"): extra learners cost 0.7
## of the births they did; a lead asks a third of the goods it did; a watch past 6 in 100 of the workers costs as extra
## learners do; carers ease crowding; daughter towns claim less new land; every
## non-learning path learns as the balanced one does; food takes about half the
## people's work. The same rules for every people.
const Society:=preload("res://scripts/society_model.gd")
const EarlyCare:=preload("res://scripts/early_life_conditions.gd")
const Paths:=preload("res://scripts/work_paths.gd")
const Food:=preload("res://scripts/food_system.gd")
const Impact:=preload("res://scripts/task_impact.gd")
const R:=preload("res://scripts/research_600_catalog.gd")
const GAME_STATE_SCRIPT:=preload("res://scripts/game_state.gd")
const YEAR:=40

class FakeDiscovery extends Node:
	var effects:Dictionary={}
	func adoption(_id:String)->float:return 1.0
	func effect(id:String)->float:return float(effects.get(id,0.0))
	func discovery_definition(id:String)->Dictionary:return {"id":id,"name":id.capitalize()}

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(515151)
	GameState.initialize_population_model();GameState.ensure_population_total(400)
	GameState.synchronize_population_allocations()
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.elapsed_days=float(YEAR*365)
	var known:Array[String]=[]
	for entry:Dictionary in DiscoverySystem.technology_catalog:
		if DiscoverySystem.research_600_earliest_year(entry)<YEAR-4.0:known.append(String(entry.id))
	GameState.known_discoveries.assign(known)
	GameState.active_investigations.clear();GameState.research_targets.clear();GameState.discovery_progress.clear()
	DiscoverySystem.learning_lead=0.0

func after_test()->void:
	WorldSimulation.clear()

## Learners within the age's share, and a watch of `share` of the able.
func _watch(share:float)->void:
	var able:=float(GameState.able_population())
	GameState.population_allocations["Knowledge"]=0
	GameState.population_allocations["Defense"]=roundi(able*share)
	DiscoverySystem.society_model._rebuild_effect_totals(DiscoverySystem.catalog)

# --- 1. The learning trap ------------------------------------------------------------

func test_extra_learners_cost_fewer_births_than_they_did()->void:
	assert_float(float(Society.SPECIALIST_UPKEEP.conception_support)).is_equal(-0.7)
	var model=DiscoverySystem.society_model
	GameState.population_allocations["Defense"]=0
	GameState.population_allocations["Knowledge"]=0
	model._rebuild_effect_totals(DiscoverySystem.catalog)
	var births:=float(model.effect("conception_support"))
	GameState.population_allocations["Knowledge"]=roundi(float(GameState.able_population())/3.0)
	model._rebuild_effect_totals(DiscoverySystem.catalog)
	var excess:=float(model.specialist_excess)
	assert_float(excess).is_greater(0.2)
	# 0.7 of a point of births for every point past the age's share (the limit aside).
	var floor_:=float((Society.EFFECT_LIMITS.get("conception_support",Vector2(-0.5,0.8)) as Vector2).x)
	assert_float(float(model.effect("conception_support"))).is_equal_approx(maxf(floor_,births-0.7*excess),0.000001)

# --- 4. The watch's upkeep ------------------------------------------------------------

func test_a_watch_within_six_in_100_costs_nothing_more()->void:
	var model=DiscoverySystem.society_model
	_watch(0.0)
	var births:=float(model.effect("conception_support"))
	var work:=float(model.effect("labor_demand"))
	_watch(0.055)
	assert_float(float(model.watch_excess)).is_equal(0.0)
	assert_float(float(model.effect("conception_support"))).is_equal_approx(births,0.000001)
	assert_float(float(model.effect("labor_demand"))).is_equal_approx(work,0.000001)

func test_a_watch_past_six_in_100_costs_as_extra_learners_do()->void:
	var model=DiscoverySystem.society_model
	_watch(0.0)
	var before:={}
	for key:String in Society.SPECIALIST_UPKEEP:before[key]=float(model.effect(key))
	_watch(0.14)
	var over:=float(model.watch_excess)
	assert_float(over).is_equal_approx(Society.watch_share()-Society.WATCH_SUSTAINABLE,0.000001)
	assert_float(over).is_between(0.07,0.09)
	for key:String in Society.SPECIALIST_UPKEEP:
		var limit:Vector2=Society.EFFECT_LIMITS.get(key,Vector2(-0.5,0.8))
		var expected:=clampf(float(before[key])+float(Society.SPECIALIST_UPKEEP[key])*over*Society.WATCH_UPKEEP,limit.x,limit.y)
		assert_float(float(model.effect(key))).override_failure_message(key).is_equal_approx(expected,0.000001)
		assert_float(float(model.upkeep_of(key))).is_equal_approx(float(Society.SPECIALIST_UPKEEP[key])*over*Society.WATCH_UPKEEP,0.000001)
	# Bands away still count: the share reads everyone set to keep watch.
	assert_float(Society.watch_share()).is_equal_approx(float(GameState.population_allocations.Defense)/float(GameState.able_population()),0.000001)

## The People view says it plainly, with the engine's number.
func test_the_people_view_tells_the_watchs_upkeep()->void:
	_watch(0.04)
	var calm:Dictionary=Impact.watch_upkeep_line()
	assert_str(String(calm.label)).is_equal("Watch the people can spare")
	assert_str(String(calm.words)).contains("6 in 100 of the workers")
	_watch(0.14)
	var over:Dictionary=Impact.watch_upkeep_line()
	assert_str(String(over.label)).is_equal("Too many on watch")
	var births:=-float(Society.SPECIALIST_UPKEEP.conception_support)*float(DiscoverySystem.society_model.watch_excess)*100.0
	assert_str(String(over.words)).contains("about %s in 100 fewer births" % Impact._one(births))
	assert_str(String(over.tone)).is_equal("bad")
	# It stands in the watch's own lines on the People view.
	var labels:=[]
	for line:Dictionary in Impact.defense().lines:labels.append(String(line.label))
	assert_array(labels).contains(["Too many on watch"])

# --- 3. Carers ease crowding --------------------------------------------------------------

func _crowded_profile(carers:float)->Dictionary:
	var state:Node=auto_free(GAME_STATE_SCRIPT.new())
	state.reset_for_new_world(5150)
	state.initialize_population_model()
	state.population_health=0.9
	state.food_security=0.9
	state.housing_capacity=4000
	state.early_care_blend=1.0
	for day in 120:state.food_history.append({"day":day,"diet_quality":0.70})
	var discovery:FakeDiscovery=auto_free(FakeDiscovery.new())
	var capacity:=EarlyCare.carrying_capacity(state,discovery)
	state.ensure_population_total(roundi(capacity*0.95))
	return EarlyCare.profile(state,discovery,{"carer_cover":carers})

func test_carers_ease_crowdings_toll_on_deaths_and_births()->void:
	assert_float(EarlyCare.CARER_CROWDING).is_equal(0.5)
	var none:=_crowded_profile(0.0)
	var full:=_crowded_profile(1.0)
	var half:=_crowded_profile(0.5)
	assert_float(float(none.crowding)).is_greater(0.3)
	assert_float(float(full.crowding)).is_equal_approx(float(none.crowding),0.000001)
	assert_float(float(none.crowding_eased)).is_equal_approx(float(none.crowding),0.000001)
	assert_float(float(full.crowding_eased)).is_equal_approx(float(none.crowding)*0.5,0.000001)
	assert_float(float(half.crowding_eased)).is_equal_approx(float(none.crowding)*0.75,0.000001)
	# Fewer of the young die and more children are born where carers tend them.
	assert_float(float(full.conception)).is_greater(float(none.conception))
	assert_float(float((full.burden as Dictionary).under5)).is_less(float((none.burden as Dictionary).under5))

# --- 6. Daughter towns claim less new land ------------------------------------------------

func test_each_daughter_town_claims_less_new_land()->void:
	assert_float(EarlyCare.TERRITORY_SLOPE).is_equal(0.85)
	var state:Node=auto_free(GAME_STATE_SCRIPT.new())
	state.reset_for_new_world(5150)
	state.initialize_population_model()
	var discovery:FakeDiscovery=auto_free(FakeDiscovery.new())
	var home:=EarlyCare.home_capacity(state,discovery)
	var towns:Array[Dictionary]=[{"id":"home","name":"Home","primary":true}]
	for index in 4:towns.append({"id":"t%d" % index,"name":"T%d" % index})
	state.player_settlements.assign(towns)
	# Five towns: home land x (1 + 0.85 x 2).
	assert_float(EarlyCare.carrying_capacity(state,discovery)).is_equal_approx(home*(1.0+0.85*2.0),0.001)

# --- 5. Every non-learning path learns as the balanced one does -----------------------------

func test_every_path_but_learning_keeps_the_balanced_share_of_learners()->void:
	for path:String in ["growth","making","war","building"]:
		assert_float(float(Paths.LEARNING_CAP[path])).override_failure_message(path).is_equal(float(Paths.LEARNING_CAP.balanced))
	assert_float(float(Paths.LEARNING_CAP.learning)).is_greater(float(Paths.LEARNING_CAP.balanced)*3.0)

# --- 7. Food takes about half the work ----------------------------------------------------

func test_food_yields_ask_about_half_the_peoples_work()->void:
	assert_float(Food.BASE_SUBSISTENCE_YIELD_CALIBRATION).is_equal_approx(1.07,0.000001)
	assert_float(Food.CULTIVATION_YIELD).is_equal_approx(4.52,0.000001)
	var source:=FileAccess.get_file_as_string("res://scripts/food_system.gd")
	assert_str(source).contains("workers*cultivation_weight*CULTIVATION_YIELD*")

# --- 2. A lead is dear in goods, not ruinous -------------------------------------------------

func test_a_century_ahead_asks_under_three_times_the_goods()->void:
	assert_float(R.LEAD_GOODS_YEARS).is_equal(60.0)
	# Each learner's goods a day, a century ahead against level with the calendar.
	var dearer:=R.goods_per_learner_day(100.0)/R.goods_per_learner_day(0.0)
	assert_float(dearer).is_between(2.0,3.0)
