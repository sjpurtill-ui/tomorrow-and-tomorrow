extends "res://tests/focused_journey_probe.gd"
func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_FocusedJourney_Test"))
	GameState.reset_for_new_world(551188);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();ProgressionSystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();ConsequenceEngine.reset_for_new_world();CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.select_founding_focus("provision");PeopleDirection.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	terrain=preload("res://local_terrain.tscn").instantiate();add_child(terrain);terrain._set_game_speed(0);await frames();hud=terrain.hud
	get_window().content_scale_size=Vector2i.ZERO;get_window().size=Vector2i(1280,900);await frames()
	GovernmentPeopleSystem.initialize()
	for size in [Vector2i(1280,900),Vector2i(800,600)]:
		get_window().size=size;await frames()
		hud.open_dock("civ",0);await capture("society-%d"%size.x)
		await click_label("PEOPLE IN GOVERNMENT");await capture("government-%d"%size.x)
		await click_label("OFFICEHOLDERS");await capture("officeholders-%d"%size.x)
		await click_control(hud.detail_dock.close_button)
		await click_label("TALK TO OUR LEADER");await capture("civic-conversation-%d"%size.x)
		var field:LineEdit=hud.find_child("CivicConversationInput",true,false)
		assert(field!=null)
		field.text="What do you think about a bonfire for our anniversary?"
		await click_control(hud.find_child("CivicConversationSend",true,false))
		await frames();await capture("civic-answer-%d"%size.x)
		assert(ConsequenceEngine.active_policies().is_empty())
		assert(not AdvisorSystem.civic_dialogue_history(SettlementModel._primary_settlement_id(),2).is_empty())
		assert(get_viewport().get_visible_rect().encloses(hud.find_child("CivicConversationSend",true,false).get_global_rect()))
		await click_label("COUNCIL DECISIONS");await capture("civic-decisions-%d"%size.x)
		await click_control(hud.detail_dock.close_button)
		await click_label("CONVERSATION SETTINGS");await capture("civic-settings-%d"%size.x)
		await click_control(hud.detail_dock.close_button)
	print("CIVIC_JOURNEY_PASS society/government/conversation focused paths at two sizes; actual local advice creates no policy; composer and next-step controls remain visible")
	get_tree().quit()
