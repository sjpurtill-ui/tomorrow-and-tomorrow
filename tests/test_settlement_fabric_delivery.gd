extends GdUnitTestSuite
const Fabric=preload("res://scripts/settlement_fabric_operations.gd")
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("fabric_delivery",1301)
func after_test()->void:
	WorldSimulation.clear()
func test_shared_method_definitions_do_not_cache_a_societys_eligibility()->void:
	var known:Array=["seasonal_patterns"]
	assert_bool(Fabric.foundations_met("building_shading_design",known)).is_false()
	known.append("geometric_survey")
	assert_bool(Fabric.foundations_met("building_shading_design",known)).is_true()
	assert_bool(Fabric.foundations_met("building_shading_design",[])).is_false()
	known.erase("seasonal_patterns")
	assert_bool(Fabric.foundations_met("building_shading_design",known)).is_false()
	assert_bool(Fabric.foundations_met("unknown_method",known)).is_false()
