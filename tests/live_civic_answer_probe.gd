extends Node
var received:Dictionary={}
func _ready()->void:
	GameState.reset_for_new_world(884201)
	PronouncementInterpreter.reset_for_new_world()
	GameState.civic_always_use_ai=true
	PronouncementInterpreter.interpretation_completed.connect(func(_id:String,result:Dictionary)->void: received=result)
	PronouncementInterpreter.interpret("I would like to honor our citizens with a massive bonfire in celebration of our 75th anniversary in 10 years.",{"population":120,"day":23626,"leader":{"name":"Mara Reed","title":"Town Speaker","disposition":"plain-spoken"},"conversation":[],"active_policies":[]})
	var deadline:=Time.get_ticks_msec()+90000
	while received.is_empty() and Time.get_ticks_msec()<deadline: await get_tree().process_frame
	var answer:=String(received.get("answer",""))
	if String(received.get("source",""))!="generative API" or answer.is_empty():
		push_error("LIVE_CIVIC_ANSWER failed: "+String(received.get("source_detail","No response")))
		get_tree().quit(1)
		return
	print("LIVE_CIVIC_ANSWER PASS: "+answer)
	get_tree().quit(0)
