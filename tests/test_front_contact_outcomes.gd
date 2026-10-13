extends GdUnitTestSuite
## Battle evidence and the owner's force must agree about whether ground is held.
const Front := preload("res://scripts/army_front_contact.gd")
const Defense := preload("res://scripts/border_defense.gd")
const Combat := preload("res://scripts/civilization_combat.gd")
const Memory := preload("res://scripts/rival_stand_down.gd")
const Model := preload("res://scripts/war_front_model.gd")
const Route := preload("res://scripts/army_land_route.gd")

var _processing:Dictionary = {}
var owner_id := ""
var origin := Vector2.ZERO
var today := 120

static func _pack(at:Vector2) -> Dictionary:
	return {"x":at.x,"z":at.y}

static func _sector(at:Vector2,owner:String) -> Dictionary:
	return {"owner":owner,"civ_id":"human","anchor":_pack(at),"points":[_pack(at+Vector2(0,-1)),_pack(at+Vector2(0,1))],"assigned_troops":120,"day":100,"organization":4.0}

func before_test() -> void:
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]:
		_processing[node]=node.is_processing();node.set_process(false)
	WorldSimulation.clear()
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();ForeignDiplomacy.ensure();GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(1200);GameState.housing_capacity=1500
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.select_founding_focus("provision");GameState.settlement_name="Front outcomes fixture"
	GameState.society_capacities["institutions"]=0.4
	GovernmentPeopleSystem._update_government_stage(false);GovernmentPeopleSystem.initialize()
	GameState.resource_stockpiles["Food"]=1000000.0;GameState.food_stocks={"Preserved food":1000000.0}
	GameState.elapsed_days=today
	CivilizationSystem.set_scout_geography_authority(func(_at:Vector2)->bool:return true)
	Route.clear_cache()
	origin=CivilizationSystem.player_world_origin
	owner_id=String(CivilizationSystem.civilizations[0].id)
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Our levy",[{"id":1,"unit":"levy","weapon":"improvised","count":500,"equipment":500,"training":0.8}],0.9,0.8)
	MilitaryCampaign.home_army.provision_ratio=1.0;MilitaryCampaign.home_army.supply_level=1.0

func after_test() -> void:
	CivilizationSystem.set_scout_geography_authority(Callable());Route.clear_cache()
	GameState.elapsed_days=0;MilitaryCampaign.reset_for_new_world();GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();CivilizationSystem.reset_for_new_world();FoodSystem.reset_for_new_world();DiscoverySystem.reset_for_new_world()
	GameState.reset_for_new_world(74017);ProgressionSystem.reset_for_new_world();WorldSimulation.clear();WorldSimulation.context_provider=Callable()
	for node:Node in _processing:node.set_process(bool(_processing[node]))
	_processing.clear()

func test_a_fit_defender_keeps_its_sector_after_an_inconclusive_battle() -> void:
	var made:Dictionary=MilitaryCampaign.create_field_army(120)
	assert_bool(made.has("ok")).override_failure_message(str(made)).is_true()
	if not made.has("ok"):return
	var id:=int(made.army.army_id)
	var army:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(id)]
	army.position=_pack(origin);army.status="stationed";army.provision_ratio=1.0
	army.border_sector=_sector(origin,"player")
	var before:=Defense.coverage(army,today)
	assert_int(before.size()).is_greater_equal(2)
	var result:={"threat":{"front_contact":true},"home_force_kind":"field_army","home_force_id":id,"home_side":"defender","termination":{"type":"continued"}}
	for outcome in ["inconclusive","continued"]:
		result.outcome=outcome
		Front.after_battle(MilitaryCampaign,result)
		assert_bool(army.has("border_sector")).is_true()
		assert_array(Array(Defense.coverage(army,today))).is_equal(Array(before))
		assert_bool(bool(army.get("resting",false))).is_false()
		assert_int(int(army.get("command_recover_until",0))).is_less_equal(today)
	# A genuine loss through the same hook must still open the sector.
	result.outcome="attacker_victory"
	Front.after_battle(MilitaryCampaign,result)
	assert_bool(army.has("border_sector")).is_false()
	assert_array(Array(Defense.coverage(army,today))).is_empty()
	assert_str(String(Front.snapshot(army).state)).is_equal("breached")
	assert_int(int(army.troops)).is_equal(120)

func test_a_witnessed_defeat_clears_only_that_recent_held_ribbon() -> void:
	var points:=[_pack(origin+Vector2(3,-1)),_pack(origin+Vector2(3,1))]
	var formation:={"id":"seen-guard","civ_id":owner_id,"kind":"expedition","strength_share":0.1,"readiness":0.8}
	CivilizationSystem.foreign_formations.assign([formation])
	var seen:={"formation_id":"seen-guard","civ_id":owner_id,"kind":"expedition","last_seen_day":today-2,"position":_pack(origin+Vector2(3,0)),"strength":120.0,"readiness":0.8,"visible":true,"defense_points":points.duplicate(true),"border_front":{"id":"seen-guard","points":points.duplicate(true),"assigned":true,"state":"held","day":today-2}}
	var distant:=seen.duplicate(true);distant.formation_id="distant-guard";distant.visible=false;distant.last_seen_day=today-8
	distant.border_front.id="distant-guard";distant.border_front.day=today-8
	CivilizationSystem.foreign_sightings.assign([seen,distant])
	var untouched:=distant.duplicate(true)
	CivilizationSystem.last_observation_day=today
	var result:={"home_side":"attacker","outcome":"attacker_victory","threat":{"front_contact":true},"defender":{"name":"Their guard","initial_troops":120,"remaining_troops":40,"morale":0.1},"termination":{"type":"rout","defeated":"Their guard","captor":"Our levy"}}
	CivilizationSystem.resolve_foreign_formation_after_battle("seen-guard",result)
	var recent:Array=CivilizationSystem.local_observation_snapshot().recent
	var defeated:Dictionary={}
	for entry:Dictionary in recent:
		if String(entry.id)=="seen-guard":defeated=entry
	assert_dict(defeated).is_not_empty()
	if defeated.is_empty():return
	assert_array(defeated.defense_points).is_empty()
	assert_array(defeated.border_front.points).is_empty()
	assert_str(String(defeated.border_front.state)).is_equal("breached")
	assert_int(int(defeated.last_seen_day)).is_equal(today)
	var rendered:=defeated.duplicate(true);rendered.strength=40.0;rendered.age_days=0
	assert_array(Model.deployed_fronts([],[rendered],origin)).is_empty()
	assert_dict(CivilizationSystem.foreign_sightings[1]).is_equal(untouched)

func test_a_recovered_owned_guard_can_be_seen_and_contacted_before_old_memory_expires() -> void:
	var at:=origin+Vector2(3,0)
	WorldSimulation.context_provider=func(_at:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":0.1,"surface_water_recognized":true}
	WorldSimulation.create_actor(owner_id,hash(owner_id)&0x7fffffff,origin+Vector2(8,0))
	WorldSimulation.actors[owner_id].controller="manual"
	WorldSimulation.actors[owner_id].systems.CivilizationSystem.scout_land_authority=func(_p:Vector2)->bool:return true
	assert_bool(WorldSimulation.submit(owner_id,{"kind":"found"}).get("ok",false)).is_true()
	var guard_id:int=WorldSimulation.scoped(owner_id,func()->int:
		WorldSimulation.state.ensure_population_total(1000);WorldSimulation.state.elapsed_days=today
		WorldSimulation.state.settlement_completed=["Hearth Circle"];WorldSimulation.settlements.ensure_founded()
		WorldSimulation.state.resource_stockpiles["Food"]=1000000.0
		var mc=WorldSimulation.military
		mc.home_army=mc.simulator.create_formation_force("Their levy",[{"id":1,"unit":"levy","weapon":"improvised","count":300,"equipment":300,"training":0.8}],0.9,0.8)
		var made:Dictionary=mc.create_field_army(120)
		if made.has("error"):return -1
		var force:Dictionary=mc.field_armies[mc._field_army_index(int(made.army.army_id))]
		force.position=_pack(at);force.status="stationed";force.location_id="field_position";force.provision_ratio=1.0
		force.border_sector=_sector(at,owner_id)
		force.command_recover_until=today-6;force.resting=false;force.morale=0.9
		return int(force.army_id))
	assert_int(guard_id).is_greater(0)
	if guard_id<=0:return
	WorldSimulation.enabled=true;WorldSimulation.refresh_projections();WorldSimulation.refresh_views()
	for civ:Dictionary in CivilizationSystem.civilizations:
		if String(civ.id)==owner_id:civ.player_relation.at_war=true;civ.player_relation.contact_level=2
	var formation_id:="%s:army:%d" % [owner_id,guard_id]
	CivilizationSystem.formation_memory[formation_id]={"day":today-20,"until":today+25,"morale":0.1,"beaten":true}
	var index:=CivilizationSystem._foreign_formation_index(formation_id)
	assert_int(index).is_greater_equal(0)
	if index<0:return
	CivilizationSystem.foreign_formations[index].disabled_until_day=today+25
	CivilizationSystem.foreign_formations[index].morale_cap=0.1
	assert_bool(Memory.standing_down(CivilizationSystem.formation_memory,formation_id,today)).is_true()
	var refreshed:=Combat.refresh_formation(CivilizationSystem.foreign_formations[index])
	assert_bool(bool(refreshed.can_defend)).is_true()
	assert_int(int(refreshed.disabled_until_day)).is_less_equal(today)
	assert_float(float(refreshed.morale_cap)).is_equal_approx(0.9,0.0001)
	CivilizationSystem._process_local_observation(today,true)
	assert_dict(CivilizationSystem.visible_formation_sighting(formation_id)).is_not_empty()
	var incident:Dictionary=CivilizationSystem.foreign_formation_engagement_data(formation_id,120)
	assert_bool(incident.has("error")).override_failure_message(str(incident)).is_false()
	if incident.has("error"):return
	assert_float(float(incident.morale_cap)).is_equal_approx(0.9,0.0001)
	var made:Dictionary=MilitaryCampaign.create_field_army(120)
	assert_bool(made.has("ok")).override_failure_message(str(made)).is_true()
	if not made.has("ok"):return
	var army:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(int(made.army.army_id))]
	army.position=_pack(at-Vector2(0.1,0));army.status="stationed";army.location_id="field_position"
	var foes:Array=MilitaryCampaign.command_hierarchy.land.enemies(today)
	var contact:=Defense.first_contact(at-Vector2(0.1,0),at-Vector2(0.1,0),foes,army)
	assert_dict(contact).is_not_empty()
	if contact.is_empty():return
	assert_str(String(contact.formation_id)).is_equal(formation_id)
	var launched:Dictionary=MilitaryCampaign.launch_front_contact(int(army.army_id),contact)
	assert_bool(launched.has("error")).override_failure_message(str(launched)).is_false()
	assert_bool(Combat.reserved({"actor":owner_id,"field_id":guard_id})).is_true()
