extends GdUnitTestSuite
## War orders at court reach the real armies, or are refused honestly.
## The user's report: "I ordered my court to send our full forces into battle
## on Tsaren. They say they would. Nothing happened." These tests pin:
## - a court war order forms a real army that marches (and shows its road);
## - the march goes round a bay by land instead of refusing (army_land_route);
## - impossible and unwise orders get a truthful answer with the reason;
## - no accepting answer without a created objective (guard);
## - the live reading (mocked) reaches the same core as the offline words;
## - a war order never lands in the generic directive path.

const CC:=preload("res://scripts/court_commands.gd")
const WO:=preload("res://scripts/court_war_orders.gd")
const Route:=preload("res://scripts/army_land_route.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Voice:=preload("res://scripts/audience_voice.gd")
const CustomDirective:=preload("res://scripts/custom_directive.gd")
const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")
const Marks:=preload("res://scripts/hud/army_marks.gd")

var home:=Vector2.ZERO
var city:=Vector2.ZERO
var city_id:=""
var civ_id:=""
var land_mode:="bay"

func _land(p:Vector2)->bool:
	match land_mode:
		"all": return true
		"islands": return p.distance_to(home)<3.0 or p.distance_to(city)<3.0
	# The user's chart: one landmass, the town across a bay from home.
	var mid:=(home+city)*0.5
	return p.distance_to(mid)>home.distance_to(city)*0.3

func before_test()->void:
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
	land_mode="bay"
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ["name"]="Tsaren"
	civ_id=String(civ.id)
	var relation:Dictionary=civ.player_relation
	relation.at_war=false; relation.treaty="none"; relation.contact_level=2; relation.home_location_known=true
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	region["name"]="Tsaren"
	city_id=String(region.id)
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",city_id,.8,int(GameState.elapsed_days),"scout report","test"),int(GameState.elapsed_days))
	home=CivilizationSystem.player_world_origin
	# The user's chart: Tsaren a few days' march south-west, across a bay.
	city=home+Vector2(-60.0,24.0)
	CivilizationSystem.city_intelligence.records.player[city_id]["position"]={"x":city.x,"z":city.y}
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))

func after_test()->void:
	CivilizationSystem.set_scout_geography_authority(Callable())
	Route.clear_cache()

func _train(count:int)->void:
	MilitaryCampaign.raise_recruits(count)
	MilitaryCampaign.start_training("levy","improvised",count)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()

func _levy_in_drill(count:int)->void:
	MilitaryCampaign.raise_recruits(count)
	MilitaryCampaign.start_training("levy","improvised",count)

func _marshal_audience()->String:
	var marshal:=GovernmentPeopleSystem.officeholder("Marshal")
	var target:={"person_id":int(marshal.get("person_id",0))} if not marshal.is_empty() else {"person_id":int((Hall._officials()[0] as Dictionary).person_id)}
	var audience:=Hall.summon(target)
	assert_dict(audience).is_not_empty()
	return String(audience.id)

func _set_garrison(mid:float)->void:
	var book:Dictionary=CivilizationSystem.city_intelligence.records.player
	var rec:Dictionary=book[city_id]
	rec.fields["garrison"]={"low":mid,"high":mid,"observed_day":int(GameState.elapsed_days),"reported_day":int(GameState.elapsed_days)}

# ---------------------------------------------------------------------------
# The road
# ---------------------------------------------------------------------------

func test_route_goes_round_a_bay_and_never_enters_water()->void:
	var began:=Time.get_ticks_msec()
	var path:=Route.find(home,city,Callable(self,"_land"),false)
	var ms:=Time.get_ticks_msec()-began
	assert_bool(path.get("ok",false)).override_failure_message(str(path)).is_true()
	assert_bool(bool(path.direct)).is_false()
	var prev:=home
	for p:Vector2 in path.points:
		assert_bool(Route.segment_land(prev,p,Callable(self,"_land"),0.05,0.0)).override_failure_message("leg %s -> %s crosses water" % [prev,p]).is_true()
		prev=p
	assert_float(float(path.length_km)).is_greater(home.distance_to(city))
	assert_float(float(path.length_km)).is_less(home.distance_to(city)*1.9)
	# Performance bound: bounded lattice and expansions, and quick.
	assert_int(int(path.expanded)).is_less_equal(Route.MAX_EXPANDED)
	assert_int(int(path.cells)).is_less_equal((Route.MAX_SIDE+2)*(Route.MAX_SIDE+2))
	assert_int(ms).is_less(4000)

func test_no_land_route_across_open_sea_is_bounded()->void:
	land_mode="islands"
	var path:=Route.find(home,city,Callable(self,"_land"),false)
	assert_str(String(path.get("reason",""))).is_equal("no_land_route")
	assert_int(int(path.get("expanded",0))).is_less_equal(Route.MAX_EXPANDED)

func test_field_move_follows_the_road_round_the_bay()->void:
	_train(120)
	var made:=MilitaryCampaign.create_field_army(100)
	var army_id:=int(made.army.army_id)
	var moved:=MilitaryCampaign.move_field_army(army_id,city_id)
	assert_bool(moved.get("ok",false)).override_failure_message(str(moved)).is_true()
	var index:=MilitaryCampaign._field_army_index(army_id)
	assert_array(MilitaryCampaign.field_armies[index].march_route).is_not_empty()
	for day in 400:
		if String(MilitaryCampaign.field_armies[index].status)!="moving": break
		GameState.elapsed_days+=1
		MilitaryCampaign._process_field_army_movement_day()
		var p:Dictionary=MilitaryCampaign.field_armies[index].position
		assert_bool(_land(Vector2(float(p.x),float(p.z)))).override_failure_message("army stood in water on day %d" % day).is_true()
	assert_str(String(MilitaryCampaign.field_armies[index].location_id)).is_equal(city_id)

# ---------------------------------------------------------------------------
# The user's order
# ---------------------------------------------------------------------------

func test_users_words_form_an_army_that_marches_on_tsaren()->void:
	_train(400)
	_set_garrison(40.0)
	var id:=_marshal_audience()
	var trained_before:=int(MilitaryCampaign.home_army.troops)
	var r:=CC.hear(id,"Send our full forces into battle on Tsaren")
	assert_bool(bool(r.get("handled",false))).is_true()
	assert_str(String(r.verb)).is_equal("war")
	assert_str(String(r.war.verdict)).override_failure_message(String(r.get("outcome",""))).is_equal("act")
	var army_id:=int(r.objective.army_id)
	assert_int(army_id).is_greater(0)
	var index:=MilitaryCampaign._field_army_index(army_id)
	var army:Dictionary=MilitaryCampaign.field_armies[index]
	assert_str(String(army.status)).is_equal("moving")
	assert_str(String(army.destination_id)).is_equal(city_id)
	assert_bool(army.has("city_operation")).is_true()
	assert_array(army.march_route).is_not_empty()
	assert_str(String(army.name)).contains("Tsaren")
	# Full forces: nobody trained stays behind.
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(0)
	assert_int(int(army.troops)).is_equal(trained_before)
	# The court says so plainly, with the days on the road; no declaration yet.
	assert_str(String(r.outcome)).contains("Tsaren")
	assert_str(String(r.outcome)).contains("days")
	assert_bool(CivilizationSystem.civilizations[0].player_relation.at_war).is_false()
	# A Chronicle line records it.
	var found:=false
	for e in GameState.chronicle.get("entries",[]):
		if String((e as Dictionary).get("key","")).begins_with("court_war:"): found=true
	assert_bool(found).is_true()
	# Map: the plan arrow follows the road, and the mark says where and when.
	var road:=Overlay._road_ahead(army,Vector2(float(army.position.x),float(army.position.z)))
	assert_int(road.size()).is_greater_equal(2)
	var doing:=Marks.doing({"status":"moving","destination_name":String(army.destination_name),"destination_id":city_id,"days_left":int(army.arrival_day)-int(GameState.elapsed_days)})
	assert_str(doing).contains("marching on")
	assert_str(doing).contains("days out")
	# Days pass: it arrives, the attack begins and war starts on contact.
	for day in 400:
		if not MilitaryCampaign.active_engagement.is_empty() or MilitaryCampaign._field_army_index(army_id)<0: break
		GameState.elapsed_days+=1
		MilitaryCampaign._process_field_army_movement_day()
	assert_dict(MilitaryCampaign.active_engagement).is_not_empty()
	assert_bool(CivilizationSystem.civilizations[0].player_relation.at_war).is_true()

func test_the_users_actual_levy_is_told_the_truth()->void:
	# Home reserve 2; a levy band of 20 in its first drill.
	_train(2)
	_levy_in_drill(20)
	var id:=_marshal_audience()
	var modifiers:=GameState.active_modifiers.size()
	var r:=CC.hear(id,"Send our full forces into battle on Tsaren")
	assert_str(String(r.war.verdict)).is_equal("impossible")
	assert_str(String(r.war.reason)).is_equal("too_few")
	assert_str(String(r.outcome)).contains("No soldiers march")
	assert_str(String(r.actor_says)).contains("2 trained")
	assert_str(String(r.actor_says)).contains("20 more are in their first drill")
	assert_bool(bool(r.executed)).is_false()
	assert_array(MilitaryCampaign.field_armies).is_empty()
	assert_int(GameState.active_modifiers.size()).is_equal(modifiers)

func test_unknown_place_and_no_road_are_refused_with_the_reason()->void:
	_train(200)
	var id:=_marshal_audience()
	var r:=CC.hear(id,"Attack Qarthane at once")
	assert_str(String(r.war.reason)).is_equal("unknown_place")
	assert_str(String(r.outcome)).contains("scouts")
	land_mode="islands"
	Route.clear_cache()
	var id2:=_marshal_audience()
	var r2:=CC.hear(id2,"March on Tsaren")
	assert_str(String(r2.war.reason)).is_equal("no_land_route")
	assert_str(String(r2.actor_says)).contains("boats")
	assert_array(MilitaryCampaign.field_armies).is_empty()

func test_general_objects_then_obeys_when_the_god_insists()->void:
	_train(60)
	_set_garrison(600.0)
	var id:=_marshal_audience()
	var r:=CC.hear(id,"Attack Tsaren")
	assert_str(String(r.war.verdict)).is_equal("object")
	assert_str(String(r.actor_says)).contains("600")
	assert_array(MilitaryCampaign.field_armies).is_empty()
	var again:=CC.hear(id,"I insist")
	assert_str(String(again.get("verb",""))).is_equal("war")
	assert_str(String(again.war.verdict)).is_equal("act")
	assert_int(int(again.objective.army_id)).is_greater(0)

func test_siege_raid_recall_defend_and_intercept_act_or_refuse()->void:
	_train(400)
	_set_garrison(20.0)
	var id:=_marshal_audience()
	var siege:=CC.hear(id,"Lay siege to Tsaren")
	assert_str(String(siege.war.verdict)).is_equal("act")
	assert_bool(bool(MilitaryCampaign.field_armies[0].city_operation.besiege)).is_true()
	for day in 3:
		GameState.elapsed_days+=1; MilitaryCampaign._process_field_army_movement_day()
	var recall:=CC.hear(id,"Bring the army home")
	assert_str(String(recall.war.verdict)).is_equal("act")
	assert_str(String(MilitaryCampaign.field_armies[0].destination_id)).is_equal("player_home")
	var again:=CC.hear(id,"March the army home")
	assert_str(String(again.war.reason)).is_equal("all_home")
	var defend:=CC.hear(id,"Defend the ford")
	assert_str(String(defend.war.verdict)).is_equal("act")
	assert_str(String(defend.actor_says)).contains("not a place on any chart")
	var intercept:=CC.hear(id,"Attack their army")
	assert_str(String(intercept.war.reason)).is_equal("no_sighting")
	# Raid, from the home reserve still there (the siege host is marching home).
	MilitaryCampaign.field_armies.clear()
	_train(100)
	var raid:=CC.hear(id,"Raid their fields")
	assert_str(String(raid.war.verdict)).override_failure_message(String(raid.outcome)).is_equal("act")
	var index:=MilitaryCampaign._field_army_index(int(raid.objective.army_id))
	assert_bool(bool(MilitaryCampaign.field_armies[index].city_operation.raid)).is_true()

func test_no_yes_without_an_objective()->void:
	# Guard: every war order either creates a real objective or says no.
	var phrasings:=["Send our full forces into battle on Tsaren","Go attack Tsaren now!","Attack Tsaren","March on Tsaren with every spear",
		"Storm Tsaren","Besiege Tsaren","Raid their fields","Attack their army","Defend the ford","March home","I want the army to march on Tsaren",
		"Take Tsaren","Destroy Tsaren","Crush Tsaren whatever the cost"]
	for troops in [0,3,400]:
		before_test()
		if troops>0: _train(troops)
		_set_garrison(30.0)
		for words:String in phrasings:
			var id:=_marshal_audience()
			var r:=CC.hear(id,words)
			assert_bool(bool(r.get("handled",false))).override_failure_message("not handled: "+words).is_true()
			assert_str(String(r.get("verb",""))).override_failure_message("%s -> %s" % [words,String(r.get("verb",""))]).is_equal("war")
			assert_str(String(r.get("route",""))).is_not_equal("custom_directive")
			var verdict:=String((r.get("war",{}) as Dictionary).get("verdict",""))
			if bool(r.get("executed",false)) or verdict=="act":
				var objective:Dictionary=r.get("objective",{})
				assert_bool(not objective.is_empty()).override_failure_message("yes without objective: "+words).is_true()
				if String(objective.get("kind",""))in ["attack","siege","raid","intercept"]:
					assert_int(MilitaryCampaign._field_army_index(int(objective.army_id))).is_greater_equal(0)
			else:
				assert_str(String(r.get("outcome",""))).is_not_empty()
				assert_str(String(r.get("actor_says",""))).is_not_empty()
			# Clear the road for the next phrasing.
			MilitaryCampaign.field_armies.clear()
			if troops>0 and int(MilitaryCampaign.home_army.troops)<troops: _train(troops-int(MilitaryCampaign.home_army.troops))

func test_questions_are_not_orders()->void:
	assert_dict(WO.read("Should we attack Tsaren?")).is_empty()
	assert_dict(WO.read("Can we march on Tsaren")).is_empty()
	assert_dict(WO.read("Strike him down")).is_empty()

func test_live_reading_reaches_the_same_core()->void:
	_train(400)
	_set_garrison(20.0)
	var id:=_marshal_audience()
	# The model's structured intent (mocked): verb war, object names the place.
	var live:={"act":"command","verb":"war","actor_ref":"you","target_ref":"","object":"attack Tsaren","confidence":0.9}
	var r:=CC.hear(id,"Deal with those people as I told you",{"live":live})
	assert_str(String(r.verb)).is_equal("war")
	assert_str(String(r.war.verdict)).is_equal("act")
	assert_int(int(r.objective.army_id)).is_greater(0)
	# The live schema lets the model say "war".
	var format:=Voice.response_format(["speaker"],[],true)
	var verbs:Array=format.json_schema.schema.properties.command.properties.verb.enum
	assert_bool("war" in verbs).is_true()
	# The voice is told what actually happened and the war leader's words.
	var told:=CC.decided_words(r)
	assert_str(told).contains("HAS set out")

func test_war_orders_never_become_directives()->void:
	_train(2)
	var routed:=CC.custom_order("Go attack Tsaren now!",{})
	assert_str(String(routed.route)).is_equal("war")
	var plan:={"summary":"Go attack Tsaren now!","natures":[]}
	var applied:=CustomDirective.apply(plan,30.0,"test",{},1.0)
	assert_bool(bool(applied.get("applied",true))).is_false()
