extends Node
## FUN AUDIT close-up captures (uncommitted). Isolated userdata; never saves.
var terrain:Node
func _ready()->void:
	if not OS.get_user_data_dir().ends_with("TomorrowFunAuditTests"):get_tree().quit(2);return
	get_window().size=Vector2i(1920,1080);get_window().content_scale_size=Vector2i(1920,1080)
	GameState.reset_for_new_world(424242)
	DiscoverySystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.civic_api_enabled=false
	terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	for i in 20:await get_tree().process_frame
	PeopleDirection.choose("makers")
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	for i in 5:await get_tree().process_frame
	terrain._start_settlement_here()
	for i in 5:await get_tree().process_frame
	if is_instance_valid(terrain.settlement_naming_panel):terrain.settlement_naming_panel.queue_free()
	var days:=int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size()>0 else 730
	terrain._set_game_speed(5)
	for i in days:
		if terrain.game_speed<=0.0:
			if terrain.military_attention_dialog and is_instance_valid(terrain.military_attention_dialog):terrain.military_attention_dialog.queue_free()
			preload("res://scripts/hud/simulation_pause.gd").owners.erase(terrain.get_instance_id())
			terrain._set_game_speed(5)
		terrain.advance_world_time(1.0)
		var dir:Node=get_tree().get_first_node_in_group("court_director")
		if dir and is_instance_valid(dir.modal):dir.modal.queue_free();preload("res://scripts/hud/simulation_pause.gd").owners.erase(terrain.get_instance_id())
		if i%10==0:await get_tree().process_frame
	terrain._set_game_speed(0)
	terrain.hud.close_dock()
	for c in terrain.hud.get_children():
		if c.get_class()=="CanvasLayer" and c!=terrain.hud:pass
	for z in [[2.8,-60.0,"a-10000ft"],[0.6,-50.0,"b-600m"],[0.2,-40.0,"c-200m"],[0.07,-32.0,"d-70m"]]:
		terrain.camera_target=GameState.settlement_founded_at
		terrain.camera.size=z[0];terrain.camera_pitch=deg_to_rad(z[1])
		terrain._update_camera();terrain._update_scale_lod()
		terrain.hud.close_dock()
		for i in 90:await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var p:=ProjectSettings.globalize_path("res://docs/fun_audit_captures/12-settlement-day%d-%s.png"%[days,z[2]])
		get_viewport().get_texture().get_image().save_png(p);print("FUN capture ",p)
	get_tree().quit(0)
