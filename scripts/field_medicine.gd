extends RefCounted
## Aggregate medical support. The coefficients are game abstractions, not
## clinical predictions; permanent disability never enters this recovery pool.
const METHODS:={
	"litter_bearer_drill":{"name":"Litter Bearer Drill","requires":["wound_cleaning","cordage"],"observation":"Carrying teams rehearse lifting and handing over injured people without abandoning the rest of the column.","capacity":0.25},
	"casualty_collection_posts":{"name":"Casualty Collection Posts","requires":["litter_bearer_drill","watch_rotation"],"observation":"Marked collection points let bearers find waiting casualties instead of searching the whole camp repeatedly.","capacity":0.20},
	"casualty_transfer_records":{"name":"Casualty Transfer Records","requires":["litter_bearer_drill","case_records"],"observation":"A record accompanies each transfer so receiving carers know what happened and what care was already given.","capacity":0.15},
	"evacuation_relays":{"name":"Casualty Evacuation Relays","requires":["casualty_collection_posts","supply_groups"],"observation":"Successive carrying teams exchange patients at agreed points rather than exhausting one team on the entire journey.","capacity":0.25},
	"field_aid_stations":{"name":"Field Aid Stations","requires":["casualty_collection_posts","surgical_anatomy","public_stores"],"observation":"Organized sheltered care concentrates trained personnel and expendable supplies behind the fighting force.","capacity":0.30},
	"triage_registers":{"name":"Triage Registers","requires":["field_aid_stations","casualty_transfer_records"],"observation":"Staff compare urgency and available treatment capacity before deciding the next destination for each casualty.","capacity":0.20},
	"medical_resupply_packing":{"name":"Medical Resupply Packing","requires":["field_aid_stations","material_accounting"],"observation":"Standard care bundles make shortages visible before a receiving station exhausts its dressings and supplies.","capacity":0.15},
	"convalescent_duty_reviews":{"name":"Convalescent Duty Reviews","requires":["triage_registers","work_rest_limits"],"observation":"Recovery records distinguish people ready for duty from those who still need care or different work.","capacity":0.15}
}
static func entries()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for id:String in METHODS:
		var method:Dictionary=METHODS[id]
		result.append({"id":id,"name":method.name,"direction":"Warfare","day":0,"chance":.002,"requires":method.requires.duplicate(),"requires_all":method.requires.duplicate(),"requires_any":[],"learning_routes":[{"id":"local","label":method.name,"requires_all":[]}],"signals":["health","logistics","warfare"],"observation":method.observation,"effects":{},"medical_method":id,"production_contract":"Increases the aggregate daily care capacity of trained, equipped medical detachments as adoption spreads. Real supplies and recoverable wounded are required; no dead or permanently disabled people return to combat."})
	return result
static func capacity(force:Dictionary)->float:
	var staff:=0.0
	for formation:Dictionary in force.get("formations",[]):
		if String(formation.get("unit",""))!="medical_detachment" or String(formation.get("weapon",""))!="medical_kit":continue
		staff+=minf(maxf(0,float(formation.get("count",0))),maxf(0,float(formation.get("equipment",0))))*clampf(float(formation.get("training",0)),0,1)*clampf(float(formation.get("personnel_condition",1)),0,1)
	var improvement:=0.0
	for id:String in METHODS:
		if id in WorldSimulation.state.known_discoveries:improvement+=float(METHODS[id].capacity)*WorldSimulation.discovery.adoption(id)
	return staff*.5*(1+minf(1.5,improvement))
static func quote(force:Dictionary,supply:float)->Dictionary:
	var wounded:=maxi(0,int(force.get("wounded_pool",0))-int(force.get("disabled_pool",0)))
	var care_capacity:=capacity(force)
	var provisioned:=clampf(supply,0,1)
	var stock:Dictionary=WorldSimulation.state.resource_stockpiles
	var fiber:=maxf(0,float(stock.get("Fiber Plants",0)))/.1
	var dressings:=maxf(0,float(stock.get("Woven Dressings",0)))/.02
	var medicine:=maxf(0,float(stock.get("Medicinal Plants",0)))/.05
	var cases:=minf(minf(float(wounded),care_capacity)*provisioned,minf(fiber+dressings,medicine))
	var reason:="Care capacity is available"
	if wounded<=0:reason="No recoverable wounded are waiting"
	elif care_capacity<=0:reason="No trained, equipped medical detachment is available"
	elif provisioned<=0:reason="The force has no supporting provisions"
	elif fiber+dressings<=0:reason="No Fiber Plants or Woven Dressings are available for care supplies"
	elif medicine<=0:reason="No Medicinal Plants are available for care supplies"
	elif cases<minf(float(wounded),care_capacity)*provisioned:reason="Remaining care supplies limit service"
	elif provisioned<1:reason="Partial provisions limit service"
	var dressed_cases:=minf(cases,dressings)
	var inputs:Dictionary={}
	if cases>0:inputs["Medicinal Plants"]=cases*.05
	if dressed_cases>0:inputs["Woven Dressings"]=dressed_cases*.02
	if cases>dressed_cases:inputs["Fiber Plants"]=(cases-dressed_cases)*.1
	return {"capacity":care_capacity,"recoverable_wounded":wounded,"cases":cases,"recovery":cases*.08,"reason":reason,"inputs":inputs}
static func provide(force:Dictionary,supply:float)->Dictionary:
	var result:=quote(force,supply)
	# A multi-day step (day_span.gd) provides `span` days of care.
	var span:=WorldSimulation.span
	for material:String in result.inputs:
		WorldSimulation.state.resource_stockpiles[material]=float(WorldSimulation.state.resource_stockpiles.get(material,0))-float(result.inputs[material])*span
	if span>1:result.recovery=float(result.recovery)*span
	return result
static func describe(report:Dictionary)->String:
	return "Equipped care capacity: %.1f patients. Recoverable wounded: %d. Current supplies support %.1f patients. %s. Care uses local supplies during recovery at home." % [float(report.get("capacity",0)),int(report.get("recoverable_wounded",0)),float(report.get("cases",0)),String(report.get("reason",""))]
