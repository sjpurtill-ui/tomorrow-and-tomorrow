extends RefCounted
## Rival workshops supply actual building demand; they do not spawn buildings.
const B=preload("res://scripts/building_material_operations.gd")
const Supply=preload("res://scripts/civilian_production_planner.gd")
static func recommendation()->Dictionary:
	var state=WorldSimulation.state
	if not state.settlement_site_committed or state.convoy_traveling or not state.resource_settlement_id.is_empty():return {}
	if state.effective_workers("Construction")<4 or WorldSimulation.military.production_labor_share<=0:return {}
	# Existing supplied fabric creates a small finite maintenance stock target.
	var maintenance:Dictionary={}
	for plot:Dictionary in state.settlement_plots:
		var profile:Dictionary=plot.get("building_materials",{})
		if profile.is_empty() or String(plot.get("status","")) in ["ruin","reclaimed","under_construction"]:continue
		var material:=String(B.PROFILES[profile.id].repair)
		maintenance[material]=float(maintenance.get(material,0))+.2
	for material:String in maintenance:
		var target:=ceili(float(maintenance[material]))
		if float(state.resource_stockpiles.get(material,0))>=target:continue
		var part:=Supply.supply(material,target,{})
		if not part.is_empty():return part
	var capacity:=0
	for plot:Dictionary in state.settlement_plots:
		if String(plot.get("status","")) in ["active","stressed","under_construction"]:capacity+=int(plot.get("resident_capacity",0))
	if state.population_exact<=float(capacity)*.88:return {}
	var options:=B.options()
	options.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.service_life)/float(a.building_materials.work)>float(b.service_life)/float(b.building_materials.work))
	for option:Dictionary in options:
		var first:Dictionary={};var feasible:=true
		for material:String in option.cost:
			if float(state.resource_stockpiles.get(material,0))>=float(option.cost[material]):continue
			var part:=Supply.supply(material,ceili(float(option.cost[material])),{})
			if part.is_empty():feasible=false;break
			if first.is_empty():first=part
		if feasible:return first
	return {}
