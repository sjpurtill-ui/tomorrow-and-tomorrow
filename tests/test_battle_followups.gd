extends GdUnitTestSuite
## Follow-ups to the battle-clarity work, from the user's first war:
## - a court-ordered attack gives one Chronicle entry and one court matter,
##   and the war leader's report in court is the battle's own account in his
##   voice (not a second "We fought at Tsaren" report);
## - a beaten rival band keeps its stand-down and its lost morale across the
##   daily rebuild of rival views, so it cannot be fought again and again.

const WO:=preload("res://scripts/court_war_orders.gd")
const Account:=preload("res://scripts/battle_account.gd")
const Route:=preload("res://scripts/army_land_route.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const StandDown:=preload("res://scripts/rival_stand_down.gd")

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
	relation.contact_level=2; relation.home_location_known=true
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	region["name"]="Tsaren"
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

func _fight_to_the_end()->Dictionary:
	var guard:=0
	while not MilitaryCampaign.active_engagement.is_empty() and guard<40:
		MilitaryCampaign.active_engagement.erase("awaiting_player_view")
		MilitaryCampaign.advance_engagement("hold"); guard+=1
	return MilitaryCampaign.battle_history[0] if not MilitaryCampaign.battle_history.is_empty() else {}


func test_a_court_ordered_attack_is_told_once_in_the_war_leaders_voice()->void:
	MilitaryCampaign.military_inventory["improvised"]=int(MilitaryCampaign.military_inventory.get("improvised",0))+40
	MilitaryCampaign.raise_recruits(40)
	MilitaryCampaign.start_training("levy","improvised",40)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()
	var book:Dictionary=CivilizationSystem.city_intelligence.records.player
	book[city_id].fields["garrison"]={"low":8.0,"high":8.0,"observed_day":int(GameState.elapsed_days),"reported_day":int(GameState.elapsed_days)}
	var decided:=WO.perform({"kind":"attack","target":WO.find_target("Attack Tsaren"),"full":true,"insist":true},true)
	assert_str(String(decided.verdict)).override_failure_message(String(decided.get("says",""))).is_equal("act")
	var army_id:=int(decided.objective.army_id)
	for day in 200:
		if not MilitaryCampaign.active_engagement.is_empty() or MilitaryCampaign._field_army_index(army_id)<0: break
		GameState.elapsed_days+=1
		MilitaryCampaign._process_field_army_movement_day()
	assert_dict(MilitaryCampaign.active_engagement).is_not_empty()
	var record:=_fight_to_the_end()
	var seed:=int(record.seed)
	var filed:=WO.daily(int(GameState.elapsed_days))
	WO.daily(int(GameState.elapsed_days)+1)
	assert_int(filed.size()).is_equal(1)
	# One Chronicle entry for the battle: the battle's own, linking the report.
	var battle_entries:=0
	var road_reports:=0
	for e:Dictionary in GameState.chronicle.get("entries",[]):
		var key:=String(e.get("key",""))
		if key.begins_with("battle:%d:" % seed): battle_entries+=1
		if key.begins_with("court_war_report:"): road_reports+=1
	assert_int(battle_entries).is_equal(1)
	assert_int(road_reports).is_equal(0)
	# One court matter for it, carrying the whole account in his voice.
	var matters:Array=[]
	for m in Hall.state().matters:
		var situation:Dictionary=((m as Dictionary).get("audience",{}) as Dictionary).get("situation",{})
		var war:Dictionary=situation.get("war",{}) if situation.get("war") is Dictionary else {}
		if int(war.get("battle_seed",-1))==seed: matters.append(war)
	assert_int(matters.size()).is_equal(1)
	var told:=String(matters[0].account)
	var state:=Account.gather(record)
	state["voice"]="first"
	var account:=Account.build(record,state)
	assert_str(told).is_equal(Account.text(account))
	assert_str(told).contains(Account.ledger_line(account.ours))
	assert_str(told).not_contains(" says: ")
	assert_str(told).not_contains("We fought at")
	var general:=String(account.general)
	if general!="": assert_str(told).not_contains(general+"'s ")


func _beaten_formation()->String:
	var formation:Dictionary={}
	for f:Dictionary in CivilizationSystem.foreign_formations:
		if String(f.get("kind",""))!="scout": formation=f; break
	assert_dict(formation).is_not_empty()
	var id:=String(formation.id)
	var result:={"home_side":"attacker","attacker":{"name":"Our band","morale":0.8},"defender":{"name":"Their band","initial_troops":20,"remaining_troops":6,"morale":0.1},
		"termination":{"type":"withdrawal","defeated":"Their band","captor":"Our band","prisoners":2}}
	CivilizationSystem.resolve_foreign_formation_after_battle(id,result)
	return id


## As world_simulation does each day: the rival's formations arrive fresh
## from its own army, with no stand-down written on them.
func _rebuild(id:String,day:int)->Dictionary:
	for i in CivilizationSystem.foreign_formations.size():
		if String(CivilizationSystem.foreign_formations[i].id)!=id: continue
		var fresh:Dictionary=CivilizationSystem.foreign_formations[i].duplicate(true)
		fresh.erase("disabled_until_day"); fresh.erase("morale_cap"); fresh["readiness"]=0.9
		CivilizationSystem.foreign_formations[i]=fresh
	GameState.elapsed_days=day
	CivilizationSystem.apply_formation_memory(day)
	for f:Dictionary in CivilizationSystem.foreign_formations:
		if String(f.id)==id: return f
	return {}


func test_a_beaten_rival_band_stands_down_across_the_daily_rebuild_then_recovers()->void:
	var day:=int(GameState.elapsed_days)
	var id:=_beaten_formation()
	# Every day of its stand-down, rebuilt fresh, it stays out of reach.
	for later in [1,2,10,30,44]:
		var f:=_rebuild(id,day+later)
		assert_int(int(f.get("disabled_until_day",0))).override_failure_message("day +%d" % later).is_greater(day+later)
		var tried:=CivilizationSystem.foreign_formation_engagement_data(id,20)
		assert_bool(bool(tried.get("standing_down",false))).override_failure_message("day +%d: %s" % [later,str(tried)]).is_true()
		# Its morale comes back slowly, never all at once.
		assert_float(float(f.morale_cap)).is_less(1.0)
		assert_float(float(f.readiness)).is_less_equal(maxf(0.08,float(f.morale_cap))+0.0001)
	# After the stand-down it can be met again, still short of whole.
	var back:=_rebuild(id,day+StandDown.BEATEN_DAYS+1)
	assert_int(int(back.get("disabled_until_day",0))).is_less_equal(day+StandDown.BEATEN_DAYS+1)
	var tried:=CivilizationSystem.foreign_formation_engagement_data(id,20)
	assert_bool(bool(tried.get("standing_down",false))).override_failure_message(str(tried)).is_false()
	assert_float(StandDown.morale_cap(CivilizationSystem.formation_memory,id,day+StandDown.BEATEN_DAYS+1)).is_between(0.5,0.95)
	# Healed and forgotten after the recovery.
	_rebuild(id,day+StandDown.RECOVERY_DAYS+2)
	assert_bool(CivilizationSystem.formation_memory.has(id)).is_false()


func test_a_shaken_band_regroups_for_a_fortnight_and_the_memory_is_saved()->void:
	var memory:={}
	var entry:=StandDown.remember(memory,"civ_02:army:4",100,{"name":"B","morale":0.3},{"type":"continued"})
	assert_int(int(entry.until)).is_equal(100+StandDown.SHAKEN_DAYS)
	var whole:=StandDown.remember(memory,"civ_02:army:5",100,{"name":"C","morale":0.8},{"type":"continued"})
	assert_int(int(whole.until)).is_equal(100)
	assert_bool(StandDown.valid(memory)).is_true()
	assert_bool(StandDown.valid({"x":{"day":1}})).is_false()
	CivilizationSystem.formation_memory=memory.duplicate(true)
	var saved:Dictionary=CivilizationSystem.export_state()
	assert_dict(saved.get("formation_memory",{})).is_equal(memory)
