extends Node
## Map motion capture: short frame sequences for reviewing animation.
##   -- --out=<absolute dir> [--prefix=name] [--size=2.8] [--frames=10] [--every=6]
##      [--saved] [--weather=rain|snow|clear|cloud] [--pan] [--zoom-to=<km>] [--speed=1]
##      [--measure=<frames>] [--hide-ui] [--great-works] [--reveal]
## Writes <prefix>_f00.png ... and prints MAP_MOTION_CAPTURE lines. `--pan`
## releases a drag and records the coast; `--zoom-to` records a distance glide.
## `--measure` records CPU frame times while panning (p50/p95) and idle.
## `--saved` loads the quicksave from this run's user dir: point the project at
## a private custom user dir first (a local, uncommitted override.cfg), never at
## the player's saves. Windowed only; run through tools/run_isolated_gpu_probe.ps1.
const Ambience:=preload("res://scripts/map_ambience.gd")
var terrain:Node

func _ready()->void:
	AudioServer.set_bus_mute(0,true)
	var out_dir:="user://map_motion_capture"
	var prefix:="motion"
	var size:=2.8
	var frames:=10
	var every:=6
	var speed:=1.0
	var zoom_to:=-1.0
	var measure:=0
	var weather:=""
	var args:=OS.get_cmdline_user_args()
	for argument in args:
		if argument.begins_with("--out="):out_dir=argument.trim_prefix("--out=")
		elif argument.begins_with("--prefix="):prefix=argument.trim_prefix("--prefix=")
		elif argument.begins_with("--size="):size=float(argument.trim_prefix("--size="))
		elif argument.begins_with("--frames="):frames=int(argument.trim_prefix("--frames="))
		elif argument.begins_with("--every="):every=int(argument.trim_prefix("--every="))
		elif argument.begins_with("--speed="):speed=float(argument.trim_prefix("--speed="))
		elif argument.begins_with("--zoom-to="):zoom_to=float(argument.trim_prefix("--zoom-to="))
		elif argument.begins_with("--measure="):measure=int(argument.trim_prefix("--measure="))
		elif argument.begins_with("--weather="):weather=argument.trim_prefix("--weather=")
	if "--no-ambience" in args:Ambience.enabled=false
	if "--saved" in args:
		var restored:Dictionary=SaveSystem.load_game()
		if restored.has("error"):
			push_error("MAP_MOTION_CAPTURE: save could not be loaded: "+String(restored.error))
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
	if GameState.population_total<60:
		GameState.population_total=120
		GameState.population_allocations={"Food":34,"Survey":6,"Extraction":10,"Construction":10,"Crafting":6,"Logistics":6,"Knowledge":4,"Administration":2,"Defense":4}
		GameState.simulation_metrics["food_sources"]=[{"name":"Wild gathering","produced":40.0},{"name":"Hunting","produced":30.0},{"name":"Fishing","produced":30.0}]
	var deadline:=Time.get_ticks_msec()+120000
	while not terrain.macro_render.ready() and Time.get_ticks_msec()<deadline:
		await get_tree().process_frame
	preload("res://scripts/living_map.gd").refresh(terrain)
	var ambience:Node=terrain.get_node_or_null("MapAmbience")
	if ambience and weather!="":
		var forced:Dictionary=ambience.weather.duplicate()
		match weather:
			"rain":forced.merge({"cloud":0.75,"rain":0.9,"snow":0.0,"wind":0.7},true)
			"snow":forced.merge({"cloud":0.7,"rain":0.0,"snow":0.9,"wind":0.35},true)
			"cloud":forced.merge({"cloud":0.55,"rain":0.0,"snow":0.0,"wind":0.6},true)
			_:forced.merge({"cloud":0.0,"rain":0.0,"snow":0.0},true)
		Ambience.forced_weather=forced
		ambience.weather=forced
		ambience.weather_day=float(GameState.elapsed_days)
		ambience.cloud=float(forced.cloud);ambience.rain=float(forced.rain);ambience.snow=float(forced.snow)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var lod=preload("res://scripts/terrain_lod.gd")
	var target:Vector3=GameState.settlement_founded_at
	terrain.camera.size=size
	terrain.zoom_target_size=-1.0
	terrain.camera_target=target
	terrain._update_camera()
	var settle:=0
	var settle_deadline:=Time.get_ticks_msec()+30000
	while Time.get_ticks_msec()<settle_deadline and (settle<45 or terrain.terrain_patch_job!=null or terrain.regional_patch_resolution!=lod.resolution_for(terrain.regional_patch_span)):
		await get_tree().process_frame
		settle+=1
	if "--hide-ui" in args:
		for layer in get_tree().root.find_children("*","CanvasLayer",true,false):(layer as CanvasLayer).visible=false
	if measure>0:
		# Paused, as the pan benchmark has always been measured; warm up first.
		for i in 90:await get_tree().process_frame
		await _measure(measure)
	terrain._set_game_speed(speed)
	if "--great-works" in args:
		var helper:Node=load("res://tests/map_art_capture.gd").new()
		helper.set("terrain",terrain)
		helper.call("_seed_great_works",target)
		helper.free()
		terrain._refresh_undertaking_visuals(true)
		if ambience:ambience.day_tick()
		for work in terrain.undertaking_visual_root.get_children():
			if work.has_meta("map_mark") and String(work.get_meta("map_mark").get("state",""))=="building":
				terrain.camera_target=work.position;terrain._update_camera();break
	if "--reveal" in args:
		# Chart new ground just beyond the known edge and watch it ink in.
		var toward:Vector3=terrain._camera_ground_screen_right()
		var point:Vector2=Vector2(target.x,target.z)+Vector2(toward.x,toward.z)*float(terrain.camera.size)*0.62
		CivilizationSystem._add_revealed_area(point,float(terrain.camera.size)*0.2,"capture")
	if "--pan" in args:
		terrain.pan_coast_velocity=preload("res://scripts/map_motion.gd").release_velocity(terrain._camera_ground_screen_right()*size*3.0,terrain.camera.size)
	if zoom_to>0.0:
		terrain.zoom_target_size=zoom_to
		terrain.zoom_pointer=get_viewport().get_visible_rect().size*0.5
	for i in frames:
		for k in every:await get_tree().process_frame
		RenderingServer.force_sync()
		var path:=out_dir.path_join("%s_f%02d.png" % [prefix,i])
		var image:=get_viewport().get_texture().get_image()
		if image:image.save_png(ProjectSettings.globalize_path(path) if path.begins_with("user://") else path)
		print("MAP_MOTION_CAPTURE: ",path," size=",snappedf(terrain.camera.size,0.001)," coast=",snappedf(terrain.pan_coast_velocity.length(),0.0001))
	if ambience:print("MAP_MOTION_CAPTURE: ambience ",JSON.stringify(ambience.ambience_report()))
	var living:Node=terrain.get_node_or_null("LivingMap")
	if living:print("MAP_MOTION_CAPTURE: living frame_usec=",living.activity_report().get("frame_usec"))
	get_tree().quit(0)

## CPU time of the map's own frame work (terrain, plus the living map and
## ambience layers when idle) while the camera pans steadily, then idle.
func _measure(count:int)->void:
	var pan:Array[float]=[]
	var idle:Array[float]=[]
	var right:Vector3=terrain._camera_ground_screen_right()
	for i in count:
		terrain._set_camera_target(terrain.camera_target+right*terrain.camera.size*0.004)
		var began:=Time.get_ticks_usec()
		terrain._process(1.0/60.0)
		var ambience_pan:Node=terrain.get_node_or_null("MapAmbience")
		if ambience_pan:ambience_pan._process(1.0/60.0)
		var living_pan:Node=terrain.get_node_or_null("LivingMap")
		if living_pan:living_pan._process(1.0/60.0)
		pan.append(float(Time.get_ticks_usec()-began)/1000.0)
		await get_tree().process_frame
	for i in count:
		var began:=Time.get_ticks_usec()
		terrain._process(1.0/60.0)
		var ambience_node:Node=terrain.get_node_or_null("MapAmbience")
		if ambience_node:ambience_node._process(1.0/60.0)
		var living_node:Node=terrain.get_node_or_null("LivingMap")
		if living_node:living_node._process(1.0/60.0)
		idle.append(float(Time.get_ticks_usec()-began)/1000.0)
		await get_tree().process_frame
	var ambience:Node=terrain.get_node_or_null("MapAmbience")
	print("MAP_MOTION_CAPTURE: measure pan_p50=%.2fms pan_p95=%.2fms idle_p50=%.2fms idle_p95=%.2fms ambience_usec=%s" % [_pct(pan,0.5),_pct(pan,0.95),_pct(idle,0.5),_pct(idle,0.95),str(ambience.frame_usec if ambience else -1.0)])

static func _pct(values:Array[float],q:float)->float:
	var sorted:=values.duplicate()
	sorted.sort()
	return float(sorted[clampi(int(q*float(sorted.size()-1)),0,sorted.size()-1)]) if not sorted.is_empty() else 0.0
