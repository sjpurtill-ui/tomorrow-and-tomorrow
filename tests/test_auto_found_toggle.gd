extends GdUnitTestSuite
## NEW TOWNS (scripts/auto_founding.gd): the ruler chooses, while playing,
## whether our leaders found new towns on their own. One flag
## (PeopleDirection.auto_settlement, already saved) is set the same way by the
## Settlement dock's switch, the "Our course" page and the court; the leaders'
## council looks for land only while it is on; a town founded by hand never
## changes it; a town the leaders found is told once in the Chronicle.

const AutoFounding:=preload("res://scripts/auto_founding.gd")
const HomeOrders:=preload("res://scripts/home_orders.gd")
const CivDay:=preload("res://scripts/civilization_day.gd")
const Controller:=preload("res://scripts/civilization_controller.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const Harness:=preload("res://tests/court_eval/harness.gd")
const CASES_PATH:="res://tests/court_eval/cases.json"
const SPARE_ROOT:="user://__auto_found_no_records/"

class FakeHud extends Control:
	var dock:Node=null
	var refreshed:=0
	func request_immediate_dock_refresh()->void:refreshed+=1

var _processing:Dictionary={}

func before()->void:
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]:_processing[node]=node.is_processing()
	# No real key or endpoint reaches this process; every model is a stub.
	for key in ["OPENAI_API_KEY","LEVIATHAN_AI_API_KEY","LEVIATHAN_AI_ENDPOINT","LEVIATHAN_AI_MODEL","LEVIATHAN_AI_READER_MODEL"]:OS.unset_environment(key)

func after()->void:
	CivDay.expansion_hook=Callable()
	CivilizationSystem.set_scout_geography_authority(Callable())
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	ProgressionSystem.reset_for_new_world()
	PeopleDirection.reset_for_new_world()
	WorldSimulation.clear()
	for node:Node in _processing:node.set_process(bool(_processing[node]))
	OS.unset_environment("LEVIATHAN_AI_READER_MODEL")
	preload("res://scripts/ai_mode.gd").reset_for_tests(preload("res://scripts/ai_mode.gd").SETTINGS_PATH)

func after_test()->void:
	CivDay.expansion_hook=Callable()

## A settled people with food and materials to spare, the first home standing.
func _settled_world()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(716203)
	GovernmentPeopleSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	PeopleDirection.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.ensure_population_total(1000)
	GameState.settlement_name="Keansburg"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(14.0,0.0,-9.0)
	GameState.food_stocks={"Fresh plants":0.0,"Fresh meat":0.0,"Fish":0.0,"Dry staples":5000.0,"Preserved food":1000.0}
	GameState.resource_stockpiles={"Food":6000.0,"Timber":500.0,"Fiber Plants":500.0}
	CivilizationSystem.register_player_origin(Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z))
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	PeopleDirection.ensure()

func _texts(node:Node)->String:
	var out:PackedStringArray=[]
	for child in node.find_children("*","",true,false):
		if child is Label:out.append((child as Label).text)
		elif child is Button:out.append((child as Button).text)
	return "\n".join(out)

## The Settlement dock's first page with only what the switch needs.
func _overview(founding:Dictionary)->VBoxContainer:
	var overview:VBoxContainer=auto_free(preload("res://scripts/hud/settlement_overview.gd").new())
	overview.setup({"leader":{},"direction":"","can_direct":false,"choices":[],"current":"",
		"metrics":[{"label":"People living here","value":"1,000"}],"cards":[],"works":{},"founding":founding,
		"on_leader":func():pass,"on_population":func():pass,"on_work":func():pass,"on_rename":func():pass})
	return overview

# --------------------------------------------------------------------------
# The switch in the Settlement dock, and the "Our course" page
# --------------------------------------------------------------------------

func test_dock_switch_sets_and_clears_the_flag_and_both_screens_agree()->void:
	_settled_world()
	var hud:=FakeHud.new();auto_free(hud)
	var provider=preload("res://scripts/hud/content/dock_content_settlement.gd").new(null,hud)
	# On by default: the leaders found them, said in plain words.
	var block:Dictionary=provider.founding_block()
	assert_bool(bool(block.on)).is_true()
	var page:=_overview(block)
	var text:=_texts(page)
	assert_str(text).contains("New towns").contains("Our leaders found them (now)").contains("Only when I order")
	assert_str(text).contains("Our leaders found a new town on their own when good land is free")
	assert_str(text).not_contains("AUTO").not_contains("auto_settlement")
	# One click: only when I order.
	(page.find_child("Choice_Ruler",true,false) as Button).pressed.emit()
	assert_bool(PeopleDirection.auto_settlement).is_false()
	assert_int(hud.refreshed).is_equal(1)
	page=_overview(provider.founding_block())
	text=_texts(page)
	assert_str(text).contains("Only when I order (now)").contains("No new town is founded unless you order it")
	# The "Our course" page reads the same flag and says the same.
	var screen:Control=auto_free(preload("res://scripts/people_direction_screen.gd").new())
	add_child(screen)
	screen._show_page(1)
	assert_str(_texts(screen)).contains("Where new homes are built: you decide")
	# Set it back there: the dock agrees.
	var back:Button=null
	for button in screen.find_children("*","Button",true,false):
		if (button as Button).text=="Let leaders decide":back=button
	assert_object(back).is_not_null()
	back.pressed.emit()
	assert_bool(PeopleDirection.auto_settlement).is_true()
	assert_str(_texts(_overview(provider.founding_block()))).contains("Our leaders found them (now)")
	# And from the dock again, the page follows.
	(_overview(provider.founding_block()).find_child("Choice_Ruler",true,false) as Button).pressed.emit()
	screen._show_page(1)
	assert_str(_texts(screen)).contains("Where new homes are built: you decide")
	screen.queue_free()

func test_dock_words_say_what_keeps_the_leaders_home_and_when_they_look()->void:
	_settled_world()
	GameState.simulation_metrics["food_days"]=400.0
	var words:=String(AutoFounding.dock().words)
	assert_str(words).contains("They next look for land in about")
	# Settlers on the road: the next party waits, said plainly.
	GameState.settlement_convoy={"active":true,"settlement_name":"Rivermeet"}
	assert_str(String(AutoFounding.dock().words)).contains("Not now: settlers are already on the road to Rivermeet")
	# Off: nobody goes unless ordered, and those on the road go on.
	AutoFounding.set_on(false)
	words=String(AutoFounding.dock().words)
	assert_str(words).contains("No new town is founded unless you order it").contains("Found a new settlement")
	assert_str(words).contains("already on the road to Rivermeet go on unless you call them home")
	GameState.settlement_convoy={}

# --------------------------------------------------------------------------
# The court's words
# --------------------------------------------------------------------------

func test_the_court_reads_the_words_for_new_towns()->void:
	for said in ["stop founding new towns","Don't found any more towns without my word","No more new towns unless I say so","Stop sending settlers out",
		"Never settle new land without my word","From now on, no new towns are to be founded without my word","Found new towns only when I order it",
		"Kishan, stop founding new towns!","I will decide where new towns are founded","do not build any more villages"]:
		var reading:=HomeOrders.read(said)
		assert_str(String(reading.get("kind",""))).override_failure_message("'%s' read as %s" % [said,str(reading)]).is_equal("found_towns")
		assert_bool(bool(reading.get("allow",true))).override_failure_message("'%s' should stop them" % said).is_false()
	for said in ["found new towns as you see fit","our leaders may settle new land again","Let our leaders found new towns again",
		"You no longer need my word to found new towns","Start founding new villages again","settle new land whenever it is good","keep founding new towns"]:
		var reading:=HomeOrders.read(said)
		assert_str(String(reading.get("kind",""))).override_failure_message("'%s' read as %s" % [said,str(reading)]).is_equal("found_towns")
		assert_bool(bool(reading.get("allow",false))).override_failure_message("'%s' should let them" % said).is_true()
	# Not the leaders' leave: one town asked for, finding (not founding),
	# houses, a quarrel settled, a question, a foreign town, our recruits.
	for said in ["Found a new town by the river","Bring me the scout who found new land","Build new houses for the families","Settle the quarrel between the hunters",
		"Are our leaders founding new towns?","Why did our leaders found new towns","Recruit 20 more warriors","Send our families to settle in Tsaren"]:
		assert_str(String(HomeOrders.read(said).get("kind",""))).override_failure_message("'%s' was read as the leaders' leave" % said).is_not_equal("found_towns")

func test_court_order_sets_the_switch_with_honest_words()->void:
	_settled_world()
	GameState.simulation_metrics["food_days"]=400.0
	var stopped:=HomeOrders.perform(HomeOrders.read("stop founding new towns"))
	assert_bool(PeopleDirection.auto_settlement).is_false()
	assert_int(int(stopped.count)).is_equal(1)
	assert_str(String(stopped.says)).contains("No new town will be founded unless you order it")
	var again:=HomeOrders.perform(HomeOrders.read("don't found any more towns without my word"))
	assert_int(int(again.count)).is_equal(0)
	assert_str(String(again.says)).contains("already")
	var allowed:=HomeOrders.perform(HomeOrders.read("found new towns as you see fit"))
	assert_bool(PeopleDirection.auto_settlement).is_true()
	assert_int(int(allowed.count)).is_equal(1)
	assert_str(String(allowed.says)).contains("may found new towns again").contains("next council")
	# What keeps them home is said, never hidden behind a promise.
	AutoFounding.set_on(false)
	GameState.simulation_metrics["food_days"]=5.0
	var hungry_allowed:=HomeOrders.perform(HomeOrders.read("our leaders may settle new land again"))
	assert_str(String(hungry_allowed.says)).contains("Nobody goes yet")
	for word in ["it is done","it will be done","carried out"]:
		assert_str(String(hungry_allowed.says).to_lower()).not_contains(word)

func test_court_lines_set_and_clear_it_on_the_offline_and_live_paths()->void:
	var h:=Harness.new(self)
	h.load_cases(CASES_PATH)
	assert_array(Array(h.load_errors)).is_empty()
	var Store:=preload("res://scripts/interaction_store.gd")
	var real_root:=String(Store.user_root)
	Store.user_root=SPARE_ROOT
	var ran:=0
	var failed:=PackedStringArray()
	for c:Dictionary in h.cases:
		if not String(c.id).begins_with("home.found"):continue
		for path:String in ["offline","live"]:
			var r:=h.run(c,path)
			ran+=1
			if not bool(r.ok):failed.append("%s [%s]: %s" % [String(r.id),path,str((r.fails as Array)[0])])
		await await_idle_frame()
	Store.user_root=real_root
	if DirAccess.dir_exists_absolute(SPARE_ROOT):
		for f in DirAccess.get_files_at(SPARE_ROOT):DirAccess.remove_absolute(SPARE_ROOT+f)
		DirAccess.remove_absolute(SPARE_ROOT)
	assert_int(ran).is_greater_equal(8)
	assert_array(Array(failed)).override_failure_message("\n".join(failed)).is_empty()

# --------------------------------------------------------------------------
# The leaders' council
# --------------------------------------------------------------------------

func test_leaders_look_for_land_only_while_the_switch_is_on()->void:
	_settled_world()
	# A council that looks for land (a people without an expansionist tradition
	# looks every sixth month).
	var day:=-1
	for d in range(3000,3400):
		if Controller.review_due("player",d) and posmod(d/30,AutoFounding.LOOK_EVERY_MONTHS)==0:day=d;break
	assert_int(day).is_greater(0)
	GameState.elapsed_days=float(day)
	var looked:Array=[]
	CivDay.expansion_hook=func(d:int)->void:looked.append(d)
	var convoy_step:Dictionary={}
	for step:Dictionary in CivDay.steps(CivDay.plan(day,{})):
		if String(step.label)=="convoy":convoy_step=step
	assert_bool(convoy_step.is_empty()).is_false()
	AutoFounding.set_on(false)
	(convoy_step.call as Callable).call()
	assert_array(looked).is_empty()
	AutoFounding.set_on(true)
	for step:Dictionary in CivDay.steps(CivDay.plan(day,{})):
		if String(step.label)=="convoy":(step.call as Callable).call()
	assert_array(looked).contains_exactly([day])
	# The dock's "next look" is the same council.
	assert_int(AutoFounding.next_look(day-1)).is_equal(day)
	assert_bool(AutoFounding.looks_for_land(day)).is_true()
	AutoFounding.set_on(false)
	assert_bool(AutoFounding.looks_for_land(day)).is_false()

# --------------------------------------------------------------------------
# Founding by hand, founding by the leaders
# --------------------------------------------------------------------------

func _found(delegated:bool,name:String)->Dictionary:
	var destination:=Vector2(GameState.settlement_founded_at.x+8.0,GameState.settlement_founded_at.z)
	var started:=SettlementModel.begin_settlement_convoy(destination,1.0,name,delegated)
	assert_bool(bool(started.ok)).override_failure_message(str(started)).is_true()
	GameState.elapsed_days=float(GameState.settlement_convoy.arrival_day)
	SettlementModel.update_settlement_convoy(destination,1.0)
	return SettlementModel.complete_settlement_convoy(destination)

func _told(key_prefix:String)->Array:
	return Chronicle.entries("whisper").filter(func(e:Dictionary)->bool:return String(e.get("key","")).begins_with(key_prefix))

func test_founding_by_hand_keeps_the_switch_as_it_was()->void:
	_settled_world()
	assert_bool(PeopleDirection.auto_settlement).is_true()
	var completed:=_found(false,"Rivermeet")
	assert_bool(bool(completed.ok)).is_true()
	# The old silent switch-off is gone: the leaders keep their leave.
	assert_bool(PeopleDirection.auto_settlement).is_true()
	assert_bool(bool(completed.get("told",false))).is_false()
	assert_array(_told("leaders_founded:")).is_empty()

func test_a_town_our_leaders_found_is_told_once()->void:
	_settled_world()
	var destination:=Vector2(GameState.settlement_founded_at.x+8.0,GameState.settlement_founded_at.z)
	var started:=SettlementModel.begin_settlement_convoy(destination,1.0,"Reedwater",true)
	assert_bool(bool(started.ok)).override_failure_message(str(started)).is_true()
	assert_bool(bool(GameState.settlement_convoy.get("by_leaders",false))).is_true()
	var convoy:=GameState.settlement_convoy.duplicate(true)
	GameState.elapsed_days=float(GameState.settlement_convoy.arrival_day)
	SettlementModel.update_settlement_convoy(destination,1.0)
	var completed:=SettlementModel.complete_settlement_convoy(destination)
	assert_bool(bool(completed.ok)).is_true()
	assert_bool(bool(completed.get("told",false))).is_true()
	var told:=_told("leaders_founded:")
	assert_int(told.size()).is_equal(1)
	var entry:Dictionary=told[0]
	assert_str(String(entry.title)).is_equal("Our leaders founded Reedwater")
	assert_str(String(entry.text)).contains("walk east of Keansburg").contains("you can stop this in the Settlement panel or tell the")
	assert_str(String(entry.tier)).is_equal("notice")
	assert_str(String((entry.get("action",{}) as Dictionary).get("section",""))).is_equal("settlement")
	# The ticker's line is that entry, the hint whole.
	assert_str(preload("res://scripts/hud/map_ticker_words.gd").latest_telling()).contains("Our leaders founded Reedwater").contains("you can stop this")
	# Once per founding: telling it again adds nothing.
	assert_bool(AutoFounding.tell_founded(completed.settlement,convoy).is_empty()).is_true()
	assert_int(_told("leaders_founded:").size()).is_equal(1)
	# The switch is untouched by the leaders' own founding.
	assert_bool(PeopleDirection.auto_settlement).is_true()
