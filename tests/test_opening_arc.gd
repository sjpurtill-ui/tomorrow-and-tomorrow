extends GdUnitTestSuite
## The opening: regional neighbours, signs of strangers, the fire circle and
## the Opening Arc's beats.
const Start=preload("res://scripts/civilization_start.gd")
const Signs=preload("res://scripts/neighbor_signs.gd")
const Lines=preload("res://scripts/fire_circle_voice.gd")
const Arc=preload("res://scripts/opening_arc.gd")
const Voice=preload("res://scripts/character_voice.gd")

func before_test()->void:
	GameState.reset_for_new_world(424242)
	CivilizationSystem.reset_for_new_world()
	PeopleDirection.reset_for_new_world()

func test_every_seat_has_neighbours_within_a_few_days_walk()->void:
	for seed_value in [424242,77013,91420]:
		GameState.reset_for_new_world(seed_value)
		for group in 3:
			var anchor:=Start.candidate(seed_value,group*Start.REGION_SEATS)
			for member in range(1,Start.REGION_SEATS):
				var seat:=group*Start.REGION_SEATS+member
				var point:=Start.candidate(seed_value,seat)
				assert_bool(point==Start.candidate(seed_value,seat)).is_true()
				assert_float(point.distance_to(anchor)).override_failure_message("seed %d seat %d is %.0f km from its region" % [seed_value,seat,point.distance_to(anchor)]).is_between(Start.NEIGHBOR_MIN_KM-Start.REGION_CELL_KM,Start.NEIGHBOR_MAX_KM+Start.REGION_CELL_KM)
				assert_bool(Start.supports_founders(PlanetEnvironment.profile_at(point))).is_true()

func test_the_players_seat_is_placed_like_any_other_region_anchor()->void:
	assert_vector(Start.candidate(424242,0)).is_equal(Start._planet_candidate(424242,0))
	assert_vector(Start.candidate(424242,3)).is_equal(Start._planet_candidate(424242,3))

func test_the_audit_seeds_now_have_a_reachable_neighbour()->void:
	for seed_value in [424242,77013]:
		GameState.reset_for_new_world(seed_value)
		CivilizationSystem.reset_for_new_world()
		var home:=Start.candidate(seed_value,0)
		var nearest:=INF
		for civ:Dictionary in CivilizationSystem.civilizations:nearest=minf(nearest,home.distance_to(CivilizationSystem._civilization_world_position(civ)))
		assert_float(nearest).override_failure_message("seed %d nearest rival %.0f km" % [seed_value,nearest]).is_less_equal(Start.NEIGHBOR_MAX_KM+Start.REGION_CELL_KM)

func _route_past(home:Vector2,miss_km:float)->Array:
	var a:=home+Vector2(-150,miss_km);var b:=home+Vector2(150,miss_km)
	return [{"x":a.x,"z":a.y},{"x":b.x,"z":b.y}]

func test_a_route_through_a_neighbours_range_brings_home_signs_not_contact()->void:
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var home:Vector2=CivilizationSystem._civilization_world_position(civ)
	var signs:=Signs.read_route(CivilizationSystem,_route_past(home,80.0),40)
	var mine:=signs.filter(func(s:Dictionary)->bool:return String(s.civ_id)==String(civ.id))
	assert_int(mine.size()).is_equal(1)
	var sign:Dictionary=mine[0]
	assert_str(String(sign.kind)).is_equal("sign")
	assert_bool(String(sign.description).contains(String(civ.name))).override_failure_message("a sign must not name the people").is_false()
	var estimate:=Vector2(float(sign.estimate.x),float(sign.estimate.z))
	assert_float(estimate.distance_to(home)).is_less(Signs.ENCOUNTER_KM)
	assert_int(int((civ.player_relation as Dictionary).get("contact_level",0))).is_equal(0)
	# Close enough to meet them is contact, not a sign; far away is nothing.
	assert_int(Signs.read_route(CivilizationSystem,_route_past(home,30.0),40).filter(func(s:Dictionary)->bool:return String(s.civ_id)==String(civ.id)).size()).is_equal(0)
	assert_int(Signs.read_route(CivilizationSystem,_route_past(home,400.0),40).filter(func(s:Dictionary)->bool:return String(s.civ_id)==String(civ.id)).size()).is_equal(0)

func test_staff_follow_a_returned_sign_toward_its_estimate()->void:
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var home:Vector2=CivilizationSystem._civilization_world_position(civ)
	var card:Dictionary=Signs.read_route(CivilizationSystem,_route_past(home,80.0),40).filter(func(s:Dictionary)->bool:return String(s.civ_id)==String(civ.id))[0]
	CivilizationSystem.scout_reports.push_front({"day":40,"discoveries":[card]})
	var target:=Signs.sign_to_follow(CivilizationSystem)
	assert_str(target).is_equal("sign:%s" % String(civ.id))
	assert_bool(CivilizationSystem._scout_target_option(target).is_empty()).is_false()
	assert_str(Signs.sign_to_follow(CivilizationSystem,{target:100},50)).is_not_equal(target)
	CivilizationSystem.scout_reports.clear()

func test_fire_circle_lines_exist_for_every_voiced_manner_and_fit_the_founding_era()->void:
	var tags:=Voice.era_tags("player")
	for model_id in Voice.MODEL_BANKS:
		assert_bool(Lines.LINES.has(model_id)).override_failure_message("no fire-circle lines for %s" % model_id).is_true()
	for model_id in Lines.LINES:
		for key in ["ask","reply","name","named","later"]:
			var text:=String(Lines.LINES[model_id][key]).replace("{name}","Alderford")
			assert_bool(Voice.permits(text,tags)).override_failure_message("%s/%s is anachronistic: %s" % [model_id,key,text]).is_true()
			assert_bool(Voice.imitation_ok(text)).is_true()
	for id in Lines.ANSWERS:
		assert_bool(PeopleDirection.AMBITIONS.has(id)).is_true()
		assert_bool(Voice.permits(String(Lines.ANSWERS[id]),tags)).is_true()
	assert_int(Lines.ANSWERS.size()).is_equal(PeopleDirection.AMBITIONS.size())

func test_four_answers_suit_the_land_and_any_words_find_a_purpose()->void:
	var offered:=Lines.offered(PlanetEnvironment.profile_at(Vector2.ZERO),424242)
	assert_int(offered.size()).is_equal(4)
	for id in offered: assert_bool(PeopleDirection.AMBITIONS.has(id)).is_true()
	assert_int(Lines.others(offered).size()).is_equal(PeopleDirection.AMBITIONS.size()-4)
	assert_str(Lines.interpret("That no child of ours ever went hungry",offered[0])).is_equal("sustenance")
	assert_str(Lines.interpret("They should fear us and remember our vengeance",offered[0])).is_equal("retribution")
	assert_str(Lines.interpret("We walked beyond every horizon",offered[0])).is_equal("horizons")
	assert_str(Lines.interpret("blue",offered[0])).is_equal(offered[0])
	assert_int(Lines.name_suggestions(PlanetEnvironment.profile_at(Vector2.ZERO),7).size()).is_equal(3)

func test_the_fire_circle_asks_once_and_sets_the_founding_purpose()->void:
	var screen:Control=auto_free(preload("res://scripts/hud/fire_circle_opening.gd").new())
	add_child(screen)
	await get_tree().process_frame
	assert_bool(screen.opening).is_true()
	assert_int(screen.ambition_buttons.size()).is_equal(PeopleDirection.AMBITIONS.size())
	assert_int(screen.ambition_buttons.filter(func(b:Button)->bool:return b.visible).size()).is_equal(4)
	var confirm:Button=screen.pages[0].get_node("ConfirmFocus")
	assert_bool(confirm.disabled).is_true()
	for button in screen.ambition_buttons:
		assert_bool(String(button.text).to_upper()==String(button.text)).override_failure_message("answers are spoken, not tagged").is_false()
	screen.ambition_buttons[1].pressed.emit()
	assert_bool(confirm.disabled).is_false()
	var chosen:=String(screen.ambition_buttons[1].get_meta("ambition"))
	confirm.pressed.emit()
	assert_str(PeopleDirection.ambition).is_equal(chosen)

func test_the_first_fire_names_the_home_in_voice()->void:
	var screen:Control=auto_free(preload("res://scripts/hud/fire_circle_opening.gd").new())
	screen.mode="name"
	add_child(screen)
	await get_tree().process_frame
	assert_object(screen.name_input).is_not_null()
	assert_object(screen.later_button).is_not_null()
	assert_bool(screen.named_line("Alderford").contains("Alderford")).is_true()

func test_beats_are_recorded_emitted_and_reset_with_a_new_world()->void:
	var heard:Array=[]
	var listener:=func(beat:Dictionary)->void:heard.append(beat)
	PeopleDirection.opening_beat.connect(listener)
	var beat:=Arc._emit("first_signs",40,"Smoke on the horizon","Smoke rose at dusk far off to the north.",{})
	PeopleDirection.opening_beat.disconnect(listener)
	assert_int(heard.size()).is_equal(1)
	assert_str(String(beat.tier)).is_equal("moment")
	assert_bool(Arc.done("first_signs")).is_true()
	assert_str(String(GameState.simulation_events[0].get("kind",""))).is_equal("opening_beat")
	GameState.reset_for_new_world(77013)
	assert_bool(Arc.done("first_signs")).is_false()

func test_default_speed_is_one_day_per_second()->void:
	var terrain:=preload("res://scripts/local_terrain.gd")
	assert_float(float(terrain.SPEED_HOURS_PER_REAL_SECOND[int(terrain.DEFAULT_PLAY_SPEED)])).is_equal(24.0)

func test_the_arc_is_saved_with_the_people_and_old_saves_start_it_empty()->void:
	var Save=preload("res://scripts/save_system.gd")
	Arc._emit("first_contact",90,"Strangers at the fire","People of the valley, met.",{})
	var captured:Dictionary=Save._capture_reflected(PeopleDirection,[])
	assert_bool(captured.has("opening_arc")).is_true()
	PeopleDirection.opening_arc={}
	Save._apply_reflected(PeopleDirection,captured)
	assert_bool(Arc.done("first_contact")).is_true()
	# A save made before the arc existed carries no opening_arc; an arc left
	# over from later in the session does not survive the load.
	captured.erase("opening_arc")
	(PeopleDirection.opening_arc as Dictionary)["last_day"]=900
	GameState.elapsed_days=200.0
	Save._apply_reflected(PeopleDirection,captured)
	assert_bool(Arc.done("first_contact")).is_false()

func test_the_chief_at_the_opening_fire_is_the_one_later_seated()->void:
	for seed_value in [424242,77013,91420,5,2024]:
		GameState.reset_for_new_world(seed_value)
		GovernmentPeopleSystem.reset_for_new_world()
		var preview:=Lines.hearth_chief()
		assert_bool(preview.is_empty()).is_false()
		GameState.settlement_completed.append("Hearth Circle")
		GameState.player_settlements.append({"id":"home","name":"Home","primary":true,"position":Vector2.ZERO})
		GameState.population_total=120
		GovernmentPeopleSystem.initialize()
		var seated:=GovernmentPeopleSystem.officeholder("Steward")
		assert_str(String(seated.get("name",""))).override_failure_message("seed %d previewed %s but seated %s" % [seed_value,String(preview.name),String(seated.get("name",""))]).is_equal(String(preview.name))

func test_a_court_childs_name_takes_no_epithet_or_place_from_the_parent()->void:
	var EraNames=preload("res://scripts/era_names.gd")
	assert_str(EraNames.family_of({"name":"Tilla of Stonewash","family":""})).is_equal("")
	assert_str(EraNames.family_of({"name":"Ysa Stone-Hand","family":""})).is_equal("")
	assert_str(EraNames.family_of({"name":"Mara Voss","family":"Voss"})).is_equal("Voss")
