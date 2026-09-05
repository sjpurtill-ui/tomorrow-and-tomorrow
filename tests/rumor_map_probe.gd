extends Node
func _ready()->void:
	AudioServer.set_bus_mute(0,true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	GameState.reset_for_new_world(424242); GameState.civic_api_enabled=false
	var terrain:=preload("res://local_terrain.tscn").instantiate(); add_child(terrain)
	await get_tree().process_frame
	terrain._set_game_speed(0); CivilizationSystem.set_process(false)
	var net=CivilizationSystem.rumor_network
	for index in 24:
		var story:Dictionary=net.observation("witness%d" % index,"people%d" % index,"Travelers %d" % index,CivilizationSystem.player_world_origin+Vector2(index%6*180-450,index/6*190-250),90+index*8,0,"account exchanged on the road")
		story.heard_position=net.point(CivilizationSystem.player_world_origin+Vector2(-300,400)) if index%4!=0 else {}
		net.receive("player",story,20)
	var fog:Array=CivilizationSystem.revealed_areas.duplicate(true)
	net.open_map(terrain)
	await get_tree().process_frame
	var screen=net.screen_layer.get_child(0)
	for dimensions in [Vector2i(1280,900),Vector2i(800,600)]:
		get_window().size=dimensions; get_window().content_scale_size=dimensions
		await get_tree().process_frame; await get_tree().process_frame
		screen.plot.fit()
		for index in 25: screen._step(1)
		screen.plot.fit()
		assert(screen.plot.leads.size()==24)
		assert(get_viewport().get_visible_rect().encloses(screen.investigate.get_global_rect()))
		assert(screen.plot.size.x>700 and screen.plot.size.y>=160)
		screen.plot.zoom(1.25,screen.plot.size*.5)
		assert(CivilizationSystem.revealed_areas==fog)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/rumor-map-%d.png" % dimensions.x)
	var selected:String=screen.selected_id
	screen.investigate.pressed.emit()
	await get_tree().process_frame
	assert(terrain.pending_scout_target_id=="lead:"+selected)
	assert(is_instance_valid(terrain.scout_dispatch_panel))
	assert(CivilizationSystem.revealed_areas==fog)
	terrain._close_scout_dispatch_panel()
	print("RUMOR_MAP_PASS: 24 accounts, all reachable by navigation, source/area chart, two sizes, selection/zoom, actual scout review, fog unchanged")
	get_tree().quit()
