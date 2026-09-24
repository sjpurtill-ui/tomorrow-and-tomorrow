class_name InteractionTypes
extends RefCounted
## Catalogue of interaction types (res://data/interactions/types.json) and the
## offline classifier: speech act + best type by weighted lexicon, with a
## calibrated confidence. Loaded lazily once per session.

const _Text:=preload("res://scripts/interaction_text.gd")
const CATALOG_PATH:="res://data/interactions/types.json"
const FALLBACK_TYPE:="custom_directive"
const PHRASE_WEIGHT:=2.6
const CUE_WEIGHT:=3.0

static var _loaded:bool=false
static var _types:Dictionary={}          # id -> normalised type dictionary
static var _order:Array[String]=[]
static var _term_index:Dictionary={}     # canonical term -> Array of [type_id, weight]
static var _phrases:Array=[]             # [canonical phrase string, type_id, weight]
static var _cues:Array=[]                # [normalised raw substring, type_id, weight]
static var _frames:Dictionary={}
static var _families:Dictionary={}       # model id -> family
static var load_error:String=""

static func ensure_loaded()->void:
	if _loaded: return
	_loaded=true
	_types.clear(); _order.clear(); _term_index.clear(); _phrases.clear(); _cues.clear(); _frames.clear(); _families.clear()
	var raw:String=FileAccess.get_file_as_string(CATALOG_PATH)
	var parsed:Variant=JSON.parse_string(raw) if not raw.is_empty() else null
	if not (parsed is Dictionary):
		load_error="Interaction type catalogue missing or unreadable at %s." % CATALOG_PATH
		parsed={"types":[]}
	var data:Dictionary=parsed as Dictionary
	var frames:Variant=data.get("frames",{})
	if frames is Dictionary: _frames=frames as Dictionary
	var fams:Variant=data.get("voice_families",{})
	if fams is Dictionary:
		for family:Variant in fams:
			var models:Variant=(fams as Dictionary)[family]
			if models is Array:
				for m:Variant in models: _families[String(m)]=String(family)
	var list:Variant=data.get("types",[])
	if list is Array:
		for item:Variant in list:
			if item is Dictionary: _add_type(item as Dictionary)
	if not _types.has(FALLBACK_TYPE):
		_add_type({"id":FALLBACK_TYPE,"label":"Custom directive","category":"custom","effects":[],"core":["I will see it done as best we understand it, {address}."]})

## Registers (or replaces) a type at runtime; used by tests and future curated packs.
static func register_type(def:Dictionary)->void:
	ensure_loaded()
	_add_type(def)

static func _add_type(def:Dictionary)->void:
	var id:String=String(def.get("id","")).strip_edges()
	if id.is_empty(): return
	var t:Dictionary=def.duplicate(true)
	t["id"]=id
	t["effects"]=_effects_from(def.get("effects",[]))
	t["side"]=_side_from(def.get("side",[]))
	for key:String in ["core","ask","phrases","policies","cues"]:
		if not (t.get(key) is Array): t[key]=[]
	if not (t.get("costs") is Dictionary): t["costs"]={}
	if not (t.get("terms") is Dictionary): t["terms"]={}
	if not _types.has(id): _order.append(id)
	_types[id]=t
	# Several surface words can share one canonical token; keep the strongest
	# weight rather than summing, so synonym-rich types do not dominate.
	var terms:Dictionary=t.terms
	var canon_weights:Dictionary={}
	for word:Variant in terms:
		var canon:String=_Text.canonical(_Text.normalize(String(word)))
		if canon.is_empty(): continue
		canon_weights[canon]=maxf(float(canon_weights.get(canon,0.0)),float(terms[word]))
	for canon2:Variant in canon_weights:
		if not _term_index.has(canon2): _term_index[canon2]=[]
		(_term_index[canon2] as Array).append([id,float(canon_weights[canon2])])
	# Phrases must survive canonicalisation as at least two tokens; single-token
	# remnants would double-count an ordinary term.
	for phrase:Variant in t.phrases:
		var toks:PackedStringArray=_Text.tokens(String(phrase))
		if toks.size()>=2: _phrases.append([" "+" ".join(toks)+" ",id,PHRASE_WEIGHT])
	for cue:Variant in t.cues:
		var norm:String=_Text.normalize(String(cue)).replace(" ?","").replace("?","").strip_edges()
		if not norm.is_empty(): _cues.append([" "+norm+" ",id,CUE_WEIGHT])

static func _effects_from(raw:Variant)->Array:
	var out:Array=[]
	if not (raw is Array): return out
	for e:Variant in raw:
		if e is Array and (e as Array).size()>=4:
			var a:Array=e as Array
			out.append({"metric":String(a[0]),"delta":float(a[1]),"uncertainty":float(a[2]),"duration_days":float(a[3]),"reason":String(a[4]) if a.size()>4 else ""})
		elif e is Dictionary:
			var d:Dictionary=e as Dictionary
			out.append({"metric":String(d.get("metric","")),"delta":float(d.get("delta",0.0)),"uncertainty":float(d.get("uncertainty",0.01)),"duration_days":float(d.get("duration_days",d.get("duration",30.0))),"reason":String(d.get("reason",""))})
	return out

static func _side_from(raw:Variant)->Array:
	var out:Array=[]
	if not (raw is Array): return out
	for e:Variant in raw:
		if e is Array and (e as Array).size()>=2:
			var a:Array=e as Array
			out.append({"id":String(a[0]),"odds":float(a[1]),"description":String(a[2]) if a.size()>2 else ""})
		elif e is Dictionary: out.append((e as Dictionary).duplicate(true))
	return out

static func get_type(id:String)->Dictionary:
	ensure_loaded()
	return _types.get(id,_types.get(FALLBACK_TYPE,{}))

static func has_type(id:String)->bool:
	ensure_loaded()
	return _types.has(id)

static func ids()->Array[String]:
	ensure_loaded()
	return _order.duplicate()

static func count()->int:
	ensure_loaded()
	return _order.size()

static func frames(family:String)->Dictionary:
	ensure_loaded()
	return _frames.get(family,_frames.get("plain",{}))

static func family_for_model(model:String)->String:
	ensure_loaded()
	return String(_families.get(model.to_lower(),"plain"))

static func family_names()->Array[String]:
	ensure_loaded()
	var out:Array[String]=[]
	for k:Variant in _frames: out.append(String(k))
	return out

## Speech act from surface cues. Precedence: threat, blessing, rebuke, praise,
## greeting, polite request, question, order, statement.
static func speech_act(text:String)->String:
	var n:String=" "+_Text.normalize(text).replace("?"," ?").replace("!"," !")+" "
	var q:bool=text.strip_edges().ends_with("?")
	for cue:String in [" or else "," or i will "," or i ll "," if you do not "," if you don t "," i will destroy "," i will smite "," i will punish "," you will suffer "," beware "," fear my "," feel my wrath "]:
		if cue in n: return "threat"
	for cue:String in [" i bless "," bless you "," blessed be "," may you "," i grant you "," you have my favour "," you have my favor "," i watch over "]:
		if cue in n: return "blessing"
	for cue:String in [" you have failed "," i am disappointed "," how dare "," shame on "," you failed "," you fool "]:
		if cue in n: return "rebuke"
	for cue:String in [" well done "," i am pleased "," good work "," i am proud "," thank you "]:
		if cue in n: return "praise"
	var words:PackedStringArray=_Text.normalize(text).split(" ",false)
	var first:String=words[0] if words.size()>0 else ""
	if first in ["hello","hi","greetings","hail","welcome","farewell","goodbye"] and words.size()<=6: return "greeting"
	if words.size()>=2 and first in ["can","could","will","would"] and words[1]=="you":
		if words.size()>=3 and not (words[2] in ["tell","explain","say","think","advise","describe"]): return "order"
	if q or first in ["who","what","why","how","when","where","which","is","are","do","does","did","should","shall","am","was","were","whom","whose"]: return "question"
	for cue:String in [" i command "," i decree "," i order "," i want "," i demand "," let "," have the "," make the "," must "," shall "," henceforth "," from now on "," no one may "]:
		if cue in n: return "order"
	return "order" if words.size()>0 else "statement"

## Classifies text into a type with a calibrated confidence in [0,1].
## Returns {type_id, confidence, speech_act, category, topic, policy_ids, scores:[[id,score]...]}.
static func classify(text:String)->Dictionary:
	ensure_loaded()
	var toks:PackedStringArray=_Text.tokens(text)
	var joined:String=" "+" ".join(toks)+" "
	var scores:Dictionary={}
	var seen:Dictionary={}
	for tok:String in toks:
		if seen.has(tok): continue
		seen[tok]=true
		if _term_index.has(tok):
			for pair:Variant in _term_index[tok]:
				var p:Array=pair as Array
				scores[p[0]]=float(scores.get(p[0],0.0))+float(p[1])
	for ph:Variant in _phrases:
		var a:Array=ph as Array
		if String(a[0]) in joined: scores[a[1]]=float(scores.get(a[1],0.0))+float(a[2])
	var raw_joined:String=" "+_Text.normalize(text).replace("?"," ").replace("!"," ")+" "
	for cue2:Variant in _cues:
		var b:Array=cue2 as Array
		if String(b[0]) in raw_joined: scores[b[1]]=float(scores.get(b[1],0.0))+float(b[2])
	var act:String=speech_act(text)
	# Speech-act-shaped types get a nudge when the act matches.
	for id:String in _order:
		var t:Dictionary=_types[id]
		if t.has("act") and String(t.act)==act and scores.has(id): scores[id]=float(scores[id])+1.2
	var ranked:Array=[]
	for id:Variant in scores: ranked.append([String(id),float(scores[id])])
	ranked.sort_custom(func(x:Array,y:Array)->bool: return float(x[1])>float(y[1]) or (float(x[1])==float(y[1]) and String(x[0])<String(y[0])))
	var best_id:String=FALLBACK_TYPE
	var best:float=0.0
	var second:float=0.0
	if ranked.size()>0:
		best_id=String(ranked[0][0]); best=float(ranked[0][1])
	if ranked.size()>1: second=float(ranked[1][1])
	# Confidence: absolute evidence (saturating) times margin over the runner-up.
	var evidence:float=1.0-exp(-best/2.4)
	var margin:float=(best-second)/maxf(best,0.001)
	var confidence:float=clampf(evidence*(0.55+0.45*margin),0.0,1.0)
	if best<=0.0: confidence=0.0
	var t2:Dictionary=get_type(best_id)
	var top:Array=ranked.slice(0,3)
	return {"type_id":best_id,"confidence":confidence,"speech_act":act,"category":String(t2.get("category","custom")),
		"topic":String(t2.get("label",best_id)),"policy_ids":(t2.get("policies",[]) as Array).duplicate(),"scores":top}
