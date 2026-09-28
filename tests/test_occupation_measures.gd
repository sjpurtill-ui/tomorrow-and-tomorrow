extends GdUnitTestSuite
## What our garrison does with the people of a town we hold
## (occupation_measures.gd), read from the god's words on both paths (the
## offline regex reading and the live order reader, stubbed here: no network,
## no real key).
##
## The user's court, September 27: Tsaren held by 16 of Rovik's band, the god
## before Kishan of Reedwater, Headman of Seanstone: "Round up all the men of
## Tsaren and tie them up. If any resist or attempt to flee, threaten their
## wives and children." The court answered "Tsaren is already ours; 16 of
## Rovik's garrison hold it. What shall become of the town and its people?"
## with "Tsaren is already ours." again underneath, and the same again when
## the order was repeated.

const CC:=preload("res://scripts/court_commands.gd")
const WO:=preload("res://scripts/court_war_orders.gd")
const OR:=preload("res://scripts/order_reader.gd")
const M:=preload("res://scripts/occupation_measures.gd")
const Held:=preload("res://scripts/held_town.gd")
const HeldDossier:=preload("res://scripts/hud/held_town_dossier.gd")
const Route:=preload("res://scripts/army_land_route.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const AiMode:=preload("res://scripts/ai_mode.gd")
const Voice:=preload("res://scripts/audience_voice.gd")
const Divine:=preload("res://scripts/divine_regard.gd")
const Governance:=preload("res://scripts/occupation_governance.gd")
const CV:=preload("res://scripts/character_voice.gd")
const PlainSpeech:=preload("res://scripts/plain_speech.gd")
const Marks:=preload("res://scripts/hud/army_marks.gd")
const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")
const Ledger:=preload("res://scripts/town_ledger.gd")

const USERS_SENTENCE:="Round up all the men of Tsaren and tie them up. If any resist or attempt to flee, threaten their wives and children."
const SECRET:="sk-test-DO-NOT-LOG-0123456789"
const COVERAGE_PATH:="res://tests/fixtures/occupation_orders_coverage.json"

var home:=Vector2.ZERO
var city:=Vector2.ZERO
var city_id:=""
var civ_id:=""
var voice:Node
var _processing:Dictionary={}

func _land(_p:Vector2)->bool:
	return true

func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]: _processing[node]=node.is_processing()
	AiMode.reset_for_tests("user://__occupation_measures_test_missing.cfg")
	OS.unset_environment("LEVIATHAN_AI_READER_MODEL")
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();ForeignDiplomacy.ensure();GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(900);GameState.housing_capacity=1000
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.select_founding_focus("provision")
	GameState.settlement_name="Seanstone"
	GameState.society_capacities["institutions"]=0.4
	GovernmentPeopleSystem._update_government_stage(false)
	GovernmentPeopleSystem.initialize()
	GameState.resource_stockpiles["Food"]=1000000.0
	GameState.elapsed_days=88*365
	Route.clear_cache()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ["name"]="Esurai"
	civ_id=String(civ.id)
	var relation:Dictionary=civ.player_relation
	relation.at_war=true; relation.contact_level=2; relation.home_location_known=true
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	region["name"]="Tsaren"
	region["population"]=300.0
	city_id=String(region.id)
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",city_id,.8,int(GameState.elapsed_days),"scout report","test"),int(GameState.elapsed_days))
	home=CivilizationSystem.player_world_origin
	city=home+Vector2(-20.0,8.0)
	CivilizationSystem.city_intelligence.records.player[city_id]["position"]={"x":city.x,"z":city.y}
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))
	if voice==null or not is_instance_valid(voice):
		voice=Voice.new()
		add_child(voice)
	voice.force_offline=false
	voice.config_override={"endpoint":"https://mock.invalid/v1/chat/completions","api_key":SECRET,"model":"mock-voice","structured_output":true}
	voice.usage.clear(); voice.last_problem.clear()

func after_test()->void:
	CivilizationSystem.set_scout_geography_authority(Callable())
	Route.clear_cache()
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	ProgressionSystem.reset_for_new_world()
	WorldSimulation.clear()
	for node:Node in _processing: node.set_process(bool(_processing[node]))
	OS.unset_environment("LEVIATHAN_AI_READER_MODEL")
	AiMode.reset_for_tests(AiMode.SETTINGS_PATH)

func after()->void:
	if voice!=null and is_instance_valid(voice): voice.free()

# --------------------------------------------------------------------------
# Fixtures
# --------------------------------------------------------------------------

func _train(count:int)->void:
	MilitaryCampaign.military_inventory["improvised"]=int(MilitaryCampaign.military_inventory.get("improvised",0))+count
	MilitaryCampaign.raise_recruits(count)
	MilitaryCampaign.start_training("levy","improvised",count)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()

## Tsaren taken; about 17 of the band hold it, one fighter stays with the band.
func _captured_tsaren(troops:int=18)->void:
	_train(troops)
	var made:=MilitaryCampaign.create_field_army(troops,"LEVY BAND %d" % (MilitaryCampaign.field_armies.size()+1))
	assert_bool(made.has("error")).override_failure_message(str(made)).is_false()
	var army_id:=int((made.army as Dictionary).army_id)
	var army:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(army_id)]
	army["supply_level"]=1.0; army["readiness"]=1.0
	army["position"]={"x":city.x+0.3,"z":city.y}
	army["location_id"]=city_id; army["location_name"]="Tsaren"; army["status"]="stationed"
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var ri:=CivilizationSystem._region_index(civ,city_id)
	civ.strategic_regions[ri]["controller"]="player"
	# A town just taken resents it (civilization_system: 0.38 + cohesion x 0.3).
	civ.strategic_regions[ri]["resistance"]=0.6
	if float(civ.strategic_regions[ri].get("population",0.0))<150.0: civ.strategic_regions[ri]["population"]=300.0
	var garrison:=MilitaryCampaign.establish_occupation_force(civ_id,civ.strategic_regions[ri],float(troops-1),army_id)
	assert_int(int(garrison.get("troops",0))).override_failure_message(str(garrison)).is_greater(0)

## A row that gave the town up: take it back for the next row.
func _retake_if_lost(troops:int=18)->void:
	if not WO.held_towns().is_empty(): return
	_captured_tsaren(troops)

func _headman()->Dictionary:
	var headman:=GovernmentPeopleSystem.officeholder("Steward")
	if headman.is_empty():
		for person in Hall._officials():
			if String(person.get("office_key",""))!="Marshal": headman=person; break
	assert_dict(headman).is_not_empty()
	return headman

func _audience(person:Dictionary)->String:
	var audience:=Hall.summon({"person_id":int(person.person_id)})
	assert_dict(audience).is_not_empty()
	return String(audience.id)

func _officials()->Array:
	var ids:Array=[]
	for p in Hall._officials(): ids.append(int(p.person_id))
	ids.sort()
	return ids

func _region()->Dictionary:
	return CivilizationSystem.region_snapshot(civ_id,city_id)

func _force()->Dictionary:
	return MilitaryCampaign.occupation_force_for_region(civ_id,city_id)

func _reading(kind:String,action:String,ttype:String,ref:String,confidence:float=0.95,details:Dictionary={},clarify:String="")->Dictionary:
	var d:={"kill_men":false,"kill_all":false,"captives":false,"raze":false,"tribute":false,"spare":false,"hold":false,"leave":false,"free":false,"full_force":false,"count":0,"resource":"","destination":"","measures":[],"stance":""}
	d.merge(details,true)
	return {"kind":kind,"action":action,"actor":"","target":{"type":ttype,"ref":ref},"details":d,"confidence":confidence,"clarify":clarify}

func _body(reading:Dictionary)->PackedByteArray:
	return JSON.stringify({"model":"mock-reader","choices":[{"finish_reason":"stop","message":{"content":JSON.stringify(reading)}}],"usage":{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15}}).to_utf8_buffer()

## The modal's live path without the UI: read (stubbed), decide, carry out.
func _say(id:String,text:String,reading:Dictionary)->Dictionary:
	var sent:=[]
	voice.order_hook=func(_aid:String,payload:Dictionary)->PackedByteArray:
		sent.append(payload)
		return _body(reading) if not reading.is_empty() else PackedByteArray()
	var got:=[{}]
	var started:bool=voice.read_order(id,text,func(read:Dictionary)->void: got[0]=read)
	assert_bool(started).is_true()
	var read:Dictionary=got[0]
	var plan:Dictionary=OR.decide(id,text,read.reading) if read.has("reading") else OR.offline_confirm(id,text)
	if plan.is_empty(): plan={"route":"legacy"}
	var done:=OR.carry_out(id,text,plan,{})
	return {"read":read,"plan":plan,"done":done,"result":done.get("result",{}),"payload":sent[0] if not sent.is_empty() else {}}

func _nobody_here_harmed(r:Dictionary,words:String,before:Array,headman:Dictionary)->void:
	var said:="%s -> stage %s, target %s: %s %s" % [words,String(r.get("stage","")),String(r.get("target_name","")),String(r.get("actor_says","")),String(r.get("outcome",""))]
	assert_bool(bool(r.get("removed",false))).override_failure_message(said).is_false()
	assert_str(String(r.get("target_name",""))).override_failure_message(said).is_not_equal(String(headman.name))
	assert_array(_officials()).override_failure_message(said).is_equal(before)

func _entries(prefix:String)->Array:
	return (GameState.chronicle.get("entries",[]) as Array).filter(func(e:Dictionary)->bool: return String(e.get("key","")).begins_with(prefix))

## Every word a rendered control shows.
func _texts(node:Node)->String:
	var out:PackedStringArray=[]
	if node is Label: out.append((node as Label).text)
	for child in node.get_children(): out.append(_texts(child))
	return "\n".join(out)

## Days pass for the garrison's measures (as court_war_orders.daily does).
func _days(n:int)->Array:
	var filed:Array=[]
	for i in n:
		GameState.elapsed_days+=1
		filed.append_array(M.daily(int(GameState.elapsed_days)))
	return filed

# --------------------------------------------------------------------------
# The user's own words, on both paths
# --------------------------------------------------------------------------

func test_the_users_sentence_binds_the_men_under_a_harsh_hand()->void:
	_captured_tsaren()
	var headman:=_headman()
	var before:=_officials()
	var id:=_audience(headman)
	var resistance_before:=float(_region().get("resistance",0.5))
	var grievance_before:=float(Governance.state(_region()).grievance)
	var dread_before:=Divine.civ_dread(civ_id)
	var fear_before:=float(MilitaryCampaign.war_reputation.get("fear",0.0))
	var r:=CC.hear(id,USERS_SENTENCE)
	_nobody_here_harmed(r,USERS_SENTENCE,before,headman)
	assert_str(String(r.get("verb",""))).is_equal("war")
	assert_str(String(r.war.kind)).is_equal("measure")
	assert_str(String(r.war.verdict)).override_failure_message(String(r.get("actor_says",""))).is_equal("fate")
	assert_bool(bool(r.executed)).is_true()
	var o:Dictionary=r.objective
	assert_array(o.measures as Array).contains(["bind_men"])
	assert_str(String(o.stance)).is_equal("harsh")
	# Bounded by the men there are and the guards the garrison can spare.
	var bound:=int(o.bound)
	var men:=roundi(300.0*M.MEN_SHARE)
	assert_int(bound).is_greater(0)
	assert_int(bound).is_less_equal(men)
	var garrison:=int(_force().troops)
	assert_int(bound).is_less_equal((garrison-maxi(M.KEEP_AT_LEAST,ceili(float(garrison)*M.KEEP_SHARE)))*M.BOUND_PER_GUARD)
	assert_int(M.men_bound(civ_id,city_id)).is_equal(bound)
	# A harsh hand: few got away (each man's chance is stated: about 1 in 10),
	# and they are on the town's ledger, running, for a chase.
	assert_int(int(o.fled)).is_less_equal(roundi(float(men)*M.ROUND_UP_FLIGHT*float(M.STANCES.harsh.escape)*2.0)+3)
	if int(o.fled)>0:
		assert_dict(preload("res://scripts/pursuit.gd").latest_flight(city_id)).is_not_empty()
		assert_int(int(Ledger.running(Ledger.of(civ_id,city_id)).count)).is_equal(int(o.fled))
	assert_bool(bool(Ledger.check(civ_id,city_id).ok)).override_failure_message(str(Ledger.check(civ_id,city_id))).is_true()
	# The war leader says what was done, with the numbers, and the threat.
	var says:=String(r.actor_says)
	assert_str(says).not_contains("already ours")
	assert_str(says).contains("house to house")
	assert_str(says).contains(str(bound) if bound>12 else "")
	assert_str(says).contains("his wife and children will answer for it")
	assert_str(String(r.outcome)).is_not_equal("Tsaren is already ours.")
	assert_str(String(r.outcome)).contains("men bound and under guard")
	# Real consequences, bounded: resistance down and held down, grievance
	# and dread up, our name for fear.
	var region:=_region()
	assert_float(float(region.resistance)).is_less(resistance_before)
	assert_float(float(region.resistance)).is_less_equal(0.35)
	assert_float(float(Governance.state(region).grievance)).is_greater(grievance_before)
	assert_array(Governance.validate(region)).is_empty()
	assert_float(Divine.civ_dread(civ_id)).is_greater(dread_before)
	assert_float(float(MilitaryCampaign.war_reputation.get("fear",0.0))).is_greater(fear_before)
	# The garrison's card and the Chronicle, once.
	assert_str(String(_force().get("fate_note",""))).is_equal("Men bound and under guard · %d" % bound)
	assert_int(_entries("measures:").size()).is_equal(1)

func test_the_users_sentence_on_the_reader_path()->void:
	_captured_tsaren()
	var headman:=_headman()
	var before:=_officials()
	var id:=_audience(headman)
	var out:=_say(id,USERS_SENTENCE,_reading("order","town_measure","town","town:"+city_id,0.92,{"measures":["bind_men"],"stance":"harsh"}))
	assert_str(String(out.plan.route)).is_equal("engine")
	var r:Dictionary=out.result
	_nobody_here_harmed(r,USERS_SENTENCE,before,headman)
	assert_str(String(r.war.verdict)).override_failure_message(String(r.get("actor_says",""))).is_equal("fate")
	assert_array(r.objective.measures as Array).contains(["bind_men"])
	assert_str(String(r.objective.stance)).is_equal("harsh")
	assert_str(String(r.actor_says)).contains("his wife and children will answer for it")
	assert_str(String(r.actor_says)).not_contains("already ours")
	# The schema offers only the measures and stances there are (the reading
	# is flat: measures and stance sit beside the action).
	var props:Dictionary=out.payload.response_format.json_schema.schema.properties
	assert_array(props.measures.items.enum as Array).contains(["bind_men","hostages","curfew","release","settle"])
	assert_array(props.stance.enum as Array).is_equal(["","lenient","firm","harsh","brutal"])

func test_an_older_reading_of_town_fate_with_nothing_decided_is_never_already_ours()->void:
	# The reader said town_fate with no flags (as the user's build would):
	# the words are read for what the garrison is to do, not answered with
	# "Tsaren is already ours" and a question.
	_captured_tsaren()
	var id:=_audience(_headman())
	var out:=_say(id,USERS_SENTENCE,_reading("order","town_fate","town","town:"+city_id,0.9))
	var r:Dictionary=out.result
	assert_str(String(r.war.verdict)).override_failure_message(String(r.get("actor_says",""))).is_equal("fate")
	assert_array(r.objective.measures as Array).contains(["bind_men"])
	assert_str(String(r.actor_says)).not_contains("already ours")

func test_a_measure_id_or_stance_outside_the_lists_is_rejected()->void:
	_captured_tsaren()
	var headman:=_headman()
	var before:=_officials()
	var id:=_audience(headman)
	for bad:Dictionary in [_reading("order","town_measure","town","town:"+city_id,0.95,{"measures":["flay_them"]}),
			_reading("order","town_measure","town","town:"+city_id,0.95,{"measures":["bind_men"],"stance":"merciless"})]:
		var out:=_say(id,USERS_SENTENCE,bad)
		assert_dict(out.read as Dictionary).override_failure_message(str(bad)).is_empty()
		assert_str(String(out.plan.route)).is_equal("legacy")
		assert_str(String(voice.last_problem.get(id,""))).contains("rejected")
	assert_array(_officials()).is_equal(before)
	assert_int(M.active(civ_id,city_id).size()).is_equal(0)

# --------------------------------------------------------------------------
# Never the same question twice
# --------------------------------------------------------------------------

func test_the_same_order_twice_gets_a_different_answer_and_no_question()->void:
	_captured_tsaren()
	var id:=_audience(_headman())
	var first:=CC.hear(id,USERS_SENTENCE)
	var bound:=int(first.objective.bound)
	var second:=CC.hear(id,USERS_SENTENCE)
	assert_str(String(second.war.verdict)).is_equal("fate")
	assert_str(String(second.actor_says)).is_not_equal(String(first.actor_says))
	assert_str(String(second.actor_says)).contains("already bound")
	assert_str(String(second.actor_says)).not_contains("?")
	assert_array(second.objective.renewed as Array).contains(["bind_men"])
	# No second round-up: the same men, the same guard.
	assert_int(M.men_bound(civ_id,city_id)).is_equal(bound)
	assert_int(M.active(civ_id,city_id).filter(func(m:Dictionary)->bool: return String(m.id)=="bind_men").size()).is_equal(1)

func test_an_attack_on_the_held_town_is_told_three_ways()->void:
	_captured_tsaren()
	var id:=_audience(_headman())
	var said:Array=[]
	for i in 3:
		var r:=CC.hear(id,"Attack Tsaren")
		assert_str(String(r.war.verdict)).is_equal("held")
		assert_str(String(r.actor_says)).contains("Tsaren is already ours")
		assert_bool(said.has(String(r.actor_says))).override_failure_message(String(r.actor_says)).is_false()
		said.append(String(r.actor_says))
	# Orders that are not attacks are never answered "it is already ours".
	for words in ["Round up the men of Tsaren","Take the weapons of Tsaren","Make the men of Tsaren work","Deal with the people of Tsaren","Punish the people of Tsaren"]:
		var r:=CC.hear(id,words)
		assert_str(String(r.get("actor_says",""))).override_failure_message(words).not_contains("already ours")
		assert_str(String(r.war.verdict)).override_failure_message(words).is_not_equal("held")

func test_a_grave_unclear_order_is_asked_once_then_his_reading_is_done()->void:
	_captured_tsaren()
	var headman:=_headman()
	var before:=_officials()
	var id:=_audience(headman)
	var population:=float(_region().population)
	var asked:=CC.hear(id,"Punish the people of Tsaren")
	assert_str(String(asked.war.verdict)).is_equal("ask")
	assert_str(String(asked.actor_says)).contains("What shall we do in Tsaren")
	assert_str(String(asked.actor_says)).contains("bind the men and keep them under guard")
	assert_str(String(asked.actor_says)).contains("take hostages from their leading families")
	assert_float(float(_region().population)).is_equal(population)
	assert_int(M.active(civ_id,city_id).size()).is_equal(0)
	# Said again, unanswered: his own nearest reading, not the question again.
	var again:=CC.hear(id,"Punish the people of Tsaren")
	_nobody_here_harmed(again,"punish again",before,headman)
	assert_str(String(again.war.verdict)).override_failure_message(String(again.actor_says)).is_equal("fate")
	assert_str(String(again.actor_says)).not_contains("What shall we do")
	assert_array(again.objective.measures as Array).contains(["execute_ringleaders"])
	# Bounded: a handful, never the town.
	var dead:=roundi(population-float(_region().population))
	assert_int(dead).is_between(1,6)

func test_an_unparsed_answer_to_his_question_is_his_nearest_reading()->void:
	_captured_tsaren()
	var id:=_audience(_headman())
	var asked:=CC.hear(id,"Destroy Tsaren")
	assert_str(String(asked.war.verdict)).is_equal("ask")
	assert_str(String(asked.actor_says)).contains("burn it and drive its people out")
	# "The second one" picks that choice.
	var picked:=CC.hear(id,"the third one")
	assert_str(String(picked.war.verdict)).override_failure_message(String(picked.get("actor_says",""))).is_equal("fate")
	assert_array(picked.objective.measures as Array).contains(["bind_men"])
	# In another court, answered with words that decide nothing: the first choice.
	after_test(); before_test()
	_captured_tsaren()
	var id2:=_audience(_headman())
	assert_str(String(CC.hear(id2,"Destroy Tsaren").war.verdict)).is_equal("ask")
	var vague:=CC.hear(id2,"whatever you judge best")
	assert_str(String(vague.war.verdict)).override_failure_message(String(vague.get("actor_says",""))).is_equal("fate")
	assert_bool(bool(vague.objective.burned)).is_true()
	assert_array(WO.held_towns()).is_empty()

func test_asked_which_town_twice_he_takes_the_one_spoken_of()->void:
	_captured_tsaren()
	# A second town of theirs, held too.
	_train(12)
	var made:=MilitaryCampaign.create_field_army(12,"LEVY BAND 2")
	var army_id:=int((made.army as Dictionary).army_id)
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var other:Dictionary={}
	for r:Dictionary in civ.strategic_regions:
		if String(r.id)!=city_id: other=r; break
	other["name"]="Varo"; other["population"]=120.0; other["controller"]="player"; other["settlement_founded"]=true
	MilitaryCampaign.establish_occupation_force(civ_id,other,8.0,army_id)
	assert_int(WO.held_towns().size()).is_equal(2)
	var id:=_audience(_headman())
	var ask:=CC.hear(id,"Round up the men and tie them up")
	assert_str(String(ask.war.verdict)).is_equal("ask")
	assert_str(String(ask.actor_says)).contains("Which town")
	var again:=CC.hear(id,"Round up the men and tie them up")
	assert_str(String(again.war.verdict)).override_failure_message(String(again.get("actor_says",""))).is_equal("fate")
	assert_str(String(again.actor_says)).contains("You have not named the town")
	assert_str(String(again.actor_says)).not_contains("Which town")

func test_the_reader_does_not_ask_the_same_question_twice()->void:
	_captured_tsaren()
	var headman:=_headman()
	var before:=_officials()
	var id:=_audience(headman)
	var first:=_say(id,"deal with Tsaren's men",_reading("order","town_fate","group","town:"+city_id,0.5,{"kill_men":true},"Do you mean every man in Tsaren put to death?"))
	assert_str(String(first.plan.route)).is_equal("clarify")
	var lines_before:=(Hall.find(id).lines as Array).size()
	# Another unclear answer: the reading asked about is taken, not asked again.
	var second:=_say(id,"you know what I mean",_reading("order","town_fate","group","town:"+city_id,0.45,{"kill_men":true},"Do you mean every man in Tsaren put to death?"))
	assert_str(String(second.plan.route)).is_equal("engine")
	var r:Dictionary=second.result
	_nobody_here_harmed(r,"second answer",before,headman)
	assert_str(String(r.war.verdict)).is_equal("fate")
	for line:Dictionary in (Hall.find(id).lines as Array).slice(lines_before):
		assert_str(String(line.text)).is_not_equal("Do you mean every man in Tsaren put to death?")

# --------------------------------------------------------------------------
# The measures themselves
# --------------------------------------------------------------------------

func test_each_measure_is_bounded_and_runs_its_days()->void:
	_captured_tsaren()
	var day:=int(GameState.elapsed_days)
	var general:=WO.war_leader()
	for id:String in ["bind_men","disarm","hostages","curfew","search","labour","requisition","conscript","execute_ringleaders","relief","set_headman","settle"]:
		var population:=float(_region().population)
		var done:=M.apply(civ_id,city_id,[id],{"words":"test"},general)
		assert_bool(done.has("error")).override_failure_message("%s: %s" % [id,str(done)]).is_false()
		assert_str(String(done.text)).is_not_empty()
		assert_bool(PlainSpeech.is_maxim(String(done.text))).override_failure_message(String(done.text)).is_false()
		var region:=_region()
		assert_float(float(region.resistance)).is_between(0.01,1.0)
		assert_array(Governance.validate(region)).override_failure_message(id).is_empty()
		assert_float(float(CivilizationSystem.civilizations[0].player_relation.get("opinion",0.0))).is_between(-1.0,1.0)
		for key in ["mercy","fear","grievance"]: assert_float(float(MilitaryCampaign.war_reputation.get(key,0.0))).is_between(0.0,1.0)
		if (done.applied as Array).has(id):
			var record:Dictionary=M.active(civ_id,city_id).filter(func(m:Dictionary)->bool: return String(m.id)==id)[0]
			assert_int(int(record.until)).override_failure_message(id).is_equal(day+int((M.CATALOGUE[id] as Dictionary).days))
		match id:
			"bind_men": assert_int(int(done.bound)).is_less_equal(roundi(population*M.MEN_SHARE))
			"hostages": assert_int(int(done.hostages)).is_between(1,20)
			"conscript": assert_int(int(done.get("conscripts",0))).is_less_equal(40)
			"execute_ringleaders": assert_int(roundi(population-float(_region().population))).is_between(1,6)
			"requisition": assert_int(int(done.get("food",0))).is_less_equal(int(_force().troops)*50)
			"relief": assert_int(int(done.get("food_given",0))).is_less_equal(400)
			"settle": assert_int(int(done.get("settlers",0))).is_between(1,60)
	# The guards they take never exceed the garrison less its gate watch.
	var guards:=0
	for m:Dictionary in M.active(civ_id,city_id): guards+=int(m.get("guards",0))
	var garrison:=int(_force().troops)
	assert_int(guards).is_less_equal(garrison-maxi(M.KEEP_AT_LEAST,ceili(float(garrison)*M.KEEP_SHARE)))
	# The card shows the most pressing one; the report lists them all.
	assert_bool(String(_force().fate_note).begins_with("Men bound and under guard · ")).override_failure_message(String(_force().fate_note)).is_true()
	assert_int((Held.report(city_id).measures as Array).size()).is_equal(M.active(civ_id,city_id).size())
	# Days pass: each ends when its days are up, and the ones that held
	# people are reported once.
	var filed:=_days(21)
	assert_bool(M.active(civ_id,city_id).any(func(m:Dictionary)->bool: return String(m.id)=="curfew")).is_false()
	assert_bool(M.active(civ_id,city_id).any(func(m:Dictionary)->bool: return String(m.id)=="bind_men")).is_true()
	filed.append_array(_days(10))
	assert_bool(M.active(civ_id,city_id).any(func(m:Dictionary)->bool: return String(m.id)=="bind_men")).is_false()
	assert_bool(M.active(civ_id,city_id).any(func(m:Dictionary)->bool: return String(m.id)=="hostages")).is_true()
	assert_int(_entries("measure_ended:%s:bind_men" % city_id).size()).is_equal(1)
	assert_bool(filed.size()>=1).is_true()
	# Labour raised the town's defences, bounded.
	assert_float(float(_region().get("fortification",0.0))).is_less_equal(1.0)

func test_a_harsh_hand_costs_more_and_loses_fewer_than_a_gentle_one()->void:
	var results:={}
	for stance in ["harsh","lenient"]:
		after_test(); before_test()
		_captured_tsaren()
		var grievance:=float(Governance.state(_region()).grievance)
		var dread:=Divine.civ_dread(civ_id)
		var done:=M.apply(civ_id,city_id,["bind_men"],{"stance":stance,"stance_set":true,"families":stance=="harsh","words":"round up the men"},WO.war_leader())
		results[stance]={"fled":int(done.fled),"grievance":float(Governance.state(_region()).grievance)-grievance,"dread":Divine.civ_dread(civ_id)-dread,"bound":int(done.bound)}
	var harsh:Dictionary=results.harsh; var soft:Dictionary=results.lenient
	assert_int(int(harsh.fled)).is_less(int(soft.fled))
	assert_float(float(harsh.grievance)).is_greater(float(soft.grievance))
	assert_float(float(harsh.dread)).is_greater(float(soft.dread))
	assert_float(float((M.STANCES.harsh as Dictionary).incident)).is_greater(float((M.STANCES.lenient as Dictionary).incident))

func test_freeing_them_undoes_the_binding()->void:
	_captured_tsaren()
	var id:=_audience(_headman())
	CC.hear(id,USERS_SENTENCE)
	assert_int(M.men_bound(civ_id,city_id)).is_greater(0)
	var held_down:=float(_region().resistance)
	var r:=CC.hear(id,"Free them")
	assert_str(String(r.war.verdict)).is_equal("fate")
	assert_array(r.objective.freed as Array).contains(["bind_men"])
	assert_str(String(r.actor_says)).contains("untied")
	assert_int(M.men_bound(civ_id,city_id)).is_equal(0)
	assert_str(String(_force().get("fate_note",""))).not_contains("bound")
	assert_float(float(_region().resistance)).is_greater(held_down)
	var lines:Array=Held.report(city_id).measures
	assert_bool(lines.any(func(l:Dictionary)->bool: return String(l.id)=="bind_men")).is_false()
	# Nothing left to free: said plainly, nothing changed.
	var none:=CC.hear(id,"Free them")
	assert_str(String(none.actor_says)).contains("no one to free")

func test_the_report_and_the_card_show_what_is_in_force()->void:
	_captured_tsaren()
	var id:=_audience(_headman())
	CC.hear(id,USERS_SENTENCE)
	var bound:=M.men_bound(civ_id,city_id)
	# The garrison's card on the map (war_front_overlay reads the force note).
	var garrisons:=Overlay._garrison_inputs()
	var marks:=Overlay._marks({"stage":"hearth","garrisons":garrisons},[],[],{"clashes":[],"sieges":[]})
	var held:Array=marks.filter(func(m:Dictionary)->bool: return bool(m.get("garrison",false)))
	var card:=Marks.card_garrison(held[0])
	assert_str(card[2]).is_equal("Men bound and under guard · %d" % bound)
	CC.hear(id,"Take their weapons and burn them")
	CC.hear(id,"Take hostages from their leading families")
	assert_str(String(_force().fate_note)).is_equal("Men bound and under guard · %d · 2 more" % bound)
	# The held-town report and its dossier.
	var report:=Held.report(city_id)
	var labels:Array=(report.measures as Array).map(func(l:Dictionary)->String: return String(l.label))
	assert_array(labels).contains(["Men bound and under guard","Hostages held","Disarmed"])
	var dossier:Control=auto_free(HeldDossier.new())
	add_child(dossier)
	dossier.setup({"report":report,"caption":"Ours · taken from the Esurai"})
	var text:=_texts(dossier)
	assert_str(text).contains("UNDER OUR GARRISON'S ORDERS")
	assert_str(text).contains("%d men are bound and kept under guard" % bound if bound>12 else "men are bound and kept under guard")
	assert_str(text).not_contains("Nothing has been done to its people")

func test_the_chronicle_tells_a_measure_once_and_an_incident_once()->void:
	_captured_tsaren()
	var id:=_audience(_headman())
	CC.hear(id,USERS_SENTENCE)
	CC.hear(id,USERS_SENTENCE)
	_days(1)
	CC.hear(id,"Chain the men of Tsaren")
	assert_int(_entries("measures:").size()).is_equal(1)
	# An incident under the harsh hand is reported once, by the war leader.
	var record:Dictionary=M.active(civ_id,city_id).filter(func(m:Dictionary)->bool: return String(m.id)=="bind_men")[0]
	record["incident"]={"day":int(GameState.elapsed_days)+1,"done":false}
	var filed:=_days(1)
	assert_int(filed.size()).is_equal(1)
	assert_int(_entries("measure_incident:").size()).is_equal(1)
	var told:=String(_entries("measure_incident:")[0].text)
	assert_str(told).contains("wife and children")
	for gore in ["blood","throat","skull","entrails"]: assert_str(told.to_lower()).not_contains(gore)
	assert_int(_days(3).size()).is_equal(0)
	assert_int(_entries("measure_incident:").size()).is_equal(1)

func test_strengthening_the_garrison_keeps_its_orders()->void:
	_captured_tsaren()
	var id:=_audience(_headman())
	CC.hear(id,USERS_SENTENCE)
	var bound:=M.men_bound(civ_id,city_id)
	# A band of ours standing at the town joins the garrison.
	_train(10)
	var made:=MilitaryCampaign.create_field_army(10,"LEVY BAND 3")
	var army:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(int((made.army as Dictionary).army_id))]
	army["position"]={"x":city.x+0.2,"z":city.y}; army["location_id"]=city_id; army["status"]="stationed"
	army["supply_level"]=1.0; army["readiness"]=1.0
	var before:=int(_force().troops)
	var r:=CC.hear(id,"Strengthen the garrison at Tsaren")
	assert_int(int(_force().troops)).override_failure_message(String(r.get("actor_says",""))).is_greater(before)
	assert_int(M.men_bound(civ_id,city_id)).is_equal(bound)
	assert_str(String(_force().get("fate_note",""))).is_equal("Men bound and under guard · %d" % bound)

func test_bound_men_cannot_run_when_they_are_put_to_death()->void:
	_captured_tsaren()
	var id:=_audience(_headman())
	CC.hear(id,"Round up the men of Tsaren and bind them")
	var bound:=M.men_bound(civ_id,city_id)
	assert_int(bound).is_greater(0)
	var r:=CC.hear(id,"Put the men of Tsaren to the sword")
	assert_str(String(r.war.verdict)).is_equal("fate")
	var fate:Dictionary=r.war.get("fate",{})
	assert_int(int(fate.get("killed",0))).is_greater_equal(bound)
	# Of the men, only those never caught in the round-up could get away.
	var men:=roundi(300.0*M.MEN_SHARE)
	assert_int(int(fate.get("escaped",0))).is_less_equal(men-bound)
	assert_int(M.men_bound(civ_id,city_id)).is_equal(0)

func test_nobody_in_the_hall_is_harmed_by_orders_about_a_people()->void:
	_captured_tsaren()
	var headman:=_headman()
	var before:=_officials()
	var id:=_audience(headman)
	for words in ["Lock up all the men","Detain the villagers","Arrest every man in the village","Kill the ringleaders","Kill anyone who resists",
			"Tie them up","Kill them","Bind them all","Round up the men and kill any who run","Hang their leaders",USERS_SENTENCE,
			"Whoever resists, kill him","Kill anyone who defies me","If any of them run, cut them down"]:
		var r:=CC.hear(id,words)
		_nobody_here_harmed(r,words,before,headman)
		assert_str(String(Hall.find(id).get("status",""))).override_failure_message(words).is_equal("waiting")
	# Holding no town, the same words never fall on anyone here either.
	after_test(); before_test()
	var headman2:=_headman()
	var before2:=_officials()
	var id2:=_audience(headman2)
	for words in ["Kill them","Lock up all the men","Tie them up","Kill anyone who resists","Whoever resists, kill him"]:
		var r:=CC.hear(id2,words)
		_nobody_here_harmed(r,words,before2,headman2)
	# A careless live reading ("detain", aimed at the one before you) cannot either.
	var careless:=_say(id2,"Tie them up",_reading("order","detain","person","person:%d" % int(headman2.person_id),0.95))
	_nobody_here_harmed(careless.result,"careless detain",before2,headman2)

func test_the_fact_he_said_is_not_said_again_underneath()->void:
	_captured_tsaren()
	# Before the band's own war leader, as the user was.
	var band:Dictionary=MilitaryCampaign.field_armies[0]
	var summoned:=Hall.summon({"figure_id":String((band.commander as Dictionary).get("figure_id",""))})
	assert_dict(summoned).is_not_empty()
	var id:=String(summoned.id)
	var speaker:=Voice.new()
	add_child(speaker)
	speaker.force_offline=true
	var start:=(Hall.find(id).lines as Array).size()
	speaker.command_reaction(id,CC.hear(id,"Attack Tsaren"))
	var lines:Array=(Hall.find(id).lines as Array).slice(start)
	var spoke:=lines.any(func(l:Dictionary)->bool: return String(l.get("role",""))!="narrator" and String(l.text).contains("Tsaren is already ours"))
	assert_bool(spoke).override_failure_message(str(lines)).is_true()
	for line:Dictionary in lines:
		assert_str(String(line.text).strip_edges()).override_failure_message(str(lines)).is_not_equal("Tsaren is already ours.")
	# A note with facts the speaker did not say still appears.
	assert_bool(Voice.fact_said("Tsaren is already ours.","Tsaren is already ours. 16 of Rovik's garrison hold it.")).is_true()
	assert_bool(Voice.fact_said("Tsaren: 58 men bound and under guard, about 7 got away.","We went house to house in Tsaren. 58 men are tied and kept together under guard.")).is_false()
	speaker.free()

func test_words_are_plain_and_of_their_time()->void:
	_captured_tsaren()
	var id:=_audience(_headman())
	var tags:=CV.era_tags("player")
	for words in [USERS_SENTENCE,"Take their weapons and burn them","Take hostages","Make them build our walls","Take their grain","Take their young men into our bands","Feed them"]:
		var r:=CC.hear(id,words)
		var says:=String(r.get("actor_says",""))
		assert_bool(CV.permits(says,tags)).override_failure_message("%s -> %s (%s)" % [words,says,str(CV.lexicon_hits(says,tags))]).is_true()
		assert_bool(PlainSpeech.is_maxim(says)).override_failure_message(says).is_false()
	if not tags.has("metal"): assert_str(String(CC.hear(id,"Chain the men of Tsaren").get("actor_says",""))).not_contains("chains")

func test_the_garrison_orders_are_offered_offline_as_words_that_read_back()->void:
	_captured_tsaren()
	var id:=_audience(_headman())
	var offered:=WO.offline_choices(id).filter(func(c:Dictionary)->bool: return String(c.group)=="garrison")
	assert_int(offered.size()).is_greater_equal(8)
	var kinds:={}
	for c:Dictionary in offered:
		var reading:=WO.read(String(c.params.command_text),"",id)
		assert_str(String(reading.get("kind",""))).override_failure_message(String(c.params.command_text)).is_equal("measure")
		for m in reading.get("measures",[]): kinds[String(m)]=true
	for want in ["bind_men","disarm","hostages","curfew","search","labour","requisition","conscript","execute_ringleaders","relief","set_headman","settle"]:
		assert_bool(kinds.has(want)).override_failure_message("%s not offered: %s" % [want,str(kinds.keys())]).is_true()
	# With the men bound, freeing them is offered instead of binding them.
	CC.hear(id,USERS_SENTENCE)
	var labels:=WO.offline_choices(id).map(func(c:Dictionary)->String: return String(c.label))
	assert_bool(labels.has("Free the bound men of Tsaren")).is_true()
	assert_bool(labels.has("Round up and bind the men of Tsaren")).is_false()

func test_orders_of_occupation_are_never_generation_aims()->void:
	var Aims:=preload("res://scripts/legacy_aims.gd")
	for words in [USERS_SENTENCE,"Take their weapons","Make them build our walls","Feed them","Take hostages from their leading families"]:
		assert_bool(Aims.is_order(words)).override_failure_message(words).is_true()
	for words in ["Let fewer of our children die before their first winter","We should learn to raise stone walls","Make the Esurai fear us"]:
		assert_bool(Aims.is_order(words)).override_failure_message(words).is_false()

# --------------------------------------------------------------------------
# The coverage table (tests/fixtures/occupation_orders_coverage.json)
# --------------------------------------------------------------------------

func _table()->Array:
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(COVERAGE_PATH))
	assert_bool(parsed is Dictionary).is_true()
	return (parsed as Dictionary).rows

func _ref(ref:String)->String:
	match ref:
		"tsaren": return "town:"+city_id
		"esurai": return "people:"+civ_id
	return ref

func _check_row(row:Dictionary,r:Dictionary,path:String,before:Array,headman:Dictionary)->Array:
	var problems:Array=[]
	var words:=String(row.order)
	var tag:="[%s] %s" % [path,words]
	if not bool(r.get("handled",false)): return ["%s: not handled" % tag]
	if String(r.get("verb",""))!="war": problems.append("%s: verb %s" % [tag,String(r.get("verb",""))])
	if bool(r.get("removed",false)) or String(r.get("target_name",""))==String(headman.name) or _officials()!=before: problems.append("%s: someone in the hall was harmed" % tag)
	var war:Dictionary=r.get("war",{})
	var kind:=String(war.get("kind",""))
	var verdict:=String(war.get("verdict",""))
	if kind!=String(row.kind): problems.append("%s: kind %s, wanted %s (%s)" % [tag,kind,String(row.kind),String(r.get("actor_says",""))])
	if not verdict in (row.verdicts as Array): problems.append("%s: verdict %s, wanted %s (%s)" % [tag,verdict,str(row.verdicts),String(r.get("actor_says",""))])
	if String(row.kind)!="held" and String(r.get("actor_says","")).contains("already ours"): problems.append("%s: answered 'already ours'" % tag)
	var objective:Dictionary=r.get("objective",{})
	for m in row.get("measures",[]):
		var done:Array=(objective.get("measures",[]) as Array)+(objective.get("renewed",[]) as Array)
		if String(m)=="release": done+=["release"] if not (objective.get("freed",[]) as Array).is_empty() or String(r.get("actor_says","")).contains("no one to free") else []
		if not done.has(String(m)): problems.append("%s: measure %s not carried out (%s)" % [tag,String(m),String(r.get("actor_says",""))])
	for f in row.get("freed",[]):
		if not (objective.get("freed",[]) as Array).has(String(f)): problems.append("%s: %s not freed (%s; running %s)" % [tag,String(f),String(r.get("actor_says","")),str(M.active(civ_id,city_id).map(func(m:Dictionary)->String: return String(m.id)))])
	if row.has("stance") and String(objective.get("stance",""))!=String(row.stance): problems.append("%s: stance %s" % [tag,String(objective.get("stance",""))])
	return problems

func test_the_coverage_table_on_the_regex_path()->void:
	# A garrison of forty, so every measure has hands to carry it out.
	_captured_tsaren(40)
	var headman:=_headman()
	var before:=_officials()
	var id:=_audience(headman)
	var problems:Array=[]
	for row:Dictionary in _table():
		_retake_if_lost(40)
		problems.append_array(_check_row(row,CC.hear(id,String(row.order)),"regex",before,headman))
	assert_array(problems).override_failure_message("\n".join(PackedStringArray(problems))).is_empty()

func test_the_coverage_table_on_the_reader_path()->void:
	_captured_tsaren(40)
	var headman:=_headman()
	var before:=_officials()
	var id:=_audience(headman)
	var problems:Array=[]
	for row:Dictionary in _table():
		_retake_if_lost(40)
		var stub:Dictionary=row.reader
		var reading:=_reading("order",String(stub.action),String(stub.type),_ref(String(stub.ref)),float(stub.get("confidence",0.92)),stub.get("details",{}))
		var out:=_say(id,String(row.order),reading)
		if String(row.get("reader_route",""))!="":
			if String(out.plan.route)!=String(row.reader_route): problems.append("[reader] %s: route %s" % [String(row.order),String(out.plan.route)])
			continue
		if String(out.plan.route)!="engine": problems.append("[reader] %s: route %s (%s)" % [String(row.order),String(out.plan.route),str(out.plan.get("why",""))]); continue
		problems.append_array(_check_row(row,out.result,"reader",before,headman))
	assert_array(problems).override_failure_message("\n".join(PackedStringArray(problems))).is_empty()
