extends GdUnitTestSuite
const Route=preload("res://scripts/water_conveyance_route.gd")

func source()->Dictionary:
	return {"id":"revealed_river_1","position":Vector3(0,2,0),"revealed":true}

func test_gravity_requires_complete_revealed_downhill_evidence()->void:
	var result:=Route.survey(source(),Vector3(1,1,0),func(x:float,_z:float)->float:return 2.0-x)
	assert_bool(result.ok).is_true()
	assert_str(result.source_id).is_equal("revealed_river_1")
	var hidden:=source();hidden.revealed=false
	assert_bool(Route.survey(hidden,Vector3(1,1,0),func(_x:float,_z:float)->float:return 1.0).ok).is_false()
	assert_bool(Route.survey(source(),Vector3(1,1,0),Callable()).ok).is_false()

func test_uphill_destination_and_intervening_ridge_block_delivery()->void:
	assert_bool(Route.survey(source(),Vector3(1,3,0),func(x:float,_z:float)->float:return 2.0+x).ok).is_false()
	var ridge:=Route.survey(source(),Vector3(1,1,0),func(x:float,_z:float)->float:return 3.0 if x>.3 and x<.7 else 2.0-x)
	assert_bool(ridge.ok).is_false()
	assert_str(ridge.reason).contains("intervening rise")

func test_missing_samples_and_nonfinite_coordinates_never_become_flat_routes()->void:
	assert_bool(Route.survey(source(),Vector3(INF,0,0),func(_x:float,_z:float)->float:return 0.0).ok).is_false()
	assert_bool(Route.survey(source(),Vector3(1,1,0),func(x:float,_z:float)->float:return NAN if x>.5 else 2.0-x).ok).is_false()
	var result:=Route.survey(source(),Vector3(1,1,0),func(x:float,_z:float)->float:return 2.0-x)
	result.samples.remove_at(4)
	assert_str(Route.gravity_blocker(result)).contains("unsurveyed gap")
