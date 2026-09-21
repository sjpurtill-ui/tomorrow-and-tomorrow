extends GdUnitTestSuite
const C=preload("res://scripts/civilization_controller.gd")
func before_test()->void:
	GameState.reset_for_new_world(31415)
	GameState.resource_stockpiles={"Timber":1000.0,"Stone":1000.0,"Fiber Plants":1000.0,"Clay":1000.0}
func _site(food:float,wood:float)->Dictionary:
	return {"environment_profile":{"food_potential":food,"water_access":1.0,"woodland":.9},"woodland_catchment":{"density":wood}}
func _plan()->Dictionary:
	return {"personality":{"empathy":.5,"discipline":.5,"openness":.5}}
func test_shortage_changes_the_preferred_settlement_opportunity()->void:
	var farms:=_site(.9,0)
	var woodland:=_site(.4,.4)
	assert_float(C.expansion_site_value(farms,_plan())).is_greater(C.expansion_site_value(woodland,_plan()))
	GameState.resource_stockpiles.Timber=0.0
	assert_float(C.expansion_site_value(woodland,_plan())).is_greater(C.expansion_site_value(farms,_plan()))
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(0.0)
func test_measured_bare_ground_does_not_inherit_macro_woodland()->void:
	GameState.resource_stockpiles.Timber=0.0
	var bare:=_site(.6,0)
	var wooded:=_site(.6,.5)
	assert_float(C.expansion_site_value(wooded,_plan())).is_greater(C.expansion_site_value(bare,_plan()))
	bare.environment_profile.woodland=0.0
	assert_float(C.expansion_site_value(bare,_plan())).is_equal(C.expansion_site_value(_site(.6,0),_plan()))

func test_search_considers_nearby_sites_without_growing_with_population()->void:
	var points:=C.expansion_candidates(Vector2(100,200),40.0)
	assert_int(points.size()).is_equal(48)
	assert_float(points[0].distance_to(Vector2(100,200))).is_equal_approx(20.0,.001)
	assert_float(points[16].distance_to(Vector2(100,200))).is_equal_approx(40.0,.001)
	assert_float(points[32].distance_to(Vector2(100,200))).is_equal_approx(60.0,.001)
func test_unworkable_trace_cover_does_not_win_a_shortage_bonus()->void:
	GameState.resource_stockpiles.Timber=0.0
	assert_float(C.expansion_site_value(_site(.6,.01),_plan())).is_equal(C.expansion_site_value(_site(.6,0),_plan()))
