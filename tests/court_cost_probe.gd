extends Node
## Cost harness for the live court voice, with a mocked model: counts model
## calls and estimated tokens per audience and per exchange (one ruler line and
## its reply), and how many court-member lines (asides, chime-ins) reach the
## hall. The mock is deliberately chatty: every cast member it is offered gets
## a line, some of them praise or maxims, as a real model tends to. Runs the
## Audience Hall's "normal" stone-age world (audience_hall_probe) for a year.
##   <godot> --headless --path <worktree> res://tests/court_cost_probe.tscn
## Prints COURT_COST ... lines; exits 0 (a measurement, not a gate).

const HALL:=preload("res://scripts/audience_hall.gd")
const HallProbe:=preload("res://tests/audience_hall_probe.gd")
const Voice:=preload("res://scripts/audience_voice.gd")
const CV:=preload("res://scripts/character_voice.gd")
const ASKS:=["Why bring this to us now?","What do you gain from this?","And if we say no?","How sure are you?"]
const CHATTER:=["A wise choice, Great One, as ever.","A full store is a quiet camp.","They owe us twenty food from last winter, and they have not paid it.","Gift-food fills bellies, but a fox leaves tracks.","Their hunters were seen in the upper valley three days ago."]

const OPENS:=["We came about the business in front of you.","Our chief sent me with this and nothing else.","I walked six days to say it plainly.","This is what our people want from yours.","I will not dress it up for you.","Hear the terms as our chief gave them.","We are not here to waste your fire."]
const ENDS:=["Answer when you are ready.","The hunters are waiting on your word.","Our camp waits for my return.","I say it once, and plainly.","Weigh it with your elders.","The snow will not wait for us.","Send word by the river path.","We keep our side of it."]
var probe:Node
var voice:Node
var calls:=0
var prompt_tokens:=0
var completion_tokens:=0
var stage_calls:={}
var audiences:=0
var exchanges:=0
var exchange_calls:=0
var exchange_tokens:=0
var court_lines:=0
var in_exchange:=false

func _ready()->void:
	probe=HallProbe.new()
	probe._setup_world()
	voice=Voice.new(); add_child(voice)
	voice.force_offline=false
	voice.config_override={"endpoint":"https://mock.invalid/v1/chat/completions","api_key":"mock-key","model":"mock-model","structured_output":true}
	voice.send_hook=_mock_send
	var founding:Array=preload("res://scripts/founding_knowledge.gd").PRACTICES.duplicate()
	CV.knowledge_override["player"]=founding.duplicate()
	for civ in CivilizationSystem.civilizations: CV.knowledge_override[String(civ.id)]=founding.duplicate()
	var ids:Array[String]=probe._civ_ids()
	HALL.set_frequency("normal")
	var rng:=RandomNumberGenerator.new(); rng.seed=int(probe.SEED)
	for day in range(1,366):
		GameState.elapsed_days=day
		probe._refill()
		probe._world_events(day,ids,rng)
		for audience in HALL.daily(day):
			await _play(audience)
		if audiences>=16: break
	var a:=maxi(audiences,1)
	var e:=maxi(exchanges,1)
	print("COURT_COST audiences=%d calls=%d calls_per_audience=%.2f tokens_per_audience=%d prompt_tokens_per_call=%d" % [audiences,calls,float(calls)/a,(prompt_tokens+completion_tokens)/a,prompt_tokens/maxi(calls,1)])
	print("COURT_COST exchanges=%d calls_per_exchange=%.2f tokens_per_exchange=%d" % [exchanges,float(exchange_calls)/e,exchange_tokens/e])
	print("COURT_COST court_lines=%d court_lines_per_audience=%.2f stage_calls=%s" % [court_lines,float(court_lines)/a,JSON.stringify(stage_calls)])
	CV.knowledge_override.clear()
	get_tree().quit(0)

func _play(audience:Dictionary)->void:
	var id:=String(audience.id)
	audiences+=1
	var envoy_name:=String((audience.get("speaker",{}) as Dictionary).get("name",""))
	voice.open_scene(id)
	await _settle(id)
	# One exchange: the ruler asks something; every third time, of a named official.
	var ask:=String(ASKS[audiences%ASKS.size()])
	var court:Array=HALL.court(id)
	if audiences%3==0 and not court.is_empty():
		ask="%s, what do you make of this?" % String((court[0] as Dictionary).get("name","")).get_slice(" ",0)
	in_exchange=true
	exchanges+=1
	voice.player_speaks(id,ask)
	await _settle(id)
	in_exchange=false
	var option:String=probe._answer(audience,audiences)
	var result:Dictionary={"ok":false,"outcome":"(no enabled option)","reaction":"neutral"}
	if option!="": result=HALL.resolve(id,option)
	result["option_id"]=option
	voice.closing(id,result)
	await _settle(id)
	for line in HALL.find(id).get("lines",[]):
		if String(line.get("role",""))=="official" and String(line.get("speaker",""))!=envoy_name: court_lines+=1

func _settle(id:String)->void:
	for i in 12:
		await get_tree().process_frame
		if not voice.busy(id): break

func _mock_send(id:String,payload:Dictionary,attempt:int)->void:
	calls+=1
	var sys:=String((payload.messages as Array)[0].content)
	var user:=String((payload.messages as Array)[1].content)
	var p_tok:=(sys.length()+user.length())/4
	var keys:Array=[]
	var fmt:Variant=payload.get("response_format",{})
	if fmt is Dictionary and not (fmt as Dictionary).is_empty():
		keys=fmt.json_schema.schema.properties.lines.items.properties.speaker_key.enum
	else: keys=["envoy"]
	var lines:Array=[]
	var n:=0
	for k in keys:
		if String(k)=="narrator": continue
		var text:=("%s %s" % [String(OPENS[calls%OPENS.size()]),String(ENDS[(calls/OPENS.size())%ENDS.size()])]) if String(k)=="envoy" else String(CHATTER[(calls+n)%CHATTER.size()])+" "+String(ENDS[(calls+n)%ENDS.size()])
		lines.append({"speaker_key":String(k),"text":text,"aside":String(k)!="envoy"})
		n+=1
	var content:=JSON.stringify({"lines":lines,"mood_shift":0.0,"divine":"none","command":{"act":"question","verb":"none","actor_ref":"","target_ref":"","object":"","confidence":0.9}})
	var c_tok:=content.length()/4+150
	prompt_tokens+=p_tok; completion_tokens+=c_tok
	var stage:=user.get_slice("NOW: ",1).substr(0,24)
	stage_calls[stage]=int(stage_calls.get(stage,0))+1
	if in_exchange:
		exchange_calls+=1; exchange_tokens+=p_tok+c_tok
	var body:=JSON.stringify({"id":"mock","model":"mock-model","choices":[{"finish_reason":"stop","message":{"role":"assistant","content":content}}],
		"usage":{"prompt_tokens":p_tok,"completion_tokens":c_tok,"total_tokens":p_tok+c_tok}})
	voice._on_response.call_deferred(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),body.to_utf8_buffer(),id,attempt)
