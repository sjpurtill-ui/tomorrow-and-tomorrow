extends Node
func _ready()->void:
	GameState.reset_for_new_world(864209)
	GameState.select_founding_focus("provision")
	var terrain:=preload("res://local_terrain.tscn").instantiate()
	add_child(terrain)
	await get_tree().process_frame
	terrain._set_game_speed(0.0)
	terrain.set_process(false)
	CivilizationSystem.set_process(false)
	MilitaryCampaign.set_process(false)
	terrain.camera_target=terrain.settler_marker.position
	terrain.camera.size=5.0
	terrain._update_camera()
	var pointer:=get_viewport().get_visible_rect().size*0.5
	var initial:Dictionary=terrain._terrain_hit(pointer)
	terrain._queue_camera_zoom(pointer,-1.0)
	terrain._queue_camera_zoom(pointer,-1.0)
	var target:=5.0/(1.4*1.4)
	assert(absf(terrain.zoom_target_size-target)<0.0001,"Wheel inputs must accumulate")
	assert(terrain.camera.size==5.0,"Input itself must not jump the camera")
	var previous:float=terrain.camera.size
	for frame in 50:
		terrain._process_smooth_camera(1.0/60.0)
		assert(terrain.camera.size<=previous and terrain.camera.size>=target-0.0001,"Smooth zoom must never overshoot")
		previous=terrain.camera.size
	assert(absf(terrain.camera.size-target)<0.0001)
	var final_hit:Dictionary=terrain._terrain_hit(pointer)
	assert((initial.position as Vector3).distance_to(final_hit.position)<0.03,"Zoom must stay anchored")
	for yaw in [-2.8,-0.5,0.0,2.9]:
		terrain.camera_yaw=yaw
		terrain._reset_camera_north()
		for frame in 50: terrain._process_smooth_camera(1.0/60.0)
		assert(terrain._north_screen_arrow()=="↑","NORTH must point up after reset")
	assert(terrain.hud.compass_label is Button)
	terrain._queue_camera_zoom(pointer,-1.0,true)
	assert(terrain.zoom_target_size<terrain.camera.size/1.4,"Shift wheel must be faster")
	terrain.zoom_target_size=-1.0
	var old_patch:Node=terrain.regional_terrain_patch
	for frame in 2000:
		terrain._update_world_streaming()
		terrain._advance_terrain_patch()
		if terrain.terrain_patch_job==null:
			terrain._update_world_streaming()
			if terrain.terrain_patch_job==null: break
	assert(terrain.regional_terrain_patch!=null)
	var live_patch:Node=terrain.regional_terrain_patch
	terrain._rebuild_regional_terrain_patch(Vector2(terrain.camera_target.x+3,terrain.camera_target.z),4.0)
	assert(terrain.regional_terrain_patch==live_patch,"Visible patch must survive while replacement builds")
	assert(terrain.terrain_patch_job!=null)
	if "--profile" in OS.get_cmdline_user_args():
		terrain.set_process(true)
		for frame in 20: await get_tree().process_frame
		var times:Array[float]=[]
		var last:=Time.get_ticks_usec()
		for frame in 120:
			if frame%12==0: terrain._queue_camera_zoom(pointer,-1.0 if frame<60 else 1.0)
			await get_tree().process_frame
			var now:=Time.get_ticks_usec()
			times.append(float(now-last)/1000.0)
			last=now
		times.sort()
		print("NAVIGATION_FRAME_PROFILE median_ms=",times[60]," p95_ms=",times[114]," max_ms=",times[119])
		terrain.set_process(false)
	print("CAMERA_NAVIGATION_PASS: smooth cumulative zoom, no overshoot, pointer anchor, four north resets, fast zoom, retained terrain. Last maximum slice ",terrain.terrain_patch_last_slice_usec,"us; commit ",terrain.terrain_patch_last_commit_usec,"us")
	get_tree().quit()
