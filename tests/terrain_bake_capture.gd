extends Node
## Windowed QA for codex/terrain-bake; run ONLY through tools/run_isolated_gpu_probe.ps1.
## --mode=capture: same camera, raster vs procedural patch path, PNGs into
##   reports/terrain-bake/. --mode=hitch: cold bake during idle play, frame times.
## Requires private TomorrowTerrainBakeTests userdata (ignored override.cfg).
const LOD:=preload("res://scripts/terrain_lod.gd")
const WORLD_SEED:=184271
const OUT:="res://reports/terrain-bake/"
var report:Dictionary={}

func _ready()->void:
	if not OS.get_user_data_dir().ends_with("TomorrowTerrainBakeTests"):
		push_warning("terrain_bake_capture requires private userdata");get_tree().quit(2);return
	call_deferred("run")

func arg(name:String,fallback:String)->String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--"+name+"="):return argument.trim_prefix("--"+name+"=")
	return fallback

func run()->void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	AudioServer.set_bus_mute(0,true)
	if arg("mode","capture")=="hitch":
		for name in DirAccess.get_files_at("user://terrain_macro"):DirAccess.remove_absolute("user://terrain_macro/"+name)
	GameState.reset_for_new_world(WORLD_SEED)
	GameState.select_founding_focus("provision")
	PeopleDirection.choose("makers")
	var terrain:Node=load("res://local_terrain.tscn").instantiate()
	add_child(terrain)
	terrain._set_game_speed(0)
	if arg("mode","capture")=="hitch":await run_hitch(terrain)
	else:await run_capture(terrain)
	var file:=FileAccess.open(OUT+"capture-%s.json" % arg("mode","capture"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "));file.close()
	print("TERRAIN_CAPTURE ",JSON.stringify(report))
	terrain.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)

func frames(count:int)->void:
	for i in count:await get_tree().process_frame

func patch_final(terrain:Node)->bool:
	return terrain.terrain_patch_job==null and terrain.regional_terrain_patch!=null and terrain.regional_patch_resolution==LOD.resolution_for(terrain.regional_patch_span)

func wait_ready(terrain:Node)->void:
	var helper:Object=terrain.get("macro_render")
	var start:=Time.get_ticks_msec()
	while not bool(helper.call("ready")) and Time.get_ticks_msec()-start<300000:await get_tree().process_frame
	report["bake_ready_ms"]=Time.get_ticks_msec()-start

func shot(terrain:Node,name:String,target:Vector3,size:float,raster:bool)->Dictionary:
	var helper:Object=terrain.get("macro_render")
	helper.set("enabled",raster)
	terrain.terrain_patch_cache.clear()
	terrain.terrain_patch_sample_source={}
	terrain.terrain_patch_job=null
	terrain.regional_patch_center=Vector2.INF
	terrain._set_camera_target(target)
	terrain.zoom_target_size=size;terrain.zoom_preset_active=true
	var n:=0
	while (terrain.zoom_target_size>0.0 or not patch_final(terrain)) and n<20000:
		# Nudge the rebuild when the camera settles on an unchanged span.
		if n%30==0 and terrain.terrain_patch_job==null and not patch_final(terrain):terrain._rebuild_regional_terrain_patch(Vector2(terrain.camera_target.x,terrain.camera_target.z),float(terrain.regional_patch_span) if terrain.regional_patch_span>0 else 100.0)
		await get_tree().process_frame;n+=1
	await frames(30)
	# A patch outside the regional window queues a re-centred bake: wait, rebuild.
	if raster and (helper.get("pending") as Array)[1]!=null:
		var waited:=0
		while (helper.get("pending") as Array)[1]!=null and waited<20000:await get_tree().process_frame;waited+=1
		return await shot(terrain,name,target,size,raster)
	var path:=OUT+"%s-%s.png" % [name,"raster" if raster else "noise"]
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	var job_samples:Dictionary=terrain.terrain_patch_sample_source.get("samples",{}) if terrain.terrain_patch_sample_source is Dictionary else {}
	return {"file":path,"frames":n,"camera_size":terrain.camera.size,"patch_span":terrain.regional_patch_span,"patch_resolution":terrain.regional_patch_resolution,"macro_level":int(job_samples.get("macro_level",-2))}

func find_targets()->Dictionary:
	## Deterministic scan around the start for a coastline and a high ridge.
	var start:=Vector2.ZERO
	var coast:=Vector2.ZERO;var mountain:=Vector2.ZERO;var best_height:=-INF;var coast_found:=false
	for ring in range(1,60):
		for spoke in 48:
			var p:=start+Vector2.from_angle(TAU*float(spoke)/48.0)*float(ring)*60.0
			var h:=PlanetEnvironment.world_height_at(p)
			if h>best_height:best_height=h;mountain=p
			if not coast_found and h<=0.0:
				var inner:=start+Vector2.from_angle(TAU*float(spoke)/48.0)*float(ring-1)*60.0
				if PlanetEnvironment.world_height_at(inner)>0.0:coast=(p+inner)*0.5;coast_found=true
	return {"coast":coast,"mountain":mountain,"mountain_height":best_height}

func run_capture(terrain:Node)->void:
	# QA only: lift the fog so the whole planet renders.
	CivilizationSystem.revealed_areas=[{"x":0.0,"z":0.0,"radius":40000.0}]
	CivilizationSystem.fog_revision+=1
	terrain._refresh_discovery_mask(true)
	await wait_ready(terrain)
	var targets:=find_targets()
	report["targets"]={"coast":str(targets.coast),"mountain":str(targets.mountain),"mountain_height":targets.mountain_height}
	var continent:float=terrain._distance_camera_size(3)
	var fifty:float=terrain._distance_camera_size(1)
	var coast:Vector2=targets.coast;var mountain:Vector2=targets.mountain
	var start:Vector3=terrain.world_start_position
	var specs:Array=[
		["continent-start",start,continent],
		["continent-coast",Vector3(coast.x,0,coast.y),continent],
		["subcontinent-coast",Vector3(coast.x,0,coast.y),continent*0.45],
		["subcontinent-mountain",Vector3(mountain.x,0,mountain.y),continent*0.45],
		["50000ft-coast",Vector3(coast.x,0,coast.y),fifty],
		["50000ft-mountain",Vector3(mountain.x,0,mountain.y),fifty]]
	var shots:Array=[]
	for spec:Array in specs:
		for raster in [true,false]:
			var result:=await shot(terrain,String(spec[0]),spec[1],float(spec[2]),raster)
			result["name"]=spec[0];result["raster_enabled"]=raster
			shots.append(result)
			print("SHOT ",JSON.stringify(result))
	report["shots"]=shots
	# Popping check: continent view, raster on, watch the patch swap after zoom-out.
	terrain.get("macro_render").set("enabled",true)
	report["zoom_sequence"]=await zoom_sequence(terrain,start,continent)

func zoom_sequence(terrain:Node,target:Vector3,size:float)->Array:
	var out:Array=[]
	terrain.terrain_patch_cache.clear();terrain.terrain_patch_sample_source={};terrain.regional_patch_center=Vector2.INF
	terrain._set_camera_target(target);terrain.set_camera_distance_level(1)
	await frames(300)
	terrain.set_camera_distance_level(3)
	var i:=0
	var settled_at:=-1
	while i<60 and (settled_at<0 or i<settled_at+2):
		await frames(10)
		if settled_at<0 and terrain.zoom_target_size<=0.0 and patch_final(terrain) and terrain.regional_patch_span>1000.0:settled_at=i
		var path:=OUT+"zoomout-%02d.png" % i
		i+=1
		get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
		var job:RefCounted=terrain.terrain_patch_job
		out.append({"job_has_raster":job!=null and job.get("macro_raster")!=null,"job_center":str(job.center) if job!=null else "","enabled":terrain.get("macro_render").get("enabled"),"stats":terrain.get("macro_render").call("stats"),"job_span":terrain.terrain_patch_job.span if terrain.terrain_patch_job!=null else -1.0,"job_res":terrain.terrain_patch_job.resolution if terrain.terrain_patch_job!=null else -1,"job_cursor":terrain.terrain_patch_job.cursor if terrain.terrain_patch_job!=null else -1,"job_phase":terrain.terrain_patch_job.phase if terrain.terrain_patch_job!=null else -1,"zoom_target":terrain.zoom_target_size,"file":path,"camera_size":terrain.camera.size,"patch_span":terrain.regional_patch_span,"resolution":terrain.regional_patch_resolution})
	return out

func run_hitch(terrain:Node)->void:
	## Idle play at the start view: frame intervals while the cold bake runs
	## versus after it finishes. Camera static; the first patch settles first.
	Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var helper:Object=terrain.get("macro_render")
	var n:=0
	while not patch_final(terrain) and n<6000:await get_tree().process_frame;n+=1
	var during:Array[float]=[];var after:Array[float]=[];var before:Array[float]=[]
	var last:=Time.get_ticks_usec()
	var start:=Time.get_ticks_msec()
	while Time.get_ticks_msec()-start<300000:
		await get_tree().process_frame
		var now:=Time.get_ticks_usec();var dt:=float(now-last)/1000.0;last=now
		var baking:bool=bool(helper.get("_requested")) and not bool(helper.call("ready"))
		if not bool(helper.get("_requested")):before.append(dt)
		elif baking:during.append(dt)
		else:
			after.append(dt)
			if after.size()>=3000:break
	report["hitch"]={"before_bake":summary(before),"during_bake":summary(during),"after_bake":summary(after),"bake_ms":Time.get_ticks_msec()-start,"stats":helper.call("stats")}

func summary(values:Array[float])->Dictionary:
	if values.is_empty():return {}
	var sorted:=values.duplicate();sorted.sort()
	var total:=0.0
	for v in values:total+=v
	var over:=0
	for v in values:if v>33.3:over+=1
	return {"frames":values.size(),"mean_ms":total/values.size(),"p50":sorted[sorted.size()/2],"p99":sorted[mini(sorted.size()-1,int(sorted.size()*0.99))],"max":sorted[-1],"frames_over_33ms":over}
