extends Node

const ADVICE_ACTS := ["report", "recommend", "warn", "object", "request", "correct", "evade", "conceal", "confess", "bargain", "challenge", "remain_silent"]
const MAX_CIVIC_DIALOGUE_PER_SETTLEMENT:=24
const MAX_SOVEREIGN_ORDER_RECORDS:=100

var initialized := false
var rng := RandomNumberGenerator.new()
var order_sequence:=0

func reset_for_new_world()->void:
	initialized=false
	rng=RandomNumberGenerator.new()
	order_sequence=0

func initialize() -> void:
	if initialized:
		return
	rng.seed = GameState.world_seed ^ 0x2e17a5d3
	initialized = true
	_seed_world_truth()

func _seed_world_truth() -> void:
	WorldFacts.set_fact("civilization", "population", GameState.population_total, "public")
	WorldFacts.set_fact("civilization", "sovereign", "player", "public")
	WorldFacts.set_fact("civilization", "food_days", 30.0, "internal")
	WorldFacts.set_fact("civilization", "settlement_status", "unsettled", "public")

func register_advisors(roster: Array[Dictionary]) -> void:
	initialize()
	for candidate in roster:
		if not advisor_by_name(String(candidate.get("name",""))).is_empty():
			continue
		var advisor := candidate.duplicate(true)
		advisor["beliefs"] = []
		advisor["memories"] = []
		advisor["goals"] = _goals_for_background(advisor.background)
		advisor["relationships"] = {"sovereign":{"trust":rng.randf_range(0.35,0.72), "respect":rng.randf_range(0.35,0.78), "fear":rng.randf_range(0.05,0.32), "resentment":0.0, "obligation":rng.randf_range(0.3,0.7)}}
		advisor["honesty"] = rng.randf_range(0.35,0.92)
		advisor["courage"] = rng.randf_range(0.25,0.9)
		advisor["pride"] = rng.randf_range(0.2,0.88)
		advisor["suspicion"] = rng.randf_range(0.15,0.85)
		GameState.advisor_roster.append(advisor)

func _goals_for_background(background: String) -> Array:
	var mapping := {
		"Caravan Organizer":["secure_supplies","expand_routes","avoid_isolation"],
		"Healer and Naturalist":["protect_population","study_environment","prevent_disease"],
		"Master Builder":["establish_settlement","improve_infrastructure","secure_materials"],
		"Hunter-Captain":["secure_perimeter","maintain_readiness","survey_threats"],
		"Trader and Mediator":["preserve_cohesion","create_exchange","avoid_feuds"],
		"Keeper of Records":["preserve_knowledge","formalize_administration","record_orders"]
	}
	return mapping.get(background, ["serve_civilization"])

func appoint(advisor_name: String, office: String) -> bool:
	var advisor := advisor_by_name(advisor_name)
	if advisor.is_empty():
		return false
	var person_id:=int(advisor.get("person_id",0))
	if person_id>0:
		var appointed:Dictionary=GovernmentPeopleSystem.mark_central_appointment(person_id,office)
		if appointed.is_empty(): return false
		advisor=appointed
	GameState.leadership_positions[office] = advisor
	_record_memory(advisor_name, "The Sovereign appointed this person to the %s office." % office, 0.85, "duty")
	return true

func advisor_by_name(advisor_name: String) -> Dictionary:
	for advisor in GameState.advisor_roster:
		if advisor.name == advisor_name:
			return advisor
	return {}

func update_belief(advisor_name: String, subject: String, predicate: String, value: Variant, confidence: float, source: String) -> void:
	var advisor := advisor_by_name(advisor_name)
	if advisor.is_empty():
		return
	var belief := {"subject":subject, "predicate":predicate, "value":value, "confidence":clampf(confidence,0.0,1.0), "source":source, "day":int(GameState.elapsed_days)}
	advisor.beliefs.append(belief)

func generate_council_item(office: String, topic: String, urgency := 0.5) -> Dictionary:
	initialize()
	if not GameState.leadership_positions.has(office):
		return {}
	var advisor: Dictionary = GameState.leadership_positions[office]
	var act := _plan_advice(advisor, topic, urgency)
	var rendered := _render_locally(advisor, act)
	if not _validate(rendered, act):
		rendered = "%s requests your attention regarding %s." % [advisor.name, topic]
	var item := {"id":"council_%d_%d" % [int(GameState.elapsed_days), rng.randi()], "advisor":advisor.name, "office":office, "topic":topic, "act":act, "text":rendered, "urgency":urgency, "day":int(GameState.elapsed_days), "status":"unread"}
	GameState.council_inbox.push_front(item)
	return item

func generate_consequence_item(event: Dictionary) -> Dictionary:
	var office_by_domain := {"food":"Steward","health":"Steward","ecology":"Scholar","legitimacy":"Envoy","security":"Marshal","knowledge":"Scholar","materials":"Quartermaster"}
	var domain := String(event.get("domain","population"))
	var office := String(office_by_domain.get(domain,"Steward"))
	if not GameState.leadership_positions.has(office): return {}
	var responses:=_responses_for_domain(domain)
	# A council interruption is a decision, not a second event log. Economy,
	# materials, and other observational domains already have dedicated records;
	# if the council cannot offer an order that changes simulation state, it stays
	# out of the sovereign inbox entirely.
	if not _responses_change_state(responses): return {}
	var advisor:Dictionary=GameState.leadership_positions[office]
	var text := "Sovereign, %s %s" % [String(event.get("description","Conditions require attention.")),_recommendation_for(advisor,domain)]
	var condition_key:=String(event.get("condition_id",event.get("title",domain))).strip_edges().to_lower().replace(" ","_")
	var severity:=String(event.get("severity","warning"))
	var current_day:=int(GameState.elapsed_days)
	for existing_variant in GameState.council_inbox:
		var existing:Dictionary=existing_variant
		if String(existing.get("condition_key",""))!=condition_key: continue
		var prior_severity:=String(existing.get("severity","warning"))
		var last_day:=int(existing.get("last_day",existing.get("day",-100000)))
		if String(existing.get("status","unread"))=="unread":
			existing["text"]=text
			existing["day"]=current_day
			existing["last_day"]=current_day
			existing["occurrences"]=int(existing.get("occurrences",1))+1
			existing["severity"]=severity
			existing["urgency"]=maxf(float(existing.get("urgency",0.0)),_council_severity_urgency(severity))
			return existing
		if String(existing.get("status","unread"))=="deferred":
			# The Sovereign waved this condition off. It keeps merging silently
			# and only returns to the queue if it genuinely escalates.
			existing["text"]=text
			existing["last_day"]=current_day
			existing["occurrences"]=int(existing.get("occurrences",1))+1
			if _council_severity_rank(severity)>_council_severity_rank(String(existing.get("deferred_severity",prior_severity))):
				existing["status"]="unread"
				existing["day"]=current_day
				existing["severity"]=severity
				existing["urgency"]=_council_severity_urgency(severity)
				return existing
			existing["severity"]=severity
			return {}
		# An answered condition does not become a fresh sovereign interruption on
		# every simulation cooldown. Escalation may reopen it immediately; otherwise
		# a full year must pass before the same decision can be raised again.
		if _council_severity_rank(severity)<=_council_severity_rank(prior_severity) and current_day-last_day<365:
			return {}
	var item := {"id":"consequence_%d_%d" % [current_day,rng.randi()],"advisor":advisor.name,"office":office,"topic":domain,"act":{"type":"warn"},"text":text,"urgency":_council_severity_urgency(severity),"day":current_day,"last_day":current_day,"status":"unread","responses":responses,"condition_key":condition_key,"severity":severity,"occurrences":1}
	GameState.council_inbox.push_front(item)
	if GameState.council_inbox.size()>80: GameState.council_inbox.resize(80)
	return item

func _responses_change_state(responses:Array)->bool:
	for option_variant in responses:
		var option:Dictionary=option_variant
		if String(option.get("effect","")).strip_edges()!="": return true
	return false

func _council_severity_rank(severity:String)->int:
	return {"notice":0,"warning":1,"danger":2,"critical":3}.get(severity.to_lower(),1)

func _council_severity_urgency(severity:String)->float:
	return {"notice":0.42,"warning":0.68,"danger":0.84,"critical":0.96}.get(severity.to_lower(),0.68)

func council_decision_items(limit:=12,include_history:=true)->Array[Dictionary]:
	var unread:Array[Dictionary]=[]
	var history:Array[Dictionary]=[]
	for item_variant in GameState.council_inbox:
		var item:Dictionary=item_variant
		if not _responses_change_state(item.get("responses",[])): continue
		var status:=String(item.get("status","unread"))
		if status=="unread": unread.append(item)
		elif status!="deferred" and history.size()<6: history.append(item)
	var visible:Array[Dictionary]=[]
	for item in unread:
		if visible.size()>=limit: break
		visible.append(item)
	if include_history:
		for item in history:
			if visible.size()>=limit: break
			visible.append(item)
	return visible

func defer_council_item(item_id:String)->void:
	## Dismissing a queue card defers the decision: it stays in the ledger,
	## keeps merging silently, and returns only if its condition escalates.
	for item_variant in GameState.council_inbox:
		var item:Dictionary=item_variant
		if String(item.get("id",""))!=item_id: continue
		if String(item.get("status","unread"))=="unread":
			item["status"]="deferred"
			item["deferred_day"]=int(GameState.elapsed_days)
			item["deferred_severity"]=String(item.get("severity","warning"))
		return

func merged_report_items(limit:=8)->Array[Dictionary]:
	## Routine reports and deferred decisions — everything the queue keeps
	## quiet — so the ledger stays reachable from the council view.
	var merged:Array[Dictionary]=[]
	for item_variant in GameState.council_inbox:
		var item:Dictionary=item_variant
		var routine:=not _responses_change_state(item.get("responses",[]))
		var deferred:=String(item.get("status","unread"))=="deferred"
		if not routine and not deferred: continue
		merged.append(item)
		if merged.size()>=limit: break
	return merged

func routine_report_count()->int:
	var count:=0
	for item_variant in GameState.council_inbox:
		var item:Dictionary=item_variant
		if not _responses_change_state(item.get("responses",[])) or String(item.get("status","unread"))=="deferred": count+=1
	return count

func generate_travel_item(stage: String,data: Dictionary) -> Dictionary:
	initialize()
	var advisor:Dictionary={}
	var office:="Travel Council"
	for preferred_office in ["Quartermaster","Steward","Marshal"]:
		if GameState.leadership_positions.has(preferred_office):
			advisor=GameState.leadership_positions[preferred_office]
			office=preferred_office
			break
	if advisor.is_empty():
		for candidate in GameState.advisor_roster:
			if String(candidate.get("background","")) in ["Caravan Organizer","Hunter-Captain","Trader and Mediator"]:
				advisor=candidate
				break
	if advisor.is_empty() and not GameState.advisor_roster.is_empty():
		advisor=GameState.advisor_roster[0]
	var advisor_name:=String(advisor.get("name","The caravan speakers"))
	var distance:=float(data.get("distance_km",0.0))
	var duration:=float(data.get("duration_days",0.0))
	var food_days:=float(data.get("food_days",0.0))
	var progress:=roundi(float(data.get("progress",0.0))*100.0)
	var supply_ratio:=roundi(float(data.get("supply_ratio",1.0))*100.0)
	var text:=""
	match stage:
		"departure":
			text="Sovereign, the column is underway: %.0f km over roughly %.0f hours. We carry %.1f days of provisions; the road will decide the rest." % [distance,duration*24.0,food_days]
		"quarter":
			text="Sovereign, one quarter of the route lies behind us. The column remains together and the pace is holding."
		"half":
			text="Sovereign, we have crossed the midpoint. Stores stand at %.1f days; route foraging is meeting %d%% of daily need." % [food_days,supply_ratio]
		"three_quarters":
			text="Sovereign, the destination is now the nearer horizon. We are %d%% through the march and watching the weakest travelers closely." % progress
		"provisions_low":
			text="Sovereign, fewer than three days of provisions remain. Route foraging supplies only %d%% of need. Another delay may force a halt." % supply_ratio
		"arrival":
			text="Sovereign, the convoy has reached the ordered ground. Population groups are regrouping while losses, stores, and usable shelter are assessed."
		"settlement":
			var known_resources:=int(data.get("known_resources",0))
			text="Sovereign, your directive is given. The convoy is halting here to establish a permanent home. Stores stand at %.1f days, and %d nearby resource %s known. The builders are organizing the first Hearth Circle from the roles you assigned." % [food_days,known_resources,"site is" if known_resources==1 else "sites are"]
		"halt":
			text="Sovereign, the column has stopped. %s" % String(data.get("reason","Continuing would endanger the population."))
		_:
			text="Sovereign, the travel council reports that the convoy is %d%% through its present route." % progress
	var item:={
		"id":"travel_%s_%d_%d" % [stage,int(GameState.elapsed_days*24.0),rng.randi()],
		"advisor":advisor_name,"office":office,"topic":"settlement" if stage=="settlement" else "travel","act":{"type":"report"},
		"text":text,"urgency":0.82 if stage in ["provisions_low","halt"] else (0.58 if stage=="settlement" else 0.42),
		"day":int(GameState.elapsed_days),"hour":int(GameState.elapsed_days*24.0)%24,"status":"unread",
		"responses":[{"label":"Acknowledge","effect":"","magnitude":0.0,"days":1.0,"ripple":"The chosen ground enters the founding record; the convoy will no longer march." if stage=="settlement" else "The report is entered into the journey record."}]
	}
	GameState.council_inbox.push_front(item)
	if GameState.council_inbox.size()>80: GameState.council_inbox.resize(80)
	return item

func _recommendation_for(advisor: Dictionary,domain: String) -> String:
	var forceful: bool = "Directive" in advisor.traits or "Centralized" in advisor.traits
	var cautious: bool = "Consensus-driven" in advisor.traits or "Representative" in advisor.traits
	if domain=="food": return "We recommend emergency gathering." if forceful else ("We recommend measured rationing." if cautious else "The office requires a clear rule for provisions.")
	if domain=="health": return "The sick must be placed into a protected care rotation."
	if domain=="ecology": return "We must restrict nearby gathering before the damage becomes permanent." if cautious else "We can accept depletion now if survival demands it."
	if domain=="legitimacy": return "Call representative assemblies and explain the burden you require."
	if domain=="security": return "Expand the watch even though other work will slow."
	return "Your directive will decide which cost the population bears."

func _responses_for_domain(domain: String) -> Array[Dictionary]:
	if domain=="food": return [
		{"label":"Drive emergency gathering","effect":"foraging_drive","magnitude":0.24,"days":120.0,"ripple":"More food now; faster ecological depletion."},
		{"label":"Impose measured rationing","effect":"rationing","magnitude":0.22,"days":90.0,"ripple":"Stores last longer; health and cohesion face strain."},
		{"label":"Hold the present course","effect":"","magnitude":0.0,"days":1.0,"ripple":"No new burden, and no relief from the shortage."}
	]
	if domain=="health": return [
		{"label":"Create care rotations","effect":"care_rotation","magnitude":0.24,"days":120.0,"ripple":"Health improves; effective labor falls temporarily."},
		{"label":"Keep every able hand working","effect":"","magnitude":0.0,"days":1.0,"ripple":"Work continues; illness follows its present course."}
	]
	if domain=="ecology": return [
		{"label":"Restrict nearby gathering","effect":"conservation_order","magnitude":0.24,"days":365.0,"ripple":"Land recovers; immediate food yields decline."},
		{"label":"Take what survival requires","effect":"foraging_drive","magnitude":0.18,"days":180.0,"ripple":"Provision improves; long-run yield and legitimacy may suffer."}
	]
	if domain=="legitimacy": return [
		{"label":"Call a public assembly","effect":"public_assembly","magnitude":0.24,"days":120.0,"ripple":"Legitimacy and cohesion improve; administration is occupied."},
		{"label":"Reassert the directive","effect":"expanded_watch","magnitude":0.16,"days":90.0,"ripple":"Compliance is guarded; resentment remains unresolved."}
	]
	if domain=="security": return [
		{"label":"Expand the watch","effect":"expanded_watch","magnitude":0.24,"days":180.0,"ripple":"Security improves while scarce labor remains committed."},
		{"label":"Rely on cohesion","effect":"public_assembly","magnitude":0.14,"days":90.0,"ripple":"Local assemblies coordinate voluntarily; direct readiness stays limited."}
	]
	return [{"label":"Acknowledge the report","effect":"","magnitude":0.0,"days":1.0,"ripple":"No standing directive is changed."}]

func _plan_advice(advisor: Dictionary, topic: String, urgency: float) -> Dictionary:
	var relationship: Dictionary = advisor.relationships.sovereign
	var act_type := "recommend"
	if urgency > 0.78: act_type = "warn"
	elif relationship.resentment > 0.55 and advisor.honesty < 0.5: act_type = "conceal"
	elif advisor.courage < 0.3 and relationship.fear > 0.5: act_type = "evade"
	elif advisor.pride > 0.72 and relationship.respect < 0.35: act_type = "object"
	return {"type":act_type, "topic":topic, "meaning":_meaning_for(topic, act_type), "tone":_tone_for(advisor), "desired_effect":_desired_effect(topic), "allowed_entities":[advisor.name,"the Sovereign","the civilization"]}

func _meaning_for(topic: String, act_type: String) -> String:
	var meanings := {"food":"food reserves require attention", "resources":"resource access requires a decision", "knowledge":"investigators require direction", "construction":"labor and materials require prioritization", "security":"the civilization faces a security concern", "population":"population organization requires adjustment"}
	return meanings.get(topic, "%s requires a sovereign decision" % topic)

func _desired_effect(topic: String) -> String:
	return "obtain a clear sovereign directive concerning %s" % topic

func _tone_for(advisor: Dictionary) -> String:
	if "Directive" in advisor.traits: return "severe"
	if "Consensus-driven" in advisor.traits: return "guarded"
	if "Representative" in advisor.traits: return "confident"
	if "Expert-led" in advisor.traits: return "precise"
	return "formal"

func _render_locally(advisor: Dictionary, act: Dictionary) -> String:
	var templates := {
		"report":"Sovereign, this office reports that %s.",
		"recommend":"Sovereign, we recommend action: %s.",
		"warn":"Sovereign, this cannot be neglected: %s.",
		"object":"Sovereign, this office must object. %s.",
		"evade":"Sovereign, the matter remains uncertain. The office can only report that %s.",
		"conceal":"Sovereign, there is little of consequence to report, beyond this: %s."
	}
	return templates.get(act.type, "Sovereign, %s.") % act.meaning

func _validate(text: String, act: Dictionary) -> bool:
	if text.length() > 360 or text.strip_edges().is_empty():
		return false
	return act.meaning.trim_suffix(".") in text

func issue_order(order_type: String, target: String, parameters: Dictionary, addressed_office := "") -> Dictionary:
	initialize()
	order_sequence+=1
	var order := {"id":"order_%d_%d" % [int(GameState.elapsed_days),rng.randi()], "sequence":order_sequence,"type":order_type, "target":target, "parameters":parameters.duplicate(true), "office":addressed_office, "issued_day":int(GameState.elapsed_days), "status":"issued"}
	GameState.sovereign_orders.push_front(order)
	_prune_sovereign_orders()
	if addressed_office != "" and GameState.leadership_positions.has(addressed_office):
		var advisor: Dictionary = GameState.leadership_positions[addressed_office]
		_record_memory(advisor.name, "The Sovereign issued a %s directive concerning %s." % [order_type,target], 0.78, "directive")
	return order

func begin_pronouncement(text:String)->Dictionary:
	var order:=issue_order("pronouncement","civilization",{"text":text.strip_edges().substr(0,500),"interpretation":{}},"")
	order["status"]="interpreting"
	order["submitted_day"]=int(GameState.elapsed_days)
	return order


func _prune_sovereign_orders(limit:int=MAX_SOVEREIGN_ORDER_RECORDS)->void:
	## Discussion is plentiful; live government business is not disposable. Prune
	## the oldest closed talk first, then other resolved records, while retaining
	## unresolved negotiations, promised reports, and the source of every policy
	## that is still materially active.
	while GameState.sovereign_orders.size()>limit:
		var remove_index:=_oldest_prunable_order_index(true)
		if remove_index<0: remove_index=_oldest_prunable_order_index(false)
		if remove_index<0:
			# A genuine overflow of live business is safer than silently deleting an
			# order people are carrying out. Ordinary play cannot reach this state:
			# new subjects supersede unresolved talk and policy load is capacity-bound.
			break
		GameState.sovereign_orders.remove_at(remove_index)


func _oldest_prunable_order_index(disposable_only:bool)->int:
	for index in range(GameState.sovereign_orders.size()-1,-1,-1):
		var order:Dictionary=GameState.sovereign_orders[index]
		if _sovereign_order_is_live(order): continue
		if disposable_only and not _sovereign_order_is_disposable(order): continue
		return index
	return -1


func _sovereign_order_is_live(order:Dictionary)->bool:
	if String(order.get("status","")) in ["interpreting","awaiting_confirmation","awaiting_clarification","leader_refused"]: return true
	var followup_state:=String(order.get("implementation_followup",{}).get("state",""))
	if followup_state=="pending": return true
	var order_id:=String(order.get("id",""))
	if order_id.is_empty(): return false
	# If the outcome is still in the player's bounded visible conversation, keep
	# its order record so "what happened?" can resolve to evidence rather than a
	# generic answer. It becomes prunable naturally when the dialogue rolls on.
	if followup_state=="reported":
		for history_variant in GameState.civic_dialogues.values():
			if not history_variant is Array: continue
			for record_variant in history_variant:
				if record_variant is Dictionary and String((record_variant as Dictionary).get("order_id",""))==order_id: return true
	for modifier_variant in GameState.active_modifiers:
		if not modifier_variant is Dictionary: continue
		var modifier:Dictionary=modifier_variant
		if String(modifier.get("source_order_id",""))!=order_id: continue
		if modifier.has("ended_reason"): continue
		if float(modifier.get("until_day",INF))>=GameState.elapsed_days: return true
	return false


func _sovereign_order_is_disposable(order:Dictionary)->bool:
	return String(order.get("status","")) in ["discussion","withdrawn","cancelled","negotiated","deliberated","clarified","continued","recorded_unresolved","no_effect","blocked","closed","expired","repealed","superseded","stale"]


func begin_civic_directive(text:String,settlement_id:String,leader:Dictionary)->Dictionary:
	var order:=begin_pronouncement(text)
	order["settlement_id"]=settlement_id
	order["leader_person_id"]=int(leader.get("person_id",0))
	order["addressed_to"]=String(leader.get("name","Unappointed leader"))
	order["leader_title"]=String(leader.get("title",leader.get("office_title","Local leader")))
	order["leader_disposition"]=String(GovernmentPeopleSystem.leader_disposition(leader).get("id","pragmatic"))
	_append_civic_dialogue(settlement_id,{
		"day":int(GameState.elapsed_days),"speaker":"player","speaker_name":"You",
		"text":text.strip_edges().substr(0,500),"order_id":String(order.id),"status":"submitted",
	})
	return order


func recover_interrupted_civic_directives()->int:
	# HTTP requests are process-local. If the scene or game closes while one is
	# pending, its serialized order cannot truthfully remain INTERPRETING forever.
	var recovered:=0
	for order_variant in GameState.sovereign_orders:
		var order:Dictionary=order_variant
		if String(order.get("type",""))!="pronouncement" or String(order.get("status",""))!="interpreting": continue
		var settlement_id:=String(order.get("settlement_id",""))
		var reply:=_with_civic_state("Our exchange was interrupted before I could answer. Repeat or revise the instruction and I will consider it again.","NEEDS YOUR DECISION")
		order["status"]="awaiting_clarification"
		order["leader_stance"]="clarify"
		order["leader_reply"]=reply
		order["parameters"]={
			"text":String(order.get("parameters",{}).get("text","Interrupted directive")),
			"interpretation":{"source":"interrupted","source_detail":"The game or civic panel closed before interpretation completed.","summary":"No policy was applied.","policies":[],"unresolved":"Repeat or revise the instruction."},
		}
		_append_civic_dialogue(settlement_id,{
			"day":int(GameState.elapsed_days),"speaker":"leader","speaker_name":String(order.get("addressed_to","The leader")),
			"title":String(order.get("leader_title","Local leader")),"text":reply,"order_id":String(order.get("id","")),
			"status":"clarify","disposition":String(order.get("leader_disposition","pragmatic")),"source":"interrupted",
		})
		recovered+=1
	return recovered


func civic_dialogue_history(settlement_id:String,limit:int=8)->Array[Dictionary]:
	var history:Array=GameState.civic_dialogues.get(settlement_id,[])
	var result:Array[Dictionary]=[]
	var start:=maxi(0,history.size()-maxi(1,limit))
	for index in range(start,history.size()):
		if history[index] is Dictionary: result.append((history[index] as Dictionary).duplicate(true))
	return result


func civic_retry_text(text:String,settlement_id:String)->String:
	if text.strip_edges().to_lower().trim_suffix(".") not in ["retry","try again","retry that"]: return text
	var history:=civic_dialogue_history(settlement_id,2)
	if history.is_empty() or String(history.back().get("status",""))!="connection_interrupted": return text
	var order:=_civic_order_by_id(String(history.back().get("order_id","")))
	return String(order.get("parameters",{}).get("text",text))

func civic_decision_context(settlement_id:String)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for order:Dictionary in GameState.sovereign_orders:
		if String(order.get("settlement_id",""))!=settlement_id or String(order.get("status",""))=="interpreting": continue
		result.append({"status":String(order.get("status","")),"request":String(order.get("parameters",{}).get("text",order.get("text",""))).substr(0,500),"outcome":String(order.get("leader_reply","")).substr(0,2400)})
		if result.size()>=8: break
	return result

func civic_leadership_action(text:String,leader_name:String="")->String:
	# Leadership commands are office actions, not policy prose. Keep the phrases
	# deliberately second-person (or name the current leader) so "arrest
	# dissidents" still goes through the ordinary directive interpreter. A
	# question or a negated threat is discussion, never an irreversible click in
	# disguise.
	var normalized:=_normalized_civic_control_text(text)
	if _civic_control_is_question(normalized): return ""
	for negation in ["do not arrest you","don't arrest you","will not arrest you","won't arrest you","not arresting you","do not detain you","don't detain you","not under arrest","do not fire you","don't fire you","will not fire you","won't fire you","not firing you","do not dismiss you","don't dismiss you","not dismissing you","do not remove you","don't remove you"]:
		if negation in normalized: return ""
	for phrase in ["you are under arrest","you're under arrest","arrest you","have you arrested","detain you","you are detained","i order your arrest","take you into custody"]:
		if phrase in normalized: return "arrest"
	var key:=_civic_control_key(normalized)
	if key=="arrest": return "arrest"
	for phrase in ["you are fired","you're fired","fire you","dismiss you","i dismiss you","remove you from office","replace you as leader","you no longer lead","you are removed","you're removed","step down","leave your office","resign your office"]:
		if phrase in normalized: return "dismiss"
	var named:=_civic_control_key(_normalized_civic_control_text(leader_name))
	if not named.is_empty():
		for phrase in ["arrest %s" % named,"detain %s" % named,"take %s into custody" % named]:
			if phrase in key: return "arrest"
		for phrase in ["fire %s" % named,"dismiss %s" % named,"remove %s" % named,"replace %s" % named]:
			if phrase in key: return "dismiss"
	return ""


func civic_conversation_action(text:String,settlement_id:String,leader_person_id:int=0)->String:
	## Resolve only short, anaphoric control phrases here. Named policy repeals
	## still belong to the directive interpreter. This keeps "cancel rationing"
	## mechanically different from "forget the proposal we are discussing."
	if _pending_civic_context(settlement_id,leader_person_id).is_empty(): return ""
	var normalized:=_normalized_civic_control_text(text)
	if _civic_control_is_question(normalized): return ""
	for negation in ["do not withdraw","don't withdraw","do not cancel","don't cancel","do not drop","don't drop","do not forget","don't forget","keep discussing","continue discussing"]:
		if negation in normalized: return ""
	var key:=_civic_control_key(normalized)
	if key in ["forget it","never mind","nevermind","withdraw it","withdraw that","withdraw this","withdraw the order","withdraw that order","drop it","drop that","drop the order","cancel it","cancel that","cancel this proposal","cancel that proposal","stop this","leave it","let it go","do not proceed","don't proceed"]:
		return "withdraw"
	return ""


func withdraw_pending_civic_directive(settlement_id:String,leader_person_id:int,player_text:String)->Dictionary:
	var pending:=_pending_civic_context(settlement_id,leader_person_id)
	if pending.is_empty(): return {"ok":false,"reason":"There is no unresolved directive to withdraw."}
	var previous_status:=String(pending.get("status","unresolved"))
	pending["status"]="withdrawn"
	pending["leader_stance"]="withdrawn"
	pending["withdrawn_day"]=int(GameState.elapsed_days)
	pending["withdrawn_from_status"]=previous_status
	_append_civic_dialogue(settlement_id,{
		"day":int(GameState.elapsed_days),"speaker":"player","speaker_name":"You",
		"text":player_text.strip_edges().substr(0,500),"order_id":String(pending.get("id","")),"status":"withdrawal",
	})
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	var disposition_id:=String(GovernmentPeopleSystem.leader_disposition(leader).get("id","pragmatic"))
	var response:="Understood. I have withdrawn the unresolved instruction. Nothing from that proposal is underway."
	match disposition_id:
		"sycophantic": response="As you wish. I have withdrawn the unresolved instruction; nothing from it is underway."
		"cantankerous": response="Good. The unresolved instruction is dropped. Nothing from it is underway."
		"principled": response="It is withdrawn and entered as such. Nothing from that proposal is underway."
		"diplomatic": response="I will close the unresolved instruction without carrying it further. Nothing from it is underway."
	var reply:=_with_civic_state(response,"WITHDRAWN — NO POLICY APPLIED")
	pending["leader_reply"]=reply
	_append_leader_reply(settlement_id,leader,reply,pending,"withdrawn")
	return {"ok":true,"message":reply,"order_id":String(pending.get("id","")),"previous_status":previous_status}


func _normalized_civic_control_text(text:String)->String:
	var normalized:=text.to_lower().replace("\r"," ").replace("\n"," ").replace("\t"," ").strip_edges()
	while "  " in normalized: normalized=normalized.replace("  "," ")
	return normalized


func _civic_control_key(normalized:String)->String:
	var key:=normalized.strip_edges()
	while not key.is_empty() and key.right(1) in [".","!",",",";",":"]: key=key.left(-1).strip_edges()
	return key


func _civic_control_is_question(normalized:String)->bool:
	if normalized.ends_with("?"): return true
	for opener in ["should i ","should we ","what if ","would you ","could i ","could we ","can i ","can we ","do you think ","are you saying ","why ","when ","how "]:
		if normalized.begins_with(opener): return true
	return false


func record_civic_leadership_change(settlement_id:String,player_text:String,result:Dictionary)->void:
	if not player_text.strip_edges().is_empty():
		_append_civic_dialogue(settlement_id,{
			"day":int(GameState.elapsed_days),"speaker":"player","speaker_name":"You",
			"text":player_text.strip_edges().substr(0,500),"status":"leadership_action",
		})
	var message:=String(result.get("message",result.get("reason","Leadership did not change.")))
	if bool(result.get("ok",false)):
		var successor:Dictionary=result.get("successor",{})
		var pending:=_pending_civic_context(settlement_id,int(successor.get("person_id",0)))
		if not pending.is_empty():
			message+=" The unresolved directive remains before the office; %s must now answer it." % String(successor.get("name","the successor"))
	_append_civic_dialogue(settlement_id,{
		"day":int(GameState.elapsed_days),"speaker":"record","speaker_name":"COUNCIL RECORD",
		"text":message,"status":"leadership_changed" if bool(result.get("ok",false)) else "leadership_unchanged",
	})


func record_civic_implementation_report(settlement_id:String,order:Dictionary,leader:Dictionary,report_text:String,outcome:String)->bool:
	## Outcome reports belong to the same exchange that commissioned the work.
	## The inbox may still surface the event, but reopening CIVICS should show the
	## leader's answer in conversational order and permit a grounded follow-up.
	if settlement_id.is_empty() or String(order.get("id","" )).is_empty() or report_text.strip_edges().is_empty(): return false
	var order_id:=String(order.get("id",""))
	var history:Array=GameState.civic_dialogues.get(settlement_id,[])
	for record_variant in history:
		if not record_variant is Dictionary: continue
		var record:Dictionary=record_variant
		if String(record.get("order_id",""))==order_id and String(record.get("status","")).begins_with("outcome_report_"):
			return false
	var normalized_outcome:=outcome if outcome in ["success","partial","failure"] else "partial"
	var state_label:="REPORT · SUCCEEDED" if normalized_outcome=="success" else "REPORT · PARTIAL" if normalized_outcome=="partial" else "REPORT · FAILED"
	var speaker_name:=String(leader.get("name",order.get("addressed_to","The appointed leader")))
	var speaker_title:=String(leader.get("title",order.get("leader_title","Local leader")))
	_append_civic_dialogue(settlement_id,{
		"day":int(GameState.elapsed_days),"speaker":"leader","speaker_name":speaker_name,"title":speaker_title,
		"text":_with_civic_state(report_text.substr(0,900),state_label),"order_id":order_id,
		"status":"outcome_report_%s" % normalized_outcome,"disposition":String(GovernmentPeopleSystem.leader_disposition(leader).get("id","unavailable")),
		"source":"deterministic implementation report",
	})
	return true


func pending_civic_proposal(settlement_id:String,leader_person_id:int=0)->Dictionary:
	var inherited:Dictionary={}
	for order_variant in GameState.sovereign_orders:
		var order:Dictionary=order_variant
		if String(order.get("settlement_id",""))!=settlement_id or String(order.get("status",""))!="awaiting_confirmation": continue
		if leader_person_id<=0 or int(order.get("leader_person_id",0))==leader_person_id: return order
		if inherited.is_empty(): inherited=order
	# The speaker changes at succession, but recorded government business does
	# not vanish. The new leader inherits the latest unresolved proposal.
	return inherited


func _pending_civic_context(settlement_id:String,leader_person_id:int)->Dictionary:
	var inherited:Dictionary={}
	for order_variant in GameState.sovereign_orders:
		var order:Dictionary=order_variant
		if String(order.get("settlement_id",""))!=settlement_id: continue
		if String(order.get("status","")) not in ["awaiting_confirmation","awaiting_clarification","leader_refused","blocked"]: continue
		var prior_interpretation:Dictionary=order.get("parameters",{}).get("interpretation",{})
		if (prior_interpretation.get("policies",[]) as Array).is_empty(): continue
		if int(order.get("leader_person_id",0))==leader_person_id: return order
		if inherited.is_empty(): inherited=order
	return inherited


func contextualize_civic_followup(text:String,interpretation:Dictionary,settlement_id:String,leader_person_id:int=0)->Dictionary:
	var result:=interpretation.duplicate(true)
	if bool(result.get("service_failure",false)): return result
	var prior:=_pending_civic_context(settlement_id,leader_person_id)
	if prior.is_empty(): return result
	var duration_revision:=_civic_duration_revision(text)
	if _rejects_civic_proposal(text) and duration_revision.is_empty():
		result["rejected_prior_order_id"]=String(prior.get("id",""))
		return result
	var ethical:Dictionary=prior.get("ethical_deliberation",{})
	var prior_interpretation:Dictionary=prior.get("parameters",{}).get("interpretation",{})
	var prior_policies:Array=prior_interpretation.get("policies",[])
	if prior_policies.is_empty(): return result
	if not duration_revision.is_empty() and prior_policies.size()!=1:
		result["policies"]=[]; result["non_directive"]=true
		result["answer"]="Which part of the proposal should use that duration? The existing terms are still recorded; nothing has changed."
		return result
	# A pending grave discussion supplies context, not carte blanche. Asking why,
	# describing conditions, or testing a hypothetical must not silently inherit
	# the prior killing/coercion policy and advance its confirmation sequence.
	if not ethical.is_empty() and bool(result.get("non_directive",false)) and not _is_civic_confirmation(text) and not _is_civic_insistence(text):
		return result
	# A grave conversation is not a trap. A clearly different command starts a
	# new subject instead of being treated as an answer to the old leader's
	# question. Only replies that actually discuss that proposal's target, scope,
	# enforcement, or explicit confirmation inherit it.
	if not ethical.is_empty() and not _grave_followup_matches_context(text,prior_policies):
		return result
	# During grave deliberation the leader's question supplies the conversational
	# subject. A standalone reading such as "ration food" must not displace that
	# subject merely because the reply mentions food as an enforcement answer.
	if ethical.is_empty() and not (result.get("policies",[]) as Array).is_empty(): return result
	if ethical.is_empty() and not _is_civic_insistence(text) and not _is_civic_confirmation(text) and duration_revision.is_empty(): return result
	var continued:Array[Dictionary]=[]
	for policy_variant in prior_policies:
		var policy:Dictionary=(policy_variant as Dictionary).duplicate(true)
		for transient_key in ["conversation_assessment","implementation_capacity","implementation_constraints","directive_costs","direct_effects","blocker","applied","skipped_as_stale","_conversation_deferred","_conversation_refused","_conversation_blocked","_office_execution_override","_executor_override"]: policy.erase(transient_key)
		if not ethical.is_empty(): _merge_grave_followup_parameters(policy,text)
		if not duration_revision.is_empty():
			policy["days"]=float(duration_revision.days)
			policy["duration_source"]=String(duration_revision.source)
		policy["basis"]="contextual continuation: %s" % text.strip_edges().substr(0,80)
		policy["confidence"]=1.0
		continued.append(policy)
	result["policies"]=continued
	result["contextual_prior_order_id"]=String(prior.get("id",""))
	if int(prior.get("leader_person_id",0))!=leader_person_id:
		result["context_inherited_from"]=String(prior.get("addressed_to","the previous leader"))
	if not String(prior.get("accepted_meaning","")).is_empty(): result["confirmed_grave_meaning"]=String(prior.get("accepted_meaning",""))
	result["source_detail"]=(String(result.get("source_detail",""))+" · contextual continuation of the leader's recorded civic discussion").strip_edges()
	result["unresolved"]=""
	return result

func _civic_duration_revision(text:String)->Dictionary:
	var pattern:=RegEx.new()
	pattern.compile("^(?:(?:no|actually)[, ]+)?(?:(?:make it|make that|limit it to|for|only|just)\\s+)?(?:[0-9]+|one|two|three|four|five|six|seven|eight|nine|ten|thirty|sixty|ninety)\\s+(?:days?|weeks?|months?|years?)(?:\\s+(?:instead|only))?$" )
	var clean:=text.strip_edges().to_lower().trim_suffix(".")
	return PronouncementInterpreter._explicit_duration(clean) if pattern.search(clean)!=null else {}


func _grave_followup_matches_context(text:String,prior_policies:Array)->bool:
	if _is_civic_confirmation(text) or _is_civic_insistence(text): return true
	var normalized:=text.to_lower().strip_edges()
	for policy_variant in prior_policies:
		match String((policy_variant as Dictionary).get("id","")):
			"mass_repression":
				for term in ["kill","execute","purge","death","lethal","punish","enforcer","resist","nonlethal","non-lethal","included","women","woman","female","girls","men","man","male","boys","older","younger","over ","under ","dissident","captive","sick"]:
					if term in normalized: return true
			"coercive_pronatalism":
				for term in ["pregnan","conception","birth","sex","mate","mating","husband","parent","single child","single-child","fertile","withhold","punish","threat","deadline","six months","6 months","voluntary family"]:
					if term in normalized: return true
			"population_resettlement":
				for term in ["relocat","deport","remove them","move them","destination","remain","right to stay","transport","provision them","force them","voluntary relocation"]:
					if term in normalized: return true
			"birth_restrictions":
				for term in ["pregnan","birth","child","parent","contrace","steril","family planning","limit families","punish","enforcer"]:
					if term in normalized: return true
	return false


func _merge_grave_followup_parameters(policy:Dictionary,text:String)->void:
	# A reply to a leader's question modifies the proposal already under
	# discussion. It is not a fresh policy prompt. Preserve the original target
	# and add only the scope or enforcement details actually supplied here.
	var parameters:Dictionary=(policy.get("directive_parameters",{}) as Dictionary).duplicate(true)
	var normalized:=text.to_lower().strip_edges()
	var policy_id:=String(policy.get("id",""))
	if policy_id=="coercive_pronatalism":
		var restates_target:=false
		for term in ["pregnant","pregnancy","women","woman","female","parent","single child","single-child","one child","have sex","mating","mate "]:
			if term in normalized:
				restates_target=true
				break
		if restates_target:
			var supplemented:Dictionary=PronouncementInterpreter._deterministic_directive_parameters(text,policy_id)
			for key in ["conception_target","demographic_target","deadline_kind","coercion_method","ethical_severity","deliberation_required"]:
				if supplemented.has(key): parameters[key]=supplemented[key]
		var withholds_food:=("withhold" in normalized or "withheld" in normalized or "deny food" in normalized or "denied food" in normalized) and "food" in normalized
		if withholds_food: parameters["enforcement_method"]="withhold food completely" if "completely" in normalized else "withhold food"
		if "husband" in normalized:
			parameters["punishment_target"]={"scope":"targeted","sex":"male","role":"husbands","label":"their husbands"}
	elif policy_id=="mass_repression":
		if _is_civic_confirmation(text) or _is_civic_insistence(text): return
		var supplies_target:=PronouncementInterpreter._has_whole_word(normalized,"women|woman|female|girls|men|man|male|boys|workers?|over|older than|under|younger than|dissidents|the sick|the opposition|the population")
		if supplies_target:
			var supplemented:Dictionary=PronouncementInterpreter._deterministic_directive_parameters(text,policy_id)
			var prior_target:Dictionary=parameters.get("demographic_target",{})
			var revised_target:Dictionary=supplemented.get("demographic_target",{})
			if prior_target.has("exact_count") and not revised_target.has("exact_count"):
				revised_target["exact_count"]=prior_target.exact_count
				revised_target["scope"]="counted"
				revised_target["label"]="exactly %d %s" % [int(prior_target.exact_count),String(revised_target.get("label","people"))]
			for key in supplemented: parameters[key]=supplemented[key]
	policy["directive_parameters"]=parameters


func resolve_civic_directive(text:String,interpretation:Dictionary,existing_order:Dictionary,settlement_id:String,leader_person_id:int)->Dictionary:
	initialize()
	var order:=existing_order
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	if bool(interpretation.get("service_failure",false)):
		order["status"]="discussion"
		order["leader_stance"]="connection_interrupted"
		order["leader_reply"]=String(interpretation.get("answer","The reply was interrupted. Retry or revise your message; no action was taken."))
		order["parameters"]={"text":text,"interpretation":interpretation.duplicate(true)}
		_append_leader_reply(settlement_id,leader,String(order.leader_reply),order,"connection_interrupted")
		return order
	if leader.is_empty() or int(leader.get("person_id",0))!=leader_person_id:
		var unavailable:=_with_civic_state("No appointed leader can answer this instruction. Appoint the settlement leader, then speak to that person again.","BLOCKED")
		order["status"]="leader_unavailable"
		order["leader_stance"]="unavailable"
		order["leader_reply"]=unavailable
		order["parameters"]={"text":text,"interpretation":interpretation.duplicate(true)}
		_append_leader_reply(settlement_id,leader,unavailable,order,"unavailable")
		return order
	var prior_context:=_pending_civic_context(settlement_id,leader_person_id)
	var result:=contextualize_civic_followup(text,interpretation,settlement_id,leader_person_id)
	var disposition:Dictionary=GovernmentPeopleSystem.leader_disposition(leader)
	order["leader_disposition"]=String(disposition.get("id","pragmatic"))
	if not String(result.get("confirmed_grave_meaning","")).is_empty(): order["accepted_meaning"]=String(result.confirmed_grave_meaning)
	var policies:Array=result.get("policies",[])
	var future_delay:=_civic_future_delay(text)
	if future_delay>0:
		# A future celebration is not authorization to enact an assembly today.
		policies=[]
		result["policies"]=[]
		result["future_start_days"]=future_delay
	if not prior_context.is_empty() and (not policies.is_empty() or result.has("rejected_prior_order_id")) and String(result.get("contextual_prior_order_id","" )).is_empty():
		_close_civic_context(prior_context,"superseded",String(order.get("id","")))
		order["supersedes_order_id"]=String(prior_context.get("id",""))
		order["supersedes_subject"]=_order_subject(prior_context)
		# Do not let the cached dictionary keep the former ethical stage alive
		# after the player has plainly changed the subject.
		prior_context={}
	if policies.is_empty():
		if bool(result.get("non_directive",false)):
			var discussion_topics:Array=result.get("discussion_policy_ids",[])
			var discussion_reference:=_civic_discussion_reference(settlement_id,String(order.get("id","")),prior_context,discussion_topics)
			var discussion_text:=String(result.get("answer","")).strip_edges()
			if discussion_text.is_empty(): discussion_text=_leader_discussion_reply(leader,discussion_topics,text)
			var discussion_state:="DISCUSSION — NO ORDER GIVEN"
			if not discussion_reference.is_empty() and String(result.get("answer","")).strip_edges().is_empty():
				discussion_text=_leader_contextual_discussion_reply(leader,discussion_reference,discussion_topics,text)
				discussion_state="DISCUSSION — NO NEW ORDER"
				order["discussion_reference_order_id"]=String(discussion_reference.get("id",""))
			var discussion:=_with_civic_state(discussion_text,discussion_state)
			order["status"]="discussion"
			order["leader_stance"]="advises"
			order["leader_reply"]=discussion
			order["parameters"]={"text":text,"interpretation":result}
			_append_leader_reply(settlement_id,leader,discussion,order,"advises")
			return order
		var answer:=String(result.get("answer","")).strip_edges()
		if answer.is_empty(): answer=_civic_unmapped_answer(text,result)
		var proposal:=_with_civic_state(answer+"\n\nI have recorded this proposal. No event has been scheduled and no people or stores have been committed.","PROPOSAL RECORDED")
		order["status"]="proposal"
		order["leader_stance"]="advises"
		order["leader_reply"]=proposal
		order["parameters"]={"text":text,"interpretation":result}
		_append_leader_reply(settlement_id,leader,proposal,order,"advises")
		return order
	var grave:=_is_grave_directive(text,policies)
	var grave_confirmed:=false
	for policy_variant in policies:
		if bool((policy_variant as Dictionary).get("_grave_meaning_confirmed",false)):
			grave_confirmed=true
			break
	var prior_deliberation:Dictionary=prior_context.get("ethical_deliberation",{})
	if grave and not grave_confirmed:
		# Clear fictional orders use the same execution rules regardless of harm.
		# Clarification below concerns uncertain meaning, never mandatory ethics.
		order["accepted_meaning"]=_grave_meaning(policies)
		result["confirmed_grave_meaning"]=String(order.accepted_meaning)
		for policy_variant in policies:
			var confirmed_policy:Dictionary=policy_variant
			confirmed_policy["_grave_meaning_confirmed"]=true
	if prior_deliberation.is_empty() and _interpretation_needs_clarification(policies):
		var focused_question:=_with_civic_state(_low_confidence_question(leader,policies),"NEEDS YOUR DECISION")
		order["status"]="awaiting_clarification"
		order["leader_stance"]="clarify"
		order["leader_reply"]=focused_question
		order["clarification_kind"]="interpretation"
		order["parameters"]={"text":text,"interpretation":result}
		order["policy_ids"]=_policy_ids(policies)
		_append_leader_reply(settlement_id,leader,focused_question,order,"clarify")
		return order
	var insistence:=_is_civic_insistence(text)
	var prepared:Array[Dictionary]=[]
	var committed:=0
	var deferred:=0
	var refused:=0
	var blocked:=0
	var implementation_total:=0.0
	var limitation_texts:Array[String]=[]
	for policy_variant in policies:
		var policy:Dictionary=(policy_variant as Dictionary).duplicate(true)
		var skills:Array=policy.get("skills",[])
		var execution:=execution_modifier_for_advisor(leader,"SettlementLeader",skills)
		var directive_parameters:Dictionary=policy.get("directive_parameters",{})
		var assessment:=ConsequenceEngine.directive_assessment(String(policy.get("id","")),float(policy.get("magnitude",0.0)),float(policy.get("days",30.0)),execution,directive_parameters)
		policy["conversation_assessment"]=assessment.duplicate(true)
		policy["requested_magnitude"]=float(assessment.get("requested_magnitude",policy.get("magnitude",0.0)))
		var willingness:=_leader_willingness(leader,String(policy.get("id","")),assessment)
		policy["leader_willingness"]=willingness
		if not bool(assessment.get("can_apply",false)):
			policy["_conversation_blocked"]=true
			policy["blocker"]=String(assessment.get("blocker","The settlement cannot carry this out."))
			limitation_texts.append(String(policy.blocker))
			blocked+=1
		else:
			var compelled:=willingness<0.42
			policy["leader_compelled"]=compelled
			if compelled: limitation_texts.append(_leader_objection(leader,String(policy.get("id","")),assessment))
			# Objections affect characterization and relationships, not authorization.
			policy["_office_execution_override"]=execution
			policy["_executor_override"]="%s, %s" % [String(leader.get("name","The leader")),String(leader.get("title","local leader"))]
			committed+=1
			implementation_total+=float(assessment.get("implementation_rate",0.0))
			for limitation_variant in assessment.get("limitations",[]):
				var limitation:=String(limitation_variant)
				if not limitation_texts.has(limitation): limitation_texts.append(limitation)
		prepared.append(policy)
	result["policies"]=prepared
	if committed==0 and refused>0:
		var repeat_refusals:=_prior_civic_refusal_count(settlement_id,leader_person_id,_policy_ids(prepared),String(order.get("id","")))
		var refusal_text:=_leader_refusal_reply(leader,limitation_texts,insistence,repeat_refusals)
		if not String(order.get("accepted_meaning","")).is_empty(): refusal_text="Accepted meaning: %s\n\n%s" % [String(order.accepted_meaning),refusal_text]
		var refusal:=_with_civic_state(refusal_text,"REFUSED")
		order["status"]="leader_refused"
		order["leader_stance"]="refuses"
		order["repeat_refusal_count"]=repeat_refusals
		order["leader_reply"]=refusal
		order["parameters"]={"text":text,"interpretation":result}
		order["policy_ids"]=_policy_ids(prepared)
		var repetition_strain:=minf(0.018,float(repeat_refusals)*0.006)
		GovernmentPeopleSystem.adjust_person_relationship(leader_person_id,-0.022-repetition_strain,0.006,0.035+repetition_strain)
		if not prior_context.is_empty() and not String(result.get("contextual_prior_order_id","")).is_empty():
			_close_civic_context(prior_context,"continued",String(order.get("id","")))
		_append_leader_reply(settlement_id,leader,refusal,order,"refuses")
		return order
	if committed==0 and deferred>0:
		var objection_text:=_leader_objection_reply(leader,limitation_texts)
		if not String(order.get("accepted_meaning","")).is_empty(): objection_text="Accepted meaning: %s\n\n%s" % [String(order.accepted_meaning),objection_text]
		var objection:=_with_civic_state(objection_text,"NEEDS YOUR DECISION")
		order["status"]="awaiting_confirmation"
		order["leader_stance"]="objects"
		order["leader_reply"]=objection
		order["parameters"]={"text":text,"interpretation":result}
		order["policy_ids"]=_policy_ids(prepared)
		GovernmentPeopleSystem.adjust_person_relationship(leader_person_id,-0.006,0.002,0.008)
		if not prior_context.is_empty() and not String(result.get("contextual_prior_order_id","")).is_empty():
			_close_civic_context(prior_context,"continued",String(order.get("id","")))
		_append_leader_reply(settlement_id,leader,objection,order,"objects")
		return order
	var resolved:=execute_pronouncement(text,result,order)
	var resolved_policies:Array[Dictionary]=[]
	var actually_committed:=0
	for resolved_policy_variant in resolved.get("parameters",{}).get("interpretation",{}).get("policies",[]):
		var resolved_policy:Dictionary=resolved_policy_variant
		resolved_policies.append(resolved_policy)
		if (String(resolved_policy.get("action","enact"))=="enact" and bool(resolved_policy.get("applied",false))) or (String(resolved_policy.get("action","enact"))=="repeal" and bool(resolved_policy.get("repealed_active_policy",false))):
			actually_committed+=1
	if committed>0 and actually_committed==0:
		for resolved_policy in resolved_policies:
			var final_blocker:=String(resolved_policy.get("blocker",""))
			if not final_blocker.is_empty() and not limitation_texts.has(final_blocker): limitation_texts.append(final_blocker)
		blocked+=committed
		committed=0
	else:
		committed=actually_committed
	var followup:=CivicImplementationSystem.schedule_order(resolved)
	var stance:="accepted"
	if blocked>0 or deferred>0 or refused>0 or (committed>0 and implementation_total/float(committed)<0.74): stance="qualified"
	if committed==0: stance="unable" if blocked>0 else "refused"
	var reply_state:="UNDERWAY" if committed>0 else ("BLOCKED" if blocked>0 else "REFUSED")
	var reply_text:=_civic_commitment_reply(leader,resolved_policies,stance,committed,blocked+deferred+refused,implementation_total,limitation_texts)
	if committed>0 and not followup.is_empty(): reply_text+=" "+_implementation_report_promise(followup)
	var inherited_from:=String(result.get("context_inherited_from",""))
	if not inherited_from.is_empty(): reply_text="I have the recorded exchange with %s and will answer the directive now.\n\n%s" % [inherited_from,reply_text]
	var accepted_meaning:=String(order.get("accepted_meaning",""))
	if not accepted_meaning.is_empty(): reply_text="Accepted meaning: %s\n\n%s" % [accepted_meaning,reply_text]
	var reply:=_with_civic_state(reply_text,reply_state)
	resolved["leader_stance"]=stance
	resolved["leader_reply"]=reply
	resolved["addressed_to"]=String(leader.get("name","The leader"))
	if insistence and prepared.any(func(policy:Dictionary)->bool: return float(policy.get("leader_willingness",1.0))<0.42):
		GovernmentPeopleSystem.adjust_person_relationship(leader_person_id,-0.015,0.004,0.025)
	elif committed>0:
		GovernmentPeopleSystem.adjust_person_relationship(leader_person_id,0.002,0.004,-0.001)
	var prior_order_id:=String(result.get("contextual_prior_order_id",""))
	if prior_order_id!="":
		for prior_variant in GameState.sovereign_orders:
			var prior_order:Dictionary=prior_variant
			if String(prior_order.get("id",""))==prior_order_id:
				prior_order["status"]="negotiated"
				prior_order["continued_by_order_id"]=String(resolved.get("id",""))
				break
	_append_leader_reply(settlement_id,leader,reply,resolved,stance)
	return resolved


func _append_civic_dialogue(settlement_id:String,record:Dictionary)->void:
	if settlement_id.is_empty(): settlement_id="civilization"
	var history:Array=GameState.civic_dialogues.get(settlement_id,[])
	history.append(record.duplicate(true))
	while history.size()>MAX_CIVIC_DIALOGUE_PER_SETTLEMENT: history.pop_front()
	GameState.civic_dialogues[settlement_id]=history


func _with_civic_state(reply:String,state_label:String)->String:
	return "%s\n\nSTATE · %s" % [reply.strip_edges(),state_label]


func _append_leader_reply(settlement_id:String,leader:Dictionary,text:String,order:Dictionary,stance:String)->void:
	var recorded_text:=text
	var superseded_subject:=String(order.get("supersedes_subject",""))
	if not superseded_subject.is_empty():
		recorded_text="I am setting aside the unresolved discussion of %s and answering this instruction instead.\n\n%s" % [superseded_subject,recorded_text]
		order["leader_reply"]=recorded_text
	_append_civic_dialogue(settlement_id,{
		"day":int(GameState.elapsed_days),"speaker":"leader","speaker_name":String(leader.get("name","Unappointed leader")),
		"title":String(leader.get("title","Local leader")),"text":recorded_text.substr(0,2400),"order_id":String(order.get("id","")),
		"status":stance,"disposition":String(GovernmentPeopleSystem.leader_disposition(leader).get("id","unavailable")),
		"source":String(order.get("parameters",{}).get("interpretation",{}).get("source","deterministic interpreter")),
	})
	_prune_sovereign_orders()


func _rejects_civic_proposal(text:String)->bool:
	var normalized:=text.to_lower().strip_edges()
	if normalized in ["no","no.","no!","cancel","cancel.","never mind","never mind."]: return true
	for prefix in ["no,", "no!", "no please", "no please,", "actually,", "instead,", "i meant", "i mean ", "that is not what", "that's not what", "cancel that", "cancel this", "forget that", "never mind", "stop that", "do not do that", "don't do that"]:
		if normalized.begins_with(prefix): return true
	return false


func _is_civic_insistence(text:String)->bool:
	var normalized:=text.to_lower()
	for phrase in ["do what you can","do your best","proceed","go ahead","make the attempt","carry it out","this is an order","do it anyway","nevertheless","even so","overruled","overrule you","overruling you","you are overruled"]:
		if String(phrase) in normalized: return true
	return false


func _is_civic_confirmation(text:String)->bool:
	var normalized:=text.to_lower().strip_edges()
	for revision_word in [" but "," except "," instead ","change ","revise "," not ","don't ","do not "]:
		if String(revision_word) in " %s " % normalized: return false
	if normalized in ["yes","yes.","correct","correct.","exactly","exactly.","confirm","confirm.","confirmed","confirmed.","do it","do it.","proceed","proceed."]: return true
	if normalized.begins_with("yes ") or normalized.begins_with("yes,") or normalized.begins_with("yes."): return true
	for phrase in ["yes, exactly","i confirm","confirm that exact meaning","confirm this exact meaning","that is the exact order","carry out that exact order"]:
		if String(phrase) in normalized: return true
	return false


func _interpretation_needs_clarification(policies:Array)->bool:
	# These values remain hidden. The player hears a concrete question, never a
	# model score or the catalog's internal strength/duration weights.
	for policy_variant in policies:
		var policy:Dictionary=policy_variant
		if float(policy.get("confidence",1.0))<0.70: return true
		if "conflicting" in String(policy.get("magnitude_source","")): return true
	return false


func _low_confidence_question(leader:Dictionary,policies:Array)->String:
	var policy:Dictionary=policies[0] if not policies.is_empty() else {}
	var action:="end" if String(policy.get("action","enact"))=="repeal" else "put into effect"
	var subject:=GovernmentPolicyCatalog.display_name(String(policy.get("id","this policy")))
	var disposition_id:=String(GovernmentPeopleSystem.leader_disposition(leader).get("id","pragmatic"))
	match disposition_id:
		"sycophantic": return "I believe I see the wisdom of your intent; should I %s %s as the settlement's actual order?" % [action,subject]
		"cantankerous": return "Say it plainly: do you want me to %s %s?" % [action,subject]
		"principled": return "I will not guess at your meaning. Do you intend me to %s %s?" % [action,subject]
		"diplomatic": return "To make sure I carry your intent rather than my own, should I %s %s?" % [action,subject]
		_: return "Do you want me to %s %s as the settlement's order?" % [action,subject]


func _is_grave_directive(text:String,policies:Array)->bool:
	var normalized:=text.to_lower()
	for policy_variant in policies:
		var policy:Dictionary=policy_variant
		if String(policy.get("action","enact"))=="repeal": continue
		var policy_id:=String(policy.get("id",""))
		if policy_id in ["mass_repression","coercive_pronatalism","population_resettlement"]: return true
		if policy_id=="birth_restrictions":
			for term in ["forced","steriliz","without consent","compulsory contraception"]:
				if String(term) in normalized: return true
	return false


func _hold_grave_deliberation(order:Dictionary,leader:Dictionary,settlement_id:String,text:String,result:Dictionary,stage:int,question:String)->Dictionary:
	var inherited_from:=String(result.get("context_inherited_from",""))
	if not inherited_from.is_empty(): question="I have the recorded exchange with %s. %s" % [inherited_from,question]
	var reply:=_with_civic_state(question,"NEEDS YOUR DECISION")
	order["status"]="awaiting_clarification"
	order["leader_stance"]="ethical_deliberation"
	order["leader_reply"]=reply
	order["clarification_kind"]="grave_directive"
	order["ethical_deliberation"]={"stage":stage,"proposed_meaning":_grave_meaning(result.get("policies",[]))}
	order["parameters"]={"text":text,"interpretation":result}
	order["policy_ids"]=_policy_ids(result.get("policies",[]))
	_append_leader_reply(settlement_id,leader,reply,order,"ethical_deliberation")
	return order


func _close_civic_context(prior:Dictionary,status:String,continued_by:String)->void:
	if prior.is_empty(): return
	prior["status"]=status
	prior["continued_by_order_id"]=continued_by


func _grave_opening_question(leader:Dictionary,policies:Array)->String:
	var meaning:=_grave_meaning(policies)
	var alternative:=_grave_less_harmful_alternative(policies)
	var scope_question:=_grave_scope_question(policies)
	var warning:=_grave_warning(policies)
	var disposition_id:=String(GovernmentPeopleSystem.leader_disposition(leader).get("id","pragmatic"))
	var opening:="This demands a clearer answer than an ordinary order."
	match disposition_id:
		"sycophantic": opening="I do not doubt that you see dangers I may not, but I cannot treat this as an ordinary order."
		"cantankerous": opening="No. You will not bury an order like this in vague words."
		"principled": opening="I will not put irreversible harm into motion on an implication."
		"diplomatic": opening="Before this divides the settlement beyond repair, we must state plainly what is being proposed."
	return "%s I understand you to mean: %s. %s%sHave you rejected the alternative of %s?" % [opening,meaning,scope_question,warning,alternative]


func _grave_confirmation_question(leader:Dictionary,policies:Array)->String:
	var meaning:=_grave_meaning(policies)
	var warning:=_grave_warning(policies)
	var disposition_id:=String(GovernmentPeopleSystem.leader_disposition(leader).get("id","pragmatic"))
	var opening:="My final reading is"
	match disposition_id:
		"sycophantic": opening="I believe I now understand your difficult but deliberate judgment as"
		"cantankerous": opening="Then let the record be plain. Your order is"
		"principled": opening="For the record, the meaning I would be asked to accept is"
		"diplomatic": opening="After considering the scope, enforcement, and alternative, my final reading is"
	return "%s: %s. %sConfirm this exact meaning and accept those foreseeable consequences, or revise it?" % [opening,meaning,warning]


func _grave_meaning(policies:Array)->String:
	var meanings:Array[String]=[]
	for policy_variant in policies:
		var policy:Dictionary=policy_variant
		var policy_id:=String(policy.get("id","directive"))
		var action:=String(policy.get("action","enact"))
		if action=="repeal":
			meanings.append("end %s" % GovernmentPolicyCatalog.display_name(policy_id))
			continue
		var parameters:Dictionary=policy.get("directive_parameters",{})
		var target:Dictionary=parameters.get("demographic_target",{})
		var target_label:=String(target.get("label","the affected population"))
		match policy_id:
			"mass_repression":
				var urgency:="immediately " if String(parameters.get("urgency",""))=="immediate" else ""
				meanings.append("%sexecute %s once" % [urgency,target_label] if target.has("exact_count") else "%suse lethal repression against %s" % [urgency,target_label])
			"coercive_pronatalism":
				var meaning:="compel %s into repeated sexual pairings until pregnancy" % target_label if String(parameters.get("coercion_method",""))=="compulsory sexual pairing until pregnancy" else "threaten %s with punishment unless pregnancies occur" % target_label
				var enforcement_method:=String(parameters.get("enforcement_method",""))
				var punishment_target:Dictionary=parameters.get("punishment_target",{})
				if not enforcement_method.is_empty():
					meaning+=", enforcing compliance by %s from %s" % [enforcement_method,String(punishment_target.get("label",target_label))]
				meanings.append(meaning)
			"population_resettlement": meanings.append("forcibly remove and relocate %s" % target_label)
			"birth_restrictions": meanings.append("impose coercive birth restrictions on %s" % target_label)
			_: meanings.append("enact %s" % GovernmentPolicyCatalog.display_name(policy_id))
	return "; ".join(meanings) if not meanings.is_empty() else "carry out the stated grave directive"


func _grave_scope_question(policies:Array)->String:
	# Do not ask the player to repeat scope the parser already captured. Ask only
	# for information that would materially change the deterministic order.
	for policy_variant in policies:
		var policy:Dictionary=policy_variant
		var parameters:Dictionary=policy.get("directive_parameters",{})
		var target:Dictionary=parameters.get("demographic_target",{})
		var target_label:=String(target.get("label",""))
		if target_label.is_empty() or target_label in ["the affected population","the population"]:
			return "Who, exactly, is covered by this order? "
		if String(policy.get("id",""))=="coercive_pronatalism" and String(parameters.get("enforcement_method","")).is_empty():
			return "What punishment do you intend, and who bears it? "
	return "Do you intend that full stated scope, without individual review? "


func _grave_warning(policies:Array)->String:
	var warnings:Array[String]=[]
	for policy_variant in policies:
		match String((policy_variant as Dictionary).get("id","")):
			"mass_repression": warnings.append("People may hide or flee; resistance, deaths, lost skill, and lasting distrust will follow, while our actual reach limits what enforcers can do. ")
			"coercive_pronatalism": warnings.append("This is likely to produce concealment, flight, injury, broken families, and resistance as well as any pregnancies. ")
			"population_resettlement": warnings.append("Displacement will expose people to hunger and weather, divide families, and provoke resistance wherever our reach is weak. ")
			"birth_restrictions": warnings.append("Coercive enforcement will drive concealment and resistance and may injure the people it targets. ")
	return "".join(warnings)


func _grave_less_harmful_alternative(policies:Array)->String:
	for policy_variant in policies:
		match String((policy_variant as Dictionary).get("id","")):
			"mass_repression": return "guarding the immediate threat and reviewing individual cases without a killing order"
			"coercive_pronatalism": return "food, care, and voluntary family support without threats"
			"population_resettlement": return "voluntary relocation with provisions and a right to remain"
			"birth_restrictions": return "voluntary family planning and material support"
	return "a narrower, reversible measure that does not compel bodily harm"


func _leader_willingness(leader:Dictionary,policy_id:String,assessment:Dictionary)->float:
	var personality:Dictionary=leader.get("personality",{})
	var relationship:Dictionary=leader.get("relationships",{}).get("sovereign",{})
	var disposition_id:=String(GovernmentPeopleSystem.leader_disposition(leader).get("id","pragmatic"))
	var coercion:=float(assessment.get("coercion",0.0))
	var empathy:=float(personality.get("empathy",0.5))
	var discipline:=float(personality.get("discipline",0.5))
	var assertiveness:=float(personality.get("assertiveness",0.5))
	var willingness:=0.28+float(relationship.get("trust",0.5))*0.20+float(relationship.get("respect",0.5))*0.16+float(relationship.get("obligation",0.4))*0.10+discipline*0.12+assertiveness*0.06
	willingness-=float(relationship.get("resentment",0.0))*0.24
	willingness-=coercion*empathy*0.34
	if policy_id in ["care_rotation","family_support","public_assembly"]: willingness+=empathy*0.10
	if policy_id in ["mass_repression","population_resettlement","birth_restrictions"]: willingness-=empathy*0.10
	match disposition_id:
		"sycophantic": willingness+=0.18
		"cantankerous": willingness-=0.12
		"principled": willingness-=coercion*0.16
		"diplomatic": willingness+=0.04-coercion*0.07
	return clampf(willingness,0.0,1.0)


func _leader_objection(leader:Dictionary,policy_id:String,assessment:Dictionary)->String:
	var coercion:=float(assessment.get("coercion",0.0))
	var empathy:=float((leader.get("personality",{}) as Dictionary).get("empathy",0.5))
	var reason:="this use of our limited authority is not yet justified"
	if coercion>=0.65 and empathy>=0.55: reason="the coercion and likely harm are greater than I can quietly accept"
	elif float(assessment.get("resistance",0.0))>=0.55: reason="people are likely to resist, and our authority may not survive the attempt"
	var disposition_id:=String(GovernmentPeopleSystem.leader_disposition(leader).get("id","pragmatic"))
	match disposition_id:
		"sycophantic": return "your purpose is surely sound, but even I must warn that %s" % reason
		"cantankerous": return "this is ill-judged: %s" % reason
		"principled": return "I cannot honestly endorse it: %s" % reason
		"diplomatic": return "we need a more workable course because %s" % reason
		_: return reason


func _leader_refuses(_disposition:Dictionary,_willingness:float,_insistence:bool)->bool:
	# Kept for callers loading older conversation records. Current execution
	# decisions are made by the physical and institutional assessment only.
	return false


func _leader_refusal(leader:Dictionary,policy_id:String,assessment:Dictionary,insistence:bool)->String:
	var disposition_id:=String(GovernmentPeopleSystem.leader_disposition(leader).get("id","pragmatic"))
	var coercion:=float(assessment.get("coercion",0.0))
	if disposition_id=="principled" and coercion>=0.45:
		return "I will not use this office to impose that harm"
	if disposition_id=="cantankerous":
		return "I will not own this order%s" % (", however many times it is repeated" if insistence else "")
	if disposition_id=="diplomatic": return "I cannot bring the settlement with us on this course"
	return "I will not commit the settlement to %s" % GovernmentPolicyCatalog.display_name(policy_id)


func _leader_objection_reply(leader:Dictionary,limitations:Array[String])->String:
	var reasons:=_join_limitations(limitations)
	var disposition_id:=String(GovernmentPeopleSystem.leader_disposition(leader).get("id","pragmatic"))
	match disposition_id:
		"sycophantic": return "Your judgment is usually the clearer one. I hesitate only because %s Tell me plainly to proceed and I will attempt it." % reasons
		"cantankerous": return "No—not as stated. %s If you truly mean to overrule me, say so, or put someone else in this office." % reasons
		"principled": return "I will be plain: %s If you insist, I will answer whether I can remain responsible for it." % reasons
		"diplomatic": return "I understand what you want, but %s We can seek a narrower course, or you may tell me to proceed." % reasons
		_: return "I understand the instruction, but %s Tell me to proceed if you accept that risk, or appoint someone else." % reasons



func _civic_future_delay(text:String)->int:
	var pattern:=RegEx.new()
	pattern.compile("(?i)\\bin\\s+(\\d+|one|two|three|four|five|six|seven|eight|nine|ten)\\s+(day|week|month|year)s?\\b")
	var found:=pattern.search(text)
	if found==null: return 0
	var number:=found.get_string(1).to_lower()
	var count:=int(number) if number.is_valid_int() else int({"one":1,"two":2,"three":3,"four":4,"five":5,"six":6,"seven":7,"eight":8,"nine":9,"ten":10}.get(number,0))
	return count*int({"day":1,"week":7,"month":30,"year":365}.get(found.get_string(2).to_lower(),1))

func _civic_unmapped_answer(text:String,result:Dictionary)->String:
	var normalized:=text.to_lower()
	if "bonfire" in normalized or "anniversary" in normalized or "celebrat" in normalized or "festival" in normalized:
		var timing:="in ten years" if int(result.get("future_start_days",0))==3650 else "at the proposed time"
		var occasion:="our 75th anniversary" if "75th" in normalized else "the anniversary" if "anniversary" in normalized else "the celebration"
		return "A public celebration %s would give people something to look forward to. For %s, I would favor a communal bonfire with an open gathering place, supervised fires, and fuel from surplus timber rather than shelter or winter supplies. Planning ahead gives us time to prepare; the size should depend on the stores and conditions nearer the date. The civic calendar cannot yet schedule a future festival, so I can discuss the plan but cannot promise it is booked." % [timing,occasion]
	var summary:=String(result.get("summary","")).strip_edges()
	if summary.is_empty() or summary.begins_with("The council identified"):
		summary="I understand the request: “%s”." % text.strip_edges().substr(0,300)
	return summary+" This action is outside the civic work the settlement can currently execute. That is a limit of our available orders, not a failure to understand your words."

func _leader_clarification_reply(leader:Dictionary,unresolved:String)->String:
	var player_reason:=_player_clarification_reason(unresolved)
	var disposition_id:=String(GovernmentPeopleSystem.leader_disposition(leader).get("id","pragmatic"))
	match disposition_id:
		"sycophantic": return "There may be wisdom in the aim, but I need a concrete instruction before I commit people or stores. %s" % player_reason
		"cantankerous": return "That is not yet an order anyone can execute. %s" % player_reason
		"principled": return "Before I commit the settlement to this, I need one detail. %s" % player_reason
		"diplomatic": return "Help me turn that aim into a concrete instruction for the settlement. %s" % player_reason
		_: return "I need a concrete instruction before I commit people or stores. %s" % player_reason


func _leader_discussion_reply(leader:Dictionary,topic_ids:Array,text:String)->String:
	## Questions should feel like a conversation without asking the API to roleplay
	## or letting an opinion mutate state. The exact feasibility numbers stay hidden.
	if topic_ids.is_empty():
		return "Ask me about a concrete concern—food, water, shelter, work, research, roads, security, families, or an expedition—and I will give you my judgment. Nothing changes until you give an order."
	var topic_id:=String(topic_ids[0])
	if not GovernmentPolicyCatalog.has_policy(topic_id):
		return "I hear the concern, but I cannot judge it without knowing what part of the settlement you mean. Nothing changes until you give an order."
	var definition:=GovernmentPolicyCatalog.definition(topic_id)
	var execution:=execution_modifier_for_advisor(leader,"SettlementLeader",definition.get("skills",[]))
	var assessment:=ConsequenceEngine.directive_assessment(topic_id,float(definition.get("magnitude",0.12)),float(definition.get("days",90.0)),execution,{})
	var display_name:=GovernmentPolicyCatalog.display_name(topic_id)
	var active:=false
	for policy_variant in ConsequenceEngine.active_policies():
		if String((policy_variant as Dictionary).get("id",""))==topic_id:
			active=true
			break
	var judgment:=""
	if active:
		judgment="%s is already in force. I would watch what it actually produces before replacing it with another version." % display_name.capitalize()
	elif not bool(assessment.get("can_apply",false)):
		judgment="I would not promise %s now: %s" % [display_name,String(assessment.get("blocker","we lack the means to carry it out")).trim_suffix(".")+"."]
	else:
		judgment="We could attempt %s. %s %s" % [display_name,_leader_capacity_phrase(leader,float(assessment.get("implementation_rate",0.0))),String(definition.get("ripple","It would redirect real people and stores.")).strip_edges()]
	var disposition_id:=String(GovernmentPeopleSystem.leader_disposition(leader).get("id","pragmatic"))
	var opening:="My judgment:"
	match disposition_id:
		"sycophantic": opening="Your concern is well chosen. My judgment is:"
		"cantankerous": opening="You asked. Here is the plain answer:"
		"principled": opening="I will answer honestly:"
		"diplomatic": opening="As I read the settlement, my judgment is:"
	var second_topic:=""
	if topic_ids.size()>1:
		second_topic=" You also raised %s; ask me separately if you want a clean judgment on that choice." % GovernmentPolicyCatalog.display_name(String(topic_ids[1]))
	return "%s %s%s This is advice only; no order has been given." % [opening,judgment,second_topic]


func _civic_discussion_reference(settlement_id:String,current_order_id:String,prior_context:Dictionary,topic_ids:Array)->Dictionary:
	## A short conversational follow-up should remain attached to the exchange the
	## player can still see. This is deterministic retrieval, not semantic
	## interpretation: it cannot create policies or change the referenced order.
	if not prior_context.is_empty() and _discussion_reference_matches(prior_context,topic_ids):
		return prior_context
	var history:Array=GameState.civic_dialogues.get(settlement_id,[])
	for index in range(history.size()-1,-1,-1):
		if not history[index] is Dictionary: continue
		var record:Dictionary=history[index]
		var order_id:=String(record.get("order_id",""))
		if order_id.is_empty() or order_id==current_order_id: continue
		var candidate:=_civic_order_by_id(order_id)
		if not candidate.is_empty() and _discussion_reference_matches(candidate,topic_ids):
			return candidate
	# Old saves may have orders but no dialogue ledger. The newest local order
	# with an executable subject is still a better answer than generic help.
	for order_variant in GameState.sovereign_orders:
		if not order_variant is Dictionary: continue
		var candidate:Dictionary=order_variant
		if String(candidate.get("id",""))==current_order_id: continue
		if String(candidate.get("settlement_id",""))!=settlement_id: continue
		if _discussion_reference_matches(candidate,topic_ids): return candidate
	return {}


func _civic_order_by_id(order_id:String)->Dictionary:
	for order_variant in GameState.sovereign_orders:
		if order_variant is Dictionary and String((order_variant as Dictionary).get("id",""))==order_id:
			return order_variant
	return {}


func _discussion_reference_matches(order:Dictionary,topic_ids:Array)->bool:
	var policies:Array=order.get("parameters",{}).get("interpretation",{}).get("policies",[])
	if policies.is_empty(): return false
	if topic_ids.is_empty(): return true
	for policy_variant in policies:
		if policy_variant is Dictionary and topic_ids.has(String((policy_variant as Dictionary).get("id",""))): return true
	return false


func _leader_contextual_discussion_reply(leader:Dictionary,reference:Dictionary,topic_ids:Array,text:String)->String:
	var policies:Array[Dictionary]=[]
	for policy_variant in reference.get("parameters",{}).get("interpretation",{}).get("policies",[]):
		if not policy_variant is Dictionary: continue
		var policy:Dictionary=policy_variant
		if topic_ids.is_empty() or topic_ids.has(String(policy.get("id",""))): policies.append(policy)
	if policies.is_empty(): return _leader_discussion_reply(leader,topic_ids,text)
	var labels:Array[String]=[]
	for policy in policies:
		var label:=GovernmentPolicyCatalog.display_name(String(policy.get("id","directive"))).to_lower()
		if not labels.has(label): labels.append(label)
	var subject:=", ".join(labels)
	var normalized:=text.to_lower().strip_edges()
	var followup:Dictionary=reference.get("implementation_followup",{})
	var body:=""
	if _question_is_about_report(normalized):
		match String(followup.get("state","")):
			"pending": body="%s is still underway. I expect to report around %s, unless a physical party remains in the field longer." % [subject.capitalize(),_calendar_label(int(followup.get("due_day",int(GameState.elapsed_days)+7)))]
			"reported": body=String(followup.get("report_text","I have already placed the outcome in the council record."))
			_: body="There is no promised outcome report attached to %s. Its recorded state is %s." % [subject,String(reference.get("status","unresolved")).replace("_"," ")]
	elif _question_is_about_meaning(normalized):
		var accepted_meaning:=String(reference.get("accepted_meaning",""))
		body="The recorded meaning is: %s." % accepted_meaning if not accepted_meaning.is_empty() else "I understood the subject as %s. I did not infer authority beyond the words recorded in that exchange." % subject
	elif _question_is_about_risk(normalized) or _question_is_about_reason(normalized):
		var warning:=_grave_warning(policies).strip_edges()
		var limitations:=_discussion_limitations(policies)
		if not warning.is_empty():
			body=warning
		elif not limitations.is_empty():
			body="My concern is practical: %s" % _join_limitations(limitations)
		else:
			var consequences:=_discussion_consequences(policies)
			body="The likely tradeoff is this: %s" % consequences if not consequences.is_empty() else "I saw no single certain outcome; the result still depends on labor, stores, authority, and how people respond."
	else:
		var disposition_capacity:=_discussion_capacity_phrase(leader,policies)
		body="We were discussing %s. %s" % [subject,disposition_capacity]
	var disposition_id:=String(GovernmentPeopleSystem.leader_disposition(leader).get("id","pragmatic"))
	var opening:="The plain answer is:"
	match disposition_id:
		"sycophantic": opening="Of course. My reading is:"
		"cantankerous": opening="You asked; here is the answer:"
		"principled": opening="I will answer without disguising it:"
		"diplomatic": opening="As I judge the situation:"
	return "%s %s I am answering your question; this does not issue, confirm, or change an order." % [opening,body]


func _question_is_about_report(text:String)->bool:
	for term in ["when","report","progress","status","underway","finished","done","how long","what happened","what came of it","how did it go","did it work","result","outcome","succeed","fail"]:
		if String(term) in text: return true
	return false


func _question_is_about_meaning(text:String)->bool:
	for term in ["what did you understand","what do you understand","what does that mean","what did i order","what are we discussing","which order"]:
		if String(term) in text: return true
	return false


func _question_is_about_risk(text:String)->bool:
	for term in ["risk","consequence","what will happen","what happens","cost us","danger","tradeoff"]:
		if String(term) in text: return true
	return false


func _question_is_about_reason(text:String)->bool:
	for term in ["why","reason","object","refus","hesitat","concern"]:
		if String(term) in text: return true
	return false


func _discussion_limitations(policies:Array[Dictionary])->Array[String]:
	var result:Array[String]=[]
	for policy in policies:
		var assessment:Dictionary=policy.get("conversation_assessment",{})
		var candidates:Array=[]
		if not String(policy.get("blocker","")).is_empty(): candidates.append(String(policy.blocker))
		if not String(assessment.get("blocker","")).is_empty(): candidates.append(String(assessment.blocker))
		candidates.append_array(assessment.get("limitations",[]))
		for candidate_variant in candidates:
			var candidate:=String(candidate_variant).strip_edges()
			if not candidate.is_empty() and not result.has(candidate): result.append(candidate)
	return result


func _discussion_consequences(policies:Array[Dictionary])->String:
	var consequences:Array[String]=[]
	for policy in policies:
		var consequence:=String(policy.get("second_order_consequence",policy.get("ripple",""))).strip_edges().trim_suffix(".")
		if not consequence.is_empty() and not consequences.has(consequence): consequences.append(consequence)
	return "; ".join(consequences)+("." if not consequences.is_empty() else "")


func _discussion_capacity_phrase(leader:Dictionary,policies:Array[Dictionary])->String:
	var total:=0.0
	var assessed:=0
	for policy in policies:
		var rate:=-1.0
		if policy.has("implementation_rate"): rate=float(policy.implementation_rate)
		elif policy.has("conversation_assessment"): rate=float((policy.conversation_assessment as Dictionary).get("implementation_rate",-1.0))
		if rate<0.0: continue
		total+=rate
		assessed+=1
	if assessed<=0: return "I cannot promise an outcome until we test it against present labor, stores, authority, and local resistance."
	return _leader_capacity_phrase(leader,total/float(assessed))


func _player_clarification_reason(internal_reason:String)->String:
	# Parser diagnostics remain in the order record for debugging. A character
	# speaks about the uncertainty itself, never about providers, confidence
	# scores, JSON mappings, catalogs, or the implementation architecture.
	var normalized:=internal_reason.to_lower()
	if "contradictory enact and repeal" in normalized:
		return "I heard you both order and cancel the same measure. Which do you mean?"
	if "at most three" in normalized or "additional policy" in normalized:
		return "That contains too many separate commands for one accountable order. Give me the three most important, or issue them separately."
	if "several policies are active" in normalized:
		return "Several standing orders could be meant. Name the one you want ended."
	if "state the action" in normalized or "discussing a condition" in normalized:
		return "You have raised the matter, but not ordered a change. Tell me what you want done—or ask me for my judgment."
	if "no currently simulated office" in normalized or "concrete action" in normalized or "grounded" in normalized or "mapping" in normalized or "provider" in normalized or "current simulation" in normalized:
		return "Tell me what should change—food, water, care, work, building, research, roads, families, public order, trade, or a physical expedition—and what you want people to do."
	var cleaned:=internal_reason.strip_edges()
	if cleaned.is_empty(): return "Tell me what should change and what you want people to do."
	return cleaned


func _leader_refusal_reply(leader:Dictionary,limitations:Array[String],insistence:bool,repeat_refusals:int=0)->String:
	var reasons:=_join_limitations(limitations)
	var disposition_id:=String(GovernmentPeopleSystem.leader_disposition(leader).get("id","pragmatic"))
	if repeat_refusals>0:
		match disposition_id:
			"cantankerous": return "We have already had this argument. I said no, and repeating it does not make it mine to carry. %s Replace me if you want another answer." % reasons
			"principled": return "You have asked again. My answer has not changed: I cannot do this and still answer for the office. %s You may dismiss or arrest me, but I will not give the order." % reasons
			"diplomatic": return "We are circling the same refusal. I still cannot bring the settlement with us on this course. %s Another leader may judge it differently." % reasons
			_: return "I heard your renewed insistence, and I still refuse. %s You may replace me." % reasons
	match disposition_id:
		"cantankerous": return "I said no. %s Replace me if you want that order carried by this office." % reasons
		"principled": return "I cannot do this and still answer for the office. %s You may dismiss me or have me arrested, but I will not give the order." % reasons
		"diplomatic": return "I cannot make this acceptable to the settlement. %s Another leader may judge it differently." % reasons
		_:
			var insistence_note:=" even after your insistence" if insistence else ""
			return "I will not carry this out%s. %s You may replace me." % [insistence_note,reasons]


func _prior_civic_refusal_count(settlement_id:String,leader_person_id:int,policy_ids:Array[String],current_order_id:String)->int:
	var count:=0
	for order_variant in GameState.sovereign_orders:
		if not order_variant is Dictionary: continue
		var prior:Dictionary=order_variant
		if String(prior.get("id",""))==current_order_id or String(prior.get("settlement_id",""))!=settlement_id: continue
		if int(prior.get("leader_person_id",0))!=leader_person_id or String(prior.get("status",""))!="leader_refused": continue
		var prior_ids:Array=prior.get("policy_ids",[])
		if policy_ids.any(func(policy_id:String)->bool: return prior_ids.has(policy_id)):
			count=maxi(count,1+int(prior.get("repeat_refusal_count",0)))
	return count


func _policy_ids(policies:Array[Dictionary])->Array[String]:
	var ids:Array[String]=[]
	for policy in policies: ids.append(String(policy.get("id","")))
	return ids


func _order_subject(order:Dictionary)->String:
	var labels:Array[String]=[]
	for policy_variant in order.get("parameters",{}).get("interpretation",{}).get("policies",[]):
		if not policy_variant is Dictionary: continue
		var label:=GovernmentPolicyCatalog.display_name(String((policy_variant as Dictionary).get("id","directive"))).to_lower()
		if not label.is_empty() and not labels.has(label): labels.append(label)
	if not labels.is_empty(): return " and ".join(labels)
	var raw:=String(order.get("parameters",{}).get("text","the earlier proposal")).strip_edges()
	return "“%s”" % raw.substr(0,90) if not raw.is_empty() else "the earlier proposal"


func _join_limitations(limitations:Array[String])->String:
	if limitations.is_empty(): return "our reach, labor, and stores impose real limits."
	return "; ".join(limitations).trim_suffix(".")+"."


func _civic_commitment_reply(leader:Dictionary,policies:Array[Dictionary],stance:String,committed:int,uncommitted:int,implementation_total:float,limitations:Array[String])->String:
	var receipts:Array[String]=[]
	for policy in policies:
		if not bool(policy.get("applied",false)): continue
		var receipt:=DecreeStatistics.receipt(policy.get("direct_effects",{}))
		var estimates:=DecreeStatistics.validate(policy.get("directive_parameters",{}).get("statistical_effects",[]))
		for estimate in estimates:
			receipt+=" Estimate before capacity adjustment: %s %+.2f ± %.2f percentage points. %s" % [String(estimate.metric),float(estimate.delta)*100.0,float(estimate.uncertainty)*100.0,String(estimate.reason)]
		if not receipt.is_empty(): receipts.append(receipt)
	if not receipts.is_empty():
		return "Recorded result: %s Further effects on work, food and public order will develop through the simulation; these immediate changes do not prove that the wider aim succeeded." % " ".join(receipts)
	var actions:Array[String]=[]
	for policy in policies:
		if bool(policy.get("_conversation_blocked",false)) or bool(policy.get("_conversation_deferred",false)) or bool(policy.get("_conversation_refused",false)): continue
		actions.append(GovernmentPolicyCatalog.display_name(String(policy.get("id","directive"))))
	if committed<=0:
		var reasons:=_join_limitations(limitations)
		var unable_disposition:=String(GovernmentPeopleSystem.leader_disposition(leader).get("id","pragmatic"))
		match unable_disposition:
			"sycophantic": return "The intention is admirable, but even the finest order cannot supply what we do not have. %s" % reasons
			"cantankerous": return "It cannot be done with what we have. %s" % reasons
			"principled": return "I will not pretend this is possible. %s" % reasons
			"diplomatic": return "We need more hands, stores, or local support before I can make this workable. %s" % reasons
			_: return "I cannot carry this out with the means now available. %s" % reasons
	var capacity_phrase:=_leader_capacity_phrase(leader,implementation_total/float(committed))
	var memory_phrase:=_relevant_civic_memory_phrase(leader,policies)
	var action_text:=", ".join(actions)
	var disposition_id:=String(GovernmentPeopleSystem.leader_disposition(leader).get("id","pragmatic"))
	var opening:="I understand."
	match disposition_id:
		"sycophantic": opening="A wise and far-sighted instruction."
		"cantankerous": opening="I have heard you."
		"principled": opening="I will answer plainly."
		"diplomatic": opening="I believe I can make this workable."
	if stance=="accepted": return "%s I will put %s into effect. %s%s" % [opening,action_text,capacity_phrase,memory_phrase]
	var omission:=" Some parts cannot be attempted." if uncommitted>0 else ""
	return "%s I will do what can be done toward %s. %s%s%s %s" % [opening,action_text,capacity_phrase,memory_phrase,omission,_join_limitations(limitations)]


func _implementation_report_promise(followup:Dictionary)->String:
	var snapshots:Array=followup.get("policies",[])
	if not snapshots.is_empty() and snapshots.all(func(snapshot:Dictionary)->bool: return bool(snapshot.get("directive_parameters",{}).get("one_time",false))):
		return "The counted action is complete. I will review its wider consequences around %s." % _calendar_label(int(followup.get("due_day",GameState.elapsed_days+7)))
	var has_operation:=false
	for snapshot_variant in followup.get("policies",[]):
		if not String((snapshot_variant as Dictionary).get("operation_kind","")).is_empty():
			has_operation=true
			break
	if has_operation:
		return "This is underway. I will report when the commissioned party returns—or when we have reason to believe it will not."
	var due_day:=int(followup.get("due_day",int(GameState.elapsed_days)+7))
	return "This is underway. I will report back around %s with what actually happened." % _calendar_label(due_day)


func _calendar_label(absolute_day:int)->String:
	return "Year %d, Day %d" % [absolute_day/365+1,absolute_day%365+1]


func _leader_capacity_phrase(leader:Dictionary,implementation_rate:float)->String:
	# The simulation retains its exact rate. The officeholder offers a fallible,
	# qualitative forecast instead of exposing the engine's percentage to the player.
	var prediction:=_leader_forecast_score(leader,implementation_rate)
	if prediction>=0.86: return "We appear to have the hands, stores, and authority to carry most of it through."
	if prediction>=0.64: return "We can carry the main work, though thin labor or local resistance may leave gaps."
	if prediction>=0.40: return "We can make a visible start, but the settlement cannot sustain every part at once."
	return "Only a narrow attempt looks possible with the hands, stores, and authority now available."


func _leader_forecast_score(leader:Dictionary,implementation_rate:float)->float:
	## This is only the leader's estimate. It never alters the bounded assessment
	## or the eventual mechanical result. Personality adds a modest, hidden bias:
	## flatterers overpromise, habitual skeptics underpromise, and principled
	## leaders stay closest to the evidence available to them.
	var knowledge:=GovernmentPeopleSystem.skill_value(leader,"Knowledge",45.0)/100.0
	var discipline:=float((leader.get("personality",{}) as Dictionary).get("discipline",0.5))
	var person_id:=int(leader.get("person_id",0))
	var error_span:=lerpf(0.12,0.025,clampf((knowledge+discipline)*0.5,0.0,1.0))
	var disposition_id:=String(GovernmentPeopleSystem.leader_disposition(leader).get("id","pragmatic"))
	var honesty:=clampf(float(leader.get("honesty",0.5)),0.0,1.0)
	var bias:=0.0
	match disposition_id:
		"sycophantic": bias=lerpf(0.12,0.035,honesty)
		"cantankerous": bias=-lerpf(0.09,0.025,honesty)
		"diplomatic": bias=0.015
		"principled": error_span*=0.55
	return clampf(implementation_rate+sin(float(person_id)*17.41+float(GameState.elapsed_days)*0.013)*error_span+bias,0.0,1.0)


func _relevant_civic_memory_phrase(leader:Dictionary,policies:Array[Dictionary])->String:
	var current_policy_ids:=_policy_ids(policies)
	if current_policy_ids.is_empty(): return ""
	var checked:=0
	for memory_variant in leader.get("memories",[]):
		if checked>=12: break
		checked+=1
		var memory:Dictionary=memory_variant
		if String(memory.get("kind",""))!="civic_outcome": continue
		var overlaps:=false
		for prior_id_variant in memory.get("policy_ids",[]):
			if String(prior_id_variant) in current_policy_ids:
				overlaps=true
				break
		if not overlaps: continue
		match String(memory.get("outcome","partial")):
			"success": return " We have carried a similar charge before; that gives me some confidence, though it is no guarantee."
			"failure": return " A similar charge failed before. I will not assume repeating the words will repair the conditions that defeated it."
			_: return " A similar charge produced only part of what was intended before, so I expect uneven results again."
	return ""

func execute_pronouncement(text:String,interpretation:Dictionary,existing_order:Dictionary={})->Dictionary:
	initialize()
	var result:=interpretation.duplicate(true)
	var executed:Array[Dictionary]=[]
	var order:=existing_order if not existing_order.is_empty() else begin_pronouncement(text)
	if String(order.get("status",""))!="interpreting" and not (order.get("parameters",{}).get("interpretation",{}) as Dictionary).is_empty(): return order
	for policy_variant in result.get("policies",[]):
		var policy:Dictionary=policy_variant.duplicate(true)
		var effect_id:=String(policy.get("id",""))
		var action:=String(policy.get("action","enact"))
		var office:=String(policy.get("office","Council"))
		var metadata:={"source_order_id":String(order.id),"source_order_sequence":int(order.get("sequence",0)),"office":office,"interpretation_source":String(result.get("source","interpreter")),"effects":(policy.get("effects",{}) as Dictionary).duplicate(true)}
		if not String(policy.get("basis","")).is_empty(): metadata["interpretation_basis"]=String(policy.basis)
		if policy.has("confidence"): metadata["interpretation_confidence"]=clampf(float(policy.confidence),0.0,1.0)
		for parameter_key in ["action_source","parameter_basis","magnitude_source","duration_source"]:
			if policy.has(parameter_key): metadata[parameter_key]=String(policy[parameter_key])
		# Preserve structured scope for deterministic target/program handling.
		for context_key in ["directive_parameters","directive_target","program_parameters"]:
			if not policy.has(context_key): continue
			var context_value:Variant=policy[context_key]
			metadata[context_key]=context_value.duplicate(true) if context_value is Dictionary or context_value is Array else context_value
		if bool(policy.get("_conversation_blocked",false)) or bool(policy.get("_conversation_deferred",false)) or bool(policy.get("_conversation_refused",false)):
			var preview:Dictionary=policy.get("conversation_assessment",{})
			policy["magnitude"]=float(preview.get("effective_magnitude",0.0))
			policy["execution_factor"]=0.0
			policy["implementation_rate"]=0.0
			policy["implementation_capacity"]=(preview.get("capacity",{}) as Dictionary).duplicate(true)
			policy["implementation_constraints"]=(preview.get("constraints",{}) as Dictionary).duplicate(true)
			policy["directive_costs"]=(preview.get("costs",{}) as Dictionary).duplicate(true)
			policy["compliance"]=float(preview.get("compliance",0.0))
			policy["resistance"]=float(preview.get("resistance",0.0))
			policy["second_order_consequence"]=String(preview.get("second_order_consequence",policy.get("ripple","")))
			policy["applied"]=false
		elif action=="repeal":
			policy["repealed_active_policy"]=ConsequenceEngine.repeal_policy(effect_id,String(policy.get("ripple","Directive rescinded.")),metadata)
			policy["execution_factor"]=1.0
		else:
			var office_execution:=float(policy.get("_office_execution_override",execution_modifier(office,policy.get("skills",[]))))
			var requested:=float(policy.get("magnitude",0.0))
			policy["requested_magnitude"]=requested
			policy["office_execution_factor"]=office_execution
			policy["executor"]=String(policy.get("_executor_override",_executor_name(office)))
			metadata["executor"]=String(policy.executor)
			metadata["office_execution_factor"]=office_execution
			metadata["requested_magnitude"]=requested
			var directive_result:=ConsequenceEngine.apply_directive(effect_id,requested,float(policy.get("days",30.0)),String(policy.get("ripple","Directive enacted.")),metadata,office_execution)
			var assessment:Dictionary=directive_result.get("assessment",{})
			policy["magnitude"]=float(assessment.get("effective_magnitude",0.0))
			policy["execution_factor"]=float(assessment.get("implementation_rate",0.0))
			policy["implementation_rate"]=float(assessment.get("implementation_rate",0.0))
			policy["implementation_capacity"]=(assessment.get("capacity",{}) as Dictionary).duplicate(true)
			policy["implementation_constraints"]=(assessment.get("constraints",{}) as Dictionary).duplicate(true)
			policy["directive_costs"]=(directive_result.get("costs",assessment.get("costs",{})) as Dictionary).duplicate(true)
			policy["compliance"]=float(assessment.get("compliance",0.0))
			policy["resistance"]=float(assessment.get("resistance",0.0))
			policy["direct_effects"]=(directive_result.get("direct_effects",{}) as Dictionary).duplicate(true)
			var operation_result:Dictionary=directive_result.get("operation_result",assessment.get("operation_result",{}))
			if not operation_result.is_empty(): policy["operation_result"]=operation_result.duplicate(true)
			policy["second_order_consequence"]=String(assessment.get("second_order_consequence",policy.get("ripple","")))
			policy["blocker"]=String(directive_result.get("error",""))
			policy["applied"]=bool(directive_result.get("applied",false))
			policy["skipped_as_stale"]=bool(directive_result.get("stale",false))
			if bool(policy.applied) and GameState.leadership_positions.has(office):
				_record_memory(String(GameState.leadership_positions[office].get("name","")),"This institution was charged with implementing %s." % GovernmentPolicyCatalog.display_name(effect_id),0.76,"duty")
		executed.append(policy)
	result["policies"]=executed
	var political_reactions:=_apply_pronouncement_reactions(executed)
	result["political_reactions"]=political_reactions
	order["political_reactions"]=political_reactions.duplicate(true)
	order["parameters"]={"text":text,"interpretation":result}
	order["status"]="interpreted"
	var policy_ids:Array[String]=[]
	for executed_policy in executed: policy_ids.append(String(executed_policy.get("id","")))
	order["policy_ids"]=policy_ids
	refresh_pronouncement_statuses()
	return order

func _apply_pronouncement_reactions(policies:Array[Dictionary])->Array[Dictionary]:
	var changed:Array[Dictionary]=[]
	for policy in policies:
		var action:=String(policy.get("action","enact"))
		if (action=="enact" and bool(policy.get("applied",false))) or (action=="repeal" and bool(policy.get("repealed_active_policy",false))): changed.append(policy)
	if changed.is_empty(): return []
	var reactions:Array[Dictionary]=[]
	for advisor_variant in GameState.advisor_roster:
		var advisor:Dictionary=advisor_variant
		var advisor_name:=String(advisor.get("name",""))
		if advisor_name.is_empty(): continue
		var goals:Array=advisor.get("goals",[])
		var alignment:=0.0
		var aligned_goals:Array[String]=[]
		var opposed_goals:Array[String]=[]
		var duty_offices:Array[String]=[]
		var changed_ids:Array[String]=[]
		for policy in changed:
			var policy_id:=String(policy.get("id",""))
			changed_ids.append(policy_id)
			var direction:=-1.0 if String(policy.get("action","enact"))=="repeal" else 1.0
			var affinity:=GovernmentPolicyCatalog.council_goal_affinity(policy_id)
			for goal_variant in goals:
				var goal:=String(goal_variant)
				var contribution:=0.0
				if (affinity.get("supports",[]) as Array).has(goal): contribution+=direction
				if (affinity.get("strains",[]) as Array).has(goal): contribution-=direction
				alignment+=contribution
				if contribution>0.0 and not aligned_goals.has(goal): aligned_goals.append(goal)
				elif contribution<0.0 and not opposed_goals.has(goal): opposed_goals.append(goal)
			var office:=String(policy.get("office","Council"))
			if GameState.leadership_positions.has(office) and String((GameState.leadership_positions[office] as Dictionary).get("name",""))==advisor_name and not duty_offices.has(office): duty_offices.append(office)
		if is_zero_approx(alignment) and duty_offices.is_empty(): continue
		alignment=clampf(alignment,-3.0,3.0)
		var has_duty:=not duty_offices.is_empty()
		var trust_delta:=clampf(alignment*0.006+(0.003 if has_duty else 0.0),-0.024,0.024)
		var respect_delta:=clampf(alignment*0.003+(0.004 if has_duty else 0.0),-0.012,0.016)
		var resentment_delta:=clampf(-alignment*0.005+(-0.002 if alignment>0.0 else 0.0),-0.012,0.018)
		var relationships:Dictionary=advisor.get("relationships",{})
		var sovereign:Dictionary=relationships.get("sovereign",{"trust":0.5,"respect":0.5,"fear":0.0,"resentment":0.0,"obligation":0.4})
		sovereign["trust"]=clampf(float(sovereign.get("trust",0.5))+trust_delta,0.0,1.0)
		sovereign["respect"]=clampf(float(sovereign.get("respect",0.5))+respect_delta,0.0,1.0)
		sovereign["resentment"]=clampf(float(sovereign.get("resentment",0.0))+resentment_delta,0.0,1.0)
		relationships["sovereign"]=sovereign
		advisor["relationships"]=relationships
		var stance:="supports" if alignment>=0.5 else "objects" if alignment<=-0.5 else "accepts"
		var reason_parts:Array[String]=[]
		if not aligned_goals.is_empty(): reason_parts.append("advances "+_readable_goals(aligned_goals))
		if not opposed_goals.is_empty(): reason_parts.append("strains "+_readable_goals(opposed_goals))
		if has_duty: reason_parts.append("assigns %s responsibility" % ", ".join(duty_offices))
		var summary:="%s %s the directive%s." % [advisor_name,stance," because "+" and ".join(reason_parts) if not reason_parts.is_empty() else ""]
		var reaction:={"advisor":advisor_name,"stance":stance,"alignment":alignment,"policy_ids":changed_ids.duplicate(),"aligned_goals":aligned_goals,"opposed_goals":opposed_goals,"duty_offices":duty_offices,"trust_delta":trust_delta,"respect_delta":respect_delta,"resentment_delta":resentment_delta,"trust_after":float(sovereign.trust),"respect_after":float(sovereign.respect),"resentment_after":float(sovereign.resentment),"summary":summary}
		reactions.append(reaction)
		if not advisor.has("memories"): advisor["memories"]=[]
		_record_memory(advisor_name,summary,clampf(0.48+absf(alignment)*0.10,0.48,0.78),"approval" if alignment>0.0 else "objection" if alignment<0.0 else "duty")
	return reactions

func _readable_goals(goals:Array[String])->String:
	var labels:Array[String]=[]
	for goal in goals: labels.append(String(goal).replace("_"," "))
	return ", ".join(labels)

func refresh_pronouncement_statuses()->void:
	ConsequenceEngine.refresh_policy_lifecycle()
	for order_variant in GameState.sovereign_orders:
		var order:Dictionary=order_variant
		if String(order.get("type",""))!="pronouncement": continue
		# Lifecycle refresh is only for orders which reached implementation. An
		# unfinished exchange can remain open for years of accelerated simulation;
		# changing its status here destroys the subject before the player's reply.
		if String(order.get("status","")) in ["interpreting","cancelled","awaiting_confirmation","awaiting_clarification","leader_refused","leader_unavailable","recorded_unresolved","discussion","proposal","withdrawn","negotiated","deliberated","clarified","continued","no_effect","closed","expired","repealed","superseded","stale"]: continue
		var policies:Array=order.get("parameters",{}).get("interpretation",{}).get("policies",[])
		if policies.is_empty():
			order["status"]="recorded_unresolved"
			continue
		var enacted:=0
		var active:=0
		var stale:=0
		var reasons:Array[String]=[]
		for policy_variant in policies:
			var policy:Dictionary=policy_variant
			if String(policy.get("action","enact"))!="enact": continue
			enacted+=1
			if bool(policy.get("skipped_as_stale",false)):
				stale+=1
				reasons.append("stale")
				continue
			if not bool(policy.get("applied",false)) and not String(policy.get("blocker","")).is_empty():
				reasons.append("blocked")
				continue
			var matching:Dictionary={}
			for modifier_variant in GameState.active_modifiers:
				var modifier:Dictionary=modifier_variant
				if String(modifier.get("source_order_id",""))==String(order.get("id","")) and String(modifier.get("id",""))==String(policy.get("id","")):
					matching=modifier
					break
			if matching.is_empty():
				reasons.append("unknown")
			else:
				policy["observation"]=ConsequenceEngine.policy_observation(matching)
				if GameState.elapsed_days<=float(matching.get("until_day",-INF)):
					active+=1
				else:
					reasons.append(String(matching.get("ended_reason","expired")))
		if enacted==0:
			var changed:=false
			for repeal_variant in policies:
				if bool((repeal_variant as Dictionary).get("repealed_active_policy",false)): changed=true
			order["status"]="executed" if changed else "no_effect"
		elif active==enacted:
			order["status"]="active"
		elif active>0:
			order["status"]="partially_active"
		elif stale==enacted:
			order["status"]="stale"
		elif not reasons.is_empty() and reasons.all(func(reason:String): return reason==reasons[0]) and reasons[0] in ["expired","repealed","superseded","stale","blocked"]:
			order["status"]=reasons[0]
		else:
			order["status"]="closed"

func _executor_name(office:String)->String:
	var executing_office:=GovernmentPeopleSystem.executing_office(office)
	if not GameState.leadership_positions.has(executing_office): return "Vacant %s office" % office
	var name:=String(GameState.leadership_positions[executing_office].get("name",executing_office))
	return name if executing_office==office else "%s acting for %s" % [name,office]

func execution_modifier(office: String, relevant_skills: Array) -> float:
	var executing_office:=GovernmentPeopleSystem.executing_office(office)
	var advisor:Dictionary=GameState.leadership_positions.get(executing_office,{})
	var result:=execution_modifier_for_advisor(advisor,executing_office,relevant_skills)
	# The founding generalist keeps essential work possible before specialist
	# government exists, but cannot match a dedicated office. Once the specialist
	# office unlocks, vacancy is a deliberate and consequential player choice.
	if executing_office!=office: result*=0.84
	return clampf(result,0.28,1.12)


func execution_modifier_for_advisor(advisor:Dictionary,office:String,relevant_skills:Array)->float:
	var governance:Dictionary=ConsequenceEngine.governance_metrics()
	var institutional_capacity:=clampf(float(GameState.society_capacities.get("institutions",0.5)),0.0,1.0)
	var burden:=float(governance.get("administrative_load",0.0))
	if advisor.is_empty(): return clampf(0.34+institutional_capacity*0.32-burden*0.45,0.28,0.64)
	var task_competence:=GovernmentPeopleSystem.competency(advisor,relevant_skills)
	var office_competence:=GovernmentPeopleSystem.office_competency(advisor,office)
	var competence:=task_competence*0.70+office_competence*0.30
	var relationship: Dictionary = advisor.get("relationships",{}).get("sovereign",{})
	var structural_adjustment:=0.0
	var doctrine:=String(advisor.get("doctrine",""))
	if doctrine!="" and DiscoverySystem.society_model!=null:
		structural_adjustment=DiscoverySystem.society_model.doctrine_execution_strength(doctrine)*0.22
	return clampf(0.36+competence*0.46+float(relationship.get("trust",0.5))*0.055+float(relationship.get("respect",0.5))*0.035+institutional_capacity*0.16+structural_adjustment-burden*0.42,0.35,1.12)

func respond_to_council_item(item_id: String, response: String) -> void:
	for item in GameState.council_inbox:
		if item.id == item_id:
			item.status = "answered"
			item.response = response
			for option in item.get("responses",[]):
				if String(option.get("label",""))==response and String(option.get("effect",""))!="":
					var effect_id:=String(option.effect)
					var definition:=GovernmentPolicyCatalog.definition(effect_id)
					var office:=String(definition.get("office",item.get("office","Council")))
					var execution:=execution_modifier(office,definition.get("skills",[]))
					var directive:=ConsequenceEngine.apply_directive(effect_id,float(option.get("magnitude",0.0)),float(option.get("days",30.0)),String(option.get("ripple",response)),{"office":office,"executor":_executor_name(office),"council_item_id":item_id},execution)
					item["directive_result"]=directive.duplicate(true)
			_record_memory(item.advisor, "The Sovereign responded '%s' to this institution's counsel about %s." % [response,item.topic],0.62,"council")
			return

func _record_memory(advisor_name: String, summary: String, importance: float, emotion: String) -> void:
	var advisor := advisor_by_name(advisor_name)
	if advisor.is_empty():
		return
	var person_id:=int(advisor.get("person_id",0))
	if person_id>0 and not GovernmentPeopleSystem.person_snapshot(person_id).is_empty():
		GovernmentPeopleSystem.record_person_memory(person_id,summary,"advisor",importance,{"emotion":emotion})
		return
	advisor.memories.push_front({"summary":summary,"importance":importance,"confidence":1.0,"emotional_weight":importance*0.5,"emotion":emotion,"created_day":int(GameState.elapsed_days),"last_recalled_day":int(GameState.elapsed_days)})
	if advisor.memories.size() > 40:
		advisor.memories.resize(40)
