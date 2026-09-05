extends Node
const SLOT:="settings_roundtrip_qa"
func snapshot()->Dictionary:
	var places:Array=[]
	for p:Dictionary in GameState.player_settlements:
		places.append({"id":p.id,"auto":p.get("auto_manage",true),"focus":p.get("management_focus","")})
	return {"weights":GameState.research_allocations.duplicate(true),"targets":GameState.research_targets.duplicate(true),"places":places,"completed":GameState.known_discoveries.duplicate(),"selected":GameState.selected_player_settlement_id,"labor_auto":GameState.population_allocation_auto,"api":GameState.civic_api_enabled}
func _ready()->void:
	if "--write-settings" in OS.get_cmdline_user_args():
		GameState.reset_for_new_world(456789)
		GameState.settlement_site_committed=true
		GameState.settlement_completed.append("Hearth Circle")
		GameState.select_founding_focus("provision")
		GameState.settlement_name="Settings QA"
		GameState.civic_api_enabled=false
		DiscoverySystem.reset_for_new_world()
		DiscoverySystem.initialize()
		CivilizationSystem.reset_for_new_world(); CivilizationSystem.initialize()
		MilitaryCampaign.reset_for_new_world()
		PeopleDirection.choose("inquiry")
		SettlementModel._ensure_primary_settlement_record()
		var home_id:=String(GameState.player_settlements[0].id)
		GameState.player_settlements.append({"id":"settings_second","name":"Second QA","primary":false,"position":Vector2(10,0),"population_share":.15,"founded_day":0})
		assert(GovernmentPeopleSystem.set_settlement_focus(home_id,"research").ok)
		GovernmentPeopleSystem.restore_delegation("settings_second")
		DiscoverySystem.set_domain_research_priority("nutrition",7)
		DiscoverySystem.set_domain_research_priority("security",3)
		GameState.known_discoveries.append("food_drying")
		GameState.discovery_adoption["food_drying"]=1.0
		DiscoverySystem._refresh_active_investigations()
		GameState.population_allocation_auto=false
		GameState.selected_player_settlement_id="settings_second"
		var file:=FileAccess.open("res://artifacts/settings-expected.var",FileAccess.WRITE)
		file.store_string(var_to_str(snapshot()));file.close()
		assert(SaveSystem.save_game(SLOT).has("ok"))
		print("SETTINGS_WRITE_PASS")
	else:
		var file:=FileAccess.open("res://artifacts/settings-expected.var",FileAccess.READ)
		var expected:Dictionary=str_to_var(file.get_as_text());file.close()
		var loaded:=SaveSystem.load_game(SLOT)
		print("SETTINGS_LOAD_RESULT=",loaded)
		if loaded.has("error"):
			get_tree().quit(1);return
		assert(snapshot()==expected,"Fresh process load changed saved settings")
		var terrain:=preload("res://local_terrain.tscn").instantiate()
		add_child(terrain);terrain._set_game_speed(0)
		assert(snapshot()==expected,"Terrain startup changed saved settings")
		DiscoverySystem._refresh_active_investigations()
		assert(snapshot()==expected,"Completed research refresh changed preferences")
		DirAccess.remove_absolute(SaveSystem.slot_path(SLOT))
		print("SETTINGS_FRESH_LOAD_PASS: inquiry weights, completion, directed Research, second city Auto, selected city, labor mode, API preference")
	get_tree().quit()
