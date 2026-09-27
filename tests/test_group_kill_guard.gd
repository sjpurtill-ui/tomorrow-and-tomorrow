extends GdUnitTestSuite
## An order to kill or maim a people ("kill all the males of Tsaren") is a
## war order about a town, never a punishment of whoever stands in the hall.
## The user's live play: speaking with Kishan of Reedwater, Headman of
## Seanstone, the god said "I want you to kill all the males of Tsaren
## immediately" and the court executed Kishan. Pinned here:
## - held town: the garrison carries out the town's fate;
## - town not held: the war leader says it must be taken first and asks to
##   march; "yes" / "do it" sends a real march (or his honest objection);
## - the live reading (verb kill, a group object, even a hall member as its
##   target) cannot turn it on anyone here;
## - "do it" / "now" repeating the group order never lands on the addressee;
## - harm clearly aimed at one person here still reaches that person.

const CC:=preload("res://scripts/court_commands.gd")
const WO:=preload("res://scripts/court_war_orders.gd")
const Route:=preload("res://scripts/army_land_route.gd")
const Hall:=preload("res://scripts/audience_hall.gd")

const USERS_ORDER:="I want you to kill all the males of Tsaren immediately"
const VARIANTS:=[USERS_ORDER,"kill the men of Tsaren","slaughter every man in Tsaren","put Tsaren's men to the sword","Kill all the males of Tsaren now!"]

var home:=Vector2.ZERO
var city:=Vector2.ZERO
var city_id:=""
var civ_id:=""
var _processing:Dictionary={}

func _land(_p:Vector2)->bool:
	return true

func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]: _processing[node]=node.is_processing()
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

func _train(count:int)->void:
	MilitaryCampaign.military_inventory["improvised"]=int(MilitaryCampaign.military_inventory.get("improvised",0))+count
	MilitaryCampaign.raise_recruits(count)
	MilitaryCampaign.start_training("levy","improvised",count)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()

## Tsaren taken: 17 of the band hold it, one fighter with its leader.
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
	var source:Dictionary=MilitaryCampaign.field_armies[0]
	var factor:=maxf(.05,float(source.get("supply_level",1.0))*(.5+.5*clampf(float(source.get("readiness",.45))*.9,.15,1.0)))
	var garrison:=MilitaryCampaign.establish_occupation_force(civ_id,civ.strategic_regions[ri],floorf(17.0*factor),int(army.army_id))
	assert_int(int(garrison.get("troops",0))).is_equal(17)

## The Headman before the god: not the war leader.
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

## Nobody in the hall was struck: every official still stands, the one
## spoken to among them, and the result is a war order, not a punishment.
func _nobody_here_harmed(r:Dictionary,words:String,before:Array,headman:Dictionary)->void:
	var said:="%s -> stage %s, target %s: %s %s" % [words,String(r.get("stage","")),String(r.get("target_name","")),String(r.get("actor_says","")),String(r.get("outcome",""))]
	assert_bool(bool(r.get("handled",false))).override_failure_message(said).is_true()
	assert_str(String(r.get("verb",""))).override_failure_message(said).is_equal("war")
	assert_str(String(r.get("stage",""))).override_failure_message(said).starts_with("war_")
	assert_bool(bool(r.get("removed",false))).override_failure_message(said).is_false()
	assert_str(String(r.get("target_name",""))).override_failure_message(said).is_not_equal(String(headman.name))
	assert_array(_officials()).override_failure_message(said).is_equal(before)
	assert_bool(Hall._official(int(headman.person_id)).is_empty()).override_failure_message(said).is_false()


func test_held_town_every_variant_is_the_towns_fate_and_nobody_here_dies()->void:
	for words:String in VARIANTS:
		before_test(); _captured_tsaren()
		var headman:=_headman()
		var before:=_officials()
		var id:=_audience(headman)
		var r:=CC.hear(id,words)
		_nobody_here_harmed(r,words,before,headman)
		assert_str(String(r.war.verdict)).override_failure_message(words+" -> "+String(r.get("actor_says",""))).is_equal("fate")
		assert_str(String(r.objective.city_id)).is_equal(city_id)
		assert_int(int(r.objective.killed)).override_failure_message(words).is_greater(0)


func test_town_not_held_the_war_leader_asks_to_take_it_first()->void:
	_train(30)
	for words:String in VARIANTS:
		var headman:=_headman()
		var before:=_officials()
		var id:=_audience(headman)
		var r:=CC.hear(id,words)
		_nobody_here_harmed(r,words,before,headman)
		assert_str(String(r.war.verdict)).override_failure_message(words+" -> "+String(r.get("actor_says",""))).is_equal("ask_march")
		assert_str(String(r.actor_says)).contains("Tsaren is still theirs")
		assert_str(String(r.actor_says)).contains("take it first")
		assert_str(String(r.actor_says)).contains("march on it")
		assert_bool(bool(r.executed)).is_false()
		# Nothing marched on the words alone.
		assert_int(MilitaryCampaign.field_armies.size()).is_equal(0)
		# A real pending order waits for the god's yes.
		var pending:Dictionary=Hall.find(id).get("pending_command",{})
		assert_str(String(pending.get("verb",""))).is_equal("war")
		assert_bool(bool(pending.get("confirm",false))).is_true()
		Hall.find(id).erase("pending_command")


func test_yes_sends_a_real_march_on_the_town()->void:
	_train(30)
	var headman:=_headman()
	var before:=_officials()
	var id:=_audience(headman)
	var r:=CC.hear(id,USERS_ORDER)
	assert_str(String(r.war.verdict)).is_equal("ask_march")
	var yes:=CC.hear(id,"Yes")
	_nobody_here_harmed(yes,"Yes",before,headman)
	var verdict:=String(yes.war.verdict)
	assert_bool(verdict in ["act","object"]).override_failure_message(String(yes.get("actor_says",""))).is_true()
	if verdict=="act":
		assert_int(int(yes.objective.get("army_id",0))).is_greater(0)
		assert_str(String(yes.objective.get("city_id",""))).is_equal(city_id)
	else:
		# An honest objection with a reason; "do it" then overrides it.
		var again:=CC.hear(id,"do it")
		_nobody_here_harmed(again,"do it",before,headman)
		assert_str(String(again.war.verdict)).override_failure_message(String(again.get("actor_says",""))).is_equal("act")


func test_do_it_after_the_ask_marches_and_never_turns_on_the_headman()->void:
	_train(30)
	var headman:=_headman()
	var before:=_officials()
	var id:=_audience(headman)
	CC.hear(id,"kill the men of Tsaren")
	var r:=CC.hear(id,"do it")
	_nobody_here_harmed(r,"do it",before,headman)
	assert_bool(String(r.war.verdict) in ["act","object"]).override_failure_message(String(r.get("actor_says",""))).is_true()


func test_insisting_on_a_group_order_repeats_it_as_a_war_order()->void:
	# No pending order left (it was cleared): "now" repeats the last command.
	for held:bool in [true,false]:
		before_test()
		if held: _captured_tsaren()
		else: _train(30)
		var headman:=_headman()
		var before:=_officials()
		var id:=_audience(headman)
		CC.hear(id,USERS_ORDER)
		Hall.find(id).erase("pending_command")
		for words in ["now","do it","I demand it"]:
			var r:=CC.hear(id,words)
			_nobody_here_harmed(r,"%s (held %s)" % [words,held],before,headman)
			Hall.find(id).erase("pending_command")


func test_kill_them_all_while_speaking_of_tsaren()->void:
	for held:bool in [true,false]:
		before_test()
		if held: _captured_tsaren()
		else: _train(30)
		var headman:=_headman()
		var before:=_officials()
		var id:=_audience(headman)
		Hall.append_line(id,{"speaker":"You","role":"ruler","person_id":0,"civ_id":"","text":"What news of Tsaren?","day":Hall._day(),"aside":false})
		var r:=CC.hear(id,"Kill them all")
		_nobody_here_harmed(r,"Kill them all (held %s)" % held,before,headman)
		assert_str(String(r.war.verdict)).override_failure_message(String(r.get("actor_says",""))).is_equal("fate" if held else "ask_march")


func test_the_live_reading_cannot_turn_a_group_order_on_anyone_here()->void:
	for held:bool in [true,false]:
		before_test()
		if held: _captured_tsaren()
		else: _train(30)
		var headman:=_headman()
		var before:=_officials()
		var id:=_audience(headman)
		var lives:=[
			{"act":"command","verb":"kill","confidence":0.95,"object":"all the males of Tsaren","actor_ref":"you","target_ref":"all the males of Tsaren"},
			# A careless model naming the one spoken to as the victim.
			{"act":"command","verb":"kill","confidence":0.95,"object":"all the males of Tsaren","actor_ref":"","target_ref":String(headman.name)},
			{"act":"command","verb":"kill","confidence":0.95,"object":"the men of Tsaren","actor_ref":"you","target_ref":"him"},
		]
		for live:Dictionary in lives:
			for words:String in [USERS_ORDER,"Rid Tsaren of every one of its men"]:
				var r:=CC.hear(id,words,{"live":live,"echoed":true})
				_nobody_here_harmed(r,"%s / %s (held %s)" % [words,str(live),held],before,headman)
				Hall.find(id).erase("pending_command")


func test_a_group_target_from_the_live_reading_never_resolves_to_a_person()->void:
	var headman:=_headman()
	var id:=_audience(headman)
	var audience:=Hall.find(id)
	var list:=CC.roster(audience)
	for ref in ["all the males of Tsaren","the men of Tsaren","everyone in Tsaren","the villagers","them all"]:
		assert_dict(CC.resolve_ref(ref,audience,list,"")).override_failure_message(ref).is_empty()


func test_group_reading()->void:
	var headman:=_headman()
	var id:=_audience(headman)
	var list:=CC.roster(Hall.find(id))
	for words in VARIANTS+["Kill them all","maim every boy in Tsaren","slaughter the Esurai"]:
		assert_str(CC.harm_to_people(words,CC.classify(words),list)).override_failure_message(words).is_not_empty()
	for words in ["Kill him","Execute %s" % String(headman.name).get_slice(" ",0),"kill the headman","Kill him and all the men of Tsaren","kill the traitor","kill all the males of Tsaren, then kill him"]:
		assert_str(CC.harm_to_people(words,CC.classify(words),list)).override_failure_message(words).is_empty()


func test_harm_clearly_aimed_at_one_person_here_still_reaches_them()->void:
	var headman:=_headman()
	var id:=_audience(headman)
	var r:=CC.hear(id,"Kill him")
	assert_str(String(r.get("verb",""))).is_equal("kill")
	assert_str(String(r.get("target_name",""))).is_equal(String(headman.name))


func test_the_voice_never_promises_what_was_not_decided()->void:
	var rules:=FileAccess.get_file_as_string("res://scripts/audience_voice.gd")
	assert_str(rules).not_contains("When the ruler gives an order you are not told the outcome of, answer briefly and do not refuse.")
	assert_str(rules).contains("never say it is done or will be done")


func test_at_peace_harm_to_our_own_people_goes_to_the_council_not_a_person()->void:
	(CivilizationSystem.civilizations[0].player_relation as Dictionary).at_war=false
	var headman:=_headman()
	var before:=_officials()
	var id:=_audience(headman)
	var r:=CC.hear(id,"Kill all the rebels")
	assert_str(String(r.get("verb",""))).override_failure_message(str(r)).is_equal("order")
	assert_bool(bool(r.get("removed",false))).is_false()
	assert_array(_officials()).is_equal(before)
	assert_str(String(r.get("outcome",""))).not_contains("put to death")


func test_an_order_nobody_can_carry_out_is_never_promised()->void:
	var routed:=CC.custom_order("",{})
	if String(routed.get("route",""))=="recorded":
		assert_bool(bool(routed.ok)).is_false()
		assert_str(String(routed.outcome)).not_contains("to be carried out")
	var src:=FileAccess.get_file_as_string("res://scripts/court_commands.gd")
	assert_str(src).not_contains("It is remembered, to be carried out.")
