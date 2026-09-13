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

static func condition(place:String,subject:String)->Dictionary:
	if settlement(place).is_empty():return {}
	return WorldSimulation.settlements.with_city_resources(place,func()->Dictionary:
		return WorldSimulation.settlements.with_local_population(func()->Dictionary:
			var state=WorldSimulation.state
			var population:=maxf(0,float(state.population_exact))
			if population<=0:return {}
			var ratio:=1.0
			match subject:
				"water":ratio=clampf(float(state.water_metrics.get("intake_ratio",1)),0,1)
				"provisions":ratio=clampf(float(state.simulation_metrics.get("food_intake_ratio",1)),0,1)
				"shelter":ratio=clampf(float(state.housing_capacity)/population,0,1)
				_:return {}
			return {"subject":subject,"ratio":ratio,"affected_population":population*(1-ratio),"day":int(state.elapsed_days),"active":ratio<.98}
		)
	)
static func observe_petitions(host:Node)->void:
	if not known("petition_registers"):return
	var d:Dictionary=host.administration_records
	for site:Dictionary in WorldSimulation.state.player_settlements:
		var place:=String(site.get("id",""))
		var person:=int(site.get("leader_person_id",0))
		if not appointed(host,place,person):continue
		for subject:String in ["water","provisions","shelter"]:
			var observation:=condition(place,subject)
			if not observation.get("active",false):continue
			var duplicate:=false
			for petition:Dictionary in d.petitions:
				if petition.settlement_id==place and petition.subject==subject and (petition.state!="resolved" or int(WorldSimulation.state.elapsed_days)-int(petition.get("disposed_day",0))<30):duplicate=true;break
			if duplicate:continue
			if d.petitions.size()>=MAX_RECORDS:
				for i in d.petitions.size():
					if d.petitions[i].state=="resolved" and int(WorldSimulation.state.elapsed_days)-int(d.petitions[i].disposed_day)>=30:
						d.petitions.remove_at(i);break
			if d.petitions.size()>=MAX_RECORDS or int(d.next_id)>=1000000000:return
			if not spend(host,.25):return
			var id:=int(d.next_id);d.next_id=id+1
			d.petitions.append({"id":id,"settlement_id":place,"subject":subject,"state":"open","recorded_day":int(WorldSimulation.state.elapsed_days),"recorded_by":person,"observation":observation,"dispositions":[]})
			WorldSimulation.advisors._append_civic_dialogue(place,{"day":int(WorldSimulation.state.elapsed_days),"speaker":"leader","speaker_name":String(host.person_snapshot(person).get("name","Local leader")),"text":"I recorded petition %d about %s: current provision meets %.0f%% of local need. I can address it, defer it, or review it once conditions improve." % [id,subject,float(observation.ratio)*100],"source":"household condition petition","status":"petition_open"})
static func petition_by_id(host:Node,id:int)->Dictionary:
	for p:Dictionary in host.administration_records.petitions:
		if int(p.id)==id:return p
	return {}
static func dispose_petition(host:Node,place:String,person:int,id:int,action:String)->Dictionary:
	if not known("petition_registers"):return {"error":"We have not established petition records."}
	var p:=petition_by_id(host,id)
	if p.is_empty() or p.settlement_id!=place:return {"error":"That petition does not belong to this settlement."}
	if not appointed(host,place,person):return {"error":"The appointed local official must handle this petition."}
	if known("official_mandate_registers") and not authorized(host,place,person,p.subject):return {"error":"My current mandate does not authorize that matter."}
	if action not in ["address","defer","resolve"]:return {"error":"That petition action is not supported."}
	if p.state=="resolved":return {"error":"That petition is already resolved."}
	if p.dispositions.size()>=32:return {"error":"This petition's disposition record is full."}
	var observation:=condition(place,p.subject)
	if observation.is_empty():return {"error":"I cannot verify the settlement's present condition."}
	if action=="resolve" and observation.active:return {"error":"The recorded shortage still exists. I cannot report it as resolved."}
	if float(host.administration_records.work)<.25:return {"error":"The clerks need time to record this disposition."}
	if action=="address":
		var result:Dictionary=host.set_settlement_focus(place,p.subject)
		if not result.get("ok",false):return {"error":String(result.get("reason","The work could not be assigned."))}
	spend(host,.25)
	p.state={"address":"addressing","defer":"deferred","resolve":"resolved"}[action]
	p["disposed_day"]=int(WorldSimulation.state.elapsed_days)
	p.dispositions.append({"day":int(WorldSimulation.state.elapsed_days),"person_id":person,"action":action,"observation":observation})
	return {"ok":true,"message":{"address":"I have directed local work toward this shortage. The petition remains open until conditions improve.","defer":"I have recorded the deferral; the shortage remains on the record.","resolve":"The current observation meets the requirement. I have recorded the petition as resolved."}[action]}
static func conversation(host:Node,place:String,person:int,text:String)->Dictionary:
	var normalized:=text.strip_edges().to_lower().trim_suffix(".").trim_suffix("?")
	if normalized in ["show petitions","review petitions","what petitions are pending","show the petition register"]:
		if not known("petition_registers"):return {"handled":true,"message":"We have not established a petition register."}
		var lines:Array[String]=[]
		for p:Dictionary in host.administration_records.petitions:
			if p.settlement_id==place and p.state!="resolved":lines.append("Petition %d: %s — %s" % [int(p.id),String(p.subject),String(p.state)])
		return {"handled":true,"message":"No unresolved petitions are recorded here." if lines.is_empty() else "\n".join(lines)}
	var result:Dictionary={}
	if normalized in ["record our jurisdiction","record this settlement's jurisdiction"]:result=register_jurisdiction(host,place,SUBJECTS)
	elif normalized in ["record your mandate","renew your mandate"]:
		result=issue_mandate(host,place,person,host.administration_records.jurisdictions.get(place,{}).get("subjects",[]),90)
	else:
		var words:=normalized.split(" ",false)
		if words.size()!=3 or words[0] not in ["address","defer","resolve"] or words[1]!="petition" or not words[2].is_valid_int():return {}
		result=dispose_petition(host,place,person,int(words[2]),words[0])
	return {"handled":true,"ok":result.get("ok",false),"message":String(result.get("error",result.get("message","I have recorded the jurisdiction." if normalized.contains("jurisdiction") else "I have recorded my authorized duties for90 days.")))}

static func number(v:Variant,low:float=0,high:float=1000000000)->bool:
	return (v is int or v is float) and is_finite(float(v)) and float(v)>=low and float(v)<=high
static func integer(v:Variant,low:int=0)->bool:return number(v,low) and floorf(float(v))==float(v)
static func short_string(v:Variant)->bool:return v is String and not v.is_empty() and v.length()<=128
static func valid_subjects(v:Variant)->bool:
	if not v is Array or v.size()>SUBJECTS.size():return false
	var seen:Array=[]
	for subject:Variant in v:
		if not subject is String or subject not in SUBJECTS or subject in seen:return false
		seen.append(subject)
	return true
static func valid_observation(v:Variant)->bool:
	return v is Dictionary and v.get("subject") in ["water","provisions","shelter"] and number(v.get("ratio"),0,1) and number(v.get("affected_population")) and integer(v.get("day")) and v.get("active") is bool and v.active==(float(v.ratio)<.98)
static func valid(v:Variant)->bool:
	if not v is Dictionary or not v.has_all(["last_day","work","jurisdictions","mandates","handovers","petitions","next_id"]):return false
	if not integer(v.last_day,-1) or not number(v.work,0,30) or not integer(v.next_id,1):return false
	if v.has("last_reserved_work") and not number(v.last_reserved_work):return false
	for field:String in ["jurisdictions","mandates"]:
		if not v[field] is Dictionary or v[field].size()>MAX_RECORDS:return false
		for key:Variant in v[field]:
			var r:Variant=v[field][key]
			if not short_string(key) or not r is Dictionary or r.get("settlement_id")!=key or not valid_subjects(r.get("subjects")):return false
			if field=="jurisdictions":
				if not integer(r.get("recorded_day")):return false
			else:
				if not integer(r.get("person_id"),1) or not integer(r.get("issued_day")) or not integer(r.get("expires_day")):return false
				if int(r.expires_day)<=int(r.issued_day) or int(r.expires_day)-int(r.issued_day)>365:return false
	var ids:Array=[]
	for field:String in ["handovers","petitions"]:
		if not v[field] is Array or v[field].size()>MAX_RECORDS:return false
		for r:Variant in v[field]:
			if not r is Dictionary or not integer(r.get("id"),1) or int(r.id)>=int(v.next_id) or int(r.id) in ids or not short_string(r.get("settlement_id")):return false
			ids.append(int(r.id))
			if field=="handovers":
				if not short_string(r.get("order_id")) or not integer(r.get("from_person"),1) or not integer(r.get("to_person"),1) or not integer(r.get("queued_day")) or r.get("state") not in ["pending","completed","superseded"]:return false
				if r.state=="completed" and (not integer(r.get("completed_day")) or int(r.completed_day)<int(r.queued_day)):return false
			else:
				if r.get("subject") not in ["water","provisions","shelter"] or r.get("state") not in ["open","addressing","deferred","resolved"] or not integer(r.get("recorded_day")) or not integer(r.get("recorded_by"),1) or not valid_observation(r.get("observation")):return false
				if not r.get("dispositions") is Array or r.dispositions.size()>32:return false
				for action:Variant in r.dispositions:
					if not action is Dictionary or not integer(action.get("day")) or not integer(action.get("person_id"),1) or action.get("action") not in ["address","defer","resolve"] or not valid_observation(action.get("observation")):return false
					if action.action=="resolve" and action.observation.active:return false
				if r.state!="open" and (not integer(r.get("disposed_day")) or r.dispositions.is_empty()):return false
	return true
