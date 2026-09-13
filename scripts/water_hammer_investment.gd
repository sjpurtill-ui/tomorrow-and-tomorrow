extends RefCounted
## Install one river hammer for sustained actual downstream forging demand.
const Ops=preload("res://scripts/technology_operations.gd")
const Site=preload("res://scripts/water_hammer_site.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
static func recommendation()->Dictionary:
	var state=WorldSimulation.state
	if not state.settlement_site_committed or state.convoy_traveling or not state.resource_settlement_id.is_empty():return {}
	if WorldSimulation.military.production_labor_share<=0 or state.effective_workers("Crafting")<3:return {}
	if "water_powered_hammers" not in state.known_discoveries or WorldSimulation.discovery.adoption("water_powered_hammers")<.25:return {}
	if not Ops.data().plants.get("water_hammer",{}).is_empty():return {}
	var site:=Site.select(WorldSimulation.discovery.latest_context)
	if site.is_empty() or float(Site.assessment(site,WorldSimulation.discovery.latest_context,int(state.elapsed_days)).capacity)<=0:return {}
	var demand:Dictionary={}
	for job:Dictionary in WorldSimulation.military.equipment_queue:
		if not bool(job.get("persistent",false)) or bool(job.get("paused",false)) or int(job.get("target_stock",0))<=0:continue
		var remaining:=maxf(0,int(job.target_stock)-P.stock(WorldSimulation.military,job))
		for output:String in ["Armor Plates","Bolt Blanks"]:
			demand[output]=float(demand.get(output,0))+remaining*float(job.materials.get(output,0))
	var batches:=0.0
	for output:String in demand:batches+=maxf(0,float(demand[output])-float(state.resource_stockpiles.get(output,0)))
	if batches<24:return {}
	var spec:Dictionary=Ops.PLANTS.water_hammer
	var needs:Dictionary=spec.cost.duplicate()
	for resource:String in spec.inputs:needs[resource]=float(needs.get(resource,0))+30.0*float(spec.inputs[resource])
	var first:Dictionary={}
	for resource:String in needs:
		if float(state.resource_stockpiles.get(resource,0))>=float(needs[resource]):continue
		var upstream:Dictionary=load("res://scripts/civilian_production_planner.gd").supply(resource,ceili(float(needs[resource])),{})
		if upstream.is_empty():return {}
		if first.is_empty():first=upstream
	if not first.is_empty():return first
	return {"kind":"plant_install","plant":"water_hammer","count":1} if not Ops.quote("water_hammer").has("error") else {}
