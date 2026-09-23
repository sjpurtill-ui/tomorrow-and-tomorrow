extends GdUnitTestSuite
const K=preload("res://scripts/microprogramming_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("computer",116)
func after_test()->void:WorldSimulation.clear()
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func setup()->void:
	var state=WorldSimulation.state;state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0;state.population_allocations.Crafting=20
func test_distinct_causal_contracts_and_existing_controller_alternative()->void:
	WorldSimulation.scoped("computer",func()->void:
		setup();assert_int(K.entries().size()).is_equal(4)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		for entry:Dictionary in K.entries():
			assert_int(int(entry.day)).is_equal(0);assert_dict(entry.effects).is_empty()
			assert_str(I.product(entry.production_items[0]).gate).is_equal(entry.id)
		assert_str(I.product("programmable_controllers").output).is_equal(I.product("microprogrammed_controller").output)
		assert_str(I.product("programmable_controllers").gate).is_equal("stored_program_control")
	)
