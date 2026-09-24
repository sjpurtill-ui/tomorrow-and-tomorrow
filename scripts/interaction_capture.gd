class_name InteractionCapture
extends RefCounted
## One-line adapters that turn each conversation surface's live API exchange
## into an interaction record. Every function is defensive: it never throws,
## never blocks gameplay, and returns "" when nothing was stored (recording
## disabled, empty text, unreadable reply). Context is reduced to an
## identity-free band signature before it reaches disk.
##
## Surfaces: "civic" (pronouncements), "audience" (hall audiences), "summon"
## (player-summoned court), "envoy" (foreign dialogue), "general" (field
## generals), or any short lowercase label a new surface chooses.

const _Store:=preload("res://scripts/interaction_store.gd")
const _Context:=preload("res://scripts/interaction_context.gd")
const _Types:=preload("res://scripts/interaction_types.gd")
const _Mode:=preload("res://scripts/ai_mode.gd")

static var captured:int=0

## Generic capture. meta keys (all optional): effects [{metric,delta,uncertainty,
## reason,duration_days}], side_effects, summary, policy_ids, counted,
## speaker {role, model}, model (API model name), usage {prompt_tokens,...},
## day, accepted, latency_ms, context (live context; defaults to live state),
## intent {speech_act,type_id,...} to override classification, source.
static func capture(surface:String,player_text:String,reply_text:String,meta:Dictionary={})->String:
	if not _Mode.records_interactions(): return ""
	var text:String=player_text.strip_edges()
	if text.is_empty(): return ""
	var ctx:Variant=meta.get("context")
	var live_ctx:Dictionary=(ctx as Dictionary) if ctx is Dictionary and not (ctx as Dictionary).is_empty() else _Context.from_live_state()
	var rec:Dictionary={
		"surface":surface,"player_text_raw":text,"context":live_ctx,
		"speaker":meta.get("speaker",{}) if meta.get("speaker") is Dictionary else {},
		"output":{"reply":reply_text,"summary":String(meta.get("summary","")),"effects":meta.get("effects",[]),
			"side_effects":meta.get("side_effects",[]),"policy_ids":meta.get("policy_ids",[])},
		"source":String(meta.get("source","live")),"model":String(meta.get("model","")),
		"usage":meta.get("usage",{}) if meta.get("usage") is Dictionary else {},
		"day":int(meta.get("day",_current_day())),"accepted":bool(meta.get("accepted",true)),
	}
	if meta.get("counted") is Dictionary: (rec.output as Dictionary)["counted"]=meta.counted
	if meta.get("intent") is Dictionary: rec["intent"]=meta.intent
	if meta.has("latency_ms"): rec["latency_ms"]=int(meta.latency_ms)
	var id:String=_Store.record(rec)
	if not id.is_empty(): captured+=1
	return id

## For surfaces that hold the raw chat-completions HTTP body. `parsed` is the
## already-decoded JSON content the surface accepted (or null to decode here).
static func capture_chat_body(surface:String,player_text:String,body:PackedByteArray,parsed:Variant=null,meta:Dictionary={})->String:
	var envelope:Variant=JSON.parse_string(body.get_string_from_utf8()) if body.size()>0 else null
	return capture_chat_envelope(surface,player_text,envelope if envelope is Dictionary else {},parsed,meta)

static func capture_chat_envelope(surface:String,player_text:String,envelope:Dictionary,parsed:Variant=null,meta:Dictionary={})->String:
	var m:Dictionary=meta.duplicate()
	if not m.has("model"): m["model"]=String(envelope.get("model",""))
	if not m.has("usage") and envelope.get("usage") is Dictionary: m["usage"]=envelope.usage
	var content:Variant=parsed
	if content==null:
		var choices:Variant=envelope.get("choices",[])
		if choices is Array and not (choices as Array).is_empty() and (choices as Array)[0] is Dictionary:
			var msg:Variant=((choices as Array)[0] as Dictionary).get("message",{})
			if msg is Dictionary:
				var raw:String=String((msg as Dictionary).get("content","")).trim_prefix("```json").trim_suffix("```").strip_edges()
				content=JSON.parse_string(raw) if not raw.is_empty() else null
				if content==null: content={"reply":raw}
	var extracted:Dictionary=extract_output(content)
	for k:String in ["summary","effects","policy_ids","speaker_key"]:
		if not m.has(k) and extracted.has(k): m[k]=extracted[k]
	if not m.has("speaker") and extracted.has("speaker_key"): m["speaker"]={"role":String(extracted.speaker_key)}
	return capture(surface,player_text,String(extracted.get("reply","")),m)

## Civic pronouncements: the PronouncementInterpreter result dictionary.
static func capture_civic(player_text:String,interpretation:Dictionary,meta:Dictionary={})->String:
	var m:Dictionary=meta.duplicate()
	var out:Dictionary=extract_output(interpretation)
	for k:String in ["summary","effects","policy_ids"]:
		if not m.has(k) and out.has(k): m[k]=out[k]
	if not m.has("accepted"): m["accepted"]=not bool(interpretation.get("service_failure",false))
	if not m.has("source") and String(interpretation.get("source","")).find("API")<0 and String(interpretation.get("source","")).find("generative")<0:
		# Deterministic/offline readings are not model output; keep them out of the live corpus.
		return ""
	return capture("civic",player_text,String(out.get("reply","")),m)

## Pulls reply text, effects and policy ids out of any surface's JSON shape:
## civic {answer,summary,policies[{id,statistical_effects}]}, audience
## {lines[{speaker_key,text}]}, envoy {envoy_words,reply,accord,tone,reaction},
## general {reply,action,target}.
static func extract_output(content:Variant)->Dictionary:
	var out:Dictionary={}
	if not (content is Dictionary): return out
	var c:Dictionary=content as Dictionary
	if c.get("answer") is String: out["reply"]=String(c.answer)
	elif c.get("reply") is String: out["reply"]=String(c.reply)
	elif c.get("lines") is Array:
		var parts:PackedStringArray=PackedStringArray()
		for line:Variant in c.lines:
			if line is Dictionary and (line as Dictionary).get("text") is String:
				parts.append(String((line as Dictionary).text))
				if not out.has("speaker_key"): out["speaker_key"]=String((line as Dictionary).get("speaker_key",""))
		out["reply"]=" ".join(parts)
	var summary:PackedStringArray=PackedStringArray()
	if c.get("summary") is String and not String(c.summary).is_empty(): summary.append(String(c.summary))
	for k:String in ["envoy_words","accord","tone","reaction","action","target","divine"]:
		if c.has(k) and not String(c[k]).is_empty(): summary.append("%s: %s" % [k,String(c[k])])
	if not summary.is_empty(): out["summary"]=" | ".join(summary)
	var effects:Array=[]
	var policy_ids:Array=[]
	if c.get("policies") is Array:
		for p:Variant in c.policies:
			if not (p is Dictionary): continue
			var pd:Dictionary=p as Dictionary
			if pd.has("id"): policy_ids.append(String(pd.id))
			var list:Variant=pd.get("statistical_effects",null)
			if not (list is Array) and pd.get("directive_parameters") is Dictionary:
				list=(pd.directive_parameters as Dictionary).get("statistical_effects",[])
			if list is Array:
				for e:Variant in list:
					if e is Dictionary: effects.append((e as Dictionary).duplicate())
	if c.get("effects") is Array:
		for e2:Variant in c.effects:
			if e2 is Dictionary: effects.append((e2 as Dictionary).duplicate())
	if not effects.is_empty(): out["effects"]=effects
	if not policy_ids.is_empty(): out["policy_ids"]=policy_ids
	return out

static func _current_day()->int:
	var loop:MainLoop=Engine.get_main_loop()
	if not (loop is SceneTree): return -1
	var gs:Node=(loop as SceneTree).root.get_node_or_null("GameState")
	if gs==null: return -1
	var d:Variant=gs.get("elapsed_days")
	return int(d) if d!=null else -1
