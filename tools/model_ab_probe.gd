extends Node
## Head-to-head test of two live court-voice models through the game's real
## prompt-building paths (audience_voice.gd, court_persons.gd, the audience
## modal and director), in the probe world of tests/audience_modal_probe.gd.
## Only the model id differs between the two runs of each scenario.
##
##   <godot> --headless --path <worktree> res://tools/model_ab_probe.tscn -- --out=<file.json>
##
## Spends real money. Needs OPENAI_API_KEY (or LEVIATHAN_AI_API_KEY) in the
## environment; the key is only placed in the Authorization header and is
## never printed or written. Every call goes through the voice's send_hook,
## where a spending guard estimates the worst case first and stops all calls
## once the running total would pass STOP_TOTAL (or a model's half of it).
## Refuses to run unless override.cfg isolates the user data directory.

const Hall:=preload("res://scripts/audience_hall.gd")
const Persons:=preload("res://scripts/court_persons.gd")
const PersonsLines:=preload("res://scripts/court_persons_lines.gd")
const Aims:=preload("res://scripts/legacy_aims.gd")
const Director:=preload("res://scripts/audience_director.gd")
const Voice:=preload("res://scripts/audience_voice.gd")
const Store:=preload("res://scripts/interaction_store.gd")
const CC:=preload("res://scripts/court_commands.gd")
const CV:=preload("res://scripts/character_voice.gd")

const ENDPOINT:="https://api.openai.com/v1/chat/completions"
const MODELS:=["gpt-5.6-terra","gpt-6-luna"]
## USD per million tokens (developers.openai.com/api/docs/pricing, 2026-09-25).
## "in"/"out" are the short-context rates used for reported cost; the guard
## uses the long-context rates as a conservative upper bound.
const PRICES:={
	"gpt-5.6-terra":{"in":2.00,"out":12.00,"guard_in":4.00,"guard_out":18.00},
	"gpt-6-luna":{"in":0.10,"out":0.50,"guard_in":0.20,"guard_out":0.75},
}
const STOP_TOTAL:=1.80
const PER_MODEL_CAP:=0.90
const CHARS_PER_TOKEN_WORST:=2.5
const HTTP_TIMEOUT:=90.0
const GAME_TIMEOUT:=45.0

class TerrainDouble extends Node:
	var game_speed:=1.0
	var capture_render_active:=false
	var decrees:Array[String]=[]
	func _set_game_speed(speed:float)->void:game_speed=speed
	func issue_civic_directive_text(text:String)->void:decrees.append(text)
	func _blocking_modal_or_report_open()->bool:return false

var out_path:=""
var api_key:=""
var spent:={}
var total:=0.0
var stopped:=false
var stop_reason:=""
var exchanges:Array=[]
var scenario_log:Array=[]
var model:=""
var scenario:=""
var director:Node
var terrain:TerrainDouble
var voice:Node
var inflight:=0
var persons_results:Dictionary={}
var dry:=false

func _ready()->void:
	if not OS.get_user_data_dir().get_file().begins_with("TomorrowFun"):
		print("MODEL_AB refused: override.cfg must isolate user data");get_tree().quit(2);return
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):out_path=a.substr(6)
	api_key=OS.get_environment("LEVIATHAN_AI_API_KEY").strip_edges()
	if api_key.is_empty():api_key=OS.get_environment("OPENAI_API_KEY").strip_edges()
	if api_key.is_empty() or out_path.is_empty():
		print("MODEL_AB needs an API key in the environment and --out=");get_tree().quit(2);return
	for m in MODELS:spent[m]=0.0
	dry=OS.get_environment("MODEL_AB_DRY")=="1"
	# Warm-up reset: the first world build leaves extra stock behind, so every
	# measured run starts from a second, identical reset.
	scenario="warmup";model=MODELS[0]
	await _fresh()
	var scenarios:=["gift_accept","violent_order","blame_liar","guilty_commoner","aim_proposal","typed_order","terrify","stores_question"]
	for sc in scenarios:
		for m in MODELS:   # interleaved: both models get each scenario before the next
			if stopped:break
			await _run(sc,m)
		if stopped:break
	_write()
	print("MODEL_AB done total=$%.4f terra=$%.4f luna=$%.4f stopped=%s %s" % [total,float(spent[MODELS[0]]),float(spent[MODELS[1]]),str(stopped),stop_reason])
	get_tree().quit(0)

# ---------------------------------------------------------------------------
# World and scenario plumbing
# ---------------------------------------------------------------------------

func _frames(n:int)->void:
	for i in n:await get_tree().process_frame

func _fresh()->void:
	if is_instance_valid(director):
		director.queue_free();await _frames(3)
	if is_instance_valid(terrain):terrain.queue_free()
	var probe:Node=load("res://tests/audience_modal_probe.gd").new()
	probe._setup_world()
	probe.free()
	GameState.ensure_population_total(600)
	GovernmentPeopleSystem.initialize()
	PeopleDirection.aims.clear()
	Persons.force={}
	# A fresh, empty interaction store per run: learned templates from one
	# model can never shape the other model's menu or prompt.
	var dir:="user://model_ab_store/%s_%s/" % [scenario,model.replace(".","_")]
	DirAccess.make_dir_recursive_absolute(dir)
	for f in DirAccess.get_files_at(dir):DirAccess.remove_absolute(dir+f)
	Store.configure_for_tests(dir,Store.SHIPPED_ROOT)
	terrain=TerrainDouble.new();add_child(terrain)
	director=Director.new();director.terrain=terrain;add_child(director)
	director.set_process(false)
	voice=director.voice
	voice.config_override={"endpoint":ENDPOINT,"api_key":api_key,"model":model,"structured_output":true}
	voice.send_hook=_hook
	voice.persons_done.connect(func(id:String,result:Dictionary):persons_results[id]=result)
	persons_results.clear()
	await _frames(2)

func _settle(id:String,limit:float=150.0)->void:
	var waited:=0.0
	await _frames(2)
	while waited<limit and (inflight>0 or (voice!=null and (voice.busy(id) or voice._requests.size()>0))):
		await get_tree().process_frame;waited+=get_process_delta_time()
	await _frames(4)

func _modal_id(modal:Control)->String:
	return String(modal.audience_id) if is_instance_valid(modal) else ""

func _say(modal:Control,text:String)->void:
	modal.speech_input.text=text
	modal._speak()
	await _settle(_modal_id(modal))

func _transcript(id:String)->Array:
	var out:Array=[]
	for l in Hall.find(id).get("lines",[]):
		out.append({"speaker":String(l.get("speaker","")),"role":String(l.get("role","")),"text":String(l.get("text","")),"aside":bool(l.get("aside",false))})
	return out

func _run(sc:String,m:String)->void:
	scenario=sc;model=m
	await _fresh()
	var ids:Array=[]
	var note:String
	match sc:
		"gift_accept":note=await _sc_gift(ids)
		"violent_order","terrify":note=await _sc_envoy(ids,sc)
		"blame_liar","guilty_commoner":note=await _sc_blame(ids,sc=="blame_liar")
		"aim_proposal":note=await _sc_aim(ids)
		_:note=await _sc_official(ids,sc)
	var transcripts:={}
	for id in ids:transcripts[id]=_transcript(String(id))
	scenario_log.append({"scenario":sc,"model":m,"audiences":ids,"note":note,"transcripts":transcripts})
	print("MODEL_AB scenario=%s model=%s exchanges=%d spent_total=$%.4f (%s $%.4f) %s" % [sc,m,_count(sc,m),total,m,float(spent[m]),note.substr(0,160)])

func _sc_gift(ids:Array)->String:
	var a:=Hall.debug_force("gift")
	if a.is_empty():return "no gift audience"
	var id:=String(a.id)
	var modal:Control=director.open_audience(id);ids.append(id)
	await _settle(id)
	await _say(modal,"I accept your gift, and I will remember who sent it.")
	var pick:=""
	for o in Hall.options(id):
		if String(o.id).begins_with("accept") and bool(o.get("enabled",true)) and pick=="":pick=String(o.id)
	if pick!="":modal.choose(pick)
	await _settle(id)
	return "option=%s string=%s" % [pick,JSON.stringify((Hall.find(id).get("situation",{}) as Dictionary).get("string",{}))]

func _sc_envoy(ids:Array,sc:String)->String:
	var a:=Hall.debug_force("threat")
	if a.is_empty():a=Hall.debug_force("request")
	if a.is_empty():return "no envoy audience"
	var id:=String(a.id)
	var modal:Control=director.open_audience(id);ids.append(id)
	await _settle(id)
	var note:="kind=%s" % String(a.get("kind",""))
	if sc=="violent_order":
		await _say(modal,"Cut his hands off and send him home.")
	else:
		var r:Dictionary=modal.divine("terrify")
		note+=" terrify=%s" % String(r.get("outcome",""))
		await _settle(id)
	return note+" hidden=%s" % JSON.stringify(Hall.find(id).get("hidden",{}))

func _sc_blame(ids:Array,liar:bool)->String:
	Persons.force={"culprit":"holder" if liar else "commoner","lie":liar}
	GameState.elapsed_days=int(GameState.elapsed_days)+3
	GameState.simulation_events.push_front({"day":int(GameState.elapsed_days),"title":"Stores Spoiled","description":"Half the stored grain was found spoiled and wet.","domain":"food","severity":"major"})
	var modal:Control=director.open_court({})
	await _frames(2)
	var ask:Dictionary={}
	for ch in modal.persons_choices():
		if String(ch.action)=="ask_blame":ask=ch;break
	if ask.is_empty():return "no ask_blame choice"
	var params:Dictionary=ask.get("params",{})
	var answerer:=Persons.answerer_for(Persons.event_by_key(String(params.get("event","")),""),"")
	if answerer.is_empty() or not modal.summon({"person_id":int(answerer.person_id)}):return "no answerer"
	var first:=_modal_id(modal);ids.append(first)
	await _settle(first)
	await _say(modal,"Who is responsible for the spoiled stores?")
	await _say(modal,"Bring the one you named before me.")
	var second:=_modal_id(modal)
	if second!=first:
		ids.append(second);await _settle(second)
		await _say(modal,"Where were you when the grain spoiled?" if liar else "Did you do this?")
	var truths:Array=[]
	for t in Persons.truth_records():truths.append(t)
	return "truth=%s" % JSON.stringify(truths).substr(0,1500)

func _sc_aim(ids:Array)->String:
	var day:=int(GameState.elapsed_days)
	var cands:=Aims.propose(day)
	var entry:=Aims.file_proposal(day,cands)
	if entry.is_empty():return "no aim matter"
	var opened:=Hall.open_matter(String(entry.id))
	if opened.is_empty():return "aim matter did not open"
	var id:=String(opened.id)
	var modal:Control=director.open_audience(id);ids.append(id)
	await _settle(id)
	var titles:=PackedStringArray()
	for c in cands:titles.append(String(c.get("title","")))
	await _say(modal,"Our aim is to found a daughter hearth.")
	var chosen:=""
	for o in Hall.options(id):
		if String(o.id).begins_with("aim_adopt:") and chosen=="":chosen=String(o.id)
	if chosen!="":modal.choose(chosen)
	await _settle(id)
	return "aims=%s chosen=%s" % [" | ".join(titles),chosen]

func _sc_official(ids:Array,sc:String)->String:
	var modal:Control=director.open_court({})
	await _frames(2)
	var target:=GovernmentPeopleSystem.officeholder("Steward")
	if target.is_empty():target=GovernmentPeopleSystem.officeholder("Quartermaster")
	if target.is_empty():return "no official"
	if not modal.summon({"person_id":int(target.person_id)}):return "summon failed"
	var sid:=_modal_id(modal);ids.append(sid)
	await _settle(sid)
	await _say(modal,"Build a great temple to me." if sc=="typed_order" else "How much food is left in the stores, and how long will it last?")
	return "decrees=%s" % JSON.stringify(terrain.decrees)

func _count(sc:String,m:String)->int:
	var n:=0
	for e in exchanges:
		if String(e.scenario)==sc and String(e.model)==m and bool(e.sent):n+=1
	return n

# ---------------------------------------------------------------------------
# Transport with the spending guard
# ---------------------------------------------------------------------------

func _hook(id:String,payload:Dictionary,attempt:int)->void:
	var request:Dictionary=voice._requests.get(id,{})
	var price:Dictionary=PRICES[model]
	var prompt_chars:=JSON.stringify(payload.get("messages",[])).length()+JSON.stringify(payload.get("response_format",{})).length()
	var est_in:=ceili(float(prompt_chars)/CHARS_PER_TOKEN_WORST)
	var max_out:=int(payload.get("max_completion_tokens",1600))
	var worst:=(float(est_in)*float(price.guard_in)+float(max_out)*float(price.guard_out))/1000000.0
	var row:=_exchange_row(id,request,payload,attempt)
	row["worst_case_usd"]=worst
	if String(payload.get("model",""))!=model:
		stopped=true;stop_reason="payload model mismatch"
	if not stopped and (total+worst>STOP_TOTAL or float(spent[model])+worst>PER_MODEL_CAP):
		stopped=true;stop_reason="budget guard: next call worst case $%.4f would pass the cap (total $%.4f, %s $%.4f)" % [worst,total,model,float(spent[model])]
	if stopped:
		row["sent"]=false;row["blocked"]=stop_reason
		exchanges.append(row)
		print("MODEL_AB blocked: %s" % stop_reason)
		voice._on_response.call_deferred(HTTPRequest.RESULT_CANT_CONNECT,0,PackedStringArray(),PackedByteArray(),id,attempt)
		return
	if dry:
		row["sent"]=false;row["dry"]=true;exchanges.append(row)
		print("MODEL_AB dry %s/%s stage=%s est_in=%d max_out=%d worst=$%.5f" % [scenario,model,String(row.stage),est_in,max_out,worst])
		voice._on_response.call_deferred(HTTPRequest.RESULT_CANT_CONNECT,0,PackedStringArray(),PackedByteArray(),id,attempt)
		return
	row["sent"]=true
	exchanges.append(row)
	inflight+=1
	var http:=HTTPRequest.new();add_child(http)
	http.timeout=HTTP_TIMEOUT;http.max_redirects=0;http.body_size_limit=Voice.MAX_RESPONSE_BYTES
	var headers:=PackedStringArray(["Content-Type: application/json","Authorization: Bearer "+api_key])
	var started:=Time.get_ticks_msec()
	http.request_completed.connect(func(result:int,code:int,h:PackedStringArray,body:PackedByteArray):_on_http(row,http,started,result,code,h,body,id,attempt))
	if http.request(ENDPOINT,headers,HTTPClient.METHOD_POST,JSON.stringify(payload))!=OK:
		inflight-=1;http.queue_free();row["error"]="request did not start"
		voice._on_response.call_deferred(HTTPRequest.RESULT_CANT_CONNECT,0,PackedStringArray(),PackedByteArray(),id,attempt)

func _exchange_row(id:String,request:Dictionary,payload:Dictionary,attempt:int)->Dictionary:
	var extra:Dictionary=request.get("extra",{})
	var s:Dictionary=request.get("scene",{})
	var cast:Array=[]
	for member in ([s.get("envoy",{})]+(s.get("officials",[]) as Array)):
		var mem:Dictionary=member
		if mem.is_empty():continue
		var persona:Dictionary=mem.get("persona",{})
		cast.append({"key":String(mem.get("key","")),"name":String(mem.get("name","")),"role":String(mem.get("role","")),"voice_model":String(persona.get("model","")),"manner":String(persona.get("manner",persona.get("voice",""))).substr(0,200)})
	var result:Dictionary=extra.get("result",{}) if extra.get("result") is Dictionary else {}
	var engine:={}
	for k in ["ok","outcome","stage","reaction","option_id","action","terminal","removed"]:
		if result.has(k):engine[k]=result[k]
	if result.get("obedience") is Dictionary:engine["obedience"]=result.obedience
	var decided:Array=[]
	for mi in extra.get("menu",[]):decided.append({"action":String((mi as Dictionary).get("action","")),"decided":String((mi as Dictionary).get("decided","")).substr(0,240)})
	var prompt_text:=""
	for msg in payload.get("messages",[]):prompt_text+=String((msg as Dictionary).get("content",""))+"\n"
	return {"scenario":scenario,"model":model,"audience_id":id,"stage":String(request.get("stage","")),"attempt":attempt,"kind":String(s.get("kind","")),"origin":String(s.get("origin","")),
		"player_text":String(extra.get("player_text","")),"engine_result":engine,"menu_decided":decided,"hidden":Persons.hidden_words(id) if String(request.get("stage",""))=="persons" else "",
		"cast":cast,"prompt_hash":str(hash(prompt_text)),"prompt_chars":prompt_text.length(),"max_completion_tokens":int(payload.get("max_completion_tokens",0)),
		"reasoning_effort":String(payload.get("reasoning_effort","")),"schema":payload.has("response_format"),"lines_before":(Hall.find(id).get("lines",[]) as Array).size(),
		"prompt_user":String(((payload.get("messages",[]) as Array)[1] as Dictionary).get("content","")) if (payload.get("messages",[]) as Array).size()>1 else ""}

func _on_http(row:Dictionary,http:HTTPRequest,started:int,result:int,code:int,h:PackedStringArray,body:PackedByteArray,id:String,attempt:int)->void:
	inflight-=1
	if is_instance_valid(http):http.queue_free()
	row["latency_ms"]=Time.get_ticks_msec()-started
	row["over_game_timeout"]=float(row.latency_ms)>GAME_TIMEOUT*1000.0
	row["http"]=code;row["transport"]=result
	var parser:=JSON.new()
	var env:Dictionary=parser.data if parser.parse(body.get_string_from_utf8())==OK and parser.data is Dictionary else {}
	var usage:Dictionary=env.get("usage",{}) if env.get("usage") is Dictionary else {}
	var pt:=int(usage.get("prompt_tokens",0));var ct:=int(usage.get("completion_tokens",0))
	var details:Dictionary=usage.get("completion_tokens_details",{}) if usage.get("completion_tokens_details") is Dictionary else {}
	var pdetails:Dictionary=usage.get("prompt_tokens_details",{}) if usage.get("prompt_tokens_details") is Dictionary else {}
	row["prompt_tokens"]=pt;row["completion_tokens"]=ct;row["reasoning_tokens"]=int(details.get("reasoning_tokens",0));row["cached_tokens"]=int(pdetails.get("cached_tokens",0))
	row["served_model"]=String(env.get("model",""))
	var price:Dictionary=PRICES[model]
	var cost:float
	if usage.is_empty():cost=float(row.worst_case_usd)   # unknown usage: count the worst case
	else:cost=(float(pt)*float(price["in"])+float(ct)*float(price["out"]))/1000000.0
	row["cost_usd"]=cost;row["cost_is_worst_case"]=usage.is_empty()
	spent[model]=float(spent[model])+cost;total+=cost
	var choices:Array=env.get("choices",[]) if env.get("choices") is Array else []
	var content:=""
	if not choices.is_empty():
		row["finish_reason"]=String((choices[0] as Dictionary).get("finish_reason",""))
		var msg:Dictionary=(choices[0] as Dictionary).get("message",{})
		content=String(msg.get("content","")) if msg.get("content") is String else ""
		row["refusal"]=msg.get("refusal")!=null
	if env.has("error"):row["api_error"]=JSON.stringify(env.error).substr(0,300)
	row["raw_content"]=content.substr(0,6000)
	var inner:=JSON.new()
	row["json_ok"]=content!="" and inner.parse(content)==OK and inner.data is Dictionary
	var raw:Dictionary=inner.data if bool(row.json_ok) else {}
	row["schema_ok"]=bool(row.json_ok) and raw.get("lines") is Array and _lines_shape_ok(raw.lines)
	row["line_checks"]=_line_checks(id,raw,String(row.stage))
	print("MODEL_AB call %s/%s stage=%s http=%d tokens=%d+%d (reasoning %d) cost=$%.5f latency=%dms | running total $%.4f (terra $%.4f, luna $%.4f)" % [scenario,model,String(row.stage),code,pt,ct,int(row.reasoning_tokens),cost,int(row.latency_ms),total,float(spent[MODELS[0]]),float(spent[MODELS[1]])])
	voice._on_response(result,code,h,body,id,attempt)
	for ri in range(voice.usage.size()-1,-1,-1):
		var rc:Dictionary=voice.usage[ri]
		if String(rc.get("audience_id",""))==id and String(rc.get("stage",""))==String(row.stage) and int(rc.get("attempt",0))==attempt:
			row["accepted"]=bool(rc.get("accepted",false));row["reject_reason"]=String(rc.get("reason",""));break
	await _frames(2)
	var after:Array=Hall.find(id).get("lines",[])
	var delivered:Array=[]
	for i in range(int(row.lines_before),after.size()):delivered.append({"speaker":String(after[i].get("speaker","")),"role":String(after[i].get("role","")),"text":String(after[i].get("text",""))})
	row["delivered"]=delivered
	if persons_results.has(id):
		var pr:Dictionary=persons_results[id]
		row["persons"]={"action":String(pr.get("action","")),"spoke_live":bool(pr.get("spoke_live",false)),"outcome":String(pr.get("outcome","")),"beat":PersonsLines.principal_beat(pr.get("lines",[])),"named":Persons.ref_name(pr.get("named",{})) if pr.get("named") is Dictionary else ""}
		persons_results.erase(id)

func _lines_shape_ok(lines:Array)->bool:
	for l in lines:
		if not l is Dictionary or not (l as Dictionary).get("speaker_key") is String or not (l as Dictionary).get("text") is String:return false
	return true

func _line_checks(id:String,raw:Dictionary,stage:String)->Array:
	## The validator's own tests, one by one, on each proposed line, so the
	## report can say why a line was dropped (and count maxims and anachronisms
	## even where the validator would have hidden them).
	var out:Array=[]
	var request:Dictionary=voice._requests.get(id,{})
	if request.is_empty() or not raw.get("lines") is Array:return out
	var s:Dictionary=request.scene
	var extra:Dictionary=request.extra
	var names:Array=voice._cast_names(s)
	var refusal:=RegEx.new();refusal.compile(CC.REFUSAL_PATTERN)
	var result:Dictionary=extra.get("result",{}) if extra.get("result") is Dictionary else {}
	var obeyed:=stage=="command" and String((result.get("obedience",{}) as Dictionary).get("id","obey")) in ["obey","reluctant"]
	var ordered:=stage=="speak" and String(CC.classify(String(extra.get("player_text",""))).get("act",""))=="command"
	var meta:=RegEx.new();meta.compile(Voice.META_PATTERN)
	var number:=RegEx.new();number.compile("\\d+(?:\\.\\d+)?")
	var allowed:Dictionary=voice.allowed_numbers(s,extra)
	for item in raw.lines:
		if not item is Dictionary:continue
		var key:=String((item as Dictionary).get("speaker_key",""))
		var text:=String((item as Dictionary).get("text",""))
		var member:Dictionary=voice._member(s,key) if key!="narrator" else {}
		var row:={"key":key,"text":text,"aside":bool((item as Dictionary).get("aside",false)),"voice_model":String((member.get("persona",{}) as Dictionary).get("model",""))}
		if key!="narrator":
			var trimmed:String=Voice.without_filler(text.strip_edges(),names)
			row["maxim_game"]="line" if trimmed=="" else ("lead" if trimmed!=text.strip_edges() else "")
			row["era_ok"]=CV.permits(text,voice._era_for(s,member)) if not member.is_empty() else true
			row["imitation_ok"]=CV.imitation_ok(text)
			row["meta"]=meta.search(text)!=null
			row["refuses_decided_order"]=(obeyed or ordered) and refusal.search(text)!=null
			var invented:=false
			for mm in number.search_all(text):
				if not allowed.has(mm.get_string()):invented=true
			row["invented_number"]=invented
			row["unknown_speaker"]=member.is_empty()
		out.append(row)
	return out

func _write()->void:
	var f:=FileAccess.open(out_path,FileAccess.WRITE)
	if f==null:print("MODEL_AB could not write %s" % out_path);return
	f.store_string(JSON.stringify({"models":MODELS,"prices":PRICES,"total_usd":total,"spent":spent,"stopped":stopped,"stop_reason":stop_reason,"exchanges":exchanges,"scenarios":scenario_log},"  "))
	f.close()
