extends GdUnitTestSuite
## INITIATIVE WITHIN THEIR DOMAIN (scripts/office_initiative.gd): an official
## who loves the god takes up their own business when it plainly needs doing,
## through the ordinary order path, with an order card and a chronicle line;
## a dreading one waits for the god's word; nobody acts twice in a month.

const Initiative:=preload("res://scripts/office_initiative.gd")
const Tracker:=preload("res://scripts/order_tracker.gd")
const TEST_SEED:=902214


func before_test()->void:
	GameState.reset_for_new_world(TEST_SEED)
	GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_name="Unbidden Ford"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(12.0,0.0,-8.0)
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	GameState.active_modifiers.clear()


func after_test()->void:
	GameState.active_modifiers.clear()


func _keeper(love:float,fear:float)->Dictionary:
	GovernmentPeopleSystem.government_stage=1
	var person:Dictionary=GovernmentPeopleSystem.people[1]
	person["relationships"]={"sovereign":{"trust":0.6,"respect":0.6,"fear":fear,"resentment":0.0,"obligation":0.5,"love":love}}
	person["office_key"]="Quartermaster"
	GameState.leadership_positions["Quartermaster"]=GovernmentPeopleSystem.person_snapshot(int(person.person_id))
	GameState.simulation_metrics["food_forecast_90"]={"first_shortage_day":40}
	return person


func _rationed()->bool:
	for mod in GameState.active_modifiers:
		if String((mod as Dictionary).get("id","")).begins_with("court_ration"): return true
	return false


func test_a_loving_keeper_rations_unbidden_with_a_card_and_says_why()->void:
	var keeper:=_keeper(0.9,0.05)
	var day:=int(GameState.elapsed_days)
	var events:=Initiative.month(day)
	assert_int(events.size()).is_equal(1)
	assert_bool(_rationed()).is_true()
	assert_str(String(events[0].description)).contains("forecast to run short in 40 days")
	assert_str(String(events[0].description)).contains(String(keeper.name))
	var cards:=Tracker.orders().filter(func(o:Dictionary)->bool: return String(o.get("source",""))=="initiative")
	assert_int(cards.size()).is_equal(1)
	assert_int(int(keeper.last_initiative_day)).is_equal(day)
	# Not twice in a month, and not while the ration stands.
	GameState.active_modifiers.clear()
	assert_int(Initiative.month(day+10).size()).is_equal(0)


func test_a_dreading_keeper_waits_for_the_gods_word()->void:
	_keeper(0.9,0.5)
	assert_int(Initiative.month(int(GameState.elapsed_days)).size()).is_equal(0)
	assert_bool(_rationed()).is_false()
	_keeper(0.5,0.05)
	assert_int(Initiative.month(int(GameState.elapsed_days)).size()).is_equal(0)


func test_nothing_is_done_when_nothing_needs_doing()->void:
	_keeper(0.9,0.05)
	GameState.simulation_metrics["food_forecast_90"]={"first_shortage_day":-1}
	assert_int(Initiative.month(int(GameState.elapsed_days)).size()).is_equal(0)
	assert_bool(_rationed()).is_false()
