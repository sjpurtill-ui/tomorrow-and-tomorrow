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
	var lod=preload("res://scripts/terrain_lod.gd")
	var target:Vector3=GameState.settlement_founded_at
	if "--great-works" in args:_seed_great_works(target)
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
