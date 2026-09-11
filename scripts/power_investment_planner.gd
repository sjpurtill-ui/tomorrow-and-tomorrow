extends RefCounted
## Build generation for actual enabled machinery demand, using ordinary stocks
## and commissioning. No power, workers or technology are granted by planning.
const Ops=preload("res://scripts/technology_operations.gd")
const Supply=preload("res://scripts/civilian_production_planner.gd")
static func recommendation()->Dictionary:
	var state=WorldSimulation.state
	if not state.settlement_site_committed or state.convoy_traveling or not state.resource_settlement_id.is_empty():return {}
	var condition:=clampf(float(state.population_health)*float(state.simulation_metrics.get("labor_efficiency",.72)),0,1)
	if condition<=0:return {}
	var demand:=Ops.workshop_power_demand()
	var capacity:=0.0;var operators:=0.0
	for id:String in Ops.data().plants:
		var record:Dictionary=Ops.data().plants[id];var spec:Dictionary=Ops.PLANTS[id]
		if not bool(record.enabled):continue
		# Finish already paid construction before ordering more equipment.
		if int(record.building)>0:return {}
		demand+=int(record.installed)*float(spec.power)*condition
		capacity+=int(record.installed)*float(spec.services.get("electricity",0))*condition
		operators+=int(record.installed)*float(spec.workers)
	if demand<=capacity+.000001:return {}
	var upstream:Dictionary={}
	for id:String in ["solar_array","steam_generator"]:
		var spec:Dictionary=Ops.PLANTS[id]
		var record:Dictionary=Ops.data().plants.get(id,{})
		if not record.is_empty() and not bool(record.enabled):continue
		if int(record.get("installed",0))+int(record.get("building",0))>=Ops.LIMIT:continue
		if state.effective_workers("Crafting")+Ops.reserved_workers(state)<operators+float(spec.workers)+1.0:continue
		var ready:=true
		for gate:String in [spec.gate]+spec.requires:
			if gate not in state.known_discoveries or WorldSimulation.discovery.adoption(gate)<.25:ready=false
		# Avoid a fuel-dependent installation that cannot sustain its first month.
		for resource:String in spec.inputs:
			if float(state.resource_stockpiles.get(resource,0))<float(spec.inputs[resource])*30.0:ready=false
		if not ready:continue
		if not Ops.quote(id).has("error"):return {"kind":"plant_install","plant":id,"count":1}
		var first:Dictionary={};var possible:=true
		for resource:String in spec.cost:
			if float(state.resource_stockpiles.get(resource,0))>=float(spec.cost[resource]):continue
			var part:=Supply.supply(resource,ceili(float(spec.cost[resource])),{})
			if part.is_empty():possible=false;break
			if first.is_empty():first=part
		if possible and not first.is_empty() and upstream.is_empty():upstream=first
	return upstream
