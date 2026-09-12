extends GdUnitTestSuite
const Industry=preload("res://scripts/civilian_industry.gd")
const Production=preload("res://scripts/persistent_production.gd")
const Knowledge=preload("res://scripts/chemical_process_knowledge.gd")
func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(91416);MilitaryCampaign.reset_for_new_world();DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);MilitaryCampaign.set_process(false);CivilizationSystem.set_process(false)
	GameState.elapsed_days=0;GameState.technology_operations.last_day=0
	GameState.population_allocations.Crafting=100;GameState.population_allocations.Logistics=100
func after_test()->void:
	GameState.elapsed_days=0;WorldSimulation.clear()
	GameState.set_process(true);MilitaryCampaign.set_process(true);CivilizationSystem.set_process(true)
func prepare(item:String)->Dictionary:
	var recipe:=Industry.product(item)
	GameState.known_discoveries.append(recipe.gate);GameState.discovery_adoption[recipe.gate]=1.0
	for resource:String in recipe.materials:GameState.resource_stockpiles[resource]=100.0
	for resource:String in recipe.tooling:GameState.resource_stockpiles[resource]=100.0
	GameState.technology_operations.services.electricity=100.0
	assert_bool(MilitaryCampaign.start_production_line(item,1).get("ok",false)).is_true()
	return MilitaryCampaign.equipment_queue.back()
func test_authored_chemical_capabilities_have_real_recipes()->void:
	assert_int(Knowledge.entries().size()).is_equal(3)
	assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(Knowledge.entries(),DiscoverySystem.technology_catalog)).is_empty()
func test_coproducts_arrive_together_only_after_a_complete_batch()->void:
	var job:=prepare("chloralkali_batch")
	Production.advance(MilitaryCampaign,job,2.5)
	for resource:String in ["Chlorine","Hydrogen","Caustic Soda"]:assert_float(float(GameState.resource_stockpiles.get(resource,0))).is_equal(0.0)
	assert_float(float(GameState.resource_stockpiles["Purified Brine"])).is_equal(99.5)
	assert_float(float(GameState.technology_operations.services.electricity)).is_equal(98.0)
	Production.advance(MilitaryCampaign,job,2.5)
	for resource:String in ["Chlorine","Hydrogen","Caustic Soda"]:assert_float(float(GameState.resource_stockpiles[resource])).is_equal(1.0)
	var before:Dictionary=GameState.resource_stockpiles.duplicate(true)
	Production.advance(MilitaryCampaign,job,100)
	assert_dict(GameState.resource_stockpiles).is_equal(before)
func test_no_power_cannot_produce_or_consume_feedstocks()->void:
	var job:=prepare("chloralkali_batch")
	GameState.technology_operations.services.electricity=0.0
	var before:Dictionary=GameState.resource_stockpiles.duplicate(true)
	Production.advance(MilitaryCampaign,job,100)
	assert_dict(GameState.resource_stockpiles).is_equal(before)
	assert_int(int(job.completed)).is_equal(0)
func test_saved_job_metadata_cannot_forge_extra_yields()->void:
	var job:=prepare("chloralkali_batch")
	job["co_products"]={"Steel":1000000.0,"Hydrogen":1000000.0}
	Production.advance(MilitaryCampaign,job,5)
	assert_float(float(GameState.resource_stockpiles.get("Steel",0))).is_equal(0.0)
	assert_float(float(GameState.resource_stockpiles.Hydrogen)).is_equal(1.0)
	assert_bool(Production.product_description("chloralkali_batch").contains("Caustic Soda")).is_true()
func test_partial_work_survives_serialization_without_duplicate_coproducts()->void:
	var job:=prepare("chloralkali_batch")
	Production.advance(MilitaryCampaign,job,2.5)
	var restored:Dictionary=JSON.parse_string(JSON.stringify(job))
	assert_str(Production.validate_saved({"equipment_queue":[restored]})).is_empty()
	Production.advance(MilitaryCampaign,restored,2.5)
	for resource:String in ["Chlorine","Hydrogen","Caustic Soda"]:assert_float(float(GameState.resource_stockpiles[resource])).is_equal(1.0)
func test_actual_brine_and_coproducts_feed_silicon_refining()->void:
	var items:=["purified_brine","chloralkali_batch","hydrogen_chloride","reagent_refined_silicon"]
	for item:String in items:
		var recipe:=Industry.product(item)
		GameState.known_discoveries.append(recipe.gate);GameState.discovery_adoption[recipe.gate]=1.0
		for resource:String in recipe.tooling:GameState.resource_stockpiles[resource]=100.0
	for resource:String in ["Salt","Freshwater","Graphite","Metallurgical Silicon"]:GameState.resource_stockpiles[resource]=100.0
	GameState.technology_operations.services.electricity=100.0
	var job:Dictionary={}
	for item:String in items:
		var target:=2 if item in ["purified_brine","chloralkali_batch"] else 1
		if job.is_empty():
			assert_bool(MilitaryCampaign.start_production_line(item,target).get("ok",false)).is_true()
			job=MilitaryCampaign.equipment_queue.back()
		else:
			assert_bool(MilitaryCampaign.retool_production_line(int(job.id),item).get("ok",false)).is_true()
			MilitaryCampaign.configure_production_line(int(job.id),target,false)
		Production.advance(MilitaryCampaign,job,100)
		assert_int(int(job.completed)).is_equal(target)
	assert_float(float(GameState.resource_stockpiles["Purified Silicon"])).is_equal(1.0)
	assert_float(float(GameState.resource_stockpiles["Caustic Soda"])).is_equal(2.0)
	assert_float(float(GameState.resource_stockpiles.Hydrogen)).is_equal(.75)
	assert_float(float(GameState.resource_stockpiles["Hydrogen Chloride"])).is_equal(.5)
