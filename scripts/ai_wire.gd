extends RefCounted
## THE WIRE TO THE MODEL: one way out for every live call, whoever serves it.
##
## Every caller (the court's voice, the order reader, envoys, the chronicle,
## the civic interpreter) builds an OpenAI-style chat request and reads an
## OpenAI-style reply. A model whose id begins "claude-" is served by
## Anthropic's Messages API instead: send() turns the request into a Messages
## request (system text apart, the strict schema as output_config.format, the
## reasoning effort as output_config.effort, no sampling settings), sends it
## from a child HTTPRequest, and hands the caller's own HTTPRequest a reply
## turned back into the chat shape (the text, a finish reason, the usage), so
## no caller changes how it reads. An OpenAI model goes out exactly as before.
##
## The Anthropic key is ANTHROPIC_API_KEY, else the game's own key when it is
## an Anthropic one (sk-ant-...). The address is api.anthropic.com unless
## LEVIATHAN_AI_ENDPOINT names an Anthropic or loopback address.
## Static helpers; preload.

const ANTHROPIC_ENDPOINT:="https://api.anthropic.com/v1/messages"
const ANTHROPIC_VERSION:="2023-06-01"
## Haiku 5.5 thinks by default and its thinking counts toward max_tokens: the
## caller's cap is for the answer alone, so room is added for the thinking.
const THINKING_ROOM:={"low":1500,"medium":4000,"high":8000}
## Effort when the caller names none (LEVIATHAN_AI_EFFORT overrides): the
## court's calls are short replies and readings, and the reader waits 8 s.
const DEFAULT_EFFORT:="low"
## Schema words Anthropic's structured outputs do not take; the game checks
## and clamps every reply itself, so they are dropped from what is sent.
## Schema words whose value maps names to schemas.
const SCHEMA_MAPS:=["properties","$defs","definitions","patternProperties"]
const UNSUPPORTED_SCHEMA_KEYS:=["minimum","maximum","exclusiveMinimum","exclusiveMaximum","multipleOf","minLength","maxLength","pattern","minItems","maxItems","uniqueItems","minProperties","maxProperties"]

## Whether `model` is served by Anthropic.
static func is_anthropic(model:String)->bool:
	return model.strip_edges().to_lower().begins_with("claude-")

## The Anthropic key, or "" when there is none.
static func anthropic_key(fallback:String="")->String:
	var key:=OS.get_environment("ANTHROPIC_API_KEY").strip_edges()
	if key.is_empty() and fallback.strip_edges().begins_with("sk-ant-"): key=fallback.strip_edges()
	if key.is_empty():
		var game_key:=OS.get_environment("LEVIATHAN_AI_API_KEY").strip_edges()
		if game_key.begins_with("sk-ant-"): key=game_key
	return key

## Where an Anthropic request goes: LEVIATHAN_AI_ENDPOINT when it is an
## Anthropic or loopback address (a test's stub), else api.anthropic.com.
static func anthropic_endpoint()->String:
	var endpoint:=OS.get_environment("LEVIATHAN_AI_ENDPOINT").strip_edges()
	var lower:=endpoint.to_lower()
	if "anthropic.com" in lower or lower.begins_with("http://127.") or lower.begins_with("http://localhost") or lower.begins_with("http://[::1]"): return endpoint
	return ANTHROPIC_ENDPOINT

## A connection set for `model`: the same config, with the address and key
## that model's service needs (the order reader may use another model than
## the voice). {} when that service has no key.
static func config_for_model(config:Dictionary,model:String)->Dictionary:
	if config.is_empty(): return {}
	var out:=config.duplicate()
	out["model"]=model
	if is_anthropic(model):
		var key:=anthropic_key(String(config.get("api_key","")))
		if key.is_empty(): return {}
		out["api_key"]=key
		out["endpoint"]=anthropic_endpoint()
		out["provider"]="anthropic"
		out["structured_output"]=true
	elif String(config.get("provider",""))=="anthropic":
		# The voice is Anthropic's, this model OpenAI's: the OpenAI connection.
		var key:=OS.get_environment("LEVIATHAN_AI_API_KEY").strip_edges()
		if key.is_empty() or key.begins_with("sk-ant-"): key=OS.get_environment("OPENAI_API_KEY").strip_edges()
		if key.is_empty(): return {}
		out["api_key"]=key
		var endpoint:=OS.get_environment("LEVIATHAN_AI_ENDPOINT").strip_edges()
		out["endpoint"]=endpoint if endpoint!="" and not "anthropic.com" in endpoint.to_lower() else "https://api.openai.com/v1/chat/completions"
		out.erase("provider")
	return out

## Sends `payload` (an OpenAI chat request) for `config` on `http`, which the
## caller has set up and connected. Returns what HTTPRequest.request returns.
static func send(http:HTTPRequest,config:Dictionary,headers:PackedStringArray,payload:Dictionary)->Error:
	var model:=String(payload.get("model",config.get("model","")))
	if not is_anthropic(model):
		return http.request(String(config.get("endpoint","")),headers,HTTPClient.METHOD_POST,JSON.stringify(payload))
	var key:=anthropic_key(String(config.get("api_key","")))
	if key.is_empty(): return ERR_UNAUTHORIZED
	var endpoint:=String(config.get("endpoint",""))
	if not ("anthropic.com" in endpoint.to_lower() or endpoint.begins_with("http://127.") or endpoint.begins_with("http://localhost")): endpoint=anthropic_endpoint()
	var wire:=HTTPRequest.new()
	wire.name="AnthropicWire"
	wire.timeout=http.timeout
	wire.max_redirects=http.max_redirects
	wire.body_size_limit=http.body_size_limit
	wire.use_threads=http.use_threads
	http.add_child(wire)
	var json_object:=payload.get("response_format") is Dictionary and String((payload.response_format as Dictionary).get("type",""))=="json_object"
	wire.request_completed.connect(func(result:int,code:int,reply_headers:PackedStringArray,body:PackedByteArray)->void:
		var turned:=to_chat_reply(body,code,json_object)
		if is_instance_valid(wire): wire.queue_free()
		if is_instance_valid(http): http.request_completed.emit(result,code,reply_headers,turned))
	var wire_headers:=PackedStringArray(["Content-Type: application/json","x-api-key: %s" % key,"anthropic-version: %s" % ANTHROPIC_VERSION])
	var error:=wire.request(endpoint,wire_headers,HTTPClient.METHOD_POST,JSON.stringify(to_messages_request(payload,model)))
	if error!=OK: wire.queue_free()
	return error

## An OpenAI chat request as an Anthropic Messages request.
static func to_messages_request(payload:Dictionary,model:String)->Dictionary:
	var system_parts:PackedStringArray=[]
	var messages:Array=[]
	for entry:Variant in payload.get("messages",[]):
		if not entry is Dictionary: continue
		var role:=String((entry as Dictionary).get("role","user"))
		var text:=_text_of((entry as Dictionary).get("content",""))
		if role in ["system","developer"]:
			if text!="": system_parts.append(text)
			continue
		if role!="assistant": role="user"
		if text.is_empty(): continue
		# Messages alternate: a second turn of the same voice joins the first.
		if not messages.is_empty() and String((messages[-1] as Dictionary).role)==role:
			(messages[-1] as Dictionary).content=String((messages[-1] as Dictionary).content)+"\n\n"+text
		else: messages.append({"role":role,"content":text})
	# A request may not end on the model's own turn (no prefill).
	if not messages.is_empty() and String((messages[-1] as Dictionary).role)=="assistant":
		messages.append({"role":"user","content":"Continue."})
	if messages.is_empty(): messages.append({"role":"user","content":"Continue."})
	var effort:=effort_for(payload)
	var cap:=int(payload.get("max_completion_tokens",payload.get("max_tokens",1024)))
	var out:={"model":model,"max_tokens":maxi(256,cap)+int(THINKING_ROOM.get(effort,1500)),"messages":messages,"thinking":{"type":"adaptive"},"output_config":{"effort":effort}}
	if not system_parts.is_empty(): out["system"]="\n\n".join(system_parts)
	var format:Variant=payload.get("response_format")
	if format is Dictionary and String((format as Dictionary).get("type",""))=="json_schema":
		var spec:Variant=(format as Dictionary).get("json_schema",{})
		var schema:Variant=(spec as Dictionary).get("schema") if spec is Dictionary else null
		if schema is Dictionary: (out.output_config as Dictionary)["format"]={"type":"json_schema","schema":clean_schema(schema)}
	return out

## The effort for a request: LEVIATHAN_AI_EFFORT, else the caller's reasoning
## effort (minimal and low are low), else DEFAULT_EFFORT.
static func effort_for(payload:Dictionary)->String:
	var setting:=OS.get_environment("LEVIATHAN_AI_EFFORT").strip_edges().to_lower()
	if setting in ["low","medium","high"]: return setting
	var asked:=String(payload.get("reasoning_effort","")).to_lower()
	if asked in ["minimal","low","none"]: return "low"
	if asked in ["medium","high"]: return asked
	return DEFAULT_EFFORT

## A JSON schema without the words structured outputs refuse; every object
## closed to further keys, as they require.
static func clean_schema(schema:Variant)->Variant:
	if schema is Array:
		var list:Array=[]
		for item:Variant in schema: list.append(clean_schema(item))
		return list
	if not schema is Dictionary: return schema
	var out:={}
	for key:Variant in schema:
		var name:=str(key)
		if name in UNSUPPORTED_SCHEMA_KEYS: continue
		var value:Variant=(schema as Dictionary)[key]
		# A map of field names to schemas: a field may be called "type".
		if name in SCHEMA_MAPS and value is Dictionary:
			var fields:={}
			for field:Variant in value: fields[field]=clean_schema((value as Dictionary)[field])
			out[key]=fields
		else: out[key]=clean_schema(value)
	var kind:Variant=out.get("type")
	if (kind is String and kind=="object") or (kind is Array and "object" in (kind as Array)): out["additionalProperties"]=false
	return out

## An Anthropic Messages reply (or error) as the chat reply callers read.
static func to_chat_reply(body:PackedByteArray,code:int,json_object:bool=false)->PackedByteArray:
	var parsed:Variant=JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary: return body
	var reply:Dictionary=parsed
	if code<200 or code>=300 or String(reply.get("type",""))=="error":
		var error:Variant=reply.get("error",{})
		var message:=String((error as Dictionary).get("message","")) if error is Dictionary else str(error)
		var kind:=String((error as Dictionary).get("type","")) if error is Dictionary else ""
		return JSON.stringify({"error":{"message":message,"type":kind}}).to_utf8_buffer()
	var text:=""
	for block:Variant in reply.get("content",[]):
		if block is Dictionary and String((block as Dictionary).get("type",""))=="text": text+=String((block as Dictionary).get("text",""))
	if json_object: text=_unfence(text)
	var stop:=String(reply.get("stop_reason",""))
	var finish:String={"end_turn":"stop","stop_sequence":"stop","max_tokens":"length","refusal":"content_filter","tool_use":"tool_calls"}.get(stop,"stop")
	if stop=="refusal": text=""
	var usage:Dictionary=reply.get("usage",{}) if reply.get("usage") is Dictionary else {}
	var prompt:=int(usage.get("input_tokens",0))+int(usage.get("cache_read_input_tokens",0))+int(usage.get("cache_creation_input_tokens",0))
	var completion:=int(usage.get("output_tokens",0))
	return JSON.stringify({
		"id":String(reply.get("id","")),"object":"chat.completion","model":String(reply.get("model","")),
		"choices":[{"index":0,"message":{"role":"assistant","content":text},"finish_reason":finish}],
		"usage":{"prompt_tokens":prompt,"completion_tokens":completion,"total_tokens":prompt+completion,
			"prompt_tokens_details":{"cached_tokens":int(usage.get("cache_read_input_tokens",0))}},
	}).to_utf8_buffer()

static func _text_of(content:Variant)->String:
	if content is String: return content
	if content is Array:
		var parts:PackedStringArray=[]
		for part:Variant in content:
			if part is Dictionary and (part as Dictionary).has("text"): parts.append(String((part as Dictionary).text))
			elif part is String: parts.append(part)
		return "\n".join(parts)
	return "" if content==null else str(content)

## JSON a model wrapped in a ``` fence, without the fence.
static func _unfence(text:String)->String:
	var t:=text.strip_edges()
	if not t.begins_with("```"): return text
	var first_line_end:=t.find("\n")
	if first_line_end<0: return text
	t=t.substr(first_line_end+1)
	if t.ends_with("```"): t=t.substr(0,t.length()-3)
	return t.strip_edges()
