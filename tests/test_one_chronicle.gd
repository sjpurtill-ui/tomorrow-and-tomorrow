extends GdUnitTestSuite
## Fun audit 2, items #5 and #10: one card queue (the Chronicle), no dashboard
## leftovers or developer text in what the player reads, and starts that differ
## with the land.
const Chronicle:=preload("res://scripts/chronicle.gd")
const Card:=preload("res://scripts/hud/chronicle_card.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Rail:=preload("res://scripts/hud/command_rail_hud.gd")
const Board:=preload("res://scripts/hud/known_world_board.gd")
const CivStart:=preload("res://scripts/civilization_start.gd")
const Arc:=preload("res://scripts/opening_arc.gd")
const Names:=preload("res://scripts/resource_names.gd")

## Phrases a clerk or a programmer would write, never the people's own words.
const DEV_TEXT:=["global tracking","omniscient tracking","not a local observation","local observations","value-conserved","unidentified aggregate","aggregate foreign formation","polity","simulated decisions"]

class Host extends Node:
	var game_speed:=3.0
	func _set_game_speed(value:float)->void:game_speed=value

class SheetHud extends Control:
	signal section_requested(section:String,sub:int)
	var dock:=PanelContainer.new()
	var detail_dock:=PanelContainer.new()
	var opened:Array=[]
	func _init()->void:
		add_child(dock);add_child(detail_dock);dock.visible=false;detail_dock.visible=false
	func open_detail(detail:Variant)->void:opened.append(detail)

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(90210)
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.research_notification_mode="milestones"
	Chronicle.pending_cards.clear()


# --- One card queue -------------------------------------------------------------

func test_a_party_home_with_news_is_a_chronicle_card_that_opens_its_report()->void:
	GameState.simulation_events.push_front({"day":0,"title":"SCOUTS RETURN","description":"The scout party returns after 40 days and charts roughly 300 km of land travel. Direct contact was established with the Keshan. They found a cold hearth by the river.","domain":"diplomacy","severity":"major","mission_id":7})
	Chronicle.ingest_day({"discoveries":[],"progression":[]})
	var told:=Chronicle.entries("moment")
	assert_int(told.size()).is_equal(1)
	assert_str(String(told[0].kind)).is_equal("scout")
	assert_dict(told[0].get("action",{})).is_equal({"kind":"scout_report","mission_id":7})
	CivilizationSystem.scout_reports.push_front({"mission_id":7,"day":0,"discoveries":[]})
	var canvas:SubViewport=auto_free(SubViewport.new());canvas.size=Vector2i(1280,800);add_child(canvas)
	var host:=Host.new();canvas.add_child(host)
	var hud:=SheetHud.new();host.add_child(hud)
	var card:=Card.flush(host,hud)
	assert_str(card.action_button.text).is_equal("Hear the scouts' tale")
	card._act()
	assert_int(hud.opened.size()).is_equal(1)
	CivilizationSystem.scout_reports.pop_front()
	assert_float(host.game_speed).is_equal(3.0)


func test_a_quiet_return_stays_a_tally_line()->void:
	GameState.simulation_events.push_front({"day":0,"title":"SCOUTS RETURN","description":"The scout party returns after 12 days and charts roughly 40 km of land travel. They met no other people.","domain":"diplomacy","severity":"major","mission_id":8})
	Chronicle.ingest_day({"discoveries":[],"progression":[]})
	assert_int(Chronicle.entries("moment").size()).is_equal(0)
	assert_str(String(Chronicle.entries("whisper")[0].text)).not_contains("met no other people")


func test_the_card_never_covers_an_open_dock_sheet()->void:
	Chronicle.record({"title":"Smoke on the horizon","tier":"moment","kind":"scout","day":1})
	var canvas:SubViewport=auto_free(SubViewport.new());canvas.size=Vector2i(1280,800);add_child(canvas)
	var host:=Host.new();canvas.add_child(host)
	var hud:=SheetHud.new();host.add_child(hud)
	hud.size=Vector2(1280,800)
	var card:=Card.flush(host,hud)
	await get_tree().process_frame
	assert_bool(card.panel.visible).is_true()
	# A narrow sheet: the card stands beside it.
	hud.dock.position=Vector2(88,64);hud.dock.size=Vector2(560,700);hud.dock.visible=true
	await get_tree().process_frame;await get_tree().process_frame
	assert_bool(card.panel.visible).is_true()
	assert_bool(card.panel.get_global_rect().intersects(hud.dock.get_global_rect())).is_false()
	# A wide sheet leaves no room: the card waits, and its time does not run.
	hud.dock.size=Vector2(980,700)
	await get_tree().process_frame
	var hold:float=card.hold
	await get_tree().process_frame;await get_tree().process_frame
	assert_bool(card.held).is_true()
	assert_bool(card.panel.visible).is_false()
	assert_float(card.hold).is_equal(hold)
	assert_bool(card.showing).is_true()
	# The sheet closes and the card comes back.
	hud.dock.visible=false
	await get_tree().process_frame;await get_tree().process_frame
	assert_bool(card.panel.visible).is_true()


# --- The bars ----------------------------------------------------------------------

func test_the_air_is_felt_before_a_thermometer_and_never_in_fahrenheit()->void:
	assert_str(Rail.temperature_words(-12.0,"↓",[])).is_equal("Bitter cold ↓")
	assert_str(Rail.temperature_words(21.0,"→",[])).is_equal("Warm →")
	assert_str(Rail.temperature_words(21.4,"→",["precision_thermometry"])).is_equal("21°C →")
	for c in [-30.0,0.0,15.0,40.0]:
		assert_str(Rail.temperature_words(c,"→",[])).not_contains("°")


func test_toolbar_words_are_the_peoples()->void:
	assert_str(EraWords.scouts_out(0)).is_equal("⌖ SEND SCOUTS")
	assert_str(EraWords.scouts_out(2)).is_equal("⌖ TWO WALKERS OUT")
	assert_str(EraWords.scouts_out(1)).is_equal("⌖ ONE WALKER OUT")
	for word in EraWords.DISTANCE_WORDS:
		assert_str(String(word)).not_contains("ft")
	assert_str(EraWords.babes_lost_short(300.0)).is_equal("30 in 100 lost")


func test_a_rumored_people_is_never_the_the()->void:
	assert_str(Board.the_name("The Nine Fires")).is_equal("The Nine Fires")
	assert_str(Board.the_name("Keshan")).is_equal("the Keshan")


func test_ores_keep_their_look_until_their_metal_is_known()->void:
	assert_str(ResourceSystem.display_name("Copper Ore")).is_equal("Green-stained Stone")
	assert_str(ResourceSystem.display_name("Iron Ore")).is_equal("Heavy Red Stone")
	assert_str(Names.label("Copper Ore",["copper_smelting"])).is_equal("Copper Ore")
	assert_str(ResourceSystem.display_name("Fiber Plants")).is_equal("Plant Fiber")


## Developer phrasing must never reach a string the player can read. Scans
## every script's string literals; clerk-side error returns and save
## validation messages are excluded, as are comments.
func test_no_developer_text_in_player_strings()->void:
	var hits:=dev_text_hits("res://scripts")
	assert_array(hits).is_empty()


static func dev_text_hits(root:String)->Array[String]:
	var hits:Array[String]=[]
	var literal:=RegEx.new();literal.compile("\"((?:[^\"\\\\]|\\\\.)*)\"")
	var article:=RegEx.new();article.compile("(?i)\\ba (?:expedition|army|unidentified|aggregate|observation)\\b")
	for path in _scripts(root):
		var lines:=FileAccess.get_file_as_string(path).split("\n")
		for index in lines.size():
			var line:=String(lines[index])
			var code:=line.strip_edges()
			if code.begins_with("#"):continue
			var lower:=code.to_lower()
			if "error" in lower or "push_warning" in lower or " in lower" in lower or "save" in lower or "valid" in lower:continue
			for m in literal.search_all(code):
				var text:=m.get_string(1)
				for phrase in DEV_TEXT:
					if text.to_lower().contains(phrase):hits.append("%s:%d %s" % [path,index+1,phrase])
				if article.search(text):hits.append("%s:%d %s" % [path,index+1,article.search(text).get_string()])
	return hits


static func _scripts(root:String)->Array[String]:
	var out:Array[String]=[]
	var dir:=DirAccess.open(root)
	if dir==null:return out
	for file in dir.get_files():
		if file.ends_with(".gd"):out.append(root.path_join(file))
	for sub in dir.get_directories():out.append_array(_scripts(root.path_join(sub)))
	return out


# --- Different lands, different openings ----------------------------------------

func test_each_seat_draws_its_own_order_of_country()->void:
	var order:=CivStart.setting_order(Vector2(1200,-340))
	assert_int(order.size()).is_equal(CivStart.SETTINGS.size())
	assert_array(order).is_equal(CivStart.setting_order(Vector2(1200,-340)))
	var firsts:Dictionary={}
	for i in 60:firsts[CivStart.setting_order(Vector2(i*997,i*-431))[0]]=true
	assert_int(firsts.size()).is_equal(CivStart.SETTINGS.size())


func test_a_seat_settles_in_the_first_kind_of_country_its_land_offers()->void:
	var origin:=Vector2(500,500)
	var order:=CivStart.setting_order(origin)
	var wanted:=String(order[1])
	# Only the second preference exists here, 20 km east; the plain best is at the origin.
	var ground:=func(point:Vector2)->Dictionary:
		var sample:={"height":1.0,"slope":.05,"river_distance_km":0.1,"fertility":.6,"biome":"grassland","woodland":.1,"relief":.05,"precipitation":.8,"coastal":false}
		if point.distance_to(origin+Vector2(20,0))<1.0:
			match wanted:
				"river":sample.relief=-.3;sample.river_distance_km=.1
				"forest_edge":sample.woodland=.35
				"coast":sample.coastal=true
				"hills":sample.relief=.4
				"dry":sample.precipitation=.4
		return sample
	var site:=CivStart.choose(origin,ground)
	assert_vector(site).is_equal_approx(origin+Vector2(20,0),Vector2(.01,.01))
	# With nothing but open country, the plain best site is kept.
	var plain:=func(_point:Vector2)->Dictionary:return {"height":1.0,"slope":.05,"river_distance_km":1.0,"fertility":.6,"biome":"grassland","woodland":.1,"relief":.05,"precipitation":.8,"coastal":false}
	assert_vector(CivStart.choose(origin,plain)).is_equal(origin)


func test_the_forest_edge_opening_is_told_from_real_building()->void:
	GameState.settlement_site_committed=true
	GameState.settlement_founded_day=0
	GameState.elapsed_days=60.0
	PeopleDirection.opening_arc={"seed":int(GameState.world_seed),"founded_day":0,"country":"forest_edge","founding_built":1,"season_seen":0.5,"last_day":59}
	GameState.settlement_completed.assign(["Hearth Circle"])
	assert_dict(Arc._land(60)).is_empty()
	GameState.settlement_completed.append("Drying Racks")
	var beat:=Arc._land(61)
	assert_str(String(beat.get("title",""))).is_equal("Timber from the wood's edge")
	assert_str(String(beat.text)).contains("drying racks")
	assert_bool(Arc.done("land")).is_true()
	assert_dict(Arc._land(62)).is_empty()


func test_an_older_arc_without_a_country_tells_no_land_beat()->void:
	GameState.settlement_site_committed=true
	PeopleDirection.opening_arc={"seed":int(GameState.world_seed),"founded_day":0,"last_day":10}
	assert_dict(Arc._land(40)).is_empty()
