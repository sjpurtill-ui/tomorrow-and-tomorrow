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
	assert_int(told.size()).is_equal(2)
	assert_str(String(told[1].title)).is_equal("The scouts come home")
	assert_str(String(told[1].text)).contains("traveling band")
	assert_str(String(told[1].text)).not_contains("No organized foreign polity")
	assert_str(String(told[0].title)).is_equal("Sana Ivers has died")
	assert_str(String(told[0].text)).not_contains("succession rules")

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
