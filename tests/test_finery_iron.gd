extends GdUnitTestSuite
const K=preload("res://scripts/finery_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("potter",120)
func after_test()->void:WorldSimulation.clear()
func setup()->void:
	var state=WorldSimulation.state;state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0;state.population_allocations.Crafting=20
	for resource:String in ["Clay","Stone","Timber","Coal","Iron Ore","Limestone","Refractory Bricks","Wrought Iron"]:state.resource_stockpiles[resource]=200.0
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func test_indirect_route_consumes_fuel_ore_and_refining_loss()->void:
	WorldSimulation.scoped("potter",func()->void:
		setup();var state=WorldSimulation.state
		var plan:={"metallurgical_coke":2,"blast_pig_iron":2,"finery_iron":1}
		for item:String in plan:
			var recipe:=I.product(item);learn(recipe.gate)
			assert_bool(WorldSimulation.military.start_production_line(item,int(state.resource_stockpiles.get(recipe.output,0.0)-recipe.tooling.get(recipe.output,0.0))+int(plan[item])).get("ok",false)).is_true()
			var job:Dictionary=WorldSimulation.military.equipment_queue.back()
			P.advance(WorldSimulation.military,job,float(recipe.days)*int(plan[item]))
			assert_int(int(job.completed)).is_equal(int(plan[item]))
			WorldSimulation.military.cancel_equipment_job(int(job.id))
		assert_float(float(state.resource_stockpiles["Coal"])).is_equal(196.0)
		assert_float(float(state.resource_stockpiles["Coke"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Iron Ore"])).is_equal(194.0)
		assert_float(float(state.resource_stockpiles["Pig Iron"])).is_equal_approx(.8,.000001)
		assert_float(float(state.resource_stockpiles["Wrought Iron"])).is_equal(195.0)
		assert_float(float(state.resource_stockpiles["Refractory Bricks"])).is_equal(188.0)
		assert_float(float(state.resource_stockpiles["Timber"])).is_equal(194.0)
	)
func test_missing_coke_blocks_blast_but_bloomery_remains_available()->void:
	WorldSimulation.scoped("potter",func()->void:
		setup();learn("blast_furnace");learn("bloomery_smelting")
		assert_array(P.startup_blockers(WorldSimulation.military,"blast_pig_iron")).is_not_empty()
		assert_array(P.startup_blockers(WorldSimulation.military,"wrought_iron")).is_empty()
		assert_array(P.startup_blockers(WorldSimulation.military,"finery_iron")).is_not_empty()
		learn("finery_forges")
		assert_array(P.startup_blockers(WorldSimulation.military,"finery_iron")).is_not_empty()
	)
func test_discovery_contracts_remove_unpaid_furnace_bonuses()->void:
	WorldSimulation.scoped("potter",func()->void:
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		for entry:Dictionary in preload("res://scripts/resource_knowledge_catalog.gd").entries():
			if entry.id in ["coke_firing","blast_furnace"]:
				assert_dict(entry.effects).is_empty()
				assert_str(I.product(entry.production_items[0]).gate).is_equal(entry.id)
		assert_int(int(K.entries()[0].day)).is_equal(0)
	)
