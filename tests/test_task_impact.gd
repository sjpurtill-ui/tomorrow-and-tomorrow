extends GdUnitTestSuite
## WHAT EACH DAILY TASK DOES (scripts/task_impact.gd), opened from a task's
## name on the People screen (hud/people_screen.gd). Every task explains
## itself in plain words with today's numbers; the numbers follow the rules
## the engine applies, and the screen opens one task at a time, keeps it open
## through the daily refresh and a reopened dock, and closes it again.

const Impact:=preload("res://scripts/task_impact.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Overview:=preload("res://scripts/hud/content/dock_content_overview.gd")
const Screen:=preload("res://scripts/hud/people_screen.gd")
const Manual:=preload("res://scripts/manual_work.gd")

const STATES:=[["font_color","normal",4.5],["font_hover_color","hover",4.5],["font_pressed_color","pressed",4.5],["font_hover_pressed_color","hover_pressed",4.5],["font_disabled_color","disabled",3.0]]
## Words a player should never meet on the People screen.
const DEV_WORDS:=["%","allocation","effective_workers","multiplier","coefficient","GDP","labor force","null","NAN","inf"]

class FakeHud extends Control:
	signal section_requested(section:String,sub:int)
	var dock:Node=null
	var refreshed:=0
	func request_immediate_dock_refresh()->void:refreshed+=1
	func open_detail(_provider:Object,_sub:int=0)->void:pass

var _processing:Dictionary={}

func before()->void:
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]:_processing[node]=node.is_processing()

func after()->void:
	T.set_color_mode("light")
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
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

## A settled people of `people` at their first home, the leaders' split set.
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
	PeopleDirection.ensure()
	ResourceSystem.initialize()
	GameState.simulation_metrics.merge({"labor_efficiency":0.72,"security":0.4,"food_days":40.0,"food_intake_ratio":1.0},true)

## The People view's labour part, built from its provider as the dock does.
func _people_view(hud:FakeHud)->VBoxContainer:
	var provider=Overview.new(null,hud)
	var block:Dictionary=(provider.tab(0).blocks as Array)[0]
	var screen:VBoxContainer=auto_free(Screen.new())
	screen.theme=T.control_theme()
	screen.size=Vector2(940,1400)
	add_child(screen)
	screen.setup(block)
	return screen

func _labor(screen:Node)->Node:
	return screen.find_child("Labor",true,false)

func _texts(node:Node)->PackedStringArray:
	var out:PackedStringArray=[]
	for child in node.find_children("*","",true,false):
		if child is Label:out.append((child as Label).text)
		elif child is Button:out.append((child as Button).text)
	return out

func _assert_plain(text:String,where:String)->void:
	for word:String in DEV_WORDS:
		assert_bool(text.contains(word)).override_failure_message("'%s' in %s: %s" % [word,where,text]).is_false()

# --------------------------------------------------------------------------
# Every task explains itself
# --------------------------------------------------------------------------

func test_every_task_explains_itself_in_plain_words()->void:
	_world()
	for role:String in GameState.POPULATION_ROLES:
		var said:=Impact.of(role)
		assert_str(String(said.get("lead",""))).override_failure_message("%s has no lead" % role).is_not_empty()
		_assert_plain(String(said.lead),role+" lead")
		var lines:Array=said.get("lines",[])
		assert_int(lines.size()).override_failure_message("%s says too little" % role).is_greater_equal(3)
		var costs:=0
		for line:Dictionary in lines:
			for field:String in ["label","value","words"]:
				assert_str(String(line.get(field,""))).override_failure_message("%s: a line with no %s" % [role,field]).is_not_empty()
				_assert_plain(String(line.get(field,"")),"%s %s" % [role,field])
			assert_bool(String(line.get("tone","")) in ["good","bad","plain"]).is_true()
			if String(line.label)=="What it costs":costs+=1
		assert_int(costs).override_failure_message("%s does not say what it costs" % role).is_equal(1)

## The extra food each task eats is the food rules' own table.
func test_the_extra_food_is_the_food_rules_own()->void:
	var source:=FileAccess.get_file_as_string("res://scripts/food_system.gd")
	var parts:PackedStringArray=[]
	for role:String in ["Food","Extraction","Construction","Defense","Survey","Logistics","Crafting","Knowledge","Administration"]:
		parts.append('"%s":%s' % [role,str(Impact.EXERTION[role])])
	assert_str(source).contains("var extras:={%s}" % ",".join(parts))

# --------------------------------------------------------------------------
# Searching the land
# --------------------------------------------------------------------------

## The founding tradition's promise to searchers acts on the real search.
func test_the_founding_promise_to_searchers_is_kept()->void:
	_world()
	var before:=WorldSimulation.consequences.survey_factor()
	# OPEN INQUIRY promises its searchers 15 in 100 more.
	GameState.founding_focus="inquiry"
	var promised:=GameState.founding_effect("survey_output")
	assert_float(promised).is_equal_approx(0.15,0.0001)
	assert_float(WorldSimulation.consequences.survey_factor()).is_equal_approx(before*1.15,0.0001)

func test_searchers_measure_what_is_found_and_nobody_else_can()->void:
	_world()
	# One stone outcrop found and waiting, one still hidden.
	GameState.resource_deposits.clear()
	GameState.resource_deposits.append({"id":"test_found","resource":"Stone","stage":"recognized","survey":0.0,"clues":1.0,"position":Vector3(20.0,0.0,-9.0),"quality":0.8})
	GameState.resource_deposits.append({"id":"test_hidden","resource":"Stone","stage":"unknown","survey":0.0,"clues":0.2,"position":Vector3(30.0,0.0,-9.0),"quality":0.8})
	GameState.population_allocations.Survey=0
	assert_str(String(_line(Impact.of("Survey"),"Finding new materials").value)).is_equal("slow")
	var idle:=_line(Impact.of("Survey"),"Measuring what is found")
	assert_str(String(idle.value)).is_equal("stopped")
	assert_str(String(idle.tone)).is_equal("bad")
	GameState.population_allocations.Survey=6
	var working:=_line(Impact.of("Survey"),"Measuring what is found")
	assert_str(String(working.value)).starts_with("next in")
	# The claim line counts the searchers against a tenth of the able.
	var claim:=_line(Impact.of("Survey"),"Land the town claims")
	var share:=clampf(GameState.effective_workers("Survey")/maxf(1.0,float(GameState.able_population())*0.10),0.0,1.0)
	assert_str(String(claim.value)).is_equal("+%d points of reach" % roundi(share*16.0))

## Repair skill and water access (research_mechanics.gd) show in the builders'
## and carriers' numbers as they act in the engine.
func test_research_shows_in_the_builders_and_carriers_numbers()->void:
	_world()
	GameState.population_allocations.Construction=12
	var before:=_line(Impact.of("Construction"),"Keeping the town up")
	DiscoverySystem.society_model.effect_totals["repair_capacity"]=0.5
	var skilled:=_line(Impact.of("Construction"),"Keeping the town up")
	assert_str(String(skilled.words)).contains("Repair skill makes their mending go 1.50 times as far")
	assert_str(String(before.words)).not_contains("Repair skill")
	GameState.water_metrics={"source_distance_km":4.0,"total_required_today":100.0,"collected_today":100.0,"household_collected_today":20.0}
	DiscoverySystem.society_model.effect_totals["water_access"]=0.4
	var water:=_line(Impact.of("Logistics"),"Drinking water")
	# 4 km counts as 4 × (1 − 0.75 × 0.4) = 2.8 km of walking.
	assert_str(String(water.words)).contains("from 4 km off, which wells and channels make a 2.8 km walk")
	DiscoverySystem.society_model.effect_totals.erase("repair_capacity");DiscoverySystem.society_model.effect_totals.erase("water_access")

func _line(said:Dictionary,label:String)->Dictionary:
	for line:Dictionary in said.lines:
		if String(line.label)==label:return line
	return {}

# --------------------------------------------------------------------------
# The People screen
# --------------------------------------------------------------------------

func test_a_task_opens_what_it_does_and_closes_again()->void:
	_world()
	var hud:=FakeHud.new();add_child(hud);auto_free(hud)
	var screen:=_people_view(hud)
	var labor:=_labor(screen)
	assert_object(labor.find_child("TaskImpact",true,false)).is_null()
	assert_str("\n".join(_texts(labor))).contains("Click a task to see what that work does.")
	var watch:=labor.find_child("Task_Defense",true,false)
	(watch.find_child("Task",true,false) as Button).pressed.emit()
	labor=_labor(screen)
	var panel:=labor.find_child("TaskImpact",true,false)
	assert_object(panel).is_not_null()
	var text:="\n".join(_texts(panel))
	assert_str(text).contains("WHAT KEEPING WATCH DOES").contains("What it costs")
	# It sits right under its own row.
	assert_int(panel.get_index()).is_equal(labor.find_child("Task_Defense",true,false).get_index()+1)
	assert_str(String(screen.view_state().task)).is_equal("Defense")
	# The daily refresh keeps it open.
	screen.update_block((Overview.new(null,hud).tab(0).blocks as Array)[0])
	assert_object(_labor(screen).find_child("TaskImpact",true,false)).is_not_null()
	# Another task opens in its place; the same one again closes it.
	(_labor(screen).find_child("Task_Survey",true,false).find_child("Task",true,false) as Button).pressed.emit()
	assert_int(_labor(screen).find_children("TaskImpact","",true,false).size()).is_equal(1)
	assert_str("\n".join(_texts(_labor(screen).find_child("TaskImpact",true,false)))).contains("WHAT SEARCHING THE LAND DOES")
	(_labor(screen).find_child("Task_Survey",true,false).find_child("Task",true,false) as Button).pressed.emit()
	assert_object(_labor(screen).find_child("TaskImpact",true,false)).is_null()
	# A reopened dock brings the open task back.
	screen.restore_view_state({"selected":"","task":"Food"})
	assert_str("\n".join(_texts(_labor(screen).find_child("TaskImpact",true,false)))).contains("WHAT GETTING FOOD DOES")

func test_the_task_names_read_well_in_both_palettes()->void:
	_world()
	var hud:=FakeHud.new();add_child(hud);auto_free(hud)
	for mode:String in ["light","dark"]:
		T.set_color_mode(mode)
		var screen:=_people_view(hud)
		screen.toggle_task("Knowledge")
		for button in _labor(screen).find_children("Task","Button",true,false):
			for state:Array in STATES:
				var style:=(button as Button).get_theme_stylebox(String(state[1]))
				if not style is StyleBoxFlat:continue
				var bg:=(style as StyleBoxFlat).bg_color
				var ground:=T.DOCK_BG.lerp(Color(bg.r,bg.g,bg.b),bg.a)
				var contrast:=T.contrast((button as Button).get_theme_color(String(state[0])),ground)
				assert_float(contrast).override_failure_message("'%s' %s %.2f:1 in %s" % [(button as Button).text,state[1],contrast,mode]).is_greater_equal(float(state[2]))
		for label in _labor(screen).find_child("TaskImpact",true,false).find_children("*","Label",true,false):
			var ink:=(label as Label).get_theme_color("font_color")
			assert_float(T.contrast(ink,T.DOCK_BG)).override_failure_message("'%s' in %s" % [(label as Label).text,mode]).is_greater_equal(4.5)
	T.set_color_mode("light")
