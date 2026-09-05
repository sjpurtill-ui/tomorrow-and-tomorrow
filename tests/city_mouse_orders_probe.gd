extends Node
var terrain:Node
func click(point:Vector2,double_click:bool=false)->void:
	var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;get_viewport().push_input(motion,true)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;event.double_click=double_click and pressed
		get_viewport().push_input(event,true)
		await get_tree().process_frame
func _ready()->void:
	assert(SaveSystem.load_game("codex_city_input_20260905").has("ok"));GameState.civic_api_enabled=false
	terrain=preload("res://local_terrain.tscn").instantiate();get_tree().root.add_child.call_deferred(terrain);await get_tree().process_frame;get_tree().current_scene=terrain;terrain._set_game_speed(0)
	CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	get_window().size=Vector2i(1280,720);get_window().content_scale_size=Vector2i(1280,720)
	terrain._focus_known_city("civ_14_region_05")
	for frame in 100:await get_tree().process_frame
	var marker:Node3D=terrain.contact_encounter_markers["civ_14_region_05"]
	var roof:MeshInstance3D=marker.find_child("PitchedRoofs",true,false)
	var vertices:PackedVector3Array=roof.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var point:Vector3=roof.to_global((vertices[0]+vertices[1]+vertices[2])/3.0)
	var screen:Vector2=terrain.camera.unproject_position(point)
	print("CLICK_ROOF world=",point," screen=",screen," terrain_hit=",terrain._terrain_hit(screen))
	var army_marker:Node3D=terrain.player_field_army_markers["1"]
	await click(terrain.camera.unproject_position(army_marker.global_position))
	assert(terrain.selected_army_id==1)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/mouse-army-figures.png")
	print("FIGURES=",terrain.close_army_figures.keys())
	for figure:Node3D in terrain.close_army_figures.values():
		print("FIGURE ",figure.position," scale=",figure.scale," count=",figure.figure_count)
		for batch:MultiMeshInstance3D in figure.batches.values():
			for i in batch.multimesh.instance_count:print("FEET ",figure.to_global(batch.multimesh.get_instance_transform(i).origin))
	var wide_size:float=terrain.camera.size
	terrain.camera.size=.055;terrain._update_camera();terrain._update_scale_lod()
	for frame in 20:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/mouse-close-figures.png")
	terrain.camera.size=wide_size;terrain._update_camera();terrain._update_scale_lod()
	for frame in 10:await get_tree().process_frame
	await click(screen)
	for frame in 10:await get_tree().process_frame
	print("REPORT_OPEN=",is_instance_valid(CivilizationSystem.city_intelligence.screen_layer)," hovered=",get_viewport().gui_get_hovered_control())
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/mouse-report.png")
	assert(is_instance_valid(CivilizationSystem.city_intelligence.screen_layer))
	var report=CivilizationSystem.city_intelligence.screen_layer.get_child(0)
	assert(report.attack.visible and not report.attack.disabled)
	assert(report.attack.text=="ATTACK NOW")
	await click(report.attack.get_global_rect().get_center())
	for frame in 20:await get_tree().process_frame
	assert(not MilitaryCampaign.active_engagement.is_empty())
	assert(int(MilitaryCampaign.active_engagement.round)==0)
	assert(terrain.game_speed==0)
	assert(is_instance_valid(MilitaryCommandUI.battle_graphics))
	assert(CivilizationSystem.civilizations[CivilizationSystem._civilization_index("civ_14")].player_relation.at_war)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/mouse-battle-visible.png")
	print("REAL_INPUT_PASS: marker selected by mouse, single roof click, Attack Now button clicked, battle visible at round0 and paused, war initiated; no manual arrival registration")
	get_tree().quit()
