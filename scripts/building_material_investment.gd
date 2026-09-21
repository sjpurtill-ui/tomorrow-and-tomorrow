extends RefCounted
## Rival workshops supply actual building demand; they do not spawn buildings.
const B=preload("res://scripts/building_material_operations.gd")
const Supply=preload("res://scripts/civilian_production_planner.gd")
static func recommendation()->Dictionary:
	var state=WorldSimulation.state
	if not state.settlement_site_committed or state.convoy_traveling or not state.resource_settlement_id.is_empty():return {}
	if state.effective_workers("Construction")<4 or WorldSimulation.military.production_labor_share<=0:return {}
	if _needs_controlled_kiln():
		var kiln:=_kiln_recommendation()
		if not kiln.is_empty():return kiln
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

static func _needs_controlled_kiln()->bool:
	var state=WorldSimulation.state
	if "kiln_control" not in state.known_discoveries or WorldSimulation.discovery.adoption("kiln_control")<.25:return false
	var record:Dictionary=preload("res://scripts/technology_operations.gd").data().plants.get("controlled_kiln",{})
	if int(record.get("installed",0))+int(record.get("building",0))>0:return false
	return "lime_burning" in state.known_discoveries or "ceramic_pipe_firing_qualification" in state.known_discoveries

static func _kiln_recommendation()->Dictionary:
	var ops=preload("res://scripts/technology_operations.gd");var spec:Dictionary=ops.PLANTS.controlled_kiln
	for item:String in spec.cost:
		if float(WorldSimulation.state.resource_stockpiles.get(item,0))>=float(spec.cost[item]):continue
		var supply:Dictionary=Supply.supply(item,ceili(float(spec.cost[item])),{})
		if not supply.is_empty():return supply
		return {}
	if not ops.quote("controlled_kiln").has("error"):return {"kind":"plant_install","plant":"controlled_kiln","count":1}
	return {}

static func fabric_targets()->Dictionary:
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
	# A private availability map asks which missing component would serve a real
	# compatible plot. It never mutates city stores or starts an unpaid project.
	var prospective:Dictionary=state.resource_stockpiles.duplicate()
	for item:String in fabric.COMPONENTS.values():prospective[item]=maxf(1.0,float(prospective.get(item,0)))
	var choice:Dictionary=fabric.choose_retrofit(state.settlement_plots,prospective,state.known_discoveries,state.discovery_adoption)
	if not choice.is_empty():
		var item:String=fabric.COMPONENTS[String(choice.method)]
		needs[item]=maxf(1.0,float(needs.get(item,0)))
	return needs

static func fabric_recommendation()->Dictionary:
	var state=WorldSimulation.state
	var required:=fabric_targets()
	# Home workshops supply local use plus outstanding demand from other cities.
	# Existing shipments and destination stock already cover part of that demand.
	if state.resource_settlement_id.is_empty():
		for city:Dictionary in state.player_settlements:
			if bool(city.get("primary",false)) or not String(city.get("occupied_by","")).is_empty():continue
			var needs:Dictionary=WorldSimulation.settlements.with_city_resources(String(city.id),func()->Dictionary:
				return WorldSimulation.settlements.with_local_population(func()->Dictionary:
					var result:=fabric_targets()
					for item:String in result:
						result[item]=maxf(0,float(result[item])-float(state.resource_stockpiles.get(item,0))-WorldSimulation.settlements._city_incoming(String(city.id),item))
					return result))
			for item:String in needs:required[item]=float(required.get(item,0))+float(needs[item])
	for item:String in required:
		if float(state.resource_stockpiles.get(item,0))>=float(required[item]):continue
		var next:Dictionary=Supply.supply(item,ceili(float(required[item])),{})
		if not next.is_empty():return next
	return {}
