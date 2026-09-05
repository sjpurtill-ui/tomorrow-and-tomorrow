extends Node
var received:Dictionary={}
var failures:Array[String]=[]

func _ready()->void:
	GameState.reset_for_new_world(424242)
	PronouncementInterpreter.reset_for_new_world()
	CivilizationSystem.reset_for_new_world(); CivilizationSystem.initialize()
	ForeignDiplomacy.reset_for_new_world()
	FoodSystem.reset_for_new_world(); FoodSystem.initialize(); FoodSystem.receive_external_food(1000)
	GameState.civic_always_use_ai=true; GameState.civic_api_enabled=true
	PronouncementInterpreter.interpretation_completed.connect(func(_id:String,result:Dictionary)->void: received=result)
	var history:Array=[]
	for question in ["I want better shelters, but keep enough timber for winter fuel. What tradeoff should we consider before I give an order?","I disagree with moving too quickly. Could we discuss a smaller trial first, keeping the fuel reserve I mentioned?"]:
		received={}
		PronouncementInterpreter.interpret(question,{"population":120,"day":40,"leader":{"name":"Mara Reed","title":"Town Speaker"},"conversation":history})
		var deadline:=Time.get_ticks_msec()+90000
		while received.is_empty() and Time.get_ticks_msec()<deadline: await get_tree().process_frame
		if int(received.get("api_attempts",0))<1 or bool(received.get("service_failure",false)) or String(received.get("answer","")).is_empty() or not received.get("policies",[]).is_empty(): failures.append("Civic discussion failed or proposed an unsolicited action")
		history.append({"speaker":"player","text":question,"status":"discussion"})
		history.append({"speaker":"leader","text":String(received.get("answer","")),"status":"advises"})
		print("CIVIC_REPLY ",received.get("answer",received.get("source_detail","")))
		print("CIVIC_CHECK attempts=",received.get("api_attempts",0)," policies=",received.get("policies",[]))
	var civ:Dictionary=CivilizationSystem.civilizations[0]; var id:String=civ.id
	civ.player_relation.contact_level=2; civ.player_relation.home_location_known=true
	civ.player_relation.home_position={"x":CivilizationSystem.player_world_origin.x+1,"z":CivilizationSystem.player_world_origin.y}
	ForeignDiplomacy.send_audience(id)
	if CivilizationSystem.diplomatic_mission.is_empty(): failures.append("Audience did not depart")
	else:
		GameState.elapsed_days=int(CivilizationSystem.diplomatic_mission.return_day)
		CivilizationSystem._process_diplomatic_mission(int(GameState.elapsed_days))
	for question in ["Before proposing any agreement, what would your people want from a relationship with ours?","I am unconvinced. Explain how a small exchange of teachers could help both sides, without committing either of us yet."]:
		ForeignDialogue.ask(id,question)
		var deadline:=Time.get_ticks_msec()+60000
		while ForeignDialogue.pending.has(id) and Time.get_ticks_msec()<deadline: await get_tree().process_frame
		if ForeignDialogue.pending.has(id) or bool(ForeignDialogue.thread(id).retryable): failures.append("Foreign reply failed")
		print("FOREIGN_REPLY ",ForeignDialogue.thread(id).reply," STATUS ",ForeignDialogue.thread(id).status)
	if not ForeignDiplomacy.leader(id).accord.is_empty() or not CivilizationSystem.diplomatic_mission.is_empty(): failures.append("Discussion executed a foreign action")
	for failure in failures: push_error(failure)
	print("LIVE_DIALOGUE_CONTINUITY ","PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
