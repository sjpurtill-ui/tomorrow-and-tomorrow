extends Node
const TERRAIN_SCENE:=preload("res://local_terrain.tscn")
var failures:Array[String]=[]
func _ready()->void:
	GameState.reset_for_new_world(551188)
	DiscoverySystem.reset_for_new_world()
	ProgressionSystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	GameState.select_founding_focus("provision")
	var terrain:=TERRAIN_SCENE.instantiate()
	add_child(terrain)
	await get_tree().process_frame
	await get_tree().process_frame
	if terrain.founding_focus_panel and is_instance_valid(terrain.founding_focus_panel): terrain.founding_focus_panel.queue_free()
	terrain.founding_focus_panel=null
	terrain._set_game_speed(0.0)
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_site_committed=true
	GameState.settlement_name="First City"
	SettlementModel.ensure_founded()
	GameState.player_settlements.append({"id":"dawngate","name":"Dawngate","primary":false,"position":Vector2(10,0),"population_share":0.25,"founded_day":0})
	GovernmentPeopleSystem.initialize()
	GameState.resource_stockpiles["Timber"]=777.0
	var hud:Control=terrain.hud
	hud.refresh()
	_expect(hud.city_selector.item_count==2,"City dropdown must list both cities")
	var primary_stores:=GameState.resource_stockpiles.duplicate(true)
	terrain._select_city("dawngate")
	await get_tree().create_timer(0.8).timeout
	_expect(GameState.selected_player_settlement_id=="dawngate","Dropdown selection must select Dawngate")
	_expect(Vector2(terrain.camera_target.x,terrain.camera_target.z).distance_to(Vector2(10,0))<0.1,"Selection must move camera to Dawngate")
	_expect(GameState.resource_stockpiles==primary_stores,"City selection must not alter first city stores")
	var economy:RefCounted=load("res://scripts/hud/content/dock_content_economy.gd").new(terrain,hud)
	var economy_data:Dictionary=economy.tab(1)
	_expect("Dawngate" in String(economy.meta().title),"Economy must name selected city")
	_expect(not "777" in str(economy_data.blocks),"Dawngate materials must not show first city timber")
	_expect("INTERCITY TRADE" in str(economy_data.blocks),"Economy must expose deliveries")
	terrain._process_other_city_resources()
	_expect(GameState.resource_stockpiles==primary_stores,"Dawngate daily production must not spend first city stores")
	terrain.game_speed=5.0
	terrain.last_discovery_day=int(GameState.elapsed_days)
	MilitaryCampaign.threat_changed.emit({"id":"probe_raid","source_name":"Reedbank Confederacy","target_region_name":"Dawngate","estimated_strength":3,"deadline_day":int(GameState.elapsed_days)+7})
	_expect(terrain.game_speed==0.0,"Incoming attack must pause game")
	await get_tree().process_frame
	_expect(terrain.military_attention_dialog!=null and terrain.military_attention_dialog.visible,"Attack dialog must be visible")
	_expect("Dawngate" in terrain.military_attention_dialog.dialog_text,"Attack must identify location")
	_expect(terrain.military_attention_dialog.ok_button_text=="OPEN WAR PLANNING","Attack must offer direct access to planning")
	terrain.military_attention_dialog.hide()
	var battle:={"seed":9988,"outcome":"defender_victory","home_side":"defender","target_region_name":"Dawngate","threat":{"source_name":"Reedbank Confederacy"},"defender":{"initial_troops":20,"remaining_troops":14,"morale":0.48}}
	MilitaryCampaign._record_council_battle(battle)
	terrain.game_speed=5.0
	MilitaryCampaign.battle_resolved.emit(battle)
	await get_tree().process_frame
	_expect(terrain.game_speed==0.0,"Battle result must pause game")
	_expect("14 remaining" in terrain.military_attention_dialog.dialog_text,"Battle dialog must expose troop result")
	var content:RefCounted=load("res://scripts/hud/content/dock_content_civilization.gd").new(terrain,hud)
	var found:=false
	for sub in 3:
		if "MILITARY ALERTS & BATTLE REPORTS" in str(content.tab(sub)): found=true
	_expect(found,"Civics must surface full battle reports outside routine reports")
	economy_data.clear()
	economy=null
	content=null
	terrain.queue_free()
	await get_tree().process_frame
	if failures.is_empty(): print("CIVIC_CITY_RUNTIME_PROBE_PASS")
	else:
		for failure in failures: push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
func _expect(condition:bool,message:String)->void:
	if not condition: failures.append(message)
