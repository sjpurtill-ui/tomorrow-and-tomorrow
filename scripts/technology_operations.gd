extends RefCounted
## Aggregate primary-settlement installations. Government still assigns roles;
## operators reserve capacity within Crafting rather than creating workers.
const LIMIT:=1000
const PLANTS={
	"solar_array":{"name":"Photovoltaic array","gate":"photovoltaic_power","requires":["cable_insulation"],"cost":{"Photovoltaic Modules":1.0,"Insulated Cable":2.0,"Steel":1.0},"work":12.0,"workers":.2,"inputs":{},"power":0.0,"services":{"electricity":4.0}},
	"steam_generator":{"name":"Steam-electric works","gate":"electrical_generators","requires":["steam_propulsion"],"cost":{"Electrical Generators":1.0,"Pressure Vessels":1.0,"Wrought Iron":5.0},"work":20.0,"workers":2.0,"inputs":{"Coal":.5,"Freshwater":1.0},"power":0.0,"services":{"electricity":10.0}},
	"cold_store":{"name":"Electric cold store","gate":"mechanical_refrigeration","requires":["electric_motors"],"cost":{"Electric Motors":1.0,"Pressure Vessels":1.0,"Glass":1.0},"work":12.0,"workers":1.0,"inputs":{"Bitumen":.01},"power":3.0,"services":{"cold_storage":200.0}},
	"powered_workshop":{"name":"Motor-driven workshop","gate":"electric_motors","requires":["electrical_generators"],"cost":{"Electric Motors":1.0,"Insulated Cable":2.0,"Wrought Iron":2.0},"work":10.0,"workers":1.0,"inputs":{},"power":2.0,"services":{"mechanical_work":3.0}},
	"controlled_workshop":{"name":"Electronically controlled workshop","gate":"electronic_machine_control","requires":["electric_motors"],"cost":{"Electronic Controllers":1.0,"Electric Motors":1.0,"Insulated Cable":2.0,"Steel":2.0},"work":15.0,"workers":1.5,"inputs":{},"power":2.5,"services":{"mechanical_work":4.5}},
	"sequenced_workshop":{"name":"Hardwired sequencing workshop","gate":"hardwired_sequence_control","requires":["electric_motors"],"cost":{"Sequence Controllers":1.0,"Electric Motors":1.0,"Insulated Cable":2.0,"Steel":3.0},"work":18.0,"workers":1.5,"inputs":{},"power":3.0,"services":{"mechanical_work":5.0}},
	"programmable_workshop":{"name": "Programmable machine workshop", "gate": "stored_program_control", "requires": ["electric_motors"], "cost": {"Programmable Controllers": 1.0, "Electric Motors": 1.0, "Insulated Cable": 2.0, "Steel": 3.0}, "work": 20.0, "workers": 1.5, "inputs": {}, "power": 4.0, "services": {"mechanical_work": 6.0}}
}
static func empty_state()->Dictionary:return {"last_day":-1,"plants":{},"services":{},"workers":0.0,"inputs":{}}
static func data()->Dictionary:return WorldSimulation.state.technology_operations
static func quote(id:String,count:int=1)->Dictionary:
	if not PLANTS.has(id) or count<1 or count>100:return {"error":"Choose an installation and between 1 and 100 units."}
	var state:=WorldSimulation.state
	if not state.settlement_site_committed or state.convoy_traveling or not state.resource_settlement_id.is_empty():return {"error":"Install machinery at the primary settled home."}
	var spec:Dictionary=PLANTS[id]
	for gate:String in [spec.gate]+spec.requires:
		if gate not in state.known_discoveries or WorldSimulation.discovery.adoption(gate)<.25:return {"error":"Establish "+String(WorldSimulation.discovery.discovery_definition(gate).get("name",gate))+" before commissioning this plant."}
	var record:Dictionary=data().plants.get(id,{})
	if int(record.get("installed",0))+int(record.get("building",0))+count>LIMIT:return {"error":"Installation capacity is full."}
	var cost:Dictionary={};var parts:Array[String]=[]
	for item:String in spec.cost:
		cost[item]=float(spec.cost[item])*count
		parts.append("%.1f %s" % [cost[item],item])
		if float(state.resource_stockpiles.get(item,0))<float(cost[item]):return {"error":"Needs %.1f %s in stores." % [cost[item],item]}
	return {"ok":true,"cost":cost,"message":"Install %d %s: %s. Commissioning needs %.1f worker-days; operators share the assigned Crafting workforce." % [count,spec.name,", ".join(parts),float(spec.work)*count]}
static func install(id:String,count:int=1)->Dictionary:
	var offer:=quote(id,count)
	if offer.has("error"):return offer
	for item:String in offer.cost:WorldSimulation.state.resource_stockpiles[item]=float(WorldSimulation.state.resource_stockpiles[item])-float(offer.cost[item])
	if not data().plants.has(id):data().plants[id]={"installed":0,"building":0,"work":0.0,"enabled":true}
	data().plants[id].building+=count
	return offer
static func set_enabled(id:String,value:bool)->void:
	if data().plants.has(id):data().plants[id].enabled=value
static func reserved_workers(state:Node)->float:
	if not state.resource_settlement_id.is_empty():return 0.0
	var ledger:Dictionary=state.technology_operations
	return float(ledger.workers) if int(ledger.last_day)==int(state.elapsed_days) else 0.0
static func service(name:String)->float:
	if not WorldSimulation.state.resource_settlement_id.is_empty() or int(data().last_day)!=int(WorldSimulation.state.elapsed_days):return 0.0
	return maxf(0,float(data().services.get(name,0)))
static func workshop_power_demand()->float:
	var demand:=0.0
	var host:=WorldSimulation.military
	if host.production_labor_share<=0:return 0.0
	for job:Dictionary in host.equipment_queue:
		if not bool(job.get("persistent",false)) or bool(job.get("paused",false)):continue
		var recipe:Dictionary=preload("res://scripts/civilian_industry.gd").product(String(job.get("item","")))
		if float(recipe.get("power",0))<=0:continue
		if (recipe.gate not in WorldSimulation.state.known_discoveries or WorldSimulation.discovery.adoption(String(recipe.gate))<.10) and not preload("res://scripts/research_licenses.gd").active(String(recipe.gate)):continue
		if int(job.get("target_stock",0))>0 and float(WorldSimulation.state.resource_stockpiles.get(recipe.output,0))>=int(job.target_stock):continue
		var supplied:=true
		for item:String in recipe.materials:
			if float(recipe.materials[item])>0 and float(WorldSimulation.state.resource_stockpiles.get(item,0))<=.000000001:supplied=false
		if supplied:demand+=float(recipe.daily_power)
	return demand
static func consume_electricity(amount:float)->float:
	var used:=minf(maxf(0,amount),service("electricity"))
	if used>0:data().services.electricity-=used
	return used
static func advance(day:int)->void:
	var ledger:=data()
	if day<=int(ledger.last_day):return
	ledger.last_day=day;ledger.services={};ledger.inputs={};ledger.workers=0.0
	for record:Dictionary in ledger.plants.values():record["running_units"]=0.0
	var state:=WorldSimulation.state
	if not state.settlement_site_committed or state.convoy_traveling:return
	var available:float=state.effective_workers("Crafting")
	var condition:=clampf(float(state.population_health)*float(state.simulation_metrics.get("labor_efficiency",.72)),0,1.0)
	if condition<=0 or available<=0:return
	var demand:=workshop_power_demand()
	for id:String in PLANTS:
		var record:Dictionary=ledger.plants.get(id,{})
		if not record.is_empty() and record.enabled:demand+=int(record.installed)*float(PLANTS[id].power)*condition
	# Generation is dispatched against actual installed demand, not an infinite
	# stockpile of electricity. Consumers share the resulting daily service.
	for id:String in PLANTS:
		var record:Dictionary=ledger.plants.get(id,{})
		if record.is_empty() or not record.enabled or int(record.installed)<=0:continue
		var spec:Dictionary=PLANTS[id]
		var units:=minf(float(record.installed),available/float(spec.workers))*condition
		if float(spec.services.get("electricity",0))>0:units=minf(units,maxf(0,demand-float(ledger.services.get("electricity",0)))/float(spec.services.electricity))
		if float(spec.power)>0:units=minf(units,float(ledger.services.get("electricity",0))/float(spec.power))
		for item:String in spec.inputs:units=minf(units,maxf(0,float(state.resource_stockpiles.get(item,0)))/float(spec.inputs[item]))
		if units<=0:continue
		record["running_units"]=units
		var staff:=units/condition*float(spec.workers)
		available-=staff;ledger.workers+=staff
		for item:String in spec.inputs:
			var amount:=units*float(spec.inputs[item])
			state.resource_stockpiles[item]=maxf(0,float(state.resource_stockpiles.get(item,0))-amount)
			ledger.inputs[item]=float(ledger.inputs.get(item,0))+amount
		if float(spec.power)>0:ledger.services.electricity=maxf(0,float(ledger.services.get("electricity",0))-units*float(spec.power))
		for name:String in spec.services:ledger.services[name]=float(ledger.services.get(name,0))+units*float(spec.services[name])
	# Existing services take priority over expansion; spent machinery stays
	# in the installation record through suspension and saving.
	for id:String in PLANTS:
		var record:Dictionary=ledger.plants.get(id,{})
		if record.is_empty() or not record.enabled or int(record.building)<=0:continue
		var spec:Dictionary=PLANTS[id]
		var required:=float(record.building)*float(spec.work)-float(record.work)
		var staff:=minf(available,minf(2.0*int(record.building),required/condition))
		record.work+=staff*condition;available-=staff;ledger.workers+=staff
		var completed:=mini(int(record.building),floori((float(record.work)+.00000001)/float(spec.work)))
		record.installed+=completed;record.building-=completed;record.work=maxf(0,float(record.work)-completed*float(spec.work))
static func status(id:String)->String:
	var record:Dictionary=data().plants.get(id,{})
	if record.is_empty():return "Not installed"
	if WorldSimulation.state.convoy_traveling:return "Inactive while traveling"
	if not record.enabled:return "Pause scheduled; today's service is already delivered" if float(record.get("running_units",0))>0 else "Paused"
	if int(data().last_day)!=int(WorldSimulation.state.elapsed_days):return "Awaiting daily review"
	if float(record.get("running_units",0))>0:return "Operating %.2f of %d installed units" % [float(record.running_units),int(record.installed)]
	if int(record.installed)<=0:return "Commissioning: %.1f work completed toward the next unit" % float(record.work)
	var spec:Dictionary=PLANTS[id]
	for item:String in spec.inputs:
		if float(WorldSimulation.state.resource_stockpiles.get(item,0))<=0:return "Waiting for "+item
	if float(spec.power)>0:return "Waiting for power or available Crafting operators"
	return "Waiting for powered demand or available Crafting operators"
static func forecast_service(name:String,days_ahead:int)->float:
	# Conservative fixed-stock forecast: future extraction and deliveries are
	# not promised. Real daily operation recalculates after actual resupply.
	for item:String in data().inputs:
		if float(WorldSimulation.state.resource_stockpiles.get(item,0))+.00000001<float(data().inputs[item])*days_ahead:return 0.0
	return service(name)
static func refrigeration_multiplier(capacity:float,stocks:Dictionary)->float:
	var perishables:=0.0
	for food:String in ["Fresh plants","Fresh meat","Fish"]:perishables+=maxf(0,float(stocks.get(food,0)))
	if perishables<=0:return 1.0
	return 1.0-.8*clampf(capacity/perishables,0,1)
static func valid(value:Variant)->bool:
	if not value is Dictionary or not value.has_all(["last_day","plants","services","workers","inputs"]):return false
	if not value.plants is Dictionary or value.plants.size()>PLANTS.size():return false
	for field:String in ["last_day","workers"]:
		if not number(value[field]) or value[field]<(-1 if field=="last_day" else 0):return false
	if float(value.last_day)!=floorf(float(value.last_day)) or float(value.workers)>14000:return false
	for field:String in ["services","inputs"]:
		if not value[field] is Dictionary or value[field].size()>16:return false
		for key:Variant in value[field]:
			if field=="services" and key not in ["electricity","cold_storage","mechanical_work"]:return false
			if field=="inputs" and key not in ["Coal","Freshwater","Bitumen"]:return false
			if not key is String or not number(value[field][key]) or value[field][key]<0:return false
	for name:String in {"electricity":14000.0,"cold_storage":200000.0,"mechanical_work":18500.0}:
		if float(value.services.get(name,0))>float({"electricity":14000.0,"cold_storage":200000.0,"mechanical_work":18500.0}[name])+.000001:return false
	for id:Variant in value.plants:
		if not PLANTS.has(id):return false
		var record:Variant=value.plants[id]
		if not record is Dictionary or not record.has_all(["installed","building","work","enabled"]) or not record.enabled is bool:return false
		for field:String in ["installed","building","work"]:
			if not number(record[field]) or record[field]<0:return false
		if not number(record.get("running_units",0)) or float(record.get("running_units",0))<0 or float(record.get("running_units",0))>float(record.installed)+.000001:return false
		if record.installed!=floorf(record.installed) or record.building!=floorf(record.building) or record.installed+record.building>LIMIT or record.work>=float(PLANTS[id].work):return false
	return true
static func number(value:Variant)->bool:return (value is float or value is int) and is_finite(float(value))
