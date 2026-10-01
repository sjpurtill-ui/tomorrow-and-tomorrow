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
const Modal:=preload("res://scripts/hud/audience_modal.gd")
const Leaders:=preload("res://scripts/leader_commands.gd")

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

var _processing:Dictionary={}

func before_test()->void:
	# Remember which singletons were ticking so after_test can put them back.
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
	# Leave nothing behind for the next suite: the day jump to year 88 lets
	# ProgressionSystem raise its domain tiers (more workshop lines), and the
	# armies, officials, court matters and war ledger made here must not leak.
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
	# Armed, as the auto-arming now leaves a finished levy.
	MilitaryCampaign.military_inventory["improvised"]=int(MilitaryCampaign.military_inventory.get("improvised",0))+count
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
		if not MilitaryCampaign.active_engagement.is_empty() or not MilitaryCampaign.battle_history.is_empty() or MilitaryCampaign._field_army_index(army_id)<0: break
		GameState.elapsed_days+=1
		MilitaryCampaign._process_field_army_movement_day()
	# A hopeless garrison is overrun and settled on arrival (test_battle_scale.gd).
	assert_bool(not MilitaryCampaign.active_engagement.is_empty() or not MilitaryCampaign.battle_history.is_empty()).is_true()
	assert_bool(CivilizationSystem.civilizations[0].player_relation.at_war).is_true()

func test_the_users_actual_levy_is_told_the_truth()->void:
	# Home reserve 2; a levy of 20 in its first drill. They exist, so the war
	# leader objects with the real numbers; he never says "raise a levy".
	_train(2)
	_levy_in_drill(20)
	var id:=_marshal_audience()
	var modifiers:=GameState.active_modifiers.size()
	var r:=CC.hear(id,"Send our full forces into battle on Tsaren")
	assert_str(String(r.war.verdict)).is_equal("object")
	assert_str(String(r.war.reason)).is_equal("few_trained")
	assert_str(String(r.outcome)).is_equal("No one marches yet.")
	assert_str(String(r.actor_says)).contains("Only 2 have finished drill")
	assert_str(String(r.actor_says)).contains("20 more are in their first drill")
	assert_str(String(r.actor_says)).contains("say the word and I take all 22 as they are")
	assert_str(String(r.actor_says).to_lower()).not_contains("raise")
	assert_bool(bool(r.executed)).is_false()
	assert_array(MilitaryCampaign.field_armies).is_empty()
	assert_int(GameState.active_modifiers.size()).is_equal(modifiers)
	# "Take them as they are": the recruits leave the drill ground with the
	# drill they have, and all 22 march.
	var again:=CC.hear(id,"Take them as they are")
	assert_str(String(again.war.verdict)).override_failure_message(String(again.get("actor_says",""))).is_equal("act")
	assert_int(int(again.objective.troops)).is_equal(22)
	assert_int(int(again.objective.mustered)).is_equal(20)
	assert_array(MilitaryCampaign.training_queue).is_empty()
	assert_str(String(again.actor_says)).contains("straight off the drill ground")

func test_unknown_place_and_no_road_are_refused_with_the_reason()->void:
	_train(200)
	var id:=_marshal_audience()
	var r:=CC.hear(id,"Attack Qarthane at once")
	assert_str(String(r.war.reason)).is_equal("unknown_place")
	assert_str(String(r.actor_says)).contains("scouts")
	assert_str(String(r.outcome)).is_equal("No one marches.")
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
	# Everyday orders that only sound martial stay civic.
	for words in ["Hold the feast at home","Send men to Tsaren to trade","Destroy the old granary","Guard the stores","Fight the fire in the long house","Send envoys to Tsaren"]:
		assert_dict(WO.read(words)).override_failure_message(words).is_empty()

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

func test_offline_choices_reach_the_same_core()->void:
	_train(400)
	_set_garrison(20.0)
	var choices:=WO.offline_choices()
	var march:={}
	for c:Dictionary in choices:
		if String(c.label)=="March on Tsaren": march=c
	assert_dict(march).is_not_empty()
	var id:=_marshal_audience()
	var r:=CC.hear(id,String(march.params.command_text))
	assert_str(String(r.verb)).is_equal("war")
	assert_str(String(r.war.verdict)).is_equal("act")
	# Once an army is away, the court offers to bring it home.
	var labels:Array=[]
	for c:Dictionary in WO.offline_choices(): labels.append(String(c.label))
	assert_bool("Bring the army home" in labels).is_true()

func test_undrilled_levy_band_gets_an_objection_then_goes_if_the_god_insists()->void:
	# The user's roster: a Levy band of 20 at home that has never drilled, 2 in reserve.
	# No general was named for it, so it serves under the war leader at home
	# (leader_commands.gd): the Marshal speaks for it as his own band.
	_train(20)
	var levy:=int(MilitaryCampaign.create_field_army(20,"Levy band").army.army_id)
	for f in MilitaryCampaign.field_armies[0].formations: f["training"]=0.05
	_train(2)
	var id:=_marshal_audience()
	var r:=CC.hear(id,"Send our full forces into battle on Tsaren")
	assert_str(String(r.war.verdict)).is_equal("object")
	assert_str(String(r.war.reason)).is_equal("undrilled")
	assert_str(String(r.actor_says)).contains("My band is 20 strong")
	assert_str(String(r.actor_says)).contains("barely begun their drill")
	assert_str(String(r.actor_says)).contains("At home 2 more are trained")
	assert_str(String(r.actor_says)).contains("say the word and I take them as they are")
	assert_str(String(MilitaryCampaign.field_armies[0].status)).is_equal("stationed")
	var again:=CC.hear(id,"I demand it")
	assert_str(String(again.war.verdict)).is_equal("act")
	assert_int(int(again.objective.army_id)).is_equal(levy)
	assert_bool(bool(again.objective.own_band)).is_true()
	assert_str(String(MilitaryCampaign.field_armies[0].status)).is_equal("moving")

func test_the_war_leader_at_home_sends_the_strongest_of_his_bands()->void:
	# Bands serve under the war leader at home until the ruler names a general
	# for them (leader_commands.gd), so the Marshal leads every one of them:
	# told to attack, he sends the strongest that can go, not the first formed.
	_train(12)
	var small:=int(MilitaryCampaign.create_field_army(12,"LEVY BAND 1").army.army_id)
	_train(150)
	var large:=int(MilitaryCampaign.create_field_army(150,"LEVY BAND 2").army.army_id)
	_set_garrison(10.0)
	var id:=_marshal_audience()
	var r:=CC.hear(id,"Attack Tsaren")
	assert_str(String(r.war.verdict)).override_failure_message(String(r.get("actor_says",""))).is_equal("act")
	var objective:Dictionary=r.get("objective",{})
	assert_int(int(objective.get("army_id",0))).is_equal(large)
	assert_bool(bool(objective.get("own_band",false))).is_true()
	assert_int(int(objective.get("troops",0))).is_equal(150)
	assert_str(String(r.get("actor_says",""))).contains("My band of 150 marches")
	assert_str(String(MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(large)].status)).is_equal("moving")
	assert_str(String(MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(small)].status)).is_equal("stationed")
	# A band the ruler put under a general is that general's, never the Marshal's.
	MilitaryCampaign.field_armies.clear()
	_train(150)
	var led:=int(MilitaryCampaign.create_field_army(150,"LEVY BAND 3").army.army_id)
	var general:=Leaders.commission_general(MilitaryCampaign)
	assert_bool(Leaders.assign(MilitaryCampaign,led,String(general.get("figure_id",""))).has("error")).is_false()
	assert_dict(WO._band_of(WO.war_leader())).is_empty()
	assert_int(int(WO._band_of(WO.war_leader({"figure_id":String(general.figure_id)})).get("army_id",0))).is_equal(led)

# ---------------------------------------------------------------------------
# The war leader's own band (live report: "There's a band of 20 soldiers
# literally called 'Rovik's band'.")
# ---------------------------------------------------------------------------

## The user's roster: the war leader's own band of 20, camped about 25 km
## from home, barely begun its drill with 3 still unarmed; 2 trained at home;
## 20 more recruits in their first drill. The war leader is a general of
## renown: the ruler put the band under him, as the War screen and the
## Military Leaders screen do (leader_commands.gd); a new band serves under
## the war leader at home until then.
func _users_band()->Dictionary:
	_train(20)
	var made:=MilitaryCampaign.create_field_army(20,"LEVY BAND 1")
	var general:=Leaders.commission_general(MilitaryCampaign)
	assert_bool(general.has("error")).override_failure_message(str(general)).is_false()
	var put:=Leaders.assign(MilitaryCampaign,int((made.army as Dictionary).army_id),String(general.get("figure_id","")))
	assert_bool(put.has("error")).override_failure_message(str(put)).is_false()
	var army:Dictionary=MilitaryCampaign.field_armies[0]
	var first:=true
	for f in army.formations:
		f["training"]=0.04
		f["equipment_required"]=int(f.count)
		f["equipment"]=int(f.count)-3 if first else int(f.count)
		first=false
	var camp:=home+Vector2(0.0,25.0)
	army["position"]={"x":camp.x,"z":camp.y}
	army["location_id"]="field_camp"; army["location_name"]="FIELD POSITION"; army["status"]="stationed"
	_train(2)
	_levy_in_drill(20)
	return army

func _band_audience(army:Dictionary)->String:
	var figure:=String((army.commander as Dictionary).get("figure_id",""))
	assert_str(figure).is_not_empty()
	var audience:=Hall.summon({"figure_id":figure})
	assert_dict(audience).is_not_empty()
	return String(audience.id)

func test_war_leader_speaks_for_his_own_band_and_marches_it_when_the_god_insists()->void:
	var army:=_users_band()
	var army_id:=int(army.army_id)
	var given:=WO._given(String(army.commander.name))
	var id:=_band_audience(army)
	var r:=CC.hear(id,"Go attack Tsaren!")
	assert_str(String(r.verb)).is_equal("war")
	assert_str(String(r.war.verdict)).override_failure_message(String(r.get("actor_says",""))).is_equal("object")
	var says:=String(r.actor_says)
	assert_str(says).contains("My band is 20 strong")
	assert_str(says).contains("barely begun their drill")
	assert_str(says).contains("3 still lack weapons")
	assert_str(says).contains("about 25 km from home")
	assert_str(says).contains("2 more are trained")
	assert_str(says).contains("20 are in their first drill")
	assert_str(says).contains("say the word and I take them as they are")
	assert_str(says.to_lower()).not_contains("raise")
	assert_str(String(r.outcome)).is_equal("No one marches yet.")
	# Nothing moved.
	var index:=MilitaryCampaign._field_army_index(army_id)
	assert_str(String(MilitaryCampaign.field_armies[index].status)).is_equal("stationed")
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(2)
	# Offline, the court offers the god's answers to the objection.
	var labels:Array=[]
	for c:Dictionary in WO.offline_choices(id): labels.append(String(c.label))
	assert_bool("Take them as they are" in labels).override_failure_message(str(labels)).is_true()
	assert_bool("Drill them first" in labels).is_true()
	# The god insists: his band marches from where it stands, by the land road.
	var again:=CC.hear(id,"Take them as they are")
	assert_str(String(again.war.verdict)).override_failure_message(String(again.get("actor_says",""))).is_equal("act")
	assert_int(int(again.objective.army_id)).is_equal(army_id)
	assert_bool(bool(again.objective.own_band)).is_true()
	index=MilitaryCampaign._field_army_index(army_id)
	var band:Dictionary=MilitaryCampaign.field_armies[index]
	assert_str(String(band.status)).is_equal("moving")
	assert_str(String(band.destination_id)).is_equal(city_id)
	assert_float(float(band.origin_position.z)).is_equal_approx(home.y+25.0,0.01)
	assert_array(band.march_route).is_not_empty()
	# Days pass: the band walks only on land, from its camp to Tsaren.
	for day in 400:
		if String(MilitaryCampaign.field_armies[index].status)!="moving": break
		GameState.elapsed_days+=1
		MilitaryCampaign._process_field_army_movement_day()
		index=MilitaryCampaign._field_army_index(army_id)
		if index<0: break
		var p:Dictionary=MilitaryCampaign.field_armies[index].position
		assert_bool(_land(Vector2(float(p.x),float(p.z)))).override_failure_message("band stood in water on day %d" % day).is_true()
	# The home reserve and the recruits stayed where they were.
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(2)
	assert_str(String(again.actor_says)).contains("from where it stands")
	assert_str(String(again.actor_says)).contains("They go as they are")
	assert_str(String(again.outcome)).is_equal("%s's band sets out for Tsaren, about %d days by land." % [given,int(again.objective.days)])

func test_insisting_in_plain_words_also_marches_the_band()->void:
	var army:=_users_band()
	var id:=_band_audience(army)
	assert_str(String(CC.hear(id,"Attack Tsaren").war.verdict)).is_equal("object")
	var r:=CC.hear(id,"Go anyway")
	assert_str(String(r.get("verb",""))).is_equal("war")
	assert_str(String(r.war.verdict)).is_equal("act")
	assert_int(int(r.objective.army_id)).is_equal(int(army.army_id))

func test_drill_them_first_brings_the_band_home_to_drill()->void:
	var army:=_users_band()
	var id:=_band_audience(army)
	CC.hear(id,"Go attack Tsaren!")
	var r:=CC.hear(id,"Drill them first")
	assert_str(String(r.get("verb",""))).is_equal("war")
	assert_str(String(r.war.verdict)).override_failure_message(String(r.get("actor_says",""))).is_equal("act")
	assert_str(String(r.objective.kind)).is_equal("drill")
	var band:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(int(army.army_id))]
	assert_str(String(band.destination_id)).is_equal("player_home")
	assert_str(String(r.actor_says)).contains("of camp drill")

func test_offline_war_menu_names_his_band()->void:
	var army:=_users_band()
	var id:=_band_audience(army)
	var given:=WO._given(String(army.commander.name))
	var labels:Array=[]
	for c:Dictionary in WO.offline_choices(id): labels.append(String(c.label))
	assert_bool(("March %s's band on Tsaren" % given) in labels).override_failure_message(str(labels)).is_true()
	assert_bool(("Drill %s's band" % given) in labels).is_true()
	for c:Dictionary in WO.offline_choices(id):
		if String(c.label)==("March %s's band on Tsaren" % given):
			var r:=CC.hear(id,String(c.params.command_text))
			assert_str(String(r.war.verdict)).is_equal("object")
			assert_str(String(r.actor_says)).contains("My band is 20 strong")

func test_one_answer_said_once_in_the_hall()->void:
	var army:=_users_band()
	var id:=_band_audience(army)
	var voice:Node=auto_free(Voice.new())
	voice.force_offline=true
	var before:=(Hall.find(id).get("lines",[]) as Array).size()
	var r:=CC.hear(id,"Go attack Tsaren!")
	voice.command_reaction(id,r)
	var lines:Array=(Hall.find(id).get("lines",[]) as Array).slice(before)
	var seen:={}
	var band_lines:=0
	var notes:=0
	var day_number:=RegEx.new(); day_number.compile("(?i)\\bday \\d{3,}")
	for line:Dictionary in lines:
		var text:=String(line.text)
		assert_bool(seen.has(text)).override_failure_message("said twice: "+text).is_false()
		seen[text]=true
		if text.contains("20 strong"): band_lines+=1
		if text=="No one marches yet.": notes+=1
		assert_object(day_number.search(text)).is_null()
	assert_int(band_lines).override_failure_message(str(lines)).is_equal(1)
	assert_int(notes).override_failure_message(str(lines)).is_equal(1)
	# The war leader's words arrive whole, ending on a full stop.
	for line:Dictionary in lines:
		if String(line.text).contains("20 strong"): assert_bool(String(line.text).strip_edges().ends_with(".")).is_true()
	# The header reads naturally, on the Chronicle's calendar.
	var audience:=Hall.find(id)
	assert_str(String((audience.petition as Dictionary).summary)).starts_with("You sent for ")
	audience["expires_day"]=int(GameState.elapsed_days)+30
	var timing:=Modal.timing_words(audience)
	assert_str(timing).contains("Year ")
	assert_object(day_number.search(timing)).is_null()

func test_no_forces_at_all_is_the_only_raise_a_levy()->void:
	var id:=_marshal_audience()
	var r:=CC.hear(id,"Attack Tsaren")
	assert_str(String(r.war.verdict)).is_equal("impossible")
	assert_str(String(r.war.reason)).is_equal("no_forces")
	assert_str(String(r.actor_says)).contains("nobody under arms and nobody in drill")

# ---------------------------------------------------------------------------
# A strike by night; the captives of a fight
# ---------------------------------------------------------------------------

func test_a_sneak_attack_by_night_goes_with_the_men_asked_for_and_states_its_chance()->void:
	## The user's words in court: "Sneak attack Eldwick under cover of night.
	## With 17 troops." Here the town is Tsaren.
	_train(40)
	var id:=_marshal_audience()
	var words:="Sneak attack Tsaren under cover of night. With 17 troops."
	var reading:=WO.read(words)
	assert_str(String(reading.kind)).is_equal("attack")
	assert_str(String(reading.approach)).is_equal("night")
	assert_int(int(reading.count)).is_equal(17)
	var r:=CC.hear(id,words)
	var war:Dictionary=r.war
	assert_str(String(war.verdict)).override_failure_message(String(r.get("actor_says",""))).is_equal("act")
	assert_int(int(war.objective.troops)).is_equal(17)
	var chance:=float((war.surprise as Dictionary).chance)
	assert_str(String(r.actor_says)).contains("By night: 17 fighters against about 2 of theirs, 6 days on the road")
	assert_str(String(r.actor_says)).contains("The chance we reach Tsaren unseen is %s." % preload("res://scripts/battle_tactics.gd").chance_words(chance))
	# The march carries the stated chance to the attack; nothing is rolled yet.
	var army:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(int(war.objective.army_id))]
	assert_float(float(((army.city_operation as Dictionary).approach as Dictionary).chance)).is_equal_approx(chance,0.0001)
	assert_str(String((army.court_order as Dictionary).approach.kind)).is_equal("night")


func test_the_last_fights_captives_hold_up_no_march()->void:
	## The user's report: "no one marches: the last battle's captives and spoils
	## remain unsettled". A fight's aftermath is settled by the general at once.
	_train(40)
	MilitaryCampaign.pending_aftermath={"type":"surrender","captor":"x","home_force_name":"x","prisoners":5,"spoils":{}}
	MilitaryCampaign.settle_pending_aftermath()
	assert_dict(MilitaryCampaign.pending_aftermath).is_empty()
	var id:=_marshal_audience()
	var r:=CC.hear(id,"Attack Tsaren with 17 troops")
	assert_str(String(r.war.reason)).is_not_equal("busy")
	assert_str(String(r.get("actor_says",""))).not_contains("captives")

# ---------------------------------------------------------------------------
# Who answers for the war while no one holds the Marshal's office
# ---------------------------------------------------------------------------

## An early court: the government has not reached the Marshal's office yet.
func _no_marshal()->Dictionary:
	GovernmentPeopleSystem.reset_for_new_world()
	GameState.society_capacities["institutions"]=0.0
	GovernmentPeopleSystem.initialize()
	assert_dict(GovernmentPeopleSystem.officeholder("Marshal")).is_empty()
	var headman:=GovernmentPeopleSystem.officeholder("Steward")
	assert_dict(headman).is_not_empty()
	return headman

func test_with_no_marshal_the_armys_own_general_at_home_answers_for_the_war()->void:
	var headman:=_no_marshal()
	# The army puts a general at its head at home (military_campaign._marshal_commander):
	# the court's war leader is that same general, never another official.
	_train(30)
	var home:Dictionary=MilitaryCampaign.home_army.get("commander",{})
	assert_str(String(home.get("figure_id",""))).is_not_empty()
	var leader:=WO.war_leader()
	assert_str(String(leader.get("figure_id",""))).is_equal(String(home.figure_id))
	assert_bool(bool(leader.get("stand_in",false))).is_false()
	# Said to the headman, the order goes to that general.
	var id:=String(Hall.summon({"person_id":int(headman.person_id)}).id)
	var r:=CC.hear(id,"Attack Tsaren")
	assert_str(String(r.get("verb",""))).is_equal("war")
	assert_str(String(r.get("actor_name",""))).is_equal(String(leader.name))
	assert_str(String(r.get("actor_says",""))).not_contains("No one holds the Marshal's office")

## No Marshal, and no general to put at the army's head at home: every general
## dead and the roll of figures full, so none can come forward. The headman
## answers for the war and says so plainly, once in the audience.
func test_with_no_marshal_and_no_general_the_headman_stands_in_and_says_so_once()->void:
	var headman:=_no_marshal()
	_train(30)
	var day:=int(GameState.elapsed_days)
	for figure:Dictionary in HistoricalFigures.people:
		if String(figure.get("role",""))=="General" and String(figure.get("status",""))!="dead": HistoricalFigures.record_death(String(figure.id),day,"old age")
	while HistoricalFigures.living_count()<HistoricalFigures.MAX_LIVING:
		if HistoricalFigures._create("Scholar",day).is_empty(): break
	var leader:=WO.war_leader()
	assert_int(int(leader.get("person_id",0))).is_equal(int(headman.person_id))
	assert_bool(bool(leader.get("stand_in",false))).is_true()
	# Never another official: not the keeper of stores, not the pathfinder.
	for office in ["Quartermaster","ChiefScout"]:
		var other:=GovernmentPeopleSystem.officeholder(String(office))
		if not other.is_empty(): assert_int(int(leader.person_id)).is_not_equal(int(other.person_id))
	# He keeps his own sheets and gets the war's too.
	assert_array(preload("res://scripts/court_facts.gd").offices({"office_key":"Steward"},{"person_id":int(headman.person_id)})).contains(["war","stores"])
	var id:=String(Hall.summon({"person_id":int(headman.person_id)}).id)
	var r:=CC.hear(id,"Attack Tsaren")
	assert_str(String(r.get("verb",""))).is_equal("war")
	assert_str(String(r.get("actor_says",""))).starts_with(WO.STAND_IN_WORDS)
	var again:=CC.hear(id,"March on Tsaren")
	assert_str(String(again.get("verb",""))).is_equal("war")
	assert_str(String(again.get("actor_says",""))).not_contains("No one holds the Marshal's office")
