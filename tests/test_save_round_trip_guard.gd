extends GdUnitTestSuite
## A whole-game save made in the middle of a war must come back exactly and go
## on exactly as if it had never been saved: a town we hold after the sword,
## with the chase offered at court; a chase out after the men who fled; the
## men of a held town bound under a harsh hand; two battles being fought.
##
## Each case writes a real save (SaveSystem, a unique temporary slot), plays on
## a few days, loads, and plays the same days again. The saved state after the
## load must equal the state at the save, and the days after the load must end
## where the unsaved days ended. A new field a system forgets to save, fails to
## reset on load, or restores in a different shape fails here. An older save
## without the newer fields loads with each at a safe default.

const CC:=preload("res://scripts/court_commands.gd")
const WO:=preload("res://scripts/court_war_orders.gd")
const Route:=preload("res://scripts/army_land_route.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Verify:=preload("res://tools/verify_campaign_save.gd")
const Legacy:=preload("res://tests/legacy_save_fixture.gd")
const BIND:="Round up all the men of Tsaren and tie them up. If any resist or attempt to flee, threaten their wives and children."

var home:=Vector2.ZERO
var city:=Vector2.ZERO
var city_id:=""
var civ_id:=""
var slot:=""
var _processing:Dictionary={}

func _land(_p:Vector2)->bool:
	return true

func before_test()->void:
	slot="save_round_trip_guard_%d_%d" % [OS.get_process_id(),Time.get_ticks_usec()]
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
	GameState.society_capacities["institutions"]=0.4
	GovernmentPeopleSystem._update_government_stage(false)
	GovernmentPeopleSystem.initialize()
	GameState.resource_stockpiles["Food"]=1000000.0
	GameState.elapsed_days=88*365
	MilitaryCampaign.last_processed_day=int(GameState.elapsed_days)
	Route.clear_cache()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ["name"]="Esurai"
	civ_id=String(civ.id)
	# At war as the save validator knows war: the war treaty, not a bare flag.
	var relation:Dictionary=civ.player_relation
	relation.at_war=true; relation.treaty="war"; relation.stance="hostile"; relation.contact_level=2; relation.home_location_known=true
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	region["name"]="Tsaren"
	region["population"]=300.0
	# Their towns never hold more people than their people number, and their
	# age groups add up to their people (the save validator checks both).
	var represented:=0.0
	for r:Dictionary in civ.strategic_regions: represented+=float(r.get("population",0.0))
	var population:=float(civ.get("population",0.0))
	if represented>population and population>0.0:
		for cohort in (civ.cohorts as Dictionary): civ.cohorts[cohort]=float(civ.cohorts[cohort])*represented/population
		civ["population"]=represented
	city_id=String(region.id)
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",city_id,.8,int(GameState.elapsed_days),"scout report","test"),int(GameState.elapsed_days))
	home=CivilizationSystem.player_world_origin
	city=home+Vector2(-20.0,8.0)
	CivilizationSystem.city_intelligence.records.player[city_id]["position"]={"x":city.x,"z":city.y}
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))

func after_test()->void:
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
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

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

func _band(count:int,name:String)->int:
	MilitaryCampaign.military_inventory["improvised"]=int(MilitaryCampaign.military_inventory.get("improvised",0))+count
	MilitaryCampaign.raise_recruits(count)
	MilitaryCampaign.start_training("levy","improvised",count)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()
	var made:=MilitaryCampaign.create_field_army(count,name)
	assert_bool(made.has("error")).override_failure_message(str(made)).is_false()
	return int((made.army as Dictionary).army_id)

## Tsaren taken; 17 of an 18-strong band hold it.
func _captured_tsaren()->Dictionary:
	var army_id:=_band(18,"LEVY BAND 1")
	var index:=MilitaryCampaign._field_army_index(army_id)
	var army:Dictionary=MilitaryCampaign.field_armies[index]
	army["supply_level"]=1.0; army["readiness"]=1.0
	army["position"]={"x":city.x+0.3,"z":city.y}
	army["location_id"]=city_id; army["location_name"]="Tsaren"; army["status"]="stationed"
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var ri:=CivilizationSystem._region_index(civ,city_id)
	civ.strategic_regions[ri]["controller"]="player"
	civ.strategic_regions[ri]["resistance"]=0.6
	var garrison:=MilitaryCampaign.establish_occupation_force(civ_id,civ.strategic_regions[ri],17.0,army_id)
	assert_int(int(garrison.get("troops",0))).override_failure_message(str(garrison)).is_greater(0)
	return MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(army_id)]

func _war_leader(band:Dictionary)->String:
	var audience:=Hall.summon({"figure_id":String((band.commander as Dictionary).get("figure_id",""))})
	assert_dict(audience).is_not_empty()
	return String(audience.id)

func _headman()->String:
	var headman:=GovernmentPeopleSystem.officeholder("Steward")
	if headman.is_empty():
		for person in Hall._officials():
			if String(person.get("office_key",""))!="Marshal": headman=person; break
	assert_dict(headman).is_not_empty()
	var audience:=Hall.summon({"person_id":int(headman.person_id)})
	assert_dict(audience).is_not_empty()
	return String(audience.id)

## Their band as strong, man for man, as the army that meets it.
func _battle(army_id:int,count:int,formation:String,seed:int)->String:
	var index:=MilitaryCampaign._field_army_index(army_id)
	MilitaryCampaign.field_armies[index]["morale"]=0.9
	MilitaryCampaign.field_armies[index]["status"]="stationed"
	var ours:Dictionary=MilitaryCampaign.field_armies[index]
	var band:Dictionary=MilitaryCampaign.simulator.create_formation_force("Esurai band",[{"unit":"levy","weapon":"improvised","count":count,"equipment":0,"training":0.25}],float(ours.get("morale",0.5)),float(ours.get("readiness",0.12)))
	band["commander"]=MilitaryCampaign.simulator.create_commander("Esurai war leader",0.5,0.5,0.5,0.5)
	var at:Dictionary=ours.position
	MilitaryCampaign.active_threat={"id":"contact-"+formation,"title":"x","incident_kind":"campaign","campaign_mode":"offensive","source_civ_id":civ_id,"source_name":"Esurai","field_encounter":true,"formation_id":formation,
		"target_region_id":"","target_region_name":"the field contact","field_army_id":army_id,"enemy_force":band,"terrain_defense":1.0,"seed":seed,"deadline_day":99999,"discovered_day":int(GameState.elapsed_days),
		"target_position":{"x":float(at.x)+0.2,"z":float(at.z)}}
	var started:Dictionary=MilitaryCampaign.begin_threat_engagement(false)
	assert_bool(started.has("error")).override_failure_message(str(started)).is_false()
	return String(started.id)

## One day of the war: the army's day (march, battles, garrisons), then the
## court's business with it (the chase, the garrison's measures, reports).
func _war_day()->void:
	GameState.elapsed_days+=1
	var day:=int(GameState.elapsed_days)
	MilitaryCampaign.last_processed_day=day
	MilitaryCampaign._process_military_day()
	WO.daily(day)

## Save, play `days`, load, play the same days again. Returns what differs.
func _round_trip(days:int)->Dictionary:
	var saved:=SaveSystem.save_game(slot)
	assert_bool(saved.has("error")).override_failure_message(str(saved)).is_false()
	var before:=Verify.capture()
	for i in days: _war_day()
	var expected:=Verify.capture()
	var loaded:=SaveSystem.load_game(slot)
	assert_bool(loaded.has("error")).override_failure_message(str(loaded)).is_false()
	var restored:=Verify.capture()
	var restore_diff:=Verify.details(before,restored)
	for i in days: _war_day()
	var actual:=Verify.capture()
	return {"restored":restore_diff,"continued":Verify.details(expected,actual)}

func _assert_same(result:Dictionary)->void:
	assert_array(result.restored as Array).override_failure_message("the load did not restore the saved world: "+str(result.restored)).is_empty()
	assert_array(result.continued as Array).override_failure_message("the days after the load went differently: "+str(result.continued)).is_empty()

# ---------------------------------------------------------------------------
# Cases
# ---------------------------------------------------------------------------

func test_a_held_town_after_the_sword_saves_with_the_chase_offered()->void:
	var id:=_war_leader(_captured_tsaren())
	var kill:=CC.hear(id,"Kill all the men of Tsaren")
	assert_str(String(kill.war.verdict)).override_failure_message(String(kill.get("actor_says",""))).is_equal("fate")
	var fled:Dictionary=preload("res://scripts/town_ledger.gd").snapshot(civ_id,city_id)  # the flight lives in the town ledger
	assert_int(preload("res://scripts/town_ledger.gd").running_total(preload("res://scripts/town_ledger.gd").of(civ_id,city_id))).is_greater(0)
	_assert_same(_round_trip(2))
	# The escape is still counted and the chase is still offered after a load.
	var loaded:=SaveSystem.load_game(slot)
	assert_bool(loaded.has("error")).override_failure_message(str(loaded)).is_false()
	assert_dict(preload("res://scripts/town_ledger.gd").snapshot(civ_id,city_id)).is_equal(fled)
	assert_str(String((Hall.find(id).get("pending_command",{}) as Dictionary).get("ask",""))).is_equal("chase")

func test_a_chase_out_after_the_men_who_fled_saves_and_comes_back()->void:
	var id:=_war_leader(_captured_tsaren())
	CC.hear(id,"Kill all the men of Tsaren")
	var chase:=CC.hear(id,"Yeah, go ahead and chase them")
	assert_str(String(chase.war.verdict)).override_failure_message(String(chase.get("actor_says",""))).is_equal("act")
	var out:=false
	for army:Dictionary in MilitaryCampaign.field_armies: out=out or army.get("pursuit") is Dictionary
	assert_bool(out).override_failure_message("no detachment went out").is_true()
	# Long enough for the chase to end, report once, walk back and rejoin.
	_assert_same(_round_trip(12))

func test_the_men_of_a_held_town_bound_under_a_harsh_hand_save_and_go_on()->void:
	_captured_tsaren()
	var bind:=CC.hear(_headman(),BIND)
	assert_str(String(bind.war.verdict)).override_failure_message(String(bind.get("actor_says",""))).is_equal("fate")
	var force:=MilitaryCampaign.occupation_force_for_region(civ_id,city_id)
	assert_bool(force.get("measures") is Array and not (force.measures as Array).is_empty()).override_failure_message(str(force.get("measures"))).is_true()
	_assert_same(_round_trip(3))

func test_two_battles_being_fought_save_and_go_on()->void:
	var origin:=CivilizationSystem.player_world_origin
	var first:=_band(120,"LEVY BAND 1")
	var second:=_band(90,"LEVY BAND 2")
	MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(first)]["position"]={"x":origin.x+5.0,"z":origin.y}
	MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(second)]["position"]={"x":origin.x-7.0,"z":origin.y}
	var first_id:=_battle(first,115,"f1",11)
	var second_id:=_battle(second,88,"f2",12)
	assert_int(MilitaryCampaign.own_engagements.size()).is_equal(2)
	# The newer battle is in focus; the older one comes back into focus after.
	var saved:=MilitaryCampaign.export_state()
	assert_str(String(saved.focused_engagement)).is_equal(second_id)
	assert_str(String(saved.focus_before)).is_equal(first_id)
	# Each day fights them in the order they began, before and after a load.
	_assert_same(_round_trip(4))

func test_an_older_save_without_the_newer_fields_loads_with_safe_defaults()->void:
	var id:=_war_leader(_captured_tsaren())
	CC.hear(id,"Kill all the men of Tsaren")
	var fled:Dictionary=preload("res://scripts/town_ledger.gd").snapshot(civ_id,city_id)  # the flight lives in the town ledger
	var made:=Legacy.write(slot)
	assert_bool(made.has("error")).override_failure_message(str(made)).is_false()
	assert_array(made.removed as Array).contains(["curated_GeneralCampaign","reflected_GeneralDialogue","player MilitaryCampaign.engagements","player MilitaryCampaign.joint_operations.raiding","player CivilizationSystem.formation_memory","player ConsequenceEngine._home_intake_today"])
	# The game being played has state of its own that the older save lacks.
	CivilizationSystem.formation_memory["stale"]={"day":1}
	ConsequenceEngine._home_intake_today=0.25
	MilitaryCampaign.joint_operations.state["captured_holding"]=5
	var loaded:=SaveSystem.load_game(slot)
	assert_bool(loaded.has("error")).override_failure_message(str(loaded)).is_false()
	assert_bool(GeneralCampaign.active).is_false()
	assert_dict(CivilizationSystem.formation_memory).is_empty()
	assert_float(ConsequenceEngine._home_intake_today).is_equal(1.0)
	var joint:Dictionary=MilitaryCampaign.joint_operations.state
	assert_dict({"raiding":joint.get("raiding"),"raids_out":joint.get("raids_out"),"war_ledger":joint.get("war_ledger"),"wounded":joint.get("wounded"),"captured_holding":joint.get("captured_holding")}).is_equal({"raiding":{},"raids_out":{},"war_ledger":{},"wounded":[],"captured_holding":0})
	assert_dict(MilitaryCampaign.own_engagements).is_empty()
	# What the older save did hold is all there, and the war goes on.
	assert_dict(preload("res://scripts/town_ledger.gd").snapshot(civ_id,city_id)).is_equal(fled)
	assert_str(String((Hall.find(id).get("pending_command",{}) as Dictionary).get("ask",""))).is_equal("chase")
	_war_day()
	assert_array(MilitaryCampaign.validate_state()).is_empty()
