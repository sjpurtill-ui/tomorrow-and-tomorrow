extends GdUnitTestSuite
## One state, nothing contradicts it (docs/ADJUDICATION.md).
##
## The user's campaign: Tsaren was taken, its men killed and bound, women
## taken, the town ordered burned, all under an older build that then handed
## Tsaren back to the Esurai and withdrew the garrison. Under the next build
## the war leader said "Twenty-one men of Tsaren are bound." (from the town's
## ledger), then, asked "Is that all of the men of Tsaren?", an offline line:
## "Nobody's brought that to me. I'll ask."; and "Take all girls under 10 back
## to Seanstone" got "We hold no town of theirs" from the order path. One
## town, three readings.
##
## Here every system reads one predicate (town_ledger.hold) in six states; an
## old save's leftovers are settled on load (and on the first read) and said
## once; factual questions get the sheet's numbers on the live path (stubbed)
## and every fallback; and "the girls under ten" is an exact, seeded taking
## when the town is held, and a plain why-not when it is not.

const CC:=preload("res://scripts/court_commands.gd")
const WO:=preload("res://scripts/court_war_orders.gd")
const OR:=preload("res://scripts/order_reader.gd")
const M:=preload("res://scripts/occupation_measures.gd")
const Fate:=preload("res://scripts/town_fate.gd")
const Ledger:=preload("res://scripts/town_ledger.gd")
const Pursuit:=preload("res://scripts/pursuit.gd")
const Held:=preload("res://scripts/held_town.gd")
const Ownership:=preload("res://scripts/map_ownership.gd")
const Facts:=preload("res://scripts/court_facts.gd")
const Answers:=preload("res://scripts/court_answers.gd")
const Route:=preload("res://scripts/army_land_route.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const AiMode:=preload("res://scripts/ai_mode.gd")
const Voice:=preload("res://scripts/audience_voice.gd")

const USERS_BIND:="Round up all the men of Tsaren and tie them up. If any resist or attempt to flee, threaten their wives and children."
const HOW_MANY_BOUND:="How many men of Tsaren are now bound?"
const IS_THAT_ALL:="Is that all of the men of Tsaren?"
const GIRLS:="Take all girls under 10 back to Seanstone"
const SECRET:="sk-test-DO-NOT-LOG-0123456789"
const IGNORANCE:=["Nobody's brought that to me","I'll ask","I don't know","won't guess","Nobody has counted","ask around"]

var home:=Vector2.ZERO
var city:=Vector2.ZERO
var city_id:=""
var civ_id:=""
var refuge_id:=""
var voice:Node
var sent:Array=[]
var slot:=""
var _processing:Dictionary={}

func _land(_p:Vector2)->bool:
	return true

func before_test()->void:
	slot="one_truth_test_%d_%d" % [OS.get_process_id(),Time.get_ticks_usec()]
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]: _processing[node]=node.is_processing()
	AiMode.reset_for_tests("user://__one_truth_test_missing.cfg")
	# The stubbed live voice's exchanges are never written into the player's
	# interaction records (user://interactions/), as in court_eval/fixtures.gd.
	AiMode.set_records_interactions(false,false)
	OS.unset_environment("LEVIATHAN_AI_READER_MODEL")
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();ForeignDiplomacy.ensure();GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(900);GameState.housing_capacity=1100
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.select_founding_focus("provision")
	GameState.settlement_name="Seanstone"
	GameState.society_capacities["institutions"]=0.4
	GovernmentPeopleSystem._update_government_stage(false)
	GovernmentPeopleSystem.initialize()
	GameState.resource_stockpiles["Food"]=1000000.0
	GameState.elapsed_days=95*365+20
	MilitaryCampaign.last_processed_day=int(GameState.elapsed_days)
	Route.clear_cache()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ["name"]="Esurai"
	civ_id=String(civ.id)
	var relation:Dictionary=civ.player_relation
	relation.at_war=true; relation.treaty="war"; relation.stance="hostile"; relation.contact_level=2; relation.home_location_known=true
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	region["name"]="Tsaren"
	region["population"]=300.0
	city_id=String(region.id)
	# Their nearest other town, where Tsaren's people run: Stonefield.
	for r:Dictionary in civ.strategic_regions:
		if String(r.id)!=city_id and String(r.get("controller",civ_id))==civ_id and bool(r.get("settlement_founded",true)):
			r["name"]="Stonefield"; refuge_id=String(r.id); break
	home=CivilizationSystem.player_world_origin
	city=home+Vector2(-20.0,8.0)
	region["position"]=city
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",city_id,.8,int(GameState.elapsed_days)-40,"scout report","test"),int(GameState.elapsed_days)-40)
	CivilizationSystem.city_intelligence.records.player[city_id]["position"]={"x":city.x,"z":city.y}
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))
	_people_add_up()
	if voice==null or not is_instance_valid(voice):
		voice=Voice.new()
		add_child(voice)
	voice.force_offline=false
	voice.config_override={"endpoint":"https://mock.invalid/v1/chat/completions","api_key":SECRET,"model":"mock-voice","structured_output":true}
	sent.clear()
	voice.send_hook=Callable(); voice.order_hook=Callable()
	voice.usage.clear(); voice.last_problem.clear()

func after_test()->void:
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	if voice!=null and is_instance_valid(voice):
		voice.send_hook=Callable(); voice.order_hook=Callable()
		for aid in (voice._requests as Dictionary).keys(): voice._requests.erase(aid)
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

## Their towns never hold more people than their people number (the save
## validator checks it).
func _people_add_up()->void:
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var represented:=0.0
	for r:Dictionary in civ.strategic_regions: represented+=float(r.get("population",0.0))
	var population:=float(civ.get("population",0.0))
	if represented>population and population>0.0:
		for cohort in (civ.cohorts as Dictionary): civ.cohorts[cohort]=float(civ.cohorts[cohort])*represented/population
		civ["population"]=represented

func _train(count:int)->void:
	MilitaryCampaign.military_inventory["improvised"]=int(MilitaryCampaign.military_inventory.get("improvised",0))+count
	MilitaryCampaign.raise_recruits(count)
	MilitaryCampaign.start_training("levy","improvised",count)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()

## Tsaren taken; about 17 of the band hold it.
func _captured_tsaren(troops:int=18)->Dictionary:
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
	civ.strategic_regions[ri]["resistance"]=0.6
	var garrison:=MilitaryCampaign.establish_occupation_force(civ_id,civ.strategic_regions[ri],float(troops-1),army_id)
	assert_int(int(garrison.get("troops",0))).override_failure_message(str(garrison)).is_greater(0)
	# Every man stayed to hold the town: the band is its garrison now, its
	# general with it (no band of nobody is left behind).
	var at:=MilitaryCampaign._field_army_index(army_id)
	return MilitaryCampaign.field_armies[at] if at>=0 else MilitaryCampaign.occupation_force_for_region(civ_id,city_id)

func _war_leader(band:Dictionary)->String:
	var audience:=Hall.summon({"figure_id":String((band.commander as Dictionary).get("figure_id",""))})
	assert_dict(audience).is_not_empty()
	return String(audience.id)

func _region()->Dictionary:
	return Ledger.region_ref(civ_id,city_id)

## The garrison leaves and (theirs=true) the town goes back to its people, as
## the old build did, without anything reading the ledger in between.
func _withdraw(theirs:bool=true)->void:
	MilitaryCampaign.occupation_forces.clear()
	if theirs: _region()["controller"]=civ_id

## An older build's garrison record over a town it took: 38 killed and the
## women and children carried off, 21 men bound, 23 who ran and reached
## Stonefield. No ledger yet; the first read adopts it.
func _old_build_records(people_now:float,killed:int=38,captives:int=60,bound:int=21,ran:int=23,state:String="gone")->void:
	_region()["population"]=people_now
	var gov:Dictionary=_region().get("governance",{}) if _region().get("governance") is Dictionary else {}
	gov["mass_killing_deaths"]=killed
	_region()["governance"]=gov
	_people_add_up()
	var at:=MilitaryCampaign._occupation_force_index(civ_id,city_id)
	var force:Dictionary=MilitaryCampaign.occupation_forces[at]
	var day:=int(GameState.elapsed_days)
	force["measures"]=[{"id":"bind_men","day":day-6,"until":day+24,"stance":"harsh","last_day":day-1,"ended":false,"end_day":-1,"families":true,"count":bound,"guards":3,"fled":0,"who":"men"}]
	force["fled"]={"count":ran,"day":day-8,"toward":"Stonefield","toward_id":refuge_id,"toward_position":{},"hills":false,"state":state,"caught":0}
	force["fate"]={"killed":killed,"captives":captives,"tribute":0,"day":day-8}

## The user's town as the next build found it: adopted from the old records
## while the garrison stood, then handed back without a word.
func _users_tsaren()->String:
	var band:=_captured_tsaren()
	var id:=_war_leader(band)
	_old_build_records(380.0)
	var l:=Ledger.of(civ_id,city_id)
	assert_int(Ledger.count(l,"bound","men")).is_equal(21)
	_withdraw(true)
	return id

func _reading(kind:String,action:String,ttype:String,ref:String,confidence:float=0.95,details:Dictionary={},clarify:String="")->Dictionary:
	var d:={"kill_men":false,"kill_all":false,"captives":false,"raze":false,"tribute":false,"spare":false,"hold":false,"leave":false,"free":false,"full_force":false,"count":0,"resource":"","destination":"","measures":[],"stance":""}
	d.merge(details,true)
	return {"kind":kind,"action":action,"actor":"","target":{"type":ttype,"ref":ref},"details":d,"confidence":confidence,"clarify":clarify}

func _body(reading:Dictionary)->PackedByteArray:
	return JSON.stringify({"model":"mock-reader","choices":[{"finish_reason":"stop","message":{"content":JSON.stringify(reading)}}],"usage":{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15}}).to_utf8_buffer()

## The modal's live path without the UI: read (stubbed), decide, carry out.
func _say(id:String,text:String,reading:Dictionary)->Dictionary:
	voice.order_hook=func(_aid:String,_payload:Dictionary)->PackedByteArray:
		return _body(reading) if not reading.is_empty() else PackedByteArray()
	var got:=[{}]
	var started:bool=voice.read_order(id,text,func(read:Dictionary)->void: got[0]=read)
	assert_bool(started).is_true()
	var read:Dictionary=got[0]
	var plan:Dictionary=OR.decide(id,text,read.reading) if read.has("reading") else OR.offline_confirm(id,text)
	if plan.is_empty(): plan={"route":"legacy"}
	var done:=OR.carry_out(id,text,plan,{})
	voice.order_hook=Callable()
	return {"read":read,"plan":plan,"done":done,"result":done.get("result",{})}

## The live voice's reply (stubbed transport; nothing leaves the machine).
## transport: a failed connection; finish "length": a reply cut off.
func _live(lines:Array,finish:String="stop",transport:int=HTTPRequest.RESULT_SUCCESS)->void:
	voice.send_hook=func(aid:String,payload:Dictionary,attempt:int)->void:
		sent.append(payload)
		if transport!=HTTPRequest.RESULT_SUCCESS:
			voice._on_response(transport,0,PackedStringArray(),PackedByteArray(),aid,attempt)
			return
		var content:=JSON.stringify({"lines":lines,"mood_shift":0.0}) if finish!="length" else "{\"lines\":[{\"speaker_key\":\"envoy\",\"text\":\"No, High"
		var body:=JSON.stringify({"id":"m","model":"mock-voice","choices":[{"finish_reason":finish,"message":{"role":"assistant","content":content}}],"usage":{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15}}).to_utf8_buffer()
		voice._on_response(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),body,aid,attempt)

## The ruler asks (the reader already read it as a question); the war
## leader's answer is returned.
func _ask(id:String,words:String)->String:
	var before:=(Hall.find(id).get("lines",[]) as Array).size()
	voice.player_speaks(id,words,false,true)
	var lines:Array=Hall.find(id).get("lines",[])
	var said:=""
	for i in range(before,lines.size()):
		var line:Dictionary=lines[i]
		if String(line.get("role",""))!="ruler" and String(line.get("role",""))!="narrator": said=String(line.get("text",""))
	for bad in IGNORANCE: assert_str(said).override_failure_message(words+" -> "+said).not_contains(bad)
	return said

func _consistent(step:String)->void:
	var check:=Ledger.check(civ_id,city_id)
	assert_bool(bool(check.get("ok",false))).override_failure_message("%s: %s" % [step,str(check)]).is_true()

func _balanced(before:Dictionary,step:String)->Dictionary:
	var after:=Ledger.snapshot(civ_id,city_id)
	var b:=Ledger.balance(before,after)
	assert_bool(bool(b.ok)).override_failure_message("%s: %s" % [step,str(b)]).is_true()
	return b

func _sheet_town()->Dictionary:
	for t:Dictionary in Facts.sheet(["common","war"]).towns:
		if String(t.get("region_id",""))==city_id: return t
	return {}

## Every system's answer to "do we hold Tsaren?", and nobody of it in our
## hands when we do not.
func _agree(expect:bool,step:String)->void:
	var why:=step+": "
	var h:=Ledger.hold(civ_id,city_id)
	assert_bool(bool(h.held)).override_failure_message(why+"hold "+str(h)).is_equal(expect)
	assert_bool(WO.held_towns().any(func(t:Dictionary)->bool: return String(t.city_id)==city_id)).override_failure_message(why+"held_towns").is_equal(expect)
	assert_bool(Held.held(city_id)).override_failure_message(why+"held_town").is_equal(expect)
	var own:=Ownership.player_hold(city_id)
	assert_bool(bool(own.get("held",false))).override_failure_message(why+"map hold "+str(own)).is_equal(expect)
	assert_bool(int(own.get("garrison",0))>0).override_failure_message(why+"map garrison").is_equal(expect)
	var brief:=OR.world_brief("")
	assert_bool((brief.held as Array).any(func(t:Dictionary)->bool: return String(t.id)=="town:"+city_id)).override_failure_message(why+"reader brief").is_equal(expect)
	var t:=_sheet_town()
	if expect or Ledger.has(civ_id,city_id):
		assert_dict(t).override_failure_message(why+"no facts for the town").is_not_empty()
		assert_bool(bool(t.held)).override_failure_message(why+"facts "+str(t.get("status",""))).is_equal(expect)
		assert_bool(int(t.garrison)>0).override_failure_message(why+"facts garrison").is_equal(expect)
	var report:=Held.report(city_id)
	if not report.is_empty(): assert_bool(int(report.garrison)>0).override_failure_message(why+"report garrison").is_equal(expect)
	var status:=Ownership.status({"city_id":city_id,"civ_id":civ_id})
	if expect: assert_str(String(status.emblem)).override_failure_message(why+"map emblem").is_equal("player")
	if not expect:
		# Nobody of it in our hands, by any reading.
		if Ledger.has(civ_id,city_id): assert_int(Ledger.held(Ledger.of(civ_id,city_id))).override_failure_message(why+"ledger holds people").is_equal(0)
		if not t.is_empty():
			for key in ["men_bound","hostages","at_forced_labour","serving_with_us"]: assert_int(int(t.get(key,0))).override_failure_message(why+key).is_equal(0)
		var chase:=Pursuit.begin(civ_id,city_id)
		assert_str(String(chase.get("reason",""))).override_failure_message(why+"chase "+str(chase)).is_equal("no_garrison")
		assert_bool(M.apply(civ_id,city_id,["curfew"]).has("error")).override_failure_message(why+"measures").is_true()
		assert_bool(Fate.apply(civ_id,city_id,{"spare":true}).has("error")).override_failure_message(why+"fate").is_true()
		if String(status.kind)=="occupied": assert_str(String(status.note)).override_failure_message(why+"map note").contains("no one guards it")

# --------------------------------------------------------------------------
# One predicate, six states, every system agrees
# --------------------------------------------------------------------------

func test_a_garrison_without_a_ledger_holds_the_town_everywhere()->void:
	_captured_tsaren()
	assert_bool(Ledger.has(civ_id,city_id)).is_false()
	_agree(true,"garrison, no ledger")
	# The facts made its ledger from its people: all free, all counted.
	var t:=_sheet_town()
	assert_str(String(t.status)).is_equal("held")
	assert_int(int(t.people_here)).is_equal(300)
	assert_int(Ledger.held(Ledger.of(civ_id,city_id))).is_equal(0)
	_consistent("garrison, no ledger")

func test_a_garrison_and_its_ledger_hold_the_bound_everywhere()->void:
	var id:=_war_leader(_captured_tsaren())
	CC.hear(id,USERS_BIND)
	var bound:=Ledger.count(Ledger.of(civ_id,city_id),"bound","men")
	assert_int(bound).is_greater(0)
	_agree(true,"garrison and ledger")
	assert_int(int(_sheet_town().men_bound)).is_equal(bound)
	assert_str(String(WO.read("Keep the people of Tsaren in their houses").get("kind",""))).is_equal("measure")
	_consistent("garrison and ledger")

func test_a_ledger_without_a_garrison_holds_nobody_and_says_so_once()->void:
	var id:=_war_leader(_captured_tsaren())
	CC.hear(id,USERS_BIND)
	var bound:=Ledger.count(Ledger.of(civ_id,city_id),"bound","men")
	var free_men:=Ledger.count(Ledger.of(civ_id,city_id),"free","men")
	_withdraw(true)
	# The raw record still says bound: nothing has read it since.
	assert_int(int((_region().ledger as Dictionary).present.bound.men)).is_equal(bound)
	_agree(false,"ledger, no garrison")
	var l:=Ledger.of(civ_id,city_id)
	assert_int(Ledger.count(l,"free","men")).is_equal(free_men+bound)
	var went:Dictionary=l.went_free
	assert_int(int(went.count)).is_equal(bound)
	assert_str(String(went.words)).is_equal("When our men left Tsaren, the %d bound men there went free." % bound)
	assert_str(String(_sheet_town().status)).is_equal("theirs again")
	assert_str(Facts.text(Facts.sheet(["common","war"]))).contains(String(went.words))
	# Said once: one Chronicle entry, however often it is read.
	for i in 3: Ledger.of(civ_id,city_id); Ledger.settle_all()
	var told:=(GameState.chronicle.get("entries",[]) as Array).filter(func(e:Dictionary)->bool: return String(e.get("key","")).begins_with("went_free:"))
	assert_int(told.size()).is_equal(1)
	assert_str(String(told[0].text)).is_equal(String(went.words))
	_consistent("ledger, no garrison")

func test_a_town_ours_with_no_garrison_is_not_held()->void:
	var id:=_war_leader(_captured_tsaren())
	CC.hear(id,USERS_BIND)
	_withdraw(false)
	assert_str(String(Ledger.hold(civ_id,city_id).state)).is_equal("unguarded")
	_agree(false,"ours, unguarded")
	assert_str(String(_sheet_town().status)).is_equal("ours")
	assert_str(String(Fate.apply(civ_id,city_id,{"spare":true}).error)).contains("Tsaren is ours, but none of our fighters are there.")
	_consistent("ours, unguarded")

func test_a_ruin_we_hold_is_held_and_a_ruin_we_left_is_not()->void:
	var id:=_war_leader(_captured_tsaren())
	CC.hear(id,USERS_BIND)
	var held_ruin:=CC.hear(id,"Burn Tsaren and hold the ruins")
	assert_bool(bool(held_ruin.objective.burned)).override_failure_message(String(held_ruin.get("actor_says",""))).is_true()
	assert_str(String(Ledger.hold(civ_id,city_id).state)).is_equal("ruin_held")
	_agree(true,"ruin held")
	assert_str(String(Ownership.status({"city_id":city_id,"civ_id":civ_id}).kind)).is_equal("ruined")
	assert_str(String(_sheet_town().status)).is_equal("ruin")
	_consistent("ruin held")
	# Leaving the ruins: those we held there are let go and scatter, said once.
	var bound:=Ledger.count(Ledger.of(civ_id,city_id),"bound")
	var left:=CC.hear(id,"Leave Tsaren and come home")
	var says:=String(left.get("actor_says",""))
	assert_str(String(Ledger.hold(civ_id,city_id).state)).override_failure_message(says).is_equal("ruin")
	_agree(false,"ruin left")
	if bound>0:
		assert_str(says).contains("were let go")
		assert_int(Ledger.gone(Ledger.of(civ_id,city_id),"displaced")).is_greater_equal(bound)
	assert_str(String(Ownership.status({"city_id":city_id,"civ_id":civ_id}).kind)).is_equal("ruined")
	_consistent("ruin left")

# --------------------------------------------------------------------------
# The user's old save: settled on load, said once, every system agrees
# --------------------------------------------------------------------------

func test_old_records_are_adopted_within_the_town_itself()->void:
	_captured_tsaren()
	# Old counters that cannot all be true of a town of 202: 38 killed, 21
	# bound and 23 running are more men than it had.
	_old_build_records(202.0,38,60,21,23,"running")
	var l:=Ledger.of(civ_id,city_id)
	var start:=int(l.start)
	assert_int(start).is_equal(202+38+60)
	var men_ever:=Ledger.here(l,"men")+Ledger.running_men(l)+Ledger.gone(l,"killed","men")+Ledger.gone(l,"fled","men")+Ledger.gone(l,"taken","men")
	assert_int(men_ever).is_less_equal(roundi(float(start)*Ledger.SHARES.men)+1)
	assert_int(Ledger.gone(l,"killed")).is_equal(38)
	assert_int(Ledger.gone(l,"taken")).is_equal(60)
	# What could not be kept is said, once, in the Chronicle.
	assert_array(l.get("adopted_notes",[]) as Array).is_not_empty()
	var noted:=(GameState.chronicle.get("entries",[]) as Array).filter(func(e:Dictionary)->bool: return String(e.get("key",""))=="ledger_adopted:"+city_id)
	assert_int(noted.size()).is_equal(1)
	_consistent("adopted, bounded")

func test_the_users_old_save_is_settled_and_every_answer_agrees()->void:
	var id:=_users_tsaren()
	# The old build's leftover: 21 bound in a town nobody of ours holds.
	var raw:Dictionary=_region().ledger
	assert_int(int(raw.present.bound.men)).is_equal(21)
	# Loading the game settles it (save_system calls this), and the war leader
	# is told once.
	var filed:=Ledger.settle_all()
	var l:=Ledger.of(civ_id,city_id)
	assert_int(Ledger.count(l,"bound")).is_equal(0)
	assert_int(int(l.went_free.count)).is_equal(21)
	var words:="When our men left Tsaren, the 21 bound men there went free."
	assert_str(String(l.went_free.words)).is_equal(words)
	var told:=(GameState.chronicle.get("entries",[]) as Array).filter(func(e:Dictionary)->bool: return String(e.get("key","")).begins_with("went_free:"))
	assert_int(told.size()).is_equal(1)
	assert_bool(filed.size()<=1).is_true()
	_agree(false,"the user's Tsaren")
	_consistent("the user's Tsaren")
	var c:=Ledger.counts(civ_id,city_id)
	assert_int(int(c.killed_men)).is_equal(38)
	assert_int(int(c.fled_men)).is_equal(23)
	# "How many men of Tsaren are now bound?": offline, the sheet's numbers.
	voice.force_offline=true
	var said:=_ask(id,HOW_MANY_BOUND)
	assert_str(said).is_equal("None of Tsaren's men are bound now. "+words)
	# "Is that all of the men of Tsaren?": the whole account, from the same sheet.
	said=_ask(id,IS_THAT_ALL)
	assert_str(said).starts_with("No. Of Tsaren's men: ")
	assert_str(said).contains("%d free in their houses" % int(c.free_men))
	assert_str(said).contains("21 of them went free when our men left")
	assert_str(said).contains("38 killed")
	assert_str(said).contains("23 fled toward Stonefield")
	# The same answer is built from the sheet the live voice is given.
	var sheet:=Facts.sheet(["common","war"])
	assert_str(Answers.answer(sheet,IS_THAT_ALL)).is_equal(said)
	var text:=Facts.text(sheet)
	for n in ["38","23","21"]: assert_str(text).contains(n)

func test_live_answers_that_state_the_sheets_numbers_are_kept()->void:
	var id:=_users_tsaren()
	Ledger.settle_all()
	# The live voice states the sheet's numbers: kept, not thrown out as invented.
	_live([{"speaker_key":"envoy","text":"No, High Giver. 38 were killed and 23 fled toward Stonefield; the 21 we had bound went free when our men left.","aside":false}])
	var said:=_ask(id,IS_THAT_ALL)
	assert_str(said).is_equal("No, High Giver. 38 were killed and 23 fled toward Stonefield; the 21 we had bound went free when our men left.")
	var receipt:Dictionary=voice.usage[voice.usage.size()-1]
	assert_bool(bool(receipt.accepted)).override_failure_message(str(receipt)).is_true()
	assert_str(String(voice.status().label)).is_equal("Live voice · mock-voice")
	# The prompt carried the facts it needed.
	var prompt:=String(((sent[sent.size()-1] as Dictionary).messages as Array)[1].content)
	assert_str(prompt).contains("Killed since we took it: 38 (men 38)")
	assert_str(prompt).contains("When our men left Tsaren, the 21 bound men there went free.")
	for payload in sent: assert_str(JSON.stringify(payload)).not_contains(SECRET)

func test_when_the_live_line_fails_the_facts_still_answer_and_the_footer_says_why()->void:
	var id:=_users_tsaren()
	Ledger.settle_all()
	var expected:=Answers.answer(Facts.sheet(["common","war"]),IS_THAT_ALL)
	assert_str(expected).starts_with("No. ")
	# A number the facts do not have: the line is thrown out, the rule named.
	_live([{"speaker_key":"envoy","text":"No. 99 of them were killed.","aside":false}])
	assert_str(_ask(id,IS_THAT_ALL)).is_equal(expected)
	var receipt:Dictionary=voice.usage[voice.usage.size()-1]
	assert_str(String(receipt.reason)).contains("a number that is not in the facts (99)")
	assert_str(String(voice.status().label)).is_equal("Live voice · mock-voice · last line offline: the answer broke the court's rules: a number that is not in the facts (99)")
	# Cut off at the length limit, twice: the facts answer; the footer says so.
	_live([],"length")
	assert_str(_ask(id,IS_THAT_ALL)).is_equal(expected)
	assert_str(String(voice.status().label)).is_equal("Live voice · mock-voice · last line offline: the answer ran too long and was cut off")
	# The connection times out: the same.
	_live([],"stop",HTTPRequest.RESULT_TIMEOUT)
	assert_str(_ask(id,HOW_MANY_BOUND)).is_equal("None of Tsaren's men are bound now. When our men left Tsaren, the 21 bound men there went free.")
	assert_str(String(voice.status().label)).is_equal("Live voice · mock-voice · last line offline: the connection timed out")

func test_a_timed_out_reading_is_named_in_the_footer()->void:
	var id:=_users_tsaren()
	var out:=_say(id,GIRLS,{})
	assert_str(String(out.plan.route)).is_equal("legacy")
	assert_str(String(voice.status().label)).is_equal("Live voice · mock-voice · last order read offline: reading your words took too long, so the plain reading stood in")

func test_the_load_settles_an_older_save()->void:
	_users_tsaren()
	# The save keeps the old build's leftover exactly (nothing read it).
	var saved:=SaveSystem.save_game(slot)
	assert_bool(saved.has("error")).override_failure_message(str(saved)).is_false()
	# Saving read nothing: the file keeps the 21 bound exactly as the old build left them.
	assert_int(int((_region().ledger as Dictionary).present.bound.men)).is_equal(21)
	var loaded:=SaveSystem.load_game(slot)
	assert_bool(loaded.has("error")).override_failure_message(str(loaded)).is_false()
	var raw:Dictionary=_region().ledger
	assert_int(int(raw.present.bound.men)).is_equal(0)
	assert_int(int(raw.went_free.count)).is_equal(21)
	_consistent("loaded")

# --------------------------------------------------------------------------
# "Take all girls under 10 back to Seanstone"
# --------------------------------------------------------------------------

func test_the_girls_under_ten_is_one_band_of_the_children()->void:
	var kw:=Fate.kid_words("take all girls under 10 back to seanstone")
	assert_dict(kw.bands as Dictionary).is_equal({"girls_young":1.0})
	assert_str(String(kw.words)).is_equal("girls under ten")
	var fate:=Fate.fate_words("take all girls under 10 back to seanstone")
	assert_bool(bool(fate.captives)).is_true()
	assert_bool(fate.has("count")).override_failure_message("the age is not a number to take").is_false()
	assert_dict(fate.kids as Dictionary).is_equal({"girls_young":1.0})
	# Other sub-groups, from the same stated make-up.
	assert_array((Fate.kid_words("the boys").bands as Dictionary).keys()).contains_exactly_in_any_order(["boys_young","boys_older"])
	var under_five:Dictionary=Fate.kid_words("girls under five").bands
	assert_float(float(under_five.girls_young)).is_between(0.4,0.7)
	assert_dict(Fate.kid_words("the women and children")).is_empty()
	# The make-up adds up: about half girls, about 7 in 10 under ten.
	var shares:=Ledger.kid_shares()
	var total:=0.0
	for b in shares: total+=float(shares[b])
	assert_float(total).is_equal_approx(1.0,0.0001)
	assert_float(float(shares.girls_young)+float(shares.boys_young)).is_between(0.65,0.78)

func test_girls_under_ten_are_taken_exactly_when_the_town_is_held()->void:
	var id:=_war_leader(_captured_tsaren())
	var l:=Ledger.of(civ_id,city_id)
	var girls:=int(Ledger.kids(l,"free").girls_young)
	var boys:=int(Ledger.kids(l,"free").boys_young)
	var older:=int(Ledger.kids(l,"free").girls_older)
	assert_int(girls).is_greater(0)
	var force:=MilitaryCampaign.occupation_force_for_region(civ_id,city_id)
	var p:=Fate.round_up_odds(l,force)
	var day:=int(GameState.elapsed_days)
	var expected:=mini(Ledger.roll(Ledger.rng(city_id,day,"carry:enslaved"),girls,p),int(force.troops)*Fate.CAPTIVES_PER_FIGHTER)
	var before:=Ledger.snapshot(civ_id,city_id)
	var r:=CC.hear(id,GIRLS)
	var says:=String(r.get("actor_says",""))
	assert_str(String(r.war.verdict)).override_failure_message(says).is_equal("fate")
	var captives:=int(r.objective.captives)
	assert_int(captives).override_failure_message(says).is_equal(expected)
	# Only the girls under ten: no women, no boys, no older girls, no men.
	var b:=_balanced(before,"girls taken")
	assert_int(int(b.taken)).is_equal(captives)
	l=Ledger.of(civ_id,city_id)
	var taken:=Ledger.kids_gone(l,"taken")
	assert_int(int(taken.girls_young)).is_equal(captives)
	assert_int(int(taken.boys_young)+int(taken.girls_older)+int(taken.boys_older)).is_equal(0)
	assert_int(Ledger.gone(l,"taken","women")+Ledger.gone(l,"taken","men")+Ledger.gone(l,"taken","elders")).is_equal(0)
	assert_int(int(Ledger.kids(l,"free").boys_young)).is_equal(boys)
	assert_int(int(Ledger.kids(l,"free").girls_older)).is_equal(older)
	# Those who slipped away or ran are girls under ten too, and all add up.
	var ran_girls:=0
	var flight:=Ledger.running(l)
	if not flight.is_empty(): ran_girls=int((flight.groups as Dictionary).get("children",0))
	assert_int(int(Ledger.kids(l,"free").girls_young)+captives+ran_girls).is_equal(girls)
	# Said with the numbers and how it was decided.
	assert_str(says).contains("girls under ten of Tsaren (%d of them there)" % girls)
	assert_str(says).contains(Ledger.chance_words(p))
	assert_str(says).contains("%d were led away toward Seanstone as captives" % captives if captives>12 else "were led away toward Seanstone as captives")
	assert_int(int(Ledger.counts(civ_id,city_id).on_road)).is_equal(captives)
	_consistent("girls taken")
	# The facts know which children went.
	assert_int(int((_sheet_town().children_taken as Dictionary).get("girls under ten",0))).is_equal(captives)

func test_killing_the_boys_kills_only_the_boys()->void:
	# The same make-up for a grave order: "the boys" are never all the children.
	var fate:=Fate.fate_words("kill the boys of tsaren")
	assert_array(fate.get("kill_groups",[]) as Array).is_equal(["children"])
	assert_array((fate.get("kill_kids",{}) as Dictionary).keys()).contains_exactly_in_any_order(["boys_young","boys_older"])
	var id:=_war_leader(_captured_tsaren())
	var l:=Ledger.of(civ_id,city_id)
	var girls:=int(Ledger.kids(l,"free").girls_young)+int(Ledger.kids(l,"free").girls_older)
	var boys:=int(Ledger.kids(l,"free").boys_young)+int(Ledger.kids(l,"free").boys_older)
	var men:=Ledger.count(l,"free","men")
	var before:=Ledger.snapshot(civ_id,city_id)
	var r:=CC.hear(id,"Kill the boys of Tsaren")
	var says:=String(r.get("actor_says",""))
	assert_str(String(r.war.verdict)).override_failure_message(says).is_equal("fate")
	var b:=_balanced(before,"boys killed")
	l=Ledger.of(civ_id,city_id)
	var dead:=Ledger.kids_gone(l,"killed")
	assert_int(int(dead.boys_young)+int(dead.boys_older)).is_equal(int(b.killed))
	assert_int(int(dead.girls_young)+int(dead.girls_older)).is_equal(0)
	assert_int(int(Ledger.kids(l,"free").girls_young)+int(Ledger.kids(l,"free").girls_older)).is_equal(girls)
	assert_int(Ledger.count(l,"free","men")).is_equal(men)
	var ran:=0
	if not Ledger.running(l).is_empty(): ran=int((Ledger.running(l).groups as Dictionary).get("children",0))
	assert_int(int(b.killed)+ran).is_equal(boys)
	assert_str(says).contains("boys")
	assert_str(says).contains(Ledger.chance_words(float(r.war.fate.kill_odds)))
	_consistent("boys killed")

func test_girls_under_ten_on_the_reader_path_too()->void:
	var id:=_war_leader(_captured_tsaren())
	var girls:=int(Ledger.kids(Ledger.of(civ_id,city_id),"free").girls_young)
	var out:=_say(id,GIRLS,_reading("order","town_fate","group","town:"+city_id,0.95,{"captives":true}))
	assert_str(String(out.plan.route)).is_equal("engine")
	var r:Dictionary=out.result
	assert_str(String(r.war.verdict)).override_failure_message(String(r.get("actor_says",""))).is_equal("fate")
	var l:=Ledger.of(civ_id,city_id)
	assert_int(int(Ledger.kids_gone(l,"taken").girls_young)).is_equal(int(r.objective.captives))
	assert_int(Ledger.gone(l,"taken")).is_equal(int(r.objective.captives))
	assert_int(int(r.objective.captives)).is_less_equal(girls)
	_consistent("reader girls taken")

func test_girls_under_ten_when_the_town_is_not_ours_says_plainly_why()->void:
	var id:=_users_tsaren()
	Ledger.settle_all()
	# Fighters at home: the war leader could march if told.
	_train(20)
	# The audience has been speaking of Tsaren.
	voice.force_offline=true
	_ask(id,HOW_MANY_BOUND)
	voice.force_offline=false
	var before:=Ledger.snapshot(civ_id,city_id)
	var r:=CC.hear(id,GIRLS)
	var says:=String(r.get("actor_says",""))
	assert_str(String(r.war.verdict)).override_failure_message(says).is_equal("ask_march")
	assert_str(says).contains("Tsaren is the Esurai's again: our men left it. None of its people are in our hands.")
	assert_str(says).contains("To carry off its girls under ten we must take it again. Shall I march on it?")
	# Nothing happened: nobody taken, nobody moved, nothing marched.
	var b:=_balanced(before,"not ours")
	assert_int(int(b.taken)+int(b.killed)+int(b.fled)).is_equal(0)
	assert_array(MilitaryCampaign.occupation_transfers.data.transfers as Array).is_empty()
	# The reader's path says the same.
	var out:=_say(id,GIRLS,_reading("order","town_fate","group","town:"+city_id,0.95,{"captives":true}))
	var read:Dictionary=out.result
	assert_str(String(read.war.verdict)).is_equal("ask_march")
	assert_str(String(read.actor_says)).contains("Tsaren is the Esurai's again")
	assert_str(String(read.actor_says)).contains("girls under ten")
	# The reader was told Tsaren is not held.
	assert_str(OR.brief_text(OR.world_brief(id))).contains("NOT HELD: Tsaren is the Esurai's again: our men left it.")
