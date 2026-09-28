extends "res://tests/court_eval/harness.gd"
## THE LIVE COURT EVALUATION: does the REAL model understand the ruler?
##
## tests/test_court_eval.gd judges the court with a stubbed reader that always
## returns each case's IDEAL reading. This drives the same cases through the
## game's own live connection (the player's: PronouncementInterpreter
## ._api_config(), gpt-6-luna unless configured otherwise) and measures:
##   reader  every case step's words go to the real order reader
##           (audience_voice.read_order: its world brief, strict schema, 8 s
##           timeout and validation), in the state the game would be in with
##           the model's own readings of the steps before. Its reading is
##           scored against the case's ideal: exact; equivalent (the engine
##           makes the same plan of it, order_reader.decide() in the same
##           state, or the world is left exactly the same by the step);
##           wrong; or failed (timeout, cut off, no reply). A step after an
##           earlier misread in its case is marked so (its state differs from
##           the one the case was written for). At most MAX_IN_FLIGHT calls
##           at once. Latency is the game's receipt (request to handling);
##           while other calls are being prepared it can run a frame long.
##   engine  each case is played through the real court (harness.run(), the
##           stubbed-transport live path) twice, with the ideal readings and
##           with the model's; the case's own expectations judge both, so a
##           case that passes with the ideal and fails with the model's
##           reading failed because of the reader.
##   voice   every question step is spoken to the real live voice (the reader
##           stubbed with the ideal reading, the steps before it played with
##           their ideal readings); the reply must carry the facts the case
##           names, never claim ignorance of a known fact and never say "it is
##           done" when nothing happened. The voice's own rejections are kept.
## SPEND is capped hard: before every call its cost is estimated high (its
## payload at CHARS_PER_TOKEN, its full completion cap) and the call is refused
## when the ledger's spent + in-flight + this estimate would pass CAP_USD; the
## run then stops cleanly. The game's receipt for each call (prompt,
## completion and reasoning tokens) settles the ledger at PRICE_*; a call with
## no receipt tokens (a timeout) is charged its estimate. The ledger lives
## OUTSIDE the repository and is shared by every run (live_eval_spend.json).
## The API key is never printed, logged or written: it stays in the game's own
## request objects, and every output is checked for it before it is written.
## REPLAY (COURT_LIVE_EVAL_REPLAY=<an earlier report .json>): no model at all;
## the readings and replies that report recorded are judged again against
## the current engine and checks, for free.
## Results are data, not asserts; tests/test_court_live_eval.gd runs this only
## when COURT_LIVE_EVAL=1 (see there for the environment).

const CASES_FILE:="res://tests/court_eval/cases.json"
## gpt-6-luna prices, $ per million tokens. Reasoning tokens are output; cached
## input is counted at the full input price (an upper bound).
const PRICE_IN_PER_M:=0.10
const PRICE_OUT_PER_M:=0.50
## The most the live evaluation may spend in all, across every run sharing the
## ledger (COURT_LIVE_EVAL_CAP_USD may lower it, never raise it).
const CAP_USD:=5.0
## Where the ledger and the reports live unless COURT_LIVE_EVAL_DIR says
## otherwise: the scratch folder the $5 budget was approved for (outside the
## repository; created when missing). Every run that shares it shares the cap.
const DEFAULT_DIR:="C:/Users/sjpur/AppData/Local/Temp/claude/C--Users-sjpur-TomorrowandTomorrow/6d2810b7-2a3e-4752-aeaf-c65709e870ac/scratchpad"
const LEDGER_FILE:="live_eval_spend.json"
const MAX_IN_FLIGHT:=4
## Characters per token when a call is priced before it is made. English runs
## about 4 and the schema's ids lower; 2.5 keeps the estimate high.
const CHARS_PER_TOKEN:=2.5
## Backstops past the game's own timeouts (reader 8 s; voice 45 s, two tries).
const READER_DEADLINE_MS:=28000
const VOICE_DEADLINE_MS:=130000
## A live call this evaluation did not make itself (none should happen) is
## charged this much and reported.
const UNTRACKED_USD:=0.02
const WORST_SHOWN:=15
## Flags that change nothing grave when missing or extra.
const BENIGN_FLAGS:=["spare","hold","full_force"]
## Numbers the live voice may say in words ("nine hundred", "twenty-seven").
const UNIT_WORDS:={"zero":0,"one":1,"two":2,"three":3,"four":4,"five":5,"six":6,"seven":7,"eight":8,"nine":9,"ten":10,"eleven":11,"twelve":12,"thirteen":13,
	"fourteen":14,"fifteen":15,"sixteen":16,"seventeen":17,"eighteen":18,"nineteen":19}
const TEN_WORDS:={"twenty":20,"thirty":30,"forty":40,"fifty":50,"sixty":60,"seventy":70,"eighty":80,"ninety":90}

# --------------------------------------------------------------------------
# The game's own voice with a meter on it
# --------------------------------------------------------------------------

## audience_voice.gd unchanged, except that every real call is priced before
## it starts (and refused past the cap) and its receipt settles the ledger.
## Stubbed calls (the test hooks) pass straight through and cost nothing.
class LiveVoice extends "res://scripts/audience_voice.gd":
	var meter=null                 ## the LiveEval (reserve / release / settle)
	var reserved:=0.0              ## $ held for the call in flight
	var reserved_stage:=""
	var call_started_ms:=0
	var last_raw:Dictionary={}     ## the reader's JSON as the model wrote it
	var last_transport:=-1
	var last_http:=0
	var last_finish:=""
	var last_row:Dictionary={}     ## the last real call's receipt (a copy)
	var rows:Array[Dictionary]=[]  ## every real call's receipt since cleared
	var last_proposed:Array=[]     ## the lines the model proposed, before validation
	var last_prompt:=""            ## the last real voice call's scene (never the key)
	var last_brief:=""             ## what the reader was shown for the last reading

	func idle()->bool:
		return _requests.is_empty() and _ordering.is_empty() and _reading.is_empty() and _picking.is_empty()

	func drain(audience_id:String)->void:
		_requests.erase(audience_id); _ordering.erase(audience_id); _reading.erase(audience_id); _picking.erase(audience_id)

	func read_order(audience_id:String,text:String,done:Callable)->bool:
		if _ordering.has(audience_id): return true
		var config:Dictionary=OrderReader.reader_config(_config())
		var h:Variant=_hall()
		if config.is_empty() or h==null or (h.find(audience_id) as Dictionary).is_empty(): return false
		# The same payload the call below builds: kept to trace what was read.
		var payload:Dictionary=OrderReader.build_payload(text,OrderReader.world_brief(audience_id),config)
		last_brief=String(((payload.messages as Array)[1] as Dictionary).get("content",""))
		if order_hook.is_valid() or meter==null: return super.read_order(audience_id,text,done)
		if not bool(meter.reserve(self,payload,"order_read")): return false
		last_raw={}; last_transport=-1; last_http=0; last_finish=""; last_row={}
		call_started_ms=Time.get_ticks_msec()
		var started:=super.read_order(audience_id,text,done)
		if not _ordering.has(audience_id) and reserved>0.0: meter.release(self)
		return started

	func _send(audience_id:String)->void:
		if not _requests.has(audience_id):
			super._send(audience_id)
			return
		var request:Dictionary=_requests[audience_id]
		var messages:Variant=(request.payload as Dictionary).get("messages",[])
		if messages is Array and (messages as Array).size()>1 and (messages as Array)[1] is Dictionary: last_prompt=String(((messages as Array)[1] as Dictionary).get("content",""))
		if send_hook.is_valid() or meter==null:
			super._send(audience_id)
			return
		if not bool(meter.reserve(self,request.payload as Dictionary,String(request.get("stage","")))):
			_requests.erase(audience_id)
			last_problem[audience_id]="the live evaluation stopped before this call"
			_deliver_offline(request.scene as Dictionary,String(request.stage),request.extra as Dictionary,"the live evaluation stopped")
			return
		call_started_ms=Time.get_ticks_msec()
		super._send(audience_id)
		if _requests.has(audience_id) and (_requests[audience_id] as Dictionary).get("http")==null and reserved>0.0: meter.release(self)

	func _on_order_response(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray,audience_id:String)->void:
		if _ordering.has(audience_id):
			last_transport=result; last_http=response_code
			last_finish=String(_envelope_facts(body).get("finish_reason",""))
			last_raw=OrderReader.parse(body) if result==HTTPRequest.RESULT_SUCCESS and response_code>=200 and response_code<300 else {}
		super._on_order_response(result,response_code,headers,body,audience_id)

	func _receipt_http(audience_id:String,request:Dictionary,result:int,code:int,envelope:Dictionary)->Dictionary:
		var row:Dictionary=super._receipt_http(audience_id,request,result,code,envelope)
		if meter!=null and reserved>0.0: meter.settle(self,row)
		return row

	func _finish_receipt(row:Dictionary,accepted:bool,fallback:bool,reason:String)->void:
		super._finish_receipt(row,accepted,fallback,reason)
		if not bool(row.get("_eval_live",false)): return
		var copy:Dictionary=row.duplicate()
		if bool(row.get("_eval_logged",false)) and not rows.is_empty(): rows[rows.size()-1]=copy
		else: rows.append(copy)
		row["_eval_logged"]=true
		last_row=copy

	func validate_lines(raw:Array,s:Dictionary,stage:String,extra:Dictionary={})->Array[Dictionary]:
		last_proposed=raw.duplicate(true)
		return super.validate_lines(raw,s,stage,extra)

# --------------------------------------------------------------------------
# Settings and state
# --------------------------------------------------------------------------

var dry:=false                  ## no model at all: plumbing only, nothing spent
var out_dir:=""
var ledger_path:=""
var cap:=CAP_USD
var max_calls:=-1
var filter:=""
var parts:PackedStringArray=PackedStringArray(["reader","voice"])
var stop_reason:=""
var calls_started:=0
var run_usd:=0.0
var run_calls:=0
var run_tokens:={"prompt":0,"completion":0,"reasoning":0}
var charged_estimates:=0
var untracked:=0
var cumulative_at_start:=0.0
var run_started:=""
var commit:=""
var connection:Dictionary={}    ## model, host, mode (never the key)
var _key_probe:=""               ## held in memory for the leak check only
var _seen_http:Dictionary={}
var pool:Array[LiveVoice]=[]
var jobs:Array[Dictionary]=[]
var _jobs_by:Dictionary={}      ## "case#step" -> job
var _cases_by:Dictionary={}     ## case id -> case
var selected:Array[Dictionary]=[]
var engine_rows:Array[Dictionary]=[]
var voice_rows:Array[Dictionary]=[]
var started_ms:=0
var replay_path:=""             ## an earlier report whose readings are judged again
var _replay:Dictionary={}       ## "case#step" -> recorded reader step; "voice:case#step" -> recorded reply
# What the stubbed reader returns while harness.run() plays a case.
var _mode:="ideal"              ## "ideal": the case's ideal; "real": the model's
var _cur:Dictionary={}
var _step_i:=0
var _compare_on:=false
var _last_audience:=""

func _init(test_suite:Node)->void:
	super(test_suite)

func configure()->void:
	dry=OS.get_environment("COURT_LIVE_EVAL_DRY").strip_edges() in ["1","true","yes"]
	filter=OS.get_environment("COURT_LIVE_EVAL_FILTER").strip_edges()
	var n:=OS.get_environment("COURT_LIVE_EVAL_MAX_CALLS").strip_edges()
	max_calls=int(n) if n.is_valid_int() else -1
	var p:=OS.get_environment("COURT_LIVE_EVAL_PARTS").strip_edges().to_lower()
	if p!="": parts=PackedStringArray(Array(p.split(",",false)).map(func(x:String)->String: return x.strip_edges()))
	out_dir=OS.get_environment("COURT_LIVE_EVAL_DIR").strip_edges()
	if out_dir=="": out_dir=DEFAULT_DIR
	ledger_path=OS.get_environment("COURT_LIVE_EVAL_LEDGER").strip_edges()
	if ledger_path=="": ledger_path=out_dir.path_join(LEDGER_FILE)
	var c:=OS.get_environment("COURT_LIVE_EVAL_CAP_USD").strip_edges()
	cap=minf(CAP_USD,float(c)) if c.is_valid_float() else CAP_USD
	replay_path=OS.get_environment("COURT_LIVE_EVAL_REPLAY").strip_edges()
	var output:Array=[]
	if OS.execute("git",["-C",ProjectSettings.globalize_path("res://"),"rev-parse","--short","HEAD"],output)==0 and not output.is_empty(): commit=String(output[0]).strip_edges()

func offline()->bool:
	## No model call can happen in this run (a dry run or a replay).
	return dry or replay_path!=""

func _load_replay()->String:
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(replay_path)) if FileAccess.file_exists(replay_path) else null
	if not parsed is Dictionary: return "COURT_LIVE_EVAL_REPLAY=%s is not a live evaluation report" % replay_path
	var report:Dictionary=parsed
	for s in report.get("reader_steps",[]):
		if s is Dictionary: _replay["%s#%d" % [String((s as Dictionary).get("cid","")),int((s as Dictionary).get("k",0))]]=s
	for v in report.get("voice_steps",[]):
		if v is Dictionary: _replay["voice:%s#%d" % [String((v as Dictionary).get("id","")),int((v as Dictionary).get("step",1))-1]]=v
	var meta:Dictionary=report.get("meta",{}) if report.get("meta") is Dictionary else {}
	connection={"model":String(meta.get("model","")),"reader_model":String(meta.get("model","")),"endpoint_host":String(meta.get("endpoint_host","")),"replay_of_commit":String(meta.get("commit",""))}
	return "" if not _replay.is_empty() else "the report %s holds no readings" % replay_path

# --------------------------------------------------------------------------
# The run
# --------------------------------------------------------------------------

func run_all()->Dictionary:
	started_ms=Time.get_ticks_msec()
	run_started=Time.get_datetime_string_from_system(false,true)
	configure()
	load_cases(CASES_FILE)
	if not load_errors.is_empty(): return {"error":"cases.json is malformed: "+"; ".join(load_errors)}
	if replay_path!="":
		var bad:=_load_replay()
		if bad!="": return {"error":bad}
	var problem:=_connection_problem()
	if problem!="": return {"skipped":problem}
	_select()
	if selected.is_empty(): return {"skipped":"no case matches COURT_LIVE_EVAL_FILTER=%s" % filter}
	# Every world first, then the player's own reader model (the worlds reset it).
	for name in _fixtures_needed():
		var w:=fx.use(name)
		if w.has("error"): return {"error":"world %s: %s" % [name,String(w.error)]}
	var reader_model:=String(connection.get("reader_model",""))
	if not offline() and reader_model!="" and reader_model!=String(connection.get("model","")): OS.set_environment("LEVIATHAN_AI_READER_MODEL",reader_model)
	if not offline():
		var opened:=_ledger_open()
		if opened!="": return {"skipped":opened}
	var how:="model %s at %s" % [String(connection.get("reader_model","")),String(connection.get("endpoint_host",""))]
	if dry: how="DRY (no model)"
	elif replay_path!="": how="REPLAY of %s (no model)" % replay_path.get_file()
	print("LIVE COURT EVALUATION: %d cases, %d steps (%d questions), %s%s; spent so far $%.4f of $%.2f" % [selected.size(),jobs.size(),_questions().size(),
		how,(", filter '%s'" % filter) if filter!="" else "",cumulative_at_start,cap])
	for i in MAX_IN_FLIGHT:
		var v:=LiveVoice.new()
		v.name="LiveEvalReader%d" % i
		v.meter=null if offline() else self
		v.config_override={"endpoint":ENDPOINT,"api_key":SECRET,"model":"mock-reader","structured_output":true} if offline() else {}
		suite.add_child(v)
		pool.append(v)
	if "reader" in parts:
		await _reader_phase()
		await _engine_phase()
	if "voice" in parts:
		await _voice_phase()
	for v in pool:
		if is_instance_valid(v): v.meter=null; v.queue_free()
	pool.clear()
	var report:=_report()
	if not offline(): _ledger_close(report)
	return report

func _connection_problem()->String:
	if offline(): return ""
	var was:=bool(GameState.civic_api_enabled)
	GameState.civic_api_enabled=true
	var cfg:Dictionary=PronouncementInterpreter._api_config()
	var status:Dictionary=PronouncementInterpreter.configuration_status()
	GameState.civic_api_enabled=was
	connection={"model":String(status.get("model","")),"endpoint_host":String(status.get("endpoint_host","")),"mode":String(status.get("mode","")),
		"structured_output":bool(status.get("structured_output",false)),"reader_model":OR.reader_model(String(cfg.get("model","")))}
	if cfg.is_empty():
		var why:=PackedStringArray()
		for m in status.get("missing",[]): why.append("missing "+String(m))
		for i in status.get("issues",[]): why.append(String(i))
		if not AiMode.allows_api(): why.append("AI mode is offline")
		return "no live connection is configured (%s). Put OPENAI_API_KEY or LEVIATHAN_AI_API_KEY in this process's environment (the launcher copies the user-scoped key) and run again." % ("; ".join(why) if not why.is_empty() else "the connection is off")
	_key_probe=String(cfg.get("api_key",""))
	return ""

func _select()->void:
	selected.clear(); jobs.clear(); _jobs_by.clear(); _cases_by.clear()
	for c:Dictionary in cases:
		if filter!="" and not (filter in String(c.id) or filter==String(c.get("domain",""))): continue
		if not "live" in paths_of(c): continue
		selected.append(c)
		_cases_by[String(c.id)]=c
		var steps:Array=c.steps
		for k in steps.size():
			var step:Dictionary=steps[k]
			var job:={"cid":String(c.id),"k":k,"say":String(step.say),"ideal":step.get("ideal",null),"domain":String(c.get("domain","")),"source":String(c.get("source","")),
				"fixture":String(c.fixture),"speaker":String(c.get("speaker","")),"status":"pending","raw":{},"valid":{},"why_not":""}
			jobs.append(job)
			_jobs_by["%s#%d" % [String(c.id),k]]=job

func _fixtures_needed()->Array:
	var out:Array=[]
	for c in selected:
		if not String(c.fixture) in out: out.append(String(c.fixture))
	return out

func _job(cid:String,k:int)->Dictionary:
	return _jobs_by.get("%s#%d" % [cid,k],{})

func _questions()->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	for job in jobs:
		if job.ideal is Dictionary and String((job.ideal as Dictionary).get("kind",""))=="question": out.append(job)
	return out

func _world(job:Dictionary)->Dictionary:
	return fx.built.get(String(job.fixture),{})

func _stop(why:String)->void:
	if stop_reason=="":
		stop_reason=why
		print("LIVE COURT EVALUATION STOPPING: "+why)

# --------------------------------------------------------------------------
# The stubbed reader while harness.run() plays a case
# --------------------------------------------------------------------------

var _effects:Array=[]           ## every world measured in the run being recorded
var _recording:=false

func measure(w:Dictionary,audience_id:String)->Dictionary:
	_last_audience=audience_id
	var m:=super.measure(w,audience_id)
	if _recording: _effects.append(_effect(m))
	return m

static func _effect(m:Dictionary)->String:
	## The whole measured world (harness.measure: ledger, forces, stores,
	## officials, measures, dread, the open questions) as one comparable string.
	var out:={}
	for key in m:
		if not String(key).begins_with("_"): out[key]=m[key]
	return JSON.stringify(out)

func _reading(ideal:Variant,w:Dictionary)->Dictionary:
	if _mode!="real" or _cur.is_empty(): return super._reading(ideal,w)
	var k:=_step_i
	_step_i+=1
	var job:=_job(String(_cur.id),k)
	if job.is_empty(): return super._reading(ideal,w)
	var real:=_safe_raw(job.get("raw",{}) as Dictionary)
	if _compare_on: _compare_plans(job,real,w)
	return real

static func _safe_raw(raw:Dictionary)->Dictionary:
	## The model's reading as it wrote it, with the containers the stubbed
	## voice reads made safe to read. order_reader.validate() treats a missing
	## or mistyped container the same way, so nothing it decides changes.
	if raw.is_empty(): return {}
	var out:=raw.duplicate(true)
	if not out.get("target") is Dictionary: out["target"]={}
	if not out.get("details") is Dictionary: out["details"]={}
	return out

func _ideal_raw(job:Dictionary)->Dictionary:
	return super._reading(job.ideal,_world(job))

func _prepare(job:Dictionary,mode:String)->String:
	## The state just before this step: its world, and the case's steps before
	## it played through the court with "ideal" or the model's ("real")
	## readings. The audience id, or "" when the step cannot be spoken.
	var c:Dictionary=_cases_by[String(job.cid)]
	var prefix:Dictionary=c.duplicate()
	prefix["steps"]=(c.steps as Array).slice(0,int(job.k))
	_mode=mode; _cur=c; _step_i=0; _compare_on=false; _last_audience=""
	var out:Dictionary=run(prefix,"live")
	_cur={}; _mode="ideal"
	for f in out.fails:
		if String((f as Dictionary).code) in ["fixture","cannot_speak"]:
			job["why_not"]=String((f as Dictionary).text)
			return ""
	var id:=_last_audience
	if id=="" or String(Hall.find(id).get("status",""))!="waiting":
		job["why_not"]="the audience is over before this step"
		return ""
	return id

func _ruler_line(id:String,text:String)->void:
	Hall.append_line(id,{"speaker":"You","role":"ruler","person_id":0,"civ_id":"","text":text,"day":int(GameState.elapsed_days),"aside":false})

# --------------------------------------------------------------------------
# Phase 1: the real reader
# --------------------------------------------------------------------------

func _reader_phase()->void:
	if replay_path!="":
		for job in jobs: _replayed_reading(job)
		return
	var rounds:=0
	for c in selected: rounds=maxi(rounds,(c.steps as Array).size())
	for r in rounds:
		for job in jobs:
			if int(job.k)!=r: continue
			if not job.ideal is Dictionary:
				job.status="no_ideal"; continue
			if r>0 and String(_job(String(job.cid),r-1).get("status","")) in ["not_run","not_reached"]:
				job.status=String(_job(String(job.cid),r-1).status); job.why_not="an earlier step did not run"; continue
			if stop_reason!="":
				job.status="not_run"; job.why_not=stop_reason; continue
			var v:LiveVoice=await _free_voice()
			var id:=_prepare(job,"real")
			if id=="":
				job.status="not_reached"
				await suite.get_tree().process_frame
				continue
			_ruler_line(id,String(job.say))
			var j:Dictionary=job
			job["audience"]=id
			# The request's timeout is a Timer run on frame time, charged the
			# whole delta of the frame it starts in. Started after the long frame
			# that built the state above, that frame would count against it (the
			# baseline saw "timeouts" after 16 ms). Two frames on, the frame
			# before it did nothing.
			await suite.get_tree().process_frame
			await suite.get_tree().process_frame
			if dry:
				var body:=_body(_ideal_raw(job))
				v.order_hook=func(_a:String,_p:Dictionary)->PackedByteArray: return body
			GameState.civic_api_enabled=not dry
			var asked:=v.read_order(id,String(job.say),func(read:Dictionary)->void: _got_reading(j,v,read))
			GameState.civic_api_enabled=false
			if dry: v.order_hook=Callable()
			_check_untracked()
			if not asked:
				job.status="not_run"
				job.why_not=stop_reason if stop_reason!="" else "the live connection was not available"
			elif String(job.status)=="pending": job.status="asking"
			await suite.get_tree().process_frame
		await _all_idle()

func _free_voice()->LiveVoice:
	while true:
		_reap()
		for v in pool:
			if v.idle() and v.reserved<=0.0: return v
		await suite.get_tree().process_frame
	return null

func _all_idle()->void:
	while true:
		_reap()
		var busy:=false
		for v in pool:
			if not v.idle(): busy=true
		if not busy: return
		await suite.get_tree().process_frame

func _reap()->void:
	## A reader call past its backstop is ended as a timeout (charged its estimate).
	for v in pool:
		for id in v._ordering.keys():
			var req:Dictionary=v._ordering[id]
			if Time.get_ticks_msec()-int(req.get("started_ms",Time.get_ticks_msec()))<=READER_DEADLINE_MS: continue
			var http:Variant=req.get("http")
			if http is HTTPRequest and is_instance_valid(http): (http as HTTPRequest).cancel_request()
			v._on_order_response(HTTPRequest.RESULT_TIMEOUT,0,PackedStringArray(),PackedByteArray(),String(id))

func _replayed_reading(job:Dictionary)->void:
	## A replay: the reading this step got in the recorded run.
	if not job.ideal is Dictionary:
		job.status="no_ideal"; return
	var rec:Dictionary=_replay.get("%s#%d" % [String(job.cid),int(job.k)],{})
	if rec.is_empty():
		job.status="not_run"; job.why_not="not in the replayed report"; return
	for key in ["status","latency_ms","tokens","usd","reason","finish","http","transport","why_not","brief_md5","brief"]:
		if rec.has(key): job[key]=rec[key]
	job["latency_ms"]=int(job.get("latency_ms",0))
	job["raw"]=(rec.get("model_raw",{}) as Dictionary).duplicate(true) if rec.get("model_raw") is Dictionary else {}
	if String(job.status) in ["asking","pending"]: job.status="failed"

func _got_reading(job:Dictionary,v:LiveVoice,read:Dictionary)->void:
	# A voice reads one order at a time: its last brief is this one's.
	job["brief"]=v.last_brief
	job["brief_md5"]=v.last_brief.md5_text()
	job["transport"]=v.last_transport
	job["http"]=v.last_http
	job["finish"]=v.last_finish
	job["raw"]=v.last_raw.duplicate(true)
	job["valid"]=(read.get("reading",{}) as Dictionary).duplicate(true) if read.get("reading") is Dictionary else {}
	var row:Dictionary=v.last_row
	job["latency_ms"]=int(row.get("latency_ms",0))
	job["tokens"]={"prompt":int(row.get("prompt_tokens",0)),"completion":int(row.get("completion_tokens",0)),"reasoning":int(row.get("reasoning_tokens",0))}
	job["usd"]=float(row.get("_eval_usd",0.0))
	job["reason"]=String(row.get("reason",""))
	if (read.get("reading",{}) as Dictionary).is_empty() and String(job.reason)=="": job.reason=String(v.last_problem.get(String(job.get("audience","")),""))
	if not (job.valid as Dictionary).is_empty(): job.status="read"
	elif v.last_transport==HTTPRequest.RESULT_TIMEOUT: job.status="timeout"
	elif not (job.raw as Dictionary).is_empty(): job.status="rejected"
	elif v.last_finish=="length": job.status="cut_off"
	else: job.status="failed"
	if dry: job["latency_ms"]=0

# --------------------------------------------------------------------------
# Phase 2: the engine with the ideal and with the model's readings
# --------------------------------------------------------------------------

func _engine_phase()->void:
	for c in selected:
		var complete:=true
		for k in (c.steps as Array).size():
			if String(_job(String(c.id),k).get("status","")) in ["not_run","pending","asking"]: complete=false
		if not complete: continue
		# harness.run() measures the world first, then before and after each
		# step: [first, before 1, after 1, before 2, after 2, ...].
		_mode="ideal"; _cur=c; _step_i=0; _compare_on=false
		_effects.clear(); _recording=true
		var a:Dictionary=run(c,"live")
		var worlds_a:=_effects.duplicate()
		_recording=false; _cur={}
		await suite.get_tree().process_frame
		_mode="real"; _cur=c; _step_i=0; _compare_on=true
		_effects.clear(); _recording=true
		var b:Dictionary=run(c,"live")
		var worlds_b:=_effects.duplicate()
		_recording=false; _effects.clear()
		_compare_on=false; _cur={}; _mode="ideal"
		await suite.get_tree().process_frame
		var log:Array=b.log
		var failed_steps:={}
		for f in b.fails: failed_steps[int((f as Dictionary).step)]=true
		for i in (c.steps as Array).size():
			var job:=_job(String(c.id),i)
			var consulted:=false
			if i<log.size():
				for heard in (log[i] as Dictionary).calls:
					if String(heard).begins_with("read"): consulted=true
				job["court_calls"]=(log[i] as Dictionary).calls
			job["consulted"]=consulted
			# The same world before the step, and the same world after it.
			var at:=1+2*i
			job["same_effect"]=at+1<worlds_a.size() and at+1<worlds_b.size() and String(worlds_a[at])==String(worlds_b[at]) and String(worlds_a[at+1])==String(worlds_b[at+1])
			job["step_ok"]=i<log.size() and not failed_steps.has(i+1)
		engine_rows.append({"id":String(c.id),"domain":String(c.get("domain","")),"source":String(c.get("source","")),"ideal_ok":bool(a.ok),"real_ok":bool(b.ok),
			"ideal_fails":_fail_words(a.fails),"real_fails":_fail_words(b.fails)})

static func _fail_words(fails:Array)->Array:
	var out:Array=[]
	for f in fails.slice(0,4): out.append("s%d %s: %s" % [int((f as Dictionary).step),String((f as Dictionary).code),String((f as Dictionary).text).substr(0,200)])
	return out

func _compare_plans(job:Dictionary,real:Dictionary,w:Dictionary)->void:
	## What the engine would make of the ideal and of the model's reading, in
	## this same state (the ruler's words shown, as the court does first).
	var id:=_last_audience
	var say:=String(job.say)
	if id=="" or Hall.find(id).is_empty(): return
	_ruler_line(id,say)
	var brief:Dictionary=OR.world_brief(id)
	var ideal_raw:Dictionary=super._reading(job.ideal,w)
	var iv:Dictionary=OR.validate(ideal_raw,brief)
	if iv.has("rejected"):
		# The case's ideal names something this state's brief does not list (a
		# corpus problem, reported): judged as the ideal without that target.
		job["ideal_rejected"]=String(iv.rejected)
		var bare:Dictionary=ideal_raw.duplicate(true)
		bare["target"]={"type":"none","ref":""}
		if bare.get("details") is Dictionary: (bare.details as Dictionary)["destination"]=""
		iv=OR.validate(bare,brief)
	var rv:Dictionary=OR.validate(real,brief) if not real.is_empty() else {"rejected":"no reading"}
	job["plan_ideal"]=_plan_sig(OR.decide(id,say,iv))
	job["plan_real"]=_plan_sig(OR.decide(id,say,rv))
	# Was the reading made from this same brief? Live, it must be (else the
	# evaluation's states disagree); in a replay, a changed brief means the
	# recorded reading may be stale (the lists or the lines have moved on).
	if job.has("brief_md5"):
		var shown:Dictionary=OR.build_payload(say,brief,{})
		var now:=String(((shown.messages as Array)[1] as Dictionary).get("content",""))
		job["brief_changed"]=now.md5_text()!=String(job.brief_md5)
		if bool(job.brief_changed): job["brief_now"]=now
	var lines:Array=Hall.find(id).get("lines",[])
	if not lines.is_empty() and String((lines[lines.size()-1] as Dictionary).get("text",""))==say: lines.pop_back()

static func _plan_sig(plan:Dictionary)->String:
	## One plan in words that differ only when the engine would act differently.
	var route:=String(plan.get("route","legacy"))
	if route!="engine": return route
	var ctx:Dictionary=plan.get("context",{}) if plan.get("context") is Dictionary else {}
	if ctx.get("war_reading") is Dictionary:
		var r:Dictionary=ctx.war_reading
		var target:Dictionary=r.get("target",{}) if r.get("target") is Dictionary else {}
		var where:=String(target.get("city_id",target.get("unknown",target.get("civ_id",""))))
		var fate:Array=[]
		var f:Dictionary=r.get("fate",{}) if r.get("fate") is Dictionary else {}
		for key in f:
			if String(key)=="group": continue
			var value:Variant=f[key]
			if value is bool:
				if bool(value): fate.append(String(key))
			else: fate.append("%s=%s" % [String(key),str(value)])
		fate.sort()
		var ms:Array=[]
		if r.get("measures") is Array:
			for m in r.measures: ms.append(str(m))
		ms.sort()
		var measure:Dictionary=r.get("measure",{}) if r.get("measure") is Dictionary else {}
		var stance:=String(measure.get("stance","")) if bool(measure.get("stance_set",false)) else ""
		return "war:%s|%s|%s|%s|%s|%s|%s|%s" % [String(r.get("kind","")),where,",".join(PackedStringArray(fate)),",".join(PackedStringArray(ms)),stance,
			str(int(r.get("count",0))),str(int(r.get("army_id",0))),"home" if bool(r.get("home",false)) else ""]
	if ctx.get("live") is Dictionary:
		var l:Dictionary=ctx.live
		return "person:%s|%s|%s" % [String(l.get("verb","")),String(l.get("target_ref","")),String(l.get("object","")).to_lower()]
	var keys:Array=[]
	for key in ctx:
		if not String(key) in ["reader","echoed"]: keys.append(String(key))
	keys.sort()
	return "engine:"+",".join(PackedStringArray(keys))

# --------------------------------------------------------------------------
# Phase 3: the real voice on question steps
# --------------------------------------------------------------------------

func _voice_phase()->void:
	for job in _questions():
		if replay_path!="":
			voice_rows.append(_voice_replayed(job)); continue
		if stop_reason!="":
			voice_rows.append(_voice_row(job,"not_run",stop_reason)); continue
		voice_rows.append(await _voice_step(job))
		await suite.get_tree().process_frame

func _voice_replayed(job:Dictionary)->Dictionary:
	## A replay: the reply this question got in the recorded run, judged by
	## today's checks against the state just before it (a question changes
	## nothing, so it is also the state after it).
	var rec:Dictionary=_replay.get("voice:%s#%d" % [String(job.cid),int(job.k)],{})
	if rec.is_empty(): return _voice_row(job,"not_run","not in the replayed report")
	if String(rec.get("status","")) in ["not_run","not_reached"]: return _voice_row(job,String(rec.status),String(rec.get("why","")))
	var id:=_prepare(job,"ideal")
	if id=="": return _voice_row(job,"not_reached",String(job.get("why_not","")))
	var m:=measure(_world(job),id)
	var texts:Array=[]
	for said in rec.get("reply",[]):
		var line:=String(said)
		var cut:=line.find(": ")
		texts.append(line.substr(cut+2) if cut>=0 else line)
	var fails:=_judge_reply(_voice_expect(job),m,m,texts)
	var row:Dictionary=rec.duplicate(true)
	row["ok"]=fails.is_empty()
	row["fails"]=fails
	return row

func _voice_expect(job:Dictionary)->Dictionary:
	var step:Dictionary=(_cases_by[String(job.cid)].steps as Array)[int(job.k)]
	var expect:Dictionary=_merged(step.get("expect",{}),{})
	if expect.get("live") is Dictionary: expect=_merged(expect,expect.live)
	return expect

func _voice_row(job:Dictionary,status:String,why:String="")->Dictionary:
	return {"id":String(job.cid),"step":int(job.k)+1,"domain":String(job.domain),"source":String(job.source),"say":String(job.say),"status":status,"why":why,"ok":false,"fails":[],"reply":[]}

func _voice_step(job:Dictionary)->Dictionary:
	var id:=_prepare(job,"ideal")
	if id=="": return _voice_row(job,"not_reached",String(job.get("why_not","")))
	var w:=_world(job)
	var v:=LiveVoice.new()
	v.name="LiveEvalVoice"
	v.config_override={"endpoint":ENDPOINT,"api_key":SECRET,"model":"mock-voice","structured_output":true}
	v.send_hook=func(_a:String,_p:Dictionary,_n:int)->void: pass
	v.pick_hook=func(_a:String,_p:Dictionary)->PackedByteArray: return PackedByteArray()
	v.answer_hook=func(_a:String,_p:Dictionary)->PackedByteArray: return PackedByteArray()
	suite.add_child(v)
	var modal:Control=Modal.new()
	modal.voice=v; modal.audience_id=id
	suite.add_child(modal)
	# Fresh frames before the call (its timeout runs on frame time; see the
	# reader phase), then the opening lines that went to the stub are dropped,
	# as in the court evaluation.
	await suite.get_tree().process_frame
	await suite.get_tree().process_frame
	v.drain(id)
	if is_instance_valid(modal) and is_instance_valid(modal.speak_button): modal._refresh_footer()
	var ready:=_ready_to_speak(modal,id)
	if ready!="":
		modal.queue_free(); v.queue_free()
		return _voice_row(job,"not_reached",ready)
	var expect:=_voice_expect(job)
	var before:=measure(w,id)
	var lines_before:=(Hall.find(id).get("lines",[]) as Array).size()
	var body:=_body(_ideal_raw(job))
	v.order_hook=func(_a:String,_p:Dictionary)->PackedByteArray: return body
	v.rows.clear(); v.rejections.clear(); v.last_proposed=[]; v.last_problem.erase(id)
	if dry:
		var reply:=_dry_reply()
		v.send_hook=func(a:String,_p:Dictionary,attempt:int)->void: v.call_deferred("_on_response",HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),reply,a,attempt)
	else:
		v.meter=self
		v.config_override={}
		v.send_hook=Callable()
	var t0:=Time.get_ticks_msec()
	GameState.civic_api_enabled=not dry
	modal.speech_input.text=String(job.say)
	modal._speak()
	GameState.civic_api_enabled=false
	_check_untracked([v])
	while not v.idle() and Time.get_ticks_msec()-t0<VOICE_DEADLINE_MS:
		await suite.get_tree().process_frame
	var overdue:=not v.idle()
	if overdue: _force_stop(v)
	# The replies' deferred signals (lines_ready, persons_done) land.
	for i in 3: await suite.get_tree().process_frame
	if v.rows.is_empty() and stop_reason!="":
		# The cap refused this call: the offline lines that stood in are not judged.
		if is_instance_valid(modal): modal.queue_free()
		v.meter=null
		v.queue_free()
		return _voice_row(job,"not_run",stop_reason)
	var after:=measure(w,id)
	var lines:Array=(Hall.find(id).get("lines",[]) as Array).slice(lines_before)
	var row:=_voice_verdict(job,expect,before,after,lines,v,overdue)
	row["ms"]=Time.get_ticks_msec()-t0
	if is_instance_valid(modal): modal.queue_free()
	v.meter=null
	v.queue_free()
	return row

func _dry_reply()->PackedByteArray:
	var content:={"lines":[{"speaker_key":"envoy","text":"I hear you.","aside":false}],"mood_shift":0.0,"divine":"none"}
	return JSON.stringify({"id":"dry","model":"mock-voice","choices":[{"finish_reason":"stop","message":{"role":"assistant","content":JSON.stringify(content)}}],"usage":{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15}}).to_utf8_buffer()

func _force_stop(v:LiveVoice)->void:
	## A voice call past its backstop: cancelled and charged its estimate.
	for id in v._requests.keys():
		var http:Variant=(v._requests[id] as Dictionary).get("http")
		if http is HTTPRequest and is_instance_valid(http): (http as HTTPRequest).cancel_request()
	v._requests.clear()
	if v.reserved>0.0: settle(v,{"latency_ms":VOICE_DEADLINE_MS,"reason":"live evaluation deadline"})

static func numbers_in(text:String)->Array[int]:
	## Every number said: digits ("6000", "6,000") and words ("nine hundred",
	## "twenty-seven", "six thousand"), as the live voice says them.
	var out:Array[int]=[]
	var lower:=text.to_lower()
	for m in RegEx.create_from_string("\\d{1,3}(?:,\\d{3})+|\\d+").search_all(lower): out.append(int(m.get_string().replace(",","")))
	# Number words in English order; punctuation or any other word ends one
	# ("Undying One, thirty fighters" is 1 and 30, never 31).
	var total:=0; var chunk:=0; var last:=""
	var tokens:=RegEx.create_from_string("[a-z]+|[^a-z\\s]").search_all(lower.replace("-"," "))
	tokens.append(null)
	for m in tokens:
		var word:=(m as RegExMatch).get_string() if m!=null else ""
		var small:=int(UNIT_WORDS.get(word,-1))
		if small>=0 and small<10 and last in ["","ten","hundred","thousand"]:
			chunk+=small; last="unit"; continue
		if small>=10 and last in ["","hundred","thousand"]:
			chunk+=small; last="teen"; continue
		if TEN_WORDS.has(word) and last in ["","hundred","thousand"]:
			chunk+=int(TEN_WORDS[word]); last="ten"; continue
		if word=="hundred" and last in ["unit","teen","ten"]:
			chunk*=100; last="hundred"; continue
		if word=="thousand" and last in ["unit","teen","ten","hundred"]:
			total+=chunk*1000; chunk=0; last="thousand"; continue
		if word=="and" and last in ["hundred","thousand"]: continue
		if last!="": out.append(total+chunk)
		total=0; chunk=0; last=""
		# This word may start the next number ("one two" is 1 and 2).
		if small>=0 and small<10: chunk=small; last="unit"
		elif small>=10: chunk=small; last="teen"
		elif TEN_WORDS.has(word): chunk=int(TEN_WORDS[word]); last="ten"
	return out

static func _says_it(text:String,want:String)->bool:
	## The reply carries this: a number in digits or words, else the words.
	if want.is_valid_int(): return int(want) in numbers_in(text)
	return want.to_lower() in text.to_lower()

func _judge_reply(expect:Dictionary,before:Dictionary,after:Dictionary,texts:Array)->Array:
	## What a reply to a question must and must not say (the case's reply_*
	## and known; never "it is done" when nothing changed).
	var reply:=" \n".join(PackedStringArray(texts.map(func(t:Variant)->String: return String(t))))
	var ctx:={"before":before,"after":after}
	var fails:Array=[]
	if texts.is_empty(): fails.append("silent: nothing was said back")
	for token in expect.get("reply_has",[]):
		var want:=fill(String(token),ctx)
		if not _says_it(reply,want): fails.append("reply lacks '%s'" % want)
	if expect.has("reply_any"):
		var wants:Array=[]
		var any:=false
		for token in expect.reply_any:
			var want:=fill(String(token),ctx)
			wants.append(want)
			if _says_it(reply,want): any=true
		if not any: fails.append("reply has none of %s" % str(wants))
	for token in expect.get("reply_lacks",[]):
		var bad:=fill(String(token),ctx)
		if _says_it(reply,bad): fails.append("reply says '%s'" % bad)
	var lower:=reply.to_lower()
	if bool(expect.get("known",false)):
		for phrase in IGNORANCE:
			if phrase in lower: fails.append("claims ignorance ('%s')" % phrase); break
	var claimed:=""
	for phrase in DONE_CLAIMS:
		if phrase in lower: claimed=phrase; break
	var nothing:=""
	for phrase in NOTHING_WORDS:
		if phrase in lower: nothing=phrase; break
	if claimed!="" and nothing!="": fails.append("says '%s' and '%s' together" % [claimed,nothing])
	elif claimed!="" and String(before.get("_material",""))==String(after.get("_material","")) and not bool(expect.get("allow_done",false)): fails.append("says '%s' but nothing changed" % claimed)
	return fails

func _voice_verdict(job:Dictionary,expect:Dictionary,before:Dictionary,after:Dictionary,lines:Array,v:LiveVoice,overdue:bool)->Dictionary:
	var row:=_voice_row(job,"live")
	var said:Array=[]
	var texts:Array=[]
	for l in lines:
		if String((l as Dictionary).get("role",""))=="ruler": continue
		said.append("%s: %s" % [String((l as Dictionary).get("speaker","")) if String((l as Dictionary).get("speaker",""))!="" else "(narration)",String((l as Dictionary).get("text",""))])
		texts.append(String((l as Dictionary).get("text","")))
	var fails:=_judge_reply(expect,before,after,texts)
	var accepted:=false
	var stages:Array=[]
	var reasons:Array=[]
	var latency:Array=[]
	var usd:=0.0
	for r:Dictionary in v.rows:
		stages.append(String(r.get("stage","")))
		if bool(r.get("accepted",false)): accepted=true
		if String(r.get("reason",""))!="": reasons.append(String(r.reason).substr(0,300))
		latency.append(int(r.get("latency_ms",0)))
		usd+=float(r.get("_eval_usd",0.0))
	if v.rows.is_empty(): row.status="no_call"
	elif not accepted: row.status="fallback"
	if overdue: row.status="timeout"
	row["ok"]=fails.is_empty()
	row["fails"]=fails
	row["reply"]=said
	row["stages"]=stages
	row["reasons"]=reasons
	row["rejections"]=Array(v.rejections).duplicate()
	row["proposed"]=v.last_proposed.duplicate(true) if not bool(row.ok) or not accepted else []
	# What the voice was told, kept for a failed answer so it can be traced.
	row["prompt"]=v.last_prompt if not bool(row.ok) or not accepted else ""
	row["latency_ms"]=latency
	row["usd"]=usd
	return row

# --------------------------------------------------------------------------
# Spend: the ledger, reservations and receipts
# --------------------------------------------------------------------------

func estimate(payload:Dictionary)->float:
	var chars:=JSON.stringify(payload).length()
	var tin:=ceili(float(chars)/CHARS_PER_TOKEN)
	var tout:=int(payload.get("max_completion_tokens",1600))
	return float(tin)*PRICE_IN_PER_M/1000000.0+float(tout)*PRICE_OUT_PER_M/1000000.0

static func cost_of(row:Dictionary)->float:
	var tin:=int(row.get("prompt_tokens",0))
	var comp:=int(row.get("completion_tokens",0))
	var reasoning:=int(row.get("reasoning_tokens",0))
	var tout:=maxi(comp,int(row.get("total_tokens",0))-tin)
	# A provider that counts reasoning apart from the completion: add it.
	if reasoning>comp: tout+=reasoning
	return float(tin)*PRICE_IN_PER_M/1000000.0+float(tout)*PRICE_OUT_PER_M/1000000.0

func reserve(v:LiveVoice,payload:Dictionary,stage:String)->bool:
	if dry:
		_stop("a real call was attempted in a dry run"); return false
	if stop_reason!="": return false
	if max_calls>=0 and calls_started>=max_calls:
		_stop("COURT_LIVE_EVAL_MAX_CALLS reached (%d calls)" % max_calls); return false
	var est:=estimate(payload)
	var book:=_ledger_read()
	if book.has("error"):
		_stop("the spend ledger could not be read: "+String(book.error)); return false
	var spent:=float(book.cumulative_usd); var flying:=float(book.pending_usd)
	if spent+flying+est>cap:
		_stop("spend cap: $%.4f spent + $%.4f in flight + $%.4f for this call would pass $%.2f" % [spent,flying,est,cap]); return false
	book["pending_usd"]=flying+est
	var wrote:=_ledger_write(book)
	if wrote!="":
		_stop("the spend ledger could not be written: "+wrote); return false
	v.reserved=est; v.reserved_stage=stage
	calls_started+=1
	return true

func release(v:LiveVoice)->void:
	## The call never left (it could not start): its reservation is returned.
	var est:=v.reserved
	v.reserved=0.0
	calls_started=maxi(0,calls_started-1)
	var book:=_ledger_read()
	if book.has("error"): return
	book["pending_usd"]=maxf(0.0,float(book.pending_usd)-est)
	_ledger_write(book)

func settle(v:LiveVoice,row:Dictionary)->void:
	var est:=v.reserved
	v.reserved=0.0
	var estimated:=int(row.get("prompt_tokens",0))<=0 and int(row.get("completion_tokens",0))<=0
	var cost:=est if estimated else cost_of(row)
	run_usd+=cost; run_calls+=1
	run_tokens.prompt=int(run_tokens.prompt)+int(row.get("prompt_tokens",0))
	run_tokens.completion=int(run_tokens.completion)+int(row.get("completion_tokens",0))
	run_tokens.reasoning=int(run_tokens.reasoning)+int(row.get("reasoning_tokens",0))
	if estimated: charged_estimates+=1
	row["_eval_live"]=true; row["_eval_usd"]=cost; row["_eval_estimated"]=estimated; row["_eval_estimate"]=est
	var book:=_ledger_read()
	if book.has("error"):
		_stop("the spend ledger could not be read: "+String(book.error)); return
	book["pending_usd"]=maxf(0.0,float(book.pending_usd)-est)
	book["cumulative_usd"]=float(book.cumulative_usd)+cost
	book["calls"]=int(book.get("calls",0))+1
	var wrote:=_ledger_write(book)
	if wrote!="": _stop("the spend ledger could not be written: "+wrote)

func _check_untracked(also_ours:Array=[])->void:
	## Any live request that is not one of ours (none should exist) is charged.
	var found:=0
	var stack:Array[Node]=[suite.get_tree().root]
	while not stack.is_empty():
		var n:Node=stack.pop_back()
		for child in n.get_children(): stack.append(child)
		if not n is HTTPRequest: continue
		var parent:=n.get_parent()
		if parent is LiveVoice or parent in also_ours: continue
		if (n as HTTPRequest).get_http_client_status()==HTTPClient.STATUS_DISCONNECTED: continue
		if _seen_http.has(n.get_instance_id()): continue
		_seen_http[n.get_instance_id()]=true
		found+=1
	if found==0: return
	untracked+=found
	var cost:=UNTRACKED_USD*found
	run_usd+=cost
	print("LIVE COURT EVALUATION: %d live request(s) outside the evaluation's meter; charged $%.2f" % [found,cost])
	var book:=_ledger_read()
	if book.has("error"): return
	book["cumulative_usd"]=float(book.cumulative_usd)+cost
	book["untracked_calls"]=int(book.get("untracked_calls",0))+found
	_ledger_write(book)

func _ledger_read()->Dictionary:
	if not FileAccess.file_exists(ledger_path):
		return {"cap_usd":CAP_USD,"cumulative_usd":0.0,"pending_usd":0.0,"calls":0,"runs":[],
			"price":{"model":"gpt-6-luna","input_per_million_usd":PRICE_IN_PER_M,"output_per_million_usd":PRICE_OUT_PER_M,"note":"reasoning counts as output; cached input at the full price"}}
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(ledger_path))
	if not parsed is Dictionary: return {"error":"%s is not a JSON object" % ledger_path}
	var book:Dictionary=parsed
	if not (book.get("cumulative_usd") is float or book.get("cumulative_usd") is int): return {"error":"%s has no cumulative_usd" % ledger_path}
	if not (book.get("pending_usd") is float or book.get("pending_usd") is int): book["pending_usd"]=0.0
	if not book.get("runs") is Array: book["runs"]=[]
	return book

func _ledger_write(book:Dictionary)->String:
	DirAccess.make_dir_recursive_absolute(ledger_path.get_base_dir())
	var text:=JSON.stringify(book,"  ")
	if _key_probe!="" and _key_probe in text: return "refused: the key would have been written"
	var tmp:=ledger_path+".tmp"
	var f:=FileAccess.open(tmp,FileAccess.WRITE)
	if f==null: return "cannot open %s" % tmp
	f.store_string(text)
	f.close()
	if DirAccess.rename_absolute(tmp,ledger_path)!=OK:
		var g:=FileAccess.open(ledger_path,FileAccess.WRITE)
		if g==null: return "cannot write %s" % ledger_path
		g.store_string(text)
		g.close()
		DirAccess.remove_absolute(tmp)
	return ""

func _ledger_open()->String:
	var book:=_ledger_read()
	if book.has("error"): return "the spend ledger is unreadable (%s); fix or remove it by hand before spending more" % String(book.error)
	if float(book.pending_usd)>0.0:
		# A run that ended mid-call: what it held is counted as spent.
		book["unsettled_folded_usd"]=float(book.get("unsettled_folded_usd",0.0))+float(book.pending_usd)
		book["cumulative_usd"]=float(book.cumulative_usd)+float(book.pending_usd)
		book["pending_usd"]=0.0
	cumulative_at_start=float(book.cumulative_usd)
	if cumulative_at_start>=cap: return "the spend ledger is already at $%.4f of the $%.2f cap (%s)" % [cumulative_at_start,cap,ledger_path]
	book["cap_usd"]=CAP_USD
	(book.runs as Array).append({"started":run_started,"commit":commit,"filter":filter,"parts":",".join(parts),"max_calls":max_calls,"model":String(connection.get("reader_model","")),"usd":0.0,"calls":0,"finished":""})
	var wrote:=_ledger_write(book)
	return "" if wrote=="" else "the spend ledger could not be written: "+wrote

func _ledger_close(report:Dictionary)->void:
	var book:=_ledger_read()
	if book.has("error"): return
	var runs:Array=book.runs
	for i in range(runs.size()-1,-1,-1):
		if runs[i] is Dictionary and String((runs[i] as Dictionary).get("started",""))==run_started:
			var entry:Dictionary=runs[i]
			entry["finished"]=Time.get_datetime_string_from_system(false,true)
			entry["usd"]=run_usd; entry["calls"]=run_calls; entry["stopped"]=stop_reason
			entry["report"]=String(report.get("json_path",""))
			break
	_ledger_write(book)
	report["cumulative_usd"]=float(book.cumulative_usd)

# --------------------------------------------------------------------------
# Scoring the reader
# --------------------------------------------------------------------------

func _reduce(r:Dictionary)->Dictionary:
	## A reading (the order reader's schema) reduced to what is compared.
	if r.is_empty(): return {}
	var target:Dictionary=r.get("target",{}) if r.get("target") is Dictionary else {}
	var d:Dictionary=r.get("details",{}) if r.get("details") is Dictionary else {}
	var flags:Array=[]
	for f in OR.DETAIL_FLAGS:
		if d.get(f) is bool and bool(d.get(f)): flags.append(String(f))
	if "kill_all" in flags and not "kill_men" in flags: flags.append("kill_men")
	flags.sort()
	var ms:Array=[]
	if d.get("measures") is Array:
		for m in d.measures:
			if not str(m) in ms: ms.append(str(m))
	ms.sort()
	var dest:=String(d.get("destination","")) if d.get("destination") is String else ""
	if dest.begins_with("ours:"): dest="home"
	var ref:=String(target.get("ref","")) if target.get("ref") is String else ""
	if ref.begins_with("ours:"): ref="home"
	var count:=int(d.get("count",0)) if (d.get("count") is int or d.get("count") is float) else 0
	var stance:=String(d.get("stance","")) if d.get("stance") is String else ""
	var conf:Variant=r.get("confidence",0.0)
	return {"kind":String(r.get("kind","")),"action":String(r.get("action","")),"type":String(target.get("type","none")) if target.get("type") is String else "none","ref":ref,
		"flags":flags,"measures":ms,"stance":"firm" if stance=="" else stance,"count":count,"destination":dest,
		"resource":String(d.get("resource","")).to_lower() if d.get("resource") is String else "","confidence":float(conf) if (conf is float or conf is int) else 0.0,
		"clarify":String(r.get("clarify","")) if r.get("clarify") is String else "","actor":String(r.get("actor","")) if r.get("actor") is String else ""}

static func _diff(i:Dictionary,r:Dictionary)->Array:
	var out:Array=[]
	if String(i.action)!=String(r.action): out.append("action")
	if String(i.type)!=String(r.type) or String(i.ref)!=String(r.ref): out.append("target")
	var fi:Array=(i.flags as Array).filter(func(f:String)->bool: return not f in BENIGN_FLAGS)
	var fr:Array=(r.flags as Array).filter(func(f:String)->bool: return not f in BENIGN_FLAGS)
	if fi!=fr: out.append("flags")
	if i.measures!=r.measures: out.append("measures")
	if String(i.stance)!=String(r.stance): out.append("stance")
	if int(i.count)!=int(r.count): out.append("count")
	if String(i.destination)!=String(r.destination) and not (String(i.destination) in ["","home"] and String(r.destination) in ["","home"]): out.append("destination")
	if String(i.resource)!="" and not (String(i.resource) in String(r.resource) or (String(r.resource)!="" and String(r.resource) in String(i.resource))): out.append("resource")
	if String(i.kind)!=String(r.kind): out.append("kind")
	if (i.flags as Array)!=(r.flags as Array) and not "flags" in out: out.append("minor_flags")
	return out

static func _rule_equivalent(i:Dictionary,r:Dictionary)->bool:
	## Readings the engine treats alike, when no plan could be compared.
	var ia:=String(i.action); var ra:=String(r.action)
	var group_types:=["group","town","people"]
	if ia==ra and ia in ["confirm","cancel"]: return true
	if ia=="none" and ra=="none" and String(i.kind) in ["question","speech"] and String(r.kind) in ["question","speech"]: return true
	var kill_pair:=(ia=="town_fate" and ra=="kill") or (ia=="kill" and ra=="town_fate")
	if ia!=ra and not kill_pair: return false
	if String(i.ref)!=String(r.ref): return false
	if String(i.type)!=String(r.type) and not (String(i.type) in group_types and String(r.type) in group_types): return false
	var fi:Array=(i.flags as Array).filter(func(f:String)->bool: return not f in BENIGN_FLAGS)
	var fr:Array=(r.flags as Array).filter(func(f:String)->bool: return not f in BENIGN_FLAGS)
	if kill_pair:
		if not "kill_men" in fi: fi.append("kill_men")
		if not "kill_men" in fr: fr.append("kill_men")
		fi.sort(); fr.sort()
	return fi==fr and i.measures==r.measures

static func _grave_sig(sig:String)->bool:
	if sig.begins_with("person:kill") or sig.begins_with("person:maim"): return true
	if not sig.begins_with("war:"): return false
	var bits:=sig.split("|")
	var kind:=bits[0].trim_prefix("war:")
	if kind in ["attack","siege","raid","storm","group_maim"]: return true
	var fate:=bits[2] if bits.size()>2 else ""
	for f in ["kill_men","kill_all","raze","captives","leave","harm=kill"]:
		if f in fate: return true
	var measures:=bits[3] if bits.size()>3 else ""
	return "execute_ringleaders" in measures

func _score_reader()->void:
	for job in jobs:
		var status:=String(job.status)
		job["verdict"]=""; job["codes"]=[]; job["severity"]=0
		if status in ["no_ideal","not_run","not_reached"]: job.verdict=status; continue
		if status in ["timeout","cut_off","failed","asking","pending"]:
			job.verdict="failed"; job.codes=[status if status!="asking" else "no_answer"]; continue
		var ideal:=_reduce(_ideal_raw(job))
		if job.has("ideal_rejected"):
			# The ideal names what this state's brief does not list: no target.
			ideal.type="none"; ideal.ref=""; ideal.destination=""
		var real:=_reduce(job.raw as Dictionary)
		job["ideal_norm"]=ideal; job["real_norm"]=real
		if status=="rejected":
			job.verdict="wrong"; job.codes=["rejected: "+String(job.get("reason","")).trim_prefix("order reading rejected: ")]
			job.severity=_severity(job,["rejected"]); continue
		var diffs:=_diff(ideal,real)
		var major:=diffs.filter(func(d:String)->bool: return d!="minor_flags")
		var known:=job.has("plan_ideal") and job.has("plan_real")
		var same_plan:=known and String(job.plan_ideal)==String(job.plan_real)
		# The engine played both readings: the same world before and after.
		var same_effect:=bool(job.get("same_effect",false))
		if major.is_empty() and (not known or same_plan):
			job.verdict="exact" if diffs.is_empty() else "equivalent"
			job.codes=diffs
		elif same_plan or same_effect or (not known and _rule_equivalent(ideal,real)):
			job.verdict="equivalent"; job.codes=diffs+(["same effect"] if not same_plan and same_effect else [])
		elif major.is_empty():
			job.verdict="wrong"
			if String(job.plan_real)=="clarify": job.codes=["confidence: asked instead of acting"]
			elif String(job.plan_ideal)=="clarify": job.codes=["confidence: acted without asking"]
			else: job.codes=diffs+["plan"]
		else:
			job.verdict="wrong"; job.codes=major
	# A step after a misread (or a failed reading) in its case was read in a
	# state its case was not written for.
	for job in jobs:
		job["after_misread"]=false
		for k in int(job.k):
			if String(_job(String(job.cid),k).get("verdict","")) in ["wrong","failed"]: job.after_misread=true
		if String(job.verdict)=="wrong": job.severity=_severity(job,job.codes)

func _severity(job:Dictionary,codes:Array)->int:
	var pi:=String(job.get("plan_ideal","")); var pr:=String(job.get("plan_real",""))
	var hesitant:=not codes.is_empty() and String(codes[0]).begins_with("confidence")
	var s:=10
	if (pr.begins_with("person:kill") or pr.begins_with("person:maim")) and not (pi.begins_with("person:kill") or pi.begins_with("person:maim")): s=100
	elif _grave_sig(pr) and not _grave_sig(pi) and pr!="": s=90
	elif _grave_sig(pi) and pr in ["speak","legacy"]: s=80
	elif _grave_sig(pi) and _grave_sig(pr) and pi!=pr: s=75
	elif "action" in codes: s=50
	elif "rejected" in codes: s=45
	elif "target" in codes: s=40
	elif hesitant: s=35
	elif "flags" in codes or "measures" in codes or "count" in codes or "stance" in codes: s=30
	elif "kind" in codes: s=20
	for row in engine_rows:
		if String(row.id)==String(job.cid) and bool(row.ideal_ok) and not bool(row.real_ok): s+=8
	# Read wrong, but the step still did what its case wanted.
	if bool(job.get("step_ok",false)): s-=20
	if bool(job.get("after_misread",false)): s-=40
	if String(job.source)=="user": s+=5
	return s

# --------------------------------------------------------------------------
# The report
# --------------------------------------------------------------------------

func _names(w:Dictionary)->Dictionary:
	var info:Dictionary=w.get("info",{})
	var out:={"home":"home"}
	for pair in [["tsaren_id","Tsaren"],["stonefield_id","Stonefield"],["eldwick_id","Eldwick"]]:
		if info.has(pair[0]): out["town:"+String(info[pair[0]])]=String(pair[1])
	if info.has("civ_id"): out["people:"+String(info.civ_id)]="Esurai"
	if info.has("varesh_id"): out["people:"+String(info.varesh_id)]="Varesh"
	if info.has("rovik_fid"): out["figure:"+String(info.rovik_fid)]="Rovik"
	if info.has("band_id"): out["band:%d" % int(info.band_id)]="Rovik's band"
	var pids:Dictionary=info.get("pids",{})
	for role in pids: out["person:%d" % int(pids[role])]=String(role)
	return out

func _words(n:Dictionary,w:Dictionary)->String:
	## A reading in one short line, with names for ids.
	if n.is_empty(): return "(no reading)"
	var names:=_names(w)
	var ref:=String(n.ref)
	var who:=String(names.get(ref,ref)) if ref!="" else ""
	var out:="%s %s" % [String(n.kind),String(n.action)]
	if who!="" and who==ref: out+=" %s" % ref
	elif String(n.type)!="none" or who!="": out+=" %s:%s" % [String(n.type),who]
	var extra:=PackedStringArray()
	if not (n.flags as Array).is_empty(): extra.append(",".join(PackedStringArray(n.flags)))
	if not (n.measures as Array).is_empty(): extra.append("measures "+",".join(PackedStringArray(n.measures)))
	if String(n.stance)!="firm": extra.append("stance "+String(n.stance))
	if int(n.count)>0: extra.append("count %d" % int(n.count))
	if String(n.destination)!="": extra.append("to "+String(names.get(String(n.destination),String(n.destination))))
	if String(n.resource)!="": extra.append(String(n.resource))
	if not extra.is_empty(): out+=" {"+"; ".join(extra)+"}"
	out+=" c%.2f" % float(n.confidence)
	if String(n.clarify)!="": out+=" ask:\"%s\"" % String(n.clarify).substr(0,90)
	return out

static func _pct(part:int,whole:int)->String:
	return "-" if whole<=0 else "%d%%" % roundi(100.0*float(part)/float(whole))

static func _quantile(values:Array,q:float)->int:
	if values.is_empty(): return 0
	var s:=values.duplicate(); s.sort()
	return int(s[clampi(int(ceil(q*float(s.size())))-1,0,s.size()-1)])

func _report()->Dictionary:
	_score_reader()
	var board:={}
	# ---- the reader ----
	var verdicts:=["exact","equivalent","wrong","failed"]
	var by_domain:={}; var by_source:={}; var totals:={}; var codes:={}
	var lat:Array=[]; var timeouts:=0; var cut:=0; var rejected:=0; var consulted:=0; var scored:=0; var bad_ideals:Array=[]
	var by_consulted:={"exact":0,"equivalent":0,"wrong":0,"failed":0}; var chained:=0; var harmless:=0; var stale:Array=[]
	for v in verdicts+["not_run","not_reached","no_ideal"]: totals[v]=0
	for job in jobs:
		var verdict:=String(job.verdict)
		totals[verdict]=int(totals.get(verdict,0))+1
		if not verdict in verdicts: continue
		scored+=1
		for key in [["d",String(job.domain)],["s",String(job.source)]]:
			var table:Dictionary=by_domain if key[0]=="d" else by_source
			if not table.has(key[1]): table[key[1]]={"exact":0,"equivalent":0,"wrong":0,"failed":0}
			table[key[1]][verdict]=int(table[key[1]][verdict])+1
		if verdict=="wrong":
			var code:=String((job.codes as Array)[0]) if not (job.codes as Array).is_empty() else "?"
			if code.begins_with("rejected"): code="rejected"
			codes[code]=int(codes.get(code,0))+1
		if int(job.get("latency_ms",0))>0: lat.append(int(job.latency_ms))
		if String(job.status)=="timeout": timeouts+=1
		if String(job.status)=="cut_off": cut+=1
		if String(job.status)=="rejected": rejected+=1
		if bool(job.get("consulted",false)):
			consulted+=1
			by_consulted[verdict]=int(by_consulted[verdict])+1
		if verdict=="wrong" and bool(job.get("after_misread",false)): chained+=1
		if verdict=="wrong" and bool(job.get("step_ok",false)): harmless+=1
		if job.has("ideal_rejected"): bad_ideals.append("%s (%s)" % [String(job.cid),String(job.ideal_rejected)])
		if bool(job.get("brief_changed",false)): stale.append(String(job.cid) if int(job.k)==0 else "%s s%d" % [String(job.cid),int(job.k)+1])
	board["reader"]={"scored":scored,"totals":totals,"by_domain":by_domain,"by_source":by_source,"wrong_by":codes,"latency_ms":{"median":_quantile(lat,0.5),"p90":_quantile(lat,0.9),"max":_quantile(lat,1.0),"n":lat.size()},
		"timeouts":timeouts,"cut_off":cut,"rejected":rejected,"consulted_by_the_court":consulted,"where_consulted":by_consulted,"wrong_after_an_earlier_misread":chained,
		"wrong_but_the_step_still_right":harmless,"ideals_the_brief_rejects":bad_ideals,"brief_changed":stale}
	# ---- the engine ----
	var e:={"cases":engine_rows.size(),"ideal_pass":0,"real_pass":0,"broke":[],"fixed":[],"by_domain":{},"user":{"cases":0,"ideal_pass":0,"real_pass":0}}
	for row in engine_rows:
		var d:=String(row.domain)
		if not (e.by_domain as Dictionary).has(d): e.by_domain[d]={"cases":0,"ideal_pass":0,"real_pass":0}
		e.by_domain[d].cases+=1
		if bool(row.ideal_ok): e.ideal_pass+=1; e.by_domain[d].ideal_pass+=1
		if bool(row.real_ok): e.real_pass+=1; e.by_domain[d].real_pass+=1
		if String(row.source)=="user":
			e.user.cases+=1
			if bool(row.ideal_ok): e.user.ideal_pass+=1
			if bool(row.real_ok): e.user.real_pass+=1
		if bool(row.ideal_ok) and not bool(row.real_ok): (e.broke as Array).append(String(row.id))
		if bool(row.real_ok) and not bool(row.ideal_ok): (e.fixed as Array).append(String(row.id))
	board["engine"]=e
	# ---- the voice ----
	var vb:={"steps":voice_rows.size(),"run":0,"passed":0,"live":0,"live_passed":0,"fallback":0,"no_call":0,"timeout":0,"not_run":0,"not_reached":0,"fails_by":{},"rejections_by":{},"latency_ms":{}}
	var vlat:Array=[]
	for row in voice_rows:
		var st:=String(row.status)
		if st in ["not_run","not_reached"]: vb[st]=int(vb[st])+1; continue
		vb.run+=1
		if bool(row.ok): vb.passed+=1
		vb[st]=int(vb.get(st,0))+1
		if st=="live" and bool(row.ok): vb.live_passed+=1
		for f in row.fails:
			var key:=String(f).get_slice(" '",0).get_slice(" (",0)
			if key.begins_with("reply has none"): key="reply has none of the facts"
			vb.fails_by[key]=int((vb.fails_by as Dictionary).get(key,0))+1
		for r in row.get("rejections",[]):
			var key2:=String(r).get_slice(":",0).substr(0,60)
			vb.rejections_by[key2]=int((vb.rejections_by as Dictionary).get(key2,0))+1
		for ms in row.get("latency_ms",[]): vlat.append(int(ms))
	vb.latency_ms={"median":_quantile(vlat,0.5),"p90":_quantile(vlat,0.9),"max":_quantile(vlat,1.0),"n":vlat.size()}
	board["voice"]=vb
	# ---- spend ----
	board["spend"]={"run_usd":run_usd,"calls":run_calls,"tokens":run_tokens.duplicate(),"charged_estimates":charged_estimates,"untracked_calls":untracked,
		"cumulative_usd_at_start":cumulative_at_start,"cumulative_usd":cumulative_at_start+run_usd,"cap_usd":cap,"ledger":ledger_path,"dry":dry}
	# ---- the worst misreads (a step read after an earlier misread is left out:
	# its state is not the one its case was written for) ----
	var wrong:Array=jobs.filter(func(j:Dictionary)->bool: return String(j.verdict)=="wrong" and not bool(j.get("after_misread",false)))
	wrong.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.severity)>int(b.severity) if int(a.severity)!=int(b.severity) else String(a.cid)<String(b.cid))
	var broken:={}
	for row in engine_rows:
		if bool(row.ideal_ok) and not bool(row.real_ok): broken[String(row.id)]=true
	var worst:Array=[]
	for job in wrong.slice(0,WORST_SHOWN):
		worst.append({"id":String(job.cid),"step":int(job.k)+1,"domain":String(job.domain),"source":String(job.source),"say":String(job.say),"severity":int(job.severity),"codes":job.codes,
			"ideal":_words(job.get("ideal_norm",{}),_world(job)),"model":_words(job.get("real_norm",{}),_world(job)),"plan_ideal":String(job.get("plan_ideal","")),"plan_real":String(job.get("plan_real","")),
			"consulted":bool(job.get("consulted",false)),"step_ok":bool(job.get("step_ok",false)),"case_broken":broken.has(String(job.cid)),"brief_changed":bool(job.get("brief_changed",false))})
	board["worst"]=worst
	var elapsed:=float(Time.get_ticks_msec()-started_ms)/1000.0
	var meta:={"started":run_started,"seconds":elapsed,"commit":commit,"model":String(connection.get("reader_model","")),"endpoint_host":String(connection.get("endpoint_host","")),
		"structured_output":bool(connection.get("structured_output",false)),"filter":filter,"parts":",".join(parts),"max_calls":max_calls,"cases":selected.size(),"steps":jobs.size(),"stopped":stop_reason,"dry":dry,
		"replay_of":replay_path,"replay_of_commit":String(connection.get("replay_of_commit",""))}
	var detail_jobs:Array=[]
	for job in jobs:
		var copy:Dictionary={}
		for key in ["cid","k","domain","source","say","status","verdict","codes","severity","consulted","after_misread","same_effect","step_ok","ideal_rejected","plan_ideal","plan_real","latency_ms","tokens","usd","reason","finish","http","transport","why_not","court_calls","brief_md5","brief_changed","brief_now"]:
			if job.has(key): copy[key]=job[key]
		copy["ideal"]=_words(job.get("ideal_norm",_reduce(_ideal_raw(job)) if job.ideal is Dictionary else {}),_world(job))
		copy["model"]=_words(job.get("real_norm",{}),_world(job))
		copy["model_raw"]=job.get("raw",{})
		# What the reader was shown, kept where the reading went wrong (or the
		# brief moved), so a misread can be traced to its words and lists.
		if String(job.get("verdict","")) in ["wrong","failed"] or bool(job.get("brief_changed",false)): copy["brief"]=String(job.get("brief",""))
		detail_jobs.append(copy)
	var report:={"meta":meta,"board":board,"reader_steps":detail_jobs,"engine_cases":engine_rows,"voice_steps":voice_rows}
	var text:=_render(board,meta)
	report["text"]=text
	# The key never leaves memory: anything carrying it is withheld.
	var json:=JSON.stringify(report,"  ")
	var leak:=_leaks(json) or _leaks(text)
	report["key_leak"]=leak
	if leak:
		text="(the report was withheld: it carried the API key)"
		json=JSON.stringify({"meta":meta,"withheld":"the report carried the API key"})
	print(text)
	DirAccess.make_dir_recursive_absolute(out_dir)
	var stamp:=run_started.replace("-","").replace(":","").replace(" ","-")
	var base:=out_dir.path_join("live_eval_%s%s" % [stamp,"_dry" if dry else ("_replay" if replay_path!="" else "")])
	var f:=FileAccess.open(base+".json",FileAccess.WRITE)
	if f!=null: f.store_string(json); f.close()
	var g:=FileAccess.open(base+".md",FileAccess.WRITE)
	if g!=null: g.store_string(_markdown(board,meta) if not leak else text); g.close()
	report["json_path"]=base+".json"
	report["md_path"]=base+".md"
	print("LIVE COURT EVALUATION report: %s (.md beside it)" % (base+".json"))
	return report

func _leaks(text:String)->bool:
	if _key_probe=="": return false
	if _key_probe in text: return true
	return _key_probe.length()>=24 and _key_probe.substr(_key_probe.length()-16) in text

func _render(board:Dictionary,meta:Dictionary)->String:
	var out:=PackedStringArray()
	var r:Dictionary=board.reader; var t:Dictionary=r.totals
	out.append("")
	out.append("======================== LIVE COURT EVALUATION ========================")
	var how:="model %s" % String(meta.model)
	if bool(meta.dry): how="DRY (no model)"
	elif String(meta.replay_of)!="": how="REPLAY of the %s readings in %s (commit %s; no model)" % [String(meta.model),String(meta.replay_of).get_file(),String(meta.replay_of_commit)]
	out.append("%s   commit %s   %d cases, %d steps   %.0f s%s" % [how,String(meta.commit),int(meta.cases),int(meta.steps),float(meta.seconds),("   STOPPED: "+String(meta.stopped)) if String(meta.stopped)!="" else ""])
	var scored:=int(r.scored)
	out.append("READER  %d scored: exact %d  equivalent %d  wrong %d  failed %d   (right %s)   not run %d, not reached %d" % [scored,int(t.exact),int(t.equivalent),int(t.wrong),int(t.failed),_pct(int(t.exact)+int(t.equivalent),scored),int(t.not_run),int(t.not_reached)])
	var wc:Dictionary=r.where_consulted
	var nc:=int(wc.exact)+int(wc.equivalent)+int(wc.wrong)+int(wc.failed)
	out.append("  where the court asks the reader (%d steps): exact %d  equivalent %d  wrong %d  failed %d   (right %s)" % [nc,int(wc.exact),int(wc.equivalent),int(wc.wrong),int(wc.failed),_pct(int(wc.exact)+int(wc.equivalent),nc)])
	out.append("  of the wrong: %d came after an earlier misread in the same case; %d still did what the step needed" % [int(r.wrong_after_an_earlier_misread),int(r.wrong_but_the_step_still_right)])
	out.append("  by domain            exact equiv wrong fail")
	var ds:=(r.by_domain as Dictionary).keys(); ds.sort()
	for d in ds:
		var row:Dictionary=r.by_domain[d]
		out.append("  %-18s %5d %5d %5d %4d" % [String(d),int(row.exact),int(row.equivalent),int(row.wrong),int(row.failed)])
	for src in ["user","variant","design"]:
		if (r.by_source as Dictionary).has(src):
			var row2:Dictionary=r.by_source[src]
			var n:=int(row2.exact)+int(row2.equivalent)+int(row2.wrong)+int(row2.failed)
			out.append("  %-18s exact %d  equivalent %d  wrong %d  failed %d  (right %s)" % ["the user's own lines" if src=="user" else src,int(row2.exact),int(row2.equivalent),int(row2.wrong),int(row2.failed),_pct(int(row2.exact)+int(row2.equivalent),n)])
	var wb:Array=(r.wrong_by as Dictionary).keys()
	wb.sort_custom(func(a:Variant,b:Variant)->bool: return int(r.wrong_by[a])>int(r.wrong_by[b]))
	out.append("  wrong by: "+", ".join(PackedStringArray(wb.map(func(k:Variant)->String: return "%s %d" % [String(k),int(r.wrong_by[k])]))))
	var l:Dictionary=r.latency_ms
	out.append("  latency median %.1f s, p90 %.1f s, max %.1f s (%d calls); timeouts %d, cut off %d, rejected %d; the court consults the reader on %d of %d scored steps" % [float(l.median)/1000.0,float(l.p90)/1000.0,float(l.max)/1000.0,int(l.n),int(r.timeouts),int(r.cut_off),int(r.rejected),int(r.consulted_by_the_court),scored])
	if not (r.ideals_the_brief_rejects as Array).is_empty(): out.append("  corpus: %d ideal readings name what their state's brief does not list (judged without that target): %s" % [(r.ideals_the_brief_rejects as Array).size(),", ".join(PackedStringArray(r.ideals_the_brief_rejects))])
	var stale:Array=r.get("brief_changed",[])
	if String(meta.replay_of)!="" and not stale.is_empty(): out.append("  %d steps' briefs changed since the recording (their readings may be stale; ask them live again): %s" % [stale.size(),", ".join(PackedStringArray(stale))])
	elif String(meta.replay_of)=="" and not stale.is_empty(): out.append("  WARNING: %d steps were read from a brief that differs from the one their engine replay built (the evaluation's states disagree): %s" % [stale.size(),", ".join(PackedStringArray(stale))])
	var e:Dictionary=board.engine
	out.append("ENGINE  (each case's expectations)  with the ideal reading %d/%d   with the model's %d/%d   broken by the reader %d, fixed %d" % [int(e.ideal_pass),int(e.cases),int(e.real_pass),int(e.cases),(e.broke as Array).size(),(e.fixed as Array).size()])
	out.append("  the user's own lines: ideal %d/%d, model %d/%d" % [int(e.user.ideal_pass),int(e.user.cases),int(e.user.real_pass),int(e.user.cases)])
	var eds:=(e.by_domain as Dictionary).keys(); eds.sort()
	for d in eds:
		var row3:Dictionary=e.by_domain[d]
		if int(row3.ideal_pass)!=int(row3.real_pass): out.append("  %-18s ideal %d/%d  model %d/%d" % [String(d),int(row3.ideal_pass),int(row3.cases),int(row3.real_pass),int(row3.cases)])
	if not (e.broke as Array).is_empty(): out.append("  broken: "+", ".join(PackedStringArray(e.broke)))
	var v:Dictionary=board.voice
	out.append("VOICE   %d question steps run: pass %d (%s); live replies %d (pass %d), fell back offline %d, no live call %d, timeouts %d; not run %d" % [int(v.run),int(v.passed),_pct(int(v.passed),int(v.run)),int(v.live),int(v.live_passed),int(v.fallback),int(v.no_call),int(v.timeout),int(v.not_run)+int(v.not_reached)])
	if not (v.fails_by as Dictionary).is_empty(): out.append("  failures: "+", ".join(PackedStringArray((v.fails_by as Dictionary).keys().map(func(k:Variant)->String: return "%s %d" % [String(k),int(v.fails_by[k])]))))
	if not (v.rejections_by as Dictionary).is_empty(): out.append("  rejected lines: "+", ".join(PackedStringArray((v.rejections_by as Dictionary).keys().map(func(k:Variant)->String: return "%s %d" % [String(k),int(v.rejections_by[k])]))))
	var vl:Dictionary=v.latency_ms
	out.append("  latency median %.1f s, p90 %.1f s (%d calls)" % [float(vl.median)/1000.0,float(vl.p90)/1000.0,int(vl.n)])
	var s:Dictionary=board.spend
	out.append("SPEND   this run $%.4f (%d calls; %d prompt, %d completion of which %d reasoning tokens; %d charged at estimate; %d untracked)   all runs $%.4f of $%.2f" % [float(s.run_usd),int(s.calls),int(s.tokens.prompt),int(s.tokens.completion),int(s.tokens.reasoning),int(s.charged_estimates),int(s.untracked_calls),float(s.cumulative_usd),float(s.cap_usd)])
	out.append("WORST MISREADS")
	var n2:=0
	for m in board.worst:
		n2+=1
		out.append("  %d. [%s%s] %s s%d  \"%s\"" % [n2,String(m.domain),", user" if String(m.source)=="user" else "",String(m.id),int(m.step),String(m.say).substr(0,120)])
		out.append("     ideal: %s" % String(m.ideal))
		out.append("     model: %s   (%s)" % [String(m.model),", ".join(PackedStringArray((m.codes as Array).map(func(c:Variant)->String: return String(c))))])
		if String(m.plan_ideal)!=String(m.plan_real): out.append("     engine: %s  ->  %s" % [String(m.plan_ideal),String(m.plan_real)])
		var notes:=PackedStringArray()
		if bool(m.case_broken): notes.append("the case fails with this reading")
		elif bool(m.step_ok): notes.append("the step still did what its case wanted")
		if not bool(m.consulted): notes.append("the court does not ask the reader here")
		if bool(m.get("brief_changed",false)): notes.append("its brief changed since the reading was made")
		if not notes.is_empty(): out.append("     ("+"; ".join(notes)+")")
	var vfails:=voice_rows.filter(func(x:Dictionary)->bool: return not bool(x.ok) and not String(x.status) in ["not_run","not_reached"])
	if not vfails.is_empty():
		out.append("VOICE FAILURES")
		for x in vfails.slice(0,12):
			out.append("  %s [%s] \"%s\": %s" % [String(x.id),String(x.status),String(x.say).substr(0,80),"; ".join(PackedStringArray((x.fails as Array).map(func(c:Variant)->String: return String(c))))])
			for said in (x.reply as Array).slice(0,3): out.append("     | %s" % String(said).substr(0,220))
	out.append("========================================================================")
	return "\n".join(out)

func _markdown(board:Dictionary,meta:Dictionary)->String:
	var md:=PackedStringArray()
	var r:Dictionary=board.reader; var t:Dictionary=r.totals; var e:Dictionary=board.engine; var v:Dictionary=board.voice; var s:Dictionary=board.spend
	md.append("# Live court evaluation, %s" % String(meta.started))
	md.append("")
	md.append("Model `%s` at %s, commit `%s`, %d cases / %d steps%s%s." % [String(meta.model),String(meta.endpoint_host),String(meta.commit),int(meta.cases),int(meta.steps),(", filter `%s`" % String(meta.filter)) if String(meta.filter)!="" else "",(". **Stopped:** "+String(meta.stopped)) if String(meta.stopped)!="" else ""])
	md.append("")
	md.append("| | result |")
	md.append("|---|---|")
	md.append("| Reader (all steps) | exact %d, equivalent %d, wrong %d, failed %d of %d (right %s) |" % [int(t.exact),int(t.equivalent),int(t.wrong),int(t.failed),int(r.scored),_pct(int(t.exact)+int(t.equivalent),int(r.scored))])
	var wc:Dictionary=r.where_consulted
	md.append("| Reader, where the court asks it | exact %d, equivalent %d, wrong %d, failed %d |" % [int(wc.exact),int(wc.equivalent),int(wc.wrong),int(wc.failed)])
	if (r.by_source as Dictionary).has("user"):
		var u:Dictionary=r.by_source.user
		md.append("| Reader, the user's own lines | exact %d, equivalent %d, wrong %d, failed %d |" % [int(u.exact),int(u.equivalent),int(u.wrong),int(u.failed)])
	md.append("| Engine correct | ideal reading %d/%d, model's reading %d/%d (reader broke %d) |" % [int(e.ideal_pass),int(e.cases),int(e.real_pass),int(e.cases),(e.broke as Array).size()])
	md.append("| Voice replies (questions) | %d/%d pass; %d fell back offline |" % [int(v.passed),int(v.run),int(v.fallback)])
	md.append("| Reader latency | median %.1f s, p90 %.1f s; %d timeouts, %d cut off |" % [float(r.latency_ms.median)/1000.0,float(r.latency_ms.p90)/1000.0,int(r.timeouts),int(r.cut_off)])
	md.append("| Spend | this run $%.4f (%d calls); all runs $%.4f of $%.2f |" % [float(s.run_usd),int(s.calls),float(s.cumulative_usd),float(s.cap_usd)])
	md.append("")
	md.append("## Reader by domain")
	md.append("")
	md.append("| domain | exact | equivalent | wrong | failed |")
	md.append("|---|---|---|---|---|")
	var ds:=(r.by_domain as Dictionary).keys(); ds.sort()
	for d in ds:
		var row:Dictionary=r.by_domain[d]
		md.append("| %s | %d | %d | %d | %d |" % [String(d),int(row.exact),int(row.equivalent),int(row.wrong),int(row.failed)])
	md.append("")
	md.append("## Worst misreads")
	md.append("")
	var n:=0
	for m in board.worst:
		n+=1
		md.append("%d. `%s` (%s%s): \"%s\"" % [n,String(m.id),String(m.domain),", user's words" if String(m.source)=="user" else "",String(m.say)])
		md.append("   - ideal: `%s`" % String(m.ideal))
		md.append("   - model: `%s` (%s)" % [String(m.model),", ".join(PackedStringArray((m.codes as Array).map(func(c:Variant)->String: return String(c))))])
		if String(m.plan_ideal)!=String(m.plan_real): md.append("   - engine plan: `%s` instead of `%s`" % [String(m.plan_real),String(m.plan_ideal)])
	md.append("")
	if not (e.broke as Array).is_empty():
		md.append("Cases the model's reading broke: "+", ".join(PackedStringArray((e.broke as Array).map(func(x:Variant)->String: return "`%s`" % String(x)))))
		md.append("")
	return "\n".join(md)
