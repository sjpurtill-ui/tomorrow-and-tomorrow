extends Node
func _ready()->void:
	GameState.reset_for_new_world(190887)
	DiscoverySystem.reset_for_new_world(); ProgressionSystem.reset_for_new_world(); ResourceSystem.reset_for_new_world(); FoodSystem.reset_for_new_world(); ConsequenceEngine.reset_for_new_world(); AdvisorSystem.reset_for_new_world(); CivilizationSystem.reset_for_new_world()
	var terrain:Node=load("res://local_terrain.tscn").instantiate()
	add_child(terrain)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(is_instance_valid(terrain.founding_focus_panel))
	assert(terrain.founding_focus_panel==PeopleDirection.panel and PeopleDirection.panel.opening)
	assert(PeopleDirection.panel.ambition_buttons.size()==8)
	assert(terrain.game_speed==0)
	PeopleDirection.panel.ambition_buttons[1].pressed.emit()
	assert(PeopleDirection.ambition=="","highlighting a card must not make the decision")
	PeopleDirection.panel.pages[0].get_node("ConfirmFocus").pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(PeopleDirection.ambition=="makers")
	assert(GameState.founding_focus=="collective_ambition")
	assert(GameState.founding_effect("food_yield")==0,"new opening silently applied old survival preset")
	assert(not is_instance_valid(terrain.founding_focus_panel))
	assert(terrain.game_speed==1.0)
	PeopleDirection.open_direction()
	assert(is_instance_valid(PeopleDirection.panel) and not PeopleDirection.panel.opening)
	PeopleDirection.panel.queue_free()
	await get_tree().process_frame
	GameState.elapsed_days=36500
	MilitaryCampaign.last_processed_day=36500
	terrain.last_discovery_day=36500
	terrain.game_speed=5
	terrain._process(0.0)
	assert(terrain.game_speed==0,"century boundary must pause for the player")
	assert(is_instance_valid(PeopleDirection.panel),"century boundary did not prompt")
	assert(PeopleDirection.ambition=="makers","new century silently chose a focus")
	PeopleDirection.panel.ambition_buttons[1].pressed.emit()
	PeopleDirection.panel.pages[0].get_node("ConfirmFocus").pressed.emit()
	assert(PeopleDirection.chosen_century==1,"renewal was not recorded")
	assert(terrain.game_speed==0,"century confirmation unexpectedly resumed time")
	terrain.queue_free()
	await get_tree().process_frame
	print("PEOPLE_OPENING PASS: eight century focuses, explicit confirmation, choice starts map, no extra preset, direction reopens")
	get_tree().quit()
