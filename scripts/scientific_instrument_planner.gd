extends RefCounted
## Invest against a month of returned physical specimen work, never hidden leads.
const Ops=preload("res://scripts/technology_operations.gd")
const Supply=preload("res://scripts/civilian_production_planner.gd")
const E=preload("res://scripts/society_exchange.gd")
static func recommendation()->Dictionary:
	var state=WorldSimulation.state
	if not state.settlement_site_committed or state.convoy_traveling or not state.resource_settlement_id.is_empty():return {}
	var condition:=clampf(float(state.population_health)*float(state.simulation_metrics.get("labor_efficiency",.72)),0,1)
	var ordinary:=float(state.effective_workers("Knowledge"))*.15
	if condition<=0 or ordinary<=0:return {}
	var remaining:=0.0
	for item:Dictionary in E.data().collections.values():
		if String(item.get("kind",""))!="specimen" or int(item.returned_day)>int(state.elapsed_days):continue
		remaining+=maxf(0,1.0-float(item.study))*float(item.work)
	if remaining<ordinary*30.0:return {}
	var spec:Dictionary=Ops.PLANTS.microscopy_bench
	for gate:String in [spec.gate]+spec.requires:
		if gate not in state.known_discoveries or WorldSimulation.discovery.adoption(gate)<.25:return {}
	var operators:=0.0
	for record_id:String in Ops.data().plants:
		var record:Dictionary=Ops.data().plants[record_id]
		if not bool(record.enabled):continue
		if int(record.building)>0:return {}
		operators+=int(record.installed)*float(Ops.PLANTS[record_id].workers)
	var bench:Dictionary=Ops.data().plants.get("microscopy_bench",{})
	if not bench.is_empty() and not bool(bench.enabled):return {}
	var installed:=int(bench.get("installed",0))
	if installed>=Ops.LIMIT or installed*float(spec.services.specimen_observation)*condition>=ordinary*.25:return {}
	# Leave enough assigned labor for commissioning as well as existing operators.
	if state.effective_workers("Crafting")+Ops.reserved_workers(state)<operators+2.0:return {}
	var slides:=ceili(float(spec.inputs["Specimen Slides"])*(installed+1)*30.0)
	if float(state.resource_stockpiles.get("Specimen Slides",0))<slides:
		return Supply.supply("Specimen Slides",slides,{})
	if not Ops.quote("microscopy_bench").has("error"):return {"kind":"plant_install","plant":"microscopy_bench","count":1}
	var first:Dictionary={}
	for resource:String in spec.cost:
		if float(state.resource_stockpiles.get(resource,0))>=float(spec.cost[resource]):continue
		var part:=Supply.supply(resource,ceili(float(spec.cost[resource])),{})
		if part.is_empty():return {}
		if first.is_empty():first=part
	return first
