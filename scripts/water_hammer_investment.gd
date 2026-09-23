extends RefCounted
## Install one river hammer for sustained actual downstream forging demand.
const Ops=preload("res://scripts/technology_operations.gd")
const Site=preload("res://scripts/water_hammer_site.gd")
const P=preload("res://scripts/persistent_production.gd")
const Bills=preload("res://scripts/goods_bills.gd")
## Iron in one forged plate or blank. Military bills name either the forged
## parts (older lines) or, once flattened, the Iron Ore they came from.
static var IRON_PER_FORGING:=maxf(.01,float(Bills.flatten({"Bolt Blanks":1.0}).get("Iron Ore",1.0)))
static func recommendation()->Dictionary:
	var state=WorldSimulation.state
	if not state.settlement_site_committed or state.convoy_traveling or not state.resource_settlement_id.is_empty():return {}
	if WorldSimulation.military.production_labor_share<=0 or state.effective_workers("Crafting")<3:return {}
	if "water_powered_hammers" not in state.known_discoveries or WorldSimulation.discovery.adoption("water_powered_hammers")<.25:return {}
	if not Ops.data().plants.get("water_hammer",{}).is_empty():return {}
	var site:=Site.select(WorldSimulation.discovery.latest_context)
	if site.is_empty() or float(Site.assessment(site,WorldSimulation.discovery.latest_context,int(state.elapsed_days)).capacity)<=0:return {}
	# Forging demand is the iron that queued military lines still have to work,
	# counted in plate-sized forgings.
	var iron:=0.0
	for job:Dictionary in WorldSimulation.military.equipment_queue:
		if not bool(job.get("persistent",false)) or bool(job.get("paused",false)) or int(job.get("target_stock",0))<=0:continue
		var remaining:=maxf(0,int(job.target_stock)-P.stock(WorldSimulation.military,job))
		if remaining<=0:continue
		iron+=remaining*float(Bills.flatten(job.get("materials",{})).get("Iron Ore",0))
	var batches:=maxf(0,iron-float(state.resource_stockpiles.get("Iron Ore",0)))/IRON_PER_FORGING
	if batches<24:return {}
	var spec:Dictionary=Ops.PLANTS.water_hammer
	var needs:Dictionary=spec.cost.duplicate()
	for resource:String in spec.inputs:needs[resource]=float(needs.get(resource,0))+30.0*float(spec.inputs[resource])
	# The plant bill is raw materials and Civilian Goods; wait until they are held.
	for resource:String in needs:
		if float(state.resource_stockpiles.get(resource,0))<float(needs[resource]):return {}
	return {"kind":"plant_install","plant":"water_hammer","count":1} if not Ops.quote("water_hammer").has("error") else {}
