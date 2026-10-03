extends GdUnitTestSuite
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
# A caught agent is a person, and nothing opens unbidden
# --------------------------------------------------------------------------

func test_a_caught_assassin_is_a_person_held_under_guard()->void:
	var waiting_before:=Hall.waiting().size()
	var p:=_catch()
	assert_str(String(p.status)).is_equal("held")
	assert_str(String(p.name)).is_not_empty()
	assert_str(String((p.look as Dictionary).get("skin",""))).is_not_empty()
	assert_bool(float(p.loyalty)>0.0 and float(p.loyalty)<1.0).is_true()
	var topics:Array=(p.facts as Array).map(func(f:Dictionary)->String: return String(f.topic))
	for topic in Captives.TOPICS: assert_bool(topic in topics).override_failure_message("missing fact "+topic).is_true()
	# Told, with a plain button; nothing opens on its own.
	assert_int(Hall.waiting().size()).is_equal(waiting_before)
	var told:Dictionary=Chronicle.entries("notice",1)[0]
	assert_str(String((told.action as Dictionary).get("kind",""))).is_equal("prisoner")
	assert_str(String((told.action as Dictionary).get("prisoner_id",""))).is_equal(String(p.id))
	var text:=String(told.text)
	assert_bool(text.contains("'s in")).override_failure_message("grammar: "+text).is_false()
	assert_bool(text.contains("an assassin of the ")).override_failure_message(text).is_true()
	assert_bool(text.contains(String(p.name))).is_true()
	# The court's list of those it may send for holds them.
	var listed:=Roster.people().filter(func(e:Dictionary)->bool: return String(e.group)=="prisoners")
	assert_int(listed.size()).is_equal(1)
	assert_str(String((listed[0].target as Dictionary).get("prisoner_id",""))).is_equal(String(p.id))
	# Brought in: a summons audience of their own, bound, with guards.
	var id:=_before_god(p)
	assert_bool(Captives.is_prisoner_audience(id)).is_true()
	var view:=Captives.stage_view(id)
	assert_bool(bool(view.bound)).is_true()
	assert_int(int(view.guards)).is_equal(3)
	# The caught list still works, with their name and state.
	var caught:=Covert.caught_spies(4)
	assert_str(String(caught[0].name)).is_equal(String(p.name))
	assert_str(String(caught[0].fate)).is_equal("held under guard")


func test_facts_come_from_the_ledger()->void:
	var civ:=_varesh()
	# Their raiders are set to come at us in 25 days, over an old wrong.
	(War.front(civ) as Dictionary)["pending"]={"day":_day()+25,"cause":"the killing at the ford","ref":"t","stack":1}
	var p:=_catch("assassinate",civ)
	var strength:=Captives.fact(p,"strength")
	assert_int(int(strength.value)).is_equal(int(War._their_fighters(civ)))
	var sender:=Captives.fact(p,"sender")
	assert_bool(String(sender.text).contains(String(Rivals.ruler_name(civ)))).override_failure_message(String(sender.text)).is_true()
	var plans:=Captives.fact(p,"plans")
	assert_str(String(plans.value)).is_equal("hostile")
	# Each fact carries one coherent falsehood beside it.
	for f in p.facts:
		assert_str(String((f as Dictionary).lie)).is_not_empty()
		assert_bool(String((f as Dictionary).lie)!=String((f as Dictionary).text)).is_true()
	assert_str(String(Captives.fact(p,"plans").lie_value)).is_equal("peace")


# --------------------------------------------------------------------------
# Questioning: the fact sheet only; stated odds are the rolled odds; seeds
# --------------------------------------------------------------------------

func test_answers_come_only_from_the_fact_sheet()->void:
	var p:=_catch()
	var id:=_before_god(p)
	for pass_n in 3:
		for manner in Captives.MANNERS:
			for topic in Captives.TOPICS:
				var r:=Captives.ask(id,topic,manner)
				assert_bool(bool(r.ok)).is_true()
				# What they said is what the hall heard from them, at once.
				var heard:=""
				for line in Hall.find(id).get("lines",[]):
					if String((line as Dictionary).get("speaker",""))==String(p.name): heard=String((line as Dictionary).text)
				if bool(r.talked): assert_bool(heard.ends_with(String(r.said.text))).override_failure_message("said in the hall: "+heard).is_true()
	var f_text:={}
	for f in p.facts: f_text[String((f as Dictionary).topic)]=[String((f as Dictionary).text),String((f as Dictionary).lie)]
	var answered:=0
	for e in p.said:
		var s:Dictionary=e
		if not bool(s.talked):
			assert_str(String(s.text)).is_empty()
			continue
		answered+=1
		var pair:Array=f_text[String(s.topic)]
		if bool(s.lied): assert_str(String(s.text)).is_equal(String(pair[1]))
		else: assert_str(String(s.text)).is_equal(String(pair[0]))
		assert_bool(String(s.text).contains("their ruler")).is_false()
	assert_int(answered).is_greater(0)


func test_stated_odds_are_the_rolled_odds_and_the_seed_repeats()->void:
	var p:=_catch("watch")
	var id:=_before_god(p)
	# The menu states them.
	var menu:=Captives.choices(id)
	var stated:Dictionary={}
	for c in menu:
		if String(c.params.topic)=="strength" and String(c.params.manner)=="terror": stated=c.odds
	assert_bool(stated.is_empty()).is_false()
	# The same record decides the same rolls, however often it is read.
	var copy:=p.duplicate(true)
	var d1:=Captives.decide_question(p,"strength","terror")
	var d2:=Captives.decide_question(copy,"strength","terror")
	assert_float(float(d1.r_talk)).is_equal(float(d2.r_talk))
	assert_float(float(d1.r_lie)).is_equal(float(d2.r_lie))
	var r:=Captives.ask(id,"strength","terror")
	assert_float(float(r.odds.talk)).is_equal(float(stated.talk))
	assert_float(float(r.odds.lie)).is_equal(float(stated.lie))
	var s:Dictionary=r.said
	assert_float(float(s.p_talk)).is_equal(float(stated.talk))
	assert_bool(bool(s.talked)).is_equal(float(s.r_talk)<float(s.p_talk))
	assert_bool(bool(s.lied)).is_equal(bool(s.talked) and float(s.r_lie)<float(s.p_lie))
	assert_float(float(s.r_talk)).is_equal_approx(float(d1.r_talk),0.0001)


func test_terror_raises_answers_and_lies()->void:
	var p:=_catch()
	for topic in Captives.TOPICS:
		var g:=Captives.ask_odds(p,topic,"gentle")
		var f:=Captives.ask_odds(p,topic,"firm")
		var t:=Captives.ask_odds(p,topic,"terror")
		assert_bool(float(t.talk)>=float(f.talk) and float(f.talk)>=float(g.talk)).is_true()
		assert_bool(float(t.lie)>float(f.lie) and float(f.lie)>float(g.lie)).is_true()


func test_a_lie_is_kept_false_and_shown_false_by_our_own_eyes()->void:
	var p:=_catch()
	var id:=_before_god(p)
	# A fiercely loyal, terrified prisoner: they talk, and mostly lie.
	p["loyalty"]=0.95; p["courage"]=0.9; p["love"]=0.0; p["dread"]=1.0
	var lied:Dictionary={}
	for attempt in 40:
		p["said"]=[]; p["asked"]={"strength":attempt}
		p["dread"]=1.0
		var r:=Captives.ask(id,"strength","terror")
		if bool(r.lied): lied=r.said; break
	assert_bool(lied.is_empty()).override_failure_message("a loyal prisoner in terror should lie within 40 tries").is_false()
	assert_str(String(lied.truth)).is_equal(String(Captives.fact(p,"strength").text))
	assert_bool(bool(lied.found_false)).is_false()
	# Our watcher's word on them, after it, shows it false.
	(Covert.state().learned as Array).push_front({"day":_day()+1,"civ_id":_varesh(),"civ_name":"Varesh","fact":"About 40 fighters.","who":"Kael"})
	Captives.refresh_contradictions()
	assert_bool(bool(lied.found_false)).is_true()
	var rows:=Captives.dossier_rows(id)
	assert_bool(rows.any(func(row:Array)->bool: return String(row[2])=="false")).is_true()


func test_typed_words_read_as_questions_manners_and_fates()->void:
	assert_dict(Captives.read("Who sent you?")).is_equal({"kind":"question","topic":"sender","manner":"firm"})
	assert_str(String(Captives.read("Tell me who sent you, or I will flay you").manner)).is_equal("terror")
	assert_dict(Captives.read("Please, eat something. Are you alone?")).is_equal({"kind":"question","topic":"others","manner":"gentle"})
	assert_str(String(Captives.read("Who were you sent to kill?").topic)).is_equal("mission")
	assert_str(String(Captives.read("How many fighters do your people have?").topic)).is_equal("strength")
	assert_str(String(Captives.read("Put him to death").option)).is_equal("pr_execute")
	assert_str(String(Captives.read("Send him home and tell his chief I will burn his village").option)).is_equal("pr_send:threat")
	assert_str(String(Captives.read("Send her back and tell them we want peace").option)).is_equal("pr_send:peace")
	assert_str(String(Captives.read("Turn him. Teach him our ways.").option)).is_equal("pr_turn")
	assert_dict(Captives.read("Don't kill him")).is_empty()
	assert_dict(Captives.read("I wonder whom you came here to kill")).is_empty()


# --------------------------------------------------------------------------
# Each fate's consequences hit the ledger
# --------------------------------------------------------------------------

func test_execution_dread_grudge_on_odds_and_deterrence()->void:
	var civ:=_varesh()
	var p:=_catch("assassinate",civ)
	var id:=_before_god(p)
	var acts_before:=DIVINE.events(24).filter(func(e:Dictionary)->bool: return String(e.get("action",""))=="harsh_law").size()
	var grudge_before:=float(Rivals.grudge_weight(civ))
	var opinion_before:=float(((CivilizationSystem.civilizations[Hall._civ_index(civ)] as Dictionary).player_relation as Dictionary).get("opinion",0.0))
	var chance_before:=float(Covert._rival_scheme_chance(civ,(CivilizationSystem.civilizations[Hall._civ_index(civ)] as Dictionary).player_relation))
	var r:=Hall.resolve(id,"pr_execute")
	assert_bool(bool(r.ok)).is_true()
	assert_str(String(Captives.by_id(String(p.id)).status)).is_equal("executed")
	assert_str(String(Hall.find(id).get("status",""))).is_equal("resolved")
	assert_int(DIVINE.events(24).filter(func(e:Dictionary)->bool: return String(e.get("action",""))=="harsh_law").size()).is_equal(acts_before+1)
	var fate:Dictionary=Captives.by_id(String(p.id)).fate
	assert_float(float(fate.learn)).is_equal(float(r.learn))
	var opinion_after:=float(((CivilizationSystem.civilizations[Hall._civ_index(civ)] as Dictionary).player_relation as Dictionary).get("opinion",0.0))
	if bool(fate.heard):
		assert_bool(float(Rivals.grudge_weight(civ))>grudge_before).is_true()
		assert_bool(opinion_after<opinion_before).is_true()
		assert_float(Captives.scheme_factor(civ)).is_equal(0.5)
	else:
		assert_float(float(Rivals.grudge_weight(civ))).is_equal(grudge_before)
		assert_float(Captives.scheme_factor(civ)).is_equal(0.8)
	var chance_after:=float(Covert._rival_scheme_chance(civ,(CivilizationSystem.civilizations[Hall._civ_index(civ)] as Dictionary).player_relation))
	assert_bool(chance_after<=chance_before*Captives.scheme_factor(civ)+0.0001).is_true()


func test_send_home_with_a_message_answered_on_arrival()->void:
	var civ:=_varesh()
	var p:=_catch("watch",civ)
	var id:=_before_god(p)
	# The card asks which words go with them, each with the ruler's odds.
	var ask:=Hall.resolve(id,"pr_send")
	assert_bool(bool(ask.ok)).is_false()
	assert_int((ask.choices as Array).size()).is_equal(4)
	assert_str(String(Hall.find(id).status)).is_equal("waiting")
	# The god's own words, recorded as spoken.
	var words:="Send him home and tell your chief that I will burn his village if another comes."
	var heard:=Captives.hear(id,words)
	assert_str(String(heard.option)).is_equal("pr_send:threat")
	var r:=Hall.resolve(id,String(heard.option))
	assert_bool(bool(r.ok)).is_true()
	var rec:=Captives.by_id(String(p.id))
	assert_str(String(rec.status)).is_equal("sent_home")
	assert_str(String(rec.fate.words)).is_equal(words)
	var stated:=Captives.message_odds(civ,"threat")
	assert_float(float(rec.fate.odds)).is_equal(stated)
	var tension_before:=float(((CivilizationSystem.civilizations[Hall._civ_index(civ)] as Dictionary).player_relation as Dictionary).get("border_tension",0.0))
	var grudge_before:=float(Rivals.grudge_weight(civ))
	GameState.elapsed_days=int(rec.fate.arrive_day)
	Captives.daily(_day())
	assert_bool(bool(rec.fate.answered)).is_true()
	# The odds stated when they were sent are the odds rolled on arrival.
	assert_float(float(rec.fate.answer_odds)).is_equal(stated)
	if bool(rec.fate.yes): assert_bool(Captives.scheme_factor(civ)<1.0).is_true()
	else:
		assert_bool(float(Rivals.grudge_weight(civ))>grudge_before).is_true()
		assert_bool(float(((CivilizationSystem.civilizations[Hall._civ_index(civ)] as Dictionary).player_relation as Dictionary).get("border_tension",0.0))>tension_before).is_true()


func test_turning_costs_food_daily_and_ends_by_its_odds()->void:
	var p:=_catch("watch")
	var id:=_before_god(p)
	var t:=Captives.turn_odds(p)
	assert_float(float(t.converted)+float(t.unmoved)+float(t.feigned)).is_equal_approx(1.0,0.001)
	Hall.resolve(id,"pr_turn")
	var rec:=Captives.by_id(String(p.id))
	assert_str(String(rec.status)).is_equal("turning")
	var pop_before:=float(GameState.population_exact)
	var spent_before:=float(rec.food_spent)
	var days:=int(rec.turn_end)-_day()
	for i in days:
		GameState.elapsed_days+=1
		Captives.daily(_day())
	assert_float(float(rec.food_spent)-spent_before).is_equal_approx(float(t.food_day)*days,float(days)*0.1)
	var roll:=float(rec.turn_roll)
	if roll<float(t.converted)+float(t.feigned):
		assert_str(String(rec.status)).is_equal("joined")
		assert_float(float(GameState.population_exact)).is_equal_approx(pop_before+1.0,0.01)
		assert_bool(bool(rec.feigned)).is_equal(roll>=float(t.converted))
	elif String(rec.status)!="escaped":
		assert_str(String(rec.status)).is_equal("held")


func test_won_over_they_tell_all_truly_and_can_go_back_as_our_eyes()->void:
	var p:=_catch("watch")
	var id:=_before_god(p)
	# A lie before they were won over.
	p["loyalty"]=0.95; p["courage"]=0.9; p["love"]=0.0
	for attempt in 40:
		p["said"]=[]; p["asked"]={"sender":attempt}; p["dread"]=1.0
		if bool(Captives.ask(id,"sender","terror").lied): break
	var lie_entry:Dictionary=(p.said as Array).back()
	Hall.resolve(id,"pr_turn")
	var rec:=Captives.by_id(String(p.id))
	rec["turn_odds"]={"converted":1.0,"feigned":0.0,"unmoved":0.0,"days":28,"food_day":2.0}
	GameState.elapsed_days=int(rec.turn_end)
	Captives.daily(_day())
	assert_str(String(rec.status)).is_equal("joined")
	assert_bool(bool(rec.feigned)).is_false()
	for topic in Captives.TOPICS:
		var last:=Captives._last_said(rec,topic)
		assert_bool(bool(last.talked) and not bool(last.lied)).override_failure_message(topic).is_true()
	if bool(lie_entry.get("lied",false)): assert_bool(bool(lie_entry.found_false)).is_true()
	# Sent back as our eyes: a source among them, with stated odds of being found.
	var id2:=_before_god(rec)
	var pop:=float(GameState.population_exact)
	var r:=Hall.resolve(id2,"pr_double")
	assert_bool(bool(r.ok)).is_true()
	assert_str(String(rec.status)).is_equal("double")
	assert_float(float(GameState.population_exact)).is_equal_approx(pop-1.0,0.01)
	var op:=Covert.op_by_id(int(rec.fate.op_id))
	assert_bool(bool(op.double)).is_true()
	assert_float(float(op.odds.caught)).is_equal(float(Captives.double_odds(rec).found))


func test_a_pretender_flees_with_a_small_bounded_loss()->void:
	var p:=_catch("watch")
	var id:=_before_god(p)
	Hall.resolve(id,"pr_turn")
	var rec:=Captives.by_id(String(p.id))
	rec["turn_odds"]={"converted":0.0,"feigned":1.0,"unmoved":0.0,"days":28,"food_day":2.0}
	var pop:=float(GameState.population_exact)
	GameState.elapsed_days=int(rec.turn_end)
	Captives.daily(_day())
	assert_str(String(rec.status)).is_equal("joined")
	assert_bool(bool(rec.feigned)).is_true()
	assert_float(float(GameState.population_exact)).is_equal_approx(pop+1.0,0.01)
	var food:=Hall.player_stock("Food")
	GameState.elapsed_days=int(rec.betray_day)
	Captives.daily(_day())
	assert_str(String(rec.status)).is_equal("fled")
	assert_float(float(GameState.population_exact)).is_equal_approx(pop,0.01)
	assert_bool(food-Hall.player_stock("Food")<=30.0+0.01).override_failure_message("the store fire is bounded").is_true()


func test_kept_prisoners_eat_and_our_watch_holds_them()->void:
	var p:=_catch("watch")
	var id:=_before_god(p)
	Hall.resolve(id,"pr_keep")
	var rec:=Captives.by_id(String(p.id))
	assert_str(String(rec.status)).is_equal("held")
	var spent:=float(rec.food_spent)
	GameState.elapsed_days+=1
	Captives.daily(_day())
	assert_float(float(rec.food_spent)-spent).is_equal_approx(Captives.RATION,0.001)
	# A stronger watch holds them better.
	GameState.population_allocations["Defense"]=0
	var weak:=Captives.escape_odds(rec)
	GameState.population_allocations["Defense"]=400
	var strong:=Captives.escape_odds(rec)
	assert_bool(strong<weak).is_true()
	assert_bool(strong>=0.01 and weak<=0.15).is_true()


func test_the_gods_wrath_and_favour_move_the_prisoner_and_the_odds()->void:
	var p:=_catch("watch")
	var id:=_before_god(p)
	var acts:=Hall.divine_options(id).map(func(o:Dictionary)->String: return String(o.id))
	for a in ["terrify","strike_down","bless","boon"]: assert_bool(a in acts).override_failure_message(a).is_true()
	var before:=Captives.ask_odds(p,"plans","firm")
	var dread:=float(p.dread)
	var r:=Hall.divine(id,"terrify")
	assert_bool(bool(r.ok)).is_true()
	assert_bool(float(p.dread)>dread).is_true()
	var after:=Captives.ask_odds(p,"plans","firm")
	assert_bool(float(after.talk)>float(before.talk) and float(after.lie)>float(before.lie)).is_true()
	var death:=Hall.divine(id,"strike_down")
	assert_bool(bool(death.terminal)).is_true()
	assert_str(String(Captives.by_id(String(p.id)).status)).is_equal("executed")


# --------------------------------------------------------------------------
# Parity: our agents taken abroad face the same fates
# --------------------------------------------------------------------------

func test_our_agent_taken_abroad_is_judged_by_their_ruler()->void:
	var civ:=_varesh()
	var agent:=Covert.volunteer()
	var op:=Covert.launch("watch",civ,"","trader",agent)
	var pop:=float(GameState.population_exact)
	Covert._agent_caught_ours(op,_day(),"watching")
	var rec:Dictionary=Captives.abroad(1)[0]
	var odds:Dictionary=rec.odds
	assert_float(float(odds.execute)+float(odds.send)+float(odds.turn)+float(odds.keep)).is_equal_approx(1.0,0.001)
	# The choice is the seeded roll against the stated odds.
	var acc:=0.0; var want:="keep"
	for c in ["execute","send","turn","keep"]:
		acc+=float(odds[c])
		if float(rec.roll)<acc: want=c; break
	assert_str(String(rec.choice)).is_equal(want)
	assert_str(String(rec.told)).is_not_empty()
	if want=="execute": assert_float(float(GameState.population_exact)).is_equal_approx(pop-1.0,0.01)
	# Told plainly in the chronicle with the agent's name.
	var told:Dictionary=Chronicle.entries("notice",1)[0]
	assert_bool(String(told.text).contains(String(op.agent_name))).is_true()


func test_a_harder_ruler_kills_more_and_the_same_rules_run_both_ways()->void:
	var civ:=_varesh()
	# A ruler in a hot feud with us, who holds grudges, kills more of ours; one
	# who dreads us sends them home. The same weights judge theirs and ours.
	var calm:=Captives.abroad_odds(civ,"watch")
	War.blood_feud(civ,_day(),"a raid","")
	Rivals.grudge(civ,"a raid on their herds",1.0,"test")
	var hard:=Captives.abroad_odds(civ,"watch")
	assert_bool(float(hard.execute)>float(calm.execute)).is_true()
	DIVINE.add_civ_dread(civ,0.4); DIVINE.add_civ_dread(civ,0.4)
	var afraid:=Captives.abroad_odds(civ,"watch")
	assert_bool(float(afraid.send)>float(hard.send)).is_true()
	# An assassin of ours is put to death more often than a watcher.
	assert_bool(float(Captives.abroad_odds(civ,"assassinate").execute)>float(afraid.execute)).is_true()
	# The message odds a ruler meets us with are read from the same temper
	# whichever way the message goes.
	assert_bool(Captives.message_odds(civ,"peace")>0.0).is_true()


# --------------------------------------------------------------------------
# Saves
# --------------------------------------------------------------------------

func test_saves_stay_compatible()->void:
	# An older save: no captives block, a caught entry with no prisoner.
	(Covert.state().caught as Array).push_front({"day":_day()-5,"civ_id":_varesh(),"civ_name":"Varesh","kind":"watch","fate":""})
	ForeignDiplomacy.audiences.erase("captives")
	assert_bool(Hall.validate_state(ForeignDiplomacy.audiences)).is_true()
	assert_array(Covert.caught_spies(4)).is_not_empty()
	assert_str(String(Covert.caught_spies(4)[0].fate)).is_equal("")
	# Now with prisoners in every state, through a real export and import.
	var p:=_catch("watch")
	var id:=_before_god(p)
	Captives.ask(id,"sender","firm")
	Hall.resolve(id,"pr_turn")
	assert_bool(Captives.valid_state(Captives.state())).is_true()
	assert_bool(Hall.validate_state(ForeignDiplomacy.audiences)).is_true()
	var payload:=ForeignDiplomacy.export_state()
	var round_trip:Dictionary=JSON.parse_string(JSON.stringify(payload))
	ForeignDiplomacy.import_state(round_trip)
	var back:=Captives.by_id(String(p.id))
	assert_str(String(back.status)).is_equal("turning")
	assert_int((back.said as Array).size()).is_equal(1)
	assert_bool(Captives.valid_state(Captives.state())).is_true()
	# Reading after a load rolls nothing again.
	var d1:=Captives.decide_question(back,"plans","firm")
	var d2:=Captives.decide_question(back,"plans","firm")
	assert_float(float(d1.r_talk)).is_equal(float(d2.r_talk))


# --------------------------------------------------------------------------
# The court screen (offline): menus with odds, fate cards, typed words
# --------------------------------------------------------------------------

func test_the_court_screen_offers_questions_fates_and_takes_typed_words()->void:
	GameState.civic_api_enabled=false
	var p:=_catch("assassinate")
	var id:=_before_god(p)
	var voice:=Harness.RecordingVoice.new()
	voice.force_offline=true
	add_child(voice)
	var modal:Control=Harness.Modal.new()
	modal.voice=voice; modal.audience_id=id
	add_child(modal)
	await await_idle_frame()
	voice.drain(id)
	modal._build_options()
	for manner in ["gentle","firm","terror"]: assert_object(modal.find_child("Persons_"+manner,true,false)).override_failure_message(manner).is_not_null()
	for card in ["pr_execute","pr_send","pr_turn","pr_keep"]: assert_object(modal.find_child("Option_"+card,true,false)).override_failure_message(card).is_not_null()
	# Typed: a question is asked and answered from the sheet.
	modal.speech_input.text="Who sent you?"
	modal._speak()
	assert_int((Captives.by_id(String(p.id)).said as Array).size()).is_equal(1)
	# The send card asks which words: four answers, each with the ruler's odds.
	modal.choose("pr_send")
	var words:=modal.find_children("*PrisonerWords*","Button",true,false)
	assert_int(words.size()).is_equal(4)
	# The execution menu's words (court_commands.hear): carried out.
	var heard:Dictionary=modal.office_order("Put %s to death with the club." % String(p.name))
	assert_bool(bool(heard.get("handled",false))).is_true()
	assert_str(String(Captives.by_id(String(p.id)).status)).is_equal("executed")
	modal.queue_free(); voice.queue_free()


func test_harsh_words_terrify_and_orders_for_the_court_go_on()->void:
	var p:=_catch("watch")
	var id:=_before_god(p)
	# A flogging is the god's terror on them (dread rises, kindness falls).
	assert_str(String(Captives.hear(id,"Flog him").get("divine",""))).is_equal("terrify")
	# Talk is met with silence, and what they can be asked is said.
	var talk:=Captives.hear(id,"You will rot here")
	assert_bool(bool(talk.handled) and bool(talk.get("talk",false))).is_true()
	# An order for the war leader is the court's business, not the prisoner's.
	assert_bool(bool(Captives.hear(id,"Attack Tsaren").get("handled",false))).is_false()


func test_the_ticker_carries_a_bring_them_button_while_they_are_held()->void:
	var p:=_catch("assassinate")
	var label:=Label.new()
	add_child(label)
	preload("res://scripts/hud/map_ticker_style.gd").style(label)
	label.text=preload("res://scripts/hud/map_ticker_words.gd").latest_telling()
	preload("res://scripts/hud/map_ticker_style.gd").fit(label,1600.0)
	var button:=label.get_node_or_null("TickerAction") as Button
	assert_object(button).is_not_null()
	assert_bool(button.visible).is_true()
	assert_str(button.text).is_equal("Bring them before you")
	assert_str(String(button.get_meta("prisoner_id",""))).is_equal(String(p.id))
	# Put to death: the button goes.
	var id:=_before_god(p)
	Hall.resolve(id,"pr_execute")
	label.set_meta("ticker_fitted","")
	preload("res://scripts/hud/map_ticker_style.gd").fit(label,1601.0)
	assert_bool(button.visible).is_false()
	label.queue_free()
