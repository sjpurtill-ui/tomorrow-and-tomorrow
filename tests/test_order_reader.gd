extends GdUnitTestSuite
## The order reader (order_reader.gd): with a live model, one short call reads
## what the ruler MEANT before anyone speaks; the engine acts on ids we
## supplied, the court asks when a grave order is unclear, and any failure
## falls back to the offline regex reading. HTTP is always stubbed here
## (audience_voice.order_hook / send_hook): no network, no real key.

const CC:=preload("res://scripts/court_commands.gd")
const WO:=preload("res://scripts/court_war_orders.gd")
const OR:=preload("res://scripts/order_reader.gd")
const Route:=preload("res://scripts/army_land_route.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const AiMode:=preload("res://scripts/ai_mode.gd")
const Voice:=preload("res://scripts/audience_voice.gd")

const USERS_ORDER:="I want you to kill all the males of Tsaren immediately"
const SECRET:="sk-test-DO-NOT-LOG-0123456789"

var home:=Vector2.ZERO
var city:=Vector2.ZERO
var city_id:=""
var civ_id:=""
var voice:Node
var payloads:Array=[]
var _processing:Dictionary={}

func _land(_p:Vector2)->bool:
	return true

func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]: _processing[node]=node.is_processing()
	AiMode.reset_for_tests("user://__order_reader_test_missing.cfg")
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
	payloads.clear()

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

func _captured_tsaren()->void:
	_train(18)
	MilitaryCampaign.create_field_army(18,"LEVY BAND 1")
	var army:Dictionary=MilitaryCampaign.field_armies[0]
	army["supply_level"]=1.0; army["readiness"]=1.0
	army["position"]={"x":city.x+0.3,"z":city.y}
	army["location_id"]=city_id; army["location_name"]="Tsaren"; army["status"]="stationed"
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var ri:=CivilizationSystem._region_index(civ,city_id)
	civ.strategic_regions[ri]["controller"]="player"
	var garrison:=MilitaryCampaign.establish_occupation_force(civ_id,civ.strategic_regions[ri],17.0,int(army.army_id))
	assert_int(int(garrison.get("troops",0))).is_greater(0)

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

func _reading(kind:String,action:String,ttype:String,ref:String,confidence:float=0.95,details:Dictionary={},clarify:String="",actor:String="")->Dictionary:
	var d:={"kill_men":false,"kill_all":false,"captives":false,"raze":false,"tribute":false,"spare":false,"hold":false,"leave":false,"free":false,"full_force":false,"count":0,"resource":"","destination":""}
	d.merge(details,true)
	return {"kind":kind,"action":action,"actor":actor,"target":{"type":ttype,"ref":ref},"details":d,"confidence":confidence,"clarify":clarify}

func _body(reading:Dictionary)->PackedByteArray:
	return JSON.stringify({"model":"mock-reader","choices":[{"finish_reason":"stop","message":{"content":JSON.stringify(reading)}}],"usage":{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15}}).to_utf8_buffer()

## The modal's path, without the UI: read (stubbed), decide, carry out.
## reading={} stands for a timeout / failed call.
func _say(id:String,text:String,reading:Dictionary)->Dictionary:
	voice.order_hook=func(_aid:String,payload:Dictionary)->PackedByteArray:
		payloads.append(payload)
		return _body(reading) if not reading.is_empty() else PackedByteArray()
	var got:=[{}]
	var started:bool=voice.read_order(id,text,func(read:Dictionary)->void: got[0]=read)
	assert_bool(started).is_true()
	var read:Dictionary=got[0]
	var plan:Dictionary=OR.decide(id,text,read.reading) if read.has("reading") else OR.offline_confirm(id,text)
	if plan.is_empty(): plan={"route":"legacy"}
	var done:=OR.carry_out(id,text,plan,{})
	return {"read":read,"plan":plan,"done":done,"result":done.get("result",{})}

func _nobody_here_harmed(r:Dictionary,words:String,before:Array,headman:Dictionary)->void:
	var said:="%s -> stage %s, target %s: %s %s" % [words,String(r.get("stage","")),String(r.get("target_name","")),String(r.get("actor_says","")),String(r.get("outcome",""))]
	assert_bool(bool(r.get("handled",false))).override_failure_message(said).is_true()
	assert_str(String(r.get("verb",""))).override_failure_message(said).is_equal("war")
	assert_bool(bool(r.get("removed",false))).override_failure_message(said).is_false()
	assert_str(String(r.get("target_name",""))).override_failure_message(said).is_not_equal(String(headman.name))
	assert_array(_officials()).override_failure_message(said).is_equal(before)

# --------------------------------------------------------------------------
# The user's real lines
# --------------------------------------------------------------------------

func test_kill_all_the_males_of_a_held_town_is_its_fate()->void:
	_captured_tsaren()
	var headman:=_headman()
	var before:=_officials()
	var id:=_audience(headman)
	var out:=_say(id,USERS_ORDER,_reading("order","town_fate","group","town:"+city_id,0.95,{"kill_men":true}))
	assert_str(String(out.plan.route)).is_equal("engine")
	var r:Dictionary=out.result
	_nobody_here_harmed(r,USERS_ORDER,before,headman)
	assert_str(String(r.war.verdict)).override_failure_message(String(r.get("actor_says",""))).is_equal("fate")
	assert_str(String(r.objective.city_id)).is_equal(city_id)
	assert_int(int(r.objective.killed)).is_greater(0)

func test_a_reader_naming_the_headman_as_victim_still_cannot_touch_him()->void:
	# A careless reading: kill, aimed at the one spoken to. The words are a
	# group order, so harm_to_people keeps it a war order about Tsaren.
	_captured_tsaren()
	var headman:=_headman()
	var before:=_officials()
	var id:=_audience(headman)
	var out:=_say(id,USERS_ORDER,_reading("order","kill","person","person:%d" % int(headman.person_id),0.97))
	_nobody_here_harmed(out.result,USERS_ORDER,before,headman)

func test_kill_all_the_males_of_a_town_not_held_asks_to_march_then_yes_marches()->void:
	_train(30)
	var headman:=_headman()
	var before:=_officials()
	var id:=_audience(headman)
	var out:=_say(id,USERS_ORDER,_reading("order","kill","group","town:"+city_id,0.93,{"kill_men":true}))
	var r:Dictionary=out.result
	_nobody_here_harmed(r,USERS_ORDER,before,headman)
	assert_str(String(r.war.verdict)).is_equal("ask_march")
	assert_int(MilitaryCampaign.field_armies.size()).is_equal(0)
	assert_bool(bool((Hall.find(id).get("pending_command",{}) as Dictionary).get("confirm",false))).is_true()
	# "Yeah, go ahead and chase them" answers the open question: yes.
	var yes:=_say(id,"Yeah, go ahead and chase them",_reading("order","confirm","none",""))
	var y:Dictionary=yes.result
	_nobody_here_harmed(y,"yeah go ahead",before,headman)
	assert_bool(String(y.war.verdict) in ["act","object"]).override_failure_message(String(y.get("actor_says",""))).is_true()

func test_chase_them_with_nothing_pending_goes_after_their_army()->void:
	_train(30)
	var headman:=_headman()
	var before:=_officials()
	var id:=_audience(headman)
	var out:=_say(id,"Yeah, go ahead and chase them",_reading("order","pursue","people","people:"+civ_id,0.9))
	var r:Dictionary=out.result
	_nobody_here_harmed(r,"chase them",before,headman)
	assert_str(String(r.war.kind)).is_equal("intercept")

func test_come_back_and_everyone_come_home_recall_the_bands()->void:
	for words:String in ["come back","everyone come home"]:
		before_test()
		_captured_tsaren()
		var headman:=_headman()
		var before:=_officials()
		var id:=_audience(headman)
		var out:=_say(id,words,_reading("order","recall","none","",0.9))
		var r:Dictionary=out.result
		_nobody_here_harmed(r,words,before,headman)
		assert_str(String(r.war.kind)).override_failure_message(words).is_equal("recall")

func test_attack_tsaren_with_everything_is_a_full_attack()->void:
	_train(30)
	var headman:=_headman()
	var before:=_officials()
	var id:=_audience(headman)
	var words:="attack Tsaren with everything"
	var out:=_say(id,words,_reading("order","attack","town","town:"+city_id,0.92,{"full_force":true}))
	var r:Dictionary=out.result
	_nobody_here_harmed(r,words,before,headman)
	assert_str(String(r.war.kind)).is_equal("attack")
	assert_bool(String(r.war.verdict) in ["act","object"]).override_failure_message(String(r.get("actor_says",""))).is_true()

func test_kill_him_reaches_the_person_the_reader_named()->void:
	var headman:=_headman()
	var id:=_audience(headman)
	var out:=_say(id,"kill him",_reading("order","kill","person","person:%d" % int(headman.person_id),0.95))
	var r:Dictionary=out.result
	assert_str(String(r.get("verb",""))).is_equal("kill")
	assert_str(String(r.get("target_name",""))).is_equal(String(headman.name))

func test_a_question_is_answered_not_acted_on()->void:
	var headman:=_headman()
	var before:=_officials()
	var id:=_audience(headman)
	var words:="what do the Esurai want?"
	var out:=_say(id,words,_reading("question","none","people","people:"+civ_id,0.95))
	assert_str(String(out.plan.route)).is_equal("speak")
	assert_dict(out.result as Dictionary).is_empty()
	assert_array(_officials()).is_equal(before)
	# The voice then answers in words only: no command classification is asked for.
	var sent:=[]
	voice.send_hook=func(_aid:String,payload:Dictionary,_attempt:int)->void: sent.append(payload)
	voice.player_speaks(id,words,false,true)
	voice.send_hook=Callable()
	assert_int(sent.size()).is_equal(1)
	var props:Dictionary=sent[0].response_format.json_schema.schema.properties
	assert_bool(props.has("command")).is_false()
	assert_str(JSON.stringify(sent[0].messages)).contains("not an order")
	voice._requests.erase(id)

# --------------------------------------------------------------------------
# Safety and fallbacks
# --------------------------------------------------------------------------

func test_an_id_not_in_the_lists_is_rejected()->void:
	var headman:=_headman()
	var before:=_officials()
	var id:=_audience(headman)
	for bad:Dictionary in [_reading("order","kill","person","person:999999",0.99),_reading("order","attack","town","town:nowhere",0.99),
			_reading("order","kill","group","person:%d" % int(headman.person_id),0.99)]:
		var out:=_say(id,"kill him",bad)
		assert_dict(out.read as Dictionary).override_failure_message(str(bad)).is_empty()
		assert_str(String(out.plan.route)).is_equal("legacy")
		assert_str(String(voice.last_problem.get(id,""))).contains("rejected")
	assert_array(_officials()).is_equal(before)

func test_low_confidence_on_a_grave_act_asks_first_and_yes_carries_it()->void:
	_captured_tsaren()
	var headman:=_headman()
	var before:=_officials()
	var id:=_audience(headman)
	var population:=float(CivilizationSystem.civilizations[0].strategic_regions[CivilizationSystem._region_index(CivilizationSystem.civilizations[0],city_id)].get("population",0.0))
	var out:=_say(id,"deal with Tsaren's men",_reading("order","town_fate","group","town:"+city_id,0.5,{"kill_men":true},"Do you mean every man in Tsaren put to death?"))
	assert_str(String(out.plan.route)).is_equal("clarify")
	assert_str(String(out.done.question)).is_equal("Do you mean every man in Tsaren put to death?")
	var lines:Array=Hall.find(id).lines
	assert_str(String(lines[-1].text)).is_equal("Do you mean every man in Tsaren put to death?")
	assert_array(_officials()).is_equal(before)
	var after:=float(CivilizationSystem.civilizations[0].strategic_regions[CivilizationSystem._region_index(CivilizationSystem.civilizations[0],city_id)].get("population",0.0))
	assert_float(after).is_equal(population)
	assert_dict(OR.pending(Hall.find(id))).is_not_empty()
	# The world brief tells the reader the question is open.
	assert_str(OR.brief_text(OR.world_brief(id))).contains("Do you mean every man in Tsaren")
	var yes:=_say(id,"yes",_reading("order","confirm","none",""))
	var r:Dictionary=yes.result
	_nobody_here_harmed(r,"yes",before,headman)
	assert_str(String(r.war.verdict)).is_equal("fate")
	assert_dict(OR.pending(Hall.find(id))).is_empty()

func test_grave_act_with_no_target_asks_even_when_confident()->void:
	var headman:=_headman()
	var id:=_audience(headman)
	var before:=_officials()
	var out:=_say(id,"kill him",_reading("order","kill","person","",0.95))
	assert_str(String(out.plan.route)).is_equal("clarify")
	assert_array(_officials()).is_equal(before)

func test_an_offline_yes_answers_the_readers_question_when_the_call_fails()->void:
	_captured_tsaren()
	var headman:=_headman()
	var before:=_officials()
	var id:=_audience(headman)
	_say(id,"deal with Tsaren's men",_reading("order","town_fate","group","town:"+city_id,0.4,{"kill_men":true}))
	assert_dict(OR.pending(Hall.find(id))).is_not_empty()
	var yes:=_say(id,"yes",{})
	_nobody_here_harmed(yes.result,"offline yes",before,headman)
	assert_str(String(yes.result.war.verdict)).is_equal("fate")

func test_timeout_falls_back_to_the_regex_reading()->void:
	_captured_tsaren()
	var headman:=_headman()
	var before:=_officials()
	var id:=_audience(headman)
	var out:=_say(id,USERS_ORDER,{})
	assert_dict(out.read as Dictionary).is_empty()
	assert_str(String(out.plan.route)).is_equal("legacy")
	assert_str(String(voice.last_problem.get(id,""))).contains("timed out")
	assert_float(OR.TIMEOUT_SECONDS).is_less_equal(4.5)
	# The offline path is unchanged: the regex engine and its guard decide.
	var r:=CC.hear(id,USERS_ORDER)
	_nobody_here_harmed(r,USERS_ORDER,before,headman)
	assert_str(String(r.war.verdict)).is_equal("fate")

func test_offline_there_is_no_reader_call()->void:
	var headman:=_headman()
	var id:=_audience(headman)
	voice.force_offline=true
	var called:=[false]
	voice.order_hook=func(_a:String,_p:Dictionary)->PackedByteArray:
		called[0]=true
		return PackedByteArray()
	assert_bool(voice.read_order(id,"kill him",func(_r:Dictionary)->void:pass)).is_false()
	assert_bool(called[0]).is_false()

func test_the_world_brief_holds_towns_garrisons_bands_and_the_hall()->void:
	_captured_tsaren()
	_train(6)
	MilitaryCampaign.create_field_army(6,"LEVY BAND 2")
	var headman:=_headman()
	var id:=_audience(headman)
	var brief:=OR.world_brief(id)
	var text:=OR.brief_text(brief)
	var garrison:=int(WO.held_towns()[0].garrison)
	assert_str(text).contains("TOWNS WE HOLD: town:%s = Tsaren (Esurai town; our garrison %d" % [city_id,garrison])
	assert_str(text).contains("people:%s = Esurai (AT WAR with us)" % civ_id)
	assert_str(text).contains("person:%d = %s" % [int(headman.person_id),String(headman.name)])
	assert_str(text).contains("SPEAKING")
	assert_str(text).override_failure_message(text).contains("OUR BANDS: band:")
	assert_str(text).contains("Seanstone")
	_say(id,"hold",_reading("speech","none","none",""))
	var payload:Dictionary=payloads[-1]
	assert_str(String(payload.messages[1].content)).contains("TOWNS WE HOLD: town:"+city_id)
	var refs:Array=payload.response_format.json_schema.schema.properties.target.properties.ref.enum
	assert_bool("town:"+city_id in refs).is_true()
	assert_bool("person:%d" % int(headman.person_id) in refs).is_true()
	assert_int(int(payload.max_completion_tokens)).is_less_equal(600)

func test_the_reader_model_is_configurable_apart_from_the_voice()->void:
	var headman:=_headman()
	var id:=_audience(headman)
	_say(id,"hello",_reading("speech","none","none",""))
	assert_str(String(payloads[-1].model)).is_equal("mock-voice")
	AiMode.set_reader_model("reader-setting-model",false)
	_say(id,"hello",_reading("speech","none","none",""))
	assert_str(String(payloads[-1].model)).is_equal("reader-setting-model")
	OS.set_environment("LEVIATHAN_AI_READER_MODEL","reader-env-model")
	_say(id,"hello",_reading("speech","none","none",""))
	assert_str(String(payloads[-1].model)).is_equal("reader-env-model")

func test_no_api_key_appears_in_payloads_receipts_or_logs()->void:
	_captured_tsaren()
	var headman:=_headman()
	var id:=_audience(headman)
	_say(id,USERS_ORDER,_reading("order","town_fate","group","town:"+city_id,0.95,{"kill_men":true}))
	_say(id,"kill him",_reading("order","kill","person","person:1",0.99))
	_say(id,"come home",{})
	for p in payloads: assert_str(JSON.stringify(p)).not_contains(SECRET)
	assert_str(str(voice.usage)).not_contains(SECRET)
	assert_str(str(voice.last_problem)).not_contains(SECRET)
	assert_str(JSON.stringify(Hall.find(id))).not_contains(SECRET)
	var src:=FileAccess.get_file_as_string("res://scripts/order_reader.gd")
	assert_str(src).not_contains("print(")
	assert_str(src).not_contains("push_warning(")

func test_yes_to_the_chase_offer_sends_a_real_detachment()->void:
	# The user's sequence through the reader: the kill order, the war leader's
	# offer to chase those who fled, then "Yeah, go ahead and chase them".
	_captured_tsaren()
	var id:=_audience(_headman())
	var out:=_say(id,USERS_ORDER,_reading("order","town_fate","group","town:"+city_id,0.95,{"kill_men":true}))
	assert_str(String(out.result.war.verdict)).is_equal("fate")
	var ask:=String((Hall.find(id).get("pending_command",{}) as Dictionary).get("ask",""))
	if ask!="chase": return   # nobody got away in this fixture: nothing to chase
	var held_before:=int(WO.held_towns()[0].garrison)
	var yes:=_say(id,"Yeah, go ahead and chase them",_reading("order","confirm","none","",0.95))
	var r:Dictionary=yes.result
	assert_str(String(r.get("war",{}).get("verdict",""))).override_failure_message(String(r.get("actor_says",""))).is_equal("act")
	var sent:=int(r.objective.troops)
	assert_int(sent).is_greater(0)
	assert_int(int(WO.held_towns()[0].garrison)).is_equal(held_before-sent)
	var out_there:=false
	for army in MilitaryCampaign.field_armies:
		if (army as Dictionary).has("pursuit"): out_there=true
	assert_bool(out_there).is_true()

func test_the_reader_naming_pursue_uses_the_real_chase_when_men_fled()->void:
	_captured_tsaren()
	var id:=_audience(_headman())
	_say(id,USERS_ORDER,_reading("order","town_fate","group","town:"+city_id,0.95,{"kill_men":true}))
	if preload("res://scripts/pursuit.gd").latest_flight(city_id).is_empty(): return
	var out:=_say(id,"send ten after the men who fled",_reading("order","pursue","town","town:"+city_id,0.9,{"count":10}))
	assert_str(String(out.result.war.objective.get("kind",out.result.get("objective",{}).get("kind","")))).is_not_equal("intercept")

func test_an_order_never_becomes_a_generation_aim()->void:
	var Aims:=preload("res://scripts/legacy_aims.gd")
	for words in ["Go and conquer Tsaren right now","Attack Tsaren","Kill all the males of Tsaren","March on Stonefield at once","take Tsaren immediately"]:
		assert_bool(Aims.is_order(words)).override_failure_message(words).is_true()
	for words in ["Let fewer of our children die before their first winter","We should learn to raise stone walls","Make the Esurai fear us"]:
		assert_bool(Aims.is_order(words)).override_failure_message(words).is_false()
