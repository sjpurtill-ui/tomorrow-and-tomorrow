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
	var fabric:=fabric_recommendation()
	if not fabric.is_empty():return fabric
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

static func fabric_recommendation()->Dictionary:
	var state=WorldSimulation.state
	var fabric=preload("res://scripts/settlement_fabric_operations.gd")
	# Maintenance targets are bounded by installed components, not by discoveries.
	var needs:Dictionary={}
	for plot:Dictionary in state.settlement_plots:
		if String(plot.get("status","")) not in ["active","stressed","damaged"]:continue
		for item:String in fabric.repair_bill(plot,.2):needs[item]=float(needs.get(item,0))+.05
		var job:Dictionary=plot.get("fabric_job",{})
		if not job.is_empty() and String(job.get("state",""))=="awaiting_inspection":
			for item:String in fabric.trial_cost(String(job.method)):
				needs[item]=maxf(float(needs.get(item,0)),float(fabric.trial_cost(String(job.method))[item]))
	for item:String in needs:
		if float(state.resource_stockpiles.get(item,0))>=float(needs[item]):continue
		var next:Dictionary=Supply.supply(item,ceili(float(needs[item])),{})
		if not next.is_empty():return next
	# A private availability map asks which missing component would serve a real
	# compatible plot. It never mutates city stores or starts an unpaid project.
	var prospective:Dictionary=state.resource_stockpiles.duplicate()
	for item:String in fabric.COMPONENTS.values():prospective[item]=maxf(1.0,float(prospective.get(item,0)))
	var choice:Dictionary=fabric.choose_retrofit(state.settlement_plots,prospective,state.known_discoveries,state.discovery_adoption)
	if choice.is_empty():return {}
	var item:String=fabric.COMPONENTS[String(choice.method)]
	if float(state.resource_stockpiles.get(item,0))>=1:return {}
	return Supply.supply(item,1,{})
