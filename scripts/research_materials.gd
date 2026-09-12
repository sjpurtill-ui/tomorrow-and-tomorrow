extends RefCounted
## Finite experimental consignments use the existing paid, provisioned embassy.
const E=preload("res://scripts/society_exchange.gd")
const P=preload("res://scripts/knowledge_pathways.gd")
const Catalog=preload("res://scripts/resource_knowledge_catalog.gd")
static func available(subject:String="")->bool:
	return "material_accounting" in WorldSimulation.state.known_discoveries and "standard_measures" in WorldSimulation.state.known_discoveries and (subject.is_empty() or Catalog.EXPERIMENTAL_SUPPLIES.has(subject))
static func needed(subject:String)->Dictionary:
	var result:Dictionary={}
	var entry:=WorldSimulation.discovery.discovery_definition(subject)
	for requirement:Dictionary in entry.get("resource_requirements",[]):
		if WorldSimulation.discovery._resource_requirements_met([requirement]):continue
		var amount:=float(requirement.get("minimum_stock",0.0))
		if amount>0:
			var resource:=String(requirement.resource)
			result[resource]=maxf(0.0,amount-float(WorldSimulation.state.resource_stockpiles.get(resource,0)))
	return result
static func describe(cargo:Dictionary)->String:
	var parts:Array[String]=[]
	for resource:String in cargo:parts.append("%.1f %s" % [float(cargo[resource]),resource])
	return ", ".join(parts)
static func quote(source:String,subject:String,payment:String)->Dictionary:
	if not available(subject):return {"error":"Experimental consignments need material accounting, standard measures and a supported material investigation."}
	var entry:=WorldSimulation.discovery.discovery_definition(subject)
	if entry.is_empty() or subject in WorldSimulation.state.known_discoveries or not P.ready(entry,int(WorldSimulation.state.elapsed_days)):return {"error":"Choose an unresolved investigation with its local knowledge foundations in place."}
	var cargo:=needed(subject)
	if cargo.is_empty():return {"error":"The material basis for this investigation is already available locally."}
	var terms:Dictionary=WorldSimulation.world.diplomatic_mission_quote(source,payment,"goodwill")
	if terms.has("error"):return terms
	terms["materials_requested"]=cargo
	terms["purpose_label"]="REQUEST EXPERIMENTAL MATERIALS"
	terms["message"]="Offer %s for %s. Travel provisions: %.1f Food; expected round trip: %d days. The supplier must have the actual stock and may refuse. Materials become available only on return; they grant no discovery, mine or production facility. Local research and later replenishment remain necessary." % [terms.gift.label,describe(cargo),float(terms.provisions),int(terms.total_days)]
	return terms
static func dispatch(source:String,subject:String,payment:String)->Dictionary:
	var terms:=quote(source,subject,payment)
	if terms.has("error"):return terms
	var result:Dictionary=WorldSimulation.world.dispatch_diplomat(source,payment,"goodwill",subject,"materials")
	if result.get("ok",false):result["message"]=terms.message
	return result
static func valid(mission:Dictionary)->bool:
	var subject:=String(mission.get("research_subject",""))
	var limits:Dictionary=Catalog.EXPERIMENTAL_SUPPLIES.get(subject,{})
	var requested:Variant=mission.get("materials_requested")
	if limits.is_empty() or not requested is Dictionary or requested.is_empty() or requested.size()>4:return false
	for resource:Variant in requested:
		if not resource is String or not limits.has(resource) or not E.number(requested[resource]) or requested[resource]<=0 or requested[resource]>limits[resource]:return false
	var cargo:Variant=mission.get("material_cargo",{})
	if not cargo is Dictionary or cargo.size()>4:return false
	if not cargo.is_empty() and cargo!=requested:return false
	if mission.has("materials_delivered") and not mission.materials_delivered is bool:return false
	if mission.get("materials_delivered",false) and (cargo.is_empty() or mission.get("research_refused",false)):return false
	if mission.get("research_refused",false) and not cargo.is_empty():return false
	return true
static func negotiate(mission:Dictionary,source:String,day:int)->void:
	if mission.has("research_refused") or day<int(mission.get("arrival_day",day+1)):return
	if E.owner_id(source)!=E.owner_id(String(mission.get("civ_id",""))):return
	var provider:=E.owner_state(source)
	var accepted:=provider!=null and valid(mission) and float(mission.get("gift_amount",0))>0
	if accepted:
		accepted=provider.effective_workers("Logistics")>=1
	if accepted:
		for resource:String in mission.materials_requested:
			if float(provider.resource_stockpiles.get(resource,0))<float(mission.materials_requested[resource]):accepted=false;break
	mission["research_refused"]=not accepted;mission["accepted"]=accepted
	mission["outcome"]="The supplier packed the requested experimental materials. They are traveling with the returning envoys." if accepted else "The supplier could not fill the material consignment. The unused payment returned with the envoys."
	if not accepted:return
	for resource:String in mission.materials_requested:provider.resource_stockpiles[resource]=float(provider.resource_stockpiles[resource])-float(mission.materials_requested[resource])
	mission["material_cargo"]=mission.materials_requested.duplicate(true)
static func prepare_return(mission:Dictionary)->void:
	if mission.get("material_cargo",{}).is_empty():
		mission["research_refused"]=true;mission["accepted"]=false
		mission["outcome"]="No experimental material consignment was obtained. The unused payment returned with the envoys."
	else:mission["outcome"]="The envoys brought home %s for local experiments. The consignment grants no discovery or mine." % describe(mission.material_cargo)
static func deliver(mission:Dictionary,day:int)->Array[Dictionary]:
	if mission.get("materials_delivered",false) or mission.get("research_refused",false) or day<int(mission.get("return_day",day+1)) or not valid(mission):return []
	var cargo:Dictionary=mission.get("material_cargo",{})
	if cargo.is_empty():return []
	for resource:String in cargo:WorldSimulation.state.resource_stockpiles[resource]=float(WorldSimulation.state.resource_stockpiles.get(resource,0))+float(cargo[resource])
	mission["materials_delivered"]=true
	return [{"title":"Experimental consignment: "+describe(cargo),"consequence":"These finite materials support local experiments. No knowledge, deposit or workshop was granted."}]
