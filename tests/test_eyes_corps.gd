extends GdUnitTestSuite
## THE EYES AND THE WARY (scripts/eyes_corps.gd): trained like the army, they
## blend in by the size of the people they move among, are rarely found once
## settled, send word home by our scouts, and the wary breed distrust at home.

const Covert:=preload("res://scripts/covert_ops.gd")
const Corps:=preload("res://scripts/eyes_corps.gd")
const Orders:=preload("res://scripts/court_eyes_orders.gd")
const Fixtures:=preload("res://tests/court_eval/fixtures.gd")
const CV:=preload("res://scripts/character_voice.gd")

var fx:Fixtures
var info:Dictionary


func before()->void:
	for key in ["OPENAI_API_KEY","LEVIATHAN_AI_API_KEY","LEVIATHAN_AI_ENDPOINT"]: OS.unset_environment(key)
	fx=Fixtures.new(self)


func before_test()->void:
	CV.knowledge_override.clear()
	info=fx.base(false)
	Covert.forget()
	ForeignDiplomacy.audiences.erase(Corps.KEY)


func after()->void:
	CV.knowledge_override.clear()
	GameState.reset_for_new_world(74017)
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	WorldSimulation.clear()


func _civ_id()->String: return String(info.get("civ_id",""))


func _run(days:int)->void:
	var day:=int(GameState.elapsed_days)
	for i in days:
		day+=1
		Corps.daily(day)
	GameState.elapsed_days=day


func test_a_course_turns_a_policy_into_trained_eyes_whose_craft_grows_to_the_ages_cap()->void:
	assert_float(Corps.members("eyes")).is_equal(0.0)
	assert_bool(Corps.set_policy("eyes","many")).is_true()
	_run(200)
	assert_float(Corps.in_training("eyes")+Corps.members("eyes")).is_greater(0.0)
	_run(800)
	assert_float(Corps.members("eyes")).is_greater_equal(1.0)
	var course:Dictionary=Corps.COURSE[Corps.stage()]
	assert_float(Corps.craft("eyes")).is_between(float(course.start)-0.001,float(course.cap)+0.001)
	# Service sharpens past what a graduate starts with.
	assert_float(Corps.craft("eyes")).is_greater(float(course.start))


func test_a_newcomer_blends_into_thousands_but_not_into_two_hundred()->void:
	var civ:Dictionary=WorldSimulation.world.civilizations[0]
	civ["population"]=200.0
	var small:=Covert.settle_risk(_civ_id(),"none",0.7,0.15,0.0,0.0)
	civ["population"]=2000.0
	var large:=Covert.settle_risk(_civ_id(),"none",0.7,0.15,0.0,0.0)
	assert_float(small).is_greater(0.6)
	assert_float(large).is_less(0.1)
	# A refugee has a reason to arrive.
	assert_float(Covert.settle_risk(_civ_id(),"refugee",0.7,0.15,0.0,0.0)).is_less(large+0.0001)


func test_a_trained_eye_settled_in_is_rarely_found_and_word_comes_home_by_the_road()->void:
	(WorldSimulation.world.civilizations[0] as Dictionary)["population"]=2500.0
	CV.knowledge_override["player"]=["phonetic_notation","copper_smelting","seed_selection"]   # a settled people can plant an eye
	var state:Dictionary=Corps.state()
	(state.eyes as Dictionary)["members"]=3.0
	(state.eyes as Dictionary)["craft"]=0.75
	var agent:=Covert.volunteer_for("plant")
	assert_bool(bool(agent.get("trained",false))).is_true()
	var op:=Covert.launch("plant",_civ_id(),"","trader",agent)
	assert_bool(op.has("error")).override_failure_message(String(op.get("error",""))).is_false()
	assert_float(Corps.members("eyes")).is_equal(2.0)
	# Each meeting with our scout is the risk once settled: small for a trained eye.
	assert_float(float((op.odds as Dictionary).caught)).is_less(0.05)
	assert_float(float((op.odds as Dictionary).settle)).is_less(0.15)
	(op.odds as Dictionary)["settle"]=0.0
	(op.odds as Dictionary)["caught"]=0.0
	Covert._arrive(op,int(op.arrive_day))
	assert_str(String(op.stage)).is_equal("in_place")
	var meet:=int(op.next_report)
	Covert._advance(op,meet)
	assert_bool(op.has("courier_due")).override_failure_message("the scout carries the word home").is_true()
	var learned_before:=Covert.learned(40).size()
	Covert._advance(op,int(op.courier_due)-1)
	assert_int(Covert.learned(40).size()).is_equal(learned_before)
	Covert._advance(op,int(op.courier_due))
	assert_bool(op.has("courier_due")).is_false()


func test_the_wary_catch_more_and_breed_distrust_that_costs_cohesion()->void:
	var plain:=Covert._catch_chance(_civ_id())
	var state:Dictionary=Corps.state()
	(state.wary as Dictionary)["members"]=float(GameState.population_exact)/1000.0*Corps.FULL_WATCH_PER_K
	(state.wary as Dictionary)["craft"]=0.8
	assert_float(Corps.coverage()).is_equal_approx(1.0,0.01)
	assert_float(Covert._catch_chance(_civ_id())).is_greater(plain)
	_run(400)
	assert_float(Corps.distrust()).is_greater(0.0)
	var before:=Corps.distrust()
	Corps.found_among_us()
	assert_float(Corps.distrust()).is_greater(before)
	assert_float(Corps.cohesion_cost()).is_greater(0.0)


func test_the_court_words_set_the_policy_and_never_steal_a_covert_act()->void:
	assert_dict(Orders.read("Teach a few eyes")).is_equal({"corps":"eyes","policy":"few"})
	assert_dict(Orders.read("train many spies")).is_equal({"corps":"eyes","policy":"many"})
	assert_dict(Orders.read("Keep the wary steady")).is_equal({"corps":"wary","policy":"steady"})
	assert_dict(Orders.read("stop training watchers")).is_equal({"corps":"eyes","policy":"none"})
	assert_dict(Orders.read("Send spies to the Esurai")).is_empty()
	assert_dict(Orders.read("how many eyes do we have?")).is_empty()
	var done:=Orders.perform({"corps":"eyes","policy":"steady"})
	assert_bool(bool(done.ok)).is_true()
	assert_str(Corps.policy("eyes")).is_equal("steady")
	assert_str(String(done.says)).contains("course")


func test_nothing_early_says_spy()->void:
	if Corps.stage()=="hearth":
		assert_str(Corps.word("eyes")).is_equal("eyes")
		assert_str(Corps.word("Wary")).not_contains("spy")
	assert_bool(Corps.valid_state(Corps.state())).is_true()


func _catch_one()->Dictionary:
	var Captives:=preload("res://scripts/captured_agents.gd")
	return Captives.take({"civ_id":_civ_id(),"kind":"watch","seed":"t:catch"},int(GameState.elapsed_days))


func test_one_of_theirs_found_first_asks_what_is_done_with_the_news()->void:
	var Hall:=preload("res://scripts/audience_hall.gd")
	var p:=_catch_one()
	var a:=Hall.summon({"prisoner_id":String(p.id)})
	assert_bool(a.is_empty()).is_false()
	var ids:Array=preload("res://scripts/captured_agents.gd").options(Hall.find(String(a.id))).map(func(o:Dictionary)->String:return String(o.id))
	assert_array(ids).contains(["pr_secrecy:hush","pr_secrecy:proclaim","pr_secrecy:sweep"])
	assert_array(ids).not_contains(["pr_execute"])
	var before:=Corps.distrust()
	var r:=Hall.resolve(String(a.id),"pr_secrecy:proclaim")
	assert_bool(bool(r.get("ok",false))).is_true()
	assert_str(String(p.secrecy)).is_equal("proclaim")
	assert_float(Corps.distrust()).is_greater(before)
	assert_float(Corps.vigilance()).is_greater(0.0)
	# Brought in again, their fate comes next.
	var again:=Hall.summon({"prisoner_id":String(p.id)})
	var next:Array=preload("res://scripts/captured_agents.gd").options(Hall.find(String(again.id))).map(func(o:Dictionary)->String:return String(o.id))
	assert_array(next).contains(["pr_execute"])


func test_a_hushed_finding_may_get_out_later_and_cost_more()->void:
	for i in 12:
		Corps.secrecy("hush",_civ_id(),int(GameState.elapsed_days),"t:hush:%d" % i)
	var leaks:Array=Corps.state().get("leaks",[])
	assert_array(leaks).is_not_empty()
	var before:=Corps.distrust()
	_run(Corps.LEAK_DAYS_MAX+2)
	assert_array(Corps.state().get("leaks",[]) as Array).is_empty()


func test_an_accused_neighbour_tells_the_truth_gently_and_may_confess_under_terror()->void:
	var Captives:=preload("res://scripts/captured_agents.gd")
	var Hall:=preload("res://scripts/audience_hall.gd")
	var p:=Corps.accuse(int(GameState.elapsed_days),_civ_id(),"fear")
	assert_bool(p.is_empty()).is_false()
	assert_bool(bool(p.accused)).is_true()
	assert_bool(bool(p.innocent)).is_true()   # no eye of theirs is among us
	var a:=Hall.summon({"prisoner_id":String(p.id)})
	var r:=Captives.ask(String(a.id),String(Captives.TOPICS[0]),"gentle")
	assert_bool(bool(r.lied)).is_false()
	assert_str(String(r.said.text)).contains("of this people")
	var ids:Array=Captives.options(Hall.find(String(a.id))).map(func(o:Dictionary)->String:return String(o.id))
	assert_array(ids).contains(["pr_free"])
	var before:=Corps.distrust()
	Hall.resolve(String(a.id),"pr_free")
	assert_str(String(Captives.by_id(String(p.id)).status)).is_equal("freed")
	assert_float(Corps.distrust()).is_less(before)
	assert_bool(Captives.valid_state(Captives.state())).is_true()


func test_a_long_settled_eye_makes_what_we_know_of_them_nearly_exact()->void:
	var Standing:=preload("res://scripts/standing.gd")
	CV.knowledge_override["player"]=["phonetic_notation","copper_smelting","seed_selection"]
	var rel:Dictionary=(WorldSimulation.world.civilizations[0] as Dictionary).player_relation
	rel["contact_level"]=2; rel["contact_intelligence"]=0.2
	var op:=Covert.launch("plant",_civ_id(),"","trader",Covert.volunteer())
	op["stage"]="in_place"
	op["settled_day"]=int(GameState.elapsed_days)
	var fresh:=Standing.certainty(_civ_id())
	op["settled_day"]=int(GameState.elapsed_days)-20*365
	var old:=Standing.certainty(_civ_id())
	assert_float(old).is_greater(fresh)
	assert_float(old).is_greater_equal(0.95)
