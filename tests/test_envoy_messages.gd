extends GdUnitTestSuite
## Messages of menace (scripts/envoy_messages.gd) and the send-envoys sheet
## (scripts/hud/envoy_dispatch_screen.gd): purposes and gift gating, the
## bounds and memory of threats, ultimatum deadlines and broken threats,
## rival weights (never pace), save round-trip, and the sheet's essentials.
## No live model: GameState.civic_api_enabled is false in the fixture.

const Messages:=preload("res://scripts/envoy_messages.gd")
const Screen:=preload("res://scripts/hud/envoy_dispatch_screen.gd")
const Fixture:=preload("res://tests/commitment_ui_probe.gd")
const Rivals:=preload("res://scripts/rival_rulers.gd")
const Divine:=preload("res://scripts/divine_regard.gd")

var first:=""

func before_test()->void:
	first=Fixture.build_fixture()
	GameState.civic_api_enabled=false

func id(index:int)->String: return String(CivilizationSystem.civilizations[index].id)

func _civ(civ_id:String)->Dictionary:
	for civ:Dictionary in CivilizationSystem.civilizations:
		if String(civ.id)==civ_id: return civ
	return {}

## Personality is derived from the world seed, so the tests move what the
## player can move: dread, the god's credibility, pledges, grudges, opinion.
func _timid(civ_id:String)->void:
	Divine.add_civ_dread(civ_id,0.4); Divine.add_civ_dread(civ_id,0.4)
	Messages.store()["credibility"]=0.9

func _proud(civ_id:String)->void:
	_civ(civ_id).player_relation.opinion=-0.9
	Rivals.grudge(civ_id,"old wrongs",1.2,"test_old")
	Messages.store()["credibility"]=0.15

func _boldest()->String:
	## Meet every people; the proudest ruler answers the harshest tests.
	var best:="";var bold:=-1.0
	for civ:Dictionary in CivilizationSystem.civilizations:
		civ.player_relation.contact_level=2; civ.player_relation.home_location_known=true
		civ.player_relation.home_position={"x":CivilizationSystem.player_world_origin.x+2,"z":CivilizationSystem.player_world_origin.y}
		var value:=float(Messages.standing(String(civ.id)).bold)
		if value>bold: bold=value; best=String(civ.id)
	return best

func _mission(civ_id:String,purpose:String,choice:Dictionary={})->Dictionary:
	var menace:=Messages.build(purpose,choice)
	if String(menace.get("demand",""))=="tribute": menace["tribute"]=Messages.tribute_terms(civ_id)
	return {"civ_id":civ_id,"purpose":purpose,"personnel":9,"depart_day":int(GameState.elapsed_days),"menace":menace}

func test_purposes_and_gift_gating()->void:
	for kind in ["goodwill","open_trade","non_aggression","send_aid","leader_parley","seek_peace","declare_war","warn","threaten","demand","ultimatum"]:
		assert_bool(kind in Messages.ORDER).is_true()
	assert_array(Messages.HOSTILE).is_equal(CivilizationSystem.HOSTILE_DIPLOMATIC_ACTIONS)
	# A gift only where it makes sense.
	assert_bool(Messages.allows_gift("goodwill","")).is_false()
	assert_bool(Messages.allows_gift("goodwill","Timber")).is_true()
	assert_bool(Messages.allows_gift("open_trade","")).is_true()
	assert_bool(Messages.allows_gift("send_aid","Timber")).is_false()
	for kind in Messages.HOSTILE+["declare_war","leader_parley"]:
		assert_bool(Messages.allows_gift(kind,"Food")).is_false()
	assert_bool(CivilizationSystem.diplomatic_mission_quote(first,"Food","threaten").has("error")).is_true()
	assert_bool(CivilizationSystem.diplomatic_mission_quote(first,"","threaten").has("error")).is_false()
	# Tokens: the terrible one only after real killing.
	assert_bool("raider_head" in Messages.tokens_for(first,"threaten")).is_false()
	assert_array(Messages.tokens_for(first,"goodwill")).is_empty()
	CivilizationSystem.war_history.push_front({"id":"war_t","participants":["player",first],"casualties":{"player":{"military_dead":2},first:{"military_dead":3}},"status":"ended"})
	assert_bool("raider_head" in Messages.tokens_for(first,"threaten")).is_true()
	# An apology needs a real wrong.
	assert_bool("apology" in Messages.demands_for(id(1))).is_false()
	assert_bool("apology" in Messages.demands_for(first)).is_true()

func test_threat_that_lands_changes_dread_grudge_and_memory()->void:
	_timid(first)
	var dread_before:=Divine.civ_dread(first)
	var mission:=_mission(first,"threaten",{"by":"wrath"})
	var result:=Messages.arrive(mission,int(GameState.elapsed_days))
	assert_str(String(result.answer)).is_equal("comply")
	assert_float(Divine.civ_dread(first)).is_greater(dread_before-0.0001)
	assert_float(Divine.civ_dread(first)).is_less_equal(1.0)
	assert_float(Rivals.grudge_weight(first)).is_greater(0.0)
	assert_str(Messages.stance(first)).is_equal("cowed")
	assert_bool(bool(mission.accepted)).is_true()
	var memories:Array=ForeignDiplomacy.leader(first).memories
	assert_str(String((memories[0] as Dictionary).text)).contains("gave way")
	# Cowed: fewer demands from them, more frightened tribute (weights only).
	assert_float(Messages.rival_weight("tribute_demand",first)).is_less(1.0)
	assert_float(Messages.rival_weight("dread_tribute",first)).is_greater(1.0)

func test_demanded_tribute_is_bounded_and_arrives_with_the_envoys()->void:
	_timid(first)
	var mission:=_mission(first,"demand",{"demand":"tribute","by":"wrath"})
	var terms:Dictionary=mission.menace.tribute
	assert_float(float(terms.amount)).is_between(1.0,150.0)
	var result:=Messages.arrive(mission,int(GameState.elapsed_days))
	assert_str(String(result.answer)).is_equal("comply")
	var carry:Dictionary=result.get("carry",{})
	assert_float(float(carry.get("amount",0.0))).is_less_equal(float(terms.amount)+0.001)
	var before:=preload("res://scripts/audience_hall.gd").player_stock(String(carry.get("resource","Food")))
	Messages.homecoming(mission,int(GameState.elapsed_days)+10)
	var after:=preload("res://scripts/audience_hall.gd").player_stock(String(carry.get("resource","Food")))
	assert_float(after-before).is_equal_approx(float(carry.get("amount",0.0)),0.51)
	# The answer joins the conversation with their ruler.
	var thread:Dictionary=WorldSimulation.dialogue.thread(first)
	assert_str(String((thread.messages as Array).back().role)).is_equal("assistant")
	# Homecoming is applied once.
	Messages.homecoming(mission,int(GameState.elapsed_days)+11)
	assert_float(preload("res://scripts/audience_hall.gd").player_stock(String(carry.get("resource","Food")))).is_equal_approx(after,0.01)

func test_proud_ruler_defies_or_harms_the_messenger_with_real_losses()->void:
	var target:=_boldest()
	assert_float(float(Messages.standing(target).bold)).is_greater(0.55)
	_proud(target)
	var answers:={}
	var harmed:={}
	for attempt in 40:
		GameState.elapsed_days=100+attempt
		(Messages.store().ultimatums as Array).clear()
		var mission:=_mission(target,"ultimatum",{"demand":"hostage","consequence":"war","deadline":91})
		var result:=Messages.arrive(mission,int(GameState.elapsed_days))
		answers[String(result.answer)]=true
		if String(result.answer)=="harm" and harmed.is_empty(): harmed={"mission":mission,"result":result}
	assert_bool(answers.has("comply")).is_false()
	assert_bool(answers.has("harm")).is_true()
	var result:Dictionary=harmed.result
	assert_int(int(result.killed)).is_between(1,8)
	var before:=int(GameState.population_total)
	Messages.homecoming(harmed.mission,int(GameState.elapsed_days)+5)
	assert_int(int(GameState.population_total)).is_less(before)
	assert_str(Messages.grievance(target)).is_not_empty()
	assert_str(String(harmed.mission.outcome)).contains("killed")

func test_ultimatum_broken_when_the_god_does_not_follow_through()->void:
	var target:=id(2)
	_proud(target)
	var mission:=_mission(target,"ultimatum",{"demand":"withdraw","consequence":"war","deadline":91})
	var day:=int(GameState.elapsed_days)
	var result:=Messages.arrive(mission,day)
	assert_str(String(result.answer)).is_not_equal("comply")
	var u:=Messages.open_ultimatum(target)
	assert_bool(u.is_empty()).is_false()
	assert_int(int(u.due)).is_equal(day+91)
	Messages.store()["credibility"]=0.6
	var credibility:=Messages.credibility()
	Messages.daily(int(u.due))
	assert_str(String(u.status)).is_equal("open")
	Messages.daily(int(u.due)+Messages.GRACE_DAYS)
	assert_str(String(u.status)).is_equal("broken")
	assert_float(Messages.credibility()).is_equal_approx(credibility-0.2,0.001)
	assert_str(Messages.stance(target)).is_equal("emboldened")
	assert_float(Messages.rival_weight("tribute_demand",target)).is_greater(1.0)
	# Broken threats weigh less next time.
	var weaker:=Messages.score(target,Messages.build("threaten",{}))
	Messages.store()["credibility"]=0.9
	assert_float(Messages.score(target,Messages.build("threaten",{}))).is_greater(weaker)

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
	# Closing the frontier needs no war: your people carry it out at the deadline.
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
	# Weights only: the kinds of visits the hall already schedules.
	for kind in ["gift_goods","trade_offer","news_report","first_contact"]:
		assert_float(Messages.rival_weight(kind,target)).is_equal(1.0)

func test_save_round_trip()->void:
	_timid(first)
	var result:=Messages.send(id(2),"ultimatum",{"demand":"withdraw","consequence":"war","deadline":182,"token":"broken_spear"})
	assert_bool(result.has("error")).is_false()
	assert_str(String(CivilizationSystem.diplomatic_mission.menace.purpose)).is_equal("ultimatum")
	Messages._open_ultimatum(first,{"deadline":91,"demand":"tribute","consequence":"sever"},int(GameState.elapsed_days))
	Messages._set_stance(first,"defiant")
	var hall:=ForeignDiplomacy.export_state()
	var world:=CivilizationSystem.export_state()
	assert_bool(Messages.valid_state(hall.audiences.menace)).is_true()
	assert_bool(ForeignDiplomacy.import_state(hall).has("error")).is_false()
	assert_bool(CivilizationSystem.import_state(world).has("error")).is_false()
	assert_str(String(CivilizationSystem.diplomatic_mission.menace.token)).is_equal("broken_spear")
	assert_bool(Messages.open_ultimatum(first).is_empty()).is_false()
	assert_str(Messages.stance(first)).is_equal("defiant")
	assert_bool(Messages.valid_state({"credibility":2.0})).is_false()
	assert_bool(Messages.valid_mission({"purpose":"goodwill"})).is_false()

func test_the_mission_returns_through_the_world_clock()->void:
	_timid(first)
	var result:=Messages.send(first,"threaten",{"by":"wrath"})
	assert_bool(result.has("error")).is_false()
	var mission:Dictionary=CivilizationSystem.diplomatic_mission
	GameState.elapsed_days=int(mission.arrival_day)
	CivilizationSystem._process_diplomatic_mission(int(GameState.elapsed_days))
	assert_bool(CivilizationSystem.diplomatic_mission.menace.has("result")).is_true()
	GameState.elapsed_days=int(CivilizationSystem.diplomatic_mission.return_day)
	CivilizationSystem._process_diplomatic_mission(int(GameState.elapsed_days))
	assert_bool(CivilizationSystem.diplomatic_mission.is_empty()).is_true()
	var record:Dictionary=CivilizationSystem.diplomatic_history[0]
	assert_str(String(record.purpose)).is_equal("threaten")
	assert_str(String(record.outcome)).contains("answered")

func test_live_voice_is_validated_and_bounded()->void:
	_timid(first)
	var mission:=_mission(first,"threaten",{"words":"Tell them the god is furious and they must stay away from our herds."})
	Messages.arrive(mission,int(GameState.elapsed_days))
	assert_bool(Messages.accept_voice(mission,{"envoy_words":"x".repeat(700),"reply":"Fine."})).is_false()
	assert_bool(Messages.accept_voice(mission,{"envoy_words":"Our god is angry. Keep away from our animals.","reply":"Press the button in the game system."})).is_false()
	assert_bool(Messages.accept_voice(mission,{"envoy_words":"Our god is angry. Keep away from our animals.","reply":"We hear you. Our people will keep away."})).is_true()
	assert_str(String(mission.outcome)).contains("We hear you")

func test_sheet_essentials_are_reachable()->void:
	assert_str(Screen.about(17308.4)).is_equal("17,300")
	assert_str(Screen.about(32.1)).is_equal("30")
	var screen:Control=auto_free(Screen.new())
	screen.set("civ_id",first)
	add_child(screen)
	await await_idle_frame()
	assert_str((screen.find_child("Title",true,false) as Label).text).is_equal("Send a messenger")
	# Purpose first: nothing is chosen and nothing can leave yet.
	assert_str(screen.purpose).is_equal("")
	assert_bool(screen.send_button.disabled).is_true()
	assert_object(screen.find_child("Gifts",true,false)).is_null()
	assert_int(screen.people_box.get_child_count()).is_equal(3)
	for kind in Messages.ORDER: assert_object(screen.find_child("Purpose_"+kind,true,false)).is_not_null()
	screen.choose("threaten")
	assert_object(screen.find_child("Gifts",true,false)).is_null()
	assert_object(screen.find_child("Tokens",true,false)).is_not_null()
	assert_object(screen.find_child("Words",true,false)).is_not_null()
	screen.choose("goodwill")
	assert_object(screen.find_child("Gifts",true,false)).is_not_null()
	screen.choose("ultimatum")
	for part in ["Demands","Deadline","Consequence","Tokens","Words"]: assert_object(screen.find_child(part,true,false)).is_not_null()
	screen.pick_demand("hostage"); screen.pick_consequence("sever"); screen.pick_deadline("365")
	# Plain words: no ledger capitals, no raw decimals.
	var all:=""
	for label in screen.find_children("*","Label",true,false): all+=(label as Label).text+"\n"
	assert_str(all).not_contains("AVAILABLE")
	assert_str(all).not_contains("BLOCKED")
	var decimals:=RegEx.new();decimals.compile("\\d\\.\\d")
	assert_object(decimals.search(all)).is_null()
	for button in screen.find_children("*","Button",true,false):
		var text:=(button as Button).text
		if text.length()>3: assert_bool(text==text.to_upper()).is_false()
	var view:=screen.get_viewport_rect()
	assert_bool(view.encloses(screen.card.get_global_rect())).is_true()
	var sent:Dictionary=screen.send()
	assert_bool(sent.has("error")).is_false()
	assert_str(String(CivilizationSystem.diplomatic_mission.menace.demand)).is_equal("hostage")
	assert_int(int(CivilizationSystem.diplomatic_mission.menace.deadline)).is_equal(365)
	assert_object(screen.find_child("Away",true,false)).is_not_null()
