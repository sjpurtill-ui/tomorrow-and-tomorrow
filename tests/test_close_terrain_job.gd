extends GdUnitTestSuite
const JOB:=preload("res://scripts/close_terrain_job.gd")
func test_sliced_and_full_sampling_produce_identical_meshes()->void:
	var sampler:=func(x:float,z:float)->Array:return [x*x-z*0.3,Vector3.UP,Color(0.2,0.4,0.1,0.3)]
	var sliced:=JOB.new(33,0.42,Vector2(3,4),sampler)
	var full:=JOB.new(33,0.42,Vector2(3,4),sampler)
	assert_bool(sliced.advance(1)).is_false()
	assert_int(sliced.cursor).is_less(1089)
	while not sliced.advance(1): pass
	while not full.advance(1000000): pass
	assert_bool(sliced.vertices==full.vertices).is_true()
	assert_bool(sliced.normals==full.normals).is_true()
	assert_bool(sliced.colors==full.colors).is_true()
	var arrays:=sliced.commit().surface_get_arrays(0)
	assert_int(arrays[Mesh.ARRAY_VERTEX].size()).is_equal(1089)
	assert_int(arrays[Mesh.ARRAY_INDEX].size()).is_equal(6144)
	assert_float(sliced.vertices[0].z).is_equal_approx(3.79,0.00001)
	assert_float(sliced.vertices[1088].z).is_equal_approx(4.21,0.00001)
