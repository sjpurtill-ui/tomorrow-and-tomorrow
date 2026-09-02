extends Node

const ADVICE_ACTS := ["report", "recommend", "warn", "object", "request", "correct", "evade", "conceal", "confess", "bargain", "challenge", "remain_silent"]

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
	GameState.leadership_positions[office] = advisor
	_record_memory(advisor_name, "The Sovereign commissioned this institution for the %s portfolio." % office, 0.85, "duty")
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
	if GameState.sovereign_orders.size()>100: GameState.sovereign_orders.resize(100)
	if addressed_office != "" and GameState.leadership_positions.has(addressed_office):
		var advisor: Dictionary = GameState.leadership_positions[addressed_office]
		_record_memory(advisor.name, "The Sovereign issued a %s directive concerning %s." % [order_type,target], 0.78, "directive")
	return order

func begin_pronouncement(text:String)->Dictionary:
	var order:=issue_order("pronouncement","civilization",{"text":text.strip_edges().substr(0,500),"interpretation":{}},"")
	order["status"]="interpreting"
	order["submitted_day"]=int(GameState.elapsed_days)
	return order

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
		if action=="repeal":
			policy["repealed_active_policy"]=ConsequenceEngine.repeal_policy(effect_id,String(policy.get("ripple","Directive rescinded.")),metadata)
			policy["execution_factor"]=1.0
		else:
			var office_execution:=execution_modifier(office,policy.get("skills",[]))
			var requested:=float(policy.get("magnitude",0.0))
			policy["requested_magnitude"]=requested
			policy["office_execution_factor"]=office_execution
			policy["executor"]=_executor_name(office)
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
			policy["second_order_consequence"]=String(assessment.get("second_order_consequence",policy.get("ripple","")))
			policy["blocker"]=String(directive_result.get("error",""))
			policy["applied"]=bool(directive_result.get("applied",false))
			policy["skipped_as_stale"]=bool(directive_result.get("stale",false))
			if bool(policy.applied) and GameState.leadership_positions.has(office):
				_record_memory(String(GameState.leadership_positions[office].get("name","")),"This institution was charged with implementing the Sovereign's %s directive." % effect_id.replace("_"," "),0.76,"duty")
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
		if String(order.get("status","")) in ["interpreting","cancelled"]: continue
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
	if not GameState.leadership_positions.has(office): return "Vacant %s office" % office
	return String(GameState.leadership_positions[office].get("name",office))

func execution_modifier(office: String, relevant_skills: Array) -> float:
	var governance:Dictionary=ConsequenceEngine.governance_metrics()
	var institutional_capacity:=clampf(float(GameState.society_capacities.get("institutions",0.5)),0.0,1.0)
	var burden:=float(governance.get("administrative_load",0.0))
	if not GameState.leadership_positions.has(office):
		return clampf(0.38+institutional_capacity*0.36-burden*0.45,0.32,0.72)
	var advisor: Dictionary = GameState.leadership_positions[office]
	var total := 0.0
	for skill in relevant_skills:
		total += float(advisor.skills.get(skill, 35))
	var competence := total / maxi(1,relevant_skills.size()) / 100.0
	var relationship: Dictionary = advisor.get("relationships",{}).get("sovereign",{})
	return clampf(0.38+competence*0.36+float(relationship.get("trust",0.5))*0.08+float(relationship.get("respect",0.5))*0.05+institutional_capacity*0.13-burden*0.45,0.35,1.12)

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
	advisor.memories.push_front({"summary":summary,"importance":importance,"confidence":1.0,"emotional_weight":importance*0.5,"emotion":emotion,"created_day":int(GameState.elapsed_days),"last_recalled_day":int(GameState.elapsed_days)})
	if advisor.memories.size() > 40:
		advisor.memories.resize(40)
