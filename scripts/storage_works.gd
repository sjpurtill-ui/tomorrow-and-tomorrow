extends RefCounted
## Physical, repeatable capacity in the current city's resource scope. Builder
## time and payment remain in SettlementConstruction's single civic work queue.
const TRIGGER:=0.80
const KINDS:=["food","water","yard","dry","covered","sealed","secure"]
const LABELS:={"food":"Food stores","water":"Water vessels","yard":"Open yards","dry":"Dry stores","covered":"Covered stores","sealed":"Sealed containers","secure":"Secure stores"}
const COSTS:={"food":{"Timber":6.0,"Fiber Plants":4.0},"water":{"Clay":5.0,"Fiber Plants":2.0},"yard":{"Timber":4.0,"Fiber Plants":2.0},"dry":{"Timber":8.0,"Fiber Plants":6.0},"covered":{"Timber":6.0,"Clay":4.0},"sealed":{"Clay":6.0,"Fiber Plants":2.0},"secure":{"Timber":8.0,"Stone":4.0}}
const BASE:={"food":1200.0,"water":240.0,"yard":160.0,"dry":100.0,"covered":100.0,"sealed":30.0,"secure":40.0}

static func added(kind:String)->float:
	return maxf(0.0,float(WorldSimulation.state.storage_works.get("capacity",{}).get(kind,0.0)))

static func capacities()->Dictionary:
	var result:Dictionary=WorldSimulation.resources.storage_capacities()
	result.food=WorldSimulation.food._food_storage_capacity()
	result.water=WorldSimulation.resources.water_storage_capacity()
	return result

static func used()->Dictionary:
	var state=WorldSimulation.state
	var result:={"food":float(state.food_stocks.get("Fresh food",0))+float(state.food_stocks.get("Stored food",0)),"water":float(state.resource_stockpiles.get("Freshwater",0)),"yard":0.0,"dry":0.0,"covered":0.0,"sealed":0.0,"secure":0.0}
	for item:String in state.resource_stockpiles:
		if item=="Food" or not WorldSimulation.resources._is_material_resource(item):continue
		var profile:Dictionary=WorldSimulation.resources.material_profile(item)
		var kind:=String(profile.store)
		result[kind]+=maxf(0.0,float(state.resource_stockpiles[item]))*float(profile.bulk)
	return result

static func title(kind:String)->String:return "Expand "+String(LABELS.get(kind,kind)).to_lower()

static func requested(kind:String)->bool:
	return bool(WorldSimulation.state.storage_works.get("requests",{}).get(kind,false))

static func needed(kind:String,held:Dictionary,room:Dictionary)->bool:
	return requested(kind) or WorldSimulation.state.storage_works.get("jobs",{}).has(kind) or (float(held.get(kind,0))>0.0 and float(held[kind])>=float(room.get(kind,0))*TRIGGER)

static func projects()->Array[Dictionary]:
	var state=WorldSimulation.state
	var result:Array[Dictionary]=[]
	var held:=used()
	for kind:String in KINDS:
		var saved:Dictionary=state.storage_works.get("jobs",{}).get(kind,{})
		if not saved.is_empty():result.append(saved.duplicate(true));continue
		var scale:=maxf(1.0,ceilf(float(held[kind])*.5/float(BASE[kind])))
		var gain:=float(BASE[kind])*scale
		var bill:Dictionary=COSTS[kind].duplicate()
		for item:String in bill:bill[item]*=scale
		result.append({"name":title(kind),"storage_kind":kind,"capacity_added":gain,"days":3.0*scale,"requires":["Hearth Circle"],"minimum":{"Construction":1},"materials":bill,"effect":"Adds %s %s of storage." % [str(gain),"rations" if kind=="food" else "water units" if kind=="water" else "bulk units"]})
	return result

static func queue(kind:String)->Dictionary:
	if kind not in KINDS:return {"error":"Unknown storage type."}
	var state=WorldSimulation.state
	if not state.settlement_site_committed or state.convoy_traveling:return {"error":"Settle here before expanding storage."}
	if not state.storage_works.has("requests"):state.storage_works.requests={}
	state.storage_works.requests[kind]=true
	return {"ok":true,"message":title(kind).capitalize()+" queued; builders use local materials."}

static func begin(project:Dictionary)->void:
	var state=WorldSimulation.state
	if not state.storage_works.has("jobs"):state.storage_works.jobs={}
	state.storage_works.jobs[String(project.storage_kind)]=project.duplicate(true)

static func complete(project:Dictionary)->void:
	var state=WorldSimulation.state
	var kind:=String(project.storage_kind)
	if not state.storage_works.has("capacity"):state.storage_works.capacity={}
	state.storage_works.capacity[kind]=added(kind)+float(project.capacity_added)
	(state.storage_works.get("requests",{}) as Dictionary).erase(kind)
	(state.storage_works.get("jobs",{}) as Dictionary).erase(kind)
	state.settlement_projects.erase(String(project.name))
	var city:=WorldSimulation.settlements.settlement_record(state.resource_settlement_id)
	if String(city.get("construction_priority",""))==String(project.name):city["construction_priority"]=""

static func rows(kinds:Array=KINDS)->Array[Dictionary]:
	var held:=used();var room:=capacities();var result:Array[Dictionary]=[]
	for project:Dictionary in projects():
		var kind:=String(project.storage_kind)
		if kind not in kinds:continue
		var pending:=needed(kind,held,room)
		var work:=float(WorldSimulation.state.settlement_projects.get(project.name,0))
		var missing:PackedStringArray=[]
		for item:String in project.materials:
			var shortfall:=maxf(0,float(project.materials[item])-float(WorldSimulation.state.resource_stockpiles.get(item,0)))
			if shortfall>0:missing.append("%s %s" % [str(snappedf(shortfall,.1)),item.to_lower()])
		var status:="Auto-expand at 80%"
		if pending:
			status="Queued" if requested(kind) else "Auto queued"
			if "Hearth Circle" not in WorldSimulation.state.settlement_completed:status="Needs a hearth circle"
			elif WorldSimulation.state.effective_workers("Construction")<=0:status="Needs builders"
			elif not missing.is_empty():status="Needs "+", ".join(missing)
			elif work>0:status="Building · %d%%" % roundi(work/float(project.days)*100)
		var costs:Array=[]
		for item:String in project.materials:costs.append({"resource":item,"need":float(project.materials[item]),"have":float(WorldSimulation.state.resource_stockpiles.get(item,0))})
		var bill:PackedStringArray=[]
		for item:String in project.materials:bill.append("%s %s" % [str(project.materials[item]),item.to_lower()])
		result.append({"kind":kind,"label":LABELS[kind],"used":held[kind],"capacity":room[kind],"pending":pending,"requested":requested(kind),"building":work>0,"status":status,"added":project.capacity_added,"costs":costs,"work_done":work,"work_required":float(project.days),"capacity_after":float(room[kind])+float(project.capacity_added),"unit":"rations" if kind=="food" else "water units" if kind=="water" else "bulk","tip":"Adds %s capacity. Costs %s and %s builder-work. Excess stock is exposed to loss; water collection stops when vessels are full." % [str(project.capacity_added),", ".join(bill),str(project.days)]})
	return result
