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

## Rich against the age (standing_scale.gd): deep stores, and materials and
## made goods well past a typical people's (a hoard of food alone is not).
func _rich(food_days:float)->void:
	GameState.simulation_metrics["food_days"]=maxf(food_days,240.0) if food_days>=100.0 else food_days
	GameState.resource_stockpiles["Timber"]=600.0
	GameState.resource_stockpiles["Stone"]=600.0
	GameState.resource_stockpiles["Civilian Goods"]=GameState.population_exact*6.0 if food_days>=100.0 else 0.0

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
	# Ordinary as the home card words it (neither proud, 0.62, nor ashamed, 0.42).
	assert_float(float(Standing.pride().value)).is_between(0.42,0.62)
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
	assert_str(String(tab.brief.title)).contains("envy our goods")
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
	# What the percentages mean, the year's dashes, and the nine.
	assert_int(board.find_child("StrengthList",true,false).get_child_count()).is_equal(11)
	assert_object(board.find_child("Arts",true,false)).is_not_null()
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

func test_pride_forgives_the_chiefs_and_shame_blames_them()->void:
	GameState.simulation_metrics["standing_pride"]=0.5
	assert_float(Standing.blame()).is_equal_approx(1.0,0.0001)
	GameState.simulation_metrics["standing_pride"]=0.85
	assert_float(Standing.blame()).is_equal_approx(0.72,0.0001)
	GameState.simulation_metrics["standing_pride"]=0.2
	assert_float(Standing.blame()).is_equal_approx(1.2,0.0001)
	# A failed aim costs a proud people's chiefs less trust.
	var Aims:=preload("res://scripts/legacy_aims.gd")
	GameState.simulation_metrics["standing_pride"]=0.85
	var proud_cost:=float(Aims.FAIL_METRICS.legitimacy)*Standing.blame()
	GameState.simulation_metrics["standing_pride"]=0.5
	var plain_cost:=float(Aims.FAIL_METRICS.legitimacy)*Standing.blame()
	assert_float(absf(proud_cost)).is_less(absf(plain_cost))

func test_memory_grows_with_what_a_people_knows()->void:
	var Voice:=preload("res://scripts/character_voice.gd")
	Voice.knowledge_override["civ_oral"]=[]
	Voice.knowledge_override["civ_print"]=["printing_process"]
	assert_float(Standing.memory_span("civ_oral")).is_equal(1.0)
	assert_float(Standing.memory_span("civ_print")).is_equal(3.0)
	Voice.knowledge_override.erase("civ_oral")
	Voice.knowledge_override.erase("civ_print")

## Leagues of the fearful (fear_league.gd): two peoples who fear us bind
## together; each weighs our strength against both, and backs the other's raids.
func _met_second(population:float=120.0,warriors:float=6.0,readiness:float=0.55)->String:
	var civ:Dictionary=CivilizationSystem.civilizations[1]
	civ.player_relation.contact_level=2
	civ.player_relation.opinion=0.0
	civ.player_relation.border_tension=0.2
	civ.population=population
	civ.military_population=warriors
	civ.military_readiness=readiness
	ForeignDiplomacy.leader(String(civ.id))
	return String(civ.id)

func test_peoples_who_fear_us_stand_together_and_it_costs_us()->void:
	var first:=_met(100.0,4.0,0.5)
	var second:=_met_second(100.0,4.0,0.5)
	_rich(120.0)
	_arm(14,0.85)
	var DIVINE:=preload("res://scripts/divine_regard.gd")
	var League:=preload("res://scripts/fear_league.gd")
	var alone:=Standing.view_of(first)
	var raid_alone:=War.envy_raid_chance(first,0.6)
	DIVINE.add_civ_dread(first,0.4); DIVINE.add_civ_dread(first,0.4)
	DIVINE.add_civ_dread(second,0.4); DIVINE.add_civ_dread(second,0.4)
	League.monthly(int(GameState.elapsed_days))
	assert_array(League.members()).contains_exactly_in_any_order([first,second])
	var bound:=Standing.view_of(first)
	# Weighed against both of them, our might awes less.
	assert_float(float(bound.strength_ratio)).is_less(float(alone.strength_ratio))
	assert_float(float(bound.awe)).is_less_equal(float(alone.awe))
	assert_float(War.envy_raid_chance(first,0.6)).is_equal_approx(raid_alone*League.RAID_BACKING,0.00001)
	var said:=Standing.consequences(first,bound)
	assert_str(String(said[0].id)).is_equal("league")
	# Fear gone, the league breaks up.
	(DIVINE.store().civ_dread as Dictionary).clear()
	League.monthly(int(GameState.elapsed_days)+30)
	assert_array(League.members()).is_empty()

func test_the_envoy_knows_how_each_people_sees_us_and_says_it()->void:
	var id:=_met(160.0,10.0,0.7)
	_rich(120.0)
	_arm(0,0.3)
	var Facts:=preload("res://scripts/court_facts.gd")
	var Answers:=preload("res://scripts/court_answers.gd")
	var sheet:=Facts.sheet(["common","tribute"])
	var peoples:Array=sheet.standing.peoples
	assert_int(peoples.size()).is_equal(1)
	var name:=String(peoples[0].name)
	assert_str(Facts.text(sheet)).contains("How the peoples we know see us")
	var said:=Answers.answer(sheet,"Why do the %s raid us?" % name)
	assert_str(said).contains("Allure")
	assert_str(said).contains("each month")
	# An official who keeps only the stores does not know it.
	assert_bool(Facts.sheet(["common","stores"]).has("standing")).is_false()
	assert_bool(id!="").is_true()

func test_pride_is_reckoned_the_same_for_every_people()->void:
	# Read from a people's own strengths, never from who has met it: a
	# computer-run people (no views) and ours stand on the same rule.
	var our:=Standing.strengths()
	var alone:=float(Standing.pride(our,[]).value)
	var admired:=float(Standing.pride(our,[{"awe":1.0,"allure":1.0}]).value)
	assert_float(admired).is_equal(alone)
	# Works and might raise it for anyone.
	our.splendor={"value":0.8,"why":""}
	our.might={"value":0.7,"why":""}
	assert_float(float(Standing.pride(our).value)).is_greater(alone)

func test_the_months_reading_survives_the_days_and_is_charted()->void:
	# ConsequenceEngine rebuilds the day's metrics; the month's standing
	# reading must outlive it, or nothing is ever charted.
	Standing.record_monthly()
	var before:=float(GameState.simulation_metrics.get("standing_pride",-1.0))
	assert_float(before).is_greater(0.0)
	GameState.elapsed_days=401.0
	ConsequenceEngine.process_day({})
	assert_float(float(GameState.simulation_metrics.get("standing_pride",-1.0))).is_equal(before)
	var scopes:=preload("res://scripts/strategic_history.gd").capture_scopes()
	assert_bool((scopes.civilization as Dictionary).has("standing_pride")).is_true()

func test_a_heavy_levy_is_resented()->void:
	_arm(0,0.3)
	assert_float(Standing.levy_burden()).is_equal(0.0)
	# A seventh of the people under arms: well past what households carry.
	_arm(roundi(GameState.population_exact*0.14),0.8)
	assert_float(Standing.levy_burden()).is_greater(0.05)

func test_allure_softens_their_bargain_and_contempt_hardens_it()->void:
	var id:=_met(160.0,10.0,0.7)
	var Pacts:=preload("res://scripts/trade_pacts.gd")
	_rich(10.0)
	_arm(14,0.85)
	var respected:=Pacts._threshold(id)
	# Unguarded and poor beside them: less allure, more contempt.
	_arm(0,0.3)
	GameState.simulation_metrics["food_days"]=0.0
	var scorned:=Pacts._threshold(id)
	assert_float(scorned).is_greater(respected)

func test_the_months_reading_counts_the_peoples_moved_against_us()->void:
	_met(160.0,10.0,0.7)
	_rich(120.0)
	_arm(0,0.3)
	assert_int(Standing.danger_count()).is_equal(1)
	assert_float(float(GameState.simulation_metrics.get("standing_dangers",-1.0))).is_equal(1.0)

func test_a_stronger_target_deters_war_and_a_weak_one_emboldens()->void:
	var Strategy:=preload("res://scripts/civilization_strategy.gd")
	var id:=_met(160.0,40.0,0.9)
	var civ:=ForeignDiplomacy.civilization(id)
	_arm(0,0.3)
	var strong:=Standing.war_deterrence(civ)
	assert_float(strong).is_greater(0.0)
	civ.population=40.0; civ.military_population=0.0; civ.military_readiness=0.2
	_arm(14,0.85)
	var weak:=Standing.war_deterrence(civ)
	assert_float(weak).is_less(0.0)
	# At an opinion just short of war, only the emboldened ruler declares.
	var plan:={"war_opinion":-0.4,"war_food":30.0,"offensive":true,"peace_food":10.0,"trade_opinion":0.5,"personality":{"empathy":0.3}}
	var relation:={"opinion":-0.35,"at_war":false,"treaty":"none"}
	assert_str(Strategy.diplomatic_action(relation,plan,90.0,strong)).is_not_equal("declare_war")
	assert_str(Strategy.diplomatic_action(relation,plan,90.0,weak)).is_equal("declare_war")

func test_the_page_tells_what_they_remember_and_what_they_mean_to_do()->void:
	var id:=_met(160.0,10.0,0.7)
	_arm(4,0.6)
	var divine:=preload("res://scripts/divine_regard.gd")
	var answer:=preload("res://scripts/world_answer.gd")
	for i in 6:
		GameState.elapsed_days=400.0+i*100.0
		divine.record_envoy_harm(id,String(CivilizationSystem.civilizations[0].name),"Envoy%d Reed" % i,"kill",0.3)
		preload("res://scripts/rival_rulers.gd").grudge(id,"the killing of their envoy Envoy%d" % i,1.0,"slain_envoy:%d" % i)
	Standing.forget()
	var page=preload("res://scripts/hud/content/dock_content_standing.gd").new(null,null)
	var board:Dictionary=page.tab(0).blocks[0]
	var theirs:Dictionary={}
	for p:Dictionary in board.peoples:
		if String(p.civ_id)==id: theirs=p
	var memories:=PackedStringArray()
	for m:Dictionary in theirs.memories: memories.append(String(m.text))
	assert_str(" ".join(memories)).contains("They tell of the killing of their envoy")
	assert_str(" ".join(memories)).contains("more years")
	# What they mean to do, at the engine's own odds.
	var o:=answer.odds(id,answer.reading(id,Standing.view_of(id)))
	var rows:=PackedStringArray()
	for c:Dictionary in theirs.consequences: rows.append(String(c.words))
	if float(o.all_in)>0.0: assert_str(" ".join(rows)).contains("every spear they have: "+Standing.monthly_odds_words(float(o.all_in)))
	if float(o.bow)>0.0: assert_str(" ".join(rows)).contains("bow and pay us tribute: "+Standing.monthly_odds_words(float(o.bow)))
	# Arming leads the dangers, once our watchers have heard of it.
	answer._begin_arming(id,int(GameState.elapsed_days),{"why_all_in":"they resent us"})
	(answer.state().arming[id] as Dictionary)["heard"]=true
	board=page.tab(0).blocks[0]
	assert_str(String((board.warnings as Array)[0].title)).contains("gathering every spear")
	# Our own people's long memory is on the home card.
	assert_str(String(board.home.told)).contains("a guest killed in the god's hall")

## The god's people, loving or afraid (standing.god_effects): love draws
## families in and binds them; dread drives them off and, past a point, frays
## them, though it props up the chiefs' word. Read once a month, in the god's
## scope only; another people's month is neutral.
func test_love_and_dread_of_the_god_move_the_home_month()->void:
	var metrics:Dictionary=WorldSimulation.state.simulation_metrics
	metrics["standing_pride"]=0.5; metrics["standing_allure"]=Standing.ALLURE_ORDINARY; metrics["standing_might"]=0.0
	metrics["standing_love"]=Standing.LOVE_ORDINARY; metrics["standing_dread"]=0.0
	var calm_attraction:=Standing.attraction_shift()
	var calm_cohesion:=Standing.cohesion_shift()
	metrics["standing_love"]=0.4
	assert_float(Standing.attraction_shift()).is_greater(calm_attraction)
	assert_float(Standing.cohesion_shift()).is_greater(calm_cohesion)
	metrics["standing_love"]=Standing.LOVE_ORDINARY; metrics["standing_dread"]=0.5
	assert_float(Standing.attraction_shift()).is_less(calm_attraction)
	assert_float(Standing.cohesion_shift()).is_less(calm_cohesion)
	assert_float(Standing.legitimacy_shift()).is_greater(0.0)
	# The page says it, with the engine's own numbers.
	var effects:=Standing.home_effects()
	assert_float(float(effects.god.drive_off)).is_equal_approx(-0.5*Standing.DREAD_DRIVE_OFF*100.0,0.01)
	var words:Dictionary=preload("res://scripts/hud/standing_board.gd")._home_words({"effects":effects})
	assert_str(String(words.god)).contains("dread drives families off −4.0")
	# A god who has done nothing worth telling moves nobody (parity with
	# every other people's month).
	Standing.record_monthly()
	assert_float(float(metrics.standing_love)).is_equal(0.0)
	assert_float(float(metrics.standing_dread)).is_equal(0.0)
	assert_bool(preload("res://scripts/hud/standing_board.gd")._home_words({"effects":Standing.home_effects()}).has("god")).is_false()
