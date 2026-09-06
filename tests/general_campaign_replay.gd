extends Node
## Runs the real mission state machine and ordinary world calendar quickly.
## Decisions use dated player-visible reports, not hidden enemy positions.
func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_GeneralCampaign_Test"))
	GameState.reset_for_new_world(551188);CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();GameState.civic_api_enabled=false
	GeneralCampaign.launch_requested=true
	var terrain:Node=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	for frame in 10:await get_tree().process_frame
	if is_instance_valid(terrain.founding_focus_panel):terrain.founding_focus_panel.queue_free();terrain.founding_focus_panel=null
	var reckless:bool="--reckless" in OS.get_cmdline_user_args()
	var log:Array=[]
	var rest_count:=0
	for decision in 32:
		if not GeneralCampaign.state.outcome.is_empty():break
		var action:="defend" if not reckless and GeneralCampaign.state.events.size()<2 else "attack"
		var target:="home"
		for known:Dictionary in GeneralCampaign.public_context().known_rivals:
			if known.get("control","rival")!="secured":target=String(GeneralCampaign.state.seen.find_key(known));break
		if GeneralCampaign.food_days()<2 or int(GeneralCampaign.army().troops)<90:action="recover"
		if not reckless and "undefended" in String(GeneralCampaign.state.reports[-1].text):action="withdraw"
		if rest_count>3 and action=="recover":action="defend"
		if action=="recover":rest_count+=1
		GeneralCampaign.propose({"action":action,"target":target})
		var committed:=GeneralCampaign.commit_proposal()
		if committed.has("error"):
			GeneralCampaign.propose({"action":"recover","target":"home"});GeneralCampaign.commit_proposal()
		var steps:=0
		while GeneralCampaign.resolving and steps<150:
			var days:=GeneralCampaign.consume_time(500)
			terrain.advance_world_time(days);GeneralCampaign.after_world_time();steps+=1
			if steps%5==0:await get_tree().process_frame
		assert(not GeneralCampaign.resolving,"A report or terminal outcome must bound this replay segment")
		log.append({"decision":decision,"action":action,"day":GameState.elapsed_days,"troops":GeneralCampaign.army().troops,"report":GeneralCampaign.state.reports[-1]})
		print("CAMPAIGN_REPLAY_STEP ",JSON.stringify(log[-1]))
	var validation:=CivilizationSystem.validate_state();assert(validation.is_empty(),str(validation))
	assert(not GeneralCampaign.state.outcome.is_empty(),"This bounded campaign must reach an actual terminal outcome")
	var file:=FileAccess.open("res://artifacts/general-campaign-"+("reckless" if reckless else "defensive")+".json",FileAccess.WRITE);file.store_string(JSON.stringify({"outcome":GeneralCampaign.state.outcome,"decisions":log},"  "));file.close()
	print("GENERAL_CAMPAIGN_REPLAY_COMPLETE outcome=",GeneralCampaign.state.outcome," decisions=",log.size())
	get_tree().quit()
