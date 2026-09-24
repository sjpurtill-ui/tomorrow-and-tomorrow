extends Node
## Headless terrain/environment cost profile for docs/TERRAIN_COST_PROFILE.md.
## Modes (user args after --): --mode=micro | patch | pan | day | newworld
## Requires the private TomorrowTerrainCostTests userdata (override.cfg) and
## headless display. Never reads player userdata; `day` loads a private copy.
const TC:=preload("res://scripts/terrain_cost_counters.gd")
const TRACE:=preload("res://scripts/performance_trace.gd")
const BUILDER:=preload("res://scripts/terrain_patch_builder.gd")
const CLOSE_JOB:=preload("res://scripts/close_terrain_job.gd")
const LOD:=preload("res://scripts/terrain_lod.gd")
const SEED:=873421

class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass

var report:Dictionary={}
var sink:=0.0
var render_previous:=0

func _ready()->void:
	if (DisplayServer.get_name()!="headless" and mode()!="render") or not OS.get_user_data_dir().ends_with("TomorrowTerrainCostTests"):
		push_error("terrain_cost_profile requires headless mode and private TomorrowTerrainCostTests userdata.")
		get_tree().quit(2);return
	call_deferred("run")

func mode()->String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--mode="):return argument.trim_prefix("--mode=")
	return "micro"

func run()->void:
	var m:=mode()
	report["mode"]=m
	match m:
		"micro":await run_micro()
		"patch":await run_patch()
		"pan":await run_pan()
		"day":await run_day()
		"dayfresh":await run_day(true)
		"newworld":await run_newworld()
		"render":await run_render()
	var path:="res://artifacts/terrain-cost/"+m+("-nocount" if OS.get_environment("TT_COST_NOCOUNT")!="" else "")+".json"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/terrain-cost/"))
	var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	print("TERRAIN_COST ",m," ",JSON.stringify(report))
	print("sink ",sink)
	WorldSimulation.clear()
	await get_tree().process_frame
	get_tree().quit(0)

func quiet_root()->void:
	for node:Node in get_tree().root.get_children():
		if node!=self:node.set_process(false);node.set_physics_process(false)

func bare_terrain()->Terrain:
	quiet_root()
	GameState.reset_for_new_world(SEED)
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
		if land_only and not PlanetEnvironment.is_land(p):continue
		result.append(p)
	return result

func ns(start:int,count:int)->float:
	return float(Time.get_ticks_usec()-start)*1000.0/float(maxi(1,count))

# ---------------------------------------------------------------- micro
func run_micro()->void:
	var terrain:=bare_terrain()
	var land:=points(20000,300.0,Vector2(0,0),true)
	var mixed:=points(20000,6000.0,Vector2(0,0),false,7)
	var fresh:=points(4000,300.0,Vector2(0,0),true,99)
	var rows:Dictionary={}
	# Warm tributary courses and chunk index once (lazy one-time setup).
	var warm:=Time.get_ticks_usec();terrain._surface_water_sources(Vector3(0,0,0));terrain._nearest_tributary_distance_at(Vector2.ZERO)
	rows["LT.tributary_setup_once_ms"]=float(Time.get_ticks_usec()-warm)/1000.0
	var t:int
	# Reference costs.
	var fnl:=FastNoiseLite.new();fnl.noise_type=FastNoiseLite.TYPE_SIMPLEX_SMOOTH;fnl.fractal_type=FastNoiseLite.FRACTAL_FBM;fnl.fractal_octaves=5;fnl.frequency=0.003
	t=Time.get_ticks_usec()
	for p in land:sink+=fnl.get_noise_2d(p.x,p.y)
	rows["ref.FastNoiseLite_5oct_get_noise_2d"]=ns(t,land.size())
	fnl.fractal_octaves=1
	t=Time.get_ticks_usec()
	for p in land:sink+=fnl.get_noise_2d(p.x,p.y)
	rows["ref.FastNoiseLite_1oct_get_noise_2d"]=ns(t,land.size())
	t=Time.get_ticks_usec()
	for p in land:sink+=p.x
	rows["ref.empty_loop"]=ns(t,land.size())
	var trivial:=func(x:float,z:float)->float:return x
	t=Time.get_ticks_usec()
	for p in land:sink+=trivial.call(p.x,p.y)
	rows["ref.callable_call_trivial"]=ns(t,land.size())
	# PlanetEnvironment (planet-scale authority).
	t=Time.get_ticks_usec()
	for p in land:sink+=PlanetEnvironment._world_height_impl(p)
	rows["PE.world_height_at(land)"]=ns(t,land.size())
	t=Time.get_ticks_usec()
	for p in mixed:sink+=PlanetEnvironment._world_height_impl(p)
	rows["PE.world_height_at(planet-wide mix)"]=ns(t,mixed.size())
	var ocean:=0
	for p in mixed:if not PlanetEnvironment.is_land(p):ocean+=1
	rows["mix_ocean_fraction"]=float(ocean)/float(mixed.size())
	t=Time.get_ticks_usec()
	for p in land:sink+=PlanetEnvironment.world_height_at(p)
	rows["PE.world_height_at(land, instrumented wrapper off)"]=ns(t,land.size())
	t=Time.get_ticks_usec()
	for p in land:if PlanetEnvironment.is_land(p):sink+=1
	rows["PE.is_land(land)"]=ns(t,land.size())
	t=Time.get_ticks_usec()
	for p in land:sink+=float(PlanetEnvironment._surface_geology_impl(p,1.0).igneous)
	rows["PE.surface_geology_at"]=ns(t,land.size())
	t=Time.get_ticks_usec()
	for p in land:sink+=PlanetEnvironment._seasonality_impl(p)
	rows["PE.seasonality_at"]=ns(t,land.size())
	PlanetEnvironment._profile_cache.clear()
	t=Time.get_ticks_usec()
	for p in fresh:sink+=float(PlanetEnvironment._profile_impl(p).height)
	rows["PE.profile_at(cold, miss)"]=ns(t,fresh.size())
	t=Time.get_ticks_usec()
	for p in fresh:sink+=float(PlanetEnvironment._profile_impl(p).height)
	rows["PE.profile_at(cached hit, incl duplicate(true))"]=ns(t,fresh.size())
	# Observed profile (what local geography passes): skips cache and coastal probes.
	var observed:={"height":1.0,"coastal":false,"river_distance_km":20.0}
	t=Time.get_ticks_usec()
	for p in fresh:sink+=float(PlanetEnvironment._profile_impl(p,observed).height)
	rows["PE.profile_at(with observed ground)"]=ns(t,fresh.size())
	var coastal_probe:=0
	t=Time.get_ticks_usec()
	for p in fresh:if PlanetEnvironment._coastal_at(p,1.0):coastal_probe+=1
	rows["PE._coastal_at (<=24 height probes)"]=ns(t,fresh.size())
	# LocalTerrain (rendering/settlement authority).
	t=Time.get_ticks_usec()
	for p in land:sink+=terrain._height_at_tcimpl(p.x,p.y)
	rows["LT._height_at(land)"]=ns(t,land.size())
	t=Time.get_ticks_usec()
	for p in mixed:sink+=terrain._height_at_tcimpl(p.x,p.y)
	rows["LT._height_at(planet-wide mix)"]=ns(t,mixed.size())
	t=Time.get_ticks_usec()
	for p in land:sink+=terrain._close_surface_height_at_tcimpl(p.x,p.y)
	rows["LT._close_surface_height_at"]=ns(t,land.size())
	t=Time.get_ticks_usec()
	for p in land:sink+=float(terrain._climate_at_tcimpl(p.x,p.y,1.0).temperature)
	rows["LT._climate_at"]=ns(t,land.size())
	t=Time.get_ticks_usec()
	for p in land:sink+=terrain._terrain_color_at_tcimpl(p.x,p.y,1.0).r
	rows["LT._terrain_color_at"]=ns(t,land.size())
	t=Time.get_ticks_usec()
	for p in land:
		sink+=terrain._terrain_color_at_tcimpl(p.x,p.y,1.0).r
		sink+=terrain._terrain_surface_fields_at_tcimpl(p.x,p.y,1.0).x
	rows["LT.color+surface_fields(shared climate, per vertex)"]=ns(t,land.size())
	t=Time.get_ticks_usec()
	for p in land:sink+=float(terrain._biome_at_tcimpl(p.x,p.y).woodland)
	rows["LT._biome_at(incl height)"]=ns(t,land.size())
	var small:=land.slice(0,2000)
	t=Time.get_ticks_usec()
	for p in small:sink+=terrain._river_distance_at_tcimpl(p.x,p.y)
	rows["LT._river_distance_at (all sources)"]=ns(t,small.size())
	t=Time.get_ticks_usec()
	for p in small:sink+=terrain._nearest_tributary_distance_at_tcimpl(p)
	rows["LT._nearest_tributary_distance_at (chunk index)"]=ns(t,small.size())
	t=Time.get_ticks_usec()
	for p in small:sink+=terrain._surface_water_sources_tcimpl(Vector3(p.x,0,p.y)).size()
	rows["LT._surface_water_sources"]=ns(t,small.size())
	t=Time.get_ticks_usec()
	for p in land:sink+=terrain._local_drainage_distance_at(p.x,p.y)
	rows["LT._local_drainage_distance_at"]=ns(t,land.size())
	var tiny:=land.slice(0,200)
	t=Time.get_ticks_usec()
	for p in tiny:sink+=float(terrain._survey_ground_at_tcimpl(p).size())
	rows["LT._survey_ground_at"]=ns(t,tiny.size())
	t=Time.get_ticks_usec()
	for p in tiny.slice(0,40):sink+=float(terrain._sample_civilization_geography_tcimpl(p).size())
	rows["LT._sample_civilization_geography (cache miss)"]=ns(t,40)
	# ---- Pre-baked alternatives: same 600 km box.
	var bake_res:=512
	var bake_half:=300.0
	var baked:=PackedFloat32Array();baked.resize(bake_res*bake_res)
	t=Time.get_ticks_usec()
	for row in bake_res:
		for col in bake_res:
			baked[row*bake_res+col]=terrain._height_at_tcimpl(-bake_half+2.0*bake_half*col/(bake_res-1),-bake_half+2.0*bake_half*row/(bake_res-1))
	var bake_ms:=float(Time.get_ticks_usec()-t)/1000.0
	rows["bake.height_512sq_total_ms"]=bake_ms
	var image:=Image.create_from_data(bake_res,bake_res,false,Image.FORMAT_RF,baked.to_byte_array())
	var cell:=2.0*bake_half/float(bake_res-1)
	t=Time.get_ticks_usec()
	for p in land:sink+=bilinear(baked,bake_res,(p.x+bake_half)/cell,(p.y+bake_half)/cell)
	rows["baked.height bilinear PackedFloat32Array (GDScript)"]=ns(t,land.size())
	t=Time.get_ticks_usec()
	for p in land:
		var u:=(p.x+bake_half)/cell;var v:=(p.y+bake_half)/cell
		sink+=baked[clampi(roundi(v),0,bake_res-1)*bake_res+clampi(roundi(u),0,bake_res-1)]
	rows["baked.height nearest PackedFloat32Array (GDScript)"]=ns(t,land.size())
	t=Time.get_ticks_usec()
	for p in land:sink+=bilinear_image(image,(p.x+bake_half)/cell,(p.y+bake_half)/cell)
	rows["baked.height bilinear Image.get_pixel x4 (GDScript)"]=ns(t,land.size())
	# Native bulk resample: one call yields a whole 385^2 patch grid.
	t=Time.get_ticks_usec()
	var region:=image.get_region(Rect2i(128,128,96,96))
	region.resize(385,385,Image.INTERPOLATE_BILINEAR)
	var heights:=region.get_data().to_float32_array()
	sink+=heights[0]
	rows["baked.native Image.get_region+resize 385sq (per sample)"]=float(Time.get_ticks_usec()-t)*1000.0/float(385*385)
	# Baked 'profile': dictionary of pre-derived records (read-only, no copy).
	var table:Dictionary={}
	for i in 4096:table[i]=PlanetEnvironment._profile_impl(fresh[i%fresh.size()])
	t=Time.get_ticks_usec()
	for i in 20000:sink+=float((table[i%4096] as Dictionary).height)
	rows["baked.profile read-only dictionary lookup"]=ns(t,20000)
	var sample_profile:Dictionary=table[0]
	t=Time.get_ticks_usec()
	for i in 4000:sink+=float(sample_profile.duplicate(true).height)
	rows["ref.profile duplicate(true)"]=ns(t,4000)
	report["ns_per_call"]=rows
	terrain.queue_free();await get_tree().process_frame

func bilinear(data:PackedFloat32Array,res:int,u:float,v:float)->float:
	var x0:=clampi(floori(u),0,res-2);var y0:=clampi(floori(v),0,res-2)
	var fx:=clampf(u-x0,0.0,1.0);var fy:=clampf(v-y0,0.0,1.0)
	var i:=y0*res+x0
	var a:=lerpf(data[i],data[i+1],fx);var b:=lerpf(data[i+res],data[i+res+1],fx)
	return lerpf(a,b,fy)

func bilinear_image(image:Image,u:float,v:float)->float:
	var res:=image.get_width()
	var x0:=clampi(floori(u),0,res-2);var y0:=clampi(floori(v),0,res-2)
	var fx:=clampf(u-x0,0.0,1.0);var fy:=clampf(v-y0,0.0,1.0)
	var a:=lerpf(image.get_pixel(x0,y0).r,image.get_pixel(x0+1,y0).r,fx)
	var b:=lerpf(image.get_pixel(x0,y0+1).r,image.get_pixel(x0+1,y0+1).r,fx)
	return lerpf(a,b,fy)

# ---------------------------------------------------------------- patch
func build(resolution:int,span:float,center:Vector2,h:Callable,c:Callable,s:Callable,season:Callable)->Dictionary:
	var job:=BUILDER.new(resolution,span,center,h,c,s,season)
	var begin:=Time.get_ticks_usec()
	while not job.advance(1000000):pass
	var total:=Time.get_ticks_usec()-begin
	var commit_start:=Time.get_ticks_usec()
	var mesh:ArrayMesh=job.commit()
	var commit_usec:=Time.get_ticks_usec()-commit_start
	sink+=mesh.get_surface_count()
	return {"job":job,"build_ms":float(total)/1000.0,"commit_ms":float(commit_usec)/1000.0}

func baked_callables(job:RefCounted)->Dictionary:
	# Rasters holding exactly what the real sampler produced, read back with
	# GDScript bilinear filtering: a like-for-like 'pre-baked world' sampler.
	var res:int=job.resolution;var span:float=job.span;var center:Vector2=job.center
	var hs:PackedFloat32Array=job.heights
	var cols:PackedColorArray=job.colors
	var clim:PackedVector2Array=job.climate_uv;var geo:PackedVector2Array=job.geology_uv
	var seas:PackedFloat32Array=job.seasonal_amplitudes
	var to_uv:=func(x:float,z:float)->Vector2:return Vector2((x-center.x)/span+0.5,(z-center.y)/span+0.5)*float(res-1)
	var h:=func(x:float,z:float)->float:
		var uv:Vector2=to_uv.call(x,z)
		return bilinear(hs,res,uv.x,uv.y)
	var c:=func(x:float,z:float,_height:float)->Color:
		var uv:Vector2=to_uv.call(x,z)
		var x0:=clampi(floori(uv.x),0,res-2);var y0:=clampi(floori(uv.y),0,res-2);var i:=y0*res+x0
		var fx:=uv.x-x0;var fy:=uv.y-y0
		return cols[i].lerp(cols[i+1],fx).lerp(cols[i+res].lerp(cols[i+res+1],fx),fy)
	var s:=func(x:float,z:float,_height:float)->Vector4:
		var uv:Vector2=to_uv.call(x,z)
		var x0:=clampi(floori(uv.x),0,res-2);var y0:=clampi(floori(uv.y),0,res-2);var i:=y0*res+x0
		var fx:=uv.x-x0;var fy:=uv.y-y0
		var a:=clim[i].lerp(clim[i+1],fx).lerp(clim[i+res].lerp(clim[i+res+1],fx),fy)
		var b:=geo[i].lerp(geo[i+1],fx).lerp(geo[i+res].lerp(geo[i+res+1],fx),fy)
		return Vector4(a.x,a.y,b.x,b.y)
	var season:=func(x:float,z:float,_height:float)->float:
		var uv:Vector2=to_uv.call(x,z)
		return bilinear(seas,res,uv.x,uv.y)
	return {"h":h,"c":c,"s":s,"season":season}

func run_patch()->void:
	var terrain:=bare_terrain()
	terrain._surface_water_sources(Vector3.ZERO)
	var aspect:=1280.0/720.0
	var cases:Array[Dictionary]=[]
	var origin:=Vector2(55.0,0.0)
	for level in 4:
		var size:=float(terrain.CAMERA_DISTANCE_LEVELS[level].width_km)/aspect
		var span:=LOD.bucket(LOD.view_span(size,aspect,-PI*0.5))
		cases.append({"label":String(terrain.CAMERA_DISTANCE_LEVELS[level].name)+" preview","span":span,"resolution":LOD.preview_resolution(span)})
		cases.append({"label":String(terrain.CAMERA_DISTANCE_LEVELS[level].name)+" final","span":span,"resolution":LOD.resolution_for(span)})
	var rows:Array=[]
	var constant_h:=func(_x:float,_z:float)->float:return 0.5
	var constant_c:=func(_x:float,_z:float,_h:float)->Color:return Color.WHITE
	var constant_s:=func(_x:float,_z:float,_h:float)->Vector4:return Vector4.ONE
	var constant_season:=func(_x:float,_z:float,_h:float)->float:return 1.0
	for spec:Dictionary in cases:
		var center:=LOD.center_for(origin,float(spec.span))
		var res:=int(spec.resolution);var span:=float(spec.span)
		# Real sampler, counted (instrumented) once for call volumes.
		TC.reset();TC.enabled=true
		var counted:=build(res,span,center,terrain._height_at,terrain._terrain_color_at,terrain._terrain_surface_fields_at,terrain._terrain_seasonality_at)
		TC.enabled=false
		var counts:=TC.snapshot()
		# Real sampler, uninstrumented timing (wrappers inert).
		var real:=build(res,span,center,terrain._height_at_tcimpl,terrain._terrain_color_at_tcimpl,terrain._terrain_surface_fields_at_tcimpl,terrain._terrain_seasonality_at)
		var bake:=baked_callables(real.job)
		var baked:=build(res,span,center,bake.h,bake.c,bake.s,bake.season)
		var none:=build(res,span,center,constant_h,constant_c,constant_s,constant_season)
		# Native whole-patch resample from a baked raster (4 channels, RGBA/RF).
		var nstart:=Time.get_ticks_usec()
		var src:=Image.create_from_data(res,res,false,Image.FORMAT_RF,(real.job.heights as PackedFloat32Array).to_byte_array())
		var r2:=src.duplicate();r2.resize(res,res,Image.INTERPOLATE_BILINEAR)
		var colors:=Image.create(res,res,false,Image.FORMAT_RGBAF);colors.resize(res,res,Image.INTERPOLATE_BILINEAR)
		var fields:=Image.create(res,res,false,Image.FORMAT_RGBAF);fields.resize(res,res,Image.INTERPOLATE_BILINEAR)
		sink+=r2.get_width()+colors.get_width()+fields.get_width()
		var native_ms:=float(Time.get_ticks_usec()-nstart)/1000.0
		var row:={"label":spec.label,"span_km":span,"resolution":res,"vertices":res*res,
			"real_build_ms":real.build_ms,"real_commit_ms":real.commit_ms,
			"instrumented_build_ms":counted.build_ms,"noise_primitive_ms_instrumented":float(counts.outer_usec)/1000.0,
			"baked_gdscript_build_ms":baked.build_ms,"constant_sampler_build_ms":none.build_ms,"native_resample_ms":native_ms,
			"sampling_share_real":1.0-none.build_ms/maxf(0.001,real.build_ms),
			"calls":counts.counts,"usec_by_fn":counts.usec,
			"frames_at_moving_budget_1p4ms":ceili(real.build_ms/1.4),"frames_at_moving_budget_baked":ceili(baked.build_ms/1.4)}
		rows.append(row)
		print("PATCH ",JSON.stringify(row))
	# Close detail job (112^2 over 420 m, 5 height calls per vertex).
	var close_center:=Vector2(55.0,0.0)
	var close_sampler:=func(x:float,z:float)->Array:
		var height:float=terrain._close_surface_height_at_tcimpl(x,z)+0.00045
		var step:=0.02
		var dx:float=(terrain._height_at_tcimpl(x+step,z)-terrain._height_at_tcimpl(x-step,z))/(step*2.0)
		var dz:float=(terrain._height_at_tcimpl(x,z+step)-terrain._height_at_tcimpl(x,z-step))/(step*2.0)
		return [height,Vector3(-dx,1.0,-dz).normalized(),terrain._terrain_color_at_tcimpl(x,z,height)]
	var job:=CLOSE_JOB.new(112,0.42,close_center,close_sampler,terrain._terrain_surface_fields_at_tcimpl,terrain._terrain_seasonality_at)
	var t:=Time.get_ticks_usec();while not job.advance(1000000):pass
	var close_ms:=float(Time.get_ticks_usec()-t)/1000.0
	var const_close:=func(x:float,z:float)->Array:return [0.5,Vector3.UP,Color.WHITE]
	var job2:=CLOSE_JOB.new(112,0.42,close_center,const_close,constant_s,constant_season)
	t=Time.get_ticks_usec();while not job2.advance(1000000):pass
	var close_const_ms:=float(Time.get_ticks_usec()-t)/1000.0
	t=Time.get_ticks_usec();sink+=job.commit().get_surface_count()
	var close_commit:=float(Time.get_ticks_usec()-t)/1000.0
	rows.append({"label":"close detail job 112sq/0.42km","vertices":112*112,"real_build_ms":close_ms,"constant_sampler_build_ms":close_const_ms,"real_commit_ms":close_commit})
	# Global planet mesh (481x241) as built at load.
	TC.reset();TC.enabled=true
	t=Time.get_ticks_usec()
	terrain._build_terrain()
	var global_ms:=float(Time.get_ticks_usec()-t)/1000.0
	TC.enabled=false
	rows.append({"label":"global planet mesh 481x241 (_build_terrain, instrumented)","vertices":481*241,"real_build_ms":global_ms,"noise_primitive_ms_instrumented":float(TC.outer_usec)/1000.0,"calls":TC.counts.duplicate()})
	report["patches"]=rows
	terrain.queue_free();await get_tree().process_frame

# ---------------------------------------------------------------- pan / zoom
func full_terrain(seed_value:int)->Node:
	AudioServer.set_bus_mute(0,true)
	GameState.reset_for_new_world(seed_value)
	GameState.select_founding_focus("provision")
	PeopleDirection.choose("makers")
	var terrain=load("res://local_terrain.tscn").instantiate()
	add_child(terrain)
	terrain._set_game_speed(0)
	terrain.set_process(false)
	await get_tree().process_frame
	return terrain

func frame(terrain:Node,frames_log:Array,label:String)->void:
	var before_outer:=TC.outer_usec
	var before_patch:=int(TRACE.totals.get("frame_terrain_patch",{"microseconds":0}).microseconds)
	var start:=Time.get_ticks_usec()
	terrain._process(1.0/60.0)
	var total:=Time.get_ticks_usec()-start
	frames_log.append({"label":label,"usec":total,"noise_usec":TC.outer_usec-before_outer,"patch_usec":int(TRACE.totals.get("frame_terrain_patch",{"microseconds":0}).microseconds)-before_patch})
	await get_tree().process_frame

func summarize(frames_log:Array,label:String)->Dictionary:
	var frames:Array=frames_log.filter(func(r:Dictionary)->bool:return r.label==label)
	if frames.is_empty():return {}
	var times:Array[float]=[];var noise:=0.0;var patch:=0.0;var total:=0.0
	for r:Dictionary in frames:times.append(float(r.usec)/1000.0);noise+=float(r.noise_usec)/1000.0;patch+=float(r.patch_usec)/1000.0;total+=float(r.usec)/1000.0
	times.sort()
	return {"frames":frames.size(),"mean_ms":total/frames.size(),"p50_ms":times[times.size()/2],"p95_ms":times[mini(times.size()-1,ceili(times.size()*0.95)-1)],"max_ms":times[-1],
		"noise_ms_per_frame":noise/frames.size(),"noise_share":noise/maxf(0.001,total),"terrain_patch_ms_per_frame":patch/frames.size()}

func patch_final(terrain:Node)->bool:
	return terrain.terrain_patch_job==null and terrain.regional_terrain_patch!=null and terrain.regional_patch_resolution==LOD.resolution_for(terrain.regional_patch_span)

func run_pan()->void:
	var terrain:Node=await full_terrain(184271)
	quiet_root()
	TRACE.enabled=true;TRACE.totals={}
	TC.reset();TC.enabled=true
	var pan_log:Array=[]
	var viewport:=get_viewport().get_visible_rect().size
	report["viewport"]=str(viewport)
	var per_level:Dictionary={}
	for i in 120:await frame(terrain,pan_log,"warmup")
	for level in [3,2,1,0]:
		var name:=String(terrain.CAMERA_DISTANCE_LEVELS[level].name)
		var calls_before:=TC.counts.duplicate()
		TC.counts={}
		var patches_before:=int(terrain.terrain_patch_cancellations)
		terrain.set_camera_distance_level(level)
		var zoom_frames:=0
		while terrain.zoom_target_size>0.0 and zoom_frames<600:
			await frame(terrain,pan_log,name+" zoom");zoom_frames+=1
		# Settle: finish patch at the idle budget.
		var settle:=0
		while not patch_final(terrain) and settle<6000:
			await frame(terrain,pan_log,name+" settle");settle+=1
		var zoom_calls:=TC.counts.duplicate();TC.counts={}
		# Pan: continuous drag, 1/150 of the view width per frame for 180 frames.
		var step:=float(terrain.camera.size)*viewport.x/viewport.y/150.0
		for i in 180:
			terrain._set_camera_target(terrain.camera_target+Vector3(step,0,step*0.35))
			terrain.camera_input_msec=Time.get_ticks_msec()
			await frame(terrain,pan_log,name+" pan")
		var pan_calls:=TC.counts.duplicate();TC.counts={}
		var after:=0
		while not patch_final(terrain) and after<6000:
			await frame(terrain,pan_log,name+" pan-settle");after+=1
		for i in 60:await frame(terrain,pan_log,name+" idle")
		var idle_calls:=TC.counts.duplicate();TC.counts={}
		per_level[name]={"camera_size":terrain.camera.size,"zoom_frames":zoom_frames,"settle_frames":settle,"pan_settle_frames":after,
			"zoom":summarize(pan_log,name+" zoom"),"settle":summarize(pan_log,name+" settle"),"pan":summarize(pan_log,name+" pan"),"pan_settle":summarize(pan_log,name+" pan-settle"),"idle":summarize(pan_log,name+" idle"),
			"calls_zoom_and_settle":zoom_calls,"calls_pan_180_frames":pan_calls,"calls_after_pan_and_idle":idle_calls,
			"patch_sampled_vertices_last":terrain.terrain_patch_last_sampled_vertices,"patch_reused_vertices_last":terrain.terrain_patch_last_reused_vertices}
		print("PAN_LEVEL ",name," ",JSON.stringify(per_level[name]))
	TC.enabled=false
	report["levels"]=per_level
	report["trace_totals"]=TRACE.totals
	report["fn_usec_total"]=TC.usec
	TRACE.enabled=false
	terrain.queue_free();await get_tree().process_frame

# ---------------------------------------------------------------- day steps
func run_day(fresh:bool=false)->void:
	var terrain:Node
	if fresh:
		terrain=await full_terrain(184271)
		GameState.civic_api_enabled=false
	else:
		var loaded:=SaveSystem.load_game("performance_snapshot")
		if not bool(loaded.get("ok",false)):
			report["error"]="private performance_snapshot could not be loaded: "+str(loaded);return
		GameState.civic_api_enabled=false
		terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
		terrain._set_game_speed(0);terrain.set_process(false)
	report["opponents"]=WorldSimulation.actors.size()
	report["start_day"]=int(GameState.elapsed_days)
	report["settled"]=GameState.settlement_site_committed
	quiet_root()
	await get_tree().process_frame
	var days:=int(OS.get_environment("TT_COST_DAYS")) if OS.get_environment("TT_COST_DAYS")!="" else 20
	var start_day:=int(GameState.elapsed_days)
	var rows:Array=[]
	TC.reset();TC.enabled=OS.get_environment("TT_COST_NOCOUNT")==""
	report["instrumented"]=TC.enabled
	for index in days:
		var day:=start_day+index+1
		var c0:=TC.counts.duplicate();var o0:=TC.outer_usec;var a0:=TC.any_outer_usec
		var timings:Dictionary={}
		var start:=Time.get_ticks_usec()
		WorldSimulation.advance_day(day,terrain._discovery_context(),terrain._process_local_settlement_day,timings)
		var elapsed:=Time.get_ticks_usec()-start
		var delta_counts:Dictionary={}
		for k in TC.counts:delta_counts[k]=int(TC.counts[k])-int(c0.get(k,0))
		rows.append({"day":day,"ms":float(elapsed)/1000.0,"noise_primitive_ms":float(TC.outer_usec-o0)/1000.0,"terrain_query_union_ms":float(TC.any_outer_usec-a0)/1000.0,"calls":delta_counts,"timings":timings})
		print("DAY ",day," ms=",float(elapsed)/1000.0," noise_ms=",float(TC.outer_usec-o0)/1000.0)
		await get_tree().process_frame
	TC.enabled=false
	report["days"]=rows
	report["fn_usec_total"]=TC.usec
	report["fn_counts_total"]=TC.counts
	terrain.queue_free();await get_tree().process_frame

# ---------------------------------------------------------------- new world
func run_newworld()->void:
	quiet_root()
	TC.reset();TC.enabled=OS.get_environment("TT_COST_NOCOUNT")==""
	report["instrumented"]=TC.enabled
	var start:=Time.get_ticks_usec()
	GameState.reset_for_new_world(184271)
	GameState.select_founding_focus("provision")
	PeopleDirection.choose("makers")
	var reset_ms:=float(Time.get_ticks_usec()-start)/1000.0
	var o0:=TC.outer_usec
	var t:=Time.get_ticks_usec()
	var terrain=load("res://local_terrain.tscn").instantiate()
	var inst_ms:=float(Time.get_ticks_usec()-t)/1000.0
	t=Time.get_ticks_usec()
	add_child(terrain)
	var ready_ms:=float(Time.get_ticks_usec()-t)/1000.0
	var ready_noise:=float(TC.outer_usec-o0)/1000.0
	var ready_union:=float(TC.any_outer_usec)/1000.0
	terrain._set_game_speed(0)
	quiet_root()
	# First frames: initial streamed patch until complete.
	var o1:=TC.outer_usec
	t=Time.get_ticks_usec()
	var frames:=0
	terrain._process(1.0/60.0);frames+=1
	while terrain.terrain_patch_job!=null and frames<2000:
		terrain._process(1.0/60.0);frames+=1
	var first_ms:=float(Time.get_ticks_usec()-t)/1000.0
	TC.enabled=false
	report["newworld"]={"reset_ms":reset_ms,"instantiate_ms":inst_ms,"ready_ms":ready_ms,"ready_noise_primitive_ms":ready_noise,"ready_terrain_query_union_ms":ready_union,
		"first_patch_frames":frames,"first_patch_cpu_ms":first_ms,"first_patch_noise_ms":float(TC.outer_usec-o1)/1000.0,
		"calls":TC.counts,"usec":TC.usec,"total_noise_primitive_ms":float(TC.outer_usec)/1000.0,"total_terrain_query_union_ms":float(TC.any_outer_usec)/1000.0}
	terrain.queue_free();await get_tree().process_frame

# ---------------------------------------------------------------- windowed render
## Only through tools/run_isolated_gpu_probe.ps1 (private desktop). The real
## frame loop runs; the probe only moves the camera and reads timers.
func run_render()->void:
	var terrain:Node=await full_terrain(184271)
	terrain.set_process(true)
	Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var rid:=get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid,true)
	TC.reset();TC.enabled=true
	var rows:Array=[]
	render_previous=Time.get_ticks_usec()
	var record:=func(label:String,noise_before:int)->void:
		var now:=Time.get_ticks_usec()
		rows.append({"label":label,"interval_ms":float(now-render_previous)/1000.0,"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,
			"render_cpu_ms":RenderingServer.viewport_get_measured_render_time_cpu(rid),"render_gpu_ms":RenderingServer.viewport_get_measured_render_time_gpu(rid),
			"noise_ms":float(TC.outer_usec-noise_before)/1000.0,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
		render_previous=now
	for i in 120:
		var o:=TC.outer_usec;await RenderingServer.frame_post_draw;record.call("warmup",o)
	var viewport:=get_viewport().get_visible_rect().size
	report["viewport"]=str(viewport)
	var levels:Dictionary={}
	for level in [3,2,1,0]:
		var name:=String(terrain.CAMERA_DISTANCE_LEVELS[level].name)
		terrain.set_camera_distance_level(level)
		var n:=0
		while (terrain.zoom_target_size>0.0 or not patch_final(terrain)) and n<6000:
			var o:=TC.outer_usec;await RenderingServer.frame_post_draw;record.call(name+" zoom+refine",o);n+=1
		for i in 90:
			var o:=TC.outer_usec;await RenderingServer.frame_post_draw;record.call(name+" static",o)
		var step:=float(terrain.camera.size)*viewport.x/viewport.y/150.0
		for i in 180:
			terrain._set_camera_target(terrain.camera_target+Vector3(step,0,step*0.35))
			terrain.camera_input_msec=Time.get_ticks_msec()
			var o:=TC.outer_usec;await RenderingServer.frame_post_draw;record.call(name+" pan",o)
		levels[name]={"zoom_refine_frames":n}
		for phase in ["zoom+refine","static","pan"]:levels[name][phase]=render_summary(rows,name+" "+phase)
		print("RENDER_LEVEL ",name," ",JSON.stringify(levels[name]))
	TC.enabled=false
	report["levels"]=levels
	terrain.queue_free();await get_tree().process_frame

func render_summary(rows:Array,label:String)->Dictionary:
	var frames:Array=rows.filter(func(r:Dictionary)->bool:return r.label==label)
	if frames.is_empty():return {}
	var result:Dictionary={"frames":frames.size()}
	for key in ["interval_ms","process_ms","render_cpu_ms","render_gpu_ms","noise_ms","draw_calls","primitives"]:
		var values:Array[float]=[]
		var total:=0.0
		for r:Dictionary in frames:values.append(float(r[key]));total+=float(r[key])
		values.sort()
		result[key]={"mean":total/frames.size(),"p50":values[values.size()/2],"p95":values[mini(values.size()-1,ceili(values.size()*0.95)-1)],"max":values[-1]}
	return result
