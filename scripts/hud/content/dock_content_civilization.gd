extends "res://scripts/hud/content/dock_content_base.gd"
## CIVILIZATION section: Society / Government / Council.
## Replaces the systems hub and the society, government, and council panels.

const DYNAMIC_ORDER:Array[String]=["demography","nutrition","health","labor","knowledge","production","infrastructure","logistics","ecology","institutions","security","culture"]
const ValuesModel:=preload("res://scripts/societal_values_model.gd")

func meta()->Dictionary:
	return {
		"eyebrow":"CIVILIZATION · SOCIETY, GOVERNMENT & KNOWLEDGE",
		"title":"Forming Order",
		"subtabs":["SOCIETY","GOVERNMENT","COUNCIL"],
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
		1: return {"kpis":kpis,"brief":_government_brief(governance),"blocks":_government_blocks(governance)}
		2: return {"kpis":kpis,"brief":_council_brief(),"blocks":_council_blocks()}
	return {"kpis":kpis,"brief":brief,"blocks":_society_blocks(capacities)}

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
		return {"tone":"info","title":"No interpreted policy is in force","why":"Issue an order in COUNCIL; it is bounded to the fixed catalog before anything changes.","action_label":"OPEN COUNCIL","on_action":jump("civ",2)}
	if support<0.45:
		return {"tone":"warn","title":"Council support is low","why":"Institutions execute reluctantly at %d%% support. Fewer, better-aligned policies recover it." % roundi(support*100.0)}
	return {"tone":"info","title":"Government is executing","why":"Standing policies are within administrative capacity."}

func _government_blocks(governance:Dictionary)->Array:
	var office_items:Array=[]
	for office_variant in ["Steward","Quartermaster","Scholar","Marshal","Envoy"]:
		var office:=String(office_variant)
		var open_appointment:=func()->void: hud.open_detail(preload("res://scripts/hud/content/dock_detail_appointments.gd").new(terrain,hud,office))
		if GameState.leadership_positions.has(office):
			var advisor:Dictionary=GameState.leadership_positions[office]
			office_items.append({"name":office,"sub":String(advisor.get("name","Unknown")),"value":"FILLED","value_color":Tokens.GREEN,"accent":Tokens.GREEN,"on_click":open_appointment,"tip":"Click to review or replace the commissioned institution"})
		else:
			office_items.append({"name":office,"sub":"vacant · execution reduced · click to appoint","value":"APPOINT","value_color":Tokens.GOLD_BRIGHT,"accent":Tokens.AMBER,"on_click":open_appointment,"tip":"Click to commission an institution for this portfolio"})
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
		{"type":"rows","heading":"OFFICES","items":office_items},
		{"type":"bars","heading":"GOVERNANCE","items":governance_items},
	]
	if policy_items.is_empty():
		blocks.append({"type":"text","heading":"STANDING POLICY","text":"No interpreted policy is in force. Issue an order in COUNCIL; it is bounded to the fixed catalog before anything changes."})
	else:
		blocks.append({"type":"rows","heading":"STANDING POLICY","note":"execution","items":policy_items})
	return blocks

func _council_brief()->Dictionary:
	var pending:=AdvisorSystem.council_decision_items(9).size()
	if pending>0:
		return {"tone":"warn","title":"%d decision%s await%s you" % [pending,"" if pending==1 else "s","s" if pending==1 else ""],"why":"Advisors hold these until you decide; repeated reports merge instead of repeating."}
	return {"tone":"info","title":"The council is quiet","why":"Answered items stay quiet for a year unless severity escalates."}

func _council_blocks()->Array:
	var blocks:Array=[]
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
			response_items.append({
				"label":label.to_upper(),"sub":String(response.get("hint","")),
				"primary":String(response.get("effect",""))!="",
				"on_press":AdvisorSystem.respond_to_council_item.bind(item_id,label),
				"tip":String(response.get("hint","Choose this response")),
			})
		if not response_items.is_empty():
			blocks.append({"type":"actions","items":response_items})
	if shown==0:
		blocks.append({"type":"text","heading":"DECISIONS AWAITING YOU","text":"Nothing awaits a decision. Advisors raise items here when conditions demand a choice."})
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
	blocks.append({"type":"order","heading":"SOVEREIGN ORDER",
		"on_submit":func(field:LineEdit)->void: terrain._issue_freeform_order(field),
		"helper":"Interpreted into at most three bounded policies from the fixed catalog. Nothing changes until the interpretation executes.",
		"status":_pronouncement_status_text(),
	})
	var merged_items:Array=AdvisorSystem.merged_report_items(6)
	if not merged_items.is_empty():
		var merged_rows:Array=[]
		for merged_variant in merged_items:
			var merged_item:Dictionary=merged_variant
			var merged_id:=String(merged_item.get("id",""))
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
		blocks.append({"type":"rows","heading":"MERGED & ROUTINE REPORTS","note":"%d held quiet" % AdvisorSystem.routine_report_count(),"items":merged_rows})
	blocks.append({"type":"text","heading":"HOW MERGING WORKS","text":"Repeat reports about the same condition fold into one entry instead of stacking up. Dismissed decisions defer here and only return to the queue if the condition worsens."})
	return blocks

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

func _pronouncement_status_text()->String:
	for order_variant in GameState.sovereign_orders:
		var order:Dictionary=order_variant
		if String(order.get("type",""))!="pronouncement": continue
		match String(order.get("status","")):
			"interpreting": return "INTERPRETING · The council is translating language into bounded policy…"
			"executed","active": return "Latest order executed. Standing policy appears under GOVERNMENT."
			"recorded_unresolved": return "Latest order was recorded but matched no bounded policy."
		break
	return ""

func signature()->Array:
	var ids:Array=[]
	for item_variant in GameState.council_inbox:
		var item:Dictionary=item_variant
		ids.append(String(item.get("id",""))+String(item.get("status","")))
	return [GameState.society_capacities.duplicate(),ids,GameState.sovereign_orders.size(),ConsequenceEngine.active_policies().size()]
