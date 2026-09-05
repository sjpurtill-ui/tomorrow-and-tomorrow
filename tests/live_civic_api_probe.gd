extends Node
## Manual live-account smoke probe. This is intentionally separate from the
## deterministic suite: it spends one small API request and verifies the exact
## production interpreter, validator, forced-AI routing, and screenshot wording.

const SCREENSHOT_ORDER:="Tarin, I would like you to prepare an expedition for the purposes of recruiting people to our village."

var received:Dictionary={}


func _ready()->void:
	GameState.reset_for_new_world(884201)
	PronouncementInterpreter.reset_for_new_world()
	GameState.civic_always_use_ai=true
	var configuration:=PronouncementInterpreter.configuration_status()
	if not bool(configuration.get("configured",false)):
		_fail("API is not configured")
		return
	PronouncementInterpreter.interpretation_completed.connect(_capture)
	PronouncementInterpreter.interpret(SCREENSHOT_ORDER,{
		"population":120,"day":550,
		"leader":{"name":"Tarin North","title":"Hearth Speaker","disposition":"plain-spoken"},
		"conversation":[],"active_policies":[],
	})
	var deadline:=Time.get_ticks_msec()+20000
	while received.is_empty() and Time.get_ticks_msec()<deadline:
		await get_tree().process_frame
	if received.is_empty():
		_fail("live interpretation timed out")
		return
	var ids:Array[String]=[]
	for policy_variant in received.get("policies",[]):
		ids.append(String((policy_variant as Dictionary).get("id","")))
	if String(received.get("source",""))!="generative API":
		_fail("request did not complete through the generative API")
		return
	if not ids.has("recruitment_expedition"):
		_fail("screenshot order did not map to recruitment_expedition")
		return
	if bool(received.get("non_directive",false)):
		_fail("screenshot order was still misclassified as discussion")
		return
	print("LIVE_CIVIC_API_PROBE PASS · model=%s · policies=%s · attempts=%d" % [String(configuration.get("model","")),",".join(PackedStringArray(ids)),int(received.get("api_attempts",0))])
	get_tree().quit(0)


func _capture(_request_id:String,result:Dictionary)->void:
	received=result.duplicate(true)


func _fail(reason:String)->void:
	push_error("LIVE_CIVIC_API_PROBE FAIL · %s" % reason)
	get_tree().quit(1)
