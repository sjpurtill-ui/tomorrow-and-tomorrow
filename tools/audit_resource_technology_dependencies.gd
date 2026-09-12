extends SceneTree
## Structural reachability under explicitly ideal geography, labor and tools.
## This deliberately does not model elapsed work, adoption or campaign pacing.
func _initialize()->void:call_deferred("run")
func run()->void:
	var excluded:Array[String]=[]
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--exclude="):excluded.append(argument.trim_prefix("--exclude="))
	for name:String in ["GameState","CivilizationSystem","MilitaryCampaign"]:root.get_node(name).set_process(false)
	var state:Node=root.get_node("GameState")
	var resources:Node=root.get_node("ResourceSystem")
	var discovery:Node=root.get_node("DiscoverySystem")
	var requirements:Script=load("res://scripts/technology_requirements.gd")
	var pathways:Script=load("res://scripts/knowledge_pathways.gd")
	discovery.initialize();state.known_discoveries.clear();state.resource_deposits.clear();state.resource_stockpiles.clear()
	for job:String in state.population_allocations:state.population_allocations[job]=100
	for resource:String in resources.catalog:
		var deposit:Dictionary=resources._deposit(resource,Vector3.ZERO,1.0,10000, state.resource_deposits.size())
		deposit.route=1.0;state.resource_deposits.append(deposit)
	var changed:=true
	var rounds:=0
	while changed:
		changed=false;rounds+=1
		for deposit:Dictionary in state.resource_deposits:
			var resource:=String(deposit.resource)
			if deposit.stage=="unknown" and resources.recognition_ready(resource):deposit.stage="surveyed";changed=true
			if deposit.stage=="surveyed" and resources._access_blockers(deposit,resources.catalog[resource],{"tools":1.0}).is_empty():
				# Assume time for route work, adopted processing and practice once
				# hard blockers clear. Never mistake this for measured extraction.
				deposit.stage="developed";changed=true
		for entry:Dictionary in discovery.technology_catalog:
			if entry.id in state.known_discoveries or entry.id in excluded:continue
			var graph:Dictionary=pathways.graph_entry(entry)
			if not requirements.evaluate(graph,state.known_discoveries).ready:continue
			var routes:Array=graph.get("learning_routes",[])
			var ready:=routes.is_empty()
			for route:Dictionary in routes:
				if requirements.evaluate(route,state.known_discoveries).ready:ready=true;break
			if ready and discovery._resource_requirements_met(entry.get("resource_requirements",[])):
				state.known_discoveries.append(entry.id);changed=true
	var blocked:Array=[]
	for entry:Dictionary in discovery.technology_catalog:
		if entry.id not in state.known_discoveries:blocked.append(entry.id)
	var materials:Dictionary={}
	for deposit:Dictionary in state.resource_deposits:materials[deposit.resource]=deposit.stage
	print(JSON.stringify({"structural_only":true,"excluded":excluded,"campaign_verified":false,"assumptions":"Every resource exists locally; abundant labor, tools, route construction, observations and processing practice; no time, adoption or production costs modeled","rounds":rounds,"reachable":state.known_discoveries.size(),"blocked":blocked,"resources":materials}))
	quit(0 if blocked.is_empty() else 1)
