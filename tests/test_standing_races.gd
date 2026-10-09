extends GdUnitTestSuite
## Who leads (standing_races.gd): the four plain races between peoples, with
## the band our knowledge of them allows and "unknown" where we know too little.

const Standing:=preload("res://scripts/standing.gd")
const Races:=preload("res://scripts/standing_races.gd")

func before_test()->void:
	OS.set_environment("OPENAI_API_KEY","")
	WorldSimulation.clear()
	GameState.reset_for_new_world(616161)
	SettlementModel.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	CivilizationSystem.reset_for_new_world(); CivilizationSystem.initialize()
	ForeignDiplomacy.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world()
	GameState.civic_api_enabled=false
	GameState.initialize_population_model()
	GameState.settlement_site_committed=true; GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded(); GovernmentPeopleSystem.initialize()
	GameState.elapsed_days=75*365
	WorldSimulation.context_provider=func(_o:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":0.3,"surface_water_recognized":true}
	for civ:Dictionary in CivilizationSystem.civilizations.slice(0,2):
		WorldSimulation.create_actor(String(civ.id),616161,Vector2.ZERO)
		WorldSimulation.actors[String(civ.id)].controller="manual"

func after_test()->void:
	WorldSimulation.clear()
	GameState.elapsed_days=0

func _met(index:int,intel:float)->String:
	var civ:Dictionary=CivilizationSystem.civilizations[index]
	civ.player_relation.contact_level=2
	civ.player_relation.contact_intelligence=intel
	var id:=String(civ.id)
	WorldSimulation.scoped(id,func()->void:
		WorldSimulation.state.elapsed_days=75*365
		Standing.record_monthly())
	return id

func _names()->Dictionary:
	var out:={}
	for civ:Dictionary in CivilizationSystem.civilizations:out[String(civ.id)]=String(civ.name)
	return out

func test_four_races_each_with_us_in_the_order()->void:
	var well:=_met(0,0.9)
	var races:=Races.races(Standing.strengths(),_names())
	assert_int(races.size()).is_equal(4)
	for race:Dictionary in races:
		var ours:=0
		var known_before_unknown:=true
		var seen_unknown:=false
		for row:Dictionary in race.rows:
			if bool(row.ours):ours+=1
			if bool(row.unknown):seen_unknown=true
			elif seen_unknown:known_before_unknown=false
		assert_int(ours).is_equal(1)
		assert_bool(known_before_unknown).is_true()
		assert_bool(race.rows.any(func(r:Dictionary)->bool:return String(r.civ_id)==well)).is_true()
	# Their rows carry a band that holds our estimate; ours is exact.
	for row:Dictionary in races[0].rows:
		assert_float(float(row.low)).is_less_equal(float(row.value)+0.0001)
		assert_float(float(row.high)).is_greater_equal(float(row.value)-0.0001)

func test_a_people_we_know_too_little_of_is_unknown_not_guessed()->void:
	var id:=_met(0,0.02)
	var races:=Races.races(Standing.strengths(),_names())
	for race:Dictionary in races:
		for row:Dictionary in race.rows:
			if String(row.civ_id)==id:
				assert_bool(bool(row.unknown)).is_true()
				assert_str(String(row.text)).contains("unknown")
		assert_bool(bool((race.rows[race.rows.size()-1] as Dictionary).unknown)).is_true()

func test_nobody_met_means_no_one_to_measure_against()->void:
	var races:=Races.races(Standing.strengths(),_names())
	assert_str(String(races[0].standing)).contains("no one")
	assert_int((races[0].rows as Array).size()).is_equal(1)

func test_every_race_is_a_plain_count_never_a_percentage()->void:
	_met(0,0.9)
	for race:Dictionary in Races.races(Standing.strengths(),_names()):
		for row:Dictionary in race.rows:
			assert_str(String(row.text)).not_contains("%")
	assert_str(Races._amount("learning",640.0,true)).is_equal("640 practices known")
	assert_str(Races._amount("works",0.0)).is_equal("no great work yet")
	assert_str(Races._words("wealth",12345.0,9000.0,15000.0,false)).is_equal("about 12,000 goods (9,000 to 15,000)")

func test_head_counts_are_said_in_two_figures_so_a_day_does_not_redraw_them()->void:
	assert_int(Races._round_count(1234.0)).is_equal(1200)
	assert_int(Races._round_count(87.0)).is_equal(87)
	assert_str(Races._grouped(12000)).is_equal("12,000")

func test_a_ruler_boasts_beyond_the_truth_by_their_bent_and_a_load_never_rerolls_it()->void:
	var id:=_met(0,0.9)
	var leader:=ForeignDiplomacy.leader(id)
	leader["temperament"]="Proud guardian"
	var day:=75*365
	var first:=Races.boast_facts(id,day)
	var again:=Races.boast_facts(id,day)
	assert_array(first).is_not_empty()
	assert_str(str(first)).is_equal(str(again))
	var truth_pop:=float(Races.their_measures(id).get("people",0.0))
	for entry:Dictionary in first:
		var boast:Dictionary=entry.f.boast
		assert_str(String(entry.f.fact_kind)).starts_with("boast_")
		if String(boast.race)=="people": assert_float(float(boast.claimed)).is_greater_equal(truth_pop)
	# A modest ruler holds back or tells it straight.
	leader["temperament"]="Bridge-builder"
	for entry:Dictionary in Races.boast_facts(id,day):
		if String(entry.f.boast.race)=="people": assert_float(float(entry.f.boast.claimed)).is_less_equal(truth_pop*1.06)

func test_a_kept_boast_shows_beside_our_reading_and_is_flagged_when_stretched()->void:
	var id:=_met(0,0.9)
	var truth:=float(Races.their_measures(id).get("wealth",0.0))
	Races.remember_boast(id,{"race":"wealth","claimed":truth*3.0+100.0,"day":75*365-40,"text":"x"})
	var races:=Races.races(Standing.strengths(),_names())
	var found:=false
	for race:Dictionary in races:
		if String(race.id)!="wealth": continue
		for row:Dictionary in race.rows:
			if String(row.civ_id)==id:
				found=true
				assert_str(String(row.said)).contains("claimed")
				assert_str(String(row.said)).contains("stretched")
	assert_bool(found).is_true()

func test_our_eyes_name_themselves_as_the_source_and_judge_a_boast_by_the_truth()->void:
	var id:=_met(0,0.6)
	var Covert:=preload("res://scripts/covert_ops.gd")
	Covert.forget()
	CV_override()
	var op:=Covert.launch("plant",id,"","trader",Covert.volunteer())
	op["stage"]="in_place"
	op["settled_day"]=int(GameState.elapsed_days)-12*365
	var truth:=float(Races.their_measures(id).get("people",0.0))
	Races.remember_boast(id,{"race":"people","claimed":truth*3.0+50.0,"day":75*365-30,"text":"x"})
	var row:Dictionary={}
	for r:Dictionary in Races.races(Standing.strengths(),_names())[0].rows:
		if String(r.civ_id)==id: row=r
	assert_str(String(row.get("source",""))).contains("12 years")
	assert_str(String(row.get("said",""))).contains("Our eyes among them say it is stretched")
	Covert.forget()
	(preload("res://scripts/character_voice.gd") as GDScript).knowledge_override.clear()

func CV_override()->void:
	(preload("res://scripts/character_voice.gd") as GDScript).knowledge_override["player"]=["phonetic_notation","copper_smelting","seed_selection"]

func test_a_met_people_the_board_cannot_name_still_shows_its_name_never_its_id()->void:
	var id:=_met(0,0.05)
	var name:=String(CivilizationSystem.civilizations[0].name)
	for race:Dictionary in Races.races({},{}):
		for row:Dictionary in race.rows:
			if String(row.civ_id)!=id:continue
			assert_str(String(row.name)).is_equal(name)
			assert_bool(String(row.name).begins_with("civ_")).is_false()
