extends RefCounted
## The settlement construction rules formerly embedded in the rendered map.
## Every local city, regardless of controller, uses this work and material bill.

static func _settlement_definitions() -> Array[Dictionary]:
	return [
		{"name":"Hearth Circle", "days":6.0, "requires":[], "minimum":{"Construction":3},"materials":{"Timber":6.0,"Fiber Plants":6.0},"requires_water":true,"effect":"anchors the camp and makes communal work possible"},
		{"name":"Lean-to Shelters", "days":9.0, "requires":["Hearth Circle"], "minimum":{"Construction":5},"materials":{"Timber":18.0,"Fiber Plants":12.0},"effect":"protects health and expands shelter"},
		{"name":"Storage Pits", "days":7.0, "requires":["Hearth Circle"], "minimum":{"Construction":4, "Logistics":4},"materials":{"Timber":4.0,"Fiber Plants":3.0},"effect":"slows spoilage and expands food storage"},
		{"name":"Open Work Area", "days":12.0, "requires":["Hearth Circle"], "minimum":{"Construction":6, "Crafting":4},"materials":{"Timber":12.0,"Fiber Plants":5.0},"effect":"improves tools and material work"},
		{"name":"Gathering Yard", "days":10.0, "requires":["Hearth Circle"], "minimum":{"Construction":4, "Extraction":4},"materials":{"Timber":10.0,"Fiber Plants":4.0}, "known_resource":true,"effect":"organizes extraction from known deposits"}
	]

static func _settlement_project_available(project: Dictionary) -> bool:
	if String(project.name) in WorldSimulation.state.settlement_completed:
		return false
	for required in project.requires:
		if String(required) not in WorldSimulation.state.settlement_completed:
			return false
	for role in project.minimum:
		if int(WorldSimulation.state.population_allocations.get(role, 0)) < int(project.minimum[role]):
			return false
	if bool(project.get("known_resource", false)) and WorldSimulation.resources.visible_deposits().is_empty():
		return false
	if bool(project.get("requires_water",false)) and not bool(WorldSimulation.state.water_metrics.get("source_accessible",false)):
		return false
	if _settlement_project_material_plan(project).is_empty(): return false
	return true


static func _settlement_project_material_plan(project:Dictionary)->Dictionary:
	var required:Dictionary=(project.get("materials",{}) as Dictionary).duplicate(true)
	var options:Array[Dictionary]=[required]
	if String(project.get("name",""))=="Lean-to Shelters":
		# Early shelter must not be hard-locked behind one named plant deposit.
		# Bark, brush, reeds, earth daub and dry stone are historically plausible
		# substitutes, with heavier alternatives costing more bulk.
		options=[
			required,
			{"Timber":25.0},
			{"Timber":15.0,"Clay":10.0},
			{"Timber":14.0,"Stone":14.0},
		]
	for option in options:
		var affordable:=true
		for resource_name in option:
			if float(WorldSimulation.state.resource_stockpiles.get(resource_name,0.0))+0.0001<float(option[resource_name]):
				affordable=false
				break
		if affordable: return option.duplicate(true)
	return {}


static func _current_settlement_project() -> Dictionary:
	var available: Array[Dictionary] = []
	for project in _settlement_definitions():
		if _settlement_project_available(project): available.append(project)
	if available.is_empty(): return {}
	if WorldSimulation.state.settlement_completed.is_empty():
		for project in available:
			if String(project.name)=="Hearth Circle": return project
	var best: Dictionary = available[0]
	var best_score := -INF
	for project in available:
		var score := float(WorldSimulation.state.settlement_projects.get(project.name,0.0))*0.08
		match String(project.name):
			"Lean-to Shelters": score+=(1.0-clampf(float(WorldSimulation.state.housing_capacity)/maxf(1.0,WorldSimulation.state.population_exact),0.0,1.0))*4.0+1.1
			"Storage Pits": score+=(1.0-clampf(float(WorldSimulation.state.simulation_metrics.get("food_days",30.0))/45.0,0.0,1.0))*3.4+float(WorldSimulation.state.population_allocations.get("Logistics",0))/10.0
			"Open Work Area": score+=float(WorldSimulation.state.population_allocations.get("Crafting",0))/5.0+float(WorldSimulation.state.population_allocations.get("Construction",0))/12.0
			"Gathering Yard": score+=float(WorldSimulation.state.population_allocations.get("Extraction",0))/4.0+float(WorldSimulation.resources.visible_deposits().size())*0.5
		if score>best_score:
			best_score=score
			best=project
	return best

static func process_day()->Array[Dictionary]:
	var events:Array[Dictionary]=[]
	if not WorldSimulation.state.settlement_site_committed or WorldSimulation.state.convoy_traveling:return events
	if "Lean-to Shelters" in WorldSimulation.state.settlement_completed and WorldSimulation.state.population_total>int(WorldSimulation.state.housing_capacity*.80):
		WorldSimulation.state.housing_progress+=float(WorldSimulation.state.population_allocations.get("Construction",0))/8.0*float(WorldSimulation.state.simulation_metrics.get("labor_efficiency",.72))
		if WorldSimulation.state.housing_progress>=28:
			WorldSimulation.state.housing_progress-=28
			WorldSimulation.state.housing_capacity+=maxi(24,roundi(WorldSimulation.state.population_total*.12))
	var project:=_current_settlement_project()
	if project.is_empty():return events
	var builders:=float(WorldSimulation.state.population_allocations.get("Construction",0))
	var carriers:=float(WorldSimulation.state.population_allocations.get("Logistics",0))
	var makers:=float(WorldSimulation.state.population_allocations.get("Crafting",0))
	var work:=(builders/8.0)*(.82+carriers/30.0+makers/50.0)*float(WorldSimulation.state.simulation_metrics.get("labor_efficiency",.72))*(1.0+WorldSimulation.discovery.effect("construction_rate")+WorldSimulation.progression.effect("construction_rate"))
	var title:=String(project.name)
	WorldSimulation.state.settlement_projects[title]=float(WorldSimulation.state.settlement_projects.get(title,0))+work
	if float(WorldSimulation.state.settlement_projects[title])<float(project.days):return events
	var materials:=_settlement_project_material_plan(project)
	if materials.is_empty():return events
	for resource in materials:WorldSimulation.state.resource_stockpiles[resource]=maxf(0,float(WorldSimulation.state.resource_stockpiles.get(resource,0))-float(materials[resource]))
	WorldSimulation.state.settlement_completed.append(title)
	if title=="Hearth Circle":
		WorldSimulation.state.settlement_founded_day=int(WorldSimulation.state.elapsed_days)
		WorldSimulation.settlements.ensure_founded()
		WorldSimulation.government.initialize()
	elif title=="Lean-to Shelters":WorldSimulation.state.housing_capacity+=roundi(90*(1+WorldSimulation.discovery.effect("housing_output")+WorldSimulation.progression.effect("housing_output")))
	var event:={"day":int(WorldSimulation.state.elapsed_days),"settlement_id":WorldSimulation.state.resource_settlement_id,"settlement_name":WorldSimulation.state.settlement_name,"event":"completed","kind":title,"form":"communal_work","land_use":"communal","material_family":"stone" if materials.has("Stone") else ("earth" if materials.has("Clay") else "organic"),"materials":materials,"counts_materials":true,"condition":1.0,"status":"active","note":String(project.get("effect",""))}
	WorldSimulation.state.record_building_event(event)
	events.append(event)
	return events
