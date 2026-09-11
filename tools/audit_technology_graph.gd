extends SceneTree
## Headless authoring audit; never launches the player scene.
func _initialize()->void:
	call_deferred("run")

func run()->void:
	for name:String in ["GameState","CivilizationSystem","MilitaryCampaign"]:root.get_node(name).set_process(false)
	var discovery:Node=root.get_node("DiscoverySystem")
	var pathways:Script=load("res://scripts/knowledge_pathways.gd")
	var requirements:Script=load("res://scripts/technology_requirements.gd")
	discovery.initialize()
	var graph:Array=[]
	for entry:Dictionary in discovery.technology_catalog:graph.append(pathways.graph_entry(entry))
	var errors:Array=requirements.validate(graph)
	errors.append_array(load("res://scripts/technology_catalog_contract.gd").validate(load("res://scripts/food_water_knowledge.gd").entries(),discovery.technology_catalog))
	errors.append_array(load("res://scripts/technology_catalog_contract.gd").validate(load("res://scripts/military_education_knowledge.gd").entries(),discovery.technology_catalog))
	errors.append_array(load("res://scripts/technology_catalog_contract.gd").validate(load("res://scripts/civilian_science_knowledge.gd").entries(),discovery.technology_catalog))
	errors.append_array(load("res://scripts/technology_catalog_contract.gd").validate(load("res://scripts/civilian_industry.gd").entries(),discovery.technology_catalog))
	errors.append_array(load("res://scripts/technology_catalog_contract.gd").validate(load("res://scripts/semiconductor_knowledge.gd").entries(),discovery.technology_catalog))
	errors.append_array(load("res://scripts/technology_catalog_contract.gd").validate(load("res://scripts/combined_arms_doctrine.gd").entries(),discovery.technology_catalog))
	errors.append_array(load("res://scripts/technology_catalog_contract.gd").validate(load("res://scripts/mathematics_knowledge.gd").entries(),discovery.technology_catalog))
	errors.append_array(load("res://scripts/technology_catalog_contract.gd").validate(load("res://scripts/chemical_process_knowledge.gd").entries(),discovery.technology_catalog))
	errors.append_array(load("res://scripts/technology_catalog_contract.gd").validate(load("res://scripts/mechanics_knowledge.gd").entries(),discovery.technology_catalog))
	for entry:Dictionary in load("res://scripts/resource_knowledge_catalog.gd").entries():
		if entry.id in ["mine_airways","blast_furnace"]:errors.append_array(load("res://scripts/technology_catalog_contract.gd").validate([entry],discovery.technology_catalog))
	errors.append_array(load("res://scripts/technology_catalog_contract.gd").validate(load("res://scripts/geoscience_knowledge.gd").entries(),discovery.technology_catalog))
	errors.append_array(load("res://scripts/technology_catalog_contract.gd").validate(load("res://scripts/field_medicine.gd").entries(),discovery.technology_catalog))
	errors.append_array(load("res://scripts/technology_catalog_contract.gd").validate(load("res://scripts/agronomy_knowledge.gd").entries(),discovery.technology_catalog))
	var authored_routes:=0
	for entry:Dictionary in discovery.technology_catalog:
		authored_routes+=(entry.get("learning_routes",[]) as Array).size()
	var result:={"proposed_discovery_target":5000,"live_discoveries":discovery.technology_catalog.size(),"explicit_learning_routes":authored_routes,"graph_errors":errors,"complete_catalog":false}
	print(JSON.stringify(result))
	quit(0 if errors.is_empty() else 1)
