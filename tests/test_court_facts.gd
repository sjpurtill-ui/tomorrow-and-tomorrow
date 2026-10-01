extends GdUnitTestSuite
## Officials answer from exact fact sheets for their office (court_facts.gd;
## docs/ADJUDICATION.md), given to the live voice in every prompt, with the
## rule that they state the numbers and never invent ignorance. Stubbed HTTP:
## no network and no real key.
##
## The user's court: after Rovik reported "The men are bound.", the god asked
## "How many is there number?", "No, how many of the men of Tsaren are
## bound!?" and was told "I don't have their number." A stray line followed
## the report: "Nobody here answers to that; the court waits for you to name
## who you mean."

const CC:=preload("res://scripts/court_commands.gd")
const WO:=preload("res://scripts/court_war_orders.gd")
const M:=preload("res://scripts/occupation_measures.gd")
const Ledger:=preload("res://scripts/town_ledger.gd")
const Facts:=preload("res://scripts/court_facts.gd")
const Route:=preload("res://scripts/army_land_route.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const AiMode:=preload("res://scripts/ai_mode.gd")
const Voice:=preload("res://scripts/audience_voice.gd")

const USERS_SENTENCE:="Round up all the men of Tsaren and tie them up. If any resist or attempt to flee, threaten their wives and children."
const USERS_KILL:="Kill all the men of Tsaren that you have tied up!"
const SECRET:="sk-test-DO-NOT-LOG-0123456789"
const STRAY:="Nobody here answers to that"

var home:=Vector2.ZERO
var city:=Vector2.ZERO
var city_id:=""
var civ_id:=""
var voice:Node
var sent:Array=[]
var _processing:Dictionary={}

func _land(_p:Vector2)->bool:
	return true

func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]: _processing[node]=node.is_processing()
	AiMode.reset_for_tests("user://__court_facts_test_missing.cfg")
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
	GameState.resource_stockpiles["Food"]=4200.0
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
	region["position"]=city
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",city_id,.8,int(GameState.elapsed_days),"scout report","test"),int(GameState.elapsed_days))
	CivilizationSystem.city_intelligence.records.player[city_id]["position"]={"x":city.x,"z":city.y}
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))
	if voice==null or not is_instance_valid(voice):
		voice=Voice.new()
		add_child(voice)
	voice.force_offline=false
	voice.config_override={"endpoint":"https://mock.invalid/v1/chat/completions","api_key":SECRET,"model":"mock-voice","structured_output":true}
	sent.clear()
	# Stubbed transport: the request is kept, nothing goes out.
	voice.send_hook=func(_aid:String,payload:Dictionary,_attempt:int)->void: sent.append(payload)
	voice.order_hook=Callable()
	voice.usage.clear(); voice.last_problem.clear()

func after_test()->void:
	if voice!=null and is_instance_valid(voice):
		voice.send_hook=Callable()
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

func _train(count:int)->void:
	MilitaryCampaign.military_inventory["improvised"]=int(MilitaryCampaign.military_inventory.get("improvised",0))+count
	MilitaryCampaign.raise_recruits(count)
	MilitaryCampaign.start_training("levy","improvised",count)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()

func _captured_tsaren(troops:int=18)->Dictionary:
	_train(troops)
	var made:=MilitaryCampaign.create_field_army(troops,"LEVY BAND %d" % (MilitaryCampaign.field_armies.size()+1))
	var army_id:=int((made.army as Dictionary).army_id)
	var army:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(army_id)]
	army["supply_level"]=1.0; army["readiness"]=1.0
	army["position"]={"x":city.x+0.3,"z":city.y}
	army["location_id"]=city_id; army["location_name"]="Tsaren"; army["status"]="stationed"
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var ri:=CivilizationSystem._region_index(civ,city_id)
	civ.strategic_regions[ri]["controller"]="player"
	civ.strategic_regions[ri]["resistance"]=0.6
	MilitaryCampaign.establish_occupation_force(civ_id,civ.strategic_regions[ri],float(troops-1),army_id)
	# Every man stayed to hold the town: the band is its garrison now, its
	# general with it (no band of nobody is left behind).
	var at:=MilitaryCampaign._field_army_index(army_id)
	return MilitaryCampaign.field_armies[at] if at>=0 else MilitaryCampaign.occupation_force_for_region(civ_id,city_id)

## Rovik, the war leader of renown who leads the band.
func _war_leader(band:Dictionary)->String:
	var audience:=Hall.summon({"figure_id":String((band.commander as Dictionary).get("figure_id",""))})
	assert_dict(audience).is_not_empty()
	return String(audience.id)

## The ruler asks; the prompt that would go out is returned (nothing is sent).
func _ask(id:String,words:String)->Dictionary:
	sent.clear()
	voice.player_speaks(id,words)
	assert_int(sent.size()).override_failure_message("no live request for: "+words).is_greater(0)
	var payload:Dictionary=sent[sent.size()-1]
	voice._requests.erase(id)
	return {"system":String((payload.messages as Array)[0].content),"prompt":String((payload.messages as Array)[1].content)}

func _no_stray_line(id:String)->void:
	for line:Dictionary in Hall.find(id).get("lines",[]):
		assert_str(String(line.get("text",""))).not_contains(STRAY)

# --------------------------------------------------------------------------

func test_after_the_bind_order_the_war_leader_is_given_the_count()->void:
	var band:=_captured_tsaren()
	var id:=_war_leader(band)
	var r:=CC.hear(id,USERS_SENTENCE)
	assert_str(String(r.war.verdict)).is_equal("fate")
	var bound:=M.men_bound(civ_id,city_id)
	var c:=Ledger.counts(civ_id,city_id)
	# The sheet: the same ledger the garrison wrote.
	var sheet:=Facts.sheet(["common","war"])
	var tsaren:Dictionary=(sheet.towns as Array).filter(func(t:Dictionary)->bool: return String(t.name)=="Tsaren")[0]
	assert_int(int(tsaren.men_bound)).is_equal(bound)
	assert_int(int(tsaren.men_here)).is_equal(int(c.here_men))
	assert_int(int(tsaren.men_free)).is_equal(int(c.free_men))
	assert_int(int(tsaren.running_now)).is_equal(int(c.running))
	assert_int(int(tsaren.garrison)).is_equal(int(MilitaryCampaign.occupation_force_for_region(civ_id,city_id).troops))
	assert_array(tsaren.measures as Array).is_not_empty()
	# The prompt for "No, how many of the men of Tsaren are bound!?" carries it.
	var asked:=_ask(id,"No, how many of the men of Tsaren are bound!?")
	var prompt:String=asked.prompt
	assert_str(prompt).contains("WHAT OUR OWN PEOPLE KNOW")
	assert_str(prompt).contains("Men there now: %d (%d bound, %d free)" % [int(c.here_men),bound,int(c.free_men)])
	assert_str(prompt).contains("Men bound and under guard · %d" % bound)
	# The rule: state the numbers, never invent ignorance.
	assert_str(String(asked.system)).contains("Never claim not to know")
	assert_str(String(asked.system)).contains("say who would know or what would find it out")
	_no_stray_line(id)

func test_how_did_they_escape_is_answered_from_the_facts()->void:
	var band:=_captured_tsaren()
	var id:=_war_leader(band)
	CC.hear(id,USERS_SENTENCE)
	var bound:=M.men_bound(civ_id,city_id)
	var ran:=Ledger.running_total(Ledger.of(civ_id,city_id))
	CC.hear(id,USERS_KILL)
	var prompt:String=_ask(id,"How did they escape?").prompt
	# None of the bound got away: all were killed; the only ones who ran, ran
	# at the round-up, before they could be bound.
	assert_str(prompt).contains("Killed since we took it: %d (men %d)" % [bound,bound])
	assert_str(prompt).contains("none of the bound got away")
	assert_str(prompt).contains("The last flight: %d ran" % ran)
	assert_str(prompt).contains("Men there now:")
	assert_str(prompt).contains("(0 bound,")

func test_are_there_any_men_left_gives_the_count_by_status()->void:
	var band:=_captured_tsaren()
	var id:=_war_leader(band)
	CC.hear(id,USERS_SENTENCE)
	var c:=Ledger.counts(civ_id,city_id)
	var prompt:String=_ask(id,"Are there any men of Tsaren still remaining in Tsaren?").prompt
	assert_str(prompt).contains("%d people there now: %s." % [int(c.here),Ledger.here_words(c)])
	assert_str(prompt).contains("men: %d bound" % int(c.bound_men))
	CC.hear(id,USERS_KILL)
	c=Ledger.counts(civ_id,city_id)
	prompt=_ask(id,"Are there any men of Tsaren still remaining in Tsaren?").prompt
	assert_str(prompt).contains("Men there now: %d (0 bound, %d free)" % [int(c.here_men),int(c.free_men)])

func test_each_office_gets_its_own_sheet()->void:
	var band:=_captured_tsaren()
	CC.hear(_war_leader(band),USERS_SENTENCE)
	# The war leader: bands, garrisons and the town's ledger.
	var war:=Facts.text(Facts.sheet(Facts.offices({"title":"War leader"},{"title":"War leader"})))
	assert_str(war).contains("Garrisons:")
	assert_str(war).contains("Men there now:")
	# The headman: stores, water, houses, sickness, work, births and deaths.
	var steward:=GovernmentPeopleSystem.officeholder("Steward")
	assert_dict(steward).is_not_empty()
	var which:=Facts.offices({"office_key":"Steward","title":String(steward.get("office_title",""))},{"person_id":int(steward.person_id)})
	assert_array(which).contains(["stores"])
	assert_array(which).not_contains(["war"])
	var stores:=Facts.text(Facts.sheet(which))
	assert_str(stores).contains("Stores: 4200 Food")
	assert_str(stores).contains("Born this season:")
	assert_str(stores).contains("houses for 1000")
	# Everyone knows who is in Tsaren now, by status, but not the war's detail.
	assert_str(stores).contains("people there now:")
	assert_str(stores).not_contains("Garrisons:")
	# A foreign envoy is told nothing of what our people know.
	var s:={"origin":"foreign","audience":{},"envoy":{"persona":{}}}
	assert_str(voice.court_records(s)).is_empty()

func test_the_stray_line_never_follows_the_bind_report()->void:
	var band:=_captured_tsaren()
	var id:=_war_leader(band)
	var bind:=CC.hear(id,USERS_SENTENCE)
	assert_str(String(bind.war.verdict)).is_equal("fate")
	# Questions go to the voice with the facts, never to a person-verb.
	for words in ["How many is there number?","No, how many of the men of Tsaren are bound!?","How do you not know how MANY MEN ARE IN TSAREN THAT YOU'VE TIED UP!?"]:
		var r:=CC.hear(id,words)
		assert_bool(bool(r.get("handled",false))).override_failure_message(words).is_false()
	# Loose words about the town right after the report: talk, or the same
	# order for another group; never "nobody here answers to that".
	var loose:=CC.hear(id,"Exile them")
	assert_bool(bool(loose.get("handled",false))).override_failure_message(String(loose.get("outcome",""))).is_false()
	assert_str(String(loose.get("outcome",""))).not_contains(STRAY)
	var women:=CC.hear(id,"Take the women too")
	assert_str(String(women.get("verb",""))).is_equal("war")
	assert_str(String(women.get("outcome",""))).not_contains(STRAY)
	_no_stray_line(id)
	# Away from a town's business the plain reply stands.
	var elsewhere:=Hall.summon({"person_id":int(GovernmentPeopleSystem.officeholder("Steward").person_id)})
	var far:=CC.hear(String(elsewhere.id),"Exile them")
	assert_str(String(far.get("outcome",""))).contains(STRAY)

func test_the_offline_path_is_unchanged()->void:
	var band:=_captured_tsaren()
	var id:=_war_leader(band)
	CC.hear(id,USERS_SENTENCE)
	voice.force_offline=true
	sent.clear()
	var before:=(Hall.find(id).get("lines",[]) as Array).size()
	voice.player_speaks(id,"How many of the men of Tsaren are bound?")
	assert_int(sent.size()).is_equal(0)
	var lines:Array=Hall.find(id).get("lines",[])
	assert_int(lines.size()).is_greater(before+1)
	for line:Dictionary in lines.slice(before): assert_str(String(line.get("text",""))).not_contains(SECRET)
