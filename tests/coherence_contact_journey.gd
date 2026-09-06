extends "res://tests/focused_journey_probe.gd"
func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_Coherence_Test"))
	GameState.reset_for_new_world(551188);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();ProgressionSystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();ConsequenceEngine.reset_for_new_world();CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();PeopleDirection.reset_for_new_world();SettlementModel.reset_for_new_world();GovernmentPeopleSystem.reset_for_new_world()
	get_window().content_scale_size=Vector2i.ZERO;get_window().size=Vector2i(1280,900)
	terrain=preload("res://local_terrain.tscn").instantiate();add_child(terrain);await frames();hud=terrain.hud
	assert(is_instance_valid(PeopleDirection.panel))
	await capture("coherent-first-choice")
	await click_control(PeopleDirection.panel.ambition_buttons[0]);await click_control(PeopleDirection.panel.pages[0].get_node("ConfirmFocus"));await frames()
	await click_control(hud.speed_buttons[0]);await capture("coherent-first-map")
	hud.close_dock();await frames()
	assert(not hud.toolbar_action_buttons.settle.disabled)
	await click_control(hud.toolbar_action_buttons.settle);await frames()
	assert(GameState.settlement_site_committed and is_instance_valid(terrain.settlement_naming_panel))
	terrain.settlement_name_input.text="New Dawn";terrain.settlement_name_input.text_changed.emit("New Dawn")
	await click_control(terrain.settlement_name_confirm);await frames()
	await capture("coherent-founding-settlement")

	hud.close_dock();await click_control(hud.speed_buttons[5])
	var deadline:=Time.get_ticks_msec()+15000
	while GameState.elapsed_days<10 and Time.get_ticks_msec()<deadline:await get_tree().process_frame
	await click_control(hud.speed_buttons[0])
	await click_control(hud.rail_buttons.world);await click_label("SEND SCOUTS")
	var launched:=false
	for button in terrain.scout_dispatch_panel.find_children("*","Button",true,false):
		if button.text.begins_with("SEND FOR 30 DAYS"):
			assert(not button.disabled);await click_control(button);launched=true;break
	assert(launched)
	if is_instance_valid(terrain.scout_dispatch_panel):
		for button in terrain.scout_dispatch_panel.find_children("*","Button",true,false):
			if button.text=="CLOSE":await click_control(button);break
	hud.close_dock();await click_control(hud.speed_buttons[5])
	deadline=Time.get_ticks_msec()+90000
	while CivilizationSystem.exploration_status().get("active",false) and Time.get_ticks_msec()<deadline:await get_tree().process_frame
	await click_control(hud.speed_buttons[0]);await click_control(hud.rail_buttons.world)
	await capture("coherence-natural-contact")
	print("NATURAL_RETURN ",JSON.stringify(CivilizationSystem.exploration_status()))
	print("NATURAL_CONTACTS ",JSON.stringify(CivilizationSystem.contact_encounters_snapshot()))
	assert(not CivilizationSystem.scout_reports.is_empty())
	assert(not CivilizationSystem.contact_encounters_snapshot().is_empty(),"First ordinary expedition must reach generated neighbors on this reviewed seed, not an injected contact")
	var contacts:=CivilizationSystem.contact_encounters_snapshot()
	var known_id:=String(contacts[0].civ_id)
	hud.open_detail(preload("res://scripts/hud/content/dock_detail_civ_report.gd").new(terrain,hud,known_id));await frames()
	await capture("coherence-investigate-proposal")
	await click_label("ASK SCOUTS TO FIND THEIR SETTLEMENT")
	assert(not CivilizationSystem.scout_missions.is_empty())
	await capture("coherence-investigate-underway")
	hud.close_detail();hud.close_dock();await click_control(hud.speed_buttons[5])
	deadline=Time.get_ticks_msec()+90000
	while CivilizationSystem.exploration_status().get("active",false) and Time.get_ticks_msec()<deadline:await get_tree().process_frame
	await click_control(hud.speed_buttons[0]);await click_control(hud.rail_buttons.world)
	var returned:=CivilizationSystem.contact_encounters_snapshot()
	var located:=false
	for contact:Dictionary in returned:
		if String(contact.civ_id)==known_id:located=bool(contact.home_location_known)
	assert(located,"Returned search must physically locate this reviewed neighbor")
	hud.open_detail(preload("res://scripts/hud/content/dock_detail_civ_report.gd").new(terrain,hud,known_id));await frames()
	await capture("coherence-neighbor-located")
	assert(SaveSystem.save_game("coherence_contact").has("ok"))
	print("COHERENCE_CONTACT_JOURNEY_PASS first encounter plus objective-led search returned a located neighbor day=",GameState.elapsed_days)
	get_tree().quit()
