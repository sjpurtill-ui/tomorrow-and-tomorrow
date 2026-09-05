extends GdUnitTestSuite
const SURFACE:=preload("res://scripts/rendered_surface_height.gd")
const BUILDER:=preload("res://scripts/terrain_patch_builder.gd")
func test_samples_match_rays_against_both_mesh_diagonals()->void:
	var builder:=BUILDER.new(3,2.0,Vector2(1,1),func(x:float,z:float)->float:return x*x+z*z+x*z,func(_x:float,_z:float,_h:float)->Color:return Color.WHITE)
	while not builder.advance(100000): pass
	for z in [0.13,0.66,1.14,1.81]:
		for x in [0.22,0.73,1.25,1.77]:
			var point:=Vector2(x,z)
			var expected:=NAN
			for index in range(0,builder.indices.size(),3):
				var hit:Variant=Geometry3D.ray_intersects_triangle(Vector3(x,100,z),Vector3.DOWN,builder.vertices[builder.indices[index]],builder.vertices[builder.indices[index+1]],builder.vertices[builder.indices[index+2]])
				if hit is Vector3:
					expected=hit.y
					break
			assert_bool(is_nan(expected)).is_false()
			var actual:=SURFACE.sample(point,Vector4(1,1,2,3),func(cell:Vector2i)->float:return builder.heights[cell.y*3+cell.x])
			assert_float(actual).is_equal_approx(expected,0.00002)
func test_fixed_diagonal_detail_is_not_bilinear()->void:
	var height:=func(cell:Vector2i)->float:return 4.0 if cell==Vector2i(1,1) else 0.0
	assert_float(SURFACE.sample(Vector2(0.75,0.25),Vector4(0.5,0.5,1,2),height,false)).is_equal(1.0)
	assert_float(SURFACE.sample(Vector2(1,1),Vector4(0.5,0.5,1,2),height,false)).is_equal(4.0)
func test_outside_and_invalid_grids_return_no_surface()->void:
	var height:=func(_cell:Vector2i)->float:return 1.0
	assert_bool(is_nan(SURFACE.sample(Vector2(3,0),Vector4(0,0,2,3),height))).is_true()
	assert_bool(is_nan(SURFACE.sample(Vector2.ZERO,Vector4.ZERO,height))).is_true()
