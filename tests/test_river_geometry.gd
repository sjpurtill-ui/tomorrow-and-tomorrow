extends GdUnitTestSuite
const RIVER:=preload("res://scripts/river_geometry.gd")
func test_draping_samples_intermediate_hills_and_preserves_course()->void:
	var course:Array[Vector3]=[Vector3(0,99,0),Vector3(2,99,0),Vector3(2,99,1)]
	var result:=RIVER.drape_course(course,func(x:float,z:float)->float: return sin(x*PI*0.5)+z,0.25)
	assert_int(result.size()).is_equal(13)
	assert_float(result[4].y).is_equal_approx(1.0,0.00001)
	assert_vector(result[0]).is_equal(Vector3.ZERO)
	assert_vector(result.back()).is_equal(Vector3(2,1,1))
	for index in result.size()-1:
		var a:=Vector2(result[index].x,result[index].z)
		var b:=Vector2(result[index+1].x,result[index+1].z)
		assert_float(a.distance_to(b)).is_less_equal(0.25001)
		assert_bool(is_zero_approx(a.y) or is_equal_approx(a.x,2.0)).is_true()
func test_empty_and_repeated_points_do_not_make_degenerate_reaches()->void:
	var empty:Array[Vector3]=[]
	var height:=func(_x:float,_z:float)->float: return 0.5
	assert_int(RIVER.drape_course(empty,height).size()).is_equal(0)
	var repeated:Array[Vector3]=[Vector3.ZERO,Vector3.ZERO,Vector3(1,0,0)]
	var result:=RIVER.drape_course(repeated,height)
	assert_int(result.size()).is_equal(5)
	for point in result: assert_float(point.y).is_equal(0.5)

func test_headwater_width_grows_by_distance_and_preserves_downstream_width()->void:
	var points:Array[Vector3]=[Vector3.ZERO,Vector3(3,20,4),Vector3(6,-20,8)]
	var factors:=RIVER.headwater_factors(points,10.0)
	assert_float(factors[0]).is_equal_approx(0.12,0.00001)
	assert_float(factors[1]).is_equal_approx(0.56,0.00001)
	assert_float(factors[2]).is_equal(1.0)
	var refined:=RIVER.drape_course(points,func(_x:float,_z:float)->float: return 0.0,0.25)
	var refined_factors:=RIVER.headwater_factors(refined,10.0)
	assert_float(refined_factors[20]).is_equal_approx(factors[1],0.00001)
	assert_float(refined_factors[40]).is_equal(factors[2])
	for index in refined_factors.size()-1:
		assert_float(refined_factors[index]).is_less_equal(refined_factors[index+1])
