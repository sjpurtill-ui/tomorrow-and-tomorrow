extends RefCounted
## THE COURT EVALUATION: does the court listen, and do the correct thing?
##
## Drives the REAL court (scripts/hud/audience_modal.gd: _speak(), exactly the
## player's path, with its voice audience_voice.gd) through every case in
## cases.json, on three paths:
##   offline  no live model: the predetermined, state-driven path;
##   live     a live model stubbed at the transport: the order reader returns
##            the case's IDEAL structured reading (order_reader.gd schema) and
##            every voice prompt is kept (nothing leaves the machine);
##   sloppy   grave group orders only (and grave words that are a law at home,
##            case key sloppy_words): the reader wrongly names the one before
##            the ruler as the victim; the guards must still hold.
## A step that summons someone moves the court into their audience, as the
## player's screen does; a live model's mapping of words about people (the
## persons stage) is the step's ideal "persons" action, else plain talk.
## Each step is measured before and after (the town's ledger, bands, garrison,
## captives, stores, officials, aims, dread, the audience's open question) and
## checked against the case's expectations and the standing rules of
## docs/ADJUDICATION.md (see check()). Results are data, never asserts: the
## runner prints the scoreboard.

const Fixtures:=preload("res://tests/court_eval/fixtures.gd")
const RecordingVoice:=preload("res://tests/court_eval/recording_voice.gd")
const Modal:=preload("res://scripts/hud/audience_modal.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const CC:=preload("res://scripts/court_commands.gd")
const WO:=preload("res://scripts/court_war_orders.gd")
const OR:=preload("res://scripts/order_reader.gd")
const Ledger:=preload("res://scripts/town_ledger.gd")
const Facts:=preload("res://scripts/court_facts.gd")
const Pursuit:=preload("res://scripts/pursuit.gd")
const Aims:=preload("res://scripts/legacy_aims.gd")
const Divine:=preload("res://scripts/divine_regard.gd")
const Measures:=preload("res://scripts/occupation_measures.gd")
const Persons:=preload("res://scripts/court_persons.gd")

const PATHS:=["offline","live","sloppy"]
## A fake key: it must never appear in a prompt, a line or a receipt.
const SECRET:="sk-court-eval-NOT-A-KEY-0000"
const ENDPOINT:="https://mock.invalid/v1/chat/completions"

## Words that claim ignorance of something the court has counted.
const IGNORANCE:=["i don't know","i do not know","don't know that","nobody has counted","no one has counted","no one has a count","nobody has a count","i won't guess","will not guess",
	"i'll ask","i will ask","i'd have to ask","i must ask","let me ask","nobody's brought","nobody has brought","no one has brought","no one's brought","don't have their number","do not have their number",
	"i can't tell you","i cannot tell you","can't say how many","cannot say how many","i have no count","haven't counted","have not counted","no count of","not been counted","who can say",
	"nothing i'd swear to","give me a few days","ask around","not my part of the work","i can find out","i could find out","don't know enough","not sure what you want"]
## Words that claim an order was, or will surely be, carried out.
const DONE_CLAIMS:=["it is done","it's done","it'll be done","it will be done","it shall be done","consider it done","has been done","carried out","i'll see it done","i will see it done","see it done","see it started","as you command, it","done, as you"]
## Words that say nothing was done.
const NOTHING_WORDS:=["nothing is set in motion","nothing is done","no one marches","nobody marches","nothing is changed","nothing more is done","nobody goes after them","nothing was done"]
## The line for a person-order that landed on nobody.
const STRAY:="nobody here answers to that"

var suite:Node
var fx:Fixtures
var cases:Array[Dictionary]=[]
var load_errors:PackedStringArray=PackedStringArray()
## The audience the last run() ended in (a summons moves the court to the one brought in).
var last_id:=""

func _init(test_suite:Node)->void:
	suite=test_suite
	fx=Fixtures.new(test_suite)

# --------------------------------------------------------------------------
# Cases
# --------------------------------------------------------------------------

const CASE_KEYS:=["id","domain","fixture","speaker","source","sloppy","paths","steps","say","ideal","expect","variants","note","sloppy_expect","sloppy_words"]
const STEP_KEYS:=["say","ideal","expect","note"]
const EXPECT_KEYS:=["route","handled","verb","kind","verdict","stage","target","harm_ok","state","reply_has","reply_any","reply_lacks","says_has","says_any","says_lacks","prompt_has","prompt_any","known","asks","aim_ok","allow_stray","allow_done","offline","live","sloppy","when_verdict"]
const IDEAL_KEYS:=["kind","action","type","ref","actor","details","confidence","clarify","persons"]

func load_cases(path:String)->void:
	cases.clear(); load_errors.clear()
	var text:=FileAccess.get_file_as_string(path)
	var parser:=JSON.new()
	if parser.parse(text)!=OK:
		load_errors.append("cases.json: %s at line %d" % [parser.get_error_message(),parser.get_error_line()]); return
	var data:Variant=parser.data
	var raw:Array=(data as Dictionary).get("cases",[]) if data is Dictionary else []
	var seen:={}
	for c in raw:
		if not c is Dictionary: load_errors.append("a case is not an object"); continue
		for key in (c as Dictionary):
			if not String(key) in CASE_KEYS: load_errors.append("%s: unknown key %s" % [String(c.get("id","?")),String(key)])
		var base:Dictionary=(c as Dictionary).duplicate(true)
		var steps:Array=base.get("steps",[])
		if steps.is_empty():
			steps=[{"say":String(base.get("say","")),"ideal":base.get("ideal",null),"expect":base.get("expect",{})}]
		base.erase("say"); base.erase("ideal"); base.erase("expect")
		base["steps"]=steps
		var expanded:Array[Dictionary]=[base]
		var variants:Array=base.get("variants",[])
		base.erase("variants")
		var n:=0
		for v in variants:
			n+=1
			var copy:=base.duplicate(true)
			copy["id"]="%s~%d" % [String(base.get("id","")),n]
			copy["source"]="variant"
			var step:Dictionary=(copy.steps[copy.steps.size()-1] as Dictionary).duplicate(true)
			if v is String: step["say"]=String(v)
			elif v is Dictionary:
				for key in (v as Dictionary):
					if key=="expect": step["expect"]=_merged(step.get("expect",{}),(v as Dictionary).expect)
					else: step[key]=(v as Dictionary)[key]
			copy.steps[copy.steps.size()-1]=step
			expanded.append(copy)
		for e in expanded:
			var id:=String(e.get("id",""))
			if id=="" or seen.has(id): load_errors.append("duplicate or empty id: "+id); continue
			seen[id]=true
			if not String(e.get("fixture","")) in Fixtures.NAMES: load_errors.append("%s: unknown fixture %s" % [id,String(e.get("fixture",""))])
			for s in e.steps:
				for key in (s as Dictionary):
					if not String(key) in STEP_KEYS: load_errors.append("%s: unknown step key %s" % [id,String(key)])
				for key in ((s as Dictionary).get("expect",{}) as Dictionary):
					if not String(key) in EXPECT_KEYS: load_errors.append("%s: unknown expect key %s" % [id,String(key)])
				var ideal:Variant=(s as Dictionary).get("ideal",null)
				if ideal is Dictionary:
					for key in (ideal as Dictionary):
						if not String(key) in IDEAL_KEYS: load_errors.append("%s: unknown ideal key %s" % [id,String(key)])
				if String((s as Dictionary).get("say","")).strip_edges()=="": load_errors.append("%s: a step says nothing" % id)
			cases.append(e)

static func _merged(a:Variant,b:Variant)->Dictionary:
	var out:Dictionary=(a as Dictionary).duplicate(true) if a is Dictionary else {}
	if b is Dictionary:
		for key in (b as Dictionary):
			if key=="state" and out.get("state") is Dictionary and (b as Dictionary).state is Dictionary:
				var st:Dictionary=(out.state as Dictionary).duplicate(); st.merge((b as Dictionary).state,true); out["state"]=st
			else: out[key]=(b as Dictionary)[key]
	return out

func paths_of(c:Dictionary)->Array:
	var out:Array=[]
	var allowed:Array=c.get("paths",["offline","live"])
	for p in ["offline","live"]:
		if p in allowed: out.append(p)
	if bool(c.get("sloppy",false)): out.append("sloppy")
	return out

# --------------------------------------------------------------------------
# One case on one path
# --------------------------------------------------------------------------

func run(c:Dictionary,path:String)->Dictionary:
	## {id, path, domain, ok, fails:[{step, code, text}], log:[...]}.
	var out:={"id":String(c.id),"path":path,"domain":String(c.get("domain","")),"source":String(c.get("source","")),"ok":false,"fails":[],"log":[]}
	var w:=fx.use(String(c.fixture))
	if w.has("error"):
		(out.fails as Array).append({"step":0,"code":"fixture","text":String(w.error)}); return out
	# No real service is ever reached and nothing is written to the player's
	# interaction records (the stubbed replies would teach the offline court).
	GameState.civic_api_enabled=false
	preload("res://scripts/ai_mode.gd").set_records_interactions(false,false)
	var voice:=RecordingVoice.new()
	voice.force_offline=path=="offline"
	if path!="offline":
		voice.config_override={"endpoint":ENDPOINT,"api_key":SECRET,"model":"mock-voice","structured_output":true}
		voice.send_hook=Callable(voice,"record_send")
		voice.pick_hook=func(_a:String,_p:Dictionary)->PackedByteArray: return PackedByteArray()
		voice.answer_hook=func(_a:String,_p:Dictionary)->PackedByteArray: return PackedByteArray()
	suite.add_child(voice)
	var id:=fx.audience_for(w,String(c.get("speaker","headman")))
	if id=="":
		(out.fails as Array).append({"step":0,"code":"fixture","text":"nobody to speak to as "+String(c.get("speaker",""))})
		voice.queue_free(); return out
	var modal:Control=Modal.new()
	modal.voice=voice; modal.audience_id=id
	suite.add_child(modal)
	var asked:Array[String]=[]
	var first:=measure(w,id)
	var start_truth:=one_truth(w,first)
	if start_truth!="": (out.fails as Array).append({"step":0,"code":"one_truth","text":"before anything was said: "+start_truth})
	var steps:Array=c.steps
	for i in steps.size():
		var step:Dictionary=steps[i]
		var said:=String(step.say)
		var expect:Dictionary=_merged(step.get("expect",{}),{})
		if expect.get(path) is Dictionary: expect=_merged(expect,expect[path])
		# The sloppy reader only garbles grave orders about many people.
		# sloppy_words: grave words that are no order about a town ("Execute every
		# thief", a law): the careless reader still names the one before the ruler.
		var sloppy:=path=="sloppy" and (_grave_step(step) or bool(c.get("sloppy_words",false)))
		if sloppy: expect=_sloppy_expect(expect,c)
		elif path=="sloppy" and expect.get("live") is Dictionary: expect=_merged(expect,expect.live)
		var before:=measure(w,id)
		var lines_before:=(Hall.find(id).get("lines",[]) as Array).size()
		voice.calls.clear(); voice.prompts.clear()
		var reading:Dictionary={}
		if path!="offline":
			reading=_sloppy_reading(w,String(c.get("speaker","")),step.get("ideal",null)) if sloppy else _reading(step.get("ideal",null),w)
			var body:=_body(reading)
			voice.order_hook=func(_a:String,_p:Dictionary)->PackedByteArray: return body
		# Anything still waiting on the stubbed model (the audience's opening
		# lines) is dropped, as if it had answered, so the ruler can speak.
		voice.drain(id)
		if is_instance_valid(modal) and is_instance_valid(modal.speak_button): modal._refresh_footer()
		var ready:=_ready_to_speak(modal,id)
		if ready!="":
			(out.fails as Array).append({"step":i+1,"code":"cannot_speak","text":ready}); break
		modal.speech_input.text=said
		modal._speak()
		if path!="offline":
			# The stubbed model answers the voice's own reading of the words (the
			# speak stage) and, for words about people, maps them as the case's
			# ideal says (the persons stage), as a live model would; every other
			# request is dropped.
			var serial:=i
			var persons_ideal:=String((step.get("ideal",{}) as Dictionary).get("persons","")) if step.get("ideal") is Dictionary else ""
			voice.answer(func(r:Dictionary)->PackedByteArray: return _voice_reply(r,reading,serial,voice,persons_ideal))
		voice.drain(id)
		if is_instance_valid(modal) and modal.has_method("_refresh_footer") and is_instance_valid(modal.speak_button): modal._refresh_footer()
		var after:=measure(w,id)
		var lines:Array=(Hall.find(id).get("lines",[]) as Array).slice(lines_before)
		# Someone was brought before the ruler (a summons): the court now speaks
		# in their audience, as the player's does; what they said arriving counts.
		var now_id:=String(modal.audience_id) if is_instance_valid(modal) else id
		if now_id!="" and now_id!=id and String(Hall.find(now_id).get("status",""))=="waiting":
			lines=lines+(Hall.find(now_id).get("lines",[]) as Array)
			after["_moved_to"]=now_id
			voice.drain(now_id)
		var answer_only:=step.get("ideal") is Dictionary and String((step.ideal as Dictionary).get("action","")) in ["confirm","cancel"]
		var fails:=check(w,c,path,i+1,said,expect,before,after,lines,voice,asked,answer_only)
		for f in fails: (out.fails as Array).append(f)
		(out.log as Array).append({"say":said,"lines":lines.map(func(l:Dictionary)->String: return "%s: %s" % [String(l.get("speaker","")) if String(l.get("speaker",""))!="" else "(narration)",String(l.get("text",""))]),
			"calls":voice.calls.map(func(k:Dictionary)->String: return _call_words(k)),"prompts":voice.prompts.size(),"changed":changed(before,after)})
		if after.has("_moved_to"): id=String(after._moved_to)
	last_id=id
	modal.queue_free(); voice.queue_free()
	out.ok=(out.fails as Array).is_empty()
	return out

func _ready_to_speak(modal:Control,id:String)->String:
	if not is_instance_valid(modal) or not is_instance_valid(modal.speech_input): return "the court has no place to speak (the audience closed)"
	var audience:=Hall.find(id)
	if String(audience.get("status",""))!="waiting": return "the audience is over (%s)" % String(audience.get("status",""))
	if is_instance_valid(modal.speak_button) and modal.speak_button.disabled: return "the Speak button is disabled"
	return ""

static func _call_words(k:Dictionary)->String:
	match String(k.get("call","")):
		"command":
			var r:Dictionary=k.result
			var war:Dictionary=r.get("war",{}) if r.get("war") is Dictionary else {}
			return "command %s/%s %s%s -> %s" % [String(r.get("verb","")),String(r.get("stage","")),String(war.get("kind","")),("/"+String(war.get("verdict",""))) if not war.is_empty() else "",String(r.get("target_name",""))]
		"read": return "read -> %s %s" % [String(k.get("route","")),String(k.get("why",""))]
		"speak": return "speak%s" % (" (read)" if bool(k.get("read",false)) else "")
		"persons": return "persons"
		"divine": return "divine %s" % String((k.result as Dictionary).get("action",""))
	return String(k.get("call",""))

# --------------------------------------------------------------------------
# Readings for the stubbed live reader
# --------------------------------------------------------------------------

func ref_of(token:String,w:Dictionary)->String:
	## "$tsaren" -> "town:<id>" and so on; anything else as given.
	var info:Dictionary=w.info
	if not token.begins_with("$"): return token
	match token:
		"$tsaren": return "town:"+String(info.get("tsaren_id",""))
		"$stonefield": return "town:"+String(info.get("stonefield_id",""))
		"$eldwick": return "town:"+String(info.get("eldwick_id",""))
		"$esurai": return "people:"+String(info.get("civ_id",""))
		"$varesh": return "people:"+String(info.get("varesh_id",""))
		"$neyali": return "people:"+String(info.get("feud_id",""))
		"$home": return "home"
		"$rovik": return "figure:"+String(info.get("rovik_fid",""))
		"$band": return "band:%d" % int(info.get("band_id",0))
		"$seanstone": return "ours:"+String(GameState.player_settlements[0].get("id","")) if not GameState.player_settlements.is_empty() else "home"
		"$focus":
			# The commoner the court last named or brought in (court_persons.gd).
			var focus:Dictionary=Persons.state().focus.get("person",{}) if Persons.state().focus.get("person") is Dictionary else {}
			return Persons.ref_key(focus) if not focus.is_empty() else ""
	var role:=token.trim_prefix("$")
	var pid:=fx.role_pid(w,role)
	return "person:%d" % pid if pid>0 else token

func _reading(ideal:Variant,w:Dictionary)->Dictionary:
	## The case's ideal reading, in the reader's strict schema. null: the
	## reader timed out (the offline reading decides).
	if not ideal is Dictionary: return {}
	var d:={"kill_men":false,"kill_all":false,"captives":false,"raze":false,"tribute":false,"spare":false,"hold":false,"leave":false,"free":false,"full_force":false,"count":0,"resource":"","destination":"","measures":[],"stance":""}
	var given:Dictionary=(ideal as Dictionary).get("details",{})
	for key in given: d[key]=given[key]
	if String(d.destination).begins_with("$"): d["destination"]=ref_of(String(d.destination),w)
	return {"kind":String(ideal.get("kind","order")),"action":String(ideal.get("action","none")),"actor":ref_of(String(ideal.get("actor","")),w) if String(ideal.get("actor",""))!="" else "",
		"target":{"type":String(ideal.get("type","none")),"ref":ref_of(String(ideal.get("ref","")),w)},"details":d,"confidence":float(ideal.get("confidence",0.95)),"clarify":String(ideal.get("clarify",""))}

func _sloppy_reading(w:Dictionary,speaker:String,ideal:Variant)->Dictionary:
	## A careless reader: the one before the ruler is the victim.
	var ref:="figure:"+String((w.info as Dictionary).get("rovik_fid","")) if speaker=="rovik" else "person:%d" % fx.role_pid(w,speaker)
	var action:="kill"
	if ideal is Dictionary and String((ideal as Dictionary).get("action",""))=="maim": action="maim"
	return _reading({"kind":"order","action":action,"type":"person","ref":ref,"confidence":0.97},w)

static func _grave_step(step:Dictionary)->bool:
	var ideal:Variant=step.get("ideal",null)
	if not ideal is Dictionary: return false
	return String((ideal as Dictionary).get("action","")) in ["kill","maim","town_fate","town_measure"] and String((ideal as Dictionary).get("type",""))!="person"

func _sloppy_expect(expect:Dictionary,c:Dictionary)->Dictionary:
	## On the sloppy path only the guards are judged: nobody here is harmed,
	## and the order stays a war order about the town.
	var out:={"verb":"war","handled":true}
	if c.get("sloppy_expect") is Dictionary: out=_merged(out,c.sloppy_expect)
	return out

## Plain replies for the stubbed voice model (never a claim, never a number,
## never twice in one audience: the voice drops a line said before).
const NEUTRAL_LINES:=["I hear you.","I take your meaning.","Your words are heard.","I follow you.","So I understand it.","I mark what you say.","I have your words.","I hear it plainly."]

func _voice_reply(r:Dictionary,reading:Dictionary,serial:int,voice:Node=null,persons:String="")->PackedByteArray:
	## The stubbed voice model answers the speak stage's own reading of the
	## ruler's words (one plain line and the command it reads, from the same
	## reading the order reader was given) and maps words about people onto the
	## persons engine's menu (the case's ideal "persons" action, else plain talk);
	## anything else goes unanswered.
	if String(r.get("stage",""))=="persons": return _persons_reply(r,serial,voice,persons)
	if String(r.get("stage",""))!="speak" or bool(r.get("read",false)): return PackedByteArray()
	var content:={"lines":[{"speaker_key":"envoy","text":NEUTRAL_LINES[serial%NEUTRAL_LINES.size()],"aside":false}],"mood_shift":0.0,"divine":"none","command":_voice_command(reading)}
	return JSON.stringify({"id":"m","model":"mock-voice","choices":[{"finish_reason":"stop","message":{"role":"assistant","content":JSON.stringify(content)}}],"usage":{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15}}).to_utf8_buffer()

func _persons_reply(r:Dictionary,serial:int,voice:Node,persons:String)->PackedByteArray:
	## A live model's mapping of words about people (court_persons_bridge.gd
	## schema): the menu entry for the ideal action, else "talk". One plain line
	## that names nobody (the engine's own line names whoever it chose).
	var menu:Array=[]
	if voice!=null and voice._requests.has(String(r.id)): menu=((voice._requests[String(r.id)] as Dictionary).get("extra",{}) as Dictionary).get("menu",[])
	var action:=persons if persons!="" else "talk"
	var choice:=-1
	for i in menu.size():
		if String((menu[i] as Dictionary).get("action",""))==action: choice=i; break
	if choice<0 and action!="talk" and not action.begins_with("novel:"): action="talk"
	var content:={"canonical_action":action,"choice":choice,"label":"","deltas":[],"lines":[{"speaker_key":"envoy","text":NEUTRAL_LINES[serial%NEUTRAL_LINES.size()],"aside":false}],
		"reply_template":"","signature":{"role":"official","guilt":"none","lying":"none","band":"wary"},"generalizable":false,"mood_shift":0.0}
	return JSON.stringify({"id":"m","model":"mock-voice","choices":[{"finish_reason":"stop","message":{"role":"assistant","content":JSON.stringify(content)}}],"usage":{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15}}).to_utf8_buffer()

static func changed(before:Dictionary,after:Dictionary)->String:
	## What an order really changed, "key before->after" (for the report).
	var parts:=PackedStringArray()
	for k in after:
		var key:=String(k)
		if key.begins_with("_") or key in ["food_days_exact"]: continue
		if str(before.get(key,""))!=str(after.get(key,"")): parts.append("%s %s->%s" % [key,str(before.get(key,"")),str(after.get(key,""))])
	return ", ".join(parts)

func _voice_command(reading:Dictionary)->Dictionary:
	## The reader's reading in the voice's command schema (court_commands ACTS, VERBS).
	var none:={"act":"statement","verb":"none","actor_ref":"","target_ref":"","object":"","confidence":0.9}
	if reading.is_empty(): return none
	var kind:=String(reading.get("kind","speech"))
	if kind=="question": none.act="question"; return none
	if kind!="order": return none
	var action:=String(reading.get("action","none"))
	var target:Dictionary=reading.get("target",{})
	var ref:=String(target.get("ref",""))
	var details:Dictionary=reading.get("details",{})
	var place:=_ref_words(ref)
	var cmd:={"act":"command","verb":"none","actor_ref":String(reading.get("actor","")),"target_ref":"","object":"","confidence":float(reading.get("confidence",0.9))}
	if action in OR.PERSON_ACTIONS:
		cmd.verb=action
		cmd.target_ref=ref if String(target.get("type",""))=="person" else place
		var res:=String(details.get("resource",""))
		if int(details.get("count",0))>0: res=("%d %s" % [int(details.count),res]).strip_edges()
		cmd.object=res
		return cmd
	if action in OR.WAR_ACTIONS:
		cmd.verb="war"
		var words:=""
		match action:
			"town_fate":
				if bool(details.get("kill_men",false)) or bool(details.get("kill_all",false)): words="kill the men of %s" % place
				elif bool(details.get("raze",false)): words="burn %s" % place
				elif bool(details.get("captives",false)): words="take captives from %s" % place
				elif bool(details.get("leave",false)): words="leave %s" % place
				else: words="deal with %s" % place
			"town_measure": words="round up the men of %s" % place
			"recall": words="march home"
			"pursue": words="chase the men who fled %s" % place
			"drill": words="drill the band"
			_: words="%s %s" % [action,place]
		cmd.object=words.strip_edges()
		return cmd
	if action=="send": cmd.verb="send"; return cmd
	if action in ["order","civic","trade","envoy"]: cmd.verb="order"; return cmd
	return none

func _ref_words(ref:String)->String:
	if ref.begins_with("town:"):
		var id:=ref.trim_prefix("town:")
		for t in WO.held_towns()+WO.known_places():
			if String((t as Dictionary).city_id)==id: return String(t.name).trim_prefix("Reported home of ")
	if ref.begins_with("people:"): return Hall._civ_name(ref.trim_prefix("people:"))
	if ref=="home": return String(GameState.settlement_name)
	return ""

static func _body(reading:Dictionary)->PackedByteArray:
	if reading.is_empty(): return PackedByteArray()
	return JSON.stringify({"model":"mock-reader","choices":[{"finish_reason":"stop","message":{"content":JSON.stringify(reading)}}],"usage":{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15}}).to_utf8_buffer()

# --------------------------------------------------------------------------
# What the world looks like
# --------------------------------------------------------------------------

func measure(w:Dictionary,audience_id:String)->Dictionary:
	var info:Dictionary=w.info
	var civ:=String(info.get("civ_id","")); var city:=String(info.get("tsaren_id",""))
	var m:={"_audience":audience_id}
	if Ledger.has(civ,city):
		var c:=Ledger.counts(civ,city)
		for key in c:
			if c[key] is int or c[key] is float: m[key]=int(c[key])
		m["ledger"]=1
		m["ledger_ok"]=1 if bool(Ledger.check(civ,city).get("ok",false)) else 0
		m["_snap"]=Ledger.snapshot(civ,city)
	else:
		m["ledger"]=0; m["ledger_ok"]=1
	var force:Dictionary=MilitaryCampaign.occupation_force_for_region(civ,city)
	m["garrison"]=int(force.get("troops",0))
	var held:=0
	for t in WO.held_towns():
		if String(t.city_id)==city: held=1
	m["held"]=held
	m["ruin"]=0 if Ledger.our_ruin(city).is_empty() else 1
	var region:=CivilizationSystem.region_snapshot(civ,city)
	m["ours"]=1 if String(region.get("controller",""))=="player" else 0
	m["tsaren_people"]=roundi(float(region.get("population",0.0)))
	var moving:=0; var field:=0; var chase:=0; var to_tsaren:=0; var to_eldwick:=0; var to_stonefield:=0; var going_home:=0
	for a in MilitaryCampaign.field_armies:
		var army:Dictionary=a
		field+=int(army.get("troops",0))
		if String(army.get("status",""))=="moving": moving+=1
		if army.get("pursuit") is Dictionary: chase+=1
		var dest:=String(army.get("destination_id",""))
		# A march the court ordered names its town (court_war_orders._strike).
		var ordered:Dictionary=army.get("court_order",{}) if army.get("court_order") is Dictionary else {}
		var target:=String(ordered.get("city_id",army.get("target_region_id","")))
		if dest==city or target==city: to_tsaren+=1
		if dest==String(info.get("eldwick_id","")) or target==String(info.get("eldwick_id","")): to_eldwick+=1
		if dest==String(info.get("stonefield_id","")) or target==String(info.get("stonefield_id","")): to_stonefield+=1
		if dest=="player_home" and String(army.get("status",""))=="moving": going_home+=1
	m["armies"]=MilitaryCampaign.field_armies.size(); m["moving"]=moving; m["field_troops"]=field; m["chases"]=chase
	m["to_tsaren"]=to_tsaren; m["to_eldwick"]=to_eldwick; m["to_stonefield"]=to_stonefield; m["going_home"]=going_home
	m["home_troops"]=int(MilitaryCampaign.home_army.get("troops",0))
	m["home_morale_x100"]=roundi(float(MilitaryCampaign.home_army.get("morale",0.0))*100.0)
	m["recruits"]=int(MilitaryCampaign.aggregate_recruits)
	m["training"]=MilitaryCampaign.training_queue.size()
	m["equipment_orders"]=MilitaryCampaign.equipment_queue.size()
	m["prisoners"]=int(MilitaryCampaign.foreign_prisoners)
	for res in ["Food","Timber","Stone","Fiber Plants","Forced Labor","Transport Carts"]: m[res.to_lower().replace(" ","_")]=roundi(float(GameState.resource_stockpiles.get(res,0.0)))
	m["spears"]=int(MilitaryCampaign.military_inventory.get("spear",0))
	m["population"]=int(GameState.population_total)
	m["modifiers"]=(GameState.active_modifiers as Array).size()
	m["practice_prisoners"]=String(MilitaryCampaign.aftermath_practice.get("prisoners",""))
	m["practice_spoils"]=String(MilitaryCampaign.aftermath_practice.get("spoils",""))
	m["settlement_prisoners"]=String((MilitaryCampaign.settlements[0] as Dictionary).get("prisoner_policy","")) if not MilitaryCampaign.settlements.is_empty() else ""
	m["settlement_spoils"]=String((MilitaryCampaign.settlements[0] as Dictionary).get("spoils_policy","")) if not MilitaryCampaign.settlements.is_empty() else ""
	var officials:Array=[]
	for p in Hall._officials(): officials.append(int(p.person_id))
	officials.sort()
	m["officials"]=officials.size(); m["_official_ids"]=officials
	for role in ["headman","suri","kavu","imeri"]:
		var pid:=fx.role_pid(w,role)
		var snap:=GovernmentPeopleSystem.person_snapshot(pid) if pid>0 else {}
		m["status_"+role]=String(snap.get("status",""))
		# Which office each holds now (appointed, dismissed, replaced).
		m["office_"+role]=String(snap.get("office_key","")) if String(snap.get("status",""))=="active" else ""
		# How each holds the god (divine_regard.gd): love and dread, x100.
		m["love_"+role]=roundi(Divine.love_of(snap)*100.0) if not snap.is_empty() else 0
		m["dread_"+role]=roundi(Divine.dread_of(snap)*100.0) if not snap.is_empty() else 0
	# The people as a whole: love and dread of the god; legitimacy, cohesion.
	var people:=Divine.people_regard(Hall._officials())
	m["people_love_x100"]=roundi(float(people.get("love",0.0))*100.0)
	m["people_dread_x100"]=roundi(float(people.get("dread",0.0))*100.0)
	m["legitimacy_x100"]=roundi(float(GameState.simulation_metrics.get("legitimacy",0.5))*100.0)
	m["cohesion_x100"]=roundi(float(GameState.simulation_metrics.get("cohesion",0.5))*100.0)
	m["settlement_name"]=String(GameState.settlement_name)
	# The court's known persons (court_persons.gd): the living, the dead and
	# the driven out, who is waiting before the ruler, whom the court spoke of.
	var living:=0; var gone:=0; var bound:=0
	for p in Persons.people():
		var st:=String((p as Dictionary).get("status",""))
		if st=="living": living+=1
		else: gone+=1
		if bool((p as Dictionary).get("bound",false)) and st=="living": bound+=1
	m["known"]=living; m["known_gone"]=gone; m["known_bound"]=bound
	var summoned:=0
	for a in Hall.waiting():
		if String(((a as Dictionary).get("speaker",{}) as Dictionary).get("known_id",""))!="": summoned+=1
	m["summoned"]=summoned
	m["waiting"]=Hall.waiting().size()
	var focus:Dictionary=Persons.state().focus.get("person",{}) if Persons.state().focus.get("person") is Dictionary else {}
	m["focus"]=Persons.ref_name(focus) if not focus.is_empty() else ""
	var here_known:=Persons.speaker_known(audience_id)
	# The one before the ruler when a commoner was brought in (or the one the
	# court last named): their state after the ruler's word.
	if here_known.is_empty() and not focus.is_empty() and String(focus.get("kind",""))=="known": here_known=Persons.by_id(String(focus.get("id","")))
	m["speaker_known"]=String(here_known.get("name","")) if not here_known.is_empty() else ""
	m["speaker_known_status"]=String(here_known.get("status","")) if not here_known.is_empty() else ""
	m["speaker_known_role"]=String(here_known.get("role","")) if not here_known.is_empty() else ""
	var marks:=PackedStringArray()
	for flag in ["bound","maimed","cursed","exalted","flogged"]:
		if bool(here_known.get(flag,false)): marks.append(flag)
	if not (here_known.get("household",{}) as Dictionary).is_empty() and String(((here_known.household as Dictionary).get("spouse",{}) as Dictionary).get("known",""))!="": marks.append("married")
	m["speaker_known_marks"]=",".join(marks)
	m["speaker_known_love"]=roundi(float(here_known.get("love",0.0))*100.0) if not here_known.is_empty() else 0
	m["speaker_known_dread"]=roundi(float(here_known.get("dread",0.0))*100.0) if not here_known.is_empty() else 0
	# Great works raised at the god's word (great_works.gd).
	m["works"]=(load("res://scripts/great_works.gd") as GDScript).call("works","player").size() if ResourceLoader.exists("res://scripts/great_works.gd") else 0
	# The other people we know (at peace): their dread and their opinion of us.
	var varesh:=String(info.get("varesh_id",""))
	m["varesh_dread_x100"]=roundi(Divine.civ_dread(varesh)*100.0) if varesh!="" else 0
	var fid:=String(info.get("rovik_fid",""))
	m["status_rovik"]=String(HistoricalFigures.by_id(fid).get("status","")) if fid!="" else ""
	var aims:=Aims.state()
	m["aim_active"]=1 if Aims.has_active() else 0
	var god:=0
	for k in (aims.get("candidates",{}) as Dictionary):
		if String(((aims.candidates as Dictionary)[k] as Dictionary).get("source",""))=="god": god+=1
	m["aim_god"]=god
	var relation:Dictionary=(CivilizationSystem.civilizations[0] as Dictionary).get("player_relation",{})
	m["at_war"]=1 if bool(relation.get("at_war",false)) else 0
	# A feud (war_loop.gd): whether it is on, and the war leader's band out in
	# it (trackers after the raiders' trail, or a strike), for the feud world's
	# people or else the Esurai.
	var WarLoop:GDScript=load("res://scripts/war_loop.gd")
	var feud_civ:=String(info.get("feud_id",civ))
	var feud_op:Dictionary=(WarLoop.call("_peek",feud_civ) as Dictionary).get("op",{})
	m["feud"]=1 if bool(WarLoop.call("feuding",feud_civ)) else 0
	m["trackers"]=1 if String(feud_op.get("objective",""))=="war_track" else 0
	m["feud_ops"]=0 if feud_op.is_empty() else 1
	# The war council's stance toward the feud world's people (or the Esurai)
	# and toward the Esurai: what the god's word set (war_council.gd).
	m["stance"]=String((WarLoop.call("_peek",feud_civ) as Dictionary).get("stance",""))
	m["stance_esurai"]=String((WarLoop.call("_peek",civ) as Dictionary).get("stance",""))
	m["opinion_x100"]=roundi(float(relation.get("opinion",0.0))*100.0)
	m["dread_x100"]=roundi(Divine.civ_dread(civ)*100.0)
	m["scouts"]=CivilizationSystem.scout_missions.size()
	m["envoys_out"]=0 if (CivilizationSystem.diplomatic_mission as Dictionary).is_empty() else 1
	# Do our leaders found new towns on their own (auto_founding.gd)?
	m["auto_found"]=1 if bool(PeopleDirection.auto_settlement) else 0
	# Who sets the daily work, and how many are at each task (manual_work.gd).
	m["manual_work"]=0 if bool(PeopleDirection.automatic_work) else 1
	for pair in [["work_food","Food"],["work_build","Construction"],["work_carry","Logistics"],["work_learn","Knowledge"],["work_watch","Defense"]]: m[String(pair[0])]=int(GameState.population_allocations.get(String(pair[1]),0))
	var audience:=Hall.find(audience_id)
	var pending:Dictionary=audience.get("pending_command",{}) if audience.get("pending_command") is Dictionary else {}
	m["pending_ask"]=String(pending.get("ask",""))
	m["pending_confirm"]=1 if bool(pending.get("confirm",false)) else 0
	m["pending_which"]=1 if bool(pending.get("which_town",false)) else 0
	m["reader_pending"]=0 if OR.pending(audience).is_empty() else 1
	m["audience_open"]=1 if String(audience.get("status",""))=="waiting" else 0
	m["envoy_state"]=String((audience.get("envoy_fate",{}) as Dictionary).get("state","")) if audience.get("envoy_fate") is Dictionary else ""
	# What the garrison is doing in Tsaren now (occupation_measures.gd).
	var running:Array=[]
	if int(m.get("garrison",0))>0: running=Measures.active(civ,city)
	m["measures"]=running.size()
	for mid in Measures.IDS: m["m_"+String(mid)]=0
	for r in running: m["m_"+String((r as Dictionary).get("id",""))]=1
	# What the war leader and the headman know, for "the reply states it".
	var sheet:=Facts.sheet(["common","war","stores","tribute"])
	m["food_days"]=roundi(float(sheet.get("food_days",0.0)))
	m["food_days_exact"]=str(sheet.get("food_days",0))
	m["food_in_store"]=int(sheet.get("food_in_store",0))
	m["fighters_at_home"]=int(sheet.get("fighters_at_home",0))
	m["housing"]=int(sheet.get("housing",0))
	m["people"]=int(sheet.get("people",0))
	# The realm's own settings (realm_orders.gd): training, drill, workshop
	# lines, what our thinkers study, the scouting, strangers, a great work.
	m["training_policy"]=String((MilitaryCampaign.training_staff.policy("army") as Dictionary).get("id",""))
	m["drill_program"]=0 if (MilitaryCampaign.training_program as Dictionary).is_empty() else 1
	var lines:=0; var line_target:=0
	for job in MilitaryCampaign.equipment_queue:
		if bool((job as Dictionary).get("persistent",false)) and not bool((job as Dictionary).get("paused",false)):
			lines+=1; line_target+=int((job as Dictionary).get("target_stock",0))
	m["lines"]=lines; m["line_target"]=line_target
	var top:=""; var top_weight:=-1
	for k in GameState.research_allocations:
		if int(GameState.research_allocations[k])>top_weight: top_weight=int(GameState.research_allocations[k]); top=String(k)
	m["research_top"]=top
	var targets:Array=(GameState.research_targets as Dictionary).values()
	targets.sort()
	m["research_targets"]=",".join(PackedStringArray(targets))
	m["scout_share_x100"]=roundi(float(CivilizationSystem.scouting_staff.data.get("share",0.0))*100.0)
	m["scout_focus"]=String(CivilizationSystem.scouting_staff.data.get("focus",""))
	var exchange:Dictionary=preload("res://scripts/society_exchange.gd").data()
	m["migration"]=String(exchange.get("migration_policy","")); m["sharing"]=String(exchange.get("sharing_policy",""))
	var pace:=""
	var home_city:=SettlementModel.settlement_record(SettlementModel._primary_settlement_id())
	for r in home_city.get("undertakings",[]):
		if r is Dictionary and String((r as Dictionary).get("status","")) in ["building","stalled"]: pace=String((r as Dictionary).get("policy","careful"))
	m["work_pace"]=pace
	m["build_priority"]=String(home_city.get("construction_priority",""))
	var town:Dictionary=GameState.player_settlements[0] if not GameState.player_settlements.is_empty() else {}
	m["town_focus"]=String(town.get("management_focus","")) if not bool(town.get("auto_manage",true)) else "leaders"
	m["defence_works"]=int(MilitaryCampaign.settlement_defense.get("project_stage",-1))
	m["settling"]=0 if (GameState.settlement_convoy as Dictionary).is_empty() else 1
	var ration:=0; var water:=0
	for mod in GameState.active_modifiers:
		if not mod is Dictionary or float((mod as Dictionary).get("until_day",0.0))<=float(GameState.elapsed_days): continue
		if String((mod as Dictionary).get("id","")).begins_with("court_ration"): ration=1
		if String((mod as Dictionary).get("id","")).begins_with("court_water"): water=1
	m["ration"]=ration; m["clean_water"]=water
	m["apart_custom"]=1 if bool((preload("res://scripts/crisis_system.gd").state().flags as Dictionary).get("apart_custom",false)) else 0
	m["_material"]=_material(m)
	return m

static func _material(m:Dictionary)->String:
	## Everything an order could really change (not words, memories or moods).
	var keys:=["here","free","bound","hostage","worker","conscript","killed","fled","taken","displaced","running","on_road","garrison","held","ruin","ours","armies","moving","field_troops","chases","home_troops",
		"recruits","training","equipment_orders","prisoners","food","timber","stone","fiber_plants","forced_labor","transport_carts","spears","population","modifiers","practice_prisoners","practice_spoils",
		"settlement_prisoners","settlement_spoils","officials","status_headman","status_suri","status_kavu","status_imeri","status_rovik","aim_active","aim_god","at_war","scouts","going_home","dread_x100","stance","stance_esurai",
		"measures","envoy_state","released","freed","envoys_out",
		# Offices, the god's standing with each official and with the people, the
		# court's known persons, the realm's name: what acts at home really change.
		"office_headman","office_suri","office_kavu","office_imeri","love_headman","love_suri","love_kavu","love_imeri","dread_headman","dread_suri","dread_kavu","dread_imeri",
		"people_love_x100","people_dread_x100","legitimacy_x100","cohesion_x100","settlement_name","known","known_gone","known_bound","summoned","waiting","varesh_dread_x100","opinion_x100",
		"speaker_known_status","speaker_known_role","speaker_known_marks","works","home_morale_x100","auto_found",
		# Who sets the daily work and the people at each task (manual_work.gd).
		"manual_work","work_food","work_build","work_carry","work_learn","work_watch",
		# A band sent out in a feud (war_loop.gd), and whether the feud is on.
		"trackers","feud_ops","feud"]
	var parts:=PackedStringArray()
	for k in keys: parts.append("%s=%s" % [k,str(m.get(k,""))])
	return "|".join(parts)

func one_truth(w:Dictionary,m:Dictionary)->String:
	## One state: people we hold under guard have a garrison guarding them, and
	## what the court's fact sheet says of the town matches who holds it.
	if int(m.get("ledger",0))==0: return ""
	var guarded:=int(m.get("bound",0))+int(m.get("hostage",0))+int(m.get("worker",0))+int(m.get("conscript",0))
	if guarded>0 and int(m.get("garrison",0))<=0: return "the ledger has %d people under our guard in Tsaren but no garrison holds it" % guarded
	var info:Dictionary=w.info
	var t:=Facts.town(String(info.civ_id),String(info.tsaren_id))
	if not t.is_empty():
		var says_held:=String(t.get("status",""))=="held"
		if says_held!=(int(m.get("held",0))==1): return "the fact sheet says Tsaren is %s but the war orders %s it" % [String(t.get("status","")),"hold" if int(m.get("held",0))==1 else "do not hold"]
	return ""

# --------------------------------------------------------------------------
# Judging one step
# --------------------------------------------------------------------------

func check(w:Dictionary,c:Dictionary,path:String,step:int,said:String,expect:Dictionary,before:Dictionary,after:Dictionary,lines:Array,voice:Node,asked:Array[String],answer_only:bool=false)->Array[Dictionary]:
	var fails:Array[Dictionary]=[]
	var add:=func(code:String,text:String)->void: fails.append({"step":step,"code":code,"text":text})
	var result:Dictionary={}
	var reads:Array=[]
	var route:=""
	for k:Dictionary in voice.calls:
		match String(k.call):
			"command": if result.is_empty(): result=k.result
			"read": reads.append(k)
	var war:Dictionary=result.get("war",{}) if result.get("war") is Dictionary else {}
	# What must follow from the verdict the war leader gave ("act": a real march).
	if expect.get("when_verdict") is Dictionary and ((expect.when_verdict as Dictionary).get(String(war.get("verdict",""))) is Dictionary):
		expect=_merged(expect,(expect.when_verdict as Dictionary)[String(war.get("verdict",""))])
	# The route: the reader's plan (live), else what the court did.
	if not reads.is_empty(): route=String((reads[0] as Dictionary).route)
	else: route=_derived_route(voice.calls,before,after)
	var reply_lines:Array=lines.filter(func(l:Dictionary)->bool: return String(l.get("role",""))!="ruler")
	var reply:=" \n".join(reply_lines.map(func(l:Dictionary)->String: return String(l.get("text",""))))
	var says:=String(result.get("actor_says",""))
	var engine_words:=(says+" \n"+String(result.get("outcome",""))).strip_edges()
	# On the live path the model's own lines never come (the transport is a
	# stub): its words are judged by the prompt, the engine's by what it decided.
	var spoken:=reply if path=="offline" else (engine_words+" \n"+reply)
	var prompt_text:="\n".join(voice.prompts.map(func(p:Dictionary)->String: return String(p.prompt)))
	var ctx:={"before":before,"after":after}
	# ---- the case's own expectations ----
	if expect.has("route") and not _one_of(route,expect.route): add.call("route","route %s, wanted %s" % [route,str(expect.route)])
	if expect.has("handled"):
		var handled:=not result.is_empty() and bool(result.get("handled",false))
		if handled!=bool(expect.handled): add.call("handled","handled %s, wanted %s (%s)" % [str(handled),str(expect.handled),_brief(result,route)])
	if expect.has("verb") and not _one_of(String(result.get("verb","")),expect.verb): add.call("verb","verb '%s', wanted %s (%s)" % [String(result.get("verb","")),str(expect.verb),_brief(result,route)])
	if expect.has("kind") and not _one_of(String(war.get("kind","")),expect.kind): add.call("kind","war kind '%s', wanted %s (%s)" % [String(war.get("kind","")),str(expect.kind),_brief(result,route)])
	if expect.has("verdict") and not _one_of(String(war.get("verdict","")),expect.verdict): add.call("verdict","verdict '%s', wanted %s: %s" % [String(war.get("verdict","")),str(expect.verdict),_short(says if says!="" else String(result.get("outcome","")))])
	if expect.has("stage") and not _one_of(String(result.get("stage","")),expect.stage): add.call("stage","stage '%s', wanted %s" % [String(result.get("stage","")),str(expect.stage)])
	if expect.has("target"):
		var want:=_role_name(w,String(expect.target))
		if String(result.get("target_name",""))!=want: add.call("target","landed on '%s', wanted %s (%s)" % [String(result.get("target_name","")),want,_brief(result,route)])
	if expect.get("state") is Dictionary:
		for metric in (expect.state as Dictionary):
			var problem:=_state_problem(String(metric),String(expect.state[metric]),before,after,w)
			if problem!="": add.call("state",problem)
	# What the fallback reply must say is judged offline, where the court's own
	# lines are the whole answer; live, the prompt carries it (prompt_has).
	var fallback:=path=="offline"
	for token in expect.get("reply_has",[]) if fallback else []:
		var want:=fill(String(token),ctx)
		if not _contains(spoken,want): add.call("reply","reply lacks '%s': %s" % [want,_short(spoken)])
	if fallback and expect.has("reply_any"):
		var any:=false
		var wants:Array=[]
		for token in expect.reply_any:
			var want:=fill(String(token),ctx); wants.append(want)
			if _contains(spoken,want): any=true
		if not any: add.call("reply","reply has none of %s: %s" % [str(wants),_short(spoken)])
	for token in expect.get("reply_lacks",[]) if fallback else []:
		var bad:=fill(String(token),ctx)
		if _contains(spoken,bad): add.call("reply","reply says '%s': %s" % [bad,_short(spoken)])
	for token in expect.get("says_has",[]):
		var want:=fill(String(token),ctx)
		if not _contains(says,want): add.call("says","the war leader's words lack '%s': %s" % [want,_short(says)])
	if expect.has("says_any"):
		var any2:=false
		for token in expect.says_any:
			if _contains(says,fill(String(token),ctx)): any2=true
		if not any2: add.call("says","the war leader's words have none of %s: %s" % [str(expect.says_any),_short(says)])
	for token in expect.get("says_lacks",[]):
		if _contains(says,fill(String(token),ctx)): add.call("says","the war leader says '%s': %s" % [fill(String(token),ctx),_short(says)])
	if path!="offline":
		for token in expect.get("prompt_has",[]):
			var want:=fill(String(token),ctx)
			if voice.prompts.is_empty(): add.call("prompt","no prompt went to the voice (wanted '%s')" % want)
			elif not _contains(prompt_text,want): add.call("prompt","the voice's prompt lacks '%s'" % want)
		if expect.has("prompt_any") and not voice.prompts.is_empty():
			var hit:=false
			for token in expect.prompt_any:
				if _contains(prompt_text,fill(String(token),ctx)): hit=true
			if not hit: add.call("prompt","the voice's prompt has none of %s" % str(expect.prompt_any))
	var did_ask:=route=="clarify" or String(war.get("verdict","")) in ["ask","ask_march"] or (String(after.pending_ask)!="" and String(after.pending_ask)!=String(before.pending_ask)) or (int(after.pending_confirm)==1 and int(before.pending_confirm)==0) or (int(after.pending_which)==1 and int(before.pending_which)==0)
	if expect.has("asks") and did_ask!=bool(expect.asks): add.call("asks","the court %s, wanted %s: %s" % ["asked" if did_ask else "did not ask","a question" if bool(expect.asks) else "no question",_short(says if says!="" else reply)])
	# ---- the standing rules ----
	# 1. Nobody in the hall is harmed by an order that is not about them.
	# harm_ok: true (the words are about someone here), or the roles the words
	# are about (["kavu"]): nobody else may be touched.
	var harm_ok:Variant=expect.get("harm_ok",false)
	if not (harm_ok is bool and bool(harm_ok)):
		var gone:=_harmed(before,after,w,harm_ok if harm_ok is Array else [])
		if gone!="": add.call("harm","a hall member was harmed: "+gone)
	# 2. An order never becomes a generation's aim.
	if not bool(expect.get("aim_ok",false)) and (int(after.aim_god)>int(before.aim_god) or int(after.aim_active)>int(before.aim_active)):
		add.call("aim","the words became an aim for a generation")
	# 3. The ledger adds up, before plus changes equals after.
	if int(after.get("ledger",0))==1:
		if int(after.ledger_ok)==0: add.call("ledger","Ledger.check failed after the step")
		if int(before.get("ledger",0))==1 and before.has("_snap") and after.has("_snap"):
			var b:=Ledger.balance(before._snap,after._snap)
			if not bool(b.get("ok",false)): add.call("ledger","Ledger.balance failed: "+str(b))
	var truth:=one_truth(w,after)
	if truth!="" and one_truth(w,before)=="": add.call("one_truth","after the step: "+truth)
	# 4. Known facts are stated, never met with "I don't know".
	var lower_spoken:=spoken.to_lower()
	if bool(expect.get("known",false)):
		for phrase in IGNORANCE:
			if phrase in lower_spoken: add.call("ignorance","claims ignorance ('%s'): %s" % [phrase,_short(spoken)]); break
	# 5. Never "it is done" when nothing was done; never both at once.
	var claimed:=""
	for phrase in DONE_CLAIMS:
		if phrase in lower_spoken: claimed=phrase; break
	var nothing:=""
	for phrase in NOTHING_WORDS:
		if phrase in lower_spoken: nothing=phrase; break
	if claimed!="" and nothing!="": add.call("false_done","says '%s' and '%s' together: %s" % [claimed,nothing,_short(spoken)])
	elif claimed!="" and String(before._material)==String(after._material) and not bool(expect.get("allow_done",false)): add.call("false_done","says '%s' but nothing changed: %s" % [claimed,_short(spoken)])
	# 5b. A yes or a no answers what is open; it never becomes a new standing order.
	if answer_only and int(after.get("modifiers",0))>int(before.get("modifiers",0)): add.call("answer_as_order","'%s' became a new standing order for the council" % said)
	# 6. Words about a town are never "nobody here answers to that".
	if not bool(expect.get("allow_stray",false)) and STRAY in lower_spoken: add.call("stray","the stray line: "+_short(spoken))
	# 7. The same question is never put twice.
	var question:=_question_asked(route,war,says,lines,after)
	if question!="":
		var key:=_norm(question)
		if key in asked: add.call("repeat_question","asked again: "+_short(question))
		asked.append(key)
	# 8. No key anywhere.
	if SECRET in prompt_text or SECRET in reply or SECRET in JSON.stringify(Hall.find(String(after.get("_audience","")))): add.call("key","the API key leaked")
	return fails

func _derived_route(calls:Array,before:Dictionary,after:Dictionary)->String:
	for k:Dictionary in calls:
		if String(k.call)=="command": return "engine"
	if int(before.audience_open)==1 and int(after.audience_open)==0: return "choice"
	for k:Dictionary in calls:
		if String(k.call)=="persons": return "persons"
		if String(k.call)=="divine": return "divine"
	for k:Dictionary in calls:
		if String(k.call)=="speak": return "speak"
	return "none"

func _question_asked(route:String,war:Dictionary,says:String,lines:Array,after:Dictionary)->String:
	if String(war.get("verdict","")) in ["ask","ask_march"]: return says
	if route=="clarify":
		for l in lines:
			if String((l as Dictionary).get("text","")).ends_with("?") and String((l as Dictionary).get("role",""))!="ruler": return String(l.text)
	return ""

static func _norm(text:String)->String:
	var re:=RegEx.new(); re.compile("[^a-z0-9 ]")
	return re.sub(text.to_lower(),"",true).strip_edges()

func _harmed(before:Dictionary,after:Dictionary,w:Dictionary={},allowed:Array=[])->String:
	var gone:=PackedStringArray()
	var ok_pids:Array=[]
	for role in allowed: ok_pids.append(fx.role_pid(w,String(role)))
	for pid in before._official_ids:
		if not pid in after._official_ids and not int(pid) in ok_pids: gone.append("official %d left the court" % int(pid))
	for role in ["headman","suri","kavu","imeri"]:
		if role in allowed: continue
		var b:=String(before.get("status_"+role,"")); var a:=String(after.get("status_"+role,""))
		if b!=a and a!="": gone.append("%s is now %s" % [role,a])
	if not "rovik" in allowed and String(before.status_rovik)!=String(after.status_rovik): gone.append("Rovik is now %s" % String(after.status_rovik))
	return "; ".join(gone)

func _role_name(w:Dictionary,role:String)->String:
	if role=="rovik": return "Rovik Longstride"
	var pid:=fx.role_pid(w,role)
	return String(GovernmentPeopleSystem.person_snapshot(pid).get("name","")) if pid>0 else role

static func _one_of(value:String,want:Variant)->bool:
	if want is Array: return value in (want as Array)
	return value==String(want)

static func _brief(result:Dictionary,route:String)->String:
	if result.is_empty(): return "route %s, no command" % route
	return "route %s, %s/%s" % [route,String(result.get("verb","")),String(result.get("stage",""))]

static func _short(text:String)->String:
	var t:=text.replace("\n"," ").strip_edges()
	return t if t.length()<=180 else t.substr(0,177)+"..."

# --------------------------------------------------------------------------
# Numbers and conditions
# --------------------------------------------------------------------------

const SMALL:=["zero","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve","thirteen","fourteen","fifteen","sixteen","seventeen","eighteen","nineteen","twenty"]

func fill(token:String,ctx:Dictionary)->String:
	## "{bound_men}" -> the count after the step; "{b.bound_men}" -> before.
	var re:=RegEx.new(); re.compile("\\{(b\\.)?([a-z_0-9]+)\\}")
	var out:=token
	for m in re.search_all(token):
		var src:Dictionary=ctx.before if m.get_string(1)!="" else ctx.after
		out=out.replace(m.get_string(),str(src.get(m.get_string(2),"?")))
	return out

static func _contains(text:String,want:String)->bool:
	## Case-insensitive; a number matches its digits or its word ("17" or
	## "seventeen"), whole: "2" is never found inside "20" or "12".
	var lower:=text.to_lower()
	var w:=want.to_lower().strip_edges()
	if w.is_valid_int():
		var n:=int(w)
		if n>=0 and n<SMALL.size() and RegEx.create_from_string("\\b%s\\b" % SMALL[n]).search(lower)!=null: return true
		return RegEx.create_from_string("(?<![0-9])%d(?![0-9])" % n).search(lower)!=null
	if not w in lower: return false
	# A phrase that starts or ends with a number ("20 bound") matches it whole.
	var starts:=w.length()>0 and w.substr(0,1).is_valid_int()
	var ends:=w.length()>0 and w.substr(w.length()-1).is_valid_int()
	if not starts and not ends: return true
	var escaped:=""
	for ch in w: escaped+=("\\"+ch) if ch in ".^$*+?()[]{}|\\-/" else ch
	return RegEx.create_from_string(("(?<![0-9])" if starts else "")+escaped+("(?![0-9])" if ends else "")).search(lower)!=null

func _state_problem(metric:String,cond:String,before:Dictionary,after:Dictionary,w:Dictionary)->String:
	## cond: ">0", "==0", "==before", "<before", ">before", "!=before", ">=before",
	## "==b.other", "==N", ">=N", "<=N", "=='text'".
	if not after.has(metric) and not before.has(metric): return "%s is not measured here" % metric
	var a:Variant=after.get(metric,0)
	var b:Variant=before.get(metric,0)
	var re:=RegEx.new(); re.compile("^(==|!=|>=|<=|>|<)\\s*(.+)$")
	var m:=re.search(cond.strip_edges())
	if m==null: return "bad condition %s for %s" % [cond,metric]
	var op:=m.get_string(1); var rhs:=m.get_string(2).strip_edges()
	var want:Variant
	if rhs=="before": want=b
	elif rhs.begins_with("b."): want=before.get(rhs.trim_prefix("b."),0)
	elif rhs.begins_with("'") and rhs.ends_with("'"): want=rhs.substr(1,rhs.length()-2)
	elif rhs.is_valid_int(): want=int(rhs)
	else: want=after.get(rhs,0)
	var ok:=false
	if a is String or want is String:
		ok=(String(a)==String(want)) if op=="==" else ((String(a)!=String(want)) if op=="!=" else false)
	else:
		var x:=float(a); var y:=float(want)
		match op:
			"==": ok=x==y
			"!=": ok=x!=y
			">": ok=x>y
			"<": ok=x<y
			">=": ok=x>=y
			"<=": ok=x<=y
	if ok: return ""
	return "%s is %s (before %s), wanted %s %s" % [metric,str(a),str(b),op,rhs if not rhs=="before" else str(b)]
