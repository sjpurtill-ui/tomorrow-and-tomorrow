extends GdUnitTestSuite
## Standing against the age (standing_scale.gd), other peoples as we know them,
## and cunning and persuasion at work (standing.gd). The player, 2026-10-03:
## "Getting 100% in things seems to be so easy... What is the 100% relative
## to?" and "are cunning and persuasion truly represented enough?"

const Standing:=preload("res://scripts/standing.gd")
const Scale:=preload("res://scripts/standing_scale.gd")
const War:=preload("res://scripts/war_loop.gd")

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

func after_test()->void:
	WorldSimulation.clear()
	GameState.elapsed_days=0

func _met(index:int=0,intel:float=0.2)->String:
	var civ:Dictionary=CivilizationSystem.civilizations[index]
	civ.player_relation.contact_level=2
	civ.player_relation.contact_intelligence=intel
	civ.player_relation.opinion=0.0
	civ.population=200.0
	civ.military_population=8.0
	civ.military_readiness=0.6
	ForeignDiplomacy.leader(String(civ.id))
	return String(civ.id)

func _arts(cunning:float,persuasion:float)->void:
	GameState.simulation_metrics["standing_cunning"]=cunning
	GameState.simulation_metrics["standing_persuasion"]=persuasion

# ------------------------------------------------------------- the yardstick

func test_the_yardstick_reads_typical_half_best_documented_eight_tenths_and_the_most_whole()->void:
	var a:=[10.0,30.0,120.0,365.0]
	assert_float(Scale.score(30.0,a)).is_equal_approx(0.5,0.0001)
	assert_float(Scale.score(120.0,a)).is_equal_approx(0.8,0.0001)
	assert_float(Scale.score(365.0,a)).is_equal_approx(1.0,0.0001)
	assert_float(Scale.score(10.0,a)).is_equal_approx(0.2,0.0001)
	assert_float(Scale.score(0.0,a)).is_equal(0.0)
	# A log scale: each doubling past the typical gains about as much.
	var first:=Scale.score(60.0,a)-Scale.score(30.0,a)
	var second:=Scale.score(120.0,a)-Scale.score(60.0,a)
	assert_float(absf(first-second)).is_less(0.02)
	# Nothing reads typical while nothing is typical, and falls away smoothly.
	assert_float(Scale.score(1.0,[0.8,1.0,2.0,4.0])).is_equal_approx(0.5,0.0001)
	assert_float(Scale.score(1.0,[0.8,1.05,2.0,4.0])).is_between(0.4,0.5)
	# Shares are read on their shortfall: 0.97 against a typical 0.93.
	assert_float(Scale.score_share(0.93,[0.75,0.93,0.98,0.995])).is_equal_approx(0.5,0.0001)
	assert_float(Scale.score_share(0.995,[0.75,0.93,0.98,0.995])).is_equal_approx(1.0,0.0001)

func test_the_anchors_are_the_benchmarks()->void:
	# Might from defense_labor_share (benchmarks_600.json, year 300: 2/5/10/18).
	var bench:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/research/benchmarks_600.json"))
	var band:Dictionary=bench.metrics.defense_labor_share.years["300"]
	var might:=Scale.might_anchors(300.0)
	assert_float(float(might[1])).is_equal_approx(float(band.typical)/100.0*Scale.ABLE_SHARE*Scale.READY,0.00001)
	assert_float(float(might[3])).is_equal_approx(float(band.max)/100.0*Scale.ABLE_SHARE*Scale.READY,0.00001)
	# Genius from discoveries_known at 1200, at the engine's pace.
	var later:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/research/benchmarks_1200.json"))
	var known:Dictionary=later.metrics.discoveries_known.years["1200"]
	assert_float(float(Scale.known_anchors(1200.0)[1])).is_equal_approx(float(known.typical)*Scale.ENGINE_PACE,0.001)
	assert_float(float(Scale.known_anchors(1200.0)[3])).is_equal_approx(float(known.max)*Scale.ENGINE_PACE,0.001)
	# Before 600 the fast sim's balanced people, meeting the benchmark at 600.
	assert_float(float(Scale.known_anchors(599.9)[1])).is_equal_approx(float(Scale.known_anchors(600.0)[1]),2.0)

func test_a_food_hoard_fills_no_strength_by_itself()->void:
	GameState.simulation_metrics["food_days"]=5000.0
	for res in ["Timber","Stone","Clay","Fiber Plants","Civilian Goods"]: GameState.resource_stockpiles[res]=0.0
	var our:=Standing.strengths()
	assert_float(float(our.wealth.value)).is_less(0.55)
	assert_float(float(our.endurance.value)).is_less(0.8)
	for row:Array in Standing.STRENGTHS:
		assert_float(float(our[String(row[0])].value)).override_failure_message(String(row[0])).is_less(0.95)
	# Each reason names what the age expects.
	assert_str(String(our.wealth.why)).contains("a typical people of our age")

func test_a_typical_people_of_its_age_reads_about_half()->void:
	# What a typical people of year 75 holds (standing_scale.gd anchors).
	var pop:=float(GameState.population_exact)
	var year:=75.0
	GameState.simulation_metrics["food_days"]=float(Scale.anchors(Scale.STORES,year)[1])
	GameState.resource_stockpiles["Timber"]=pop*float(Scale.anchors(Scale.MATERIALS,year)[1])
	GameState.resource_stockpiles["Civilian Goods"]=pop*float(Scale.anchors(Scale.GOODS,year)[1])
	var wealth:=float(Standing.strengths().wealth.value)
	assert_float(wealth).is_equal_approx(0.5,0.02)
	# Might: the typical share ready to fight.
	var a:=Scale.might_anchors(year)
	MilitaryCampaign.home_army["readiness"]=0.9
	MilitaryCampaign.home_army["troops"]=roundi(pop*float(a[1])/0.9)
	assert_float(float(Standing.strengths().might.value)).is_between(0.4,0.6)
	# Twice the age's learning, and a share at research past the best, reads high.
	var known:=float(Scale.known_anchors(year)[1])
	var ids:Array=[]
	for i in roundi(known*1.28): ids.append("x_%d" % i)
	GameState.known_discoveries.assign(ids)
	var genius:Dictionary=Standing.strengths().genius
	assert_float(float((genius.parts as Array)[0].score)).is_equal_approx(0.8,0.02)

func test_every_reason_says_what_it_is_compared_with()->void:
	var our:=Standing.strengths()
	for id in ["might","wealth","endurance","genius","splendor","order","reach","cunning"]:
		assert_str(String(our[id].why)).override_failure_message(id).contains("typical")
	# Persuasion names who speaks for us; before the envoy's office, the chief.
	assert_str(String(our.persuasion.why)).contains("speaks for us")

# --------------------------------------------- other peoples, as we know them

func _actors()->void:
	WorldSimulation.context_provider=func(_o:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":0.3,"surface_water_recognized":true}
	for civ:Dictionary in CivilizationSystem.civilizations.slice(0,2):
		WorldSimulation.create_actor(String(civ.id),616161,Vector2.ZERO)
		WorldSimulation.actors[String(civ.id)].controller="manual"

func test_genius_reads_the_peoples_we_know_never_a_false_zero()->void:
	_actors()
	var id:=_met(0,0.95)
	var theirs:Array=[]
	for i in 600: theirs.append("their_%d" % i)
	WorldSimulation.scoped(id,func()->void:
		WorldSimulation.state.elapsed_days=75*365
		WorldSimulation.state.known_discoveries.assign(theirs))
	_arts(1.0,0.5)
	var rival:=Standing.best_known_rival()
	assert_str(String(rival.civ_id)).is_equal(id)
	# Known well and watched closely: their own count, exactly.
	assert_float(float(rival.known)).is_equal_approx(600.0,1.0)
	assert_str(String(Standing.strengths().genius.why)).contains("knows 600")
	# Hardly known and no cunning: "unknown", never 0.
	CivilizationSystem.civilizations[0].player_relation.contact_intelligence=0.05
	_arts(0.0,0.5)
	var hidden:=Standing.best_known_rival()
	assert_bool(bool(hidden.get("unknown",false))).is_true()
	assert_str(String(Standing.strengths().genius.why)).contains("too little")

func test_their_strengths_come_from_their_own_ledger_with_a_band_that_cunning_narrows()->void:
	_actors()
	var id:=_met(0,0.3)
	# Their own month's reading, in their own scope.
	WorldSimulation.scoped(id,func()->void:
		WorldSimulation.state.elapsed_days=75*365
		Standing.record_monthly())
	var truth:=Standing.their_true(id)
	assert_int(truth.size()).is_equal(9)
	_arts(0.2,0.5)
	var dull:=Standing.their_strengths(id)
	_arts(0.9,0.5)
	var sharp:=Standing.their_strengths(id)
	var dull_band:=float(dull.might.high)-float(dull.might.low)
	var sharp_band:=float(sharp.might.high)-float(sharp.might.low)
	assert_float(sharp_band).is_less(dull_band)
	assert_float(Standing.estimate_right_odds(Standing.certainty(id))).is_greater(0.3)
	# The truth lies within the band.
	for row:Array in Standing.STRENGTHS:
		var sid:=String(row[0])
		assert_float(float(truth[sid])).override_failure_message(sid).is_between(float(sharp[sid].low)-0.0001,float(sharp[sid].high)+0.0001)
	# Reading never makes or remakes their world.
	assert_int((WorldSimulation.actors[id].systems.CivilizationSystem.civilizations as Array).size()).is_equal(0)

func test_parity_the_same_state_reads_the_same_in_any_scope()->void:
	_actors()
	var id:=String(CivilizationSystem.civilizations[0].id)
	var ours:=Standing.strengths()
	var theirs:Dictionary=WorldSimulation.scoped(id,func()->Dictionary:
		var s=WorldSimulation.state
		s.elapsed_days=GameState.elapsed_days
		s.simulation_metrics["food_days"]=float(GameState.simulation_metrics.get("food_days",0.0))
		return Standing.strengths())
	# The yardstick is the age's, not the god's: wealth's food part reads the same.
	assert_float(float(theirs.wealth.parts[0].score)).is_equal_approx(float(ours.wealth.parts[0].score),0.0001)

# ---------------------------------------------------------- cunning at work

func test_cunning_sees_raids_coming_and_the_watch_meets_them()->void:
	var id:=_met()
	var day:=int(GameState.elapsed_days)
	_arts(0.95,0.5)
	var seen:=0
	var due_seen:=-1
	for k in 60:
		War.front(id)["pending"]={}
		War._schedule(id,day+30+k,"envy","envy")
		if bool((War.front(id).pending as Dictionary).get("seen",false)):
			seen+=1
			if due_seen<0: due_seen=day+30+k
	_arts(0.05,0.5)
	var seen_dull:=0
	for k in 60:
		War.front(id)["pending"]={}
		War._schedule(id,day+30+k,"envy","envy")
		if bool((War.front(id).pending as Dictionary).get("seen",false)): seen_dull+=1
	assert_int(seen).is_greater(seen_dull+20)
	# Seen, the warning comes on its day and the watch keeps the approaches.
	_arts(0.95,0.5)
	War.front(id)["pending"]={}
	War._schedule(id,due_seen,"envy","envy")
	var f:=War.front(id)
	var warn:=int((f.pending as Dictionary).warn_day)
	assert_int(due_seen-warn).is_equal(Standing.forewarn_days(0.95))
	War._forewarn(id,f,warn)
	assert_int(int(f.guard_until)).is_greater(due_seen)

func test_cunning_reads_bluffs_and_a_typical_people_keeps_the_old_odds()->void:
	var typical:=Standing.bluff_reading(0.5)
	assert_float(float(typical.tells)).is_equal_approx(0.85,0.0001)
	assert_float(float(typical.signs)).is_equal_approx(0.7,0.0001)
	assert_float(float(typical.false_tells)).is_equal_approx(0.15,0.0001)
	assert_float(float(Standing.bluff_reading(1.0).tells)).is_greater(0.95)
	assert_float(float(Standing.bluff_reading(0.0).false_tells)).is_greater(0.25)

func test_cunning_lifts_our_agents_and_catches_theirs()->void:
	var id:=_met()
	var Covert:=preload("res://scripts/covert_ops.gd")
	var agent:={"tongue":0.5,"stealth":0.5,"nerve":0.5,"blade":0.5,"poison":0.5}
	_arts(0.1,0.5)
	var dull:=Covert.odds("watch",id,"","trader",agent)
	var dull_catch:=Covert._catch_chance()
	_arts(0.9,0.5)
	var sharp:=Covert.odds("watch",id,"","trader",agent)
	assert_float(float(sharp.success)).is_greater(float(dull.success))
	assert_float(float(sharp.caught)).is_less(float(dull.caught))
	assert_float(Covert._catch_chance()).is_greater(dull_catch)

func test_cunning_sharpens_every_look_at_their_towns()->void:
	var chart=CivilizationSystem.city_intelligence
	var place:Dictionary={}
	for site:Dictionary in chart.sites(false): place=site; break
	if place.is_empty(): return
	_arts(0.05,0.5)
	var dull:Dictionary=chart.capture("player",String(place.city_id),0.6,int(GameState.elapsed_days),"test","dull")
	_arts(0.95,0.5)
	var sharp:Dictionary=chart.capture("player",String(place.city_id),0.6,int(GameState.elapsed_days),"test","sharp")
	assert_float(float(sharp.quality)).is_greater(float(dull.quality))
	if (dull.fields as Dictionary).has("population") and (sharp.fields as Dictionary).has("population"):
		var dull_width:=float(dull.fields.population.high)-float(dull.fields.population.low)
		var sharp_width:=float(sharp.fields.population.high)-float(sharp.fields.population.low)
		assert_float(sharp_width).is_less_equal(dull_width)

func test_an_arming_our_watchers_miss_is_heard_only_late()->void:
	var id:=_met()
	var Answer:=preload("res://scripts/world_answer.gd")
	_arts(0.0,0.5)
	var day:=int(GameState.elapsed_days)
	var missed:=""
	for k in 40:
		Answer.state().arming.erase(id)
		Answer._begin_arming(id,day+k,{"why_all_in":"they resent us"})
		if not bool((Answer.state().arming[id] as Dictionary).get("heard",true)):
			missed=str(day+k); break
	assert_str(missed).is_not_empty()
	# Missed: nothing on the Standing page or at court.
	assert_bool(Answer.heard_of_arming(id).is_empty()).is_true()
	# In the last month before they march, word comes.
	var arm:Dictionary=Answer.state().arming[id]
	Answer._late_word(id,int(arm.march)-Standing.LATE_WORD_DAYS)
	assert_bool(Answer.heard_of_arming(id).is_empty()).is_false()

# ------------------------------------------------------- persuasion at work

func test_persuasion_wins_better_deals_and_heeded_words()->void:
	var id:=_met()
	var Deals:=preload("res://scripts/envoy_deals.gd")
	var Captives:=preload("res://scripts/captured_agents.gd")
	var audience:={"id":"test_deal","civ_id":id}
	_arts(0.5,0.1)
	var poor_temper:=Deals.temper(id,0.3)
	var poor_odds:=Deals.odds(audience,0.2)
	var poor_heeded:=Captives.message_odds(id,"peace")
	_arts(0.5,0.95)
	assert_float(Deals.temper(id,0.3)).is_greater(poor_temper)
	assert_float(Deals.odds(audience,0.2)).is_greater(poor_odds)
	assert_float(Captives.message_odds(id,"peace")).is_greater(poor_heeded)

func test_persuasion_holds_pacts_and_treaties_and_softens_grudges()->void:
	var Pacts:=preload("res://scripts/trade_pacts.gd")
	_arts(0.5,0.5)
	assert_int(Pacts.misses_borne()).is_equal(Pacts.MISSES_TO_LAPSE)
	_arts(0.5,1.0)
	assert_int(Pacts.misses_borne()).is_greater(Pacts.MISSES_TO_LAPSE)
	_arts(0.5,0.0)
	assert_int(Pacts.misses_borne()).is_less(Pacts.MISSES_TO_LAPSE)
	assert_float(Standing.treaty_floor("player","nobody")).is_greater(Standing.TREATY_BREAK)
	_arts(0.5,1.0)
	assert_float(Standing.treaty_floor("player","nobody")).is_less(Standing.TREATY_BREAK)
	# A new grudge against a persuasive people weighs less.
	var id:=_met()
	var Rivals:=preload("res://scripts/rival_rulers.gd")
	_arts(0.5,0.0)
	Rivals.grudge(id,"a test wrong",0.5,"test:hard")
	var hard:=Rivals.grudge_weight(id)
	_arts(0.5,1.0)
	Rivals.grudge(id,"another test wrong",0.5,"test:soft")
	assert_float(Rivals.grudge_weight(id)-hard).is_less(hard)

func test_persuasion_draws_families_and_every_effect_is_stated()->void:
	_arts(0.5,0.5)
	var plain:=Standing.attraction_shift()
	_arts(0.5,1.0)
	assert_float(Standing.attraction_shift()).is_greater(plain)
	var said:=Standing.arts_at_work()
	assert_int((said.cunning as Array).size()).is_greater_equal(5)
	assert_int((said.persuasion as Array).size()).is_greater_equal(6)
	var words:=PackedStringArray()
	for row:Dictionary in said.cunning+said.persuasion: words.append(String(row.words))
	var text:=" ".join(words)
	assert_str(text).contains("in 100")
	assert_str(text).contains("points")

func test_the_arts_are_fed_by_their_ledgers()->void:
	var id:=_met()
	var before:=float(Standing.strengths().cunning.value)
	# Spies of theirs caught lately and an agent of ours on watch among them.
	var covert:=preload("res://scripts/covert_ops.gd").state()
	(covert.caught as Array).push_front({"day":int(GameState.elapsed_days),"civ_id":id,"civ_name":"them","kind":"watch","fate":""})
	(covert.ops as Array).push_front({"civ_id":id,"civ_name":"them","kind":"watch","stage":"in_place","agent_name":"A","cover":"trader","start_day":int(GameState.elapsed_days)})
	var after:Dictionary=Standing.strengths().cunning
	assert_float(float(after.value)).is_greater(before)
	assert_str(String(after.why)).contains("one agent abroad")
	# An agent among them makes us surer of them.
	assert_float(Standing.certainty(id)).is_greater_equal(Standing.EYES_CERTAINTY-0.31)
	# A treaty in force counts for persuasion.
	var plain:=float(Standing.strengths().persuasion.value)
	CivilizationSystem.civilizations[0].player_relation.treaty="trade"
	assert_float(float(Standing.strengths().persuasion.value)).is_greater(plain)
