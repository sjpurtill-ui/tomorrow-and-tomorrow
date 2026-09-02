extends Node

const FORBIDDEN_PERSON_KEYS := [
	"citizen_registry", "citizen_ids", "soldier_ids", "wounded_ids",
	"scattered_ids", "captured_ids", "mother_id", "father_id", "household_id"
]

var failures:Array[String]=[]


func _ready()->void:
	call_deferred("_run")


func _run()->void:
	_reset_fixture(30_000_000)
	_test_numeric_mobilization_and_training()
	_test_numeric_captivity_and_return()
	_test_numeric_battle_losses()
	_test_save_round_trip_and_legacy_stripping()
	_test_billion_scale_state_shape()
	_test_competitive_campaign_orientation()
	if not failures.is_empty():
		for failure in failures:
			push_error("Military aggregate regression: "+failure)
		get_tree().quit(1)
		return
	print("MILITARY_CAMPAIGN_PASS aggregate_only=true population=%d formations=%d mobilized=%d" % [
		GameState.population_total,
		(MilitaryCampaign.home_army.get("formations",[]) as Array).size(),
		MilitaryCampaign._mobilized_count()
	])
	get_tree().quit(0)


func _reset_fixture(population:int)->void:
	GameState.reset_for_new_world(441122)
	GameState.initialize_population_model()
	GameState.ensure_population_total(population)
	GameState.population_health=0.82
	GameState.food_security=0.90
	GameState.housing_capacity=population
	GameState.simulation_metrics.merge({"cohesion":0.68,"security":0.62,"food_intake_ratio":1.0,"logistics":0.72},true)
	GameState.society_capacities.merge({"security":0.62,"logistics":0.72,"institutions":0.65},true)
	GameState.synchronize_population_allocations()
	MilitaryCampaign.reset_for_new_world()


func _test_numeric_mobilization_and_training()->void:
	var raised:Dictionary=MilitaryCampaign.raise_recruits(500_000)
	_expect(int(raised.get("raised",0))==500_000,"failed to raise a 500,000-person cohort")
	_expect(MilitaryCampaign.aggregate_recruits==500_000,"recruit reserve is not an authoritative count")
	var demobilized:Dictionary=MilitaryCampaign.demobilize(50_000)
	_expect(int(demobilized.get("released",0))==50_000,"numeric demobilization did not release the requested cohort")
	MilitaryCampaign.raise_recruits(50_000)
	var order:Dictionary=MilitaryCampaign.start_training("levy","improvised",300_000)
	_expect(int(order.get("accepted",0))==300_000,"training did not accept a 300,000-person cohort")
	_expect(int(MilitaryCampaign.training_queue[0].get("count",0))==300_000,"training order stores anything other than its numeric count")
	_expect(not MilitaryCampaign.training_queue[0].has("soldier_ids"),"training order contains individual soldier IDs")
	var training:Dictionary=MilitaryCampaign.training_queue[0].duplicate(true)
	MilitaryCampaign._complete_training(training)
	MilitaryCampaign.training_queue.clear()
	_expect(int(MilitaryCampaign.home_army.get("troops",0))==300_000,"completed training did not create the numeric field strength")
	_expect((MilitaryCampaign.home_army.get("formations",[]) as Array).size()==1,"one aggregate training order created more than one formation record")
	_expect(int(MilitaryCampaign.home_army.formations[0].count)==300_000,"formation count differs from field strength")
	_expect(MilitaryCampaign._mobilized_count()==500_000,"mobilized population was not conserved across recruit and field pools")
	var cancel_order:Dictionary=MilitaryCampaign.start_training("levy","improvised",50_000)
	var cancelled:Dictionary=MilitaryCampaign.cancel_training(int(cancel_order.get("id",-1)))
	_expect(int(cancelled.get("returned",0))==50_000,"cancelled cohort did not return to the numeric recruit reserve")
	_expect(MilitaryCampaign.validate_state().is_empty(),"numeric mobilization state failed validation: %s" % "; ".join(MilitaryCampaign.validate_state()))


func _test_numeric_captivity_and_return()->void:
	var before:=MilitaryCampaign._mobilized_count()
	MilitaryCampaign._mark_home_prisoners(25_000)
	_expect(int(MilitaryCampaign.home_army.get("captured_pool",0))==25_000,"captivity did not enter the aggregate captured pool")
	_expect(MilitaryCampaign._mobilized_count()==before,"capture moved population out of military conservation")
	var returned:Dictionary=MilitaryCampaign._process_home_captives_day(1.0)
	_expect(int(returned.get("returned",0))==25_000,"forced cohort return did not release the complete captured count")
	_expect(int(MilitaryCampaign.home_army.get("captured_pool",0))==0,"captured pool remained after complete return")
	_expect(MilitaryCampaign._mobilized_count()==before,"returned captives were not conserved into the recruit reserve")


func _test_numeric_battle_losses()->void:
	var population_before:=GameState.population_total
	var troops_before:=int(MilitaryCampaign.home_army.get("troops",0))
	var side:Dictionary=MilitaryCampaign.home_army.duplicate(true)
	var survivors:=troops_before-20_000
	side["remaining_troops"]=survivors
	side["troops"]=survivors
	side["wounded_pool"]=10_000
	side["scattered_pool"]=5_000
	side.formations[0]["count"]=survivors
	var rounds:Array=[{
		"attacker_casualties":{"killed":5_000,"wounded":10_000,"scattered":5_000},
		"attacker_cohort_equipment_losses":[0]
	}]
	MilitaryCampaign._apply_home_result(side,rounds,8181)
	_expect(GameState.population_total==population_before-5_000,"battle deaths did not reduce the aggregate population exactly once")
	_expect(int(MilitaryCampaign.home_army.get("troops",0))==survivors,"battle survivors were not stored as numeric field strength")
	_expect(int(MilitaryCampaign.home_army.get("wounded_pool",0))==10_000,"wounded population was not stored as a numeric pool")
	_expect(int(MilitaryCampaign.home_army.get("scattered_pool",0))==5_000,"scattered population was not stored as a numeric pool")
	_expect(MilitaryCampaign.validate_state().is_empty(),"post-battle aggregate state failed validation: %s" % "; ".join(MilitaryCampaign.validate_state()))


func _test_save_round_trip_and_legacy_stripping()->void:
	var saved:Dictionary=MilitaryCampaign.export_state()
	_expect(int(saved.get("version",0))==MilitaryCampaign.SAVE_VERSION,"military aggregate save version does not match the current bounded schema")
	_expect(not _has_forbidden_person_data(saved),"current military save contains person-level data")
	var expected_mobilized:=MilitaryCampaign._mobilized_count()
	MilitaryCampaign.aggregate_recruits=0
	var imported:Dictionary=MilitaryCampaign.import_state(saved)
	_expect(bool(imported.get("ok",false)),"aggregate save could not round-trip")
	_expect(MilitaryCampaign._mobilized_count()==expected_mobilized,"save round-trip changed mobilized population")
	var legacy:Dictionary=saved.duplicate(true)
	legacy["version"]=2
	legacy.home_army["soldier_ids"]=[1,2,3]
	legacy.home_army["wounded_ids"]=[4]
	if not (legacy.home_army.get("formations",[]) as Array).is_empty():
		legacy.home_army.formations[0]["soldier_ids"]=[1,2]
	var migrated:Dictionary=MilitaryCampaign.import_state(legacy)
	_expect(bool(migrated.get("ok",false)),"legacy aggregate migration failed")
	_expect(not _has_forbidden_person_data(MilitaryCampaign.export_state()),"legacy migration retained individual roster data")


func _test_billion_scale_state_shape()->void:
	_reset_fixture(1_000_000_000)
	var raised:Dictionary=MilitaryCampaign.raise_recruits(20_000_000)
	_expect(int(raised.get("raised",0))==20_000_000,"billion-scale recruitment was incorrectly capped by runtime record limits")
	var order:Dictionary=MilitaryCampaign.start_training("levy","improvised",10_000_000)
	_expect(int(order.get("accepted",0))==10_000_000,"billion-scale training was incorrectly capped by runtime record limits")
	var training:Dictionary=MilitaryCampaign.training_queue[0].duplicate(true)
	MilitaryCampaign._complete_training(training)
	MilitaryCampaign.training_queue.clear()
	var state:Dictionary=MilitaryCampaign.export_state()
	_expect((MilitaryCampaign.home_army.get("formations",[]) as Array).size()==1,"ten million personnel created per-person or per-unit formation records")
	_expect(int(MilitaryCampaign.home_army.formations[0].count)==10_000_000,"ten-million formation lost numeric personnel")
	_expect(not _has_forbidden_person_data(state),"billion-scale military state contains individual records")
	_expect(JSON.stringify(state).length()<50_000,"military save size scales with headcount")
	_expect(MilitaryCampaign.validate_state().is_empty(),"billion-scale military state failed validation: %s" % "; ".join(MilitaryCampaign.validate_state()))


func _test_competitive_campaign_orientation()->void:
	_reset_fixture(1_000_000)
	GameState.settlement_site_committed=true
	GameState.province_terrain="Mountains"
	CivilizationSystem.reset_for_new_world()
	MilitaryCampaign.raise_recruits(20_000)
	var order:Dictionary=MilitaryCampaign.start_training("levy","improvised",10_000)
	var training:Dictionary=MilitaryCampaign.training_queue[0].duplicate(true)
	MilitaryCampaign._complete_training(training)
	MilitaryCampaign.training_queue.clear()
	var civ_id:=String(CivilizationSystem.civilizations[0].id)
	var contacted:Dictionary=CivilizationSystem.civilizations[0]
	contacted.player_relation["contact_level"]=2
	contacted.player_relation["contact_intelligence"]=1.0
	contacted.player_relation["home_location_known"]=true
	contacted.player_relation["home_position"]={"x":1200.0,"z":900.0}
	CivilizationSystem.civilizations[0]=contacted
	var war:Dictionary=CivilizationSystem.conduct_player_action(civ_id,"declare_war",true)
	_expect(bool(war.get("ok",false)),"could not open the test war")
	var target:Dictionary=CivilizationSystem.campaign_targets(civ_id).filter(func(region:Dictionary)->bool: return bool(region.available))[0]
	var created:Dictionary=MilitaryCampaign.create_field_army(8_000)
	_expect(bool(created.get("ok",false)),"could not form an offensive field army")
	MilitaryCampaign.field_armies[0]["location_id"]=String(target.id)
	MilitaryCampaign.field_armies[0]["location_name"]=String(target.name)
	var offensive:Dictionary=MilitaryCampaign.launch_offensive(civ_id,String(target.id))
	_expect(not offensive.has("error"),"player offensive campaign could not begin")
	_expect(String(MilitaryCampaign.active_engagement.get("home_side",""))=="attacker","player force is not the attacker in its own offensive campaign")
	_expect(String((MilitaryCampaign.active_engagement.get("attacker",{}) as Dictionary).get("name",""))==String(MilitaryCampaign.field_armies[0].get("name","")),"offensive campaign assigned the rival to the player side")
	_expect(float(MilitaryCampaign.active_engagement.get("terrain_defense",0.0))>=1.0,"rival defensive ground uses an inverted terrain modifier")
	MilitaryCampaign.advance_engagement("retreat")
	var incident:={"id":"orientation_defense","source_civ_id":civ_id,"source_name":String(CivilizationSystem.civilizations[0].name),"strength":8000,"technology":0.30,"readiness":0.60,"aggression":0.60}
	MilitaryCampaign._create_civilization_threat(incident,"defensive")
	var defensive:Dictionary=MilitaryCampaign.begin_threat_engagement()
	_expect(not defensive.has("error"),"defensive rival campaign could not begin")
	_expect(String(MilitaryCampaign.active_engagement.get("home_side",""))=="defender","player force is not the defender against an incoming rival campaign")
	_expect(String((MilitaryCampaign.active_engagement.get("defender",{}) as Dictionary).get("name",""))==String(MilitaryCampaign.home_army.get("name","")),"defensive campaign assigned the rival to the home side")
	_expect(float(MilitaryCampaign.active_engagement.get("terrain_defense",0.0))>=1.35,"mountain defense does not benefit the defending player force")
	MilitaryCampaign.advance_engagement("retreat")
	_expect(MilitaryCampaign.validate_state().is_empty(),"competitive campaign orientation left invalid military state: %s" % "; ".join(MilitaryCampaign.validate_state()))


func _has_forbidden_person_data(value:Variant)->bool:
	if value is Dictionary:
		for key in value:
			if String(key) in FORBIDDEN_PERSON_KEYS:
				return true
			if _has_forbidden_person_data(value[key]):
				return true
	elif value is Array:
		for entry in value:
			if _has_forbidden_person_data(entry):
				return true
	return false


func _expect(condition:bool,message:String)->void:
	if not condition:
		failures.append(message)
