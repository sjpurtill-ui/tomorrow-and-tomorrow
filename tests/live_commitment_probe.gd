extends Node
func _ready()->void:
	GameState.reset_for_new_world(424242)
	CivilizationSystem.reset_for_new_world(); CivilizationSystem.initialize()
	ForeignDiplomacy.reset_for_new_world(); ForeignDiplomacy.ensure()
	GameState.civic_api_enabled=true; GameState.civic_always_use_ai=true
	var civ:Dictionary=CivilizationSystem.civilizations[0]; var id:=String(civ.id)
	civ.player_relation.contact_level=2; civ.player_relation.opinion=.5
	ForeignDiplomacy.leader(id)["audience_day"]=0
	var questions:Array=["I propose mutual protection for future defensive sieges, with help limited by our real troops, food and travel. Draft those supported terms for my review; do not dispatch anything.","I disagree with a merely bilateral pact. Instead, draft founding a league with you, focused on safe roads, retaining our own leaders and consulting before war. Replace the previous draft; do not send it."]
	var expected:Array=["protection","found_faction"]
	var failures:Array=[]
	for index:int in questions.size():
		ForeignDialogue.ask(id,questions[index])
		var deadline:=Time.get_ticks_msec()+60000
		while ForeignDialogue.pending.has(id) and Time.get_ticks_msec()<deadline: await get_tree().process_frame
		var discussion:=ForeignDialogue.thread(id)
		print("COMMITMENT_REPLY ",discussion.reply," DRAFT ",discussion.draft," STATUS ",discussion.status)
		if bool(discussion.retryable) or discussion.draft.get("commitment",{}).get("action","")!=expected[index]: failures.append("Expected revised commitment draft did not arrive.")
	if not ForeignDiplomacy.commitments.state.pacts.is_empty() or not ForeignDiplomacy.commitments.state.factions.is_empty() or not CivilizationSystem.diplomatic_mission.is_empty(): failures.append("Conversation executed an action.")
	for failure in failures: push_error(failure)
	print("LIVE_COMMITMENT ","PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
