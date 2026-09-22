extends RefCounted
## Material commitments are recipe quantities, not mouths to feed.
static func calculate()->Dictionary:
	var state=WorldSimulation.state
	var result:Dictionary={}
	var build=preload("res://scripts/settlement_construction.gd")
	for project:Dictionary in build._settlement_definitions():
		if String(project.name) in state.settlement_completed:continue
		if project.has("discovery") and String(project.discovery) not in state.known_discoveries:continue
		var ready:=true
		for required:String in project.requires:
			if required not in state.settlement_completed:ready=false
		if not ready:continue
		# Protect an affordable local material alternative when one exists; otherwise
		# retain the default bill so exports cannot prevent its accumulation.
		var cost:Dictionary=build._settlement_project_material_plan(project)
		if cost.is_empty():cost=project.materials
		for item:String in cost:result[item]=maxf(float(result.get(item,0)),float(cost[item]))
	if state.resource_settlement_id.is_empty():
		var host=WorldSimulation.military
		for job:Dictionary in host.equipment_queue:
			if not bool(job.get("persistent",false)) or bool(job.get("paused",false)):continue
			if int(job.get("target_stock",0))>0 and host.PersistentProduction.stock(host,job)>=int(job.target_stock):continue
			var remaining:=maxf(0,1.0-float(job.get("progress_days",0))/maxf(.001,float(job.work_per_item)))
			for item:String in job.get("materials",{}):result[item]=float(result.get(item,0))+float(job.materials[item])*(1.0+remaining)
	if not state.resource_settlement_id.is_empty():return result
	var operations=preload("res://scripts/technology_operations.gd")
	for id:String in state.technology_operations.get("plants",{}):
		var plant:Dictionary=state.technology_operations.plants[id]
		if not bool(plant.get("enabled",true)):continue
		for item:String in operations.PLANTS.get(id,{}).get("inputs",{}):
			result[item]=float(result.get(item,0))+maxi(0,int(plant.get("installed",0)))*float(operations.PLANTS[id].inputs[item])*30.0
	return result
