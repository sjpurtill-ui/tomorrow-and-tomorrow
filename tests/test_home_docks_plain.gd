extends GdUnitTestSuite
## The home docks read every number as a sentence: a label, a direction and a
## cause. These checks cover the plain readings and the rebuilt ledgers.
const Words=preload("res://scripts/hud/home_plain.gd")
const Works=preload("res://scripts/hud/water_conveyance_controls.gd")

func _texts(node:Node)->String:
	var out:PackedStringArray=[]
	for child in node.find_children("*","",true,false):
		if child is Label:out.append((child as Label).text)
		elif child is Button:out.append((child as Button).text)
	return "\n".join(out)

func test_food_reading_has_duration_direction_and_cause()->void:
	var falling:=Words.food(214.0,{"produced":40.0,"eaten":70.0,"spoiled":2.0,"missions":0.0})
	assert_str(String(falling.headline)).is_equal("Food lasts about 7 months")
	assert_str(String(falling.trend)).is_equal("falling")
	assert_str(String(falling.cause)).is_equal("we eat more than comes in each day")
	var rising:=Words.food(40.0,{"produced":90.0,"eaten":70.0,"spoiled":1.0})
	assert_str(String(rising.trend)).is_equal("rising")
	assert_str(String(rising.sentence)).contains("rising").contains("more comes in")
	var spoiling:=Words.food(20.0,{"produced":70.0,"eaten":68.0,"spoiled":9.0})
	assert_str(String(spoiling.cause)).is_equal("more spoils than we can spare")
	assert_str(String(spoiling.tone)).is_equal("bad")
	assert_str(String(Words.food(0.0,{},false).headline)).contains("not counted yet")

func test_supply_names_what_slows_it()->void:
	assert_str(String(Words.supply(99.0,100.0,0.9).slows)).contains("Storage is what slows us")
	assert_str(String(Words.supply(20.0,100.0,0.3).slows)).is_equal("Hauling is what slows us.")
	assert_str(String(Words.supply(20.0,100.0,1.0).sentence)).contains("everything that is dug and cut")

func test_material_reading_compares_with_last_count()->void:
	var reading:=Words.material(30.0,2.0,0.0,[{"day":0,"value":10.0},{"day":30,"value":20.0}])
	assert_str(String(reading.trend)).is_equal("rising")
	assert_str(String(reading.since)).is_equal("since last month")
	var stuck:=Words.material(3.0,0.0,0.4,[{"day":0,"value":9.0}],"Access not organized")
	assert_str(String(stuck.trend)).is_equal("falling")
	assert_str(String(stuck.cause)).contains("access not organized").contains("spoils or is lost")

func test_words_for_people_numbers()->void:
	assert_str(Words.dependency(10,30)).contains("Few children and elders")
	assert_str(Words.dependency(30,20)).contains("More children and elders than workers")
	assert_str(Words.fit_words(0.85)).is_equal("Suits the office very well")
	assert_str(Words.researchers(0.5)).is_equal("One person, part of the time")
	assert_str(Words.evidence(0.63)).is_equal("most of the way to proof")
	var care:=Words.care(0.25,2.0,{"supported":1.0,"blocker":"Care demand exceeds current staff, observation or local supplies."},3.0,true)
	assert_str(String(care.choice)).is_equal("standard")
	assert_str(String(care.second)).contains("3 sick people are waiting").contains("too few carers")

func test_provisions_ledger_reads_as_sentences_and_marks_the_current_choice()->void:
	var ledger:VBoxContainer=auto_free(preload("res://scripts/hud/provisions_panel.gd").new())
	var asked:Array=[]
	ledger.setup({"city":"Ashford","leader_name":"Tovan","managed":false,"focus":"water","can_direct":true,
		"rows":[{"name":"Fresh food","stock":400.0,"lost":3.0,"detail":"Fresh food: 400 rations in store."}],
		"food_days":214.0,"water":{"required_today":100.0,"collected_today":80.0,"intake_ratio":0.8},
		"forecast30":{},"forecast90":{"first_shortage_day":40},
		"flow":{"Produced":40.0,"Eaten":70.0,"Spoiled":3.0,"Missions":0.0,"Net":-33.0},
		"selected":"","on_select":func(_k:String):pass,"on_focus":func(f:String):asked.append(f),
		"on_water":func():pass,"on_sources":func():pass,"on_history":func():pass,"on_trade":func():pass})
	var text:=_texts(ledger)
	assert_str(text).contains("Food lasts about 7 months").contains("Falling: we eat more than comes in each day")
	assert_str(text).contains("8 in every 10 drink enough").contains("food runs short in about 40 days")
	assert_str(text).contains("Water (now)").contains("Ask Tovan for more hands on")
	assert_str(text).not_contains("▴").not_contains("▾").not_contains("LEADER MANAGED")
	(ledger.find_child("Choice_Provisions",true,false) as Button).pressed.emit()
	assert_array(asked).contains_exactly(["provisions"])

func test_materials_and_wealth_ledgers_use_words()->void:
	var materials:VBoxContainer=auto_free(preload("res://scripts/hud/materials_ledger.gd").new())
	materials.setup({"city":"Ashford","leader":{},"managed":true,"can_direct":true,"focus":"","storage":98.0,"capacity":100.0,"hauling":0.9,
		"rows":[{"key":"Timber","name":"Timber","stock":40.0,"delivered":2.0,"loss":0.0,"points":[{"day":0,"value":30.0}],"details":["North wood: access not organized"],"blocked":false}],
		"incoming":[],"day":10,"selected":"","on_select":func(_k:String):pass,"on_map":func():pass,"on_focus":func(_f:String):pass,"on_trade":func():pass})
	var text:=_texts(materials)
	assert_str(text).contains("Stores are full").contains("Storage is what slows us").contains("Timber: 40 in store").contains("Rising since last month")
	assert_str(text).not_contains("›").not_contains("DELIVERED / DAY")
	var wealth:VBoxContainer=auto_free(preload("res://scripts/hud/wealth_ledger.gd").new())
	wealth.setup({"stage":"subsistence","city":"Ashford","leader":{},"managed":true,"economy":{"gdp":42.0,"gdp_per_capita":0.4,"productivity":0.8,"effective_workers":52.0},
		"history":[],"conditions":{"health":0.5,"cohesion":0.9,"housing":1.0},"accounts":[],"selected":"","show_work":false,
		"on_select":func(_k:String):pass,"on_work":func():pass,"on_history":func():pass,"on_stores":func():pass,"on_policy":func():pass})
	text=_texts(wealth)
	assert_str(text).contains("equals about 42 people working at their best").contains("sickness holds them back most")
	assert_str(text).not_contains("worker-days").not_contains("⌄")

func test_settlement_overview_has_one_ask_row_and_no_override_grid()->void:
	var overview:VBoxContainer=auto_free(preload("res://scripts/hud/settlement_overview.gd").new())
	var asked:Array=[]
	var choices:Array=[]
	for key:String in ["water","provisions"]:choices.append({"id":key,"label":key.capitalize(),"on_press":func():asked.append(key)})
	choices.append({"id":"","label":"Let Tovan decide","on_press":func():asked.append("")})
	var started:Array=[]
	overview.setup({"leader":{},"direction":"You asked Tovan for more hands on water.","can_direct":true,"choices":choices,"current":"water",
		"metrics":[{"label":"People living here","value":"118 souls"}],"cards":[],
		"works":{"progress":[],"offers":[{"id":"work:latrine","title":"Latrine ground","sentence":"Dig latrines well away from the drinking water.","cost":"Costs 4 stone and 2 timber; about 2 months of building.","blocked":"","action":"Build it","on_press":func():started.append(true)}]},
		"on_leader":func():pass,"on_population":func():pass,"on_work":func():pass,"on_rename":func():pass})
	var text:=_texts(overview)
	assert_str(text).contains("Water (now)").contains("Let Tovan decide").contains("Dig latrines").contains("Costs 4 stone")
	assert_str(text).not_contains("OVERRIDE").not_contains("AUTO").not_contains("dependency")
	(overview.find_child("Start_work_latrine",true,false) as Button).pressed.emit()
	assert_bool(started.is_empty()).is_false()

func test_water_works_offers_are_plain_and_start_the_real_work()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("home_works",77)
	WorldSimulation.scoped("home_works",func()->void:
		var state=WorldSimulation.state
		state.settlement_site_committed=true;state.convoy_traveling=false
		state.known_discoveries.append("latrine_siting");state.discovery_adoption["latrine_siting"]=1.0
		state.resource_stockpiles={"Stone":10.0,"Timber":10.0}
		assert_bool(Works.relevant()).is_true()
		var offers:=Works.offers({})
		assert_int(offers.size()).is_equal(1)
		assert_str(String(offers[0].sentence)).contains("latrines")
		assert_str(String(offers[0].cost)).contains("4 stone and 2 timber")
		var result:Dictionary=(offers[0].on_press as Callable).call()
		assert_bool(bool(result.get("ok",false))).is_true()
		assert_str(Works.progress_lines()[0]).contains("being built"))
	WorldSimulation.clear()

func _prepare_settled()->void:
	GameState.reset_for_new_world(771204);GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(120)
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()

class SubHolder extends Node:
	var sub:=0

class FakeHud extends Control:
	var dock:Node=null
	func request_immediate_dock_refresh()->void:pass

func test_health_and_research_docks_build_plain_pages()->void:
	_prepare_settled()
	var hud:=FakeHud.new();auto_free(hud)
	var health=preload("res://scripts/hud/content/dock_detail_health.gd").new(null,hud)
	var page:Dictionary=health.tab(0)
	var text:=JSON.stringify(page)
	assert_str(text).contains("Care of the sick").not_contains("Care duty:").not_contains("population equivalents")
	var inquiry=preload("res://scripts/hud/content/dock_content_inquiry.gd").new(null,hud)
	assert_array(inquiry.meta().subtabs).contains_exactly(["Where we look","Knowledge tree","What we know"])
	var board:VBoxContainer=auto_free(preload("res://scripts/hud/inquiry_board.gd").new())
	board.setup({"fields":[{"id":"health","goal":"keeping people well","weight":2,"share":0.25,"active":1,"on_open":func():pass,"on_more":func():pass,"on_less":func():pass}],
		"investigations":[{"name":"Wound cleaning","dynamic":"health","progress":0.5,"research_workforce":0.5,"estimated_days":400,"bottleneck":"RESEARCH WORKFORCE — a thin team: less than one person at it, where a people of our size would put about 3 on one question"}],
		"on_tree":func():pass,"on_work":func():pass,"on_domain":func(_d:String):pass})
	var words:=_texts(board)
	assert_str(words).contains("About 25 in 100 of our attention").contains("One person, part of the time").contains("about 13 months to proof").contains("Thin team").contains("A thin team: less than one person at it")
	assert_str(words).not_contains("−").not_contains("% attention ·").not_contains("researchers")

func test_economy_dock_titles_follow_the_rail()->void:
	_prepare_settled()
	var hud:=FakeHud.new();auto_free(hud)
	var economy=preload("res://scripts/hud/content/dock_content_economy.gd").new(null,hud)
	assert_str(String(economy.meta().title)).is_equal("Food")
	assert_array(economy.meta().subtabs).contains_exactly(["Food & water","Materials","Wealth","Trade"])
	var dock:=SubHolder.new();auto_free(dock);dock.sub=2;hud.dock=dock
	assert_str(String(economy.meta().title)).is_equal("Wealth")

func test_a_shipment_on_the_way_reads_across_the_row()->void:
	# Regression: the shipment's words folded to one letter a line.
	var materials:VBoxContainer=auto_free(preload("res://scripts/hud/materials_ledger.gd").new())
	materials.setup({"city":"Ashford","leader":{},"managed":true,"can_direct":false,"focus":"","storage":40.0,"capacity":100.0,"hauling":0.9,
		"rows":[],"incoming":[{"quantity":3.0,"resource":"Medicinal Plants","source_name":"Seanstone","arrival_day":14.0}],
		"day":10,"selected":"","on_select":func(_k:String):pass,"on_map":func():pass,"on_focus":func(_f:String):pass,"on_trade":func():pass})
	materials.size=Vector2(1100,600);add_child(materials)
	await get_tree().process_frame;await get_tree().process_frame
	var voice:Control=materials._incoming[0].voice
	var when:Control=materials._incoming[0].when
	assert_str(_texts(materials)).contains("3 medicinal plants on the way").contains("From Seanstone")
	assert_float(voice.size.x).is_greater(400.0)
	assert_float(when.size.x).is_greater(400.0)
	assert_float(voice.size.y).is_less(80.0)
