extends Node
func _ready()->void:run.call_deferred()
func run()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_GeneralCampaign_Test"))
	var saved:=SaveSystem.load_game("general_journey")
	if saved.has("error"):print("GENERAL_LOAD_ERROR ",saved.error);get_tree().quit(2);return
	GameState.civic_api_enabled=true
	var configured:=PronouncementInterpreter.configuration_status()
	if not bool(configured.get("configured",false)):
		print("GENERAL_LIVE_UNAVAILABLE ",JSON.stringify(configured));get_tree().quit(2);return
	GeneralCampaign.state.proposal={};GeneralCampaign.state.mission={}
	var before:=GameState.elapsed_days
	for sample in [{"text":"What would attacking Bracken Hold cost us? I am asking, not ordering an attack.","action":""},{"text":"Bring the army home. Preserve the survivors; you choose the route and handle the withdrawal.","action":"withdraw"},{"text":"Actually, set that aside and defend Alderford instead. I want the army to protect home, not attack.","action":"defend"}]:
		assert(GeneralDialogue.ask(sample.text))
		var deadline:=Time.get_ticks_msec()+42000
		while GeneralDialogue.pending.has("player") and Time.get_ticks_msec()<deadline:await get_tree().process_frame
		assert(not GeneralDialogue.pending.has("player"),"Live reply deadline")
		assert(not GeneralDialogue.usage.is_empty() and GeneralDialogue.usage[-1].accepted,"A valid live answer is required")
		assert(String(GeneralCampaign.state.proposal.get("action",""))==sample.action,"Intent mismatch")
		assert(GameState.elapsed_days==before,"Draft discussion must not move the world")
		print("GENERAL_LIVE_TURN ",JSON.stringify({"text":sample.text,"reply":GeneralCampaign.state.messages[-1],"proposal":GeneralCampaign.state.proposal,"usage":GeneralDialogue.usage[-1]}))
	GeneralDialogue.request_opponent(String(GeneralCampaign.state.rivals[0].id))
	var deadline:=Time.get_ticks_msec()+42000
	while not GeneralDialogue.pending.is_empty() and Time.get_ticks_msec()<deadline:await get_tree().process_frame
	assert(GeneralDialogue.usage[-1].role=="opponent" and GeneralDialogue.usage[-1].accepted)
	print("GENERAL_LIVE_OPPONENT ",JSON.stringify(GeneralDialogue.usage[-1]))
	var file:=FileAccess.open("res://artifacts/general-live-usage.json",FileAccess.WRITE);file.store_string(JSON.stringify(GeneralDialogue.usage,"  "));file.close()
	print("GENERAL_LIVE_PASS three Terra turns: question, withdrawal objective, correction to defense; no time or movement during drafts")
	get_tree().quit()
