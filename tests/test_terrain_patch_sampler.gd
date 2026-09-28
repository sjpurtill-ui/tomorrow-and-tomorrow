extends GdUnitTestSuite
## codex/map-speed: streamed patches built on worker threads with the fused
## sampler are the sliced main-thread build exactly, bit for bit, and a
## worker build can always be abandoned or drained.
const BUILDER:=preload("res://scripts/terrain_patch_builder.gd")
const SAMPLER:=preload("res://scripts/terrain_patch_sampler.gd")
const RENDER:=preload("res://scripts/terrain_macro_render.gd")
const LOD:=preload("res://scripts/terrain_lod.gd")
const Renderer:=preload("res://scripts/local_terrain.gd")
const TEST_SEED:=184271
const REGION_SPAN:=291.92926025390625

class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass


func before_test()->void:
	GameState.reset_for_new_world(TEST_SEED)
	PlanetEnvironment.reset_for_new_world()


func after_test()->void:
	BUILDER.drain()


func _world()->Terrain:
	var terrain:Terrain=auto_free(Terrain.new())
	terrain._configure_seamless_world();terrain._configure_shape();terrain._configure_noise()
	return terrain


func _job(terrain:Node,resolution:int,span:float,at:Vector2,prior:Dictionary={})->RefCounted:
	return BUILDER.new(resolution,span,at,terrain._height_at,terrain._terrain_color_at,terrain._terrain_surface_fields_at,terrain._terrain_seasonality_at,prior)


func _finish(job:RefCounted)->RefCounted:
	while not job.advance(1000000):pass
	return job


func _same_patch(worker:RefCounted,sliced:RefCounted)->void:
	for key in ["vertices","heights","colors","normals","cover","indices","climate_uv","geology_uv","seasonal_amplitudes"]:
		assert_bool(worker.get(key)==sliced.get(key)).override_failure_message(key+" differs").is_true()
	assert_int(worker.sampled_vertices).is_equal(sliced.sampled_vertices)
	assert_int(worker.reused_vertices).is_equal(sliced.reused_vertices)


func test_fused_sampler_is_the_sliced_sampler_chain_bit_for_bit()->void:
	var terrain:=_world()
	var sampler:=SAMPLER.from_terrain(terrain)
	assert_bool(sampler.shared_continent).is_true()
	# Home, the cradle, the great river's floodplain, inland and distant
	# land, open ocean and the shore beside it.
	for at:Vector2 in [Vector2(5733.6,1043.4),Vector2.ZERO,Vector2(-18.0,300.0),Vector2(9000.0,-4000.0),Vector2(-15000.0,7000.0),Vector2(3000.0,2500.0)]:
		var sliced:=_finish(_job(terrain,33,REGION_SPAN,at))
		var fused:Array=sampler.sample_rows(_job(terrain,33,REGION_SPAN,at),0,33)
		assert_bool(fused[0]==sliced.heights).override_failure_message("heights at %s" % at).is_true()
		assert_bool(fused[1]==sliced.vertices).is_true()
		assert_bool(fused[2]==sliced.colors).override_failure_message("colours at %s" % at).is_true()
		assert_bool(fused[3]==sliced.climate_uv).is_true()
		assert_bool(fused[4]==sliced.geology_uv).is_true()
		assert_bool(fused[5]==sliced.seasonal_amplitudes).is_true()
		assert_int(int(fused[6])).is_equal(33*33)


func test_worker_build_is_the_sliced_build_with_its_mesh_and_textures()->void:
	var terrain:=_world()
	var sampler:=SAMPLER.from_terrain(terrain)
	var at:=Vector2(5733.6,1043.4)
	var sliced:=_finish(_job(terrain,65,REGION_SPAN,at))
	var job:=_job(terrain,65,REGION_SPAN,at)
	job.start(sampler)
	assert_bool(job.uses_worker()).is_true()
	var worker:=_finish(job)
	_same_patch(worker,sliced)
	assert_object(worker.built_mesh).is_not_null()
	assert_bool(worker.commit().surface_get_arrays(0)==sliced.commit().surface_get_arrays(0)).is_true()
	# The images behind the owner's textures: raw heights, their mip chain,
	# the cover's.
	var relief:=Image.create_from_data(65,65,false,Image.FORMAT_RF,sliced.heights.to_byte_array())
	assert_bool(worker.height_image.has_mipmaps()).is_false()
	assert_bool(worker.height_image.get_data()==relief.get_data()).is_true()
	relief.generate_mipmaps()
	assert_bool(worker.relief_image.get_data()==relief.get_data()).is_true()
	var cover:=Image.create_from_data(65,65,false,Image.FORMAT_RGBA8,sliced.cover)
	cover.generate_mipmaps()
	assert_bool(worker.cover_image.get_data()==cover.get_data()).is_true()


func test_worker_refinement_reuses_exactly_the_preview_nodes()->void:
	var terrain:=_world()
	var sampler:=SAMPLER.from_terrain(terrain)
	var at:=LOD.center_for(Vector2(3000.0,2500.0),REGION_SPAN)
	var preview:=_job(terrain,33,REGION_SPAN,at)
	preview.start(sampler)
	var samples:Dictionary=_finish(preview).completed_samples()
	var refined:=_job(terrain,97,REGION_SPAN,at,samples)
	refined.start(sampler)
	_finish(refined)
	assert_int(refined.reused_vertices).is_equal(33*33)
	_same_patch(refined,_finish(_job(terrain,97,REGION_SPAN,at,samples)))
	var fresh:=_finish(_job(terrain,97,REGION_SPAN,at))
	for key in ["vertices","heights","colors","normals","climate_uv","geology_uv","seasonal_amplitudes"]:
		assert_bool(refined.get(key)==fresh.get(key)).is_true()


func test_raster_bands_on_workers_are_the_sliced_raster_patch()->void:
	var terrain:=_world()
	var raster:=RENDER.Raster.new()
	raster.level=1;raster.origin=Vector2(-400,-400);raster.cell=Vector2(7,7);raster.columns=120;raster.rows=120
	var rng:=RandomNumberGenerator.new();rng.seed=5
	for i in raster.columns*raster.rows:
		raster.heights.append(rng.randf_range(-1,3));raster.seasons.append(rng.randf_range(5,20))
		raster.colors.append(Color(rng.randf(),rng.randf(),rng.randf(),rng.randf()).to_rgba32())
		raster.fields.append(Color(rng.randf(),rng.randf(),rng.randf(),rng.randf()).to_rgba32())
	var sliced:=_job(terrain,49,500.0,Vector2(10,-20))
	sliced.macro_raster=raster
	_finish(sliced)
	var worker:=_job(terrain,49,500.0,Vector2(10,-20))
	worker.macro_raster=raster
	worker.start(SAMPLER.from_terrain(terrain))
	_same_patch(_finish(worker),sliced)
	assert_int(int(worker.completed_samples().macro_level)).is_equal(1)


func test_cancelled_worker_build_stops_and_drains()->void:
	var terrain:=_world()
	var job:=_job(terrain,257,REGION_SPAN,Vector2(900,0))
	job.start(SAMPLER.from_terrain(terrain))
	job.cancel()
	var started:=Time.get_ticks_msec()
	BUILDER.drain()
	assert_int(Time.get_ticks_msec()-started).is_less(1000)
	assert_int(job.phase).is_less(2)
	assert_object(job.built_mesh).is_null()
	assert_bool(job.advance(1000)).is_false()


func test_a_build_missing_channels_stays_on_the_main_thread()->void:
	var terrain:=_world()
	var job:=BUILDER.new(17,4.0,Vector2.ZERO,terrain._height_at,terrain._terrain_color_at)
	job.start(SAMPLER.from_terrain(terrain))
	assert_bool(job.uses_worker()).is_false()
	assert_bool(_finish(job).climate_uv.is_empty()).is_true()


func test_only_the_unmodified_world_builds_on_workers()->void:
	var double:=_world()
	assert_object(double._terrain_patch_sampler()).is_null()
	var world:Node3D=auto_free(Renderer.new())
	world._configure_seamless_world();world._configure_shape();world._configure_noise()
	var sampler:RefCounted=world._terrain_patch_sampler()
	assert_object(sampler).is_not_null()
	assert_object(world._terrain_patch_sampler()).is_same(sampler)
	world._configure_noise()
	assert_object(world._terrain_patch_sampler()).is_not_same(sampler)
	world.terrain_patch_threads=false
	assert_object(world._terrain_patch_sampler()).is_null()


func test_world_installs_worker_patches_and_drops_another_worlds()->void:
	var world:Node3D=auto_free(Renderer.new())
	world._configure_seamless_world();world._configure_shape();world._configure_noise()
	var span:=LOD.bucket(20.0)
	var at:=Vector2(55.0,0.0)
	for stage in 2:
		world._rebuild_regional_terrain_patch(at,span)
		assert_bool(world.terrain_patch_job.uses_worker()).is_true()
		while world.terrain_patch_job!=null:world._advance_terrain_patch()
	assert_int(world.regional_patch_resolution).is_equal(LOD.resolution_for(span))
	assert_int(world.terrain_patch_last_reused_vertices).is_equal(LOD.preview_resolution(span)*LOD.preview_resolution(span))
	var snapped:=LOD.center_for(at,span)
	var sliced:=_finish(_job(world,LOD.resolution_for(span),span,snapped))
	assert_bool(world.rendered_regional_heights==sliced.heights).is_true()
	assert_bool(world.regional_terrain_patch.mesh.surface_get_arrays(0)==sliced.commit().surface_get_arrays(0)).is_true()
	assert_object(world.chart_relief_texture).is_not_null()
	assert_object(world.chart_cover_texture).is_not_null()
	# One texture set a grid size, updated in place when a patch of the same
	# size lands (a cached one here).
	var relief:ImageTexture=world.chart_relief_texture
	world._rebuild_regional_terrain_patch(at+Vector2(span,0.0),span)
	while world.terrain_patch_job!=null:world._advance_terrain_patch()
	world._rebuild_regional_terrain_patch(at+Vector2(span,0.0),span)
	while world.terrain_patch_job!=null:world._advance_terrain_patch()
	assert_int(world.regional_patch_resolution).is_equal(LOD.resolution_for(span))
	assert_object(world.chart_relief_texture).is_same(relief)
	world._rebuild_regional_terrain_patch(at,span)
	assert_object(world.terrain_patch_job).is_null()
	assert_bool(world.rendered_regional_heights==sliced.heights).is_true()
	assert_object(world.chart_relief_texture).is_same(relief)
	# A world changed while a patch sampled: that patch never lands.
	var shown:MeshInstance3D=world.regional_terrain_patch
	world._rebuild_regional_terrain_patch(at-Vector2(span*2.0,0.0),span)
	assert_bool(world.terrain_patch_job.uses_worker()).is_true()
	GameState.world_seed+=1
	while world.terrain_patch_job!=null:world._advance_terrain_patch()
	assert_object(world.regional_terrain_patch).is_same(shown)
	GameState.world_seed-=1
	world._exit_tree()
