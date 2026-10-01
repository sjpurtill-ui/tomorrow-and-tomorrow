extends GdUnitTestSuite
## COVERT OPERATIONS (scripts/covert_ops.gd): spies and assassins as a
## statistically consequential part of the one world. Each operation has
## stated odds and a seeded roll; outcomes are bounded and land on the same
## ledgers every system reads. The world is the court-eval base world
## (Seanstone, the Esurai, the Varesh), restored for each test.

const Covert:=preload("res://scripts/covert_ops.gd")
const Fixtures:=preload("res://tests/court_eval/fixtures.gd")
const War:=preload("res://scripts/war_loop.gd")
const CV:=preload("res://scripts/character_voice.gd")

var fx:Fixtures
var info:Dictionary


func before()->void:
	for key in ["OPENAI_API_KEY","LEVIATHAN_AI_API_KEY","LEVIATHAN_AI_ENDPOINT"]: OS.unset_environment(key)
	fx=Fixtures.new(self)


func before_test()->void:
	CV.knowledge_override.clear()
	info=fx.base(false)   # at peace with the Esurai; the Varesh known too
	Covert.forget()


func after()->void:
	CV.knowledge_override.clear()
	GameState.reset_for_new_world(74017)
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	WorldSimulation.clear()


func _civ_id()->String: return String(info.get("civ_id",""))
func _varesh()->String: return String(info.get("varesh_id",""))
func _tsaren()->String: return String(info.get("tsaren_id",""))


# --------------------------------------------------------------------------
# Odds are stated and bounded
# --------------------------------------------------------------------------

func test_every_operation_states_bounded_odds()->void:
	var agent:=Covert.volunteer()
	assert_str(String(agent.get("name",""))).is_not_empty()
	for kind in Covert.KINDS:
		var odds:=Covert.odds(kind,_civ_id(),_tsaren(),"none",agent)
		var success:=float(odds.get("success",-1.0))
		assert_bool(success>0.0 and success<=1.0).override_failure_message("%s success %f out of (0,1]" % [kind,success]).is_true()
		assert_int(int(odds.days)).is_greater(0)
	# An assassination names a kill cap, a trace chance and an escape chance.
	var strike:=Covert.odds("assassinate",_civ_id(),_tsaren(),"envoy",agent)
	assert_int(int(strike.kills_max)).is_equal(Covert.STRIKE_KILL_CAP)
	assert_bool(float(strike.trace)>0.0 and float(strike.trace)<=1.0).is_true()
	assert_bool(float(strike.escape)>0.0 and float(strike.escape)<1.0).is_true()


func test_envoy_cover_reaches_a_ruler_better_than_sneaking_in_at_peace()->void:
	var agent:=Covert.volunteer()
	var by_envoy:=Covert.cover_access("envoy","assassinate",_civ_id(),agent)
	var by_none:=Covert.cover_access("none","assassinate",_civ_id(),agent)
	assert_bool(by_envoy>by_none).override_failure_message("envoy %f should reach further than none %f at peace" % [by_envoy,by_none]).is_true()


func test_envoy_cover_is_refused_once_a_feud_is_hot()->void:
	var agent:=Covert.volunteer()
	var at_peace:=Covert.cover_access("envoy","assassinate",_varesh(),agent)
	War.blood_feud(_varesh(),int(GameState.elapsed_days),"a raid","")
	var in_feud:=Covert.cover_access("envoy","assassinate",_varesh(),agent)
	assert_bool(in_feud<at_peace).override_failure_message("a hot feud should refuse our envoy: %f vs %f" % [in_feud,at_peace]).is_true()


# --------------------------------------------------------------------------
# Watch sharpens what we know
# --------------------------------------------------------------------------

func test_a_watch_report_sharpens_our_estimates_and_brings_a_fact()->void:
	var agent:=Covert.volunteer()
	var op:=Covert.launch("watch",_civ_id(),_tsaren(),"trader",agent)
	assert_bool(op.has("error")).override_failure_message(String(op.get("error",""))).is_false()
	(op.odds as Dictionary)["caught"]=0.0   # this watcher is not caught
	var chart:Variant=CivilizationSystem.city_intelligence
	var before:=float(chart.known("player",_tsaren()).get("quality",0.0))
	Covert._arrive(op,int(op.arrive_day))
	assert_str(String(op.stage)).is_equal("in_place")
	Covert._watch_report(op,int(op.report_day))
	var after:=float(chart.known("player",_tsaren()).get("quality",0.0))
	assert_bool(after>=before).override_failure_message("quality %f should not fall below %f" % [after,before]).is_true()
	assert_bool(after>=0.65).override_failure_message("an eye in the town sharpens it to at least 0.65, got %f" % after).is_true()
	assert_array(Covert.learned(5)).is_not_empty()
	assert_str(String(op.stage)).is_equal("done")


func test_eyes_on_reports_to_the_war_screen()->void:
	var agent:=Covert.volunteer()
	var op:=Covert.launch("watch",_civ_id(),_tsaren(),"trader",agent)
	Covert._arrive(op,int(op.arrive_day))   # now in place
	var eyes:=Covert.eyes_on(_civ_id())
	assert_int(int(eyes.count)).is_greater(0)


# --------------------------------------------------------------------------
# The assassination: success, fate, trace, and the consequences
# --------------------------------------------------------------------------

func test_envoy_assassination_that_is_traced_brings_a_feud_and_breaks_envoy_sanctity()->void:
	var target:=_varesh()
	var agent:=Covert.volunteer()
	var op:=Covert.launch("assassinate",target,"","envoy",agent,"as many of their leaders as he can")
	assert_bool(op.has("error")).is_false()
	op["stage"]="struck"
	(op.odds as Dictionary)["success"]=1.0
	(op.odds as Dictionary)["escape"]=0.0
	(op.odds as Dictionary)["trace"]=1.0
	var before_opinion:=float((CivilizationSystem.civilizations[1] as Dictionary).player_relation.get("opinion",0.0))
	Covert._resolve(op,int(GameState.elapsed_days))
	var outcome:Dictionary=op.outcome
	assert_str(String(outcome.kind)).is_equal("struck")
	assert_int(int(outcome.killed)).is_between(1,Covert.STRIKE_KILL_CAP)
	assert_bool(bool(outcome.traced)).is_true()
	# Traced: a blood feud with them (they are a small people).
	assert_bool(War.feuding(target)).override_failure_message("a traced murder should start a feud").is_true()
	# Envoy sanctity broken: our envoys are refused for a time, and every
	# people we know trusts them less.
	assert_bool(Covert.envoys_barred()).override_failure_message("an envoy-cover killing should bar our envoys").is_true()
	assert_int(Covert.sanctity_days_left()).is_greater(0)
	var after_opinion:=float((CivilizationSystem.civilizations[1] as Dictionary).player_relation.get("opinion",0.0))
	assert_bool(after_opinion<=before_opinion).override_failure_message("their trust in us should not rise after this").is_true()
	# The agent's fate is recorded; the outcome is credited once.
	assert_bool(bool(op.credited)).is_true()


func test_a_dead_ruler_brings_a_successor()->void:
	var target:=_civ_id()   # the Esurai: a people we know well enough to name their ruler
	var before:=String(ForeignDiplomacy.leader(target).get("name",""))
	assert_str(before).override_failure_message("the Esurai should have a named ruler").is_not_empty()
	var agent:=Covert.volunteer()
	var op:=Covert.launch("assassinate",target,"","none",agent,"their chief")
	# Decide the kill with their ruler among the dead, then run the real death.
	Covert._kill_leaders(target,1,true,op,int(GameState.elapsed_days))
	var after:=String(ForeignDiplomacy.leader(target).get("name",""))
	assert_str(after).override_failure_message("the heir should take a new name after the chief falls").is_not_equal(before)


func test_a_failed_strike_changes_nobody_and_starts_no_feud()->void:
	var target:=_varesh()
	var agent:=Covert.volunteer()
	var op:=Covert.launch("assassinate",target,"","none",agent,"their chief")
	op["stage"]="struck"
	(op.odds as Dictionary)["success"]=0.0
	(op.odds as Dictionary)["escape"]=1.0
	(op.odds as Dictionary)["trace"]=0.0
	Covert._resolve(op,int(GameState.elapsed_days))
	assert_str(String((op.outcome as Dictionary).kind)).is_equal("failed")
	assert_bool(War.feuding(target)).override_failure_message("a clean miss, not traced, starts no feud").is_false()


# --------------------------------------------------------------------------
# A caught agent who talks
# --------------------------------------------------------------------------

func test_a_caught_agent_who_talks_brings_a_feud()->void:
	var target:=_varesh()
	var talked:=false
	# A fearless nerve rarely breaks; a timid one often does. Over a season of
	# tries one caught agent breaks and names us, and the feud follows.
	for day in range(1,60):
		Covert.forget()
		var agent:=Covert.volunteer()
		agent["nerve"]=0.0   # a timid hand breaks under their questioning
		var op:=Covert.launch("watch",target,"","trader",agent)
		Covert._agent_caught_ours(op,day,"watching")
		if bool((op.outcome as Dictionary).get("talks",false)):
			talked=true
			assert_bool(War.feuding(target)).override_failure_message("a talking caught agent should bring a feud").is_true()
			assert_str(String(Covert.stored_agent(String(op.agent)).get("fate",""))).is_equal("caught")
			break
	assert_bool(talked).override_failure_message("a timid caught agent should break within a season of tries").is_true()


# --------------------------------------------------------------------------
# A secret stolen; sabotage applied
# --------------------------------------------------------------------------

func test_a_stolen_secret_moves_our_learning_forward()->void:
	var target:=_varesh()
	# A settled people can be robbed of a craft (era gate: tier 1).
	CV.knowledge_override["player"]=["clay_shaping"]
	# They hold a way our people lack.
	var secret:="seed_selection"
	GameState.known_discoveries.erase(secret)
	GameState.discovery_progress.erase(secret)
	var index:=1
	(CivilizationSystem.civilizations[index] as Dictionary)["discovery_profile"]={"technologies":[secret]}
	var agent:=Covert.volunteer()
	var op:=Covert.launch("steal",target,"","trader",agent)
	op["stage"]="struck"
	(op.odds as Dictionary)["success"]=1.0
	(op.odds as Dictionary)["caught"]=0.0
	Covert._resolve(op,int(GameState.elapsed_days))
	assert_str(String((op.outcome as Dictionary).kind)).is_equal("stole")
	assert_bool(float(GameState.discovery_progress.get(secret,0.0))>0.0).override_failure_message("the stolen secret should move our learning forward").is_true()


func test_sabotage_is_applied_to_their_ledger()->void:
	var target:=_varesh()
	var index:=1
	(CivilizationSystem.civilizations[index] as Dictionary)["food_days"]=40.0
	var agent:=Covert.volunteer()
	var op:=Covert.launch("sabotage",target,"","pilgrim",agent)
	op["stage"]="struck"
	(op.odds as Dictionary)["success"]=1.0
	(op.odds as Dictionary)["caught"]=0.0
	Covert._resolve(op,int(GameState.elapsed_days))
	assert_str(String((op.outcome as Dictionary).kind)).is_equal("sabotaged")
	assert_bool(float((CivilizationSystem.civilizations[index] as Dictionary).get("food_days",40.0))<40.0).override_failure_message("sabotage should cost them real food or days").is_true()


# --------------------------------------------------------------------------
# Rivals run the same rules; our watch catches some
# --------------------------------------------------------------------------

func test_our_watch_can_catch_a_slipped_in_spy()->void:
	# One of theirs arrives; with our watch strong, it is taken.
	GameState.population_allocations["Defense"]=200
	GameState.simulation_metrics["cohesion"]=0.8
	var s:=Covert.state()
	(s.incoming as Array).append({"civ_id":_varesh(),"civ_name":Hall_name(_varesh()),"kind":"watch","start_day":1,"arrive_day":int(GameState.elapsed_days),"seed":"rivaltest:1"})
	Covert._catch_incoming(int(GameState.elapsed_days))
	# Either caught (listed) or slipped past; with a strong watch it is caught.
	assert_array(Covert.caught_spies(4)).is_not_empty()


func Hall_name(civ_id:String)->String:
	return String((CivilizationSystem.civilizations[1] as Dictionary).get("name",civ_id))


func test_rivals_covert_acts_are_rare_over_years_no_spam()->void:
	# A feud with the Varesh raises their scheming, but over five years it must
	# stay rare: a handful at most, never a flood.
	War.blood_feud(_varesh(),int(GameState.elapsed_days),"a raid","")
	var start:=int(GameState.elapsed_days)
	for day in range(start,start+5*365):
		GameState.elapsed_days=day
		Covert.daily(day)
	var sent:=int((Covert.state().stats as Dictionary).get("rival_sent",0))
	assert_int(sent).override_failure_message("rivals sent %d covert acts in five years: too many" % sent).is_less_equal(30)
	# Nothing piled up unresolved.
	assert_int((Covert.state().incoming as Array).size()).is_less_equal(Covert.INCOMING_MAX)


# --------------------------------------------------------------------------
# Era gating
# --------------------------------------------------------------------------

func test_early_peoples_have_only_plain_methods()->void:
	CV.knowledge_override["player"]=[]   # the old stone world
	var m:=Covert.methods("player")
	assert_bool(bool(m.watch)).is_true()
	assert_bool(bool(m.sabotage)).is_true()
	assert_bool(bool(m.assassinate)).is_true()
	assert_bool(bool(m.plant)).is_false()
	assert_bool(bool(m.steal)).is_false()
	assert_bool(bool(m.networks)).is_false()


func test_a_writing_people_gains_networks()->void:
	CV.knowledge_override["player"]=["phonetic_notation","copper_smelting","seed_selection"]
	var m:=Covert.methods("player")
	assert_bool(bool(m.plant)).is_true()
	assert_bool(bool(m.steal)).is_true()
	assert_bool(bool(m.networks)).is_true()


# --------------------------------------------------------------------------
# Save round trip
# --------------------------------------------------------------------------

func test_the_covert_ledger_saves_and_loads()->void:
	var agent:=Covert.volunteer()
	Covert.launch("watch",_civ_id(),_tsaren(),"trader",agent)
	Covert.launch("assassinate",_varesh(),"","envoy",Covert.volunteer(),"their chief")
	assert_bool(Covert.valid_state(Covert.state())).is_true()
	# Through the court's own save validator.
	assert_bool(preload("res://scripts/audience_hall.gd").validate_state(ForeignDiplomacy.audiences)).is_true()
	# A real export/import round trip of the diplomacy payload that carries it.
	var payload:=ForeignDiplomacy.export_state()
	ForeignDiplomacy.import_state(payload)
	assert_int((Covert.state().ops as Array).size()).is_equal(2)
	assert_bool(Covert.valid_state(Covert.state())).is_true()
