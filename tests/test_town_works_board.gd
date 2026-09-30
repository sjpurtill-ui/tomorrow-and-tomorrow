extends GdUnitTestSuite
## The Buildings page's town board (hud/town_works_board.gd, built by
## dock_content_construction.gd). The player: "The building screens are a
## WALL of text and it's tough to see consequences." Each work is now a card:
## a mark, a figure, a bar with days left, before -> after numbers, have /
## need bars and short chips for what stops it; the sentences wait in
## tooltips. The defences are a card of their own. Every figure is the
## engine's (one ledger): here the defence card is checked against the
## defence ledger, the stage table and the shared rule, the visible words
## stay short, and the board reads in light and dark.

const Provider:=preload("res://scripts/hud/content/dock_content_construction.gd")
const Construction:=preload("res://scripts/settlement_construction.gd")
const HomeDefense:=preload("res://scripts/home_defense.gd")
const Controller:=preload("res://scripts/civilization_controller.gd")
const Blocks:=preload("res://scripts/hud/dock_blocks.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")

class FakeHud extends Control:
	signal section_requested(section:String,sub:int)
	var opened:Array=[]
	func _init()->void:section_requested.connect(func(section:String,sub:int)->void:opened.append([section,sub]))
	func request_immediate_dock_refresh()->void:pass
	func open_detail(_provider:Object,_sub:int=0)->void:pass

class StubTerrain extends Node:
	var reports:Array=[]
	func _report_military_action(r:Dictionary)->void:reports.append(r)
	func _on_settlement_action_pressed()->void:pass

var hud:FakeHud
var terrain:StubTerrain
var _processing:Dictionary={}

func before()->void:
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign]:_processing[node]=node.is_processing()

func after()->void:
	T.set_color_mode("light")
	WorldSimulation.clear()
	MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world();FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world();ResourceSystem.reset_for_new_world();SettlementModel.reset_for_new_world()
	PeopleDirection.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	for node:Node in _processing:node.set_process(bool(_processing[node]))

func before_test()->void:
	T.set_color_mode("light")
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(616161)
	ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();SettlementModel.reset_for_new_world()
	DiscoverySystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world();PeopleDirection.reset_for_new_world();PeopleDirection.ensure()
	for civ:Dictionary in CivilizationSystem.civilizations:civ.player_relation.contact_level=0
	hud=FakeHud.new();add_child(hud)
	terrain=StubTerrain.new();add_child(terrain)

func after_test()->void:
	if is_instance_valid(hud):hud.queue_free()
	if is_instance_valid(terrain):terrain.queue_free()

## The player's year-68 town in small: every early work built, 2.6 timber at
## home, five on the watch, two friendly peoples known.
func _town()->void:
	ResourceSystem.initialize()
	GameState.settlement_site_committed=true;GameState.convoy_traveling=false
	GameState.settlement_name="Sean Springs";GameState.settlement_founded_day=0;GameState.elapsed_days=67*365+200
	GameState.settlement_completed.assign(["Hearth Circle","Storage Pits","Gathering Yard","Open Work Area","Lean-to Shelters"])
	GameState.ensure_population_total(229)
	GameState.population_allocations={"Food":50,"Survey":12,"Extraction":11,"Construction":22,"Crafting":9,"Logistics":13,"Knowledge":27,"Administration":6,"Defense":5}
	GameState.simulation_metrics.merge({"labor_efficiency":0.95,"food_days":260.0,"logistics":0.4},true)
	GameState.water_metrics={"source_accessible":true,"intake_ratio":1.0}
	GameState.housing_capacity=240
	SettlementModel.ensure_founded()
	GameState.city_form={"tier":3.0,"condition":0.91,"materials_paid":1.0}
	SettlementModel.rebuild_summary()
	GameState.resource_stockpiles.merge({"Timber":2.57,"Stone":111.7,"Clay":190.0,"Fiber Plants":251.9},true)
	for index in 2:
		var relation:Dictionary=(CivilizationSystem.civilizations[index] as Dictionary).player_relation
		relation.contact_level=2;relation.opinion=0.45;relation.border_tension=0.05

func _page()->Dictionary:
	return Provider.new(terrain,hud).tab(0)

static func _cards(page:Dictionary)->Dictionary:
	var cards:={}
	for block:Dictionary in page.get("blocks",[]):
		if String(block.get("type",""))!="town_works":continue
		for card:Dictionary in block.cards:cards[String(card.get("key",card.name))]=card
	return cards

func _render(page:Dictionary)->VBoxContainer:
	var body:=VBoxContainer.new();body.custom_minimum_size=Vector2(860,0);add_child(body)
	Blocks.render(body,page.blocks)
	return body

func _walk(node:Node,out:Array)->void:
	out.append(node)
	for child in node.get_children():_walk(child,out)

func _find(root:Node,name_start:String,text:String="")->Array:
	var nodes:Array=[];_walk(root,nodes)
	return nodes.filter(func(n:Node)->bool:return String(n.name).begins_with(name_start) and (text=="" or (n is Button and (n as Button).text.begins_with(text))))

# --------------------------------------------------------------------------
# The defences card: one ledger
# --------------------------------------------------------------------------

func test_the_defence_card_shows_the_engines_own_numbers()->void:
	_town()
	var card:Dictionary=_cards(_page()).defences
	var snapshot:=MilitaryCampaign.settlement_defense_snapshot()
	var stage:Dictionary=MilitaryCampaign.SETTLEMENT_DEFENSE_STAGES[1]
	assert_str(String(card.value)).is_equal(String(snapshot.short))
	# Before -> after: the ledger's figures now, the stage table's once built.
	var gains:Array=card.gains
	assert_str(String(gains[0].before)).is_equal("+%d%%" % roundi(float(snapshot.defense_bonus)*100.0))
	assert_str(String(gains[0].after)).is_equal("+%d%%" % roundi(float(stage.defense_bonus)*100.0))
	assert_str(String(gains[1].before)).is_equal("%d km" % roundi(float(snapshot.observation_radius_km)))
	assert_str(String(gains[1].after)).is_equal("%d km" % roundi(float(stage.observation_km)))
	assert_str(String(gains[2].after)).is_equal("%d%%" % roundi(float(stage.store_protection)*100.0))
	# Have against need: the store against twice the bill (the people's rule).
	for need:Dictionary in card.needs:
		assert_float(float(need.have)).is_equal(float(GameState.resource_stockpiles[need.resource]))
		assert_float(float(need.need)).is_equal(float(stage.materials[need.resource])*Controller.DEFENSE_SPARE)
	# The danger meter is the rule's own reading, the tick its need.
	var decision:=Controller.defense_decision(HomeDefense.plan("player"))
	assert_float(float(card.meter.ratio)).is_equal_approx(float(decision.weighed),0.000001)
	assert_float(float(card.meter.tick)).is_equal(float(decision.need))
	# The chips are the reading's blockers, word for word.
	var reading:=HomeDefense.reading()
	assert_array((card.blockers as Array).map(func(b:Dictionary)->String:return String(b.text))).is_equal((reading.blockers as Array).map(func(b:Dictionary)->String:return String(b.text)))
	assert_array((card.blockers as Array).map(func(b:Dictionary)->String:return String(b.text))).contains(["Timber 2 of 20"])
	# Who decides: the people, by default.
	assert_str(String(card.choice.selected)).is_equal("people")

func test_a_rising_stage_shows_its_bar_and_days_left_from_the_ledger()->void:
	_town()
	MilitaryCampaign._ensure_settlement_defense()
	MilitaryCampaign.settlement_defense.merge({"project_stage":1,"project_work":14.0,"project_progress":0.35,"reserved_materials":{"Timber":10.0,"Fiber Plants":4.0},"started_by":"people"},true)
	var card:Dictionary=_cards(_page()).defences
	var construction:Dictionary=MilitaryCampaign.settlement_defense_snapshot().construction
	assert_float(float(card.progress.ratio)).is_equal(0.35)
	assert_float(float(construction.days_left)).is_equal_approx((40.0-14.0)/MilitaryCampaign.settlement_defense_daily_work(1),0.000001)
	assert_str(String(card.progress.text)).is_equal("about %s left" % Plain.span_text(float(construction.days_left)))
	assert_str(String(card.sub)).is_equal("Raising the watch posts · 5 on the watch")
	assert_str(String(card.value)).is_equal("35%")
	assert_array(card.get("blockers",[])).is_empty()

func test_the_choice_and_the_fixes_work_from_the_board()->void:
	_town()
	GameState.population_allocations["Defense"]=0
	GameState.resource_stockpiles["Timber"]=40.0
	var body:=_render(_page())
	# Nobody on the watch: the fix is one click, by the rule's own count.
	var add:=HomeDefense.watch_fix(1)
	var fix:Array=_find(body,"Act","Put %d on the watch" % add)
	assert_int(fix.size()).is_equal(1)
	(fix[0] as Button).pressed.emit()
	assert_int(int(GameState.population_allocations.Defense)).is_equal(add)
	body.queue_free()
	# Build now, from the choice: the works start at once, paid from the store.
	body=_render(_page())
	var build:Array=_find(body,"Choose_build")
	assert_int(build.size()).is_equal(1)
	(build[0] as Button).pressed.emit()
	assert_str(HomeDefense.word()).is_equal("build")
	assert_int(int(MilitaryCampaign.settlement_defense.project_stage)).is_equal(1)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(30.0,0.0001)
	assert_str(String(terrain.reports.back().message)).is_equal("Work begins on the watch posts.")
	body.queue_free()

func test_a_second_town_does_not_show_the_first_towns_defences()->void:
	_town()
	var home:Vector2=SettlementModel.settlement_record(GameState.selected_player_settlement_id).get("position",Vector2.ZERO)
	GameState.player_settlements.append({"id":"second","name":"Rivermeet","position":home+Vector2(9,4),"primary":false,"population_share":0.2,"founded_day":20})
	assert_bool(bool(SettlementModel.select_settlement("second").ok)).is_true()
	assert_bool(_cards(_page()).has("defences")).is_false()

# --------------------------------------------------------------------------
# Finishing a work is an event
# --------------------------------------------------------------------------

func test_a_finished_work_is_stamped_and_told()->void:
	_town()
	GameState.settlement_completed.assign(["Hearth Circle"])
	GameState.resource_stockpiles.merge({"Timber":60.0,"Fiber Plants":60.0},true)
	GameState.population_allocations.Logistics=13
	var pits:Dictionary=Construction._settlement_definitions().filter(func(d:Dictionary)->bool:return String(d.name)=="Storage Pits")[0]
	GameState.settlement_projects["Storage Pits"]=float(pits.days)
	Construction.process_day()
	if not "Storage Pits" in GameState.settlement_completed:
		# The builders were on another work first: finish that one's turn.
		for step in 40:
			if "Storage Pits" in GameState.settlement_completed:break
			Construction.process_day()
	assert_array(GameState.settlement_completed).contains(["Storage Pits"])
	var told:Dictionary={}
	for entry:Dictionary in Chronicle.entries("whisper"):
		if String(entry.title)=="The Storage Pits stand":told=entry
	assert_dict(told).is_not_empty()
	# The pits' room for food, in the engine's own figure (building_impact).
	var room:String=(preload("res://scripts/building_impact.gd").work("Storage Pits").lines as Array).filter(func(l:Dictionary)->bool:return String(l.label)=="Room for food")[0].value
	assert_str(String(told.text)).is_equal("Raised at Sean Springs: room for food %s, water vessels +2 days." % room)
	var card:Dictionary=_cards(_page()).get("just_built",{})
	assert_str(String(card.get("name",""))).is_equal("Storage Pits")
	assert_str(String(card.stamp.text)).is_equal("Built")
	assert_str(String(card.sub)).is_equal("Finished today")

# --------------------------------------------------------------------------
# Glanceable: short words, readable in both palettes
# --------------------------------------------------------------------------

func _long_texts(root:Node)->Array:
	var nodes:Array=[];_walk(root,nodes)
	var long:Array=[]
	for node in nodes:
		if not (node is Label or node is Button):continue
		if not (node as Control).is_visible_in_tree():continue
		var text:String=(node as Label).text if node is Label else (node as Button).text
		var words:=RegEx.create_from_string("[A-Za-z0-9']+").search_all(text).size()
		if words>12:long.append("%s: %s" % [node.name,text])
	return long

func _ground_of(node:Node)->Color:
	var parent:=node.get_parent()
	while parent!=null:
		if parent is PanelContainer:
			var style:=(parent as PanelContainer).get_theme_stylebox("panel")
			if style is StyleBoxFlat:
				var bg:=(style as StyleBoxFlat).bg_color
				if bg.a>=0.999:return bg
				return _ground_of(parent).lerp(Color(bg.r,bg.g,bg.b),bg.a)
		parent=parent.get_parent()
	return T.DOCK_BG

func _contrast_failures(root:Node)->Array:
	var nodes:Array=[];_walk(root,nodes)
	var failures:Array=[]
	for node in nodes:
		if node is Label and (node as Label).is_visible_in_tree() and (node as Label).text!="":
			var ratio:=T.contrast((node as Label).get_theme_color("font_color"),_ground_of(node))
			if ratio<4.5:failures.append("%s '%s' %.2f" % [node.name,(node as Label).text,ratio])
		elif node is Button and (node as Button).is_visible_in_tree():
			var button:Button=node
			for state:Array in [["font_color","normal",4.5],["font_hover_color","hover",4.5],["font_pressed_color","pressed",4.5]]:
				var style:=button.get_theme_stylebox(String(state[1]))
				if not style is StyleBoxFlat:continue
				var bg:=(style as StyleBoxFlat).bg_color
				var ground:=_ground_of(button).lerp(Color(bg.r,bg.g,bg.b),bg.a)
				var ratio:=T.contrast(button.get_theme_color(String(state[0])),ground)
				if ratio<float(state[2]):failures.append("%s %s %.2f" % [button.name,state[1],ratio])
	return failures

func _town_boards(body:Node)->Array:
	var nodes:Array=[];_walk(body,nodes)
	return nodes.filter(func(n:Node)->bool:return String(n.name).begins_with("TownWorksBoard"))

func test_no_visible_label_over_twelve_words_and_both_palettes_read()->void:
	for mode:String in ["light","dark"]:
		T.set_color_mode(mode)
		MilitaryCampaign.reset_for_new_world()
		_town()
		for state:String in ["calm","rising","idle"]:
			if state=="rising":MilitaryCampaign.settlement_defense.merge({"project_stage":1,"project_work":14.0,"project_progress":0.35,"reserved_materials":{"Timber":10.0,"Fiber Plants":4.0}},true)
			if state=="idle":MilitaryCampaign.settlement_defense.merge({"project_stage":-1,"project_work":0.0,"project_progress":0.0},true);GameState.population_allocations["Defense"]=0
			var body:=_render(_page())
			await get_tree().process_frame
			var boards:=_town_boards(body)
			assert_int(boards.size()).is_equal(2)
			for board:Node in boards:
				assert_array(_long_texts(board)).override_failure_message("%s %s" % [mode,state]).is_empty()
				assert_array(_contrast_failures(board)).override_failure_message("%s %s" % [mode,state]).is_empty()
			body.queue_free()
	T.set_color_mode("light")
