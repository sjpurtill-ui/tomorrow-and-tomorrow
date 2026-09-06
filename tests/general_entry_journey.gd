extends "res://tests/focused_journey_probe.gd"
func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_GeneralCampaign_Test"))
	GameState.reset_for_new_world(551188);CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();GameState.civic_api_enabled=false
	terrain=load("res://local_terrain.tscn").instantiate();get_tree().root.add_child.call_deferred(terrain)
	await frames();get_tree().current_scene=terrain;hud=terrain.hud
	terrain._set_game_speed(0)
	if is_instance_valid(terrain.founding_focus_panel):terrain.founding_focus_panel.queue_free();terrain.founding_focus_panel=null
	get_window().content_scale_size=Vector2i.ZERO;get_window().size=Vector2i(1280,800)
	GameState.settlement_name="Entry preservation world"
	assert(SaveSystem.save_game().has("ok"))
	var quicksave:=FileAccess.get_sha256(SaveSystem.slot_path("quicksave"))
	await click_control(hud.rail_buttons.military);await capture("general-entry")
	await click_label("PLAY GENERAL CAMPAIGN")
	await frames();terrain=get_tree().current_scene;hud=terrain.hud
	assert(GeneralCampaign.active and GeneralCampaign.state.rivals.size()==2)
	assert(SaveSystem.save_metadata("before_river_war").settlement_name=="Entry preservation world")
	assert(SaveSystem.save_game().has("ok"))
	assert(FileAccess.get_sha256(SaveSystem.slot_path("quicksave"))==quicksave)
	assert(SaveSystem.save_metadata("river_war").settlement_name=="Alderford")
	await capture("general-entry-launched")
	var ui:Control=GeneralCampaign.screen
	for button:Button in ui.find_children("*","Button",true,false):
		if button.text=="RETURN TO MY WORLD":await click_control(button);break
	await frames();terrain=get_tree().current_scene;hud=terrain.hud
	assert(not GeneralCampaign.active and GameState.settlement_name=="Entry preservation world")
	assert(FileAccess.get_sha256(SaveSystem.slot_path("quicksave"))==quicksave)
	print("GENERAL_ENTRY_JOURNEY_PASS actual Military entry, separate backup/save slot, unchanged quicksave, and return to original world")
	get_tree().quit()
