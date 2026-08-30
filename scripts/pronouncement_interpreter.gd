extends Node

signal interpretation_completed(request_id: String, result: Dictionary)
signal interpretation_progress(request_id: String, status: Dictionary)

const MAX_API_ATTEMPTS:=2
const RETRY_DELAY_SECONDS:=0.18
const MIN_API_CONFIDENCE:=0.55
const MAX_API_RESPONSE_BYTES:=131072

const POLICY_TERMS:Dictionary={
	"rationing":["ration","reduce portions","food allowance"],"foraging_drive":["forag","gather food","hunt","find food"],
	"conservation_order":["conserv","protect the land","preserve the land","limit gathering"],"care_rotation":["heal","care","sick","clinic"],
	"expanded_watch":["watch","guard","defen","patrol"],"public_assembly":["assembly","explain","public council","hear the people"],
	"emergency_building":["build","shelter","construction","housing"],
	"directed_inquiry":["fund research","support scholars","direct inquiry","investigate","study"],
	"craft_mobilization":["prioritize crafting","expand workshops","mobilize artisans","increase production"],
	"route_priority":["build roads","improve routes","expand logistics","prioritize hauling"],
	"labor_mobilization":["mobilize labor","work quotas","longer work","compulsory labor"],
	"family_support":["support families","childcare","encourage births","parental support"]
}

const DURATION_NUMBER_WORDS:Dictionary={
	"a":1.0,"an":1.0,"one":1.0,"two":2.0,"three":3.0,"four":4.0,"five":5.0,"six":6.0,
	"seven":7.0,"eight":8.0,"nine":9.0,"ten":10.0,"eleven":11.0,"twelve":12.0,
	"fourteen":14.0,"fifteen":15.0,"twenty":20.0,"thirty":30.0,"sixty":60.0,"ninety":90.0
}

var _requests: Dictionary = {}
var _request_serial:=0

func reset_for_new_world()->void:
	for request_variant in _requests.values():
		var request:Dictionary=request_variant
		var http:HTTPRequest=request.get("http")
		if http and is_instance_valid(http):
			http.cancel_request()
			http.queue_free()
	_requests.clear()

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
	var config := _api_config()
	if config.is_empty():
		fallback["source_detail"]="API not configured"
		_emit_progress.call_deferred(request_id,{"stage":"offline","message":"Using the deterministic interpreter because the API is not fully configured."})
		_emit_result.call_deferred(request_id,fallback)
		return request_id
	var payload := {"model":config.model,"temperature":0.1,"messages":[
		{"role":"system","content":"You translate sovereign pronouncements into a safe civilization-simulation policy contract. Return only JSON. Never create policy IDs or direct variable changes."},
		{"role":"user","content":_prompt(clean,safe_context)}
	]}
	if bool(config.get("structured_output",false)): payload["response_format"]=_structured_response_format()
	var headers:=PackedStringArray(["Content-Type: application/json","Authorization: Bearer %s" % config.api_key,"X-Client-Request-Id: %s" % request_id])
	_requests[request_id]={"fallback":fallback,"config":config,"payload":payload,"headers":headers,"text":clean,"attempts":0,"max_attempts":MAX_API_ATTEMPTS,"structured_output_requested":bool(config.get("structured_output",false)),"structured_output_downgraded":false}
	_send_http(request_id)
	return request_id

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
	http.timeout=25.0
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
	var endpoint:=OS.get_environment("LEVIATHAN_AI_ENDPOINT").strip_edges()
	var api_key:=OS.get_environment("LEVIATHAN_AI_API_KEY").strip_edges()
	if api_key.is_empty(): api_key=OS.get_environment("OPENAI_API_KEY").strip_edges()
	var model:=OS.get_environment("LEVIATHAN_AI_MODEL").strip_edges()
	if endpoint.is_empty() and not api_key.is_empty(): endpoint="https://api.openai.com/v1/chat/completions"
	if endpoint.is_empty() or api_key.is_empty() or model.is_empty(): return {}
	if not bool(_endpoint_security(endpoint).get("allowed",false)): return {}
	var structured_output:=_structured_output_enabled(endpoint)
	return {"endpoint":endpoint,"api_key":api_key,"model":model,"structured_output":structured_output}

func configuration_status()->Dictionary:
	var endpoint:=OS.get_environment("LEVIATHAN_AI_ENDPOINT").strip_edges()
	var api_key:=OS.get_environment("LEVIATHAN_AI_API_KEY").strip_edges()
	if api_key.is_empty(): api_key=OS.get_environment("OPENAI_API_KEY").strip_edges()
	var model:=OS.get_environment("LEVIATHAN_AI_MODEL").strip_edges()
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
	return {"configured":configured,"mode":"strict structured API" if structured else "compatible JSON API" if configured else "deterministic offline","model":_safe_diagnostic_text(model,80),"endpoint_host":_endpoint_host(endpoint),"transport_security":String(security.get("label","not configured")),"structured_output":structured,"missing":missing,"issues":issues}

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
	var offices:Array[String]=[]
	var office_values=context.get("known_offices",[])
	if office_values is Array:
		for office_variant in office_values:
			var office:=_safe_diagnostic_text(String(office_variant),50)
			if not office.is_empty() and not offices.has(office): offices.append(office)
			if offices.size()>=16: break
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
			if active.size()>=20: break
	if context.has("active_policies"): safe["active_policies"]=active
	return safe

func _structured_response_format()->Dictionary:
	var policy_ids:Array[String]=[]
	for policy_id in GovernmentPolicyCatalog.POLICIES: policy_ids.append(String(policy_id))
	policy_ids.sort()
	return {"type":"json_schema","json_schema":{"name":"pronouncement_contract","strict":true,"schema":{
		"type":"object","additionalProperties":false,
		"properties":{
			"summary":{"type":"string"},
			"policies":{"type":"array","maxItems":3,"items":{"type":"object","additionalProperties":false,"properties":{
				"id":{"type":"string","enum":policy_ids},
				"basis":{"type":"string","minLength":3,"maxLength":160},"confidence":{"type":"number","minimum":0,"maximum":1}
			},"required":["id","basis","confidence"]}},
			"unresolved":{"type":"string"}
		},"required":["summary","policies","unresolved"]
	}}}

func _prompt(text:String,context:Dictionary)->String:
	var safe_context:=_sanitize_public_context(context)
	return """Interpret this public sovereign pronouncement: %s
PUBLIC GAME CONTEXT: %s
Allowed policies and defaults: %s
Return exactly {\"summary\":\"plain-language reading\",\"policies\":[{\"id\":\"allowed id\",\"basis\":\"shortest exact nonempty quote from the pronouncement supporting this mapping\",\"confidence\":0.0-1.0}],\"unresolved\":\"what could not be simulated, or empty\"}.
Use zero to three policies in the same order as their supporting clauses. Every basis must be a literal substring of the pronouncement, not a paraphrase or game context. Omit mappings below 0.55 confidence. Do not return magnitude, duration, effects, or variable changes: deterministic code derives policy terms from catalog defaults and explicit player wording. Do not infer a policy contradicted by the text. Never include secrets, code, variable names, or prose pretending to change state.""" % [JSON.stringify(text),JSON.stringify(safe_context),JSON.stringify(GovernmentPolicyCatalog.public_contract())]

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
		accepted["api_attempts"]=attempt
		accepted["structured_output_requested"]=bool(request.get("structured_output_requested",false))
		accepted["structured_output_used"]=request.payload.has("response_format")
		accepted["structured_output_downgraded"]=bool(request.get("structured_output_downgraded",false))
		accepted["source_detail"]="API accepted on attempt %d%s" % [attempt," after structured-output compatibility downgrade" if bool(request.get("structured_output_downgraded",false)) else ""]
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
		var definition:Dictionary=GovernmentPolicyCatalog.definition(id)
		var action_data:=_policy_action(pronouncement_text,basis,id)
		if bool(action_data.get("ambiguous",false)):
			ambiguity_rejections+=1
			continue
		var action:=String(action_data.action)
		var parameters:=_policy_parameters(pronouncement_text,basis,definition)
		seen[id]=true
		var validated_policy:={"id":id,"action":action,"action_source":String(action_data.source),"office":definition.office,"skills":definition.skills.duplicate(),"effects":definition.effects.duplicate(true),"magnitude":float(parameters.magnitude),"days":float(parameters.days),"basis":basis,"confidence":confidence,"parameter_basis":String(parameters.parameter_basis),"magnitude_source":String(parameters.magnitude_source),"duration_source":String(parameters.duration_source),"ripple":_policy_ripple(id,action)}
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
	var unresolved:=provider_unresolved
	if not audit_reasons.is_empty():
		unresolved=" ".join(audit_reasons)
		if not provider_unresolved.is_empty(): unresolved+=" Provider note: "+provider_unresolved
		unresolved=unresolved.substr(0,240)
	return {"summary":summary,"policies":policies,"unresolved":unresolved,"grounding_rejections":grounding_rejections,"ambiguity_rejections":ambiguity_rejections,"capacity_rejections":capacity_rejections,"source":"generative API"}

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
		var index:=text.find(term)
		while index>=0:
			actions[_action_near_match(text,index)]=true
			index=text.find(term,index+maxi(1,term.length()))
	return actions

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
	var start:=0
	for separator in [",",";","."," and "," then "]:
		var index:=text.rfind(String(separator),match_index)
		if index>=0: start=maxi(start,index+String(separator).length())
	var finish:=text.length()
	for separator in [",",";","."," and "," then "]:
		var index:=text.find(String(separator),match_index+grounded.length())
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
	var normalized:=text.to_lower()
	var scores:Dictionary={}
	var bases:Dictionary={}
	var first_positions:Dictionary={}
	for id in POLICY_TERMS:
		for term in POLICY_TERMS[id]:
			var match_index:=normalized.find(String(term))
			if match_index>=0:
				scores[id]=int(scores.get(id,0))+1
				if not bases.has(id):
					bases[id]=normalized.substr(match_index,String(term).length())
					first_positions[id]=match_index
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
	return {"summary":"The council identified %d executable policy consequence%s." % [policies.size(),"" if policies.size()==1 else "s"],"policies":policies,"unresolved":unresolved,"ambiguity_rejections":ambiguity_rejections,"capacity_rejections":capacity_rejections,"source":"deterministic interpreter"}

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
	for negation in ["end ","stop ","lift ","repeal ","cancel ","abolish ","rescind ","do not ","don't ","never "]:
		if String(negation) in prefix: return "repeal"
	return "enact"

func _policy_ripple(id:String,action:String)->String:
	var definition:Dictionary=GovernmentPolicyCatalog.definition(id)
	if action=="repeal": return "The standing %s order is rescinded; its simulation effects end." % id.replace("_"," ")
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
