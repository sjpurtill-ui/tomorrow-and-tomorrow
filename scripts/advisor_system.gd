extends Node

const ADVICE_ACTS := ["report", "recommend", "warn", "object", "request", "correct", "evade", "conceal", "confess", "bargain", "challenge", "remain_silent"]

var initialized := false
var rng := RandomNumberGenerator.new()

func reset_for_new_world()->void:
	initialized=false
	rng=RandomNumberGenerator.new()

func initialize() -> void:
	if initialized:
		return
	rng.seed = GameState.world_seed ^ 0x2e17a5d3
	initialized = true
	_seed_world_truth()

func _seed_world_truth() -> void:
	WorldFacts.set_fact("civilization", "population", 120, "public")
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
	_record_memory(advisor_name, "The Sovereign appointed me as %s." % office, 0.85, "duty")
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
	var advisor:Dictionary=GameState.leadership_positions[office]
	var responses:=_responses_for_domain(domain)
	var text := "Sovereign, %s %s" % [String(event.get("description","Conditions require attention.")),_recommendation_for(advisor,domain)]
	var item := {"id":"consequence_%d_%d" % [int(GameState.elapsed_days),rng.randi()],"advisor":advisor.name,"office":office,"topic":domain,"act":{"type":"warn"},"text":text,"urgency":0.82,"day":int(GameState.elapsed_days),"status":"unread","responses":responses}
	GameState.council_inbox.push_front(item)
	return item

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
			text="Sovereign, the convoy has reached the ordered ground. The people are regrouping and counting losses, stores, and usable shelter."
		"settlement":
			var known_resources:=int(data.get("known_resources",0))
			text="Sovereign, your order is given. The convoy is halting here to establish a permanent home. Stores stand at %.1f days, and %d nearby resource %s known. The builders are organizing the first Hearth Circle from the roles you assigned." % [food_days,known_resources,"site is" if known_resources==1 else "sites are"]
		"halt":
			text="Sovereign, the column has stopped. %s" % String(data.get("reason","Continuing would endanger the people."))
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
	var forceful: bool = "Ruthless" in advisor.traits or "Ambitious" in advisor.traits
	var cautious: bool = "Cautious" in advisor.traits or "Compassionate" in advisor.traits
	if domain=="food": return "I recommend emergency gathering." if forceful else ("I recommend measured rationing." if cautious else "I require a clear rule for provisions.")
	if domain=="health": return "The sick must be placed into a protected care rotation."
	if domain=="ecology": return "We must restrict nearby gathering before the damage becomes permanent." if cautious else "We can accept depletion now if survival demands it."
	if domain=="legitimacy": return "Call the households together and explain the burden you require."
	if domain=="security": return "Expand the watch even though other work will slow."
	return "Your order will decide which cost the people accept."

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
		{"label":"Reassert the order","effect":"expanded_watch","magnitude":0.16,"days":90.0,"ripple":"Compliance is guarded; resentment remains unresolved."}
	]
	if domain=="security": return [
		{"label":"Expand the watch","effect":"expanded_watch","magnitude":0.24,"days":180.0,"ripple":"Security improves while scarce labor remains committed."},
		{"label":"Rely on cohesion","effect":"public_assembly","magnitude":0.14,"days":90.0,"ripple":"Households coordinate voluntarily; direct readiness stays limited."}
	]
	return [{"label":"Acknowledge the report","effect":"","magnitude":0.0,"days":1.0,"ripple":"No standing order is changed."}]

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
	return "obtain a clear sovereign order concerning %s" % topic

func _tone_for(advisor: Dictionary) -> String:
	if "Ruthless" in advisor.traits: return "severe"
	if "Cautious" in advisor.traits: return "guarded"
	if "Charismatic" in advisor.traits: return "confident"
	if "Meticulous" in advisor.traits: return "precise"
	return "formal"

func _render_locally(advisor: Dictionary, act: Dictionary) -> String:
	var templates := {
		"report":"Sovereign, my office reports that %s.",
		"recommend":"Sovereign, I recommend action: %s.",
		"warn":"Sovereign, this cannot be neglected: %s.",
		"object":"Sovereign, I must object. %s.",
		"evade":"Sovereign, the matter remains uncertain. I can only say that %s.",
		"conceal":"Sovereign, there is little of consequence to report, beyond this: %s."
	}
	return templates.get(act.type, "Sovereign, %s.") % act.meaning

func _validate(text: String, act: Dictionary) -> bool:
	if text.length() > 360 or text.strip_edges().is_empty():
		return false
	return act.meaning.trim_suffix(".") in text

func issue_order(order_type: String, target: String, parameters: Dictionary, addressed_office := "") -> Dictionary:
	initialize()
	var order := {"id":"order_%d_%d" % [int(GameState.elapsed_days),rng.randi()], "type":order_type, "target":target, "parameters":parameters.duplicate(true), "office":addressed_office, "issued_day":int(GameState.elapsed_days), "status":"issued"}
	GameState.sovereign_orders.push_front(order)
	if addressed_office != "" and GameState.leadership_positions.has(addressed_office):
		var advisor: Dictionary = GameState.leadership_positions[addressed_office]
		_record_memory(advisor.name, "The Sovereign ordered %s concerning %s." % [order_type,target], 0.78, "order")
	return order

func execution_modifier(office: String, relevant_skills: Array) -> float:
	if not GameState.leadership_positions.has(office):
		return 0.62
	var advisor: Dictionary = GameState.leadership_positions[office]
	var total := 0.0
	for skill in relevant_skills:
		total += float(advisor.skills.get(skill, 35))
	var competence := total / maxi(1,relevant_skills.size()) / 100.0
	var relationship: Dictionary = advisor.relationships.sovereign
	return clampf(0.45 + competence * 0.42 + relationship.trust * 0.08 + relationship.respect * 0.05,0.35,1.12)

func respond_to_council_item(item_id: String, response: String) -> void:
	for item in GameState.council_inbox:
		if item.id == item_id:
			item.status = "answered"
			item.response = response
			for option in item.get("responses",[]):
				if String(option.get("label",""))==response and String(option.get("effect",""))!="":
					ConsequenceEngine.apply_policy(String(option.effect),float(option.get("magnitude",0.0)),float(option.get("days",30.0)),String(option.get("ripple",response)))
			_record_memory(item.advisor, "The Sovereign responded '%s' to my counsel about %s." % [response,item.topic],0.62,"council")
			return

func _record_memory(advisor_name: String, summary: String, importance: float, emotion: String) -> void:
	var advisor := advisor_by_name(advisor_name)
	if advisor.is_empty():
		return
	advisor.memories.push_front({"summary":summary,"importance":importance,"confidence":1.0,"emotional_weight":importance*0.5,"emotion":emotion,"created_day":int(GameState.elapsed_days),"last_recalled_day":int(GameState.elapsed_days)})
	if advisor.memories.size() > 40:
		advisor.memories.resize(40)
