extends GdUnitTestSuite
## PEOPLES WE KNOW (hud/peoples_known_model.gd, hud/peoples_known_board.gd):
## every people we have met, ranked, as we know them. Each foreign figure is
## an estimate from the town reports that came home (city_intelligence),
## summed to a people's totals, with its age and source; never their true
## numbers. Our own row is our own count.

const Model:=preload("res://scripts/hud/peoples_known_model.gd")
const Board:=preload("res://scripts/hud/peoples_known_board.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const WarBoard:=preload("res://scripts/hud/war_board.gd")
const World:=preload("res://scripts/hud/content/dock_content_world.gd")

const TODAY:=400
## A field's base figure, for hand-made reports: each people is a multiple.
const BASE:={"population":100.0,"garrison":10.0,"supply":20.0,"production":0.2,"science_capacity":2.0,"life_expectancy":20.0,"gdp":50.0,"fortification":0.2}

class StubTerrain extends Node:
	func _diplomat_action_presentation(_status:Dictionary,count:int)->Dictionary:return {"disabled":count==0,"tooltip":""}
	func _open_scout_dispatch_panel()->void:pass
	func _open_diplomat_dispatch_panel()->void:pass

class StubHud extends Control:
	var opened:RefCounted
	func open_detail(value:RefCounted,_sub:int=0)->void:opened=value

func before_test()->void:
	GameState.reset_for_new_world(424242)
	SettlementModel.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world(); CivilizationSystem.initialize()
	MilitaryCampaign.reset_for_new_world(); ForeignDiplomacy.reset_for_new_world()
	GameState.initialize_population_model(); GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]; SettlementModel.ensure_founded()
	FoodSystem.reset_for_new_world(); FoodSystem.initialize(); FoodSystem.receive_external_food(10000)
	GameState.civic_api_enabled=false
	GameState.elapsed_days=10
	T.set_color_mode("light")

func after_test()->void:
	T.set_color_mode("light")
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()

func intel(): return CivilizationSystem.city_intelligence
func civ(index:int=0)->Dictionary: return CivilizationSystem.civilizations[index]
func region(index:int=0,civ_index:int=0)->String: return String(civ(civ_index).strategic_regions[index].id)
func observe(city_id:String,quality:float=.8,day:int=10,source:="physical reconnaissance",reference:="scout:1")->void:
	intel().publish("player",intel().capture("player",city_id,quality,day,source,reference),day)

func row_of(rows:Array,civ_id:String)->Dictionary:
	for row:Dictionary in rows:
		if String(row.civ_id)==civ_id:return row
	return {}

## A report as city_intelligence.known() gives one, made by hand.
func report(civ_id:String,city_id:String,day:int,times:float,width:=0.05,source:="physical reconnaissance",reference:="scout:1")->Dictionary:
	var fields:={}
	for key:String in BASE:
		var mid:=float(BASE[key])*times
		fields[key]={"low":mid*(1.0-width),"high":mid*(1.0+width),"observed_day":day,"quality":.8,"source":source,"reference":reference}
	var age:=maxi(0,TODAY-day)
	return {"city_id":city_id,"civ_id":civ_id,"controller":civ_id,"name":city_id.capitalize(),"position":{"x":0.0,"z":0.0},"observed_day":day,"reported_day":day,"quality":.8,
		"source":source,"reference":reference,"fields":fields,"age_days":age,"freshness":"recent" if age<=30 else ("aging" if age<=180 else "stale")}

func people(id:String,name:String,extra:={})->Dictionary:
	var p:={"civ_id":id,"name":name,"at_war":false,"treaty":"none","feud":false,"hot":false,"trust":0.0,"withheld":false,"envoys_away":false,
		"home_known":true,"home_position":{"x":0.0,"z":0.0},"met_day":0,"stance":""}
	p.merge(extra,true)
	return p

func three_peoples()->Array:
	return [people("a","Ashen"),people("b","Briar"),people("c","Cinder")]

# ---------------------------------------------------------------------------
# As we know it
# ---------------------------------------------------------------------------

func test_rows_come_from_estimates_never_truth()->void:
	observe(region())
	var id:=String(civ().id)
	var before:Dictionary=row_of(Model.build().rows,id)
	assert_bool(bool(before.cells.people.known)).is_true()
	var seen:Dictionary=intel().known("player",region(),10).fields.population
	assert_float(float(before.cells.people.low)).is_equal_approx(float(seen.low),0.001)
	assert_float(float(before.cells.people.high)).is_equal_approx(float(seen.high),0.001)
	# Their true numbers change at home; our row does not move.
	civ().population*=10.0; civ().military_population*=20.0; civ().food_days=0.0
	civ().strategic_regions[0].population*=10.0
	var after:Dictionary=row_of(Model.build().rows,id)
	for column:String in ["people","fighters","stores","crafts","walls","lore","lives"]:
		assert_str(String(after.cells[column].text)).override_failure_message(column).is_equal(String(before.cells[column].text))
	assert_float(float(after.cells.people.high)).is_equal(float(before.cells.people.high))
	# Until a new report comes home.
	GameState.elapsed_days=11
	observe(region(),.8,11)
	var told:Dictionary=row_of(Model.build().rows,id)
	assert_float(float(told.cells.people.low)).is_greater(float(before.cells.people.high)*3.0)

func test_totals_sum_the_town_ranges()->void:
	observe(region(0)); observe(region(1))
	var id:=String(civ().id)
	var row:=row_of(Model.build().rows,id)
	var towns:=[intel().known("player",region(0),10),intel().known("player",region(1),10)]
	for pair:Array in [["people","population"],["fighters","garrison"]]:
		var low:=0.0;var high:=0.0
		for town:Dictionary in towns:
			low+=float(town.fields[pair[1]].low);high+=float(town.fields[pair[1]].high)
		assert_float(float(row.cells[pair[0]].low)).override_failure_message(pair[0]).is_equal_approx(low,0.001)
		assert_float(float(row.cells[pair[0]].high)).override_failure_message(pair[0]).is_equal_approx(high,0.001)
	assert_int(int(row.cells.towns.low)).is_equal(2)
	# A level is the towns' average: it lies within their ranges.
	var lows:=towns.map(func(t:Dictionary)->float:return float(t.fields.supply.low))
	var highs:=towns.map(func(t:Dictionary)->float:return float(t.fields.supply.high))
	assert_float(float(row.cells.stores.low)).is_between(lows.min(),lows.max())
	assert_float(float(row.cells.stores.high)).is_between(highs.min(),highs.max())
	# Both towns are told in the opened row, each with its own figures.
	assert_int((row.towns as Array).size()).is_equal(2)
	# A town known only by where it lies adds to the count, not the sums:
	# the total says "+" for what it could not count.
	intel().publish("player",intel().location_record(intel().site(region(2)),-1,"earlier location report","home:x"),10)
	var more:=row_of(Model.build().rows,id)
	assert_int(int(more.cells.towns.low)).is_equal(3)
	assert_float(float(more.cells.people.high)).is_equal_approx(float(row.cells.people.high),0.001)
	assert_str(String(more.cells.people.text)).ends_with("+")
	assert_str(String(more.cells.people.tip)).contains("2 of 3 towns")

func test_ranking_by_each_column_with_ties_about_level()->void:
	var rows:=Model.rows(three_peoples(),[report("a","a1",TODAY,1.0),report("b","b1",TODAY,2.0),report("c","c1",TODAY,3.0)],[],{},TODAY,"reckoned")
	for column:String in ["people","fighters","stores","crafts","lore","lives","wealth","walls"]:
		var order:=Model.order(rows,column).map(func(r:Dictionary)->String:return String(r.civ_id))
		assert_array(order).override_failure_message(column).is_equal(["c","b","a"])
		assert_array(Model.order(rows,column,true).map(func(r:Dictionary)->String:return String(r.civ_id))).override_failure_message(column).is_equal(["a","b","c"])
		assert_str(String(row_of(rows,"c").cells[column].rank)).override_failure_message(column).is_equal("1st")
		assert_str(String(row_of(rows,"b").cells[column].rank)).is_equal("2nd")
		assert_str(String(row_of(rows,"a").cells[column].rank)).is_equal("3rd")
	# Where what we know overlaps, nobody can say who leads: about level.
	var close:=report("a","a1",TODAY,1.95,0.06)
	rows=Model.rows(three_peoples(),[close,report("b","b1",TODAY,2.0),report("c","c1",TODAY,3.0)],[],{},TODAY,"reckoned")
	for column:String in ["people","fighters","stores","crafts","lore","lives","wealth","walls"]:
		assert_str(String(row_of(rows,"a").cells[column].rank)).override_failure_message(column).is_equal("about level")
		assert_str(String(row_of(rows,"b").cells[column].rank)).is_equal("about level")
		assert_str(String(row_of(rows,"b").cells[column].rank_tip)).contains("Ashen")
		assert_str(String(row_of(rows,"c").cells[column].rank)).is_equal("1st")
	# Towns: a count, ranked the same way.
	rows=Model.rows(three_peoples(),[report("a","a1",TODAY,1.0),report("b","b1",TODAY,1.0),report("b","b2",TODAY,1.0),report("c","c1",TODAY,1.0)],[],{},TODAY,"reckoned")
	assert_str(String(row_of(rows,"b").cells.towns.rank)).is_equal("1st")
	assert_str(String(row_of(rows,"a").cells.towns.rank)).is_equal("about level")
	# Names A to Z; the fiercest relation first.
	assert_array(Model.order(rows,"name").map(func(r:Dictionary)->String:return String(r.name))).is_equal(["Ashen","Briar","Cinder"])
	var feud:=three_peoples();feud[1]["feud"]=true;feud[1]["hot"]=true;feud[2]["at_war"]=true
	rows=Model.rows(feud,[],[],{},TODAY,"reckoned")
	assert_array(Model.order(rows,"between").map(func(r:Dictionary)->String:return String(r.civ_id))).is_equal(["c","b","a"])

func test_a_people_with_no_town_reports_shows_unknown()->void:
	var rows:=Model.rows(three_peoples(),[report("a","a1",TODAY,1.0),report("b","b1",TODAY,2.0)],[],{},TODAY,"hearth")
	var c:=row_of(rows,"c")
	assert_str(String(c.cells.people.text)).is_equal("unknown")
	for column:String in ["fighters","stores","crafts","lore","lives","wealth","walls"]:
		assert_str(String(c.cells[column].text)).override_failure_message(column).is_equal("?")
		assert_bool(c.cells[column].has("rank")).is_false()
	assert_str(String(c.cells.towns.text)).is_equal("0")
	assert_str(String(c.fresh.level)).is_equal("none")
	# What we do not know comes last, whichever way the page is sorted.
	assert_str(String(Model.order(rows,"people")[2].civ_id)).is_equal("c")
	assert_str(String(Model.order(rows,"people",true)[2].civ_id)).is_equal("c")
	# In the game: a people met on the road, no town of theirs yet seen.
	var relation:Dictionary=civ(1).player_relation
	relation.contact_level=2;relation.contact_source="test meeting";relation.encounter_position={"x":40.0,"z":40.0};relation.met_day=3
	var met:=row_of(Model.build().rows,String(civ(1).id))
	assert_bool(met.is_empty()).is_false()
	assert_str(String(met.cells.people.text)).is_equal("unknown")
	assert_str(String(met.fresh.text)).is_equal("no town seen yet")

func test_freshness_and_age_marks()->void:
	GameState.elapsed_days=TODAY
	var marks:={"a":TODAY-5,"b":TODAY-100,"c":TODAY-300}
	var rows:=Model.rows(three_peoples(),[report("a","a1",marks.a,1.0),report("b","b1",marks.b,1.0,0.05,"local observation","lookouts"),report("c","c1",marks.c,1.0,0.05,"our watcher","covert:c1")],[],{},TODAY,"hearth")
	assert_str(String(row_of(rows,"a").fresh.level)).is_equal("recent")
	assert_str(String(row_of(rows,"b").fresh.level)).is_equal("aging")
	assert_str(String(row_of(rows,"c").fresh.level)).is_equal("stale")
	for id:String in marks:assert_str(String(row_of(rows,id).fresh.text)).is_equal(EraWords.ago(int(marks[id])))
	assert_str(String(row_of(rows,"a").fresh.source)).is_equal("scouts")
	assert_str(String(row_of(rows,"b").fresh.source)).is_equal("the watch")
	assert_str(String(row_of(rows,"c").fresh.source)).is_equal("spies")
	assert_str(Model.source_word("shared by the Keshan","x")).is_equal("envoys")
	assert_str(Model.source_word("caravan traders' account","")).is_equal("traders")
	# Undated: only where it lies is known.
	var undated:=report("a","a1",-1,1.0);undated.observed_day=-1
	assert_str(String(Model.freshness([undated],TODAY).level)).is_equal("undated")
	# Every figure says how old and whose its word is.
	assert_str(String(row_of(rows,"b").cells.people.tip)).contains("the watch")
	assert_str(String(row_of(rows,"b").cells.people.tip)).contains(EraWords.ago(int(marks.b)))
	# Ranges widen as the word ages (known() does it; the row follows).
	GameState.elapsed_days=10
	observe(region(),.8,10)
	var id:=String(civ().id)
	var fresh:=row_of(Model.build(10).rows,id)
	var old:=row_of(Model.build(500).rows,id)
	assert_float(float(old.cells.people.high)-float(old.cells.people.low)).is_greater(float(fresh.cells.people.high)-float(fresh.cells.people.low))
	assert_str(String(fresh.fresh.level)).is_equal("recent")
	assert_str(String(old.fresh.level)).is_equal("stale")
	# The board draws the mark beside each people's name.
	var board:=_board({"stage":"hearth","rows":rows,"unplaced":[]})
	await get_tree().process_frame
	board.select_people("a")
	assert_str((board.find_child("Freshness",true,false) as Label).tooltip_text).contains("Recent")
	board.select_people("c")
	assert_str((board.find_child("Freshness",true,false) as Label).tooltip_text).contains("Stale")

func test_our_own_row()->void:
	GameState.settlement_name="Oakford"
	observe(region())
	var rows:Array=Model.build().rows
	var ours:=row_of(rows,"player")
	assert_bool(bool(ours.us)).is_true()
	assert_str(String(ours.name)).is_equal(Model.our_name())
	assert_str(Model.our_name()).is_equal(Model.title_case(String(CivilizationSystem._player_civilization_name())))
	# Our own count, told exactly.
	assert_str(String(ours.cells.people.text)).is_equal(EraWords.grouped(roundi(float(GameState.population_total))))
	assert_float(float(ours.cells.people.low)).is_equal(float(ours.cells.people.high))
	assert_str(String(ours.fresh.level)).is_equal("ours")
	assert_int(int(ours.cells.towns.low)).is_equal(GameState.player_settlements.size())
	# We are ranked among them.
	assert_bool(ours.cells.people.has("rank")).is_true()
	# The board marks our row "us".
	var board:=_board(Model.build())
	await get_tree().process_frame
	board.select_people("player")
	assert_object(board.find_child("People_player",true,false)).is_not_null()
	assert_str((board.find_child("Freshness",true,false) as Label).text).is_equal("Our own count · today")

# ---------------------------------------------------------------------------
# The board
# ---------------------------------------------------------------------------

func _board(model:Dictionary,view:={},on_town:=Callable())->Control:
	var board:Control=auto_free(Board.new())
	board.size=Vector2(900,600)
	add_child(board)
	board.setup({"model":model,"view":view,"on_town":on_town})
	return board

## A ledger with all its parts: a feud with a stance, bands seen, a town of
## unknown people, a people unknown, our row, and one row opened.
func _full_model(stage:String,our_people:=420.0,width:=0.05)->Dictionary:
	var peoples:=three_peoples()
	peoples[0]["feud"]=true;peoples[0]["hot"]=true;peoples[0]["stance"]="take";peoples[0]["trust"]=-0.4
	peoples[1]["treaty"]="trade";peoples[1]["trust"]=0.5
	var bands:=[{"civ_id":"a","kind":"army","strength_estimate_low":20,"strength_estimate_high":40,"last_seen_day":TODAY-3}]
	var us:={"name":"Oakford","values":{"population":our_people,"garrison":30.0,"supply":45.0,"production":0.4,"science_capacity":3.0,"life_expectancy":31.0,"gdp":200.0,"fortification":0.4},"towns":[{"name":"Oakford","values":{"population":our_people,"garrison":30.0,"supply":45.0,"fortification":0.4}}]}
	var rows:=Model.rows(peoples,[report("a","a1",TODAY-5,1.0,width),report("a","a2",TODAY-200,1.5,width),report("b","b1",TODAY-100,2.0,width)],bands,us,TODAY,stage)
	return {"stage":stage,"rows":rows,"unplaced":[{"city_id":"x","name":"Unidentified settlement"}]}

func _walk(node:Node,out:Array)->void:
	out.append(node)
	for child in node.get_children():_walk(child,out)

func test_selected_profile_exposes_known_fields_without_rendering_every_people()->void:
	GameState.elapsed_days=TODAY
	var board:=_board(_full_model("reckoned"),{"selected":"a"})
	await get_tree().process_frame
	assert_int(board.find_children("People_*","",true,false).size()).is_equal(1)
	for id:String in Model.RANKED:
		assert_object(board.find_child("Cell_"+id,true,false)).is_not_null()
	for id:String in ["lore","crafts","wealth","lives","walls","stores"]:
		var value:Label=board.find_child("Cell_"+id,true,false).find_child("Value",true,false)
		assert_str(value.text).is_not_equal("Unknown")
	board.select_people("c")
	assert_str((board.find_child("Cell_lore",true,false).find_child("Value",true,false) as Label).text).is_equal("Unknown")
	assert_object(board.find_child("People_a",true,false)).is_null()
	board.select_people("a")
	assert_str((board._labels.caption_lore as Label).text).is_equal("Learning capacity")

func test_selector_sort_search_and_town_callbacks_are_preserved()->void:
	GameState.elapsed_days=TODAY
	var opened:=[]
	var view:={"selected":"a"}
	var board:=_board(_full_model("reckoned"),view,func(id:String):opened.append(id))
	await get_tree().process_frame
	var picker:Board.VisibleChoice=board.find_child("SelectPeople",true,false)
	assert_str(String(_board(_full_model("reckoned")).view.selected)).is_equal("a")
	assert_str(String(picker.get_item_metadata(0))).is_equal("player")
	board.sort_by("fighters")
	assert_str(String(picker.get_item_metadata(0))).is_equal("a")
	assert_str(String(view.selected)).is_equal("a")
	board.sort_by("fighters")
	assert_bool(bool(view.flip)).is_true()
	assert_str(String(picker.get_item_metadata(0))).is_equal("b")
	var search:LineEdit=board.find_child("FindPeople",true,false)
	search.text="Briar";search.text_changed.emit(search.text)
	assert_int(picker.item_count).is_equal(1)
	assert_str(String(picker.get_item_metadata(0))).is_equal("b")
	picker.item_selected.emit(0)
	assert_str(String(view.selected)).is_equal("b")
	board.toggle("b")
	(board.find_child("Read_b1",true,false) as Button).pressed.emit()
	assert_array(opened).is_equal(["b1"])
	assert_str(String(view.open)).is_equal("b")
	board.select_people("a")
	assert_str((board.find_child("BetweenUs",true,false) as Label).text).contains("Hot feud")
	assert_str((board.find_child("BetweenUs",true,false) as Label).text).contains("Envoys: barred")

func test_town_reader_is_bounded_and_every_report_remains_reachable()->void:
	var data:=_full_model("reckoned")
	var row:=row_of(data.rows,"a")
	for index in 9:
		var town:Dictionary=row.towns[0].duplicate(true);town.city_id="extra_"+str(index);town.name="Extra "+str(index);row.towns.append(town)
	var opened:=[]
	var view:={"selected":"a","open":"a"}
	var board:=_board(data,view,func(id:String):opened.append(id))
	await get_tree().process_frame
	assert_int(board.find_children("Town_*","VBoxContainer",true,false).size()).is_equal(Board.TOWN_PAGE)
	(board.find_child("NextTowns",true,false) as Button).pressed.emit()
	assert_int(int(view.town_page)).is_equal(1)
	assert_int(board.find_children("Town_*","VBoxContainer",true,false).size()).is_equal(Board.TOWN_PAGE)
	(board.find_child("Read_extra_2",true,false) as Button).pressed.emit()
	assert_array(opened).is_equal(["extra_2"])
	(board.find_child("NextTowns",true,false) as Button).pressed.emit()
	assert_int(board.find_children("Town_*","VBoxContainer",true,false).size()).is_equal(3)
	assert_bool((board.find_child("NextTowns",true,false) as Button).disabled).is_true()

func test_regard_and_estimates_are_distinct_and_unknown_is_not_zero()->void:
	var board:=_board(_full_model("reckoned"),{"selected":"a"})
	var views:=[]
	for spec:Array in Board.Standing.VIEWS:views.append({"id":spec[0],"name":spec[1],"value":0.42,"means":spec[2],"why":"fixture"})
	var side:=[{"civ_id":"a","headline":"They trust our word.","ruler":"Hearth Chief Alen","memories":[{"text":"They remember the peace."}],"theirs":{"genius":{"value":0.62,"low":0.5,"high":0.7,"unknown":false,"exact":false}},"views":views,"envy":0.2,"contempt":0.1}]
	board.update_block({"model":_full_model("reckoned"),"view":board.view,"side":side})
	assert_str((board._labels.art_genius as Label).text).is_equal("~62%")
	assert_str((board._labels.art_genius as Label).tooltip_text).contains("50 to 70")
	assert_str((board._labels.art_splendor as Label).text).is_equal("Unknown")
	assert_str((board._labels.view_awe as Label).text).is_equal("42%")
	assert_str((board._labels.view_envy as Label).text).is_equal("20%")
	assert_str((board._labels.view_contempt as Label).text).is_equal("10%")
	assert_str((board._labels.regard as Label).text).is_equal("They trust our word.")
	assert_str((board._labels.regard as Label).tooltip_text).contains("Hearth Chief Alen")
	assert_str((board._labels.regard as Label).tooltip_text).contains("They remember the peace.")
	board.select_people("c")
	assert_str((board._labels.view_awe as Label).text).is_equal("Unknown")

func test_live_profile_updates_preserve_selection_and_focus()->void:
	GameState.elapsed_days=TODAY
	var view:={"selected":"player","sort":"people","flip":false}
	var board:=_board(_full_model("hearth"),view)
	await get_tree().process_frame
	var picker:Board.VisibleChoice=board.find_child("SelectPeople",true,false)
	picker.buttons[0].grab_focus()
	var next:=_full_model("hearth",431.0,0.08)
	board.update_block({"model":next,"view":view})
	assert_bool(board.find_child("SelectPeople",true,false)==picker).is_true()
	assert_bool(picker.buttons[0].has_focus()).is_true()
	assert_str((board.find_child("Cell_people",true,false).find_child("Value",true,false) as Label).text).is_equal("431")
	assert_str(String(view.selected)).is_equal("player")
	var talked:=[]
	board.update_block({"model":next,"view":view,"on_speak":func(id:String):talked.append(id)})
	board.select_people("a")
	var talk:Button=board.find_child("Talk",true,false);talk.grab_focus()
	var changed:=_full_model("hearth",440.0,0.1)
	board.update_block({"model":changed,"view":view,"on_speak":func(id:String):talked.append(id)})
	assert_bool((board.find_child("Talk",true,false) as Button).has_focus()).is_true()
	(board.find_child("Talk",true,false) as Button).pressed.emit()
	assert_array(talked).is_equal(["a"])

func test_a_narrow_profile_wraps_without_hiding_facts_or_actions()->void:
	GameState.elapsed_days=TODAY
	var board:=_board(_full_model("hearth"),{"selected":"a"})
	board.size=Vector2(420,600);board._layout()
	await get_tree().process_frame
	assert_bool(board._columns.vertical).is_true()
	assert_bool((board.find_child("Freshness",true,false) as Control).visible).is_true()
	assert_int(board._picker.buttons.size()).is_less_equal(6)
	assert_int(board.find_children("*","OptionButton",true,false).size()).is_equal(0)
	assert_int(board.find_children("*","MenuButton",true,false).size()).is_equal(0)
	for id:String in Model.RANKED:assert_bool((board.find_child("Cell_"+id,true,false) as Control).visible).is_true()

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
	return T.paper_panel_style(false).bg_color

func test_every_word_reads_in_light_and_dark()->void:
	GameState.elapsed_days=TODAY
	for mode:String in ["light","dark"]:
		T.set_color_mode(mode)
		var board:=_board(_full_model("hearth"),{"sort":"people","flip":false,"open":"a"})
		await get_tree().process_frame
		var nodes:Array=[];_walk(board,nodes)
		var failures:Array=[]
		for node in nodes:
			if node is Label and (node as Label).is_visible_in_tree() and (node as Label).text!="":
				var ratio:=T.contrast((node as Label).get_theme_color("font_color"),_ground_of(node))
				if ratio<4.5:failures.append("%s '%s' %.2f" % [node.name,(node as Label).text,ratio])
		assert_array(failures).override_failure_message(mode).is_empty()

# ---------------------------------------------------------------------------
# Where it lives
# ---------------------------------------------------------------------------

func test_the_known_world_leads_with_the_ledger_once_a_people_is_met()->void:
	var terrain:=StubTerrain.new();add_child(terrain)
	var hud:=StubHud.new();add_child(hud)
	var content:=World.new(terrain,hud)
	assert_str(String(content.tab(0).blocks[0].type)).is_equal("known_world")
	observe(region())
	var blocks:Array=content.tab(0).blocks
	assert_str(String(blocks[0].type)).is_equal("peoples_known")
	assert_str(String(blocks[1].type)).is_equal("known_world")
	# The page keeps its own view across rebuilds.
	assert_bool(blocks[0].view==content.peoples_view).is_true()
	# A town opens its report.
	(blocks[0].on_town as Callable).call(region())
	assert_bool(hud.opened!=null).is_true()
	# Drawn in the dock.
	var panel:=preload("res://scripts/hud/dock_panel.gd").new();add_child(panel)
	panel.size=Vector2(980,900)
	panel.present(content,0)
	await get_tree().process_frame
	assert_object(panel.find_child("PeoplesKnownBoard",true,false)).is_not_null()
	panel.find_child("PeoplesKnownBoard",true,false).select_people(String(civ().id))
	assert_object(panel.find_child("People_"+String(civ().id).validate_node_name(),true,false)).is_not_null()
	await get_tree().process_frame
	panel.free();hud.free();terrain.free()

func test_the_war_screen_links_to_all_peoples_we_know()->void:
	var board:VBoxContainer=auto_free(WarBoard.new())
	add_child(board)
	board.setup({})
	# A small link on the Enemies heading, not a box on the sheet.
	var link:Button=board.fronts_section.find_child("AllPeoples",true,false)
	assert_object(link).is_not_null()
	assert_str(link.text).starts_with("All peoples")

func test_empty_hearsay_is_compact_and_keeps_the_map_action()->void:
	var opened:=[]
	var board:Control=auto_free(preload("res://scripts/hud/known_world_board.gd").new())
	add_child(board)
	board.setup({"model":{"leads":[],"actions":{"rumor_map":func():opened.append(true)}}})
	assert_object(board.find_child("Leads",true,false)).is_instanceof(HFlowContainer)
	(board.find_child("RumorMap",true,false) as Button).pressed.emit()
	assert_array(opened).is_equal([true])

func test_hearsay_reader_keeps_all_leads_and_only_one_detail()->void:
	var leads:Array=[]
	for index in 21:leads.append({"id":"lead_"+str(index),"name":"River people "+str(index),"where":"Northeast · ~24 days","text":"Telling "+str(index),"confidence":0.3,"word":"An uncertain telling","searched":2,"stale":false})
	var called:=[]
	var data:={"leads":leads,"actions":{"plan":func():called.append("plan"),"rumor_map":func():called.append("map")}}
	var view:={"lead":"","query":""}
	var board:Control=auto_free(preload("res://scripts/hud/known_world_board.gd").new());add_child(board);board.setup({"model":data,"view":view})
	assert_int(board.lead_picker.item_count).is_equal(21)
	assert_int(board.find_children("LeadEvidence","Label",true,false).size()).is_equal(1)
	var search:LineEdit=board.find_child("FindLead",true,false);search.text="people 20";search.text_changed.emit(search.text)
	assert_int(board.lead_picker.item_count).is_equal(1)
	board.lead_picker.item_selected.emit(0)
	assert_str(String(view.lead)).is_equal("lead_20")
	assert_str((board.find_child("LeadEvidence",true,false) as Label).text).is_equal("Telling 20")
	(board.find_child("FollowLead",true,false) as Button).pressed.emit();(board.find_child("RumorMap",true,false) as Button).pressed.emit()
	assert_array(called).is_equal(["plan","map"])
	search.grab_focus()
	var next:Dictionary=data.duplicate(true);next.leads[20].text="A newer telling"
	board.update_block({"model":next})
	assert_str(String(view.lead)).is_equal("lead_20")
	assert_str((board.find_child("FindLead",true,false) as LineEdit).text).is_equal("people 20")
	assert_bool((board.find_child("FindLead",true,false) as LineEdit).has_focus()).is_true()
	assert_str((board.find_child("LeadEvidence",true,false) as Label).text).is_equal("A newer telling")
	var refreshed_search:LineEdit=board.find_child("FindLead",true,false)
	refreshed_search.text="no such telling";refreshed_search.text_changed.emit(refreshed_search.text)
	assert_str((board.find_child("LeadCount",true,false) as Label).text).is_equal("0 matching of 21 tellings")
	assert_bool(board.lead_reader.visible).is_false()
	refreshed_search.text="";refreshed_search.text_changed.emit("")
	assert_bool(board.lead_reader.visible).is_true()
	assert_str(String(view.lead)).is_equal("lead_20")

func test_hearsay_provider_no_longer_discards_leads_after_six()->void:
	var terrain:=StubTerrain.new();add_child(terrain);var hud:=StubHud.new();add_child(hud)
	var provider:=World.new(terrain,hud)
	var leads:Array=[]
	for index in 21:leads.append({"id":"lead_"+str(index),"name":"River people "+str(index),"center":{"x":80.0,"z":40.0},"confidence":0.3,"via":"traders"})
	var presented:=provider._leads_model(leads,Vector2.ZERO,10)
	assert_int(presented.size()).is_greater_equal(21)
	assert_str(String(presented[20].id)).is_equal("lead_20")
	hud.free();terrain.free()

## A people that bows to us, or gathers every spear against us
## (world_answer.gd), says so in the "between us" cell.
func test_between_us_says_who_bows_and_who_arms()->void:
	var Model:=preload("res://scripts/hud/peoples_known_model.gd")
	var answer:=preload("res://scripts/world_answer.gd")
	var a:=String(CivilizationSystem.civilizations[0].id)
	var b:=String(CivilizationSystem.civilizations[1].id)
	answer._bind(a,int(GameState.elapsed_days),20.0,"Tam, son of Ilak","")
	answer._begin_arming(b,int(GameState.elapsed_days),{"why_all_in":"they resent us"})
	var bowed:=Model.relation_cell({"civ_id":a,"treaty":"none"})
	assert_str(String(bowed.text)).is_equal("Bows to us")
	assert_str(String(bowed.tip)).contains("Tam, son of Ilak")
	var arming:=Model.relation_cell({"civ_id":b,"treaty":"none"})
	assert_str(String(arming.text)).is_equal("Arming against us")
	assert_str(String(arming.tone)).is_equal("danger")
