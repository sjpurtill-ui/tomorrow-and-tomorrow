extends GdUnitTestSuite
const Knowledge=preload("res://scripts/chemical_process_knowledge.gd")
func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(91416);MilitaryCampaign.reset_for_new_world();DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);MilitaryCampaign.set_process(false);CivilizationSystem.set_process(false)
	GameState.elapsed_days=0;GameState.technology_operations.last_day=0
	GameState.population_allocations.Crafting=100;GameState.population_allocations.Logistics=100
func after_test()->void:
	GameState.elapsed_days=0;WorldSimulation.clear()
	GameState.set_process(true);MilitaryCampaign.set_process(true);CivilizationSystem.set_process(true)
func test_authored_chemical_capabilities_have_real_recipes()->void:
	assert_int(Knowledge.entries().size()).is_equal(4)
	assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(Knowledge.entries(),DiscoverySystem.technology_catalog)).is_empty()
