extends GdUnitTestSuite
## Sickness and disasters go to their own log, not to cards or the Chronicle
## (hardship_log.gd, crisis_system.gd, consequence_engine.gd). The user: "there
## should just be sickness and disaster logs not an entire pop-up every single
## time ... They don't need to go in the chronicle. There is nothing special
## about them unless they are EXTREME!"
## - a routine fire or sickness is written in the log with its numbers, still
##   waits at court, and makes no card and no Chronicle entry, start to end;
## - an extreme one (one in twenty dead, or half the stores or shelter lost)
##   makes exactly one card, and the Chronicle keeps how it ended;
## - one that turns extreme only later gets its one card then;
## - telling never changes what happens: the same crisis told or not has the
##   same dead, losses and answers;
## - widespread sickness is logged, not raised as a council decision, a
##   Chronicle notice or a line over the map; an extreme spell is told once;
## - the log is bounded, saved with the court, and older saves load;
## - the Health page's "Sickness & disasters" tab lists it.
## Offline; never calls a real API.

const Crisis:=preload("res://scripts/crisis_system.gd")
const Hardships:=preload("res://scripts/hardship_log.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Ticker:=preload("res://scripts/hud/map_ticker_words.gd")
const Health:=preload("res://scripts/hud/content/dock_detail_health.gd")

var _saved_people:Array=[]

class FakeHud extends Control:
	var dock:Node=null
	func request_immediate_dock_refresh()->void:pass


func before_test()->void:
	var world:Node=preload("res://tests/audience_modal_probe.gd").new()
	world._setup_world()
	world.free()
	GameState.settlement_founded_day=0
	GameState.elapsed_days=400
	GameState.settlement_name="Ashford"
	GameState.chronicle={}
	Chronicle.pending_cards.clear()
	ForeignDiplomacy.audiences.erase("crises")
	ForeignDiplomacy.audiences.erase("turning_points")
	ForeignDiplomacy.audiences.erase("hardships")
	Crisis.onsets_enabled=false
	_saved_people=GovernmentPeopleSystem.people.duplicate(true)


func after_test()->void:
	GovernmentPeopleSystem.people=_saved_people
	Crisis.onsets_enabled=true


func _x()->Dictionary:
	var x:=Crisis.inputs(int(GameState.elapsed_days))
	x["pop"]=float(GameState.population_total)
	x["river"]=true
	return x


func _run_to(to_day:int)->void:
	for day in range(int(GameState.elapsed_days)+1,to_day+1):
		GameState.elapsed_days=day
		Crisis.daily(day)


func _finish(c:Dictionary)->void:
	_run_to(int(c.end_day)+2)
	if String(c.phase)=="remember": _run_to(int(GameState.elapsed_days)+Crisis.MID_DECIDE_DAYS+2)


func _told_of(c:Dictionary)->Array:
	return (GameState.chronicle.get("entries",[]) as Array).filter(func(e:Dictionary)->bool:return String(e.get("key","")).begins_with("crisis:%s:" % String(c.id)))


func _cards_of(c:Dictionary)->Array:
	return _told_of(c).filter(func(e:Dictionary)->bool:return String(e.get("tier",""))=="moment")


func _line(crisis_id:String)->Dictionary:
	return Hardships.of_crisis(crisis_id)


func _sickness(v:float)->Dictionary:
	Crisis._open_sickness(int(GameState.elapsed_days),_x(),"sickness",v,"",false)
	return Crisis._active_of("sickness")


func test_extreme_is_measured_by_the_engines_own_numbers()->void:
	# Planned death share at onset: one in twenty.
	assert_bool(Crisis.is_extreme({"pop0":200,"m":0.049})).is_false()
	assert_bool(Crisis.is_extreme({"pop0":200,"m":0.05})).is_true()
	# The dead counted so far: one in twenty of the people it struck.
	assert_bool(Crisis.is_extreme({"pop0":200,"m":0.01,"deaths":9})).is_false()
	assert_bool(Crisis.is_extreme({"pop0":200,"m":0.01,"deaths":10})).is_true()
	# Half the stores or the shelter gone at once.
	assert_bool(Crisis.is_extreme({"pop0":200,"loss_share":0.49})).is_false()
	assert_bool(Crisis.is_extreme({"pop0":200,"loss_share":0.5})).is_true()
	# The engine's fires and floods never take that much.
	assert_float(Hardships.EXTREME_LOSS_SHARE).is_greater(0.35)


func test_a_routine_fire_is_written_in_the_log_and_never_carded()->void:
	GameState.resource_stockpiles["Timber"]=400.0
	var housing:=int(GameState.housing_capacity)
	Crisis._open_fire(int(GameState.elapsed_days),_x())
	var c:=Crisis._active_of("fire")
	assert_bool(c.is_empty()).is_false()
	assert_bool(Crisis.is_extreme(c)).is_false()
	# It still waits at court, held by an official.
	assert_str(String(c.matter)).is_not_empty()
	# No card, no Chronicle entry.
	assert_int(Chronicle.pending_cards.size()).is_equal(0)
	assert_array(_told_of(c)).is_empty()
	# Its line, with the engine's numbers.
	var line:=_line(String(c.id))
	assert_bool(line.is_empty()).is_false()
	assert_str(String(line.type)).is_equal("fire")
	assert_int(int(line.house_lost)).is_equal(housing-int(GameState.housing_capacity))
	assert_float(float(line.food_lost)).is_greater(0.0)
	assert_float(float(line.timber_lost)).is_greater(0.0)
	assert_str(String(line.place)).is_equal("Ashford")
	assert_bool(bool(line.extreme)).is_false()
	# The court still hears of it; the Chronicle passes its ledger line by.
	var heard:=GameState.simulation_events.filter(func(e:Dictionary)->bool:return bool(e.get("hardship",false)) and String(e.get("id","")).begins_with("hardship_%s_" % String(c.id)))
	assert_array(heard).is_not_empty()
	Chronicle.ingest_day({"discoveries":[],"progression":[]})
	assert_array(GameState.chronicle.get("entries",[])).is_empty()
	# Run its course with the god silent: still nothing told, the log complete.
	_finish(c)
	assert_str(String(c.phase)).is_equal("done")
	assert_array(_told_of(c)).is_empty()
	assert_int(Chronicle.pending_cards.size()).is_equal(0)
	line=_line(String(c.id))
	assert_bool(line.has("end")).is_true()
	assert_str(String(line.choice)).is_not_empty()
	assert_str(String(line.by)).is_equal("holder")
	var said:=Hardships.words(line)
	print("FIRE LINE: %s | %s | %s | %s" % [said.title,said.sub,said.detail,said.value])
	assert_str(String(said.detail)).contains("shelter for %d lost" % int(line.house_lost)).contains("Food").contains("timber burned").contains("the god was silent")
	assert_str(String(said.sub)).contains("Fire").contains("Ashford")


func test_a_routine_sickness_runs_its_course_in_the_log_only()->void:
	var c:=_sickness(0.03)
	assert_bool(bool(c.get("quiet",false))).is_false()
	assert_bool(Crisis.is_extreme(c)).is_false()
	assert_str(String(c.matter)).is_not_empty()
	_finish(c)
	assert_str(String(c.phase)).is_equal("done")
	assert_array(_told_of(c)).is_empty()
	assert_int(Chronicle.pending_cards.size()).is_equal(0)
	var line:=_line(String(c.id))
	assert_int(int(line.sick)).is_equal(int(c.sick))
	assert_int(int(line.dead)).is_equal(int(c.deaths))
	assert_str(String(line.where)).is_equal(String(c.where))
	if int(c.deaths)>0:
		assert_array(line.names).is_not_empty()
		assert_str(Hardships.numbers(line)).contains("%d died: %s" % [int(c.deaths),String(line.names[0])])
	# Its history is kept for the court as before.
	assert_bool((Crisis.state().history as Array).any(func(h:Dictionary)->bool:return String(h.id)==String(c.id))).is_true()
	print("SICKNESS LINE: ",Hardships.sentence(line))


func test_an_extreme_sickness_interrupts_once_and_the_chronicle_keeps_its_end()->void:
	var c:=_sickness(0.2)
	assert_bool(Crisis.is_extreme(c)).is_true()
	# One card at onset, pointing at the court.
	var cards:=_cards_of(c)
	assert_int(cards.size()).is_equal(1)
	assert_str(String(cards[0].key)).ends_with(":onset")
	assert_str(String((cards[0].get("action",{}) as Dictionary).get("kind",""))).is_equal("court")
	assert_int(Chronicle.pending_cards.size()).is_equal(1)
	_finish(c)
	# Still one card; its end is kept in the Chronicle without another.
	assert_int(_cards_of(c).size()).is_equal(1)
	var ends:=_told_of(c).filter(func(e:Dictionary)->bool:return String(e.key).ends_with(":end"))
	assert_int(ends.size()).is_equal(1)
	assert_str(String(ends[0].tier)).is_equal("notice")
	# Its middle report is only in the log (the holder's silent answer is
	# still counted in the tallies, as before).
	assert_bool(_told_of(c).any(func(e:Dictionary)->bool:return String(e.key)=="crisis:%s:mid" % String(c.id))).is_false()
	assert_bool(_told_of(c).all(func(e:Dictionary)->bool:return String(e.tier)!="whisper" or String(e.key).contains(":silent:"))).is_true()
	var line:=_line(String(c.id))
	assert_bool(bool(line.extreme)).is_true()
	assert_int(int(line.dead)).is_equal(int(c.deaths))
	assert_int(int(line.dead)).is_greater(0)


func test_a_crisis_that_turns_extreme_late_gets_its_one_card_then()->void:
	var c:=_sickness(0.03)
	assert_bool(Crisis.is_extreme(c)).is_false()
	assert_array(_cards_of(c)).is_empty()
	# Stand in for a harder course: by its turn one in twenty has died.
	c.mult=12.0
	_run_to(int(c.mid_day)+1)
	assert_int(int(c.deaths)).is_greater_equal(roundi(float(c.pop0)*Hardships.EXTREME_DEAD_SHARE))
	var cards:=_cards_of(c)
	assert_int(cards.size()).is_equal(1)
	assert_str(String(cards[0].key)).ends_with(":mid")
	_finish(c)
	assert_int(_cards_of(c).size()).is_equal(1)
	assert_bool(_told_of(c).any(func(e:Dictionary)->bool:return String(e.key).ends_with(":end") and String(e.tier)=="notice")).is_true()


func test_a_crisis_told_before_this_change_still_ends_in_the_chronicle()->void:
	var c:=_sickness(0.03)
	assert_bool(Crisis.is_extreme(c)).is_false()
	# An older save: no "told" key, and its onset card was told then.
	c.erase("told")
	Chronicle.record({"key":"crisis:%s:onset" % String(c.id),"title":"Sickness at the Fires","text":"Seven are down with a shaking fever.","tier":"moment","kind":"omen","priority":true})
	Chronicle.pending_cards.clear()
	_finish(c)
	var ends:=_told_of(c).filter(func(e:Dictionary)->bool:return String(e.key).ends_with(":end"))
	assert_int(ends.size()).is_equal(1)
	assert_str(String(ends[0].tier)).is_equal("notice")
	assert_int(_cards_of(c).size()).is_equal(1)
	assert_int(Chronicle.pending_cards.size()).is_equal(0)


func _outcome(tell:bool)->Dictionary:
	before_test()
	GameState.resource_stockpiles["Timber"]=400.0
	Crisis._open_fire(int(GameState.elapsed_days),_x())
	var fire:=Crisis._active_of("fire")
	if tell: fire["told"]=true
	var sick:=_sickness(0.03)
	if tell: sick["told"]=true
	_run_to(int(GameState.elapsed_days)+200)
	var hist:Array=[]
	for h in Crisis.state().history: hist.append([String(h.id),int(h.deaths),(h.dead as Array).duplicate(),String(h.choice),String(h.mid_choice)])
	return {"pop":GameState.population_total,"housing":GameState.housing_capacity,"food":snappedf(Hall.player_stock("Food"),0.0001),
		"timber":snappedf(float(GameState.resource_stockpiles.get("Timber",0.0)),0.0001),"serial":int(Crisis.state().serial),"hall":int(Hall.state().serial),
		"immunity":snappedf(float(Crisis.state().immunity),0.000001),"history":hist,
		"told":Chronicle.entries("whisper").filter(func(e:Dictionary)->bool:return String(e.get("key","")).begins_with("crisis:")).size()}


func test_telling_a_crisis_never_changes_what_happens()->void:
	var quiet:=_outcome(false)
	var told:=_outcome(true)
	print("QUIET ",quiet)
	print("TOLD  ",told)
	# The told run went through the Chronicle; the quiet run never touched it.
	assert_int(int(quiet.told)).is_equal(0)
	assert_int(int(told.told)).is_greater(0)
	for key in ["pop","housing","food","timber","serial","hall","immunity","history"]:
		assert_str(str(quiet[key])).override_failure_message("%s differs: %s vs %s" % [key,str(quiet[key]),str(told[key])]).is_equal(str(told[key]))


func test_widespread_sickness_is_logged_not_raised_or_told()->void:
	var events:Array[Dictionary]=[]
	GameState.population_health=0.40
	var event:Dictionary=ConsequenceEngine._threshold_event(events,"ill_health","Widespread Illness","Poor nutrition, exposure, and water conditions are reducing effective labor.","health","danger",45)
	assert_bool(event.is_empty()).is_false()
	Hardships.illness_warning(event,0.40)
	assert_bool(bool(event.get("hardship",false))).is_true()
	# Not a council decision, not a Chronicle notice, not a line over the map.
	var inbox:=GameState.council_inbox.size()
	assert_dict(AdvisorSystem.generate_consequence_item(event)).is_empty()
	assert_int(GameState.council_inbox.size()).is_equal(inbox)
	Chronicle.ingest_day({"discoveries":[],"progression":[]})
	assert_bool((GameState.chronicle.get("entries",[]) as Array).any(func(e:Dictionary)->bool:return String(e.get("title",""))=="Widespread Illness")).is_false()
	assert_str(Ticker.day_news([],[],[],[event])).is_equal("")
	# Its spell's line.
	var spell:Dictionary=Hardships.entries()[0]
	assert_str(String(spell.type)).is_equal("illness")
	assert_float(float(spell.health_low)).is_equal_approx(0.40,0.0001)
	# Deaths of sickness add to the same spell; one in twenty makes it extreme,
	# told once.
	var people:=int(spell.pop)
	var record:={"id":"demographic_death_test","day":int(GameState.elapsed_days),"title":"3 deaths at Ashford","description":"","severity":"demographic","kind":"death","cause":"Illness","count":3}
	Hardships.illness_deaths(record,3)
	assert_bool(bool(record.get("hardship",false))).is_true()
	assert_int(int(Hardships.entries()[0].dead)).is_equal(3)
	assert_bool(bool(Hardships.entries()[0].get("extreme",false))).is_false()
	assert_int(Chronicle.pending_cards.size()).is_equal(0)
	Hardships.illness_deaths(record,ceili(float(people)*Hardships.EXTREME_DEAD_SHARE))
	assert_int(Hardships.entries().size()).is_equal(1)
	assert_bool(bool(Hardships.entries()[0].extreme)).is_true()
	assert_int(Chronicle.pending_cards.size()).is_equal(1)
	assert_str(String(Chronicle.pending_cards[0].title)).is_equal("The Sickness Will Not Lift")
	Hardships.illness_deaths(record,2)
	assert_int(Chronicle.pending_cards.size()).is_equal(1)
	# Other peoples keep no log, but their warnings are marked all the same.
	var rival:={"day":400,"title":"Widespread Illness"}
	WorldSimulation.scoped("rival_a",func()->void:Hardships.illness_warning(rival,0.3))
	assert_bool(bool(rival.get("hardship",false))).is_true()
	assert_int(Hardships.entries().size()).is_equal(1)


func test_the_years_telling_reads_the_log_for_troubles_it_does_not_tell()->void:
	# A fever over the turn of years 1 and 2, a fire in year 3 still going, a
	# spell of sickness in year 5; year 4 had none.
	GameState.elapsed_days=3*365+100
	Hardships.note("c1@700",{"crisis":"c1","type":"sickness","start":700,"end":760})
	Hardships.note("c2@1150",{"crisis":"c2","type":"fire","start":1150})
	assert_int(Hardships.count_in_year(1)).is_equal(1)
	assert_int(Hardships.count_in_year(2)).is_equal(1)
	assert_int(Hardships.count_in_year(3)).is_equal(1)
	assert_int(Hardships.count_in_year(0)).is_equal(0)
	GameState.elapsed_days=5*365+200
	Hardships.note("c2@1150",{"end":1200})
	Hardships.note("illness:1900",{"type":"illness","start":1900,"last":1960})
	assert_int(Hardships.count_in_year(4)).is_equal(0)
	assert_int(Hardships.count_in_year(5)).is_equal(1)
	# A year with one is troubled, though nothing of it is told.
	assert_bool(preload("res://scripts/chronicle_years.gd").troubled({"crises":0,"routine":1})).is_true()
	assert_int(preload("res://scripts/chronicle_annals.gd").routine_troubles(5)).is_equal(1)


func test_the_log_is_bounded_and_saved_with_the_court()->void:
	for i in Hardships.LOG_MAX+30:
		Hardships.note("t%d" % i,{"type":"fire","name":"the Burning %d" % i,"start":i,"end":i+10,"dead":i%3,"names":["Ama, a girl","Tesk, an old man","Ulmo, a hunter","Ira, a grandmother"]})
	var lines:=Hardships.entries()
	assert_int(lines.size()).is_equal(Hardships.LOG_MAX)
	assert_str(String(lines[0].id)).is_equal("t%d" % (Hardships.LOG_MAX+29))
	assert_int((lines[0].names as Array).size()).is_equal(3)
	assert_bool(Hardships.valid_state(Hardships.state())).is_true()
	assert_bool(Hall.validate_state(ForeignDiplomacy.audiences.duplicate(true))).is_true()
	# An older save has no log: it loads, and the log starts empty.
	var older:=ForeignDiplomacy.audiences.duplicate(true)
	older.erase("hardships")
	assert_bool(Hall.validate_state(older)).is_true()
	ForeignDiplomacy.audiences.erase("hardships")
	assert_array(Hardships.entries()).is_empty()
	# A damaged block is refused.
	assert_bool(Hardships.valid_state({"entries":"nonsense"})).is_false()
	assert_bool(Hardships.valid_state({"entries":range(Hardships.LOG_MAX+1).map(func(i:int)->Dictionary:return {"id":str(i)})})).is_false()


func test_the_health_page_lists_the_log()->void:
	var hud:=FakeHud.new();auto_free(hud)
	var page=Health.new(null,hud)
	assert_array(page.meta().subtabs).contains(["Sickness & disasters"])
	var empty:Dictionary=page.tab(1)
	assert_str(JSON.stringify(empty.blocks)).contains("Nothing written yet")
	GameState.resource_stockpiles["Timber"]=400.0
	Crisis._open_fire(int(GameState.elapsed_days),_x())
	var c:=Crisis._active_of("fire")
	var shown:Dictionary=page.tab(1)
	var rows:Array=[]
	for block in shown.blocks:
		if String(block.get("type",""))=="rows": rows=block.items
	assert_int(rows.size()).is_equal(1)
	assert_str(String(rows[0].name)).is_equal("The Burning")
	assert_str(String(rows[0].sub)).contains("Fire").contains("Ashford")
	assert_object(rows[0].icon).is_not_null()
	# Its matter waits at court: the line summons the holder.
	assert_str(String(rows[0].detail)).contains("waits to be summoned")
	assert_bool(rows[0].get("on_click") is Callable).is_true()
	assert_str(String(shown.brief.why)).contains("one in twenty")
	# The page refreshes when the log changes.
	var before:Array=page.signature()
	_finish(c)
	assert_bool(page.signature().hash()!=before.hash()).is_true()
	var after:Dictionary=page.tab(1)
	for block in after.blocks:
		if String(block.get("type",""))=="rows": rows=block.items
	assert_bool(rows[0].get("on_click") is Callable).is_false()
	assert_str(String(rows[0].detail)).not_contains("Still going")
