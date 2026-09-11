extends GdUnitTestSuite
class DockHud extends Control:
	func request_immediate_dock_refresh()->void:pass
class DockTerrain extends Node:
	var result:Dictionary={}
	func _report_military_action(value:Dictionary)->void:result=value

const Industry=preload("res://scripts/civilian_industry.gd")
const Production=preload("res://scripts/persistent_production.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(7511);MilitaryCampaign.reset_for_new_world();DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);MilitaryCampaign.set_process(false);CivilizationSystem.set_process(false)
	GameState.resource_stockpiles["Timber"]=100.0
	GameState.population_allocations["Crafting"]=100
	GameState.population_allocations["Logistics"]=100
	GameState.population_health=1.0
	GameState.simulation_metrics["labor_efficiency"]=1.0
	GameState.settlement_plots.clear()
	GameState.settlement_plots.append({"land_use":"workshop","worker_capacity":100,"condition":1.0,"status":"active","damage":{}})
	MilitaryCampaign.military_inventory["improvised"]=0


func after_test()->void:
	GameState.elapsed_days=0
	WorldSimulation.clear()
	GameState.set_process(true);MilitaryCampaign.set_process(true);CivilizationSystem.set_process(true)

func prepare(item:String)->void:
	var recipe:=Industry.product(item)
	GameState.known_discoveries.append(recipe.gate);GameState.discovery_adoption[recipe.gate]=1.0
	for resource:String in recipe.materials:GameState.resource_stockpiles[resource]=100.0
	for resource:String in recipe.tooling:GameState.resource_stockpiles[resource]=100.0
	GameState.resource_stockpiles[recipe.output]=0.0

func test_setup_and_fractional_batches_conserve_real_inputs()->void:
	prepare("glass_batch")
	var before:=GameState.resource_stockpiles.duplicate(true)
	assert_bool(MilitaryCampaign.start_production_line("glass_batch",1).get("ok",false)).is_true()
	var job:Dictionary=MilitaryCampaign.equipment_queue.back()
	assert_float(float(GameState.resource_stockpiles.Stone)).is_equal(float(before.Stone)-12)
	assert_float(float(GameState.resource_stockpiles["Fine Sand"])).is_equal(100.0)
	Production.advance(MilitaryCampaign,job,1.5)
	assert_float(float(GameState.resource_stockpiles.Glass)).is_equal(0.0)
	assert_float(float(GameState.resource_stockpiles["Fine Sand"])).is_equal(99.0)
	Production.advance(MilitaryCampaign,job,1.5)
	assert_float(float(GameState.resource_stockpiles.Glass)).is_equal(1.0)
	assert_float(float(GameState.resource_stockpiles["Fine Sand"])).is_equal(98.0)
	Production.advance(MilitaryCampaign,job,100)
	assert_float(float(GameState.resource_stockpiles.Glass)).is_equal(1.0)
	assert_bool(MilitaryCampaign.military_inventory.has("glass_batch")).is_false()

func test_missing_tooling_or_knowledge_does_not_debit_stock()->void:
	prepare("glass_batch");GameState.resource_stockpiles.Clay=0.0
	var before:=GameState.resource_stockpiles.duplicate(true)
	assert_bool(MilitaryCampaign.start_production_line("glass_batch",1).has("error")).is_true()
	assert_dict(GameState.resource_stockpiles).is_equal(before)
	GameState.resource_stockpiles.Clay=100.0;GameState.known_discoveries.clear()
	assert_bool(MilitaryCampaign.start_production_line("glass_batch",1).has("error")).is_true()
	assert_array(MilitaryCampaign.equipment_queue).is_empty()

func test_intermediate_output_supplies_downstream_recipe()->void:
	prepare("refined_copper");prepare("copper_wire")
	GameState.resource_stockpiles["Refined Copper"]=0.0
	assert_bool(MilitaryCampaign.start_production_line("copper_wire",1).has("error")).is_true()
	assert_bool(MilitaryCampaign.start_production_line("refined_copper",1).get("ok",false)).is_true()
	var copper:Dictionary=MilitaryCampaign.equipment_queue.back()
	Production.advance(MilitaryCampaign,copper,3.0)
	assert_bool(MilitaryCampaign.retool_production_line(int(copper.id),"copper_wire").get("ok",false)).is_true()
	var wire:Dictionary=MilitaryCampaign.equipment_queue.back()
	Production.advance(MilitaryCampaign,wire,2.0)
	assert_float(float(GameState.resource_stockpiles["Refined Copper"])).is_equal(0.0)
	assert_float(float(GameState.resource_stockpiles["Copper Wire"])).is_equal(1.0)

func test_retool_shortage_preserves_existing_line_and_progress()->void:
	prepare("glass_batch");prepare("copper_wire")
	assert_bool(MilitaryCampaign.start_production_line("glass_batch",1).get("ok",false)).is_true()
	var job:Dictionary=MilitaryCampaign.equipment_queue.back()
	Production.advance(MilitaryCampaign,job,1.0)
	GameState.resource_stockpiles["Wrought Iron"]=0.0
	var before:=job.duplicate(true)
	assert_bool(MilitaryCampaign.retool_production_line(int(job.id),"copper_wire").has("error")).is_true()
	assert_dict(job).is_equal(before)

func test_saved_civilian_recipe_rejects_forged_free_materials()->void:
	prepare("glass_batch")
	assert_bool(MilitaryCampaign.start_production_line("glass_batch",1).get("ok",false)).is_true()
	var payload:Dictionary={"equipment_queue":JSON.parse_string(JSON.stringify(MilitaryCampaign.equipment_queue))}
	assert_str(Production.validate_saved(payload)).is_empty()
	payload.equipment_queue[0].materials={}
	assert_bool(Production.validate_saved(payload).is_empty()).is_false()

func test_closed_line_keeps_goods_and_does_not_refund_tooling()->void:
	prepare("glass_batch")
	assert_bool(MilitaryCampaign.start_production_line("glass_batch",1).get("ok",false)).is_true()
	var job:Dictionary=MilitaryCampaign.equipment_queue.back()
	Production.advance(MilitaryCampaign,job,3.0)
	var stocks:=GameState.resource_stockpiles.duplicate(true)
	MilitaryCampaign.cancel_equipment_job(int(job.id))
	assert_dict(GameState.resource_stockpiles).is_equal(stocks)

func test_products_are_visible_only_after_their_own_research()->void:
	prepare("glass_batch")
	var choices:=Production.available_products(MilitaryCampaign)
	assert_bool("glass_batch" in choices).is_true()
	assert_bool("electrical_generator" in choices).is_false()
	assert_str(Production.product_description("glass_batch")).contains("Line setup consumes")
