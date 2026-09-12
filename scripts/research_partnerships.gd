extends RefCounted
## Bilateral investigations use collection study and ordinary physical envoys.
## No shared omniscient progress counter or independent research workforce.
const E=preload("res://scripts/society_exchange.gd")
const P=preload("res://scripts/knowledge_pathways.gd")
static func available()->bool:
	return "public_schools" in WorldSimulation.state.known_discoveries and "experimental_controls" in WorldSimulation.state.known_discoveries
static func key(peer:String,subject:String,result:bool=false)->String:
	return ("partnership_result:" if result else "partnership_protocol:")+E.owner_id(peer)+":"+subject
static func pending(subject:String)->bool:
	for protocol:Dictionary in E.data().collections.values():
		if protocol.get("partnership_protocol",false) and protocol.discovery_id==subject and not E.data().collections.has(key(String(protocol.source_id),subject,true)):return true
	return false
static func quote(peer:String,subject:String,resource:String)->Dictionary:
	if not available():return {"error":"Joint investigations need public schools and experimental controls."}
	var entry:=WorldSimulation.discovery.discovery_definition(subject)
	var protocol:Dictionary=E.data().collections.get(key(peer,subject),{})
	if entry.is_empty() or (protocol.is_empty() and subject in WorldSimulation.state.known_discoveries) or not P.ready(entry,int(WorldSimulation.state.elapsed_days)):return {"error":"Choose an unresolved investigation with its foundations in place."}
	if WorldSimulation.state.effective_workers("Knowledge")<1:return {"error":"Assign Knowledge workers to contribute to a joint investigation."}
	if E.data().collections.has(key(peer,subject,true)):return {"error":"The joint findings have already been brought home."}
	if not protocol.is_empty() and float(protocol.study)<1:return {"error":"Complete your agreed investigation before exchanging findings (%.0f%% studied)." % (float(protocol.study)*100)}
	if E.data().collections.size()>=E.COLLECTION_LIMIT:return {"error":"The collection has no room for the research material."}
	var terms:Dictionary=WorldSimulation.world.diplomatic_mission_quote(peer,resource,"goodwill")
	if terms.has("error"):return terms
	terms["partnership_phase"]="propose" if protocol.is_empty() else "exchange"
	terms["purpose_label"]="PROPOSE JOINT INVESTIGATION" if protocol.is_empty() else "EXCHANGE JOINT FINDINGS"
	terms["message"]=("Offer %s to investigate %s together. Both sides must complete 180 units of local study. Then send another delegation to exchange findings; returned results need 60 units of validation." if protocol.is_empty() else "Offer %s and carry your completed findings on %s. The partner must have completed its investigation and agree to share. Returned results need 60 units of local validation.") % [terms.gift.label,entry.name]
	terms.message+=" This trip needs %.1f Food and approximately %d days. Unused payment returns if refused." % [float(terms.provisions),int(terms.total_days)]
	return terms
static func dispatch(peer:String,subject:String,resource:String)->Dictionary:
	return WorldSimulation.world.dispatch_diplomat(peer,resource,"goodwill",subject,"partnership")
static func item(peer:String,name:String,subject:String,position:Dictionary,day:int,result:bool)->Dictionary:
	var entry:=WorldSimulation.discovery.discovery_definition(subject)
	return {"id":key(peer,subject,result),"kind":"knowledge","name":("Joint findings: " if result else "Joint investigation: ")+String(entry.get("name",subject)),"source_id":E.owner_id(peer),"source_name":name,"position":position.duplicate(),"observed_day":day,"returned_day":day,"discovery_id":subject,"study":0.0,"work":60.0 if result else 180.0,"signals":entry.get("signals",[]).duplicate(),"partnership_protocol":not result,"research_partnership":result}
static func negotiate(mission:Dictionary,peer:String,name:String,position:Dictionary,day:int)->void:
	var subject:=String(mission.research_subject)
	var phase:=String(mission.get("partnership_phase",""))
	var provider:=E.owner_state(peer)
	var accepted:=provider!=null and float(mission.get("gift_amount",0))>0 and phase in ["propose","exchange"]
	var host:=WorldSimulation.actor_id
	var incoming_key:=key(host,subject,phase=="exchange")
	if accepted:accepted=provider.society_exchange.sharing_policy=="open" and provider.society_exchange.collections.size()<E.COLLECTION_LIMIT and not provider.society_exchange.collections.has(incoming_key)
	if accepted and phase=="propose":
		accepted=bool(WorldSimulation.scoped(E.owner_id(peer),func()->bool:
			return available() and WorldSimulation.state.effective_workers("Knowledge")>=1 and P.ready(WorldSimulation.discovery.discovery_definition(subject),day) and subject not in WorldSimulation.state.known_discoveries))
	if accepted and phase=="exchange":
		var local:Dictionary=E.data().collections.get(key(peer,subject),{})
		var remote:Dictionary=provider.society_exchange.collections.get(key(host,subject),{})
		accepted=float(local.get("study",0))>=1 and float(remote.get("study",0))>=1
	mission["research_refused"]=not accepted;mission["accepted"]=accepted
	mission["outcome"]="The partner agreed to a joint investigation. Complete local study, then send findings by another delegation." if phase=="propose" else "Both completed investigations were exchanged. Researchers must validate the returned findings."
	if not accepted:
		mission.outcome="The partner could not agree or exchange completed findings on these terms. Unused payment returns."
		return
	var incoming:=item(host,host,subject,mission.get("origin_position",{"x":0.0,"z":0.0}),day,phase=="exchange")
	provider.society_exchange.collections[incoming.id]=incoming
	if not mission.has("carried_collections"):mission.carried_collections=[]
	mission.carried_collections.append(item(peer,name,subject,position,day,phase=="exchange"))
static func prepare_return(mission:Dictionary)->void:
	var expected:=key(String(mission.civ_id),String(mission.research_subject),mission.get("partnership_phase","")=="exchange")
	var found:=false;var incoming:=0
	for report:Dictionary in mission.get("carried_collections",[]):
		if report.id==expected:found=true
		if not E.data().collections.has(report.id):incoming+=1
	if not found or E.data().collections.has(expected) or E.data().collections.size()+incoming>E.COLLECTION_LIMIT:
		mission["research_refused"]=true;mission["accepted"]=false
		mission["outcome"]="No new partnership material was delivered. Unused payment returns."
