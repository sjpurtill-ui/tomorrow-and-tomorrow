extends GdUnitTestSuite
## Standing (docs/STANDING_DESIGN.md): our strengths read from real state, each
## met people's view of us, the dangers Envy and Contempt, and their
## consequences: raids weigh fighting strength (warriors count), envy draws
## raiders, contempt brings demands, awe gifts; our warbands menace newcomers.

const Standing:=preload("res://scripts/standing.gd")
const War:=preload("res://scripts/war_loop.gd")
const Lives:=preload("res://scripts/court_lives.gd")

func before_test()->void:
	OS.set_environment("OPENAI_API_KEY","")
	GameState.reset_for_new_world(515151)
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
	GameState.elapsed_days=400.0
	Standing.forget()

func after_test()->void:
	Standing.forget()
	GameState.elapsed_days=0

func _met(population:float=120.0,warriors:float=6.0,readiness:float=0.55)->String:
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.player_relation.contact_level=2
	civ.player_relation.opinion=0.0
	civ.player_relation.border_tension=0.2
	civ.population=population
	civ.military_population=warriors
	civ.military_readiness=readiness
	ForeignDiplomacy.leader(String(civ.id))
	return String(civ.id)

func _rich(food_days:float)->void:
	GameState.simulation_metrics["food_days"]=food_days
	GameState.resource_stockpiles["Timber"]=600.0
	GameState.resource_stockpiles["Stone"]=600.0

func _arm(troops:int,readiness:float)->void:
	MilitaryCampaign.home_army["troops"]=troops
	MilitaryCampaign.home_army["readiness"]=readiness
	# The month's reading the daily systems use (ConsequenceEngine takes it monthly).
	Standing.record_monthly()

func test_strengths_are_read_from_state_with_reasons()->void:
	var our:=Standing.strengths()
	for id:String in ["might","genius","persuasion","cunning","wealth","splendor","order","endurance","reach"]:
		assert_bool(our.has(id)).override_failure_message(id).is_true()
		assert_float(float(our[id].value)).override_failure_message(id).is_between(0.0,1.0)
		assert_str(String(our[id].why)).override_failure_message(id).is_not_empty()

func test_warriors_count_in_fighting_strength_and_the_raid_ratio()->void:
	var id:=_met()
	_arm(0,0.3)
	var unarmed:=War.ratio(id)
	_arm(12,0.8)
	var armed:=War.ratio(id)
	assert_float(armed).is_less(unarmed*0.8)
	assert_float(Standing.strengths().might.value).is_greater(0.5)

func test_rich_and_unguarded_is_envied_and_held_in_contempt()->void:
	var id:=_met(160.0,10.0,0.7)
	_rich(120.0)
	_arm(0,0.3)
	var weak:=Standing.view_of(id)
	assert_bool(bool(weak.known)).is_true()
	assert_float(float(weak.envy)).is_greater(Standing.ENVY_RAID_FLOOR)
	assert_float(float(weak.contempt)).is_greater(Standing.CONTEMPT_FLOOR)
	_arm(14,0.85)
	var guarded:=Standing.view_of(id)
	assert_float(float(guarded.awe)).is_greater(float(weak.awe))
	assert_float(float(guarded.envy)).is_less(float(weak.envy))
	assert_float(float(guarded.contempt)).is_less(float(weak.contempt))
	# Might menaces: the same people find us less alluring when we bristle.
	assert_float(float(guarded.allure)).is_less_equal(float(weak.allure))

func test_views_move_the_envoys_business()->void:
	var id:=_met(160.0,10.0,0.7)
	_rich(120.0)
	_arm(0,0.3)
	var demands_weak:=Lives.standing_weight("tribute_demand",id)
	_arm(14,0.85)
	var demands_strong:=Lives.standing_weight("tribute_demand",id)
	assert_float(demands_weak).is_greater(demands_strong)
	assert_float(Lives.standing_weight("gift_goods",id)).is_greater_equal(1.0)

func test_a_people_never_met_holds_no_view()->void:
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.player_relation.contact_level=0
	var v:=Standing.view_of(String(civ.id))
	assert_bool(bool(v.known)).is_false()
	assert_float(float(v.envy)).is_equal(0.0)

func test_pride_is_ordinary_for_a_plain_village_and_menace_costs_allure()->void:
	_arm(0,0.3)
	assert_float(float(Standing.pride().value)).is_between(0.45,0.6)
	var calm:=Standing.attraction_shift()
	_arm(14,0.85)
	assert_float(Standing.attraction_shift()).is_less(calm)

func test_the_standing_page_says_what_we_are_and_how_each_people_sees_us()->void:
	var id:=_met(160.0,10.0,0.7)
	_rich(120.0)
	_arm(0,0.3)
	var page=preload("res://scripts/hud/content/dock_content_standing.gd").new(null,null)
	var tab:Dictionary=page.tab(0)
	var board:Dictionary=tab.blocks[0]
	assert_str(String(board.type)).is_equal("standing")
	assert_int((board.strengths as Array).size()).is_equal(9)
	assert_str(String(board.posture.words)).is_not_empty()
	var theirs:Dictionary={}
	for p:Dictionary in board.peoples:
		if String(p.civ_id)==id: theirs=p
	assert_bool(theirs.is_empty()).is_false()
	var names:Array=[]
	for view:Dictionary in theirs.views: names.append(String(view.name))
	assert_array(names).contains_exactly(["Allure","Awe","Fear","Respect","Trust","Resentment"])
	# Rich and unguarded: the page leads with the raid danger and its odds.
	assert_str(String(tab.brief.title)).contains("envy our stores")
	assert_str(String(tab.brief.why)).contains("each month")
	# The years of our name are charted from the monthly record.
	assert_str(String(tab.blocks[1].type)).is_equal("trend_chart")

func test_the_odds_on_the_page_are_the_engines()->void:
	var id:=_met(160.0,10.0,0.7)
	_rich(120.0)
	_arm(0,0.3)
	var view:=Standing.view_of(id)
	var said:=Standing.consequences(id,view)
	var raid:Dictionary={}
	for c:Dictionary in said:
		if String(c.id)=="envy": raid=c
	assert_bool(raid.is_empty()).is_false()
	var chance:=War.envy_raid_chance(id,float(view.envy))
	assert_float(chance).is_greater(0.0)
	assert_str(String(raid.words)).contains(Standing.monthly_odds_words(chance))
	# Envoy business uses the same weights the court's envoys are drawn by.
	for c:Dictionary in said:
		if String(c.id)=="tribute_demand": assert_str(String(c.words)).contains(Standing.times_words(Lives.standing_weight("tribute_demand",id,view)))

func test_the_board_draws_the_rose_the_peoples_and_home()->void:
	var id:=_met(160.0,10.0,0.7)
	_rich(120.0)
	_arm(4,0.6)
	var page=preload("res://scripts/hud/content/dock_content_standing.gd").new(null,null)
	var board=auto_free(preload("res://scripts/hud/standing_board.gd").new())
	add_child(board)
	board.size=Vector2(900,1600)
	board.setup(page.tab(0).blocks[0])
	assert_object(board.find_child("Rose",true,false)).is_not_null()
	assert_int(board.find_child("StrengthList",true,false).get_child_count()).is_equal(10)
	assert_object(board.find_child("People_"+id,true,false)).is_not_null()
	assert_object(board.find_child("Home",true,false)).is_not_null()
	# Laying a people's strengths over ours needs them simulated; a plain
	# test world has no actors, so the chip says we know too little.
	var chip:Button=board.find_child("Compare_"+id,true,false)
	assert_bool(chip.disabled).is_true()
	# The daily refresh updates in place.
	assert_bool(board.update_block(page.tab(0).blocks[0])).is_true()
	# Drawn for real: the rose, the meters and the medallions paint without error.
	var rose:Control=board.find_child("Rose",true,false)
	rose.size=Vector2(420,420)
	rose.set_highlight(2)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_str(rose.tooltip_text).is_equal("")
	assert_str(rose._get_tooltip(rose.size*0.5+Vector2(0,-120))).contains("Might")

func test_every_strength_is_recorded_each_month_for_the_years_chart()->void:
	Standing.record_monthly()
	for row:Array in Standing.STRENGTHS:
		assert_bool(GameState.simulation_metrics.has("standing_"+String(row[0]))).override_failure_message(String(row[0])).is_true()
	var scopes:=preload("res://scripts/strategic_history.gd").capture_scopes()
	assert_bool((scopes.civilization as Dictionary).has("standing_genius")).is_true()
	assert_float(float(scopes.civilization.standing_pride)).is_between(0.0,100.0)

func test_posture_names_the_lean_and_the_neglect()->void:
	var our:Dictionary={}
	for row:Array in Standing.STRENGTHS: our[String(row[0])]={"value":0.4,"why":""}
	assert_str(String(Standing.posture(our).id)).is_equal("balanced")
	our.genius={"value":0.95,"why":""}
	our.might={"value":0.05,"why":""}
	var lean:=Standing.posture(our)
	assert_str(String(lean.id)).is_equal("genius")
	assert_str(String(lean.words)).is_equal("A learned people, with few spears.")
	assert_bool(bool(lean.lopsided)).is_true()
