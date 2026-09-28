extends GdUnitTestSuite
## Several battles at once (military_campaign.gd `engagements`): bands on
## different fronts each fight their own battle, a day (a phase) at a time,
## and each is reported when it ends. No band fights two battles. The battles
## are saved and loaded together, and an older save's one battle loads into
## the same registry. The war leader's clashes (war_loop.gd) are kept to be
## watched in the battle panel.

const View:=preload("res://scripts/hud/battle_view.gd")
const Record:=preload("res://scripts/battle_record.gd")
const WarLoop:=preload("res://scripts/war_loop.gd")

var _processing:Dictionary={}
var civ_id:=""


func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]: _processing[node]=node.is_processing()
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();ForeignDiplomacy.ensure();GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(1400);GameState.housing_capacity=1600
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.select_founding_focus("provision")
	GameState.settlement_name="Seanstone"
	GameState.resource_stockpiles["Food"]=1000000.0
	GameState.elapsed_days=88*365
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ["name"]="Esurai"
	civ_id=String(civ.id)


func after_test()->void:
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


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

func _army(count:int,east:float)->int:
	MilitaryCampaign.raise_recruits(count)
	MilitaryCampaign.start_training("levy","improvised",count)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()
	var made:Dictionary=MilitaryCampaign.create_field_army(count)
	var army_id:=int((made.army as Dictionary).army_id)
	var index:=MilitaryCampaign._field_army_index(army_id)
	var origin:Vector2=CivilizationSystem.player_world_origin
	MilitaryCampaign.field_armies[index]["position"]={"x":origin.x+east,"z":origin.y}
	MilitaryCampaign.field_armies[index]["status"]="stationed"
	return army_id


## A band as strong, man for man, as the army that meets it.
func _band_like(army_id:int,count:int)->Dictionary:
	var ours:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(army_id)]
	var band:Dictionary=MilitaryCampaign.simulator.create_formation_force("Esurai band",[{"unit":"levy","weapon":"improvised","count":count,"equipment":0,"training":0.25}],float(ours.get("morale",0.5)),float(ours.get("readiness",0.12)))
	band["commander"]=MilitaryCampaign.simulator.create_commander("Esurai war leader",0.5,0.5,0.5,0.5)
	return band


## Our army meets their band in the field; the battle begins.
func _fight(army_id:int,enemy:Dictionary,formation:String,seed:int)->Dictionary:
	var origin:Vector2=CivilizationSystem.player_world_origin
	var at:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(army_id)].position
	MilitaryCampaign.active_threat={"id":"contact-"+formation,"title":"x","incident_kind":"campaign","campaign_mode":"offensive","source_civ_id":civ_id,"source_name":"Esurai","field_encounter":true,"formation_id":formation,
		"target_region_id":"","target_region_name":"the field contact","field_army_id":army_id,"enemy_force":enemy,"terrain_defense":1.0,"seed":seed,"deadline_day":99999,"discovered_day":int(GameState.elapsed_days),
		"target_position":{"x":float(at.x)+0.2,"z":origin.y}}
	return MilitaryCampaign.begin_threat_engagement(false)


## Two armies on two fronts, each fighting a steady band its own size: both
## battles last more than a day.
func _two_battles()->Array:
	var first:=_steady(_army(120,5.0))
	var second:=_steady(_army(90,-7.0))
	var a:Dictionary=_fight(first,_band_like(first,115),"f1",11)
	assert_bool(a.has("error")).override_failure_message(str(a)).is_false()
	var b:Dictionary=_fight(second,_band_like(second,88),"f2",12)
	assert_bool(b.has("error")).override_failure_message(str(b)).is_false()
	return [first,second,String(a.id),String(b.id)]


func _steady(army_id:int)->int:
	MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(army_id)]["morale"]=0.9
	return army_id


func _reported(id:String)->bool:
	for record:Dictionary in MilitaryCampaign.battle_history:
		if String(record.get("id",""))==id: return true
	return false


func _exchanges(id:String)->int:
	var engagement:Dictionary=MilitaryCampaign.engagements.get(id,{})
	return int((engagement.get("battle",{}) as Dictionary).get("exchange",0))


# ---------------------------------------------------------------------------
# Two battles at once
# ---------------------------------------------------------------------------

func test_two_battles_are_fought_at_once_and_each_is_reported_on_its_own()->void:
	var made:=_two_battles()
	var first:int=made[0]; var second:int=made[1]; var first_id:String=made[2]; var second_id:String=made[3]
	assert_str(first_id).is_not_equal(second_id)
	assert_int(MilitaryCampaign.own_engagements.size()).is_equal(2)
	assert_int(MilitaryCampaign.engagements.size()).is_equal(2)
	# The newest battle is in focus; the other goes on all the same.
	assert_str(String(MilitaryCampaign.active_engagement.id)).is_equal(second_id)
	# Both are listed for the map, each with its own side and progress.
	var listed:Array=View.list_now()
	assert_int(listed.size()).is_equal(2)
	for item:Dictionary in listed:
		assert_str(String(item.sides.a.civ_id)).is_equal("player")
		assert_float(float(item.progress)).is_between(-1.0,1.0)
	# Neither army can be sent to a second fight while it is in this one.
	var again:Dictionary=_fight(first,_band_like(first,40),"f3",13)
	assert_str(String(again.get("error",""))).contains("already in a fight")
	MilitaryCampaign.active_threat.clear()
	# A day fights a phase of each; both go on into the next day.
	MilitaryCampaign._fight_own_battles_day()
	assert_int(_exchanges(first_id)).is_greater(0)
	assert_int(_exchanges(second_id)).is_greater(0)
	assert_str(String(MilitaryCampaign.active_engagement.get("id",""))).is_equal(second_id)
	# Fought to the end a day at a time, each ends and is reported on its own.
	var days:=1
	while not MilitaryCampaign.own_engagements.is_empty() and days<40:
		MilitaryCampaign._fight_own_battles_day(); days+=1
	assert_dict(MilitaryCampaign.own_engagements).is_empty()
	assert_dict(MilitaryCampaign.active_engagement).is_empty()
	var reported:={}
	for record:Dictionary in MilitaryCampaign.battle_history: reported[String(record.get("id",""))]=record
	assert_bool(reported.has(first_id)).is_true()
	assert_bool(reported.has(second_id)).is_true()
	assert_int(int(reported[first_id].home_force_id)).is_equal(first)
	assert_int(int(reported[second_id].home_force_id)).is_equal(second)
	# Each army carries its own battle's losses home, not the other's.
	for pair in [[first,first_id,120],[second,second_id,90]]:
		var index:=MilitaryCampaign._field_army_index(int(pair[0]))
		var left:=int(MilitaryCampaign.field_armies[index].get("troops",0)) if index>=0 else 0
		var record:Dictionary=reported[String(pair[1])]
		assert_int(int((record.attacker as Dictionary).initial_troops)).is_equal(int(pair[2]))
		assert_int(left).is_less_equal(int((record.attacker as Dictionary).remaining_troops))


func test_the_battle_in_focus_moves_on_when_it_ends()->void:
	var made:=_two_battles()
	var first_id:String=made[2]; var second_id:String=made[3]
	assert_bool(MilitaryCampaign.focus_engagement(first_id)).is_true()
	assert_str(String(MilitaryCampaign.active_engagement.id)).is_equal(first_id)
	# Our general pulls back from the first: it ends, the other comes into focus.
	MilitaryCampaign.advance_engagement("retreat")
	assert_bool(MilitaryCampaign.own_engagements.has(first_id)).is_false()
	assert_str(String(MilitaryCampaign.active_engagement.get("id",""))).is_equal(second_id)
	assert_bool(MilitaryCampaign.focus_engagement("no-such-battle")).is_false()


func test_other_armies_move_and_fight_while_a_battle_is_fought()->void:
	var first:=_steady(_army(120,5.0))
	var second:=_army(90,-7.0)
	var started:Dictionary=_fight(first,_band_like(first,115),"f1",11)
	assert_bool(started.has("error")).is_false()
	# The second army still takes orders while the first is fighting.
	var origin:Vector2=CivilizationSystem.player_world_origin
	var moved:Dictionary=MilitaryCampaign.move_field_army_to_position(second,origin.x-5.0,origin.y+1.0)
	assert_str(String(moved.get("error",""))).not_contains("Finish the active")
	# The same band cannot be fought twice.
	assert_bool(MilitaryCampaign.command_hierarchy.battle.enemy_engaged("f1")).is_true()
	assert_str(String(MilitaryCampaign.map_engagement_availability(second,"f1").get("error",""))).contains("already being fought")
	# Nor can a busy army be picked for another operation.
	assert_bool(MilitaryCampaign._army_in_battle(first)).is_true()
	assert_bool(MilitaryCampaign._army_in_battle(second)).is_false()
	assert_str(String(MilitaryCampaign.offensive_campaign_availability(civ_id,"somewhere",first).get("error",""))).contains("already fighting")


func test_war_planning_lists_every_battle_with_a_way_to_watch_it()->void:
	var made:=_two_battles()
	var first_id:String=made[2]
	var dock:RefCounted=load("res://scripts/hud/content/dock_detail_war_planning.gd").new(null,null)
	var page:Dictionary=dock.tab(0)
	assert_str(String(page.brief.title)).is_equal("Our people are fighting in 2 places")
	var headings:Array=[]
	var watches:=0
	for block:Dictionary in page.blocks:
		if String(block.get("type",""))=="rows": headings.append(String(block.get("heading","")))
		if String(block.get("type",""))=="actions":
			for item:Dictionary in block.get("items",[]):
				if String(item.get("label",""))=="Watch the battle": watches+=1
	assert_array(headings).contains(["FIGHTING NOW · 1 OF 2","FIGHTING NOW · 2 OF 2"])
	assert_int(watches).is_equal(2)
	# An order given on one battle goes to that battle, not the one in focus.
	assert_str(String(MilitaryCampaign.active_engagement.id)).is_not_equal(first_id)
	dock.call("_order",first_id,"hold")
	assert_int(_exchanges(first_id)).is_equal(1)


func test_a_watched_battle_that_ends_shows_how_it_ended()->void:
	var made:=_two_battles()
	var first_id:String=made[2]; var second_id:String=made[3]
	var host:=Node.new(); host.set("game_speed",0.0); add_child(host)
	var panel:Control=View.open(first_id,host)
	assert_object(panel).is_not_null()
	assert_bool(bool(panel.get("live"))).is_true()
	# The other battle ends first: this one is still followed as it goes.
	assert_bool(MilitaryCampaign.focus_engagement(second_id)).is_true()
	MilitaryCampaign.advance_engagement("retreat")
	panel.call("_process",0.5)
	assert_bool(bool(panel.get("live"))).is_true()
	assert_str(String((panel.get("record") as Dictionary).get("id",""))).is_equal(first_id)
	# Then this one ends: the panel shows how it ended, from its report.
	assert_bool(MilitaryCampaign.focus_engagement(first_id)).is_true()
	MilitaryCampaign.advance_engagement("retreat")
	panel.call("_process",0.5)
	assert_bool(bool(panel.get("live"))).is_false()
	assert_str(String((panel.get("record") as Dictionary).get("id",""))).is_equal(first_id)
	View.close_open(host)
	host.queue_free()


func test_the_chronicle_offers_to_watch_a_war_leader_clash()->void:
	var feed:VBoxContainer=load("res://scripts/hud/chronicle_feed.gd").new()
	var copy:=VBoxContainer.new()
	feed.call("_battle_links",copy,{"action":{"kind":"court","focus":{"civ_id":civ_id},"battle_seed":42}})
	var links:Node=copy.get_node_or_null("BattleLinks")
	assert_object(links).is_not_null()
	assert_int(links.get_child_count()).is_equal(1)
	assert_str(String((links.get_child(0) as Button).text)).is_equal("Watch the battle")
	# A court matter with no battle offers nothing.
	var plain:=VBoxContainer.new()
	feed.call("_battle_links",plain,{"action":{"kind":"court","focus":{"civ_id":civ_id}}})
	assert_object(plain.get_node_or_null("BattleLinks")).is_null()
	for node:Node in [copy,plain,feed]: node.free()


# ---------------------------------------------------------------------------
# Saves
# ---------------------------------------------------------------------------

func test_the_battles_are_saved_and_loaded_together()->void:
	var made:=_two_battles()
	var first_id:String=made[2]; var second_id:String=made[3]
	MilitaryCampaign._fight_own_battles_day()
	assert_bool(MilitaryCampaign.focus_engagement(first_id)).is_true()
	var fought:={first_id:_exchanges(first_id),second_id:_exchanges(second_id)}
	var saved:Dictionary=MilitaryCampaign.export_state()
	assert_int((saved.engagements as Array).size()).is_equal(2)
	assert_str(String(saved.focused_engagement)).is_equal(first_id)
	MilitaryCampaign.reset_for_new_world()
	assert_dict(MilitaryCampaign.own_engagements).is_empty()
	var loaded:Dictionary=MilitaryCampaign.import_state(saved)
	assert_bool(loaded.has("error")).override_failure_message(str(loaded)).is_false()
	assert_int(MilitaryCampaign.own_engagements.size()).is_equal(2)
	assert_str(String(MilitaryCampaign.active_engagement.get("id",""))).is_equal(first_id)
	for id in fought: assert_int(_exchanges(id)).is_equal(int(fought[id]))
	# And they go on from where they were.
	MilitaryCampaign._fight_own_battles_day()
	for id in fought:
		if MilitaryCampaign.own_engagements.has(id): assert_int(_exchanges(id)).is_greater(int(fought[id]))
	assert_array(MilitaryCampaign.validate_state()).is_empty()


func test_an_older_save_with_one_battle_loads_into_the_registry()->void:
	var first:=_steady(_army(120,5.0))
	var started:Dictionary=_fight(first,_band_like(first,115),"f1",11)
	assert_bool(started.has("error")).is_false()
	var saved:Dictionary=MilitaryCampaign.export_state()
	# As an older game saved it: one battle, no registry, no id, no blocks.
	saved.erase("engagements"); saved.erase("focused_engagement")
	var legacy:Dictionary=saved.active_engagement
	for key in ["id","battle","ground","progress"]: legacy.erase(key)
	MilitaryCampaign.reset_for_new_world()
	var loaded:Dictionary=MilitaryCampaign.import_state(saved)
	assert_bool(loaded.has("error")).override_failure_message(str(loaded)).is_false()
	assert_int(MilitaryCampaign.own_engagements.size()).is_equal(1)
	var engagement:Dictionary=MilitaryCampaign.active_engagement
	assert_str(String(engagement.get("id",""))).is_equal("%d-%d" % [int(GameState.elapsed_days),11])
	assert_bool((engagement.get("battle",{}) as Dictionary).has("sides")).is_true()
	MilitaryCampaign._fight_own_battles_day()
	var id:=String(engagement.get("id",""))
	if MilitaryCampaign.own_engagements.has(id): assert_int(_exchanges(id)).is_greater(0)
	else: assert_str(String(MilitaryCampaign.battle_history[0].id)).is_equal(id)


# ---------------------------------------------------------------------------
# The war leader's clashes, kept to be watched
# ---------------------------------------------------------------------------

func test_a_war_leader_clash_is_kept_and_opens_in_the_battle_panel()->void:
	var raiders:Dictionary=WarLoop._band("Esurai raiders",14,0.2,0.5,"their war leader",0.5)
	var ours:Dictionary=WarLoop._band("Seanstone",18,0.2,0.55,"Rovik Longstride",0.6)
	var fight:Dictionary=WarLoop._clash(raiders,ours,1.0,"raid:%s:1" % civ_id)
	var seed:int=WarLoop._observe("raid:%s:1" % civ_id,"Esurai Raiders at Planted Fields","at the planted fields",civ_id,"defender",fight)
	assert_int(seed).is_greater_equal(0)
	var kept:Array=WarLoop.observed_battles()
	assert_int(kept.size()).is_equal(1)
	# The panel finds it by the seed the Chronicle carries, finished, and reads it.
	var found:Dictionary=View.find(seed)
	assert_bool(found.is_empty()).is_false()
	assert_bool(bool(found.live)).is_false()
	var view:Dictionary=Record.view(found.record,View.words(found.record,false))
	assert_bool(bool(view.player)).is_true()
	assert_str(String(view.names.right)).is_equal("the Esurai")
	assert_str(String(view.where)).is_equal("at the planted fields")
	assert_int(int(view.sides.left.totals.went_in)).is_equal(18)
	assert_int(int(view.sides.right.totals.went_in)).is_equal(14)
	assert_bool((view.phases as Array).is_empty()).is_false()
	# Bounded: only the newest few are kept, and the ledger stays loadable.
	for n in 10:
		var key:="raid:%s:%d" % [civ_id,n+2]
		WarLoop._observe(key,"Raid %d" % n,"at the herds",civ_id,"defender",WarLoop._clash(raiders,ours,1.0,key))
	assert_int(WarLoop.observed_battles().size()).is_equal(WarLoop.OBSERVED_MAX)
	assert_str(String(WarLoop.observed_battles()[0].headline)).is_equal("Raid 9")
	assert_bool(WarLoop.valid_state(WarLoop.state())).is_true()
	assert_int(JSON.stringify(WarLoop.observed_battles()).length()).is_less_equal(WarLoop.OBSERVED_CHARS)


# ---------------------------------------------------------------------------
# Cost
# ---------------------------------------------------------------------------

func test_a_day_of_eight_battles_is_quick()->void:
	var armies:Array=[]
	for n in 8:
		var army_id:=_army(60,3.0+float(n))
		var started:Dictionary=_fight(army_id,_band_like(army_id,58),"b%d" % n,100+n)
		assert_bool(started.has("error")).override_failure_message(str(started)).is_false()
		armies.append(army_id)
	assert_int(MilitaryCampaign.own_engagements.size()).is_equal(8)
	var begun:=Time.get_ticks_usec()
	MilitaryCampaign._fight_own_battles_day()
	var spent:=float(Time.get_ticks_usec()-begun)/1000.0
	print("BENCH eight battles, one day: %.1f ms" % spent)
	assert_float(spent).is_less(400.0)
