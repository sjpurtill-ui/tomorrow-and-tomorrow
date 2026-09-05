extends Node
## Deterministic, delayed follow-through for leader-approved civic directives.
##
## The language model may help interpret what the player said, but it never
## decides whether the instruction worked.  This system revisits the policy
## after simulation time has passed, compares the original implementation
## plan with present capacity and recorded metric movement, and delivers one
## non-blocking report from the settlement's leader.

const MIN_REVIEW_DAYS:=7
const MAX_REVIEW_DAYS:=60
const MAX_INBOX_ITEMS:=80
const MAX_EVENTS:=80


func reset_for_new_world()->void:
	# Pending state lives on sovereign orders, which makes old saves compatible
	# and avoids a second source of truth for a directive's lifecycle.
	pass


func process_day(day:int=-1)->Array[Dictionary]:
	var current_day:=int(GameState.elapsed_days) if day<0 else day
	var events:Array[Dictionary]=[]
	# New commitments are discovered here rather than requiring the dialogue or
	# API code to own simulation scheduling.  This also repairs active directives
	# from saves made before delayed reports existed.
	for order_variant in GameState.sovereign_orders:
		var order:Dictionary=order_variant
		if not order.has("implementation_followup"):
			schedule_order(order,current_day)
		var followup:Dictionary=order.get("implementation_followup",{})
		if String(followup.get("state",""))=="reported":
			_ensure_report_in_dialogue(order,followup)
			_ensure_report_in_memory(order,followup)
			continue
		if String(followup.get("state",""))!="pending": continue
		_repair_pending_snapshot(order,followup)
		if current_day<int(followup.get("due_day",current_day+1)): continue
		var event:=_resolve_order(order,followup,current_day)
		if not event.is_empty(): events.append(event)
	return events


func schedule_order(order:Dictionary,day:int=-1)->Dictionary:
	if order.is_empty() or String(order.get("type",""))!="pronouncement": return {}
	if int(order.get("leader_person_id",0))<=0: return {}
	if order.has("implementation_followup"): return (order.implementation_followup as Dictionary).duplicate(true)
	var policies:=_implemented_policies(order)
	if policies.is_empty(): return {}
	var current_day:=int(GameState.elapsed_days) if day<0 else day
	var shortest_duration:=730.0
	var snapshots:Array[Dictionary]=[]
	for policy in policies:
		var duration:=clampf(float(policy.get("days",30.0)),7.0,730.0)
		shortest_duration=minf(shortest_duration,duration)
		var modifier:=_modifier_for(String(order.get("id","")),String(policy.get("id","")))
		var baseline:Dictionary={}
		if not modifier.is_empty(): baseline=(modifier.get("observation_baseline",{}) as Dictionary).duplicate(true)
		var operation_result:Dictionary=policy.get("operation_result",{})
		var operation_kind:=String(GovernmentPolicyCatalog.directive_contract(String(policy.get("id",""))).get("operation",""))
		var mission_id:=int(operation_result.get("mission_id",0))
		if mission_id<=0:
			mission_id=_mission_id_from_dispatch_status(operation_result.get("status",{}),operation_kind)
		snapshots.append({
			"id":String(policy.get("id","")),
			"requested_magnitude":float(policy.get("requested_magnitude",policy.get("magnitude",0.0))),
			"duration_days":duration,
			"office_execution":float(policy.get("office_execution_factor",policy.get("execution_factor",0.5))),
			"planned_implementation":clampf(float(policy.get("implementation_rate",policy.get("execution_factor",0.0))),0.0,1.0),
			"baseline":baseline,"directive_parameters":(policy.get("directive_parameters",{}) as Dictionary).duplicate(true),
			"operation_kind":operation_kind,"mission_id":mission_id,
		})
	var delay:=clampi(roundi(shortest_duration*0.20),MIN_REVIEW_DAYS,MAX_REVIEW_DAYS)
	var followup:Dictionary={
		"state":"pending","scheduled_day":current_day,"due_day":current_day+delay,
		"leader_person_id":int(order.get("leader_person_id",0)),
		"leader_name":String(order.get("addressed_to","The appointed leader")),
		"leader_title":String(order.get("leader_title","Local leader")),
		"settlement_id":String(order.get("settlement_id","")),
		"policies":snapshots,
	}
	order["implementation_followup"]=followup
	return followup.duplicate(true)


func pending_count()->int:
	var count:=0
	for order_variant in GameState.sovereign_orders:
		if String((order_variant as Dictionary).get("implementation_followup",{}).get("state",""))=="pending": count+=1
	return count


func outcome_for_order(order_id:String)->Dictionary:
	for order_variant in GameState.sovereign_orders:
		var order:Dictionary=order_variant
		if String(order.get("id",""))==order_id:
			return (order.get("implementation_followup",{}) as Dictionary).duplicate(true)
	return {}


func _implemented_policies(order:Dictionary)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var interpretation:Dictionary=order.get("parameters",{}).get("interpretation",{})
	for policy_variant in interpretation.get("policies",[]):
		var policy:Dictionary=policy_variant
		if String(policy.get("action","enact"))!="enact" or not bool(policy.get("applied",false)): continue
		if String(policy.get("id","")).is_empty(): continue
		result.append(policy)
	return result


func _repair_pending_snapshot(order:Dictionary,followup:Dictionary)->void:
	# Earlier saves can contain a pending review created before physical operation
	# identity was recorded. Rehydrate only missing fields from the already-saved
	# interpreted policy; never redispatch an expedition.
	var interpreted:Dictionary=order.get("parameters",{}).get("interpretation",{})
	var policies:Array=interpreted.get("policies",[])
	var snapshots:Array=followup.get("policies",[])
	for snapshot_index in snapshots.size():
		var snapshot:Dictionary=snapshots[snapshot_index]
		var policy:Dictionary={}
		for policy_variant in policies:
			if String((policy_variant as Dictionary).get("id",""))==String(snapshot.get("id","")):
				policy=policy_variant
				break
		if not snapshot.has("directive_parameters"):
			snapshot["directive_parameters"]=(policy.get("directive_parameters",{}) as Dictionary).duplicate(true)
		if not snapshot.has("operation_kind"):
			snapshot["operation_kind"]=String(GovernmentPolicyCatalog.directive_contract(String(snapshot.get("id",""))).get("operation",""))
		if String(snapshot.get("operation_kind",""))!="" and int(snapshot.get("mission_id",0))<=0:
			var operation_result:Dictionary=policy.get("operation_result",{})
			snapshot["mission_id"]=int(operation_result.get("mission_id",0))
			if int(snapshot.mission_id)<=0: snapshot["mission_id"]=_mission_id_from_dispatch_status(operation_result.get("status",{}),String(snapshot.operation_kind))
		snapshots[snapshot_index]=snapshot
	followup["policies"]=snapshots
	order["implementation_followup"]=followup


func _resolve_order(order:Dictionary,followup:Dictionary,current_day:int)->Dictionary:
	# Physical operations resolve on the party, not on an arbitrary review date.
	# Keep waiting while that exact mission remains in the field, including when
	# road conditions make it overdue.
	for snapshot_variant in followup.get("policies",[]):
		var snapshot:Dictionary=snapshot_variant
		if String(snapshot.get("operation_kind",""))=="" or not _operation_is_active(int(snapshot.get("mission_id",0))): continue
		followup["due_day"]=current_day+1
		followup["waiting_on_operation"]=true
		order["implementation_followup"]=followup
		return {}
	var policy_results:Array[Dictionary]=[]
	for snapshot_variant in followup.get("policies",[]):
		policy_results.append(_evaluate_policy(String(order.get("id","")),snapshot_variant,current_day,int(followup.get("scheduled_day",current_day))))
	if policy_results.is_empty():
		followup["state"]="cancelled"
		followup["resolved_day"]=current_day
		order["implementation_followup"]=followup
		return {}
	var success_count:=policy_results.filter(func(result:Dictionary)->bool: return String(result.outcome)=="success").size()
	var failure_count:=policy_results.filter(func(result:Dictionary)->bool: return String(result.outcome)=="failure").size()
	var outcome:="partial"
	if success_count==policy_results.size(): outcome="success"
	elif failure_count==policy_results.size(): outcome="failure"
	var leader:=_reporting_leader(followup)
	var leader_name:=String(leader.get("name",followup.get("leader_name","The appointed leader")))
	var leader_title:=String(leader.get("title",followup.get("leader_title","Local leader")))
	var report_text:=_report_text(order,policy_results,outcome,leader,followup)
	followup["state"]="reported"
	followup["resolved_day"]=current_day
	followup["outcome"]=outcome
	followup["policy_results"]=policy_results.duplicate(true)
	followup["reporter_person_id"]=int(leader.get("person_id",followup.get("leader_person_id",0)))
	followup["reporter_name"]=leader_name
	followup["report_text"]=report_text
	order["implementation_followup"]=followup
	_ensure_report_in_dialogue(order,followup,leader)
	_ensure_report_in_memory(order,followup,leader)
	var report_id:="directive_outcome_%s" % String(order.get("id","unknown"))
	GameState.council_inbox.push_front({
		"id":report_id,"advisor":leader_name,"office":leader_title,"topic":"civic directive",
		"act":{"type":"report","order_id":String(order.get("id","")),"settlement_id":String(followup.get("settlement_id",""))},
		"text":report_text,"urgency":0.72 if outcome=="failure" else 0.52 if outcome=="partial" else 0.34,
		"day":current_day,"status":"unread","report_outcome":outcome,"source_order_id":String(order.get("id","")),
	})
	if GameState.council_inbox.size()>MAX_INBOX_ITEMS: GameState.council_inbox.resize(MAX_INBOX_ITEMS)
	var title:="Directive Succeeded" if outcome=="success" else "Directive Partly Succeeded" if outcome=="partial" else "Directive Failed"
	var event:Dictionary={
		"id":report_id,"day":current_day,"title":title,"description":"%s reports: %s" % [leader_name,report_text],
		"domain":"institutions","severity":"warning" if outcome=="failure" else "notice",
		"source_order_id":String(order.get("id","")),"leader_person_id":int(followup.get("reporter_person_id",0)),
	}
	GameState.simulation_events.push_front(event)
	if GameState.simulation_events.size()>MAX_EVENTS: GameState.simulation_events.resize(MAX_EVENTS)
	return event


func _ensure_report_in_dialogue(order:Dictionary,followup:Dictionary,leader:Dictionary={})->void:
	if bool(followup.get("dialogue_recorded",false)): return
	if String(followup.get("state",""))!="reported": return
	var reporter:=leader
	if reporter.is_empty(): reporter=_reporting_leader(followup)
	AdvisorSystem.record_civic_implementation_report(
		String(followup.get("settlement_id",order.get("settlement_id",""))),order,reporter,
		String(followup.get("report_text","")),String(followup.get("outcome","partial"))
	)
	followup["dialogue_recorded"]=true
	order["implementation_followup"]=followup


func _ensure_report_in_memory(order:Dictionary,followup:Dictionary,leader:Dictionary={})->void:
	if bool(followup.get("memory_recorded",false)): return
	if String(followup.get("state",""))!="reported": return
	var reporter:=leader
	if reporter.is_empty(): reporter=_reporting_leader(followup)
	var reporter_id:=int(reporter.get("person_id",followup.get("reporter_person_id",0)))
	if reporter_id<=0 or GovernmentPeopleSystem.person_snapshot(reporter_id).is_empty(): return
	var policy_ids:Array[String]=[]
	var labels:Array[String]=[]
	for result_variant in followup.get("policy_results",[]):
		var result:Dictionary=result_variant
		var policy_id:=String(result.get("id",""))
		if not policy_id.is_empty() and not policy_ids.has(policy_id): policy_ids.append(policy_id)
		var label:=String(result.get("label",GovernmentPolicyCatalog.display_name(policy_id)))
		if not label.is_empty() and not labels.has(label): labels.append(label)
	var outcome:=String(followup.get("outcome","partial"))
	var outcome_words:="succeeded" if outcome=="success" else "failed" if outcome=="failure" else "achieved only part of its aim"
	var subject:=", ".join(labels) if not labels.is_empty() else "the civic directive"
	var original_leader_id:=int(followup.get("leader_person_id",0))
	GovernmentPeopleSystem.record_person_memory(reporter_id,"%s %s when the settlement attempted it." % [subject,outcome_words],"civic_outcome",0.82 if outcome=="failure" else 0.72,{
		"order_id":String(order.get("id","")),"outcome":outcome,"policy_ids":policy_ids,
		"settlement_id":String(followup.get("settlement_id",order.get("settlement_id",""))),
		"inherited":original_leader_id>0 and reporter_id!=original_leader_id,
		"emotion":"warning" if outcome=="failure" else "duty",
	})
	followup["memory_recorded"]=true
	order["implementation_followup"]=followup


func _evaluate_policy(order_id:String,snapshot:Dictionary,current_day:int,scheduled_day:int)->Dictionary:
	var policy_id:=String(snapshot.get("id",""))
	if String(snapshot.get("operation_kind",""))!="":
		return _evaluate_operation(snapshot)
	var modifier:=_modifier_for(order_id,policy_id)
	var duration:=maxf(7.0,float(snapshot.get("duration_days",30.0)))
	var elapsed:=maxf(0.0,float(current_day-scheduled_day))
	var continuity:=clampf(elapsed/duration,0.0,1.0)
	var active:=not modifier.is_empty() and current_day<=float(modifier.get("until_day",-INF)) and not modifier.has("ended_reason")
	if active: continuity=1.0
	var assessment:=ConsequenceEngine.directive_assessment(
		policy_id,float(snapshot.get("requested_magnitude",0.0)),
		maxf(7.0,duration-elapsed),float(snapshot.get("office_execution",0.5)),
		(snapshot.get("directive_parameters",{}) as Dictionary)
	)
	var capacity_score:=clampf(float(assessment.get("implementation_rate",0.0)),0.0,1.0)
	var planned_score:=clampf(float(snapshot.get("planned_implementation",0.0)),0.0,1.0)
	var observation:=ConsequenceEngine.policy_observation(modifier) if not modifier.is_empty() else {"metrics":[],"summary":"No continuing policy record could be found."}
	var evidence:=_evidence_score(observation.get("metrics",[]))
	var score:=planned_score*0.34+capacity_score*0.26+evidence*0.30+continuity*0.10
	if not active:
		var ended_reason:=String(modifier.get("ended_reason","lost implementation record")) if not modifier.is_empty() else "lost implementation record"
		if ended_reason in ["repealed","superseded"]: score=minf(score,0.42)
		else: score=minf(score,0.28)
	var outcome:="success" if score>=0.64 else "partial" if score>=0.31 else "failure"
	var limitations:Array[String]=[]
	for limitation_variant in assessment.get("limitations",[]):
		var limitation:=_qualitative_limitation(String(limitation_variant))
		if not limitation.is_empty() and not limitations.has(limitation): limitations.append(limitation)
	if not active:
		limitations.append("the standing implementation ended before this report")
	return {
		"id":policy_id,"label":GovernmentPolicyCatalog.display_name(policy_id),"outcome":outcome,
		"delivery_score":clampf(score,0.0,1.0),"planned_implementation":planned_score,
		"current_capacity":capacity_score,"observed_evidence":evidence,"continuity":continuity,
		"observation_summary":String(observation.get("summary","No linked result was measurable.")),
		"qualitative_evidence":_qualitative_evidence(observation.get("metrics",[])),
		"limitations":limitations,"bounded":true,
	}


func _evaluate_operation(snapshot:Dictionary)->Dictionary:
	var mission_id:=int(snapshot.get("mission_id",0))
	var report:=_scout_report(mission_id)
	if not report.is_empty():
		var recruits:=maxi(0,int(report.get("recruits",0)))
		var losses:=maxi(0,int(report.get("lost_personnel",0)))
		var outcome:="success" if recruits>0 else "partial"
		var evidence:="Some of the scouts did not return with the party." if losses>0 else ""
		return {
			"id":String(snapshot.get("id","operation")),"label":GovernmentPolicyCatalog.display_name(String(snapshot.get("id","operation"))),
			"outcome":outcome,"delivery_score":0.82 if recruits>0 else 0.44,
			"qualitative_evidence":evidence,"limitations":[],"bounded":true,
			"operation_kind":String(snapshot.get("operation_kind","")),"mission_id":mission_id,"recruits":recruits,
		}
	var last_outcome:Dictionary=CivilizationSystem.last_scout_outcome
	var failure_matches:=mission_id>0 and int(last_outcome.get("mission_id",0))==mission_id and String(last_outcome.get("status",""))=="missing"
	return {
		"id":String(snapshot.get("id","operation")),"label":GovernmentPolicyCatalog.display_name(String(snapshot.get("id","operation"))),
		"outcome":"failure","delivery_score":0.0,"qualitative_evidence":"",
		"limitations":["the commissioned party failed to return" if failure_matches else "the expedition's outcome could not be verified"],
		"bounded":true,"operation_kind":String(snapshot.get("operation_kind","")),"mission_id":mission_id,"recruits":0,
	}


func _evidence_score(metrics:Array)->float:
	var assessed:=0
	var score:=0.0
	for metric_variant in metrics:
		var metric:Dictionary=metric_variant
		var expected:=float(metric.get("expected_direction",0.0))
		if is_zero_approx(expected): continue
		assessed+=1
		var directed_delta:=float(metric.get("delta",0.0))*expected
		if directed_delta>0.0001: score+=1.0
		elif directed_delta>=-0.0001: score+=0.45
	if assessed==0: return 0.45
	return clampf(score/float(assessed),0.0,1.0)


func _qualitative_evidence(metrics:Array)->String:
	var favorable:Array[String]=[]
	var unclear:Array[String]=[]
	var adverse:Array[String]=[]
	for metric_variant in metrics:
		var metric:Dictionary=metric_variant
		var expected:=float(metric.get("expected_direction",0.0))
		if is_zero_approx(expected): continue
		var label:=String(metric.get("label","recorded conditions")).to_lower()
		var directed_delta:=float(metric.get("delta",0.0))*expected
		if directed_delta>0.0001: favorable.append(label)
		elif directed_delta>=-0.0001: unclear.append(label)
		else: adverse.append(label)
	var clauses:Array[String]=[]
	if not favorable.is_empty(): clauses.append("%s moved in the intended direction" % _natural_list(favorable))
	if not unclear.is_empty(): clauses.append("%s showed no clear change" % _natural_list(unclear))
	if not adverse.is_empty(): clauses.append("%s moved against the intended result" % _natural_list(adverse))
	return "; ".join(clauses)+("." if not clauses.is_empty() else "")


func _qualitative_limitation(raw:String)->String:
	var normalized:=raw.to_lower()
	if "administrative" in normalized: return "administrative reach remained thin"
	if "security" in normalized or "enforcement" in normalized: return "local enforcement and coordination remained weak"
	if "food" in normalized or "ration" in normalized: return "food stores could not safely bear the work"
	if "material" in normalized: return "usable material stores remained inadequate"
	if "standing directive" in normalized or "already carrying" in normalized: return "the government was already carrying more work than it could reliably administer"
	if "required practice" in normalized or "not known" in normalized: return "the required practical knowledge was not yet established"
	if "recognized" in normalized and ("source" in normalized or "supply" in normalized): return "the necessary resource had not been reliably recognized or secured"
	if "expedition" in normalized or "party" in normalized: return "the physical expedition could not be sustained"
	return "local conditions remained unfavorable"


func _mission_id_from_dispatch_status(status:Dictionary,operation_kind:String)->int:
	if operation_kind!="recruitment_scouts": return 0
	for party_variant in status.get("parties",[]):
		var party:Dictionary=party_variant
		if String(party.get("target_id",""))=="recruit_people": return int(party.get("mission_id",0))
	return 0


func _operation_is_active(mission_id:int)->bool:
	if mission_id<=0: return false
	for mission_variant in CivilizationSystem.scout_missions:
		if int((mission_variant as Dictionary).get("mission_id",0))==mission_id: return true
	return false


func _scout_report(mission_id:int)->Dictionary:
	if mission_id<=0: return {}
	for report_variant in CivilizationSystem.scout_reports:
		var report:Dictionary=report_variant
		if int(report.get("mission_id",0))==mission_id: return report
	return {}


func _modifier_for(order_id:String,policy_id:String)->Dictionary:
	for modifier_variant in GameState.active_modifiers:
		var modifier:Dictionary=modifier_variant
		if String(modifier.get("kind",""))!="policy": continue
		if String(modifier.get("source_order_id",""))==order_id and String(modifier.get("id",""))==policy_id: return modifier
	return {}


func _reporting_leader(followup:Dictionary)->Dictionary:
	var settlement_id:=String(followup.get("settlement_id",""))
	if not settlement_id.is_empty():
		var current:=GovernmentPeopleSystem.settlement_leader(settlement_id)
		if not current.is_empty(): return current
	var original:=GovernmentPeopleSystem.person_snapshot(int(followup.get("leader_person_id",0)))
	if String(original.get("status","active"))=="active": return original
	return {}


func _report_text(order:Dictionary,results:Array[Dictionary],outcome:String,leader:Dictionary,followup:Dictionary)->String:
	var names:Array[String]=[]
	var observation_lines:Array[String]=[]
	var limitations:Array[String]=[]
	var operation_only:=not results.is_empty()
	for result in results:
		names.append(String(result.get("label","the instruction")))
		if String(result.get("operation_kind",""))=="": operation_only=false
		var observation:=String(result.get("qualitative_evidence",""))
		if not observation.is_empty() and observation not in observation_lines: observation_lines.append(observation)
		for limitation_variant in result.get("limitations",[]):
			var limitation:=_qualitative_limitation(String(limitation_variant))
			if not limitation.is_empty() and not limitations.has(limitation): limitations.append(limitation)
	var opening:="I can report that %s took hold." % _natural_list(names)
	var detail:=" The settlement carried the main work through with the hands, stores, and authority available."
	if operation_only:
		opening="The recruitment party is back, and people it met have chosen to join us." if outcome=="success" else ("The recruitment party is back, but it found no one willing to settle here." if outcome=="partial" else "The recruitment party did not return. I have no recruits or reliable field account to report.")
		detail=""
	elif outcome=="partial":
		opening="I have mixed results to report on %s." % _natural_list(names)
		detail=" Some parts took hold, but the work remained uneven or incomplete."
	elif outcome=="failure":
		opening="I must report that %s did not take hold." % _natural_list(names)
		detail=" The available people, stores, or local cooperation were not enough to make the instruction real."
	var original_leader_id:=int(followup.get("leader_person_id",0))
	if not leader.is_empty() and int(leader.get("person_id",0))!=original_leader_id:
		opening="I reviewed %s's unfinished directive. %s" % [String(followup.get("leader_name","my predecessor")),opening]
	var evidence:=" What we can see: %s" % " ".join(observation_lines).substr(0,420) if not observation_lines.is_empty() else ""
	var constraint:=" The main constraint was %s." % "; ".join(limitations).substr(0,260) if not limitations.is_empty() else ""
	return (opening+detail+evidence+constraint).substr(0,900)


func _natural_list(items:Array[String])->String:
	if items.is_empty(): return "the instruction"
	if items.size()==1: return items[0]
	if items.size()==2: return "%s and %s" % [items[0],items[1]]
	var leading:=items.slice(0,items.size()-1)
	return "%s, and %s" % [", ".join(leading),items.back()]
