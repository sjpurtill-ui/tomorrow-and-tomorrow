extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	for id:String in ["GameState","CivilizationSystem","MilitaryCampaign"]:root.get_node(id).set_process(false)
	var discovery:=root.get_node("DiscoverySystem");discovery.initialize()
	var ids:Array=[]
	for entry:Dictionary in discovery.technology_catalog:ids.append(entry.id)
	var result:=preload("res://tools/production_dependency_audit.gd").audit(load("res://scripts/civilian_industry.gd").PRODUCTS,load("res://scripts/technology_operations.gd").PLANTS,root.get_node("ResourceSystem").catalog.keys()+load("res://scripts/household_clothing.gd").HUNTING_BYPRODUCTS.keys(),ids,load("res://tools/production_dependency_audit.gd").operating_routes(),load("res://scripts/sec_specialist_supply.gd").RESERVE)
	result["assumptions"]="All raw resources obtainable and all methods known; finite work, staffing, material quantities, geography and research/material coupling are not simulated. Electricity requires a fabricable commissioned generator; storage is not a source."
	print(JSON.stringify(result))
	quit(0 if result.errors.is_empty() and result.blocked_products.is_empty() and result.blocked_plants.is_empty() else 1)
