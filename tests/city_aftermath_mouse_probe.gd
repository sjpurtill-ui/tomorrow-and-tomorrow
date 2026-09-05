extends Node
func click_control(control:Control)->void:
	var viewport:=get_viewport();var point:=control.get_global_rect().get_center()
	if control.get_window()!=get_window():point+=Vector2(control.get_window().position)
	var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;viewport.push_input(motion,true)
	await get_tree().process_frame
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;viewport.push_input(event,true);await get_tree().process_frame
func _ready()->void:
	assert(SaveSystem.load_game().has("ok"));GameState.civic_api_enabled=false
	var before:=GameState.population_total
	get_window().size=Vector2i(1280,720);get_window().content_scale_size=Vector2i(1280,720);get_window().gui_embed_subwindows=true
	var terrain:=preload("res://local_terrain.tscn").instantiate();get_tree().root.add_child.call_deferred(terrain);await get_tree().process_frame;get_tree().current_scene=terrain;terrain._set_game_speed(0)
	CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	for frame in 10:await get_tree().process_frame
	assert(terrain.military_attention_dialog.visible)
	await click_control(terrain.military_attention_dialog.get_cancel_button())
	assert(not terrain.military_attention_dialog.visible)
	terrain._focus_known_city("civ_14_region_05");terrain.camera.size=.065;terrain._update_camera();terrain._update_scale_lod()
	for frame in 100:await get_tree().process_frame
	assert(not terrain.player_field_army_markers.has("1") or not terrain.player_field_army_markers["1"].visible)
	var figures:=0
	for visual:Node3D in terrain.close_army_figures.values():figures+=visual.figure_count
	assert(figures==4)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/current-garrison-visible.png")
	CivilizationSystem.city_intelligence.open("civ_14_region_05")
	for frame in 12:await get_tree().process_frame
	var report=CivilizationSystem.city_intelligence.screen_layer.get_child(0)
	assert(report.garrison_button.visible and report.aftermath_button.visible)
	assert(not report.attack.visible)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/current-garrison-report.png")
	await click_control(report.aftermath_button)
	for frame in 12:await get_tree().process_frame
	assert(not is_instance_valid(CivilizationSystem.city_intelligence.screen_layer))
	assert(terrain.hud.active_section=="military" and terrain.hud.dock.visible)
	assert(not MilitaryCampaign.pending_aftermath.is_empty())
	assert(GameState.population_total==before)
	assert(MilitaryCampaign.occupation_active_personnel()==4)
	assert(MilitaryCampaign.field_armies[0].scattered_pool==2)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/current-aftermath-open.png")
	terrain.hud.open_detail(preload("res://scripts/hud/content/dock_detail_population_ledger.gd").new(terrain,terrain.hud))
	for frame in 15:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/current-death-ledger.png")
	print("CURRENT_AFTERMATH_INPUT_PASS 0 active marker removed;4 garrison figures;2 scattered preserved; report aftermath clicked; no resolution or population change")
	get_tree().quit()
