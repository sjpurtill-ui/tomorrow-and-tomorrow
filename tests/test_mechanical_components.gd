extends GdUnitTestSuite
const Industry=preload("res://scripts/civilian_industry.gd")
const Production=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
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
func test_components_form_a_consumed_chain_into_a_commissionable_generator()->void:
	prepare()
	var job:Dictionary={}
	for item:String in ITEMS:
		var target:=2 if item=="shaft_bearings" else 1
		if job.is_empty():
			assert_bool(MilitaryCampaign.start_production_line(item,target).get("ok",false)).is_true()
			job=MilitaryCampaign.equipment_queue.back()
		else:
			assert_bool(MilitaryCampaign.retool_production_line(int(job.id),item).get("ok",false)).is_true()
			MilitaryCampaign.configure_production_line(int(job.id),target,false)
		Production.advance(MilitaryCampaign,job,100)
		assert_int(int(job.completed)).override_failure_message(item).is_equal(target)
	for resource:String in ["Gear Sets","Shaft Bearings","Crank Assemblies","Flywheels","Mechanical Governors"]:assert_float(float(GameState.resource_stockpiles[resource])).is_equal(0.0)
	assert_float(float(GameState.resource_stockpiles["Electrical Generators"])).is_equal(1.0)
	assert_bool(Ops.install("steam_generator").has("error")).is_true()
	GameState.known_discoveries.append("steam_propulsion");GameState.discovery_adoption.steam_propulsion=1.0
	assert_bool(Ops.install("steam_generator").get("ok",false)).is_true()
	assert_float(float(GameState.resource_stockpiles["Electrical Generators"])).is_equal(0.0)
	assert_int(int(Ops.data().plants.steam_generator.installed)).is_equal(0)
func test_missing_component_blocks_assembly_without_consuming_other_materials()->void:
	prepare()
	assert_bool(MilitaryCampaign.start_production_line("governed_generators",1).has("error")).is_true()
	assert_float(float(GameState.resource_stockpiles["Copper Wire"])).is_equal(100.0)
	assert_float(float(GameState.resource_stockpiles.Steel)).is_equal(100.0)
func test_existing_direct_generator_workshop_remains_available()->void:
	prepare()
	assert_bool(MilitaryCampaign.start_production_line("electrical_generator",1).get("ok",false)).is_true()
	var job:Dictionary=MilitaryCampaign.equipment_queue.back()
	Production.advance(MilitaryCampaign,job,20)
	assert_int(int(job.completed)).is_equal(1)
func test_component_knowledge_does_not_create_stocks_and_saved_work_uses_real_recipe()->void:
	prepare()
	for item:String in ITEMS:assert_float(float(GameState.resource_stockpiles.get(Industry.product(item).output,0))).is_equal(0.0)
	assert_bool(MilitaryCampaign.start_production_line("gear_sets",1).get("ok",false)).is_true()
	var job:Dictionary=MilitaryCampaign.equipment_queue.back()
	Production.advance(MilitaryCampaign,job,2.5)
	var saved:Dictionary=JSON.parse_string(JSON.stringify(job))
	assert_str(Production.validate_saved({"equipment_queue":[saved]})).is_empty()
	assert_float(float(GameState.resource_stockpiles["Gear Sets"])).is_equal(0.0)
	Production.advance(MilitaryCampaign,saved,2.5)
	assert_float(float(GameState.resource_stockpiles["Gear Sets"])).is_equal(1.0)
