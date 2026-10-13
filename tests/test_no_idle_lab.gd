extends GdUnitTestSuite
## The microscope lab never ran, yet once Laboratory Notebooks was known it
## held back a quarter of the people set to Knowledge. It is gone: knowing
## the method takes nobody from their work.

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(7311)
	GameState.settlement_site_committed=true
	GameState.population_allocations["Knowledge"]=40

func after_test()->void:
	WorldSimulation.clear()

func test_knowing_the_lab_methods_takes_nobody_from_knowledge_work()->void:
	var before:=float(GameState.effective_workers("Knowledge"))
	assert_float(before).is_greater(0.0)
	for id:String in ["laboratory_notebooks","microscopic_cell_observation","microbial_observation"]:
		GameState.known_discoveries.append(id)
	assert_float(float(GameState.effective_workers("Knowledge"))).is_equal(before)
	assert_bool(GameState.get("microscopy")==null).is_true()
