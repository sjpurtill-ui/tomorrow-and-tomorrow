extends GdUnitTestSuite
## "How come other civs' city info pages are so much better than my own!"
## Our own town's page (settlement_overview.gd, own_town_model.gd) is drawn
## from its own figures and is at least as rich as a stranger's: the town in
## ink, the local leader's word, every figure grouped with a bar, the foreign
## towns we know as their returned estimate bands, and each row the front
## door to the page that owns its number. One truth: every row equals the
## number its owning dock shows for the same state.

const Provider:=preload("res://scripts/hud/content/dock_content_settlement.gd")
const Overview:=preload("res://scripts/hud/overview_folio.gd")
const Model:=preload("res://scripts/hud/own_town_model.gd")
const Health:=preload("res://scripts/hud/content/dock_detail_health.gd")
const Economy:=preload("res://scripts/hud/content/dock_content_economy.gd")
const Construction:=preload("res://scripts/hud/content/dock_content_construction.gd")
const KPI:=preload("res://scripts/hud/civilization_kpi_model.gd")
const Words:=preload("res://scripts/hud/home_plain.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const V:=preload("res://scripts/hud/city_report_visuals.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Voice:=preload("res://scripts/character_voice.gd")
const Director:=preload("res://scripts/audience_director.gd")
## Words the HUD keeps for the statistical age (tests/test_era_words.gd).
const MODERN:=["GDP","IMR","‰","edu","SCIENCE","worker-days"]
## Button states and the least contrast each needs (tests/test_button_contrast.gd).
const STATES:=[["font_color","normal",4.5],["font_hover_color","hover",4.5],["font_pressed_color","pressed",4.5],["font_hover_pressed_color","hover_pressed",4.5],["font_disabled_color","disabled",3.0]]

class FakeHud extends Control:
	signal section_requested(section:String,sub:int)
	var dock:Node=null
	var refreshed:=0
	var opened:Array=[]
	var details:Array=[]
	func _init()->void:section_requested.connect(func(section:String,sub:int)->void:opened.append([section,sub]))
	func request_immediate_dock_refresh()->void:refreshed+=1
	func open_detail(provider:Object,_sub:int=0)->void:details.append(provider)

class StubTerrain extends Node:
	var naming:Array=[]
	func _settlement_display_name()->String:return "Seanstone"
	func _open_settlement_naming_panel(id:String="")->void:naming.append(id)
	func _discovery_context()->Dictionary:return {}
	func _report_military_action(_r:Dictionary)->void:pass
	func _able_population()->int:return 60
	func _on_settlement_action_pressed()->void:pass

class FakeCourt extends Node:
	var opened:Array=[]
	func open_court(focus:Dictionary={})->Control:
		opened.append(focus.duplicate());return null

var hud:FakeHud
var terrain:StubTerrain
var _processing:Dictionary={}
var _revealed:=""

func before()->void:
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]:_processing[node]=node.is_processing()
	_revealed=Overview.last_revealed

func after()->void:
	T.set_color_mode("light")
	Overview.last_revealed=_revealed
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

func before_test()->void:
	T.set_color_mode("light")
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(515151);GameState.civic_api_enabled=false
	ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();SettlementModel.reset_for_new_world()
	DiscoverySystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();ForeignDiplomacy.ensure();GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_founded_day=0
	GameState.ensure_population_total(93)
	GameState.elapsed_days=31*365+120
	GameState.settlement_completed=["Hearth Circle","Lean-to Shelters","Storage Pits"];GameState.settlement_site_committed=true;GameState.settlement_name="Seanstone"
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	PeopleDirection.reset_for_new_world();PeopleDirection.ensure()
	# A town with something to say on every row: some sleep out, the food is
	# falling, not everyone drinks enough, the walls need mending.
	GameState.housing_capacity=80
	GameState.food_stocks.merge({"Fresh food":300.0,"Stored food":1000.0},true)
	GameState.simulation_metrics.merge({"food_days":45.0,"food_production":20.0,"food_eaten":29.0,"food_spoilage":1.0,"food_net":-10.0,"housing_ratio":0.86,"labor_efficiency":0.74,"cohesion":0.8,"logistics":0.3,"material_capacity":0.4},true)
	GameState.water_metrics={"required_today":93.0,"collected_today":75.0,"intake_ratio":0.8,"stored":30.0,"days":0.3,"source_accessible":true}
	GameState.city_form={"tier":1.0,"condition":0.77,"materials_paid":1.0}
	MilitaryCampaign._ensure_settlement_defense()
	MilitaryCampaign.settlement_defense["stage"]=3;MilitaryCampaign.settlement_defense["integrity"]=0.6
	MilitaryCampaign.home_army["troops"]=37
	hud=FakeHud.new();add_child(hud)
	terrain=StubTerrain.new();add_child(terrain)

func after_test()->void:
	if is_instance_valid(hud):hud.queue_free()
	if is_instance_valid(terrain):terrain.queue_free()
	for court in get_tree().get_nodes_in_group(Director.GROUP):
		if court is FakeCourt:court.queue_free()
	await get_tree().process_frame

# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------

func _block()->Dictionary:
	var page:Dictionary=Provider.new(terrain,hud).tab(0)
	var blocks:Array=page.blocks
	assert_str(String(blocks[0].type)).is_equal("settlement_overview")
	return blocks[0]

func _rows(block:Dictionary)->Dictionary:
	var out:={}
	for group:Dictionary in block.groups:
		for row:Dictionary in group.rows:out[String(row.key)]=row
	return out

func _page(block:Dictionary)->VBoxContainer:
	var page:VBoxContainer=auto_free(Overview.new())
	page.size=Vector2(940,1200)
	add_child(page)
	page.setup(block)
	return page

func _texts(node:Node)->PackedStringArray:
	var out:PackedStringArray=[]
	for child in node.find_children("*","",true,false):
		if child is Label:out.append((child as Label).text)
		elif child is Button:out.append((child as Button).text)
	return out

func _primary_id()->String:
	for city:Dictionary in GameState.player_settlements:
		if bool(city.get("primary",false)):return String(city.id)
	return ""

func _scoped(id:String,read:Callable)->Variant:
	return SettlementModel.with_city_resources(id,func()->Variant:return SettlementModel.with_local_population(read))

## A stranger's town our scouts saw `ago` days back, at quality .6.
func _seen_town(name:String,population:float,ago:int)->Dictionary:
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.player_relation.contact_level=2
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	region["name"]=name;region["population"]=population
	var day:=int(GameState.elapsed_days)-ago
	var intel=CivilizationSystem.city_intelligence
	intel.publish("player",intel.capture("player",String(region.id),.6,day,"physical reconnaissance","test"),day)
	return region

# --------------------------------------------------------------------------
# One truth
# --------------------------------------------------------------------------

func test_every_row_is_the_number_its_own_dock_shows()->void:
	var block:=_block()
	var rows:=_rows(block)
	var id:=_primary_id()
	# Souls: the People screen's own count of this town.
	var local:Dictionary=_scoped(id,func()->Dictionary:return preload("res://scripts/hud/civilization_overview_model.gd").local_snapshot())
	assert_int(int(rows.population.number)).is_equal(int(local.population))
	assert_str(String(rows.population.value)).is_equal(EraWords.people(int(local.population)))
	# How long we live and babes lost: the Health page's own figures.
	var health:Dictionary=Health.new(null,hud).tab(0)
	assert_str(String(rows.life_expectancy.value)).is_equal(String(health.kpis[0].value))
	assert_str(String(rows.infant_mortality.value)).is_equal(String(health.kpis[1].value))
	assert_float(float(rows.life_expectancy.number)).is_equal_approx(float(local.life),0.0001)
	# Food put by and water: the Food page's stores and water.
	var food:Dictionary=(Economy.new(null,hud).tab(0).blocks as Array)[0]
	assert_float(float(rows.supply.number)).is_equal(float(food.food_days))
	var flow:={}
	for key:String in food.flow:flow[key.to_lower()]=float(food.flow[key])
	var reading:=Words.food(float(food.food_days),flow,true)
	assert_str("Food lasts "+String(rows.supply.value)).is_equal(String(reading.headline))
	assert_str(String(rows.supply.note)).is_equal(String(reading.trend))
	assert_float(float(rows.water.number)).is_equal_approx(float(food.water.intake_ratio),0.0001)
	assert_str(String(rows.water.value)).is_equal("8 in 10 drink enough")
	# Roofs, repair and works: the Buildings page.
	var shown:={}
	for city_block:Dictionary in (Construction.new(terrain,hud).tab(0).blocks as Array):
		for item:Dictionary in city_block.get("items",city_block.get("cards",[])):
			if item.has("name"):shown[String(item.name)]=String(item.get("value",""))
	assert_str(String(shown.Housing)).is_equal("%d places" % int(rows.roofs.number))
	assert_str(String(rows.roofs.note)).is_equal("13 sleep out")
	assert_str(String(shown.Condition)).is_equal("%d%%" % int(rows.damage.number))
	var queue:Dictionary=(Construction.new(terrain,hud).tab(1).blocks as Array)[0]
	assert_int(int(rows.works.number)).is_equal(int(queue.completed))
	# Fighters here and walls: the Military ledger. Those who would defend
	# home are its levy, its watch (here the levy alone fills the watch) and
	# its townsfolk who rise.
	var Combat:=preload("res://scripts/civilization_combat.gd")
	var defense:=MilitaryCampaign.settlement_defense_snapshot()
	var home_guard:=Combat.home_defenders()
	# The watch is the army (watch_military.gd): at home its home guard and
	# those free for the bands, all thirty-seven of them.
	assert_int(int(home_guard.trained)+int(home_guard.watch)).is_equal(int(MilitaryCampaign.personnel_ledger().home))
	assert_int(int(rows.garrison.number)).is_equal(int(defense.garrison_personnel))
	assert_int(int(rows.garrison.number)).is_equal(37+int(home_guard.rise))
	assert_int(int(rows.garrison.number)).is_equal(Combat.defenders(id))
	# Those keeping watch and the townsfolk who would rise, apart.
	assert_str(String(rows.garrison.value)).is_equal("37 on watch, %d would take up arms" % int(home_guard.rise))
	assert_str(String(rows.fortification.value)).is_equal(String(defense.short))
	assert_int(int(rows.fortification.number)).is_equal(int(defense.stage))
	assert_str(String(rows.fortification.note)).is_equal("needs repair")
	# Lore keepers: the LORE chip's keepers.
	assert_int(int(rows.learning.number)).is_equal(roundi(float(KPI.snapshot().minds)))
	# What a stranger's scout would count of us is the same ledger.
	var truth:Dictionary=CivilizationSystem.city_intelligence.truth(id).values
	assert_float(float(rows.production.number)).is_equal_approx(float(truth.production),0.0001)
	assert_float(float(rows.logistics.number)).is_equal_approx(float(truth.logistics),0.0001)
	assert_float(float(rows.supply.number)).is_equal_approx(float(truth.supply),0.0001)
	# A scout counts who would defend home (the same rule for every people).
	assert_int(int(rows.garrison.number)).is_equal(int(truth.garrison))
	assert_float(float(rows.fortification.own)).is_equal_approx(float(truth.fortification),0.0001)
	# The leader says the same figures.
	assert_str(String(block.lead)).is_equal("We are ninety-three, thirteen without a roof; food for two moons, falling; eight in ten drink enough.")

# --------------------------------------------------------------------------
# The towns of strangers
# --------------------------------------------------------------------------

func test_foreign_marks_are_only_returned_estimates_and_absent_without_them()->void:
	var block:=_block()
	for row:Dictionary in _rows(block).values():assert_array(row.marks).override_failure_message(String(row.key)).is_empty()
	assert_array(block.legend).is_empty()
	var page:=_page(block)
	assert_object(page.find_child("Legend",true,false)).is_null()
	# Our scouts saw Flintwick three seasons ago.
	var region:=_seen_town("Flintwick",58.0,270)
	var known:=CivilizationSystem.city_intelligence.known("player",String(region.id))
	var field:Dictionary=known.fields.population
	block=_block()
	var rows:=_rows(block)
	assert_int((rows.population.marks as Array).size()).is_equal(1)
	var mark:Dictionary=rows.population.marks[0]
	assert_str(String(mark.name)).is_equal("Flintwick")
	assert_float(float(mark.low)).is_equal(V.bounds(field).x)
	assert_float(float(mark.high)).is_equal(V.bounds(field).y)
	var seen:=EraWords.ago(int(field.observed_day))
	assert_str(seen).ends_with("seasons ago")
	assert_str(String(rows.population.tip)).contains("Flintwick: %s, seen %s." % [V.words("population",field),seen])
	assert_array(block.legend).has_size(1)
	# Only what was brought home: the town's true size is never read.
	region["population"]=5000.0
	var again:Dictionary=_rows(_block()).population.marks[0]
	assert_float(float(again.low)).is_equal(float(mark.low))
	assert_float(float(again.high)).is_equal(float(mark.high))
	# Rows with no estimate of theirs carry no mark: water, roofs, works.
	for key:String in ["water","roofs","works","building"]:assert_array(rows[key].marks).override_failure_message(key).is_empty()
	# Their damage is war damage and our repair counts wear too: their sighting
	# is told in the tooltip, never drawn against our scale.
	assert_bool(bool(rows.damage.get("bands",true))).is_false()
	assert_str(String(rows.damage.tip)).contains("Flintwick: ")
	page.name="PreviousOverview"
	page=_page(block)
	var compare:=page.find_child("CompareTowns",true,false) as Button
	assert_object(compare).is_not_null()
	assert_object(page.find_child("Scale",true,false)).is_null()
	var people:=page.find_child("Row_population",true,false).find_child("Comparison",true,false) as Label
	assert_bool(people.visible).is_false()
	compare.button_pressed=true
	assert_bool(people.visible).is_true()
	assert_str(people.text).contains("Flintwick").contains(String(rows.population.marks[0].words))
	assert_bool(page.update_block(block)).is_true()
	assert_bool(compare.button_pressed).is_true()

# --------------------------------------------------------------------------
# Other towns of ours
# --------------------------------------------------------------------------

func test_a_second_town_shows_its_own_figures_not_home()->void:
	var home:=_rows(_block())
	var home_position:Vector2=SettlementModel.settlement_record(_primary_id()).get("position",Vector2.ZERO)
	GameState.player_settlements.append({"id":"second","name":"Rivermeet","position":home_position+Vector2(9,4),"primary":false,"population_share":.3,"founded_day":20*365})
	GovernmentPeopleSystem.initialize()
	SettlementModel.with_city_resources("second",func()->void:
		GameState.housing_capacity=40
		GameState.settlement_completed=["Hearth Circle"]
		GameState.simulation_metrics.merge({"food_days":300.0,"food_production":20.0,"food_eaten":9.0,"food_spoilage":0.0,"food_net":11.0,"material_capacity":0.1,"logistics":0.12},true)
		GameState.water_metrics={"required_today":28.0,"collected_today":30.0,"intake_ratio":1.0,"stored":9.0,"days":0.3}
		GameState.city_form={"tier":0.0,"condition":0.95,"materials_paid":1.0})
	assert_bool(bool(SettlementModel.select_settlement("second").ok)).is_true()
	var provider:=Provider.new(terrain,hud)
	assert_str(String(provider.meta().title)).is_equal("Rivermeet")
	var block:=_block()
	var rows:=_rows(block)
	var people:=roundi(float(SettlementModel.settlement_by_id("second").population))
	assert_int(int(rows.population.number)).is_equal(people)
	assert_int(int(rows.population.number)).is_not_equal(int(home.population.number))
	assert_float(float(rows.supply.number)).is_equal(300.0)
	assert_int(int(rows.roofs.number)).is_equal(40)
	assert_int(int(rows.works.number)).is_equal(1)
	assert_int(int(rows.damage.number)).is_equal(95)
	assert_str(String(rows.water.value)).is_equal("enough for all")
	# Its own watch and townsfolk, the ones its battle musters, never the home
	# levy; no walls.
	var Combat:=preload("res://scripts/civilization_combat.gd")
	var parts:Dictionary=Combat.guard_ledger().get("second",{})
	assert_int(int(rows.garrison.number)).is_equal(Combat.defenders("second"))
	assert_int(int(rows.garrison.number)).is_equal(int(parts.watch)+int(parts.rise))
	assert_str(String(rows.garrison.value)).is_equal(preload("res://scripts/hud/own_town_model.gd").untrained_words(int(parts.watch),int(parts.rise)))
	assert_str(String(rows.fortification.value)).is_equal("none")
	# The Health page, opened on this town, agrees.
	var health:Dictionary=Health.new(null,hud).tab(0)
	assert_str(String(rows.life_expectancy.value)).is_equal(String(health.kpis[0].value))
	assert_str(String(block.lead)).contains("We are %s" % Model.spoken(people))
	assert_str(String(block.sketch.held_caption)).starts_with("Our hamlet")

# --------------------------------------------------------------------------
# What stays: the leader, the hands, the New towns switch, the reports
# --------------------------------------------------------------------------

func test_seat_growth_leader_card_hands_and_reports_still_act()->void:
	var court:=FakeCourt.new();court.add_to_group(Director.GROUP);add_child(court)
	var id:=_primary_id()
	var page:=_page(_block())
	var text:="\n".join(_texts(page))
	assert_str(text).contains("How our seat grows").contains("district by district")
	assert_object(page.find_child("Choice_Ruler",true,false)).is_null()
	# The one way to ask for more hands.
	var ask:=page.find_child("AskForHands",true,false)
	assert_object(ask).is_not_null()
	(ask.find_child("Choice_Water",true,false) as Button).pressed.emit()
	var management:=GovernmentPeopleSystem.settlement_management(id)
	assert_str(String(management.focus)).is_equal("water")
	assert_bool(bool(management.auto_manage)).is_false()
	# The leader card still calls them to the court.
	(page.find_child("TalkWithLeader",true,false) as Button).pressed.emit()
	assert_int(court.opened.size()).is_equal(1)
	assert_str(String(court.opened[0].get("settlement_id",""))).is_equal(id)
	# The town's own reports and its name.
	var reports:=page.find_child("Reports",true,false)
	var labels:=_texts(reports)
	assert_array(Array(labels)).contains(["Ages and families","Rename this place"])
	# Who does what is The People's to show and set (manual_work.gd), not a second screen here.
	assert_array(Array(labels)).not_contains(["Who does what"])
	for button in reports.find_children("*","Button",true,false):
		if (button as Button).text=="Rename this place":(button as Button).pressed.emit()
		if (button as Button).text=="Ages and families":(button as Button).pressed.emit()
	assert_array(terrain.naming).contains_exactly([id])
	assert_int(hud.details.size()).is_equal(1)
	# The asked-for hands show as the current choice on the next build.
	text="\n".join(_texts(_page(_block())))
	assert_str(text).contains("Water (now)").contains("You asked")

func test_the_leader_counts_in_words_and_seasons()->void:
	assert_str(Model.spoken(7)).is_equal("seven")
	assert_str(Model.spoken(13)).is_equal("thirteen")
	assert_str(Model.spoken(40)).is_equal("forty")
	assert_str(Model.spoken(93)).is_equal("ninety-three")
	assert_str(Model.spoken(2400)).is_equal("2,400")
	assert_str(Model.since(10)).is_equal("this season")
	assert_str(Model.since(45)).is_equal("two moons ago")
	assert_str(Model.since(400)).is_equal("a winter ago")
	assert_str(Model.since(31*365+120)).is_equal("thirty-one winters ago")
	GameState.known_discoveries.append("pictographic_records")
	assert_str(Model.since(400)).is_equal("13 months ago")

func test_the_history_tab_is_unchanged()->void:
	var history:Array=Provider.new(terrain,hud).tab(1).blocks
	assert_str(String(history[0].type)).is_equal("chronicle")
	for block:Dictionary in history:assert_str(String(block.get("type",""))).is_not_equal("settlement_overview")

# --------------------------------------------------------------------------
# Rows: the drawing lights, and each is the owning page's front door
# --------------------------------------------------------------------------

func test_rows_light_the_drawing_and_open_the_page_that_owns_them()->void:
	var page:=_page(_block())
	var sketch:Control=page.find_child("TownSketch",true,false)
	assert_object(sketch).is_not_null()
	var expected:={"life_expectancy":["health",0],"infant_mortality":["health",0],"learning":["inquiry",0],"garrison":["military",0],"fortification":["military",0],"damage":["construction",0],
		"supply":["economy",0],"water":["economy",0],"production":["production",0],"logistics":["economy",1],"roofs":["construction",0],"works":["construction",1],"building":["construction",1]}
	for key:String in expected:
		var row:=page.find_child("Row_"+key,true,false) as Control
		assert_object(row).override_failure_message(key).is_not_null()
		row.mouse_entered.emit()
		assert_str(String(sketch.highlight)).override_failure_message(key).is_equal(String(Overview.OwnSketch.LIGHTS.get(key,key)))
		row.mouse_exited.emit()
		assert_str(String(sketch.highlight)).is_empty()
		var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true
		hud.opened.clear()
		row.gui_input.emit(click)
		assert_array(hud.opened).override_failure_message(key).contains_exactly([expected[key]])
	# The head count opens the town's own ages and families.
	var people:=page.find_child("Row_population",true,false) as Control
	var press:=InputEventMouseButton.new();press.button_index=MOUSE_BUTTON_LEFT;press.pressed=true
	people.gui_input.emit(press)
	assert_int(hud.details.size()).is_equal(1)
	# Each row says where it leads, in its tooltip.
	assert_str(people.tooltip_text).contains("ages and families")
	assert_str((page.find_child("Row_supply",true,false) as Control).tooltip_text).contains("Opens the Food page.")

func test_the_drawing_shows_what_stands()->void:
	var block:=_block()
	var drawing:Dictionary=block.sketch
	# Ink for those under a roof, pencil for the thirteen without.
	assert_float(float(drawing.fields.population.low)).is_equal(80.0)
	assert_float(float(drawing.fields.population.high)).is_equal(93.0)
	assert_int(int(drawing.wall_stage)).is_equal(3)
	assert_float(float(drawing.fields.garrison.low)).is_equal(float(preload("res://scripts/civilization_combat.gd").defenders(_primary_id())))
	assert_float(float(drawing.fields.garrison.low)).is_greater_equal(37.0)
	assert_bool(bool(drawing.flag)).is_true()
	assert_array(drawing.works).contains(["Hearth Circle","Storage Pits"])
	assert_str(String(drawing.held_caption)).is_equal("Our hamlet · settled thirty-one winters ago")
	# The stranger's sketch is not touched: no walls by stage without one.
	var stranger:=preload("res://scripts/hud/city_dossier.gd").Sketch.new()
	assert_bool(stranger.data.has("wall_stage")).is_false()
	stranger.free()

# --------------------------------------------------------------------------
# Era words, short labels, and both palettes
# --------------------------------------------------------------------------

func _words(text:String)->int:
	return text.strip_edges().split(" ",false).size()

func _assert_short(page:Node)->void:
	for label in page.find_children("*","Label",true,false):
		var words:=_words((label as Label).text)
		if String(label.name)=="NewTownsWords":continue
		var most:=18 if String(label.name)=="LeadWords" else 12
		assert_int(words).override_failure_message("'%s' has %d words" % [(label as Label).text,words]).is_less_equal(most)

func test_era_words_before_writing_and_short_labels()->void:
	var page:=_page(_block())
	var text:="\n".join(_texts(page))
	assert_str(text).contains("93 souls").contains("winters").contains("in 100").contains("Babes lost").contains("Food put by").contains("lore ").contains(" passed on")
	for word:String in MODERN:assert_str(text).override_failure_message(word).not_contains(word)
	assert_array(Voice.lexicon_hits(text,Voice.era_tags("player"))).is_empty()
	_assert_short(page)
	# Writing: people and years, the registers' counting.
	GameState.known_discoveries.append("pictographic_records")
	page=_page(_block())
	text="\n".join(_texts(page))
	assert_str(text).contains("93 people").contains("years").contains("in 1,000").contains("Infants buried").contains("records ")
	for word:String in MODERN:assert_str(text).override_failure_message(word).not_contains(word)
	_assert_short(page)
	# Print: the statistical age has its measures.
	GameState.known_discoveries.append("printing_process")
	page=_page(_block())
	text="\n".join(_texts(page))
	assert_str(text).contains("Life expectancy").contains("/ 1,000").contains("schooled")
	_assert_short(page)

func _ground(style:StyleBox)->Color:
	var bg:=(style as StyleBoxFlat).bg_color
	return T.DOCK_BG.lerp(Color(bg.r,bg.g,bg.b),bg.a)

func test_the_page_reads_in_light_and_dark()->void:
	_seen_town("Flintwick",58.0,270)
	for mode:String in ["light","dark"]:
		T.set_color_mode(mode)
		var page:=_page(_block())
		for label in page.find_children("*","Label",true,false):
			var ink:=(label as Label).get_theme_color("font_color")
			var ratio:=T.contrast(ink,T.DOCK_BG)
			assert_float(ratio).override_failure_message("'%s' %.2f:1 in %s" % [(label as Label).text,ratio,mode]).is_greater_equal(4.5)
		for button in page.find_children("*","Button",true,false):
			for state:Array in STATES:
				var style:=(button as Button).get_theme_stylebox(String(state[1]))
				if not style is StyleBoxFlat:continue
				var ratio:=T.contrast((button as Button).get_theme_color(String(state[0])),_ground(style))
				assert_float(ratio).override_failure_message("'%s' %s %.2f:1 in %s" % [(button as Button).text,state[1],ratio,mode]).is_greater_equal(float(state[2]))
		# The caption drawn on the sketch's band.
		assert_float(T.contrast(T.GOLD_TEXT,T.PAPER_SUNK)).is_greater_equal(4.5)
	T.set_color_mode("light")
