extends RefCounted
## Records belong to GovernmentPeopleSystem; no people or labor are created here.
const MAX_RECORDS=128
const SUBJECTS=["provisions","water","shelter","work","disputes"]
static func empty_state()->Dictionary:
	return {"last_day":-1,"work":0.0,"jurisdictions":{},"mandates":{},"handovers":[],"petitions":[],"next_id":1}
static func known(id:String)->bool:return id in WorldSimulation.state.known_discoveries
static func settlement(id:String)->Dictionary:
	for place:Dictionary in WorldSimulation.state.player_settlements:
		if String(place.get("id",""))==id and String(place.get("occupied_by","" )).is_empty():return place
	return {}
static func appointed(host:Node,place:String,person:int)->bool:
	var site:=settlement(place)
	var holder:Dictionary=host.person_snapshot(person)
	return not site.is_empty() and int(site.get("leader_person_id",0))==person and not holder.is_empty() and holder.get("status")=="active"
static func spend(host:Node,amount:float)->bool:
	if float(host.administration_records.work)<amount:return false
	host.administration_records.work-=amount
	return true
static func reserved(state:Node,capacity:float)->float:
	if not state.resource_settlement_id.is_empty():return 0.0
	if not state.settlement_site_committed or state.convoy_traveling:return 0.0
	if "jurisdiction_boundaries" not in state.known_discoveries and "petition_registers" not in state.known_discoveries and "public_office_handover" not in state.known_discoveries:return 0.0
	# Standing primary-office duty, deducted by the shared worker API even before
	# government processing. Other settlements do not fund this register twice.
	return maxf(0.0,capacity)*.1
static func credit_day(host:Node,day:int)->void:
	var d:Dictionary=host.administration_records
	if day<=int(d.last_day):return
	d.last_day=day
	# Called by the government's daily owner, with at most one day's allocation.
	# Missed days never create a retrospective balance of fictional clerical work.
	if not known("jurisdiction_boundaries") and not known("petition_registers") and not known("public_office_handover"):return
	var state=WorldSimulation.state
	var paid:=reserved(state,state.effective_workers("Administration",false,false,true))
	d.work=minf(30.0,float(d.work)+paid)
	d["last_reserved_work"]=paid
static func register_jurisdiction(host:Node,place:String,subjects:Array)->Dictionary:
	if not known("jurisdiction_boundaries"):return {"error":"We have not established jurisdiction records."}
	if settlement(place).is_empty():return {"error":"That settlement is not under our authority."}
	if subjects.is_empty() or subjects.size()>SUBJECTS.size():return {"error":"Specify the matters this authority handles."}
	var unique:Array[String]=[]
	for subject:Variant in subjects:
		if not subject is String or subject not in SUBJECTS or subject in unique:return {"error":"The jurisdiction contains an unsupported or repeated subject."}
		unique.append(subject)
	var d:Dictionary=host.administration_records
	if not d.jurisdictions.has(place) and d.jurisdictions.size()>=MAX_RECORDS:return {"error":"The jurisdiction register is full."}
	if not spend(host,1.0):return {"error":"The clerks need time to record these boundaries."}
	d.jurisdictions[place]={"settlement_id":place,"subjects":unique,"recorded_day":int(WorldSimulation.state.elapsed_days)}
	# Revised boundaries cannot preserve powers that are no longer recorded.
	if d.mandates.has(place):
		for subject:String in d.mandates[place].subjects.duplicate():
			if subject not in unique:d.mandates[place].subjects.erase(subject)
	return {"ok":true,"jurisdiction":d.jurisdictions[place].duplicate(true)}
static func issue_mandate(host:Node,place:String,person:int,subjects:Array,days:int)->Dictionary:
	if not known("official_mandate_registers"):return {"error":"We have not established mandate registers."}
	if not appointed(host,place,person):return {"error":"Only the appointed local official can receive this mandate."}
	var d:Dictionary=host.administration_records
	var jurisdiction:Dictionary=d.jurisdictions.get(place,{})
	if jurisdiction.is_empty():return {"error":"Record this settlement's jurisdiction first."}
	if days<1 or days>365:return {"error":"A mandate needs a term of one to365 days."}
	if subjects.is_empty() or subjects.size()>SUBJECTS.size():return {"error":"Specify the authorized duties."}
	var unique:Array[String]=[]
	for subject:Variant in subjects:
		if not subject is String or subject not in jurisdiction.subjects or subject in unique:return {"error":"That duty is outside the registered jurisdiction."}
		unique.append(subject)
	if not d.mandates.has(place) and d.mandates.size()>=MAX_RECORDS:return {"error":"The mandate register is full."}
	if not spend(host,1.0):return {"error":"The clerks need time to record the mandate."}
	var day:=int(WorldSimulation.state.elapsed_days)
	d.mandates[place]={"settlement_id":place,"person_id":person,"subjects":unique,"issued_day":day,"expires_day":day+days}
	return {"ok":true,"mandate":d.mandates[place].duplicate(true)}
static func authorized(host:Node,place:String,person:int,subject:String)->bool:
	if not known("official_mandate_registers") or not appointed(host,place,person):return false
	var d:Dictionary=host.administration_records
	var m:Dictionary=d.mandates.get(place,{})
	var j:Dictionary=d.jurisdictions.get(place,{})
	var day:=int(WorldSimulation.state.elapsed_days)
	return not m.is_empty() and not j.is_empty() and int(m.person_id)==person and day>=int(m.issued_day) and day<int(m.expires_day) and subject in m.subjects and subject in j.subjects

static func order_by_id(id:String)->Dictionary:
	for order:Dictionary in WorldSimulation.state.sovereign_orders:
		if String(order.get("id",""))==id:return order
	return {}
static func queue_handovers(host:Node,place:String,successor:int)->void:
	if not known("public_office_handover") or not appointed(host,place,successor):return
	var d:Dictionary=host.administration_records
	for order:Dictionary in WorldSimulation.state.sovereign_orders:
		if String(order.get("settlement_id",""))!=place:continue
		var f:Dictionary=order.get("implementation_followup",{})
		if f.get("state")!="pending":continue
		var previous:=int(f.get("custodian_person_id",f.get("leader_person_id",0)))
		if previous<=0 or previous==successor:continue
		if f.get("handover_state")=="pending" and int(f.get("handover_successor",0))==successor:continue
		while d.handovers.size()>=MAX_RECORDS:
			var retired:=-1
			for i in d.handovers.size():
				if d.handovers[i].state!="pending":retired=i;break
			if retired<0:return
			d.handovers.remove_at(retired)
		if int(d.next_id)>=1000000000:return
		var id:=int(d.next_id);d.next_id=id+1
		d.handovers.append({"id":id,"order_id":String(order.get("id","")),"settlement_id":place,"from_person":previous,"to_person":successor,"queued_day":int(WorldSimulation.state.elapsed_days),"state":"pending"})
		f["handover_id"]=id;f["handover_state"]="pending";f["handover_successor"]=successor
static func process_handovers(host:Node)->void:
	if not known("public_office_handover"):return
	var d:Dictionary=host.administration_records
	for record:Dictionary in d.handovers:
		if record.state!="pending":continue
		var order:=order_by_id(record.order_id)
		var f:Dictionary=order.get("implementation_followup",{})
		if f.get("state")!="pending" or int(f.get("handover_id",0))!=int(record.id):record.state="superseded";continue
		if not appointed(host,record.settlement_id,int(record.to_person)):continue
		if known("official_mandate_registers") and not authorized(host,record.settlement_id,int(record.to_person),"work"):continue
		if not spend(host,.5):return
		f["custodian_person_id"]=int(record.to_person)
		f["handover_state"]="completed";f["custody_day"]=int(WorldSimulation.state.elapsed_days)
		record.state="completed";record["completed_day"]=int(WorldSimulation.state.elapsed_days)
		host.record_person_memory(int(record.to_person),"I received the pending civic duty recorded as "+String(record.order_id)+" from my predecessor.","civic_handover",.6,{"order_id":record.order_id,"from_person":record.from_person})
static func can_review(host:Node,followup:Dictionary)->bool:
	if followup.get("handover_state")=="pending":return false
	if not followup.has("custodian_person_id"):return true
	var place:=String(followup.get("settlement_id",""))
	var person:=int(followup.custodian_person_id)
	if not appointed(host,place,person):return false
	return not known("official_mandate_registers") or authorized(host,place,person,"work")
