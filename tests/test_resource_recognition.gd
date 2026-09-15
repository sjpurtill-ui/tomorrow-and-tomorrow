extends GdUnitTestSuite
func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(91421);ResourceSystem.reset_for_new_world();ResourceSystem.initialize();DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.elapsed_days=0;GameState.resource_deposits.clear()
func after_test()->void:
	GameState.elapsed_days=0;WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func deposit(resource:String)->Dictionary:
	var item:=ResourceSystem._deposit(resource,Vector3(1,0,1),.8,1000,0)
	item.clues=1.0;GameState.resource_deposits.append(item)
	return item
func test_ordinary_material_recognition_does_not_wait_for_a_year()->void:
	var coal:=deposit("Coal")
	ResourceSystem.process_day({"origin":Vector3.ZERO,"settled":false})
	assert_str(String(coal.stage)).is_equal("recognized")
func test_campaign_age_cannot_identify_an_ununderstood_special_material()->void:
	var uranium:=deposit("Uranium Ore")
	GameState.elapsed_days=2000000
	ResourceSystem.process_day({"origin":Vector3.ZERO,"settled":false})
	assert_str(String(uranium.stage)).is_equal("unknown")
	assert_float(float(uranium.clues)).is_equal(1.0)
func test_chemical_and_radiation_routes_identify_ore_without_reactor_knowledge()->void:
	for method:String in ["chemical_distillation","radiation_measurement"]:
		GameState.resource_deposits.clear();GameState.known_discoveries.assign(["ore_assaying",method])
		var uranium:=deposit("Uranium Ore")
		ResourceSystem.process_day({"origin":Vector3.ZERO,"settled":false})
		assert_str(String(uranium.stage)).is_equal("recognized")
		assert_bool("reactor_engineering" in GameState.known_discoveries).is_false()
func test_recognition_remains_saved_when_method_knowledge_is_absent()->void:
	var clay:=deposit("Refractory Clay");clay.stage="recognized"
	GameState.population_allocations.Survey=6
	ResourceSystem.process_day({"origin":Vector3.ZERO,"settled":false})
	assert_str(String(clay.stage)).is_equal("recognized")
	assert_float(float(clay.survey)).is_greater(0.0)
func test_every_special_method_has_existing_non_self_gated_foundations()->void:
	for resource:String in ResourceSystem.RECOGNITION_RULES:
		var rule:Dictionary=ResourceSystem.RECOGNITION_RULES[resource]
		for parent:String in preload("res://scripts/technology_requirements.gd").parents(rule):
			var entry:=DiscoverySystem.discovery_definition(parent)
			assert_bool(entry.is_empty()).is_false()
			for needed:Dictionary in entry.get("resource_requirements",[]):assert_str(String(needed.resource)).is_not_equal(resource)
func test_identification_still_needs_accumulated_observation_and_never_awards_stock()->void:
	GameState.known_discoveries.assign(["pit_firing"])
	var clay:=deposit("Refractory Clay");clay.clues=0.0
	ResourceSystem.process_day({"origin":Vector3.ZERO,"settled":false})
	assert_str(String(clay.stage)).is_equal("unknown")
	assert_float(float(clay.clues)).is_greater(0.0)
	assert_float(float(GameState.resource_stockpiles.get("Refractory Clay",0))).is_equal(0.0)

func test_coal_ventilation_can_be_resolved_without_previously_extracting_coal()->void:
	var coal:=deposit("Coal");coal.stage="surveyed";coal.route=1.0
	GameState.population_allocations.Construction=10;GameState.population_allocations.Logistics=4
	assert_array(ResourceSystem._access_blockers(coal,ResourceSystem.catalog["Coal"],{})).contains(["safe underground ventilation is unknown"])
	GameState.known_discoveries.append("mine_airways")
	assert_array(ResourceSystem._access_blockers(coal,ResourceSystem.catalog["Coal"],{})).is_empty()
	GameState.population_allocations.Construction=0
	assert_array(ResourceSystem._access_blockers(coal,ResourceSystem.catalog["Coal"],{})).contains(["mining works have not been developed"])
	var entry:=DiscoverySystem.discovery_definition("mine_airways")
	assert_str(String(entry.resource_requirements[0].stage)).is_equal("surveyed")
func test_aquifer_lifting_uses_drainage_knowledge_but_still_needs_specialists()->void:
	var water:=deposit("Deep Aquifer");water.route=1.0
	GameState.known_discoveries.assign(["well_siting"]);GameState.population_allocations.Knowledge=5
	assert_array(ResourceSystem._access_blockers(water,ResourceSystem.catalog["Deep Aquifer"],{})).contains(["deep lifting machinery is unavailable"])
	GameState.known_discoveries.append("mine_drainage")
	assert_array(ResourceSystem._access_blockers(water,ResourceSystem.catalog["Deep Aquifer"],{})).is_empty()
	GameState.population_allocations.Knowledge=0
	assert_array(ResourceSystem._access_blockers(water,ResourceSystem.catalog["Deep Aquifer"],{})).contains(["specialist knowledge is unavailable"])

func test_flint_access_uses_adopted_flaking_and_actual_extraction_labor()->void:
	var flint:=deposit("Flint");flint.stage="surveyed";flint.route=1.0
	GameState.population_allocations.Extraction=8;GameState.population_allocations.Logistics=8
	var context:={"tools":1.0,"origin":Vector3.ZERO,"settled":false}
	assert_float(ResourceSystem._calculate_access(flint,ResourceSystem.catalog.Flint,context)).is_less(1.0)
	ResourceSystem.process_day(context)
	assert_array(flint.blockers).contains(["Access practice needed: Controlled Flaking"])
	GameState.known_discoveries.append("controlled_flaking");GameState.discovery_adoption.controlled_flaking=0.0
	assert_float(ResourceSystem._calculate_access(flint,ResourceSystem.catalog.Flint,context)).is_less(1.0)
	GameState.discovery_adoption.controlled_flaking=1.0
	assert_float(ResourceSystem._calculate_access(flint,ResourceSystem.catalog.Flint,context)).is_greater_equal(1.0)
	GameState.population_allocations.Extraction=0
	assert_array(ResourceSystem._access_blockers(flint,ResourceSystem.catalog.Flint,context)).contains(["no extraction labor assigned"])
	GameState.population_allocations.Extraction=8
	ResourceSystem.process_day(context)
	assert_str(String(flint.stage)).is_equal("developed")
	assert_float(float(flint.lifetime_extracted)).is_greater(0.0)
	assert_float(float(flint.remaining)).is_less(1000.0)
