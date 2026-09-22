extends GdUnitTestSuite

const BUILDER:=preload("res://scripts/terrain_patch_builder.gd")
const LOD:=preload("res://scripts/terrain_lod.gd")
class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
class CheapTerrain extends Terrain:
	func _height_at(x:float,z:float)->float:return sin(x*.7)*.08+cos(z*.31)*.03
	func _terrain_color_at(x:float,z:float,h:float)->Color:return Color(.3+x*.001,.4+z*.001,.2+h,0.25)
	func _terrain_surface_fields_at(x:float,z:float,h:float)->Vector4:return Vector4(1.5+x*.00001,.5+z*.00001,.3+h*.001,.2)
	func _terrain_seasonality_at(x:float,z:float,_h:float)->float:return x*.001+z*.002

func finish(builder:RefCounted)->void:
	while not builder.advance(1000):pass

func build(terrain:Terrain,resolution:int,span:float,center:Vector2,prior:Dictionary={})->RefCounted:
	var job:=BUILDER.new(resolution,span,center,terrain._height_at,terrain._terrain_color_at,terrain._terrain_surface_fields_at,terrain._terrain_seasonality_at,prior)
	finish(job)
	return job

func compare(a:RefCounted,b:RefCounted)->void:
	assert_bool(a.vertices==b.vertices).is_true()
	assert_bool(a.heights==b.heights).is_true()
	assert_bool(a.colors==b.colors).is_true()
	assert_bool(a.normals==b.normals).is_true()
	assert_bool(a.indices==b.indices).is_true()
	assert_bool(a.climate_uv==b.climate_uv).is_true()
	assert_bool(a.geology_uv==b.geology_uv).is_true()
	assert_bool(a.seasonal_amplitudes==b.seasonal_amplitudes).is_true()

func test_one_step_pan_only_samples_entering_strip_and_rebuilds_edge_normals()->void:
	var terrain:CheapTerrain=auto_free(CheapTerrain.new())
	var source:=build(terrain,49,12,Vector2.ZERO)
	var before:Dictionary=source.completed_samples()
	var moved:=build(terrain,49,12,Vector2(1,0),before)
	var fresh:=build(terrain,49,12,Vector2(1,0))
	assert_int(moved.reused_vertices).is_equal(45*49)
	assert_int(moved.sampled_vertices).is_equal(4*49)
	compare(moved,fresh)
	# Reusing a snapshot does not mutate the original completed mesh.
	compare(source,build(terrain,49,12,Vector2.ZERO))

func test_nonmatching_lattice_falls_back_to_authoritative_sampling()->void:
	var terrain:CheapTerrain=auto_free(CheapTerrain.new())
	var source:=build(terrain,49,12,Vector2.ZERO)
	var moved:=build(terrain,49,12,Vector2(.07,.13),source.completed_samples())
	assert_int(moved.reused_vertices).is_equal(0)
	compare(moved,build(terrain,49,12,Vector2(.07,.13)))

func test_middle_zoom_grids_share_samples_after_snapped_pan()->void:
	var terrain:CheapTerrain=auto_free(CheapTerrain.new())
	for span:float in [LOD.bucket(24.0),LOD.bucket(42.0)]:
		var resolution:=LOD.resolution_for(span)
		var center:=LOD.center_for(Vector2.ZERO,span)
		var next:=LOD.center_for(Vector2(span/12.0,0),span)
		var source:=build(terrain,resolution,span,center)
		var moved:=build(terrain,resolution,span,next,source.completed_samples())
		assert_int(moved.reused_vertices).is_greater(int(resolution*resolution*.85))
		compare(moved,build(terrain,resolution,span,next))

func test_refinement_reuses_only_existing_grid_nodes()->void:
	var terrain:CheapTerrain=auto_free(CheapTerrain.new())
	var source:=build(terrain,17,12,Vector2.ZERO)
	var refined:=build(terrain,49,12,Vector2.ZERO,source.completed_samples())
	assert_int(refined.reused_vertices).is_equal(17*17)
	compare(refined,build(terrain,49,12,Vector2.ZERO))

func test_missing_surface_channels_cannot_be_reused()->void:
	var terrain:CheapTerrain=auto_free(CheapTerrain.new())
	var source:=BUILDER.new(49,12,Vector2.ZERO,terrain._height_at,terrain._terrain_color_at)
	finish(source)
	var full:=build(terrain,49,12,Vector2.ZERO,source.completed_samples())
	assert_int(full.reused_vertices).is_equal(0)
	compare(full,build(terrain,49,12,Vector2.ZERO))

func test_real_distant_world_samples_are_exact_after_pan()->void:
	GameState.reset_for_new_world(873421)
	var terrain:Terrain=auto_free(Terrain.new())
	terrain._configure_seamless_world();terrain._configure_shape();terrain._configure_noise()
	var span:=LOD.bucket(7.0)
	for location:Vector2 in [Vector2(55,0),Vector2(12000,-3800),Vector2(-17400,-7790)]:
		var center:=LOD.center_for(location,span)
		var next:=center+Vector2(span/12.0,span/12.0)
		var source:=build(terrain,49,span,center)
		var moved:=build(terrain,49,span,next,source.completed_samples())
		assert_int(moved.reused_vertices).is_greater(1800)
		compare(moved,build(terrain,49,span,next))

func test_live_refinement_prefers_overlapping_fine_cache_and_rejects_other_seed()->void:
	GameState.reset_for_new_world(873421)
	var terrain:CheapTerrain=auto_free(CheapTerrain.new());add_child(terrain)
	var span:=LOD.bucket(7.0)
	for stage in 3:
		terrain._rebuild_regional_terrain_patch(Vector2.ZERO,span)
		while terrain.terrain_patch_job!=null:terrain._advance_terrain_patch()
	for stage in 3:
		terrain._rebuild_regional_terrain_patch(Vector2(span/12.0,0),span)
		while terrain.terrain_patch_job!=null:terrain._advance_terrain_patch()
	assert_int(terrain.terrain_patch_last_reused_vertices).is_greater(130000)
	assert_int(terrain.terrain_patch_last_sampled_vertices).is_less(15000)
	assert_int(terrain.terrain_patch_cache.size()).is_equal(2)
	GameState.world_seed=271828
	assert_dict(terrain._overlapping_terrain_samples(Vector2.ZERO,span,385)).is_empty()

func test_covered_pan_keeps_fine_mesh_without_rebuilding()->void:
	GameState.reset_for_new_world(873421)
	var terrain:CheapTerrain=auto_free(CheapTerrain.new());add_child(terrain)
	var camera:=Camera3D.new();terrain.add_child(camera);terrain.camera=camera
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2
	camera.position=Vector3(0,5,0);camera.look_at(Vector3.ZERO,Vector3.FORWARD)
	terrain.camera_target=Vector3.ZERO
	var span:=LOD.bucket(7.0)
	for stage in 3:
		terrain._rebuild_regional_terrain_patch(Vector2.ZERO,span)
		while terrain.terrain_patch_job!=null:terrain._advance_terrain_patch()
	var original:MeshInstance3D=terrain.regional_terrain_patch
	camera.position.x+=span/12.0;terrain.camera_target.x+=span/12.0
	assert_bool(terrain._regional_patch_covers_camera()).is_true()
	terrain._rebuild_regional_terrain_patch(Vector2(span/12.0,0),span)
	assert_object(terrain.terrain_patch_job).is_null()
	terrain._advance_terrain_patch()
	assert_object(terrain.regional_terrain_patch).is_same(original)
	while terrain.terrain_patch_job!=null:terrain._advance_terrain_patch()
	assert_int(terrain.regional_patch_resolution).is_equal(385)
