extends "res://tests/focused_journey_probe.gd"
func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_FocusedJourney_Test"))
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
	await click_label("FOOD & MATERIALS");await capture("coherent-needs")
	await click_label("WATER ACCESS");await capture("coherent-water-before")
	var start_day:=GameState.elapsed_days
	hud.close_dock();await frames()
	await click_control(hud.speed_buttons[5]);assert(terrain.game_speed==5)
	var deadline:=Time.get_ticks_msec()+16000
	while GameState.elapsed_days<start_day+10 and Time.get_ticks_msec()<deadline:await get_tree().process_frame
	await click_control(hud.speed_buttons[0]);await capture("coherent-water-after-time")
	assert(GameState.elapsed_days>=start_day+1,"Actual time controls must advance the running simulation")
	assert("Hearth Circle" in GameState.settlement_completed)
	await click_control(hud.rail_buttons.economy);await click_label("WATER ACCESS");await click_label("PRIORITIZE WATER")
	assert(GovernmentPeopleSystem.settlement_management(GameState.selected_player_settlement_id).focus=="water")
	await capture("coherent-water-directed")
	await click_control(hud.rail_buttons.inquiry);await click_label("KNOWLEDGE & SOCIETY");await click_label("Security")
	var research_before:=int(GameState.research_allocations.get("security",0))
	await click_label("MORE ATTENTION");assert(int(GameState.research_allocations.get("security",0))==research_before+1);await capture("coherent-research")
	await click_control(hud.rail_buttons.military);await click_label("PREPARE AN ARMY");await capture("coherent-army-next")
	await click_label("LEVY BAND");await click_label("2 · RECRUIT & TRAIN");await capture("coherent-training-next")
	get_window().size=Vector2i(800,600);await frames();await capture("coherent-training-small")
	var trainees:=MilitaryCampaign._queued_trainees()
	await click_label("RECRUIT & TRAIN");assert(MilitaryCampaign._queued_trainees()==trainees)
	await click_control(hud.rail_buttons.world);await capture("coherent-diplomacy-next")
	await click_label("SEND SCOUTS");assert(is_instance_valid(terrain.scout_dispatch_panel));await capture("coherent-scout-review-small")
	var scouts_before:=int(CivilizationSystem.exploration_status().get("active_count",0))
	var food_before:=float(GameState.resource_stockpiles.Food)
	var sent:=false
	for button in terrain.scout_dispatch_panel.find_children("*","Button",true,false):
		if button.text.begins_with("SEND FOR 30 DAYS"):
			assert(not button.disabled);await click_control(button);sent=true;break
	assert(sent and int(CivilizationSystem.exploration_status().get("active_count",0))==scouts_before+1)
	assert(is_equal_approx(float(GameState.resource_stockpiles.Food),food_before-99.0))
	await capture("coherent-scouts-departed")
	print("COHERENT_EARLY_JOURNEY_PASS one unreset new world: founding choice, real site commitment/naming, needs/water direction, normal time advancement, research direction, waiting army order without duplicate trainees, actual 6-person scout departure reserving99Food; day=",GameState.elapsed_days," population=",GameState.population_total," settlement=",GameState.settlement_name," works=",GameState.settlement_completed)
	await after_scout_departure()
	get_tree().quit()

func after_scout_departure()->void:
	pass
