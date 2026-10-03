extends GdUnitTestSuite
## CAPTURED AGENTS, THE RULES THAT KEEP THE LEDGER TRUE (review of PR #133):
## one count for the won over, each course its own roll, stated odds rolled,
## pretenders indistinguishable, deaths abroad quiet and true, parity abroad,
## orders that name others, favour limits and hunger. Split from
## test_captured_agents.gd so each run stays under two minutes.
## CAPTURED AGENTS (scripts/captured_agents.gd): a spy or assassin our watch
## takes is a person held under guard; questioned before the god at stated
## odds with seeded rolls, answering from their fact sheet only; and given a
## fate (death, home with a message, care and teaching, or kept) whose
## effects land on the one ledger. Our own agents taken abroad are judged by
## that ruler on the same rules. The world is the court-eval base world
## (Seanstone, the Esurai, the Varesh), restored for each test. Offline; never
## calls a real API.

const Captives:=preload("res://scripts/captured_agents.gd")
const Covert:=preload("res://scripts/covert_ops.gd")
const Fixtures:=preload("res://tests/court_eval/fixtures.gd")
const Harness:=preload("res://tests/court_eval/harness.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const War:=preload("res://scripts/war_loop.gd")
const Rivals:=preload("res://scripts/rival_rulers.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const Roster:=preload("res://scripts/hud/court_roster.gd")
const CV:=preload("res://scripts/character_voice.gd")

var fx:Fixtures
var info:Dictionary


func before()->void:
	for key in ["OPENAI_API_KEY","LEVIATHAN_AI_API_KEY","LEVIATHAN_AI_ENDPOINT","LEVIATHAN_AI_MODEL","LEVIATHAN_AI_READER_MODEL"]: OS.unset_environment(key)
	fx=Fixtures.new(self)


func before_test()->void:
	CV.knowledge_override.clear()
	info=fx.base(false)   # at peace with the Esurai; the Varesh known too
	# The Varesh are met: rivals scheme only against peoples in contact.
	((CivilizationSystem.civilizations[1] as Dictionary).player_relation as Dictionary)["contact_level"]=2
	Covert.forget()
	Captives.forget()


func after()->void:
	CV.knowledge_override.clear()
	GameState.reset_for_new_world(74017)
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	WorldSimulation.clear()


func _varesh()->String: return String(info.get("varesh_id",""))
func _day()->int: return int(GameState.elapsed_days)


## One of theirs arrives and our strong watch takes them: the real path.
func _catch(kind:String="assassinate",civ_id:String="")->Dictionary:
	if civ_id=="": civ_id=_varesh()
	GameState.population_allocations["Defense"]=400
	GameState.simulation_metrics["cohesion"]=0.9
	var s:=Covert.state()
	for i in 12:
		(s.incoming as Array).append({"civ_id":civ_id,"civ_name":Hall._civ_name(civ_id),"kind":kind,"start_day":_day()-10,"arrive_day":_day(),"seed":"pt:%s:%d" % [kind,i]})
		Covert._catch_incoming(_day())
		if not (s.caught as Array).is_empty(): break
	assert_bool((s.caught as Array).is_empty()).override_failure_message("our strong watch should take one of theirs").is_false()
	var pid:=String(((s.caught as Array)[0] as Dictionary).get("prisoner_id",""))
	var p:=Captives.by_id(pid)
	assert_bool(p.is_empty()).override_failure_message("a caught agent should be a person held").is_false()
	return p


## A held prisoner brought before the god.
func _before_god(p:Dictionary)->String:
	var a:=Hall.summon({"prisoner_id":String(p.id)})
	assert_bool(a.is_empty()).override_failure_message("the prisoner should be brought in").is_false()
	return String(a.id)


# --------------------------------------------------------------------------
# Review fixes (PR #133)
# --------------------------------------------------------------------------

## A prisoner won over to us through a course whose end is forced.
func _won_over(feigned:bool=false)->Dictionary:
	var p:=_catch("watch")
	var id:=_before_god(p)
	Hall.resolve(id,"pr_turn")
	var rec:=Captives.by_id(String(p.id))
	rec["turn_odds"]={"converted":0.0 if feigned else 1.0,"feigned":1.0 if feigned else 0.0,"unmoved":0.0,"days":28,"food_day":2.0}
	GameState.elapsed_days=int(rec.turn_end)
	Captives.daily(_day())
	assert_str(String(rec.status)).is_equal("joined")
	return rec


func _cell(cohort:String,sex:String)->float:
	GameState.ensure_female_cohorts()
	var all:=float(GameState.population_cohorts.get(cohort,0.0))
	var women:=float(GameState.population_cohorts.get(GameState.FEMALE_PREFIX+cohort,0.0))
	return women if sex=="female" else all-women


func test_one_won_over_leaves_our_count_as_who_they_are_when_struck_down()->void:
	var rec:=_won_over()
	var cohort:=Captives._cohort_of(Captives.age_now(rec))
	assert_str(String(rec.counted.cohort)).is_equal(cohort)
	var pop:=float(GameState.population_exact)
	var cell:=_cell(cohort,String(rec.sex))
	var id:=_before_god(rec)
	var r:=Hall.divine(id,"strike_down")
	assert_bool(bool(r.ok)).is_true()
	assert_str(String(rec.status)).is_equal("executed")
	assert_float(float(GameState.population_exact)).is_equal_approx(pop-1.0,0.01)
	assert_float(_cell(cohort,String(rec.sex))).is_equal_approx(cell-1.0,0.01)


func test_one_won_over_sent_home_departs_our_count()->void:
	var rec:=_won_over()
	var pop:=float(GameState.population_exact)
	var cohort:=Captives._cohort_of(Captives.age_now(rec))
	var cell:=_cell(cohort,String(rec.sex))
	var id:=_before_god(rec)
	var heard:=Captives.hear(id,"Send him home and tell your chief we want peace")
	Hall.resolve(id,String(heard.option))
	assert_str(String(rec.status)).is_equal("sent_home")
	assert_float(float(GameState.population_exact)).is_equal_approx(pop-1.0,0.01)
	assert_float(_cell(cohort,String(rec.sex))).is_equal_approx(cell-1.0,0.01)


func test_the_age_and_sex_ledger_holds_through_joining_and_leaving()->void:
	var p:=_catch("watch")
	var cohort:=Captives._cohort_of(Captives.age_now(p))
	var cell:=_cell(cohort,String(p.sex))
	var id:=_before_god(p)
	Hall.resolve(id,"pr_turn")
	var rec:=Captives.by_id(String(p.id))
	rec["turn_odds"]={"converted":1.0,"feigned":0.0,"unmoved":0.0,"days":28,"food_day":2.0}
	GameState.elapsed_days=int(rec.turn_end)
	Captives.daily(_day())
	cohort=Captives._cohort_of(Captives.age_now(rec))
	assert_float(_cell(cohort,String(rec.sex))).is_equal_approx(cell+1.0,0.01)
	var id2:=_before_god(rec)
	Hall.resolve(id2,"pr_double")
	assert_float(_cell(cohort,String(rec.sex))).is_equal_approx(cell,0.01)


func test_each_course_of_care_rolls_anew()->void:
	var p:=_catch("watch")
	var id:=_before_god(p)
	Hall.resolve(id,"pr_turn")
	var rec:=Captives.by_id(String(p.id))
	var first:=Captives.turn_key(rec)
	rec["turn_odds"]={"converted":0.0,"feigned":0.0,"unmoved":1.0,"days":28,"food_day":2.0}
	GameState.elapsed_days=int(rec.turn_end)
	Captives.daily(_day())
	assert_str(String(rec.status)).is_equal("held")
	var id2:=_before_god(rec)
	Hall.resolve(id2,"pr_turn")
	assert_int(int(rec.course)).is_equal(2)
	assert_bool(Captives.turn_key(rec)!=first).is_true()


func test_a_pretender_tells_everything_too_and_shows_the_same_odds_of_being_found()->void:
	var rec:=_won_over(true)
	assert_bool(bool(rec.feigned)).is_true()
	for topic in Captives.TOPICS:
		var last:=Captives._last_said(rec,topic)
		assert_bool(bool(last.talked)).override_failure_message(topic).is_true()
		assert_bool(bool(last.lied)).override_failure_message(topic).is_true()
		assert_str(String(last.text)).is_equal(String(Captives.fact(rec,topic).lie))
	# On the screen they read as a true convert's would: nothing shown false.
	var id:=_before_god(rec)
	assert_bool(Captives.dossier_rows(id).any(func(row:Array)->bool: return String(row[2])=="false")).is_false()
	assert_int(Captives.said_rows(rec).size()).is_equal(Captives.TOPICS.size())
	# Sent back as our eyes: the same stated odds of being found, never rolled.
	Hall.resolve(id,"pr_double")
	var op:=Covert.op_by_id(int(rec.fate.op_id))
	assert_float(float(op.odds.caught)).is_equal(float(Captives.double_odds(rec).found))
	(op.odds as Dictionary)["caught"]=1.0
	op["stage"]="in_place"
	Covert._plant_report(op,_day()+90)
	assert_str(String(op.stage)).is_equal("in_place")
	# Their own false report shows none of their words false.
	Captives.refresh_contradictions()
	assert_bool(bool(Captives._last_said(rec,"strength").found_false)).is_false()
	# A true double agent on the same certain odds is found.
	var real:=_won_over()
	var id2:=_before_god(real)
	Hall.resolve(id2,"pr_double")
	var op2:=Covert.op_by_id(int(real.fate.op_id))
	(op2.odds as Dictionary)["caught"]=1.0
	op2["stage"]="in_place"
	Covert._plant_report(op2,_day()+90)
	assert_str(String(op2.stage)).is_equal("done")


func test_our_official_killed_abroad_dies_of_their_hand_not_ours()->void:
	var civ:=_varesh()
	var official:Dictionary={}
	for person in Hall._officials():
		if String(person.get("office_key",""))!="" and String(person.get("office_key",""))!="settlement": official=person; break
	assert_bool(official.is_empty()).is_false()
	var agent:=Covert.agent_from_person(official)
	var op:=Covert.launch("watch",civ,"","trader",agent)
	var metrics:Dictionary=GameState.simulation_metrics
	var legitimacy:=float(metrics.get("legitimacy",0.5)); var cohesion:=float(metrics.get("cohesion",0.5))
	var pop:=float(GameState.population_exact)
	Captives._our_agent_dies(op,agent,civ)
	var after:=GovernmentPeopleSystem.person_snapshot(int(official.person_id))
	assert_str(String(after.get("status",""))).is_equal("deceased")
	assert_str(String(after.get("removal_reason",""))).is_equal("died_abroad")
	assert_float(float(metrics.get("legitimacy",0.5))).is_equal(legitimacy)
	assert_float(float(metrics.get("cohesion",0.5))).is_equal(cohesion)
	assert_float(float(GameState.population_exact)).is_equal_approx(pop-1.0,0.01)


func test_ours_held_abroad_may_slip_their_guards_each_month()->void:
	var civ:=_varesh()
	var rec:={"op_id":991,"civ_id":civ,"agent":"t","name":"Kael Tor","given":"Kael","kind":"watch","day":_day(),"odds":{},"roll":0.5,"choice":"keep","status":"held_abroad","doing":"watching","loyalty":0.6,"nerve":0.95}
	(Captives.state().abroad as Array).push_front(rec)
	var odds:=Captives.abroad_escape_odds(rec)
	assert_bool(odds>=0.01 and odds<=0.15).is_true()
	var start:=_day()
	for d in range(start+1,start+30*48+1):
		GameState.elapsed_days=d
		Captives._abroad_daily(rec,d)
		if String(rec.status)!="held_abroad": break
	assert_str(String(rec.status)).override_failure_message("four years of monthly chances at %f should free them" % odds).is_equal("home")
	assert_bool(float(rec.escape.roll)<float(rec.escape.odds)).is_true()
	# A foreign ruler works on ours with the same turn odds we use on theirs.
	var t:=Captives.turn_odds(Captives.held_view(rec),civ)
	assert_float(float(t.converted)+float(t.feigned)+float(t.unmoved)).is_equal_approx(1.0,0.001)


func test_words_about_others_never_kill_the_one_before_the_god()->void:
	assert_dict(Captives.read("Find the others and kill them")).is_empty()
	assert_dict(Captives.read("Hunt down his people and kill them all")).is_empty()
	var p:=_catch("watch")
	var id:=_before_god(p)
	Captives.hear(id,"Find the others and kill them")
	assert_str(String(Captives.by_id(String(p.id)).status)).is_equal("held")


func test_favour_counts_again_only_after_a_month_however_often_they_are_summoned()->void:
	var p:=_catch("watch")
	var id:=_before_god(p)
	assert_bool(bool(Hall.divine(id,"bless").ok)).is_true()
	Hall.resolve(id,"pr_keep")
	var id2:=_before_god(p)
	var bless:Dictionary=Hall.divine_options(id2).filter(func(o:Dictionary)->bool: return String(o.id)=="bless")[0]
	assert_bool(bool(bless.enabled)).is_false()
	assert_bool(bool(Hall.divine(id2,"bless").ok)).is_false()
	Hall.resolve(id2,"pr_keep")
	GameState.elapsed_days+=Captives.FAVOUR_DAYS
	var id3:=_before_god(p)
	assert_bool(bool(Hall.divine(id3,"bless").ok)).is_true()
	# Gentle questions warm them once a day, however many are asked.
	var love:=float(p.love)
	Captives.ask(id3,"sender","gentle"); Captives.ask(id3,"plans","gentle"); Captives.ask(id3,"others","gentle")
	assert_float(float(p.love)).is_equal_approx(love+0.03,0.001)


func test_unfed_prisoners_suffer_and_an_unpaid_course_waits()->void:
	var p:=_catch("watch")
	var id:=_before_god(p)
	Hall.resolve(id,"pr_turn")
	var rec:=Captives.by_id(String(p.id))
	var end:=int(rec.turn_end)
	var escape:=Captives.escape_odds(rec)
	var kind:=float(rec.treatment)
	# Empty stores.
	Hall.EXCHANGE.take("player","Food",Hall.player_stock("Food"))
	for i in 5:
		GameState.elapsed_days+=1
		Captives.daily(_day())
	assert_int(int(rec.turn_end)).is_equal(end+5)
	assert_int(int(rec.hungry_days)).is_equal(5)
	assert_bool(float(rec.treatment)<kind).is_true()
	assert_bool(Captives.escape_odds(rec)>escape).is_true()



# --------------------------------------------------------------------------
# Second review (PR #133)
# --------------------------------------------------------------------------

func test_orders_naming_others_still_fall_on_the_one_before_the_god()->void:
	for line in ["Kill him as a warning to the others","Hang her in front of her people","Put him to death before his men",
			"Execute him so whoever sent him knows","Behead him and send his head to their chief","Kill him and his family",
			"Kill him. Then find the rest.","Kill him, and let the others watch"]:
		assert_str(String(Captives.read(line).get("option",""))).override_failure_message(line).is_equal("pr_execute")
	for line in ["Lock him up until we catch the others","Keep her under guard while we hunt her friends"]:
		assert_str(String(Captives.read(line).get("option",""))).override_failure_message(line).is_equal("pr_keep")
	# Words about the others alone never touch the prisoner.
	assert_dict(Captives.read("Find the others and kill them")).is_empty()
	assert_dict(Captives.read("Hunt down his people and kill them all")).is_empty()
	# Through the prisoner's own audience, by name, and a flogging in front of his men.
	var p:=_catch("watch")
	var id:=_before_god(p)
	assert_str(String(Captives.hear(id,"Flog %s in front of his men" % String(p.given)).get("divine",""))).is_equal("terrify")
	var heard:=Captives.hear(id,"Kill %s as a warning to the others" % String(p.name))
	assert_str(String(heard.get("option",""))).is_equal("pr_execute")


func test_a_town_leader_killed_abroad_dies_quietly_and_truthfully()->void:
	var civ:=_varesh()
	var leader:={}
	for settlement in GameState.player_settlements:
		var person:=GovernmentPeopleSystem.settlement_leader(String((settlement as Dictionary).get("id","")))
		if not person.is_empty(): leader=person; break
	assert_bool(leader.is_empty()).override_failure_message("the base world should have a town leader").is_false()
	var pid:=int(leader.person_id)
	var town:=String(GovernmentPeopleSystem.person_snapshot(pid).get("local_leader_of",""))
	var metrics:Dictionary=GameState.simulation_metrics
	var legitimacy:=float(metrics.get("legitimacy",0.5)); var cohesion:=float(metrics.get("cohesion",0.5))
	var events_before:=GameState.simulation_events.size()
	var pop:=float(GameState.population_exact)
	var agent:=Covert.agent_from_person(GovernmentPeopleSystem.person_snapshot(pid))
	var op:=Covert.launch("watch",civ,"","trader",agent)
	Captives._our_agent_dies(op,agent,civ)
	var after:=GovernmentPeopleSystem.person_snapshot(pid)
	assert_str(String(after.get("status",""))).is_equal("deceased")
	assert_str(String(after.get("removal_reason",""))).is_equal("died_abroad")
	assert_float(float(metrics.get("legitimacy",0.5))).is_equal(legitimacy)
	assert_float(float(metrics.get("cohesion",0.5))).is_equal(cohesion)
	assert_float(float(GameState.population_exact)).is_equal_approx(pop-1.0,0.01)
	# One truthful event, and no dismissal or execution told.
	var told:=GameState.simulation_events.slice(0,GameState.simulation_events.size()-events_before)
	assert_bool(told.any(func(e:Dictionary)->bool: return String(e.get("title",""))=="Died Abroad")).is_true()
	for e in told: assert_bool(String((e as Dictionary).get("title","")) in ["Leader Dismissed","Officeholder Dismissed","Leader Executed","Officeholder Executed"]).override_failure_message(String((e as Dictionary).get("title",""))).is_false()
	# The dead are never named to an office again; the town has another leader or none.
	var now:=GovernmentPeopleSystem.settlement_leader(town)
	assert_bool(now.is_empty() or int(now.get("person_id",0))!=pid).is_true()
	for key in GameState.leadership_positions: assert_int(int((GameState.leadership_positions[key] as Dictionary).get("person_id",0))).is_not_equal(pid)
