extends GdUnitTestSuite
const K=preload("res://scripts/refractory_ceramics_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("potter",115)
func after_test()->void:WorldSimulation.clear()
func setup()->void:
	var state=WorldSimulation.state;state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0;state.population_allocations.Crafting=20
	for resource:String in ["Clay","Stone","Timber","Freshwater","Fine Sand","Limestone"]:state.resource_stockpiles[resource]=200.0
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func test_authored_branch_has_valid_distinct_production_contracts()->void:
	WorldSimulation.scoped("potter",func()->void:
		assert_int(K.entries().size()).is_equal(6)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		for entry:Dictionary in K.entries():
			assert_int(int(entry.day)).is_equal(0);assert_dict(entry.effects).is_empty()
			assert_str(I.product(entry.production_items[0]).gate).is_equal(entry.id)
	)
func test_full_preparation_chain_supplies_glass_and_consumes_pot_wear()->void:
	WorldSimulation.scoped("potter",func()->void:
		setup();var state=WorldSimulation.state
		var plan:={"prepared_clay":18,"ceramic_grog":5,"refractory_clay":9,"refractory_brick":8,"ceramic_crucible":1,"crucible_glass":1}
		for item:String in plan:
			var recipe:=I.product(item);learn(recipe.gate)
			assert_bool(WorldSimulation.military.start_production_line(item,int(plan[item])).get("ok",false)).is_true()
			var job:Dictionary=WorldSimulation.military.equipment_queue.back()
			P.advance(WorldSimulation.military,job,float(recipe.days)*int(plan[item]))
			assert_int(int(job.completed)).is_equal(int(plan[item]))
			WorldSimulation.military.cancel_equipment_job(int(job.id))
		assert_float(float(state.resource_stockpiles["Glass"])).is_equal(1.0)
		assert_float(float(state.resource_stockpiles["Ceramic Crucibles"])).is_equal_approx(.95,.000001)
		assert_float(float(state.resource_stockpiles["Refractory Bricks"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Prepared Clay"])).is_equal(0.0)
	)
func test_unavailable_pots_block_new_method_while_original_glass_remains_viable()->void:
	WorldSimulation.scoped("potter",func()->void:
		setup();learn("crucible_glass_melting");learn("glassmaking")
		WorldSimulation.state.resource_stockpiles["Refractory Bricks"]=8.0
		assert_array(P.startup_blockers(WorldSimulation.military,"crucible_glass")).is_not_empty()
		assert_array(P.startup_blockers(WorldSimulation.military,"glass_batch")).is_empty()
		assert_bool(WorldSimulation.military.start_production_line("glass_batch",1).get("ok",false)).is_true()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back();P.advance(WorldSimulation.military,job,3.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Glass"])).is_equal(1.0)
	)
