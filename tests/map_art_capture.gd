extends Node
## Map art capture: one world, several zooms, one run. For before/after map
## art reviews at the settlement and regional views.
##   -- --out=<absolute dir> [--prefix=name] [--sizes=6,40,160,900] [--saved] [--hide-ui] [--river] [--woodland] [--timing]
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
	terrain.game_speed=0.0
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
	# Diagnosis: `--no-shadows` turns off the sun's cast shadows, `--sky=clear|cloud|rain|snow`
	# forces the day's weather (cloud shadows, rain or snow).
	if "--no-shadows" in args:
		for light in terrain.find_children("*","DirectionalLight3D",true,false):(light as DirectionalLight3D).shadow_enabled=false
	for argument in args:
		if argument.begins_with("--sky="):_force_sky(argument.trim_prefix("--sky="))
	var lod=preload("res://scripts/terrain_lod.gd")
	var target:Vector3=GameState.settlement_founded_at
	if "--great-works" in args:_seed_great_works(target)
	if "--river" in args:
		# Look at the world river instead (charted here for this capture only).
		var river_z:=clampf(target.z,-600.0,600.0)
		target=Vector3(terrain._world_river_x(river_z),0.0,river_z)
		target.y=terrain._height_at(target.x,target.z)
		CivilizationSystem._add_revealed_area(Vector2(target.x,target.z),260.0,"capture")
	if "--winter" in args:
		# A cold region in the depth of its winter (charted for this capture).
		var cold:=_find_cold(target)
		if cold!=Vector3.INF:
			target=cold
			CivilizationSystem._add_revealed_area(Vector2(target.x,target.z),260.0,"capture")
			print("MAP_ART_CAPTURE: cold ground at ",target," ",JSON.stringify(PlanetEnvironment.profile_at(Vector2(target.x,target.z)).get("mean_temperature_c")))
		# Midwinter for that hemisphere (season_wave is -1).
		GameState.elapsed_days=91.0 if target.z>0.0 else 274.0
		terrain._refresh_seasonal_visuals()
	if "--fresh-snow" in args:
		# As if it snowed there yesterday: fresh snow lying on the ground.
		for reference in terrain.seasonal_materials:
			var material:=(reference as WeakRef).get_ref() as ShaderMaterial
			if material:material.set_shader_parameter("weather_snow",0.85)
		terrain.seasonal_snow=0.85
	if "--woodland" in args:
		# Look at the nearest dense woodland instead (charted for this capture only).
		var found:=_find_woodland(target)
		if found!=Vector3.INF:
			target=found
			CivilizationSystem._add_revealed_area(Vector2(target.x,target.z),260.0,"capture")
			print("MAP_ART_CAPTURE: woodland at ",target)
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
		# Let streamed close crowns finish growing and fading in (bounded).
		var woods:Node=terrain.get_node_or_null("CloseWoods")
		var woods_deadline:=Time.get_ticks_msec()+20000
		while woods and Time.get_ticks_msec()<woods_deadline and (not woods.queue.is_empty()):
			await get_tree().process_frame
		if woods:
			for i in 50:await get_tree().process_frame
			print("MAP_ART_CAPTURE: close woods ",JSON.stringify(woods.report()))
		if "--hide-ui" in args:
			for layer in get_tree().root.find_children("*","CanvasLayer",true,false):(layer as CanvasLayer).visible=false
		for i in 6:await get_tree().process_frame
		RenderingServer.force_sync()
		RenderingServer.force_draw(true,0.0)
		var tag:=str(int(size)) if is_equal_approx(size,roundf(size)) else str(snappedf(size,0.01)).replace(".","p")
		var path:=out_dir.path_join("%s_z%s.png" % [prefix,tag])
		var image:=get_viewport().get_texture().get_image()
		if image:image.save_png(ProjectSettings.globalize_path(path) if path.begins_with("user://") or path.begins_with("res://") else path)
		print("MAP_ART_CAPTURE: ",path," frames=",frames," patch=",terrain.regional_patch_span,"/",terrain.regional_patch_resolution)
		if "--timing" in args:print("MAP_ART_TIMING: z=",size," ",JSON.stringify(await _frame_timing()))
	get_tree().quit(0)

## `--great-works`: several works of different shapes, materials and stages
## around the home settlement (one without a surveyed site, as older saves have).
func _seed_great_works(center:Vector3)->void:
	var city:Dictionary={}
	for settlement:Dictionary in GameState.player_settlements:
		if bool(settlement.get("primary",false)) or city.is_empty():city=settlement
	if city.is_empty():return
	var home:Vector2=city.get("position",Vector2(center.x,center.z))
	var concept:=preload("res://scripts/wonder_concept.gd")
	var catalog:=preload("res://scripts/undertaking_catalog.gd")
	var works:=[["tower","honor_dead","grand","stone","functioning",1.0,Vector2(.34,-.22),true],
		["colossus","honor_dead","audacious","brick","building",.55,Vector2(-.36,-.18),false],
		["hall","bind_tribes","modest","timber","building",.15,Vector2(.05,.42),false],
		["mound","honor_dead","grand","earth","ruined",.9,Vector2(-.30,.30),false],
		["ring","bind_tribes","grand","stone","functioning",1.0,Vector2(.44,.20),false]]
	var list:Array=[]
	for i in works.size():
		var w:Array=works[i]
		var id:String=concept.make_id(w[0],w[1],w[2],w[3],1,"cap%d" % i)
		var d:Dictionary=catalog.get_definition(id)
		var record:={"id":id,"policy":"careful","status":w[4],"progress":float(d.work)*float(w[5]),"condition":.4 if w[4]=="ruined" else 1.0,"site":{"position":home+Vector2(w[6]),"angle":.4*i}}
		if bool(w[7]):record.dedicated_day=1
		if w[4]=="ruined":record.outcome="collapse"
		list.append(record)
	# An older record without a surveyed site sits at the default offset.
	var legacy_id:String=concept.make_id("tower","honor_dead","modest","stone",1,"capold")
	list.append({"id":legacy_id,"policy":"careful","status":"building","progress":float(catalog.get_definition(legacy_id).work)*.08,"condition":1.0})
	city.undertakings=list
	print("MAP_ART_CAPTURE: seeded ",list.size()," great works around ",home)
	terrain._refresh_undertaking_visuals(true)

func _force_sky(kind:String)->void:
	var ambience_script:=preload("res://scripts/map_ambience.gd")
	var forced:={"cloud":0.0,"rain":0.0,"snow":0.0}
	match kind:
		"cloud":forced={"cloud":0.6,"rain":0.0,"snow":0.0,"wind":0.6}
		"rain":forced={"cloud":0.8,"rain":0.9,"snow":0.0,"wind":0.7}
		"snow":forced={"cloud":0.7,"rain":0.0,"snow":0.9,"wind":0.35}
	ambience_script.forced_weather=forced
	var ambience:Node=terrain.get_node_or_null("MapAmbience")
	if ambience:
		var sky:Dictionary=ambience.weather.duplicate();sky.merge(forced,true)
		ambience.weather=sky
		ambience.cloud=float(forced.cloud);ambience.rain=float(forced.rain);ambience.snow=float(forced.snow)

## The coldest land found poleward of `center` (cold all year if any is).
func _find_cold(center:Vector3)->Vector3:
	var pole:=signf(center.z) if absf(center.z)>1.0 else -1.0
	var best:=Vector3.INF
	var best_c:=INF
	for step in range(1,70):
		for offset in [0.0,120.0,-120.0,260.0,-260.0]:
			var x:=center.x+float(offset)
			var z:=center.z+pole*float(step)*140.0
			if absf(z)>9500.0:continue
			var h:float=terrain._height_at(x,z)
			if h<0.05:continue
			var c:=float(PlanetEnvironment.profile_at(Vector2(x,z)).get("mean_temperature_c",99.0))
			if c<best_c:
				best_c=c;best=Vector3(x,h,z)
			if c<-3.0:return best
	return best

## Nearest point with dense woodland, searched on widening rings.
func _find_woodland(center:Vector3)->Vector3:
	for ring in range(1,60):
		var radius:=float(ring)*12.0
		for step in 24:
			var angle:=TAU*float(step)/24.0
			var x:=center.x+cos(angle)*radius
			var z:=center.z+sin(angle)*radius
			var biome:Dictionary=terrain._biome_at(x,z)
			if float(biome.get("woodland",0.0))>0.62:
				return Vector3(x,terrain._height_at(x,z),z)
	return Vector3.INF

## `--timing`: median and p95 frame times (vsync off) and GPU render time at
## this view, for before/after cost comparisons of the map shaders.
func _frame_timing()->Dictionary:
	var viewport:=get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport,true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	for i in 20:await RenderingServer.frame_post_draw
	var frames:Array[float]=[];var gpu:Array[float]=[]
	var previous:=Time.get_ticks_usec()
	for i in 120:
		await RenderingServer.frame_post_draw
		var now:=Time.get_ticks_usec();frames.append(float(now-previous)/1000.0);previous=now
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(viewport))
	frames.sort();gpu.sort()
	return {"frame_median_ms":snappedf(frames[60],0.01),"frame_p95_ms":snappedf(frames[114],0.01),"gpu_median_ms":snappedf(gpu[60],0.01),"gpu_p95_ms":snappedf(gpu[114],0.01)}
