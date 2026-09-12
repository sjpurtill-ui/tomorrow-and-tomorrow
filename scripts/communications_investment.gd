extends RefCounted
## Build analysis capacity only against returned communications study demand.
const Ops=preload("res://scripts/technology_operations.gd")
const E=preload("res://scripts/society_exchange.gd")
const Analysis=preload("res://scripts/communications_analysis.gd")
const Supply=preload("res://scripts/civilian_production_planner.gd")
const Power=preload("res://scripts/power_investment_planner.gd")
const TYPES=["optical_signal_bench","electrical_signal_bench","radio_signal_bench","digital_signal_bench"]
static func recommendation()->Dictionary:
	var radio:=radio_recommendation()
	if not radio.is_empty():return radio
	var state=WorldSimulation.state
	if not state.settlement_site_committed or state.convoy_traveling or not state.resource_settlement_id.is_empty():return {}
	var ordinary:=float(state.effective_workers("Knowledge"))*.15
	var condition:=clampf(float(state.population_health)*float(state.simulation_metrics.get("labor_efficiency",.72)),0,1)
	if ordinary<=0 or condition<=0:return {}
	var remaining:Dictionary={}
	for item:Dictionary in E.data().collections.values():
		if int(item.get("returned_day",2147483647))>int(state.elapsed_days) or not Analysis.eligible(item):continue
		var group:=Analysis.family(item)
		remaining[group]=float(remaining.get(group,0))+maxf(0,1.0-float(item.study))*float(item.work)
	if remaining.is_empty():return {}
	var capacity:Dictionary={};var operators:=0.0
	for id:String in Ops.data().plants:
		var record:Dictionary=Ops.data().plants[id];var spec:Dictionary=Ops.PLANTS[id]
		if not bool(record.enabled):continue
		if int(record.building)>0:return {}
		operators+=int(record.installed)*float(spec.workers)
		var group:=String(spec.get("analysis_family",""))
		if not group.is_empty():capacity[group]=float(capacity.get(group,0))+int(record.installed)*float(spec.services.get("analysis_"+group,0))*condition
	if state.effective_workers("Crafting")+Ops.reserved_workers(state)<operators+2.0:return {}
	var upstream:Dictionary={}
	for id:String in TYPES:
		var spec:Dictionary=Ops.PLANTS[id];var record:Dictionary=Ops.data().plants.get(id,{})
		var group:=String(spec.analysis_family)
		if float(remaining.get(group,0))<ordinary*30.0 or float(capacity.get(group,0))>=ordinary*.25:continue
		if not record.is_empty() and not bool(record.enabled):continue
		if int(record.get("installed",0))>=Ops.LIMIT:continue
		var known:=true
		for gate:String in [spec.gate]+spec.requires:
			if gate not in state.known_discoveries or WorldSimulation.discovery.adoption(gate)<.25:known=false
		if not known:continue
		var needs:Dictionary=spec.cost.duplicate()
		for resource:String in spec.inputs:needs[resource]=float(needs.get(resource,0))+float(spec.inputs[resource])*(int(record.get("installed",0))+1)*30.0
		var first:Dictionary={};var feasible:=true
		for resource:String in needs:
			if float(state.resource_stockpiles.get(resource,0))>=float(needs[resource]):continue
			var part:=Supply.supply(resource,ceili(float(needs[resource])),{})
			if part.is_empty():feasible=false;break
			if first.is_empty():first=part
		if not feasible:continue
		if float(spec.power)>0 and not Power.can_supply(float(spec.power)*condition):
			var generation:=Power.recommendation(float(spec.power)*condition)
			if upstream.is_empty() and not generation.is_empty():upstream=generation
			continue
		if first.is_empty() and not Ops.quote(id).has("error"):return {"kind":"plant_install","plant":id,"count":1}
		if upstream.is_empty():upstream=first
	return upstream

static func radio_recommendation()->Dictionary:
	var state=WorldSimulation.state
	if not state.settlement_site_committed or state.convoy_traveling or not state.resource_settlement_id.is_empty():return {}
	var mission:Dictionary=WorldSimulation.world.diplomatic_mission
	var demand:bool=mission.has("research_subject") and mission.get("research_mode","purchase") in ["purchase","partnership"] and int(mission.get("return_day",-1))>int(state.elapsed_days)
	if not demand:return {}
	var spec:Dictionary=Ops.PLANTS.research_radio_station
	for gate:String in [spec.gate]+spec.requires:
		if gate not in state.known_discoveries or WorldSimulation.discovery.adoption(gate)<.25:return {}
	var existing:Dictionary=Ops.data().plants.get("research_radio_station",{})
	if not existing.is_empty():return {}
	var operators:=0.0
	for id:String in Ops.data().plants:
		var record:Dictionary=Ops.data().plants[id]
		if not bool(record.enabled):continue
		if int(record.building)>0:return {}
		operators+=int(record.installed)*float(Ops.PLANTS[id].workers)
	if state.effective_workers("Knowledge")<=0 or state.effective_workers("Crafting")+Ops.reserved_workers(state)<operators+2.0:return {}
	var condition:=clampf(float(state.population_health)*float(state.simulation_metrics.get("labor_efficiency",.72)),0,1)
	if condition<=0:return {}
	var needs:Dictionary=spec.cost.duplicate()
	for resource:String in spec.inputs:needs[resource]=float(needs.get(resource,0))+float(spec.inputs[resource])*30.0
	var first:Dictionary={}
	for resource:String in needs:
		if float(state.resource_stockpiles.get(resource,0))>=float(needs[resource]):continue
		var part:=Supply.supply(resource,ceili(float(needs[resource])),{})
		if part.is_empty():return {}
		if first.is_empty():first=part
	if not Power.can_supply(float(spec.power)*condition):return Power.recommendation(float(spec.power)*condition)
	if first.is_empty() and not Ops.quote("research_radio_station").has("error"):return {"kind":"plant_install","plant":"research_radio_station","count":1}
	return first
