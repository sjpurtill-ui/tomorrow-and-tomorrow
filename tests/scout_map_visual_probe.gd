extends Node

func _ready()->void:
	GameState.reset_for_new_world(778899)
	CivilizationSystem.reset_for_new_world()
	var terrain:=preload("res://local_terrain.tscn").instantiate()
	add_child(terrain)
	await get_tree().process_frame
	await get_tree().process_frame
	terrain._set_game_speed(0.0)
	if is_instance_valid(terrain.founding_focus_panel): terrain.founding_focus_panel.queue_free()
	terrain.founding_focus_panel=null
	await get_tree().process_frame
	var center:Vector3=terrain.camera_target
	CivilizationSystem.scout_missions.clear()
	for i in 3:
		var route:Array=[]
		for j in 6:
			var offset:=Vector2(float(j)*11.0*(float(i)-1.0),-float(j)*12.0)
			route.append({"x":center.x+offset.x,"z":center.z+offset.y})
		CivilizationSystem.scout_missions.append({"mission_id":i+1,"route":route,"ordered_heading":["northwest","north","northeast"][i],"return_day":100+i*30})
	terrain._refresh_player_scout_route_markers()
	terrain.set_process(false)
	for zoom in [140.0,300.0]:
		terrain.camera.position=center+Vector3(0,zoom*0.75,zoom*0.7)
		terrain.camera.look_at(center+Vector3(0,0,-25))
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/scout-map-%d.png" % int(zoom))
		if zoom==140.0:
			var overlay=terrain.player_scout_route_markers["3"].find_child("ScoutRouteOverlay",true,false)
			var endpoint:Vector3=overlay.points[overlay.points.size()-1]
			get_viewport().warp_mouse(terrain.camera.unproject_position(endpoint))
			await get_tree().process_frame
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://artifacts/scout-map-hover.png")
			get_viewport().warp_mouse(Vector2(2,2))
	print("SCOUT_MAP_VISUAL_PROBE PASS")
	get_tree().quit()
