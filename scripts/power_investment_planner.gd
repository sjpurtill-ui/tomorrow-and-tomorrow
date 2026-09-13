extends RefCounted
## Build generation for actual enabled machinery demand, using ordinary stocks
## and commissioning. No power, workers or technology are granted by planning.
const Ops=preload("res://scripts/technology_operations.gd")
const Supply=preload("res://scripts/civilian_production_planner.gd")
static func recommendation(proposed_demand:float=0.0)->Dictionary:
	var state=WorldSimulation.state
	if not state.settlement_site_committed or state.convoy_traveling or not state.resource_settlement_id.is_empty():return {}
	var condition:=clampf(float(state.population_health)*float(state.simulation_metrics.get("labor_efficiency",.72)),0,1)
	if condition<=0:return {}
	var demand:=Ops.workshop_power_demand()+Ops.auxiliary_power_demand()+maxf(0,proposed_demand)
	var capacity:=0.0;var operators:=0.0
	for id:String in Ops.data().plants:
		var record:Dictionary=Ops.data().plants[id];var spec:Dictionary=Ops.PLANTS[id]
		if not bool(record.enabled):continue
		# Finish already paid construction before ordering more equipment.
		if int(record.building)>0:return {}
		demand+=int(record.installed)*float(spec.power)*condition
		capacity+=int(record.installed)*float(spec.services.get("electricity",0))*condition
		operators+=int(record.installed)*float(spec.workers)
	if demand<=capacity+.000001:return storage_recommendation(demand,capacity,operators,condition)
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

## Check commissioned capacity, not today's remaining dispatch: a first line
## has no dispatch yet. Require current fuel and leave a worker for production.
static func can_supply(proposed_demand:float)->bool:
	var state=WorldSimulation.state
	if not state.settlement_site_committed or state.convoy_traveling or not state.resource_settlement_id.is_empty():return false
	var condition:=clampf(float(state.population_health)*float(state.simulation_metrics.get("labor_efficiency",.72)),0,1)
	if condition<=0:return false
	var workers:=maxf(0,state.effective_workers("Crafting")+Ops.reserved_workers(state)-1.0)
	var demand:=Ops.workshop_power_demand()+Ops.auxiliary_power_demand()+maxf(0,proposed_demand)
	var capacity:=0.0
	for id:String in Ops.PLANTS:
		var record:Dictionary=Ops.data().plants.get(id,{})
		if record.is_empty() or not bool(record.enabled):continue
		var spec:Dictionary=Ops.PLANTS[id]
		if float(spec.power)>0:
			demand+=int(record.installed)*float(spec.power)*condition
			workers=maxf(0,workers-int(record.installed)*float(spec.workers))
	for id:String in ["solar_array","steam_generator"]:
		var record:Dictionary=Ops.data().plants.get(id,{})
		if record.is_empty() or not bool(record.enabled):continue
		var spec:Dictionary=Ops.PLANTS[id]
		var units:=minf(float(record.installed),workers/float(spec.workers))*condition
		for resource:String in spec.inputs:
			units=minf(units,float(state.resource_stockpiles.get(resource,0))/float(spec.inputs[resource]))
		capacity+=units*float(spec.services.electricity)
		workers=maxf(0,workers-units/condition*float(spec.workers))
	for id:String in Ops.PLANTS:
		var spec:Dictionary=Ops.PLANTS[id];var storage:Dictionary=spec.get("storage",{})
		var record:Dictionary=Ops.data().plants.get(id,{})
		if storage.is_empty() or record.is_empty() or not record.enabled:continue
		var units:=minf(float(record.installed),workers/float(spec.workers))*condition
		var retained:=float(record.get("stored_energy",0))*(1.0-float(storage.self_discharge))
		var output:=minf(maxf(0,demand-capacity),minf(units*float(storage.discharge_rate),retained*float(storage.discharge_efficiency)))
		capacity+=output;workers=maxf(0,workers-output/float(storage.discharge_rate)/condition*float(spec.workers))
	return demand>0 and capacity+.000001>=demand

## Buy a bounded three-day reserve only after commissioned generation has
## spare charging capacity. Capacity here is potential storage, never energy.
static func storage_recommendation(demand:float,capacity:float,operators:float,condition:float)->Dictionary:
	if demand<=0 or capacity<=demand+.000001:return {}
	var state=WorldSimulation.state
	var reserve:=0.0
	for id:String in Ops.data().plants:
		var record:Dictionary=Ops.data().plants[id];var spec:Dictionary=Ops.PLANTS[id]
		if not record.enabled:continue
		var storage:Dictionary=spec.get("storage",{})
		if not storage.is_empty():reserve+=int(record.installed)*minf(float(storage.discharge_rate)*condition,float(storage.capacity)*float(storage.discharge_efficiency)/3.0)
		# Do not order reserve infrastructure while its charger lacks fuel.
		if float(spec.services.get("electricity",0))>0:
			for item:String in spec.inputs:
				if float(state.resource_stockpiles.get(item,0))<int(record.installed)*float(spec.inputs[item])*30:return {}
	if reserve+.000001>=demand:return {}
	var upstream:Dictionary={}
	for id:String in ["regulated_battery_store","battery_store"]:
		var spec:Dictionary=Ops.PLANTS[id];var record:Dictionary=Ops.data().plants.get(id,{})
		if not record.is_empty() and not record.enabled:continue
		if int(record.get("installed",0))+int(record.get("building",0))>=Ops.LIMIT:continue
		if state.effective_workers("Crafting")+Ops.reserved_workers(state)<operators+float(spec.workers)+1.0:continue
		var known:=true
		for gate:String in [spec.gate]+spec.requires:
			if gate not in state.known_discoveries or WorldSimulation.discovery.adoption(gate)<.25:known=false
		if not known:continue
		if not Ops.quote(id).has("error"):return {"kind":"plant_install","plant":id,"count":1}
		var first:Dictionary={};var possible:=true
		for item:String in spec.cost:
			if float(state.resource_stockpiles.get(item,0))>=float(spec.cost[item]):continue
			var part:=Supply.supply(item,ceili(float(spec.cost[item])),{})
			if part.is_empty():possible=false;break
			if first.is_empty():first=part
		if possible and upstream.is_empty():upstream=first
	return upstream
