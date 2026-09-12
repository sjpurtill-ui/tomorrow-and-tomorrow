extends SceneTree
## Read-only catalog check; no player scene or campaign state is loaded.
func _initialize()->void:call_deferred("run")
func run()->void:
	var discovery=root.get_node("DiscoverySystem")
	discovery.initialize()
	var errors:=preload("res://scripts/technology_requirements.gd").validate(discovery.technology_catalog)
	var meal_ids:Array[String]=[]
	for entry:Dictionary in load("res://scripts/food_preparation.gd").entries():
		meal_ids.append(entry.id)
		if not load("res://scripts/food_preparation.gd").METHODS.has(entry.id):errors.append("Missing operating method: "+String(entry.id))
		if int(entry.day)!=0:errors.append("Unexpected calendar gate: "+String(entry.id))
	for entry:Dictionary in discovery.technology_catalog:
		var channels:Dictionary=preload("res://scripts/discovery_frontier_catalog.gd").SUBCATEGORIES
		if not channels.has(entry.dynamic) or String(entry.subcategory) not in channels.get(entry.dynamic,[]):errors.append("Unsupported research channel: "+String(entry.id))
	print(JSON.stringify({"live_discoveries":discovery.technology_catalog.size(),"new_food_discoveries":meal_ids,"errors":errors,"full_revamp_integrated":false}))
	quit(0 if errors.is_empty() else 1)
