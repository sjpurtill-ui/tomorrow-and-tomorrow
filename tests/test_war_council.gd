extends GdUnitTestSuite
## THE WAR COUNCIL (war_council.gd): one planner for every people, the god's
## own included, acting on a stance toward each people with the REAL army
## (MilitaryCampaign field armies, their land roads, the combat simulator,
## sieges and garrisons). The user: "Military needs to be stupidly simple, but
## not UNIT BASED... You assign units to a LEADER's command... The leader sees
## to supply, logistics, organization, pacing." These tests pin each stance
## with real bands, a rival's council against another rival, no double strike
## in a formal war, and a sane cadence over years.

const Council:=preload("res://scripts/war_council.gd")
const WAR:=preload("res://scripts/war_loop.gd")
const Odds:=preload("res://scripts/war_odds.gd")
const Route:=preload("res://scripts/army_land_route.gd")
const Board:=preload("res://scripts/hud/war_board.gd")
const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")
const Orders:=preload("res://scripts/army_orders.gd")

var civ_id:=""
var city_id:=""
var city:=Vector2.ZERO
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
	relation.at_war=false; relation.treaty="none"; relation.contact_level=2; relation.home_location_known=true; relation.met_day=0
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	region["name"]="Tsaren"
	city_id=String(region.id)
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",city_id,.8,int(GameState.elapsed_days),"scout report","test"),int(GameState.elapsed_days))
	city=CivilizationSystem.player_world_origin+Vector2(-20.0,8.0)
	_place_town(city)
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))
	_bring_near(CivilizationSystem.civilizations[0])

## Tsaren stands here, in the world and on our chart alike (a battle's report
## charts the town again where it truly stands).
func _place_town(at:Vector2)->void:
	city=at
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	for region in civ.strategic_regions:
		if String((region as Dictionary).get("id",""))==city_id: (region as Dictionary)["position"]=at
	CivilizationSystem.city_intelligence.records.player[city_id]["position"]={"x":at.x,"z":at.y}

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
	WorldSimulation.context_provider=Callable()
	for node:Node in _processing: node.set_process(bool(_processing[node]))

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Trained and armed fighters at home (the levy, finished drill).
func _train(count:int,drill:float=0.6)->void:
	MilitaryCampaign.military_inventory["improvised"]=int(MilitaryCampaign.military_inventory.get("improvised",0))+count
	MilitaryCampaign.raise_recruits(count)
	MilitaryCampaign.start_training("levy","improvised",count)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()
	for f in MilitaryCampaign.home_army.get("formations",[]): (f as Dictionary)["training"]=maxf(float((f as Dictionary).get("training",0.0)),drill)

## Our scouts' count of the fighters in Tsaren.
func _counted(mid:float)->void:
	var rec:Dictionary=CivilizationSystem.city_intelligence.records.player[city_id]
	rec.fields["garrison"]={"low":mid,"high":mid,"observed_day":int(GameState.elapsed_days),"reported_day":int(GameState.elapsed_days)}

## Their real fighters: the aggregate the town's defence is drawn from.
func _their_men(n:float)->void:
	CivilizationSystem.civilizations[0]["military_population"]=n

## Days pass: the army marches and fights, battles are fought out, the war
## ledger counts and the council sits when it is due.
func _days(n:int,stop:Callable=Callable())->void:
	for i in n:
		GameState.elapsed_days=int(GameState.elapsed_days)+1
		var day:=int(GameState.elapsed_days)
		MilitaryCampaign.last_processed_day=day
		MilitaryCampaign._process_military_day()
		for e in MilitaryCampaign.own_engagements.values(): (e as Dictionary).erase("awaiting_player_view")
		WAR.daily(day)
		Council.day(day)
		if stop.is_valid() and bool(stop.call()): return

func _band(act:String)->Dictionary:
	for a in MilitaryCampaign.field_armies:
		var c:Variant=(a as Dictionary).get("council")
		if c is Dictionary and String((c as Dictionary).get("act",""))==act: return a
	return {}

func _held()->bool:
	return String(CivilizationSystem.region_snapshot(civ_id,city_id).get("controller",""))=="player"

# ---------------------------------------------------------------------------
# Take a town
# ---------------------------------------------------------------------------

func test_take_waits_for_three_to_two_then_marches_besieges_or_storms_and_garrisons()->void:
	_their_men(8.0)
	_counted(60.0)
	_train(40)
	WAR.blood_feud(civ_id,int(GameState.elapsed_days),"the killing of their envoy Qira")
	var place:={"city_id":city_id,"civ_id":civ_id,"name":"Tsaren","position":{"x":city.x,"z":city.y}}
	# 40 against the 60 our scouts counted behind walls: short of 3 to 2. The
	# war leader waits and says how many more would make it.
	var first:=Council.order(civ_id,"take",{"place":place})
	assert_bool(String(first.verdict) in ["object","wait"]).override_failure_message(str(first)).is_true()
	assert_str(String(first.says)).contains("3 to 2")
	assert_str(String(first.says)).contains("more would make it")
	assert_dict(_band("take")).is_empty()
	assert_str(String(WAR.front(civ_id).get("stance",""))).is_equal("take")
	assert_str(Council.operation_words(civ_id)).is_not_empty()
	# The levy grows (the god raised the share): the council, sitting, finds
	# the odds and goes by the land road.
	_train(260)
	Council.sit(int(GameState.elapsed_days))
	var band:=_band("take")
	assert_dict(band).override_failure_message(str(Council.peek(civ_id))).is_not_empty()
	assert_str(String(band.status)).is_equal("moving")
	assert_str(String(band.destination_id)).is_equal(city_id)
	assert_bool(band.has("city_operation")).is_true()
	assert_array(band.get("march_route",[])).is_not_empty()
	# The watch stays home.
	assert_int(int(MilitaryCampaign.home_army.troops)).is_greater(0)
	# The War screen says it in one plain line.
	var said:=Council.operation_words(civ_id)
	assert_str(said).contains("Tsaren")
	assert_str(said).contains("there in about")
	# Days pass: they arrive, fight or lay siege, and Tsaren changes hands.
	_days(240,func()->bool:return _held() and _band("take").is_empty())
	assert_bool(_held()).override_failure_message("Tsaren never fell: %s / %s" % [str(Council.peek(civ_id)),str(MilitaryCampaign.battle_history.map(func(b:Dictionary)->String:return String(b.get("message",""))))]).is_true()
	# A garrison of ours holds it, out of the band that took it.
	var garrison:=MilitaryCampaign.occupation_force_for_region(civ_id,city_id)
	assert_int(int(garrison.get("troops",0))).is_greater(0)
	# Taken: the stance is to hold what we took, and the rest come home.
	assert_str(String(WAR.front(civ_id).get("stance",""))).is_equal("defend")
	# The fight is in the war ledger, counted once.
	assert_int(int(WAR.front(civ_id).get("strikes",0))).is_greater_equal(1)

## "Bring me their chief": a band strikes at their chief town; beating its
## defenders, it takes their chief, who is ransomed, and the feud is sworn
## off (war_loop chief_taken), as the court's words promise. No town is held,
## and the engine's war flag comes down with the band home.
func test_bring_me_their_chief_strikes_their_chief_town_and_they_ransom_him()->void:
	for region in CivilizationSystem.civilizations[0].strategic_regions:
		var r:Dictionary=region
		if String(r.get("role",""))=="capital": r["role"]="granary"
		if String(r.get("id",""))==city_id: r["role"]="capital"
	assert_str(String(CivilizationSystem.city_intelligence.primary_id(civ_id))).is_equal(city_id)
	_their_men(8.0)
	_counted(10.0)
	_train(120)
	WAR.blood_feud(civ_id,int(GameState.elapsed_days),"the killing of their envoy Qira")
	WAR.order(civ_id,"war_chief")
	var band:=_band("punish")
	assert_dict(band).override_failure_message(str(Council.peek(civ_id))).is_not_empty()
	assert_str(String(band.destination_id)).is_equal(city_id)
	assert_bool(bool((band.get("city_operation",{}) as Dictionary).get("raid",false))).is_true()
	_days(120,func()->bool:return not WAR.feuding(civ_id) and _band("punish").is_empty())
	# Their chief was taken: ransomed, and the feud sworn off.
	var kinds:Array=(WAR.state().log as Array).map(func(e:Dictionary)->String:return String(e.kind))
	assert_array(kinds).override_failure_message("%s
%s" % [str(WAR.front(civ_id)),str((WAR.state().log as Array).slice(0,8))]).contains(["chief_taken"])
	assert_str(String((WAR.front(civ_id).get("feud_end",{}) as Dictionary).get("why",""))).is_equal("chief ransomed")
	assert_bool(WAR.feuding(civ_id)).override_failure_message("%s
%s" % [str(WAR.front(civ_id)),str(CivilizationSystem.civilizations[0].player_relation)]).is_false()
	assert_bool(bool(CivilizationSystem.civilizations[0].player_relation.get("at_war",false))).is_false()
	# Nothing more goes out against them, and no town of theirs is held.
	assert_str(String(WAR.front(civ_id).get("stance",""))).is_equal("leave")
	assert_bool(_held()).is_false()

## The user judges by what he can see: a band the council sent shows on the
## war map as a counter on the move with its arrow (or, in the raid age, its
## dotted raid track) along its land road, through the existing overlay.
func test_a_council_band_on_the_march_shows_on_the_war_map()->void:
	_their_men(8.0)
	_counted(10.0)
	_train(120)
	WAR.blood_feud(civ_id,int(GameState.elapsed_days),"the killing of their envoy Qira")
	_place_town(CivilizationSystem.player_world_origin+Vector2(-60.0,8.0))
	Council.order(civ_id,"take",{"place":{"city_id":city_id,"civ_id":civ_id,"name":"Tsaren","position":{"x":city.x,"z":city.y}}})
	var band:=_band("take")
	assert_dict(band).is_not_empty()
	_days(1)
	var overlay:Control=auto_free(Overlay.new())
	var inputs:Dictionary=overlay.call("collect")
	var counter:={}
	for f in inputs.get("friendly",[]):
		if int((f as Dictionary).get("army_id",0))==int(band.army_id): counter=f
	# Its counter, on the move toward Tsaren, with the days left.
	assert_dict(counter).is_not_empty()
	assert_bool((counter.objective as Vector2).is_finite()).is_true()
	assert_int(int(counter.get("days_left",0))).is_greater(0)
	# Its arrow (or raid track) along the road.
	var built:=Overlay.compose(inputs)
	var drawn:=false
	for a in (built.get("arrows",[]) as Array)+(built.get("raids",[]) as Array):
		if int((a as Dictionary).get("army_id",0))==int(band.army_id): drawn=true
	assert_bool(drawn).override_failure_message(str(built.get("arrows",[]))).is_true()

# ---------------------------------------------------------------------------
# Punish
# ---------------------------------------------------------------------------

func test_punish_sends_a_real_band_that_raids_their_stores_and_comes_home()->void:
	_their_men(40.0)
	_counted(8.0)
	_train(80)
	WAR.blood_feud(civ_id,int(GameState.elapsed_days),"the killing of their envoy Qira")
	var their_food_before:=float(CivilizationSystem.civilizations[0].get("food_days",0.0))
	var people_before:=int(GameState.population_total)
	var said:=Council.order(civ_id,"punish")
	assert_str(String(said.verdict)).override_failure_message(str(said)).is_equal("act")
	var band:=_band("punish")
	assert_dict(band).is_not_empty()
	# A raid, sized by the odds: not everyone, and the watch stays home.
	assert_bool(bool((band.city_operation as Dictionary).get("raid",false))).is_true()
	assert_int(int(band.troops)).is_less(80)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_greater(0)
	var army_id:=int(band.army_id)
	var sent:=int(band.troops)
	assert_str(Council.operation_words(civ_id)).contains("raiders")
	# Days pass: they reach Tsaren, raid it and turn for home.
	_days(60,func()->bool:return _band("punish").is_empty() and MilitaryCampaign._field_army_index(army_id)<0)
	var record:={}
	for b in MilitaryCampaign.battle_history:
		if int((b as Dictionary).get("home_force_id",-1))==army_id: record=b
	assert_dict(record).override_failure_message("no raid was fought").is_not_empty()
	assert_str(String((record.threat as Dictionary).get("incident_kind",""))).is_equal("raid")
	# Our dead are our own fighters, out of our own people.
	var ours_dead:=int((record[String(record.home_side)] as Dictionary).get("dead",0))
	assert_int(people_before-int(GameState.population_total)).is_equal(ours_dead)
	# Won, their stores fell and ours rose by what the band carried home.
	var strategic:Dictionary=record.get("strategic_outcome",{})
	if bool(strategic.get("player_won",false)):
		assert_float(float((strategic.get("raid_spoils",{}) as Dictionary).get("Food",0.0))).is_greater(0.0)
		assert_float(float(CivilizationSystem.civilizations[0].get("food_days",0.0))).is_less(their_food_before)
	# The band came home and went back into the levy.
	assert_int(MilitaryCampaign._field_army_index(army_id)).is_equal(-1)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_greater(80-sent)
	# The feud's ledger counted the strike once, with the dead as fought.
	assert_int(int(WAR.front(civ_id).get("strikes",0))).is_equal(1)
	assert_int(int(WAR.front(civ_id).get("our_dead",0))).is_equal(ours_dead)
	# The next raid waits out its rest.
	Council.sit(int(GameState.elapsed_days))
	assert_dict(_band("punish")).is_empty()
	assert_str(String(Council.peek(civ_id).get("verdict",""))).is_equal("rest")

func test_punish_sends_trackers_first_when_nobody_knows_where_they_live()->void:
	_train(40)
	WAR.blood_feud(civ_id,int(GameState.elapsed_days),"the killing of their envoy Qira")
	CivilizationSystem.city_intelligence.records.player.erase(city_id)
	CivilizationSystem.civilizations[0].player_relation["home_location_known"]=false
	var said:=Council.order(civ_id,"punish")
	assert_dict(_band("punish")).is_empty()
	assert_str(String((WAR.front(civ_id).get("op",{}) as Dictionary).get("objective",""))).is_equal("war_track")
	assert_str(String(said.says)).contains("raiders' trail")
	assert_str(Council.operation_words(civ_id)).contains("trackers")

# ---------------------------------------------------------------------------
# Defend
# ---------------------------------------------------------------------------

func test_defend_calls_the_raiders_home_and_their_raid_meets_our_watch()->void:
	_their_men(40.0)
	_counted(8.0)
	_train(80)
	WAR.blood_feud(civ_id,int(GameState.elapsed_days),"the killing of their envoy Qira")
	_place_town(CivilizationSystem.player_world_origin+Vector2(-60.0,8.0))
	Council.order(civ_id,"punish")
	var army_id:=int(_band("punish").army_id)
	_days(1)
	var held:=Council.order(civ_id,"defend")
	# The band out on the road turns for home; the approaches are watched.
	var index:=MilitaryCampaign._field_army_index(army_id)
	assert_int(index).is_greater_equal(0)
	assert_str(String(MilitaryCampaign.field_armies[index].get("destination_id",""))).is_equal("player_home")
	assert_int(int(WAR.front(civ_id).get("guard_until",-1))).is_greater(int(GameState.elapsed_days))
	assert_str(String(held.says)).is_not_empty()
	_days(20)
	# Their raid comes: men of their real army against our real watch.
	var their_men:=float(CivilizationSystem.civilizations[0].get("military_population",0.0))
	var people:=int(GameState.population_total)
	var watch:=int(MilitaryCampaign.home_army.troops)
	var day:=int(GameState.elapsed_days)
	WAR._schedule(civ_id,day,"vengeance","test")
	WAR._execute(civ_id,day)
	var raid:Dictionary=WAR.front(civ_id).get("last_raid",{})
	assert_dict(raid).override_failure_message(str((WAR.state().log as Array).slice(0,3))).is_not_empty()
	assert_int(int(raid.get("day",-1))).is_equal(day)
	assert_bool(bool(raid.get("watch",false))).override_failure_message(str(raid)).is_true()
	var record:Dictionary=MilitaryCampaign.battle_history[0]
	assert_str(String((record.threat as Dictionary).get("war_loop",""))).is_not_empty()
	# Our dead came off our watch at home and our people; theirs off their army.
	assert_int(people-int(GameState.population_total)).is_equal(int(raid.our_dead))
	assert_int(int(MilitaryCampaign.home_army.troops)).is_less_equal(watch)
	assert_float(float(CivilizationSystem.civilizations[0].get("military_population",0.0))).is_less_equal(their_men)
	# Counted once: the raid is its own, the scan of the battles passes it.
	var raids_before:=int(WAR.front(civ_id).get("raids",0))
	WAR.from_battles(day)
	assert_int(int(WAR.front(civ_id).get("raids",0))).is_equal(raids_before)

func test_defend_deploys_real_border_band_and_keeps_capital_reserve()->void:
	_their_men(30.0)
	_train(120)
	WAR.blood_feud(civ_id,int(GameState.elapsed_days),"the killing of their envoy Qira")
	var day:=int(GameState.elapsed_days)
	GameState.border_forts={"forts":[],"border_share":0.0,"next_id":1,"seeded":true}
	var border:Dictionary=preload("res://scripts/fort_border.gd").outline()
	CivilizationSystem._add_revealed_area(CivilizationSystem.player_world_origin,float(border.reach)+5.0,"home border survey")
	var at:=CivilizationSystem.player_world_origin+Vector2(14.0,0.0)
	CivilizationSystem.foreign_formations.append({"id":"%s_raiders" % civ_id,"civ_id":civ_id,"kind":"expedition","command_position":{"x":at.x,"z":at.y},"strength_share":0.5,"actual_troops":15,"readiness":0.5})
	CivilizationSystem._process_local_observation(day,true)
	assert_dict(CivilizationSystem.visible_formation_sighting("%s_raiders" % civ_id)).is_not_empty()
	var before:=int(MilitaryCampaign.home_army.troops)+MilitaryCampaign.field_army_active_personnel()
	var held:=Council.order(civ_id,"defend")
	# What the watch saw is kept for the screens at the sitting.
	assert_str(String(Council.peek(civ_id).get("coming",""))).contains("km from")
	assert_int(Council.incoming().size()).is_equal(1)
	var band:=_band("border")
	assert_dict(band).override_failure_message(str(held)).is_not_empty()
	if band.is_empty():return
	assert_str(String(band.status)).is_equal("moving")
	assert_dict(band.position).is_equal({"x":CivilizationSystem.player_world_origin.x,"z":CivilizationSystem.player_world_origin.y})
	assert_dict(band.destination_position).is_equal(band.border_sector.anchor)
	assert_array(Array(preload("res://scripts/border_defense.gd").coverage(band,day))).is_empty()
	assert_str(String(held.says)).contains("assigned border km")
	assert_dict(_band("intercept")).is_empty()
	# Forming the band transfers people; the capital retains at least its fifth.
	assert_int(int(MilitaryCampaign.home_army.troops)+MilitaryCampaign.field_army_active_personnel()).is_equal(before)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_greater_equal(ceili(float(before)*0.2))

# ---------------------------------------------------------------------------
# Leave them be, seek peace
# ---------------------------------------------------------------------------

func test_leave_and_peace_bring_the_bands_home_and_send_no_raid()->void:
	_their_men(40.0)
	_counted(8.0)
	_train(80)
	WAR.blood_feud(civ_id,int(GameState.elapsed_days),"the killing of their envoy Qira")
	_place_town(CivilizationSystem.player_world_origin+Vector2(-60.0,8.0))
	Council.order(civ_id,"punish")
	var army_id:=int(_band("punish").army_id)
	_days(1)
	var left:=Council.order(civ_id,"leave")
	assert_str(String(left.says)).contains("No one goes after")
	var index:=MilitaryCampaign._field_army_index(army_id)
	assert_str(String(MilitaryCampaign.field_armies[index].destination_id)).is_equal("player_home")
	_days(40)
	# Home, folded back into the levy; and nothing new went out.
	assert_int(MilitaryCampaign._field_army_index(army_id)).is_equal(-1)
	assert_dict(_band("punish")).is_empty()
	for b in MilitaryCampaign.battle_history: assert_int(int((b as Dictionary).get("home_force_id",-1))).is_not_equal(army_id)
	# Peace: messengers go; no band goes out.
	var peace:=Council.order(civ_id,"peace")
	assert_str(String((WAR.front(civ_id).get("op",{}) as Dictionary).get("objective",""))).is_equal("war_parley")
	assert_str(String(peace.says)).contains("messengers")
	Council.sit(int(GameState.elapsed_days))
	assert_array(MilitaryCampaign.field_armies.filter(func(a:Dictionary)->bool:return a.has("council"))).is_empty()
	assert_str(Council.operation_words(civ_id)).contains("messengers")

# ---------------------------------------------------------------------------
# One engine: no second, made-up strike in a war
# ---------------------------------------------------------------------------

func test_no_double_strike_in_a_formal_war()->void:
	GameState.ensure_population_total(2400); GameState.housing_capacity=3200
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ["population"]=3000.0
	_train(60)
	assert_bool(WAR.declare(civ_id,int(GameState.elapsed_days),"the tribute you would not pay")).is_true()
	assert_dict(WAR.front(civ_id).war as Dictionary).is_not_empty()
	var people:=int(GameState.population_total)
	var day:=int(GameState.elapsed_days)
	for i in 400:
		day+=1
		GameState.elapsed_days=day
		WAR.daily(day)
	var kinds:Array=(WAR.state().log as Array).filter(func(e:Dictionary)->bool:return String(e.civ)==civ_id).map(func(e:Dictionary)->String:return String(e.kind))
	# Their host comes only through the real army: war_loop sends nobody of its own.
	assert_array(kinds).not_contains(["enemy_attack","op_burn","op_pursue","op_chief"])
	assert_int(int(GameState.population_total)).is_equal(people)
	# Nor does the war leader strike on his own: with no word he defends.
	assert_str(Council.stance_of(civ_id)).is_equal("defend")

# ---------------------------------------------------------------------------
# Cadence: a few years of it, no daily spam
# ---------------------------------------------------------------------------

func test_a_few_years_of_punishing_give_a_sane_number_of_raids()->void:
	_their_men(30.0)
	_counted(6.0)
	_train(120)
	WAR.blood_feud(civ_id,int(GameState.elapsed_days),"the killing of their envoy Qira")
	Council.order(civ_id,"punish")
	var sittings:=0
	var last_sat:=int(Council.peek(civ_id).get("sat",-1))
	var bands_seen:={}
	var start:=Time.get_ticks_msec()
	for i in 3*365:
		_days(1)
		var sat:=int(Council.peek(civ_id).get("sat",-1))
		if sat!=last_sat: sittings+=1; last_sat=sat
		for a in MilitaryCampaign.field_armies:
			if (a as Dictionary).has("council"): bands_seen[int((a as Dictionary).army_id)]=true
	var raids:=0
	for e in (WAR.state().log as Array):
		if String((e as Dictionary).get("kind",""))=="battle_ours": raids+=1
	# One raid at a time, a rest between: about one a season, never daily.
	assert_int(bands_seen.size()).override_failure_message("bands: %d" % bands_seen.size()).is_between(3,14)
	assert_int(sittings).override_failure_message("sittings: %d" % sittings).is_less(3*365/2)
	assert_int(raids).is_less_equal(bands_seen.size())
	assert_int(Time.get_ticks_msec()-start).is_less(90000)

# ---------------------------------------------------------------------------
# Every people the same council: a rival against another rival
# ---------------------------------------------------------------------------

## Two simulated peoples, each with its own systems, their towns a day's
## march apart; the first at war with the second.
func _two_peoples()->Dictionary:
	var first:=String(CivilizationSystem.civilizations[1].id)
	var second:=String(CivilizationSystem.civilizations[2].id)
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	var origins:={first:CivilizationSystem.player_world_origin+Vector2(200.0,0.0),second:CivilizationSystem.player_world_origin+Vector2(225.0,0.0)}
	for id in [first,second]:
		WorldSimulation.create_actor(id,hash(id)&0x7fffffff,origins[id])
		WorldSimulation.actors[id].controller="manual"
		WorldSimulation.actors[id].systems.CivilizationSystem.scout_land_authority=func(_p:Vector2)->bool:return true
		assert_bool(WorldSimulation.submit(id,{"kind":"found"}).get("ok",false)).is_true()
		WorldSimulation.scoped(id,func()->void:
			WorldSimulation.state.ensure_population_total(2400)
			WorldSimulation.state.settlement_completed=["Hearth Circle"]
			WorldSimulation.settlements.ensure_founded()
			WorldSimulation.state.resource_stockpiles["Food"]=100000.0
			WorldSimulation.state.simulation_metrics["food_days"]=120.0)
	WorldSimulation.enabled=true
	WorldSimulation.refresh_projections()
	WorldSimulation.refresh_views()
	return {"first":first,"second":second}

func _relation_in(viewer:String,other:String)->Dictionary:
	return WorldSimulation.scoped(viewer,func()->Dictionary:
		for c in WorldSimulation.world.civilizations:
			if String((c as Dictionary).get("id",""))==other: return (c as Dictionary).player_relation
		return {})

func test_a_rival_takes_a_town_of_another_rival_through_the_same_council()->void:
	var pair:=_two_peoples()
	var first:=String(pair.first); var second:=String(pair.second)
	# At war, both ways.
	for v in [[first,second],[second,first]]:
		var rel:=_relation_in(String(v[0]),String(v[1]))
		rel["at_war"]=true; rel["treaty"]="war"; rel["contact_level"]=2
	var day:=int(GameState.elapsed_days)
	var their_town:String=WorldSimulation.scoped(first,func()->String:
		var mc=WorldSimulation.military
		mc.military_inventory["improvised"]=420
		mc.raise_recruits(420)
		mc.start_training("levy","improvised",420)
		mc._complete_training(mc.training_queue[0].duplicate(true))
		mc.training_queue.clear()
		# The first people's scouts have counted the second's chief town.
		var chart=WorldSimulation.world.city_intelligence
		var town:=String(chart.primary_id(second))
		chart.publish("player",chart.capture("player",town,0.8,day,"scout report","test"),day)
		# A bold ruler: its plan takes towns at war (civilization_strategy offensive).
		Council.state()["plan"]={"day":day,"offensive":true,"peace_food":0.0}
		Council.sit(day)
		return town)
	assert_str(their_town).is_not_empty()
	var band:Dictionary=WorldSimulation.scoped(first,func()->Dictionary:
		for a in WorldSimulation.military.field_armies:
			var c:Variant=(a as Dictionary).get("council")
			if c is Dictionary and String((c as Dictionary).get("civ",""))==second: return (a as Dictionary).duplicate(true)
		return {})
	var said:Dictionary=WorldSimulation.scoped(first,func()->Dictionary:return Council.peek(second))
	assert_dict(band).override_failure_message(str(said)).is_not_empty()
	# The same stance word and the same act as the god's own people: take.
	assert_str(String(said.get("stance",""))).is_equal("take")
	assert_str(String((band.council as Dictionary).act)).is_equal("take")
	assert_str(String(band.status)).is_equal("moving")
	assert_str(String(band.destination_id)).is_equal(their_town)
	assert_int(int(band.troops)).is_greater(100)
	# The watch stays home in their world too.
	assert_int(int(WorldSimulation.scoped(first,func()->int:return int(WorldSimulation.military.home_army.troops)))).is_greater(0)
	# Days pass in the first people's own world: the band arrives, fights the
	# second people's own defenders and takes the town, leaving a garrison
	# big enough to hold it; the second people's own record has it occupied.
	var held:=false
	for i in 30:
		day+=1
		var today:=day
		WorldSimulation.scoped(first,func()->void:
			WorldSimulation.state.elapsed_days=today
			WorldSimulation.military.last_processed_day=today
			WorldSimulation.military._process_military_day()
			for e in WorldSimulation.military.own_engagements.values(): (e as Dictionary).erase("awaiting_player_view")
			Council.day(today))
		held=String(WorldSimulation.scoped(first,func()->String:return String(WorldSimulation.world.region_snapshot(second,their_town).get("controller",""))))=="player"
		if held: break
	assert_bool(held).override_failure_message("the town never fell: %s" % str(WorldSimulation.scoped(first,func()->Dictionary:return Council.peek(second)))).is_true()
	var garrison:Dictionary=WorldSimulation.scoped(first,func()->Dictionary:return WorldSimulation.military.occupation_force_for_region(second,their_town))
	assert_int(int(garrison.get("troops",0))).is_greater_equal(int(float(garrison.get("required",1.0))))
	var occupied:String=WorldSimulation.scoped(second,func()->String:
		for c in WorldSimulation.state.player_settlements:
			if bool((c as Dictionary).get("primary",false)): return String((c as Dictionary).get("occupied_by",""))
		return "")
	assert_str(occupied).is_equal(first)

# ---------------------------------------------------------------------------
# Their raid on us: a real band of theirs, from their own council
# ---------------------------------------------------------------------------

## In a world of simulated peoples their feud's raid on us is a band of their
## own army, sent by their war council by the land road to a town of ours
## they know; the fight is the engine's, both armies bury their own, and our
## war ledger counts it once, as their raid.
func test_their_raid_marches_on_our_town_as_a_band_of_their_own_army()->void:
	var them:=String(CivilizationSystem.civilizations[1].id)
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	WorldSimulation.create_actor(them,hash(them)&0x7fffffff,CivilizationSystem.player_world_origin+Vector2(40.0,0.0))
	WorldSimulation.actors[them].controller="manual"
	WorldSimulation.actors[them].systems.CivilizationSystem.scout_land_authority=func(_p:Vector2)->bool:return true
	assert_bool(WorldSimulation.submit(them,{"kind":"found"}).get("ok",false)).is_true()
	WorldSimulation.scoped(them,func()->void:
		WorldSimulation.state.ensure_population_total(600)
		WorldSimulation.state.settlement_completed=["Hearth Circle"]
		WorldSimulation.settlements.ensure_founded()
		WorldSimulation.state.resource_stockpiles["Food"]=100000.0
		WorldSimulation.state.simulation_metrics["food_days"]=120.0)
	WorldSimulation.enabled=true
	WorldSimulation.refresh_projections()
	WorldSimulation.refresh_views()
	CivilizationSystem.civilizations[1].player_relation["contact_level"]=2
	_train(12)
	var day:=int(GameState.elapsed_days)
	# Their levy, and our town on their chart (their envoys came to us); their
	# days kept with ours.
	WorldSimulation.scoped(them,func()->void:
		WorldSimulation.state.elapsed_days=day
		var mc=WorldSimulation.military
		mc.military_inventory["improvised"]=120
		mc.raise_recruits(120)
		mc.start_training("levy","improvised",120)
		mc._complete_training(mc.training_queue[0].duplicate(true))
		mc.training_queue.clear()
		var chart=WorldSimulation.world.city_intelligence
		var ours:=String(chart.primary_id("human"))
		chart.publish("player",chart.capture("player",ours,0.8,day,"envoys","test"),day))
	WAR.blood_feud(them,day,"the killing of their envoy Qira")
	var people:=int(GameState.population_total)
	var their_people:=int(WorldSimulation.scoped(them,func()->int:return int(WorldSimulation.state.population_total)))
	# Their raid comes due: it goes to their council, not to a made-up band.
	WAR._schedule(them,day,"vengeance","test")
	WAR._execute(them,day)
	var kinds:Array=(WAR.state().log as Array).filter(func(e:Dictionary)->bool:return String(e.civ)==them).map(func(e:Dictionary)->String:return String(e.kind))
	assert_array(kinds).contains(["raid_called"])
	assert_array(kinds).not_contains(["raid","skirmish"])
	# Days pass in both worlds: their council sends the band, it marches on our
	# town and fights our watch there.
	var counted:=false
	var marched:=false
	for i in 40:
		day+=1
		var today:=day
		WorldSimulation.scoped(them,func()->void:
			WorldSimulation.state.elapsed_days=today
			WorldSimulation.military.last_processed_day=today
			WorldSimulation.military._process_military_day()
			for e in WorldSimulation.military.own_engagements.values(): (e as Dictionary).erase("awaiting_player_view")
			Council.day(today))
		marched=marched or bool(WorldSimulation.scoped(them,func()->bool:
			for a in WorldSimulation.military.field_armies:
				var c:Variant=(a as Dictionary).get("council")
				if c is Dictionary and String((c as Dictionary).get("civ",""))=="human" and String((c as Dictionary).get("act",""))=="punish": return true
			return false))
		GameState.elapsed_days=today
		MilitaryCampaign.last_processed_day=today
		MilitaryCampaign._process_military_day()
		WAR.from_battles(today)
		if int(WAR.front(them).get("raids",0))>0: counted=true; break
	assert_bool(marched).override_failure_message(str(WorldSimulation.scoped(them,func()->Dictionary:return Council.peek("human")))).is_true()
	assert_bool(counted).override_failure_message("their band never fought at our town: %s" % str(WorldSimulation.scoped(them,func()->Dictionary:return Council.peek("human")))).is_true()
	# The dead are real on both sides and the ledger agrees with the battle.
	var raid:Dictionary=WAR.front(them).get("last_raid",{})
	assert_int(people-int(GameState.population_total)).is_equal(int(raid.get("our_dead",0)))
	assert_int(their_people-int(WorldSimulation.scoped(them,func()->int:return int(WorldSimulation.state.population_total)))).is_equal(int(raid.get("their_dead",0)))

# ---------------------------------------------------------------------------
# Saves
# ---------------------------------------------------------------------------

## The council's word and its band's errand survive a save: the diplomacy
## payload keeps the council (checked with the hall's own state), the military
## payload keeps the band's errand, and after loading the council follows the
## same band. A broken council in a save is refused like any broken hall state.
func test_the_council_and_its_band_survive_a_save()->void:
	_their_men(8.0)
	_counted(10.0)
	_train(120)
	WAR.blood_feud(civ_id,int(GameState.elapsed_days),"the killing of their envoy Qira")
	_place_town(CivilizationSystem.player_world_origin+Vector2(-60.0,8.0))
	Council.order(civ_id,"take",{"place":{"city_id":city_id,"civ_id":civ_id,"name":"Tsaren","position":{"x":city.x,"z":city.y}}})
	var band:=_band("take")
	assert_dict(band).is_not_empty()
	var said:=String(Council.peek(civ_id).get("says",""))
	assert_str(said).is_not_empty()
	# Through JSON, as a save file carries them.
	var diplomacy:Dictionary=JSON.parse_string(JSON.stringify(ForeignDiplomacy.export_state()))
	var military:Dictionary=JSON.parse_string(JSON.stringify(MilitaryCampaign.export_state()))
	ForeignDiplomacy.reset_for_new_world();ForeignDiplomacy.ensure()
	MilitaryCampaign.reset_for_new_world()
	assert_dict(_band("take")).is_empty()
	assert_bool(ForeignDiplomacy.import_state(diplomacy).get("ok",false)).override_failure_message(str(ForeignDiplomacy.import_state(diplomacy))).is_true()
	assert_bool(MilitaryCampaign.import_state(military).get("ok",false)).is_true()
	var loaded:=_band("take")
	assert_int(int(loaded.get("army_id",0))).is_equal(int(band.army_id))
	assert_str(String(WAR.front(civ_id).get("stance",""))).is_equal("take")
	assert_str(String(Council.peek(civ_id).get("says",""))).is_equal(said)
	# The council goes on with the same band: no second band is formed.
	Council.sit(int(GameState.elapsed_days)+3)
	assert_int(Council.bands_against(civ_id).size()).is_equal(1)
	assert_str(Council.operation_words(civ_id)).contains("Tsaren")
	# A broken council in a save is refused.
	var bad:Dictionary=diplomacy.duplicate(true)
	(bad.audiences as Dictionary)["council"]={"version":1,"fronts":{civ_id:"not a front"}}
	assert_bool(ForeignDiplomacy.import_state(bad).has("error")).is_true()

# ---------------------------------------------------------------------------
# Bands left in the field
# ---------------------------------------------------------------------------

## A band of the old hand orders: formed from the levy at home, then left
## where its order ended (a town, the road), named as the old orders named
## it.
func _old_band(count:int,name:String,region_id:String="",at:Vector2=Vector2.INF)->int:
	var made:Dictionary=MilitaryCampaign.create_field_army(count,name)
	assert_bool(made.has("army")).override_failure_message(str(made)).is_true()
	var army_id:=int((made.army as Dictionary).army_id)
	# It marched out and back under its old order long ago.
	var old:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(army_id)]
	old["departure_day"]=int(GameState.elapsed_days)-120;old["arrival_day"]=int(GameState.elapsed_days)-100
	if region_id!="":
		var band:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(army_id)]
		band["status"]="stationed";band["location_id"]=region_id;band["location_name"]=name;band["destination_id"]=""
		band["position"]={"x":at.x,"z":at.y}
	return army_id

func _army(army_id:int)->Dictionary:
	var index:=MilitaryCampaign._field_army_index(army_id)
	return MilitaryCampaign.field_armies[index] if index>=0 else {}

func _told(words:String)->int:
	var n:=0
	for e in (GameState.chronicle.get("entries",[]) as Array):
		if String((e as Dictionary).get("text","")).contains(words): n+=1
	return n

## The old hand orders left bands about (a save from before the council):
## at every sitting those with no errand of the council's, not guarding a
## town we hold, not fighting and not on a live order come home and go back
## into the army at home; a band with nobody left is struck off. Told once.
func test_bands_left_by_old_orders_come_home_and_rejoin_the_army()->void:
	_train(80)
	var held:Dictionary={}
	var esurai:Dictionary=CivilizationSystem.civilizations[0]
	for region in esurai.strategic_regions:
		if String((region as Dictionary).get("id",""))!=city_id: held=region; break
	held["controller"]="player"
	var held_at:Vector2=held.get("position",city+Vector2(6.0,6.0)) if held.get("position") is Vector2 else city+Vector2(6.0,6.0)
	var idle_a:=_old_band(4,"BUILD 2 1")
	var idle_b:=_old_band(6,"Host marching on Iglan")
	var afield:=_old_band(5,"Host marching on Eldwick",city_id,city)
	var emptied:=_old_band(3,"Withdrawal from Iglan",city_id,city)
	var guard:=_old_band(4,"Guard of the held town",String(held.id),held_at)
	var marching:=_old_band(4,"Band on the road")
	assert_bool(MilitaryCampaign.move_field_army(marching,city_id).has("error")).is_false()
	# One the ruler sent to wait on open ground (the Army screen's "Go to…"),
	# and one laying a depot: both are at the ruler's work.
	CivilizationSystem._add_revealed_area(CivilizationSystem.player_world_origin,72.0,"home ground")
	var posted:=_old_band(4,"Band sent to the ford")
	var sent:Dictionary=Orders.give(posted,"goto",{"type":"spot","x":CivilizationSystem.player_world_origin.x+9.0,"z":CivilizationSystem.player_world_origin.y-4.0})
	assert_str(String(sent.get("verdict",""))).override_failure_message(str(sent)).is_equal("act")
	var post:Dictionary=_army(posted).get("post",{})
	assert_dict(post).is_not_empty()
	var standing:=_army(posted)
	standing["status"]="stationed";standing["location_id"]="field_position";standing["destination_id"]=""
	standing["position"]={"x":float(post.x),"z":float(post.z)}
	var digging:=_old_band(20,"Depot layers",city_id,city+Vector2(9.0,0.0))
	_army(digging)["depot_site"]={"x":city.x+9.0,"z":city.y,"work":100.0,"days":2}
	# Nobody left of one of them, its wounded still to be counted.
	var gone:=_army(emptied)
	gone["troops"]=0;gone["wounded_pool"]=2
	for f in gone.get("formations",[]): (f as Dictionary)["count"]=0
	# A band the ruler has just formed at home, not yet sent anywhere.
	var fresh:=int((MilitaryCampaign.create_field_army(4,"").army as Dictionary).army_id)
	var home_before:=int(MilitaryCampaign.home_army.troops)
	var wounded_before:=int(MilitaryCampaign.home_army.get("wounded_pool",0))
	Council.sit(int(GameState.elapsed_days))
	# The fresh one waits for the ruler's word a while.
	assert_dict(_army(fresh)).is_not_empty()
	# Those at home are back in the army at home at once.
	assert_dict(_army(idle_a)).is_empty()
	assert_dict(_army(idle_b)).is_empty()
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(home_before+10)
	# The one out in the field turns for home, to rejoin it there.
	var walking:=_army(afield)
	assert_str(String(walking.status)).is_equal("moving")
	assert_str(String(walking.destination_id)).is_equal("player_home")
	assert_str(String((walking.get("council",{}) as Dictionary).get("phase",""))).is_equal("home")
	# Nobody left: struck off, its wounded counted at home.
	assert_dict(_army(emptied)).is_empty()
	assert_int(int(MilitaryCampaign.home_army.get("wounded_pool",0))).is_equal(wounded_before+2)
	# The guard of a town we hold stays; the band on the road goes on.
	assert_str(String(_army(guard).get("location_id",""))).is_equal(String(held.id))
	assert_bool(_army(guard).has("council")).is_false()
	assert_str(String(_army(marching).status)).is_equal("moving")
	assert_str(String(_army(marching).destination_id)).is_equal(city_id)
	assert_bool(_army(posted).has("council")).is_false()
	assert_str(String(_army(posted).status)).is_equal("stationed")
	assert_bool(_army(digging).has("council")).is_false()
	# Told once in the Chronicle.
	assert_int(_told("called home the bands left in the field")).is_equal(1)
	# Days pass: the band from the field reaches home and rejoins the army.
	_days(30,func()->bool:return _army(afield).is_empty())
	assert_dict(_army(afield)).is_empty()
	assert_int(int(MilitaryCampaign.home_army.troops)).is_greater_equal(home_before+15)
	# Another band left about later comes home too, without another telling;
	# the fresh one, given no word in a month, goes back into the army.
	var later:=_old_band(4,"Left after a court order")
	GameState.elapsed_days=int(GameState.elapsed_days)+Council.FORMED_GRACE_DAYS
	Council.sit(int(GameState.elapsed_days))
	assert_dict(_army(later)).is_empty()
	assert_dict(_army(fresh)).is_empty()
	assert_int(_told("called home the bands left in the field")).is_equal(1)

## Where the stance has work for a band left in the field (punish, nobody out
## on it yet, its own men make the odds at the town and it stands nearer it
## than the home), it takes up the raid from where it stands; no other band
## goes from home.
func test_a_band_left_at_their_town_takes_up_the_raid()->void:
	_their_men(8.0)
	_counted(10.0)
	_train(60)
	WAR.blood_feud(civ_id,int(GameState.elapsed_days),"the killing of their envoy Qira")
	WAR.front(civ_id)["stance"]="punish"
	var afield:=_old_band(30,"Host marching on Tsaren",city_id,city)
	var home_before:=int(MilitaryCampaign.home_army.troops)
	Council.sit(int(GameState.elapsed_days))
	var band:=_army(afield)
	assert_dict(band).is_not_empty()
	var tag:Dictionary=band.get("council",{})
	assert_str(String(tag.get("act",""))).override_failure_message(str(Council.peek(civ_id))).is_equal("punish")
	assert_str(String(tag.get("civ",""))).is_equal(civ_id)
	assert_int(Council.bands_against(civ_id).size()).is_equal(1)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(home_before)
	assert_int(_told("takes up the raid on Tsaren")).is_equal(1)

# ---------------------------------------------------------------------------
# The war leader's upkeep: resting bands, the chain of command, the march
# ---------------------------------------------------------------------------

## A band the war leader's upkeep took out of the fighting (broken, under
## strength, resting: band_upkeep.gd) is neither sent nor counted: a band of
## the council's that goes to rest ends its errand there (the stance sends
## fresh men after the usual rest), and a broken band left in the field does
## not take up the raid.
func test_a_resting_or_broken_band_is_not_sent()->void:
	_their_men(8.0)
	_counted(10.0)
	_train(160)
	# A broken band of the old orders, left at their town.
	var broken:=_old_band(30,"Host marching on Tsaren",city_id,city)
	_army(broken)["morale"]=0.15
	WAR.blood_feud(civ_id,int(GameState.elapsed_days),"the killing of their envoy Qira")
	_place_town(CivilizationSystem.player_world_origin+Vector2(-60.0,8.0))
	_army(broken)["position"]={"x":city.x,"z":city.y}
	Council.order(civ_id,"take",{"place":{"city_id":city_id,"civ_id":civ_id,"name":"Tsaren","position":{"x":city.x,"z":city.y}}})
	var band:=_band("take")
	assert_dict(band).override_failure_message(str(Council.peek(civ_id))).is_not_empty()
	var army_id:=int(band.army_id)
	_days(1)
	band=_army(army_id)
	# The upkeep takes it out of the fighting: broken, it pulls back to rest.
	band["morale"]=0.2
	band["resting"]=true;band["rest_reason"]="broken";band["rest_place"]="player_home"
	assert_bool(MilitaryCampaign.return_field_army(army_id).has("error")).is_false()
	var today:=int(GameState.elapsed_days)
	Council.sit(today)
	var resting:=_army(army_id)
	assert_str(String((resting.council as Dictionary).get("phase",""))).is_equal("home")
	# The council leaves its road to the upkeep.
	assert_str(String(resting.status)).is_equal("moving")
	assert_str(String(resting.destination_id)).is_equal("player_home")
	assert_str(String(Council.peek(civ_id).get("verdict",""))).is_equal("rest")
	assert_str(Council.operation_words(civ_id)).contains("rest")
	# No fresh band goes before the rest after a failed attempt.
	for a in MilitaryCampaign.field_armies:
		var c:Variant=(a as Dictionary).get("council")
		if c is Dictionary and String((c as Dictionary).get("act",""))=="take" and String((c as Dictionary).get("phase",""))!="home": fail("a second band went while the first rests")
	# The broken band at their town does not take up the raid.
	WAR.front(civ_id)["stance"]="punish"
	Council.sit(today+1)
	assert_bool(_army(broken).has("council")).is_false()
	# The god's own pick of a broken band is refused, with the reason.
	var refused:Dictionary=Council._launch_ours(civ_id,{"city_id":city_id,"civ_id":civ_id,"name":"Tsaren","position":{"x":city.x,"z":city.y}},"punish",false,10,true,{"context":{"army_id":broken}})
	assert_str(String(refused.get("verdict",""))).override_failure_message(str(refused)).is_equal("impossible")
	assert_str(String(refused.get("says",""))).contains("not fit to go")

## The council's bands answer to it, not to a standing order up the chain
## (a whole-army objective): the war leader's upkeep sees to them (rest and
## refill) and the zone staff leave them be.
func test_council_bands_are_free_of_a_whole_army_order()->void:
	_their_men(8.0)
	_counted(10.0)
	_train(120)
	WAR.blood_feud(civ_id,int(GameState.elapsed_days),"the killing of their envoy Qira")
	var command:RefCounted=MilitaryCampaign.command_hierarchy
	command.sync()
	command.node("army")["order"]={"mission":"defend","zone_id":"old_zone"}
	Council.order(civ_id,"take",{"place":{"city_id":city_id,"civ_id":civ_id,"name":"Tsaren","position":{"x":city.x,"z":city.y}}})
	var band:=_band("take")
	assert_dict(band).is_not_empty()
	assert_bool(command.controls_army(int(band.army_id))).is_false()
	assert_bool(MilitaryCampaign.upkeep.free_to_see_to(band)).is_true()
	# Still on its road: freeing it did not stop the march.
	assert_str(String(band.status)).is_equal("moving")

## The feed-the-march check is the march's own reckoning (military_campaign
## march_supply): days, the share lived off the land at half pace, fed on
## the road and camped at the end, the leaner of the two deciding.
func test_the_march_is_fed_by_the_marchs_own_reckoning()->void:
	_train(60)
	var town:={"city_id":city_id,"civ_id":civ_id,"name":"Tsaren","position":{"x":city.x,"z":city.y}}
	var fed:Dictionary=Council._fed_at(town,40)
	assert_dict(fed).is_not_empty()
	for key in ["ratio","on_road","there","days","half_pace"]: assert_bool(fed.has(key)).override_failure_message(str(fed)).is_true()
	assert_float(float(fed.ratio)).is_equal(minf(float(fed.on_road),float(fed.there)))
	var home:Vector2=CivilizationSystem.player_world_origin
	var probe:Dictionary=(MilitaryCampaign.home_army as Dictionary).duplicate(false)
	probe["troops"]=40;probe["position"]={"x":home.x,"z":home.y};probe["status"]="moving"
	var march:Dictionary=MilitaryCampaign.march_supply(probe,MilitaryCampaign.field_route(home,city,probe))
	assert_int(int(fed.days)).is_equal(int(march.days))
	# Its words when it would starve them.
	var said:=Council._hungry_road_words(town,{"ratio":0.3,"on_road":0.3,"there":0.8,"days":9.0,"half_pace":0.5,"season":""})
	assert_str(said).contains("on the road to Tsaren")
	assert_str(said).contains("30% of a ration")
	assert_str(said).contains("living off the land at half pace")

## The zone staff (land_command.gd) read the one break and strength lines
## (army_lines.gd) and the one supply number (supply_state.gd fed), and no
## longer wear a band's supply down by the distance it marched.
func test_the_zone_staff_read_the_one_lines_and_the_one_supply_number()->void:
	var land:RefCounted=MilitaryCampaign.command_hierarchy.land
	var ours:={"troops":60,"morale":0.6,"provision_ratio":0.9,"supply_level":0.1,"formations":[{"unit":"levy","count":60,"equipment":60,"equipment_required":60,"training":0.6}]}
	var theirs:={"troops":60,"morale":0.6,"supply_level":0.9,"formations":[{"unit":"levy","count":60,"equipment":60,"equipment_required":60,"training":0.6}]}
	MilitaryCampaign.active_engagement={"home_side":"attacker","attacker":ours,"defender":theirs,"attacker_initial":100}
	# Fed (the one number is the ration eaten, not the old store level).
	assert_str(land.battle_order()).is_not_equal("retreat")
	ours["morale"]=0.24
	assert_str(land.battle_order()).is_equal("retreat")
	ours["morale"]=0.6;ours["troops"]=48
	assert_str(land.battle_order()).is_equal("retreat")
	ours["troops"]=60;ours["provision_ratio"]=0.4
	assert_str(land.battle_order()).is_equal("retreat")
	MilitaryCampaign.active_engagement={}
	# A march no longer wears the stores down by the distance.
	_train(20)
	var made:Dictionary=MilitaryCampaign.create_field_army(20,"Zone band")
	var actual:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(int((made.army as Dictionary).army_id))]
	actual["supply_level"]=0.9
	land._move(actual,CivilizationSystem.player_world_origin+Vector2(12.0,0.0),{"mission":"defend"},int(GameState.elapsed_days))
	assert_float(float(actual.supply_level)).is_equal(0.9)

## The enemy lives a few days from us (war_loop.gd near_us): a war needs a road.
func _bring_near(civ:Dictionary)->void:
	var home:Vector2=CivilizationSystem.player_world_origin+Vector2(250.0,0.0)
	civ["position"]=Vector2(home.x/CivilizationSystem.CIVILIZATION_WORLD_RADIUS_X_KM,home.y/CivilizationSystem.CIVILIZATION_WORLD_RADIUS_Z_KM)
	for region:Dictionary in civ.get("strategic_regions",[]):
		if String(region.get("role",""))=="capital": region["position"]=home
