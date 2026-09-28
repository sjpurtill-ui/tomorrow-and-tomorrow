extends Node
## Map art capture: one world, several zooms, one run. For before/after map
## art reviews at the settlement and regional views.
##   -- --out=<absolute dir> [--prefix=name] [--sizes=6,40,160,900] [--saved] [--hide-ui] [--river] [--woodland] [--timing]
##      [--town] (a later-era walled town fixture in place of the new camp)
##      [--look=dx,dz] (aim the camera this far from the settlement, km)
##      [--midwinter] [--fresh-snow] (the settlement in winter, snow lying)
##      [--foreign] (the nearest known foreign city) [--second-town]
##      [--hide=Name,Other] (hide nodes whose names contain these, to diagnose)
##      [--inventory] (list the settlement batches drawn, with a tint)
##      [--topdown] (the player's view: straight down with the distance-level lens;
##       --sizes may then name the levels L0..L3: 10,000 ft, 50,000 ft, Region, Continent)
##      [--reveal=km] (chart this radius round the target, as a well-explored campaign)
##      [--trails=n] (n scout trails charted out from home) [--day=n] (the calendar day)
##      [--highest] (the highest ground within ~1,500 km: a mountain range, charted)
##      [--population=n] [--villages=n] (the home's people; villages of ours round it)
##      [--marsh] (the nearest wet meadows, charted)
##      [--strangers=n] (n strangers' towns seen near home, the last burned)
##      [--film=from,to,steps] (after the captures: a zoom in even steps, an
##       image a step, to find pops across the crossfades)
##      [--sweep] (after the captures: frame times while stepping through the
##       distance levels and panning at the Region level, GPU included)
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
	var size_names:PackedStringArray=[]
	var args:=OS.get_cmdline_user_args()
	for argument in args:
		if argument.begins_with("--out="):out_dir=argument.trim_prefix("--out=")
		elif argument.begins_with("--prefix="):prefix=argument.trim_prefix("--prefix=")
		elif argument.begins_with("--sizes="):
			sizes.clear()
			size_names=argument.trim_prefix("--sizes=").split(",")
			for part in size_names:sizes.append(float(part))
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
	# `--topdown`: the lens and straight-down view the distance levels give
	# (the wheel steps between them); `L0..L3` in --sizes name those levels.
	if "--topdown" in args:
		terrain.set_camera_distance_level(0)
		terrain.zoom_target_size=-1.0
		terrain.zoom_preset_active=false
	for index in size_names.size():
		if size_names[index].begins_with("L"):sizes[index]=terrain._distance_camera_size(int(size_names[index].substr(1)))
	var target:Vector3=GameState.settlement_founded_at
	if "--great-works" in args:_seed_great_works(target)
	if "--town" in args:_seed_town()
	for argument in args:
		# `--look=dx,dz`: aim the camera this far (km) from the settlement.
		if argument.begins_with("--look="):
			var parts:=argument.trim_prefix("--look=").split(",")
			if parts.size()==2:
				target+=Vector3(float(parts[0]),0.0,float(parts[1]))
				target.y=terrain._height_at(target.x,target.z)
	if "--foreign" in args:
		# Look at the nearest foreign city the people know of.
		var nearest:=INF
		var found:=Vector3.INF
		for city:Dictionary in CivilizationSystem.city_intelligence.known_cities("player","",false,Vector2(target.x,target.z),INF):
			var at:=Vector3(float(city.position.x),0.0,float(city.position.z))
			var d:=Vector2(at.x-target.x,at.z-target.z).length()
			if d<nearest:nearest=d;found=at
		if found!=Vector3.INF:
			target=Vector3(found.x,terrain._height_at(found.x,found.z),found.z)
			CivilizationSystem._add_revealed_area(Vector2(target.x,target.z),30.0,"capture")
			print("MAP_ART_CAPTURE: foreign city at ",target," ",snappedf(nearest,0.1)," km away")
	if "--second-town" in args:
		# Look at the player's second town.
		for settlement in GameState.player_settlements:
			if settlement is Dictionary and not bool(settlement.get("primary",false)):
				var at:Vector2=settlement.get("position",Vector2.ZERO)
				target=Vector3(at.x,terrain._height_at(at.x,at.y),at.y)
				print("MAP_ART_CAPTURE: second town at ",target)
				break
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
	if "--midwinter" in args:
		# The home settlement in the depth of its own winter (paths in snow).
		GameState.elapsed_days=floorf(float(GameState.elapsed_days)/365.0)*365.0+(91.0 if target.z>0.0 else 274.0)
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
	for argument in args:
		# `--population=n`: the home settlement's people (sizes its worked land).
		if argument.begins_with("--population="):
			GameState.ensure_population_total(int(argument.trim_prefix("--population=")))
	for argument in args:
		# `--villages=n`: n villages of ours round home, as a grown people has.
		if argument.begins_with("--villages="):_seed_villages(int(argument.trim_prefix("--villages=")))
		# `--strangers=n`: n strangers' towns seen near home (the last burned).
		elif argument.begins_with("--strangers="):_seed_strangers(int(argument.trim_prefix("--strangers=")))
	if "--marsh" in args:
		# Look at the nearest wet meadows instead (charted for this capture):
		# they lie along the great river, a few kilometres out from its banks.
		var marsh:=_find_marsh(target)
		if marsh!=Vector3.INF:
			target=marsh
			CivilizationSystem._add_revealed_area(Vector2(target.x,target.z),260.0,"capture")
			print("MAP_ART_CAPTURE: marsh at ",target)
	if "--highest" in args:
		# Look at the highest ground within ~1,500 km (a mountain range), charted.
		var best:=Vector3.INF
		var best_h:=-INF
		for ring in range(0,31):
			for step in maxi(1,ring*6):
				var angle:=TAU*float(step)/float(maxi(1,ring*6))
				var x:=target.x+cos(angle)*float(ring)*50.0
				var z:=target.z+sin(angle)*float(ring)*50.0
				var h:float=terrain._height_at(x,z)
				if h>best_h:best_h=h;best=Vector3(x,h,z)
		if best!=Vector3.INF:
			target=best
			CivilizationSystem._add_revealed_area(Vector2(target.x,target.z),420.0,"capture")
			print("MAP_ART_CAPTURE: highest ground at ",target)
	if "--heights" in args:
		# Diagnosis: the spread of land heights (km) within 1,500 km of the target.
		var heights:Array[float]=[]
		for i in 61:
			for j in 61:
				var h:float=terrain._height_at(target.x+(float(i)-30.0)*50.0,target.z+(float(j)-30.0)*50.0)
				if h>0.0:heights.append(h)
		heights.sort()
		if not heights.is_empty():
			var pick:=func(q:float)->float:return snappedf(heights[mini(heights.size()-1,int(q*float(heights.size())))],0.01)
			print("MAP_ART_HEIGHTS: land=",heights.size()," p10=",pick.call(0.1)," p50=",pick.call(0.5)," p90=",pick.call(0.9)," p99=",pick.call(0.99)," max=",heights[-1])
	for argument in args:
		# `--reveal=km`: the ground a long campaign has charted round the target.
		if argument.begins_with("--reveal="):
			CivilizationSystem._add_revealed_area(Vector2(target.x,target.z),float(argument.trim_prefix("--reveal=")),"capture")
		# `--trails=n`: n returned scout trails wandering out from home, charted
		# as the game charts them (18 km either side), as years of scouting leave.
		elif argument.begins_with("--trails="):
			var home:=Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z)
			var count:=int(argument.trim_prefix("--trails="))
			for trail in count:
				var heading:=TAU*float(trail)/float(max(count,1))+0.4
				var at:=home
				var points:=[{"x":at.x,"z":at.y}]
				for leg in 9:
					heading+=sin(float(trail*7+leg)*1.7)*0.45
					at+=Vector2(cos(heading),sin(heading))*48.0
					points.append({"x":at.x,"z":at.y})
				CivilizationSystem._add_revealed_trail(points,18.0,"returned scout trail",int(GameState.elapsed_days))
		# `--day=n`: the calendar day (the season and the day's weather).
		elif argument.begins_with("--day="):
			GameState.elapsed_days=float(argument.trim_prefix("--day="))
			terrain._refresh_seasonal_visuals()
	for size_index in sizes.size():
		var size:=sizes[size_index]
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
		# Let the roads between places finish routing (bounded).
		var roads:Node=terrain.get("settlement_roads")
		var roads_deadline:=Time.get_ticks_msec()+25000
		while roads and Time.get_ticks_msec()<roads_deadline and (not (roads.get("pending") as Array).is_empty() or not (roads.get("working") as Dictionary).is_empty()):
			await get_tree().process_frame
		if roads:
			for i in 12:await get_tree().process_frame
			print("MAP_ART_CAPTURE: roads links=",(roads.get("edges") as Array).size()," drawn=",roads.get_meta("roads_drawn",0)," knowledge=",JSON.stringify(roads.knowledge())," places=",roads.call("_places").map(func(p:Array)->String:return "%s@%.1f,%.1f" % [p[2],(p[0] as Vector2).x,(p[0] as Vector2).y]))
		if "--hide-ui" in args:
			for layer in get_tree().root.find_children("*","CanvasLayer",true,false):(layer as CanvasLayer).visible=false
		# Diagnosis: `--hide=Name,Other` hides every node whose name contains one.
		for argument in args:
			if argument.begins_with("--hide="):
				for part in argument.trim_prefix("--hide=").split(","):
					for node in terrain.find_children("*"+part+"*","Node3D",true,false):(node as Node3D).visible=false
		for i in 6:await get_tree().process_frame
		RenderingServer.force_sync()
		RenderingServer.force_draw(true,0.0)
		var tag:=str(int(size)) if is_equal_approx(size,roundf(size)) else str(snappedf(size,0.01)).replace(".","p")
		if size_index<size_names.size() and size_names[size_index].begins_with("L"):tag=size_names[size_index]
		var path:=out_dir.path_join("%s_z%s.png" % [prefix,tag])
		var image:=get_viewport().get_texture().get_image()
		if image:image.save_png(ProjectSettings.globalize_path(path) if path.begins_with("user://") or path.begins_with("res://") else path)
		print("MAP_ART_CAPTURE: ",path," frames=",frames," patch=",terrain.regional_patch_span,"/",terrain.regional_patch_resolution)
		var living:Node=terrain.get_node_or_null("LivingMap")
		var ambience:Node=terrain.get_node_or_null("MapAmbience")
		if living and ambience and size==sizes[0]:
			var site:Vector3=ambience.call("_water_site",living.get("anchor"))
			var landing:MeshInstance3D=ambience.get("landing")
			print("MAP_ART_CAPTURE: water site ",site," from settlement km ",Vector2(site.x-target.x,site.z-target.z) if site!=Vector3.ZERO else Vector2.INF," landing=",landing!=null and landing.mesh!=null)
		if living:print("MAP_ART_CAPTURE: life visible=",living.get("figures_visible")," workers=",(living.get("workers") as Array).size()," anchor=",living.get("anchor")," grounds=",JSON.stringify(preload("res://scripts/settlement_grounds.gd").report)," slots=",JSON.stringify(preload("res://scripts/settlement_grounds.gd").slot_keys))
		if "--inventory" in args and size==sizes[0]:
			# What the settlement kits drew: batch names and instance counts.
			var drawn:=PackedStringArray()
			for node in terrain.find_children("*","MultiMeshInstance3D",true,false):
				var batch:=(node as MultiMeshInstance3D).multimesh
				if batch and not String(node.name).begins_with("GroundShadow"):
					var tint:=batch.get_instance_color(0).to_html(false) if batch.use_colors and batch.instance_count>0 else ""
					drawn.append("%s=%d%s" % [node.name,batch.instance_count,(" #"+tint) if tint!="" else ""])
			print("MAP_ART_INVENTORY: ",", ".join(drawn))
			var meshes:={}
			for node in terrain.find_children("*","MeshInstance3D",true,false):
				if (node as MeshInstance3D).is_visible_in_tree() and not node is MultiMeshInstance3D:meshes[String(node.get_parent().name)+"/"+String(node.name).get_slice("@",0)]=true
			print("MAP_ART_MESHES: ",", ".join(PackedStringArray(meshes.keys())))
		if "--timing" in args:print("MAP_ART_TIMING: z=",size," ",JSON.stringify(await _frame_timing()))
	if "--sweep" in args:
		for line in await _level_sweep(target):print("MAP_ART_SWEEP: ",JSON.stringify(line))
	for argument in args:
		# `--glide=from,to`: a real glide between two distance levels, as the
		# wheel makes it, with images at its end and after, to see how long
		# the streamed ground takes to catch up.
		if argument.begins_with("--glide="):
			var levels:=argument.trim_prefix("--glide=").split(",")
			if levels.size()==2:await _glide_shots(target,int(levels[0]),int(levels[1]),out_dir,prefix)
	for argument in args:
		# `--film=from,to,steps`: a zoom from one view size to another in even
		# steps (a zoom factor per step), one image per step, to find pops.
		if argument.begins_with("--film="):
			var parts:=argument.trim_prefix("--film=").split(",")
			if parts.size()==3:await _film(target,float(parts[0]),float(parts[1]),int(parts[2]),out_dir,prefix)
	get_tree().quit(0)

## `--glide`: settle at one distance level, glide to another as the wheel
## does (real time, vsync as in play), and save the view when the glide ends
## and 0.25 to 16 seconds later, with whether the streamed patch
## has caught up.
func _glide_shots(target:Vector3,from_level:int,to_level:int,out_dir:String,prefix:String)->void:
	terrain.camera_target=target
	terrain.set_camera_distance_level(from_level)
	terrain.camera.size=terrain.zoom_target_size
	terrain.zoom_target_size=-1.0
	terrain.zoom_preset_active=false
	terrain._update_camera()
	var lod=preload("res://scripts/terrain_lod.gd")
	var deadline:=Time.get_ticks_msec()+30000
	var frames:=0
	while Time.get_ticks_msec()<deadline and (frames<60 or terrain.terrain_patch_job!=null):
		await get_tree().process_frame
		frames+=1
	terrain.set_camera_distance_level(to_level)
	terrain.zoom_pointer=get_viewport().get_visible_rect().size*0.5
	var started:=Time.get_ticks_msec()
	while terrain.zoom_target_size>0.0 and Time.get_ticks_msec()-started<10000:
		await get_tree().process_frame
	var ended:=Time.get_ticks_msec()
	print("MAP_ART_GLIDE: L%d->L%d glide %d ms" % [from_level,to_level,ended-started])
	for wait_ms in [0,250,500,1000,2000,4000,8000,16000]:
		while Time.get_ticks_msec()-ended<wait_ms:await get_tree().process_frame
		var image:=get_viewport().get_texture().get_image()
		if image:image.save_png(out_dir.path_join("%s_glide_%d_%d_%04d.png" % [prefix,from_level,to_level,wait_ms]))
		var covered:bool=terrain._patch_covers_camera(terrain.regional_patch_center,terrain.regional_patch_span) if terrain.has_method("_patch_covers_camera") else true
		print("MAP_ART_GLIDE: +%d ms patch=%.1f/%d job=%s covers=%s" % [wait_ms,terrain.regional_patch_span,terrain.regional_patch_resolution,str(terrain.terrain_patch_job!=null),str(covered)])

## `--film`: the view zooms from `from_size` to `to_size` about the target in
## `steps` equal ratios, two frames a step (streaming and fades run as in
## play), saving each step's image at half size with its camera size, and
## when the streamed patch changed.
func _film(target:Vector3,from_size:float,to_size:float,steps:int,out_dir:String,prefix:String)->void:
	var ratio:=pow(to_size/from_size,1.0/float(maxi(steps,1)))
	var size:=from_size
	terrain.camera_target=target
	terrain.zoom_target_size=-1.0
	terrain.camera.size=size
	terrain._update_camera()
	for i in 90:await get_tree().process_frame
	var span:float=terrain.regional_patch_span
	var log_lines:=PackedStringArray()
	for step in steps+1:
		terrain.camera.size=size
		terrain.camera_target=target
		terrain._update_camera()
		for i in 2:await get_tree().process_frame
		RenderingServer.force_draw(true,0.0)
		var image:=get_viewport().get_texture().get_image()
		if image:
			image.resize(image.get_width()/2,image.get_height()/2,Image.INTERPOLATE_BILINEAR)
			image.save_png(out_dir.path_join("%s_film_%03d.png" % [prefix,step]))
		var installed:=not is_equal_approx(float(terrain.regional_patch_span),span)
		span=terrain.regional_patch_span
		log_lines.append("%d %.4f %d %.3f" % [step,size,1 if installed else 0,span])
		size*=ratio
	var file:=FileAccess.open(out_dir.path_join("%s_film.txt" % prefix),FileAccess.WRITE)
	if file:file.store_string("
".join(log_lines))
	print("MAP_ART_FILM: ",steps+1," frames ",from_size," -> ",to_size)

## `--sweep`: frame times (vsync off, GPU included) while the camera glides
## between the distance levels as the wheel steps them, holding a second at
## each, then while panning across the Region view. Streaming, label layout
## and every shader change on the way are part of what is measured.
func _level_sweep(target:Vector3)->Array:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	var lines:=[]
	terrain.camera_target=target
	terrain.set_camera_distance_level(0)
	terrain.camera.size=terrain.zoom_target_size
	terrain.zoom_target_size=-1.0
	terrain.zoom_preset_active=false
	terrain._update_camera()
	for i in 120:await RenderingServer.frame_post_draw
	var center:=get_viewport().get_visible_rect().size*0.5
	for next in [1,2,3,2,1,0]:
		var from:=int(terrain.camera_distance_level())
		terrain.set_camera_distance_level(next)
		terrain.zoom_pointer=center
		var times:Array[float]=[]
		var worst:=[]
		var previous:=Time.get_ticks_usec()
		var glide_frames:=0
		var dwell:=0
		while dwell<60 and times.size()<1200:
			await RenderingServer.frame_post_draw
			var now:=Time.get_ticks_usec()
			var ms:=float(now-previous)/1000.0
			previous=now
			times.append(ms)
			worst.append([snappedf(ms,0.01),snappedf(terrain.camera.size,0.01)])
			if terrain.zoom_target_size>0.0:glide_frames+=1
			else:dwell+=1
		lines.append(_timing_summary("L%d->L%d" % [from,next],times,worst,{"glide_frames":glide_frames}))
	# Pan across the Region view, as a drag does, for two seconds.
	terrain.set_camera_distance_level(2)
	terrain.camera.size=terrain.zoom_target_size
	terrain.zoom_target_size=-1.0
	terrain.zoom_preset_active=false
	terrain._update_camera()
	for i in 90:await RenderingServer.frame_post_draw
	var origin:Vector3=terrain.camera_target
	var times:Array[float]=[]
	var worst:=[]
	var previous:=Time.get_ticks_usec()
	for i in 120:
		terrain.camera_input_msec=Time.get_ticks_msec()
		terrain._set_camera_target(origin+Vector3(terrain.camera.size*0.004*i,0,terrain.camera.size*0.002*i))
		terrain._update_camera()
		await RenderingServer.frame_post_draw
		var now:=Time.get_ticks_usec()
		var ms:=float(now-previous)/1000.0
		previous=now
		times.append(ms)
		worst.append([snappedf(ms,0.01),snappedf(terrain.camera.size,0.01)])
	lines.append(_timing_summary("pan_region",times,worst,{}))
	return lines

func _timing_summary(name:String,times:Array[float],worst:Array,extra:Dictionary)->Dictionary:
	var sorted:=times.duplicate();sorted.sort()
	worst.sort_custom(func(a:Array,b:Array)->bool:return a[0]>b[0])
	var over:=0
	for t in times:if t>33.3:over+=1
	var out:={"phase":name,"frames":times.size(),"p50_ms":snappedf(sorted[sorted.size()/2],0.01),"p95_ms":snappedf(sorted[int(sorted.size()*0.95)],0.01),"max_ms":snappedf(sorted[-1],0.01),"over_33ms":over,"worst":worst.slice(0,4)}
	out.merge(extra)
	return out

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

## `--town`: a later-era market town in place of the new camp, for reviewing
## the settlement art as it grows (a fixture only; nothing is simulated).
## Masonry and timber houses along streets round a market plaza, halls,
## workshops and stores, a well, fields in their season all round, and a
## palisade with gates.
## `--town`: a later-era market town (tests/town_fixture.gd) in place of the
## new camp, behind a palisade with gates.
func _seed_town()->void:
	var town:Dictionary=preload("res://tests/town_fixture.gd").build()
	GameState.settlement_plots.assign(town.plots)
	GameState.settlement_routes.assign(town.routes)
	var campaign:=get_node_or_null("/root/MilitaryCampaign")
	if campaign:
		campaign.settlement_defense["stage"]=3
		campaign.settlement_defense["integrity"]=1.0
	# A town of this age builds carts and trades in its market.
	for known in ["solid_wheel_assembly","cart_running_gear","pottery","plain_weaving","animal_taming","herding_rotas","well_siting"]:
		GameState.discovery_log.append({"id":known})
	GameState.morphology_revision+=1
	print("MAP_ART_CAPTURE: seeded a town of ",town.plots.size()," plots and ",town.routes.size()," routes")

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

## `--villages=n`: villages of ours on dry land 15-45 km round home, each with
## a share of the people (a fixture only; nothing is simulated).
func _seed_villages(count:int)->void:
	var home:=Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z)
	var placed:=0
	for attempt in count*12:
		if placed>=count:break
		var angle:=TAU*float(attempt)/float(maxi(count,1))*0.618+0.3
		var reach:=15.0+30.0*fmod(float(attempt)*0.37,1.0)
		var at:=home+Vector2(cos(angle),sin(angle))*reach
		if terrain._height_at(at.x,at.y)<0.05:continue
		var sequence:=int(WorldSimulation.state.next_player_settlement_id)
		var record:={"id":"settlement_%03d" % sequence,"sequence":sequence,"primary":false,"name":"Village %d" % (placed+1),"position":at,
			"population_share":0.10,"founded_day":0,"status":"established","source_settlement_id":"","territory_context":{},"environment_profile":{},
			"auto_manage":true,"management_focus":"establishment","leader_person_id":0}
		WorldSimulation.state.next_player_settlement_id+=1
		WorldSimulation.state.player_settlements.append(record)
		placed+=1
	print("MAP_ART_CAPTURE: seeded ",placed," villages")

## `--strangers=n`: strangers' towns our scouts have seen, set 25-50 km round
## home on dry land, the last of them burned out (a fixture only).
func _seed_strangers(count:int)->void:
	if CivilizationSystem.civilizations.is_empty():CivilizationSystem.initialize()
	# Strangers found their towns years in: found each people's chief town now.
	for civ:Dictionary in CivilizationSystem.civilizations:
		for region:Dictionary in civ.strategic_regions:
			if String(region.get("role",""))=="capital":region["settlement_founded"]=true
	var intel=CivilizationSystem.city_intelligence
	print("MAP_ART_CAPTURE: peoples=",CivilizationSystem.civilizations.size()," sites=",intel.sites(false).size())
	for civ:Dictionary in CivilizationSystem.civilizations:civ.player_relation.contact_level=2
	var home:=Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z)
	var day:=int(GameState.elapsed_days)
	var placed:=0
	for site:Dictionary in intel.sites(false):
		if placed>=count:break
		var at:=Vector2.INF
		for attempt in 16:
			var angle:=TAU*(float(placed)/float(maxi(count,1))+float(attempt)*0.07)+0.9
			var candidate:=home+Vector2(cos(angle),sin(angle))*(28.0+float(attempt%4)*6.0)
			if terrain._height_at(candidate.x,candidate.y)>0.08:at=candidate;break
		if at==Vector2.INF:continue
		var observation:Dictionary=intel.capture("player",String(site.city_id),.85,day,"Scout report","capture")
		observation.position={"x":at.x,"z":at.y}
		# The first is a grown walled city, the second a market town.
		var report:={"observed_day":day,"quality":.85,"source":"Scout report","reference":"capture"}
		if placed==0:
			observation.fields["population"]=report.merged({"low":14000.0,"high":18000.0})
			observation.fields["fortification"]=report.merged({"low":.6,"high":.75})
		elif placed==1:
			observation.fields["population"]=report.merged({"low":2500.0,"high":3500.0})
		if placed==count-1 and count>1:observation.fields["damage"]=report.merged({"low":.7,"high":.85})
		intel.publish("player",observation,day+1)
		placed+=1
	print("MAP_ART_CAPTURE: seeded ",placed," strangers' towns")

## Wet meadows beside the world river, walking its course from `center`.
func _find_marsh(center:Vector3)->Vector3:
	for step in range(0,800):
		for direction:float in [1.0,-1.0]:
			var z:=clampf(center.z,-750.0,750.0)+direction*float(step)*2.0
			if absf(z)>758.0:continue
			var river:float=terrain._world_river_x(z)
			for offset:float in [5.0,8.0,11.0,14.0,17.0,-5.0,-8.0,-11.0,-14.0,-17.0]:
				var x:=river+float(offset)
				if String(terrain._biome_at(x,z).get("id",""))=="wetland":
					return Vector3(x,terrain._height_at(x,z),z)
	return Vector3.INF

## Nearest land of this biome, searched on widening rings.
func _find_biome(center:Vector3,id:String)->Vector3:
	for ring in range(1,120):
		var radius:=float(ring)*12.0
		for step in 32:
			var angle:=TAU*float(step)/32.0
			var x:=center.x+cos(angle)*radius
			var z:=center.z+sin(angle)*radius
			if String(terrain._biome_at(x,z).get("id",""))==id:
				return Vector3(x,terrain._height_at(x,z),z)
	return Vector3.INF

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
