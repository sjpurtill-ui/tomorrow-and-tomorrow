extends RefCounted
## Purchase an existing validated study through the ordinary physical embassy.
## Payment uses its carried goods; evidence uses the existing collection and
## Knowledge workforce. This does not create a second research ledger.
const Exchange=preload("res://scripts/society_exchange.gd")
const Pathways=preload("res://scripts/knowledge_pathways.gd")

static func available()->bool:
	return "experimental_controls" in WorldSimulation.state.known_discoveries and "public_schools" in WorldSimulation.state.known_discoveries

static func quote(source:String,subject:String,resource:String)->Dictionary:
	if not available():return {"error":"Research purchasing needs experimental controls and public schools to assess and reproduce a study."}
	var entry:=WorldSimulation.discovery.discovery_definition(subject)
	if entry.is_empty() or subject in WorldSimulation.state.known_discoveries or not Pathways.ready(entry,int(WorldSimulation.state.elapsed_days)):
		return {"error":"Choose an unresolved question your researchers can investigate."}
	if Exchange.data().collections.has(key(source,subject)):return {"error":"This study has already been brought home."}
	if Exchange.data().collections.size()>=Exchange.COLLECTION_LIMIT:return {"error":"The collection has no room for another study."}
	var result:Dictionary=WorldSimulation.world.diplomatic_mission_quote(source,resource,"goodwill")
	if result.has("error"):return result
	result["subject"]=subject
	result["purpose_label"]="PURCHASE VALIDATED RESEARCH"
	result["message"]="Offer %s for a validated study of %s. Travel provisions: %.1f Food; expected round trip: %d days. The supplier may refuse; unused payment returns with the envoys. Returned studies require local examination." % [result.gift.label,entry.name,float(result.provisions),int(result.total_days)]
	return result

static func dispatch(source:String,subject:String,resource:String)->Dictionary:
	var terms:=quote(source,subject,resource)
	if terms.has("error"):return terms
	var result:Dictionary=WorldSimulation.world.dispatch_diplomat(source,resource,"goodwill",subject)
	if not result.get("ok",false):return result
	var mission:Dictionary=WorldSimulation.world.diplomatic_mission
	mission["research_subject"]=subject
	mission["purpose_label"]="PURCHASE VALIDATED RESEARCH"
	result["message"]=terms.message
	return result

static func key(source:String,subject:String)->String:
	return "purchase:"+Exchange.owner_id(source)+":"+subject

static func negotiate(mission:Dictionary,source:String,source_name:String,position:Dictionary,day:int)->void:
	if not mission.has("research_subject") or mission.has("research_refused"):return
	if Exchange.owner_id(String(mission.get("civ_id","")))!=Exchange.owner_id(source) or day<int(mission.get("arrival_day",day+1)):return
	if mission.get("research_mode","purchase")=="scholar":
		preload("res://scripts/scholar_visits.gd").negotiate(mission,source,day);return
	if mission.get("research_mode","purchase")=="partnership":
		preload("res://scripts/research_partnerships.gd").negotiate(mission,source,source_name,position,day);return
	var subject:=String(mission.research_subject)
	var provider:=Exchange.owner_state(source)
	var accepted:=provider!=null and float(mission.get("gift_amount",0))>0
	if accepted:
		accepted=subject in provider.known_discoveries and provider.society_exchange.sharing_policy=="open"
	if accepted:
		accepted=bool(WorldSimulation.scoped(Exchange.owner_id(source),func()->bool:return WorldSimulation.discovery.adoption(subject)>=.35 and WorldSimulation.state.effective_workers("Knowledge")>=1))
	mission["research_refused"]=not accepted
	mission["accepted"]=accepted
	mission["outcome"]="The supplier provided a validated study. Your researchers must examine and reproduce its results." if accepted else "The supplier could not provide this study on the offered terms. The payment returned with the envoys."
	if not accepted:return
	var entry:=WorldSimulation.discovery.discovery_definition(subject)
	if entry.is_empty():mission.research_refused=true;mission.accepted=false;return
	if not mission.has("carried_collections"):mission.carried_collections=[]
	mission.carried_collections.append({"id":key(source,subject),"kind":"knowledge","name":"Purchased study: "+String(entry.name),"source_id":Exchange.owner_id(source),"source_name":source_name,"position":position.duplicate(),"observed_day":day,"returned_day":day,"discovery_id":subject,"study":0.0,"work":120.0,"signals":entry.get("signals",[]).duplicate(),"research_purchase":true,"acquisition":"Validated research purchased for %s %s" % [mission.get("gift_amount",0),mission.get("gift_resource","")]})

static func prepare_return(mission:Dictionary)->void:
	if not mission.has("research_subject"):return
	if mission.get("research_mode","purchase")=="scholar":
		preload("res://scripts/scholar_visits.gd").deliver(mission);return
	if mission.get("research_mode","purchase")=="partnership":
		preload("res://scripts/research_partnerships.gd").prepare_return(mission);return
	var report_key:=key(String(mission.civ_id),String(mission.research_subject))
	var carried:=false
	var incoming:=0
	for item:Dictionary in mission.get("carried_collections",[]):
		if item.id==report_key:carried=true
		if not Exchange.data().collections.has(item.id):incoming+=1
	if not carried or Exchange.data().collections.size()+incoming>Exchange.COLLECTION_LIMIT or Exchange.data().collections.has(report_key):
		mission["research_refused"]=true;mission["accepted"]=false
		mission["outcome"]="No new usable study was delivered. The unused research payment returned with the envoys."

static func refund(mission:Dictionary)->void:
	if not mission.has("research_subject") or not mission.get("research_refused",false) or mission.get("research_refunded",false):return
	mission["research_refunded"]=true
	WorldSimulation.food.receive_external_food(float(mission.get("scholar_provisions",0)))
	var amount:=float(mission.get("gift_amount",0))
	var resource:=String(mission.get("gift_resource",""))
	if resource=="Food":WorldSimulation.food.receive_external_food(amount)
	elif amount>0:WorldSimulation.state.resource_stockpiles[resource]=float(WorldSimulation.state.resource_stockpiles.get(resource,0))+amount
