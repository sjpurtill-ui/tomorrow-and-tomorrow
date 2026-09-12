extends RefCounted
## Destructive examination of a physically owned manufactured example.
const Specimens=preload("res://scripts/research_specimens.gd")
const Exchange=preload("res://scripts/society_exchange.gd")
const Pathways=preload("res://scripts/knowledge_pathways.gd")
static func available()->bool:
	return "apprentice_contracts" in WorldSimulation.state.known_discoveries and "workshop_standards" in WorldSimulation.state.known_discoveries
static func specimens(subject:String)->Array[String]:
	return Specimens.for_subject(subject)
static func quote(subject:String,item:String)->Dictionary:
	if not available():return {"error":"Examining manufactured examples needs apprenticeship and workshop standards."}
	var entry:=WorldSimulation.discovery.discovery_definition(subject)
	if entry.is_empty() or subject in WorldSimulation.state.known_discoveries or not Pathways.ready(entry,int(WorldSimulation.state.elapsed_days)):return {"error":"Local foundations for this investigation are missing, or the discovery is already known."}
	if Exchange.evidence_strength(Pathways.evidence(subject))>=1.35:return {"error":"An equally strong or stronger study already supports this investigation."}
	if item not in specimens(subject):return {"error":"This specimen does not demonstrate the selected manufacturing practice."}
	if Exchange.data().collections.has("reverse:"+subject):return {"error":"A specimen of this practice has already been assigned for examination."}
	if Exchange.data().collections.size()>=Exchange.COLLECTION_LIMIT:return {"error":"The collection is full."}
	var specimen:Dictionary=Specimens.definition(item)
	var resource:=String(specimen.output)
	var military:=bool(specimen.get("military",false))
	var owned:=float(WorldSimulation.military.military_inventory.get(specimen.get("equipment",""),0)) if military else float(WorldSimulation.state.resource_stockpiles.get(resource,0))
	if owned<1:return {"error":"Needs one unassigned, serviceable equipment set: "+resource+"." if military else "Needs one physically owned batch of "+resource+"."}
	return {"subject":subject,"item":item,"resource":resource,"message":"Consume one owned example of %s for destructive examination. Researchers need 180 study-work, then gain a 1.35× evidence multiplier on this investigation. Local foundations and subsequent research are still required." % resource}
static func begin(subject:String,item:String)->Dictionary:
	var terms:=quote(subject,item)
	if terms.has("error"):return terms
	var entry:=WorldSimulation.discovery.discovery_definition(subject)
	var day:=int(WorldSimulation.state.elapsed_days)
	var record:={"id":"reverse:"+subject,"kind":"artifact","name":"Disassembled example: "+String(entry.name),"source_id":"","source_name":"Owned manufactured specimen","position":{"x":0.0,"z":0.0},"observed_day":day,"returned_day":day,"discovery_id":subject,"study":0.0,"work":180.0,"signals":entry.get("signals",[]).duplicate(),"reverse_engineered":true,"specimen_item":item,"acquisition":"One owned manufactured example consumed for destructive examination"}
	var specimen:Dictionary=Specimens.definition(item)
	if specimen.get("military",false):
		WorldSimulation.military.military_inventory[specimen.equipment]=int(WorldSimulation.military.military_inventory[specimen.equipment])-1
	else:
		WorldSimulation.state.resource_stockpiles[terms.resource]=float(WorldSimulation.state.resource_stockpiles[terms.resource])-1.0
	Exchange.data().collections[record.id]=record
	Exchange.log_event("Assigned a manufactured example of %s for destructive examination." % String(entry.name))
	return {"ok":true,"message":terms.message}
