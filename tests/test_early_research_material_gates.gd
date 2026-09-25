extends GdUnitTestSuite
const Paths=preload("res://scripts/knowledge_pathways.gd")
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("research_gates",117)
func after_test()->void:WorldSimulation.clear()
func learn(ids:Array[String])->void:
	for id:String in ids:
		if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
		WorldSimulation.state.discovery_adoption[id]=1.0
func test_alumina_cannot_jump_from_ore_assay_to_chemical_refining()->void:
	WorldSimulation.scoped("research_gates",func()->void:
		var entry:Dictionary=WorldSimulation.discovery.discovery_definition("alumina_refining")
		learn(["ore_assaying","metallurgical_mass_balances"])
		assert_bool(Paths.ready(entry,100000)).is_false()
		learn(["chemical_distillation","pressure_vessels","chloralkali_cells"])
		assert_bool(Paths.ready(entry,0)).is_true()
		WorldSimulation.state.resource_deposits=[]
		WorldSimulation.state.resource_stockpiles["Bauxite"]=0.0
		assert_bool(WorldSimulation.discovery._resource_requirements_met(entry.resource_requirements)).is_false()
		WorldSimulation.state.resource_stockpiles["Bauxite"]=2.5
		assert_bool(WorldSimulation.discovery._resource_requirements_met(entry.resource_requirements)).is_true()
	)
func test_tin_requires_actual_ore_but_can_be_studied_with_imported_material()->void:
	WorldSimulation.scoped("research_gates",func()->void:
		var entry:Dictionary=WorldSimulation.discovery.discovery_definition("tin_smelting")
		learn(["ore_assaying","charcoal","copper_smelting"]) # 600-year design: tin follows copper smelting
		assert_bool(Paths.ready(entry,0)).is_true()
		WorldSimulation.state.resource_deposits=[]
		WorldSimulation.state.resource_stockpiles["Tin Ore"]=0.0
		assert_bool(WorldSimulation.discovery._resource_requirements_met(entry.resource_requirements)).is_false()
		WorldSimulation.state.resource_stockpiles["Tin Ore"]=2.0
		assert_bool(WorldSimulation.discovery._resource_requirements_met(entry.resource_requirements)).is_true()
	)

func test_mounted_scouting_does_not_supply_archery()->void:
	WorldSimulation.scoped("research_gates",func()->void:
		var entry:Dictionary=WorldSimulation.discovery.discovery_definition("mounted_archery")
		learn(["animal_taming","pack_animals","domesticated_mounts","mounted_scouts"])
		assert_bool(Paths.ready(entry,100000)).is_false()
		assert_bool(preload("res://scripts/persistent_production.gd").recipe(WorldSimulation.military,"mounted_bow").has("error")).is_true()
		learn(["bow_craft"])
		assert_bool(Paths.ready(entry,0)).is_true()
		learn(["mounted_archery"])
		assert_bool(preload("res://scripts/persistent_production.gd").recipe(WorldSimulation.military,"mounted_bow").has("error")).is_false()
		assert_bool(WorldSimulation.military.consumable_knowledge_availability("arrows").unlocked).is_true()
		assert_str(preload("res://scripts/military_unit_catalog.gd").gate_for("horse_archer")).is_equal("mounted_archery")
	)
