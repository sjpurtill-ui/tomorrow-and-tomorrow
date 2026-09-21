extends GdUnitTestSuite
func before_test()->void:
	GameState.reset_for_new_world(112358)
	CivilizationSystem.reset_for_new_world()
func test_projection_bounds_summary_without_capping_actual_production()->void:
	GameState.simulation_metrics={"material_capacity":1.03,"food_days":35.0}
	var summary:Dictionary=CivilizationSystem.civilizations[0].duplicate(true)
	WorldSimulation.project(summary)
	assert_float(float(summary.production)).is_equal(1.0)
	assert_float(float(summary.food_days)).is_equal(35.0)
	assert_float(float(GameState.simulation_metrics.material_capacity)).is_equal(1.03)
func test_existing_shared_summary_overflow_loads()->void:
	var payload:=CivilizationSystem.export_state()
	payload.civilizations[0]["shared_rules"]=true
	payload.civilizations[0]["production"]=1.03
	assert_bool(CivilizationSystem.import_state(payload).has("error")).is_false()
	assert_float(float(CivilizationSystem.civilizations[0].production)).is_equal(1.0)
func test_negative_summary_remains_invalid()->void:
	var payload:=CivilizationSystem.export_state()
	payload.civilizations[0]["shared_rules"]=true
	payload.civilizations[0]["production"]=-0.1
	assert_bool(CivilizationSystem.import_state(payload).has("error")).is_true()
