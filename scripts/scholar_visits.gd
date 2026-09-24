extends RefCounted
## Temporary specialists remain members of their source population. Their
## Knowledge capacity is unavailable there until their scheduled return.
const E=preload("res://scripts/society_exchange.gd")
const P=preload("res://scripts/knowledge_pathways.gd")
const DURATION:=60
const LIMIT:=32

static func available()->bool:
	return "apprentice_contracts" in WorldSimulation.state.known_discoveries or "public_schools" in WorldSimulation.state.known_discoveries

static func quote(source:String,subject:String,resource:String)->Dictionary:
	if not available():return {"error":"Visiting teachers need apprenticeship contracts or public schools."}
	var entry:=WorldSimulation.discovery.discovery_definition(subject)
	if entry.is_empty() or subject in WorldSimulation.state.known_discoveries or not P.ready(entry,int(WorldSimulation.state.elapsed_days)):
		return {"error":"Choose an unresolved investigation with its foundations in place."}
	if WorldSimulation.state.effective_workers("Knowledge")<1:return {"error":"Assign Knowledge workers to learn from the visitor."}
	if E.data().get("scholar_visits",{}).size()>=LIMIT:return {"error":"The visiting scholar register is full."}
	for contract:Dictionary in E.data().get("scholar_visits",{}).values():
		if contract.host==WorldSimulation.actor_id and contract.subject==subject and int(contract.home_day)>int(WorldSimulation.state.elapsed_days):return {"error":"A scholar visit for this investigation is already arranged."}
	var result:Dictionary=WorldSimulation.world.diplomatic_mission_quote(source,resource,"goodwill")
	if result.has("error"):return result
	var rations:=(DURATION+2*int(result.travel_days))*.55
	var required:=float(result.provisions)+rations+(float(result.gift.amount) if result.gift.resource=="Food" else 0.0)
	if float(WorldSimulation.state.resource_stockpiles.get("Food",0))<required:return {"error":"More stored Food is needed for the visitor's journey and stay."}
	result["scholar_provisions"]=rations
	result["purpose_label"]="INVITE VISITING SCHOLAR"
	result["message"]="Offer %s for a 60-day teacher of %s. Envoy rations: %.1f Food; visitor travel and board: %.1f Food. Teaching begins after the envoys return, requires local Knowledge staff, and ends when the scholar leaves. The source may refuse; unused payment and visitor rations return." % [result.gift.label,entry.name,float(result.provisions),rations]
	return result

static func dispatch(source:String,subject:String,resource:String)->Dictionary:
	return WorldSimulation.world.dispatch_diplomat(source,resource,"goodwill",subject,"scholar")

## A foreign envoy who brings the teacher along: the same host and provider
## rules as a returned mission (knowledge staff, register, supplier's open
## sharing, adoption and spare scholars) without our own mission slot.
static func envoy_quote(source:String,subject:String)->Dictionary:
	if not available():return {"error":"Visiting teachers need apprenticeship contracts or public schools."}
	var entry:=WorldSimulation.discovery.discovery_definition(subject)
	if entry.is_empty() or subject in WorldSimulation.state.known_discoveries or not P.ready(entry,int(WorldSimulation.state.elapsed_days)):
		return {"error":"Choose an unresolved investigation with its foundations in place."}
	if WorldSimulation.state.effective_workers("Knowledge")<1:return {"error":"Assign Knowledge workers to learn from the visitor."}
	if E.data().get("scholar_visits",{}).size()>=LIMIT:return {"error":"The visiting scholar register is full."}
	for contract:Dictionary in E.data().get("scholar_visits",{}).values():
		if contract.host==WorldSimulation.actor_id and contract.subject==subject and int(contract.home_day)>int(WorldSimulation.state.elapsed_days):return {"error":"A scholar visit for this investigation is already arranged."}
	var provider:=E.owner_state(source)
	if provider==null or not subject in provider.known_discoveries or provider.society_exchange.sharing_policy!="open" or provider.society_exchange.get("scholar_visits",{}).size()>=LIMIT:return {"error":"They have no teacher of this to spare."}
	var spare:=bool(WorldSimulation.scoped(E.owner_id(source),func()->bool:return WorldSimulation.discovery.adoption(subject)>=.35 and WorldSimulation.state.effective_workers("Knowledge")>=2))
	if not spare:return {"error":"They have no teacher of this to spare."}
	return {"ok":true,"subject_name":String(entry.name)}

## The teacher stays sixty days from today and travels home afterwards.
static func host_from_envoy(source:String,subject:String,travel_days:int)->Dictionary:
	var quote:=envoy_quote(source,subject)
	if quote.has("error"):return quote
	var day:=int(WorldSimulation.state.elapsed_days)
	var travel:=maxi(1,travel_days)
	var depart:=maxi(0,day-travel)
	var arrival:=maxi(depart+1,day)
	var id:="scholar:%s:%s:%d" % [WorldSimulation.actor_id,E.owner_id(source),depart]
	var contract:={"id":id,"source":E.owner_id(source),"host":WorldSimulation.actor_id,"subject":subject,"depart_day":depart,"arrival_day":arrival,"leave_day":arrival+DURATION,"home_day":arrival+DURATION+travel,"delivered":true}
	var provider:=E.owner_state(source)
	if not provider.society_exchange.has("scholar_visits"):provider.society_exchange["scholar_visits"]={}
	provider.society_exchange.scholar_visits[id]=contract.duplicate(true)
	if not E.data().has("scholar_visits"):E.data()["scholar_visits"]={}
	E.data().scholar_visits[id]=contract.duplicate(true)
	return {"ok":true,"message":"A teacher of %s stays sixty days, until day %d, while your Knowledge staff learn." % [String(quote.subject_name),int(contract.leave_day)]}

static func negotiate(mission:Dictionary,source:String,day:int)->void:
	if mission.has("research_refused"):return
	var provider:=E.owner_state(source)
	var accepted:=provider!=null and float(mission.get("gift_amount",0))>0
	if accepted:
		accepted=String(mission.research_subject) in provider.known_discoveries and provider.society_exchange.sharing_policy=="open" and provider.society_exchange.get("scholar_visits",{}).size()<LIMIT
	if accepted:
		accepted=bool(WorldSimulation.scoped(E.owner_id(source),func()->bool:return WorldSimulation.discovery.adoption(String(mission.research_subject))>=.35 and WorldSimulation.state.effective_workers("Knowledge")+absent(WorldSimulation.state,int(WorldSimulation.state.elapsed_days))-absent(WorldSimulation.state,day)>=2))
	mission["research_refused"]=not accepted;mission["accepted"]=accepted
	mission["outcome"]="A scholar is traveling home with the envoys for a 60-day teaching visit." if accepted else "No scholar was available on these terms. The unused payment and visitor rations return."
	if not accepted:return
	var departure:=int(mission.arrival_day)
	var travel:=maxi(1,int(mission.return_day)-departure)
	var id:="scholar:%s:%s:%d" % [WorldSimulation.actor_id,E.owner_id(source),int(mission.depart_day)]
	var contract:={"id":id,"source":E.owner_id(source),"host":WorldSimulation.actor_id,"subject":String(mission.research_subject),"depart_day":departure,"arrival_day":int(mission.return_day),"leave_day":int(mission.return_day)+DURATION,"home_day":int(mission.return_day)+DURATION+travel,"delivered":false}
	if not provider.society_exchange.has("scholar_visits"):provider.society_exchange["scholar_visits"]={}
	provider.society_exchange.scholar_visits[id]=contract.duplicate(true)
	mission["scholar_contract"]=contract

static func deliver(mission:Dictionary)->void:
	if not mission.has("scholar_contract"):
		mission["research_refused"]=true;mission["accepted"]=false
		mission["outcome"]="No scholar arrived. The unused payment and visitor rations return."
		return
	var contract:Dictionary=mission.scholar_contract
	if not E.data().has("scholar_visits"):E.data()["scholar_visits"]={}
	contract.delivered=true
	E.data().scholar_visits[contract.id]=contract.duplicate(true)
	var provider:=E.owner_state(String(contract.source))
	if provider!=null and provider.society_exchange.get("scholar_visits",{}).has(contract.id):provider.society_exchange.scholar_visits[contract.id].delivered=true

static func absent(state:Node,day:int)->int:
	var count:=0
	for contract:Dictionary in state.society_exchange.get("scholar_visits",{}).values():
		if E.owner_state(String(contract.source))==state and day>=int(contract.depart_day) and day<int(contract.home_day):count+=1
	return count

static func bonus(subject:String,day:int)->float:
	if WorldSimulation.state.effective_workers("Knowledge")<1:return 1.0
	for contract:Dictionary in E.data().get("scholar_visits",{}).values():
		if contract.host!=WorldSimulation.actor_id or contract.subject!=subject or not contract.delivered:continue
		if E.owner_state(String(contract.source))==null:continue
		if day<int(contract.arrival_day) or day>=int(contract.leave_day):continue
		var view_id:="human" if contract.source=="player" else String(contract.source)
		var index:int=WorldSimulation.world._civilization_index(view_id)
		if index<0 or WorldSimulation.world.civilizations[index].player_relation.get("at_war",false):continue
		return 1.5
	return 1.0

static func advance(day:int)->void:
	var visits:Dictionary=E.data().get("scholar_visits",{})
	for id:String in visits.keys():
		if day>=int(visits[id].home_day):visits.erase(id)

static func valid(value:Variant)->bool:
	if not value is Dictionary or value.size()>LIMIT:return false
	for key:Variant in value:
		var c:Variant=value[key]
		if not c is Dictionary:return false
		for field:String in ["id","source","host","subject"]:
			if not E.short_text(c.get(field)) or String(c[field]).is_empty():return false
		if key!=c.id or c.source==c.host or not c.get("delivered") is bool:return false
		for field:String in ["depart_day","arrival_day","leave_day","home_day"]:
			if not E.number(c.get(field)) or c[field]<0:return false
		if c.arrival_day<=c.depart_day or c.leave_day-c.arrival_day!=DURATION or c.home_day<=c.leave_day:return false
	return true
