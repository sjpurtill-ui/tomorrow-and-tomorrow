extends Node
## Map art capture: one world, several zooms, one run. For before/after map
## art reviews at the settlement and regional views.
##   -- --out=<absolute dir> [--prefix=name] [--sizes=6,40,160,900] [--saved] [--hide-ui] [--river]
## `--saved` loads the quicksave from this run's user dir: point the project at
## a private custom user dir first (a local, uncommitted override.cfg), never at
## the player's saves. Windowed only (a headless run has no image); run it
## through tools/run_isolated_gpu_probe.ps1 so no window reaches the desktop.
var terrain:Node

func _ready()->void:
	AudioServer.set_bus_mute(0,true)
	var out_dir:="user://map_art_capture"
	var prefix:="map"
	var sizes:Array[float]=[6.0,40.0,160.0,900.0]
	var args:=OS.get_cmdline_user_args()
	for argument in args:
		if argument.begins_with("--out="):out_dir=argument.trim_prefix("--out=")
		elif argument.begins_with("--prefix="):prefix=argument.trim_prefix("--prefix=")
		elif argument.begins_with("--sizes="):
			sizes.clear()
			for part in argument.trim_prefix("--sizes=").split(","):sizes.append(float(part))
	if "--saved" in args:
		var restored:Dictionary=SaveSystem.load_game()
		if restored.has("error"):
			push_error("MAP_ART_CAPTURE: save could not be loaded: "+String(restored.error))
			get_tree().quit(2)
			return
	else:
		GameState.reset_for_new_world(184271)
		GameState.select_founding_focus("provision")
		PeopleDirection.choose("makers")
	terrain=load("res://local_terrain.tscn").instantiate()
	add_child(terrain)
	await get_tree().process_frame
	terrain.game_speed=0
	if not GameState.settlement_site_committed or "Hearth Circle" not in GameState.settlement_completed:
		GameState.settlement_site_committed=true
		GameState.settlement_founded_at=terrain.settler_marker.position
		if "Hearth Circle" not in GameState.settlement_completed:GameState.settlement_completed.append("Hearth Circle")
		SettlementModel.ensure_founded()
	# Let the per-seed macro rasters (the shared coast mask) land, bounded.
	var deadline:=Time.get_ticks_msec()+120000
	while not terrain.macro_render.ready() and Time.get_ticks_msec()<deadline:
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var lod=preload("res://scripts/terrain_lod.gd")
	var target:Vector3=GameState.settlement_founded_at
	if "--river" in args:
		# Look at the world river instead (charted here for this capture only).
		var river_z:=clampf(target.z,-600.0,600.0)
		target=Vector3(terrain._world_river_x(river_z),0.0,river_z)
		target.y=terrain._height_at(target.x,target.z)
		CivilizationSystem._add_revealed_area(Vector2(target.x,target.z),260.0,"capture")
	for size in sizes:
		terrain.camera.size=size
		terrain.zoom_target_size=-1.0
		terrain.camera_target=target
		terrain._update_camera()
		var frames:=0
		var settle_deadline:=Time.get_ticks_msec()+30000
		while Time.get_ticks_msec()<settle_deadline and (frames<45 or terrain.terrain_patch_job!=null or terrain.regional_patch_resolution!=lod.resolution_for(terrain.regional_patch_span)):
			await get_tree().process_frame
			frames+=1
		if "--hide-ui" in args:
			for layer in get_tree().root.find_children("*","CanvasLayer",true,false):(layer as CanvasLayer).visible=false
		for i in 6:await get_tree().process_frame
		RenderingServer.force_sync()
		RenderingServer.force_draw(true,0.0)
		var path:=out_dir.path_join("%s_z%d.png" % [prefix,int(size)])
		var image:=get_viewport().get_texture().get_image()
		if image:image.save_png(ProjectSettings.globalize_path(path) if path.begins_with("user://") or path.begins_with("res://") else path)
		print("MAP_ART_CAPTURE: ",path," frames=",frames," patch=",terrain.regional_patch_span,"/",terrain.regional_patch_resolution)
	get_tree().quit(0)
