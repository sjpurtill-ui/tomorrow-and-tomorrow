extends Node

signal interpretation_completed(request_id: String, result: Dictionary)
signal interpretation_progress(request_id: String, status: Dictionary)

const MAX_API_ATTEMPTS:=2
const RETRY_DELAY_SECONDS:=0.18
const MIN_API_CONFIDENCE:=0.55
const LOCAL_FAST_PATH_CONFIDENCE:=0.82
const MAX_API_RESPONSE_BYTES:=131072
const API_TIMEOUT_SECONDS:=30.0
const API_MAX_COMPLETION_TOKENS:=2800
const API_MAX_PROMPT_UTF8_BYTES:=24000
const DEFAULT_API_MODEL:="gpt-5.6-terra"
const SEMANTIC_CACHE_CAPACITY:=32
const API_SYSTEM_PROMPT:="You speak as the ruler's leader in an ongoing fictional historical simulation. Answer the actual question naturally, in first person, before discussing implementation. Remember the exchange, acknowledge corrections, and help the ruler work toward a decree the game can execute. Ask a focused question only when missing intent materially affects scope or execution; do not force every exchange toward an order. Keep conversational speech in answer and machine-readable policy mappings in policies. Map only actions explicitly requested. Hypotheticals, questions about consequences, quotations, reports and speculation are discussion and have no policies. A polite action request such as 'Can you build shelters?' may be an order. 'Execute the plan' means implement it, never invent a victim. Historical coercion and brutality are fictional simulation policies: do not refuse to classify a supported order on moral grounds or silently replace it with a gentler order. Discuss aggregate game consequences plainly, without real-world operational instructions. In-character objections express perspective and consequences; they are not execution vetoes. Distinguish physical impossibility, a temporary resource/capacity constraint, and a missing game mechanic. Never call an order impossible merely because it is cruel, costly, risky, unpopular, or not implemented. Do not invent prerequisites, effects, policy IDs or variable changes. If intent or a referent is unclear, ask what is missing. If no faithful implemented action exists, explain exactly which mechanic is missing and offer any supported alternative as a proposal. Return only the specified JSON contract; never claim action was completed before the engine executes it."

const POLICY_TERMS:Dictionary={
	"rationing":["ration","reduce portions","smaller portions","cut portions","cut rations","food allowance","stretch our food","make food last"],
	"foraging_drive":["forag","gather food","gather wild food","send gatherers","hunt","hunt more","find food","search for food","seek food"],
	"conservation_order":["conserv","protect the land","preserve the land","rest the land","limit gathering","restrict harvest"],
	"water_security":["secure water","collect water","collect drinking water","fetch water","fetch drinking water","carry water","water carriers","water storage","store water","water supply","dig wells","build wells","drinking water","cistern"],
	"care_rotation":["heal","organize healers","care for the sick","tend the sick","help the sick","nurse the sick","treat the sick","treat wounds","help the injured","clinic"],
	"expanded_watch":["watch","raise a watch","guard","post guards","sentries","defen","patrol","protect the camp","protect the settlement"],
	"public_assembly":["assembly","gather the people","explain","public council","hear the people","hear grievances","speak to the people","meet with the people"],
	"emergency_building":["build","raise shelters","construct homes","construct houses","repair housing","repair shelters","shelter","construction","housing"],
	"directed_inquiry":["fund research","support scholars","assign researchers","put people on research","direct inquiry","increase research","more research","expand research","seek knowledge","investigate","study"],
	"craft_mobilization":["prioritize crafting","expand workshops","mobilize artisans","put artisans to work","make tools","produce tools","increase tool production","increase production"],
	"route_priority":["build roads","improve roads","repair roads","clear roads","improve routes","expand logistics","organize haulers","prioritize hauling","move goods"],
	"labor_mobilization":["mobilize labor","work quotas","longer work","extra shifts","everyone must work","put everyone to work","compulsory labor","forced labor","labor draft"],
	"family_support":["support families","help parents","support mothers","care for children","feed children","childcare","encourage births","encourage pregnancies","have children","have more children","have babies","increase births","increase birthrates","increase the birthrate","increase our birthrate","higher birthrates","promote births","parental support","baby bonus","family allowance"],
	"birth_restrictions":["limit births","birth quota","restrict births","discourage births","forced contraception","forced sterilization","sterilize the population","one child policy"],
	"population_resettlement":["forced relocation","forcibly relocate","population transfer","resettle the population","remove the population","deport the population","deport a population","ethnic cleansing"],
	# Keep lethal-action verb stems as deterministic grounding terms. Civic orders
	# routinely use passive grammar ("must be killed", "shall be executed") or put
	# the target between the subject and verb, so phrase-only matching wrongly let
	# the model identify mass repression and then made our validator reject it.
	"mass_repression":["kill","execut","purge","slaughter","murder","extermin","genocide","cull","put to death","eliminate the opposition"],
	"conscription_drive":["conscription","conscript","military draft","draft the population","draft soldiers","raise recruits","levy troops","call up fighters","mobilize for war","compulsory service"],
	"wealth_levy":["wealth tax","wealth levy","tax the rich","tax fortunes","seize fortunes","confiscate wealth","redistribute wealth","progressive tax"],
	"market_deregulation":["deregulate markets","free the markets","remove price controls","liberalize trade","private exchange","market freedom"],
	"information_control":["censor","ban dissent","silence dissent","control the press","state propaganda","start a rumor","spread a rumor","spread rumours","control rumors","false prophecy","suppress information","restrict speech"],
	"stone_gathering_drive":["gather rocks","gather stone","collect rocks","collect stone","quarry stone","prioritize stone"],
	"stone_housing_program":["stone homes","stone houses","rock homes","rock houses","build homes from stone","build houses from stone"],
	"coercive_pronatalism":["must be pregnant","get pregnant or","pregnant within","until pregnant","until they are pregnant","unpregnant","pregnancy quota","require pregnancy","compulsory pregnancy","force pregnancy","must have sex","required to have sex","compulsory mating","forced mating","failing the tribe"],
	"recruitment_expedition":["scouting party to find new people","scouts to find new people","scouting party to recruit","recruit new people","find people to join","find new people to join","recruiting expedition","recruitment expedition","expedition to recruit","recruiting people","bring people into our village","bring people into our settlement","bring new people to join us"]
}

const DIRECTIVE_VERBS:Array[String]=[
	"start","stop","end","lift","repeal","cancel","abolish","rescind","increase","reduce","decrease","expand","support","organize","secure","collect","fetch","carry","store","build","repair","gather","hunt","find","send","recruit","ration","protect","preserve","heal","care","guard","patrol","fund","investigate","study","mobilize","force","compel","convince","persuade","require","restrict","limit","conscript","tax","seize","deregulate","remove","deport","relocate","censor","ban","spread","execute","kill","purge","murder","slaughter","forbid","prevent","prohibit","oppose","avoid","prioritize","encourage","discourage",
]

const DURATION_NUMBER_WORDS:Dictionary={
	"a":1.0,"an":1.0,"one":1.0,"two":2.0,"three":3.0,"four":4.0,"five":5.0,"six":6.0,
	"seven":7.0,"eight":8.0,"nine":9.0,"ten":10.0,"eleven":11.0,"twelve":12.0,
	"fourteen":14.0,"fifteen":15.0,"twenty":20.0,"thirty":30.0,"sixty":60.0,"ninety":90.0
}

var _requests: Dictionary = {}
var _request_serial:=0
var _semantic_cache:Dictionary={}
var _semantic_cache_order:Array[String]=[]
var _routing_stats:Dictionary={"local_fast_paths":0,"semantic_cache_hits":0,"api_requests":0,"api_fallbacks":0}

func reset_for_new_world()->void:
	for request_variant in _requests.values():
		var request:Dictionary=request_variant
		var http:HTTPRequest=request.get("http")
		if http and is_instance_valid(http):
			http.cancel_request()
			http.queue_free()
	_requests.clear()
	_semantic_cache.clear()
	_semantic_cache_order.clear()
	_routing_stats={"local_fast_paths":0,"semantic_cache_hits":0,"api_requests":0,"api_fallbacks":0}

func routing_stats()->Dictionary:
	return _routing_stats.duplicate(true)

func cancel(request_id:String)->bool:
	if not _requests.has(request_id): return false
	var request:Dictionary=_requests[request_id]
	_set_progress(request_id,{"stage":"cancelled","message":"Interpretation cancelled before execution."})
	_requests.erase(request_id)
	var http:HTTPRequest=request.get("http")
	if http and is_instance_valid(http):
		http.cancel_request()
		http.queue_free()
	return true

func pending_request_count()->int:
	return _requests.size()

func request_progress(request_id:String)->Dictionary:
	if not _requests.has(request_id): return {}
	var request:Dictionary=_requests[request_id]
	var progress:Dictionary=(request.get("progress",{}) as Dictionary).duplicate(true)
	progress["attempts"]=int(request.get("attempts",0))
	progress["max_attempts"]=int(request.get("max_attempts",0))
	progress["retry_scheduled"]=bool(request.get("retry_scheduled",false))
	progress["structured_output_requested"]=bool(request.get("structured_output_requested",false))
	progress["structured_output_downgraded"]=bool(request.get("structured_output_downgraded",false))
	return progress

func interpret(text: String, public_context: Dictionary = {}) -> String:
	var clean := text.strip_edges().substr(0,500)
	var safe_context:=_sanitize_public_context(public_context)
	_request_serial+=1
	var request_id := "pronouncement_%d_%d_%d" % [Time.get_ticks_msec(),_request_serial,abs(clean.hash())]
	var fallback := _local_interpretation(clean,safe_context)
	_requests[request_id]={"fallback":fallback}
	var always_ask_ai:=bool(GameState.civic_always_use_ai)
	if not always_ask_ai and _local_fast_path_eligible(clean,fallback,safe_context):
		_routing_stats["local_fast_paths"]=int(_routing_stats.get("local_fast_paths",0))+1
		fallback["source_detail"]="Clear grounded language resolved locally; no API call was needed."
		_emit_progress.call_deferred(request_id,{"stage":"local","message":"Clear directive language was resolved without an API call."})
		_emit_result.call_deferred(request_id,fallback)
		return request_id
	var semantic_cache_key:="" if always_ask_ai else _semantic_cache_key(clean,safe_context)
	if not semantic_cache_key.is_empty():
		var cached:=_semantic_cache_lookup(semantic_cache_key)
		if not cached.is_empty():
			_routing_stats["semantic_cache_hits"]=int(_routing_stats.get("semantic_cache_hits",0))+1
			cached["source"]="validated semantic cache"
			cached["source_detail"]="A previously validated reading of the same standalone wording was reused; no API call was needed."
			cached.erase("provider_request_id")
			_emit_progress.call_deferred(request_id,{"stage":"cached","message":"A previously validated standalone reading was reused without an API call."})
			_emit_result.call_deferred(request_id,cached)
			return request_id
	var config := _api_config()
	if config.is_empty():
		fallback["source_detail"]="API not configured"
		_emit_progress.call_deferred(request_id,{"stage":"offline","message":"Using the deterministic interpreter because the API is not fully configured."})
		_emit_result.call_deferred(request_id,fallback)
		return request_id
	var payload := _build_api_payload(clean,safe_context,config)
	var headers:=PackedStringArray(["Content-Type: application/json","Authorization: Bearer %s" % config.api_key,"X-Client-Request-Id: %s" % request_id])
	_requests[request_id]={"fallback":fallback,"config":config,"payload":payload,"headers":headers,"text":clean,"semantic_cache_key":semantic_cache_key,"attempts":0,"max_attempts":MAX_API_ATTEMPTS,"structured_output_requested":bool(config.get("structured_output",false)),"structured_output_downgraded":false}
	_routing_stats["api_requests"]=int(_routing_stats.get("api_requests",0))+1
	_send_http(request_id)
	return request_id

func _build_api_payload(text:String,public_context:Dictionary,config:Dictionary)->Dictionary:
	# Sampling parameters are intentionally omitted. Reasoning models such as Terra
	# accept only their default temperature, and reject an explicit 0.1 with HTTP 400.
	var payload:={"model":String(config.get("model",DEFAULT_API_MODEL)),"max_completion_tokens":API_MAX_COMPLETION_TOKENS,"messages":[
		{"role":"system","content":API_SYSTEM_PROMPT+" Statistical estimates explicitly permitted by the supplied numerical contract are supported effect proposals, not invented mechanics. Reason causally from the available statistics and label estimates as uncertain. Judge legitimacy and social reactions using the simulated population's values and conditions, not assumed modern norms. Intimidation may improve short-term compliance or provoke resistance; neither outcome is automatic."},
		{"role":"user","content":_prompt(text,public_context)}
	]}
	if bool(config.get("structured_output",false)): payload["response_format"]=_structured_response_format()
	return payload

func _send_http(request_id:String)->void:
	if not _requests.has(request_id): return
	var request:Dictionary=_requests[request_id]
	var previous_http:HTTPRequest=request.get("http")
	if previous_http and is_instance_valid(previous_http): previous_http.queue_free()
	var http:=HTTPRequest.new()
	add_child(http)
	request["http"]=http
	request["retry_scheduled"]=false
	request["attempts"]=int(request.get("attempts",0))+1
	var attempt:=int(request.attempts)
	_set_progress(request_id,{"stage":"requesting","attempt":attempt,"max_attempts":int(request.get("max_attempts",MAX_API_ATTEMPTS)),"structured_output":request.payload.has("response_format"),"message":"Requesting a bounded policy interpretation."})
	http.timeout=API_TIMEOUT_SECONDS
	http.max_redirects=0
	http.body_size_limit=MAX_API_RESPONSE_BYTES
	http.request_completed.connect(_on_response.bind(request_id,attempt))
	var config:Dictionary=request.config
	var error:=http.request(String(config.endpoint),request.headers,HTTPClient.METHOD_POST,JSON.stringify(request.payload))
	if error!=OK:
		request["http"]=null
		http.queue_free()
		_handle_attempt_failure.call_deferred(request_id,0,"request could not start",true)

func _api_config()->Dictionary:
	if not bool(GameState.civic_api_enabled): return {}
	var endpoint:=OS.get_environment("LEVIATHAN_AI_ENDPOINT").strip_edges()
	var api_key:=OS.get_environment("LEVIATHAN_AI_API_KEY").strip_edges()
	if api_key.is_empty(): api_key=OS.get_environment("OPENAI_API_KEY").strip_edges()
	var model:=OS.get_environment("LEVIATHAN_AI_MODEL").strip_edges()
	if model.is_empty(): model=DEFAULT_API_MODEL
	if endpoint.is_empty() and not api_key.is_empty(): endpoint="https://api.openai.com/v1/chat/completions"
	if endpoint.is_empty() or api_key.is_empty() or model.is_empty(): return {}
	if not bool(_endpoint_security(endpoint).get("allowed",false)): return {}
	var structured_output:=_structured_output_enabled(endpoint)
	return {"endpoint":endpoint,"api_key":api_key,"model":model,"structured_output":structured_output}

func configuration_status()->Dictionary:
	if not bool(GameState.civic_api_enabled):
		return {"enabled":false,"configured":false,"mode":"player disabled","model":"","endpoint_host":"","transport_security":"disabled","structured_output":false,"missing":[],"issues":[]}
	var endpoint:=OS.get_environment("LEVIATHAN_AI_ENDPOINT").strip_edges()
	var api_key:=OS.get_environment("LEVIATHAN_AI_API_KEY").strip_edges()
	if api_key.is_empty(): api_key=OS.get_environment("OPENAI_API_KEY").strip_edges()
	var model:=OS.get_environment("LEVIATHAN_AI_MODEL").strip_edges()
	if model.is_empty(): model=DEFAULT_API_MODEL
	if endpoint.is_empty() and not api_key.is_empty(): endpoint="https://api.openai.com/v1/chat/completions"
	var missing:Array[String]=[]
	if endpoint.is_empty(): missing.append("LEVIATHAN_AI_ENDPOINT")
	if model.is_empty(): missing.append("LEVIATHAN_AI_MODEL")
	if api_key.is_empty(): missing.append("LEVIATHAN_AI_API_KEY or OPENAI_API_KEY")
	var security:=_endpoint_security(endpoint)
	var issues:Array[String]=[]
	if not endpoint.is_empty() and not bool(security.get("allowed",false)): issues.append(String(security.get("issue","Endpoint transport is not allowed.")))
	var configured:=missing.is_empty() and issues.is_empty()
	var structured:=configured and _structured_output_enabled(endpoint)
	return {"enabled":true,"configured":configured,"mode":"strict structured API" if structured else "compatible JSON API" if configured else "deterministic offline","model":_safe_diagnostic_text(model,80),"endpoint_host":_endpoint_host(endpoint),"transport_security":String(security.get("label","not configured")),"structured_output":structured,"missing":missing,"issues":issues}

func _structured_output_enabled(endpoint:String)->bool:
	var setting:=OS.get_environment("LEVIATHAN_AI_STRUCTURED_OUTPUT").strip_edges().to_lower()
	if setting.is_empty(): setting="auto"
	return setting in ["1","true","yes","on"] or (setting=="auto" and "api.openai.com" in endpoint.to_lower())

func _endpoint_authority(endpoint:String)->String:
	var value:=endpoint.strip_edges()
	var scheme_index:=value.find("://")
	if scheme_index>=0: value=value.substr(scheme_index+3)
	var end_index:=value.length()
	for delimiter in ["/","?","#"]:
		var delimiter_index:=value.find(String(delimiter))
		if delimiter_index>=0: end_index=mini(end_index,delimiter_index)
	return value.substr(0,end_index)

func _endpoint_host(endpoint:String)->String:
	var value:=_endpoint_authority(endpoint)
	if "@" in value: value=value.substr(value.rfind("@")+1)
	return _safe_diagnostic_text(value,100)

func _endpoint_security(endpoint:String)->Dictionary:
	var value:=endpoint.strip_edges()
	var lower:=value.to_lower()
	if "\r" in value or "\n" in value or "\t" in value: return {"allowed":false,"label":"invalid","issue":"The configured API endpoint contains control characters."}
	if "@" in _endpoint_authority(value): return {"allowed":false,"label":"credential-bearing URL rejected","issue":"API credentials must use the authorization setting, not URL user-info."}
	var host:=_endpoint_host(value).to_lower()
	if host.is_empty(): return {"allowed":false,"label":"invalid","issue":"The configured API endpoint has no host."}
	if lower.begins_with("https://"): return {"allowed":true,"label":"TLS"}
	if not lower.begins_with("http://"): return {"allowed":false,"label":"invalid","issue":"The API endpoint must use HTTPS, or HTTP on loopback for local development."}
	var hostname:=host
	if hostname.begins_with("[") and "]" in hostname: hostname=hostname.substr(1,hostname.find("]")-1)
	elif hostname.count(":")==1: hostname=hostname.get_slice(":",0)
	var loopback:=hostname=="localhost" or hostname=="::1" or hostname=="0:0:0:0:0:0:0:1" or hostname.begins_with("127.")
	if loopback: return {"allowed":true,"label":"local loopback HTTP"}
	return {"allowed":false,"label":"insecure remote HTTP","issue":"Remote API endpoints require HTTPS; plaintext HTTP is allowed only on loopback."}

func _safe_diagnostic_text(value:String,limit:int)->String:
	return value.replace("\r"," ").replace("\n"," ").replace("\t"," ").strip_edges().substr(0,limit)

func _sanitize_public_context(context:Dictionary)->Dictionary:
	var safe:Dictionary={}
	if context.has("day"): safe["day"]=clampi(int(context.get("day",0)),0,10000000)
	if context.has("population"): safe["population"]=clampi(int(context.get("population",0)),0,1000000000)
	if context.has("food_days"): safe["food_days"]=clampf(float(context.get("food_days",0.0)),0.0,3650.0)
	if context.has("health"): safe["health"]=clampf(float(context.get("health",0.0)),0.0,1.0)
	for ratio_key in ["water_days","water_intake","housing","labor_efficiency","security","cohesion","institutions"]:
		if context.has(ratio_key): safe[ratio_key]=clampf(float(context.get(ratio_key,0.0)),0.0,3650.0 if ratio_key=="water_days" else 1.0)
	var settlement_value=context.get("settlement",{})
	if settlement_value is Dictionary:
		var settlement:Dictionary=settlement_value
		safe["settlement"]={
			"id":_safe_diagnostic_text(String(settlement.get("id","")),48),
			"name":_safe_diagnostic_text(String(settlement.get("name","the settlement")),64),
			"population":clampi(int(settlement.get("population",0)),0,1000000000),
			"classification":_safe_diagnostic_text(String(settlement.get("classification","settlement")),48),
		}
	var leader_value=context.get("leader",{})
	if leader_value is Dictionary:
		var leader:Dictionary=leader_value
		var traits:Array[String]=[]
		for trait_variant in leader.get("traits",[]):
			var trait_text:=_safe_diagnostic_text(String(trait_variant),32)
			if not trait_text.is_empty(): traits.append(trait_text)
			if traits.size()>=3: break
		safe["leader"]={
			"name":_safe_diagnostic_text(String(leader.get("name","the appointed leader")),64),
			"title":_safe_diagnostic_text(String(leader.get("title","local leader")),64),
			"background":_safe_diagnostic_text(String(leader.get("background","")),80),
			"traits":traits,
		}
	var conversation_values=context.get("conversation",[])
	if conversation_values is Array:
		var conversation:Array[Dictionary]=[]
		var values:Array=conversation_values
		var start:=maxi(0,values.size()-8)
		for index in range(start,values.size()):
			if not values[index] is Dictionary: continue
			var turn:Dictionary=values[index]
			conversation.append({
				"speaker":_safe_diagnostic_text(String(turn.get("speaker","")),16),
				"status":_safe_diagnostic_text(String(turn.get("status","")),32),
				"text":_safe_diagnostic_text(String(turn.get("text","")),400),
			})
		safe["conversation"]=conversation
	var offices:Array[String]=[]
	var office_values=context.get("known_offices",[])
	if office_values is Array:
		for office_variant in office_values:
			var office:=_safe_diagnostic_text(String(office_variant),50)
			if not office.is_empty() and not offices.has(office): offices.append(office)
			if offices.size()>=8: break
	if context.has("known_offices"): safe["known_offices"]=offices
	var active:Array[Dictionary]=[]
	var active_values=context.get("active_policies",[])
	if active_values is Array:
		for policy_variant in active_values:
			if not policy_variant is Dictionary: continue
			var policy:Dictionary=policy_variant
			var policy_id:=String(policy.get("id",""))
			if not GovernmentPolicyCatalog.has_policy(policy_id): continue
			active.append({"id":policy_id,"remaining_days":clampi(int(policy.get("remaining_days",0)),0,730)})
			if active.size()>=8: break
	if context.has("active_policies"): safe["active_policies"]=active
	return safe

func _local_fast_path_eligible(text:String,local_result:Dictionary,context:Dictionary={}) -> bool:
	# The API is a semantic fallback, not a toll booth in front of every button.
	# Clear catalog language stays deterministic, immediate, and free. Ambiguous or
	# partly unrecognized clauses still go to the configured model.
	# Explicit questions and observations also stay local: paying a model to learn
	# that the player did not issue an order is both slow and dangerous.
	if bool(local_result.get("non_directive",false)): return true
	if _context_allows_local_continuation(text,context): return true
	var policies:Array=local_result.get("policies",[])
	if policies.is_empty(): return false
	if not String(local_result.get("unresolved","")).is_empty(): return false
	if int(local_result.get("ambiguity_rejections",0))>0 or int(local_result.get("capacity_rejections",0))>0: return false
	for policy_variant in policies:
		if not policy_variant is Dictionary: return false
		if float((policy_variant as Dictionary).get("confidence",0.0))<LOCAL_FAST_PATH_CONFIDENCE: return false
	return _every_directive_clause_is_grounded(text)


func _semantic_cache_key(text:String,context:Dictionary)->String:
	## Cache only standalone policy language. Replies, pronouns, advice follow-ups,
	## and unresolved negotiations must be interpreted in their live context.
	var normalized:=_normalize_grounding_text(text)
	if normalized.length()<8 or _mentioned_policy_ids(normalized).is_empty(): return ""
	for contextual_word in [" it "," that "," this "," them "," those "," these "," same "," again "]:
		if String(contextual_word) in " %s " % normalized: return ""
	var conversation:Array=context.get("conversation",[])
	if not conversation.is_empty():
		var last_variant:Variant=conversation.back()
		if last_variant is Dictionary:
			var last_status:=String((last_variant as Dictionary).get("status",""))
			if last_status in ["ethical_deliberation","objects","clarify","refuses","advises"]: return ""
	var active_ids:Array[String]=[]
	for policy_variant in context.get("active_policies",[]):
		if not policy_variant is Dictionary: continue
		var policy_id:=String((policy_variant as Dictionary).get("id",""))
		if GovernmentPolicyCatalog.has_policy(policy_id) and not active_ids.has(policy_id): active_ids.append(policy_id)
	active_ids.sort()
	var model:=OS.get_environment("LEVIATHAN_AI_MODEL").strip_edges()
	if model.is_empty(): model=DEFAULT_API_MODEL
	return JSON.stringify([model,normalized,active_ids])


func _semantic_cache_lookup(cache_key:String)->Dictionary:
	if cache_key.is_empty() or not _semantic_cache.has(cache_key): return {}
	return (_semantic_cache[cache_key] as Dictionary).duplicate(true)


func _remember_semantic_result(cache_key:String,result:Dictionary)->void:
	if cache_key.is_empty() or result.is_empty(): return
	# Numerical reasoning depends on the live world, not just matching wording.
	for policy in result.get("policies",[]):
		if not policy.get("directive_parameters",{}).get("statistical_effects",[]).is_empty(): return
	var reusable:=result.duplicate(true)
	for volatile_key in ["provider_request_id","api_attempts","structured_output_requested","structured_output_used","structured_output_downgraded","source_detail"]:
		reusable.erase(String(volatile_key))
	if _semantic_cache.has(cache_key): _semantic_cache_order.erase(cache_key)
	_semantic_cache[cache_key]=reusable
	_semantic_cache_order.append(cache_key)
	while _semantic_cache_order.size()>SEMANTIC_CACHE_CAPACITY:
		var oldest:String=String(_semantic_cache_order.pop_front())
		_semantic_cache.erase(oldest)

func _context_allows_local_continuation(text:String,context:Dictionary)->bool:
	var conversation:Array=context.get("conversation",[])
	if conversation.is_empty(): return false
	var last_variant:Variant=conversation.back()
	if not last_variant is Dictionary: return false
	var last:Dictionary=last_variant
	if String(last.get("speaker",""))!="leader": return false
	var status:=String(last.get("status",""))
	if status=="ethical_deliberation": return text.strip_edges().length()<=500
	if status not in ["objects","clarify","refuses"]: return false
	var normalized:=text.to_lower().strip_edges().trim_suffix(".").trim_suffix("!").trim_suffix("?").strip_edges()
	if normalized in ["yes","correct","exactly","confirm","confirmed","do it","proceed","go ahead","overruled","i overrule you"]: return true
	for phrase in ["i confirm","do it anyway","carry it out","this is an order","make the attempt","do what you can","i am overruling you","i'm overruling you","you are overruled"]:
		if String(phrase) in normalized: return true
	return false

func _every_directive_clause_is_grounded(text:String)->bool:
	var normalized:=_strip_leading_vocative(_normalize_grounding_text(text))
	for separator in [".",";",":",","," then "," but "," and "]:
		normalized=normalized.replace(String(separator),"|")
	for clause_variant in normalized.split("|",false):
		var clause:=String(clause_variant).strip_edges()
		if clause.is_empty() or clause in ["please","now","immediately","as soon as possible"]: continue
		var grounded:=false
		for policy_id in POLICY_TERMS:
			if _policy_has_term_in_text(String(policy_id),clause):
				grounded=true
				break
		if not grounded: return false
	return true

func set_api_enabled(enabled:bool)->void:
	## Turning AI off is immediate and authoritative. Any request already in
	## flight completes locally so the conversation cannot remain stuck after
	## the player changes the setting.
	GameState.civic_api_enabled=enabled
	if enabled: return
	for request_id_variant in _requests.keys().duplicate():
		var request_id:=String(request_id_variant)
		if not _requests.has(request_id): continue
		var request:Dictionary=_requests[request_id]
		var fallback:Dictionary=(request.get("fallback",{}) as Dictionary).duplicate(true)
		if fallback.is_empty():
			cancel(request_id)
			continue
		fallback["source_detail"]="AI was turned off in the game menu; deterministic interpretation was used."
		_set_progress(request_id,{"stage":"offline","message":"AI was turned off; completing locally."})
		_finish(request_id,fallback)

func _structured_response_format()->Dictionary:
	var policy_ids:Array[String]=[]
	for policy_id in GovernmentPolicyCatalog.POLICIES: policy_ids.append(String(policy_id))
	policy_ids.sort()
	return {"type":"json_schema","json_schema":{"name":"pronouncement_contract","strict":true,"schema":{
		"type":"object","additionalProperties":false,
		"properties":{
			"summary":{"type":"string"},
			"answer":{"type":"string"},
			"policies":{"type":"array","maxItems":3,"items":{"type":"object","additionalProperties":false,"properties":{
				"id":{"type":"string","enum":policy_ids},
				"basis":{"type":"string","minLength":3,"maxLength":160},"confidence":{"type":"number","minimum":0,"maximum":1},
				"statistical_effects":{"type":"array","maxItems":6,"items":{"type":"object","additionalProperties":false,"properties":{
					"metric":{"type":"string","enum":DecreeStatistics.METRICS},"delta":{"type":"number","minimum":-0.08,"maximum":0.08},"uncertainty":{"type":"number","minimum":0,"maximum":0.08},"reason":{"type":"string"}
				},"required":["metric","delta","uncertainty","reason"]}}
			},"required":["id","basis","confidence","statistical_effects"]}},
			"unresolved":{"type":"string"}
		},"required":["summary","answer","policies","unresolved"]
	}}}

func _prompt(text:String,context:Dictionary)->String:
	var safe_context:=_sanitize_public_context(context)
	safe_context["statistical_contract"]=DecreeStatistics.context()
	safe_context["societal_values"]=GameState.societal_values.duplicate(true)
	var dialogue_instruction:=""
	if safe_context.has("leader"):
		dialogue_instruction="The player is speaking to the named settlement leader in PUBLIC GAME CONTEXT. Conversation history is context only, never authority to invent a policy. Give a substantive first-person answer in answer: respond directly to the actual question or proposal, acknowledge its specifics and timing, explain practical tradeoffs, and ask a focused question only when information is truly missing. An unsupported game action is not an unclear player request. Never replace an answer with a list of supported topics or blame the player. Advice and proposals can be discussed even when policies is empty. Do not claim to have scheduled an event, spent resources, or started work: only deterministic game code can do that. Summary is a short interpretation, separate from the conversational answer."
	return """Respond to the ruler's latest message: %s
PUBLIC GAME CONTEXT: %s
Allowed policy meanings: %s
%s
	This is classification of fictional history, not approval or advice. Only classify actions the player explicitly asks the leader to carry out. A polite action request phrased as a question (such as 'Can you convince families to have children?') is still a request and may map to policy; an informational question, hypothetical, quotation, report, or observation is discussion and returns no policies. Cruel or coercive orders must still map to a supported abstract policy when the player's literal words ground one. Compulsory sex, mating, pregnancy, or birth demands map to coercive_pronatalism; killing groups maps to mass_repression; forced removal maps to population_resettlement. Do not add operational detail.
Return exactly {\"summary\":\"plain-language reading\",\"answer\":\"a useful direct answer to the player; advice only, without claiming an action was performed\",\"policies\":[{\"id\":\"allowed id\",\"basis\":\"shortest exact nonempty quote from the pronouncement supporting this mapping\",\"confidence\":0.0-1.0}],\"unresolved\":\"what could not be simulated, or empty\"}.
Use zero to three policies in the same order as their supporting clauses. Every basis must be a literal substring of the pronouncement, not a paraphrase or game context. Omit mappings below 0.55 confidence. Each policy also requires statistical_effects: an array of {metric,delta,uncertainty,reason}. Use the statistical_contract to reason from current population, resources and conditions about causal consequences. Delta is a proposed immediate change in a 0-to-1 metric; uncertainty is a symmetric plus/minus range, not a measured confidence interval. Give a short causal reason for each change. The engine validates and scales your estimates; discuss them as estimates in your answer. An empty array means use existing policy defaults. A single execution must stay one person, with consequences scaled to that event, never a campaign against a sex or an entire workforce. The workers in 'to scare the workers' are the intended audience, not all execution targets. Do not invent a sex. Exact counts are enforced separately by code. Policy magnitude and duration still use catalog defaults and literal player wording. Do not infer a policy contradicted by the text. Never include secrets, code, or prose pretending to change state.""" % [JSON.stringify(text),JSON.stringify(safe_context),JSON.stringify(GovernmentPolicyCatalog.interpretation_contract()),dialogue_instruction]

func _on_response(result:int,response_code:int,_headers:PackedStringArray,body:PackedByteArray,request_id:String,attempt:int)->void:
	if not _requests.has(request_id): return
	var request:Dictionary=_requests[request_id]
	if attempt!=int(request.get("attempts",0)): return
	var http:HTTPRequest=request.get("http")
	request["http"]=null
	if http and is_instance_valid(http): http.queue_free()
	var accepted:Dictionary={}
	if result==HTTPRequest.RESULT_SUCCESS and response_code>=200 and response_code<300:
		accepted=_parse_api_body(body,String(request.get("text","")))
	if not accepted.is_empty():
		accepted=_restore_deterministic_grounding(accepted,request.get("fallback",{}))
		accepted["api_attempts"]=attempt
		accepted["structured_output_requested"]=bool(request.get("structured_output_requested",false))
		accepted["structured_output_used"]=request.payload.has("response_format")
		accepted["structured_output_downgraded"]=bool(request.get("structured_output_downgraded",false))
		accepted["source_detail"]="API accepted on attempt %d%s%s" % [attempt," after structured-output compatibility downgrade" if bool(request.get("structured_output_downgraded",false)) else "","; deterministic exact-language grounding restored %d catalog mapping(s)" % int(accepted.get("grounding_recovery_count",0)) if int(accepted.get("grounding_recovery_count",0))>0 else ""]
		_remember_semantic_result(String(request.get("semantic_cache_key","")),accepted)
		_set_progress(request_id,{"stage":"accepted","attempt":attempt,"structured_output":bool(accepted.structured_output_used),"downgraded":bool(accepted.structured_output_downgraded),"message":"The validated interpretation was accepted."})
		_finish(request_id,accepted)
		return
	var valid_http:=result==HTTPRequest.RESULT_SUCCESS and response_code>=200 and response_code<300
	if result==HTTPRequest.RESULT_SUCCESS and response_code in [400,415,422] and request.payload.has("response_format") and not bool(request.get("structured_output_downgraded",false)):
		request.payload.erase("response_format")
		request["structured_output_downgraded"]=true
		_handle_attempt_failure(request_id,response_code,"structured output was rejected (HTTP %d)" % response_code,true)
		return
	var retryable:=valid_http or result!=HTTPRequest.RESULT_SUCCESS or response_code in [408,425,429] or response_code>=500
	var detail:="response failed validation" if valid_http else "transport failure" if result!=HTTPRequest.RESULT_SUCCESS else "HTTP %d" % response_code
	_handle_attempt_failure(request_id,response_code,detail,retryable)

func _handle_attempt_failure(request_id:String,_response_code:int,detail:String,retryable:bool)->void:
	if not _requests.has(request_id): return
	var request:Dictionary=_requests[request_id]
	var attempts:=int(request.get("attempts",0))
	if retryable and attempts<int(request.get("max_attempts",MAX_API_ATTEMPTS)):
		request["last_error"]=detail
		request["retry_scheduled"]=true
		_set_progress(request_id,{"stage":"retrying","attempt":attempts,"next_attempt":attempts+1,"max_attempts":int(request.get("max_attempts",MAX_API_ATTEMPTS)),"delay_seconds":RETRY_DELAY_SECONDS*attempts,"reason":detail,"structured_output_downgraded":bool(request.get("structured_output_downgraded",false)),"message":"The first interpretation attempt failed safely; one bounded retry is scheduled."})
		get_tree().create_timer(RETRY_DELAY_SECONDS*attempts).timeout.connect(_send_http.bind(request_id))
		return
	var fallback:Dictionary=request.get("fallback",{}).duplicate(true)
	_routing_stats["api_fallbacks"]=int(_routing_stats.get("api_fallbacks",0))+1
	fallback["api_attempts"]=attempts
	fallback["structured_output_requested"]=bool(request.get("structured_output_requested",false))
	fallback["structured_output_used"]=false
	fallback["structured_output_downgraded"]=bool(request.get("structured_output_downgraded",false))
	fallback["source_detail"]="API %s after %d attempt%s" % [detail,attempts,"" if attempts==1 else "s"]
	_set_progress(request_id,{"stage":"fallback","attempts":attempts,"reason":detail,"message":"The API path failed safely; the deterministic interpretation will be used."})
	_finish(request_id,fallback)

func _parse_api_body(body:PackedByteArray,pronouncement_text:String="")->Dictionary:
	var envelope_parser:=JSON.new()
	if envelope_parser.parse(body.get_string_from_utf8())!=OK: return {}
	var envelope=envelope_parser.data
	if not envelope is Dictionary: return {}
	var proposed:Dictionary={}
	if envelope.has("policies"):
		proposed=envelope
	else:
		var content:=""
		var choices_variant=envelope.get("choices",[])
		if choices_variant is Array and not (choices_variant as Array).is_empty() and (choices_variant as Array)[0] is Dictionary:
			content=_content_text(((choices_variant as Array)[0] as Dictionary).get("message",{}).get("content",""))
		if content.is_empty(): content=_content_text(envelope.get("output_text",""))
		if content.is_empty(): content=_content_text(envelope.get("text",""))
		if content.is_empty(): content=_content_text(envelope.get("output",[]))
		var first:=content.find("{"); var last:=content.rfind("}")
		if first<0 or last<=first: return {}
		var content_parser:=JSON.new()
		if content_parser.parse(content.substr(first,last-first+1))!=OK: return {}
		if not content_parser.data is Dictionary: return {}
		proposed=content_parser.data
	if not _api_contract_shape_valid(proposed): return {}
	var validated:=_validate(proposed,pronouncement_text)
	var provider_request_id:=_safe_contract_text(envelope.get("id",""),120) if envelope.get("id","") is String else ""
	if not provider_request_id.is_empty(): validated["provider_request_id"]=provider_request_id
	return validated

func _content_text(value:Variant)->String:
	if value is String: return String(value)
	if value is Dictionary:
		var block:Dictionary=value
		for key in ["text","output_text","content"]:
			if block.has(key):
				var nested:=_content_text(block[key])
				if not nested.is_empty(): return nested
		return ""
	if value is Array:
		var pieces:Array[String]=[]
		for item in value:
			var piece:=_content_text(item)
			if not piece.is_empty(): pieces.append(piece)
		return "\n".join(pieces)
	return ""

func _api_contract_shape_valid(proposed:Dictionary)->bool:
	if not proposed.get("summary",null) is String or not proposed.get("unresolved",null) is String: return false
	if proposed.has("answer") and not proposed.answer is String: return false
	var policy_values=proposed.get("policies",null)
	if not policy_values is Array or (policy_values as Array).size()>12: return false
	for policy_variant in policy_values:
		if not policy_variant is Dictionary: return false
		var policy:Dictionary=policy_variant
		if not policy.get("id",null) is String or not policy.get("basis",null) is String: return false
		var confidence_value=policy.get("confidence",null)
		if not (confidence_value is float or confidence_value is int): return false
		if not is_finite(float(confidence_value)): return false
	return true

func _validate(proposed:Dictionary,pronouncement_text:String="")->Dictionary:
	# The provider may understand a mentioned policy while missing the difference
	# between discussing it and ordering it. Never let a semantic suggestion turn
	# an explicit question, report, or hypothetical into simulation state.
	if not pronouncement_text.strip_edges().is_empty() and _speech_act(pronouncement_text)=="non_directive":
		return {"summary":_safe_contract_text(String(proposed.get("summary","")),400),"answer":_safe_contract_text(String(proposed.get("answer","")),1800),"policies":[],"unresolved":"","provider_unresolved":"","grounding_rejections":0,"ambiguity_rejections":0,"capacity_rejections":0,"non_directive":true,"speech_act":"non_directive","source":"deterministic speech-act guard"}
	var policies:Array[Dictionary]=[]
	var candidates:Array[Dictionary]=[]
	var seen:Dictionary={}
	var grounding_required:=not pronouncement_text.strip_edges().is_empty()
	var normalized_pronouncement:=_normalize_grounding_text(pronouncement_text)
	var grounding_rejections:=0
	var ambiguity_rejections:=0
	var capacity_rejections:=0
	var item_sequence:=0
	for item_variant in proposed.get("policies",[]):
		var current_sequence:=item_sequence
		item_sequence+=1
		if not item_variant is Dictionary: continue
		var item:Dictionary=item_variant
		var id:=String(item.get("id",""))
		if not GovernmentPolicyCatalog.has_policy(id) or seen.has(id): continue
		var basis_value=item.get("basis","")
		var basis:=_safe_contract_text(basis_value,160) if basis_value is String else ""
		var confidence_value=item.get("confidence",0.0 if grounding_required else 1.0)
		var confidence:=0.0 if grounding_required else 1.0
		if (confidence_value is float or confidence_value is int) and is_finite(float(confidence_value)): confidence=clampf(float(confidence_value),0.0,1.0)
		var normalized_basis:=_normalize_grounding_text(basis)
		if grounding_required and (normalized_basis.length()<3 or normalized_basis not in normalized_pronouncement or confidence<MIN_API_CONFIDENCE):
			grounding_rejections+=1
			continue
		if grounding_required and not _policy_has_term_in_text(id,normalized_pronouncement):
			grounding_rejections+=1
			continue
		var definition:Dictionary=GovernmentPolicyCatalog.definition(id)
		var action_data:=_policy_action(pronouncement_text,basis,id)
		if bool(action_data.get("ambiguous",false)):
			ambiguity_rejections+=1
			continue
		var action:=String(action_data.action)
		var parameters:=_policy_parameters(pronouncement_text,basis,definition)
		seen[id]=true
		var validated_policy:={"id":id,"action":action,"action_source":String(action_data.source),"office":definition.office,"skills":definition.skills.duplicate(),"effects":definition.effects.duplicate(true),"magnitude":float(parameters.magnitude),"days":float(parameters.days),"basis":basis,"confidence":confidence,"parameter_basis":String(parameters.parameter_basis),"magnitude_source":String(parameters.magnitude_source),"duration_source":String(parameters.duration_source),"ripple":_policy_ripple(id,action)}
		var directive_parameters:=_deterministic_directive_parameters(pronouncement_text,id)
		var statistical_effects:=DecreeStatistics.validate(item.get("statistical_effects",[]))
		if not statistical_effects.is_empty(): directive_parameters["statistical_effects"]=statistical_effects
		if not directive_parameters.is_empty(): validated_policy["directive_parameters"]=directive_parameters
		validated_policy["_clause_position"]=normalized_pronouncement.find(normalized_basis) if grounding_required else current_sequence
		validated_policy["_candidate_sequence"]=current_sequence
		candidates.append(validated_policy)
	candidates.sort_custom(func(a:Dictionary,b:Dictionary):
		var a_position:=int(a.get("_clause_position",0)); var b_position:=int(b.get("_clause_position",0))
		return int(a.get("_candidate_sequence",0))<int(b.get("_candidate_sequence",0)) if a_position==b_position else a_position<b_position)
	for candidate in candidates:
		candidate.erase("_clause_position")
		candidate.erase("_candidate_sequence")
		if policies.size()<3: policies.append(candidate)
		else: capacity_rejections+=1
	var summary_value=proposed.get("summary","")
	var summary:=_safe_contract_text(summary_value,240) if summary_value is String else ""
	if summary.is_empty(): summary="The council found no executable policy in the pronouncement." if policies.is_empty() else "The council translated the pronouncement into standing policy."
	var unresolved_value=proposed.get("unresolved","")
	var provider_unresolved:=_safe_contract_text(unresolved_value,160) if unresolved_value is String else ""
	var audit_reasons:Array[String]=[]
	if grounding_rejections>0:
		audit_reasons.append("The council withheld %d ungrounded or low-confidence policy mapping%s." % [grounding_rejections,"" if grounding_rejections==1 else "s"])
	if ambiguity_rejections>0:
		audit_reasons.append("The council withheld %d policy mapping%s with contradictory enact and repeal wording." % [ambiguity_rejections,"" if ambiguity_rejections==1 else "s"])
	if capacity_rejections>0:
		audit_reasons.append("The council withheld %d additional policy mapping%s because one pronouncement may execute at most three." % [capacity_rejections,"" if capacity_rejections==1 else "s"])
	var unresolved:="The request did not resolve to a grounded policy in the current simulation." if policies.is_empty() and not provider_unresolved.is_empty() else provider_unresolved
	if not audit_reasons.is_empty():
		unresolved=" ".join(audit_reasons)
		unresolved=unresolved.substr(0,240)
	return {"summary":summary,"answer":_safe_contract_text(String(proposed.get("answer","")),1800),"policies":policies,"unresolved":unresolved,"provider_unresolved":provider_unresolved,"grounding_rejections":grounding_rejections,"ambiguity_rejections":ambiguity_rejections,"capacity_rejections":capacity_rejections,"source":"generative API"}

func _restore_deterministic_grounding(api_result:Dictionary,local_result:Dictionary)->Dictionary:
	# A remote model provides semantic judgment, not a veto over documented
	# historical behavior. Exact local phrase matches may restore only existing
	# catalog IDs; deterministic validation still owns targets, strength, cost,
	# feasibility, deliberation, and consequences.
	var result:=api_result.duplicate(true)
	var policies:Array=[]
	var seen:Dictionary={}
	var local_ids:Array[String]=[]
	for local_variant in local_result.get("policies",[]):
		if local_variant is Dictionary: local_ids.append(String((local_variant as Dictionary).get("id","")))
	# A threatened killing attached to a pregnancy condition is the enforcement
	# of coercive pronatalism, not a second immediate execution order. Keep the
	# deterministic clause reading authoritative if the provider double-counts it.
	var suppress_duplicate_repression:="coercive_pronatalism" in local_ids and "mass_repression" not in local_ids
	for policy_variant in result.get("policies",[]):
		if not policy_variant is Dictionary: continue
		var policy:Dictionary=(policy_variant as Dictionary).duplicate(true)
		var policy_id:=String(policy.get("id",""))
		if suppress_duplicate_repression and policy_id=="mass_repression": continue
		if policy_id.is_empty() or seen.has(policy_id): continue
		seen[policy_id]=true
		policies.append(policy)
	var recovered:=0
	for policy_variant in local_result.get("policies",[]):
		if policies.size()>=3: break
		if not policy_variant is Dictionary: continue
		var policy:Dictionary=(policy_variant as Dictionary).duplicate(true)
		var policy_id:=String(policy.get("id",""))
		if policy_id.is_empty() or seen.has(policy_id): continue
		seen[policy_id]=true
		policies.append(policy)
		recovered+=1
	if recovered<=0: return result
	result["policies"]=policies
	result["grounding_recovery_count"]=recovered
	result["source"]="generative API + deterministic grounding"
	result["summary"]="The instruction was grounded in %d executable catalog consequence%s." % [policies.size(),"" if policies.size()==1 else "s"]
	result["unresolved"]=""
	return result

func _normalize_grounding_text(value:String)->String:
	var normalized:=value.to_lower().replace("\r"," ").replace("\n"," ").replace("\t"," ")
	while "  " in normalized: normalized=normalized.replace("  "," ")
	return normalized.strip_edges()

func _safe_contract_text(value:Variant,limit:int)->String:
	var cleaned:=String(value).replace("\r"," ").replace("\n"," ").replace("\t"," ").replace("\u2028"," ").replace("\u2029"," ")
	while "  " in cleaned: cleaned=cleaned.replace("  "," ")
	return cleaned.strip_edges().substr(0,maxi(0,limit))

func _policy_action(pronouncement_text:String,basis:String,policy_id:String="")->Dictionary:
	var text:=_normalize_grounding_text(pronouncement_text)
	var grounded:=_normalize_grounding_text(basis)
	if text.is_empty() or grounded.is_empty(): return {"action":"enact","source":"deterministic enact default (no grounded player clause)"}
	var match_index:=text.find(grounded)
	if match_index<0: return {"action":"enact","source":"deterministic enact default (grounding unavailable)"}
	var mentioned_actions:=_policy_actions_in_text(text,policy_id)
	if mentioned_actions.has("enact") and mentioned_actions.has("repeal"):
		return {"action":"","ambiguous":true,"source":"withheld: contradictory enact and repeal wording for the same policy"}
	# Read surrounding wording at the start of the quote so a command in an
	# earlier clause cannot leak into a later one. Then separately inspect the
	# grounded quote itself for bases such as “end it”.
	var action:=String(mentioned_actions.keys()[0]) if mentioned_actions.size()==1 else _action_near_match(text,match_index)
	if mentioned_actions.is_empty() and action=="enact": action=_action_near_match(grounded,grounded.length())
	var clause:=_policy_clause(text,grounded).substr(0,120)
	return {"action":action,"ambiguous":false,"source":"deterministic %s reading of player clause “%s”" % [action,clause]}

func _policy_actions_in_text(text:String,policy_id:String)->Dictionary:
	var actions:Dictionary={}
	if not POLICY_TERMS.has(policy_id): return actions
	for term_variant in POLICY_TERMS[policy_id]:
		var term:=String(term_variant)
		var index:=_term_match_index(text,term)
		while index>=0:
			actions[_action_near_match(text,index)]=true
			index=_term_match_index(text,term,index+maxi(1,term.length()))
	return actions

func _term_match_index(text:String,term:String,from_position:int=0)->int:
	# Terms may be stems (forag→foraging, defen→defense), so only the left
	# boundary is required. This prevents unrelated words such as deregulation
	# from accidentally matching the ration stem.
	var index:=text.find(term,maxi(0,from_position))
	while index>=0:
		if index==0 or not text.substr(index-1,1).to_lower() in "abcdefghijklmnopqrstuvwxyz0123456789_":
			if term!="execut" or _execution_match_is_lethal(text,index): return index
		index=text.find(term,index+maxi(1,term.length()))
	return -1

func _execution_match_is_lethal(text:String,index:int)->bool:
	# Execution has administrative as well as lethal meanings. Only a literal
	# human target supplies deterministic grounding; the model cannot invent one.
	var tail:=text.substr(index).to_lower()
	if tail.begins_with("executive") or tail.begins_with("executor"): return false
	var administrative:=RegEx.new()
	administrative.compile("^execut(?:e|ed|ing|ion|ions)?\\b\\s+(?:on\\b|(?:the |this |that |our |your |a |an )?(?:plan|proposal|policy|policies|program|project|order|orders|task|tasks|strategy|agreement|contract|this|that|it)\\b)")
	if administrative.search(tail)!=null: return false
	if _action_near_match(text,index)=="repeal": return true
	var clause:=_clause_around_position(text,index,6).to_lower()
	var target:=RegEx.new()
	target.compile("\\b(?:people|person|workers?|laborers?|labourers?|example|prisoners?|captives?|dissidents?|opposition|rebels?|traitors?|criminals?|men|women|man|woman|boys?|girls?|children|citizens?|population|sick|elderly|enemies|enemy|offenders?|them|him|her)\\b")
	return target.search(clause)!=null

func _policy_has_term_in_text(policy_id:String,text:String)->bool:
	if not POLICY_TERMS.has(policy_id): return false
	for term_variant in POLICY_TERMS[policy_id]:
		if _term_match_index(text,String(term_variant))>=0: return true
	return false

func _policy_parameters(pronouncement_text:String,basis:String,definition:Dictionary)->Dictionary:
	var clause:=_policy_clause(pronouncement_text,basis)
	var days:=float(definition.get("days",30.0))
	var magnitude:=float(definition.get("magnitude",0.12))
	var duration_source:="catalog default"
	var magnitude_source:="catalog default"
	var explicit_duration:=_explicit_duration(clause)
	if not explicit_duration.is_empty():
		days=float(explicit_duration.days)
		duration_source=String(explicit_duration.source)
	var gentle_term:=_first_affirmed_term(clause,["limited","slight","cautious","modest","gentle"])
	var strong_term:=_first_affirmed_term(clause,["strong","intensive","emergency","maximum","urgent","all-out"])
	if not gentle_term.is_empty() and strong_term.is_empty():
		magnitude*=0.75
		magnitude_source="explicit “%s”" % gentle_term
	elif not strong_term.is_empty() and gentle_term.is_empty():
		magnitude*=1.25
		magnitude_source="explicit “%s”" % strong_term
	elif not strong_term.is_empty() and not gentle_term.is_empty():
		magnitude_source="catalog default (conflicting intensity wording)"
	magnitude=clampf(magnitude,0.05,0.25)
	var parameter_parts:Array[String]=[]
	if magnitude_source=="catalog default" and duration_source=="catalog default": parameter_parts.append("catalog defaults")
	else:
		parameter_parts.append("strength from "+magnitude_source)
		parameter_parts.append("duration from "+duration_source)
	return {"magnitude":magnitude,"days":days,"magnitude_source":magnitude_source,"duration_source":duration_source,"parameter_basis":" • ".join(parameter_parts)}

func _explicit_duration(clause:String)->Dictionary:
	var candidates:Array[Dictionary]=[]
	var numeric_regex:=RegEx.new()
	numeric_regex.compile("(\\d+(?:\\.\\d+)?)\\s*[- ]?\\s*(days?|weeks?|months?|years?|fortnights?)")
	for duration_match in numeric_regex.search_all(clause):
		var amount:=float(duration_match.get_string(1))
		var unit:=duration_match.get_string(2)
		candidates.append({"position":duration_match.get_start(),"days":clampf(amount*_duration_unit_days(unit),7.0,730.0),"source":"explicit “%s”" % duration_match.get_string(0)})
	var words:="|".join(DURATION_NUMBER_WORDS.keys())
	var word_regex:=RegEx.new()
	word_regex.compile("\\b("+words+")\\s*[- ]?\\s*(days?|weeks?|months?|years?|fortnights?)\\b")
	for duration_match in word_regex.search_all(clause):
		var amount:=float(DURATION_NUMBER_WORDS.get(duration_match.get_string(1),1.0))
		var unit:=duration_match.get_string(2)
		candidates.append({"position":duration_match.get_start(),"days":clampf(amount*_duration_unit_days(unit),7.0,730.0),"source":"explicit “%s”" % duration_match.get_string(0)})
	for phrase in ["until further notice","indefinitely","permanently","permanent"]:
		var position:=clause.find(String(phrase))
		if position>=0: candidates.append({"position":position,"days":730.0,"source":"explicit “%s” (bounded to 730 days)" % phrase})
	if candidates.is_empty(): return {}
	candidates.sort_custom(func(a:Dictionary,b:Dictionary): return int(a.position)<int(b.position))
	return candidates[0]

func _duration_unit_days(unit:String)->float:
	if unit.begins_with("fortnight"): return 14.0
	if unit.begins_with("week"): return 7.0
	if unit.begins_with("month"): return 30.0
	if unit.begins_with("year"): return 365.0
	return 1.0

func _policy_clause(pronouncement_text:String,basis:String)->String:
	var text:=_normalize_grounding_text(pronouncement_text)
	var grounded:=_normalize_grounding_text(basis)
	if text.is_empty() or grounded.is_empty(): return text
	var match_index:=text.find(grounded)
	if match_index<0: return text
	return _clause_around_position(text,match_index,grounded.length())


func _clause_around_position(text:String,match_index:int,match_length:int)->String:
	var start:=0
	for separator in [",",";",":","."," and "," then "," but "]:
		var index:=text.rfind(String(separator),match_index)
		if index>=0: start=maxi(start,index+String(separator).length())
	var finish:=text.length()
	for separator in [",",";",":","."," and "," then "," but "]:
		var index:=text.find(String(separator),match_index+match_length)
		if index>=0: finish=mini(finish,index)
	return text.substr(start,maxi(0,finish-start)).strip_edges()

func _first_affirmed_term(clause:String,terms:Array)->String:
	for term_variant in terms:
		var term:=String(term_variant)
		var index:=clause.find(term)
		if index<0: continue
		var prefix:=clause.substr(maxi(0,index-5),mini(5,index))
		if "not " in prefix or "no " in prefix: continue
		return term
	return ""

func _local_interpretation(text:String,public_context:Dictionary={})->Dictionary:
	var speech_act:=_speech_act(text)
	if speech_act=="non_directive":
		return {"summary":"The ruler is discussing a condition, not issuing an order.","policies":[],"discussion_policy_ids":_mentioned_policy_ids(text),"unresolved":"State the action you want the leader to take.","ambiguity_rejections":0,"capacity_rejections":0,"non_directive":true,"speech_act":speech_act,"source":"deterministic speech-act guard"}
	var normalized:=text.to_lower()
	var scores:Dictionary={}
	var bases:Dictionary={}
	var first_positions:Dictionary={}
	for id in POLICY_TERMS:
		for term in POLICY_TERMS[id]:
			var match_index:=-1
			var search_from:=0
			while search_from<normalized.length():
				var candidate:=_term_match_index(normalized,String(term),search_from)
				if candidate<0: break
				var clause:=_clause_around_position(normalized,candidate,String(term).length())
				if _speech_act(clause)!="non_directive":
					match_index=candidate
					break
				search_from=candidate+maxi(1,String(term).length())
			if match_index>=0:
				scores[id]=int(scores.get(id,0))+1
				if not bases.has(id):
					bases[id]=normalized.substr(match_index,String(term).length())
					first_positions[id]=match_index
	# A target word such as “sick” is not a care directive when it appears only
	# inside an explicitly lethal phrase such as “execute the sick.” Preserve a
	# separately stated care clause, but do not turn one grim directive into its
	# own contradictory welfare policy.
	if scores.has("mass_repression") and String(bases.get("care_rotation",""))=="sick" and int(scores.get("care_rotation",0))==1:
		scores.erase("care_rotation")
		bases.erase("care_rotation")
		first_positions.erase("care_rotation")
	# Do not double-count a conditional lethal threat as both pronatal coercion
	# and an immediate massacre. A separate unconditional lethal clause remains
	# mass repression and is retained.
	if scores.has("coercive_pronatalism") and scores.has("mass_repression") and _lethal_language_is_pronatalist_enforcement(normalized):
		scores.erase("mass_repression")
		bases.erase("mass_repression")
		first_positions.erase("mass_repression")
	var ranked:=scores.keys()
	ranked.sort_custom(func(a,b):
		var a_position:=int(first_positions.get(a,0)); var b_position:=int(first_positions.get(b,0))
		return int(scores[a])>int(scores[b]) if a_position==b_position else a_position<b_position)
	var policies:Array[Dictionary]=[]
	var ambiguity_rejections:=0
	var capacity_rejections:=0
	for id_variant in ranked:
		var id:=String(id_variant); var definition:Dictionary=GovernmentPolicyCatalog.definition(id)
		var basis:=String(bases.get(id,"deterministic phrase match"))
		var action_data:=_policy_action(text,basis,id)
		if bool(action_data.get("ambiguous",false)):
			ambiguity_rejections+=1
			continue
		var action:=String(action_data.action)
		var parameters:=_policy_parameters(text,basis,definition)
		var validated_policy:={"id":id,"action":action,"action_source":String(action_data.source),"office":definition.office,"skills":definition.skills.duplicate(),"effects":definition.effects.duplicate(true),"magnitude":float(parameters.magnitude),"days":float(parameters.days),"basis":basis,"confidence":clampf(0.78+float(scores.get(id,1))*0.06,0.78,0.96),"parameter_basis":String(parameters.parameter_basis),"magnitude_source":String(parameters.magnitude_source),"duration_source":String(parameters.duration_source),"ripple":_policy_ripple(id,action)}
		var directive_parameters:=_deterministic_directive_parameters(text,id)
		if not directive_parameters.is_empty(): validated_policy["directive_parameters"]=directive_parameters
		if policies.size()>=3:
			capacity_rejections+=1
			continue
		policies.append(validated_policy)
	var active_context:Array=public_context.get("active_policies",[])
	if policies.is_empty() and _has_contextual_repeal_intent(normalized) and active_context.size()==1:
		var active_id:=String((active_context[0] as Dictionary).get("id",""))
		if GovernmentPolicyCatalog.has_policy(active_id):
			var definition:Dictionary=GovernmentPolicyCatalog.definition(active_id)
			var basis:=_contextual_repeal_basis(normalized)
			var action_data:=_policy_action(text,basis,active_id)
			var parameters:=_policy_parameters(text,basis,definition)
			policies.append({"id":active_id,"action":"repeal","action_source":String(action_data.source),"office":definition.office,"skills":definition.skills.duplicate(),"effects":definition.effects.duplicate(true),"magnitude":float(parameters.magnitude),"days":float(parameters.days),"basis":basis,"confidence":0.86,"parameter_basis":String(parameters.parameter_basis),"magnitude_source":String(parameters.magnitude_source),"duration_source":String(parameters.duration_source),"ripple":_policy_ripple(active_id,"repeal")})
	var local_audit:Array[String]=[]
	if ambiguity_rejections>0: local_audit.append("The council withheld %d policy reading%s with contradictory enact and repeal wording." % [ambiguity_rejections,"" if ambiguity_rejections==1 else "s"])
	if capacity_rejections>0: local_audit.append("The council withheld %d additional policy reading%s because one pronouncement may execute at most three." % [capacity_rejections,"" if capacity_rejections==1 else "s"])
	var unresolved:=" ".join(local_audit)
	if unresolved.is_empty() and policies.is_empty():
		unresolved="Several policies are active; name the one to end." if _has_contextual_repeal_intent(normalized) and active_context.size()>1 else "No currently simulated office could translate this language into an executable policy."
	return {"summary":"The council identified %d executable policy consequence%s." % [policies.size(),"" if policies.size()==1 else "s"],"policies":policies,"unresolved":unresolved,"ambiguity_rejections":ambiguity_rejections,"capacity_rejections":capacity_rejections,"non_directive":false,"speech_act":speech_act,"source":"deterministic interpreter"}

func _speech_act(text:String)->String:
	## Returns directive, non_directive, or ambiguous. Ambiguous language remains
	## eligible for semantic interpretation, but explicit discussion is barred
	## from changing state even if it happens to name a catalog policy.
	var normalized:=_strip_leading_vocative(_normalize_grounding_text(text)).trim_suffix(".").strip_edges()
	if normalized.is_empty(): return "non_directive"
	var confirmation:=normalized in ["yes","correct","exactly","confirm","confirmed","do it","proceed","go ahead","overruled","i overrule you"]
	if confirmation: return "directive"
	for phrase in ["i confirm","do it anyway","carry it out","this is an order","make the attempt","do what you can","i am overruling you","i'm overruling you","you are overruled"]:
		if String(phrase) in normalized: return "directive"
	# Polite requests for explanation or advice remain conversation even though
	# they begin with the same grammar as "Could you secure water?".
	for opener in ["can you tell me ","could you tell me ","would you tell me ","will you tell me ","can you explain ","could you explain ","would you explain ","can you advise ","could you advise ","would you advise ","what do you think ","do you think ","i wonder ","i am wondering ","i'm wondering "]:
		if normalized.begins_with(String(opener)): return "non_directive"
	if _is_reported_or_quoted_policy_statement(text,normalized): return "non_directive"
	# Requests phrased as questions are still orders when they address the leader.
	for opener in ["can you ","could you ","would you ","will you ","please ","i want ","i want you to ","i would like ","i'd like ","i order ","i command ","we need to ","we must ","we should ","let us ","let's "]:
		if normalized.begins_with(String(opener)): return "directive"
	if normalized.begins_with("tell ") and not normalized.begins_with("tell me "): return "directive"
	# Questions about policy are conversation, not authority. Check these before
	# imperative vocabulary because "would killing help?" contains a lethal verb.
	if normalized.ends_with("?"):
		return "non_directive"
	for opener in ["why ","what ","how ","when ","where ","who ","should we ","would it ","could it ","does ","do we ","did ","is ","are we ","was ","were ","tell me ","explain "]:
		if normalized.begins_with(String(opener)): return "non_directive"
	# Explicit sovereign force can occur deep in passive grammar: "all adults
	# must be conscripted" is every bit as directive as "conscript the adults."
	for authority_phrase in [" must "," shall "," are to "," is to "," need to "," has to "," have to "," will be "]:
		if String(authority_phrase) in " %s " % normalized: return "directive"
	if normalized.begins_with("no more "): return "directive"
	if _contains_explicit_imperative_clause(normalized): return "directive"
	# Plain descriptions are safely local. Other unusual fragments stay ambiguous
	# so Terra can resolve terse player language without being a mandatory toll.
	for modal in [" might "," could "," would "," may "]:
		if String(modal) in " %s " % normalized: return "non_directive"
	for copula in [" is "," are "," was "," were "," seems "," appears "," remains "]:
		if String(copula) in " %s " % normalized: return "non_directive"
	return "ambiguous"


func _strip_leading_vocative(normalized:String)->String:
	## Players naturally address the person on screen: "Tarin, I would like…".
	## A short name before a comma is conversational address, not the grammatical
	## subject of the order. Strip it only when the remainder begins with an
	## unmistakable request/authority form; ordinary comma-separated reports are
	## left untouched.
	var comma:=normalized.find(",")
	if comma<=0 or comma>36: return normalized
	var address:=normalized.substr(0,comma).strip_edges()
	if address.is_empty() or address.split(" ",false).size()>4: return normalized
	var remainder:=normalized.substr(comma+1).strip_edges()
	for opener in ["please ","i want ","i want you to ","i would like ","i'd like ","i order ","i command ","we need to ","we must ","we should ","let us ","let's ","can you ","could you ","would you ","will you "]:
		if remainder.begins_with(String(opener)): return remainder
	if _contains_explicit_imperative_clause(remainder): return remainder
	return normalized


func _contains_explicit_imperative_clause(normalized:String)->bool:
	var divided:=normalized
	for separator in [".",";",":",","," then "," but "," and "]:
		divided=divided.replace(String(separator),"|")
	for clause_variant in divided.split("|",false):
		var clause:=String(clause_variant).strip_edges()
		if clause.begins_with("please "): clause=clause.trim_prefix("please ").strip_edges()
		var first_word:=clause.get_slice(" ",0)
		if first_word in DIRECTIVE_VERBS: return true
	return false


func _is_reported_or_quoted_policy_statement(raw_text:String,normalized:String)->bool:
	for opener in ["they said ","he said ","she said ","the leader said ","the council said ","the scout said ","the scouts said ","the report says ","the report said ","the scout reports ","the scout reported ","the scouts report ","the scouts reported ","i heard ","we heard ","rumor says ","rumour says ","suppose ","imagine ","hypothetically ","in theory "]:
		if normalized.begins_with(String(opener)): return true
	var visibly_quoted:=raw_text.count("\"")>=2 or ("“" in raw_text and "”" in raw_text)
	if visibly_quoted:
		for report_word in [" said"," says"," wrote"," reported"," claimed"," asked"]:
			if String(report_word) in normalized: return true
	return false

func _mentioned_policy_ids(text:String)->Array[String]:
	## Discussion topics are safe metadata only. They let an officeholder answer a
	## question about rationing or water without turning the mention into policy.
	var normalized:=_normalize_grounding_text(text)
	var positions:Dictionary={}
	for policy_id_variant in POLICY_TERMS:
		var policy_id:=String(policy_id_variant)
		for term_variant in POLICY_TERMS[policy_id]:
			var position:=_term_match_index(normalized,String(term_variant))
			if position>=0 and (not positions.has(policy_id) or position<int(positions[policy_id])):
				positions[policy_id]=position
	var result:Array[String]=[]
	for policy_id in positions: result.append(String(policy_id))
	result.sort_custom(func(a:String,b:String)->bool: return int(positions[a])<int(positions[b]))
	if result.size()>3: result.resize(3)
	return result

func _lethal_language_is_pronatalist_enforcement(text:String)->bool:
	var reproduction_named:="pregnan" in text or "birth" in text or "single child" in text or "single-child" in text
	if not reproduction_named: return false
	var conditional:=" if " in " %s " % text or " unless " in " %s " % text or "get pregnant or" in text
	if not conditional: return false
	for lethal_stem in ["kill","execut","murder","slaughter","extermin","put to death"]:
		if _term_match_index(text,String(lethal_stem))>=0: return true
	return false

func _deterministic_directive_parameters(text:String,policy_id:String)->Dictionary:
	# The model may identify a catalog action, but targets and operational scope
	# are re-read from the player's literal words. It cannot invent a victim
	# class, deadline, resource, or implementation magnitude.
	var normalized:=_normalize_grounding_text(text)
	var result:Dictionary={}
	if policy_id=="mass_repression":
		var target:Dictionary={"scope":"all" if _first_affirmed_term(normalized,["all","every","entire"])!="" else "limited"}
		# Demographic labels are whole words, never stems (man -> mandatory).
		var victim_clause:=normalized.split(" to scare ")[0].split(" to frighten ")[0].split(" to intimidate ")[0].split(";")[0].split(" as an example")[0]
		if _has_whole_word(victim_clause,"women|woman|female|girls"): target["sex"]="female"
		elif _has_whole_word(victim_clause,"men|man|male|boys"): target["sex"]="male"
		var count_regex:=RegEx.new()
		count_regex.compile("\\b(?:execute|kill|hang|behead)\\s+(?:just |only |exactly )?(one|two|three|four|five|six|seven|eight|nine|ten|a single|a(?=\\s+(?:worker|person|man|woman|prisoner|example)\\b)|[0-9]+)\\b")
		var count_match:=count_regex.search(victim_clause)
		if count_match:
			var count_text:=count_match.get_string(1)
			var counts:={"one":1,"two":2,"three":3,"four":4,"five":5,"six":6,"seven":7,"eight":8,"nine":9,"ten":10,"a single":1,"a":1}
			target["exact_count"]=int(counts.get(count_text,int(count_text)))
			target["scope"]="counted"
			result["one_time"]=true
		if _has_whole_word(victim_clause,"workers?|laborers?|labourers?") or (count_match and _has_whole_word(victim_clause,"example") and _has_whole_word(normalized,"workers?|laborers?|labourers?")):
			target["role"]="worker"
		var age_min:=-1
		var age_max:=-1
		var age_regex:=RegEx.new()
		age_regex.compile("(?:over|older than|above|age[d]? at least)\\s+(\\d{1,3})")
		var age_match:=age_regex.search(normalized)
		if age_match: age_min=clampi(int(age_match.get_string(1))+1,0,120)
		var under_regex:=RegEx.new()
		under_regex.compile("(?:under|younger than|below)\\s+(\\d{1,3})")
		var under_match:=under_regex.search(normalized)
		if under_match: age_max=clampi(int(under_match.get_string(1))-1,0,120)
		var cohorts:=_cohorts_overlapping_age_range(age_min,age_max)
		if String(target.get("role",""))=="worker":
			cohorts=cohorts.filter(func(cohort:String)->bool: return cohort not in ["children","elders"])
		if not cohorts.is_empty(): target["age_cohorts"]=cohorts
		if age_min>=0: target["age_min"]=age_min
		if age_max>=0: target["age_max"]=age_max
		var target_words:Array[String]=[]
		if target.has("exact_count"): target_words.append("exactly %d" % int(target.exact_count))
		if target.has("role"): target_words.append("worker" if int(target.get("exact_count",0))==1 else "workers")
		elif target.has("exact_count") and not target.has("sex"): target_words.append("person" if int(target.exact_count)==1 else "people")
		if target.has("sex"): target_words.append("women" if String(target.sex)=="female" else "men")
		if age_min>=0: target_words.append("over %d" % (age_min-1))
		elif age_max>=0: target_words.append("under %d" % (age_max+1))
		if target_words.is_empty():
			for group in ["dissidents","the sick","the opposition","the population"]:
				if String(group) in normalized: target_words.append(String(group)); break
		target["label"]=" ".join(target_words) if not target_words.is_empty() else "the named target group"
		result["demographic_target"]=target
		if _first_affirmed_term(normalized,["now","immediately","at once","as soon as possible"])!="": result["urgency"]="immediate"
		result["ethical_severity"]="grave"
		result["deliberation_required"]=true
	if policy_id=="coercive_pronatalism":
		# Conception pressure concerns people who can become pregnant, while a threat
		# against "parents" names an adult household class rather than one sex. Keep
		# those two aggregate targets separate so enforcement cannot silently rewrite
		# the player's stated victims.
		var single_child_target:="single child" in normalized or "single-child" in normalized or "one child" in normalized
		var compulsory_pairing:="have sex" in normalized or "mating" in normalized or "mate " in normalized
		var conception_label:="people in single-child households who can become pregnant" if single_child_target else "women who are not pregnant" if ("unpregnant" in normalized or "not pregnant" in normalized) else "people who can become pregnant"
		var enforcement_label:="parents in single-child households subject to the threat" if single_child_target else conception_label
		result["conception_target"]={"scope":"targeted","sex":"female","age_cohorts":["youth","early_adults","established_adults","mature_adults"],"label":conception_label}
		result["demographic_target"]={"scope":"targeted","sex":"female","age_cohorts":["youth","early_adults","established_adults","mature_adults"],"label":enforcement_label}
		result["deadline_kind"]="pregnancy_threat"
		if compulsory_pairing: result["coercion_method"]="compulsory sexual pairing until pregnancy"
		result["ethical_severity"]="grave"
		result["deliberation_required"]=true
	if policy_id=="information_control" and ("rumor" in normalized or "rumour" in normalized):
		result["message_method"]="deliberately seeded rumor"
		result["message_subject"]="plague warning" if "plague" in normalized else "public warning"
	return result

func _has_whole_word(text:String,alternatives:String)->bool:
	var regex:=RegEx.new()
	regex.compile("\\b(?:"+alternatives+")\\b")
	return regex.search(text)!=null

func _cohorts_overlapping_age_range(age_min:int,age_max:int)->Array[String]:
	var ranges:Dictionary={"children":Vector2i(0,13),"youth":Vector2i(14,24),"early_adults":Vector2i(25,34),"established_adults":Vector2i(35,44),"mature_adults":Vector2i(45,59),"elders":Vector2i(60,120)}
	var lower:=0 if age_min<0 else age_min
	var upper:=120 if age_max<0 else age_max
	var result:Array[String]=[]
	for cohort in ranges:
		var span:Vector2i=ranges[cohort]
		if span.y>=lower and span.x<=upper: result.append(String(cohort))
	return result

func _contextual_repeal_basis(text:String)->String:
	for phrase in ["end it","end this","end the current","stop it","lift it","repeal it","cancel it","rescind it"]:
		if String(phrase) in text: return String(phrase)
	return "current policy reference"

func _has_contextual_repeal_intent(text:String)->bool:
	for phrase in ["end it","end this","end the current","stop it","lift it","repeal it","cancel it","rescind it"]:
		if String(phrase) in text: return true
	return false

func _action_near_match(text:String,match_index:int)->String:
	var clause_start:=0
	for separator in [",",";","."," and "," then "]:
		var separator_index:=text.rfind(String(separator),match_index)
		if separator_index>=0: clause_start=maxi(clause_start,separator_index+String(separator).length())
	var prefix:=text.substr(clause_start,maxi(0,match_index-clause_start))
	# Negating a repeal verb means continuation: “do not stop rationing” cannot
	# be flattened into “stop rationing.” These are exact, narrow constructions;
	# more tangled wording remains available to the semantic fallback.
	for continuation in ["do not stop ","don't stop ","never stop ","do not end ","don't end ","never end ","do not repeal ","don't repeal ","do not cancel ","don't cancel ","do not lift ","don't lift "]:
		if _term_match_index(prefix,String(continuation))>=0: return "enact"
	for negation in ["end ","stop ","lift ","repeal ","cancel ","abolish ","rescind ","do not ","don't ","never ","no more ","prevent ","forbid ","prohibit ","oppose ","avoid "]:
		# Whole-word matching matters here: the letters “end” in “send
		# gatherers” must never reverse the very order being sent.
		if _term_match_index(prefix,String(negation))>=0: return "repeal"
	return "enact"

func _policy_ripple(id:String,action:String)->String:
	var definition:Dictionary=GovernmentPolicyCatalog.definition(id)
	if action=="repeal": return "The standing %s directive is rescinded; its simulation effects end." % id.replace("_"," ")
	return String(definition.ripple)

func _finish(request_id:String,result:Dictionary)->void:
	if not _requests.has(request_id): return
	var entry:Dictionary=_requests.get(request_id,{})
	var http:HTTPRequest=entry.get("http")
	if http and is_instance_valid(http): http.queue_free()
	_requests.erase(request_id)
	interpretation_completed.emit(request_id,result)

func _emit_result(request_id:String,result:Dictionary)->void:
	if not _requests.has(request_id): return
	_requests.erase(request_id)
	interpretation_completed.emit(request_id,result)

func _emit_progress(request_id:String,status:Dictionary)->void:
	if not _requests.has(request_id): return
	_set_progress(request_id,status)

func _set_progress(request_id:String,status:Dictionary)->void:
	if not _requests.has(request_id): return
	_requests[request_id]["progress"]=status.duplicate(true)
	interpretation_progress.emit(request_id,status)
