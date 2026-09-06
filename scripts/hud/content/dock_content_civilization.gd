extends "res://scripts/hud/content/dock_content_base.gd"
## CIVILIZATION section: Society / Government / Council.
## Replaces the systems hub and the society, government, and council panels.

const DYNAMIC_ORDER:Array[String]=["demography","nutrition","health","labor","knowledge","production","infrastructure","logistics","ecology","institutions","security","culture"]
const ValuesModel:=preload("res://scripts/societal_values_model.gd")

func meta()->Dictionary:
	var government:=GovernmentPeopleSystem.structure_snapshot()
	return {
		"eyebrow":"CIVILIZATION · SOCIETY, GOVERNMENT & KNOWLEDGE",
		"title":String(government.get("name","Forming Order")).capitalize(),
		"subtabs":["SOCIETY","GOVERNMENT","CIVICS"],
	}

func tab(sub:int)->Dictionary:
	var capacities:Dictionary=GameState.society_capacities
	var mean:=0.0
	var weakest:="—"
	var weakest_value:=2.0
	for domain in capacities:
		var value:=clampf(float(capacities[domain]),0.0,1.0)
		mean+=value
		if value<weakest_value:
			weakest_value=value
			weakest=String(domain)
	mean/=maxf(1.0,float(capacities.size()))
	var governance:Dictionary=ConsequenceEngine.governance_metrics()
	var legitimacy:=roundi(clampf(float(GameState.simulation_metrics.get("legitimacy",0.7)),0.0,1.0)*100.0)
	var policies:=ConsequenceEngine.active_policies().size()
	var kpis:Array=[
		{"label":"CAPACITY","value":"%d%%" % roundi(mean*100.0),"delta":"","accent":Tokens.TEAL,"tip":"Mean of twelve aggregate capacities"},
		{"label":"WEAKEST","value":weakest.capitalize(),"delta":"%d%%" % roundi(weakest_value*100.0),"delta_color":Tokens.RED,"accent":Tokens.RED,"tip":"Limiting capacity"},
		{"label":"LEGITIMACY","value":"%d%%" % legitimacy,"delta":"","accent":Tokens.AMBER,"tip":"Shared acceptance of authority"},
		{"label":"POLICIES","value":str(policies),"delta":"active","accent":Tokens.BLUE,"tip":"Standing interpreted policies"},
	]
	var raw_brief:Dictionary=terrain._society_attention_brief(capacities)
	var brief:=adapt_brief(raw_brief,"warn" if weakest_value<0.4 else "info","")
	match sub:
		1: return {"kpis":[kpis[2],kpis[3]],"brief":_government_brief(governance),"blocks":_government_overview()}
		2: return {"kpis":[],"brief":{},"blocks":_council_blocks()}
	return {"kpis":[kpis[2],kpis[3]],"brief":brief,"blocks":_society_overview()}

func _society_blocks(capacities:Dictionary)->Array:
	var items:Array=[]
	for domain in DYNAMIC_ORDER:
		var value:=clampf(float(capacities.get(domain,0.0)),0.0,1.0)*100.0
		items.append({"name":String(domain).capitalize(),"pct":value,"trend":"—","tip":String(terrain._dynamic_definition(domain))})
	items.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.pct)<float(b.pct))
	var identity:Dictionary=ValuesModel.identity_snapshot(GameState.societal_values)
	var identity_text:="%s · %s." % [String(identity.get("name","Forming order")).capitalize(),String(identity.get("summary","still forming")).to_lower()]
	return [
		{"type":"caps","heading":"TWELVE CAPACITIES","note":"weakest first","items":items},
		{"type":"text","heading":"VALUES & IDENTITY","text":identity_text+" Values shift slowly with lived conditions, not by decree."},
	]

func _government_brief(governance:Dictionary)->Dictionary:
	var support:=clampf(float(governance.get("council_support",0.6)),0.0,1.0)
	if ConsequenceEngine.active_policies().is_empty():
		return {"tone":"info","title":"No standing policy is in force","why":"Talk with your local leader in CIVICS. Advice, proposals and accepted work have distinct outcomes.","action_label":"OPEN COUNCIL","on_action":jump("civ",2)}
	if support<0.45:
		return {"tone":"warn","title":"Council support is low","why":"Institutions execute reluctantly at %d%% support. Fewer, better-aligned policies recover it." % roundi(support*100.0)}
	return {"tone":"info","title":"Government is executing","why":"Standing policies are within administrative capacity."}

func _government_blocks(governance:Dictionary)->Array:
	var office_items:Array=[]
	var government:=GovernmentPeopleSystem.structure_snapshot()
	for office_variant in GovernmentPeopleSystem.active_offices():
		var office_record:Dictionary=office_variant
		var office:=String(office_record.key)
		var office_title:=String(office_record.title)
		var open_appointment:=func()->void: hud.open_detail(preload("res://scripts/hud/content/dock_detail_appointments.gd").new(terrain,hud,office))
		var advisor:=GovernmentPeopleSystem.officeholder(office)
		if not advisor.is_empty():
			office_items.append({"name":office_title,"sub":"%s · age %d · %s" % [String(advisor.get("name","Unknown")),int(advisor.get("age",0)),String(advisor.get("background",""))],"value":"FILLED","value_color":Tokens.GREEN,"accent":Tokens.GREEN,"on_click":open_appointment,"tip":"Click to review or replace this named officeholder. The title evolves with government."})
		else:
			office_items.append({"name":office_title,"sub":"vacant · execution reduced · click to appoint a person","value":"APPOINT","value_color":Tokens.GOLD_BRIGHT,"accent":Tokens.AMBER,"on_click":open_appointment,"tip":"Choose a living person from the bounded government pool."})
	var load:=clampf(float(governance.get("administrative_load",0.0)),0.0,1.0)
	var churn:=clampf(float(governance.get("policy_churn",0.0)),0.0,1.0)
	var support:=clampf(float(governance.get("council_support",0.6)),0.0,1.0)
	var governance_items:Array=[
		{"name":"Administrative load","value":"%d%%" % roundi(load*100.0),"ratio":load,"color":Tokens.capacity_color(100.0-load*100.0),"tip":"Occupied administrative capacity"},
		{"name":"Policy churn","value":"%d%%" % roundi(churn*100.0),"ratio":churn,"color":Tokens.capacity_color(100.0-churn*100.0),"tip":"Recent replacement and rescinding of policy"},
		{"name":"Council support","value":"%d%%" % roundi(support*100.0),"ratio":support,"color":Tokens.capacity_color(support*100.0),"tip":"Institutional alignment with your directives"},
	]
	var policy_items:Array=[]
	for policy_variant in ConsequenceEngine.active_policies():
		var policy:Dictionary=policy_variant
		policy_items.append({
			"name":String(policy.get("name",policy.get("id","Policy"))).capitalize(),
			"sub":"%s · %d days remain" % [String(policy.get("office","Council")),ceili(float(policy.get("remaining_days",0.0)))],
			"value":"%d%%" % roundi(maxf(0.0,float(policy.get("execution_factor",0.62)))*100.0),
			"value_color":Tokens.BODY_2,"accent":Tokens.BLUE,
			"tip":"Execution strength under the current office holder",
		})
	var blocks:Array=[
		{"type":"rows","heading":"PEOPLE IN GOVERNMENT","note":"%d known public figures · %s" % [int(government.get("living_people",0)),String(government.get("scope","founding council"))],"items":office_items},
		{"type":"bars","heading":"GOVERNANCE","items":governance_items},
	]
	if policy_items.is_empty():
		blocks.append({"type":"text","heading":"STANDING POLICY","text":"No standing policy is in force. Talk with your local leader in CIVICS. Advice, proposals and accepted work have distinct outcomes."})
	else:
		blocks.append({"type":"rows","heading":"STANDING POLICY","note":"execution","items":policy_items})
	return blocks

func _council_brief()->Dictionary:
	var settlement:=_civic_settlement()
	var leader:=GovernmentPeopleSystem.settlement_leader(String(settlement.get("id","")))
	if leader.is_empty():
		return {"tone":"warn","title":"This settlement has no leader","why":"Civic directives require one accountable person who can answer, object, and carry them out.","action_label":"APPOINT LEADER","on_action":_open_civic_leadership.bind(String(settlement.get("id","")))}
	var latest_order:=_latest_civic_order(String(settlement.get("id","")),int(leader.get("person_id",0)))
	var directive_state:=_directive_state(latest_order)
	match directive_state:
		"OBSERVING EFFECTS":
			return {"tone":"info","title":"ACTION COMPLETE · watching the consequences","why":"The counted action and its population record are complete. The leader will review its wider effects."}
		"REPORTED":
			return {"tone":"info","title":"REPORTED · the outcome is recorded","why":"Read the leader's report below for the result and its limits."}
		"INTERPRETING":
			return {"tone":"info","title":"NOT YET UNDERWAY · interpreting your instruction","why":"No policy has been applied. The leader is still deciding what your words mean."}
		"NEEDS YOUR DECISION":
			return {"tone":"warn","title":"NEEDS YOUR DECISION · %s objects" % String(leader.get("name","The leader")),"why":"This is still a discussion. No policy has been applied. Answer, revise the instruction, or change the leadership."}
		"PROPOSAL RECORDED":
			return {"tone":"info","title":"Your proposal has an answer","why":"Read the leader’s advice below. Scheduling and resource commitments are separate from discussion."}
		"DISCUSSION":
			return {"tone":"info","title":"DISCUSSION · %s gave advice" % String(leader.get("name","The leader")),"why":"No order was given and no policy was applied. Continue the conversation or state a concrete instruction."}
		"REFUSED":
			return {"tone":"warn","title":"REFUSED · %s will not carry it out" % String(leader.get("name","The leader")),"why":"No policy was applied. Revise the instruction or change the leadership."}
		"BLOCKED":
			return {"tone":"warn","title":"BLOCKED · the directive cannot proceed","why":"No policy was applied because the required people, stores, authority, or concrete instruction are missing."}
		"WITHDRAWN":
			return {"tone":"info","title":"WITHDRAWN · the unresolved instruction is closed","why":"Nothing from that proposal is underway. Give a new instruction whenever you are ready."}
		"UNDERWAY":
			return {"tone":"info","title":"UNDERWAY · %s accepted responsibility" % String(leader.get("name","The leader")),"why":"The committed work is now part of the simulation. The leader will report its outcome later."}
	var pending:=AdvisorSystem.council_decision_items(9).size()
	if pending>0:
		return {"tone":"warn","title":"%d decision%s await%s you" % [pending,"" if pending==1 else "s","s" if pending==1 else ""],"why":"Advisors hold these until you decide; repeated reports merge instead of repeating."}
	return {"tone":"info","title":"The council is quiet","why":"Answered items stay quiet for a year unless severity escalates."}

func _council_all_blocks()->Array:
	var blocks:Array=[_interpreter_status_block()]
	var settlement:=_civic_settlement()
	var settlement_id:=String(settlement.get("id",""))
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	var disposition:=GovernmentPeopleSystem.leader_disposition(leader)
	var history:=AdvisorSystem.civic_dialogue_history(settlement_id,6)
	var latest_order:=_latest_civic_order(settlement_id,int(leader.get("person_id",0)))
	var latest_state:=_directive_state(latest_order)
	if not leader.is_empty():
		var dialogue_turns:Array=[]
		for turn in history:
			var is_player:=String(turn.get("speaker",""))=="player"
			var dialogue_text:=String(turn.get("text",""))
			if "\n\nSTATE ·" in dialogue_text: dialogue_text=dialogue_text.split("\n\nSTATE ·")[0]
			dialogue_turns.append({
				"speaker":"player" if is_player else "leader",
				"name":"YOU" if is_player else String(turn.get("speaker_name",leader.get("name","LEADER"))),
				"text":dialogue_text,"day":int(turn.get("day",0)),
			})
		var leadership_actions:Array=[]
		if latest_state in ["NEEDS YOUR DECISION","REFUSED"]:
			leadership_actions=[
				{"label":"CHANGE LEADER…","on_press":_open_civic_leadership.bind(settlement_id),"tip":"Review named candidates. Nothing changes until you appoint someone."},
				{"label":"DISMISS","on_press":_remove_civic_leader.bind(settlement_id,"dismiss"),"tip":"Remove this leader and appoint a successor. This carries a political cost."},
				{"label":"ARREST","color":Tokens.RED,"on_press":_remove_civic_leader.bind(settlement_id,"arrest"),"tip":"Detain this leader and appoint a successor. This carries a severe political cost."},
			]
		blocks.append({
			"type":"conversation","leader_name":String(leader.get("name","the appointed leader")),
			"leader_title":String(leader.get("title","local leader")),"disposition":String(disposition.get("label","pragmatic")).to_lower(),
			"state":latest_state,"state_color":_directive_state_color(latest_state),"items":dialogue_turns,
			"empty_text":"Speak plainly. %s will answer according to their character and what %s can actually do." % [String(leader.get("name","The leader")),String(settlement.get("name","this settlement"))],
			"status":_pronouncement_status_text(settlement_id,int(leader.get("person_id",0))),
			"actions":leadership_actions,"on_submit":func(field:LineEdit)->void: terrain._issue_freeform_order(field),
			"placeholder":"Reply to %s…" % String(leader.get("name","the leader")),"disabled":latest_state=="INTERPRETING",
		})
	if leader.is_empty():
		blocks.append({"type":"text","heading":"NO LOCAL LEADER","text":"Appoint one accountable person before beginning a civic conversation."})
		blocks.append({"type":"actions","items":[{"label":"APPOINT A LEADER","sub":"one accountable person must hold local authority","primary":true,"on_press":_open_civic_leadership.bind(settlement_id),"tip":"Choose a named person to lead this settlement before issuing civic directives."}]})
	var combat_reports:Array=[]
	for item in GameState.council_inbox:
		var item_id:=String(item.get("id",""))
		if not item_id.begins_with("battle_") and not item_id.begins_with("threat_"): continue
		combat_reports.append({"name":"BATTLE REPORT" if item_id.begins_with("battle_") else "APPROACHING FORCE","detail":String(item.get("text","")),"sub":"Day %d · %s" % [int(item.get("day",0)),String(item.get("office","Military command"))],"value":"OPEN","accent":Tokens.RED,"on_click":terrain._open_war_planning,"tip":"Read the full military situation and issue orders."})
		if combat_reports.size()>=6: break
	if not combat_reports.is_empty():
		blocks.append({"type":"rows","heading":"MILITARY ALERTS & BATTLE REPORTS","note":"Open War Planning for details","items":combat_reports})
	var decisions:Array=AdvisorSystem.council_decision_items(6)
	var shown:=0
	for item_variant in decisions:
		var item:Dictionary=item_variant
		if String(item.get("status","unread"))!="unread": continue
		if shown>=3: break
		shown+=1
		var item_id:=String(item.get("id",""))
		blocks.append({"type":"rows","heading":"DECISION · %s" % String(item.get("office","Council")).to_upper(),"note":"Day %d" % int(item.get("day",0)),"items":[{
			"name":String(item.get("text","Council item")).split("\n")[0],
			"sub":String(item.get("advisor","")),
			"value":"","accent":Tokens.RED if String(item.get("severity","warning")) in ["danger","critical"] else Tokens.AMBER,
			"tip":String(item.get("text","")),
		}]})
		var responses:Array=item.get("responses",[])
		var response_items:Array=[]
		for response_variant in responses:
			var response:Dictionary=response_variant
			var label:=String(response.get("label",""))
			if label=="": continue
			# Every response carries its authored consequence line; a decision the
			# player cannot price is not a decision.
			var ripple:=String(response.get("ripple",response.get("hint","")))
			var effect_id:=String(response.get("effect",""))
			var duration_days:=roundi(float(response.get("days",0.0)))
			var enacts:="Enacts the %s policy for %d days." % [effect_id.replace("_"," "),duration_days] if effect_id!="" else "No standing policy is enacted."
			response_items.append({
				"label":label.to_upper(),"sub":ripple,
				"primary":effect_id!="",
				"on_press":AdvisorSystem.respond_to_council_item.bind(item_id,label),
				"tip":"%s\n%s" % [ripple,enacts] if ripple!="" else enacts,
			})
		if not response_items.is_empty():
			blocks.append({"type":"actions","items":response_items})
	var pending_orders:Array=[]
	for order_variant in GameState.sovereign_orders:
		var order:Dictionary=order_variant
		if String(order.get("type",""))!="pronouncement": continue
		if String(order.get("status","")) in ["interpreting"]:
			pending_orders.append({
				"name":"\"%s\"" % String(order.get("parameters",{}).get("text","")).substr(0,64),
				"sub":"interpreting · day %d" % int(order.get("issued_day",0)),
				"value":"CANCEL","value_color":Tokens.RED,"accent":Tokens.AMBER,
				"on_click":terrain._cancel_pending_pronouncement.bind(String(order.get("id","")),String(order.get("request_id",""))),
				"tip":"Cancel this pronouncement before interpretation completes",
			})
	if not pending_orders.is_empty():
		blocks.append({"type":"rows","heading":"PENDING ORDERS","items":pending_orders})
	var merged_items:Array=AdvisorSystem.merged_report_items(6)
	if not merged_items.is_empty():
		var merged_rows:Array=[]
		for merged_variant in merged_items:
			var merged_item:Dictionary=merged_variant
			var merged_id:=String(merged_item.get("id",""))
			if merged_id.begins_with("battle_") or merged_id.begins_with("threat_"): continue
			var deferred:=String(merged_item.get("status","unread"))=="deferred"
			var occurrences:=int(merged_item.get("occurrences",1))
			merged_rows.append({
				"name":String(merged_item.get("text","Report")).split("\n")[0],
				"sub":"%s · day %d%s%s" % [String(merged_item.get("office","Council")),int(merged_item.get("day",0))," · merged ×%d" % occurrences if occurrences>1 else ""," · deferred" if deferred else ""],
				"value":"RESTORE" if deferred else "","value_color":Tokens.GOLD,
				"accent":Tokens.AMBER if deferred else Color(0,0,0,0),
				"on_click":(_restore_deferred.bind(merged_id)) if deferred else null,
				"tip":String(merged_item.get("text",""))+("\n\nClick to return this deferred decision to the queue." if deferred else ""),
			})
		blocks.append({"type":"rows","heading":"REPORTS","note":"%d routine reports held quiet" % AdvisorSystem.routine_report_count(),"items":merged_rows})
	return blocks


func _interpreter_status_block(config_override:Dictionary={})->Dictionary:
	## Configuration is surfaced separately from individual directive provenance.
	## A clear catalog order can (intentionally) resolve through the local fast
	## path even while the AI route is fully wired, so response speed alone is a
	## misleading online/offline indicator.
	var config:=config_override if not config_override.is_empty() else PronouncementInterpreter.configuration_status()
	var enabled:=bool(config.get("enabled",GameState.civic_api_enabled))
	var configured:=bool(config.get("configured",false))
	var structured:=bool(config.get("structured_output",false))
	var always_ask_ai:=bool(config.get("always_use_ai",GameState.civic_always_use_ai))
	if not enabled:
		return {
			"type":"rows","heading":"DIRECTIVE INTERPRETER","note":"actual configuration",
			"items":[{
				"name":"LOCAL · AI OFF","sub":"Player disabled paid interpretation in Game Menu",
				"value":"OFF","value_color":Tokens.MUTED,"accent":Tokens.MUTED,
				"tip":"The API master switch is off. Civic dialogue remains playable through the local catalog and sends zero API requests. Turn AI on in Game Menu to restore configured interpretation.",
			}],
		}
	if configured:
		var model:=String(config.get("model","AI")).strip_edges()
		var model_label:=model.to_upper()
		if "terra" in model.to_lower(): model_label="TERRA"
		elif model_label.length()>22: model_label=model_label.substr(0,21)+"…"
		var mode_label:="Strict structured interpretation" if structured else "Compatible JSON interpretation"
		var host:=String(config.get("endpoint_host","configured endpoint"))
		var transport:=String(config.get("transport_security","validated transport"))
		var routing_name:="ROUTING · ALWAYS ASK AI" if always_ask_ai else "ROUTING · SMART"
		var routing_sub:="Every message uses the configured AI; local shortcuts and response cache are bypassed." if always_ask_ai else "Clear known language may resolve locally; ambiguous language uses AI."
		var routing_tip:="Click to restore smart routing and reduce API use." if always_ask_ai else "Click to turn off fast local replies and send every civic message to the configured AI. This increases API use."
		var interpreter_tip:="AI interpretation is configured for %s over %s. Every civic message is currently sent to that model; local fast replies and the response cache are bypassed. Every result still passes the deterministic simulation gate." % [model,transport] if always_ask_ai else "AI interpretation is configured for %s over %s. Clear, known orders resolve instantly through the local catalog to save time and tokens; unfamiliar or ambiguous language uses the AI route. Every result passes the same deterministic simulation gate." % [model,transport]
		var routing_item:={
			"name":routing_name,"sub":routing_sub,"value":"CHANGE",
			"value_color":Tokens.GOLD_BRIGHT,"accent":Tokens.BLUE,"tip":routing_tip,
		}
		if config_override.is_empty(): routing_item["on_click"]=_toggle_interpreter_routing
		return {
			"type":"rows","heading":"DIRECTIVE INTERPRETER","note":"actual configuration",
			"items":[{
				"name":"AI · %s" % model_label,"sub":"%s · %s" % [mode_label,host],
				"value":"READY","value_color":Tokens.GREEN,"accent":Tokens.GREEN,
				"tip":interpreter_tip,
			},routing_item],
		}
	var missing:Array=config.get("missing",[])
	var issues:Array=config.get("issues",[])
	var reason:="No API credentials or endpoint are configured."
	if not issues.is_empty(): reason=String(issues[0])
	elif not missing.is_empty(): reason="Missing: %s." % ", ".join(PackedStringArray(missing))
	return {
		"type":"rows","heading":"DIRECTIVE INTERPRETER","note":"actual configuration",
		"items":[{
			"name":"LOCAL · OFFLINE","sub":"Deterministic catalog only",
			"value":"OFFLINE","value_color":Tokens.AMBER,"accent":Tokens.AMBER,
			"tip":"%s Civic directives remain bounded and playable, but unfamiliar language cannot use AI interpretation." % reason,
		}],
	}


func _toggle_interpreter_routing()->void:
	GameState.civic_always_use_ai=not GameState.civic_always_use_ai
	if hud and hud.has_method("request_immediate_dock_refresh"):
		hud.request_immediate_dock_refresh()

func _restore_deferred(item_id:String)->void:
	for item_variant in GameState.council_inbox:
		var item:Dictionary=item_variant
		if String(item.get("id",""))!=item_id: continue
		if String(item.get("status","unread"))=="deferred":
			item["status"]="unread"
			item["day"]=int(GameState.elapsed_days)
		break
	if hud:
		hud.dismissed_alert_ids.erase(item_id)
		hud._queue_signature="__stale__"
		hud.refresh()
		hud.live_refresh_dock()

func _pronouncement_status_text(settlement_id:String,leader_person_id:int)->String:
	var order:=_latest_civic_order(settlement_id,leader_person_id)
	var state:=_directive_state(order)
	match state:
		"INTERPRETING": return "NOT YET UNDERWAY · The leader is interpreting the instruction; no policy has been applied."
		"NEEDS YOUR DECISION": return "NEEDS YOUR DECISION · Discussion only; no policy has been applied."
		"PROPOSAL RECORDED": return "PROPOSAL RECORDED · The leader has answered; no event or spending has been scheduled."
		"DISCUSSION": return "DISCUSSION · Advice only; no order was given and no policy has been applied."
		"REFUSED": return "REFUSED · No policy was applied. Revise the directive or change the leadership."
		"BLOCKED": return "BLOCKED · No policy was applied; the instruction exceeded present means or was not concrete enough."
		"WITHDRAWN": return "WITHDRAWN · The unresolved instruction was closed and no policy was applied."
		"UNDERWAY": return "UNDERWAY · The leader committed; the outcome report will arrive later."
		"REPORTED": return "REPORTED · The leader's outcome report is in this conversation."
		"OBSERVING EFFECTS": return "ACTION COMPLETE · The counted result is recorded; wider effects are being reviewed."
	return ""

func signature()->Array:
	var ids:Array=[]
	for item_variant in GameState.council_inbox:
		var item:Dictionary=item_variant
		ids.append(String(item.get("id",""))+String(item.get("status","")))
	var settlement:=_civic_settlement()
	var history:=AdvisorSystem.civic_dialogue_history(String(settlement.get("id","")),6)
	var latest_dialogue_status:=String(history.back().get("status","")) if not history.is_empty() else ""
	var leader:=GovernmentPeopleSystem.settlement_leader(String(settlement.get("id","")))
	var latest_order:=_latest_civic_order(String(settlement.get("id","")),int(leader.get("person_id",0)))
	var interpreter_config:=PronouncementInterpreter.configuration_status()
	return [GameState.society_capacities.duplicate(),ids,GameState.sovereign_orders.size(),ConsequenceEngine.active_policies().size(),GovernmentPeopleSystem.revision,GameState.player_settlements.size(),history.size(),latest_dialogue_status,String(latest_order.get("status","")),bool(interpreter_config.get("enabled",GameState.civic_api_enabled)),bool(interpreter_config.get("configured",false)),String(interpreter_config.get("model","")),bool(interpreter_config.get("structured_output",false)),GameState.civic_always_use_ai]


func _civic_settlement()->Dictionary:
	var settlement:=SettlementModel.selected_settlement_snapshot()
	if not settlement.is_empty(): return settlement
	return GameState.player_settlements[0] if not GameState.player_settlements.is_empty() else {}


func _open_civic_leadership(settlement_id:String)->void:
	if settlement_id.is_empty(): return
	hud.open_detail(preload("res://scripts/hud/content/dock_detail_settlement_people.gd").new(terrain,hud,settlement_id))


func _latest_civic_order(settlement_id:String,leader_person_id:int)->Dictionary:
	var inherited_pending:Dictionary={}
	for order_variant in GameState.sovereign_orders:
		var order:Dictionary=order_variant
		if String(order.get("type",""))!="pronouncement": continue
		if String(order.get("settlement_id",""))!=settlement_id: continue
		if leader_person_id<=0 or int(order.get("leader_person_id",0))==leader_person_id: return order
		if inherited_pending.is_empty() and String(order.get("status","")) in ["awaiting_confirmation","awaiting_clarification","leader_refused"]:
			inherited_pending=order
	return inherited_pending


func _civic_order_by_id(order_id:String)->Dictionary:
	if order_id.is_empty(): return {}
	for order_variant in GameState.sovereign_orders:
		var order:Dictionary=order_variant
		if String(order.get("id",""))==order_id: return order
	return {}


func _directive_state(order:Dictionary)->String:
	if order.is_empty(): return ""
	if String(order.get("implementation_followup",{}).get("state",""))=="reported": return "REPORTED"
	var status:=String(order.get("status",""))
	var stance:=String(order.get("leader_stance",""))
	var policies:Array=order.get("parameters",{}).get("interpretation",{}).get("policies",[])
	if not policies.is_empty() and policies.all(func(policy:Dictionary)->bool: return bool(policy.get("applied",false)) and bool(policy.get("directive_parameters",{}).get("one_time",false))): return "OBSERVING EFFECTS"
	var applied:=false
	var discussion_pending:=false
	var refused:=false
	var physically_blocked:=false
	for policy_variant in policies:
		var policy:Dictionary=policy_variant
		applied=applied or bool(policy.get("applied",false)) or bool(policy.get("repealed_active_policy",false))
		discussion_pending=discussion_pending or bool(policy.get("_conversation_deferred",false))
		refused=refused or bool(policy.get("_conversation_refused",false))
		physically_blocked=physically_blocked or bool(policy.get("_conversation_blocked",false))
	# Actual application outranks a qualified discussion: mixed directives may
	# put one feasible part underway while declining another part.
	if applied or status in ["active","partially_active","executed","interpreted"]: return "UNDERWAY"
	if status=="proposal": return "PROPOSAL RECORDED"
	if stance=="advises" or status=="discussion": return "DISCUSSION"
	if refused or stance in ["refuses","refused"] or status in ["leader_refused","refused"]: return "REFUSED"
	if discussion_pending or stance in ["objects","clarify"] or status in ["awaiting_confirmation","awaiting_clarification"]: return "NEEDS YOUR DECISION"
	if status=="interpreting": return "INTERPRETING"
	if stance=="withdrawn" or status=="withdrawn": return "WITHDRAWN"
	if physically_blocked or status in ["blocked","leader_unavailable","recorded_unresolved","no_effect","stale","closed","expired","repealed","superseded"]: return "BLOCKED"
	return ""


func _directive_state_color(state:String)->Color:
	match state:
		"UNDERWAY": return Tokens.GREEN
		"REPORTED": return Tokens.GREEN
		"OBSERVING EFFECTS": return Tokens.GREEN
		"INTERPRETING": return Tokens.BLUE
		"DISCUSSION","PROPOSAL RECORDED": return Tokens.BLUE
		"WITHDRAWN": return Tokens.BODY_2
		"REFUSED","BLOCKED": return Tokens.RED
		"NEEDS YOUR DECISION": return Tokens.AMBER
	return Tokens.BODY_2


func _remove_civic_leader(settlement_id:String,action:String)->void:
	terrain._perform_civic_leader_removal(settlement_id,action)

func _society_overview()->Array:
	var details:=_society_blocks(GameState.society_capacities)
	return [details[1],{"type":"actions","items":[{"label":"OUR DIRECTION","sub":"Long-term purpose and traditions","on_press":func():PeopleDirection.open_direction()}, {"label":"TALK TO OUR LEADER","sub":"Discuss a problem or give direction","on_press":jump("civ",2)},focused_action("CAPACITIES IN DETAIL","Twelve measures of what society can do",func()->Dictionary:return {"blocks":_society_blocks(GameState.society_capacities)}),{"label":"PEOPLE IN GOVERNMENT","sub":"Offices, responsibilities and policy","on_press":jump("civ",1)}]}]
func _government_overview()->Array:
	return [{"type":"actions","heading":"GOVERNING TOGETHER","items":[focused_action("OFFICEHOLDERS","Named people and their responsibilities",func()->Dictionary:return {"blocks":[_government_blocks(ConsequenceEngine.governance_metrics())[0]]}),focused_action("POLICY & EXECUTION","Standing commitments and capacity",func()->Dictionary:return {"blocks":_government_blocks(ConsequenceEngine.governance_metrics()).slice(1)}),{"label":"TALK TO OUR LEADER","sub":"Discuss and direct local work","on_press":jump("civ",2)}]}]
func _council_blocks()->Array:
	var all:=_council_all_blocks();var blocks:Array=[]
	for item:Dictionary in all:
		if item.get("type","")=="conversation":blocks.append(item)
	if blocks.is_empty():
		blocks.append({"type":"text","text":"Appoint a local leader to begin civic conversation."})
		blocks.append({"type":"actions","items":[{"label":"APPOINT A LEADER","on_press":_open_civic_leadership.bind(String(_civic_settlement().get("id","")))}]})
	blocks.append({"type":"actions","items":[focused_action("COUNCIL DECISIONS","Review pending choices and consequences",_civic_report.bind("decisions")),focused_action("WORK & REPORTS","Pending orders and returned reports",_civic_report.bind("reports")),focused_action("MILITARY REPORTS","Threats and battle outcomes",_civic_report.bind("military")),focused_action("CONVERSATION SETTINGS","AI routing and local interpretation",func()->Dictionary:return {"blocks":[_interpreter_status_block()]})]})
	return blocks
func _civic_report(kind:String)->Dictionary:
	var chosen:Array=[];var section:=""
	for block:Dictionary in _council_all_blocks():
		var heading:=String(block.get("heading",""))
		if heading.begins_with("DECISION ·"):section="decisions"
		elif heading=="MILITARY ALERTS & BATTLE REPORTS":section="military"
		elif heading in ["PENDING ORDERS","REPORTS"]:section="reports"
		elif heading in ["DIRECTIVE INTERPRETER","NO LOCAL LEADER"] or block.get("type","")=="conversation":section=""
		if section==kind:chosen.append(block)
	if chosen.is_empty():chosen.append({"type":"text","text":"No pending decisions here." if kind=="decisions" else "No reports are waiting here."})
	return {"blocks":chosen}
