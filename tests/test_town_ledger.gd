extends GdUnitTestSuite
## One ledger of a held town's people (town_ledger.gd; docs/ADJUDICATION.md):
## every order that touches them reads and writes it, the odds are stated and
## rolled once, the counts add up after every step, and the report, the map
## and the war leader's facts all read the same numbers.
##
## The user's court: Tsaren held by Rovik's band. "Round up all the men of
## Tsaren and tie them up. If any resist or attempt to flee, threaten their
## wives and children." Then "Kill all the men of Tsaren that you have tied
## up!" Then "How did they escape?" (none did: the bound cannot run). Then the
## women and girls taken to Seanstone, and Tsaren burned.

const CC:=preload("res://scripts/court_commands.gd")
const WO:=preload("res://scripts/court_war_orders.gd")
const OR:=preload("res://scripts/order_reader.gd")
const M:=preload("res://scripts/occupation_measures.gd")
const Fate:=preload("res://scripts/town_fate.gd")
const Ledger:=preload("res://scripts/town_ledger.gd")
const Pursuit:=preload("res://scripts/pursuit.gd")
const Held:=preload("res://scripts/held_town.gd")
const HeldDossier:=preload("res://scripts/hud/held_town_dossier.gd")
const Ownership:=preload("res://scripts/map_ownership.gd")
const Route:=preload("res://scripts/army_land_route.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const AiMode:=preload("res://scripts/ai_mode.gd")
const Voice:=preload("res://scripts/audience_voice.gd")

const USERS_SENTENCE:="Round up all the men of Tsaren and tie them up. If any resist or attempt to flee, threaten their wives and children."
const USERS_KILL:="Kill all the men of Tsaren that you have tied up!"
const SECRET:="sk-test-DO-NOT-LOG-0123456789"

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
	AiMode.reset_for_tests("user://__town_ledger_test_missing.cfg")
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
	home=CivilizationSystem.player_world_origin
	city=home+Vector2(-20.0,8.0)
	# The town stands a short walk from home (its site and our chart agree).
	region["position"]=city
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",city_id,.8,int(GameState.elapsed_days)-40,"scout report","test"),int(GameState.elapsed_days)-40)
	CivilizationSystem.city_intelligence.records.player[city_id]["position"]={"x":city.x,"z":city.y}
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))
	if voice==null or not is_instance_valid(voice):
		voice=Voice.new()
		add_child(voice)
	voice.force_offline=false
	voice.config_override={"endpoint":"https://mock.invalid/v1/chat/completions","api_key":SECRET,"model":"mock-voice","structured_output":true}
	voice.send_hook=Callable(); voice.order_hook=Callable()
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
	return MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(army_id)]

func _war_leader(band:Dictionary)->String:
	var audience:=Hall.summon({"figure_id":String((band.commander as Dictionary).get("figure_id",""))})
	assert_dict(audience).is_not_empty()
	return String(audience.id)

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

## The ledger adds up to the world's count, every figure whole and none below zero.
func _consistent(step:String)->void:
	var check:=Ledger.check(civ_id,city_id)
	assert_bool(bool(check.get("ok",false))).override_failure_message("%s: %s" % [step,str(check)]).is_true()

## Before, plus or minus what changed, equals after.
func _balanced(before:Dictionary,step:String)->Dictionary:
	var after:=Ledger.snapshot(civ_id,city_id)
	var b:=Ledger.balance(before,after)
	assert_bool(bool(b.ok)).override_failure_message("%s: %s" % [step,str(b)]).is_true()
	return b

# --------------------------------------------------------------------------
# The user's own words
# --------------------------------------------------------------------------

func test_the_bound_are_killed_and_none_of_them_run()->void:
	var band:=_captured_tsaren()
	var id:=_war_leader(band)
	var bind:=CC.hear(id,USERS_SENTENCE)
	assert_str(String(bind.war.verdict)).override_failure_message(String(bind.get("actor_says",""))).is_equal("fate")
	_consistent("bound")
	var l:=Ledger.of(civ_id,city_id)
	var bound:=Ledger.count(l,"bound","men")
	var free_men:=Ledger.count(l,"free","men")
	var ran:=Ledger.running_total(l)
	assert_int(bound).is_greater(0)
	assert_int(M.men_bound(civ_id,city_id)).is_equal(bound)
	var before:=Ledger.snapshot(civ_id,city_id)
	var kill:=CC.hear(id,USERS_KILL)
	var says:=String(kill.get("actor_says",""))
	assert_str(String(kill.war.verdict)).override_failure_message(says).is_equal("fate")
	# Exactly the bound men died; nobody bound ran; the free and the runners
	# were not touched.
	assert_int(int(kill.objective.killed)).is_equal(bound)
	var b:=_balanced(before,"killed the bound")
	assert_int(int(b.killed)).is_equal(bound)
	assert_int(int(b.fled)+int(b.taken)+int(b.displaced)).is_equal(0)
	l=Ledger.of(civ_id,city_id)
	assert_int(Ledger.count(l,"bound")).is_equal(0)
	assert_int(Ledger.gone(l,"killed","men")).is_equal(bound)
	assert_int(Ledger.count(l,"free","men")).is_equal(free_men)
	assert_int(Ledger.running_total(l)).is_equal(ran)
	_consistent("killed the bound")
	# Said with the numbers and how it was decided; no chase is offered.
	assert_str(says).contains("none could run")
	assert_str(says).contains(str(bound) if bound>12 else "")
	assert_str(says).not_contains("I can send")
	assert_str(says).not_contains("got away")
	var pending:Dictionary=Hall.find(id).get("pending_command",{}) if Hall.find(id).get("pending_command") is Dictionary else {}
	assert_str(String(pending.get("ask",""))).is_not_equal("chase")
	# The binding ended with nobody left to hold.
	assert_int(M.active(civ_id,city_id).filter(func(m:Dictionary)->bool: return String(m.id)=="bind_men").size()).is_equal(0)

func test_the_bound_are_killed_on_the_reader_path_too()->void:
	var band:=_captured_tsaren()
	var id:=_war_leader(band)
	CC.hear(id,USERS_SENTENCE)
	var bound:=M.men_bound(civ_id,city_id)
	var free_men:=Ledger.count(Ledger.of(civ_id,city_id),"free","men")
	var out:=_say(id,USERS_KILL,_reading("order","town_fate","group","town:"+city_id,0.95,{"kill_men":true}))
	assert_str(String(out.plan.route)).is_equal("engine")
	var r:Dictionary=out.result
	assert_str(String(r.war.verdict)).override_failure_message(String(r.get("actor_says",""))).is_equal("fate")
	assert_int(int(r.objective.killed)).is_equal(bound)
	assert_int(Ledger.count(Ledger.of(civ_id,city_id),"free","men")).is_equal(free_men)
	_consistent("reader kill")

func test_killing_the_free_men_states_the_odds_and_the_rest_run()->void:
	var band:=_captured_tsaren()
	var id:=_war_leader(band)
	var before:=Ledger.snapshot(civ_id,city_id)
	var men:=Ledger.count(before,"free","men")
	var r:=CC.hear(id,"Kill all the men of Tsaren")
	var fate:Dictionary=r.war.fate
	var killed:=int(r.objective.killed)
	var ran:=int(fate.kill_escaped)
	var odds:=float(fate.kill_odds)
	# Every man accounted for; the chance is the one stated, within what early
	# warfare shows (most who stand are caught, a good share get away).
	assert_int(killed+ran).is_equal(men)
	assert_float(odds).is_between(0.35,0.92)
	assert_str(String(r.actor_says)).contains(Ledger.chance_words(odds))
	assert_int(killed).is_less_equal(17*Fate.KILLS_PER_FIGHTER)
	var b:=_balanced(before,"killed the free")
	assert_int(int(b.killed)).is_equal(killed)
	assert_int(Ledger.running_total(Ledger.of(civ_id,city_id))).is_equal(ran)
	_consistent("killed the free")
	# The seeded roll: the same world, the same day, the same result.
	assert_int(Ledger.roll(Ledger.rng(city_id,int(GameState.elapsed_days),"kill:men"),men,odds)).is_equal(killed)
	# Those who ran are there to be chased.
	if ran>0:
		assert_str(String(r.actor_says)).contains("I can send")
		assert_str(String((Hall.find(id).get("pending_command",{}) as Dictionary).get("ask",""))).is_equal("chase")

# --------------------------------------------------------------------------
# Bind, kill, take the women and girls, burn: the ledger after every step
# --------------------------------------------------------------------------

func test_the_whole_sequence_leaves_a_ruin_that_is_ours_to_account_for()->void:
	var band:=_captured_tsaren()
	var id:=_war_leader(band)
	var start:=Ledger.snapshot(civ_id,city_id)
	var people:=int(start.population)
	# 1. Bind the men.
	CC.hear(id,USERS_SENTENCE)
	_consistent("1 bind")
	# 2. Kill the bound.
	var before:=Ledger.snapshot(civ_id,city_id)
	var kill:=CC.hear(id,USERS_KILL)
	var killed:=int(kill.objective.killed)
	var b:=_balanced(before,"2 kill")
	assert_int(int(b.killed)).is_equal(killed)
	_consistent("2 kill")
	# 3. The women and girls to Seanstone, as captives.
	before=Ledger.snapshot(civ_id,city_id)
	var take:=CC.hear(id,"Take the women and girls of Tsaren to Seanstone")
	var says:=String(take.get("actor_says",""))
	assert_str(String(take.war.verdict)).override_failure_message(says).is_equal("fate")
	var captives:=int(take.objective.captives)
	assert_int(captives).override_failure_message(says).is_greater(0)
	b=_balanced(before,"3 take")
	assert_int(int(b.taken)).is_equal(captives)
	var l:=Ledger.of(civ_id,city_id)
	assert_int(Ledger.gone(l,"taken","men")+Ledger.gone(l,"taken","elders")).is_equal(0)
	assert_int(int(Ledger.counts(civ_id,city_id).on_road)).is_equal(captives)
	_consistent("3 take")
	# 4. Burn Tsaren.
	before=Ledger.snapshot(civ_id,city_id)
	var burn:=CC.hear(id,"Burn Tsaren")
	says=String(burn.get("actor_says",""))
	assert_str(String(burn.war.verdict)).override_failure_message(says).is_equal("fate")
	assert_bool(bool(burn.objective.burned)).is_true()
	_balanced(before,"4 burn")
	_consistent("4 burn")
	# The ruin: nobody lives there, and it is not handed back to the Esurai.
	var region:=_region()
	assert_str(String(region.controller)).is_not_equal(civ_id)
	assert_float(float(region.population)).is_equal(0.0)
	assert_float(float(region.damage)).is_equal(1.0)
	assert_float(float(region.fortification)).is_equal(0.0)
	assert_dict(_force()).is_empty()
	assert_array(WO.held_towns()).is_empty()
	var c:=Ledger.counts(civ_id,city_id)
	assert_int(int(c.here)).is_equal(0)
	assert_int(int(c.killed)+int(c.taken)+int(c.fled)+int(c.displaced)).is_equal(people+int(c.joined)-int(c.lost))
	# Our own account, dated the day: exact, no report age, no ranges.
	var report:=Held.report(city_id)
	assert_str(String(report.get("kind",""))).is_equal("ruin")
	var lead:=String(report.lead)
	assert_str(lead).contains("Burned by us in the")
	assert_str(lead).contains("Before: %d people." % int((c.ruin as Dictionary).before))
	assert_str(lead).contains("Killed %d" % int(c.killed))
	assert_str(lead).contains("taken %d to Seanstone" % int(c.taken))
	assert_str(lead).contains("on the road")
	assert_str(lead).contains("fled")
	assert_str(lead).contains("Nobody lives there now.")
	var dossier:Control=auto_free(HeldDossier.new())
	add_child(dossier)
	dossier.setup({"report":report,"caption":""})
	var shown:=_texts(dossier).to_lower()
	for stale in ["aging","stale","days ago","reported","estimate","est."]: assert_str(shown).not_contains(stale)
	var dash:=RegEx.new(); dash.compile("\\d\\s*[–-]\\s*\\d")
	assert_object(dash.search(shown)).override_failure_message(shown).is_null()
	# The chart: ruined, from our own record, not the Esurai's town.
	var status:=Ownership.status({"city_id":city_id,"civ_id":civ_id})
	assert_str(String(status.kind)).is_equal("ruined")
	assert_str(String(status.note)).contains("Burned by us")
	assert_str(String(status.note)).contains("nobody lives there")
	# 5. The captives reach Seanstone and are counted among us.
	var ours_before:=int(GameState.population_total)
	for t:Dictionary in MilitaryCampaign.occupation_transfers.data.transfers: t["traveled"]=float(t.distance)
	MilitaryCampaign.occupation_transfers.advance(int(GameState.elapsed_days)+1)
	c=Ledger.counts(civ_id,city_id)
	assert_int(int(c.on_road)).is_equal(0)
	assert_int(int(c.arrived)).is_equal(captives)
	assert_int(int(GameState.population_total)).is_equal(ours_before+captives)
	assert_str(String(Held.report(city_id).lead)).contains("%d arrived" % captives)

func test_the_ruin_is_lived_in_again_only_by_its_own_event()->void:
	var band:=_captured_tsaren()
	var id:=_war_leader(band)
	CC.hear(id,"Burn Tsaren")
	var l:=Ledger.of(civ_id,city_id)
	var rs:Dictionary=(l.ruin as Dictionary).resettle
	# The odds and the day are set once, when we left it; bounded.
	assert_float(float(rs.chance)).is_between(0.05,0.85)
	assert_int(int(rs.day)).is_between(int(GameState.elapsed_days)+Fate.RESETTLE_DAYS[0],int(GameState.elapsed_days)+Fate.RESETTLE_DAYS[1])
	assert_int(int(rs.learn_day)).is_greater(int(rs.day))
	# Days pass before its day: still our ruin, nobody's, nobody living there.
	var filed:=0
	for d in 5:
		GameState.elapsed_days+=1
		filed+=Fate.daily(int(GameState.elapsed_days)).size()
	assert_int(filed).is_equal(0)
	assert_str(String(_region().controller)).is_equal("player")
	# Say the roll went their way: on its day their people come back, and we
	# hear of it later, once.
	rs["happens"]=true; rs["day"]=int(GameState.elapsed_days)+1; rs["learn_day"]=int(GameState.elapsed_days)+3
	GameState.elapsed_days+=1
	Fate.daily(int(GameState.elapsed_days))
	assert_str(String(_region().controller)).is_equal(civ_id)
	# Our people do not know yet: the chart and the report still show our own
	# account, and nobody at court says what our people have not seen.
	assert_str(String(Ownership.status({"city_id":city_id,"civ_id":civ_id}).kind)).is_equal("ruined")
	assert_str(String(Held.report(city_id).lead)).contains("Nobody lives there now.")
	assert_str(String(Ownership.status({"city_id":city_id,"civ_id":civ_id}).note)).contains("nobody lives there")
	var told:Array=[]
	for d in 3:
		GameState.elapsed_days+=1
		told.append_array(Fate.daily(int(GameState.elapsed_days)))
	assert_int(told.size()).is_equal(1)
	assert_dict(Ledger.our_ruin(city_id)).is_empty()
	assert_str(String(Ownership.status({"city_id":city_id,"civ_id":civ_id}).kind)).is_not_equal("occupied")
	var entries:=(GameState.chronicle.get("entries",[]) as Array).filter(func(e:Dictionary)->bool: return String(e.get("key","")).begins_with("ruin_resettled:"))
	assert_int(entries.size()).is_equal(1)
	assert_str(String(entries[0].text)).contains("come back to live in the ruins of Tsaren")

func test_a_ruin_held_by_a_garrison_stays_ours()->void:
	var band:=_captured_tsaren()
	var id:=_war_leader(band)
	CC.hear(id,USERS_SENTENCE)
	var bound:=M.men_bound(civ_id,city_id)
	var r:=CC.hear(id,"Burn Tsaren and hold the ruins")
	assert_bool(bool(r.objective.burned)).override_failure_message(String(r.get("actor_says",""))).is_true()
	assert_dict(_force()).is_not_empty()
	var l:=Ledger.of(civ_id,city_id)
	# The free scattered; those we hold stay under guard.
	assert_int(Ledger.count(l,"free")).is_equal(0)
	assert_int(Ledger.count(l,"bound","men")).is_equal(bound)
	assert_bool(bool((l.ruin as Dictionary).held)).is_true()
	assert_dict((l.ruin as Dictionary).resettle).is_empty()
	_consistent("held ruin")
	var status:=Ownership.status({"city_id":city_id,"civ_id":civ_id})
	assert_str(String(status.kind)).is_equal("ruined")
	assert_str(String(status.emblem)).is_equal("player")
	# Nothing to attack there: said plainly.
	assert_str(String(Held.report(city_id).kind)).is_equal("ruin")

# --------------------------------------------------------------------------
# Follow-ups and the stray line
# --------------------------------------------------------------------------

func test_the_women_too_binds_the_women()->void:
	var band:=_captured_tsaren(30)
	var id:=_war_leader(band)
	CC.hear(id,USERS_SENTENCE)
	var women:=Ledger.count(Ledger.of(civ_id,city_id),"free","women")
	var r:=CC.hear(id,"The women too")
	assert_str(String(r.get("verb",""))).is_equal("war")
	assert_str(String(r.war.verdict)).override_failure_message(String(r.get("actor_says",""))).is_equal("fate")
	var l:=Ledger.of(civ_id,city_id)
	assert_int(Ledger.count(l,"bound","women")).is_greater(0)
	assert_int(Ledger.count(l,"bound","women")+Ledger.count(l,"free","women")+int(Ledger.running(l).get("groups",{}).get("women",0))).is_equal(women)
	assert_str(String(r.actor_says)).contains("women")
	_consistent("women too")

func test_an_order_to_kill_names_whom_it_kills()->void:
	assert_array(Fate.fate_words("kill the women of tsaren").get("kill_groups",[]) as Array).is_equal(["women"])
	assert_bool(Fate.fate_words("kill all the males and take the women and girls to seanstone").has("kill_groups")).is_false()
	assert_bool(bool(Fate.fate_words("kill all the men of tsaren that you have tied up!").get("bound_only",false))).is_true()
	assert_bool(bool(Fate.fate_words("kill all the men of tsaren").get("bound_only",false))).is_false()
	var band:=_captured_tsaren()
	var id:=_war_leader(band)
	var men:=Ledger.count(Ledger.of(civ_id,city_id),"free","men")
	var women:=Ledger.count(Ledger.of(civ_id,city_id),"free","women")
	var r:=CC.hear(id,"Kill the women of Tsaren")
	assert_str(String(r.war.verdict)).override_failure_message(String(r.get("actor_says",""))).is_equal("fate")
	var l:=Ledger.of(civ_id,city_id)
	assert_int(Ledger.gone(l,"killed","men")).is_equal(0)
	assert_int(Ledger.count(l,"free","men")).is_equal(men)
	assert_int(Ledger.gone(l,"killed","women")+int((Ledger.running(l).get("groups",{}) as Dictionary).get("women",0))).is_equal(women)
	assert_str(String(r.actor_says)).contains("women")
	_consistent("killed the women")

func test_the_bound_women_are_taken_first_and_none_slip_away()->void:
	var band:=_captured_tsaren(30)
	var id:=_war_leader(band)
	CC.hear(id,USERS_SENTENCE)
	CC.hear(id,"The women too")
	var bound_women:=Ledger.count(Ledger.of(civ_id,city_id),"bound","women")
	assert_int(bound_women).is_greater(0)
	var before:=Ledger.snapshot(civ_id,city_id)
	var r:=CC.hear(id,"Take the women of Tsaren to Seanstone")
	var says:=String(r.get("actor_says",""))
	assert_str(String(r.war.verdict)).override_failure_message(says).is_equal("fate")
	var b:=_balanced(before,"take the bound women")
	assert_int(int(r.objective.captives)).is_equal(int(b.taken))
	# Those we held went first; none of them could slip away.
	assert_int(Ledger.count(Ledger.of(civ_id,city_id),"bound","women")).is_equal(maxi(0,bound_women-int(b.taken)))
	assert_str(says).contains("could not slip away")
	_consistent("taken the bound women")

func test_the_women_too_after_a_killing_is_asked_once()->void:
	var band:=_captured_tsaren()
	var id:=_war_leader(band)
	CC.hear(id,USERS_SENTENCE)
	CC.hear(id,USERS_KILL)
	var women:=Ledger.count(Ledger.of(civ_id,city_id),"free","women")
	var asked:=CC.hear(id,"Now the women too")
	assert_str(String(asked.war.verdict)).is_equal("ask")
	assert_str(String(asked.actor_says)).contains("The women of Tsaren as well?")
	assert_int(Ledger.count(Ledger.of(civ_id,city_id),"free","women")).is_equal(women)
	# "Bind them" picks that choice: nobody dies.
	var picked:=CC.hear(id,"bind them")
	assert_str(String(picked.war.verdict)).override_failure_message(String(picked.get("actor_says",""))).is_equal("fate")
	assert_int(Ledger.count(Ledger.of(civ_id,city_id),"bound","women")).is_greater(0)
	assert_int(Ledger.gone(Ledger.of(civ_id,city_id),"killed","women")).is_equal(0)
	_consistent("asked once")

func _texts(node:Node)->String:
	var out:PackedStringArray=[]
	if node is Label: out.append((node as Label).text)
	for child in node.get_children(): out.append(_texts(child))
	return "\n".join(out)
