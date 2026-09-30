extends GdUnitTestSuite
## The god's own people raise their town's defences by the rule every
## computer ruler follows (home_defense.gd council -> civilization_controller
## defense_decision), unless the god has said otherwise: build now, hold off,
## or let the people decide. The player found them "not building defences"
## with no word why: in their year-68 save the people were never asked (only
## the court could start works), the first town held 2.6 timber of the 10
## watch posts take while the other towns held about 400 each, and a bold
## people reads two friendly neighbours as danger 16 against the 20 watch
## posts need. Here: the rule starts works when danger and means allow; the
## screen's reading names each blocker in numbers; the god's word overrides;
## the word is saved; the Chronicle tells the start and the finish; and the
## materials are paid exactly as the court's order pays them.

const Controller:=preload("res://scripts/civilization_controller.gd")
const Strategy:=preload("res://scripts/civilization_strategy.gd")
const HomeDefense:=preload("res://scripts/home_defense.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const Wary:={"openness":.5,"discipline":.8,"empathy":.7,"assertiveness":.3,"risk_tolerance":.1}
const Bold:={"openness":.7,"discipline":.5,"empathy":.38,"assertiveness":.2,"risk_tolerance":.92}

var _processing:Dictionary={}

func before()->void:
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign]:_processing[node]=node.is_processing()

func after()->void:
	WorldSimulation.clear()
	MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	for node:Node in _processing:node.set_process(bool(_processing[node]))

func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(686868)
	ResourceSystem.reset_for_new_world();SettlementModel.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world();GovernmentPeopleSystem.reset_for_new_world()
	GameState.elapsed_days=67*365+200
	GameState.settlement_site_committed=true
	GameState.settlement_completed.assign(["Hearth Circle"])
	SettlementModel.ensure_founded()
	GameState.ensure_population_total(229)
	GameState.population_allocations["Defense"]=5
	GameState.simulation_metrics["food_days"]=260.0
	GameState.simulation_metrics["labor_efficiency"]=0.95
	for civ:Dictionary in CivilizationSystem.civilizations:civ.player_relation.contact_level=0

func after_test()->void:
	# A rival made for a test is freed with its test.
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()

## The people know `count` peoples, each feeling `opinion` toward them.
func _neighbours(count:int,opinion:float,tension:float=0.05)->void:
	for index in count:
		var relation:Dictionary=(CivilizationSystem.civilizations[index] as Dictionary).player_relation
		relation.contact_level=2;relation.opinion=opinion;relation.border_tension=tension;relation.at_war=false

func _stores(timber:float,fibre:float)->void:
	GameState.resource_stockpiles["Timber"]=timber;GameState.resource_stockpiles["Fiber Plants"]=fibre

func _plan(personality:Dictionary)->Dictionary:
	return Strategy.preferences(personality,{"food_days":260})

func _told(title:String)->Dictionary:
	for entry:Dictionary in Chronicle.entries("whisper"):
		if String(entry.title)==title:return entry
	return {}

# --------------------------------------------------------------------------
# The rule every people follows
# --------------------------------------------------------------------------

func test_the_people_raise_the_next_stage_when_danger_and_means_allow()->void:
	_neighbours(1,-0.5,0.5)
	_stores(40.0,20.0)
	var decision:=HomeDefense.council("player",_plan(Wary))
	assert_bool(bool(decision.build)).override_failure_message(str(decision)).is_true()
	var defense:Dictionary=MilitaryCampaign.settlement_defense
	assert_int(int(defense.project_stage)).is_equal(1)
	assert_str(String(defense.started_by)).is_equal("people")
	# Paid exactly as the court's order pays: the stage's own bill.
	var bill:Dictionary=MilitaryCampaign.SETTLEMENT_DEFENSE_STAGES[1].materials
	assert_float(40.0-float(GameState.resource_stockpiles.Timber)).is_equal_approx(float(bill.Timber),0.0001)
	assert_float(20.0-float(GameState.resource_stockpiles["Fiber Plants"])).is_equal_approx(float(bill["Fiber Plants"]),0.0001)
	# The Chronicle says what was set aside, who raises it and how long.
	var told:=_told("Work begins on the watch posts")
	assert_dict(told).is_not_empty()
	assert_str(String(told.text)).contains("10 timber and 4 plant fiber set aside")
	assert_str(String(told.text)).contains("5 on the watch raise them in about 25 days")
	assert_str(String(told.text)).contains("The people judged the danger worth it")

func test_the_gods_people_and_a_computer_ruler_decide_alike()->void:
	# One rule, the same world: the player's people and a rival reach the
	# same decision on the same facts.
	_neighbours(1,-0.5,0.5)
	_stores(40.0,20.0)
	var mine:=Controller.defense_decision(_plan(Wary))
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	WorldSimulation.create_actor("alpha",777,Vector2.ZERO)
	WorldSimulation.actors.alpha.controller="manual"
	var theirs:Dictionary=WorldSimulation.scoped("alpha",func()->Dictionary:
		var state:=WorldSimulation.state
		state.settlement_site_committed=true
		state.settlement_completed.assign(["Hearth Circle"])
		WorldSimulation.settlements.ensure_founded()
		state.resource_stockpiles.merge({"Timber":40.0,"Fiber Plants":20.0},true)
		state.population_allocations["Defense"]=5
		state.simulation_metrics["food_days"]=260.0
		state.simulation_metrics["labor_efficiency"]=0.95
		WorldSimulation.world.civilizations.append({"id":"stranger","name":"Strangers","alive":true,"player_relation":{"contact_level":2,"opinion":-0.5,"border_tension":0.5,"at_war":false,"treaty":"none"}})
		return Controller.defense_decision(_plan(Wary)))
	for key:String in ["build","wants","stage","danger","wariness","weighed","need","days"]:
		assert_that(theirs[key]).override_failure_message(key).is_equal(mine[key])

func test_the_players_own_plan_reads_the_peoples_temper()->void:
	# The council passes the people's own plan (their lived values as a
	# temper), the same the delegated research and new towns use.
	_neighbours(2,0.45)
	var plan:=HomeDefense.plan("player")
	assert_dict(plan.get("personality",{})).is_equal(preload("res://scripts/leader_personality.gd").from_values(GameState.societal_values))
	var reading:=HomeDefense.reading(plan)
	assert_float(float(reading.danger.weighed)).is_equal_approx(float(Controller.defense_decision(plan).weighed),0.000001)

# --------------------------------------------------------------------------
# When nothing goes up, the reading says exactly why
# --------------------------------------------------------------------------

func test_a_calm_bold_people_short_of_timber_say_why_in_numbers()->void:
	# The player's own year-68 town in small: two friendly peoples, a bold
	# temper, 2.6 timber at home.
	_neighbours(2,0.45)
	_stores(2.57,251.9)
	var plan:=_plan(Bold)
	var decision:=Controller.defense_decision(plan)
	assert_bool(bool(decision.build)).is_false()
	HomeDefense.council("player",plan)
	assert_int(int(MilitaryCampaign.settlement_defense.project_stage)).is_equal(-1)
	var reading:=HomeDefense.reading(plan)
	assert_str(String(reading.status)).is_equal("calm")
	var texts:=(reading.blockers as Array).map(func(b:Dictionary)->String:return String(b.text))
	assert_array(texts).contains(["Danger %d of 20 needed" % floori(float(decision.weighed)*100.0+0.0001)])
	# Twice the watch posts' 10 timber, so it can be spared: 2 of 20.
	assert_array(texts).contains(["Timber 2 of 20"])
	assert_int(texts.size()).is_equal(2)
	# Nobody on the watch is named too, with the fix counted.
	GameState.population_allocations["Defense"]=0
	var idle:=HomeDefense.reading(plan)
	assert_array((idle.blockers as Array).map(func(b:Dictionary)->String:return String(b.text))).contains(["Nobody on the watch"])
	assert_int(HomeDefense.watch_fix(1)).is_greater(0)
	# The people want the works when the danger is enough: then only the
	# means are short, and the town asks its other towns for twice the bill.
	var wary:=_plan(Wary);_neighbours(1,-0.5,0.5)
	GameState.population_allocations["Defense"]=5
	HomeDefense.council("player",wary)
	assert_str(String(HomeDefense.reading(wary).status)).is_equal("waiting")
	assert_dict(HomeDefense.material_targets()).is_equal({"Timber":20.0,"Fiber Plants":8.0})

func test_the_fix_for_an_empty_watch_is_the_rules_own_count()->void:
	_stores(40.0,20.0)
	GameState.population_allocations["Defense"]=0
	var add:=HomeDefense.watch_fix(1)
	# Enough to raise the watch posts at their fastest pace, no more than the
	# planners' base watch: the engine's own figures.
	var full:int=MilitaryCampaign.settlement_defense_full_pace_workers(1)
	var base:=ceili(float(GameState.able_population())*float(GovernmentPeopleSystem.BASE_ALLOCATIONS.Defense)/100.0)
	assert_int(add).is_equal(mini(full,base))
	GameState.population_allocations["Defense"]=add
	assert_float(MilitaryCampaign.settlement_defense_daily_work(1)).is_equal_approx(minf(40.0*MilitaryCampaign.DEFENSE_DAILY_SHARE,float(add)*0.95*MilitaryCampaign.DEFENSE_WORK_PER_HAND),0.000001)
	assert_int(HomeDefense.watch_fix(1)).is_equal(0)

# --------------------------------------------------------------------------
# The god's word overrides
# --------------------------------------------------------------------------

func test_build_now_raises_the_works_whatever_the_danger_and_pays_the_same()->void:
	_neighbours(2,0.45)
	_stores(2.57,251.9)
	var result:=HomeDefense.set_word("build")
	assert_bool(bool(result.ok)).is_true()
	assert_bool(bool(result.started)).is_false()
	# It waits only for what physically starts the works: the bill itself.
	var reading:=HomeDefense.reading(_plan(Bold))
	assert_str(String(reading.status)).is_equal("waiting")
	assert_array((reading.blockers as Array).map(func(b:Dictionary)->String:return String(b.text))).is_equal(["Timber 2 of 10"])
	# Meanwhile the first town asks our other towns for twice the bill.
	assert_dict(HomeDefense.material_targets()).is_equal({"Timber":20.0,"Fiber Plants":8.0})
	# The day the timber is there, the works start, at the god's word.
	GameState.resource_stockpiles["Timber"]=12.0
	var started:=HomeDefense.act("player")
	assert_bool(bool(started.get("ok",false))).is_true()
	assert_int(int(MilitaryCampaign.settlement_defense.project_stage)).is_equal(1)
	assert_str(String(MilitaryCampaign.settlement_defense.started_by)).is_equal("ruler")
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(2.0,0.0001)
	assert_str(String(_told("Work begins on the watch posts").text)).contains("At your word.")
	# While a stage rises nothing more is asked for.
	assert_dict(HomeDefense.material_targets()).is_empty()

func test_hold_off_keeps_even_a_frightened_people_from_building()->void:
	_neighbours(1,-0.5,0.5)
	_stores(40.0,20.0)
	HomeDefense.set_word("hold")
	var decision:=HomeDefense.council("player",_plan(Wary))
	# The rule would build; the god said hold off.
	assert_bool(bool(decision.build)).is_true()
	assert_int(int(MilitaryCampaign.settlement_defense.project_stage)).is_equal(-1)
	var reading:=HomeDefense.reading(_plan(Wary))
	assert_str(String(reading.status)).is_equal("held")
	assert_dict(HomeDefense.material_targets()).is_empty()
	# And letting the people decide again hands it back to their rule.
	HomeDefense.set_word("people")
	HomeDefense.council("player",_plan(Wary))
	assert_int(int(MilitaryCampaign.settlement_defense.project_stage)).is_equal(1)

func test_the_war_leader_knows_the_defences_as_the_screen_shows_them()->void:
	# Asked at court why no walls go up, the war leader reads the same facts.
	_neighbours(2,0.45)
	_stores(2.57,251.9)
	var sheet:=preload("res://scripts/court_facts.gd").sheet(["common","war"])
	var line:=preload("res://scripts/court_facts.gd").text(sheet)
	var reading:=HomeDefense.reading()
	assert_str(line).contains("Town defences: Open ground now")
	for blocker:Dictionary in reading.blockers:assert_str(line).contains(String(blocker.text))
	assert_str(line).contains("the god's word: let the people decide")
	HomeDefense.set_word("hold")
	assert_str(preload("res://scripts/court_facts.gd").text(preload("res://scripts/court_facts.gd").sheet(["common","war"]))).contains("no new works: the god said hold off")

func test_an_unknown_word_is_refused()->void:
	assert_bool(HomeDefense.set_word("walls").has("error")).is_true()
	assert_str(HomeDefense.word()).is_equal("people")

# --------------------------------------------------------------------------
# The finish, the save
# --------------------------------------------------------------------------

func test_a_finished_stage_is_told_with_what_it_now_does()->void:
	_neighbours(1,-0.5,0.5)
	_stores(40.0,20.0)
	HomeDefense.council("player",_plan(Wary))
	var events_before:=GameState.simulation_events.size()
	for day in 40:
		GameState.elapsed_days+=1
		MilitaryCampaign._process_settlement_defense_day()
		if int(MilitaryCampaign.settlement_defense.stage)==1:break
	assert_int(int(MilitaryCampaign.settlement_defense.stage)).is_equal(1)
	var told:=_told("The watch posts stand")
	assert_dict(told).is_not_empty()
	assert_str(String(told.tier)).is_equal("moment")
	assert_str(String(told.text)).contains("Defenders now fight 4% better at home, raiders are seen 40 km off, and 5% of the stores are safe from raids.")
	# Said once: the Chronicle keeps the ledger line, no second clerk's line.
	var clerks:=GameState.simulation_events.filter(func(e:Dictionary)->bool:return String(e.get("title",""))=="Watch posts completed")
	assert_int(clerks.size()).is_equal(0)
	assert_int(GameState.simulation_events.size()).is_greater(events_before-1)
	assert_bool(MilitaryCampaign.settlement_defense.has("started_by")).is_false()

func test_the_word_is_saved_and_an_older_save_lets_the_people_decide()->void:
	HomeDefense.set_word("hold")
	var payload:=MilitaryCampaign.export_state()
	assert_str(String(payload.settlement_defense.word)).is_equal("hold")
	MilitaryCampaign.reset_for_new_world()
	assert_str(HomeDefense.word()).is_equal("people")
	var loaded:Variant=MilitaryCampaign.import_state(payload.duplicate(true))
	assert_bool(loaded is Dictionary and (loaded as Dictionary).has("error")).is_false()
	assert_str(HomeDefense.word()).is_equal("hold")
	# A save from before the word: the people decide, as every people does.
	var older:=payload.duplicate(true)
	(older.settlement_defense as Dictionary).erase("word")
	(older.settlement_defense as Dictionary).erase("council")
	MilitaryCampaign.reset_for_new_world()
	loaded=MilitaryCampaign.import_state(older)
	assert_bool(loaded is Dictionary and (loaded as Dictionary).has("error")).is_false()
	assert_str(HomeDefense.word()).is_equal("people")
	# A stage in progress survives with who started it.
	_neighbours(1,-0.5,0.5);_stores(40.0,20.0)
	HomeDefense.council("player",_plan(Wary))
	var rising:=MilitaryCampaign.export_state()
	MilitaryCampaign.reset_for_new_world()
	MilitaryCampaign.import_state(rising.duplicate(true))
	assert_int(int(MilitaryCampaign.settlement_defense.project_stage)).is_equal(1)
	assert_str(String(MilitaryCampaign.settlement_defense.started_by)).is_equal("people")
