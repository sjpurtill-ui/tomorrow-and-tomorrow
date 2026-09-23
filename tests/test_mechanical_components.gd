extends GdUnitTestSuite
const Industry=preload("res://scripts/civilian_industry.gd")
const ITEMS=["gear_sets","shaft_bearings","crank_assemblies","flywheels","mechanical_governors","governed_generators"]
func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(91419);MilitaryCampaign.reset_for_new_world();DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.elapsed_days=0;GameState.settlement_site_committed=true;GameState.population_health=1
	GameState.population_allocations.Crafting=100;GameState.population_allocations.Logistics=100
	GameState.simulation_metrics.labor_efficiency=1.0
func after_test()->void:
	GameState.elapsed_days=0;WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func prepare()->void:
	for item:String in ITEMS:
		var recipe:=Industry.product(item)
		GameState.known_discoveries.append(recipe.gate);GameState.discovery_adoption[recipe.gate]=1.0
		for resource:String in recipe.tooling:GameState.resource_stockpiles[resource]=100.0
	for resource:String in ["Steel","Refined Copper","Wrought Iron","Graphite","Copper Wire","Insulated Cable","Pressure Vessels"]:GameState.resource_stockpiles[resource]=100.0
func test_missing_component_blocks_assembly_without_consuming_other_materials()->void:
	prepare()
	assert_bool(MilitaryCampaign.start_production_line("governed_generators",1).has("error")).is_true()
	assert_float(float(GameState.resource_stockpiles["Copper Wire"])).is_equal(100.0)
	assert_float(float(GameState.resource_stockpiles.Steel)).is_equal(100.0)
