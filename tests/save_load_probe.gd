extends Node
## Probes whole-game persistence: save a mutated world, scramble everything
## with a different seed, load, and verify the world (state layer AND a fresh
## terrain scene built from it) comes back.

const TERRAIN_SCENE:=preload("res://local_terrain.tscn")
const SLOT:="save_load_probe"
var failures:Array[String]=[]


func _ready()->void:
	_reset_all(424242)
	GameState.select_founding_focus("provision")
	var terrain:=TERRAIN_SCENE.instantiate()
	add_child(terrain)
	await get_tree().process_frame
	await get_tree().process_frame
	if terrain.founding_focus_panel and is_instance_valid(terrain.founding_focus_panel): terrain.founding_focus_panel.queue_free()
	terrain.founding_focus_panel=null
	await get_tree().process_frame

	# Mutate a spread of state across systems.
	GameState.elapsed_days=140.0
	GameState.register_directive_population_deaths(1,"mass_repression","One counted execution.",{"exact_count":1,"role":"worker","age_cohorts":["youth","early_adults","established_adults","mature_adults"],"source_order_id":"saved_counted_decree","label":"exactly 1 worker"})
	GameState.civic_always_use_ai=true
	GameState.civic_api_enabled=false
	GameState.register_population_arrivals(30,"probe arrivals")
	if "food_drying" not in GameState.known_discoveries: GameState.known_discoveries.append("food_drying")
	GameState.resource_stockpiles["Food"]=333.0
	CivilizationSystem.landmarks.append({"id":"landmark_probe","name":"The Probe Stones","kind":"plain","feature_id":"sun_stone_row","myth":"Probe myth.","position":{"x":10.0,"z":10.0},"discovered_day":100,"description":"Probe."})
	var civic_order:={
		"id":"order_persistence_probe","type":"pronouncement","settlement_id":"player_settlement_1",
		"leader_person_id":77,"addressed_to":"Mara Vale","leader_title":"Hearth Speaker",
		"parameters":{"text":"Expand the watch.","interpretation":{"policies":[{"id":"expanded_watch","action":"enact","applied":true,"days":180.0,"magnitude":0.18,"implementation_rate":0.62,"office_execution_factor":0.70}]}},
	}
	GameState.sovereign_orders.push_front(civic_order)
	GameState.civic_dialogues["player_settlement_1"]=[{"speaker":"player","text":"Expand the watch.","status":"submitted"},{"speaker":"leader","speaker_name":"Mara Vale","text":"This is underway.","status":"accepted"}]
	var civic_followup:=CivicImplementationSystem.schedule_order(civic_order,140)
	var saved_civic_due_day:=int(civic_followup.get("due_day",0))
	# The probe begins before settlement founding, so add one canonical public
	# person solely to prove that a bounded personal memory survives the reflected
	# system save path.
	var memory_person_id:=909
	GovernmentPeopleSystem.people.append(GovernmentPeopleSystem._generate_person(memory_person_id))
	GovernmentPeopleSystem.record_person_memory(memory_person_id,"The settlement remembers the probe watch.","civic_outcome",0.72,{"order_id":"memory_save_probe","outcome":"success","policy_ids":["expanded_watch"],"settlement_id":"player_settlement_1"})
	# A save made while a provider request is in flight must never serialize its
	# authorization header. The matching civic order is the durable state.
	PronouncementInterpreter._requests["secret_probe"]={"headers":PackedStringArray(["Authorization: Bearer NEVER_SAVE_THIS"])}
	var saved_population:=GameState.population_total
	var saved_seed:=GameState.world_seed

	GameState.player_settlements.append({"id":"city_save_probe","name":"Dawngate","primary":false,"position":Vector2(10,0),"population_share":0.15,"founded_day":10})
	SettlementModel.with_city_resources("city_save_probe",func()->void: GameState.resource_stockpiles["Timber"]=17.0)
	GameState.selected_player_settlement_id="city_save_probe"
	GameState.city_trade_shipments.append({"id":9001,"source_id":"origin","destination_id":"city_save_probe","resource":"Timber","quantity":8.0,"arrival_day":160.0,"travel_days":20.0})
	var save_result:Dictionary=SaveSystem.save_game(SLOT)
	_expect(bool(save_result.get("ok",false)),"save failed: %s" % save_result.get("error",""))
	_expect(not SaveSystem.save_metadata(SLOT).is_empty(),"saved metadata unreadable")
	var raw_save:=FileAccess.get_file_as_string(SaveSystem.slot_path(SLOT))
	_expect("NEVER_SAVE_THIS" not in raw_save,"save serialized an API authorization header")

	# Scramble the world completely.
	terrain.queue_free()
	await get_tree().process_frame
	_reset_all(999)
	GameState.select_founding_focus("industry")
	_expect(GameState.world_seed==999,"scramble reset did not take")
	_expect("food_drying" not in GameState.known_discoveries,"scramble left old knowledge behind")

	# Load and verify the state layer.
	var load_result:Dictionary=SaveSystem.load_game(SLOT)
	_expect(bool(load_result.get("ok",false)),"load failed: %s" % load_result.get("error",""))
	_expect(GameState.world_seed==saved_seed,"world seed not restored (%d)" % GameState.world_seed)
	_expect(absf(GameState.elapsed_days-140.0)<1.0,"elapsed days not restored (%.1f)" % GameState.elapsed_days)
	_expect(GameState.population_total==saved_population,"population not restored (%d vs %d)" % [GameState.population_total,saved_population])
	_expect(GameState.demographic_ledger.any(func(record:Dictionary)->bool: return String(record.get("source_order_id",""))=="saved_counted_decree" and int(record.get("count",0))==1),"counted execution death record was not restored")
	_expect(GameState.civic_always_use_ai,"civic Always Ask AI routing preference not restored")
	_expect(not GameState.civic_api_enabled,"civic API master switch not restored")
	_expect("food_drying" in GameState.known_discoveries,"known discovery not restored")
	_expect(absf(float(GameState.resource_stockpiles.get("Food",0.0))-333.0)<0.01,"food stockpile not restored")
	var landmark_found:=false
	for landmark in CivilizationSystem.landmarks:
		if String((landmark as Dictionary).get("name",""))=="The Probe Stones": landmark_found=true
	_expect(landmark_found,"landmark not restored")
	_expect(GameState.founding_focus=="provision","founding focus not restored (%s)" % GameState.founding_focus)
	var restored_civic_order:Dictionary={}
	for order_variant in GameState.sovereign_orders:
		if String((order_variant as Dictionary).get("id",""))=="order_persistence_probe": restored_civic_order=order_variant; break
	_expect(not restored_civic_order.is_empty(),"civic order not restored")
	_expect(int(restored_civic_order.get("implementation_followup",{}).get("due_day",0))==saved_civic_due_day,"directive outcome deadline not restored")
	_expect((GameState.civic_dialogues.get("player_settlement_1",[]) as Array).size()==2,"civic conversation not restored")
	_expect(PronouncementInterpreter.pending_request_count()==0,"transient provider request was incorrectly restored")
	var restored_person:=GovernmentPeopleSystem.person_snapshot(memory_person_id)
	_expect((restored_person.get("memories",[]) as Array).any(func(memory:Dictionary)->bool: return String(memory.get("order_id",""))=="memory_save_probe"),"leader's civic memory not restored")

	_expect(GameState.selected_player_settlement_id=="city_save_probe","selected city not restored")
	_expect(float(SettlementModel.city_resource_snapshot("city_save_probe").stores.get("Timber",0.0))==17.0,"local city stores not restored")
	_expect(GameState.city_trade_shipments.size()==1,"in-transit city cargo not restored")
	_expect(GameState.resource_settlement_id=="","transient resource context must not survive load")
	# A fresh terrain scene must rebuild cleanly from the restored state.
	var reloaded:=TERRAIN_SCENE.instantiate()
	add_child(reloaded)
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(reloaded.hud!=null,"terrain rebuilt from loaded state has no HUD")
	_expect(absf(GameState.elapsed_days-140.0)<2.0,"terrain rebuild disturbed elapsed days (%.1f)" % GameState.elapsed_days)

	DirAccess.remove_absolute(SaveSystem.slot_path(SLOT))
	_finish()


func _reset_all(seed_value:int)->void:
	GameState.reset_for_new_world(seed_value)
	DiscoverySystem.reset_for_new_world()
	ProgressionSystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	EconomySystem.reset_for_new_world()
	SettlementModel.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	WorldFacts.reset_for_new_world()
	PronouncementInterpreter.reset_for_new_world()


func _expect(condition:bool,message:String)->void:
	if not condition:
		failures.append(message)
		push_error("SAVE_LOAD_PROBE %s" % message)


func _finish()->void:
	if failures.is_empty():
		print("SAVE_LOAD_PROBE PASS")
		get_tree().quit(0)
	else:
		print("SAVE_LOAD_PROBE FAIL (%d)" % failures.size())
		get_tree().quit(1)
