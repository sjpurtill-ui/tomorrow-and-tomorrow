extends GdUnitTestSuite
func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(41)
	GameState.water_metrics={"intake_ratio":1.0,"source_accessible":true}
func after_test()->void:WorldSimulation.clear()
func allocation(production:float,intake:float=1.0)->Dictionary:
	GameState.simulation_metrics={"food_consumption":120.0,"food_production":production,"food_labor_share":.4,"food_intake_ratio":intake}
	return GovernmentPeopleSystem._allocations_for_focus("research",{},false)
func test_low_local_yield_moves_existing_labor_to_food_without_erasing_other_roles()->void:
	# The founding era keeps about 62% of labor on food regardless of yield
	# (FOOD_LABOR_FLOOR); a poor site must still move labor above that floor.
	var fertile:=allocation(180)
	var poor:=allocation(60,.75)
	assert_float(float(poor.Food)).is_greater(55.0)
	assert_float(float(poor.Food)).is_greater(float(fertile.Food))
	var sum:=0.0
	for role in poor:sum+=float(poor[role]);assert_float(float(poor[role])).is_greater(0.0)
	assert_float(sum).is_equal_approx(100.0,.00001)
func test_recovery_preserves_subsistence_floor_and_better_yields_release_labor()->void:
	# A site that barely feeds itself needs more than the era floor; better
	# yields release labor back down to the floor.
	var recovered:=allocation(70)
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

## Balance (2026-09-29): planners keep a reserve against the lean season. With
## the same yield, a people whose stores are short plans more food work than
## one whose stores are full, but never aims past what its stores can hold.
func _planned(food_days:float,production:float=110.0)->float:
	GameState.simulation_metrics={"food_consumption":120.0,"food_production":production,"food_labor_share":.5,"food_intake_ratio":1.0,"food_days":food_days,"food_projected_days":food_days}
	return float(GovernmentPeopleSystem._allocations_for_focus("balanced",{},false).Food)

func test_short_stores_plan_more_food_work_than_full_stores()->void:
	GameState.founding_manifest["food_storage_rations"]=120.0*200.0
	var empty:=_planned(0.0)
	var half:=_planned(30.0)
	var full:=_planned(90.0)
	assert_float(empty).is_greater(half)
	assert_float(half).is_greater_equal(full)

func test_the_reserve_target_is_what_the_stores_can_hold()->void:
	# Baskets and bundles for about 10 days: 10 days in store is already all
	# the reserve there is room for, so it plans no more than full stores do.
	GameState.founding_manifest["food_storage_rations"]=120.0*10.0
	assert_float(_planned(9.0)).is_equal_approx(_planned(90.0),0.5)

func test_the_food_floor_sits_below_the_typical_share_so_better_farming_frees_hands()->void:
	GameState.elapsed_days=0.0
	var weights:={"Food":0.0,"Knowledge":38.0}
	GovernmentPeopleSystem._apply_food_labor_floor(weights)
	var share:=float(weights.Food)/(float(weights.Food)+38.0)
	assert_float(share).is_equal_approx(0.62*GovernmentPeopleSystem.FOOD_FLOOR_OF_TYPICAL,0.01)
	assert_float(share).is_less(0.62)

## Guards in proportion to how hard the neighbours press, for every people alike.
func test_hostile_neighbours_draw_more_guards_but_food_comes_first()->void:
	CivilizationSystem.reset_for_new_world(); CivilizationSystem.initialize()
	for civ in CivilizationSystem.civilizations: civ.player_relation.contact_level=0
	var calm:=_planned_split(150.0)
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.player_relation.contact_level=2
	civ.player_relation.border_tension=0.8
	civ.player_relation.opinion=-0.5
	assert_float(GovernmentPeopleSystem.neighbour_threat()).is_greater(0.5)
	var pressed:=_planned_split(150.0)
	assert_float(float(pressed.Defense)).is_greater(float(calm.Defense)+2.0)
	# The food floor still holds its share.
	assert_float(float(pressed.Food)).is_equal_approx(float(calm.Food),0.5)

func _planned_split(production:float)->Dictionary:
	GameState.simulation_metrics={"food_consumption":120.0,"food_production":production,"food_labor_share":.5,"food_intake_ratio":1.0,"food_days":90.0,"food_projected_days":90.0}
	return GovernmentPeopleSystem._allocations_for_focus("balanced",{},false)

## The Food page says why this many hands are on food, from the planners' numbers.
func test_the_food_plan_is_told_from_the_planners_numbers()->void:
	GameState.initialize_population_model()
	GameState.simulation_metrics={"food_consumption":120.0,"food_production":150.0,"food_labor_share":.55,"food_intake_ratio":1.0,"food_days":20.0,"food_projected_days":20.0}
	GameState.founding_manifest["food_storage_rations"]=120.0*200.0
	var said:=GovernmentPeopleSystem.food_plan_words()
	assert_str(said).contains("1.25 times what is eaten")
	assert_str(said).contains("at least %d%% on food" % roundi(GovernmentPeopleSystem.food_floor_share()*100.0))
	assert_str(said).contains("they plan")
	# The same floor the plan applies.
	var weights:={"Food":0.0,"Knowledge":38.0}
	GovernmentPeopleSystem._apply_food_labor_floor(weights)
	assert_float(float(weights.Food)/(float(weights.Food)+38.0)).is_equal_approx(GovernmentPeopleSystem.food_floor_share(),0.0001)
