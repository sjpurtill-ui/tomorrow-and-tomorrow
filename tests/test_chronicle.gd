extends GdUnitTestSuite
## The Chronicle (whisper / notice / moment), the seasonal hearth count and the
## quieter scout returns (fun audit items #7 and #8).
const Chronicle:=preload("res://scripts/chronicle.gd")
const HearthCount:=preload("res://scripts/hearth_count.gd")
const Card:=preload("res://scripts/hud/chronicle_card.gd")
const Notices:=preload("res://scripts/hud/research_announcements.gd")

class Host extends Node:
	var game_speed:=3.0
	func _set_game_speed(value:float)->void:game_speed=value

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(90210)
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.research_notification_mode="milestones"
	Chronicle.pending_cards.clear()
	ForeignDiplomacy.ensure();ForeignDiplomacy.audiences.erase("lives")

func _same_field_pair()->Array:
	var by_field:Dictionary={}
	for id in DiscoverySystem.catalog_by_id:
		if id in GameState.known_discoveries:continue
		var field:=String((DiscoverySystem.catalog_by_id[id] as Dictionary).get("dynamic",""))
		if field=="":continue
		var list:Array=by_field.get(field,[])
		list.append(String(id));by_field[field]=list
		if list.size()>=2 and String(list[0]) not in Chronicle.RESEARCH_MILESTONES and String(list[1]) not in Chronicle.RESEARCH_MILESTONES:return list
	return []

func test_first_discovery_in_a_field_is_a_moment_and_the_next_is_a_notice()->void:
	var pair:=_same_field_pair()
	assert_int(pair.size()).is_equal(2)
	GameState.known_discoveries.append_array(pair)
	Chronicle.ingest_day({"discoveries":[{"id":pair[0],"day":10}],"progression":[]})
	GameState.elapsed_days=40.0
	Chronicle.ingest_day({"discoveries":[{"id":pair[1],"day":40}],"progression":[]})
	var told:=Chronicle.entries("notice")
	assert_int(told.size()).is_equal(2)
	assert_str(String(told[1].tier)).is_equal("moment")
	assert_bool(bool(told[1].first)).is_true()
	assert_str(String(told[0].tier)).is_equal("notice")
	assert_bool(Chronicle.discovery_is_moment(pair[0])).is_true()
	assert_bool(Chronicle.discovery_is_moment(pair[1])).is_false()
	assert_int(Chronicle.pending_cards.size()).is_equal(1)

func test_moment_card_replaces_the_research_popup_and_never_pauses()->void:
	var pair:=_same_field_pair()
	GameState.known_discoveries.append(pair[0])
	Chronicle.ingest_day({"discoveries":[{"id":pair[0],"day":3}],"progression":[]})
	var canvas:SubViewport=auto_free(SubViewport.new());canvas.size=Vector2i(1280,800);add_child(canvas)
	var host:=Host.new();canvas.add_child(host)
	var hud:=Control.new();host.add_child(hud)
	var digest:=Notices.announce(host,hud,[{"id":pair[0],"day":3}])
	assert_int(digest.unread).is_equal(0)
	assert_bool(hud.has_meta("discovery_popup")).is_false()
	var card:=Card.flush(host,hud)
	assert_object(card).is_not_null()
	assert_bool(card.showing).is_true()
	assert_str(card.title_label.text).is_not_empty()
	assert_object(card.picture.texture).is_not_null()
	assert_float(host.game_speed).is_equal(3.0)

func test_moments_are_capped_per_month_and_extra_ones_are_kept_as_notices()->void:
	for i in 4:
		Chronicle.record({"title":"Moment %d" % i,"tier":"moment","kind":"omen","day":100+i})
	var entries:=Chronicle.entries("notice")
	assert_int(entries.size()).is_equal(4)
	assert_str(String(entries[0].tier)).is_equal("notice")
	assert_bool(bool(entries[0].get("crowded",false))).is_true()
	assert_int(Chronicle.entries("moment").size()).is_equal(3)
	Chronicle.record({"title":"Much later","tier":"moment","day":200})
	assert_int(Chronicle.entries("moment").size()).is_equal(4)

func test_record_dedupes_by_key_and_notices_reach_the_ledger()->void:
	var first:=Chronicle.record({"key":"court:1","title":"The chief speaks","text":"She named her heir.","tier":"notice","kind":"court"})
	assert_str(String(first.tier)).is_equal("notice")
	assert_bool(Chronicle.record({"key":"court:1","title":"Again"}).is_empty()).is_true()
	assert_str(String(GameState.simulation_events[0].title)).is_equal("The chief speaks")
	Chronicle.record({"title":"A quiet line","tier":"whisper"})
	assert_str(String(GameState.simulation_events[0].title)).is_equal("The chief speaks")
	assert_str(Chronicle.latest_headline()).contains("THE CHIEF SPEAKS")
	assert_bool(Chronicle.latest_headline().begins_with("HEARTH-TALE")).is_true()

func test_routine_births_and_deaths_fold_into_one_seasonal_tally()->void:
	GameState.elapsed_days=50.0
	var events:Array[Dictionary]=[]
	HearthCount.advance(events)
	for i in 3:HearthCount.tally("born",1)
	HearthCount.tally("buried",2);HearthCount.tally("infants",1)
	HearthCount.tally("lost",1)
	GameState.elapsed_days=140.0
	HearthCount.advance(events)
	assert_int(events.size()).is_equal(1)
	var line:Dictionary=events[0]
	assert_str(String(line.kind)).is_equal("hearth_count")
	assert_str(String(line.severity)).is_equal("minor")
	assert_bool(String(line.description).begins_with("Three born, two buried (among the dead, a newborn).")).is_true()
	assert_str(String(line.description)).contains("One pregnancy was lost before birth.")
	assert_str(String(line.description)).not_contains("pregnancies")
	assert_str(Chronicle.grade(line)).is_equal("whisper")
	# A quiet season says nothing.
	GameState.elapsed_days=240.0
	HearthCount.advance(events)
	assert_int(events.size()).is_equal(1)
	HearthCount.tally("lost",2)
	GameState.elapsed_days=330.0
	HearthCount.advance(events)
	assert_str(String(events[1].description)).contains("Two pregnancies were lost before birth.")

func test_crisis_deaths_are_not_folded()->void:
	assert_bool(HearthCount.routine("Natural causes")).is_true()
	assert_bool(HearthCount.routine("Hunger")).is_false()
	assert_bool(HearthCount.routine("Dehydration")).is_false()

func test_scout_returns_are_silent_unless_something_new()->void:
	var routine:={"mission_kind":"explore","contacts":[],"discoveries":[{"kind":"tool","title":"The pebble that steadied a net","collection_id":"c1"},{"title":"Routes worth remembering"}],"lost_personnel":1}
	assert_bool(ScoutArchive.newsworthy(routine)).is_false()
	var band:=routine.duplicate(true);band.discoveries.append({"kind":"encounter","title":"Lives beyond our own"})
	assert_bool(ScoutArchive.newsworthy(band)).is_false()
	for change:Dictionary in [{"contacts":["Orrun"]},{"recruits":3},{"discoveries":[{"kind":"hearsay","title":"A name beyond the horizon"}]},{"turnback_reason":"The river was in flood."},{"stayed_personnel":1}]:
		var news:=routine.duplicate(true);news.merge(change,true)
		assert_bool(ScoutArchive.newsworthy(news)).is_true()

func test_old_saves_without_a_chronicle_do_not_replay_known_fields()->void:
	var pair:=_same_field_pair()
	GameState.known_discoveries.append_array(pair)
	GameState.discovery_log.append({"id":pair[0],"day":5})
	var state:=SaveSystem._capture_reflected(GameState,[])
	assert_bool(state.has("chronicle")).is_true()
	state.erase("chronicle");state.erase("hearth_season")
	GameState.chronicle={"version":1,"entries":[{"key":"x","tier":"moment","title":"stale","day":1}]}
	GameState.reset_for_new_world(90210)
	SaveSystem._apply_reflected(GameState,state)
	assert_bool(GameState.chronicle.is_empty()).is_true()
	GameState.elapsed_days=900.0
	Chronicle.ingest_day({"discoveries":[{"id":pair[1],"day":900}],"progression":[]})
	var told:=Chronicle.entries("notice")
	assert_int(told.size()).is_equal(1)
	assert_str(String(told[0].tier)).is_equal("notice")

func test_rival_simulations_keep_no_chronicle()->void:
	WorldSimulation.create_actor("rival_test",4)
	var made:Variant=WorldSimulation.scoped("rival_test",func()->Dictionary:return Chronicle.record({"title":"Not ours","tier":"moment"}))
	for instance in WorldSimulation.actors["rival_test"].systems.values():instance.free()
	WorldSimulation.actors.erase("rival_test")
	assert_bool((made as Dictionary).is_empty()).is_true()
	assert_int(Chronicle.entries().size()).is_equal(0)

func test_era_voice_moves_from_tally_marks_to_annals()->void:
	assert_str(String(Chronicle.voice().feed)).is_equal("Hearth-Tales")
	GameState.known_discoveries.append("pictographic_records")
	assert_str(String(Chronicle.voice().feed)).is_equal("The Annals")
	assert_str(String(Chronicle.voice().ticker)).is_equal("THE ANNALS")

func test_moment_marks_are_procedural_and_card_sized()->void:
	for kind in ["founding","birth","death","discovery","contact","settlement","ceremony","milestone","scout","omen","war","court","hearth_count","work"]:
		var texture:=preload("res://scripts/resource_icons.gd").moment_texture(kind,Color("e1c27a"))
		assert_int(texture.get_width()).is_equal(112)
	var sting:=Card.sting("tally")
	assert_int(sting.data.size()).is_greater(20000)

func test_a_thin_season_is_carried_into_the_next_tally()->void:
	GameState.elapsed_days=10.0
	var events:Array[Dictionary]=[]
	HearthCount.advance(events)
	HearthCount.tally("born",1)
	GameState.elapsed_days=50.0
	HearthCount.advance(events)
	assert_int(events.size()).is_equal(0)
	HearthCount.tally("buried",1);HearthCount.tally("born",1)
	GameState.elapsed_days=140.0
	HearthCount.advance(events)
	assert_int(events.size()).is_equal(1)
	assert_str(String(events[0].title)).is_equal("Tally of spring and summer, year 1")
	assert_bool(String(events[0].description).begins_with("Two born, one buried.")).is_true()

func test_scout_and_death_lines_are_retold_for_the_people()->void:
	GameState.simulation_events.push_front({"day":0,"title":"SCOUTS RETURN","description":"The scout party returns after 82 days and charts roughly 1122 km of land travel. No organized foreign polity was encountered. The pebble line counted by moving — the unfinished comparison — Your knowledge workers will examine this. Its specific evidence becomes usable after study. They passed a traveling band who kept moving; the dated sighting is marked, but the band will not remain there. The map now reveals only the physical route contained in its returned report.","domain":"diplomacy","severity":"major"})
	GameState.simulation_events.push_front({"day":0,"title":"Officeholder Died","description":"Sana Ivers died aged 53 while serving as Hearth Chief. The office and local duties now pass through the same succession rules as every other appointment.","domain":"institutions","severity":"major"})
	Chronicle.ingest_day({"discoveries":[],"progression":[]})
	var told:=Chronicle.entries("notice")
	# The clerk's death line is left to the court's mourning (court_lives.gd).
	assert_int(told.size()).is_equal(1)
	assert_str(String(told[0].title)).is_equal("The scouts come home")
	assert_str(String(told[0].text)).contains("traveling band")
	assert_str(String(told[0].text)).not_contains("No organized foreign polity")

func test_court_records_are_told_once_and_open_the_court()->void:
	var Lives:=preload("res://scripts/court_lives.gd")
	GameState.elapsed_days=200.0
	Lives.record("death","Sana Ivers Is Dead","Sana Ivers, Hearth Chief, died aged 53.",{"pid":7},{"key":"court:death:person:7","focus":{"person_id":9}})
	Lives.record("omen","The Sky Answered","Nine days after the god demanded rain, the rain came.",{"wish":"rain"})
	Lives.record("rite","A Rite at the Camp","A bonfire: for the feast.")
	Chronicle.ingest_day({"discoveries":[],"progression":[]})
	Chronicle.ingest_day({"discoveries":[],"progression":[]})
	var told:=Chronicle.entries("notice")
	assert_int(told.size()).is_equal(3)
	var death:Dictionary=told.filter(func(e:Dictionary)->bool:return String(e.kind)=="death")[0]
	assert_str(String(death.tier)).is_equal("moment")
	assert_str(String((death.action as Dictionary).kind)).is_equal("court")
	assert_int(int(((death.action as Dictionary).focus as Dictionary).person_id)).is_equal(9)
	assert_int(told.filter(func(e:Dictionary)->bool:return String(e.kind)=="omen").size()).is_equal(1)
	assert_int(told.filter(func(e:Dictionary)->bool:return String(e.kind)=="ceremony").size()).is_equal(1)
	# The court's ledger lines stay, marked as already told.
	for ev in GameState.simulation_events:
		if (ev as Dictionary).has("court_kind"):assert_bool(bool(ev.get("chronicle",false))).is_true()

func test_the_season_tally_names_the_courts_dead()->void:
	var Lives:=preload("res://scripts/court_lives.gd")
	GameState.elapsed_days=10.0
	var events:Array[Dictionary]=[]
	HearthCount.advance(events)
	HearthCount.tally("buried",3)
	(Lives.state().remembered as Array).push_front({"key":"person:7","pid":7,"day":30,"died":30,"name":"Sana Ivers","title":"Hearth Chief"})
	(Lives.state().remembered as Array).push_front({"key":"person:8","pid":8,"day":31,"died":31,"name":"Oda Reed","title":"of the hearth"})
	GameState.elapsed_days=140.0
	HearthCount.advance(events)
	assert_int(events.size()).is_equal(1)
	assert_str(String(events[0].description)).contains("Among the dead: Sana Ivers, Hearth Chief.")
	assert_str(String(events[0].description)).not_contains("Oda Reed")

func test_a_new_high_headcount_is_remembered_once()->void:
	GameState.settlement_founded_day=0
	GameState.population_total=120
	Chronicle.data()
	GameState.population_total=212
	GameState.elapsed_days=800.0
	Chronicle.ingest_day({"discoveries":[],"progression":[]})
	var told:=Chronicle.entries("notice")
	assert_int(told.size()).is_equal(1)
	assert_str(String(told[0].title)).is_equal("The hearths hold 200 souls")
	assert_str(String(told[0].tier)).is_equal("moment")
	Chronicle.ingest_day({"discoveries":[],"progression":[]})
	assert_int(Chronicle.entries("notice").size()).is_equal(1)

func test_a_finished_work_is_announced_once_with_a_way_to_attend()->void:
	GameState.founding_focus="provision"
	GameState.player_settlements.assign([{"id":"c1","name":"Hometown","primary":true,"undertakings":[{"id":"legacy_test_ring","custom_name":"The Hearth Stones","status":"complete","ceremony":{"status":"pending","day":5,"attendees":[]}}]}])
	var director:Node=auto_free(preload("res://scripts/audience_director.gd").new())
	add_child(director)
	director._offer_ceremony()
	director._offer_ceremony()
	var told:=Chronicle.entries("moment")
	assert_int(told.size()).is_equal(1)
	assert_str(String(told[0].kind)).is_equal("ceremony")
	assert_str(String((told[0].action as Dictionary).kind)).is_equal("ceremony")
	assert_str(String((told[0].action as Dictionary).work_id)).is_equal("legacy_test_ring")
	assert_bool(is_instance_valid(director.ceremony)).is_false()

func _beat(kind:String,day:int,title:String,refs:Dictionary={})->Dictionary:
	return {"id":"opening_%s_%d" % [kind,day],"kind":kind,"tier":"moment","day":day,"title":title,"text":title+", as the people saw it.","refs":refs}

func _fill_moments(day:int)->void:
	for i in Chronicle.MOMENTS_PER_WINDOW:Chronicle.record({"title":"Busy moment %d" % i,"tier":"moment","kind":"omen","day":day})

func test_opening_beats_that_repeat_a_first_are_told_once()->void:
	# The first birth and a court member's child born that same day are one birth.
	GameState.elapsed_days=60.0
	Chronicle.record_first("first_birth",{"title":"The first child born at Home","kind":"birth","tier":"moment"})
	Chronicle.record_beat(_beat("named_child",60,"A child at the hearth chief's hearth",{"parent_id":4,"child_name":"Ama"}))
	var births:=Chronicle.entries().filter(func(e:Dictionary)->bool:return String(e.kind)=="birth")
	assert_int(births.size()).is_equal(1)
	assert_str(String(births[0].title)).is_equal("A child at the hearth chief's hearth")
	assert_int(int(((births[0].action as Dictionary).focus as Dictionary).person_id)).is_equal(4)
	# The band the scouts saw and the smoke they brought home the same day.
	GameState.elapsed_days=80.0
	Chronicle.record_first("band_sighted",{"title":"Other people walk this land","kind":"contact","tier":"notice"})
	Chronicle.record_beat(_beat("first_signs",80,"Smoke on the horizon"))
	var signs:=Chronicle.entries().filter(func(e:Dictionary)->bool:return String(e.get("key",""))=="first:band_sighted")
	assert_int(signs.size()).is_equal(1)
	assert_str(String(signs[0].title)).is_equal("Smoke on the horizon")
	assert_str(String(signs[0].tier)).is_equal("moment")
	# The first discovery keeps its name and gains the scene at the fire.
	Chronicle.record({"key":"discovery:wood_joinery","title":"Wood Joinery","tier":"moment","kind":"discovery","day":90})
	Chronicle.record_beat(_beat("first_discovery",90,"The first discovery: Wood Joinery",{"discovery_id":"wood_joinery"}))
	var found:=Chronicle.entries().filter(func(e:Dictionary)->bool:return String(e.kind)=="discovery")
	assert_int(found.size()).is_equal(1)
	assert_str(String(found[0].title)).is_equal("Wood Joinery")
	assert_str(String(found[0].text)).contains("as the people saw it")
	assert_int(Chronicle.entries().size()).is_equal(3)

func test_a_child_on_another_day_is_its_own_story()->void:
	GameState.elapsed_days=30.0
	Chronicle.record_first("first_birth",{"title":"The first child born at Home","kind":"birth","tier":"moment"})
	GameState.elapsed_days=75.0
	Chronicle.record_beat(_beat("named_child",75,"A child at the hearth chief's hearth",{"parent_id":4}))
	assert_int(Chronicle.entries().filter(func(e:Dictionary)->bool:return String(e.kind)=="birth").size()).is_equal(2)

func test_first_winter_and_first_contact_are_never_buried_by_the_moment_cap()->void:
	GameState.elapsed_days=200.0
	_fill_moments(200)
	Chronicle.record_beat(_beat("first_winter",200,"The first winter",{"person_id":3}))
	# The season's own first-winter line then has nothing new to tell.
	Chronicle.record_first("first_winter",{"title":"The first winter at Home is behind us","kind":"hearth_count","tier":"notice"})
	var winter:=Chronicle.entries().filter(func(e:Dictionary)->bool:return String(e.get("key",""))=="first:first_winter")
	assert_int(winter.size()).is_equal(1)
	assert_str(String(winter[0].title)).is_equal("The first winter")
	assert_str(String(winter[0].tier)).is_equal("moment")
	# First contact from the ledger, then its beat: one moment, with the beat's words.
	GameState.simulation_events.push_front({"day":201,"title":"First contact — Varrow","description":"Scouts met the Varrow.","domain":"diplomacy","severity":"major","kind":"first_contact","civ_id":"rival_b"})
	GameState.elapsed_days=201.0
	Chronicle.ingest_day({"discoveries":[],"progression":[]})
	Chronicle.record_beat(_beat("first_contact",201,"Strangers at the fire",{"civ_id":"rival_b"}))
	var met:=Chronicle.entries().filter(func(e:Dictionary)->bool:return String(e.kind)=="contact")
	assert_int(met.size()).is_equal(1)
	assert_str(String(met[0].tier)).is_equal("moment")
	assert_str(String(met[0].title)).is_equal("Strangers at the fire")
	assert_str(String(((met[0].action as Dictionary).focus as Dictionary).civ_id)).is_equal("rival_b")
	# An ordinary beat in a crowded month waits as a notice.
	var crowded:=Chronicle.record_beat(_beat("headcount_130",202,"130 of us"))
	assert_str(String(crowded.tier)).is_equal("notice")

func test_near_neighbours_scouts_crossing_ours_are_routine()->void:
	GameState.simulation_events.push_front({"day":0,"title":"Scouts report foreign scout","description":"Returning scouts report a scout of Kintara moving near the marked point.","domain":"diplomacy","severity":"notice","kind":"unit_sighting","civ_id":"rival_b"})
	GameState.simulation_events.push_front({"day":0,"title":"SCOUTS RETURN","description":"The scout party returns after 37 days and charts roughly 210 km of land travel. They crossed the trail of a foreign scout (of unknown strength) and marked where they saw it. They crossed the trail of a foreign scout (of unknown strength) and marked where they saw it.","domain":"diplomacy","severity":"major"})
	Chronicle.ingest_day({"discoveries":[],"progression":[]})
	assert_int(Chronicle.entries("notice").size()).is_equal(0)
	assert_int(Chronicle.entries().size()).is_equal(2)
