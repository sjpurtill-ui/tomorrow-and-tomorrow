extends GdUnitTestSuite
## codex/map-speed: the streamed patch reads the per-seed macro rasters as
## the planet layer does, so its painting's relief cues and the chart's
## landform near its edge run there too.
const Renderer:=preload("res://scripts/local_terrain.gd")
const RENDER:=preload("res://scripts/terrain_macro_render.gd")


func before_test()->void:
	GameState.reset_for_new_world(184271)
	PlanetEnvironment.reset_for_new_world()


func _raster(level:int,origin:Vector2)->RefCounted:
	var raster:=RENDER.Raster.new()
	raster.level=level;raster.seed_value=GameState.world_seed
	raster.origin=origin;raster.cell=Vector2(7,7);raster.columns=4;raster.rows=4
	for i in 16:
		raster.heights.append(float(i)*0.1);raster.seasons.append(10.0)
		raster.colors.append(Color(0.4,0.5,0.3,0.2).to_rgba32());raster.fields.append(Color(0.5,0.5,0.4,0.3).to_rgba32())
	return raster


func test_streamed_patches_read_the_macro_rasters()->void:
	var world:Node3D=auto_free(Renderer.new())
	world._configure_seamless_world();world._configure_shape();world._configure_noise()
	world.macro_render.levels[0]=_raster(0,Vector2(-20,-20))
	world._sync_coast_mask()
	# A patch installed after the raster landed carries it.
	var heights:=PackedFloat32Array();heights.resize(33*33)
	world._install_regional_patch({"mesh":ArrayMesh.new(),"center":Vector2.ZERO,"span":8.0,"resolution":33,"heights":heights})
	var material:=world.regional_terrain_patch.material_override as ShaderMaterial
	assert_object(material.get_shader_parameter("coast_level0")).is_not_null()
	assert_that(material.get_shader_parameter("coast_grid0")).is_equal(Vector4(-20,-20,7,7))
	assert_object(material.get_shader_parameter("coast_color0")).is_not_null()
	assert_object(material.get_shader_parameter("coast_fields0")).is_not_null()
	# A raster that lands later reaches the patch already shown.
	world.macro_render.levels[1]=_raster(1,Vector2(-10,-10))
	world._sync_coast_mask()
	assert_that(material.get_shader_parameter("coast_grid1")).is_equal(Vector4(-10,-10,7,7))
	assert_object(material.get_shader_parameter("coast_level1")).is_not_null()
