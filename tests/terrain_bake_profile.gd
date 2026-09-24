extends Node
## Headless before/after timing for docs/TERRAIN_BAKE_HANDOFF.md. Adapted from the
## codex/terrain-cost-profile harness without its counting instrumentation: every
## figure here times the real, unwrapped functions. Runs on both the base commit
## and the bake branch (bake-only rows are skipped when the API is absent).
## Modes (after --): --mode=micro | patch | pan | newworld | dayfresh | equiv | contention
## Options: --label=<name> --clear-cache=1 --samples=<n> --bake=skip --render-bake=off
## Requires private TomorrowTerrainBakeTests userdata (ignored override.cfg).
const BUILDER:=preload("res://scripts/terrain_patch_builder.gd")
const LOD:=preload("res://scripts/terrain_lod.gd")
const SEED:=873421
const WORLD_SEED:=184271

class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass

var report:Dictionary={}
var sink:=0.0

func _ready()->void:
	if DisplayServer.get_name()!="headless" or not OS.get_user_data_dir().ends_with("TomorrowTerrainBakeTests"):
		push_error("terrain_bake_profile requires headless mode and private TomorrowTerrainBakeTests userdata.")
		get_tree().quit(2);return
	call_deferred("run")

func arg(name:String,fallback:String)->String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--"+name+"="):return argument.trim_prefix("--"+name+"=")
	return fallback

func run()->void:
	var m:=arg("mode","micro")
	if arg("clear-cache","0")=="1":
		for name in DirAccess.get_files_at("user://terrain_macro"):DirAccess.remove_absolute("user://terrain_macro/"+name)
	report["mode"]=m
	report["bake_api"]=PlanetEnvironment.has_method("macro_bake_ready")
	report["label"]=arg("label","run")
	match m:
		"micro":await run_micro()
		"patch":await run_patch()
		"pan":await run_pan()
		"newworld":await run_newworld()
		"dayfresh":await run_day()
		"equiv":await run_equiv()
		"contention":await run_contention()
	var path:="res://artifacts/terrain-bake/%s-%s.json" % [m,String(report.label)]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/terrain-bake/"))
	var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	print("TERRAIN_BAKE ",m," ",JSON.stringify(report))
	print("sink ",sink)
	WorldSimulation.clear()
	await get_tree().process_frame
	get_tree().quit(0)

func quiet_root()->void:
	for node:Node in get_tree().root.get_children():
		if node!=self:node.set_process(false);node.set_physics_process(false)

func bare_terrain(seed_value:int=SEED)->Terrain:
	quiet_root()
	GameState.reset_for_new_world(seed_value)
	var terrain:=Terrain.new();add_child(terrain)
	terrain._configure_seamless_world();terrain._configure_shape();terrain._configure_noise();terrain._prepare_river_course()
	PlanetEnvironment.reset_for_new_world()
	return terrain

func points(count:int,half:float,center:Vector2,land_only:bool,rng_seed:int=1)->Array[Vector2]:
	var rng:=RandomNumberGenerator.new();rng.seed=rng_seed
	var result:Array[Vector2]=[]
	var guard:=0
	while result.size()<count and guard<count*40:
		guard+=1
		var p:=center+Vector2(rng.randf_range(-half,half),rng.randf_range(-half,half))
		if land_only and PlanetEnvironment.world_height_at(p)<=0.015:continue
		result.append(p)
	return result

func ns(start:int,count:int)->float:
	return float(Time.get_ticks_usec()-start)*1000.0/float(maxi(1,count))

func render_helper(terrain:Node)->Object:
	return terrain.get("macro_render") if "macro_render" in terrain else null

func wait_for_bakes(terrain:Node,limit_ms:int=240000)->float:
	## Bake-branch only: start and await the planet and render bakes (off-thread).
	if not PlanetEnvironment.has_method("macro_bake_ready"):return -1.0
	var start:=Time.get_ticks_msec()
	var helper:=render_helper(terrain)
	if helper!=null:
		if helper.get("terrain")==null:helper.call("bind",terrain,true,true)
		helper.call("request",Vector2(55.0,0.0))
	else:PlanetEnvironment.call("request_macro_bake")
	while Time.get_ticks_msec()-start<limit_ms:
		PlanetEnvironment.call("poll_macro_bake")
		if helper!=null:helper.call("poll")
		var terrain_ready:bool=helper==null or bool(helper.call("ready"))
		if PlanetEnvironment.call("macro_bake_ready") and terrain_ready:break
		await get_tree().process_frame
	return float(Time.get_ticks_msec()-start)

# ---------------------------------------------------------------- micro
func micro_rows(terrain:Terrain,land:Array[Vector2],mixed:Array[Vector2],fresh:Array[Vector2],ocean_starts:Array[Vector2])->Dictionary:
	var rows:Dictionary={}
	var t:int
	t=Time.get_ticks_usec()
	for p in land:sink+=PlanetEnvironment.world_height_at(p)
	rows["PE.world_height_at(land)"]=ns(t,land.size())
	t=Time.get_ticks_usec()
	for p in land:if PlanetEnvironment.is_land(p):sink+=1
	rows["PE.is_land(land)"]=ns(t,land.size())
	t=Time.get_ticks_usec()
	for p in mixed:if PlanetEnvironment.is_land(p):sink+=1
	rows["PE.is_land(planet-wide mix)"]=ns(t,mixed.size())
	t=Time.get_ticks_usec()
	for p in fresh:if PlanetEnvironment._coastal_at(p,PlanetEnvironment.world_height_at(p)):sink+=1
	rows["PE._coastal_at (incl. own height)"]=ns(t,fresh.size())
	PlanetEnvironment._profile_cache.clear()
	t=Time.get_ticks_usec()
	for p in fresh:sink+=float(PlanetEnvironment.profile_at(p).height)
	rows["PE.profile_at(cold)"]=ns(t,fresh.size())
	t=Time.get_ticks_usec()
	for p in fresh:sink+=float(PlanetEnvironment.profile_at(p).height)
	rows["PE.profile_at(cached hit)"]=ns(t,fresh.size())
	var observed:={"height":1.0,"coastal":false,"river_distance_km":20.0}
	t=Time.get_ticks_usec()
	for p in fresh:sink+=float(PlanetEnvironment.profile_at(p,observed).height)
	rows["PE.profile_at(observed height+coastal)"]=ns(t,fresh.size())
	PlanetEnvironment._viable_land_cache.clear()
	t=Time.get_ticks_usec()
	for i in ocean_starts.size():sink+=PlanetEnvironment.nearest_viable_land(ocean_starts[i],i).x
	rows["PE.nearest_viable_land(ocean start, cold)"]=ns(t,ocean_starts.size())
	t=Time.get_ticks_usec()
	for p in land:sink+=terrain._height_at(p.x,p.y)
	rows["LT._height_at(land)"]=ns(t,land.size())
	var near:=land.filter(func(p:Vector2)->bool:return p.length()<260.0).slice(0,2000)
	t=Time.get_ticks_usec()
	for p:Vector2 in near:sink+=minf(terrain._river_distance_at(p.x,p.y),1000.0)
	rows["LT._river_distance_at"]=ns(t,near.size())
	t=Time.get_ticks_usec()
	for p:Vector2 in near:sink+=terrain._surface_water_sources(Vector3(p.x,0,p.y)).size()
	rows["LT._surface_water_sources(limit INF)"]=ns(t,near.size())
	t=Time.get_ticks_usec()
	for p:Vector2 in near:sink+=terrain._surface_water_sources(Vector3(p.x,0,p.y),6.0).size()
	rows["LT._surface_water_sources(limit 6 km)"]=ns(t,near.size())
	t=Time.get_ticks_usec()
	for p:Vector2 in near:sink+=minf(terrain._nearest_tributary_distance_at(p),1000.0)
	rows["LT._nearest_tributary_distance_at"]=ns(t,near.size())
	var tiny:=near.slice(0,200)
	t=Time.get_ticks_usec()
	for p:Vector2 in tiny:sink+=float(terrain._survey_ground_at(p).size())
	rows["LT._survey_ground_at"]=ns(t,tiny.size())
	t=Time.get_ticks_usec()
	for p:Vector2 in tiny.slice(0,40):sink+=float(terrain._sample_civilization_geography(p).size())
	rows["LT._sample_civilization_geography(miss)"]=ns(t,40)
	return rows

func run_micro()->void:
	var terrain:=bare_terrain()
	var land:=points(20000,300.0,Vector2(0,0),true)
	var mixed:=points(20000,6000.0,Vector2(0,0),false,7)
	var fresh:=points(4000,300.0,Vector2(0,0),true,99)
	var ocean_starts:Array[Vector2]=[]
	for p in points(4000,9000.0,Vector2(0,0),false,31):
		if PlanetEnvironment.world_height_at(p)<-0.5:ocean_starts.append(p)
		if ocean_starts.size()>=200:break
	terrain._surface_water_sources(Vector3.ZERO);terrain._nearest_tributary_distance_at(Vector2.ZERO)
	report["noise"]=micro_rows(terrain,land,mixed,fresh,ocean_starts)
	if PlanetEnvironment.has_method("macro_bake_ready"):
		report["bake_wait_ms"]=await wait_for_bakes(terrain)
		report["bake_stats"]=PlanetEnvironment.call("macro_bake_stats")
		report["baked"]=micro_rows(terrain,land,mixed,fresh,ocean_starts)
	terrain.queue_free();await get_tree().process_frame

# ---------------------------------------------------------------- patch
func build(resolution:int,span:float,center:Vector2,terrain:Terrain,raster:Object)->Dictionary:
	var job:RefCounted=BUILDER.new(resolution,span,center,terrain._height_at,terrain._terrain_color_at,terrain._terrain_surface_fields_at,terrain._terrain_seasonality_at)
	if raster!=null:job.set("macro_raster",raster)
	var begin:=Time.get_ticks_usec()
	while not job.advance(1000000):pass
	var total:=Time.get_ticks_usec()-begin
	var commit_start:=Time.get_ticks_usec()
	var mesh:ArrayMesh=job.commit()
	sink+=mesh.get_surface_count()
	return {"job":job,"build_ms":float(total)/1000.0,"commit_ms":float(Time.get_ticks_usec()-commit_start)/1000.0}

func compare_jobs(a:RefCounted,b:RefCounted)->Dictionary:
	var ha:PackedFloat32Array=a.get("heights");var hb:PackedFloat32Array=b.get("heights")
	var ca:PackedColorArray=a.get("colors");var cb:PackedColorArray=b.get("colors")
	var errors:Array[float]=[];var color_max:=0.0;var land_flips:=0;var sq:=0.0
	for i in ha.size():
		var e:=absf(ha[i]-hb[i]);errors.append(e);sq+=e*e
		color_max=maxf(color_max,maxf(absf(ca[i].r-cb[i].r),maxf(absf(ca[i].g-cb[i].g),absf(ca[i].b-cb[i].b))))
		if (ha[i]>0.0006)!=(hb[i]>0.0006):land_flips+=1
	errors.sort()
	# Planet-scale shape: 5x5-vertex box averages (about 4 vertex spacings wide).
	var res:int=a.get("resolution")
	var smooth_sq:=0.0;var smooth_max:=0.0;var smooth_n:=0
	for row in range(2,res-2,4):
		for column in range(2,res-2,4):
			var sa:=0.0;var sb:=0.0
			for dz in range(-2,3):
				for dx in range(-2,3):
					var i:=(row+dz)*res+column+dx
					sa+=ha[i];sb+=hb[i]
			var e:=absf(sa-sb)/25.0
			smooth_sq+=e*e;smooth_max=maxf(smooth_max,e);smooth_n+=1
	var color_sq:=0.0
	for i in ha.size():color_sq+=pow(ca[i].r-cb[i].r,2.0)+pow(ca[i].g-cb[i].g,2.0)+pow(ca[i].b-cb[i].b,2.0)
	return {"height_rms":sqrt(sq/float(maxi(1,ha.size()))),"height_p99":errors[mini(errors.size()-1,int(errors.size()*0.99))],"height_max":errors[-1],
		"lowpass_height_rms":sqrt(smooth_sq/float(maxi(1,smooth_n))),"lowpass_height_max":smooth_max,
		"color_rms":sqrt(color_sq/float(3*maxi(1,ha.size()))),"color_max":color_max,"shoreline_vertex_flips":land_flips,"shoreline_flip_share":float(land_flips)/float(maxi(1,ha.size()))}

func run_patch()->void:
	var terrain:=bare_terrain(WORLD_SEED)
	terrain._surface_water_sources(Vector3.ZERO)
	var aspect:=1280.0/720.0
	var cases:Array[Dictionary]=[]
	var origin:=Vector2(55.0,0.0)
	for level in 4:
		var size:=float(terrain.CAMERA_DISTANCE_LEVELS[level].width_km)/aspect
		var span:=LOD.bucket(LOD.view_span(size,aspect,-PI*0.5))
		cases.append({"label":String(terrain.CAMERA_DISTANCE_LEVELS[level].name)+" preview","span":span,"resolution":LOD.preview_resolution(span)})
		cases.append({"label":String(terrain.CAMERA_DISTANCE_LEVELS[level].name)+" final","span":span,"resolution":LOD.resolution_for(span)})
	for span_power in [15,16,17,18,19,20,22,23]:
		var span:=pow(1.5,float(span_power))
		cases.append({"label":"span %.0f km final" % span,"span":span,"resolution":LOD.resolution_for(span)})
	var bake_ms:=-1.0
	if PlanetEnvironment.has_method("macro_bake_ready"):
		render_helper(terrain).call("bind",terrain,true,true)
		var t0:=Time.get_ticks_usec()
		terrain._build_terrain()
		report["global_mesh_ms_bake_branch"]=float(Time.get_ticks_usec()-t0)/1000.0
		bake_ms=await wait_for_bakes(terrain)
	else:
		var t0:=Time.get_ticks_usec()
		terrain._build_terrain()
		report["global_mesh_ms"]=float(Time.get_ticks_usec()-t0)/1000.0
	report["bake_wait_ms"]=bake_ms
	var rows:Array=[]
	for spec:Dictionary in cases:
		var center:=LOD.center_for(origin,float(spec.span))
		var res:=int(spec.resolution);var span:=float(spec.span)
		var real:=build(res,span,center,terrain,null)
		var row:={"label":spec.label,"span_km":span,"resolution":res,"spacing_km":span/float(res-1),"noise_build_ms":real.build_ms,"commit_ms":real.commit_ms}
		if render_helper(terrain)!=null:
			var raster:Object=render_helper(terrain).call("raster_for",center,span,res)
			row["raster_level"]=-1 if raster==null else int(raster.get("level"))
			if raster!=null:
				var baked:=build(res,span,center,terrain,raster)
				row["raster_build_ms"]=baked.build_ms
				row["equivalence"]=compare_jobs(real.job,baked.job)
		rows.append(row)
		print("PATCH ",JSON.stringify(row))
	report["patches"]=rows
	terrain.queue_free();await get_tree().process_frame

# ---------------------------------------------------------------- pan / zoom (real _process)
func full_terrain(seed_value:int)->Node:
	AudioServer.set_bus_mute(0,true)
	GameState.reset_for_new_world(seed_value)
	GameState.select_founding_focus("provision")
	PeopleDirection.choose("makers")
	var terrain:Node=load("res://local_terrain.tscn").instantiate()
	add_child(terrain)
	terrain._set_game_speed(0)
	terrain.set_process(false)
	await get_tree().process_frame
	return terrain

func patch_final(terrain:Node)->bool:
	return terrain.terrain_patch_job==null and terrain.regional_terrain_patch!=null and terrain.regional_patch_resolution==LOD.resolution_for(terrain.regional_patch_span)

func run_pan()->void:
	var terrain:Node=await full_terrain(WORLD_SEED)
	quiet_root()
	if PlanetEnvironment.has_method("macro_bake_ready"):report["bake_wait_ms"]=await wait_for_bakes(terrain)
	for i in 60:
		terrain._process(1.0/60.0);await get_tree().process_frame
	var viewport:=get_viewport().get_visible_rect().size
	var per_level:Dictionary={}
	for level in [0,1,2,3,1,0]:
		var name:=String(terrain.CAMERA_DISTANCE_LEVELS[level].name)
		if per_level.has(name):name+=" (revisit)"
		terrain.terrain_patch_cache.clear()
		terrain.set_camera_distance_level(level)
		var frames:=0;var cpu_usec:=0;var max_usec:=0
		var start:=Time.get_ticks_usec()
		while (terrain.zoom_target_size>0.0 or not patch_final(terrain)) and frames<12000:
			var f0:=Time.get_ticks_usec();terrain._process(1.0/60.0);var f:=Time.get_ticks_usec()-f0
			cpu_usec+=f;max_usec=maxi(max_usec,f);frames+=1
			await get_tree().process_frame
		var zoom_wall_ms:=float(Time.get_ticks_usec()-start)/1000.0
		# Pan 180 frames, then settle to final detail.
		var step:=float(terrain.camera.size)*viewport.x/viewport.y/150.0
		for i in 180:
			terrain._set_camera_target(terrain.camera_target+Vector3(step,0,step*0.35))
			terrain.camera_input_msec=Time.get_ticks_msec()
			terrain._process(1.0/60.0);await get_tree().process_frame
		var settle:=0;var settle_cpu:=0
		while not patch_final(terrain) and settle<12000:
			var f0:=Time.get_ticks_usec();terrain._process(1.0/60.0);settle_cpu+=Time.get_ticks_usec()-f0;settle+=1
			await get_tree().process_frame
		per_level[name]={"frames_to_final":frames,"final_cpu_ms":float(cpu_usec)/1000.0,"max_frame_ms":float(max_usec)/1000.0,"wall_ms":zoom_wall_ms,
			"frames_to_final_after_pan":settle,"after_pan_cpu_ms":float(settle_cpu)/1000.0,"patch_span":terrain.regional_patch_span,"patch_resolution":terrain.regional_patch_resolution,
			"raster_patches":int(render_helper(terrain).get("patches_served")) if render_helper(terrain)!=null else 0}
		print("PAN_LEVEL ",name," ",JSON.stringify(per_level[name]))
	report["levels"]=per_level
	terrain.queue_free();await get_tree().process_frame

# ---------------------------------------------------------------- new world
func run_newworld()->void:
	quiet_root()
	var start:=Time.get_ticks_usec()
	GameState.reset_for_new_world(WORLD_SEED)
	GameState.select_founding_focus("provision")
	PeopleDirection.choose("makers")
	var reset_ms:=float(Time.get_ticks_usec()-start)/1000.0
	var terrain:Node=load("res://local_terrain.tscn").instantiate()
	var t:=Time.get_ticks_usec()
	add_child(terrain)
	var ready_ms:=float(Time.get_ticks_usec()-t)/1000.0
	if arg("render-bake","on")=="off" and render_helper(terrain)!=null:render_helper(terrain).set("enabled",false)
	terrain._set_game_speed(0)
	quiet_root()
	t=Time.get_ticks_usec()
	var frames:=0;var max_frame:=0
	while (terrain.terrain_patch_job!=null or frames==0) and frames<4000:
		var f0:=Time.get_ticks_usec();terrain._process(1.0/60.0);max_frame=maxi(max_frame,Time.get_ticks_usec()-f0);frames+=1
		await get_tree().process_frame
	report["newworld"]={"reset_ms":reset_ms,"ready_ms":ready_ms,"first_patch_frames":frames,"first_patch_wall_ms":float(Time.get_ticks_usec()-t)/1000.0,"first_patch_max_frame_ms":float(max_frame)/1000.0}
	if PlanetEnvironment.has_method("macro_bake_ready"):
		report["newworld"]["bake_complete_after_ready_ms"]=await wait_for_bakes(terrain)
		report["bake_stats"]=PlanetEnvironment.call("macro_bake_stats")
		if render_helper(terrain)!=null:report["render_bake_stats"]=render_helper(terrain).call("stats")
	terrain.queue_free();await get_tree().process_frame

# ---------------------------------------------------------------- day steps (fresh world)
func run_day()->void:
	var terrain:Node=await full_terrain(WORLD_SEED)
	GameState.civic_api_enabled=false
	quiet_root()
	if PlanetEnvironment.has_method("macro_bake_ready") and arg("bake","wait")=="wait":report["bake_wait_ms"]=await wait_for_bakes(terrain)
	await get_tree().process_frame
	var days:=int(arg("days","20"))
	var start_day:=int(GameState.elapsed_days)
	var rows:Array[float]=[]
	for index in days:
		var day:=start_day+index+1
		var timings:Dictionary={}
		var start:=Time.get_ticks_usec()
		WorldSimulation.advance_day(day,terrain._discovery_context(),terrain._process_local_settlement_day,timings)
		rows.append(float(Time.get_ticks_usec()-start)/1000.0)
		await get_tree().process_frame
	var sorted:=rows.duplicate();sorted.sort()
	var total:=0.0
	for v in rows:total+=v
	report["days"]=rows
	report["day1_ms"]=rows[0]
	report["mean_ms"]=total/float(rows.size())
	report["median_ms"]=sorted[sorted.size()/2]
	var later:=0.0
	for i in range(1,rows.size()):later+=rows[i]
	report["mean_after_day1_ms"]=later/float(maxi(1,rows.size()-1))
	terrain.queue_free();await get_tree().process_frame

# ---------------------------------------------------------------- equivalence (outputs, both branches)
func run_equiv()->void:
	## Records exact outputs of the changed queries so base and bake runs can be
	## diffed. On the bake branch it also records the same outputs with the bake
	## ready and compares decisions against the noise path in-process.
	var terrain:=bare_terrain(WORLD_SEED)
	var near:=points(3000,240.0,Vector2(0,0),false,5)
	var out:Dictionary={}
	out["noise"]=equiv_outputs(terrain,near)
	if PlanetEnvironment.has_method("macro_bake_ready"):
		report["bake_wait_ms"]=await wait_for_bakes(terrain)
		out["baked"]=equiv_outputs(terrain,near)
		report["baked_matches_noise"]=JSON.stringify(out.baked)==JSON.stringify(out.noise)
		report["land_decisions"]=land_decision_audit()
		report["rival_placement"]=rival_placement_audit()
	report["digest"]=JSON.stringify(out.noise).sha256_text()
	report["outputs"]=out
	terrain.queue_free();await get_tree().process_frame

func equiv_outputs(terrain:Terrain,near:Array[Vector2])->Dictionary:
	var rivers:Array=[];var sources:Array=[];var local:Array=[];var tributary:Array=[]
	for p in near:
		rivers.append(snappedf(terrain._river_distance_at(p.x,p.y),0.000001) if is_finite(terrain._river_distance_at(p.x,p.y)) else -1.0)
		tributary.append(snappedf(terrain._nearest_tributary_distance_at(p),0.000001))
	for p in near.slice(0,600):
		sources.append(str(terrain._surface_water_sources(Vector3(p.x,0,p.y))))
		local.append(str(terrain._surface_water_sources(Vector3(p.x,0,p.y),6.0)))
	var profiles:Array=[]
	PlanetEnvironment._profile_cache.clear()
	var planet:=points(300,7000.0,Vector2.ZERO,false,17)
	for p in planet:
		profiles.append(str(PlanetEnvironment.profile_at(p)))
		profiles.append(str(PlanetEnvironment.profile_at(p)))
		profiles.append(str(PlanetEnvironment.profile_at(p,{"height":1.0,"coastal":true,"river_distance_km":4.0})))
		profiles.append(str(PlanetEnvironment.profile_at(p,{"temperature":0.5})))
	var viable:Array=[]
	PlanetEnvironment._viable_land_cache.clear()
	for i in 120:viable.append(str(PlanetEnvironment.nearest_viable_land(planet[i],i)))
	var land:Array=[]
	for p in planet:land.append(PlanetEnvironment.is_land(p))
	return {"river":rivers,"tributary":tributary,"sources":sources,"sources6":local,"profiles":profiles,"viable":viable,"is_land":land}

func rival_placement_audit()->Dictionary:
	## AI civilization start sites (CivilizationStart.candidate: nearest viable
	## land plus profile scoring) with the land mask vs the pure noise path.
	var start:=preload("res://scripts/civilization_start.gd")
	var placements:Array[Vector2]=[]
	for pass_index in 2:
		PlanetEnvironment.set("_macro_ready",pass_index==0)
		PlanetEnvironment._viable_land_cache.clear();PlanetEnvironment._profile_cache.clear()
		var index:=0
		for seed_offset in 10:
			for seat in 12:
				var point:Vector2=start.candidate(WORLD_SEED+seed_offset,seat)
				if pass_index==0:placements.append(point)
				elif placements[index]!=point:return {"placements":placements.size(),"mismatch_at":index}
				index+=1
	PlanetEnvironment.set("_macro_ready",true)
	var land_checks:=0;var land_flips:=0
	for point in placements:
		land_checks+=1
		if PlanetEnvironment.is_land(point)!=(PlanetEnvironment.world_height_at(point)>0.015):land_flips+=1
	return {"placements":placements.size(),"identical":true,"is_land_checks_at_sites":land_checks,"is_land_flips_at_sites":land_flips}

func land_decision_audit()->Dictionary:
	## Every guarded raster decision is compared with the exact noise predicate.
	var rng:=RandomNumberGenerator.new();rng.seed=4242
	var count:=int(arg("samples","400000"))
	var flips:=0;var coast_flips:=0;var raster_answers:=0
	for i in count:
		var p:=Vector2(rng.randf_range(-20000.0,20000.0),rng.randf_range(-9990.0,9990.0))
		if i%2==0:p=Vector2(rng.randf_range(-4000.0,4000.0),rng.randf_range(-3000.0,3000.0))
		var exact:=PlanetEnvironment.world_height_at(p)
		var decided:int=PlanetEnvironment.call("_macro_decide",p,0.015)
		if decided>=0:
			raster_answers+=1
			if (decided==1)!=(exact>0.015):flips+=1
		var coast:int=PlanetEnvironment.call("_macro_decide",p,0.0)
		if coast>=0 and (coast==1)!=(exact>0.0):coast_flips+=1
	return {"samples":count,"raster_answered":raster_answers,"is_land_flips":flips,"sea_level_flips":coast_flips}

# ---------------------------------------------------------------- bake contention
func main_workload(terrain:Terrain)->float:
	var t:=Time.get_ticks_usec()
	for i in 20000:sink+=terrain._height_at(float(i%200)*0.9-60.0,float(i/200)*0.9-40.0)
	return float(Time.get_ticks_usec()-t)/1000.0

func median(values:Array[float])->float:
	var sorted:=values.duplicate();sorted.sort()
	return float(sorted[sorted.size()/2])

func run_contention()->void:
	## Main-thread GDScript cost while the single background bake thread runs,
	## plus bake durations (cold with --clear-cache=1, otherwise cache loads).
	var terrain:=bare_terrain(WORLD_SEED)
	var idle:Array[float]=[]
	for i in 5:idle.append(main_workload(terrain))
	report["main_workload_idle_ms"]=median(idle)
	var helper:=render_helper(terrain)
	if helper==null:
		terrain.queue_free();await get_tree().process_frame;return
	helper.call("bind",terrain,true,true)
	var start:=Time.get_ticks_msec()
	helper.call("request",Vector2(55.0,0.0))
	var busy:Array[float]=[]
	var frames:=0
	while not bool(helper.call("ready")) and Time.get_ticks_msec()-start<400000:
		helper.call("poll")
		if frames%10==0:busy.append(main_workload(terrain))
		frames+=1
		await get_tree().process_frame
	report["bake_total_ms"]=Time.get_ticks_msec()-start
	report["main_workload_during_bake_ms"]=median(busy) if not busy.is_empty() else -1.0
	report["main_workload_samples"]=busy.size()
	report["render_bake_stats"]=helper.call("stats")
	report["planet_bake_stats"]=PlanetEnvironment.call("macro_bake_stats")
	# Raster nodes must hold the builder's exact samples (colour/fields as RGBA8).
	var raster:Object=helper.get("levels")[0]
	var worst:=0.0;var colour_worst:=0.0
	for probe in 400:
		var column:=(probe*7919)%int(raster.get("columns"));var row:=(probe*104729)%int(raster.get("rows"))
		var origin:Vector2=raster.get("origin");var cell:Vector2=raster.get("cell")
		var point:=Vector2(origin.x+float(column)*cell.x,origin.y+float(row)*cell.y)
		var index:=row*int(raster.get("columns"))+column
		var height:float=terrain._height_at(point.x,point.y)
		worst=maxf(worst,absf(height-(raster.get("heights") as PackedFloat32Array)[index]))
		var colour:Color=terrain._terrain_color_at(point.x,point.y,height+0.0006)
		var stored:=Color.hex((raster.get("colors") as PackedInt32Array)[index])
		colour_worst=maxf(colour_worst,maxf(maxf(absf(colour.r-stored.r),absf(colour.g-stored.g)),maxf(absf(colour.b-stored.b),absf(colour.a-stored.a))))
	report["node_exactness"]={"probes":400,"height_max_abs_error":worst,"colour_max_abs_error":colour_worst}
	terrain.queue_free();await get_tree().process_frame