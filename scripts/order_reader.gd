extends RefCounted
## THE ORDER READER: what did the ruler mean?
##
## With a live model, the ruler's words are read FIRST by one short dedicated
## call that only reads intent (no dialogue). It is given the words, the last
## few lines of the audience, the hall roster (with keys) and a compact brief
## of the war: our towns, towns we hold and their garrisons, the peoples we
## know and whether we fight them, our bands and where they stand, and any
## question still open in this audience. It answers in strict JSON whose ids
## can only be ids we supplied; the engine resolves them. The model never
## invents a target, and harm to a group, a town or a people can never
## resolve to anyone in the hall (court_commands.harm_to_people stays the
## hard safety net underneath).
##
## decide() turns a validated reading into one plan:
##   speak    - talk or a question: the voice answers, nothing is done;
##   engine   - an order the engine carries out (court_commands.hear with a
##              resolved live reading, or a war reading built here from ids);
##   clarify  - low confidence, or a grave act (kill, maim, raze, war, leaving
##              a town) whose target is uncertain: the court asks ONE plain
##              question and keeps the order pending; "yes" carries it out;
##   legacy   - anything the reader does not own (civic business, trade,
##              envoys, a failed or rejected reading): the unchanged regex
##              path decides, exactly as offline.
## Offline there is no reader: the predetermined, state-driven path stands.
## Static helpers; preload. The HTTP call itself lives in audience_voice.gd.

const Hall:=preload("res://scripts/audience_hall.gd")
const CC:=preload("res://scripts/court_commands.gd")
const WarOrders:=preload("res://scripts/court_war_orders.gd")
const TownFate:=preload("res://scripts/town_fate.gd")
const Measures:=preload("res://scripts/occupation_measures.gd")
const AiMode:=preload("res://scripts/ai_mode.gd")

## The reader must be quick: past this the regex classifier answers instead.
const TIMEOUT_SECONDS:=4.0
const MAX_COMPLETION_TOKENS:=420
const MAX_RESPONSE_BYTES:=32768
## Below this nothing is carried out without asking.
const MIN_CONFIDENCE:=0.6
## A grave, irreversible act needs this much and a certain target.
const GRAVE_CONFIDENCE:=0.8
const PENDING_DAYS:=2
const RECENT_LINES:=6
const MAX_ROSTER:=18
const MAX_CLARIFY_CHARS:=160

const KINDS:=["speech","question","order"]
## Existing person verbs (court_commands.VERBS less the generic ones), what
## becomes of a held town, war objectives, and the business the regex path
## keeps (trade, envoy, civic, order).
const PERSON_ACTIONS:=["kill","maim","exile","detain","penance","terrify","bless","boon","raise","demote","appoint","give","take"]
const WAR_ACTIONS:=["town_fate","town_measure","attack","siege","raid","storm","intercept","pursue","recall","defend","drill"]
## What a garrison may do with the people of a town we hold
## (occupation_measures.gd), and how hard its hand is.
const MEASURE_IDS:=Measures.IDS
const STANCES:=["","lenient","firm","harsh","brutal"]
const LEGACY_ACTIONS:=["send","trade","envoy","civic","order"]
const ACTIONS:=["none"]+PERSON_ACTIONS+WAR_ACTIONS+LEGACY_ACTIONS+["confirm","cancel"]
const TARGET_TYPES:=["person","group","town","people","band","none"]
const DETAIL_FLAGS:=["kill_men","kill_all","captives","raze","tribute","spare","hold","leave","free","full_force"]
const HARM:=["kill","maim"]

const SYSTEM_PROMPT:="""You read what a ruler means in a royal audience of a fictional early society. You do NOT write dialogue. Return only the JSON asked for.
kind: 'question' for a question, 'speech' for talk, thanks, threats without an order, musing; 'order' for any instruction however phrased ('I want you to...', 'go ahead', 'come home').
action: what is ordered. Person acts (kill, maim, exile, detain, penance, terrify, bless, boon, raise, demote, appoint, give, take) fall on ONE person from HALL. town_fate: what becomes of a town WE HOLD and its people (set details). town_measure: what our garrison is to DO with the people of a town WE HOLD while holding it; details.measures lists every measure named: bind_men (round up, tie, bind, chain, detain, lock up, hold under guard), disarm (take or burn their weapons), hostages, curfew (keep them in their houses), search (search the houses), labour (make them work, build walls, clear roads, work fields), requisition (take their food or stores), conscript (take their men into our bands), execute_ringleaders (kill the leaders, make an example), release (free, untie, let go), relief (feed, protect, reward those who help), set_headman (set someone over them), settle (move our families in). details.stance is how hard the hand is: harsh for threats to families or beatings (\"if any resist, threaten their wives\"), brutal for \"kill any who resist\", lenient for gently, else ''. Group acts on a town's people are town_measure, never a person act. attack, siege, raid, storm: war on a FOREIGN town. intercept or pursue: go after their army or band in the field. recall: bring bands home (target a band for one band, none for all). defend: guard home or a place. drill: train first. send, trade, envoy, civic, order: other business. confirm: yes / do it / go ahead to the OPEN QUESTION. cancel: no / wait / leave it, to the OPEN QUESTION. none: not an order.
target.type and target.ref: ref MUST be an id copied from the lists, or '' when none fits. 'him', 'her', 'you' mean a person (the one marked SPEAKING is the one before the ruler). Killing or harming many people (all the men, the villagers, everyone, them all, a town's people, a whole people) is NEVER a person in HALL: use type group (ref = the town or people meant, or ''), town, or people. A town we hold is a town_fate, never an attack.
details: flags for a town's fate (kill_men, kill_all, captives, raze, tribute, spare, hold, leave, free), full_force for 'with everything', count if a number is said, resource for goods named, destination an id or ''.
confidence 0 to 1 for how sure you are of action AND target. If the words are unclear about something grave (killing, maiming, burning a town, going to war, abandoning a town), give low confidence and write clarify: ONE short, plain question the court would ask the ruler (no flattery). Otherwise clarify is ''."""

# --------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------

static func reader_model(voice_model:String)->String:
	## LEVIATHAN_AI_READER_MODEL, else the device setting (ai_mode.cfg), else
	## the voice model itself.
	var env:=OS.get_environment("LEVIATHAN_AI_READER_MODEL").strip_edges()
	if env!="": return env
	var chosen:=AiMode.reader_model()
	return chosen if chosen!="" else voice_model

static func reader_config(config:Dictionary)->Dictionary:
	if config.is_empty(): return {}
	var out:=config.duplicate()
	out["model"]=reader_model(String(config.get("model","")))
	return out

# --------------------------------------------------------------------------
# The world brief
# --------------------------------------------------------------------------

static func world_brief(audience_id:String)->Dictionary:
	## Everything the reader may point at, each with an id:
	## {roster, ours, held, towns, peoples, bands, home_troops, besieging,
	##  pending, recent, ids:{id->type}}.
	var audience:=Hall.find(audience_id)
	var brief:={"roster":[],"ours":[],"held":[],"towns":[],"peoples":[],"bands":[],"home_troops":0,"besieging":"","pending":"","recent":[],"ids":{}}
	var ids:Dictionary=brief.ids
	var list:=CC.roster(audience)
	list.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(bool(a.speaker))*2+int(bool(a.present))>int(bool(b.speaker))*2+int(bool(b.present)))
	for e:Dictionary in list.slice(0,MAX_ROSTER):
		(brief.roster as Array).append({"id":String(e.key),"name":String(e.name),"office":String(e.get("title","")),"speaking":bool(e.speaker),"present":bool(e.present)})
		ids[String(e.key)]="person"
	if WorldSimulation.state!=null:
		for s in WorldSimulation.state.player_settlements:
			if not s is Dictionary: continue
			var sid:="ours:"+String((s as Dictionary).get("id",""))
			(brief.ours as Array).append({"id":sid,"name":String((s as Dictionary).get("name",""))})
			ids[sid]="town"
	if WorldSimulation.military!=null and WorldSimulation.world!=null:
		for t:Dictionary in WarOrders.held_towns():
			var tid:="town:"+String(t.city_id)
			# What the garrison is doing there now (occupation_measures.gd).
			var in_force:Array=[]
			for m:Dictionary in Measures.active(String(t.civ_id),String(t.city_id)): in_force.append(Measures.card_label(m))
			(brief.held as Array).append({"id":tid,"name":String(t.name),"people":String(t.civ_name),"garrison":int(t.garrison),"commander":String(t.commander),"measures":in_force})
			ids[tid]="town"
		for t:Dictionary in WarOrders.known_places():
			var tid:="town:"+String(t.city_id)
			if ids.has(tid): continue
			(brief.towns as Array).append({"id":tid,"name":String(t.name).trim_prefix("Reported home of "),"people":String(t.civ_name)})
			ids[tid]="town"
		for c:Dictionary in WorldSimulation.world.civilizations:
			var cid:=String(c.get("id",""))
			if cid=="" or cid=="player": continue
			var rel:Dictionary=c.get("player_relation",{}) if c.get("player_relation") is Dictionary else {}
			if int(rel.get("contact_level",0))<=0 and not bool(rel.get("at_war",false)): continue
			(brief.peoples as Array).append({"id":"people:"+cid,"name":String(c.get("name",cid)),"at_war":bool(rel.get("at_war",false))})
			ids["people:"+cid]="people"
		var mc:Variant=WorldSimulation.military
		brief.home_troops=maxi(0,int((mc.home_army as Dictionary).get("troops",0)))
		for a in mc.field_armies:
			var army:Dictionary=a
			if int(army.get("troops",0))<=0: continue
			var bid:="band:%d" % int(army.get("army_id",0))
			var commander:Dictionary=army.get("commander",{}) if army.get("commander") is Dictionary else {}
			(brief.bands as Array).append({"id":bid,"name":String(army.get("name","")),"troops":int(army.troops),"where":WarOrders._where(army),"status":String(army.get("status","")),"leader":String(commander.get("name",""))})
			ids[bid]="band"
		brief.besieging=String(WarOrders._besieged().get("name",""))
	ids["home"]="town"
	brief.pending=_pending_words(audience)
	var lines:Array=audience.get("lines",[])
	for i in range(maxi(0,lines.size()-RECENT_LINES),lines.size()):
		var line:Dictionary=lines[i]
		(brief.recent as Array).append("%s: %s" % [String(line.get("speaker","")) if String(line.get("role",""))!="narrator" else "(narration)",String(line.get("text","")).substr(0,220)])
	return brief

static func _pending_words(audience:Dictionary)->String:
	var mine:=pending(audience)
	if not mine.is_empty(): return "The court asked \"%s\" about the ruler's order \"%s\"." % [String(mine.get("question","")),String(mine.get("text",""))]
	var p:Dictionary=audience.get("pending_command",{}) if audience.get("pending_command") is Dictionary else {}
	if p.is_empty() or Hall._day()-int(p.get("day",-99))>CC.PENDING_DAYS: return ""
	if bool(p.get("confirm",false)): return "The war leader asked whether to go ahead with: \"%s\"." % String(p.get("text",""))
	if String(p.get("ask",""))=="chase": return "The war leader offered to send men after those who fled; the ruler may say yes (confirm), no (cancel), or name how many (pursue)."
	if String(p.get("ask",""))=="abandon": return "The war leader asked whether to leave the town unguarded and bring its garrison home; yes is confirm, no is cancel."
	if String(p.get("ask",""))=="measure": return "The war leader asked: \"%s\" The ruler may name one of those choices (town_measure or town_fate), say yes (confirm: the first choice), or no (cancel)." % String(p.get("question",""))
	if String(p.get("ask",""))!="": return "The war leader asked the ruler a question about the order \"%s\"; yes is confirm, no is cancel." % String(p.get("text",""))
	if bool(p.get("which_town",false)): return "The war leader asked which town the order \"%s\" is for." % String(p.get("text",""))
	if String(p.get("verb",""))=="war": return "The war leader objected to the order \"%s\"; the ruler may insist." % String(p.get("text",""))
	return "Someone hesitated over the order \"%s\"; the ruler may insist." % String(p.get("text",""))

static func pending(audience:Dictionary)->Dictionary:
	## The reader's own open question in this audience, while fresh.
	var p:Dictionary=audience.get("reader_pending",{}) if audience.get("reader_pending") is Dictionary else {}
	if p.is_empty() or Hall._day()-int(p.get("day",-99))>PENDING_DAYS: return {}
	return p

static func brief_text(brief:Dictionary)->String:
	var out:PackedStringArray=PackedStringArray()
	var rows:PackedStringArray=PackedStringArray()
	for r:Dictionary in brief.roster:
		rows.append("%s = %s%s%s" % [String(r.id),String(r.name),(", "+String(r.office)) if String(r.office)!="" else ""," (SPEAKING, before the ruler)" if bool(r.speaking) else (" (present)" if bool(r.present) else "")])
	out.append("HALL: "+("; ".join(rows) if not rows.is_empty() else "nobody"))
	rows=PackedStringArray()
	for t:Dictionary in brief.ours: rows.append("%s = %s" % [String(t.id),String(t.name)])
	var home_name:=String(WorldSimulation.state.settlement_name) if WorldSimulation.state!=null else ""
	rows.append("home = %s (our home settlement)" % home_name if home_name!="" else "home = our home settlement")
	out.append("OUR TOWNS: "+"; ".join(rows))
	rows=PackedStringArray()
	for t:Dictionary in brief.held: rows.append("%s = %s (%s town; our garrison %d%s%s)" % [String(t.id),String(t.name),String(t.people),int(t.garrison),(", under "+String(t.commander)) if String(t.commander)!="" else "",
		("; in force: "+", ".join(PackedStringArray(t.get("measures",[])))) if not (t.get("measures",[]) as Array).is_empty() else ""])
	out.append("TOWNS WE HOLD: "+("; ".join(rows) if not rows.is_empty() else "none"))
	rows=PackedStringArray()
	for t:Dictionary in brief.towns: rows.append("%s = %s (%s)" % [String(t.id),String(t.name),String(t.people)])
	out.append("FOREIGN TOWNS WE KNOW: "+("; ".join(rows) if not rows.is_empty() else "none"))
	rows=PackedStringArray()
	for p:Dictionary in brief.peoples: rows.append("%s = %s (%s)" % [String(p.id),String(p.name),"AT WAR with us" if bool(p.at_war) else "at peace"])
	out.append("PEOPLES: "+("; ".join(rows) if not rows.is_empty() else "none known"))
	rows=PackedStringArray()
	for b:Dictionary in brief.bands: rows.append("%s = %s, %d fighters, %s%s" % [String(b.id),String(b.name),int(b.troops),String(b.where),(", led by "+String(b.leader)) if String(b.leader)!="" else ""])
	out.append("OUR BANDS: "+("; ".join(rows) if not rows.is_empty() else "none in the field")+". Trained at home: %d." % int(brief.home_troops))
	if String(brief.besieging)!="": out.append("WE ARE BESIEGING: "+String(brief.besieging))
	out.append("OPEN QUESTION: "+(String(brief.pending) if String(brief.pending)!="" else "none"))
	if not (brief.recent as Array).is_empty(): out.append("LAST LINES:\n"+"\n".join(PackedStringArray(brief.recent)))
	return "\n".join(out)

# --------------------------------------------------------------------------
# The call
# --------------------------------------------------------------------------

static func build_payload(text:String,brief:Dictionary,config:Dictionary)->Dictionary:
	var said:=text.strip_edges().replace("\n"," ").substr(0,400)
	var payload:={"model":String(config.get("model","")),"max_completion_tokens":MAX_COMPLETION_TOKENS,"messages":[
		{"role":"system","content":SYSTEM_PROMPT},
		{"role":"user","content":brief_text(brief)+"\nTHE RULER SAYS: <<%s>>" % said}]}
	if "api.openai.com" in String(config.get("endpoint","")).to_lower(): payload["reasoning_effort"]="low"
	if bool(config.get("structured_output",false)): payload["response_format"]=response_format(brief)
	return payload

static func response_format(brief:Dictionary)->Dictionary:
	var refs:Array=[""]
	var people:Array=[""]
	for id:String in (brief.ids as Dictionary):
		refs.append(id)
		if String(brief.ids[id])=="person": people.append(id)
	var details:={}
	for flag:String in DETAIL_FLAGS: details[flag]={"type":"boolean"}
	details["count"]={"type":"integer"}
	details["resource"]={"type":"string"}
	details["destination"]={"type":"string","enum":refs}
	details["measures"]={"type":"array","items":{"type":"string","enum":MEASURE_IDS}}
	details["stance"]={"type":"string","enum":STANCES}
	return {"type":"json_schema","json_schema":{"name":"order_reading","strict":true,"schema":{
		"type":"object","additionalProperties":false,"required":["kind","action","actor","target","details","confidence","clarify"],
		"properties":{
			"kind":{"type":"string","enum":KINDS},
			"action":{"type":"string","enum":ACTIONS},
			"actor":{"type":"string","enum":people},
			"target":{"type":"object","additionalProperties":false,"required":["type","ref"],"properties":{"type":{"type":"string","enum":TARGET_TYPES},"ref":{"type":"string","enum":refs}}},
			"details":{"type":"object","additionalProperties":false,"required":details.keys(),"properties":details},
			"confidence":{"type":"number"},
			"clarify":{"type":"string"}}}}}

static func parse(body:PackedByteArray)->Dictionary:
	var parser:=JSON.new()
	if parser.parse(body.get_string_from_utf8())!=OK or not parser.data is Dictionary: return {}
	var envelope:Dictionary=parser.data
	if envelope.has("action") and envelope.has("kind"): return envelope
	var content:=""
	var choices:Variant=envelope.get("choices",[])
	if choices is Array and not (choices as Array).is_empty() and choices[0] is Dictionary:
		var message:Variant=(choices[0] as Dictionary).get("message",{})
		if message is Dictionary: content=PronouncementInterpreter._content_text((message as Dictionary).get("content",""))
	if content.is_empty(): content=PronouncementInterpreter._content_text(envelope.get("output_text",""))
	var first:=content.find("{"); var last:=content.rfind("}")
	if first<0 or last<=first: return {}
	var inner:=JSON.new()
	if inner.parse(content.substr(first,last-first+1))!=OK or not inner.data is Dictionary: return {}
	return inner.data

static func validate(raw:Dictionary,brief:Dictionary)->Dictionary:
	## The reading as the engine may use it, or {"rejected": why}. Every id
	## must be one we supplied, of the kind its type says.
	if raw.is_empty(): return {"rejected":"no reading"}
	var kind:=String(raw.get("kind",""))
	var action:=String(raw.get("action",""))
	if not kind in KINDS: return {"rejected":"unknown kind"}
	if not action in ACTIONS: return {"rejected":"unknown action"}
	var ids:Dictionary=brief.get("ids",{})
	var target:Dictionary=raw.get("target",{}) if raw.get("target") is Dictionary else {}
	var ttype:=String(target.get("type","none"))
	var ref:=String(target.get("ref","")).strip_edges()
	if not ttype in TARGET_TYPES: return {"rejected":"unknown target type"}
	if ref!="":
		if not ids.has(ref): return {"rejected":"target not in the lists"}
		var of:=String(ids[ref])
		match ttype:
			"person": if of!="person": return {"rejected":"target is not a person"}
			"town": if of!="town": return {"rejected":"target is not a town"}
			"people": if of!="people": return {"rejected":"target is not a people"}
			"band": if of!="band": return {"rejected":"target is not a band"}
			"group": if not of in ["town","people"]: return {"rejected":"a group is a town or a people, never a person"}
			"none": ref=""
	var actor:=String(raw.get("actor","")).strip_edges()
	if actor!="" and String(ids.get(actor,""))!="person": return {"rejected":"actor not in the hall"}
	var conf:Variant=raw.get("confidence",0.0)
	var details_in:Dictionary=raw.get("details",{}) if raw.get("details") is Dictionary else {}
	var details:={}
	for flag:String in DETAIL_FLAGS:
		if bool(details_in.get(flag,false)): details[flag]=true
	var count:Variant=details_in.get("count",0)
	if (count is int or count is float) and int(count)>0: details["count"]=clampi(int(count),1,100000)
	var dest:=String(details_in.get("destination",""))
	if dest!="" and ids.has(dest): details["destination"]=dest
	var res:=String(details_in.get("resource","")).strip_edges().substr(0,40)
	if res!="": details["resource"]=res
	# Measures and stance come only from their lists: anything else is refused.
	var measures_in:Variant=details_in.get("measures",[])
	if not measures_in is Array: return {"rejected":"measures is not a list"}
	var measures:Array[String]=[]
	for m in measures_in:
		if not m is String or not String(m) in MEASURE_IDS: return {"rejected":"unknown measure"}
		if not measures.has(String(m)): measures.append(String(m))
	if not measures.is_empty(): details["measures"]=measures
	var stance:=String(details_in.get("stance","")) if details_in.get("stance","") is String else "?"
	if not stance in STANCES: return {"rejected":"unknown stance"}
	if stance!="": details["stance"]=stance
	var clarify:=String(raw.get("clarify","")).strip_edges().replace("\n"," ").substr(0,MAX_CLARIFY_CHARS)
	return {"kind":kind,"action":action,"actor":actor,"type":ttype,"ref":ref,"details":details,
		"confidence":clampf(float(conf) if (conf is float or conf is int) else 0.0,0.0,1.0),"clarify":clarify}

# --------------------------------------------------------------------------
# Deciding
# --------------------------------------------------------------------------

static func grave(reading:Dictionary)->bool:
	var action:=String(reading.get("action",""))
	var d:Dictionary=reading.get("details",{})
	if action in HARM or action in ["attack","siege","raid","storm"]: return true
	if action=="town_fate": return bool(d.get("kill_men",false)) or bool(d.get("kill_all",false)) or bool(d.get("raze",false)) or bool(d.get("captives",false)) or bool(d.get("leave",false))
	if action=="town_measure": return (d.get("measures",[]) as Array).any(func(m:Variant)->bool: return String(m) in Measures.GRAVE) or String(d.get("stance",""))=="brutal"
	return false

static func _held_by_ref(ref:String)->Dictionary:
	if not ref.begins_with("town:"): return {}
	for t:Dictionary in WarOrders.held_towns():
		if "town:"+String(t.city_id)==ref: return t
	return {}

static func _place_by_ref(ref:String)->Dictionary:
	if not ref.begins_with("town:"): return {}
	for t:Dictionary in WarOrders.known_places():
		if "town:"+String(t.city_id)==ref: return t
	return {}

static func _held_of(civ_id:String)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	for t:Dictionary in WarOrders.held_towns():
		if String(t.civ_id)==civ_id: out.append(t)
	return out

static func certain(reading:Dictionary)->bool:
	## Is the target of this reading settled beyond doubt?
	var action:=String(reading.get("action",""))
	var ttype:=String(reading.get("type","none"))
	var ref:=String(reading.get("ref",""))
	if action in PERSON_ACTIONS and not action in HARM: return true
	if action in HARM and ttype in ["person","none"]: return ttype=="person" and ref!=""
	if action in HARM or action in ["town_fate","town_measure"]:
		if ref.begins_with("town:"): return true
		if ref.begins_with("people:"): return _held_of(ref.trim_prefix("people:")).size()<=1
		return WarOrders.held_towns().size()==1
	if action in ["attack","siege","raid"]: return ref.begins_with("town:") or ref.begins_with("people:")
	if action=="storm": return not WarOrders._besieged().is_empty() or ref.begins_with("town:")
	return true

static func decide(audience_id:String,text:String,reading:Dictionary,confirmed:bool=false)->Dictionary:
	## One plan from a validated reading (see the header).
	var audience:=Hall.find(audience_id)
	if reading.is_empty() or reading.has("rejected") or audience.is_empty(): return {"route":"legacy","why":String(reading.get("rejected","no reading"))}
	var action:=String(reading.action)
	var kind:=String(reading.kind)
	var conf:=float(reading.confidence)
	var mine:=pending(audience)
	var theirs:Dictionary=audience.get("pending_command",{}) if audience.get("pending_command") is Dictionary else {}
	if not theirs.is_empty() and Hall._day()-int(theirs.get("day",-99))>CC.PENDING_DAYS: theirs={}
	if action=="confirm":
		if not mine.is_empty():
			var stored:Dictionary=mine.get("reading",{})
			var plan:=decide(audience_id,String(mine.get("text","")),stored,true)
			plan["text"]=String(mine.get("text",""))
			plan["clear_pending"]=true
			return plan
		if bool(theirs.get("confirm",false)): return {"route":"engine","context":{"confirm":true,"reader":true}}
		# The war leader's own question ("Shall I send some after them?",
		# "Leave Tsaren unguarded?"): the court's answer reading takes the words.
		if String(theirs.get("ask",""))!="": return {"route":"engine","context":{"reader":true}}
		if not theirs.is_empty(): return {"route":"engine","context":{"insist":true,"reader":true}}
		return {"route":"speak"}
	if action=="cancel":
		if String(theirs.get("ask",""))!="": return {"route":"engine","context":{"reader":true}}
		return {"route":"speak","clear_pending":true}
	# The war leader put one question about a town we hold: an answer that is
	# no order of its own goes to him, and an unclear one is taken as his own
	# nearest reading (court_war_orders.pending_answer), never asked again.
	if String(theirs.get("ask",""))=="measure" and kind!="question" and (kind!="order" or action=="none"): return {"route":"engine","context":{"reader":true}}
	if kind!="order" or action=="none": return {"route":"speak"}
	# The captives and spoils of our last fight (or the standing word for the
	# next) are read by the war orders' own words, whatever the reading named.
	var captive:=WarOrders.captive_reading(text)
	if not captive.is_empty() and WarOrders.captive_applies(captive): return _war_plan(captive)
	if action in LEGACY_ACTIONS: return {"route":"legacy","why":"not the reader's business"}
	var is_grave:=grave(reading)
	var sure:=certain(reading)
	if not confirmed and (conf<MIN_CONFIDENCE or (is_grave and (conf<GRAVE_CONFIDENCE or not sure))):
		var question:=String(reading.get("clarify",""))
		if question=="" or not question.ends_with("?"): question=default_question(reading)
		if not mine.is_empty():
			# We asked already and the answer is still unclear. About a town's
			# people, the reading we asked about stands (a harm aimed at one
			# person never does); otherwise we ask differently, never the same.
			var stored:Dictionary=mine.get("reading",{})
			var stored_action:=String(stored.get("action",""))
			if stored_action in ["town_fate","town_measure"] or (stored_action in HARM and String(stored.get("type",""))!="person" and String(stored.get("type",""))!="none"):
				var plan:=decide(audience_id,String(mine.get("text","")),stored,true)
				plan["text"]=String(mine.get("text",""))
				plan["clear_pending"]=true
				plan["nearest"]=true
				return plan
			if question==String(mine.get("question","")): question="I still cannot tell what you want done, or to whom. Say it plainly, with the name, and it is done."
		return {"route":"clarify","question":question,"pending":{"text":text.substr(0,300),"reading":reading.duplicate(true),"day":Hall._day(),"question":question}}
	if confirmed and is_grave and not sure and String(reading.get("type",""))=="person":
		return {"route":"legacy","why":"still no one named"}
	return _engine_plan(audience,text,reading,theirs)

static func _engine_plan(audience:Dictionary,text:String,reading:Dictionary,theirs:Dictionary)->Dictionary:
	var action:=String(reading.action)
	var ttype:=String(reading.type)
	var ref:=String(reading.ref)
	var details:Dictionary=reading.details
	var lower:=text.to_lower()
	var base:={"full":bool(details.get("full_force",false)) or WarOrders._has(lower,WarOrders.FULL_WORDS),"insist":WarOrders._has(lower,WarOrders.INSIST_WORDS),"place":"","army_words":true,"text":text.substr(0,300),"reader":true}
	# Harm to many is a town's fate (or a town to be taken first): never a person.
	if action in HARM and ttype in ["group","town","people"]:
		return _war_plan(_group_harm(audience,text,action,ref,details,base))
	if action in HARM and ttype!="person": return {"route":"legacy","why":"harm with no one named"}
	if action in PERSON_ACTIONS:
		if ttype in ["group","town","people","band"]: return {"route":"legacy","why":"a person act aimed at many"}
		var live:={"act":"command","verb":action,"actor_ref":String(reading.actor),"target_ref":ref,"object":String(details.get("resource","")),"confidence":float(reading.confidence)}
		if details.has("count"): live.object=("%d %s" % [int(details.count),String(live.object)]).strip_edges()
		return {"route":"engine","context":{"live":live,"reader":true}}
	match action:
		"town_fate":
			if ref.begins_with("town:") and _held_by_ref(ref).is_empty() and not _place_by_ref(ref).is_empty():
				# Their town, not ours: nobody of theirs is in our hands yet.
				var first:=base.duplicate(); first["kind"]="take_first"; first["target"]=_place_by_ref(ref)
				first["fate"]=_fate(lower,details,{}); first["harm"]="kill" if bool((first.fate as Dictionary).get("kill_men",false)) else ""
				return _war_plan(first)
			var town:=_held_by_ref(ref)
			if town.is_empty() and ref.begins_with("people:"):
				var theirs_held:=_held_of(ref.trim_prefix("people:"))
				if theirs_held.size()==1: town=theirs_held[0]
			if town.is_empty() and bool(theirs.get("which_town",false)) and ref.begins_with("town:"): town=_held_by_ref(ref)
			if town.is_empty() and WarOrders.held_towns().size()==1 and ref=="": town=WarOrders.held_towns()[0]
			if town.is_empty():
				var none:=base.duplicate(); none["kind"]="no_town" if WarOrders.held_towns().is_empty() else "which_town"; none["target"]={}
				none["fate"]=_fate(lower,details,theirs)
				var names:Array[String]=[]
				for t:Dictionary in WarOrders.held_towns(): names.append(String(t.name))
				none["towns"]=names
				return _war_plan(none)
			var fate:=_fate(String(Measures.conditions(lower).main),details,theirs)
			if fate.is_empty() or not Measures.read(text).is_empty():
				# Nothing decided about the town itself: what the garrison is to
				# do with its people, or the war leader's nearest reading. Never
				# "it is already ours" to an order that is not an attack.
				return _war_plan(_measure_plan(text,town,details,base))
			var r:=base.duplicate()
			r["kind"]="fate"; r["fate"]=fate
			r["target"]=town
			return _war_plan(r)
		"town_measure":
			var held:=_held_by_ref(ref)
			if held.is_empty() and ref.begins_with("people:"):
				var theirs_held:=_held_of(ref.trim_prefix("people:"))
				if theirs_held.size()==1: held=theirs_held[0]
			if held.is_empty() and WarOrders.held_towns().size()==1: held=WarOrders.held_towns()[0]
			if held.is_empty() and ref.begins_with("town:") and not _place_by_ref(ref).is_empty():
				var first:=base.duplicate(); first["kind"]="take_first"; first["target"]=_place_by_ref(ref); first["fate"]={}; first["harm"]=""
				var ids:Array=details.get("measures",[])
				first["deed"]=String(WarOrders.MEASURE_DEEDS.get(String(ids[0]) if not ids.is_empty() else "","deal with its people"))
				return _war_plan(first)
			if held.is_empty():
				var none:=base.duplicate(); none["kind"]="no_town" if WarOrders.held_towns().is_empty() else "which_town"; none["target"]={}; none["fate"]={}
				var names:Array[String]=[]
				for t:Dictionary in WarOrders.held_towns(): names.append(String(t.name))
				none["towns"]=names; none["measures"]=(details.get("measures",[]) as Array).duplicate()
				return _war_plan(none)
			return _war_plan(_measure_plan(text,held,details,base))
		"attack","siege","raid":
			var r:=base.duplicate(); r["kind"]=action; r["target"]=_foreign_target(ref)
			# By night, and with how many: the same words as offline.
			if details.has("count"): r["count"]=int(details.count)
			WarOrders.strike_manner(r,lower)
			# A town we already hold is not attacked: the war leader says so.
			if bool((r.target as Dictionary).get("held",false)): r["kind"]="held"
			return _war_plan(r)
		"storm":
			var besieged:=WarOrders._besieged()
			var r:=base.duplicate(); r["kind"]="storm" if not besieged.is_empty() else "attack"; r["target"]=besieged if not besieged.is_empty() else _foreign_target(ref)
			return _war_plan(r)
		"intercept","pursue":
			# Men who fled a town we hold: the chase is real (pursuit.gd).
			var held_id:=String(_held_by_ref(ref).get("city_id","")) if ref.begins_with("town:") else ""
			var flight:=preload("res://scripts/pursuit.gd").latest_flight(held_id)
			if action=="pursue" and not flight.is_empty():
				var chase:=base.duplicate(); chase["kind"]="pursue"; chase["target"]=WarOrders._held_town(String(flight.region_id)); chase["count"]=int((reading.get("details",{}) as Dictionary).get("count",0))
				return _war_plan(chase)
			var r:=base.duplicate(); r["kind"]="intercept"
			var civ:=""
			if ref.begins_with("people:"): civ=ref.trim_prefix("people:")
			elif ref.begins_with("town:"): civ=String(_place_by_ref(ref).get("civ_id",_held_by_ref(ref).get("civ_id","")))
			r["target"]={"civ_id":civ} if civ!="" else {}
			if ref.begins_with("band:"): r["army_id"]=int(ref.trim_prefix("band:"))
			return _war_plan(r)
		"recall":
			var r:=base.duplicate(); r["kind"]="recall"; r["target"]={}
			if ref.begins_with("band:"): r["army_id"]=int(ref.trim_prefix("band:"))
			# Home, or back to the town they came from; and whether garrisons are meant.
			var home_name:=String(WorldSimulation.state.settlement_name).to_lower() if WorldSimulation.state!=null else ""
			r["home"]=WarOrders._has(lower,"(home|withdraw|retreat|recall)") or (home_name!="" and WarOrders._name_hit(lower,home_name))
			r["garrison"]=WarOrders._has(lower,"(garrisons?|every ?one|every ?body|all of (you|them)|them all|you all|every soldier|all our|all the)")
			return _war_plan(r)
		"defend":
			var r:=base.duplicate(); r["kind"]="defend"; r["target"]={}
			return _war_plan(r)
		"drill":
			var r:=base.duplicate(); r["kind"]="drill"; r["target"]={}
			return _war_plan(r)
	return {"route":"legacy","why":"no engine mapping"}

static func _war_plan(reading:Dictionary)->Dictionary:
	return {"route":"engine","context":{"war_reading":reading,"reader":true}}

static func _measure_plan(text:String,town:Dictionary,details:Dictionary,base:Dictionary)->Dictionary:
	## The reader's measures (ids from the list only) with what the words
	## themselves carry: who, the work, a count, a name, a condition. Nothing
	## named at all: the war leader's nearest reading ("town_word").
	var lower:=text.to_lower()
	var words:=Measures.read(text)
	var main:=String(Measures.conditions(lower).main)
	var measure:Dictionary=words.duplicate(true) if not words.is_empty() else {"measures":[],"stance":"firm","stance_set":false,"families":false,"clause":"","who":"men","work":"","count":0,"headman":"","release":[],"destroy":false,"heavy":false,"people":false,"pronoun":false,"consumes":[]}
	var ids:Array[String]=[]
	for id in (details.get("measures",[]) as Array): ids.append(String(id))
	if ids.is_empty():
		for id in (measure.measures as Array): ids.append(String(id))
	measure["measures"]=ids
	var stance:=String(details.get("stance",""))
	if stance!="": measure["stance"]=stance; measure["stance_set"]=true
	if details.has("count"): measure["count"]=int(details.count)
	measure["words"]=text
	var r:=base.duplicate()
	r["target"]=town
	if ids.is_empty() and not bool(measure.stance_set):
		var fate:=_fate(main,details,{})
		if not fate.is_empty():
			r["kind"]="fate"; r["fate"]=fate
			return r
		r["kind"]="town_word"
		return r
	var reading:=WarOrders._measure_reading(text,main,town,measure,false)
	if reading.is_empty():
		r["kind"]="town_word"
		return r
	# Fate flags the reader named beside the measures ("round up the men and
	# kill them"), less those the measures already explain.
	var fate:Dictionary=(reading.get("fate",{}) as Dictionary).duplicate()
	for flag in ["kill_men","kill_all","captives","raze","tribute","leave","free"]:
		if bool(details.get(flag,false)) and not (measure.get("consumes",[]) as Array).has(flag): fate[flag]=true
	reading["fate"]=fate
	reading.merge({"reader":true,"insist":bool(base.get("insist",false)),"full":bool(base.get("full",false))},true)
	return reading

static func _foreign_target(ref:String)->Dictionary:
	if ref.begins_with("town:"):
		var held:=_held_by_ref(ref)
		if not held.is_empty(): return held
		return _place_by_ref(ref)
	if ref.begins_with("people:"):
		var civ:=ref.trim_prefix("people:")
		var best:=WarOrders._primary_place(WarOrders.known_places(),civ)
		if not best.is_empty(): return best
		return {"unknown":Hall._civ_name(civ),"civ_id":civ}
	return {}

static func _fate(lower:String,details:Dictionary,theirs:Dictionary)->Dictionary:
	var fate:=TownFate.fate_words(lower).duplicate()
	for flag:String in ["kill_men","kill_all","captives","raze","tribute","spare","hold","leave","free"]:
		if bool(details.get(flag,false)): fate[flag]=true
	if bool(fate.get("kill_all",false)): fate["kill_men"]=true
	if bool(fate.get("kill_men",false)): fate.erase("spare")
	if details.has("count"): fate["count"]=int(details.count)
	if fate.is_empty() and theirs.get("fate") is Dictionary: fate=(theirs.fate as Dictionary).duplicate()
	return fate

static func _group_harm(audience:Dictionary,text:String,verb:String,ref:String,details:Dictionary,base:Dictionary)->Dictionary:
	## Harm to a people or a town's people: that town's fate when we hold it,
	## the town to be taken first when it is theirs, else what the engine
	## reads from the words (which town / we hold none). Never {} and never a
	## person.
	var town:=_held_by_ref(ref)
	if town.is_empty() and ref.begins_with("people:"):
		var held:=_held_of(ref.trim_prefix("people:"))
		if held.size()==1: town=held[0]
	# "Kill the ringleaders", "kill any who run": a measure or a standing word
	# to the garrison, never every man in the town.
	var words:=Measures.read(text)
	if not words.is_empty() and ((words.measures as Array).has("execute_ringleaders") or String(words.get("clause",""))!=""):
		var at:=town
		if at.is_empty() and WarOrders.held_towns().size()==1: at=WarOrders.held_towns()[0]
		if not at.is_empty(): return _measure_plan(text,at,{},base)
	var fate:=_fate(String(Measures.conditions(text.to_lower()).main),details,{})
	if verb=="kill": fate["kill_men"]=true
	fate["group"]=true
	var out:=base.duplicate(); out["fate"]=fate; out["harm"]=verb; out["group_harm"]=true
	if not town.is_empty():
		out["kind"]="fate" if verb=="kill" else "group_maim"; out["target"]=town
		return out
	var foreign:=_foreign_target(ref)
	if foreign.has("city_id") or foreign.has("unknown"):
		out["kind"]="take_first"; out["target"]=foreign
		return out
	var own:=WarOrders.group_harm_reading(text,verb,"",String(audience.get("civ_id","")),String(audience.get("id","")))
	own["reader"]=true
	return own

static func default_question(reading:Dictionary)->String:
	var action:=String(reading.get("action",""))
	var ref:=String(reading.get("ref",""))
	var name:=_ref_name(ref)
	if action in HARM and String(reading.get("type",""))=="person":
		return "Whom do you mean? Name them and it is done." if name=="" else "You mean %s? Say yes and it is done." % name
	if action in HARM or action=="town_fate":
		var what:=_fate_phrase(reading)
		return ("Which town's people do you mean, and what is to be done: %s?" % what) if name=="" else ("%s: %s. Is that your word?" % [name,what.capitalize() if what=="" else what])
	if action in ["attack","siege","raid","storm"]:
		return "Which town do we march on?" if name=="" else "March on %s now? Say yes and we go." % name
	if action=="town_measure":
		var shorts:PackedStringArray=PackedStringArray()
		for id in ((reading.get("details",{}) as Dictionary).get("measures",[]) as Array):
			shorts.append(String((Measures.CATALOGUE.get(String(id),{}) as Dictionary).get("short",id)))
		var what:=" and ".join(shorts) if not shorts.is_empty() else "deal harshly with any who resist"
		return ("Which town's people do you mean? I will %s there once you say." % what) if name=="" else ("In %s, %s. Is that your word?" % [name,what])
	return "What would you have done?"

static func _fate_phrase(reading:Dictionary)->String:
	var d:Dictionary=reading.get("details",{})
	var parts:PackedStringArray=PackedStringArray()
	if bool(d.get("kill_all",false)): parts.append("put everyone to death")
	elif bool(d.get("kill_men",false)) or String(reading.get("action",""))=="kill": parts.append("put the men to death")
	if bool(d.get("captives",false)): parts.append("take captives")
	if bool(d.get("raze",false)): parts.append("burn it")
	if bool(d.get("leave",false)): parts.append("leave it")
	return " and ".join(parts) if not parts.is_empty() else "what is to become of it"

static func _ref_name(ref:String)->String:
	if ref=="": return ""
	if ref.begins_with("town:"):
		var t:=_held_by_ref(ref)
		if t.is_empty(): t=_place_by_ref(ref)
		return String(t.get("name","")).trim_prefix("Reported home of ")
	if ref.begins_with("people:"): return Hall._civ_name(ref.trim_prefix("people:"))
	return ""

# --------------------------------------------------------------------------
# Carrying out a plan (the modal and the tests share this)
# --------------------------------------------------------------------------

static func carry_out(audience_id:String,text:String,plan:Dictionary,context:Dictionary={})->Dictionary:
	## Engine and clarify plans are acted on here; speak and legacy are the
	## caller's (they need the voice or the regex path). Returns
	## {route, result?, question?}. context carries terrain / civic_settlement.
	var audience:=Hall.find(audience_id)
	var route:=String(plan.get("route","legacy"))
	if audience.is_empty(): return {"route":"legacy"}
	if bool(plan.get("clear_pending",false)): audience.erase("reader_pending")
	match route:
		"clarify":
			audience["reader_pending"]=(plan.get("pending",{}) as Dictionary).duplicate(true)
			var question:=String(plan.get("question",""))
			var speaker:Dictionary=audience.get("speaker",{}) if audience.get("speaker") is Dictionary else {}
			var line:={"speaker":"","role":"narrator","person_id":0,"civ_id":"","text":question,"day":Hall._day(),"aside":false}
			if String(audience.get("origin",""))=="court" and String(speaker.get("name",""))!="":
				line={"speaker":String(speaker.name),"role":"official","person_id":int(speaker.get("person_id",0)),"civ_id":"player","text":question,"day":Hall._day(),"aside":false}
			Hall.append_line(audience_id,line)
			return {"route":"clarify","question":question}
		"engine":
			var ctx:=context.duplicate()
			ctx.merge(plan.get("context",{}) as Dictionary,true)
			ctx["echoed"]=true
			var said:=String(plan.get("text",text))
			var heard:=CC.hear(audience_id,said,ctx)
			if bool(heard.get("handled",false)): audience.erase("reader_pending")
			return {"route":"engine","result":heard}
		"speak":
			return {"route":"speak"}
	return {"route":"legacy"}

static func offline_confirm(audience_id:String,text:String)->Dictionary:
	## The reader failed on an answer to its own question: a plain "yes"
	## still carries the order it asked about (read then), a plain "no"
	## drops it. {} when there is no such question or these are other words.
	var audience:=Hall.find(audience_id)
	var mine:=pending(audience)
	if mine.is_empty(): return {}
	var re:=RegEx.new(); re.compile(CC.CONFIRM_PATTERN)
	if re.search(text.strip_edges())!=null or CC._re(CC.INSIST_PATTERN).search(text.strip_edges())!=null:
		var plan:=decide(audience_id,String(mine.get("text","")),mine.get("reading",{}),true)
		plan["text"]=String(mine.get("text",""))
		plan["clear_pending"]=true
		return plan
	var no:=RegEx.new(); no.compile("(?i)^\\s*(no|nay|not yet|wait|hold|stop|leave it|never mind|forget it|don't|do not)\\b")
	if no.search(text)!=null: return {"route":"speak","clear_pending":true}
	return {}
