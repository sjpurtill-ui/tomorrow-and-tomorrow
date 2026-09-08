extends GdUnitTestSuite
const Land=preload("res://scripts/military_unit_catalog.gd")
const Joint=preload("res://scripts/joint_force_catalog.gd")
const Knowledge=preload("res://scripts/joint_force_knowledge.gd")
const Combat=preload("res://scripts/combat_simulator.gd")
const Production=preload("res://scripts/persistent_production.gd")

func test_fifty_land_units_have_combat_equipment_and_reachable_knowledge()->void:
	assert_int(Land.ARCHETYPES.size()).is_equal(50)
	assert_array(MilitaryCampaign.validate_military_progression()).is_empty()
	for id:String in Land.ARCHETYPES:
		assert_bool(Combat.UNIT_TYPES.has(id)).is_true()
		for item:String in Land.equipment_for(id):
			assert_bool(Combat.WEAPONS.has(item)).is_true()
			assert_bool(MilitaryCampaign._equipment_recipe(item).is_empty()).is_false()
		var parent:=Land.lineage_for(id)
		assert_bool(parent.is_empty() or Land.ARCHETYPES.has(parent)).is_true()

func test_air_and_naval_chains_are_additional_to_land_and_have_production()->void:
	var domains:={"navy":0,"air":0}
	for id:String in Joint.UNITS:
		var unit:Dictionary=Joint.UNITS[id]
		domains[unit.domain]+=1
		assert_bool(Land.ARCHETYPES.has(id)).is_false()
		assert_bool(DiscoverySystem.discovery_definition(unit.gate).is_empty()).is_false()
		if unit.gate not in GameState.known_discoveries:GameState.known_discoveries.append(unit.gate)
		GameState.discovery_adoption[unit.gate]=1.0
		assert_bool(Production.recipe(MilitaryCampaign,unit.equipment).has("error")).is_false()
		assert_bool(unit.lineage=="" or Joint.UNITS.has(unit.lineage)).is_true()
	assert_int(domains.navy).is_equal(20)
	assert_int(domains.air).is_equal(16)

func test_all_land_equipment_recipes_produce_exact_stock_after_research()->void:
	GameState.reset_for_new_world(7511);MilitaryCampaign.reset_for_new_world()
	GameState.population_allocations["Crafting"]=100;GameState.population_allocations["Logistics"]=100
	GameState.population_health=1.0;GameState.simulation_metrics["labor_efficiency"]=1.0
	GameState.settlement_plots.clear()
	GameState.settlement_plots.append({"land_use":"workshop","worker_capacity":100,"condition":1.0,"status":"active","damage":{}})
	for id:String in Land.ARCHETYPES:
		for item:String in Land.equipment_for(id):
			MilitaryCampaign.equipment_queue.clear();MilitaryCampaign.military_inventory[item]=0
			var gate:=String(Land.EQUIPMENT_GATES[item])
			if not gate.is_empty():
				if gate not in GameState.known_discoveries:GameState.known_discoveries.append(gate)
				GameState.discovery_adoption[gate]=1.0
			var recipe:=Production.recipe(MilitaryCampaign,item)
			assert_bool(recipe.has("error")).override_failure_message(item+" cannot be produced after its research").is_false()
			if recipe.has("error"):continue
			for material:String in recipe.materials:GameState.resource_stockpiles[material]=1000000.0
			var result:=MilitaryCampaign.start_production_line(item,1)
			assert_bool(result.has("ok")).override_failure_message(item+": "+str(result)).is_true()
			if not result.has("ok"):continue
			Production.advance(MilitaryCampaign,MilitaryCampaign.equipment_queue.back(),1000000.0)
			assert_int(int(MilitaryCampaign.military_inventory[item])).is_equal(1)

func test_modern_weapons_require_specific_knowledge()->void:
	GameState.reset_for_new_world(7511);MilitaryCampaign.reset_for_new_world()
	for item:String in ["service_rifle","machine_gun","motorized_kit","armored_vehicle","modern_field_gun"]:
		var gate:=String(Land.EQUIPMENT_GATES[item])
		assert_bool(gate.begins_with("__")).is_false()
		assert_bool(Production.recipe(MilitaryCampaign,item).has("error")).is_true()
		GameState.known_discoveries.append(gate);GameState.discovery_adoption[gate]=1.0
		assert_bool(Production.recipe(MilitaryCampaign,item).has("error")).is_false()

func test_every_new_knowledge_dependency_exists_without_cycles()->void:
	for entry:Dictionary in Knowledge.entries():
		_check_dependencies(String(entry.id),[])

func test_progression_view_keeps_fifty_land_separate_from_naval_and_air()->void:
	var world:Node=auto_free(Node.new());var shell:Control=auto_free(Control.new())
	var view:=preload("res://scripts/hud/content/military_unit_map.gd").new(world,shell)
	assert_int(view.tab(0).blocks[1].items.size()).is_equal(50)
	assert_int(view.tab(1).blocks[1].items.size()).is_equal(20)
	assert_int(view.tab(2).blocks[1].items.size()).is_equal(16)

func _check_dependencies(id:String,ancestors:Array)->void:
	assert_bool(id in ancestors).is_false()
	if id in ancestors:return
	var definition:=DiscoverySystem.discovery_definition(id)
	assert_bool(definition.is_empty()).override_failure_message("Missing discovery: "+id).is_false()
	var path:=ancestors.duplicate();path.append(id)
	for dependency:String in definition.get("requires",[]):_check_dependencies(dependency,path)
