extends GdUnitTestSuite
## A capital objective must meet the armies actually holding its approach.
## Geometry is shared by every actor; integration cases use the real council,
## march and battle commit, not a second combat model.
const Defense := preload("res://scripts/border_defense.gd")
const Council := preload("res://scripts/war_council.gd")
const War := preload("res://scripts/war_loop.gd")
const Route := preload("res://scripts/army_land_route.gd")

var _processing:Dictionary = {}
var _world_started := false
var civ_id := ""
var city_id := ""
var origin := Vector2.ZERO
var capital := Vector2.ZERO

static func _pack(at:Vector2) -> Dictionary:
	return {"x":at.x,"z":at.y}

static func _point(force:Dictionary) -> Vector2:
	var p:Dictionary = force.get("position",{})
	return Vector2(float(p.get("x",0)),float(p.get("z",0)))

static func _defender(id:String,at:Vector2,men:int=3000,half_span:float=6.0) -> Dictionary:
	return {"id":id,"civ_id":"rival","owner":"rival","position":_pack(at),"troops":men,
		"morale":0.9,"readiness":1.0,"provision_ratio":1.0,"supply_level":1.0,"status":"stationed",
		"formations":[{"count":men,"equipment":men,"training":0.8,"personnel_condition":1.0}],
		"border_sector":{"owner":"rival","civ_id":"player","anchor":_pack(at),
			"points":[_pack(at+Vector2(0,-half_span)),_pack(at+Vector2(0,half_span))],
			"assigned_troops":men,"day":100,"organization":4.0}}

func test_swept_march_meets_first_defense_even_when_it_could_cross_both_in_one_day() -> void:
	var near := _defender("near",Vector2(-6,0))
	var far := _defender("far",Vector2(6,0))
	var before := [near.duplicate(true),far.duplicate(true)]
	var contact:Dictionary = Defense.first_contact(Vector2(-20,0),Vector2(20,0),[far,near],{"troops":30000})
	assert_dict(contact).is_not_empty()
	if contact.is_empty(): return
	assert_str(String(contact.formation_id)).is_equal("near")
	assert_float((contact.point as Vector2).x).is_less(-5.9)
	assert_float(float(contact.t)).is_between(0.0,0.5)
	assert_array([near,far]).is_equal(before)

func test_unheld_gap_is_passable_and_a_small_detachment_cannot_seal_the_whole_assignment() -> void:
	var thin := _defender("thin",Vector2.ZERO,30,10.0)
	var full := _defender("full",Vector2.ZERO,4000,10.0)
	assert_dict(Defense.first_contact(Vector2(-12,7),Vector2(12,7),[thin],{"troops":100})).is_empty()
	assert_dict(Defense.first_contact(Vector2(-12,7),Vector2(12,7),[full],{"troops":100})).is_not_empty()
	assert_dict(Defense.first_contact(Vector2(-12,14),Vector2(12,14),[full],{"troops":100})).is_empty()

func test_defense_geometry_is_actor_symmetric_and_roundtrips_without_new_soldiers() -> void:
	var force := _defender("line",Vector2.ZERO)
	var count := int(force.troops)
	var saved:Dictionary = JSON.parse_string(JSON.stringify(force))
	assert_array(Array(Defense.coverage(saved))).is_equal(Array(Defense.coverage(force)))
	var east:Dictionary = Defense.first_contact(Vector2(-12,0),Vector2(12,0),[force],{"troops":1200,"owner":"player"})
	force.owner="player"; force.civ_id="player"; force.border_sector.owner="player"; force.border_sector.civ_id="rival"
	var west:Dictionary = Defense.first_contact(Vector2(12,0),Vector2(-12,0),[force],{"troops":1200,"owner":"rival"})
	assert_dict(east).is_not_empty(); assert_dict(west).is_not_empty()
	if east.is_empty() or west.is_empty(): return
	assert_float((east.point as Vector2).x).is_equal_approx(-(west.point as Vector2).x,0.00001)
	assert_int(int(force.troops)).is_equal(count)
	assert_int(int(saved.troops)).is_equal(count)

func test_broken_or_departed_defenders_do_not_leave_an_invisible_wall() -> void:
	var force := _defender("line",Vector2.ZERO)
	assert_int(Defense.coverage(force).size()).is_greater_equal(2)
	force["resting"]=true
	assert_array(Array(Defense.coverage(force))).is_empty()
	force.erase("resting"); force.position=_pack(Vector2(12,0)); force.status="moving"
	assert_array(Array(Defense.coverage(force))).is_empty()
	assert_dict(Defense.first_contact(Vector2(-4,0),Vector2(4,0),[force],{"troops":100})).is_empty()

func _start_world() -> void:
	_world_started=true
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]:
		_processing[node]=node.is_processing(); node.set_process(false)
	WorldSimulation.clear()
	GameState.reset_for_new_world(74017); GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world(); FoodSystem.reset_for_new_world(); MilitaryCampaign.reset_for_new_world(); CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world(); ForeignDiplomacy.ensure(); GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(1200); GameState.housing_capacity=1500
	GameState.settlement_site_committed=true; GameState.settlement_completed=["Hearth Circle"]; SettlementModel.ensure_founded()
	GameState.select_founding_focus("provision"); GameState.settlement_name="Seanstone"
	GameState.society_capacities["institutions"]=0.4
	GovernmentPeopleSystem._update_government_stage(false); GovernmentPeopleSystem.initialize()
	GameState.resource_stockpiles["Food"]=1000000.0; GameState.food_stocks={"Preserved food":1000000.0}
	GameState.elapsed_days=88*365
	CivilizationSystem.set_scout_geography_authority(func(_at:Vector2)->bool:return true)
	Route.clear_cache()
	origin=CivilizationSystem.player_world_origin; capital=origin+Vector2(8,0)
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ_id=String(civ.id); civ.name="Esurai"; civ.military_population=240.0
	civ.player_relation.at_war=false; civ.player_relation.treaty="none"; civ.player_relation.contact_level=2; civ.player_relation.home_location_known=true
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	city_id=String(region.id)
	for place:Dictionary in civ.strategic_regions:
		if String(place.get("role",""))=="capital": place.role="granary"
	region.role="capital"; region.name="Tsaren"; region.position=capital
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",city_id,0.8,int(GameState.elapsed_days),"scout report","test"),int(GameState.elapsed_days))
	var rec:Dictionary=CivilizationSystem.city_intelligence.records.player[city_id]
	rec.position=_pack(capital)
	rec.fields.garrison={"low":40,"high":40,"observed_day":int(GameState.elapsed_days),"reported_day":int(GameState.elapsed_days)}
	MilitaryCampaign.military_inventory.improvised=500
	MilitaryCampaign.raise_recruits(500); MilitaryCampaign.start_training("levy","improvised",500)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true)); MilitaryCampaign.training_queue.clear()
	for formation:Dictionary in MilitaryCampaign.home_army.formations: formation.training=0.8
	MilitaryCampaign.home_army.morale=0.9; MilitaryCampaign.home_army.readiness=0.9
	# A real legacy foreign force, placed on the approach. It is intentionally
	# not a supplied scout sighting: physically meeting it must reveal contact.
	var guard:Dictionary=CivilizationSystem.foreign_formations[0].duplicate(true)
	guard.id="border-guard"; guard.civ_id=civ_id; guard.kind="patrol"; guard.actual_troops=100
	guard.strength_share=100.0/240.0
	guard.command_position=_pack(origin+Vector2(3,0)); guard.command_response_day=int(GameState.elapsed_days)
	guard.disabled_until_day=0; guard.morale=0.9; guard.readiness=0.8
	guard.border_sector=_defender("guard",origin+Vector2(3,0),100,1).border_sector
	guard.border_sector.owner=civ_id; guard.border_sector.civ_id="player"
	CivilizationSystem.foreign_formations.assign([guard])
	War.blood_feud(civ_id,int(GameState.elapsed_days),"test frontier dispute")

func after_test() -> void:
	if not _world_started: return
	CivilizationSystem.set_scout_geography_authority(Callable()); Route.clear_cache()
	GameState.elapsed_days=0; MilitaryCampaign.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world(); CivilizationSystem.reset_for_new_world(); FoodSystem.reset_for_new_world(); DiscoverySystem.reset_for_new_world()
	GameState.reset_for_new_world(74017); ProgressionSystem.reset_for_new_world(); WorldSimulation.clear(); WorldSimulation.context_provider=Callable()
	for node:Node in _processing: node.set_process(bool(_processing[node]))
	_processing.clear(); _world_started=false

func _take() -> Dictionary:
	var order:Dictionary=Council.order(civ_id,"take",{"place":{"city_id":city_id,"civ_id":civ_id,"name":"Tsaren","position":_pack(capital)}})
	for army:Dictionary in MilitaryCampaign.field_armies:
		if String((army.get("council",{}) as Dictionary).get("act",""))=="take": return army
	assert_bool(false).override_failure_message("Council did not send the capital objective: "+str(order)).is_true()
	return {}

func _march_to_contact() -> Dictionary:
	var army:=_take()
	if army.is_empty(): return {}
	# A short road fits in a normal day's budget. The swept collision must
	# stop at 3 km even though the ordered capital is only 8 km from home.
	GameState.elapsed_days+=1
	MilitaryCampaign._process_field_army_movement_day()
	return MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(int(army.army_id))]

func test_real_council_capital_march_meets_defense_before_the_city() -> void:
	_start_world()
	var population:=int(GameState.population_total)
	var soldiers:=int(MilitaryCampaign.home_army.troops)
	var army:=_march_to_contact()
	if army.is_empty(): return
	assert_float(_point(army).x-origin.x).is_less(3.1)
	assert_str(String(army.get("destination_id",""))).is_equal(city_id)
	assert_bool(army.has("city_operation")).is_true()
	assert_dict(MilitaryCampaign.active_engagement).is_not_empty()
	if MilitaryCampaign.active_engagement.is_empty(): return
	assert_bool(bool(MilitaryCampaign.active_engagement.threat.get("front_contact",false))).is_true()
	assert_str(String(MilitaryCampaign.active_engagement.threat.get("formation_id",""))).is_equal("border-guard")
	assert_str(String(CivilizationSystem.region_snapshot(civ_id,city_id).get("controller",""))).is_not_equal("player")
	assert_int(int(GameState.population_total)).is_equal(population)
	var deployed:=int(MilitaryCampaign.home_army.troops)
	for band:Dictionary in MilitaryCampaign.field_armies: deployed+=int(band.troops)
	assert_int(deployed).is_equal(soldiers)
	var army_id:=int(army.army_id)
	var saved:Dictionary=MilitaryCampaign.export_state()
	var restored:Dictionary=MilitaryCampaign.import_state(JSON.parse_string(JSON.stringify(saved)))
	assert_bool(restored.has("ok")).override_failure_message(str(restored)).is_true()
	army=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(army_id)]
	assert_bool(army.has("city_operation")).is_true()
	assert_str(String(army.get("destination_id",""))).is_equal(city_id)
	var before:=_point(army)
	MilitaryCampaign._process_field_army_movement_day()
	assert_vector(_point(army)).is_equal(before)

func test_front_victory_preserves_the_capital_objective_and_can_meet_a_second_inland_defense() -> void:
	_start_world()
	var army:=_march_to_contact()
	if army.is_empty(): return
	assert_dict(MilitaryCampaign.active_engagement).is_not_empty()
	if MilitaryCampaign.active_engagement.is_empty(): return
	var initial_id:=int(army.army_id)
	var before_population:=int(GameState.population_total)
	var engagement:Dictionary=MilitaryCampaign.active_engagement
	var enemy_side:=MilitaryCampaign._engagement_enemy_side(engagement)
	engagement[enemy_side]["morale"]=0.01
	for _round in 8:
		if MilitaryCampaign.active_engagement.is_empty(): break
		MilitaryCampaign.active_engagement.erase("awaiting_player_view")
		MilitaryCampaign.fight_engagement_day("press")
	assert_dict(MilitaryCampaign.active_engagement).is_empty()
	army=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(initial_id)]
	assert_int(int(army.army_id)).is_equal(initial_id)
	assert_str(String(army.get("destination_id",""))).is_equal(city_id)
	assert_bool(army.has("city_operation")).is_true()
	assert_int(int(GameState.population_total)).is_less_equal(before_population)
	var second:Dictionary=CivilizationSystem.foreign_formations[0].duplicate(true)
	second.id="inland-guard"; second.disabled_until_day=0; second.actual_troops=100; second.morale=0.9; second.readiness=0.8
	second.command_position=_pack(origin+Vector2(6,0)); second.command_response_day=int(GameState.elapsed_days)
	second.erase("border_sector")
	CivilizationSystem.foreign_formations.append(second)
	GameState.elapsed_days+=1; MilitaryCampaign._process_field_army_movement_day()
	assert_dict(MilitaryCampaign.active_engagement).is_not_empty()
	if MilitaryCampaign.active_engagement.is_empty(): return
	assert_str(String(MilitaryCampaign.active_engagement.threat.get("formation_id",""))).is_equal("inland-guard")
	assert_float(_point(army).x-origin.x).is_between(3.0,6.1)
	assert_str(String(CivilizationSystem.region_snapshot(civ_id,city_id).get("controller",""))).is_not_equal("player")

func test_retreat_from_front_cannot_resume_the_capital_march() -> void:
	_start_world()
	var army:=_march_to_contact()
	if army.is_empty(): return
	assert_dict(MilitaryCampaign.active_engagement).is_not_empty()
	if MilitaryCampaign.active_engagement.is_empty(): return
	MilitaryCampaign.active_engagement.erase("awaiting_player_view")
	MilitaryCampaign.fight_engagement_day("retreat")
	assert_dict(MilitaryCampaign.active_engagement).is_empty()
	army=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(int(army.army_id))]
	var before:=_point(army)
	GameState.elapsed_days+=1; MilitaryCampaign._process_field_army_movement_day()
	assert_float(_point(army).x).is_less_equal(before.x+0.001)
	assert_str(String(CivilizationSystem.region_snapshot(civ_id,city_id).get("controller",""))).is_not_equal("player")
