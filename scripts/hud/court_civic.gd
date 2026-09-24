extends RefCounted
## The civic side of a settlement leader's audience: which directive is open
## between the ruler and that leader, what state it is in, and the plain
## record of what was said. Read-only views over AdvisorSystem and
## GameState.sovereign_orders; orders still travel through the terrain's
## ordinary civic pipeline (issue_civic_directive_text).

const Tokens:=preload("res://scripts/hud/hud_tokens.gd")

static func leader_settlement(person_id:int)->String:
	## The settlement this person leads, or "" if they lead none.
	if person_id<=0: return ""
	for settlement in GameState.player_settlements:
		var sid:=String((settlement as Dictionary).get("id",""))
		if sid.is_empty(): continue
		if int(GovernmentPeopleSystem.settlement_leader(sid).get("person_id",0))==person_id: return sid
	return ""

static func settlement_name(settlement_id:String)->String:
	for settlement in GameState.player_settlements:
		if String((settlement as Dictionary).get("id",""))==settlement_id: return String((settlement as Dictionary).get("name",""))
	return ""

static func latest_order(settlement_id:String,leader_person_id:int)->Dictionary:
	var inherited_pending:Dictionary={}
	for order_variant in GameState.sovereign_orders:
		var order:Dictionary=order_variant
		if String(order.get("type",""))!="pronouncement": continue
		if String(order.get("settlement_id",""))!=settlement_id: continue
		if leader_person_id<=0 or int(order.get("leader_person_id",0))==leader_person_id: return order
		if inherited_pending.is_empty() and String(order.get("status","")) in ["awaiting_confirmation","awaiting_clarification","leader_refused"]:
			inherited_pending=order
	return inherited_pending

static func state(order:Dictionary)->String:
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

static func state_color(value:String)->Color:
	match value:
		"UNDERWAY","REPORTED","OBSERVING EFFECTS": return Tokens.GREEN
		"INTERPRETING","DISCUSSION","PROPOSAL RECORDED": return Tokens.BLUE
		"WITHDRAWN": return Tokens.BODY_2
		"REFUSED","BLOCKED": return Tokens.RED
		"NEEDS YOUR DECISION": return Tokens.AMBER
	return Tokens.BODY_2

static func status_text(value:String)->String:
	match value:
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

static func headline(value:String,leader_name:String)->String:
	## The short banner over the transcript: what stands between you and them.
	match value:
		"INTERPRETING": return "NOT YET UNDERWAY · %s is weighing your words" % leader_name
		"NEEDS YOUR DECISION": return "NEEDS YOUR DECISION · %s objects" % leader_name
		"PROPOSAL RECORDED": return "PROPOSAL RECORDED · %s has answered" % leader_name
		"DISCUSSION": return "DISCUSSION · %s gave advice" % leader_name
		"REFUSED": return "REFUSED · %s will not carry it out" % leader_name
		"BLOCKED": return "BLOCKED · the directive cannot proceed"
		"WITHDRAWN": return "WITHDRAWN · nothing from it is underway"
		"UNDERWAY": return "UNDERWAY · %s accepted responsibility" % leader_name
		"REPORTED": return "REPORTED · the outcome is recorded"
		"OBSERVING EFFECTS": return "ACTION COMPLETE · watching the consequences"
	return ""

static func quick_replies(value:String)->Array[Dictionary]:
	## Plain answers the ruler can give with one word. Each is ordinary speech
	## that the civic pipeline already understands; nothing here bypasses it.
	var replies:Array[Dictionary]=[]
	match value:
		"NEEDS YOUR DECISION":
			replies.append({"id":"confirm","label":"Yes — as I said","text":"Yes, confirm.","tip":"Confirm the exact meaning they asked about."})
			replies.append({"id":"insist","label":"I insist","text":"This is an order. Proceed.","tip":"Overrule their objection. Reluctant leaders may still refuse."})
			replies.append({"id":"withdraw","label":"Withdraw it","text":"Withdraw it.","tip":"Close the unresolved instruction. Nothing from it goes forward."})
		"REFUSED":
			replies.append({"id":"insist","label":"I insist","text":"This is an order. Proceed.","tip":"Repeat the order over their refusal."})
			replies.append({"id":"withdraw","label":"Withdraw it","text":"Withdraw it.","tip":"Close the unresolved instruction."})
	return replies

static func history(settlement_id:String,limit:int=6)->Array[Dictionary]:
	## The civic record with this settlement's leader, state suffixes removed.
	var result:Array[Dictionary]=[]
	for turn in AdvisorSystem.civic_dialogue_history(settlement_id,limit):
		var text:=String(turn.get("text",""))
		if "\n\nSTATE ·" in text: text=text.split("\n\nSTATE ·")[0]
		# Engine numbers travel as a small receipt beneath the speech.
		var receipt:=""
		if "\n\nRECEIPT · " in text:
			receipt=text.split("\n\nRECEIPT · ")[1].strip_edges()
			text=text.split("\n\nRECEIPT · ")[0]
		result.append({"speaker":"player" if String(turn.get("speaker",""))=="player" else "leader","name":String(turn.get("speaker_name","")),
			"text":text.strip_edges(),"receipt":receipt,"day":int(turn.get("day",0)),"status":String(turn.get("status","")),"order_id":String(turn.get("order_id",""))})
	return result

static func turn_key(turn:Dictionary)->String:
	return "%d|%s|%s|%s" % [int(turn.get("day",0)),String(turn.get("speaker","")),String(turn.get("order_id","")),String(turn.get("text","")).md5_text()]

static func pending_interpretation(settlement_id:String,leader_person_id:int)->Dictionary:
	## An order still being interpreted, which the ruler may call back.
	var order:=latest_order(settlement_id,leader_person_id)
	if String(order.get("status",""))=="interpreting": return order
	return {}
