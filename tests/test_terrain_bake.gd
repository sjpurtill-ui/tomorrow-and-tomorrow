extends GdUnitTestSuite
## codex/terrain-bake: exactness of the cheap query fixes, the land-mask
## certainty rule and the visual-only planet rasters.
const Renderer:=preload("res://scripts/local_terrain.gd")
const PE_SCRIPT:=preload("res://scripts/planet_environment.gd")
const BUILDER:=preload("res://scripts/terrain_patch_builder.gd")
const RENDER:=preload("res://scripts/terrain_macro_render.gd")
const TEST_SEED:=184271

class CountingPlanet extends "res://scripts/planet_environment.gd":
	var height_calls:=0
	var coast_calls:=0
	func world_height_at(position:Vector2)->float:
		height_calls+=1
		return super(position)
	func _coastal_at(position:Vector2,height:float)->bool:
		coast_calls+=1
		return super(position,height)

class Shore extends "res://scripts/local_terrain.gd":
	# Tributaries and drainage west of x=40 are submerged.
	func _height_at(x:float,_z:float)->float:return -1.0 if x<40.0 else 1.0

class Subclassed extends "res://scripts/local_terrain.gd":
	pass


func before_test()->void:
	GameState.reset_for_new_world(TEST_SEED)
	PlanetEnvironment.reset_for_new_world()


func _world(script:GDScript=Renderer)->Node3D:
	var world:Node3D=auto_free(script.new())
	world._configure_shape();world._configure_noise();world._prepare_river_course()
	return world


func _points(count:int,half:float,center:Vector2,rng_seed:int)->Array[Vector2]:
	var rng:=RandomNumberGenerator.new();rng.seed=rng_seed
	var result:Array[Vector2]=[]
	for i in count:result.append(center+Vector2(rng.randf_range(-half,half),rng.randf_range(-half,half)))
	return result


func _reference_sources(world:Node3D,origin:Vector3,limit:float)->Array[Dictionary]:
	## The former unculled implementation, kept verbatim as the oracle.
	var sources:Array[Dictionary]=[]
	var river_x:float=world._world_river_x(origin.z)
	if is_finite(river_x) and absf(origin.x-river_x)<=limit:
		var height:float=world._height_at(river_x,origin.z)
		if height>0.0:sources.append({"position":Vector3(river_x,height,origin.z),"distance_km":absf(origin.x-river_x),"kind":"River"})
	var point:=Vector2(origin.x,origin.z)
	for course:Array in world.world_tributary_courses:
		var nearest:=Vector2.INF
		var distance:=INF
		for i:int in course.size()-1:
			var start:Vector3=course[i];var finish:Vector3=course[i+1]
			var sample:=Geometry2D.get_closest_point_to_segment(point,Vector2(start.x,start.z),Vector2(finish.x,finish.z))
			var candidate_distance:=point.distance_to(sample)
			if candidate_distance<minf(distance,limit+.001):
				distance=candidate_distance;nearest=sample
		if is_finite(distance) and distance<=limit:
			var height:float=world._height_at(nearest.x,nearest.y)
			if height>0.0:sources.append({"position":Vector3(nearest.x,height,nearest.y),"distance_km":distance,"kind":"Tributary"})
	var drainage_distance:float=world._local_drainage_distance_at(origin.x,origin.z)
	if is_finite(drainage_distance) and drainage_distance<=limit:
		var phase:=float(posmod(GameState.world_seed,10007))/10007.0
		var channel_x:float=world._local_drainage_channel_x(roundi((origin.x-(phase-.5)*2.4)/2.4),origin.z)
		var height:float=world._height_at(channel_x,origin.z)
		if height>0.0:sources.append({"position":Vector3(channel_x,height,origin.z),"distance_km":drainage_distance,"kind":"Surface drainage"})
	return sources


func test_chunked_water_sources_equal_the_full_segment_scan()->void:
	var world:=_world()
	world.world_tributary_courses=world._seeded_world_tributaries()
	for p in _points(160,180.0,Vector2(-18.0,0.0),11):
		var origin:=Vector3(p.x,0,p.y)
		assert_str(str(world._surface_water_sources(origin,6.0))).is_equal(str(_reference_sources(world,origin,6.0)))
		assert_str(str(world._surface_water_sources(origin))).is_equal(str(_reference_sources(world,origin,INF)))


func test_river_distance_is_the_minimum_valid_source_distance()->void:
	for script:GDScript in [Renderer,Shore]:
		var world:=_world(script)
		world.world_tributary_courses=world._seeded_world_tributaries()
		for p in _points(200,200.0,Vector2(0.0,0.0),23):
			var expected:=INF
			for source:Dictionary in _reference_sources(world,Vector3(p.x,0,p.y),INF):expected=minf(expected,float(source.distance_km))
			var actual:float=world._river_distance_at(p.x,p.y)
			if is_inf(expected):assert_bool(is_inf(actual)).is_true()
			else:assert_float(actual).is_equal(expected)


func test_observed_ground_skips_planet_height_and_coast_probes()->void:
	var planet:CountingPlanet=auto_free(CountingPlanet.new())
	planet._ensure_configured()
	var point:=Vector2(120.0,-40.0)
	var observed:=planet.profile_at(point,{"height":1.2,"coastal":false,"river_distance_km":8.0})
	assert_int(planet.height_calls).is_equal(0)
	assert_int(planet.coast_calls).is_equal(0)
	assert_bool(bool(observed.coastal)).is_false()
	assert_float(float(observed.height)).is_equal(1.2)
	planet.profile_at(point,{"temperature":0.5})
	assert_int(planet.height_calls).is_greater_equal(1)
	assert_int(planet.coast_calls).is_equal(1)


func test_cached_profiles_are_shared_deeply_read_only_records()->void:
	var point:=PlanetEnvironment.nearest_viable_land(Vector2(300.0,200.0),3)
	var first:=PlanetEnvironment.profile_at(point)
	var second:=PlanetEnvironment.profile_at(point)
	assert_bool(is_same(first,second)).is_true()
	assert_bool(first.is_read_only()).is_true()
	for key in ["hazards","geology","resource_potentials"]:assert_bool((first[key] as Dictionary).is_read_only()).is_true()
	var copy:=first.duplicate(true)
	assert_bool(copy.is_read_only()).is_false()
	assert_bool((copy.hazards as Dictionary).is_read_only()).is_false()
	assert_dict(copy).is_equal(first)
	var observed:=PlanetEnvironment.profile_at(point,{"height":1.0})
	assert_bool(observed.is_read_only()).is_false()


func test_land_mask_cells_are_certain_and_decisions_match_exact_heights()->void:
	var planet:Node=auto_free(PE_SCRIPT.new())
	planet._ensure_configured()
	var columns:int=PE_SCRIPT.MACRO_COLUMNS
	var first_row:=952
	var band:Array=planet._macro_sample_band(first_row,16)
	var classes:PackedByteArray=band[0]
	# Install just this band; every other cell stays uncertain (noise fallback).
	var full:=PackedByteArray();full.resize(columns*PE_SCRIPT.MACRO_ROWS);full.fill(PE_SCRIPT.MACRO_CELL_UNCERTAIN)
	for i in classes.size():full[first_row*columns+i]=classes[i]
	planet._macro_classes=full;planet._macro_ready=true
	var rng:=RandomNumberGenerator.new();rng.seed=97
	var answered:=0
	for i in 6000:
		var z:=PE_SCRIPT.MACRO_Z0+(float(first_row)+rng.randf()*16.0)*PE_SCRIPT.MACRO_DZ
		var point:=Vector2(rng.randf_range(-20000.0,20000.0),z)
		var exact:float=planet._world_height_unchecked(point)
		var decided:int=planet._macro_decide(point,0.015)
		if decided>=0:answered+=1
		assert_bool(planet.is_land(point)).is_equal(exact>0.015)
		var coast:int=planet._macro_decide(point,0.0)
		if coast>=0:assert_bool(coast==1).is_equal(exact>0.0)
	assert_int(answered).is_greater(1000)
	assert_int(planet._macro_decide(Vector2(0.0,PE_SCRIPT.MACRO_Z0+10.0),0.015)).is_equal(-1)


func test_raster_patch_reads_exact_nodes_and_never_feeds_exact_reuse()->void:
	var raster:=RENDER.Raster.new()
	raster.level=1;raster.origin=Vector2(-2,-2);raster.cell=Vector2(1,1);raster.columns=5;raster.rows=5
	for i in 25:
		raster.heights.append(float(i)*0.1);raster.seasons.append(float(i))
		raster.colors.append(Color(float(i)/25.0,0.5,0.25,0.75).to_rgba32())
		raster.fields.append(Color(0.5,0.25,0.4,0.2).to_rgba32())
	var never:=func(_x:float,_z:float)->float:
		assert_bool(false).override_failure_message("procedural sampler used").is_true();return 0.0
	var builder:=BUILDER.new(5,4.0,Vector2.ZERO,never,func(_x:float,_z:float,_h:float)->Color:return Color.BLACK,func(_x:float,_z:float,_h:float)->Vector4:return Vector4.ZERO,func(_x:float,_z:float,_h:float)->float:return 0.0)
	builder.macro_raster=raster
	while not builder.advance(1000000):pass
	for i in 25:
		assert_float(builder.heights[i]).is_equal_approx(float(i)*0.1+0.0006,0.000001)
		assert_float(builder.seasonal_amplitudes[i]).is_equal_approx(float(i),0.00001)
		assert_float(builder.colors[i].r).is_equal_approx(Color.hex(raster.colors[i]).r,0.000001)
		assert_float(builder.climate_uv[i].x).is_greater_equal(1.0)
	var samples:=builder.completed_samples()
	assert_int(int(samples.macro_level)).is_equal(1)
	var exact:=BUILDER.new(5,4.0,Vector2.ZERO,func(_x:float,_z:float)->float:return 0.5,func(_x:float,_z:float,_h:float)->Color:return Color.WHITE,Callable(),Callable(),samples)
	assert_int(exact.reuse_resolution).is_equal(0)


func test_vertex_sample_equals_the_patch_builder_sampler_chain()->void:
	var world:=_world()
	var builder:=BUILDER.new(9,900.0,Vector2(40.0,-60.0),world._height_at,world._terrain_color_at,world._terrain_surface_fields_at,world._terrain_seasonality_at)
	while not builder.advance(1000000):pass
	for i in builder.vertices.size():
		var vertex:Vector3=builder.vertices[i]
		var sample:Array=RENDER.vertex_sample(world,vertex.x,vertex.z,true)
		var lifted:=PackedFloat32Array([float(sample[0])+RENDER.PATCH_LIFT])
		assert_float(builder.heights[i]).is_equal(lifted[0])
		assert_bool(builder.colors[i]==(sample[2] as Color)).is_true()
		var fields:Vector4=sample[3]
		assert_bool(builder.climate_uv[i]==Vector2(fields.x,fields.y)).is_true()
		assert_bool(builder.geology_uv[i]==Vector2(fields.z,fields.w)).is_true()
		assert_float(builder.seasonal_amplitudes[i]).is_equal(PackedFloat32Array([float(sample[1])])[0])


func test_rasters_bind_only_to_the_unmodified_world_and_respect_spacing()->void:
	var helper:=RENDER.new()
	var double:Node3D=auto_free(Subclassed.new())
	helper.bind(double,true)
	assert_bool(helper.enabled).is_false()
	var real:=RENDER.new()
	var world:Node3D=auto_free(Renderer.new())
	real.bind(world,true)
	assert_bool(real.enabled).is_true()
	assert_object(real.raster_for(Vector2.ZERO,5000.0,385)).is_null()
	var coarse:=RENDER.Raster.new()
	coarse.level=0;coarse.seed_value=GameState.world_seed
	coarse.origin=Vector2(-20037.5,-10002.0);coarse.cell=RENDER.level0_cell();coarse.columns=RENDER.LEVEL0_COLUMNS;coarse.rows=RENDER.LEVEL0_ROWS
	real.levels[0]=coarse
	# 11,223 km at 385 vertices is ~29 km spacing: the 20.9 km planet raster serves it.
	assert_object(real.raster_for(Vector2.ZERO,11222.74,385)).is_same(coarse)
	# Region scale (0.76 km spacing) keeps the procedural sampler.
	assert_object(real.raster_for(Vector2.ZERO,291.93,385)).is_null()
	GameState.world_seed+=1
	assert_object(real.raster_for(Vector2.ZERO,11222.74,385)).is_null()
