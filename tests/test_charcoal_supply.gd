extends GdUnitTestSuite
const K=preload("res://scripts/charcoal_knowledge.gd")
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
func test_charcoal_furnace_research_has_no_coal_dependency_but_needs_fuel()->void:
	WorldSimulation.scoped("potter",func()->void:
		setup();var state=WorldSimulation.state;state.resource_deposits.clear();state.resource_stockpiles["Coal"]=0.0
		state.known_discoveries.assign(["rope_rigging","charcoal","refractory_brick_firing","bloomery_smelting"])
		var discovery=WorldSimulation.discovery;var entry:=discovery.discovery_definition("blast_furnace")
		# 1200-1800 design: water-blown stacks and liquid iron are the common
		# foundations; the charcoal furnace remains an authored route.
		state.known_discoveries.append_array(entry.requires_all)
		var day:=int(ceil(discovery.research_600_earliest_year(entry)*365.0)) # once its era has come
		assert_bool(discovery._discovery_is_eligible(entry,day)).is_false()
		for row:Dictionary in discovery.technology_tree():
			if row.id=="blast_furnace":assert_str("; ".join(PackedStringArray(row.missing))).contains("10.0 Charcoal in stores")
		state.resource_stockpiles["Charcoal"]=9.0
		assert_bool(discovery._discovery_is_eligible(entry,day)).is_false()
		state.resource_stockpiles["Charcoal"]=10.0
		assert_bool(discovery._discovery_is_eligible(entry,day)).is_true()
		assert_str(String(preload("res://scripts/knowledge_pathways.gd").chosen(entry,day).id)).is_equal("charcoal_furnace")
		assert_dict(preload("res://scripts/research_materials.gd").needed("blast_furnace")).is_empty()
		assert_float(discovery._resource_evidence(entry.resource_requirements)).is_greater_equal(.82)
		state.known_discoveries.erase("refractory_brick_firing")
		assert_str(String(preload("res://scripts/knowledge_pathways.gd").chosen(entry,day).id)).is_not_equal("charcoal_furnace")
		state.known_discoveries.erase("liquid_iron_furnaces")
		assert_bool(discovery._discovery_is_eligible(entry,day)).is_false()
	)
func test_authored_contracts_and_missing_fuel_are_explicit()->void:
	WorldSimulation.scoped("potter",func()->void:
		setup();assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		learn("blast_furnace");learn("finery_forges");learn("bloomery_charge_control")
		for item:String in ["charcoal_pig_iron","charcoal_finery_iron","charged_bloomery_iron"]:
			assert_array(P.startup_blockers(WorldSimulation.military,item)).is_not_empty()
		for entry:Dictionary in K.entries():assert_int(int(entry.day)).is_equal(0)
	)
