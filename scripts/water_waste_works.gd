extends RefCounted
## Paid, maintained local works. Knowledge exposes each project; it does not
## create storage, treatment, sanitation, or a protected groundwater source.

const State=preload("res://scripts/water_waste_works_state.gd")
const ORDER := ["latrine", "wellhead", "cistern", "settling_basin"]
const SPECS := {
	"latrine":{"discovery":"latrine_siting","name":"Separated Latrine Ground","work":18.0,"cost":{"Stone":4.0,"Timber":2.0}},
	"wellhead":{"discovery":"protected_wellheads","name":"Protected Wellhead","work":24.0,"cost":{"Stone":6.0,"Joined Timber Components":1.0}},
	"cistern":{"discovery":"rainwater_cisterns","name":"Lined Rainwater Cistern","work":36.0,"cost":{"Stone":8.0},"alternatives":{"Sealed Clay Vessels":2.0,"Lime Mortar":3.0,"Bitumen":2.0}},
	"settling_basin":{"discovery":"water_settling_basins","name":"Water Settling Basin","work":24.0,"cost":{"Clay":5.0,"Stone":4.0}}
}

static func data()->Dictionary:return WorldSimulation.state.water_waste_works
static func adopted(id:String)->bool:return id in WorldSimulation.state.known_discoveries and WorldSimulation.discovery.adoption(id)>=.25
static func work_for(kind:String)->Dictionary:
	for record:Dictionary in data().works:
		if String(record.kind)==kind:return record
	return {}

static func quote(kind:String,context:Dictionary={})->Dictionary:
	if not SPECS.has(kind):return {"error":"Unknown water or waste work."}
	if not WorldSimulation.state.settlement_site_committed or WorldSimulation.state.convoy_traveling:return {"error":"Settle before building local water or waste works."}
	var spec:Dictionary=SPECS[kind]
	if not adopted(String(spec.discovery)):return {"error":"%s has not been adopted here." % String(spec.name)}
	if not work_for(kind).is_empty():return {"error":"This settlement already has %s." % String(spec.name).to_lower()}
	if kind=="wellhead" and not _has_existing_well(context):return {"error":"A confirmed local well or developed aquifer is required; a wellhead cannot create a water source."}
	var cost:Dictionary=spec.cost.duplicate(true)
	var lining:=""
	if spec.has("alternatives"):
		for item:String in spec.alternatives:
			if float(WorldSimulation.state.resource_stockpiles.get(item,0.0))>=float(spec.alternatives[item]):lining=item;break
		if lining.is_empty():return {"error":"A cistern needs 2 Sealed Clay Vessels, 3 Lime Mortar, or 2 Bitumen for its lining."}
		cost[lining]=float(spec.alternatives[lining])
	for item:String in cost:
		if float(WorldSimulation.state.resource_stockpiles.get(item,0.0))<float(cost[item]):return {"error":"Insufficient %s for %s." % [item,String(spec.name)]}
	return {"ok":true,"kind":kind,"name":spec.name,"work_required":spec.work,"cost":cost,"lining":lining}

static func begin(kind:String,context:Dictionary={})->Dictionary:
	var terms:=quote(kind,context)
	if not bool(terms.get("ok",false)):return terms
	for item:String in terms.cost:WorldSimulation.state.resource_stockpiles[item]=maxf(0.0,float(WorldSimulation.state.resource_stockpiles.get(item,0.0))-float(terms.cost[item]))
	var record:={"id":int(data().next_id),"kind":kind,"status":"under_construction","work_done":0.0,"work_required":float(terms.work_required),"condition":1.0,"lining":String(terms.lining),"started_day":int(WorldSimulation.state.elapsed_days),"last_maintenance_day":-1}
	data().next_id=int(data().next_id)+1;data().works.append(record)
	return {"ok":true,"message":"%s is supplied and awaiting construction work." % String(terms.name),"work_id":record.id}

static func construction_sites()->int:
	var count:=0
	for record:Dictionary in data().works:
		if String(record.status)=="under_construction":count+=1
	return count

static func construction_work(available:float,day:int)->float:
	var remaining:=maxf(0.0,available)
	for record:Dictionary in data().works:
		if remaining<=.000001:break
		if String(record.status)!="under_construction":continue
		var amount:=minf(remaining,maxf(0.0,float(record.work_required)-float(record.work_done)))
		record.work_done=float(record.work_done)+amount;remaining-=amount
		if float(record.work_done)>=float(record.work_required):record.status="active";record.condition=1.0;record.completed_day=day
	return maxf(0.0,available)-remaining

static func advance(context:Dictionary,day:int,daily_water_need:float)->Dictionary:
	if int(data().last_day)>=day:return data().report
	data().last_day=day
	var report:={"cistern_capacity":0.0,"cistern_coverage":0.0,"rain_collected":0.0,"latrine_coverage":0.0,"wellhead_coverage":0.0,"settling_coverage":0.0}
	var population:=maxf(1.0,WorldSimulation.state.population_exact)
	for record:Dictionary in data().works:
		if String(record.status)!="active":continue
		record.condition=maxf(0.0,float(record.condition)-.00035)
		var condition:=clampf(float(record.condition),0.0,1.0)
		match String(record.kind):
			"latrine":
				var staff:=WorldSimulation.state.effective_workers("Logistics")+WorldSimulation.state.effective_workers("Construction")*.35
				report.latrine_coverage=maxf(float(report.latrine_coverage),minf(condition,staff/maxf(1.0,population*.018)))
			"wellhead":
				if _has_existing_well(context):report.wellhead_coverage=maxf(float(report.wellhead_coverage),condition)
			"cistern":
				var capacity:=population*2.5*condition
				var precipitation:=clampf(float(context.get("environment_profile",{}).get("precipitation",0.0)),0.0,1.5)
				report.cistern_capacity=float(report.cistern_capacity)+capacity
				report.rain_collected=float(report.rain_collected)+minf(capacity,population*.16*precipitation*condition)
				report.cistern_coverage=maxf(float(report.cistern_coverage),minf(condition,precipitation))
			"settling_basin":
				var staff:=WorldSimulation.state.effective_workers("Logistics")*.35
				var volume:=minf(population*.55*condition,staff*18.0)
				report.settling_coverage=maxf(float(report.settling_coverage),clampf(volume/maxf(.01,daily_water_need),0.0,1.0))
	data().report=report
	return report

static func scheduled_maintenance(work_per_site:float,day:int)->void:
	if work_per_site<=0:return
	for record:Dictionary in data().works:
		if String(record.status)!="active" or int(record.last_maintenance_day)>=day:continue
		record.last_maintenance_day=day
		var need:=1.0-float(record.condition)
		if need<=0:continue
		var item:="Stone" if String(record.kind)!="cistern" or String(record.get("lining",""))=="" else String(record.lining)
		var stock:=maxf(0.0,float(WorldSimulation.state.resource_stockpiles.get(item,0.0)))
		var repaired:=minf(need,minf(work_per_site*.01,stock*.05))
		WorldSimulation.state.resource_stockpiles[item]=stock-repaired/.05
		record.condition=float(record.condition)+repaired

static func factor(discovery_id:String)->float:
	var key:String=String(({"latrine_siting":"latrine_coverage","protected_wellheads":"wellhead_coverage","rainwater_cisterns":"cistern_coverage","water_settling_basins":"settling_coverage"} as Dictionary).get(discovery_id,""))
	if key.is_empty():return 1.0
	var value:=float(data().get("report",{}).get(key,0.0))
	return clampf(value,0.0,1.0)

static func describe()->String:
	if data().works.is_empty():return "No local water or waste works have been commissioned."
	var lines:Array[String]=[]
	for record:Dictionary in data().works:
		var spec:Dictionary=SPECS[String(record.kind)]
		if String(record.status)=="under_construction":lines.append("%s · %.1f / %.1f construction work" % [String(spec.name),float(record.work_done),float(record.work_required)])
		else:lines.append("%s · %d%% condition" % [String(spec.name),roundi(float(record.condition)*100)])
	return "\n".join(lines)

static func _has_existing_well(context:Dictionary)->bool:
	for source_variant:Variant in context.get("water_conveyance_sources",[]):
		if not source_variant is Dictionary:continue
		var source:Dictionary=source_variant
		if bool(source.get("revealed",false)) and "well" in String(source.get("kind","")).to_lower():return true
	for deposit_variant:Variant in WorldSimulation.state.resource_deposits:
		if not deposit_variant is Dictionary:continue
		var deposit:Dictionary=deposit_variant
		if String(deposit.get("resource",""))=="Deep Aquifer" and String(deposit.get("stage",""))=="developed":return true
	return false
