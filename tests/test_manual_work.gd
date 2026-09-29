extends GdUnitTestSuite
## WHO SETS THE DAILY WORK (scripts/manual_work.gd): our leaders, as always,
## or the ruler by hand. One switch (PeopleDirection.automatic_work) and one
## split (PeopleDirection.work_baseline), set the same way from The People
## view, the town page and the court. GovernmentPeopleSystem stays the owner
## of daily labour: in the ruler's hands its daily delegation lays the split
## on every town as it is, with no hidden guard or floor, and the People view
## warns from the counts. Everything reads population_allocations.

const Manual:=preload("res://scripts/manual_work.gd")
const HomeOrders:=preload("res://scripts/home_orders.gd")
const Save:=preload("res://scripts/save_system.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Overview:=preload("res://scripts/hud/content/dock_content_overview.gd")
const Screen:=preload("res://scripts/hud/people_screen.gd")
const Settlement:=preload("res://scripts/hud/content/dock_content_settlement.gd")
const TownPage:=preload("res://scripts/hud/settlement_overview.gd")
const Facts:=preload("res://scripts/court_facts.gd")
const Answers:=preload("res://scripts/court_answers.gd")
const Harness:=preload("res://tests/court_eval/harness.gd")
const CASES_PATH:="res://tests/court_eval/cases.json"
const SPARE_ROOT:="user://__manual_work_no_records/"
const STATES:=[["font_color","normal",4.5],["font_hover_color","hover",4.5],["font_pressed_color","pressed",4.5],["font_hover_pressed_color","hover_pressed",4.5],["font_disabled_color","disabled",3.0]]

class FakeHud extends Control:
	signal section_requested(section:String,sub:int)
	var dock:Node=null
	var refreshed:=0
	var opened:Array=[]
	func _init()->void:section_requested.connect(func(section:String,sub:int)->void:opened.append([section,sub]))
	func request_immediate_dock_refresh()->void:refreshed+=1
	func open_detail(_provider:Object,_sub:int=0)->void:pass

class StubTerrain extends Node:
	func _settlement_display_name()->String:return "Keansburg"
	func _open_settlement_naming_panel(_id:String="")->void:pass
	func _discovery_context()->Dictionary:return {}
	func _report_military_action(_r:Dictionary)->void:pass
	func _able_population()->int:return 60
	func _on_settlement_action_pressed()->void:pass

var _processing:Dictionary={}
var slot:=""

func before()->void:
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]:_processing[node]=node.is_processing()
	for key in ["OPENAI_API_KEY","LEVIATHAN_AI_API_KEY","LEVIATHAN_AI_ENDPOINT","LEVIATHAN_AI_MODEL","LEVIATHAN_AI_READER_MODEL"]:OS.unset_environment(key)

func after()->void:
	T.set_color_mode("light")
	CivilizationSystem.set_scout_geography_authority(Callable())
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	SettlementModel.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	ProgressionSystem.reset_for_new_world()
	PeopleDirection.reset_for_new_world()
	WorldSimulation.clear()
	for node:Node in _processing:node.set_process(bool(_processing[node]))
	OS.unset_environment("LEVIATHAN_AI_READER_MODEL")
	preload("res://scripts/ai_mode.gd").reset_for_tests(preload("res://scripts/ai_mode.gd").SETTINGS_PATH)

func after_test()->void:
	if slot!="" and FileAccess.file_exists(SaveSystem.slot_path(slot)):DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	slot=""

## A settled people of `people`, a leader at their first home, the day's
## count made (food and water measured with the split the leaders set).
func _world(people:int=120)->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(716203);GameState.civic_api_enabled=false
	ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();SettlementModel.reset_for_new_world()
	DiscoverySystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world();PeopleDirection.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.ensure_population_total(people)
	GameState.settlement_name="Keansburg"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(14.0,0.0,-9.0)
	GameState.elapsed_days=6*365+40
	GameState.food_stocks={"Fresh plants":0.0,"Fresh meat":0.0,"Fish":0.0,"Dry staples":1800.0,"Preserved food":200.0}
	GameState.resource_stockpiles={"Food":2000.0,"Timber":500.0,"Fiber Plants":500.0}
	CivilizationSystem.register_player_origin(Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z))
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	# The month's council is held: each process_day below is an ordinary day.
	GovernmentPeopleSystem.last_processed_month=(int(GameState.elapsed_days)+60)/30
	PeopleDirection.ensure()
	# A day as the world runs it: the count, the leaders share out the work,
	# and the next count is made with their split.
	_count(100.0,100.0)
	_delegate()
	_count(100.0,100.0)

## The day's count: food made and eaten, and water fetched, measured with
## the hands at work now (the count's own food_workers and collection_workers).
func _count(produced:float,eaten:float)->void:
	var projected:=2000.0/(eaten-produced) if produced<eaten else 9999.0
	# Counted in the town's own scope, as the food and water counts are.
	var food:float=SettlementModel.with_local_population(func()->float:return GameState.effective_workers("Food"))
	var hands:float=SettlementModel.with_local_population(func()->float:return GameState.effective_workers("Logistics")+GameState.effective_workers("Food")*0.22)
	GameState.simulation_metrics.merge({"food_days":2000.0/eaten,"food_production":produced,"food_consumption":eaten,"food_eaten":eaten,"food_spoilage":0.0,"food_net":produced-eaten,
		"food_total_stock":2000.0,"food_workers":food,"food_projected_days":projected,"food_intake_ratio":1.0,"food_labor_share":0.5,"food_forecast_90":{"first_shortage_day":-1}},true)
	GameState.water_metrics={"required_today":100.0,"total_required_today":100.0,"collected_today":100.0,"household_collected_today":40.0,"organized_collection_capacity":60.0,"collection_workers":hands,
		"conveyed_today":0.0,"rain_collected_today":0.0,"cistern_capacity":0.0,"intake_ratio":1.0,"stored":50.0,"days":0.5,"source_accessible":true}

## The daily delegation, as GovernmentPeopleSystem.process_day runs it.
func _delegate()->void:
	GovernmentPeopleSystem.initializing=true
	GovernmentPeopleSystem._delegate_settlements(int(GameState.elapsed_days))
	GovernmentPeopleSystem.initializing=false

## What the leaders' own rules give for this state (the path the ruler's
## hands never touch): each town's focus and its allocations, by its share.
func _leaders_expected()->Dictionary:
	var aggregate:={}
	for role:String in GameState.POPULATION_ROLES:aggregate[role]=0.0
	var satellite:=0.0
	for city:Dictionary in GameState.player_settlements:
		if not bool(city.get("primary",false)):satellite+=maxf(0.0,float(city.get("population_share",0.0)))
	var weight:=0.0
	GovernmentPeopleSystem.initializing=true
	for city:Dictionary in GameState.player_settlements:
		var share:=maxf(0.01,1.0-satellite) if bool(city.get("primary",false)) else maxf(0.001,float(city.get("population_share",0.0)))
		var auto:=bool(city.get("auto_manage",true))
		var leader:=GovernmentPeopleSystem._person_record(int(city.get("leader_person_id",0)))
		var allocations:Dictionary=SettlementModel.with_city_resources(String(city.id),func()->Dictionary:
			var focus:=String(GovernmentPeopleSystem._focus_decision_for_settlement(city).id) if auto else String(city.get("management_focus","balanced"))
			return GovernmentPeopleSystem._allocations_for_focus(focus,leader,auto))
		for role:String in GameState.POPULATION_ROLES:aggregate[role]=float(aggregate[role])+float(allocations.get(role,0.0))*share
		weight+=share
	GovernmentPeopleSystem.initializing=false
	for role:String in GameState.POPULATION_ROLES:aggregate[role]=float(aggregate[role])/weight
	return aggregate

func _assert_same(a:Dictionary,b:Dictionary)->void:
	for role:String in GameState.POPULATION_ROLES:
		assert_float(float(a.get(role,0.0))).override_failure_message("%s: %s vs %s" % [role,str(a.get(role)),str(b.get(role))]).is_equal_approx(float(b.get(role,0.0)),0.000001)

func _total(people:Dictionary)->int:
	var total:=0
	for role:String in GameState.POPULATION_ROLES:total+=int(people.get(role,0))
	return total

func _texts(node:Node)->PackedStringArray:
	var out:PackedStringArray=[]
	for child in node.find_children("*","",true,false):
		if child is Label:out.append((child as Label).text)
		elif child is Button:out.append((child as Button).text)
	return out

## The People view's labour part, built from its provider as the dock does.
func _people_view(hud:FakeHud)->Control:
	var provider=Overview.new(null,hud)
	var block:Dictionary=(provider.tab(0).blocks as Array)[0]
	var screen:VBoxContainer=auto_free(Screen.new())
	# The rail HUD's theme, as every dock inherits it (command_rail_hud.gd).
	screen.theme=T.control_theme()
	screen.size=Vector2(940,1400)
	add_child(screen)
	screen.setup(block)
	return screen.find_child("Labor",true,false)

func _task_row(labor:Node,role:String)->Node:
	return labor.find_child("Task_"+role,true,false)

# --------------------------------------------------------------------------
# Our leaders: today's behaviour, untouched
# --------------------------------------------------------------------------

func test_leaders_mode_is_unchanged()->void:
	_world()
	assert_bool(Manual.manual()).is_false()
	# The same allocations as the leaders' own rules give for the same state,
	# guard and food floor included (a lean count asks for more on food).
	_count(40.0,100.0)
	var expected:=_leaders_expected()
	_delegate()
	_assert_same(GameState.population_allocation_percentages,expected)
	assert_bool(bool(GameState.player_settlements[0].get("survival_guard_active",false))).is_true()
	# Taking the work in hand and giving it back leaves nothing behind.
	Manual.set_manual(true)
	Manual.move("Construction",4)
	Manual.set_manual(false)
	_assert_same(GameState.population_allocation_percentages,expected)
	_delegate()
	_assert_same(GameState.population_allocation_percentages,expected)
	# The count's food_workers is read only: nothing in the simulation reads it
	# but the ruler's forecast (manual_work.gd), and the food count writes it.
	for path:String in _scripts("res://scripts"):
		var text:=FileAccess.get_file_as_string(path)
		if "\"food_workers\"" in text:assert_array(["res://scripts/food_system.gd","res://scripts/manual_work.gd"]).contains([path])

func _scripts(root:String)->Array[String]:
	var out:Array[String]=[]
	for file in DirAccess.get_files_at(root):
		if file.ends_with(".gd"):out.append(root+"/"+file)
	for dir in DirAccess.get_directories_at(root):out.append_array(_scripts(root+"/"+dir))
	return out

func test_the_food_count_says_its_own_hands_and_nothing_else_changes()->void:
	_world()
	var hands:float=SettlementModel.with_local_population(func()->float:return GameState.effective_workers("Food"))
	var result:Dictionary=FoodSystem.process_day({"traveling":false},0.74,0.88)
	assert_float(float(result.food_workers)).is_equal_approx(hands,0.0001)
	assert_float(float(result.food_labor_share)).is_greater(0.0)

# --------------------------------------------------------------------------
# The ruler's split
# --------------------------------------------------------------------------

func test_the_ruler_split_holds_day_after_day_in_every_town()->void:
	_world(240)
	# A second town of ours: the split is the whole realm's.
	var home:Vector2=SettlementModel.settlement_record(SettlementModel._primary_settlement_id()).get("position",Vector2.ZERO)
	GameState.player_settlements.append({"id":"second","name":"Rivermeet","position":home+Vector2(9,4),"primary":false,"population_share":.25,"founded_day":2*365})
	GovernmentPeopleSystem.initialize()
	_delegate()
	var before:=Manual.counts()
	assert_bool(Manual.set_manual(true)).is_true()
	# Taking the work in hand keeps it person for person.
	assert_that(Manual.counts()).is_equal(before)
	var moved:=Manual.move("Construction",6)
	assert_int(int(moved.moved)).is_equal(6)
	var mine:=Manual.counts()
	assert_int(int(mine.Construction)).is_equal(int(before.Construction)+6)
	assert_int(_total(mine)).is_equal(GameState.able_population())
	# A lean count would make the leaders put more on food; the ruler's split
	# holds, day after day, with no guard and no floor.
	_count(40.0,100.0)
	for day in 3:
		GameState.elapsed_days+=1
		GovernmentPeopleSystem.process_day(int(GameState.elapsed_days))
		assert_that(Manual.counts()).is_equal(mine)
	for city:Dictionary in GameState.player_settlements:
		assert_bool(bool(city.get("survival_guard_active",true))).is_false()
		_assert_same(city.local_allocations,Manual.applied_percentages())
		assert_bool(bool(GovernmentPeopleSystem.settlement_management(String(city.id)).ruler_sets_work)).is_true()
	# No leader can shift hands meanwhile; the reason is said.
	var asked:=GovernmentPeopleSystem.set_settlement_focus("second","water")
	assert_bool(bool(asked.ok)).is_false()
	assert_str(String(asked.reason)).contains("You set the daily work yourself")
	assert_that(Manual.counts()).is_equal(mine)

func test_minus_plus_and_five_move_whole_people()->void:
	_world()
	Manual.set_manual(true)
	var start:=Manual.counts()
	var total:=_total(start)
	# + takes one from the task with the most (getting food, here).
	var one:=Manual.move("Knowledge",1)
	var now:=Manual.counts()
	assert_int(int(now.Knowledge)).is_equal(int(start.Knowledge)+1)
	assert_int(int(now.Food)).is_equal(int(start.Food)-1)
	assert_that(one.from).is_equal({"Food":1})
	assert_int(_total(now)).is_equal(total)
	# − gives one back to the task with the most.
	Manual.move("Knowledge",-1)
	assert_that(Manual.counts()).is_equal(start)
	# ×5: five at once.
	Manual.move("Defense",5)
	assert_int(int(Manual.counts().Defense)).is_equal(int(start.Defense)+5)
	assert_int(_total(Manual.counts())).is_equal(total)
	# Nobody can be taken from a task with nobody; the rest is unchanged.
	while int(Manual.counts().Administration)>0:Manual.move("Administration",-1)
	var empty:=Manual.move("Administration",-1)
	assert_bool(bool(empty.ok)).is_false()
	assert_int(_total(Manual.counts())).is_equal(total)
	# "from" a named task.
	var before:=Manual.counts()
	Manual.move("Construction",3,"Logistics")
	assert_int(int(Manual.counts().Logistics)).is_equal(int(before.Logistics)-3)

func test_shares_keep_their_proportions_as_the_people_grow_and_shrink()->void:
	_world(120)
	Manual.set_manual(true)
	Manual.move("Construction",7)
	var shares:=Manual.split()
	var small:=Manual.counts()
	var able:=GameState.able_population()
	# Twice the people: each task about twice, no drift in the shares.
	GameState.ensure_population_total(240)
	_delegate()
	var grown:=Manual.counts()
	assert_int(_total(grown)).is_equal(GameState.able_population())
	var factor:=float(GameState.able_population())/float(able)
	for role:String in GameState.POPULATION_ROLES:
		assert_float(float(grown[role])).override_failure_message(role).is_equal_approx(float(small[role])*factor,1.0)
	_assert_same(Manual.split(),shares)
	# And back: as many who can work as before give the same people, exactly.
	assert_that(Manual.whole_people(Manual.split(),able)).is_equal(small)
	GameState.ensure_population_total(120)
	_delegate()
	assert_int(_total(Manual.counts())).is_equal(GameState.able_population())
	for role:String in GameState.POPULATION_ROLES:
		assert_float(float(Manual.counts()[role])).override_failure_message(role).is_equal_approx(float(small[role])*float(GameState.able_population())/float(able),1.0)
	_assert_same(Manual.split(),shares)

func test_a_task_the_ruler_gave_anyone_keeps_at_least_one()->void:
	_world(120)
	Manual.set_manual(true)
	# One on the watch of about seventy who can work.
	while int(Manual.counts().Defense)>1:Manual.move("Defense",-1)
	assert_int(int(Manual.counts().Defense)).is_equal(1)
	# Fewer people: the share rounds to nothing, one still keeps watch.
	GameState.ensure_population_total(40)
	_delegate()
	var few:=Manual.counts()
	assert_int(int(few.Defense)).is_equal(1)
	assert_int(_total(few)).is_equal(GameState.able_population())
	# A task set to nobody stays nobody as the people grow.
	while int(Manual.counts().Administration)>0:Manual.move("Administration",-1)
	GameState.ensure_population_total(400)
	_delegate()
	assert_int(int(Manual.counts().Administration)).is_equal(0)
	assert_int(int(Manual.counts().Defense)).is_greater_equal(1)
	# The rounding itself: the ledger's largest remainders, then one each.
	var people:=Manual.whole_people({"Food":97.0,"Defense":1.0,"Knowledge":2.0},20)
	assert_int(int(people.Defense)).is_equal(1)
	assert_int(int(people.Knowledge)).is_equal(1)
	assert_int(int(people.Food)).is_equal(18)

# --------------------------------------------------------------------------
# Back to our leaders
# --------------------------------------------------------------------------

func test_back_to_our_leaders_restores_delegation_and_the_chips()->void:
	_world()
	var hud:=FakeHud.new();add_child(hud);auto_free(hud)
	var terrain:=StubTerrain.new();add_child(terrain);auto_free(terrain)
	var id:=String(GameState.player_settlements[0].id)
	var expected:=_leaders_expected()
	Manual.set_manual(true)
	Manual.move("Construction",5)
	# The town page: no chips while the ruler sets the work, one way back.
	var block:Dictionary=(Settlement.new(terrain,hud).tab(0).blocks as Array)[0]
	assert_bool(bool(block.ruler_sets_work)).is_true()
	var page:VBoxContainer=auto_free(TownPage.new());page.size=Vector2(940,1200);add_child(page);page.setup(block)
	assert_object(page.find_child("AskForHands",true,false)).is_null()
	assert_str("\n".join(_texts(page))).contains("You set the daily work yourself.").contains("You set the daily work for all our towns.")
	(page.find_child("SetTheWork",true,false) as Button).pressed.emit()
	assert_array(hud.opened).contains([["overview",0]])
	(page.find_child("BackToLeaders",true,false) as Button).pressed.emit()
	assert_bool(Manual.manual()).is_false()
	_assert_same(GameState.population_allocation_percentages,expected)
	# The chips work as before.
	block=(Settlement.new(terrain,hud).tab(0).blocks as Array)[0]
	page=auto_free(TownPage.new());page.size=Vector2(940,1200);add_child(page);page.setup(block)
	var ask:=page.find_child("AskForHands",true,false)
	assert_object(ask).is_not_null()
	(ask.find_child("Choice_Water",true,false) as Button).pressed.emit()
	assert_str(String(GovernmentPeopleSystem.settlement_management(id).focus)).is_equal("water")
	# The town page has no second "Who does what" screen.
	assert_array(Array(_texts(page.find_child("Reports",true,false)))).not_contains(["Who does what"])
	assert_array(Array(_texts(page.find_child("Reports",true,false)))).contains(["Ages and families","Rename this place"])

# --------------------------------------------------------------------------
# Saves
# --------------------------------------------------------------------------

func test_a_save_keeps_the_mode_and_the_split_and_an_old_save_loads_in_leaders_mode()->void:
	_world()
	slot="manual_work_%d_%d" % [OS.get_process_id(),Time.get_ticks_usec()]
	# An older save: written before the ruler ever took the work (as every
	# save before this change was: automatic_work true, no split).
	assert_bool(bool(SaveSystem.save_game(slot).get("ok",false))).is_true()
	Manual.set_manual(true)
	Manual.move("Construction",4)
	var mine:=Manual.counts()
	var shares:=Manual.split()
	assert_bool(bool(SaveSystem.load_game(slot).get("ok",false))).is_true()
	assert_bool(Manual.manual()).is_false()
	# A save in the ruler's hands comes back in the ruler's hands, the split exact.
	Manual.set_manual(true)
	Manual.move("Construction",4)
	mine=Manual.counts();shares=Manual.split()
	assert_bool(bool(SaveSystem.save_game(slot).get("ok",false))).is_true()
	Manual.set_manual(false)
	assert_bool(bool(SaveSystem.load_game(slot).get("ok",false))).is_true()
	assert_bool(Manual.manual()).is_true()
	_assert_same(Manual.split(),shares)
	_delegate()
	assert_that(Manual.counts()).is_equal(mine)
	# The direction's own export keeps both too.
	var exported:=PeopleDirection.export_state()
	assert_bool(bool(exported.automatic_work)).is_false()
	PeopleDirection.automatic_work=true
	assert_bool(PeopleDirection.import_state(exported).has("ok")).is_true()
	assert_bool(Manual.manual()).is_true()

# --------------------------------------------------------------------------
# Plain warnings, nothing overridden
# --------------------------------------------------------------------------

func test_warnings_show_the_real_forecast_and_nothing_is_overridden()->void:
	_world()
	var food_hands:=float(GameState.simulation_metrics.food_workers)
	Manual.set_manual(true)
	var calm:=Manual.outlook()
	assert_str(String((calm.lines[0] as Dictionary).text)).is_equal("At this split the stores hold.")
	# Twenty off getting food: the count's own harvest, fewer hands.
	Manual.move("Construction",20)
	var ratio:float=SettlementModel.with_local_population(func()->float:return GameState.effective_workers("Food"))/food_hands
	var days:=2000.0/(100.0-100.0*ratio)
	var look:=Manual.outlook()
	assert_float(float(look.food_days)).is_equal_approx(days,0.01)
	var words:=String((look.lines[0] as Dictionary).text)
	assert_str(words).is_equal("At this split the stores last %s." % preload("res://scripts/hud/production_plain.gd").duration_text(days))
	assert_str(String((look.lines[0] as Dictionary).tone)).is_equal("bad")
	# Every carrier set to building: water falls short, said in tens.
	while int(Manual.counts().Logistics)>0:Manual.move("Logistics",-1,"Construction")
	look=Manual.outlook()
	assert_float(float(look.water_ratio)).is_less(0.98)
	var water:=""
	for line:Dictionary in look.lines:
		if String(line.text).begins_with("Water"):water=String(line.text)
	assert_str(water).is_equal("Water: %d in 10 drink enough." % roundi(float(look.water_ratio)*10.0))
	# Nothing rewrites the split: not the day's delegation, not a lean count.
	var mine:=Manual.counts()
	_count(20.0,100.0)
	GameState.water_metrics["intake_ratio"]=0.5
	GovernmentPeopleSystem.process_day(int(GameState.elapsed_days)+1)
	assert_that(Manual.counts()).is_equal(mine)
	assert_int(int(mine.Logistics)).is_equal(0)

# --------------------------------------------------------------------------
# The court's words
# --------------------------------------------------------------------------

func test_the_court_reads_words_for_the_daily_work()->void:
	for said in ["I will set the work myself","I'll decide who does what from now on","Leave the daily work to me","From now on I decide who does what","Let me decide the work"]:
		var reading:=HomeOrders.read(said)
		assert_str(String(reading.get("mode",""))).override_failure_message("'%s' read as %s" % [said,str(reading)]).is_equal("ruler")
	for said in ["let the headman decide the work again","Our leaders may set the work again","Hand the work back to the leaders","Let Kishan decide who does what","I want you to decide the work again","Kishan, decide the work again"]:
		var reading:=HomeOrders.read(said)
		assert_str(String(reading.get("mode",""))).override_failure_message("'%s' read as %s" % [said,str(reading)]).is_equal("leaders")
	var moves:=[["put 10 more on building","Construction",10,false,""],["Put ten more people on building","Construction",10,false,""],["take three off the watch","Defense",3,true,""],
		["Move 5 from food to building","Construction",5,false,"Food"],["add five to the watch","Defense",5,false,""],["put more hands on carrying","Logistics",0,false,""],["two fewer on learning","Knowledge",2,true,""]]
	for row:Array in moves:
		var reading:=HomeOrders.read(String(row[0]))
		assert_str(String(reading.get("role",""))).override_failure_message("'%s' read as %s" % [row[0],str(reading)]).is_equal(String(row[1]))
		assert_int(int(reading.get("count",-1))).override_failure_message(String(row[0])).is_equal(int(row[2]))
		assert_bool(bool(reading.get("fewer",false))).override_failure_message(String(row[0])).is_equal(bool(row[3]))
		assert_str(String(reading.get("other",""))).is_equal(String(row[4]))
	# Not the daily work: other orders, questions, a foreign town, a person.
	for said in ["Build roads between the houses and haul stone to the new houses","Send scouts to the north","Store more grain for the winter","Recruit 20 more warriors",
		"Make the men of Tsaren work the fields","Every seventh day no one works","What are the people working on?","Put Kishan in chains","Put the captives to death",
		"Put more people on the roofs","Give Kavu twenty food","Stop founding new towns","Double the rations for the children this winter","I order you to work the fields"]:
		assert_str(String(HomeOrders.read(said).get("kind",""))).override_failure_message("'%s' was read as the daily work" % said).is_not_equal("work")

func test_court_words_set_the_switch_apply_the_split_and_say_the_numbers()->void:
	_world()
	var start:=Manual.counts()
	var taken:=HomeOrders.perform(HomeOrders.read("I will set the work myself"))
	assert_bool(Manual.manual()).is_true()
	assert_int(int(taken.count)).is_equal(1)
	assert_that(Manual.counts()).is_equal(start)
	assert_str(String(taken.says)).contains("you set the daily work").contains("%d getting food" % int(start.Food))
	var more:=HomeOrders.perform(HomeOrders.read("put 10 more on building"))
	var now:=Manual.counts()
	assert_int(int(now.Construction)).is_equal(int(start.Construction)+10)
	assert_int(int(more.count)).is_equal(10)
	assert_str(String(more.says)).contains("10 more build: %d now, up from %d. They come from getting food." % [int(now.Construction),int(start.Construction)])
	HomeOrders.perform(HomeOrders.read("add five to the watch"))
	now=Manual.counts()
	var fewer:=HomeOrders.perform(HomeOrders.read("take two off the watch"))
	assert_int(int(Manual.counts().Defense)).is_equal(int(now.Defense)-2)
	assert_str(String(fewer.says)).contains("2 fewer keep watch: %d now" % int(Manual.counts().Defense))
	# No number: a twentieth of those who can work, and the count is said.
	var unnamed:=HomeOrders.perform(HomeOrders.read("put more hands on carrying"))
	assert_str(String(unnamed.says)).contains("You named no number, so I moved %d." % maxi(1,roundi(float(Manual.able())/20.0)))
	var back:=HomeOrders.perform(HomeOrders.read("let the headman decide the work again"))
	assert_bool(Manual.manual()).is_false()
	assert_str(String(back.says)).contains("share out the daily work again").contains("%d getting food" % int(Manual.counts().Food))
	for said:String in [String(taken.says),String(more.says),String(fewer.says),String(back.says)]:
		for word in ["it is done","it will be done","carried out"]:assert_str(said.to_lower()).not_contains(word)
	# The headman's sheet and answer say who sets it, from the same switch.
	var sheet:=Facts.sheet(["common","stores"])
	assert_str(Facts.text(sheet)).contains("Who sets the daily work: our leaders share it out")
	Manual.set_manual(true)
	sheet=Facts.sheet(["common","stores"])
	assert_str(Facts.text(sheet)).contains("Who sets the daily work: you set it yourself")
	assert_str(Answers.answer(sheet,"Who decides the work?")).contains("You set the daily work yourself").contains("%d getting food" % int(Manual.counts().Food))

func test_court_lines_on_the_offline_and_live_paths()->void:
	var h:=Harness.new(self)
	h.load_cases(CASES_PATH)
	assert_array(Array(h.load_errors)).is_empty()
	var Store:=preload("res://scripts/interaction_store.gd")
	var real_root:=String(Store.user_root)
	Store.user_root=SPARE_ROOT
	var ran:=0
	var failed:=PackedStringArray()
	for c:Dictionary in h.cases:
		if not (String(c.id).begins_with("work.") or String(c.id).begins_with("q.work.who")):continue
		for path:String in ["offline","live"]:
			var r:=h.run(c,path)
			ran+=1
			if not bool(r.ok):failed.append("%s [%s]: %s" % [String(r.id),path,str((r.fails as Array)[0])])
		await await_idle_frame()
	Store.user_root=real_root
	if DirAccess.dir_exists_absolute(SPARE_ROOT):
		for f in DirAccess.get_files_at(SPARE_ROOT):DirAccess.remove_absolute(SPARE_ROOT+f)
		DirAccess.remove_absolute(SPARE_ROOT)
	assert_int(ran).is_greater_equal(20)
	assert_array(Array(failed)).override_failure_message("\n".join(failed)).is_empty()

# --------------------------------------------------------------------------
# The People view: the switch, the controls, the words, both palettes
# --------------------------------------------------------------------------

func test_the_people_view_shows_the_switch_and_the_controls()->void:
	_world()
	var hud:=FakeHud.new();add_child(hud);auto_free(hud)
	var labor:=_people_view(hud)
	assert_object(labor).is_not_null()
	var text:="\n".join(_texts(labor))
	assert_str(text).contains("Who sets the daily work:").contains("Our leaders (now)").contains("I do")
	# Our leaders: the rows are a view, and a line says who sets it and why.
	assert_object(labor.find_child("Less",true,false)).is_null()
	var who:=labor.find_child("WorkWho",true,false) as Label
	assert_object(who).is_not_null()
	var leader:=String(GovernmentPeopleSystem.settlement_leader(String(GameState.player_settlements[0].id)).get("name","")).get_slice(" ",0)
	assert_str(who.text).starts_with(leader+": ")
	# The rows add up to the people who can work, and the heading says so.
	var sum:=0
	for role:String in GameState.POPULATION_ROLES:
		var row:=_task_row(labor,role)
		assert_object(row).override_failure_message(role).is_not_null()
		sum+=int((row.find_child("Count",true,false) as Label).text)
		assert_int(int((row.find_child("Count",true,false) as Label).text)).is_equal(int(GameState.population_allocations[role]))
	assert_int(sum).is_equal(GameState.able_population())
	assert_str(text).contains("%d can work" % sum)
	# I do: each row has −, + and ×5, in whole people.
	(labor.find_child("WorkRuler",true,false) as Button).pressed.emit()
	assert_bool(Manual.manual()).is_true()
	labor=_people_view(hud)
	text="\n".join(_texts(labor))
	assert_str(text).contains("Back to our leaders").contains("I do (now)").contains("You set the work in every town")
	var build:=_task_row(labor,"Construction")
	var before:=int(GameState.population_allocations.Construction)
	(build.find_child("More",true,false) as Button).pressed.emit()
	assert_int(int(GameState.population_allocations.Construction)).is_equal(before+1)
	(build.find_child("Five",true,false) as Button).pressed.emit()
	assert_int(int(GameState.population_allocations.Construction)).is_equal(before+6)
	(build.find_child("Less",true,false) as Button).pressed.emit()
	assert_int(int(GameState.population_allocations.Construction)).is_equal(before+5)
	assert_int(hud.refreshed).is_greater_equal(4)
	# Tooltips name where each one comes from and goes.
	assert_str((build.find_child("More",true,false) as Button).tooltip_text).contains("from getting food")
	# The warning, in the view, from the counts.
	for i in 4:Manual.move("Construction",5)
	labor=_people_view(hud)
	var warning:=labor.find_child("WorkWarning",true,false) as Label
	assert_object(warning).is_not_null()
	assert_str(warning.text).starts_with("At this split the stores last about")
	# Back to our leaders.
	(labor.find_child("WorkLeaders",true,false) as Button).pressed.emit()
	assert_bool(Manual.manual()).is_false()

func test_era_words_short_labels_and_both_palettes()->void:
	_world()
	var hud:=FakeHud.new();add_child(hud);auto_free(hud)
	Manual.set_manual(true)
	Manual.move("Construction",20)
	for mode:String in ["light","dark"]:
		T.set_color_mode(mode)
		var labor:=_people_view(hud)
		var text:="\n".join(_texts(labor))
		for word in ["GDP","allocation","percent","%","labor force","AUTO","manual"]:
			assert_str(text).override_failure_message("'%s' in %s" % [word,text]).not_contains(word)
		for label in labor.find_children("*","Label",true,false):
			var words:=(label as Label).text.strip_edges().split(" ",false).size()
			assert_int(words).override_failure_message("'%s' has %d words" % [(label as Label).text,words]).is_less_equal(12)
			var ink:=(label as Label).get_theme_color("font_color")
			var ratio:=T.contrast(ink,T.DOCK_BG)
			assert_float(ratio).override_failure_message("'%s' %.2f:1 in %s" % [(label as Label).text,ratio,mode]).is_greater_equal(4.5)
		for button in labor.find_children("*","Button",true,false):
			if (button as Button).text=="":continue
			for state:Array in STATES:
				var style:=(button as Button).get_theme_stylebox(String(state[1]))
				if not style is StyleBoxFlat:continue
				var bg:=(style as StyleBoxFlat).bg_color
				var ground:=T.DOCK_BG.lerp(Color(bg.r,bg.g,bg.b),bg.a)
				var contrast:=T.contrast((button as Button).get_theme_color(String(state[0])),ground)
				assert_float(contrast).override_failure_message("'%s' %s %.2f:1 in %s" % [(button as Button).text,state[1],contrast,mode]).is_greater_equal(float(state[2]))
	T.set_color_mode("light")
