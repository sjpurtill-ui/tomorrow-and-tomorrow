extends RefCounted
## Invest in mechanical assistance only for sustained, materially supplied work.
## All recommendations still pass through ordinary production and plant orders.
const Ops=preload("res://scripts/technology_operations.gd")
const P=preload("res://scripts/persistent_production.gd")
const Supply=preload("res://scripts/civilian_production_planner.gd")
const Power=preload("res://scripts/power_investment_planner.gd")
const TYPES=["programmable_workshop","sequenced_workshop","geared_workshop","controlled_workshop","powered_workshop","pneumatic_workshop"]

static func supplied_work_days()->float:
	var host=WorldSimulation.military
	var snapshot:Dictionary=host.production_lines_snapshot()
	var rate:=float(snapshot.total_daily_work)
	if rate<=0:return 0.0
	var stock:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate()
	var work:=0.0
	for job:Dictionary in host.equipment_queue:
		if not bool(job.get("persistent",false)) or P.state(host,job)!="Working":continue
		var units:=INF
		if int(job.target_stock)>0:units=maxf(0,int(job.target_stock)-P.stock(host,job)-float(job.progress_days)/float(job.work_per_item))
		for resource:String in job.materials:
			var amount:=float(job.materials[resource])
			if amount>0:units=minf(units,maxf(0,float(stock.get(resource,0)))/amount)
		# A cost-free unbounded recipe cannot justify unlimited capital demand.
		if not is_finite(units) or units<=0:continue
		for resource:String in job.materials:stock[resource]=maxf(0,float(stock.get(resource,0))-units*float(job.materials[resource]))
		work+=units*float(job.work_per_item)/maxf(.1,float(job.efficiency))
	return work/rate

static func recommendation()->Dictionary:
	var state=WorldSimulation.state
	if not state.settlement_site_committed or state.convoy_traveling or not state.resource_settlement_id.is_empty():return {}
	if WorldSimulation.military.production_labor_share<=0 or supplied_work_days()<30.0:return {}
	var condition:=clampf(float(state.population_health)*float(state.simulation_metrics.get("labor_efficiency",.72)),0,1)
	if condition<=0:return {}
	var operators:=0.0;var mechanical:=0.0
	for id:String in Ops.data().plants:
		var record:Dictionary=Ops.data().plants[id];var spec:Dictionary=Ops.PLANTS[id]
		if not bool(record.enabled):continue
		if int(record.building)>0:return {}
		operators+=int(record.installed)*float(spec.workers)
		mechanical+=int(record.installed)*float(spec.services.get("mechanical_work",0))*condition
	var free:=maxf(0,state.effective_workers("Crafting")+Ops.reserved_workers(state)-operators)
	var baseline:=free+minf(free*.5,mechanical)
	var upstream:Dictionary={}
	for id:String in TYPES:
		var spec:Dictionary=Ops.PLANTS[id];var record:Dictionary=Ops.data().plants.get(id,{})
		if not record.is_empty() and not bool(record.enabled):continue
		if int(record.get("installed",0))>=Ops.LIMIT:continue
		var remaining:=free-float(spec.workers)
		if remaining<2.0:continue
		var assisted:=remaining+minf(remaining*.5,mechanical+float(spec.services.mechanical_work)*condition)
		if assisted<=baseline+.25:continue
		var known:=true
		for gate:String in [spec.gate]+spec.requires:
			if gate not in state.known_discoveries or WorldSimulation.discovery.adoption(gate)<.25:known=false
		if not known:continue
		var needs:Dictionary=spec.cost.duplicate()
		for resource:String in spec.inputs:needs[resource]=float(needs.get(resource,0))+float(spec.inputs[resource])*30.0
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
