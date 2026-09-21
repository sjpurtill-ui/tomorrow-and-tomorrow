extends GdUnitTestSuite
func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(41)
	GameState.water_metrics={"intake_ratio":1.0,"source_accessible":true}
func after_test()->void:WorldSimulation.clear()
func allocation(production:float,intake:float=1.0)->Dictionary:
	GameState.simulation_metrics={"food_consumption":120.0,"food_production":production,"food_labor_share":.4,"food_intake_ratio":intake}
	return GovernmentPeopleSystem._allocations_for_focus("research",{},false)
func test_low_local_yield_moves_existing_labor_to_food_without_erasing_other_roles()->void:
	var fertile:=allocation(180)
	var poor:=allocation(90,.75)
	assert_float(float(poor.Food)).is_greater(55.0)
	assert_float(float(poor.Food)).is_greater(float(fertile.Food))
	var sum:=0.0
	for role in poor:sum+=float(poor[role]);assert_float(float(poor[role])).is_greater(0.0)
	assert_float(sum).is_equal_approx(100.0,.00001)
func test_recovery_preserves_subsistence_floor_and_better_yields_release_labor()->void:
	var recovered:=allocation(110)
	var productive:=allocation(220)
	assert_float(float(recovered.Food)).is_greater(44.0)
	assert_float(float(productive.Knowledge)).is_greater(float(recovered.Knowledge))
func test_zero_yield_preserves_essential_work_and_unknown_ledgers_use_existing_policy()->void:
	var zero:=allocation(0,0)
	assert_float(float(zero.Food)).is_less_equal(85.00001)
	assert_float(float(zero.Logistics)).is_greater(0.0)
	GameState.simulation_metrics={}
	var unknown:=GovernmentPeopleSystem._allocations_for_focus("research",{},false)
	assert_float(float(unknown.Food)).is_less(float(zero.Food))
