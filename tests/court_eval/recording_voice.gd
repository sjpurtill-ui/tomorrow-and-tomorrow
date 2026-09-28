extends "res://scripts/audience_voice.gd"
## The court's own voice (audience_voice.gd), unchanged, with its calls
## recorded for the court evaluation (tests/test_court_eval.gd): what the
## engine decided (command_reaction), what the order reader read and the plan
## it led to, words sent to the voice as talk, persons turns, and every prompt
## that would have gone to a live model (send_hook; nothing leaves the machine).
## answer() lets the harness play the stubbed model: it answers the requests
## it chooses through the voice's own response handler, and drops the rest.

const Reader:=preload("res://scripts/order_reader.gd")

var calls:Array[Dictionary]=[]
var prompts:Array[Dictionary]=[]   ## {stage, prompt, system}

func command_reaction(audience_id:String,result:Dictionary)->void:
	calls.append({"call":"command","result":result.duplicate(true)})
	super.command_reaction(audience_id,result)

func divine_reaction(audience_id:String,result:Dictionary)->void:
	calls.append({"call":"divine","result":result.duplicate(true)})
	super.divine_reaction(audience_id,result)

func player_speaks(audience_id:String,text:String,offline_order:bool=false,read:bool=false)->void:
	calls.append({"call":"speak","text":text,"offline_order":offline_order,"read":read})
	super.player_speaks(audience_id,text,offline_order,read)

func persons_turn(audience_id:String,text:String)->void:
	calls.append({"call":"persons","text":text})
	super.persons_turn(audience_id,text)

func read_order(audience_id:String,text:String,done:Callable)->bool:
	# The plan the modal is about to make from this reading (decide() only
	# reads), recorded before the modal acts on it.
	var log:=calls
	var wrapped:=func(read:Dictionary)->void:
		var plan:Dictionary=Reader.decide(audience_id,text,read.reading as Dictionary) if read.has("reading") else Reader.offline_confirm(audience_id,text)
		log.append({"call":"read","read":read.duplicate(true),"route":String(plan.get("route","legacy")) if not plan.is_empty() else "legacy","why":String(plan.get("why",""))})
		done.call(read)
	return super.read_order(audience_id,text,wrapped)

var replies:Array[Dictionary]=[]   ## requests waiting for the stubbed model

func record_send(audience_id:String,payload:Dictionary,attempt:int)->void:
	## send_hook: the prompt is kept; nothing is sent.
	var request:Dictionary=_requests.get(audience_id,{})
	var stage:=String(request.get("stage",""))
	var messages:Array=payload.get("messages",[])
	prompts.append({"stage":stage,"system":String((messages[0] as Dictionary).get("content","")) if messages.size()>0 else "",
		"prompt":String((messages[1] as Dictionary).get("content","")) if messages.size()>1 else ""})
	replies.append({"id":audience_id,"attempt":attempt,"stage":stage,"read":bool((request.get("extra",{}) as Dictionary).get("read",false)),
		"offline_order":bool((request.get("extra",{}) as Dictionary).get("offline_order",false))})

func answer(reply:Callable,rounds:int=8)->int:
	## The stubbed model answers what was asked of it, in order: reply(request)
	## gives the response body, or nothing (the request is dropped unanswered).
	var n:=0
	while not replies.is_empty() and n<rounds:
		var r:Dictionary=replies.pop_front(); n+=1
		if not _requests.has(String(r.id)): continue
		var body:PackedByteArray=reply.call(r)
		if body.is_empty(): _requests.erase(String(r.id)); continue
		_on_response(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),body,String(r.id),int(r.attempt))
	return n

func drain(audience_id:String)->void:
	## Whatever is still unanswered is dropped so the next words can be said.
	_requests.erase(audience_id); _ordering.erase(audience_id); _reading.erase(audience_id); _picking.erase(audience_id)
	replies.clear()
