extends Node
var terrain:Node
var results:Array=[]
var label:="baseline"

func _ready()->void:
	AudioServer.set_bus_mute(0,true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--result-label="): label=argument.trim_prefix("--result-label=")
	GameState.reset_for_new_world(184271)
	PeopleDirection.reset_for_new_world()
	PeopleDirection.choose("makers")
	get_window().size=Vector2i(1280,720)
	get_window().content_scale_size=Vector2i(1920,1080)
	terrain=load("res://local_terrain.tscn").instantiate()
	add_child(terrain)
	terrain.game_speed=0
	var origin:Vector3=terrain.camera_target
	GameState.settlement_founded_at=origin
	for population in [120,1000000]:
		GameState.ensure_population_total(population)
		GameState.settlement_site_committed=true
		GameState.settlement_completed=["Hearth Circle"]
		SettlementModel.ensure_founded()
		terrain._refresh_settlement_network(true)
		for step in [{"size":180.0,"offset":0.0},{"size":1.2,"offset":0.0},{"size":40.0,"offset":8.0},{"size":0.6,"offset":0.0}]:
			terrain.camera_target=origin+Vector3(float(step.offset),0,0)
			terrain.camera.size=float(step.size)
			terrain.zoom_target_size=-1.0
			terrain._update_camera()
			terrain._update_world_streaming()
			var started:=Time.get_ticks_msec()
			var last_frame:=Time.get_ticks_usec()
			var frames:Array[float]=[]
			var first_ready:=-1
			var first_coverage:=-1
			var uncovered:=0
			for frame in 360:
				await get_tree().process_frame
				var now:=Time.get_ticks_usec()
				frames.append(float(now-last_frame)/1000.0); last_frame=now
				var desired:=clampf(float(step.size)*2.9/clampf(sin(absf(terrain.camera_pitch)),0.42,1.0),1.2,920.0)
				var center:Vector2=Vector2(terrain.camera_target.x,terrain.camera_target.z)
				var covered:=_view_is_covered()
				if not covered and not terrain.province_terrain_mesh.visible: uncovered+=1
				if covered and first_coverage<0: first_coverage=Time.get_ticks_msec()-started
				var bucket:=clampf(pow(1.5,ceil(log(maxf(0.9,desired))/log(1.5))),0.9,920.0)
				var installed_resolution:Variant=terrain.get("regional_patch_resolution")
				var full_detail:=installed_resolution==null or int(installed_resolution)>33
				if terrain.terrain_patch_job==null and covered and full_detail and is_equal_approx(terrain.regional_patch_span,bucket) and first_ready<0: first_ready=Time.get_ticks_msec()-started
				if frame==8 and population==120:
					await _capture("transition-"+str(step.size))
					last_frame=Time.get_ticks_usec() # Image readback/PNG encoding is not gameplay frame cost.
				if first_ready>=0 and frame>=30: break
			frames.sort()
			var result:={"population":population,"size":step.size,"frames":frames.size(),"ready_ms":first_ready,"elapsed_ms":Time.get_ticks_msec()-started,"frame_p50_ms":frames[frames.size()/2],"frame_p95_ms":frames[int(frames.size()*0.95)],"frame_max_ms":frames.back(),"uncovered_frames":uncovered,"slice_us":terrain.terrain_patch_last_slice_usec,"commit_us":terrain.terrain_patch_last_commit_usec}
			result["coverage_ms"]=first_coverage
			results.append(result); print("ZOOM_SAMPLE ",JSON.stringify(result))
			await _capture("settled-%d-%s" % [population,str(step.size)])
	var report:=FileAccess.open("res://artifacts/zoom-"+label+".json",FileAccess.WRITE)
	if report:
		report.store_string(JSON.stringify(results,"\t")); report.close()
	print("ZOOM_PROBE_DONE ",label)
	terrain.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _capture(suffix:String)->void:
	if DisplayServer.get_name()=="headless" or "--capture-zoom" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/zoom-"+label+"-"+suffix+".png")

func _view_is_covered()->bool:
	if terrain.regional_terrain_patch==null: return false
	var rect:=get_viewport().get_visible_rect()
	for corner in [rect.position,Vector2(rect.end.x,0),rect.end,Vector2(0,rect.end.y)]:
		var ray:Vector3=terrain.camera.project_ray_normal(corner)
		var start:Vector3=terrain.camera.project_ray_origin(corner)
		if absf(ray.y)<0.00001: return false
		var hit:Vector3=start+ray*((terrain.camera_target.y-start.y)/ray.y)
		if absf(hit.x-terrain.regional_patch_center.x)>terrain.regional_patch_span*0.5 or absf(hit.z-terrain.regional_patch_center.y)>terrain.regional_patch_span*0.5: return false
	return true
