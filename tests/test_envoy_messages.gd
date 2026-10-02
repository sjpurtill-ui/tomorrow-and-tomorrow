extends GdUnitTestSuite
## Word abroad, in the one court: purposes and gift gating, weighty tribute,
## reverence and dread in the answer, coherent words, real replies in the
## ruler's voice, visible consequences, ultimatum deadlines and broken
## threats, rival weights (never pace), the live voice (mocked), save
## round-trip, and the court's compose area and pacts pane.
## No live model: GameState.civic_api_enabled is false throughout.

const Messages:=preload("res://scripts/envoy_messages.gd")
const Compose:=preload("res://scripts/hud/court_envoy_compose.gd")
const Council:=preload("res://scripts/hud/court_council_panel.gd")
const Court:=preload("res://scripts/hud/audience_modal.gd")
const Fixture:=preload("res://tests/diplomacy_fixture.gd")
const Rivals:=preload("res://scripts/rival_rulers.gd")
const Divine:=preload("res://scripts/divine_regard.gd")
const Lives:=preload("res://scripts/court_lives.gd")

var first:=""

func before_test()->void:
	first=Fixture.build_fixture()
	GameState.civic_api_enabled=false

func id(index:int)->String: return String(CivilizationSystem.civilizations[index].id)

func _civ(civ_id:String)->Dictionary:
	for civ:Dictionary in CivilizationSystem.civilizations:
		if String(civ.id)==civ_id: return civ
	return {}

## The portrait's reverence comes from opinion and their ruler's trust.
func _revering(civ_id:String)->void:
	_civ(civ_id).player_relation.opinion=0.9
	_civ(civ_id).player_relation.border_tension=0.0
	ForeignDiplomacy.leader(civ_id)["trust"]=0.8

func _unmoved(civ_id:String)->void:
	_civ(civ_id).player_relation.opinion=-0.3
	_civ(civ_id).player_relation.border_tension=0.0
	ForeignDiplomacy.leader(civ_id)["trust"]=-0.3

func _terrified(civ_id:String)->void:
	Divine.add_civ_dread(civ_id,0.4); Divine.add_civ_dread(civ_id,0.4)

func _proud(civ_id:String)->void:
	_unmoved(civ_id)
	_civ(civ_id).player_relation.opinion=-0.9
	Rivals.grudge(civ_id,"old wrongs",1.2,"test_old")
	Messages.store()["credibility"]=0.15

func _boldest()->String:
	var best:="";var bold:=-1.0
	for civ:Dictionary in CivilizationSystem.civilizations:
		civ.player_relation.contact_level=2; civ.player_relation.home_location_known=true
		civ.player_relation.home_position={"x":CivilizationSystem.player_world_origin.x+2,"z":CivilizationSystem.player_world_origin.y}
		var value:=float(Messages.standing(String(civ.id)).bold)
		if value>bold: bold=value; best=String(civ.id)
	return best

func _mission(civ_id:String,purpose:String,choice:Dictionary={})->Dictionary:
	var menace:=Messages.priced(civ_id,Messages.build(purpose,choice))
	menace["brief"]=Messages.brief(civ_id,menace)
	return {"civ_id":civ_id,"purpose":purpose,"personnel":9,"depart_day":int(GameState.elapsed_days),"menace":menace}

func _sentences(text:String)->int:
	var count:=0
	for mark in [".","!","?"]: count+=text.count(mark)
	return count

# --- Catalogue ---------------------------------------------------------------------

func test_purposes_and_gift_gating()->void:
	assert_array(Messages.HOSTILE).is_equal(CivilizationSystem.HOSTILE_DIPLOMATIC_ACTIONS)
	assert_bool(Messages.allows_gift("goodwill","")).is_false()
	assert_bool(Messages.allows_gift("goodwill","Timber")).is_true()
	assert_bool(Messages.allows_gift("open_trade","")).is_true()
	assert_bool(Messages.allows_gift("send_aid","Timber")).is_false()
	for kind in Messages.HOSTILE+["declare_war","leader_parley"]:
		assert_bool(Messages.allows_gift(kind,"Food")).is_false()
	assert_bool(CivilizationSystem.diplomatic_mission_quote(first,"Food","threaten").has("error")).is_true()
	assert_bool("raider_head" in Messages.tokens_for(first,"threaten")).is_false()
	CivilizationSystem.war_history.push_front({"id":"war_t","participants":["player",first],"casualties":{"player":{"military_dead":2},first:{"military_dead":3}},"status":"ended"})
	assert_bool("raider_head" in Messages.tokens_for(first,"threaten")).is_true()
	assert_bool("apology" in Messages.demands_for(id(1))).is_false()
	assert_bool("apology" in Messages.demands_for(first)).is_true()

# --- Weighty demands -----------------------------------------------------------------

func test_tribute_is_sized_to_matter_to_them()->void:
	var modest:=Messages.tribute_terms(first,"Food","modest")
	var heavy:=Messages.tribute_terms(first,"Food","heavy")
	var crushing:=Messages.tribute_terms(first,"Food","crushing")
	var stock:=float(modest.stock)
	assert_float(stock).is_greater(100.0)
	# A real share of what they hold, never a token amount, never all of it.
	assert_float(float(modest.amount)).is_greater_equal(stock*0.07)
	assert_float(float(heavy.amount)).is_greater(float(modest.amount))
	assert_float(float(crushing.amount)).is_greater(float(heavy.amount))
	assert_float(float(crushing.amount)).is_less_equal(stock*0.36)
	# Heavier demands weigh more in their answer.
	var light:=Messages.build("demand",{"demand":"tribute","size":"modest"})
	var harsh:=Messages.build("demand",{"demand":"tribute","size":"crushing"})
	assert_float(Messages.score(first,harsh)).is_less(Messages.score(first,light))
	# The words name the real amount.
	assert_str(Messages.demand_words(first,Messages.priced(first,harsh))).contains(str(roundi(float(Messages.priced(first,harsh).tribute.amount))))

# --- Reverence and dread -------------------------------------------------------------

func test_revering_people_gives_way_to_the_gods_wrath()->void:
	_revering(first)
	var s:=Messages.standing(first)
	assert_float(float(s.reverence)).is_greater(0.75)
	for size in ["modest","heavy"]:
		var menace:=Messages.build("ultimatum",{"by":"wrath","demand":"tribute","size":size,"consequence":"war"})
		var f:=Messages.forecast(first,menace)
		assert_float(float(f.chance)).override_failure_message("chance %s for %s" % [f.chance,size]).is_greater_equal(0.8)
		assert_str(String(f.words)).contains("give way")
		assert_bool("they revere you" in (f.why as Array)).is_true()
	# Awe is the god's, not the warriors': the same people weigh spears apart.
	var spears:=Messages.build("demand",{"by":"spears","demand":"tribute","size":"heavy"})
	var wrath:=Messages.build("demand",{"by":"wrath","demand":"tribute","size":"heavy"})
	assert_float(Messages.score(first,wrath)).is_greater(Messages.score(first,spears))
	# And the answer is awed compliance.
	var result:=Messages.arrive(_mission(first,"demand",{"by":"wrath","demand":"tribute","size":"modest"}),int(GameState.elapsed_days))
	assert_str(String(result.answer)).is_equal("comply")
	assert_str(String(result.mood)).is_equal("awed")

func test_dread_makes_them_comply_and_indifference_makes_them_scoff()->void:
	_unmoved(id(1))
	var threat:=Messages.build("threaten",{"by":"wrath"})
	assert_float(float(Messages.forecast(id(1),threat).chance)).is_less(0.3)
	var result:=Messages.arrive(_mission(id(1),"threaten",{"by":"wrath"}),int(GameState.elapsed_days))
	assert_str(String(result.answer)).is_equal("defy")
	assert_bool(String(result.mood) in ["scornful","proud"]).is_true()
	# Terrify them first: the same threat now lands, out of fear.
	(Messages.store().stances as Dictionary).clear()
	_terrified(id(1))
	assert_float(float(Messages.forecast(id(1),threat).chance)).is_greater(0.6)
	GameState.elapsed_days+=1
	var second:=Messages.arrive(_mission(id(1),"threaten",{"by":"wrath"}),int(GameState.elapsed_days))
	assert_str(String(second.answer)).is_equal("comply")
	assert_str(String(second.mood)).is_equal("terrified")

func test_revering_people_asked_too_much_is_shaken_and_betrayed()->void:
	_revering(first)
	var before:=float(Divine.foreign_regard(first).love)
	var crushing:=Messages.build("demand",{"by":"wrath","demand":"tribute","size":"crushing"})
	var f:=Messages.forecast(first,crushing)
	assert_float(float(f.chance)).is_less(0.2)
	assert_bool(str(f.why).contains("betrayal")).is_true()
	var result:=Messages.arrive(_mission(first,"demand",{"by":"wrath","demand":"tribute","size":"crushing"}),int(GameState.elapsed_days))
	assert_str(String(result.answer)).is_equal("defy")
	assert_str(String(result.mood)).is_equal("betrayed")
	assert_str(String(result.reply)).contains("your god")
	# Shaken, not shrugging: their reverence falls and they remember it.
	assert_float(float(Divine.foreign_regard(first).love)).is_less(before-0.05)
	assert_str(Messages.consequence_note(first,{"purpose":"demand","result":result})).contains("reverence")

# --- Words ---------------------------------------------------------------------------

func test_words_keep_backing_and_consequence_together()->void:
	var wrath:=Messages.priced(first,Messages.build("ultimatum",{"by":"wrath","demand":"tribute","consequence":"war","deadline":91}))
	for line in Messages.phrasings(first,"ultimatum",wrath):
		assert_str(line).contains("send my people against you")
		assert_str(line.to_lower()).not_contains("warriors")
		assert_str(line).contains("one season")
	var spears:=Messages.priced(first,Messages.build("ultimatum",{"by":"spears","demand":"tribute","consequence":"war"}))
	for line in Messages.phrasings(first,"ultimatum",spears):
		assert_str(line).contains("warriors")
		assert_str(line.to_lower()).not_contains("god")
	var sever:=Messages.priced(first,Messages.build("ultimatum",{"by":"wrath","demand":"withdraw","consequence":"sever"}))
	for line in Messages.phrasings(first,"ultimatum",sever):
		assert_str(line).contains("turn my face from you")
		assert_str(line.to_lower()).not_contains("spears")
	# The envoy tells it in the envoy's own voice, token and all.
	var told:=Messages.envoy_account(first,Messages.priced(first,Messages.build("ultimatum",{"by":"wrath","demand":"tribute","consequence":"war","token":"broken_spear"})))
	assert_str(told).contains("I told them")
	assert_str(told).contains("you will send your people against them with spears")
	assert_str(told).contains("broken spear")

func test_offline_answers_are_real_replies()->void:
	_revering(first)
	var comply:=Messages.arrive(_mission(first,"demand",{"by":"wrath","demand":"tribute","size":"modest"}),int(GameState.elapsed_days))
	assert_str(String(comply.answer)).is_equal("comply")
	assert_int(_sentences(String(comply.reply))).is_greater_equal(2)
	assert_str(String(comply.reply)).contains(str(roundi(float(comply.carry.amount))))
	var target:=_boldest()
	_proud(target)
	var defy:=Messages.arrive(_mission(target,"ultimatum",{"by":"spears","demand":"hostage","consequence":"war","deadline":91}),int(GameState.elapsed_days))
	assert_str(String(defy.answer)).is_not_equal("comply")
	if String(defy.answer)=="defy":
		assert_int(_sentences(String(defy.reply))).is_greater_equal(2)
		assert_str(String(defy.reply)).not_contains("Your threat does not frighten me")
		assert_str(String(defy.reply).to_lower()).contains("count")

# --- Consequences ---------------------------------------------------------------------

func test_consequences_are_shown_in_the_conversation_chronicle_and_ties()->void:
	var target:=_boldest()
	_proud(target)
	var result:Dictionary=Messages.send(target,"ultimatum",{"by":"spears","demand":"withdraw","consequence":"war","deadline":91})
	assert_bool(result.has("error")).is_false()
	GameState.elapsed_days=int(CivilizationSystem.diplomatic_mission.arrival_day)
	CivilizationSystem._process_diplomatic_mission(int(GameState.elapsed_days))
	assert_str(String(CivilizationSystem.diplomatic_mission.menace.result.answer)).is_not_equal("comply")
	GameState.elapsed_days=int(CivilizationSystem.diplomatic_mission.return_day)
	CivilizationSystem._process_diplomatic_mission(int(GameState.elapsed_days))
	var roles:Array=[]
	var note:=""
	for line:Dictionary in ForeignDialogue.thread(target).messages:
		roles.append(String(line.role))
		if String(line.role)=="note": note=String(line.content)
	assert_array(roles).contains(["user","envoy","assistant","note"])
	assert_str(note).contains("Their deadline is Year ")
	# A people too small for a declared war is threatened with our spears, and
	# the threat is kept by a strike (conflict_scale.gd; early feuds).
	var small:=not preload("res://scripts/conflict_scale.gd").formal(target)
	assert_str(note).contains("bound to send your spears against them" if small else "bound to make war")
	var shown:=""
	for tie:Dictionary in Council.ties(target): shown+=String(tie.text)+"\n"
	assert_str(shown).contains("Your ultimatum · due Year ")
	var titles:=""
	for entry in Lives.state().chronicle: titles+=String((entry as Dictionary).get("title",""))+"\n"
	assert_str(titles).contains("Answers Your Ultimatum")
	# The court hears when the deadline passes.
	var u:=Messages.open_ultimatum(target)
	assert_bool(u.is_empty()).is_false()
	Messages.daily(int(u.due))
	var last:Dictionary=(ForeignDialogue.thread(target).messages as Array).back()
	assert_str(String(last.role)).is_equal("note")
	assert_str(String(last.content)).contains("Strike before" if small else "Declare it before")

func test_ultimatum_broken_when_the_god_does_not_follow_through()->void:
	var target:=_boldest()
	_proud(target)
	var day:=int(GameState.elapsed_days)
	Messages._open_ultimatum(target,{"deadline":91,"demand":"withdraw","consequence":"war","by":"spears"},day)
	var u:=Messages.open_ultimatum(target)
	Messages.store()["credibility"]=0.6
	Messages.daily(int(u.due))
	assert_str(String(u.status)).is_equal("open")
	Messages.daily(int(u.due)+Messages.GRACE_DAYS)
	assert_str(String(u.status)).is_equal("broken")
	assert_float(Messages.credibility()).is_equal_approx(0.4,0.001)
	assert_str(Messages.stance(target)).is_equal("emboldened")
	assert_float(Messages.rival_weight("tribute_demand",target)).is_greater(1.0)

func test_ultimatum_kept_by_war_and_sever_carried_out()->void:
	var target:=id(2)
	_proud(target)
	var day:=int(GameState.elapsed_days)
	Messages._open_ultimatum(target,{"deadline":182,"demand":"withdraw","consequence":"war"},day)
	var u:=Messages.open_ultimatum(target)
	var credibility:=Messages.credibility()
	_civ(target).player_relation.at_war=true
	_civ(target).player_relation.war_started_day=day+30
	Messages.daily(day+30)
	assert_str(String(u.status)).is_equal("kept")
	assert_float(Messages.credibility()).is_greater(credibility)
	var other:=id(1)
	_proud(other)
	_civ(other).player_relation.treaty="trade"
	Messages._open_ultimatum(other,{"deadline":91,"demand":"withdraw","consequence":"sever"},day)
	Messages.daily(day+91)
	assert_str(String(_civ(other).player_relation.treaty)).is_equal("none")

func test_rival_weights_change_business_not_pace()->void:
	var target:=id(2)
	var base:=Rivals.weight("tribute_demand",target)
	Messages._set_stance(target,"emboldened")
	assert_float(Rivals.weight("tribute_demand",target)).is_greater(base)
	for kind in ["gift_goods","trade_offer","news_report","first_contact"]:
		assert_float(Messages.rival_weight(kind,target)).is_equal(1.0)

# --- The live voice (mocked) ------------------------------------------------------------

func test_live_voice_is_validated_and_waited_for()->void:
	_revering(first)
	var mission:=_mission(first,"demand",{"by":"wrath","demand":"tribute","size":"modest","words":"The god wants a share of their food and will not wait long."})
	Messages.arrive(mission,int(GameState.elapsed_days))
	var amount:=roundi(float(mission.menace.result.carry.amount))
	# Invented numbers, broken character and a reversed answer are refused.
	assert_bool(Messages.accept_voice(mission,{"envoy_words":"I told them the god wants their food.","reply":"We will give you 9999 food."})).is_false()
	assert_bool(Messages.accept_voice(mission,{"envoy_words":"I told them the god wants their food.","reply":"Press the button in the game system."})).is_false()
	assert_bool(Messages.accept_voice(mission,{"envoy_words":"I told them the god wants their food.","reply":"No. We will not give you food."})).is_false()
	# The mock answers after the envoys are home: nothing is told until it does.
	mission.menace["voice"]="pending"
	CivilizationSystem.diplomatic_history.push_front(mission)
	Messages.homecoming(mission,int(GameState.elapsed_days)+5)
	var before:=(ForeignDialogue.thread(first).messages as Array).size()
	assert_bool(bool(mission.menace.result.get("told",false))).is_false()
	var ok:=Messages.voice_answered(first,int(mission.depart_day),{"envoy_words":"I told them at their fire that you want part of what they have stored, and soon.","reply":"We honour your god. Take the %d food; my people will carry it to the border." % amount})
	assert_bool(ok).is_true()
	var lines:Array=ForeignDialogue.thread(first).messages
	assert_int(lines.size()).is_greater(before)
	var said:=""
	for line:Dictionary in lines: said+=String(line.content)+"\n"
	assert_str(said).contains("We honour your god")
	# A voice lost to a reload is told in preset words after two days.
	var second:=_mission(id(1),"threaten",{"by":"wrath"})
	second["depart_day"]=int(GameState.elapsed_days)+1
	Messages.arrive(second,int(GameState.elapsed_days))
	second.menace["voice"]="pending"
	CivilizationSystem.diplomatic_history.push_front(second)
	Messages.homecoming(second,int(GameState.elapsed_days))
	Messages.daily(int(GameState.elapsed_days)+3)
	assert_bool(bool(second.menace.result.get("told",false))).is_true()
	assert_str(String(second.menace.voice)).is_equal("failed")

func test_live_prompt_carries_the_decided_outcome_and_facts()->void:
	_revering(first)
	var mission:=_mission(first,"ultimatum",{"by":"wrath","demand":"tribute","size":"heavy","consequence":"war","deadline":182})
	Messages.arrive(mission,int(GameState.elapsed_days))
	var messages:=Messages.voice_messages(first,mission.menace)
	var system:=String(messages[0].content)
	assert_str(system).contains("ALREADY DECIDED")
	assert_str(system).contains("mood:")
	var facts:=String(messages[1].content)
	for key in ["reverence_for_the_god","dread_of_the_god","temper","manner","their_stores_of_it","demand_amount","consequence","their_friends","their_grudges","their_memories"]:
		assert_str(facts).contains(key)

# --- Save and the world clock ------------------------------------------------------------

func test_save_round_trip()->void:
	var result:=Messages.send(id(2),"ultimatum",{"demand":"tribute","size":"crushing","consequence":"war","deadline":182,"token":"broken_spear"})
	assert_bool(result.has("error")).is_false()
	Messages._open_ultimatum(first,{"deadline":91,"demand":"tribute","consequence":"sever"},int(GameState.elapsed_days))
	Messages._set_stance(first,"defiant")
	var hall:=ForeignDiplomacy.export_state()
	var world:=CivilizationSystem.export_state()
	assert_bool(Messages.valid_state(hall.audiences.menace)).is_true()
	assert_bool(ForeignDialogue.validate_state(ForeignDialogue.export_state())).is_true()
	assert_bool(ForeignDiplomacy.import_state(JSON.parse_string(JSON.stringify(hall))).has("error")).is_false()
	assert_bool(CivilizationSystem.import_state(world).has("error")).is_false()
	assert_str(String(CivilizationSystem.diplomatic_mission.menace.size)).is_equal("crushing")
	assert_bool(Messages.open_ultimatum(first).is_empty()).is_false()
	assert_str(Messages.stance(first)).is_equal("defiant")
	assert_bool(Messages.valid_state({"credibility":2.0})).is_false()
	assert_bool(Messages.valid_mission({"purpose":"goodwill"})).is_false()

# --- The one court ----------------------------------------------------------------------

func _court(civ_id:String)->Control:
	var court:Control=auto_free(Court.new())
	add_child(court)
	await await_idle_frame()
	assert_bool(court.show_foreign(civ_id)).is_true()
	await await_idle_frame()
	return court

func test_court_compose_offers_every_purpose_and_sends_menace()->void:
	var court:Control=await _court(first)
	var compose=court.compose
	assert_object(compose).is_not_null()
	for pair:Array in Compose.GROUPS:
		compose.choose_group(String(pair[0]))
		for kind:String in compose.purposes_in(String(pair[0])): assert_object(compose.find_child("Purpose_"+kind,true,false)).is_not_null()
	compose.choose("threaten")
	assert_object(compose.find_child("Gifts",true,false)).is_null()
	assert_object(compose.find_child("Tokens",true,false)).is_not_null()
	compose.choose("goodwill")
	assert_object(compose.find_child("Gifts",true,false)).is_not_null()
	compose.choose("shared_work")
	assert_object(compose.find_child("Accord",true,false)).is_not_null()
	compose.choose("protection")
	assert_str(compose.reception.text).contains("Likely answer")
	# The ultimatum shows the real amount before it leaves.
	compose.choose("ultimatum")
	for part in ["Backing","Demands","Goods","Size","Deadline","Consequence","Tokens","Words"]: assert_object(compose.find_child(part,true,false)).is_not_null()
	compose.pick("size","crushing")
	var terms:=Messages.tribute_terms(first,String(compose.sel.good),"crushing")
	var sizes:=""
	for button in compose.find_child("Size",true,false).find_children("*","Button",true,false): sizes+=(button as Button).text+"\n"
	assert_str(sizes).contains(Compose.about(float(terms.amount)))
	assert_str(compose.reception.text).contains("in 10")
	assert_str(compose.cost_label.text).contains("days there and back")
	var sent:Dictionary=compose.send()
	assert_bool(sent.has("error")).is_false()
	assert_str(String(CivilizationSystem.diplomatic_mission.menace.size)).is_equal("crushing")
	assert_bool(compose.send_button.disabled).is_true()
	var brief:Dictionary=(ForeignDialogue.thread(first).messages as Array).back()
	assert_str(String(brief.role)).is_equal("user")

func test_court_pacts_pane_and_ties_replace_the_council()->void:
	var court:Control=await _court(first)
	assert_object(court.find_child("Ties",true,false)).is_not_null()
	court.show_foreign_view("pacts")
	await await_idle_frame()
	assert_bool((court.find_child("PactsPane",true,false) as Control).visible).is_true()
	for part in ["LeagueTerms","Member_player","Relief_relief_9","SendFood_"+id(1)]: assert_object(court.find_child(part,true,false)).is_not_null()
	for label in court.council_panel.find_children("When","Label",true,false): assert_str((label as Label).text).starts_with("YEAR ")
	(court.find_child("SendFood_"+id(1),true,false) as Button).pressed.emit()
	await await_idle_frame()
	assert_str(String(court.foreign_civ)).is_equal(id(1))
	assert_str(String(court.compose.purpose)).is_equal("send_aid")
	assert_bool((court.find_child("ConversationPane",true,false) as Control).visible).is_true()
	assert_bool(court.focus({"civ_id":first,"purpose":"declare_war"})).is_true()
	assert_str(String(court.compose.purpose)).is_equal("declare_war")

## "Bow to us" (world_answer.gd): demanded at the menace's own stated odds; if
## they give way they become tributaries through the one tribute ledger, with
## a hostage the court knows. A people that already bows is not asked again.
func test_a_demand_to_bow_makes_them_tributaries_when_they_give_way()->void:
	var answer:=preload("res://scripts/world_answer.gd")
	_revering(first)
	_terrified(first)
	assert_array(Messages.demands_for(first)).contains(["submit"])
	var menace:=Messages.build("demand",{"by":"wrath","demand":"submit"})
	var f:=Messages.forecast(first,menace)
	assert_float(float(f.chance)).is_greater(0.0)
	# Asking them to bow weighs more than asking for a modest tribute.
	assert_float(Messages.score(first,menace)).is_less(Messages.score(first,Messages.build("demand",{"by":"wrath","demand":"tribute","size":"modest"})))
	var result:=Messages.arrive(_mission(first,"demand",{"by":"wrath","demand":"submit"}),int(GameState.elapsed_days))
	if String(result.answer)=="comply":
		assert_bool(answer.is_tributary(first)).is_true()
		assert_bool(preload("res://scripts/trade_stances.gd").tribute(first,"player").is_empty()).is_false()
		assert_array(Messages.demands_for(first)).not_contains(["submit"])
