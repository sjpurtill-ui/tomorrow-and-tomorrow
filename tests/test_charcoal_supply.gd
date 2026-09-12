extends GdUnitTestSuite
const K=preload("res://scripts/charcoal_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("potter",121)
func after_test()->void:WorldSimulation.clear()
func setup()->void:
	var state=WorldSimulation.state;state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0;state.population_allocations.Crafting=20
	for resource:String in ["Clay","Stone","Timber","Coal","Iron Ore","Limestone","Refractory Bricks","Wrought Iron"]:state.resource_stockpiles[resource]=200.0
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func test_charcoal_can_be_manufactured_then_consumed_by_a_bloomery()->void:
	WorldSimulation.scoped("potter",func()->void:
		setup();var state=WorldSimulation.state;state.resource_stockpiles["Wrought Iron"]=0.0
		for item:String in ["wood_charcoal","charged_bloomery_iron"]:
			var recipe:=I.product(item);learn(recipe.gate)
			assert_bool(WorldSimulation.military.start_production_line(item,1).get("ok",false)).is_true()
			var job:Dictionary=WorldSimulation.military.equipment_queue.back()
			P.advance(WorldSimulation.military,job,float(recipe.days))
			assert_int(int(job.completed)).is_equal(1)
			WorldSimulation.military.cancel_equipment_job(int(job.id))
		assert_float(float(state.resource_stockpiles["Charcoal"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Wrought Iron"])).is_equal(1.0)
		assert_float(float(state.resource_stockpiles["Timber"])).is_equal(196.0)
		assert_float(float(state.resource_stockpiles["Iron Ore"])).is_equal(197.0)
	)
func test_retort_pays_advanced_tooling_and_reduces_wood_per_batch()->void:
	WorldSimulation.scoped("potter",func()->void:
		setup();learn("charcoal_retorts")
		assert_array(P.startup_blockers(WorldSimulation.military,"retort_charcoal")).is_not_empty()
		WorldSimulation.state.resource_stockpiles["Pressure Vessels"]=2.0
		assert_bool(WorldSimulation.military.start_production_line("retort_charcoal",1).get("ok",false)).is_true()
		P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue.back(),2.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Charcoal"])).is_equal(1.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Timber"])).is_equal(197.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Pressure Vessels"])).is_equal(0.0)
	)
func test_charcoal_furnace_research_has_no_coal_dependency_but_needs_fuel()->void:
	WorldSimulation.scoped("potter",func()->void:
		setup();var state=WorldSimulation.state;state.resource_deposits.clear();state.resource_stockpiles["Coal"]=0.0
		state.known_discoveries.assign(["rope_rigging","charcoal","refractory_brick_firing","bloomery_smelting"])
		var discovery=WorldSimulation.discovery;var entry:=discovery.discovery_definition("blast_furnace")
		assert_bool(discovery._discovery_is_eligible(entry,0)).is_false()
		for row:Dictionary in discovery.technology_tree():
			if row.id=="blast_furnace":assert_str("; ".join(PackedStringArray(row.missing))).contains("10.0 Charcoal in stores")
		state.resource_stockpiles["Charcoal"]=9.0
		assert_bool(discovery._discovery_is_eligible(entry,0)).is_false()
		state.resource_stockpiles["Charcoal"]=10.0
		assert_bool(discovery._discovery_is_eligible(entry,0)).is_true()
		assert_str(String(preload("res://scripts/knowledge_pathways.gd").chosen(entry,0).id)).is_equal("charcoal_furnace")
		assert_dict(preload("res://scripts/research_materials.gd").needed("blast_furnace")).is_empty()
		assert_float(discovery._resource_evidence(entry.resource_requirements)).is_greater_equal(.82)
		learn("blast_furnace")
		assert_bool(WorldSimulation.military.start_production_line("charcoal_pig_iron",1).get("ok",false)).is_true()
		P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue.back(),3.0)
		assert_float(float(state.resource_stockpiles["Pig Iron"])).is_equal(1.0)
		assert_float(float(state.resource_stockpiles["Coal"])).is_equal(0.0)
		state.resource_stockpiles["Charcoal"]=10.0
		state.known_discoveries.erase("refractory_brick_firing")
		assert_bool(discovery._discovery_is_eligible(entry,0)).is_false()
	)
func test_authored_contracts_and_missing_fuel_are_explicit()->void:
	WorldSimulation.scoped("potter",func()->void:
		setup();assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		learn("blast_furnace");learn("finery_forges");learn("bloomery_charge_control")
		for item:String in ["charcoal_pig_iron","charcoal_finery_iron","charged_bloomery_iron"]:
			assert_array(P.startup_blockers(WorldSimulation.military,item)).is_not_empty()
		for entry:Dictionary in K.entries():assert_int(int(entry.day)).is_equal(0)
	)
