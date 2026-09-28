extends GdUnitTestSuite
## The war map reads a battle being fought from the real campaign (not a
## fixture): MilitaryCampaign's engagement reaches the overlay's inputs as a
## battle mark on our side, with the band fighting it marked "in battle".

const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")
const Marks:=preload("res://scripts/hud/battle_marks.gd")

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
	GameState.ensure_population_total(900);GameState.housing_capacity=1000
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


func _band(name:String,count:int,morale:=0.7,readiness:=0.6)->Dictionary:
	var sim:CombatSimulator=MilitaryCampaign.simulator
	var force:=sim.create_formation_force(name,[{"unit":"levy","weapon":"improvised","count":count,"equipment":count,"training":0.4}],morale,readiness)
	force["commander"]=sim.create_commander(name+" leader",0.55,0.55,0.5,0.6)
	return force


func _army(count:int)->int:
	MilitaryCampaign.raise_recruits(count)
	MilitaryCampaign.start_training("levy","improvised",count)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()
	var made:=MilitaryCampaign.create_field_army(count)
	var army_id:=int((made.army as Dictionary).army_id)
	var index:=MilitaryCampaign._field_army_index(army_id)
	var origin:Vector2=CivilizationSystem.player_world_origin
	MilitaryCampaign.field_armies[index]["position"]={"x":origin.x+5.0,"z":origin.y}
	MilitaryCampaign.field_armies[index]["status"]="stationed"
	return army_id


func test_a_battle_being_fought_reaches_the_war_map()->void:
	var army_id:=_army(60)
	var origin:Vector2=CivilizationSystem.player_world_origin
	MilitaryCampaign.active_threat={"id":"contact","title":"x","incident_kind":"campaign","campaign_mode":"offensive","source_civ_id":civ_id,"source_name":"Esurai","field_encounter":true,"formation_id":"f1",
		"target_region_id":"","target_region_name":"the field contact","field_army_id":army_id,"enemy_force":_band("Esurai band",55),"terrain_defense":1.0,"seed":11,"deadline_day":99999,
		"target_position":{"x":origin.x+5.4,"z":origin.y}}
	var started:=MilitaryCampaign.begin_threat_engagement()
	assert_bool(started.has("error")).override_failure_message(str(started)).is_false()
	assert_dict(MilitaryCampaign.active_engagement).is_not_empty()
	var overlay:Control=auto_free(Overlay.new())
	var inputs:Dictionary=overlay.collect()
	var battles:Array=inputs.get("battles",[])
	assert_int(battles.size()).is_equal(1)
	var battle:Dictionary=battles[0]
	assert_bool(bool(battle.ours)).is_true()
	assert_int(int(battle.army_id)).is_equal(army_id)
	assert_str(String(battle.sides.b.name)).is_equal("Esurai")
	# Between our band and the foe it met, about five km out from home.
	assert_float((battle.pos as Vector2).distance_to(origin+Vector2(5.2,0.0))).is_less(0.01)
	assert_str(Marks.label(battle)).ends_with("· day 1")
	var built:=Overlay.compose(inputs)
	assert_int((built.battles as Array).size()).is_equal(1)
	var ours:Array=(built.marks as Array).filter(func(m:Dictionary)->bool: return String(m.side)=="ours" and int(m.get("army_id",0))==army_id)
	assert_int(ours.size()).is_equal(1)
	assert_str(String(ours[0].state)).is_equal("fighting")
	# The click on it asks the game's own battle view for this army's fight.
	var request:=Overlay.battle_view_request(battle)
	assert_str(String(request.method)).is_equal("_open_battle_graphics")
	assert_array(request.args).is_equal([army_id,-1])
	# When the fight is over, nothing is left standing on the map as a live battle.
	MilitaryCampaign.active_engagement.clear()
	assert_array(overlay.collect().get("battles",[])).is_empty()
