extends Node

var failures:Array[String]=[]

func _ready()->void:
	GameState.reset_for_new_world(47913)
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	ConsequenceEngine.initialize()
	GameState.society_capacities["institutions"]=0.8
	GameState.simulation_metrics["security"]=0.8
	GameState.simulation_metrics["cohesion"]=0.7
	GameState.simulation_metrics["legitimacy"]=0.7
	_test_conversation_drafts()
	_test_coercive_execution()
	_test_response_boundaries()
	await _test_offline_and_ui()
	if OS.get_environment("LEADER_CONVERSATION_MOCK")=="1": await _test_http_conversation()
	LeaderConversation.reset_for_new_world()
	if failures.is_empty():
		print("LEADER_CONVERSATION_PROBE PASS")
		get_tree().quit(0)
	else:
		for failure in failures: push_error("LEADER_CONVERSATION_PROBE "+failure)
		get_tree().quit(1)

func _offer(decree:String,id:String)->Dictionary:
	return {"reply":"Here are the proposed terms. Nothing has been issued.","decree":decree,"policies":[{"id":id,"basis":decree,"confidence":0.99}]}

func _test_conversation_drafts()->void:
	var before:=GameState.sovereign_orders.size()
	LeaderConversation.accept_reply("Council",{"reply":"Are you considering reducing portions, or increasing the food supply?","decree":"","policies":[]})
	_expect(GameState.sovereign_orders.size()==before,"conversation created an order")
	_expect(LeaderConversation._thread("Council").draft.is_empty(),"clarification created a draft")
	LeaderConversation.accept_reply("Council",_offer("Enact rationing for 30 days.","rationing"))
	_expect(not LeaderConversation._thread("Council").draft.is_empty(),"valid proposal rejected")
	_expect(GameState.sovereign_orders.size()==before,"proposal executed without acceptance")
	_expect("30 days" in LeaderConversation.preview("Council"),"preview lost duration")
	_expect(LeaderConversation.issue("Council",-1).is_empty(),"stale revision executed")
	_expect(LeaderConversation._thread("Marshal").messages.is_empty(),"Council history leaked into Marshal")
	var invalid:=_offer("Enact rationing for 30 days.","rationing")
	invalid.policies.append({"id":"invented_policy","basis":"Enact rationing","confidence":1.0})
	LeaderConversation.accept_reply("Council",invalid)
	_expect(LeaderConversation._thread("Council").draft.is_empty(),"partially valid decree became executable")
	_expect(GameState.sovereign_orders.size()==before,"invalid proposal executed")

func _test_coercive_execution()->void:
	for pair:Array in [["Enact compulsory labor for 30 days.","labor_mobilization"],["Enact conscription for 30 days.","conscription_drive"],["Enact forced relocation for 30 days.","population_resettlement"],["Execute dissidents for 30 days.","mass_repression"]]:
		LeaderConversation.accept_reply("Marshal",_offer(String(pair[0]),String(pair[1])))
		_expect(not LeaderConversation._thread("Marshal").draft.is_empty(),"supported historical policy rejected: "+String(pair[1]))
	var revision:=int(LeaderConversation._thread("Marshal").revision)
	var before:=GameState.sovereign_orders.size()
	var order:Dictionary=LeaderConversation.issue("Marshal",revision)
	_expect(not order.is_empty(),"accepted repression decree did not reach engine")
	if not order.is_empty():
		var policies:Array=order.parameters.interpretation.policies
		_expect(policies.size()==1 and String(policies[0].id)=="mass_repression","repression substituted a different policy")
		_expect(policies[0].has("implementation_rate") and policies[0].has("direct_effects"),"execution bypassed mathematical assessment")
		_expect(bool(policies[0].get("applied",false)),"adequately resourced repression failed to apply")
	_expect(GameState.sovereign_orders.size()==before+1,"accepted decree did not create exactly one order")
	_expect(LeaderConversation.issue("Marshal",revision).is_empty(),"accepted draft executed twice")
	LeaderConversation.accept_reply("Marshal",_offer("Repeal mass execution.","mass_repression"))
	var repeal:Dictionary=LeaderConversation.issue("Marshal",int(LeaderConversation._thread("Marshal").revision))
	_expect(not repeal.is_empty() and String(repeal.parameters.interpretation.policies[0].action)=="repeal","repeal changed into enactment")

func _test_response_boundaries()->void:
	var valid:=_offer("Enact rationing for 30 days.","rationing")
	var envelope:={"choices":[{"message":{"content":JSON.stringify(valid)}}]}
	_expect(not LeaderConversation.parse_reply(JSON.stringify(envelope).to_utf8_buffer()).is_empty(),"valid API response rejected")
	_expect(LeaderConversation.parse_reply('{"choices":[{"message":"bad"}]}'.to_utf8_buffer()).is_empty(),"malformed message accepted")
	_expect(LeaderConversation.parse_reply('{"choices":[{"message":{"refusal":"refused"}}]}'.to_utf8_buffer()).is_empty(),"provider refusal turned into a decree")
	for index in range(40): LeaderConversation._append("Scholar","user","Question %d" % index)
	_expect(LeaderConversation._thread("Scholar").messages.size()==LeaderConversation.MAX_TURNS,"history is unbounded")

func _test_offline_and_ui()->void:
	var endpoint:=OS.get_environment("LEVIATHAN_AI_ENDPOINT")
	OS.set_environment("LEVIATHAN_AI_ENDPOINT","invalid://offline")
	LeaderConversation.accept_reply("Council",_offer("Enact rationing for 30 days.","rationing"))
	var revision:=int(LeaderConversation._thread("Council").revision)
	var before:=GameState.sovereign_orders.size()
	LeaderConversation.send("Council","What if we made that sixty days instead?")
	_expect(LeaderConversation._thread("Council").draft.is_empty(),"edit left previous proposal executable")
	_expect(LeaderConversation.issue("Council",revision).is_empty(),"old draft survived an edit")
	_expect(GameState.sovereign_orders.size()==before,"offline discussion triggered local execution")
	OS.set_environment("LEVIATHAN_AI_ENDPOINT",endpoint)
	LeaderConversation.open("Council")
	await get_tree().process_frame
	_expect(LeaderConversation.panel.is_visible_in_tree(),"conversation panel did not open")
	_expect(not LeaderConversation.issue_button.visible,"UI offers issue without a draft")
	LeaderConversation.accept_reply("Council",_offer("Enact rationing for 30 days.","rationing"))
	LeaderConversation._refresh()
	await get_tree().process_frame
	_expect(LeaderConversation.issue_button.visible,"UI omitted decree issue action")
	_expect(LeaderConversation.transcript.get_parsed_text().contains("sixty days"),"UI lost conversation history")
	_expect(LeaderConversation.entry.get_global_rect().end.y<=get_viewport().get_visible_rect().end.y,"conversation input outside viewport")
	if OS.get_environment("LEADER_CONVERSATION_CAPTURE")=="1":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/leader-conversation-panel.png")
	LeaderConversation.open("Marshal")
	_expect(not LeaderConversation.transcript.get_parsed_text().contains("sixty days"),"office switch mixed transcripts")
	GameState.reset_for_new_world(47913)
	_expect(LeaderConversation.conversations.is_empty() and LeaderConversation.pending.is_empty(),"new world retained conversation or pending execution")
	await get_tree().process_frame

func _test_http_conversation()->void:
	LeaderConversation.send("Council","How can we stretch our stores?")
	await _await_response("Council")
	_expect(LeaderConversation._thread("Council").draft.is_empty(),"HTTP clarification created decree")
	LeaderConversation.send("Council","Rationing for thirty days, please.")
	await _await_response("Council")
	_expect(not LeaderConversation._thread("Council").draft.is_empty(),"HTTP follow-up failed to produce a grounded draft")
	var before:=GameState.sovereign_orders.size()
	LeaderConversation.send("Council","What if we made that sixty days instead?")
	await _await_response("Council")
	_expect(GameState.sovereign_orders.size()==before,"HTTP hypothetical executed decree")
	_expect(LeaderConversation._thread("Council").draft.is_empty(),"HTTP hypothetical retained old draft")
	LeaderConversation.send("Council","Yes, draft rationing for sixty days.")
	await _await_response("Council")
	_expect("60 days" in LeaderConversation.preview("Council"),"HTTP follow-up lost negotiated duration")
	LeaderConversation.send("Council","issue it")
	_expect(GameState.sovereign_orders.size()==before+1,"explicit conversational acceptance did not execute")
	LeaderConversation.send("Marshal","MALFORMED")
	await _await_response("Marshal")
	_expect(LeaderConversation._thread("Marshal").draft.is_empty(),"malformed HTTP response created a decree")
	LeaderConversation.send("Envoy","CANCEL_ON_RESET")
	GameState.reset_for_new_world(47)
	await get_tree().create_timer(0.2).timeout
	_expect(LeaderConversation.conversations.is_empty() and LeaderConversation.pending.is_empty(),"late response resurrected reset world conversation")

func _await_response(office:String)->void:
	var deadline:=Time.get_ticks_msec()+6000
	while LeaderConversation.is_pending(office) and Time.get_ticks_msec()<deadline:
		await get_tree().process_frame
	_expect(not LeaderConversation.is_pending(office),"mock HTTP request timed out")

func _expect(condition:bool,message:String)->void:
	if not condition: failures.append(message)
