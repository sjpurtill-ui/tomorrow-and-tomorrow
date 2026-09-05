extends GdUnitTestSuite
const BUILDER:=preload("res://scripts/terrain_patch_builder.gd")
func test_mesh_build_yields_and_preserves_height_color_and_normals()->void:
	var builder:=BUILDER.new(33,4.0,Vector2(8,12),func(x:float,z:float)->float: return x*0.2+z*0.3,func(_x:float,_z:float,_h:float)->Color: return Color(0.2,0.4,0.1))
	assert_bool(builder.advance(1)).is_false()
	assert_int(builder.cursor).is_less(33*33)
	var slices:=1
	while not builder.advance(1000): slices+=1
	var mesh:=builder.commit()
	var arrays:=mesh.surface_get_arrays(0)
	var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	assert_int(vertices.size()).is_equal(1089)
	assert_int(builder.heights.size()).is_equal(vertices.size())
	for index in vertices.size():
		assert_float(builder.heights[index]).is_equal(vertices[index].y)
	assert_int((arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size()).is_equal(32*32*6)
	assert_float(vertices[0].y).is_equal_approx(6.0*0.2+10.0*0.3+0.0006,0.00001)
	var expected:=Vector3(-0.2,1.0,-0.3).normalized()
	assert_float((arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array)[544].distance_to(expected)).is_less(0.001)
	assert_int(slices).is_greater_equal(1)

func test_incremental_and_uninterrupted_builds_are_identical()->void:
	var height:=func(x:float,z:float)->float: return sin(x)*cos(z)
	var tint:=func(_x:float,_z:float,h:float)->Color: return Color(0.2+h*0.1,0.3,0.1)
	var sliced:=BUILDER.new(17,3.0,Vector2.ZERO,height,tint)
	var complete:=BUILDER.new(17,3.0,Vector2.ZERO,height,tint)
	while not sliced.advance(1): pass
	assert_bool(complete.advance(1000000)).is_true()
	assert_bool(sliced.vertices==complete.vertices).is_true()
	assert_bool(sliced.heights==complete.heights).is_true()
	assert_bool(sliced.normals==complete.normals).is_true()
	assert_bool(sliced.indices==complete.indices).is_true()

func test_close_ridge_shading_is_smoothed_without_flattening_geometry()->void:
	var ridge:=func(x:float,_z:float)->float:return -absf(x)*0.2
	var builder:=BUILDER.new(65,0.128,Vector2.ZERO,ridge,func(_x:float,_z:float,_h:float)->Color:return Color.WHITE)
	while not builder.advance(100000): pass
	var row:=32*65
	for index in range(1,64):
		assert_float(builder.normals[row+index].distance_to(builder.normals[row+index-1])).is_less(0.035)
		assert_float(builder.vertices[row+index].y).is_equal_approx(-absf(builder.vertices[row+index].x)*0.2+0.0006,0.000001)
	assert_float(builder.normals[row+8].x).is_less(-0.15)
	assert_float(builder.normals[row+56].x).is_greater(0.15)
