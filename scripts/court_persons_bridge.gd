extends RefCounted
## The bridge between live and offline play for the court-known persons
## engine. Every live exchange returns, in the same single call, the canonical
## action it chose, bounded deltas, the in-world reply, a templated version of
## that reply and a situation signature. The engine validates it, clamps it,
## and stores it in the existing interaction database (InteractionStore,
## surface "court_persons"): intent.type_id is the action, intent.topic is the
## signature ("r=commoner;g=i;l=l;b=dread;e=0;v=stores;k=alibi_named"), the
## reply and its template go to output. Nothing secret is written as text:
## guilt and lying live only in the signature, and templates carry no names.
##
## Offline, a choice's action plus the current signature asks for the nearest
## recorded template that agrees exactly on the beat, role, guilt and lie
## state and is within the era gate; slots are refilled with the current
## people, matches rotate for variety, and the deterministic banks stand in
## when nothing matches. Typed intents the vocabulary lacks ("novel:<slug>")
## are counted; one that recurs (or that the model marks generalizable) is
## promoted to an offline choice with its learned deltas, under a hard cap.

const Store:=preload("res://scripts/interaction_store.gd")
const Context:=preload("res://scripts/interaction_context.gd")
const CV:=preload("res://scripts/character_voice.gd")

const SURFACE:="court_persons"
const NOVEL_THRESHOLD:=3
const NOVEL_CAP:=12
const NOVEL_METRICS:=["legitimacy","cohesion","love","dread"]
const DELTA_CAP:=0.03
const ALLOWED_SLOTS:=["name","given","trade","village","age","household","detail","He","he","his","him","event","liar","liar_title","charge","place","witness","culprit","named","kin","office","spouse","act","ledger","title","count","god_address","role","temper","Age","Given"]
## The true culprit's name may be templated only where the truth is spoken.
const TRUTH_BEATS:=["alibi_kin","confess_kin","confess_self"]
const META:="(?i)\\b(game|player|button|menu|json|ai|model|prompt|npc|click|guilty flag|signature)\\b"

static var _rotation:Dictionary={}
static var _promoted_cache:Dictionary={"revision":-1,"list":[]}

# --------------------------------------------------------------------------
# Signature text
# --------------------------------------------------------------------------

static func sig_text(sig:Dictionary,beat:String="")->String:
	var t:="r=%s;g=%s;l=%s;b=%s;e=%d;v=%s" % [String(sig.get("role","")),String(sig.get("g","n")),String(sig.get("l","n")),String(sig.get("band","")),int(sig.get("era",0)),String(sig.get("ev",""))]
	if beat!="": t+=";k="+beat
	return t.substr(0,80)

static func parse_sig(text:String)->Dictionary:
	var out:Dictionary={}
	for part in text.split(";",false):
		var kv:=String(part).split("=",true,1)
		if kv.size()==2: out[String(kv[0])]=String(kv[1])
	return out

# --------------------------------------------------------------------------
# Validation of a live reply
# --------------------------------------------------------------------------

static func clamp_deltas(raw:Variant)->Array:
	var out:Array=[]
	if not raw is Array: return out
	for v in raw:
		if out.size()>=4: break
		if not v is Dictionary: continue
		var metric:=String((v as Dictionary).get("metric",""))
		var delta:Variant=(v as Dictionary).get("delta",null)
		if not metric in NOVEL_METRICS or not (delta is float or delta is int) or not is_finite(float(delta)): continue
		out.append({"metric":metric,"delta":clampf(float(delta),-DELTA_CAP,DELTA_CAP)})
	return out

static func slug_ok(action:String)->bool:
	if not action.begins_with("novel:"): return false
	var re:=RegEx.new(); re.compile("^[a-z][a-z0-9_]{2,39}$")
	return re.search(action.trim_prefix("novel:"))!=null

static func validate_live(raw:Variant,menu:Array)->Dictionary:
	## {ok, action, params, deltas, template, generalizable, label, reason}.
	## A reply whose action is neither on the menu nor a well-formed novel
	## slug is rejected; deltas out of bounds are clamped, malformed dropped.
	if not raw is Dictionary: return {"ok":false,"reason":"not an object"}
	var r:Dictionary=raw
	var action:=String(r.get("canonical_action","")).strip_edges().to_lower().substr(0,48)
	var choice:Variant=r.get("choice",-1)
	var index:=int(choice) if (choice is int or choice is float) and is_finite(float(choice)) else -1
	var params:Dictionary={}
	var found:=false
	if index>=0 and index<menu.size() and String((menu[index] as Dictionary).get("action",""))==action:
		params=((menu[index] as Dictionary).get("params",{}) as Dictionary).duplicate(true); found=true
	elif not action.begins_with("novel:"):
		for m in menu:
			if String((m as Dictionary).get("action",""))==action:
				params=((m as Dictionary).get("params",{}) as Dictionary).duplicate(true); found=true; break
	if action=="talk": found=true
	var label:=String(r.get("label","")).strip_edges().substr(0,60)
	if action.begins_with("novel:"):
		if not slug_ok(action): return {"ok":false,"reason":"malformed novel action"}
		found=true
		params["label"]=label if label!="" else action.trim_prefix("novel:").replace("_"," ")
	if not found: return {"ok":false,"reason":"action not on the menu: %s" % action}
	var template:=String(r.get("reply_template","")).strip_edges().substr(0,300)
	return {"ok":true,"action":action,"params":params,"deltas":clamp_deltas(r.get("deltas",[])),"template":template,
		"generalizable":bool(r.get("generalizable",false)) if r.get("generalizable") is bool else false,"label":label}

static func safe_template(template:String,beat:String,era_tags:Array)->bool:
	## A template carries no names (every person is a slot), no slot it may
	## not use, no hidden truth, nothing the era lacks and no talk of games.
	if template.length()<8 or template.length()>300: return false
	var slot:=RegEx.new(); slot.compile("\\{([A-Za-z_]+)\\}")
	for m in slot.search_all(template):
		var s:=m.get_string(1)
		if not s in ALLOWED_SLOTS: return false
		if s=="culprit" and not beat in TRUTH_BEATS: return false
	var bare:=slot.sub(template,"",true)
	var name:=RegEx.new(); name.compile("(?<=[a-z,;:] )[A-Z][a-z]{2,}")
	if name.search(bare)!=null: return false
	var meta:=RegEx.new(); meta.compile(META)
	if meta.search(bare)!=null: return false
	return CV.permits(bare,era_tags)

# --------------------------------------------------------------------------
# Learning: store one validated exchange
# --------------------------------------------------------------------------

static func learn(player_text:String,action:String,beat:String,sig:Dictionary,reply:String,template:String,deltas:Array,meta:Dictionary={})->String:
	var era_tags:=Context.tags_for_tier(int(sig.get("era",0)))
	var tpl:=template if safe_template(template,beat,era_tags) else ""
	var summary:="gen=%d;label=%s" % [1 if bool(meta.get("generalizable",false)) else 0,String(meta.get("label","")).replace(";",",").substr(0,60)]
	var effects:Array=[]
	for d in clamp_deltas(deltas): effects.append({"metric":String((d as Dictionary).metric),"delta":float((d as Dictionary).delta),"reason":"court_persons"})
	var rec:={"surface":SURFACE,"player_text_raw":player_text if player_text.strip_edges()!="" else "(choice) "+action,
		"intent":{"speech_act":"court","type_id":action.substr(0,48),"type_confidence":1.0,"topic":sig_text(sig,beat),"policy_ids":[]},
		"context":{"era_tier":int(sig.get("era",0)),"population":int(GameState.population_total),"metrics":GameState.simulation_metrics.duplicate(),"food_days":float(GameState.simulation_metrics.get("food_days",30.0))},
		"speaker":{"role":String(sig.get("role","")),"model":String(meta.get("model",""))},
		"output":{"reply":reply,"reply_template":tpl,"summary":summary,"effects":effects},
		"source":String(meta.get("source","live")),"model":String(meta.get("model_name","")),"usage":meta.get("usage",{}) if meta.get("usage") is Dictionary else {},"day":int(GameState.elapsed_days)}
	return Store.record(rec,bool(meta.get("force",false)))

# --------------------------------------------------------------------------
# Replay: the nearest learned template for exactly this situation
# --------------------------------------------------------------------------

static func matches(sig:Dictionary,beat:String)->Array:
	var out:Array=[]
	var era:=int(sig.get("era",0))
	for r in Store.records():
		if not r is Dictionary: continue
		var rec:Dictionary=r
		if String(rec.get("surface",""))!=SURFACE: continue
		var intent:Dictionary=rec.get("intent",{}) if rec.get("intent") is Dictionary else {}
		if String(intent.get("type_id",""))!=String(sig.get("action","")): continue
		var tpl:=String((rec.get("output",{}) as Dictionary).get("reply_template",""))
		if tpl=="": continue
		var got:=parse_sig(String(intent.get("topic","")))
		# Must agree: the beat, the speaker's role, guilt and lie state.
		if String(got.get("k",""))!=beat: continue
		if String(got.get("r",""))!=String(sig.get("role","")) or String(got.get("g",""))!=String(sig.get("g","n")) or String(got.get("l",""))!=String(sig.get("l","n")): continue
		# Era gate: a template learned in a later era is never spoken earlier.
		if int(got.get("e","0"))>era: continue
		var score:=1.0
		if String(got.get("b",""))==String(sig.get("band","")): score+=0.5
		if String(got.get("v",""))==String(sig.get("ev","")): score+=0.3
		score-=absf(float(int(got.get("e","0"))-era))*0.1
		out.append({"template":tpl,"score":score,"id":String(rec.get("id",""))})
	out.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.score)>float(b.score) or (float(a.score)==float(b.score) and String(a.id)<String(b.id)))
	return out

static func replay(sig:Dictionary,beat:String,slots:Dictionary,_rng:RandomNumberGenerator)->String:
	var found:=matches(sig,beat)
	if found.is_empty(): return ""
	var best:=float((found[0] as Dictionary).score)
	var top:Array=found.filter(func(m:Dictionary)->bool: return float(m.score)>=best-0.001)
	var key:=sig_text(sig,beat)
	var turn:=int(_rotation.get(key,0))
	_rotation[key]=turn+1
	var lines:GDScript=load("res://scripts/court_persons_lines.gd")
	for i in top.size():
		var tpl:=String((top[(turn+i)%top.size()] as Dictionary).template)
		var filled:=String(lines.call("fill",tpl,slots))
		if bool(lines.call("usable",filled,slots)): return filled
	return ""

# --------------------------------------------------------------------------
# Choice discovery
# --------------------------------------------------------------------------

static func promoted(sig:Dictionary)->Array:
	## Novel intents seen often enough (or marked generalizable), as offline
	## choices gated by the speaker's role: [{action,label,deltas,count}].
	var list:=_promoted_all()
	var out:Array=[]
	for p in list:
		if String((p as Dictionary).get("role",""))==String(sig.get("role","")) and int((p as Dictionary).get("era",0))<=int(sig.get("era",0)): out.append(p)
	return out

static func _promoted_all()->Array:
	if int(_promoted_cache.revision)==Store.revision(): return _promoted_cache.list
	var clusters:Dictionary={}
	for r in Store.records():
		if not r is Dictionary: continue
		var rec:Dictionary=r
		if String(rec.get("surface",""))!=SURFACE: continue
		var action:=String((rec.get("intent",{}) as Dictionary).get("type_id",""))
		if not slug_ok(action): continue
		var got:=parse_sig(String((rec.get("intent",{}) as Dictionary).get("topic","")))
		var summary:=parse_sig(String((rec.get("output",{}) as Dictionary).get("summary","")))
		var c:Dictionary=clusters.get(action,{"action":action,"count":0,"gen":false,"labels":{},"deltas":{},"roles":{},"era":9})
		c.count=int(c.count)+1
		if String(summary.get("gen","0"))=="1": c.gen=true
		var label:=String(summary.get("label",""))
		if label!="": (c.labels as Dictionary)[label]=int((c.labels as Dictionary).get(label,0))+1
		var role:=String(got.get("r",""))
		(c.roles as Dictionary)[role]=int((c.roles as Dictionary).get(role,0))+1
		c.era=mini(int(c.era),int(got.get("e","0")))
		for e in (rec.get("output",{}) as Dictionary).get("effects",[]):
			var m:=String((e as Dictionary).get("metric",""))
			if m in NOVEL_METRICS:
				var acc:Array=(c.deltas as Dictionary).get(m,[0.0,0])
				(c.deltas as Dictionary)[m]=[float(acc[0])+float((e as Dictionary).get("delta",0.0)),int(acc[1])+1]
		clusters[action]=c
	var out:Array=[]
	for action in clusters:
		var c2:Dictionary=clusters[action]
		if int(c2.count)<NOVEL_THRESHOLD and not bool(c2.gen): continue
		var label2:=_top_key(c2.labels as Dictionary)
		if label2=="": label2=String(action).trim_prefix("novel:").replace("_"," ")
		label2=label2.substr(0,1).to_upper()+label2.substr(1)
		# Quality filter: short, era-true, no names, no talk of games.
		if label2.length()>48 or not CV.permits(label2,Context.tags_for_tier(int(c2.era))): continue
		var nm:=RegEx.new(); nm.compile("(?<=[a-z,;:] )[A-Z][a-z]{2,}")
		if nm.search(label2)!=null: continue
		var meta:=RegEx.new(); meta.compile(META)
		if meta.search(label2)!=null: continue
		var deltas:Array=[]
		for m2 in c2.deltas:
			var acc2:Array=(c2.deltas as Dictionary)[m2]
			deltas.append({"metric":String(m2),"delta":clampf(float(acc2[0])/maxf(1.0,float(acc2[1])),-DELTA_CAP,DELTA_CAP)})
		out.append({"action":String(action),"label":label2,"deltas":deltas,"count":int(c2.count),"role":_top_key(c2.roles as Dictionary),"era":int(c2.era)})
	out.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.count)>int(b.count) or (int(a.count)==int(b.count) and String(a.action)<String(b.action)))
	while out.size()>NOVEL_CAP: out.pop_back()
	_promoted_cache={"revision":Store.revision(),"list":out}
	return out

static func _top_key(d:Dictionary)->String:
	var best:=""
	var n:=-1
	for k in d:
		if int(d[k])>n or (int(d[k])==n and String(k)<best): n=int(d[k]); best=String(k)
	return best

# --------------------------------------------------------------------------
# The live request: schema and instruction
# --------------------------------------------------------------------------

static func response_format(keys:Array[String])->Dictionary:
	return {"type":"json_schema","json_schema":{"name":"court_persons","strict":true,"schema":{
		"type":"object","additionalProperties":false,
		"required":["canonical_action","choice","label","deltas","lines","reply_template","signature","generalizable","mood_shift"],
		"properties":{
			"canonical_action":{"type":"string"},
			"choice":{"type":"integer"},
			"label":{"type":"string"},
			"deltas":{"type":"array","items":{"type":"object","additionalProperties":false,"required":["metric","delta"],"properties":{"metric":{"type":"string","enum":NOVEL_METRICS},"delta":{"type":"number"}}}},
			"lines":{"type":"array","items":{"type":"object","additionalProperties":false,"required":["speaker_key","text","aside"],"properties":{"speaker_key":{"type":"string","enum":keys},"text":{"type":"string"},"aside":{"type":"boolean"}}}},
			"reply_template":{"type":"string"},
			"signature":{"type":"object","additionalProperties":false,"required":["role","guilt","lying","band"],"properties":{"role":{"type":"string"},"guilt":{"type":"string"},"lying":{"type":"string"},"band":{"type":"string"}}},
			"generalizable":{"type":"boolean"},
			"mood_shift":{"type":"number"}}}}}

static func instruction(player_text:String,menu:Array,hidden:String)->String:
	var rows:PackedStringArray=PackedStringArray()
	for i in menu.size():
		var m:Dictionary=menu[i]
		rows.append("%d. %s [%s] -> engine decides: %s" % [i,String(m.get("label","")),String(m.get("action","")),String(m.get("decided",""))])
	return ("The ruler just said: \"%s\". Map these words onto ONE action from the MENU (canonical_action = its [id], choice = its number). " % player_text)+\
		"If nothing fits, use canonical_action \"novel:<short_snake_slug>\", choice -1, a short label (under 6 words, no names), and at most 3 deltas (metric legitimacy/cohesion/love/dread, each between -0.03 and 0.03); set generalizable true if any ruler might ask it again. "+\
		"For conversation that asks nothing of the engine use \"talk\". Then write the scene for EXACTLY what the engine decides for that action (never another outcome): 'narrator' may give one stage direction in square brackets; the one addressed answers in their OWN voice (the summoned speak for themselves, never as the officials' mouthpiece); at most one other reacts as an aside. "+\
		"reply_template is the principal speaker's line again with every person, place and event replaced by slots {name} {given} {trade} {village} {event} {place} {witness} {liar} {kin} {named} {god_address}; no names may remain. signature: role (official/commoner/group), guilt (guilty/innocent/none), lying (yes/no/none), band (love/dread/wary) of the one answering.\n"+\
		"HIDDEN (never state it unless the decided outcome is a confession or an alibi that exposes it): %s\nMENU:\n%s" % [hidden,"\n".join(rows)]

# --------------------------------------------------------------------------
# Coverage mining (dev): which cells lack learned templates
# --------------------------------------------------------------------------

const CELLS:=[
	["ask_blame","official","blame","n","t"],["ask_blame","official","blame_lie","n","l"],["ask_about","official","describe","n","n"],
	["q_where","commoner","alibi_named","i","l"],["q_where","commoner","vague","g","t"],["q_where","commoner","where_plain","n","n"],
	["q_did","commoner","protest_named","i","l"],["q_did","commoner","confess","g","t"],["q_did","commoner","deny","g","t"],["q_did","commoner","beg","g","t"],["q_did","commoner","false_confession","i","l"],
	["q_swear","commoner","swear_true_named","i","l"],["q_swear","commoner","swear_false","g","t"],["q_who_else","commoner","witness","i","l"],["q_who_else","commoner","shift_blame","g","t"],
	["q_mercy","commoner","thanks_alibi_named","i","l"],["q_threaten","commoner","false_confession","i","l"],["q_threaten","commoner","cower","n","n"],
	["accuse_lie","official","confess_self","n","l"],["accuse_lie","official","confess_kin","n","l"],["accuse_lie","official","double_down","n","l"],["accuse_lie","official","protest_honest","n","t"],
	["exalt","commoner","react_exalt","n","n"],["pardon","commoner","react_pardon","g","t"],["curse","commoner","react_curse","g","t"],["make_example","commoner","react_example","g","t"],
]

static func coverage()->Array:
	var out:Array=[]
	for c in CELLS:
		var row:Array=c
		var n:=matches({"action":String(row[0]),"role":String(row[1]),"g":String(row[3]),"l":String(row[4]),"band":"wary","era":3,"ev":""},String(row[2])).size()
		out.append({"action":String(row[0]),"role":String(row[1]),"beat":String(row[2]),"g":String(row[3]),"l":String(row[4]),"templates":n})
	return out
