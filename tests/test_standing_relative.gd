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

## Their cunning, in their own month's reading (their own scope).
func _their_cunning(id:String,cunning:float)->void:
	WorldSimulation.scoped(id,func()->void:
		WorldSimulation.state.elapsed_days=GameState.elapsed_days
		WorldSimulation.state.simulation_metrics["standing_cunning"]=cunning
		WorldSimulation.state.simulation_metrics["standing_day"]=float(GameState.elapsed_days))

func test_cunning_against_cunning_is_one_rule_both_ways()->void:
	# The rule itself: the sender's edge is the keeper's loss, whoever is the god.
	for pair in [[0.9,0.5],[0.5,0.9],[0.2,0.7],[0.65,0.65]]:
		var a:=float(pair[0]); var b:=float(pair[1])
		assert_float(Standing.covert_edge(a,b)).is_equal_approx(-Standing.covert_edge(b,a),0.000001)
		assert_float(Standing.catch_edge(a,b)).is_equal_approx(-Standing.catch_edge(b,a),0.000001)
	assert_float(Standing.covert_edge(0.7,0.7)).is_equal(0.0)
	_actors()
	var id:=_met(0,0.5)
	var Covert:=preload("res://scripts/covert_ops.gd")
	var agent:={"tongue":0.5,"stealth":0.5,"nerve":0.5,"blade":0.5,"poison":0.5}
	_arts(0.5,0.5)
	_their_cunning(id,0.5)
	var even:=Covert.odds("plant",id,"","trader",agent)
	var even_catch:=Covert._catch_chance(id)
	_their_cunning(id,0.9)
	var sharp:=Covert.odds("plant",id,"","trader",agent)
	var sharp_catch:=Covert._catch_chance(id)
	# Their cunning counts against our agents: lower odds, more caught...
	assert_float(float(sharp.success)).is_less(float(even.success))
	assert_float(float(sharp.caught)).is_greater(float(even.caught))
	# ...and for their spies among us: fewer caught, by the same 12 points.
	assert_float(sharp_catch).is_less(even_catch)
	assert_float(float(sharp.caught)-float(even.caught)).is_equal_approx(even_catch-sharp_catch,0.0001)
	assert_float(float(sharp.caught)-float(even.caught)).is_equal_approx(0.4*Standing.CATCH_EDGE,0.0001)
	# The roles swapped (ours 0.9, theirs 0.5) give us exactly what they had.
	_arts(0.9,0.5)
	_their_cunning(id,0.5)
	var ours_sharp:=Covert.odds("plant",id,"","trader",agent)
	assert_float(float(even.caught)-float(ours_sharp.caught)).is_equal_approx(float(sharp.caught)-float(even.caught),0.0001)
	assert_float(Covert._catch_chance(id)-even_catch).is_equal_approx(even_catch-sharp_catch,0.0001)
	# A sender not named counts as typical.
	_arts(0.5,0.5)
	assert_float(Covert._catch_chance()).is_equal_approx(even_catch,0.0001)

func test_their_cunning_finds_doubles_and_turned_agents_by_the_same_rule()->void:
	_actors()
	var id:=_met(0,0.5)
	var Captives:=preload("res://scripts/captured_agents.gd")
	var prisoner:={"civ_id":id,"courage":0.5}
	_arts(0.5,0.5)
	_their_cunning(id,0.5)
	var plain:=float(Captives.double_odds(prisoner).found)
	_their_cunning(id,0.9)
	var watched:=float(Captives.double_odds(prisoner).found)
	assert_float(watched).is_greater(plain)
	assert_float(watched-plain).is_equal_approx(minf(0.3,plain+0.4*Standing.CATCH_EDGE)-plain,0.0001)
	_arts(0.9,0.5)
	assert_float(float(Captives.double_odds(prisoner).found)).is_equal_approx(plain,0.0001)

func test_the_spies_line_states_the_odds_between_us()->void:
	_actors()
	var id:=_met(0,0.95)
	_arts(0.5,0.5)
	_their_cunning(id,0.9)
	var line:=Standing.spies_words(id)
	assert_str(String(line.words)).contains("Spies between us")
	assert_str(String(line.words)).contains("points")
	assert_str(String(line.tone)).is_equal("danger")
	assert_str(String(line.detail)).contains("the same rule both ways")
	# The arts card names the most cunning people we know with the same numbers.
	var rows:Array=Standing.arts_at_work().cunning
	var words:=PackedStringArray()
	for row:Dictionary in rows: words.append(String(row.words))
	assert_str(" ".join(words)).contains("The most cunning people we know")
	assert_str(" ".join(words)).contains("typical cunning")
	# Hardly known: we say we cannot tell, never a false number.
	CivilizationSystem.civilizations[0].player_relation.contact_intelligence=0.0
	_arts(0.0,0.5)
	assert_str(String(Standing.spies_words(id).words)).contains("know too little")

# ------------------------------------------------ another people's month

func test_another_peoples_month_is_values_only_and_the_same_values()->void:
	_actors()
	var id:=String(CivilizationSystem.civilizations[0].id)
	var out:Dictionary=WorldSimulation.scoped(id,func()->Dictionary:
		WorldSimulation.state.elapsed_days=75*365
		var full:=Standing.strengths()
		var quiet:=Standing.values()
		Standing.record_monthly()
		return {"full":full,"quiet":quiet,"metrics":WorldSimulation.state.simulation_metrics.duplicate()})
	for row:Array in Standing.STRENGTHS:
		var sid:=String(row[0])
		assert_float(float(out.quiet[sid].value)).override_failure_message(sid).is_equal(float(out.full[sid].value))
		assert_str(String(out.quiet[sid].why)).is_empty()
		assert_str(String(out.full[sid].why)).is_not_empty()
		assert_float(float(out.metrics["standing_"+sid])).override_failure_message(sid).is_equal(float(out.full[sid].value))
	# The words come back for the god's own reading.
	assert_str(String(Standing.strengths().might.why)).is_not_empty()
	assert_float(float(out.metrics.standing_dangers)).is_equal(0.0)

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

func test_the_rose_lays_every_people_we_know_beside_ours()->void:
	_actors()
	var id:=_met(0,0.4)
	WorldSimulation.scoped(id,func()->void:
		WorldSimulation.state.elapsed_days=75*365
		Standing.record_monthly())
	var page=preload("res://scripts/hud/content/dock_content_standing.gd").new(null,null)
	var board=auto_free(preload("res://scripts/hud/standing_board.gd").new())
	add_child(board)
	board.size=Vector2(900,1600)
	board.setup(page.tab(0).blocks[0])
	var rose=board.find_child("Rose",true,false)
	assert_int((rose.others as Array).size()).is_equal(1)
	assert_bool(bool(rose.others[0].chosen)).is_false()
	# Chosen, it is drawn stronger with its band; the tooltip names it.
	var chip:Button=board.find_child("Compare_"+id,true,false)
	assert_bool(chip.disabled).is_false()
	chip.pressed.emit()
	assert_bool((rose.theirs as Dictionary).is_empty()).is_false()
	rose.size=Vector2(420,420)
	# (No frames are drawn here: this test world's CivilizationSystem would
	# catch up seventy-five years on the next frame.)
	var tip:String=rose._get_tooltip(rose.size*0.5+Vector2(0,-120))
	assert_str(tip).contains(String(CivilizationSystem.civilizations[0].name))
	assert_str(tip).contains("typical people of our age")

# ------------------------------------------------------ review of PR #139

func test_a_missed_arming_shows_nowhere_until_word_comes()->void:
	var id:=_met()
	var Answer:=preload("res://scripts/world_answer.gd")
	var Ledger:=preload("res://scripts/hud/war_ledger_model.gd")
	var Known:=preload("res://scripts/hud/peoples_known_model.gd")
	_arts(0.0,0.5)
	var day:=int(GameState.elapsed_days)
	for k in 60:
		Answer.state().arming.erase(id)
		Answer._begin_arming(id,day+k,{"why_all_in":"they resent us"})
		if not bool((Answer.state().arming[id] as Dictionary).get("heard",true)): break
	assert_bool(bool((Answer.state().arming[id] as Dictionary).get("heard",true))).is_false()
	var armed:=func()->bool:
		for e:Dictionary in Ledger.entries(day): if String(e.civ_id)==id and e.has("arming_days"): return true
		return false
	assert_bool(armed.call()).is_false()
	assert_str(String(Known.relation_cell({"civ_id":id}).get("text",""))).is_not_equal("Arming against us")
	(Answer.state().arming[id] as Dictionary)["heard"]=true
	assert_bool(armed.call()).is_true()
	assert_str(String(Known.relation_cell({"civ_id":id}).text)).is_equal("Arming against us")

func test_every_people_reads_its_month_however_many_days_a_step_covers()->void:
	var metrics:Dictionary=GameState.simulation_metrics
	metrics.erase("standing_day")
	assert_bool(Standing.reading_due()).is_true()
	# A computer people stepping three days at a time, from day 1.
	var readings:=0
	for step in range(1,301,3):
		GameState.elapsed_days=float(step)
		if Standing.reading_due():
			Standing.record_monthly()
			readings+=1
	assert_int(readings).is_equal(10)
	# A calendar set back reads again at once.
	GameState.elapsed_days=10.0
	assert_bool(Standing.reading_due()).is_true()
	# The engine asks it.
	assert_str(FileAccess.get_file_as_string("res://scripts/consequence_engine.gd")).contains("standing.gd\").reading_due()")

func test_the_reasons_beside_an_estimate_say_the_estimate()->void:
	_actors()
	var id:=_met(0,0.3)
	var ours:Array=[]
	for i in 600: ours.append("ours_%d" % i)
	GameState.known_discoveries.assign(ours)
	var theirs:Array=[]
	for i in 100: theirs.append("theirs_%d" % i)
	WorldSimulation.scoped(id,func()->void:
		WorldSimulation.state.elapsed_days=75*365
		WorldSimulation.state.known_discoveries.assign(theirs))
	_arts(0.5,0.5)
	var awe:=String((Standing.view_of(id).why as Dictionary).awe)
	assert_str(awe).contains("by our watchers' reckoning")
	assert_str(awe).not_contains("we know 500 things")
	# Their plenty, as an estimate; nothing at all when we cannot say.
	assert_str(Standing._plenty_words(id,0.8,0.4)).contains("against their about")
	CivilizationSystem.civilizations[0].player_relation.contact_intelligence=0.02
	_arts(0.0,0.5)
	assert_str(Standing._plenty_words(id,0.8,0.4)).is_equal(" (our plenty 80%)")
	assert_str(Standing._lead_words(id,600.0,100.0)).is_equal("")

func test_the_war_ledger_says_unknown_when_we_know_too_little()->void:
	var id:=_met(0,0.02)
	var Ledger:=preload("res://scripts/hud/war_ledger_model.gd")
	_arts(0.0,0.5)
	var e:=Ledger._common(id,{},{},int(GameState.elapsed_days))
	assert_bool(bool(e.strength_unknown)).is_true()
	assert_bool(bool(Ledger.odds(e).get("unknown",false))).is_true()
	assert_str(Ledger.odds_words(e)).starts_with("unknown")
	# Known a little: a real band, never "between X and X".
	CivilizationSystem.civilizations[0].player_relation.contact_intelligence=0.3
	_arts(0.5,0.5)
	var known:=Ledger._common(id,{},{},int(GameState.elapsed_days))
	assert_bool(bool(known.strength_unknown)).is_false()
	assert_float(float(known.strength_high)).is_greater(float(known.strength_low))

func test_the_arts_lines_read_plainly()->void:
	assert_str(Standing._signed_points(0.01)).is_equal("+1 point")
	assert_str(Standing._signed_points(-0.04)).is_equal("-4 points")
	assert_str(Standing._signed_points(0.01,"more","less")).is_equal("1 point more")
	assert_str(Standing._share_words(0.1,"more","less")).is_equal("a tenth more")
	assert_str(Standing._share_words(-0.05,"more","less")).is_equal("a twentieth less")
	_arts(0.5,1.0)
	var lines:=PackedStringArray()
	for row:Dictionary in Standing.arts_at_work().persuasion: lines.append(String(row.words)+" "+String(row.detail))
	var text:=" ".join(lines)
	assert_str(text).contains("pays a tenth more")
	assert_str(text).not_contains(" 1 points")
	assert_str(text).contains("Between any two peoples")
