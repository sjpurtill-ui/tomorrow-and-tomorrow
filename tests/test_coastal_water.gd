extends GdUnitTestSuite
const BUILDER:=preload("res://scripts/terrain_patch_builder.gd")
class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
func fixture()->Terrain:
	var terrain:Terrain=auto_free(Terrain.new());add_child(terrain)
	terrain._build_water()
	return terrain
func patch(center:Vector2,resolution:int)->Dictionary:
	var builder:=BUILDER.new(resolution,2.0,center,func(x:float,z:float)->float:return x*.02+z*.03,func(_x:float,_z:float,_h:float)->Color:return Color.WHITE)
	while not builder.advance(100000):pass
	return {"mesh":builder.commit(),"center":center,"span":2.0,"resolution":resolution,"heights":builder.heights}
func test_ocean_does_not_inundate_positive_elevation_coastal_ground()->void:
	var terrain:=fixture()
	assert_float(terrain.ocean_surface.position.y).is_equal(terrain.SEA_LEVEL)
	assert_float(terrain.ocean_surface.position.y).is_less(.005)
	assert_float(terrain.coastal_water_material.get_shader_parameter("sea_level")).is_equal(terrain.ocean_surface.position.y)
func test_completed_and_cached_meshes_rebind_the_same_visible_bed()->void:
	var terrain:=fixture();var first:=patch(Vector2.ZERO,5);var second:=patch(Vector2(2,1),7)
	for completed:Dictionary in [first,second,first]:
		terrain._install_regional_patch(completed)
		var texture:ImageTexture=terrain.coastal_water_material.get_shader_parameter("terrain_heights")
		assert_object(texture).is_same(terrain.river_terrain_height_texture)
		assert_int(texture.get_width()).is_equal(completed.resolution)
		assert_bool(texture.get_image().get_data()==completed.heights.to_byte_array()).is_true()
		assert_vector(terrain.coastal_water_material.get_shader_parameter("terrain_grid")).is_equal(terrain.river_terrain_grid)
		assert_vector(terrain.coastal_water_surface.position).is_equal(Vector3(completed.center.x,0,completed.center.y))
		assert_vector(terrain.coastal_water_surface.mesh.size).is_equal(Vector2.ONE*completed.span)
		assert_int(terrain.ocean_surface.get_child_count()).is_equal(1)
		assert_vector(terrain.ocean_surface.material_override.get_shader_parameter("terrain_grid")).is_equal(terrain.river_terrain_grid)
func test_water_created_after_patch_uses_existing_bed_and_fog_registry()->void:
	var terrain:Terrain=auto_free(Terrain.new());add_child(terrain)
	terrain._install_regional_patch(patch(Vector2(3,2),5));terrain._build_water()
	assert_object(terrain.coastal_water_material.get_shader_parameter("terrain_heights")).is_same(terrain.river_terrain_height_texture)
	assert_bool(terrain.coastal_water_material in terrain.terrain_fog_materials).is_true()
